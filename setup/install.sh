#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_packages=false
install_latex=false
install_symlinks=false
prompt_latex=false

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
        --symlinks) install_symlinks=true ;;
        *)
            echo "unknown option: $arg" >&2
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
    "$script_dir/install_packages.sh"
fi
if $install_latex; then
    "$script_dir/install_latex.sh"
fi
if $install_symlinks; then
    "$script_dir/symlinks.sh"
fi
