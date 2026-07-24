#!/usr/bin/env bash
set -euo pipefail

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
firmware_vars="$state_dir/OVMF_VARS.4m.fd"

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

section 'Resetting Wayland VM'
shopt -s nullglob
old_state=("$disk" "$firmware_vars" "$disk".*.bak "$firmware_vars".*.bak)
((${#old_state[@]} == 0)) || rm -- "${old_state[@]}"
shopt -u nullglob
"$(dirname "${BASH_SOURCE[0]}")/create.sh"

# Remove obsolete state from the previous cloud-image VM
[[ ! -f $state_dir/cloud-init.iso ]] || rm -- "$state_dir/cloud-init.iso"

# Remove legacy cloud images once the new disk no longer references them
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
for base in "$state_dir"/arch-cloud*.qcow2; do
    keep=false
    for referenced_base in "${referenced_bases[@]}"; do
        [[ $base == "$referenced_base" ]] && keep=true
    done
    $keep || rm -- "$base"
done
shopt -u nullglob
