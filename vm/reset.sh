#!/usr/bin/env bash
set -euo pipefail

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
seed="$state_dir/cloud-init.iso"
firmware_vars="$state_dir/OVMF_VARS.4m.fd"

timestamp=$(date +%Y%m%d-%H%M%S)
if [[ -f $disk ]]; then
	# Keep only the guest being replaced as a recoverable backup
	shopt -s nullglob
	old_backups=("$disk".*.bak "$firmware_vars".*.bak)
	((${#old_backups[@]} == 0)) || rm -- "${old_backups[@]}"
	shopt -u nullglob

	mv "$disk" "$disk.$timestamp.bak"
	[[ -f $firmware_vars ]] && mv "$firmware_vars" "$firmware_vars.$timestamp.bak"
fi
[[ -f $seed ]] && rm "$seed"
"$(dirname "${BASH_SOURCE[0]}")/create.sh"

# Retain only cloud images referenced by the active disk or its latest backup
referenced_bases=()
shopt -s nullglob
images=("$disk" "$disk".*.bak)
shopt -u nullglob
for image in "${images[@]}"; do
	[[ -f $image ]] || continue
	base=$(qemu-img info --output=json "$image" | jq -r '.["full-backing-filename"] // empty')
	[[ -z $base ]] || referenced_bases+=("$base")
done

shopt -s nullglob
for base in "$state_dir"/arch-cloud.qcow2 "$state_dir"/arch-cloud-*.qcow2; do
	keep=false
	for referenced_base in "${referenced_bases[@]}"; do
		[[ $base == "$referenced_base" ]] && keep=true
	done
	$keep || rm -- "$base"
done
shopt -u nullglob
