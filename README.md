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
| Lock and idle    | Hyprlock and Hypridle         |
| Screenshots      | Grim, Slurp, and wl-clipboard |
| Bootloader       | systemd-boot                  |

Package profiles under `setup/packages/` are divided by where they run and how
they are installed:

| Profile        | Purpose                                                    |
| -------------- | ---------------------------------------------------------- |
| `base`         | Command-line tools shared by physical and VM installations |
| `desktop`      | Wayland desktop shared by physical and VM installations    |
| `applications` | Physical-machine applications from Arch repositories       |
| `aur`          | Physical-machine applications installed with Yay           |
| `development`  | Physical-machine development tools                         |
| `host`         | Intel hardware support and QEMU host tools                 |
| `vm`           | QEMU guest integration                                     |

## Layout

- `bin/`: personal command-line scripts
- `config/`: application, desktop, home, and development-tool configuration
- `hypr/`: Hyprland configuration and desktop helper scripts
- `nvim/`: Neovim configuration
- `setup/`: package profiles, installer, and symlink script
- `vm/`: disposable QEMU test machine

Hyprland configuration is divided by responsibility under `hypr/conf/`. Its
helper commands live in `hypr/scripts/`.

## Install

From a fresh Arch installation:

```bash
git clone \
    --branch dotfiles-wayland \
    https://github.com/petobens/dotfiles.git \
    ~/git-repos/private/dotfiles-wayland
cd ~/git-repos/private/dotfiles-wayland
./setup/install.sh --all
```

The installer installs the host profiles, enables the required
services, and symlinks the configuration into the home directory. Existing
real files at symlink destinations are backed up under
`~/.local/state/dotfiles-backup/`.

The installer sets Fish as the login shell. After entering the username and
password at the tty1 login prompt, that Fish login starts Hyprland
automatically.

See `hypr/conf/monitors.lua` for monitor configuration.

## VM test

See [vm/README.md](vm/README.md) for the clean Arch VM test.
