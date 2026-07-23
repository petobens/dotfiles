#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_packages=false
install_symlinks=false
vm=false

for arg in "$@"; do
	case $arg in
	--all)
		install_packages=true
		install_symlinks=true
		;;
	--packages) install_packages=true ;;
	--symlinks) install_symlinks=true ;;
	--vm) vm=true ;;
	--non-interactive) ;;
	*)
		echo "unknown option: $arg" >&2
		exit 2
		;;
	esac
done

if ! $install_packages && ! $install_symlinks; then
	printf 'Install [p]ackages, [s]ymlinks, or [a]ll? '
	read -r choice
	case $choice in
	p) install_packages=true ;;
	s) install_symlinks=true ;;
	a)
		install_packages=true
		install_symlinks=true
		;;
	*) exit 1 ;;
	esac
fi

if $install_packages; then
	package_args=()
	$vm && package_args+=(--vm)
	"$script_dir/install-packages.sh" "${package_args[@]}"
fi
if $install_symlinks; then
	"$script_dir/symlinks.sh"
fi

if command -v fish >/dev/null && [[ $(getent passwd "$USER" | cut -d: -f7) != "$(command -v fish)" ]]; then
	echo "Fish is installed. Run 'chsh -s $(command -v fish)' when ready."
fi
