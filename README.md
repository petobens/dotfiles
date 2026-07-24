# Arch Wayland Dotfiles

Dotfiles and installation scripts for an Arch Linux desktop using Hyprland.

## Desktop

| Role             | Tool                          |
| ---------------- | ----------------------------- |
| Compositor       | Hyprland                      |
| Bar              | Waybar                        |
| Launcher         | Rofi                          |
| Notifications    | Mako                          |
| Terminal         | Ghostty                       |
| Shell and prompt | Fish and Starship             |
| File manager     | Yazi                          |
| Image viewer     | imv                           |
| Editor           | Neovim                        |
| Multiplexer      | tmux                          |
| Audio            | PipeWire and WirePlumber      |
| Network          | NetworkManager and Impala     |
| Power management | TLP                           |
| Compressed swap  | zram-generator                |
| Lock and idle    | Hyprlock and Hypridle         |
| Screenshots      | Grim, Slurp, and wl-clipboard |
| Bootloader       | systemd-boot                  |

Package profiles under `setup/packages/` are divided by purpose:

| Profile        | Purpose                                          |
| -------------- | ------------------------------------------------ |
| `base`         | Command-line and system tools                    |
| `desktop`      | Wayland desktop and Intel hardware support       |
| `applications` | Desktop applications from Arch repositories      |
| `aur`          | Additional applications installed with Yay       |
| `development`  | Development, data, document, and QEMU host tools |

`setup/install_packages.sh` installs these profiles, then delegates system and
user configuration to `setup/post_install.sh`.

## Layout

- `bin/`: personal command-line scripts
- `config/`: application, desktop, home, and development-tool configuration
- `hypr/`: Hyprland configuration and desktop helper scripts
- `nvim/`: Neovim configuration
- `setup/`: package profiles, installer, and symlink script
- `vm/`: disposable QEMU test machine

Hyprland configuration is divided by responsibility under `hypr/conf/`. Its
helper commands live in `hypr/scripts/`.

## Install Arch

Boot the official Arch installation USB in UEFI mode, connect to the internet,
and fetch this branch in the live environment:

```bash
pacman -Sy --needed git
git clone \
    --depth 1 \
    --branch dotfiles-wayland \
    https://github.com/petobens/dotfiles.git \
    /tmp/dotfiles
cd /tmp/dotfiles
./setup/install_arch.sh
```

The interactive installer handles the disk layout, filesystems, `pacstrap`,
locale, timezone, hostname, users, services, systemd-boot, and both kernels.
On physical hardware, it defaults to hostname `x1-carbon`, a 1 GiB EFI
partition, a 60 GiB root partition, and an ext4 home partition using the
remaining space.

Virtualization is detected automatically. A VM defaults to hostname `arch-vm`,
a 1 GiB EFI partition, a 40 GiB root partition, and an ext4 home partition
using the remaining VM space. It otherwise uses the same repository clone and
handoff as the physical machine. The hostname, root size, and home size remain
editable in the prompts. Pass `--vm` or `--physical` to override environment
detection.

The VM's 96 GiB QCOW2 disk is sparse. This is its maximum guest-visible
capacity, not 96 GiB reserved on the host. The host file starts small and grows
as the guest writes data. VM resets permanently discard the previous disk and
firmware state while retaining the verified Arch ISO.

The selected disk is completely erased. The script rejects mounted disks,
shows the proposed layout, and continues only after its exact
`ERASE /dev/...` confirmation is entered. It does not support encryption,
dual boot, RAID, LVM, hibernation, or Secure Boot enrollment.

At the end, accept the default prompt to clone the Wayland branch into
`~/git-repos/private/dotfiles`. Inspect `/mnt/etc/fstab`, then reboot as
instructed.

## Install dotfiles

From a fresh Arch installation:

```bash
git clone \
    --branch dotfiles-wayland \
    https://github.com/petobens/dotfiles.git \
    ~/git-repos/private/dotfiles
cd ~/git-repos/private/dotfiles
tmux
./setup/install.sh
```

For scrollback, press `Ctrl+B`, release both keys, and then press `[`. Press
`q` to return to the live command.

The installer lets you choose packages, optional native TeX Live managed by
`tlmgr`, symlinks, or all three. It enables the required services and symlinks
the configuration into the home directory. Existing real files at symlink
destinations are backed up under
`~/.local/state/dotfiles-backup/`.

The optional LaTeX installation includes the headless Java runtime required by
`arara`. No Java runtime is installed when LaTeX is skipped.

For explicit component selection, `--all` installs packages and symlinks but
not LaTeX. Add `--latex` to include it:

```bash
./setup/install.sh --all
./setup/install.sh --all --latex
```

The installer sets Fish as the login shell. After entering the username and
password at the tty1 login prompt, that Fish login starts Hyprland
automatically.

Both the standard and LTS kernels, including their headers, are installed.
Choosing between them requires corresponding entries in the machine's
bootloader.

See `hypr/conf/monitors.lua` for monitor configuration.

## Sync from master

After committing and pushing changes to `master`, update the Wayland branch
from its clean checkout with:

```bash
sync_dotfiles
```

The command fetches `origin/master` and merges it into `dotfiles-wayland`.
Non-conflicting changes are applied normally. Conflicts are resolved in favor
of the existing Wayland version after their paths and diffs are printed.

## VM test

See [vm/README.md](vm/README.md) for the clean Arch VM test.
