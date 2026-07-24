# Arch Wayland VM

The VM boots the official Arch installation ISO with UEFI and a blank NVMe
disk. It uses the same interactive installer, partitioning, `pacstrap`,
systemd-boot, standard kernel, and LTS kernel setup as the future machine.
The package installer skips Firefox, OneDrive, OnlyOffice, Zoom, and Microsoft
Edge in the VM to avoid spending several gigabytes on applications that are
not needed for configuration testing.

Create and launch the first VM from the repository root:

```bash
./vm/create.sh
./vm/launch.sh
```

Commit and push the Wayland branch before testing. The first launch boots the
Arch ISO; fetch the branch exactly as on the physical machine:

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

The installer detects QEMU and defaults to hostname `arch-vm`, a 1 GiB EFI
partition, a 40 GiB root partition, and a home partition using the remaining
space. At the `Target disk` prompt, type the complete device path
`/dev/nvme0n1` and press Enter. Accept the default prompt to clone the Wayland
branch into the installed system.

After the installer finishes:

```bash
umount -R /mnt
reboot
```

After the installed system boots, log in as `pedro` and run the normal
interactive installer:

```bash
cd ~/git-repos/private/dotfiles
tmux
./setup/install.sh
sudo reboot
```

For scrollback, press `Ctrl+B`, release both keys, and then press `[`. Press
`q` to return to the live command.

The VM has an independent Git checkout, just like the physical machine. Push
host changes before testing them, then update the VM with:

```bash
cd ~/git-repos/private/dotfiles
git pull
```

If this installation replaced an earlier VM, remove the old VM host key:

```bash
ssh-keygen -R '[127.0.0.1]:2222'
```

After each clean VM installation, authorize the host's existing SSH key:

```bash
chmod 600 ~/.ssh/id_rsa
ssh-copy-id -F none \
    -i ~/.ssh/id_rsa.pub \
    -p 2222 pedro@127.0.0.1
ssh -F none \
    -i ~/.ssh/id_rsa \
    -p 2222 pedro@127.0.0.1
```

Enter the VM password for `ssh-copy-id`. This affects only the VM; the physical
installation does not install an authorized key. Unattended SSH also requires
the local private key to have no passphrase or to be loaded in `ssh-agent`.

On later boots, Fish starts Hyprland automatically after login. If the VM opens
directly into the graphical desktop, installation is complete.

To replace the VM with a blank disk and repeat the complete Arch installation:

```bash
./vm/reset.sh
./vm/launch.sh
```

`reset.sh` permanently removes the current disk, firmware state, and any old
backups before running `create.sh` automatically. It retains the verified Arch
ISO and downloads a newer one only when a new release is available.

QEMU grabs the mouse and keyboard while the pointer is over the VM display.
Press `Ctrl+Alt+G` to release or recapture input. The guest also has accelerated
graphics, PipeWire-backed audio, and a virtual entropy source.

State is stored in `~/.local/state/dotfiles-wayland-vm`. The virtual disk has a
96 GiB guest-visible capacity but is sparse. It does not reserve 96 GiB on the
host: the QCOW2 file starts small and grows as the guest writes data. Guest
TRIM requests are passed through so `fstrim.timer` can return unused blocks to
the host. The verified Arch ISO is retained between resets.
