# Arch Linux Wayland Installation

This guide documents this repository's Arch Linux installer, desktop setup,
verification, and recovery procedures. It targets an Intel laptop and the
disposable QEMU environment in [setup/vm](../setup/vm/README.md).

These are opinionated dotfiles, not a general-purpose Arch installer. Review
the assumptions and defaults before using them on another machine. Commands
that use repository paths assume the dotfiles checkout is the working
directory unless stated otherwise.

It assumes:

- UEFI firmware
- one internal NVMe drive
- one Btrfs filesystem with flat `@`, `@home`, `@pkg`, `@snapshots`, and
  `@var_log` subvolumes
- systemd-boot with unified kernel images
- the standard `linux` and `linux-lts` kernels
- an Intel CPU and integrated Intel graphics
- a normal tty login, followed by automatic Hyprland startup

Disk encryption and Secure Boot are intentionally omitted from this setup.
RAID, LVM, hibernation, and dual boot are not supported by this guide. LVM is
not used because Btrfs subvolumes provide the useful volume management for
this layout.

## Contents

- [Before starting](#before-starting)
- [Arch installation](#arch-installation)
- [Installer steps in detail](#installer-steps-in-detail)
- [Install the dotfiles](#install-the-dotfiles)
- [Verification and testing](#verification-and-testing)
- [Recovery](#recovery)

## Before starting

### Adapt the defaults

The scripts and dotfiles use the maintainer's defaults. Before installing:

- Choose your own username, hostname, timezone, and keyboard layout at the
  installer prompts. The prefilled values are examples, not requirements.
- Review `setup/packages/` and `setup/post_install.sh` for the applications
  and system policies you want. This guide covers the Intel hardware path;
  other CPU or GPU vendors require adapting the package and power settings.
- Review `hypr/conf/monitors.lua` for connector names, display positions,
  scaling, and workspace assignments. The supplied multi-monitor layout is
  a default, not a hardware requirement.
- Review application bindings and browser policies. Installing applications
  does not sign you in or require the maintainer's accounts. Personal cloud
  and credential restoration is outside this guide.

The installer uses `~/git-repos/private/dotfiles` as its checkout location.
Here, `private` is only a directory name; the cloned repository is public.
The commands below use that path to match the scripts.

### Prepare the installation media

Commit and push the `master` branch from the existing computer. The
new machine cannot clone uncommitted local changes.

Download the current Arch ISO from <https://archlinux.org/download/>. On an
Arch machine, install Caligula and identify the USB and its mounted partitions:

```bash
sudo pacman -S --needed caligula
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS
```

Replace `/dev/sda` and `/dev/sda1` below with your USB drive and partition.
Unmount any mounted USB partitions before burning; skip this if none are
mounted. Caligula does not unmount them on Linux.

```bash
udisksctl unmount -b /dev/sda1
caligula burn path/to/archlinux-version-x86_64.iso
```

Select the whole USB drive in Caligula and check its model and capacity before
confirming: this erases the USB. Caligula requests elevation and verifies the
write.

After successful verification, press `q`. Check for partitions remounted by
the desktop, unmount them if needed, then power off the USB:

```bash
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS
# Only if mounted; repeat for other USB partitions
udisksctl unmount -b /dev/sda1
udisksctl power-off -b /dev/sda
```

Unplug the USB once power-off succeeds.

Back up anything needed from the target disk.

### Validate package lists

Before replacing the current system, update it and verify that every package
listed by the dotfiles still exists:

```bash
sudo pacman -Syu
mapfile -t packages < <(grep -vE '^(#|$)' setup/packages/pacman.txt)
pacman -Si -- "${packages[@]}" > /dev/null
mapfile -t packages < <(grep -vE '^(#|$)' setup/packages/aur.txt)
yay -Si -- "${packages[@]}" > /dev/null
```

Run these commands from the dotfiles repository root. A missing repository
package prevents the entire Pacman transaction from starting. Any Pacman or
AUR installation error stops `setup/install.sh`, although packages installed
by earlier stages remain and the installer can be rerun after correcting the
list. The Yay lookup also accepts packages that moved from the AUR into an
official repository, matching the installer, but cannot guarantee that every
PKGBUILD will still build successfully.

## Arch Installation

Insert the official Arch USB and restart the machine. Use the manufacturer's
boot-menu key to select the USB drive. On Lenovo laptops, repeatedly press
`F12` or `Fn+F12` at the logo. Other manufacturers commonly use `F12`, `F11`,
`Esc`, or `F9`; check the instructions for your model. If the menu offers both
UEFI and legacy entries for the USB, choose the UEFI entry.

### Connect to the internet

In the Arch live environment, Ethernet should connect automatically. For
Wi-Fi, start `iwctl`:

```bash
iwctl
```

List the wireless devices:

```text
device list
```

Replace `wlan0` below with your device name. Scan and list nearby networks:

```text
station wlan0 scan
station wlan0 get-networks
```

Replace `SSID` with your Wi-Fi network name, keeping the quotes. Enter the
Wi-Fi password when prompted, then leave `iwctl`:

```text
station wlan0 connect "SSID"
exit
```

Check the connection from the shell:

```bash
ping -c 3 archlinux.org
```

See the [iwctl manual](https://man.archlinux.org/man/iwctl.1) for more commands.

### Run the automated installer

Once connected, run:

```bash
pacman -Sy --needed git tmux
tmux
git clone --depth 1 https://github.com/petobens/dotfiles.git /tmp/dotfiles
cd /tmp/dotfiles
./setup/install_arch.sh
```

Use `-Sy` only in the live ISO to keep the running kernel's modules intact.
If Pacman reports `Partition / too full`, run the following command, then
retry Pacman. It raises the live environment's RAM-backed storage limit to
2 GiB without resizing the USB or internal disk:

```bash
mount -o remount,size=2G /run/archiso/cowspace
```

See [Archiso](https://wiki.archlinux.org/title/Archiso) for details.

For scrollback, press `Ctrl+B`, release both keys, and then press `[`. Press
`q` to return to the live command.

The installer first asks whether to use a larger font in the live console, then
prompts for the keyboard layout, timezone, hostname, username, and target disk.
The largest unmounted, non-removable whole disk is offered as the default;
verify it in the displayed `lsblk` output before accepting it. Replace the
prefilled user and machine settings with your own. The installer handles
partitioning, the base system, users, services, both kernels, unified kernel
images, and the repository handoff. Both physical and VM installs use a 1 GiB
EFI partition and the remaining space for Btrfs root.

The disk is not changed until the exact `ERASE /dev/...` confirmation is
entered. After installation, unmount and reboot. Continue at
[Install the dotfiles](#install-the-dotfiles).

See [Installer steps in detail](#installer-steps-in-detail) for what the
installer does, including equivalent manual commands.

#### Test in a VM

The VM runs the same installer on a disposable QEMU disk. On an Arch host,
install its requirements, then run it from the dotfiles repository:

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf
./setup/vm/vm.sh
```

Add `--background` (or `-b`) to detach QEMU from the terminal after it starts.

Press `Ctrl+Alt+G` in the QEMU window to toggle mouse and keyboard capture.

The first launch prepares the Arch ISO and boots the installer. Later launches
reuse the installed disk; `./setup/vm/vm.sh reset` discards it and starts a
clean installation. Use `./setup/vm/vm.sh multi` to test three 1920x1080
virtual displays without reproducing the physical connector names. See the
[VM guide](../setup/vm/README.md) for the complete workflow, SSH access, and
VM-specific defaults.

### Installer steps in detail

These 13 steps explain the automated installer. The commands are a manual
reference; do not repeat them after a successful automated installation.

#### Steps 1-2/13: Live environment

These manual steps start in the same Arch live environment described above.
If the NVMe drive is unavailable, check the firmware storage-controller mode
and whether the installer supports the selected mode before continuing.

Verify that the installer was booted in UEFI mode:

```bash
ls /sys/firmware/efi/efivars
```

##### Step 1/13: Checking network and clock

Follow [Connect to the internet](#connect-to-the-internet), then enable and
check time synchronization:

```bash
timedatectl set-ntp true
timedatectl status
```

##### Step 2/13: Entering installation settings

Set a larger console font if necessary:

```bash
setfont ter-132n
```

Check the keyboard layout and available disks:

```bash
localectl list-keymaps
loadkeys us
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
```

#### Steps 3-5/13: Disk setup

##### Step 3/13: Selecting the installation disk

The following example uses `/dev/nvme0n1`:

| Partition            |  Suggested size | Type       | Mount   |
| -------------------- | --------------: | ---------- | ------- |
| EFI System Partition |           1 GiB | EFI System | `/boot` |
| Root                 | Remaining space | Linux root | `/`     |

The partition uses the discoverable x86-64 root type. It contains a Btrfs
filesystem with `@` as the default root subvolume. Separate `@home`, `@pkg`,
and `@var_log` subvolumes keep personal data, cached packages, and logs outside
root snapshots. The `@snapshots` subvolume stores Snapper snapshots separately.
All subvolumes share the available space.

##### Step 4/13: Partitioning and formatting

The partitioning commands below destroy data. Confirm the target device with
`lsblk` before formatting anything. Replace every example device with the value
from the new machine.

Create the GPT partition table and both partitions:

```bash
sfdisk --lock --wipe always --wipe-partitions always /dev/nvme0n1 << 'EOF'
label: gpt
size=1GiB, type=U, name="EFI"
type="Linux root (x86-64)", name="Arch root"
EOF
udevadm settle
```

This guide does not create disk swap. The dotfiles package stage installs
`zram-generator`, and its post-install step creates
`/etc/systemd/zram-generator.conf` with a `[zram0]` section. On the following
boot, systemd creates zstd-compressed RAM-backed swap sized to half of RAM. This
swap uses `vm.swappiness=180` and `vm.page-cluster=0` to favor fast compressed
swap without disk-oriented readahead. It is not available during the live
installation or before the dotfiles package stage.

Zram alone does not support hibernation. Keep zram and add disk-backed swap
with kernel resume configured separately if hibernation is required.

During a Hyprland session, the battery monitor checks charge every 30 seconds
and warns at 20% and 10%. Waybar turns red at 10% or below only while
discharging. At 5%, a persistent "Connect charger" notification warns that
shutdown will occur at 3%. At 3% or below, the monitor gives a five-second
warning, then requests an orderly shutdown if the battery is still
discharging at that level. Connecting the charger during the warning cancels
shutdown. Unsaved work can still be lost.

The post-install step also sets UPower to `CriticalPowerAction=PowerOff` with
`UsePercentageForPolicy=true` and `PercentageAction=2.0` as a system-wide
fallback. These checks only run while the laptop is awake. Ordinary idle or
lid-triggered sleep still consumes battery and cannot guarantee a shutdown
before the remaining charge runs out.

Assuming EFI is `p1` and root is `p2`:

```bash
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.btrfs -f /dev/nvme0n1p2
```

##### Step 5/13: Mounting filesystems

```bash
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
for subvolume in @ @home @pkg @snapshots @var_log; do
    btrfs property set "/mnt/$subvolume" compression zstd
done
btrfs subvolume set-default /mnt/@
umount /mnt
mount -o noatime,nodiscard /dev/nvme0n1p2 /mnt
mount --mkdir -o noatime,nodiscard,subvol=@home /dev/nvme0n1p2 /mnt/home
mount --mkdir -o noatime,nodiscard,subvol=@pkg \
    /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount --mkdir -o noatime,nodiscard,subvol=@snapshots \
    /dev/nvme0n1p2 /mnt/.snapshots
mount --mkdir -o noatime,nodiscard,subvol=@var_log /dev/nvme0n1p2 /mnt/var/log
mount --mkdir -o umask=0077 /dev/nvme0n1p1 /mnt/boot

findmnt /mnt
```

The EFI partition must be mounted at `/mnt/boot` for the systemd-boot layout
used here. The restrictive FAT umask protects systemd-boot's random seed. The
default Btrfs subvolume lets systemd discover root without an explicit root
device path.

The explicit `nodiscard` options disable Btrfs asynchronous discard. The
weekly `fstrim.timer` enabled later handles SSD trimming instead.

`@snapshots` is mounted at `/.snapshots`. The dotfiles post-install step
configures Snapper to retain the latest ten numbered snapshots and to discard
pre/post pairs that changed nothing. Automatic timeline snapshots are
disabled.

Btrfs snapshots are not recursive, so a snapshot of `@` excludes personal
data, logs, cached packages, and the stored snapshots themselves. Their
explicit mounts remain available after a root rollback.

#### Step 6/13: Installing the base system

Install only what is needed to boot, connect to the network, create the user,
and clone the repository:

```bash
pacstrap -K /mnt \
    base \
    btrfs-progs \
    git \
    intel-ucode \
    linux \
    linux-firmware-intel \
    linux-lts \
    networkmanager \
    sudo \
    systemd-ukify \
    terminus-font \
    tmux \
    vim
```

Pacstrap may warn that `/mnt/boot` has permissions `700` instead of the
package default of `755`, and early kernel hooks may warn that
`/etc/vconsole.conf` does not exist. Both warnings are expected. The restrictive
boot permissions are intentional, and the installer creates the console
configuration and regenerates both unified kernel images before rebooting.

`linux-firmware-intel` provides the Intel graphics and Wi-Fi firmware needed by
the target laptop without installing firmware for unrelated vendors. The
dotfiles package stage installs the Intel graphics stack on physical hosts. Do
not install `xf86-video-intel` for the modern Intel GPU.

Both kernels are installed here so their unified kernel images can be created
before the first reboot. Kernel headers are unnecessary because this setup does
not build DKMS or other external kernel modules.

#### Step 7/13: Configuring filesystem mounts

Create the `fstab` entries for the non-root subvolumes:

```bash
root_uuid=$(blkid -s UUID -o value /dev/nvme0n1p2)
printf '%s\n' \
    "UUID=$root_uuid /home btrfs noatime,nodiscard,subvol=@home 0 0" \
    "UUID=$root_uuid /var/cache/pacman/pkg btrfs noatime,nodiscard,subvol=@pkg 0 0" \
    "UUID=$root_uuid /.snapshots btrfs noatime,nodiscard,subvol=@snapshots 0 0" \
    "UUID=$root_uuid /var/log btrfs noatime,nodiscard,subvol=@var_log 0 0" \
    > /mnt/etc/fstab
```

systemd discovers the root partition and EFI System Partition from their GPT
types and the booted unified kernel image.

Enter the installed system:

```bash
arch-chroot /mnt
```

#### Steps 8-10/13: Configure the installed system

##### Step 8/13: Configuring locale and system identity

Use the timezone selected during installation; replace `Region/City` below.
The generated locales shown here match the repository defaults.

```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```

Uncomment these entries in `/etc/locale.gen`:

```text
en_US.UTF-8 UTF-8
es_AR.UTF-8 UTF-8
```

Then generate the locales:

```bash
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=us\n' > /etc/vconsole.conf
```

Choose a lowercase hostname and create the host files:

```bash
printf 'HOSTNAME\n' > /etc/hostname
```

Replace `HOSTNAME` above and below:

```bash
printf '%s\n' \
    '127.0.0.1 localhost' \
    '::1 localhost' \
    '127.0.1.1 HOSTNAME.localdomain HOSTNAME' > /etc/hosts
```

`/etc/hosts` provides local name resolution without DNS. The first two entries
define IPv4 and IPv6 localhost; the third makes the chosen hostname and its
`localdomain` form resolve to the loopback interface. This is separate from the
`.local` network discovery provided by Avahi later.

##### Step 9/13: Creating users

Choose the normal username, set the root password, create the user, and set
its password. Replace `youruser` with the chosen username:

```bash
username=youruser
passwd
useradd -m -G wheel -s /bin/bash "$username"
passwd "$username"
```

Allow members of the `wheel` group to use sudo:

```bash
install -Dm440 /dev/stdin /etc/sudoers.d/10-wheel << 'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF
```

The `useradd` command above adds the account to the `wheel` group. This rule
allows members of that group to run administrative commands with sudo after
entering their password.

##### Step 10/13: Enabling system services

Enable networking, clock synchronization, periodic SSD trimming, and automatic
systemd-boot updates:

```bash
systemctl enable \
    fstrim.timer \
    NetworkManager \
    systemd-boot-update.service \
    systemd-timesyncd
```

The dotfiles installer will enable the remaining desktop and user services.

#### Step 11/13: Installing unified kernel images

Leave the normal chroot, install systemd-boot with systemd API filesystems
available, and reenter the chroot:

```bash
exit
arch-chroot -S /mnt bootctl install
arch-chroot /mnt
```

Configure a systemd-based initramfs so it can discover the root partition:

```bash
install -Dm644 /dev/stdin \
    /etc/mkinitcpio.conf.d/10-systemd.conf << 'EOF'
HOOKS=(
    base systemd autodetect microcode modconf kms keyboard
    sd-vconsole block filesystems
)
EOF
```

`systemd` provides early userspace and GPT root discovery, while `base` keeps
an emergency shell available. `autodetect` limits the normal image to this
machine's hardware; the fallback presets below skip it. The remaining hooks add
early microcode, module settings, graphics and console support, and the drivers
needed to find and mount the root filesystem.

Create the embedded kernel command line:

```bash
printf 'rootflags=noatime,nodiscard rw quiet\n' > /etc/kernel/cmdline
```

`rootflags` applies the same `noatime` and `nodiscard` options to the discovered
root filesystem. `rw` mounts it writable, and `quiet` suppresses routine boot
messages.

Edit `/etc/mkinitcpio.d/linux.preset` to write the default and fallback
presets as UKIs:

```bash
PRESETS=('default' 'fallback')
default_uki="/boot/EFI/Linux/arch-linux.efi"
fallback_uki="/boot/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
```

Comment out `default_image` and `fallback_image`. Configure
`/etc/mkinitcpio.d/linux-lts.preset` with default and fallback presets too:

```bash
PRESETS=('default' 'fallback')
default_uki="/boot/EFI/Linux/arch-linux-lts.efi"
fallback_uki="/boot/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
```

Comment out `default_image` and `fallback_image`. Each fallback UKI covers
modules omitted by hardware autodetection. The LTS UKIs provide an independent
older kernel whose support for newer hardware may differ from the standard
kernel. The Arch installation USB remains the final recovery path.

Create `/boot/loader/loader.conf`:

```ini
default arch-linux.efi
timeout 3
console-mode 4
editor yes
```

`default` selects the standard `linux` UKI instead of an LTS or fallback entry.
`timeout` shows the boot menu for three seconds before starting that default.
`console-mode 4` enlarges the menu on the physical HiDPI machine and is also
set by the installer. Mode numbers are firmware-specific. Press `r` in the
boot menu to cycle modes; the choice persists and overrides this file.
Press `Shift+R` to restore the file's setting.
`editor yes` allows temporary kernel command-line changes from the boot menu,
which supports the recovery procedure below. Disable the editor if unauthorized
physical access is a concern.

Remove the conventional initramfs files created before the presets were
switched to UKI mode, then build the unified kernel images:

```bash
rm -f /boot/initramfs-linux*.img
mkinitcpio -P
```

The UKIs combine each kernel, initramfs, microcode, and command line into one
EFI file. systemd-boot discovers them automatically, so loader entry files and
`root=` parameters are unnecessary. The boot menu also offers the standard
fallback, LTS default, and LTS fallback UKIs as recovery alternatives.

Verify the installation:

```bash
bootctl status
bootctl list
ls -lh /boot/EFI/Linux
```

#### Steps 12-13/13: Handoff and completion

##### Step 12/13: Cloning the Wayland dotfiles

Set the username again after reentering the chroot, then clone the repository's
default branch as that user. Replace `youruser` with the username created
above:

```bash
username=youruser
checkout="/home/$username/git-repos/private/dotfiles"
install -d -o "$username" -g "$username" \
    "/home/$username/git-repos" "$(dirname "$checkout")"
runuser -u "$username" -- \
    git clone \
    https://github.com/petobens/dotfiles.git "$checkout"
```

##### Step 13/13: Installation complete

Leave the chroot, unmount the installation, and reboot:

```bash
exit
umount -R /mnt
reboot
```

Remove the USB drive. The system should boot through systemd-boot and show a
normal tty login prompt.

## Install the dotfiles

Log in with the normal username selected during installation. If Wi-Fi is not
connected:

```bash
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"
```

Confirm the handoff requirements:

```bash
ping -c 3 archlinux.org
sudo true
git --version
```

The Arch installer already cloned the repository's default branch into
`~/git-repos/private/dotfiles`. Run the dotfiles installer as the normal user,
without putting `sudo` in front of the script:

```bash
cd ~/git-repos/private/dotfiles
tmux
./setup/install.sh
```

Setup scripts resolve repository paths from their own location. They can also
be run from inside `setup/` as `./install.sh` or `./symlinks.sh`.

For scrollback, press `Ctrl+B`, release both keys, and then press `[`. Press
`q` to return to the live command.

With no arguments, the installer behaves as `--all`: it installs packages and
symlinks and asks whether to install LaTeX. It requests sudo when needed,
installs the Pacman packages, bootstraps `yay-bin` if needed, installs the AUR
packages and language tools, installs LaTeX when selected, runs
`setup/post_install.sh`, and creates the configuration symlinks. Yazi installs
its pinned plugins on its first launch instead. AUR packages build with all
available CPU cores under `/tmp/makepkg`.

### Post-install configuration

The post-install step applies the system configuration:

- **Performance and power:** Configures zstd-compressed zram, limits persistent
  journals to 250 MiB, loads `scx_lavd` in automatic mode, enables HWP dynamic
  boost on AC, and uses the base Intel Xe GPU profile with Wi-Fi power saving
  disabled on battery. Sets UPower to shut down at 2% as a fallback for the
  desktop battery monitor's 3% shutdown. These battery settings favor call and
  desktop responsiveness over maximum runtime. Physical hardware also receives
  firmware metadata refreshes and Intel LPMD; thermald is enabled only when
  Lenovo DYTC is unavailable.
- **Services and networking:** Enables NetworkManager, Bluetooth, TLP, CUPS,
  Avahi, monthly Btrfs scrubbing, weekly package-cache cleanup, and the user
  audio services, and creates `/mnt/nfs`. It retains root snapshots taken
  before and after Pacman transactions and refreshes the Pacman mirror list
  weekly, keeping the five fastest among ten recently synchronized HTTPS
  mirrors. Avahi ignores Docker and libvirt bridges, while `nss-mdns` adds
  `.local` hostname lookup. The wireless regulatory database uses the world
  domain until Wi-Fi learns the access point's country. UFW denies unsolicited
  inbound traffic, allows outgoing traffic, rate-limits recovery SSH, and
  permits LocalSend on TCP and UDP port 53317 and mDNS on UDP port 5353.
- **Desktop integration:** Configures Gopass and MIME defaults, unlocks GNOME
  Keyring at console login, and keeps the keyring password synchronized with
  the login password. It selects the dark color scheme, the `Adwaita-dark` GTK
  theme, `Noto Sans 11`, `Papirus-Dark` icons, and matching Apple Hyprcursor
  and XCursor themes. It adds
  the user to the `video` group so the backlight keys can write to the
  screen and keyboard brightness files under `/sys/class/backlight` and
  `/sys/class/leds`, and installs the udev rule that resets the external
  Logitech webcam zoom. It also installs browser policies and seeds Zoom
  scaling and disabled Spotify autostart before those applications create
  their settings.
- **Docker:** Stores Docker data under `~/.cache` and disables Btrfs
  copy-on-write before Docker uses the directory. The data is disposable and
  does not need Btrfs checksums or compression. Published ports bind to
  `127.0.0.1` by default for both the standard bridge and newly created bridge
  networks because Docker-published ports bypass UFW. Bind a port explicitly
  to `0.0.0.0` only when another device needs to reach that container.

Password-based recovery SSH is enabled on every installation so an unprepared
device, such as a phone, can still reach the machine. Public-key login and SFTP
also remain available. Root, keyboard-interactive, and empty-password login are
disabled, and access is limited to the selected user. Login attempts use a
30-second grace period and allow three authentication failures. Agent, TCP, and
X11 forwarding and SSH tunnels are disabled because the service is intended
only for a recovery shell and file transfer. Because SSH listens on every
connected network, use a strong, unique login password. UFW rate-limits new
SSH connections but does not restrict them to a particular network.

The physical package set includes the Intel VPL runtime for Quick Sync, Intel
GPU and VA-API diagnostics, Source Code Pro, and the libcamera tools, GStreamer
plugin, and PipeWire integration used by supported cameras. WirePlumber loads
its V4L2 and libcamera monitors and deduplicates devices without a custom
override. It also includes Bolt, whose `boltd` daemon authorizes Thunderbolt
and USB4 devices. On systems requiring user authorization, a dock and its
devices can remain unavailable until authorized. The daemon is D-Bus
activated and has no unit to enable.

Brave and Edge run through native Wayland and receive the
`AcceleratedVideoEncoder` and `AcceleratedVideoDecodeLinuxZeroCopyGL` feature
flags so supported codecs can use Intel hardware video acceleration. Brave also
enables `WebRtcPipeWireCamera` for PipeWire camera access. Browser policies
install Surfingkeys in Brave, Edge, and Firefox, Google Docs Offline
in Brave, and uBlock Origin in Edge. They also allow the Chromium Surfingkeys
extensions to read the local configuration, set Firefox's PipeWire camera
default, and provide Google as an overridable Brave and Edge startup default.

Ollama is installed but does not start automatically. Start it when needed:

```bash
sudo systemctl start ollama
```

The `ua` Fish abbreviation updates repository and AUR packages, including
development AUR packages, cleans the package cache, and updates installed
Python, Node.js, Rust, and TeX Live tooling. On physical hardware, run
`fwupdmgr get-updates` to check for available firmware, then review the result
and run `fwupdmgr update` explicitly when ready.

Reboot after the dotfiles installer finishes. This activates zram, `scx_lavd`,
and Docker group membership:

```bash
sudo reboot
```

Zram uses zstd compression and half of RAM. After rebooting, verify that
`/dev/zram0` is active as swap:

```bash
swapon --show
zramctl
sysctl vm.swappiness vm.page-cluster
```

Confirm that the Snapper configuration and cleanup timer are active:

```bash
sudo snapper -c root get-config |
    rg 'NUMBER_|EMPTY_PRE_POST|TIMELINE_'
sudo snapper -c root list
systemctl list-timers snapper-cleanup.timer
```

`snap-pac` creates a pre/post pair for later Pacman transactions. Root
snapshots exclude home files, logs, cached packages, and the snapshots
themselves because those paths are separate Btrfs subvolumes. Automatic
timeline snapshots are disabled. Snapper retains the latest ten numbered
recovery points and removes pre/post pairs with no filesystem differences.
Before changing root files manually, create a temporary recovery point:

```bash
sudo snapper -c root create \
    --description 'before manual change' \
    --cleanup-algorithm number
```

This snapshot uses the same number-based retention and is removed as newer
numbered snapshots accumulate.

At tty1, enter the normal username and password. Fish then starts Hyprland
automatically. No display manager and no passwordless login are used.
Hyprland starts a user target bound to `graphical-session.target` after
exporting its Wayland environment and stops it during shutdown. This gives
portals and graphical user services the correct systemd lifecycle without a
separate session manager.

## Verification and testing

### Verify services and hardware

After rebooting, open a terminal inside Hyprland and run:

```bash
system_report --sudo
```

The report checks boot, Btrfs, snapshots, zram, services, power settings,
networking, hardware discovery, and the graphical session. It also collects
OpenCL, OpenGL, Vulkan, VA-API, PipeWire, and camera diagnostics. Review its
warnings and failures before using the troubleshooting commands below; most
of those checks already run automatically and need no manual repetition.

The `--sudo` option adds protected boot, Btrfs, Snapper, firewall, and SSH
checks. Omit it to skip authentication and those checks. Reports redact common
personal and machine identifiers, but review them before sharing. Run locally:
an SSH shell lacks Hyprland's environment and produces a `Hyprland session`
warning even when the desktop is healthy.

#### Service and hardware diagnostics

Use these commands to investigate a report finding:

```bash
systemctl --failed
systemctl --user --failed
scxctl get
tlp-stat -s
swapon --show
grep '^hosts:' /etc/nsswitch.conf
grep '^WIRELESS_REGDOM' /etc/conf.d/wireless-regdom
sudo ufw status verbose
sudo sshd -T | grep -E \
    '^(passwordauthentication|permitrootlogin|maxauthtries|disableforwarding) '
```

The report checks expected system and user services. `fwupd-refresh.timer`
and `intel_lpmd` apply only to physical installations; see
[vm_skip.txt](../setup/packages/vm_skip.txt) for VM exclusions. `thermald`
should be enabled on physical hardware unless Lenovo DYTC is available at
`/sys/devices/platform/thinkpad_acpi/dytc_lapmode`.

For an Intel NPU discovery problem, inspect its driver, firmware, and device:

```bash
lspci -knnd ::1200
journalctl -kg intel_vpu
ls -l /dev/accel/accel0
```

Skip NPU checks if the machine has none. Install a user-space runtime only when
an application needs one, using its supported OpenVINO, compiler, and Level
Zero versions.

Physical installations include `intel-compute-runtime`, `level-zero-loader`,
and `clinfo` for optional Intel GPU compute; these are omitted in the VM and
are not required for Hyprland or VA-API. The installer also provides
`intel-gpu-tools`, `libva-utils`, `mesa-utils`, and `vulkan-tools`. For
graphics, audio, or camera problems, use the relevant diagnostics:

```bash
clinfo -l
glxinfo -B
vulkaninfo --summary
vainfo
wpctl status
cam -l
```

Missing optional hardware is not an installation failure.

#### Temporary NvPCR workaround on the ThinkPad

On 2026-09-26, the ThinkPad X1 Carbon received a workaround for systemd 262-1
NvPCR failures ([upstream issue][nvpcr-issue]): four `/etc/nvpcr/*.nvpcr`
overrides point to `/dev/null`, and the product/login measurement services
are masked. Normal TPM setup and boot measurements remain enabled; reboot
verification passed. The installer does not apply this workaround.

Wait for an upstream fix, then remove the overrides below. Package upgrades
do not remove them automatically:

```bash
for name in cryptsetup hardware login verity; do
    path="/etc/nvpcr/$name.nvpcr"
    if [[ $(readlink "$path") == /dev/null ]]; then
        sudo rm "$path"
    fi
done
sudo systemctl unmask systemd-pcrproduct.service systemd-pcrlogin@.service
```

Reboot and check `systemctl --failed` and `journalctl -b -p err`.

[nvpcr-issue]: https://github.com/systemd/systemd/issues/43848

#### Manual connection and media tests

The report cannot verify these interactions. Test password-based SSH from
another device on the same network, using the installed username and hostname:

```bash
ssh youruser@yourhost.local
```

Open LocalSend on both devices and transfer a file in each direction.

Connect a removable drive and confirm that Udiskie mounts it under
`/run/media/$USER`. In Yazi, press `"` then `u` to browse mounted drives.
Before unplugging, press `Super+Shift+E` to unmount and power off all removable
drives. Udiskie runs without a tray icon. NTFS uses the kernel's `ntfs3`
driver; install `ntfs-3g` only if a drive does not work with it.

Check that `wpctl status` lists the expected speakers, microphones, and camera.
Open the Quickshell audio menu from Waybar or `Super+Shift+V` to test volume
and default devices; expand `Applications` for per-app controls. The menu
needs no autostart service. Do not copy another machine's WirePlumber state.
If Bluetooth headphones are silent, check output selection and app mute,
then pause playback and reconnect them if needed.

Test the camera in Firefox, Brave, and Edge. During a Meet call, run
`sudo intel_gpu_top` and check for Video engine activity to confirm hardware
encoding. Check `brave://gpu` for hardware-accelerated video encoding and
`brave://version` for the configured feature flags. While sharing the screen,
open `Super+V` or `Super+/`: Rofi should remain visible locally but be hidden
from the shared output.

If Edge cannot detect the PipeWire camera, enable the WebRTC PipeWire camera
option in its flags page and restart. Only if that fixes detection, add
`WebRtcPipeWireCamera` to its `--enable-features` configuration.

#### Optional: reclaim the installation USB

Writing the Arch image replaces the USB's partition table. To reuse it for
files, identify its whole-drive path without a `-partN` suffix. Replace
`usb-MODEL-SERIAL` below, verify it with `lsblk`, and unmount its filesystems.
The following commands erase the selected drive:

```bash
ls -l /dev/disk/by-id/usb-*
lsblk /dev/disk/by-id/usb-MODEL-SERIAL
udiskie-umount --all
sudo wipefs --all /dev/disk/by-id/usb-MODEL-SERIAL
printf 'label: dos\n,,7\n' |
    sudo sfdisk /dev/disk/by-id/usb-MODEL-SERIAL
sudo udevadm settle
sudo mkfs.exfat -L USB /dev/disk/by-id/usb-MODEL-SERIAL-part1
```

This creates an exFAT partition supporting files larger than 4 GiB and readable
by Linux, Windows, and macOS. Reconnect the drive or mount it with Udiskie.

### Verify the first graphical session

Confirm that Waybar appears, then open Ghostty and run:

```bash
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
tmux new -A -s desktop
v
```

The session type should be `wayland`; `system_report` checks the graphical
session targets and failed user units. The Fish alias `v` runs `nvim`. Let
Neovim finish installing its `vim.pack` plugins before closing it. QML tooling
comes from `qt6-declarative` and needs no Mason installation. Tmux also
installs missing plugins on first launch. Run `fm` and check that Yazi opens
cleanly.

Test the desktop controls:

- Use the volume and brightness keys and check Mako's indicators.
- Copy English/Spanish text from a selected region with `Super+Shift+O`.
  Escape cancels selection; failed or empty OCR leaves the clipboard intact.
- Magnify the screen with `Super+Alt+=`, reduce it with `Super+Alt+-`, and
  reset with `Super+Alt+0`. Magnification is limited to 1x through 4x.
- Take a selection screenshot with `Super+Shift+C`. The screen should freeze
  during selection, and the result should reach both the clipboard and
  `~/Pictures/Screenshots`. Open it from Yazi to check that it uses imv.
- Record a region with `Super+Shift+G`, then press it again to stop. Check for
  the GIF in `~/Videos/Recordings`. `Super+Alt+G` records MP4 instead; both use
  Intel GPU encoding when `/dev/dri/renderD128` exists.
- Open the Waybar Arch menu and select `about arch`: Fastfetch should appear
  in a centered window. Leave the pointer still for a second and check that
  it hides until moved.
- Open the Rofi cheatsheet with `Super+/` and check its keybinding labels.
  Run `hyprprop` and click a window to inspect its properties.
- Copy text, close its source window, and paste it. `wl-clip-persist` keeps
  the selection alive; `Super+V` opens the `cliphist` history in Rofi.
- Open the Bluetooth menu from Waybar. Use the terminal's `bt` chooser for
  devices requiring a pairing passkey.

#### Displays and idle behavior

The default layout places two 1920x1080 displays (`DP-1` and `DP-3`) above the
centered laptop screen (`eDP-1`). Inspect connector names and modes with:

```bash
hyprctl monitors all
```

Adjust connectors, positions, workspaces, and scale in `hypr/conf/monitors.lua`.
The 2880x1800 rule uses scale `1.5`; 3000x2000 uses `2`. A generic fallback
handles other displays. Workspaces 1, 4, and 9 belong to `DP-3`; 2, 3, and 8
to `eDP-1`; and 5, 6, and 7 to `DP-1`. Waybar shows only active or occupied
workspaces, so gaps are expected.

Test these mappings:

- `Super+Return`: laptop-only mode, disabling all other displays. Without
  `eDP-1`, as in the VM, it falls back to the multi-display layout.
- `Super+Ctrl+Return`: restore connected displays.
- `Super+Shift+Return`: mirror the laptop onto every other display, including
  unconfigured connectors such as an `HDMI-1` projector.
- `Super+Ctrl+Arrow`: move the focused window in each direction.
- `Super+Shift+Arrow`: move the current workspace in each direction.

Closing the lid disables `eDP-1` and uses external displays; opening it
restores the previous monitor mode. With the lid closed, the laptop suspends
without an external display and stays running with one connected.

Hypridle locks after 10 minutes, blanks displays after 15, and suspends after
30 on battery. While plugged in, it locks and blanks but does not suspend.

### Test on physical hardware

The following checks require physical hardware and cannot be completed in
the VM. Skip checks for devices your machine does not have:

- Enroll and verify a fingerprint, then run `hyprlock` and confirm that either
  the fingerprint or login password unlocks it:

  ```bash
  fprintd-enroll
  fprintd-verify
  hyprlock
  ```

  If enrollment reports that no device is available, the reader is not
  supported by the installed `libfprint` version. Fingerprints are intentionally
  not enabled for tty login, `sudo`, or Polkit.

- Verify the battery warnings. `hypr/scripts/battery_monitor` starts with the
  session and exits immediately when no battery is present, so confirm it runs
  with `pgrep -f battery_monitor`. While discharging, Mako shows a warning at
  20% and a sticky one at 10%, followed by a persistent "Connect charger"
  warning at 5%. At 3%, it requests an orderly shutdown after five seconds
  unless charging has started. UPower provides a shutdown fallback at 2%.
  Save all work before testing the shutdown threshold.
- Test closing and opening the lid while undocked and while connected to the
  dock. The undocked laptop should suspend; while docked, the external displays
  should remain active and reopening the lid should restore the selected layout.
- Confirm that the Thunderbolt dock is authorized automatically. `boltd` is
  D-Bus activated, so it should start on its own when the dock is connected:

  ```bash
  boltctl list
  ```

  Every dock entry should show `authorized`. If one shows `connected` but not
  authorized, run `boltctl enroll <uuid>` once to store it permanently.

- Verify idle suspension on battery with no call window focused and no
  fullscreen MPV window. Unplug the charger, leave the session untouched, and
  confirm that it locks after 10 minutes, blanks after 15, and suspends after
  30 minutes.
  Repeat while plugged in and confirm that it locks and blanks but does not
  suspend. On battery, also leave a Meet, Teams, or Zoom window focused past
  the lock timeout and repeat with MPV fullscreen; neither should trigger idle
  actions.
- Test local English and Spanish dictation: press F10 to start recording, speak,
  and press F10 again to have Voxtype type the transcription into the focused
  window.

## Recovery

### Open a shell if Hyprland fails

Press `Ctrl+Alt+F2` (plus `Fn` if needed) and log in to the text console on
tty2 to edit configuration or inspect logs. Fish starts Hyprland only on
tty1, so this shell remains available if Hyprland cannot start.

Run `exit` when finished, then press `Ctrl+Alt+F1` to return to tty1. You can
test this while Hyprland is running; switching consoles keeps it running.

`Super+X` opens Kitty and requires working Hyprland. The text console is
independent, though a hard GPU or kernel freeze can prevent switching.

### Roll back a root snapshot

If the installed system still boots, list the snapshots there. A Pacman
pre/post pair can also be inspected before choosing its pre snapshot:

```bash
sudo snapper -c root list
sudo snapper -c root status PRE..POST
```

If the system cannot boot, skip those commands and boot the Arch USB. Identify
the root and EFI partitions with `lsblk`, then mount the top-level Btrfs
filesystem. The type, pairing metadata, description, and file path identify
the available snapshots. Copy the recovery script from the home subvolume
before unmounting it. The USB shell runs as root, so these commands do not use
`sudo`. Replace `youruser` with the installed username:

```bash
mount -o subvolid=5 /dev/nvme0n1p2 /mnt
grep -HE '<(type|pre_num|description)>' /mnt/@snapshots/*/info.xml
username=youruser
cp "/mnt/@home/$username/git-repos/private/dotfiles/setup/restore_snapshot.sh" \
    /tmp/
umount /mnt
```

The directory in each file path is the snapshot number. For a broken package
transaction, choose its `pre` snapshot. To undo a manual change, choose the
`single` snapshot created before it.

Run the copied script with the selected snapshot number, root partition, and
EFI partition:

```bash
bash /tmp/restore_snapshot.sh 123 /dev/nvme0n1p2 /dev/nvme0n1p1
```

The script validates the inputs and asks for confirmation. It preserves the
failed root as `@failed-*` and restores the selected snapshot. Because `/boot`
is not part of root snapshots, it copies the restored kernels from
`/usr/lib/modules` to `/boot` before regenerating the unified kernel images.
Remove the USB and reboot when it finishes. After confirming that the restored
system works, delete the preserved subvolume from a top-level Btrfs mount.
Replace the root partition and `@failed-YYYYMMDD-HHMMSS` below with the values
used by the restore script:

```bash
sudo mount --mkdir -o subvolid=5 /dev/nvme0n1p2 /mnt/btrfs
sudo btrfs subvolume delete --recursive /mnt/btrfs/@failed-YYYYMMDD-HHMMSS
sudo umount /mnt/btrfs
```

The recursive option also removes nested subvolumes, such as `var/lib/machines`
and `var/lib/portables`, inside that failed root.

This rollback restores only the root subvolume. It does not revert home files,
logs, the package cache, or other excluded subvolumes.

### Repair without rollback

If systemd-boot and the kernel still work but normal userspace does not, select
the Arch Linux entry in the boot menu and press `e`. Append `init=/bin/bash` to
the kernel command line and optionally remove `quiet` to see boot messages.
Press `Enter` to boot the edited entry.

The configured command line includes `rw`, so this opens a writable root shell.
After making repairs:

```bash
sync
reboot -f
```

If the physical system does not boot, start the Arch USB and mount the
installed filesystems:

```bash
mount -o noatime,nodiscard /dev/nvme0n1p2 /mnt
mount --mkdir -o noatime,nodiscard,subvol=@home /dev/nvme0n1p2 /mnt/home
mount --mkdir -o noatime,nodiscard,subvol=@pkg \
    /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount --mkdir -o noatime,nodiscard,subvol=@snapshots \
    /dev/nvme0n1p2 /mnt/.snapshots
mount --mkdir -o noatime,nodiscard,subvol=@var_log /dev/nvme0n1p2 /mnt/var/log
mount --mkdir -o umask=0077 /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

Useful checks include:

```bash
bootctl status
bootctl list
ls -lh /boot/EFI/Linux
journalctl -b -p warning
mkinitcpio -P
```

After repairs:

```bash
exit
umount -R /mnt
reboot
```

## References

- <https://wiki.archlinux.org/title/Btrfs>
- <https://wiki.archlinux.org/title/Hardware_video_acceleration>
- <https://wiki.archlinux.org/title/Installation_guide>
- <https://wiki.archlinux.org/title/Intel_graphics>
- <https://wiki.archlinux.org/title/NetworkManager>
- <https://wiki.archlinux.org/title/Snapper>
- <https://wiki.archlinux.org/title/Sudo>
- <https://wiki.archlinux.org/title/Systemd-boot>
- <https://wiki.archlinux.org/title/Unified_kernel_image>
- <https://wiki.archlinux.org/title/Users_and_groups>
- <https://wiki.archlinux.org/title/Zram>
