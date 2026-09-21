# Arch Wayland Dotfiles

Dotfiles and installation scripts for an Arch Linux desktop using Hyprland.

![Hyprland desktop with Neovim, tmux, Yazi, and audio controls][desktop]

[desktop]: docs/screenshots/desktop.png

## Stack

| Area | Tools |
| --- | --- |
| Audio | PipeWire, WirePlumber |
| Development | Neovim |
| Desktop | Hyprland, Mako, Quickshell, Rofi, Voxtype, Waybar |
| Files and media | imv, Yazi |
| Network | NetworkManager, nmtui |
| Session | cliphist, Hypridle, Hyprlock, Hyprshot, Slurp, wf-recorder, wl-clipboard |
| System | Btrfs, fwupd, Intel LPMD, scx_lavd, systemd-boot, thermald, TLP, UKI, zram |
| Terminal | Fish, Ghostty, tmux |

## Install Arch

Read our [installation guide](docs/installation.md) for hardware assumptions,
USB preparation, installer details, verification, and recovery. The installer
erases the selected disk after confirmation and uses Btrfs with systemd-boot;
disk encryption and Secure Boot are not configured.

Boot the official Arch installation USB in UEFI mode, connect to the internet,
and run:

```bash
pacman -Sy --needed git tmux
tmux
git clone --depth 1 https://github.com/petobens/dotfiles.git /tmp/dotfiles
cd /tmp/dotfiles
./setup/install_arch.sh
```

The installer prompts for the target disk and user settings, then installs
Arch and clones this branch into `~/git-repos/private/dotfiles`.

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

Verify the finished installation after rebooting with:

```bash
system_report
```

Use `system_report --sudo` to include protected boot, Snapper, firewall, and
SSH checks. Run `system_report --help` for all options.

## Repository

- `bin/`: command-line scripts
- `config/`: application, home, and development-tool configuration
- `docs/`: installation, verification, recovery, and desktop screenshots
- `hypr/`: Hyprland configuration and desktop helpers
- `nvim/`: Neovim configuration
- `setup/`: package lists, installation, sync and symlink scripts, udev rules,
  and the disposable QEMU test machine
- `typst/`: reusable local document packages and templates
