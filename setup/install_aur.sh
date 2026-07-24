#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() {
	printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

section 'Disabling AUR debug packages'
sudo install -d /etc/makepkg.conf.d
printf 'OPTIONS+=(!debug)\n' | sudo tee /etc/makepkg.conf.d/dotfiles.conf >/dev/null

if ! command -v yay >/dev/null; then
	section 'Installing Yay'
	build_dir=$(mktemp -d /tmp/yay-build.XXXXXX)
	trap 'rm -rf -- "$build_dir"' EXIT
	git clone https://aur.archlinux.org/yay-bin.git "$build_dir/yay"
	(
		cd "$build_dir/yay"
		makepkg -si --needed --noconfirm --clean --rmdeps
	)
fi

# Install the declarative AUR profile after bootstrapping Yay
section 'Installing AUR packages'
mapfile -t packages < <(
	sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$script_dir/packages/aur.txt"
)

if systemd-detect-virt --quiet; then
	section 'Skipping unnecessary applications in the VM'
	filtered_packages=()
	for package in "${packages[@]}"; do
		case $package in
		microsoft-edge-dev-bin | onedrive-abraunegg | onlyoffice-bin | zoom) ;;
		*) filtered_packages+=("$package") ;;
		esac
	done
	packages=("${filtered_packages[@]}")
fi

yay -S --needed --noconfirm --answerdiff=None --removemake --cleanafter "${packages[@]}"
