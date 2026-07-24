#!/usr/bin/env bash
set -euo pipefail

current_step=0
total_steps=12

section() {
    ((current_step += 1))
    printf '\033[1;34m\n-> [%d/%d] %s...\033[0m\n' \
        "$current_step" "$total_steps" "$1"
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

mode=auto
virtualization=
while (($#)); do
    case $1 in
        --vm)
            [[ $mode == auto || $mode == vm ]] || die 'Choose only one installation mode'
            mode=vm
            ;;
        --physical)
            [[ $mode == auto || $mode == physical ]] || die 'Choose only one installation mode'
            mode=physical
            ;;
        --help)
            printf '%s\n' \
                'Usage: install_arch.sh [--vm|--physical]' \
                '' \
                'Interactively installs Arch Linux on one empty UEFI disk.' \
                'The selected disk is completely erased.' \
                '' \
                'Installation mode is detected automatically unless overridden.'
            exit
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

[[ $EUID == 0 ]] || die 'Run this script as root from the Arch installation ISO'
[[ -d /sys/firmware/efi/efivars ]] || die 'Boot the installation ISO in UEFI mode'
mountpoint -q /mnt && die 'Unmount the existing installation from /mnt first'

for command in arch-chroot curl genfstab pacstrap sfdisk systemd-detect-virt; do
    command -v "$command" > /dev/null || die "Missing $command; use the official Arch installation ISO"
done

if [[ $mode == auto ]]; then
    if virtualization=$(systemd-detect-virt --vm 2> /dev/null); then
        mode=vm
    else
        mode=physical
        virtualization=
    fi
fi

if [[ $mode == vm ]]; then
    default_hostname=arch-vm
    default_root_gib=40
    default_home_gib=remaining
else
    default_hostname=x1-carbon
    default_root_gib=60
    default_home_gib=remaining
fi

printf 'Installation mode: %s%s\n' \
    "$mode" "${virtualization:+ ($virtualization)}"

section 'Checking network and clock'
curl --fail --location --silent --show-error --output /dev/null https://archlinux.org ||
    die 'Connect to Ethernet or Wi-Fi before continuing'
timedatectl set-ntp true

section 'Checking installation settings'
read -r -p 'Keyboard layout [us]: ' keymap
keymap=${keymap:-us}
localectl list-keymaps | grep -Fx "$keymap" > /dev/null || die "Unknown keyboard layout: $keymap"
loadkeys "$keymap"

read -r -p 'Timezone [America/Argentina/Buenos_Aires]: ' timezone
timezone=${timezone:-America/Argentina/Buenos_Aires}
[[ -e /usr/share/zoneinfo/$timezone ]] || die "Unknown timezone: $timezone"

read -r -p "Hostname [$default_hostname]: " hostname
hostname=${hostname:-$default_hostname}
[[ $hostname =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] ||
    die 'Use a lowercase hostname containing only letters, numbers, and hyphens'

read -r -p 'Username [pedro]: ' username
username=${username:-pedro}
[[ $username =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username: $username"

read -r -p "Root partition size in GiB [$default_root_gib]: " root_gib
root_gib=${root_gib:-$default_root_gib}
[[ $root_gib =~ ^[0-9]+$ && $root_gib -ge 10 ]] ||
    die 'Root size must be an integer of at least 10 GiB'
if ((root_gib < 20)); then
    printf 'Warning: less than 20 GiB may be too small for the full package profile\n'
fi

read -r -p "Home partition size in GiB or 'remaining' [$default_home_gib]: " home_gib
home_gib=${home_gib:-$default_home_gib}
[[ $home_gib == remaining || $home_gib =~ ^[0-9]+$ && $home_gib -ge 10 ]] ||
    die "Home size must be an integer of at least 10 GiB or 'remaining'"

section 'Selecting the installation disk'
lsblk -dp -o NAME,SIZE,MODEL,TRAN,RM,TYPE
read -r -p 'Target disk (enter the full path, for example /dev/nvme0n1): ' disk
[[ -b $disk && $(lsblk -dnro TYPE "$disk") == disk ]] || die "Not a whole disk: $disk"
if lsblk -nrpo MOUNTPOINTS "$disk" | grep '[^[:space:]]' > /dev/null; then
    die "$disk or one of its partitions is mounted"
fi

disk_bytes=$(blockdev --getsize64 "$disk")
if [[ $home_gib == remaining ]]; then
    minimum_bytes=$(((root_gib + 2) * 1024 * 1024 * 1024))
    home_description='remaining space'
    home_partition_spec='type=L, name="Home"'
else
    minimum_bytes=$(((root_gib + home_gib + 2) * 1024 * 1024 * 1024))
    home_description="$home_gib GiB"
    home_partition_spec="size=${home_gib}GiB, type=L, name=\"Home\""
fi
((disk_bytes >= minimum_bytes)) ||
    die "$disk is too small for the selected EFI, root, and home partitions"

printf '\n%s will be completely erased and replaced with:\n' "$disk"
printf '  EFI:   1 GiB, FAT32, mounted at /boot\n'
printf '  Root:  %s GiB, ext4\n' "$root_gib"
printf '  Home:  %s, ext4\n\n' "$home_description"
read -r -p "Type 'ERASE $disk' to continue: " confirmation
[[ $confirmation == "ERASE $disk" ]] || die 'Installation cancelled'

if [[ $disk =~ [0-9]$ ]]; then
    partition_prefix=${disk}p
else
    partition_prefix=$disk
fi
efi_partition=${partition_prefix}1
root_partition=${partition_prefix}2
home_partition=${partition_prefix}3

section 'Partitioning and formatting'
sfdisk --lock --wipe always --wipe-partitions always "$disk" << EOF
label: gpt
size=1GiB, type=U, name="EFI"
size=${root_gib}GiB, type=L, name="Arch root"
$home_partition_spec
EOF
udevadm settle

mkfs.fat -F 32 "$efi_partition"
mkfs.ext4 -F "$root_partition"
mkfs.ext4 -F "$home_partition"

section 'Mounting filesystems'
mount "$root_partition" /mnt
mount --mkdir -o umask=0077 "$efi_partition" /mnt/boot
mount --mkdir "$home_partition" /mnt/home
findmnt /mnt

section 'Installing the base system'
pacstrap -K /mnt \
    base \
    git \
    intel-ucode \
    linux \
    linux-firmware \
    linux-lts \
    networkmanager \
    sudo \
    tmux \
    vim
genfstab -U /mnt > /mnt/etc/fstab

section 'Configuring locale and system identity'
ln -sf "/usr/share/zoneinfo/$timezone" /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i -E \
    -e 's/^# ?(en_US\.UTF-8 UTF-8)/\1/' \
    -e 's/^# ?(es_AR\.UTF-8 UTF-8)/\1/' \
    /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf 'LANG=en_US.UTF-8\n' > /mnt/etc/locale.conf
printf 'KEYMAP=%s\n' "$keymap" > /mnt/etc/vconsole.conf
printf '%s\n' "$hostname" > /mnt/etc/hostname
printf '%s\n' \
    '127.0.0.1 localhost' \
    '::1 localhost' \
    "127.0.1.1 $hostname.localdomain $hostname" > /mnt/etc/hosts

section 'Creating users'
printf 'Set the root password\n'
arch-chroot /mnt passwd
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
printf 'Set the password for %s\n' "$username"
arch-chroot /mnt passwd "$username"
install -Dm440 /dev/stdin /mnt/etc/sudoers.d/10-wheel << 'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF

section 'Enabling system services'
arch-chroot /mnt systemctl enable \
    NetworkManager \
    fstrim.timer \
    systemd-boot-update.service \
    systemd-timesyncd

section 'Installing systemd-boot'
arch-chroot -S /mnt bootctl install
root_uuid=$(blkid -s UUID -o value "$root_partition")
install -d /mnt/boot/loader/entries
install -Dm644 /dev/stdin /mnt/boot/loader/loader.conf << 'EOF'
default arch.conf
timeout 3
console-mode keep
editor no
EOF
install -Dm644 /dev/stdin /mnt/boot/loader/entries/arch.conf << EOF
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=$root_uuid rw quiet
EOF
install -Dm644 /dev/stdin /mnt/boot/loader/entries/arch-lts.conf << EOF
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /intel-ucode.img
initrd /initramfs-linux-lts.img
options root=UUID=$root_uuid rw
EOF

section 'Preparing the dotfiles handoff'
checkout="/home/$username/git-repos/private/dotfiles"
read -r -p 'Clone the Wayland dotfiles into the installed system? [Y/n] ' clone_dotfiles
if [[ ! $clone_dotfiles =~ ^[nN]$ ]]; then
    arch-chroot /mnt install -d -o "$username" -g "$username" \
        "$(dirname "$checkout")"
    arch-chroot /mnt runuser -u "$username" -- \
        git clone --branch dotfiles-wayland \
        https://github.com/petobens/dotfiles.git "$checkout"
    handoff="After login: cd $checkout, start tmux, then run ./setup/install.sh"
else
    handoff='After login, prepare the checkout, start tmux, then run ./setup/install.sh'
fi

section 'Installation complete'
printf '%s\n' \
    'Inspect /mnt/etc/fstab and the messages above before rebooting.' \
    'Then run: umount -R /mnt && reboot' \
    "$handoff"
