#!/usr/bin/env bash

# Check bash major version
bash_version=${BASH_VERSION:0:1}

# Ask for dotfiles dir (the -i flag is only available on Bash 4)
cur_dir="$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")"
if [[ $bash_version -gt 3 ]]; then
    read -r -e -p "Enter dotfiles directory: " -i "$cur_dir" dotfiles_dir
else
    read -r -e -p "Enter dotfiles directory: " dotfiles_dir
fi
while [ ! -d "$dotfiles_dir" ]; do
    (>&2 echo "$dotfiles_dir: No such directory")
    if [[ $bash_version -gt 3 ]]; then
        read -r -e -p "Enter dotfiles directory: " -i "$HOME/" dotfiles_dir
    else
        read -r -e -p "Enter dotfiles directory: " dotfiles_dir
    fi
done
dotfiles_dir=${dotfiles_dir%/}   # Strip last (potential) slash

# Creating missing dirs
echo Creating symlinks under "$HOME"/
mkdir -p "$HOME/.config/"

# First symlink bashrc and reload it without logging out and back in
if type "bash" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/bashrc" "$HOME/.bashrc"
    echo Created .bashrc symlink
    ln -fTs "$dotfiles_dir/bash_profile" "$HOME/.bash_profile"
    echo Created .bash_profile symlink
fi
. "$HOME/.bashrc"

# Language related
if type "python" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/python/pdbrc" "$HOME/.pdbrc"
    echo Created .pdbrc symlink
    if type "pip" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/config/pip" "$HOME/.config/pip"
        echo Created .config/pip folder symlink
    fi
fi
if type "ipython" > /dev/null 2>&1; then
    mkdir -p "$HOME/.ipython/profile_default/startup"
    ln -fTs "$dotfiles_dir/python/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"
    echo Created .ipython/profile_default/ipython_config symlink
    ln -fTs "$dotfiles_dir/python/ipython_startup.py" "$HOME/.ipython/profile_default/startup/ipython_startup.py"
    echo Created .ipython/profile_default/startup/ipython_startup symlink
fi
if type "R" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/R/Rprofile" "$HOME/.Rprofile"
    echo Created .Rprofile symlink
fi

# Coding environment
if type "alacritty" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/config/alacritty" "$HOME/.config/alacritty"
    echo Created .config/alacritty folder symlink
fi
if type "tmux" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/tmux" "$HOME/.tmux"
    echo Created .tmux folder symlink
fi
if type "powerline-daemon" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/config/powerline" "$HOME/.config/powerline"
    echo Created .config/powerline folder symlink
fi
if type "vim" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/vim" "$HOME/.vim"
    echo Created .vim folder symlink
    ln -fTs "$dotfiles_dir/vimrc" "$HOME/.vimrc"
    echo Created .vimrc symlink
fi
if type "nvim" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/vim" "$HOME/.config/nvim"
    echo Created .config/nvim folder symlink
    ln -fTs "$dotfiles_dir/vimrc" "$HOME/.config/nvim/init.vim"
    echo Created .config/nvim/.init.vim symlink
fi
if type "ctags" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/ctags" "$HOME/.ctags"
    echo Created .ctags symlink
fi
# Browser
ln -fTs "$dotfiles_dir/surfingkeysrc.js" "$HOME/.surfingkeysrc"
echo Created .surfingkeysrc symlink

# Linters
if type "vint" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/linters/vintrc.yaml" "$HOME/.vintrc.yaml"
    echo Created .vintrc.yaml symlink
fi
if type "eslint" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/linters/eslintrc.yaml" "$HOME/.eslintrc.yaml"
    echo Created .eslintrc.yaml symlink
fi
if type "tern" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/linters/tern-config" "$HOME/.tern-config"
    echo Created .tern-config symlink
fi
if type "htmlhint" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/linters/htmlhintrc" "$HOME/.htmlhintrc"
    echo Created .htmlhintrc symlink
fi

# Terminal programs
if type "arara" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/arararc.yaml" "$HOME/.arararc.yaml"
    echo Created .arararc.yaml symlink
fi
if type "mutt" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/config/mutt" "$HOME/.config/mutt"
    echo Created .config/mutt folder symlink
fi
if type "ranger" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/config/ranger" "$HOME/.config/ranger"
    echo Created .config/ranger folder symlink
fi

# OS dependent
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if open -Ra "hammerspoon" ; then
        ln -fTs "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
        echo Created .hammerspoon folder symlink
    fi
else
    if [ -d "$dotfiles_dir/arch/bin" ]; then
        ln -fTs "$dotfiles_dir/arch/bin" "$HOME/bin"
        echo Created bin folder symlink
    fi
    # Window manager related
    if type "i3" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/i3" "$HOME/.config/i3"
        echo Created .config/i3 folder symlink
        if type "xfce4-power-manager" > /dev/null 2>&1; then
            sudo ln -fTs "$dotfiles_dir/arch/config/i3/i3lock_fancy.sh" "/usr/local/bin/xflock4"
            echo Created /usr/local/bin/xflock4 symlink to i3lock
        fi
        sudo ln -fTs "$dotfiles_dir/arch/systemd/sleeplock.service" "/etc/systemd/system/sleeplock.service"
        echo Created /etc/systemd/system/sleeplock.service symlink
    fi
    if type "polybar" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/polybar" "$HOME/.config/polybar"
        echo Created .config/polybar folder symlink
    fi
    if type "Xorg" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/X/xinitrc" "$HOME/.xinitrc"
        echo Created .xinitrc symlink
        ln -fTs "$dotfiles_dir/arch/X/xresources" "$HOME/.Xresources"
        echo Created .Xresources symlink
        ln -fTs "$dotfiles_dir/arch/X/xmodmap" "$HOME/.Xmodmap"
        echo Created .Xmodmap symlink
    fi
    if type "compton" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/compton.conf" "$HOME/.config/compton.conf"
        echo Created .config/compton.conf symlink
    fi
    if [ -d "$dotfiles_dir/arch/config/gtk" ]; then
        ln -fTs "$dotfiles_dir/arch/config/gtk/gtk-3.0" "$HOME/.config/gtk-3.0"
        echo Created .config/gtk-3.0 folder symlink
        ln -fTs "$dotfiles_dir/arch/config/gtk/gtkrc-2.0" "$HOME/.gtkrc-2.0"
        echo Created .gtkrc-2.0 symlink
    fi
    if [ -d "$dotfiles_dir/arch/fontconfig" ]; then
        ln -fTs "$dotfiles_dir/arch/fontconfig" "$HOME/fontconfig"
        echo Created fontconfig folder symlink
    fi
    # Applications
    if type "pulseaudio" > /dev/null 2>&1; then
        mkdir -p "$HOME/.pulse/"
        ln -fTs "$dotfiles_dir/arch/pulse/default.pa" "$HOME/.pulse/default.pa"
        echo Created .pulse/default.pa symlink
    fi
    if type "rofi" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/rofi" "$HOME/.config/rofi"
        echo Created .config/rofi folder symlink
    fi
    if type "dunst" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/dunst" "$HOME/.config/dunst"
        echo Created .config/dunst folder symlink
    fi
    if type "feh" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/feh" "$HOME/.config/feh"
        echo Created .config/feh folder symlink
    fi
    if type "zathura" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/zathura" "$HOME/.config/zathura"
        echo Created .config/zathura folder symlink
    fi
    if type "mpv" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/mpv" "$HOME/.config/mpv"
        echo Created .config/mpv folder symlink
    fi
    if type "onedrive" > /dev/null 2>&1; then
        ln -fTs "$dotfiles_dir/arch/config/onedrive" "$HOME/.config/onedrive"
        echo Created .config/onedrive folder symlink
    fi
fi

# Git
if type "git" > /dev/null 2>&1; then
    ln -fTs "$dotfiles_dir/gitignore" "$HOME/.gitignore"
    echo Created .gitignore symlink

    read -p "Do you want to create new gitconfig file (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.gitconfig"
        read -r -e -p "Enter git user name: " username
        read -r -e -p "Enter git mail: " mail
        if [[ "$OSTYPE" == 'darwin'* ]]; then
            credential_helper='osxkeychain'
        else
            credential_helper='/usr/share/git/credential/netrc/git-credential-netrc'
        fi
        cat > "$HOME/.gitconfig" << EOF
[user]
    name = $username
    email = $mail
[push]
    default = simple
[core]
    editor = nvim
    excludesfile = ~/.gitignore
[web]
    browser = start
[credential]
    helper = $credential_helper
EOF
        echo Created .gitconfig file
    fi
fi
