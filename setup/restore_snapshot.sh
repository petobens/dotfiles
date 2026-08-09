#!/usr/bin/env bash

set -euo pipefail

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 3 ]] || {
    printf 'Usage: %s SNAPSHOT ROOT_PARTITION EFI_PARTITION\n' "$0" >&2
    exit 2
}

snapshot=$1
root_partition=$2
efi_partition=$3
target=/mnt

((EUID == 0)) || die 'run this script as root from the Arch USB'
[[ $snapshot =~ ^[1-9][0-9]*$ ]] || die 'snapshot must be a positive number'
[[ -b $root_partition ]] || die "$root_partition is not a block device"
[[ -b $efi_partition ]] || die "$efi_partition is not a block device"
[[ $(blkid -s TYPE -o value "$root_partition") == btrfs ]] ||
    die "$root_partition is not Btrfs"
[[ $(blkid -s TYPE -o value "$efi_partition") == vfat ]] ||
    die "$efi_partition is not FAT"
mountpoint -q "$target" && die "$target is already mounted"

cleanup() {
    if mountpoint -q "$target"; then
        umount -R "$target" || true
    fi
}
trap cleanup EXIT

mount -o subvolid=5 "$root_partition" "$target"
snapshot_path="$target/@snapshots/$snapshot/snapshot"
failed_name="@failed-$(date +%Y%m%d-%H%M%S)"
failed_root="$target/$failed_name"
btrfs subvolume show "$snapshot_path" > /dev/null 2>&1 ||
    die "snapshot $snapshot does not exist"
btrfs subvolume show "$target/@" > /dev/null 2>&1 ||
    die 'the @ root subvolume does not exist'
[[ ! -e $failed_root ]] || die "$failed_root already exists"

printf 'Snapshot: %s\nRoot:     %s\nEFI:      %s\n' \
    "$snapshot" "$root_partition" "$efi_partition"
read -r -p 'Type RESTORE to continue: ' confirmation
if [[ $confirmation != RESTORE ]]; then
    printf 'Rollback cancelled\n'
    exit 0
fi

mv "$target/@" "$failed_root"
if ! btrfs subvolume snapshot "$snapshot_path" "$target/@"; then
    mv "$failed_root" "$target/@"
    die 'could not restore the snapshot'
fi
btrfs subvolume set-default "$target/@"
umount "$target"

mount -o noatime,nodiscard "$root_partition" "$target"
mount --mkdir -o noatime,nodiscard,subvol=@home \
    "$root_partition" "$target/home"
mount --mkdir -o noatime,nodiscard,subvol=@pkg \
    "$root_partition" "$target/var/cache/pacman/pkg"
mount --mkdir -o noatime,nodiscard,subvol=@snapshots \
    "$root_partition" "$target/.snapshots"
mount --mkdir -o noatime,nodiscard,subvol=@var_log \
    "$root_partition" "$target/var/log"
mount --mkdir -o umask=0077 "$efi_partition" "$target/boot"
arch-chroot "$target" mkinitcpio -P
umount -R "$target"
trap - EXIT

printf 'Rollback complete. The previous root is preserved as %s\n' "$failed_name"
printf 'Remove the Arch USB and reboot\n'
