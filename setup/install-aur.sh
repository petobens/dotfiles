#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() {
	printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

if ! command -v yay >/dev/null; then
	section 'Installing Yay'
	build_dir=$(mktemp -d /tmp/yay-build.XXXXXX)
	trap 'rm -rf -- "$build_dir"' EXIT
	git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
	(
		cd "$build_dir/yay"
		makepkg -si --needed --noconfirm
	)
fi

# Install the declarative AUR profile after bootstrapping Yay
section 'Installing AUR packages'
mapfile -t packages < <(
	sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$script_dir/packages/aur.txt"
)
yay -S --needed --noconfirm --answerdiff=None "${packages[@]}"
