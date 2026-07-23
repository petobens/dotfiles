#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
base="$state_dir/arch-cloud.qcow2"
disk="$state_dir/wayland.qcow2"
seed="$state_dir/cloud-init.iso"
firmware_vars="$state_dir/OVMF_VARS.4m.fd"
image_url=https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2
checksum_url=$image_url.SHA256
firmware_vars_template=/usr/share/edk2/x64/OVMF_VARS.4m.fd

for command in curl qemu-img cloud-localds; do
	command -v "$command" >/dev/null || {
		echo "Missing $command. Install qemu-desktop and cloud-image-utils." >&2
		exit 1
	}
done

mkdir -p "$state_dir"
[[ -r $firmware_vars_template ]] || {
	echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
	exit 1
}
checksum=$(curl --fail --location "$checksum_url" | awk '{print $1}')
# Keep guest writes in a small overlay on top of the verified base image
if [[ ! -f $base ]] || ! printf '%s  %s\n' "$checksum" "$base" | sha256sum --check --status; then
	curl --fail --location --output "$base.part" "$image_url"
	mv "$base.part" "$base"
fi
printf '%s  %s\n' "$checksum" "$base" | sha256sum --check
[[ -f $disk ]] || qemu-img create -f qcow2 -F qcow2 -b "$base" "$disk" 16G
[[ -f $firmware_vars ]] || cp "$firmware_vars_template" "$firmware_vars"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$script_dir/user-data" "$tmp/user-data"
printf 'instance-id: dotfiles-wayland\nlocal-hostname: wayland-vm\n' >"$tmp/meta-data"
cloud-localds "$seed" "$tmp/user-data" "$tmp/meta-data"
printf 'VM created in %s\nRun %s/launch.sh\n' "$state_dir" "$script_dir"
