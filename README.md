# Arch Wayland Dotfiles

Dotfiles and installation scripts for an Arch Linux desktop using Hyprland.

## Stack

| Area            | Tools                                         |
| --------------- | --------------------------------------------- |
| Audio           | PipeWire, WirePlumber                         |
| Development     | Neovim                                        |
| Desktop         | Hyprland, Mako, Rofi, Waybar                  |
| Files and media | imv, Yazi                                     |
| Network         | Impala, NetworkManager                        |
| Session         | Grim, Hypridle, Hyprlock, Slurp, wl-clipboard |
| System          | systemd-boot, TLP, zram-generator             |
| Terminal        | Fish, Ghostty, Starship, tmux                 |

## Install Arch

Boot the official Arch installation USB in UEFI mode, connect to the internet,
and run:

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

The interactive installer erases the selected disk only after an exact
confirmation, installs the base system, and clones this branch into
`~/git-repos/private/dotfiles`.

### Test in a VM

Use the disposable QEMU VM to test the complete Arch and dotfiles installation
before running it on physical hardware:

```bash
./vm/vm.sh
```

See [vm/README.md](vm/README.md) for installation, reset, and SSH instructions.

## Install dotfiles

From the repository on the installed system, run:

```bash
cd ~/git-repos/private/dotfiles
./setup/install.sh
```

The script installs the package profiles, configures the system, and creates
the dotfile symlinks. Clone the Wayland branch to that location first when
using these dotfiles without the Arch installer.

## Repository

- `bin/`: command-line scripts
- `config/`: application, home, and development-tool configuration
- `hypr/`: Hyprland configuration and desktop helpers
- `nvim/`: Neovim configuration
- `setup/`: package profiles, installation, and symlink scripts
- `vm/`: disposable QEMU test machine

## Sync from master

After committing and pushing changes to `master`, update the Wayland branch
from its clean checkout with:

```bash
sync_dotfiles
```

The command fetches `origin/master` and merges it into `dotfiles-wayland`.
Non-conflicting changes are applied normally. Conflicts are resolved in favor
of the existing Wayland version after their paths and diffs are printed.
