# Arch Wayland VM

This disposable QEMU VM tests the same interactive Arch installer and dotfiles
workflow used on physical hardware. It boots with UEFI, a virtual NVMe disk,
accelerated graphics, PipeWire audio, and SSH forwarding on host port 2222.

## Host requirements

On an Arch host, install QEMU and the OVMF firmware:

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf
```

Enable hardware virtualization in the firmware settings. After booting the
host, confirm that KVM is available to the current user:

```bash
test -r /dev/kvm && test -w /dev/kvm && echo 'KVM ready'
```

The VM script checks these requirements before creating or launching a VM.

## First installation

Commit and push the Wayland branch, then run from the repository root:

```bash
./setup/vm/vm.sh
```

When no VM disk exists, the command downloads and verifies the current Arch
ISO, creates the VM state, and boots with the ISO attached. In the Arch live
environment, run:

```bash
pacman -Sy --needed git tmux
tmux
git clone \
    --depth 1 \
    --branch dotfiles-wayland \
    https://github.com/petobens/dotfiles.git \
    /tmp/dotfiles
cd /tmp/dotfiles
./setup/install_arch.sh
```

Use `Ctrl-b [` to enter tmux scrollback, then `q` to leave it.

At the `Target disk` prompt, press Enter to accept `/dev/nvme0n1`. The VM
defaults to hostname `arch-vm`, a 1 GiB EFI partition, and a Btrfs root using
the remaining space. The filesystem uses zstd compression with separate `@`,
`@home`, `@var_log`, and `@pkg` subvolumes. The examples below use username
`pedro`; substitute the selected username when different.

After the installer finishes:

```bash
umount -R /mnt
reboot
```

Log in with the username selected during installation and complete the dotfiles
installation:

```bash
cd ~/git-repos/private/dotfiles
tmux
./setup/install.sh
sudo reboot
```

Later invocations of `./setup/vm/vm.sh` detect the existing disk and launch
without attaching the cached ISO.

## Reset

To discard the VM and repeat the complete installation:

```bash
./setup/vm/vm.sh reset
```

The command verifies the ISO before deleting the disk, firmware state, and old
backups. It then creates a blank VM and boots the installer. The verified ISO
is retained between resets and replaced when a new Arch release is available.

## SSH and updates

After a reset, remove the previous host key and authorize the host's existing
SSH key:

```bash
username=pedro
ssh-keygen -R '[127.0.0.1]:2222'
ssh-copy-id -F none \
    -i ~/.ssh/id_rsa.pub \
    -p 2222 "$username@127.0.0.1"
ssh -F none -p 2222 "$username@127.0.0.1"
```

The forwarded port listens only on the host's loopback interface. Unattended
SSH requires a key without a passphrase or one loaded in `ssh-agent`.

The VM has an independent Git checkout. Push host changes, then update it with:

```bash
cd ~/git-repos/private/dotfiles
git pull
```

## Details

State is stored in `~/.local/state/dotfiles-wayland-vm`. The 96 GiB QCOW2 disk
is sparse and grows as the guest writes data. When the state directory is on
Btrfs, QEMU disables copy-on-write for newly created disks. Guest TRIM can
return unused blocks to the host.

The VM package installation skips Firefox, firmware updates, Microsoft Edge,
Ollama, OneDrive, OnlyOffice, QEMU and its firmware, Slack, Spotify, and Zoom.
It also skips thermald, which only benefits physical hardware.
