#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
policies_dir="$script_dir/../config/browser-policies"

current_step=0
total_steps=$(grep -c "^section '" "${BASH_SOURCE[0]}")

section() {
    ((current_step += 1))
    printf '\033[1;34m\n-> [%d/%d] %s...\033[0m\n' \
        "$current_step" "$total_steps" "$1"
}

ensure_pam_rule() {
    local file=$1 anchor=$2 rule=$3
    local rule_pattern=${rule// /[[:space:]]+}
    grep -Eq "^$rule_pattern$" "$file" && return
    grep -Eq "$anchor" "$file" || {
        printf 'PAM anchor not found in %s: %s\n' "$file" "$anchor" >&2
        return 1
    }
    sudo sed -i -E "/$anchor/a $rule" "$file"
}

printf '\033[1;32m\n:: Starting post-install configuration\033[0m\n'

section 'Configuring CPU scheduler'
sudo install -Dm644 /dev/stdin /etc/scx_loader/config.toml << 'EOF'
default_sched = "scx_lavd"
default_mode = "Auto"
EOF

section 'Configuring CPU power management'
sudo install -Dm644 /dev/stdin /etc/tlp.d/10-performance.conf << 'EOF'
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_SAV=0
INTEL_GPU_POWER_PROFILE_ON_BAT=base
WIFI_PWR_ON_BAT=off
EOF

section 'Configuring compressed swap'
sudo install -Dm644 /dev/stdin /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
sudo install -Dm644 /dev/stdin /etc/sysctl.d/99-zram.conf << 'EOF'
vm.page-cluster = 0
vm.swappiness = 180
EOF

section 'Limiting persistent logs'
sudo install -Dm644 /dev/stdin /etc/systemd/journald.conf.d/size.conf << 'EOF'
[Journal]
SystemMaxUse=250M
EOF

section 'Creating NFS mount point'
sudo install -d /mnt/nfs

section 'Configuring recovery SSH'
sudo install -Dm644 /dev/stdin /etc/ssh/sshd_config.d/10-recovery.conf << EOF
PasswordAuthentication yes
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers $USER
EOF
sudo ssh-keygen -A
sudo /usr/bin/sshd -t

section 'Configuring wireless regulatory domain'
sudo sed -i -E \
    -e 's/^WIRELESS_REGDOM=/#&/' \
    -e 's/^#WIRELESS_REGDOM="00"$/WIRELESS_REGDOM="00"/' \
    /etc/conf.d/wireless-regdom

section 'Configuring local hostname discovery'
sudo sed -i \
    -e '/^deny-interfaces=docker0,virbr0$/d' \
    -e '/^\[server\]$/a deny-interfaces=docker0,virbr0' \
    /etc/avahi/avahi-daemon.conf
if ! grep -q '^hosts:.*mdns_minimal' /etc/nsswitch.conf; then
    sudo sed -i \
        '/^hosts:/ s/mymachines/mymachines mdns_minimal [NOTFOUND=return]/' \
        /etc/nsswitch.conf
fi

section 'Enabling system services'
sudo systemctl enable \
    bluetooth \
    btrfs-scrub.timer \
    NetworkManager \
    paccache.timer \
    scx_loader.service \
    tlp
sudo systemctl enable --now \
    avahi-daemon.socket \
    cups.socket \
    sshd.service \
    systemd-timesyncd
if ! systemd-detect-virt --vm --quiet; then
    sudo systemctl enable fwupd-refresh.timer
    sudo systemctl enable --now intel_lpmd.service
    # Lenovo DYTC provides the thermal policy on supported ThinkPads
    if [[ ! -e /sys/devices/platform/thinkpad_acpi/dytc_lapmode ]]; then
        sudo systemctl enable --now thermald.service
    fi
fi

section 'Configuring login and keyring'
# Fish login sessions start Hyprland after tty1 authentication
sudo chsh -s "$(command -v fish)" "$USER"
ensure_pam_rule \
    /etc/pam.d/login \
    '^auth[[:space:]]+include[[:space:]]+system-local-login$' \
    'auth optional pam_gnome_keyring.so'
ensure_pam_rule \
    /etc/pam.d/login \
    '^session[[:space:]]+include[[:space:]]+system-local-login$' \
    'session optional pam_gnome_keyring.so auto_start'
ensure_pam_rule \
    /etc/pam.d/passwd \
    '^password[[:space:]]+include[[:space:]]+system-auth$' \
    'password optional pam_gnome_keyring.so'

section 'Enabling user services'
systemctl --user enable \
    gnome-keyring-daemon.socket \
    pipewire \
    pipewire-pulse \
    wireplumber

section 'Configuring Docker'
sudo usermod -aG docker "$USER"
mkdir -p "$HOME/.cache/docker"
if [[ $(findmnt -no FSTYPE --target "$HOME/.cache/docker") == btrfs ]]; then
    chattr +C "$HOME/.cache/docker"
fi
sudo install -Dm644 /dev/stdin /etc/docker/daemon.json << EOF
{
    "data-root": "$HOME/.cache/docker"
}
EOF
sudo systemctl enable --now docker.socket

section 'Setting desktop defaults'
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface cursor-theme capitaine-cursors
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
xdg-user-dirs-update
xdg-mime default org.pwmt.zathura-pdf-poppler.desktop application/pdf
for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
    xdg-mime default imv.desktop "$mime"
done

section 'Installing browser policies'
sudo install -Dm644 \
    "$policies_dir/brave.json" \
    /etc/brave/policies/managed/dotfiles.json
sudo install -Dm644 \
    "$policies_dir/chromium-recommended.json" \
    /etc/brave/policies/recommended/dotfiles.json
sudo install -Dm644 \
    "$policies_dir/edge.json" \
    /etc/opt/edge/policies/managed/dotfiles.json
sudo install -Dm644 \
    "$policies_dir/chromium-recommended.json" \
    /etc/opt/edge/policies/recommended/dotfiles.json
sudo install -Dm644 \
    "$policies_dir/firefox.json" \
    /etc/firefox/policies/policies.json

section 'Setting application defaults'
if command -v zoom > /dev/null && [[ ! -e $HOME/.config/zoomus.conf ]]; then
    mkdir -p "$HOME/.config"
    printf '%s\n' \
        '[General]' \
        'autoScale=false' \
        'scaleFactor=2' \
        > "$HOME/.config/zoomus.conf"
fi
if command -v spotify > /dev/null &&
    [[ ! -e $HOME/.config/spotify/prefs ]]; then
    mkdir -p "$HOME/.config/spotify"
    printf 'app.autostart-mode="off"\n' > "$HOME/.config/spotify/prefs"
fi

section 'Configuring gopass'
gopass config generate.autoclip false
gopass config core.notifications false
gopass config mounts.path "$HOME/.password-store"
