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

"$script_dir/install_aur.sh"
"$script_dir/install_tools.sh"
"$script_dir/post_install.sh"

section 'Cleaning package caches'
yay -Yc --noconfirm
yay -Sc --noconfirm
