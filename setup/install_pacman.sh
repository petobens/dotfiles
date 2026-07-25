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

if systemd-detect-virt --vm --quiet; then
    section 'Skipping unnecessary applications in the VM'
    mapfile -t packages < <(
        printf '%s\n' "${packages[@]}" |
            grep -Fvx -f "$script_dir/packages/vm_skip.txt"
    )
fi

section 'Installing Pacman packages'
sudo pacman -Syu --needed --noconfirm "${packages[@]}"
