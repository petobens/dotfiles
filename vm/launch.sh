#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
firmware_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
firmware_vars="$state_dir/OVMF_VARS.4m.fd"

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

# Ensure the host and persistent VM state are ready
if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    echo 'KVM is unavailable. Reboot, then check that /dev/kvm exists.' >&2
    exit 1
fi

[[ -f $disk && -f $firmware_vars ]] || "$script_dir/create.sh"
iso=$(find "$state_dir" -maxdepth 1 -name 'archlinux-*.iso' -print -quit)
[[ -n $iso ]] || {
    "$script_dir/create.sh"
    iso=$(find "$state_dir" -maxdepth 1 -name 'archlinux-*.iso' -print -quit)
}
[[ -r $firmware_code ]] || {
    echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
    exit 1
}

printf '%s\n' \
    'First boot:' \
    'pacman -Sy --needed git' \
    'git clone --depth 1 --branch dotfiles-wayland https://github.com/petobens/dotfiles.git /tmp/dotfiles' \
    'cd /tmp/dotfiles && ./setup/install_arch.sh' \
    'At the Target disk prompt, type: /dev/nvme0n1' \
    'After reboot: cd ~/git-repos/private/dotfiles && tmux' \
    'Inside tmux: ./setup/install.sh' \
    'If Hyprland starts, the guest is already installed and no setup is needed.'

# Match the intended physical machine while keeping QEMU integration local
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
    -drive "if=none,id=nvme0,format=qcow2,discard=unmap,detect-zeroes=unmap,file=$disk"
    -device "nvme,drive=nvme0,serial=dotfiles-wayland"
    -drive "if=virtio,media=cdrom,readonly=on,file=$iso"
    -nic "user,model=virtio-net-pci,hostfwd=tcp::2222-:22"
)

section 'Launching Wayland VM'
exec qemu-system-x86_64 "${args[@]}"
