#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
firmware_vars="$state_dir/OVMF_VARS.4m.fd"
iso_url=https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
checksum_url=https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt
firmware_vars_template=/usr/share/edk2/x64/OVMF_VARS.4m.fd

section() {
	printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

# Check the host tools and firmware needed to build the VM
for command in curl qemu-img; do
	command -v "$command" >/dev/null || {
		echo "Missing $command. Install qemu-desktop." >&2
		exit 1
	}
done

mkdir -p "$state_dir"
[[ -r $firmware_vars_template ]] || {
	echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
	exit 1
}

section 'Preparing Arch installation media'
checksum=$(curl --fail --location "$checksum_url" |
	awk '$2 == "archlinux-x86_64.iso" {print $1}')
[[ -n $checksum ]] || {
	echo 'Could not find the Arch ISO checksum.' >&2
	exit 1
}
iso="$state_dir/archlinux-$checksum.iso"
if [[ ! -f $iso ]] || ! printf '%s  %s\n' "$checksum" "$iso" | sha256sum --check --status; then
	curl --fail --location --output "$iso.part" "$iso_url"
	mv "$iso.part" "$iso"
fi
printf '%s  %s\n' "$checksum" "$iso" | sha256sum --check

# Create persistent guest storage and writable UEFI variables
if [[ ! -f $disk ]]; then
	section 'Creating VM disk'
	qemu-img create -f qcow2 "$disk" 96G
fi
if [[ ! -f $firmware_vars ]]; then
	section 'Initializing UEFI firmware'
	cp "$firmware_vars_template" "$firmware_vars"
fi

# Keep only the current installer ISO
shopt -s nullglob
for old_iso in "$state_dir"/archlinux-*.iso; do
	[[ $old_iso == "$iso" ]] || rm -- "$old_iso"
done
shopt -u nullglob

printf 'VM created in %s\nRun %s/launch.sh\n' "$state_dir" "$script_dir"
