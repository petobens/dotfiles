# Arch Wayland VM

This disposable QEMU VM tests the same interactive Arch installer and dotfiles
workflow used on physical hardware. It uses a virtual NVMe disk, provides SSH
access through host port 2222, and installs the normal package set except for
packages listed in [`vm_skip.txt`](../packages/vm_skip.txt).

## Host requirements

On an Arch host, install QEMU and the OVMF firmware:

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf
```

Hardware virtualization is commonly enabled by default. After booting the host,
confirm that KVM is available to the current user:

```bash
test -r /dev/kvm && test -w /dev/kvm && echo 'KVM ready'
```

If the check fails because hardware virtualization is disabled, enable Intel
VT-x or AMD SVM in the firmware settings.

The VM script checks these requirements before creating or launching a VM.

## First installation

Commit and push the Wayland branch, then start the VM:

```bash
./setup/vm/vm.sh
```

When no VM disk exists, the command downloads and verifies the current Arch
ISO, creates the VM state, and boots with the ISO attached. In the Arch live
environment, run:

```bash
pacman -Syu --needed git tmux
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

The command verifies the ISO before deleting the disk and firmware state. It
then creates a blank VM and boots the installer. The verified ISO is retained
between resets and replaced when a new Arch release is available.

## SSH and updates

The [`post_install.sh`](../post_install.sh) script enables password-based
recovery SSH on every installation, including the VM and physical laptops.

After a reset, set `username` to the account selected during installation,
remove the previous host key, and authorize the host's existing SSH key:

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

The VM package installation excludes the packages listed in
[`vm_skip.txt`](../packages/vm_skip.txt). The VM loads `scx_lavd` in automatic
mode to verify the same scheduler setup used on the physical machine, but it
cannot reproduce laptop responsiveness, power use, or thermal behavior.
