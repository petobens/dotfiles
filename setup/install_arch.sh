#!/usr/bin/env bash
set -euo pipefail

current_step=0
total_steps=13

section() {
    ((current_step += 1))
    printf '\033[1;34m\n-> [%d/%d] %s...\033[0m\n' \
        "$current_step" "$total_steps" "$1"
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

(($# == 0)) || die 'This script does not accept arguments'
[[ $EUID == 0 ]] || die 'Run this script as root from the Arch installation ISO'
[[ -d /sys/firmware/efi/efivars ]] || die 'Boot the installation ISO in UEFI mode'
mountpoint -q /mnt && die 'Unmount the existing installation from /mnt first'

for command in arch-chroot blkid btrfs curl mkfs.btrfs pacstrap sfdisk \
    systemd-detect-virt; do
    command -v "$command" > /dev/null || die "Missing $command; use the official Arch installation ISO"
done

if virtualization=$(systemd-detect-virt --vm 2> /dev/null); then
    mode=vm
else
    mode=physical
    virtualization=
fi

if [[ $mode == vm ]]; then
    default_hostname=arch-vm
else
    default_hostname=x1-carbon
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

section 'Selecting the installation disk'
lsblk -dp -o NAME,SIZE,MODEL,TRAN,RM,TYPE
default_disk=$(
    largest=0
    while read -r candidate size type removable; do
        [[ $type == disk && $removable == 0 ]] || continue
        if lsblk -nrpo MOUNTPOINTS "$candidate" |
            grep -q '[^[:space:]]'; then
            continue
        fi
        if ((size > largest)); then
            largest=$size
            disk=$candidate
        fi
    done < <(lsblk -bdpno NAME,SIZE,TYPE,RM)
    printf '%s\n' "${disk:-}"
)
[[ -n $default_disk ]] || die 'No unmounted, non-removable whole disks found'
read -r -p "Target disk [$default_disk]: " disk
disk=${disk:-$default_disk}
[[ -b $disk && $(lsblk -dnro TYPE "$disk") == disk ]] || die "Not a whole disk: $disk"
if lsblk -nrpo MOUNTPOINTS "$disk" | grep '[^[:space:]]' > /dev/null; then
    die "$disk or one of its partitions is mounted"
fi

printf '\n%s will be completely erased and replaced with:\n' "$disk"
printf '  EFI:   1 GiB, FAT32, mounted at /boot\n'
printf '  Root:  remaining space, Btrfs with zstd compression\n\n'
read -r -p "Type 'ERASE $disk' to continue: " confirmation
[[ $confirmation == "ERASE $disk" ]] || die 'Installation cancelled'

if [[ $disk =~ [0-9]$ ]]; then
    partition_prefix=${disk}p
else
    partition_prefix=$disk
fi
efi_partition=${partition_prefix}1
root_partition=${partition_prefix}2

section 'Partitioning and formatting'
sfdisk --lock --wipe always --wipe-partitions always "$disk" << EOF
label: gpt
size=1GiB, type=U, name="EFI"
type="Linux root (x86-64)", name="Arch root"
EOF
udevadm settle

mkfs.fat -F 32 "$efi_partition"
mkfs.btrfs -f "$root_partition"

section 'Mounting filesystems'
mount "$root_partition" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@var_log
for subvolume in @ @home @pkg @var_log; do
    btrfs property set "/mnt/$subvolume" compression zstd
done
btrfs subvolume set-default /mnt/@
umount /mnt
mount -o noatime,nodiscard "$root_partition" /mnt
mount --mkdir -o noatime,nodiscard,subvol=@home "$root_partition" /mnt/home
mount --mkdir -o noatime,nodiscard,subvol=@pkg \
    "$root_partition" /mnt/var/cache/pacman/pkg
mount --mkdir -o noatime,nodiscard,subvol=@var_log "$root_partition" /mnt/var/log
mount --mkdir -o umask=0077 "$efi_partition" /mnt/boot
findmnt /mnt

section 'Installing the base system'
pacstrap -K /mnt \
    base \
    btrfs-progs \
    git \
    intel-ucode \
    linux \
    linux-firmware-intel \
    linux-lts \
    networkmanager \
    sudo \
    systemd-ukify \
    terminus-font \
    tmux \
    vim

section 'Configuring filesystem mounts'
root_uuid=$(blkid -s UUID -o value "$root_partition")
printf '%s\n' \
    "UUID=$root_uuid /home btrfs noatime,nodiscard,subvol=@home 0 0" \
    "UUID=$root_uuid /var/cache/pacman/pkg btrfs noatime,nodiscard,subvol=@pkg 0 0" \
    "UUID=$root_uuid /var/log btrfs noatime,nodiscard,subvol=@var_log 0 0" \
    > /mnt/etc/fstab

section 'Configuring locale and system identity'
ln -sf "/usr/share/zoneinfo/$timezone" /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i -E \
    -e 's/^# ?(en_US\.UTF-8 UTF-8)/\1/' \
    -e 's/^# ?(es_AR\.UTF-8 UTF-8)/\1/' \
    /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf 'LANG=en_US.UTF-8\n' > /mnt/etc/locale.conf
printf 'KEYMAP=%s\nFONT=ter-132n\n' "$keymap" > /mnt/etc/vconsole.conf
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
    btrfs-scrub@-.timer \
    fstrim.timer \
    NetworkManager \
    systemd-boot-update.service \
    systemd-timesyncd

section 'Installing unified kernel images'
arch-chroot -S /mnt bootctl install
install -Dm644 /dev/stdin \
    /mnt/etc/mkinitcpio.conf.d/10-systemd.conf << 'EOF'
HOOKS=(
    base systemd autodetect microcode modconf kms keyboard
    sd-vconsole block filesystems
)
EOF
printf 'rootflags=noatime,nodiscard rw quiet\n' > /mnt/etc/kernel/cmdline
sed -i -E \
    -e "s|^PRESETS=.*|PRESETS=('default' 'fallback')|" \
    -e 's|^default_image=|#default_image=|' \
    -e 's|^#default_uki=.*|default_uki="/boot/EFI/Linux/arch-linux.efi"|' \
    -e 's|^fallback_image=|#fallback_image=|' \
    -e 's|^#fallback_uki=.*|fallback_uki="/boot/EFI/Linux/arch-linux-fallback.efi"|' \
    /mnt/etc/mkinitcpio.d/linux.preset
sed -i -E \
    -e "s|^PRESETS=.*|PRESETS=('default')|" \
    -e 's|^default_image=|#default_image=|' \
    -e 's|^#default_uki=.*|default_uki="/boot/EFI/Linux/arch-linux-lts.efi"|' \
    /mnt/etc/mkinitcpio.d/linux-lts.preset
install -Dm644 /dev/stdin /mnt/boot/loader/loader.conf << 'EOF'
default arch-linux.efi
timeout 3
console-mode keep
editor yes
EOF
rm -f /mnt/boot/initramfs-linux*.img
arch-chroot /mnt mkinitcpio -P

section 'Cloning the Wayland dotfiles'
checkout="/home/$username/git-repos/private/dotfiles"
arch-chroot /mnt install -d -o "$username" -g "$username" \
    "$(dirname "$checkout")"
arch-chroot /mnt runuser -u "$username" -- \
    git clone --branch dotfiles-wayland \
    https://github.com/petobens/dotfiles.git "$checkout"

section 'Installation complete'
printf '%s\n' \
    'Run: umount -R /mnt && reboot' \
    "After login: cd $checkout, start tmux, then run ./setup/install.sh"
