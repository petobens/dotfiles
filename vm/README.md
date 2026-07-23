# Arch Wayland VM

The VM uses QEMU/KVM with UEFI, the official Arch cloud image, cloud-init, and
a sparse qcow2 overlay. Cloud-init creates the `pedro` user and copies this
checkout to the same path used on the physical machine. Installation is then
run interactively through the same installer.

For the first VM, create and launch it from the repository root:

```bash
./vm/create.sh
./vm/launch.sh
```

To replace an existing VM with a clean guest, run:

```bash
./vm/reset.sh
./vm/launch.sh
```

`reset.sh` runs `create.sh` automatically, so do not run both. It preserves the
current overlay as the only timestamped backup, then removes older backups and
unreferenced cloud base images. A reset is required after changes to cloud-init
settings or virtual disk capacity.

On the first boot of a new or reset guest, log in through the graphical console
as `pedro` with password `wayland`. Wait for cloud-init to finish copying the
checkout:

```bash
sudo cloud-init status --wait
```

When it reports `status: done`, start the installer:

```bash
cd ~/git-repos/private/dotfiles
./setup/install.sh
```

Choose packages, optional native TeX Live managed by `tlmgr`, symlinks, or all
three when prompted. The installation uses the same profiles, AUR packages,
tools, services, and symlinks as the physical machine. It includes the QEMU
host tooling, so nested virtualization is available when the physical host
supports it. Reboot when installation finishes; Hyprland starts automatically
after authentication.

```bash
sudo reboot
```

On later boots, Fish starts Hyprland automatically after login. If the VM opens
directly into the graphical desktop, installation is already complete and
there is nothing else to run.

QEMU grabs the mouse and keyboard while the pointer is over the VM display, so
desktop shortcuts are sent to the guest. Press `Ctrl+Alt+G` to release or
recapture input. The guest also has accelerated graphics, PipeWire-backed
audio, and a virtual entropy source.

State is stored in `~/.local/state/dotfiles-wayland-vm`. The virtual disk has a
sparse 64 GB capacity and consumes only the space written by the guest.

The cloud image replaces the physical Arch bootstrap, and QEMU provides
virtual hardware. From the interactive dotfiles installation onward, the VM
and physical machine follow the same path.
