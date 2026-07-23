#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! command -v yay >/dev/null; then
	build_dir=$(mktemp -d /tmp/yay-build.XXXXXX)
	trap 'rm -rf -- "$build_dir"' EXIT
	git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
	(
		cd "$build_dir/yay"
		makepkg -si --needed --noconfirm
	)
fi

mapfile -t packages < <(
	sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$script_dir/packages/aur.txt"
)
yay -S --needed --noconfirm --answerdiff=None "${packages[@]}"
