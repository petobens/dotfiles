#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
policies_dir="$script_dir/../config/browser-policies"

current_step=0
total_steps=$(grep -c "^section '" "${BASH_SOURCE[0]}")

section() {
    ((current_step += 1))
    printf '\033[1;34m\n  -> [%d/%d] %s...\033[0m\n' \
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

printf '\033[1;32m:: Starting post-install configuration\033[0m\n'

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

section 'Configuring root snapshots'
sudo install -Dm600 \
    /usr/share/snapper/config-templates/default \
    /etc/snapper/configs/root
sudo sed -i -E \
    -e 's/^NUMBER_CLEANUP=.*/NUMBER_CLEANUP="yes"/' \
    -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' \
    -e 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="0"/' \
    -e 's/^EMPTY_PRE_POST_CLEANUP=.*/EMPTY_PRE_POST_CLEANUP="yes"/' \
    -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' \
    -e 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="no"/' \
    /etc/snapper/configs/root
sudo install -Dm644 /dev/stdin /etc/conf.d/snapper << 'EOF'
SNAPPER_CONFIGS="root"
EOF
sudo chmod 750 /.snapshots

section 'Limiting persistent logs'
sudo install -Dm644 /dev/stdin /etc/systemd/journald.conf.d/size.conf << 'EOF'
[Journal]
SystemMaxUse=250M
EOF

section 'Creating NFS mount point'
sudo install -d /mnt/nfs

section 'Configuring recovery SSH'
sudo install -Dm644 /dev/stdin /etc/ssh/sshd_config.d/10-recovery.conf << EOF
AllowUsers $USER
DisableForwarding yes
KbdInteractiveAuthentication no
LoginGraceTime 30
MaxAuthTries 3
PasswordAuthentication yes
PermitEmptyPasswords no
PermitRootLogin no
PubkeyAuthentication yes
EOF
sudo ssh-keygen -A
sudo /usr/bin/sshd -t

section 'Configuring firewall'
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit 22/tcp comment 'recovery SSH'
sudo ufw allow 53317/tcp comment 'LocalSend'
sudo ufw allow 53317/udp comment 'LocalSend'
sudo ufw --force enable
sudo systemctl enable --now ufw.service

section 'Configuring wireless regulatory domain'
sudo sed -i -E \
    -e 's/^WIRELESS_REGDOM=/#&/' \
    -e 's/^#WIRELESS_REGDOM="00"$/WIRELESS_REGDOM="00"/' \
    /etc/conf.d/wireless-regdom

section 'Configuring Pacman mirrors'
sudo install -Dm644 /dev/stdin /etc/xdg/reflector/reflector.conf << 'EOF'
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 10
--sort rate
--number 5
EOF

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
    reflector.timer \
    scx_loader.service \
    snapper-cleanup.timer \
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
    "data-root": "$HOME/.cache/docker",
    "ip": "127.0.0.1",
    "default-network-opts": {
        "bridge": {
            "com.docker.network.bridge.host_binding_ipv4": "127.0.0.1"
        }
    }
}
EOF
sudo systemctl enable --now docker.socket

section 'Installing udev rules'
# Reset the zoom level of the external Logitech webcam when it is plugged in
sudo install -Dm644 \
    "$script_dir/udev/99-webcam.rules" \
    /etc/udev/rules.d/99-webcam.rules
sudo udevadm control --reload

section 'Setting desktop defaults'
# The video group grants write access to the backlight brightness files
sudo usermod -aG video "$USER"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface cursor-theme macOS
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
xdg-user-dirs-update
xdg-mime default org.pwmt.zathura-pdf-poppler.desktop application/pdf
for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
    xdg-mime default imv-dir.desktop "$mime"
done

section 'Installing DM fonts'
dm_fonts_commit=9c5708e735fc805514913d46d259945a3b6ba67a
dm_fonts_url="https://raw.githubusercontent.com/google/fonts/$dm_fonts_commit/ofl"
dm_sans_url="$dm_fonts_url/dmsans"
dm_sans_dir="$HOME/.local/share/fonts/DM Sans"
mkdir -p "$dm_sans_dir"
curl -fsSL --remove-on-error -o "$dm_sans_dir/DMSans.ttf" \
    "$dm_sans_url/DMSans%5Bopsz%2Cwght%5D.ttf"
curl -fsSL --remove-on-error -o "$dm_sans_dir/DMSans-Italic.ttf" \
    "$dm_sans_url/DMSans-Italic%5Bopsz%2Cwght%5D.ttf"
dm_mono_url="$dm_fonts_url/dmmono"
dm_mono_dir="$HOME/.local/share/fonts/DM Mono"
mkdir -p "$dm_mono_dir"
for dm_mono_file in \
    DMMono-Light.ttf DMMono-LightItalic.ttf \
    DMMono-Regular.ttf DMMono-Italic.ttf; do
    curl -fsSL --remove-on-error -o "$dm_mono_dir/$dm_mono_file" \
        "$dm_mono_url/$dm_mono_file"
done
fc-cache "$dm_sans_dir" "$dm_mono_dir"

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
# This runs before config symlinks, so keep the model in sync with
# config/voxtype/config.toml
if command -v voxtype > /dev/null; then
    voxtype setup --download --model small
fi

section 'Configuring gopass'
gopass config generate.autoclip false
gopass config core.notifications false
gopass config mounts.path "$HOME/.password-store"
