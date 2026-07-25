# Arch Wayland VM

This disposable QEMU VM tests the same interactive Arch installer and dotfiles
workflow used on physical hardware. It boots with UEFI, a virtual NVMe disk,
accelerated graphics, PipeWire audio, and SSH forwarding on host port 2222.

## First installation

Commit and push the Wayland branch, then run from the repository root:

```bash
./setup/vm/vm.sh
```

When no VM disk exists, the command downloads and verifies the current Arch
ISO, creates the VM state, and boots with the ISO attached. In the Arch live
environment, run:

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

At the `Target disk` prompt, enter `/dev/nvme0n1`. The VM defaults to hostname
`arch-vm`, a 1 GiB EFI partition, a 40 GiB root partition, and the remaining
space for home.

After the installer finishes:

```bash
umount -R /mnt
reboot
```

Log in as `pedro` and complete the dotfiles installation:

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
ssh-keygen -R '[127.0.0.1]:2222'
chmod 600 ~/.ssh/id_rsa
ssh-copy-id -F none \
    -i ~/.ssh/id_rsa.pub \
    -p 2222 pedro@127.0.0.1
ssh -F none -p 2222 pedro@127.0.0.1
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
is sparse and grows as the guest writes data. Guest TRIM can return unused
blocks to the host.

The VM package installation skips Firefox, OneDrive, OnlyOffice, Zoom, and
Microsoft Edge.
