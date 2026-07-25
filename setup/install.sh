#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_packages=false
install_latex=false
install_post=false
install_symlinks=false
prompt_latex=false

usage() {
    cat << EOF
usage: $0 [--all] [--packages] [--latex] [--post] [--symlinks]

  --all       Install packages and symlinks, and optionally LaTeX (default)
  --packages  Install packages and run post-install configuration
  --latex     Install LaTeX
  --post      Run post-install only (included by --all and --packages)
  --symlinks  Create configuration symlinks
EOF
}

(($#)) || set -- --all

for arg in "$@"; do
    case $arg in
        --all)
            install_packages=true
            install_symlinks=true
            prompt_latex=true
            ;;
        --packages) install_packages=true ;;
        --latex) install_latex=true ;;
        --post) install_post=true ;;
        --symlinks) install_symlinks=true ;;
        -h | --help)
            usage
            exit
            ;;
        *)
            echo "unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if $prompt_latex && ! $install_latex; then
    printf 'Install LaTeX with tlmgr? [y/n] '
    read -r choice
    [[ $choice == [yY] ]] && install_latex=true
fi

# Run selected components in dependency order
if $install_packages; then
    "$script_dir/install_pacman.sh"
    "$script_dir/install_aur.sh"
    "$script_dir/install_language_tools.sh"
fi
if $install_latex; then
    "$script_dir/install_latex.sh"
fi
if $install_packages || $install_post; then
    "$script_dir/post_install.sh"
fi
if $install_symlinks; then
    "$script_dir/symlinks.sh"
fi
