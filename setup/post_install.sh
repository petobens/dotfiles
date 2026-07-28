#!/usr/bin/env bash
set -euo pipefail

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

section 'Configuring CPU scheduler'
sudo install -d /etc/scx_loader
sudo tee /etc/scx_loader/config.toml > /dev/null << 'EOF'
default_sched = "scx_lavd"
default_mode = "Auto"
EOF

section 'Configuring CPU power management'
sudo install -d /etc/tlp.d
sudo tee /etc/tlp.d/10-performance.conf > /dev/null << 'EOF'
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_SAV=0
INTEL_GPU_POWER_PROFILE_ON_BAT=base
WIFI_PWR_ON_BAT=off
EOF

section 'Configuring compressed swap'
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
sudo tee /etc/sysctl.d/99-zram.conf > /dev/null << 'EOF'
vm.page-cluster = 0
vm.swappiness = 180
EOF

section 'Limiting persistent logs'
sudo install -d /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size.conf > /dev/null << 'EOF'
[Journal]
SystemMaxUse=250M
EOF

section 'Creating mount points'
sudo install -d /mnt/nfs

section 'Configuring recovery SSH'
sudo install -d /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/10-recovery.conf > /dev/null << EOF
PasswordAuthentication yes
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers $USER
EOF
sudo ssh-keygen -A
sudo /usr/bin/sshd -t

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
sudo systemctl enable scx_loader.service
sudo systemctl enable tlp
if ! systemd-detect-virt --vm --quiet; then
    sudo systemctl enable --now intel_lpmd.service
    # Lenovo DYTC provides the thermal policy on supported ThinkPads
    if [[ ! -e /sys/devices/platform/thinkpad_acpi/dytc_lapmode ]]; then
        sudo systemctl enable --now thermald.service
    fi
    sudo systemctl enable fwupd-refresh.timer
fi
sudo systemctl enable NetworkManager
sudo systemctl enable --now systemd-timesyncd
sudo systemctl enable --now avahi-daemon.socket
sudo systemctl enable --now sshd.service
sudo systemctl enable bluetooth
sudo systemctl enable --now cups.socket
sudo systemctl enable paccache.timer

section 'Configuring login and user services'
# Fish login sessions start Hyprland after tty1 authentication
sudo chsh -s "$(command -v fish)" "$USER"
systemctl --user enable gnome-keyring-daemon.socket
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber

section 'Configuring development services'
sudo usermod -aG docker "$USER"
mkdir -p "$HOME/.cache/docker"
if [[ $(findmnt -no FSTYPE --target "$HOME/.cache/docker") == btrfs ]]; then
    chattr +C "$HOME/.cache/docker"
fi
sudo install -d /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
    "data-root": "$HOME/.cache/docker"
}
EOF
sudo systemctl enable --now docker.socket

section 'Setting desktop defaults'
xdg-user-dirs-update
xdg-mime default org.pwmt.zathura-pdf-poppler.desktop application/pdf
for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
    xdg-mime default imv.desktop "$mime"
done

section 'Configuring Gopass'
gopass config generate.autoclip false
gopass config core.notifications false
gopass config mounts.path "$HOME/.password-store"
