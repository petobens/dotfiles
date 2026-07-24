#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
profiles=(base desktop applications development)

section() {
	printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

# Merge declarative package profiles before calling pacman
mapfile -t packages < <(
	for profile in "${profiles[@]}"; do
		sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
			"$script_dir/packages/$profile.txt"
	done | sort -u
)

if systemd-detect-virt --quiet; then
	section 'Skipping Firefox in the VM'
	filtered_packages=()
	for package in "${packages[@]}"; do
		[[ $package == firefox ]] || filtered_packages+=("$package")
	done
	packages=("${filtered_packages[@]}")
fi

section 'Installing Pacman packages'
sudo pacman -Syu --needed --noconfirm "${packages[@]}"

section 'Configuring login and system services'
# Fish login sessions start Hyprland after tty1 authentication
sudo chsh -s "$(command -v fish)" "$USER"
sudo systemctl enable NetworkManager bluetooth sshd tlp
systemctl --user enable pipewire pipewire-pulse wireplumber gnome-keyring-daemon.socket 2>/dev/null || true

section 'Configuring compressed swap'
printf '[zram0]\n' | sudo tee /etc/systemd/zram-generator.conf >/dev/null

section 'Setting desktop defaults'
for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
	xdg-mime default imv.desktop "$mime"
done

section 'Configuring development services'
if grep -qw vmx /proc/cpuinfo; then
	sudo modprobe kvm_intel
fi
sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker.socket systemd-timesyncd
"$script_dir/install-aur.sh"
"$script_dir/install-tools.sh"

section 'Cleaning package caches'
yay -Yc --noconfirm
yay -Sc --noconfirm
