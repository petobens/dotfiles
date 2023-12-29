#!/usr/bin/env bash

# Set default shell to latest bash
sudo bash -c "echo $(command -v bash) >> /etc/shells"
sudo chsh -s "$(command -v bash)"

# Nvim extras
if type "luarocks" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Installing luarocks packages...\\033[0m"
    luarocks --local --lua-version 5.1 install magick
fi

# Extra packages
if [ ! -f "$HOME/git-repos/private/trueline/trueline.sh" ]; then
    git clone https://github.com/petobens/trueline ~/git-repos/private/trueline
fi
if type "ranger" > /dev/null 2>&1; then
    # Install ranger plugins and scope.sh executable
    echo -e "\\033[1;34m--> Installing ranger devicons...\\033[0m"
    mkdir -p "$HOME/.config/ranger/plugins"
    git clone https://github.com/alexanderjeurissen/ranger_devicons "$HOME/.config/ranger/plugins/ranger_devicons"
    ranger --copy-config=scope
fi

# Bash completions (see: https://github.com/pypa/pipenv/issues/1247)
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi
else
    base_pkg_dir='/usr'
fi
if type "poetry" > /dev/null 2>&1; then
    poetry completions bash | sudo tee "$base_pkg_dir/share/bash-completion/completions/poetry"
    poetry config virtualenvs.prefer-active-python true
fi

# Git access tokens and (go)pass settings
if type "gopass" > /dev/null 2>&1; then
    # Set some gopass settings
    echo -e "\\033[1;34m--> Setting (go)pass options...\\033[0m"
    gopass config autoclip false
    gopass config notifications false
    gopass config path "$HOME/.password-store"
    echo -e "\\033[1;34m--> Generating gitlab access token file...\\033[0m"
    gopass git/gitlab/access_token > "$HOME/.gitlab_access_token"
    echo "Created .gitlab_access_token file"
    if type "gh" > /dev/null 2>&1; then
        gh auth login
    fi
fi

# Reload GPG agent since we change the gpg config
if type "gpg-connect-agent" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Reloading GPG agent...\\033[0m"
    gpg-connect-agent reloadagent /bye
fi

# VSCode Extensions
if type "code" > /dev/null 2>&1; then
    if [ -f "$HOME/.config/Code/User/extensions.txt" ]; then
        echo -e "\\033[1;34m--> Installing VSCode Extensions...\\033[0m"
        xargs -a "$HOME/.config/Code/User/extensions.txt" -n 1 code --install-extension
    fi
fi

# OS-Specific
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if [ -d "/Applications/Skim.app/" ]; then
        # Auto reload files
        defaults write -app Skim SKAutoReloadFileUpdate -boolean true
        # Synctex (with neovim)
        defaults write -app Skim SKTeXEditorPreset "Custom"
        defaults write -app Skim SKTeXEditorCommand "nvr"
        defaults write -app Skim SKTeXEditorArguments "--remote-silent +\'\'%line\'\' %file"
    fi
else
    # We need to add our user to the "video" group in order to handle screen brightness
    if type "xbacklight" > /dev/null 2>&1; then
        sudo usermod -a -G video "$USER"
    fi

    # xfce4-power-manager
    if type "xfce4-power-manager" > /dev/null 2>&1; then
        x4fce_cmd="xfconf-query --channel xfce4-power-manager --property /xfce4-power-manager"
        eval "$x4fce_cmd/general-notification --set false"
    fi

    # Create XDG directories
    if type "xdg-user-dirs-update" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Creating missing XDG directories...\\033[0m"
        dirs=("Desktop" "Documents" "Downloads" "Music" "Pictures" "Videos"
            "Public" "Templates")
        for dir in "${dirs[@]}"; do
            if [ "$dir" == "Templates" ]; then
                xdg-user-dirs-update --set "${dir^^}" "$HOME"
                continue
            fi
            mkdir -p "$HOME/$dir"
            xdg-user-dirs-update --set "${dir^^}" "$HOME/$dir"
        done
        mkdir -p "$HOME/.local/share"
        xdg-user-dirs-update --set DATA_HOME "$HOME/.local/share"
    fi

    # Set some default apps on Linux
    if type "xdg-mime" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Setting default apps for specific filetypes...\\033[0m"
        if type "zathura" > /dev/null 2>&1; then
            xdg-mime default org.pwmt.zathura-pdf-poppler.desktop application/pdf
        fi
        if type "vimiv" > /dev/null 2>&1; then
            xdg-mime default vimiv.desktop image/gif
        fi
        if type "freeoffice-textmaker" > /dev/null 2>&1; then
            xdg-mime default freeoffice-textmaker.desktop application/octet-stream
        fi
        if type "nvim" > /dev/null 2>&1; then
            # Note we need something like `Exec=alacritty -e nvim %F` in /usr/share/nvim.desktop
            xdg-mime default nvim.desktop text/plain
        fi
    fi

    # Manage docker as non-root and change image directory
    if type "docker" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Managing docker as non-root...\\033[0m"
        sudo groupadd docker
        sudo usermod -aG docker "$USER"
        echo -e "\\033[1;34m--> Changing docker image cache dir...\\033[0m"
        # Note we can check that this worked with `docker info`
        sudo mkdir -p /etc/docker
        sudo -E /usr/bin/bash -c 'cat > /etc/docker/daemon.json << EOF
{
    "data-root": "$HOME/.cache/docker"
}
EOF'
        mkdir -p "$HOME/.cache/docker"
        sudo systemctl enable docker
        sudo systemctl restart docker
    fi

    # Enable some services
    echo -e "\\033[1;34m--> Enabling some systemd services...\\033[0m"
    # Start pipewire
    systemctl --user enable pipewire.service
    systemctl --user start pipewire.service
    systemctl --user enable pipewire-pulse.service
    systemctl --user start pipewire-pulse.service
    systemctl --user enable wireplumber.service
    systemctl --user start wireplumber.service
    # Time Sync (ntp)
    sudo systemctl enable systemd-timesyncd.service
    sudo systemctl start systemd-timesyncd.service
    # Connman
    sudo systemctl enable connman.service
    # Lock
    if [ -f /etc/systemd/system/sleeplock.service ]; then
        sudo systemctl enable sleeplock.service
        sudo systemctl start sleeplock.service
    fi
    # Bluetooth
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    sudo rfkill unblock all # unblock all devices
    sudo systemctl restart bluetooth.service
    # TLP
    sudo systemctl enable tlp.service
    sudo systemctl start tlp.service
    # Printer
    sudo systemctl enable cups.service
    sudo systemctl start cups.service
    # Disable rfkill (for tlp)
    sudo systemctl mask systemd-rfkill.service
    sudo systemctl mask systemd-rfkill.socket
    # SSH
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    # Remove previous pacman cache dir (we changed it in pacman.conf)
    echo -e "\\033[1;34m--> Removing old pacman cache dir...\\033[0m"
    sudo rm -rf /var/cache/pacman
fi
