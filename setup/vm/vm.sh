#!/usr/bin/env bash
set -euo pipefail

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-wayland-vm
disk="$state_dir/wayland.qcow2"
firmware_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
firmware_vars="$state_dir/OVMF_VARS.4m.fd"
firmware_vars_template=/usr/share/edk2/x64/OVMF_VARS.4m.fd
iso_url=https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
checksum_url=https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt
iso=

usage() {
    cat << EOF
usage: $0 [launch|reset]

  launch  Launch the VM, preparing its first installation if needed (default)
  reset   Delete the VM, recreate it, and launch the Arch ISO
EOF
}

section() {
    printf '\033[1;34m\n-> %s\033[0m\n' "$1"
}

check_host() {
    command -v qemu-system-x86_64 > /dev/null || {
        echo 'Missing qemu-system-x86_64. Install qemu-desktop.' >&2
        exit 1
    }
    if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
        echo 'KVM is unavailable. Reboot, then check that /dev/kvm exists.' >&2
        exit 1
    fi
    [[ -r $firmware_code ]] || {
        echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
        exit 1
    }
}

prepare_install_media() {
    local checksum required_command

    for required_command in curl sha256sum awk; do
        command -v "$required_command" > /dev/null || {
            echo "Missing $required_command." >&2
            exit 1
        }
    done

    mkdir -p "$state_dir"
    section 'Preparing Arch ISO'
    checksum=$(curl --fail --location "$checksum_url" |
        awk '$2 == "archlinux-x86_64.iso" {print $1}')
    [[ -n $checksum ]] || {
        echo 'Could not find the Arch ISO checksum.' >&2
        exit 1
    }

    iso="$state_dir/archlinux-$checksum.iso"
    if [[ ! -f $iso ]] ||
        ! printf '%s  %s\n' "$checksum" "$iso" |
        sha256sum --check --status; then
        curl --fail --location --output "$iso.part" "$iso_url"
        printf '%s  %s\n' "$checksum" "$iso.part" |
            sha256sum --check --status
        mv "$iso.part" "$iso"
    fi
    printf '%s  %s\n' "$checksum" "$iso" | sha256sum --check

    shopt -s nullglob
    for old_iso in "$state_dir"/archlinux-*.iso; do
        [[ $old_iso == "$iso" ]] || rm -- "$old_iso"
    done
    shopt -u nullglob
}

initialize_state() {
    mkdir -p "$state_dir"
    if [[ ! -f $disk ]]; then
        command -v qemu-img > /dev/null || {
            echo 'Missing qemu-img. Install qemu-desktop.' >&2
            exit 1
        }
        section 'Creating disk'
        qemu-img create -f qcow2 "$disk" 96G
    fi
    if [[ ! -f $firmware_vars ]]; then
        [[ -r $firmware_vars_template ]] || {
            echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2
            exit 1
        }
        section 'Initializing firmware'
        cp "$firmware_vars_template" "$firmware_vars"
    fi
}

reset_state() {
    local -a old_state

    section 'Resetting VM'
    shopt -s nullglob
    old_state=(
        "$disk"
        "$firmware_vars"
        "$disk".*.bak
        "$firmware_vars".*.bak
    )
    rm -f -- "${old_state[@]}"
    shopt -u nullglob
}

launch_vm() {
    local install_mode=$1
    local args=(
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
        -device virtio-tablet-pci
        -device virtio-rng-pci
        -drive "if=pflash,format=raw,unit=0,readonly=on,file=$firmware_code"
        -drive "if=pflash,format=raw,unit=1,file=$firmware_vars"
        -drive "if=none,id=nvme0,format=qcow2,discard=unmap,detect-zeroes=unmap,file=$disk"
        -device "nvme,drive=nvme0,serial=dotfiles-wayland"
        -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22"
    )

    if $install_mode; then
        args+=(-drive "if=virtio,media=cdrom,readonly=on,file=$iso")
        printf '%s\n' \
            'Run inside the Arch ISO:' \
            'pacman -Sy --needed git' \
            'git clone --depth 1 --branch dotfiles-wayland https://github.com/petobens/dotfiles.git /tmp/dotfiles' \
            'cd /tmp/dotfiles && ./setup/install_arch.sh' \
            'Target disk: /dev/nvme0n1'
    fi

    section 'Launching VM'
    exec qemu-system-x86_64 "${args[@]}"
}

(($# <= 1)) || {
    usage >&2
    exit 2
}

action=${1:-launch}
install_mode=false
case $action in
    launch)
        ;;
    reset)
        install_mode=true
        ;;
    -h | --help)
        usage
        exit
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

check_host
if [[ $action == reset ]]; then
    prepare_install_media
    reset_state
elif [[ ! -f $disk ]]; then
    prepare_install_media
    install_mode=true
fi
initialize_state
launch_vm "$install_mode"
