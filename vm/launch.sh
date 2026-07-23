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
	'Existing VM state is reused; only a new or reset guest is provisioned.' \
	'On first boot, run "sudo journalctl -fu cloud-final" or wait for its reboot.'

args=(
	-name dotfiles-wayland
	-enable-kvm
	-machine "q35,accel=kvm"
	-cpu host
	-smp 4
	-m 4096
	-device virtio-vga-gl
	-display "gtk,gl=on,grab-on-hover=on,zoom-to-fit=on"
	-device virtio-keyboard-pci
	-device virtio-mouse-pci
	-drive "if=pflash,format=raw,unit=0,readonly=on,file=$firmware_code"
	-drive "if=pflash,format=raw,unit=1,file=$firmware_vars"
	-drive "if=virtio,format=qcow2,file=$disk"
	-drive "if=virtio,media=cdrom,readonly=on,file=$seed"
	-nic "user,model=virtio-net-pci,hostfwd=tcp::2222-:22"
	# Provision from this checkout without allowing the guest to modify it
	-virtfs "local,path=$repo,mount_tag=dotfiles,security_model=none,readonly=on"
	-device virtio-serial-pci
	-chardev "spicevmc,id=vdagent,name=vdagent"
	-device "virtserialport,chardev=vdagent,name=com.redhat.spice.0"
)
exec qemu-system-x86_64 "${args[@]}"
