#!/usr/bin/env bash
set -euo pipefail

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

section 'Configuring Gopass'
gopass config generate.autoclip false
gopass config core.notifications false
gopass config mounts.path "$HOME/.password-store"

section 'Configuring login and system services'
# Fish login sessions start Hyprland after tty1 authentication
sudo chsh -s "$(command -v fish)" "$USER"
sudo systemctl enable --now avahi-daemon.service
sudo systemctl enable bluetooth
sudo systemctl enable --now cups.socket
sudo systemctl enable --now ipp-usb.service
sudo systemctl enable NetworkManager
if ! systemd-detect-virt --vm --quiet; then
    sudo systemctl enable --now ollama.service
fi
sudo systemctl enable sshd
sudo systemctl enable tlp
systemctl --user enable gnome-keyring-daemon.socket
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber

section 'Configuring compressed swap'
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

section 'Setting desktop defaults'
xdg-user-dirs-update
xdg-mime default org.pwmt.zathura-pdf-poppler.desktop application/pdf
for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
    xdg-mime default imv.desktop "$mime"
done

section 'Creating mount points'
sudo install -d /mnt/nfs

section 'Configuring development services'
sudo usermod -aG docker "$USER"
mkdir -p "$HOME/.cache/docker"
sudo install -d /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
    "data-root": "$HOME/.cache/docker"
}
EOF
sudo systemctl enable --now docker.socket
sudo systemctl enable --now systemd-timesyncd
