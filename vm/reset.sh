#!/usr/bin/env bash
set -euo pipefail

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
seed="$state_dir/cloud-init.iso"
firmware_vars="$state_dir/OVMF_VARS.4m.fd"
# Preserve the last guest disk so a failed test can still be inspected
timestamp=$(date +%Y%m%d-%H%M%S)
[[ -f $disk ]] && mv "$disk" "$disk.$timestamp.bak"
[[ -f $firmware_vars ]] && mv "$firmware_vars" "$firmware_vars.$timestamp.bak"
[[ -f $seed ]] && rm "$seed"
"$(dirname "${BASH_SOURCE[0]}")/create.sh"
