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
sudo systemctl enable NetworkManager bluetooth sshd tlp
systemctl --user enable pipewire pipewire-pulse wireplumber gnome-keyring-daemon.socket 2>/dev/null || true
sudo systemctl enable --now avahi-daemon.service cups.socket ollama.service

section 'Configuring compressed swap'
printf '[zram0]\n' | sudo tee /etc/systemd/zram-generator.conf >/dev/null

section 'Setting desktop defaults'
xdg-user-dirs-update
xdg-mime default org.pwmt.zathura-pdf-poppler.desktop application/pdf
for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
	xdg-mime default imv.desktop "$mime"
done

section 'Creating mount points'
sudo install -d /mnt/nfs

section 'Configuring development services'
if grep -qw vmx /proc/cpuinfo; then
	sudo modprobe kvm_intel
fi
sudo usermod -aG docker "$USER"
mkdir -p "$HOME/.cache/docker"
sudo install -d /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
    "data-root": "$HOME/.cache/docker"
}
EOF
sudo systemctl enable --now docker.socket systemd-timesyncd
