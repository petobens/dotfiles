#!/usr/bin/env bash
# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"

# Use our pacman conf
if type "pacman" > /dev/null 2>&1; then
    sudo ln -fTs "$parent_dir/arch/config/pacman.conf" "/etc/pacman.conf"
    echo Created /etc/pacman.conf symlink
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

yay_cmd='yay -S --nodiffmenu --answerclean N --needed --force --removemake'

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
$yay_cmd python-pipenv
$yay_cmd pyenv
$yay_cmd rust
if ! type "tlmgr" > /dev/null 2>&1; then
    read -p "Do you want to install latex (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
        tar xvzf install-tl-unx.tar.gz
        (
            builtin cd install-tl-*/ || exit
            sudo ./install-tl
        )
        rm -rf install-tl-*/
    fi
fi
read -p "Do you want to install R (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    $yay_cmd r
fi
read -p "Do you want to install Node.js (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    $yay_cmd nodejs
    $yay_cmd npm
fi

# Neovim and tmux and more bash
$yay_cmd neovim-git
$yay_cmd python-neovim
$yay_cmd neovim-remote
$yay_cmd tmux
$yay_cmd powerline
$yay_cmd python-powerline-gitstatus

# Arch specific and window manager
$yay_cmd acpi_call
$yay_cmd alsa-tools
$yay_cmd compton
$yay_cmd connman
$yay_cmd dunst
$yay_cmd dunstify
$yay_cmd feh
$yay_cmd i3-gaps
$yay_cmd i3ipc-python-git
$yay_cmd i3lock-color-git
$yay_cmd maim
$yay_cmd mpv
$yay_cmd ntfs-3g
$yay_cmd pulseaudio
$yay_cmd pavucontrol
$yay_cmd playerctl
$yay_cmd polybar-git
$yay_cmd raiseorlaunch
$yay_cmd reflector
$yay_cmd rofi-git
$yay_cmd rofi-dmenu
$yay_cmd tabbed
$yay_cmd tlp
$yay_cmd udiskie
$yay_cmd update-grub
$yay_cmd upower
$yay_cmd unclutter-xfixes-git
$yay_cmd xdg-user-dirs
$yay_cmd xdotool
$yay_cmd xsendkey
$yay_cmd xclip
$yay_cmd xsel

# Themes
$yay_cmd capitaine-cursors
$yay_cmd papirus-icon-theme

# Databases
$yay_cmd gqlplus # depends on adding oracle to pacman and installing sqlplus
$yay_cmd mongodb
$yay_cmd mongodb-tools
$yay_cmd postgresql
$yay_cmd protobuf # Required by python's mysql-connector
$yay_cmd redis
$yay_cmd sqlite3

# CLI
$yay_cmd bat
$yay_cmd beautysh
$yay_cmd docker
$yay_cmd fd
$yay_cmd fzf
$yay_cmd gnupg
$yay_cmd htop
$yay_cmd neofetch-git
$yay_cmd neomutt
$yay_cmd openconnect-git
$yay_cmd openssh
$yay_cmd openvpn
$yay_cmd pandoc
$yay_cmd pandoc-citeproc
$yay_cmd pass
$yay_cmd pass-update
$yay_cmd rlwrap
$yay_cmd rsync
$yay_cmd shellcheck
$yay_cmd socat
$yay_cmd sshpass
$yay_cmd stoken-git
$yay_cmd the_silver_searcher
$yay_cmd trash-cli
$yay_cmd tree
$yay_cmd unimatrix
$yay_cmd universal-ctags-git
$yay_cmd unrar
$yay_cmd unzip
$yay_cmd w3m
$yay_cmd yamllint
$yay_cmd zip

# Z (jump around)
if ! type "z" > /dev/null 2>&1; then
    sudo mkdir -p ~/.local/bin/
    wget https://raw.githubusercontent.com/rupa/z/master/z.sh -P ~/.local/bin
fi

# Apps
$yay_cmd chromium
$yay_cmd connman-gtk
$yay_cmd cups
$yay_cmd cups-pdf
$yay_cmd hplip-plugin
$yay_cmd libreoffice-fresh
$yay_cmd onedrive-abraunegg-git
$yay_cmd peek
$yay_cmd ranger-git
$yay_cmd slack-desktop
$yay_cmd skypeforlinux-preview-bin
$yay_cmd spotify
$yay_cmd thunderbird
$yay_cmd transmission-gtk
$yay_cmd xfce4-power-manager
$yay_cmd zathura
$yay_cmd zathura-pdf-mupdf

yay -c

# Python binaries (can also be installed with yay but we do it with pipsi to
# avoid clashing dependencies)
$yay_cmd python-pipsi
pipsi install ipython
pipsi install jupyter-core
pipsi install pgcli
pipsi install mycli
# FIXME: Not working:
# pipsi install mssql-cli
