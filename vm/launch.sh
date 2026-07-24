#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
firmware_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
firmware_vars="$state_dir/OVMF_VARS.4m.fd"
install_mode=false

case $# in
    0) ;;
    1)
        [[ $1 == --install ]] || {
            echo "usage: $0 [--install]" >&2
            exit 2
        }
        install_mode=true
        ;;
    *)
        echo "usage: $0 [--install]" >&2
        exit 2
        ;;
esac

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

# Ensure the host and persistent VM state are ready
if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    echo 'KVM is unavailable. Reboot, then check that /dev/kvm exists.' >&2
    exit 1
fi

if [[ ! -f $disk ]] && ! $install_mode; then
    echo "Missing VM disk. Run $0 --install to create and install the VM." >&2
    exit 1
fi
if $install_mode || [[ ! -f $firmware_vars ]]; then
    "$script_dir/create.sh"
fi
if $install_mode; then
    iso=$(find "$state_dir" -maxdepth 1 -name 'archlinux-*.iso' -print -quit)
    [[ -n $iso ]] || {
        echo 'Missing Arch installation ISO. Run vm/create.sh first.' >&2
        exit 1
    }
fi
[[ -r $firmware_code ]] || {
    echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
    exit 1
}

if $install_mode; then
    printf '%s\n' \
        'First boot:' \
        'pacman -Sy --needed git' \
        'git clone --depth 1 --branch dotfiles-wayland https://github.com/petobens/dotfiles.git /tmp/dotfiles' \
        'cd /tmp/dotfiles && ./setup/install_arch.sh' \
        'At the Target disk prompt, type: /dev/nvme0n1' \
        'After reboot: cd ~/git-repos/private/dotfiles && tmux' \
        'Inside tmux: ./setup/install.sh'
else
    printf '%s\n' \
        'Launching the installed guest without the Arch ISO.' \
        "For a clean installation, run: $0 --install"
fi

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
    -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22"
)
if $install_mode; then
    args+=(-drive "if=virtio,media=cdrom,readonly=on,file=$iso")
fi

section 'Launching Wayland VM'
exec qemu-system-x86_64 "${args[@]}"
