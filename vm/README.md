# Arch Wayland VM

The VM boots the official Arch installation ISO with UEFI and a blank NVMe
disk. It uses the same interactive installer, partitioning, `pacstrap`,
systemd-boot, standard kernel, and LTS kernel setup as the future machine.

Create and launch the first VM from the repository root:

```bash
./vm/create.sh
./vm/launch.sh
```

The first launch boots the Arch ISO. Mount the read-only host checkout in the
live environment and run its installer:

```bash
mount -m -t 9p -o trans=virtio dotfiles /run/dotfiles
/run/dotfiles/setup/install-arch.sh
```

The installer detects QEMU and defaults to hostname `arch-vm`, a 1 GiB EFI
partition, a 40 GiB root partition, and a home partition using the remaining
space. At the `Target disk` prompt, type the complete device path
`/dev/nvme0n1` and press Enter. It skips the repository clone and configures
the read-only host checkout automatically.

After the installer finishes:

```bash
umount -R /mnt
reboot
```

After the installed system boots, log in as `pedro`. The checkout is available
at `~/git-repos/private/dotfiles`; run the normal interactive installer:

```bash
cd ~/git-repos/private/dotfiles
tmux
./setup/install.sh
sudo reboot
```

For scrollback, press `Ctrl+B`, release both keys, and then press `[`. Press
`q` to return to the live command.

Host edits are visible in the guest immediately. The guest cannot modify the
checkout. Applications may still need to reload their configuration.

Verify that systemd-boot exposes both kernels:

```bash
bootctl list
```

On later boots, Fish starts Hyprland automatically after login. If the VM opens
directly into the graphical desktop, installation is complete.

To replace the VM with a blank disk and repeat the complete Arch installation:

```bash
./vm/reset.sh
./vm/launch.sh
```

`reset.sh` runs `create.sh` automatically. It preserves the current disk and
firmware state as the only timestamped backup, removes older backups, and
downloads a newer Arch ISO when one is released.

QEMU grabs the mouse and keyboard while the pointer is over the VM display.
Press `Ctrl+Alt+G` to release or recapture input. The guest also has accelerated
graphics, PipeWire-backed audio, and a virtual entropy source.

State is stored in `~/.local/state/dotfiles-wayland-vm`. The virtual disk has a
96 GiB guest-visible capacity but is sparse. It does not reserve 96 GiB on the
host: the QCOW2 file starts small and grows as the guest writes data. Guest
TRIM requests are passed through so `fstrim.timer` can return unused blocks to
the host. The verified Arch ISO is retained between resets. The single VM
backup is also sparse, but its previously written data continues to consume
host space until a later reset replaces that backup.
