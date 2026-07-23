# Arch Wayland VM

The VM uses QEMU/KVM with UEFI, the official Arch cloud image, cloud-init, and
a sparse qcow2 overlay. It copies this checkout into a clean guest, runs the
Wayland installer, links the installed configuration to a read-only host
share, and reboots.

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

QEMU grabs the mouse and keyboard while the pointer is over the VM display, so
desktop shortcuts are sent to the guest. Press `Ctrl+Alt+G` to release or
recapture input.

Host changes under `hypr/` are immediately visible through the guest's
configuration symlink. Reload Hyprland to apply configuration changes:

```bash
hyprctl reload
```

The guest installs the `base`, `desktop`, and `vm` package profiles. This is
enough to test Hyprland, Waybar, Ghostty, Fish, Starship, tmux, Yazi, and
Neovim after a reboot. Host applications and development packages are omitted
to keep the guest small.

State is stored in `~/.local/state/dotfiles-wayland-vm`. The virtual disk has a
sparse 16 GB capacity and consumes only the space written by the guest.

Use `./vm/reset.sh` to preserve the current overlay as a timestamped backup and
create a clean guest.
