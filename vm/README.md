# Arch Wayland VM

The VM uses QEMU/KVM with UEFI, the official Arch cloud image, cloud-init, and
a sparse qcow2 overlay. It copies this checkout into a clean guest, runs the
Wayland installer, and reboots.

Create and launch it from the repository root:

```bash
./vm/create.sh
./vm/launch.sh
```

Run `./vm/reset.sh` first if the existing guest was created with an older VM
configuration.

After provisioning, log in through the graphical console as `arch` with
password `wayland`. Hyprland starts automatically after authentication. SSH is
available at:

```bash
ssh -p 2222 arch@localhost
```

The guest installs the `base`, `desktop`, and `vm` package profiles. This is
enough to test Hyprland, Waybar, Ghostty, Fish, Starship, tmux, Yazi, and
Neovim after a reboot. Host applications and development packages are omitted
to keep the guest small.

State is stored in `~/.local/state/dotfiles-wayland-vm`. The virtual disk has a
sparse 16 GB capacity and consumes only the space written by the guest.

Use `./vm/reset.sh` to preserve the current overlay as a timestamped backup and
create a clean guest.
