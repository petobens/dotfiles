#!/usr/bin/env bash

# Ask for sudo right away
sudo echo -n

# Check bash major version
bash_version=${BASH_VERSION:0:1}

# Ask for dotfiles dir (the -i flag is only available on Bash 4)
cur_dir="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"
if [[ $bash_version -gt 3 ]]; then
    read -r -e -p "Enter dotfiles directory: " -i "$cur_dir" dotfiles_dir
else
    read -r -e -p "Enter dotfiles directory: " dotfiles_dir
fi
while [ ! -d "$dotfiles_dir" ]; do
    (echo >&2 "$dotfiles_dir: No such directory")
    if [[ $bash_version -gt 3 ]]; then
        read -r -e -p "Enter dotfiles directory: " -i "$HOME/" dotfiles_dir
    else
        read -r -e -p "Enter dotfiles directory: " dotfiles_dir
    fi
done
dotfiles_dir=${dotfiles_dir%/} # Strip last (potential) slash

# Creating missing dirs
echo Creating symlinks under "$HOME"/

# Always use coreutils ln command
ln_cmd='ln'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "gln" > /dev/null 2>&1; then
        ln_cmd='gln'
    else
        echo "Coreutils ln (gln) command not found!" 1>&2
        exit 1
    fi
fi

# First symlink bashrc and reload it without logging out and back in
if type "bash" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/bashrc" "$HOME/.bashrc"
    echo Created .bashrc symlink
    $ln_cmd -fTs "$dotfiles_dir/bash_profile" "$HOME/.bash_profile"
    echo Created .bash_profile symlink
    # Load fzf settings
    if type "fzf" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/fzf_bash.sh" "$HOME/.fzf_bash.sh"
        echo Created .fzf_bash.sh symlink
    fi
fi
# shellcheck disable=SC1091
. "$HOME/.bashrc"
# Readline
$ln_cmd -fTs "$dotfiles_dir/inputrc" "$HOME/.inputrc"
echo Created .inputrc symlink

# Language related
if type "python" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/python/pdbrc" "$HOME/.pdbrc"
    echo Created .pdbrc symlink
    $ln_cmd -fTs "$dotfiles_dir/python/pdbrc.py" "$HOME/.pdbrc.py"
    echo Created .pdbrc.py symlink
    if type "pip" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/config/pip" "$HOME/.config/pip"
        echo Created .config/pip folder symlink
    fi
    if [ "$OSTYPE" == 'linux-gnu' ]; then
        $ln_cmd -fTs "$dotfiles_dir/python/matplotlib" "$HOME/.config/matplotlib"
        echo Created .config/matplotlib folder symlink
    fi
    if type "pylint" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/python/pylintrc" "$HOME/.pylintrc"
        echo Created .pylintrc symlink
    fi
    if type "flake8" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/python/flake8" "$HOME/.config/flake8"
        echo Created .config/flake8 symlink
    fi
    if type "mypy" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/python/mypy.ini" "$HOME/.mypy.ini"
        echo Created .mypy.ini symlink
    fi
    if type "isort" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/python/isort.cfg" "$HOME/.isort.cfg"
        echo Created .isort.cfg symlink
    fi
    if type "black" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/python/black.toml" "$HOME/.config/.black.toml"
        echo Created .black.toml symlink
    fi
    if type "ruff" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/python/ruff" "$HOME/.config/ruff"
        echo Created .config/ruff folder symlink
    fi
fi
if type "ipython" > /dev/null 2>&1; then
    mkdir -p "$HOME/.ipython/profile_default/startup"
    $ln_cmd -fTs "$dotfiles_dir/python/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"
    echo Created .ipython/profile_default/ipython_config symlink
    $ln_cmd -fTs "$dotfiles_dir/python/ipython_startup.py" "$HOME/.ipython/profile_default/startup/ipython_startup.py"
    echo Created .ipython/profile_default/startup/ipython_startup symlink
fi
if [ -d "$HOME/.jupyter/lab/user-settings" ]; then
    sudo $ln_cmd -fTs "$dotfiles_dir/python/jupyterlab/overrides.json" "$HOME/.jupyter/lab/user-settings/overrides.json"
    echo Created .jupyter/lab/user-settings/overrides.json symlink
    rm -rf "$HOME/.jupyter/lab/user-settings/jupyterlab_code_formatter"
    $ln_cmd -fTs "$dotfiles_dir/python/jupyterlab/jupyterlab_code_formatter" "$HOME/.jupyter/lab/user-settings/jupyterlab_code_formatter"
    echo Created .jupyter/lab/user-settings/jupyterlab_code_formatter folder symlink
fi
if type "ruby" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/gemrc" "$HOME/.gemrc"
    echo Created .gemrc symlink
fi

# Coding environment
if type "alacritty" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/config/alacritty" "$HOME/.config/alacritty"
    echo Created .config/alacritty folder symlink
fi
if type "kitty" > /dev/null 2>&1; then
    mkdir -p "$HOME/.config/kitty"
    $ln_cmd -fTs "$dotfiles_dir/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    echo Created .config/kitty/kitty.conf symlink
fi
if type "tmux" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/config/tmux" "$HOME/.config/tmux"
    echo Created .config/tmux folder symlink
fi
if type "nvim" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/nvim" "$HOME/.config/nvim"
    echo Created .config/nvim folder symlink
fi
if type "code" > /dev/null 2>&1; then
    mkdir -p "$HOME/.config/Code/User"
    for f in settings.json keybindings.json extensions.txt; do
        $ln_cmd -fTs "$dotfiles_dir/vscode/$f" "$HOME/.config/Code/User/$f"
        echo "Created .config/Code/User/$f symlink"
    done
fi
if type "fd" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/fdignore" "$HOME/.fdignore"
    echo Created .fdignore symlink
fi
if type "vivid" > /dev/null 2>&1; then
    sudo mkdir -p /usr/share/vivid/themes
    sudo $ln_cmd -fTs "$dotfiles_dir/config/vivid/onedarkish.yml" "/usr/share/vivid/themes/onedarkish.yml"
    echo Created /usr/share/vivid/themes/onedarkish.yml symlink
fi
if type "rg" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/config/ripgrep" "$HOME/.config/ripgrep"
    echo Created .config/ripgrep folder symlink
fi
if type "bat" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/config/bat" "$HOME/.config/bat"
    echo Created .config/bat folder symlink
fi
# Browser
$ln_cmd -fTs "$dotfiles_dir/surfingkeysrc.js" "$HOME/.surfingkeysrc"
echo Created .surfingkeysrc symlink

# Linters
if type "eslint" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/eslintrc.yaml" "$HOME/.eslintrc.yaml"
    echo Created .eslintrc.yaml symlink
fi
if type "htmlhint" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/htmlhintrc" "$HOME/.htmlhintrc"
    echo Created .htmlhintrc symlink
fi
if type "markdownlint" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/markdownlint.json" "$HOME/.markdownlint.json"
    echo Created .markdownlint.json symlink
fi
if type "prettierd" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/prettierrc.yaml" "$HOME/.prettierrc.yaml"
    echo Created .prettierrc.yaml symlink
fi
if type "hadolint" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/hadolint.yaml" "$HOME/.config/hadolint.yaml"
    echo Created .config/hadolint.yaml symlink
fi
if type "stylua" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/stylua.toml" "$HOME/.config/stylua.toml"
    echo Created .config/stylua.toml symlink
fi
if type "luacheck" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/luacheckrc" "$HOME/.config/.luacheckrc"
    echo Created .config/.luacheckrc symlink
fi
if type "sqlfluff" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/sqlfluff" "$HOME/.sqlfluff"
    echo Created .sqlfluff symlink
fi
if type "taplo" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/linters/taplo.toml" "$HOME/taplo.toml"
    echo Created taplo.toml symlink
fi
if type "yamllint" > /dev/null 2>&1; then
    sudo mkdir -p "$HOME/.config/yamllint"
    sudo $ln_cmd -fTs "$dotfiles_dir/linters/yamllint.yaml" "$HOME/.config/yamllint/config"
    echo Created "$HOME/.config/yamllint/config" symlink
fi

# Terminal programs
if type "less" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/lesskey" "$HOME/.lesskey"
    echo Created .lesskey symlink
fi
if type "ssh" > /dev/null 2>&1; then
    if [ -f "$HOME"/OneDrive/programming/arch/ssh/config ]; then
        sudo mkdir -p "$HOME/.ssh"
        sudo $ln_cmd -fTs "$HOME/OneDrive/programming/arch/ssh/config" "$HOME/.ssh/config"
        echo Created .ssh/config symlink
        sudo $ln_cmd -fTs "$HOME/OneDrive/programming/arch/ssh/id_rsa.pub" "$HOME/.ssh/id_rsa.pub"
        echo Created .ssh/id_rsa.pub symlink
    fi
fi
if type "arara" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/arararc.yaml" "$HOME/.arararc.yaml"
    echo Created .arararc.yaml symlink
fi
if type "mutt" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/config/mutt" "$HOME/.config/mutt"
    echo Created .config/mutt folder symlink
fi
if type "ranger" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/config/ranger" "$HOME/.config/ranger"
    echo Created .config/ranger folder symlink
fi
if type "pgcli" > /dev/null 2>&1; then
    sudo mkdir -p "$HOME/.config/pgcli"
    sudo $ln_cmd -fTs "$dotfiles_dir/dbs/pgcli_config" "$HOME/.config/pgcli/config"
    echo Created ".config/pgcli/config" symlink
fi
if type "litecli" > /dev/null 2>&1; then
    sudo mkdir -p "$HOME/.config/litecli"
    sudo $ln_cmd -fTs "$dotfiles_dir/dbs/sqlite_config" "$HOME/.config/litecli/config"
    echo Created ".config/litecli/config" symlink
fi
if type "gopass" > /dev/null 2>&1; then
    sudo $ln_cmd -fTs "$(command -v gopass)" "$HOME/.local/bin/pass"
    echo Created "$HOME/.local/bin/pass" symlink to gopass
fi
if [ -d "$HOME/.gnupg" ]; then
    sudo $ln_cmd -fTs "$dotfiles_dir/config/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
    echo Created ".gnupg/gpg-agent.conf" symlink
fi

if [ -f "$HOME/OneDrive/programming/arch/git/.netrc.gpg" ]; then
    sudo $ln_cmd -fTs "$HOME/OneDrive/programming/arch/git/.netrc.gpg" "$HOME/.netrc.gpg"
    echo "Created $HOME/.netrc.gpg symlink"
fi

# OS dependent
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if open -Ra "hammerspoon"; then
        $ln_cmd -fTs "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
        echo Created .hammerspoon folder symlink
    fi
else
    if [ -d "$dotfiles_dir/arch/bin" ]; then
        $ln_cmd -fTs "$dotfiles_dir/arch/bin" "$HOME/bin"
        echo Created bin folder symlink
        if type "tmux" > /dev/null 2>&1; then
            $ln_cmd -fTs "$dotfiles_dir/config/tmux/tmux_tree" "$HOME/bin/tmux_tree"
            echo Created bin/tmux_tree symlink
        fi
    fi
    if type "pacman" > /dev/null 2>&1; then
        # shellcheck disable=SC2033
        sudo rm /etc/pacman.conf
        sudo $ln_cmd -fTs "$dotfiles_dir/arch/config/pacman.conf" "/etc/pacman.conf"
        echo Created /etc/pacman.conf symlink
    fi
    # Window manager related
    if type "i3" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/i3" "$HOME/.config/i3"
        echo Created .config/i3 folder symlink
        if type "xfce4-power-manager" > /dev/null 2>&1; then
            sudo $ln_cmd -fTs "$dotfiles_dir/arch/config/i3/i3lock_fancy.sh" "/usr/local/bin/xflock4"
            echo Created /usr/local/bin/xflock4 symlink to i3lock
        fi
        sudo $ln_cmd -fTs "$dotfiles_dir/arch/systemd/sleeplock.service" "/etc/systemd/system/sleeplock.service"
        echo Created /etc/systemd/system/sleeplock.service symlink
    fi
    if type "polybar" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/polybar" "$HOME/.config/polybar"
        echo Created .config/polybar folder symlink
    fi
    if type "Xorg" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/X/xinitrc" "$HOME/.xinitrc"
        echo Created .xinitrc symlink
        $ln_cmd -fTs "$dotfiles_dir/arch/X/xresources" "$HOME/.Xresources"
        echo Created .Xresources symlink
        $ln_cmd -fTs "$dotfiles_dir/arch/X/xresources_hidpi" "$HOME/.Xresources_hidpi"
        echo Created .Xresources_hidpi symlink
        $ln_cmd -fTs "$dotfiles_dir/arch/X/xresources_hd_cursor" "$HOME/.Xresources_hd_cursor"
        echo Created .Xresources_hd_cursor symlink
        $ln_cmd -fTs "$dotfiles_dir/arch/X/xmodmap" "$HOME/.Xmodmap"
        echo Created .Xmodmap symlink
    fi
    if type "picom" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/picom" "$HOME/.config/picom"
        echo Created .config/picom folder symlink
    fi
    if type "connmanctl" > /dev/null 2>&1; then
        sudo mkdir -p "/etc/connman"
        # shellcheck disable=SC2033
        sudo cp "$dotfiles_dir/arch/config/connman.conf" "/etc/connman/main.conf"
        echo Copied connman config to /etc/connman/main.conf
    fi
    if [ -d "$dotfiles_dir/arch/config/gtk" ]; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/gtk/gtk-3.0" "$HOME/.config/gtk-3.0"
        echo Created .config/gtk-3.0 folder symlink
        $ln_cmd -fTs "$dotfiles_dir/arch/config/gtk/gtkrc-2.0" "$HOME/.gtkrc-2.0"
        echo Created .gtkrc-2.0 symlink
    fi
    if [ -d "$dotfiles_dir/arch/fontconfig" ]; then
        $ln_cmd -fTs "$dotfiles_dir/arch/fontconfig" "$HOME/fontconfig"
        echo Created fontconfig folder symlink
    fi
    # Applications
    if type "rofi" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/rofi" "$HOME/.config/rofi"
        echo Created .config/rofi folder symlink
    fi
    if type "dunst" > /dev/null 2>&1; then
        mkdir -p "$HOME/.local/share"
        $ln_cmd -fTs "/usr/share/icons" "$HOME/.local/share/icons"
        $ln_cmd -fTs "$dotfiles_dir/arch/config/dunst" "$HOME/.config/dunst"
        echo Created .config/dunst folder symlink
    fi
    if type "feh" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/feh" "$HOME/.config/feh"
        echo Created .config/feh folder symlink
    fi
    if type "vimiv" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/vimiv" "$HOME/.config/vimiv"
        echo Created .config/vimiv folder symlink
    fi
    if type "zathura" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/zathura" "$HOME/.config/zathura"
        echo Created .config/zathura folder symlink
    fi
    if type "pdfpc" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/pdfpc" "$HOME/.config/pdfpc"
        echo Created .config/pdfpc folder symlink
    fi
    if type "mpv" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/mpv" "$HOME/.config/mpv"
        echo Created .config/mpv folder symlink
    fi
    if type "onedrive" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/onedrive" "$HOME/.config/onedrive"
        echo Created .config/onedrive folder symlink
    fi
    if type "wireplumber" > /dev/null 2>&1; then
        $ln_cmd -fTs "$dotfiles_dir/arch/config/wireplumber" "$HOME/.config/wireplumber"
        echo Created .config/wireplumber folder symlink
    fi
    if type "udevadm" > /dev/null 2>&1; then
        mkdir -p "/etc/udev/rules.d"
        # FIXME: Uncomment when figuring it how to reload polybar from udev rule
        # sudo $ln_cmd -fTs "$dotfiles_dir/arch/udev/monitor-hotplug.rules" "/etc/udev/rules.d/99-monitor-hotplug.rules"
        # echo Created /etc/udev/rules.d/99-monitor-hotplug.rules symlink
        # sudo $ln_cmd -fTs "$dotfiles_dir/arch/udev/usb-ethernet.rules" "/etc/udev/rules.d/99-usb-ethernet.rules"
        # echo Created /etc/udev/rules.d/99-usb-ethernet.rules symlink
        sudo $ln_cmd -fTs "$dotfiles_dir/arch/udev/99-webcam.rules" "/etc/udev/rules.d/99-webcam.rules"
        echo Created /etc/udev/rules.d/99-webcam.rules symlink
        sudo $ln_cmd -fTs "$dotfiles_dir/arch/udev/99-backlight.rules" "/etc/udev/rules.d/99-backlight.rules"
        echo Created /etc/udev/rules.d/99-backlight.rules symlink
    fi
fi

# Git
if type "git" > /dev/null 2>&1; then
    $ln_cmd -fTs "$dotfiles_dir/gitignore" "$HOME/.gitignore"
    echo Created .gitignore symlink
    $ln_cmd -fTs "$dotfiles_dir/gitconfig" "$HOME/.gitconfig"
    echo Created .gitconfig file
fi
