#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() {
    printf '\033[1;34m\n  -> %s...\033[0m\n' "$1"
}

printf '\033[1;32m\n:: Starting AUR package installation\033[0m\n'

section 'Configuring AUR builds'
sudo install -Dm644 /dev/stdin /etc/makepkg.conf.d/dotfiles.conf << 'EOF'
BUILDDIR=/tmp/makepkg
MAKEFLAGS="-j$(nproc)"
OPTIONS+=(!debug)
EOF

if ! command -v yay > /dev/null; then
    section 'Installing Yay'
    build_dir=$(mktemp -d /tmp/yay-build.XXXXXX)
    trap 'rm -rf -- "$build_dir"' EXIT
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir"
    (
        cd "$build_dir"
        makepkg -si --needed --noconfirm --rmdeps
    )
fi

section 'Installing AUR packages'
mapfile -t packages < <(
    sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$script_dir/packages/aur.txt"
)

if systemd-detect-virt --vm --quiet; then
    section 'Skipping packages unnecessary in the VM'
    mapfile -t packages < <(
        printf '%s\n' "${packages[@]}" |
            grep -Fvx -f <(
                sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
                    "$script_dir/packages/vm_skip.txt"
            )
    )
fi

yay -S --needed --noconfirm --answerdiff=None --removemake --cleanafter "${packages[@]}"

section 'Cleaning package caches'
yay -Yc --noconfirm
yay -Sc --noconfirm
