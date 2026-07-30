# Arch Wayland Dotfiles

Dotfiles and installation scripts for an Arch Linux desktop using Hyprland.

## Stack

| Area            | Tools                                                |
| --------------- | ---------------------------------------------------- |
| Audio           | PipeWire, WirePlumber                                |
| Development     | Neovim                                               |
| Desktop         | Hyprland, Mako, Rofi, Waybar                         |
| Files and media | imv, Yazi                                            |
| Network         | NetworkManager, nmtui                                |
| Session         | Grim, Hypridle, Hyprlock, Slurp, wl-clipboard        |
| System          | Btrfs, fwupd, Intel LPMD, scx_lavd, systemd-boot,    |
|                 | thermald, TLP, UKI, zram                             |
| Terminal        | Fish, Ghostty, Starship, tmux                        |

## Install Arch

Boot the official Arch installation USB in UEFI mode, connect to the internet,
and run:

```bash
pacman -Syu --needed git tmux
tmux
git clone \
    --depth 1 \
    --branch dotfiles-wayland \
    https://github.com/petobens/dotfiles.git \
    /tmp/dotfiles
cd /tmp/dotfiles
./setup/install_arch.sh
```

The installer asks for the normal username, defaulting to `pedro`. It erases
the selected disk only after an exact confirmation. It creates a 1 GiB EFI
partition and a zstd-compressed Btrfs filesystem with separate `@` and `@home`
subvolumes, plus `@var_log` and `@pkg` so future root snapshots exclude logs
and cached packages. Discoverable partitions mount root and the EFI partition;
`fstab` mounts the remaining subvolumes. The installer also creates default and
fallback unified kernel images for both the standard and LTS kernels, then
clones this branch into `~/git-repos/private/dotfiles`.

Snapshot tooling, disk encryption, and Secure Boot are intentionally omitted.
The flat subvolume layout leaves room to add root snapshots later without
including `/home`, logs, or cached packages.

The base install uses Intel-specific firmware for the target laptop. The
installation also configures monthly Btrfs scrubs, weekly package-cache
cleanup, zram, and the `scx_lavd` CPU scheduler.

After installation, unmount before rebooting:

```bash
umount -R /mnt
reboot
```

### Test in a VM

On an Arch host, install QEMU and OVMF:

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf
```

Then use the disposable VM to test the complete Arch and dotfiles installation
before running it on physical hardware:

```bash
./setup/vm/vm.sh
```

See [setup/vm/README.md](setup/vm/README.md) for installation, reset, and SSH
instructions.

## Install dotfiles

From the repository on the installed system, run:

```bash
cd ~/git-repos/private/dotfiles
./setup/install.sh
sudo reboot
```

The script installs the packages, applies the system and application defaults,
and creates the dotfile symlinks.

After rebooting into Hyprland, finish the personal setup:

```bash
cd ~/git-repos/private/dotfiles
./setup/finish_setup.sh
```

The helper synchronizes OneDrive and restores the personal credentials and
repositories configured in `~/OneDrive/programming/arch/personal.json`. Its
keys are documented in `setup/load_personal.sh`.

Setup scripts resolve repository paths from their own location. They can also
be run from inside `setup/` as `./install.sh`, `./symlinks.sh`, or
`./sync_dotfiles`.

## Repository

- `bin/`: command-line scripts
- `config/`: application, home, and development-tool configuration
- `hypr/`: Hyprland configuration and desktop helpers
- `nvim/`: Neovim configuration
- `setup/`: package lists, installation, sync and symlink scripts, and the
  disposable QEMU test machine

## Sync from master

After committing and pushing changes to `master`, update the Wayland branch
from its clean checkout with:

```bash
./setup/sync_dotfiles
```

The command fetches `origin/master` and merges it into `dotfiles-wayland`.
Non-conflicting changes are applied normally. Conflicts are resolved in favor
of the existing Wayland version after their paths and diffs are printed.
