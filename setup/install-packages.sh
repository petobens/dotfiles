#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
profiles=(base desktop)
vm=false
if [[ ${1:-} == --vm ]]; then
	profiles+=(vm)
	vm=true
else
	# QEMU belongs on the physical host, not inside the test guest
	profiles+=(applications development host)
fi

# Merge declarative package profiles before calling pacman
mapfile -t packages < <(
	for profile in "${profiles[@]}"; do
		sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
			"$script_dir/packages/$profile.txt"
	done | sort -u
)

sudo pacman -Syu --needed --noconfirm "${packages[@]}"

# Use Fish for login sessions so tty1 starts Hyprland after authentication
sudo chsh -s "$(command -v fish)" "$USER"

# Enable the services required by the desktop profile
sudo systemctl enable NetworkManager bluetooth sshd
systemctl --user enable pipewire pipewire-pulse wireplumber gnome-keyring-daemon.socket 2>/dev/null || true

for mime in image/gif image/jpeg image/png image/svg+xml image/webp; do
	xdg-mime default imv.desktop "$mime"
done

if ! $vm; then
	sudo modprobe kvm_intel
	sudo usermod -aG docker "$USER"
	if [[ ! -f /var/lib/postgres/data/PG_VERSION ]]; then
		sudo -iu postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data
	fi
	sudo systemctl enable --now docker postgresql systemd-timesyncd
	"$script_dir/install-aur.sh"
	"$script_dir/install-tools.sh"
fi
