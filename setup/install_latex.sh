#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

die() {
    printf '\033[1;31mError: %s\033[0m\n' "$1" >&2
    exit 1
}

printf '\033[1;32m\n:: Starting LaTeX installation\033[0m\n'

# Verify the system dependencies needed by the native installer
for command in curl git perl tar; do
    command -v "$command" > /dev/null ||
        die "Missing $command. Install the system packages first."
done

section 'Installing the arara Java runtime'
sudo pacman -S --needed --noconfirm jre21-openjdk-headless

# Reuse the newest native TeX Live installation when available
texlive_root=/usr/local/texlive
tlmgr=
if [[ -d $texlive_root ]]; then
    tlmgr=$(find "$texlive_root" -path '*/bin/x86_64-linux/tlmgr' -type f |
        sort -V | tail -1)
fi

if [[ -z $tlmgr ]]; then
    section 'Installing TeX Live'
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' EXIT
    archive="$tmp/install-tl-unx.tar.gz"
    curl --fail --location --output "$archive" \
        https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar -xzf "$archive" -C "$tmp"
    installer=("$tmp"/install-tl-*/install-tl)
    [[ -f ${installer[0]} ]] ||
        die 'TeX Live archive did not contain the installer.'
    sudo perl "${installer[0]}" --no-interaction --scheme=basic
    tlmgr=$(find "$texlive_root" -path '*/bin/x86_64-linux/tlmgr' -type f |
        sort -V | tail -1)
fi

[[ -x $tlmgr ]] || die 'TeX Live installation did not produce tlmgr.'

# Keep the requested TeX packages explicit and reproducible
mapfile -t packages < "$script_dir/packages/latex.txt"

section 'Installing TeX Live packages'
sudo "$tlmgr" update --self
sudo "$tlmgr" option docfiles 1
sudo "$tlmgr" install "${packages[@]}"
sudo "$tlmgr" update --all
sudo "$tlmgr" path add

if [[ ! -d $HOME/texmf ]]; then
    section 'Installing personal BibLaTeX style'
    git clone https://github.com/petobens/mybibformat "$HOME/texmf"
fi
