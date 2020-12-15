#!/usr/bin/env bash
# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parent_dir="$(dirname "$current_dir")"

# Use our pacman conf
if type "pacman" > /dev/null 2>&1; then
    sudo ln -fTs "$parent_dir/arch/config/pacman.conf" "/etc/pacman.conf"
    echo Created /etc/pacman.conf symlink
    sudo pacman -Sy --needed reflector
    sudo reflector --verbose --latest 25 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist
    sudo pacman -Syu

fi

# Install yay if not installed
if ! type "yay" > /dev/null 2>&1; then
    git clone https://aur.archlinux.org/yay.git
    (
        cd yay || exit
        makepkg -si
    )
    rm -rf yay
fi

# Use latest and update any already installed package
echo "Updating packages..."
yay -Syu --nodiffmenu --answerclean N --devel --timeupdate --combinedupgrade \
    --removemake
yay -c

yay_cmd='yay -S --nodiffmenu --answerclean N --needed --removemake'

# Fonts
$yay_cmd adobe-source-code-pro-fonts
$yay_cmd nerd-fonts-source-code-pro
$yay_cmd noto-fonts
$yay_cmd noto-fonts-cjk
$yay_cmd noto-fonts-emoji
$yay_cmd ttf-dejavu
$yay_cmd ttf-nerd-fonts-symbols
$yay_cmd ttf-ms-fonts
$yay_cmd freetype2-infinality

# Bash related
$yay_cmd bash-completion

# Compiler related
$yay_cmd cmake
$yay_cmd gcc-fortran
$yay_cmd openblas

# Languages
$yay_cmd python
$yay_cmd python-pip
$yay_cmd pyenv
$yay_cmd pyenv-virtualenv
$yay_cmd ruby
$yay_cmd rust
$yay_cmd jdk-openjdk
read -p $'\033[1mDo you want to install R (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    $yay_cmd r
fi
read -p $'\033[1mDo you want to install Node.js (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    $yay_cmd nodejs
    $yay_cmd npm
fi

# Alacritty, kitty, neovim and tmux and more bash
$yay_cmd alacritty
$yay_cmd kitty
$yay_cmd neovim-git
$yay_cmd tmux

# Arch specific and window manager
$yay_cmd acpi_call
$yay_cmd alsa-tools
$yay_cmd bluez-utils
$yay_cmd capnet-assist
$yay_cmd connman
$yay_cmd debtap
$yay_cmd downgrade
$yay_cmd dunst
$yay_cmd feh
$yay_cmd i3-gaps
$yay_cmd i3ipc-python-git
$yay_cmd i3lock-color-git
$yay_cmd intltool
$yay_cmd lsof
$yay_cmd maim
$yay_cmd mesa-demos
$yay_cmd mpv
$yay_cmd networkmanager
$yay_cmd nmap
$yay_cmd ntfs-3g
$yay_cmd obs-studio
$yay_cmd pavucontrol
$yay_cmd picom
$yay_cmd playerctl
$yay_cmd polybar
$yay_cmd pulseaudio
$yay_cmd pulseaudio-alsa
$yay_cmd pulseaudio-bluetooth
$yay_cmd rofi
$yay_cmd rofi-dmenu
$yay_cmd sane-airscan
$yay_cmd tlp
$yay_cmd udiskie
$yay_cmd unclutter-xfixes-git
$yay_cmd update-grub
$yay_cmd upower
$yay_cmd xclip
$yay_cmd xdg-user-dirs
$yay_cmd xdotool
$yay_cmd xsel
$yay_cmd xsendkey

# Themes
$yay_cmd adwaita-dark
$yay_cmd capitaine-cursors
$yay_cmd papirus-icon-theme

# Databases
$yay_cmd oracle-instantclient-basic
$yay_cmd oracle-instantclient-sqlplus
$yay_cmd python-pymysql # python version of mysql
$yay_cmd mongodb-bin
$yay_cmd mongodb-tools-bin
$yay_cmd postgresql
$yay_cmd protobuf # Required by python's mysql-connector
$yay_cmd redis
$yay_cmd sqlite3

# CLI
$yay_cmd --mflags "--skipchecksums" snx-800007075
$yay_cmd bat
$yay_cmd bind-tools
$yay_cmd cronie
$yay_cmd ctop
$yay_cmd diff-so-fancy
$yay_cmd dmidecode
$yay_cmd docker
$yay_cmd docker-compose
$yay_cmd dust
$yay_cmd fd
$yay_cmd fzf
$yay_cmd github-cli
$yay_cmd globalprotect-openconnect
$yay_cmd gnupg
$yay_cmd gobject-introspection
$yay_cmd gopass
$yay_cmd graphviz
$yay_cmd hadolint-bin
$yay_cmd htop
$yay_cmd httping
$yay_cmd hyperfine-bin
$yay_cmd inetutils
$yay_cmd jq
$yay_cmd lsb-release
$yay_cmd lsd
$yay_cmd neofetch
$yay_cmd neomutt
$yay_cmd oath-toolkit
$yay_cmd openconnect-git
$yay_cmd openssh
$yay_cmd openvpn
$yay_cmd pandoc
$yay_cmd pandoc-citeproc
$yay_cmd pandoc-crossref
$yay_cmd prettyping
$yay_cmd procs-bin
$yay_cmd progress
$yay_cmd proxychains-ng
$yay_cmd qrencode
$yay_cmd ripgrep
$yay_cmd rlwrap
$yay_cmd rsync
$yay_cmd sd
$yay_cmd shellcheck
$yay_cmd shfmt
$yay_cmd socat
$yay_cmd sshfs
$yay_cmd sshpass
$yay_cmd stoken-git
$yay_cmd strace
$yay_cmd tk
$yay_cmd tldr
$yay_cmd tokei
$yay_cmd tree
$yay_cmd universal-ctags-git
$yay_cmd unrar
$yay_cmd unzip
$yay_cmd vagrant
$yay_cmd virtualbox
$yay_cmd vivid
$yay_cmd w3m
$yay_cmd wget
$yay_cmd z
$yay_cmd zbar
$yay_cmd zip

# Apps
$yay_cmd brave-bin
$yay_cmd connman-gtk
$yay_cmd cups
$yay_cmd cups-pdf
$yay_cmd discord
$yay_cmd firefox
$yay_cmd --mflags --skipinteg freeoffice
$yay_cmd gcolor3
$yay_cmd gnome-font-viewer
$yay_cmd hplip-plugin
$yay_cmd onedrive-abraunegg
$yay_cmd pdfpc
$yay_cmd peek-git
$yay_cmd simple-scan
$yay_cmd slack-desktop
$yay_cmd spotify
$yay_cmd teams
$yay_cmd thunderbird
$yay_cmd transmission-gtk
$yay_cmd xfce4-power-manager
$yay_cmd zathura
$yay_cmd zathura-djvu
$yay_cmd zathura-pdf-poppler
$yay_cmd zoom

# Cleanup
yay -c
