#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$script_dir/.." && pwd)
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
seed="$state_dir/cloud-init.iso"
firmware_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
firmware_vars="$state_dir/OVMF_VARS.4m.fd"

if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
	echo 'KVM is unavailable. Reboot, then check that /dev/kvm exists.' >&2
	exit 1
fi

[[ -f $disk && -f $seed && -f $firmware_vars ]] || "$script_dir/create.sh"
[[ -r $firmware_code ]] || {
	echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
	exit 1
}

printf '%s\n' \
	'First boot only: log in as pedro with password wayland.' \
	'Wait for ~/git-repos/private/dotfiles to appear.' \
	'Then run: cd ~/git-repos/private/dotfiles && ./setup/install.sh' \
	'Host edits are reflected live in the read-only guest checkout.' \
	'If Hyprland starts, the guest is already installed and no setup is needed.'

args=(
	-name dotfiles-wayland
	-enable-kvm
	-machine "q35,accel=kvm"
	-cpu host
	-smp 8
	-m 8192
	-device virtio-vga-gl
	-display "gtk,gl=on,grab-on-hover=on,zoom-to-fit=on"
	-audiodev "pipewire,id=audio0"
	-device ich9-intel-hda
	-device "hda-duplex,audiodev=audio0"
	-device virtio-keyboard-pci
	-device virtio-mouse-pci
	-device virtio-rng-pci
	-drive "if=pflash,format=raw,unit=0,readonly=on,file=$firmware_code"
	-drive "if=pflash,format=raw,unit=1,file=$firmware_vars"
	-drive "if=virtio,format=qcow2,file=$disk"
	-drive "if=virtio,media=cdrom,readonly=on,file=$seed"
	-nic "user,model=virtio-net-pci,hostfwd=tcp::2222-:22"
	# Expose this checkout live without allowing the guest to modify the host
	-virtfs "local,path=$repo,mount_tag=dotfiles,security_model=none,readonly=on"
)
exec qemu-system-x86_64 "${args[@]}"
