# Arch Wayland Dotfiles

Dotfiles and installation scripts for an Arch Linux desktop using Hyprland.

## Stack

| Area            | Tools                                             |
| --------------- | ------------------------------------------------- |
| Audio           | PipeWire, WirePlumber                             |
| Development     | Neovim                                            |
| Desktop         | Hyprland, Mako, Rofi, Waybar                      |
| Files and media | imv, Yazi                                         |
| Network         | NetworkManager, nmtui                             |
| Session         | Grim, Hypridle, Hyprlock, Slurp, wl-clipboard     |
| System          | Btrfs, fwupd, Intel LPMD, scx_lavd, systemd-boot, |
|                 | thermald, TLP, UKI, zram                          |
| Terminal        | Fish, Ghostty, Starship, tmux                     |

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

Setup scripts resolve repository paths from their own location, so they can be
run from the repository root as above or directly from inside `setup/`, for
example as `./install_arch.sh`, `./vm.sh`, or `./symlinks.sh`.

The installer asks for the username, defaulting to `pedro`, and erases the
selected disk only after an exact confirmation. It creates a 1 GiB EFI
partition and a zstd-compressed Btrfs filesystem with `@`, `@home`, `@pkg`,
`@snapshots`, and `@var_log` subvolumes. This layout keeps home files, cached
packages, and logs out of future root snapshots and reserves `/.snapshots` for
future snapshot tooling. Snapshot tooling and disk encryption are not included.

Root and EFI use discoverable partitions, while `fstab` mounts the remaining
subvolumes. The installer creates default and fallback unified kernel images
for the standard and LTS kernels without enabling Secure Boot. It then clones
this branch into `~/git-repos/private/dotfiles`.

The installation uses Intel firmware for the target system and configures,
among other things, monthly Btrfs scrubs, weekly package-cache cleanup, zram,
and the `scx_lavd` CPU scheduler.

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

The helper restores personal credentials and repositories from a
`personal.json` file stored in cloud storage. Its supported keys are documented
in `setup/load_personal.sh`.

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
of the existing Wayland version after their paths and diffs are printed. If the
merge introduces new files, their paths are printed and the merge continues
only after explicit confirmation.
