#!/usr/bin/env bash
# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parent_dir="$(dirname "$current_dir")"

install_node=false
read -p $'\033[1mDo you want to install Node.js (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_node=true
fi

# Use our pacman conf
if type "pacman" > /dev/null 2>&1; then
    sudo ln -fTs "$parent_dir/arch/config/pacman.conf" "/etc/pacman.conf"
    echo Created /etc/pacman.conf symlink
    sudo pacman -Sy --needed reflector
    read -p $'\033[1mDo you want to update package mirrorlist (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reflector --verbose --latest 25 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist
    fi
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
yay -Syu --diffmenu=false --answerclean N --devel --timeupdate --combinedupgrade \
    --removemake
yay -Yc

yay_cmd='yay -S --diffmenu=false --answerclean N --needed --removemake --noconfirm --answerdiff=None'

# Fonts
$yay_cmd adobe-source-code-pro-fonts
$yay_cmd freetype2
$yay_cmd noto-fonts
$yay_cmd noto-fonts-cjk
$yay_cmd noto-fonts-emoji
$yay_cmd ttf-dejavu
$yay_cmd ttf-ms-fonts
$yay_cmd ttf-nerd-fonts-symbols
$yay_cmd ttf-sourcecodepro-nerd

# Bash related
$yay_cmd bash-completion

# Compiler related
$yay_cmd cmake
$yay_cmd gcc-fortran
$yay_cmd openblas

# Languages
$yay_cmd luarocks
$yay_cmd lua51
$yay_cmd python
$yay_cmd python-pip
$yay_cmd pyenv
$yay_cmd pyenv-virtualenv
$yay_cmd rust
$yay_cmd jdk-openjdk
if [[ "$install_node" = true ]]; then
    $yay_cmd nodejs
    $yay_cmd npm
fi

# Alacritty, kitty, neovim and tmux and more bash
$yay_cmd alacritty
$yay_cmd kitty
$yay_cmd neovim-git
$yay_cmd tree-sitter-cli
$yay_cmd tmux

# Audio/video
$yay_cmd gst-plugin-libcamera
$yay_cmd libcamera
$yay_cmd libcamera-tools
$yay_cmd pipewire
$yay_cmd pipewire-alsa
$yay_cmd pipewire-jack
$yay_cmd pipewire-libcamera
$yay_cmd pipewire-pulse
$yay_cmd sof-firmware
$yay_cmd wireplumber
# We need xdg-portal for firefox/brave/obs to request permission for libcamera support
# https://bbs.archlinux.org/viewtopic.php?pid=2218247#p2218247
$yay_cmd xdg-desktop-portal
$yay_cmd xdg-desktop-portal-gtk

# Arch specific and window manager
$yay_cmd acpi_call
yay -S --mflags --skipinteg --answerclean N --diffmenu=false acpilight # manually resolve conflicts with xorg-xbacklight
$yay_cmd acpilight
$yay_cmd alsa-tools
$yay_cmd bluez
$yay_cmd bluez-utils
$yay_cmd capnet-assist
$yay_cmd cmst-git
$yay_cmd downgrade
$yay_cmd dunst
$yay_cmd feh
$yay_cmd i3-wm
$yay_cmd i3lock-color
$yay_cmd inotify-tools # used by nvim
$yay_cmd intltool
$yay_cmd kwayland5        # neded for pinentry-qt
$yay_cmd kwindowsystem    # neded for pinentry-qt
$yay_cmd kguiaddons       # neded for pinentry-qt
$yay_cmd libxcrypt-compat # needed for latex biber?
$yay_cmd lsof
$yay_cmd maim
$yay_cmd mesa-demos
$yay_cmd mpv
$yay_cmd networkmanager
$yay_cmd nfs-utils
$yay_cmd nmap
$yay_cmd ntfs-3g
$yay_cmd pavucontrol
$yay_cmd picom
$yay_cmd playerctl
$yay_cmd polybar
$yay_cmd rofi
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
$yay_cmd zip

# Themes
$yay_cmd gnome-themes-extra # includes adwaita-dark theme
$yay_cmd capitaine-cursors
$yay_cmd papirus-icon-theme
$yay_cmd adwaita-qt5-git
$yay_cmd qt5ct
$yay_cmd adwaita-qt6-git
$yay_cmd qt6ct

# Databases
$yay_cmd postgresql
$yay_cmd redis
$yay_cmd sqlite3

# VPN
$yay_cmd globalprotect-openconnect
$yay_cmd openvpn

# CLI
$yay_cmd act
$yay_cmd actionlint
$yay_cmd bat
$yay_cmd bind-tools
$yay_cmd cronie
$yay_cmd ctags
$yay_cmd ctop
$yay_cmd docker
$yay_cmd docker-buildx
$yay_cmd docker-compose
$yay_cmd dragon-drop
$yay_cmd dust
$yay_cmd fastfetch
$yay_cmd fd
$yay_cmd forgit
$yay_cmd fzf
$yay_cmd git-delta
$yay_cmd github-cli
$yay_cmd gnupg
$yay_cmd go-yq
$yay_cmd gobject-introspection
$yay_cmd gopass
$yay_cmd graphviz
$yay_cmd hadolint-bin
$yay_cmd htop
$yay_cmd httping
$yay_cmd hyperfine
$yay_cmd inetutils
$yay_cmd jq
$yay_cmd libgit2
$yay_cmd lsb-release
$yay_cmd lsd
$yay_cmd luacheck
$yay_cmd oath-toolkit
$yay_cmd openssh
$yay_cmd p7zip
$yay_cmd pandoc-cli
$yay_cmd pandoc-crossref
$yay_cmd prettyping
$yay_cmd procs
$yay_cmd qrencode
$yay_cmd ripgrep
$yay_cmd rsync
$yay_cmd sd
$yay_cmd seahorse
$yay_cmd shellcheck
$yay_cmd shfmt
$yay_cmd slides-bin
$yay_cmd socat
$yay_cmd sshfs
$yay_cmd sshpass
$yay_cmd stylua
$yay_cmd taplo-cli
$yay_cmd tealdeer
$yay_cmd tk
$yay_cmd tree
$yay_cmd unrar
$yay_cmd unzip
$yay_cmd virtualbox
$yay_cmd vivid
$yay_cmd w3m
$yay_cmd wget
$yay_cmd zbar
$yay_cmd zip
$yay_cmd zoxide

# Apps
$yay_cmd brave-bin
$yay_cmd connman-gtk
$yay_cmd cups
$yay_cmd cups-pdf
$yay_cmd microsoft-edge-dev-bin
$yay_cmd firefox
$yay_cmd gcolor3
$yay_cmd gnome-font-viewer
$yay_cmd hplip-plugin
$yay_cmd mailspring
$yay_cmd obs-studio
$yay_cmd onedrive-abraunegg
$yay_cmd onlyoffice-bin
$yay_cmd pdfpc
$yay_cmd peek-git
$yay_cmd simple-scan
$yay_cmd slack-desktop
$yay_cmd spotify
$yay_cmd transmission-gtk
$yay_cmd visual-studio-code-bin
$yay_cmd xfce4-power-manager
$yay_cmd zathura
$yay_cmd zathura-djvu
$yay_cmd zathura-pdf-poppler
$yay_cmd zoom

# Cleanup
yay -Yc
