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

Package profiles under `setup/packages/` are divided by purpose:

| Profile        | Purpose                                          |
| -------------- | ------------------------------------------------ |
| `base`         | Command-line and system tools                    |
| `desktop`      | Wayland desktop and Intel hardware support       |
| `applications` | Desktop applications from Arch repositories      |
| `aur`          | Additional applications installed with Yay       |
| `development`  | Development, data, document, and QEMU host tools |

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
    ~/git-repos/private/dotfiles
cd ~/git-repos/private/dotfiles
./setup/install.sh
```

The installer lets you choose packages, optional native TeX Live managed by
`tlmgr`, symlinks, or all three. It enables the required services and symlinks
the configuration into the home directory. Existing real files at symlink
destinations are backed up under
`~/.local/state/dotfiles-backup/`.

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

## VM test

See [vm/README.md](vm/README.md) for the clean Arch VM test.
