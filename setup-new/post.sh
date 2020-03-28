#!/usr/bin/env bash

# Set default shell to latest bash
sudo bash -c "echo $(command -v bash) >> /etc/shells"
sudo chsh -s "$(command -v bash)"

# Extra packages
if [ ! -f "$HOME/git-repos/private/trueline/trueline.sh" ]; then
    git clone https://github.com/petobens/trueline ~/git-repos/private/trueline
fi
if [ ! -f "$HOME/.local/bin/forgit.plugin.zsh" ]; then
    # Forgit (fzf and git integration)
    sudo mkdir -p ~/.local/bin/
    wget https://raw.githubusercontent.com/wfxr/forgit/master/forgit.plugin.zsh -P ~/.local/bin
fi
if type "gem" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Installing sqlint...\\033[0m"
    gem install sqlint
fi
if type "mongo" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Installing mongo-hacker...\\033[0m"
    git clone https://github.com/TylerBrock/mongo-hacker
    (
        cd mongo-hacker || exit
        make install
    )
    # rm -rf mongo-hacker # (this erases config file)
fi
if type "ranger" > /dev/null 2>&1; then
    # Install ranger plugins and scope.sh executable
    echo -e "\\033[1;34m--> Installing ranger devicons...\\033[0m"
    git clone https://github.com/alexanderjeurissen/ranger_devicons
    (
        cd ranger_devicons || exit
        make install
    )
    rm -rf ranger_devicons
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
if type "pipenv" > /dev/null 2>&1; then
    pipenv --completion | sudo tee "$base_pkg_dir/share/bash-completion/completions/pipenv"
fi
if type "poetry" > /dev/null 2>&1; then
    poetry completions bash | sudo tee "$base_pkg_dir/share/bash-completion/completions/poetry"
fi

# Git access tokens and (go)pass settings
if type "gopass" > /dev/null 2>&1; then
    # Set some gopass settings
    echo -e "\\033[1;34m--> Setting (go)pass options...\\033[0m"
    gopass config autosync false
    gopass config noconfirm true
    echo -e "\\033[1;34m--> Generating gitlab access token file...\\033[0m"
    gopass git/gitlab/access_token > "$HOME/.gitlab_access_token"
    echo "Created .gitlab_access_token file"
fi

# OS-Specific
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if [ -d "/Applications/Skim.app/" ]; then
        # Auto reload files
        defaults write -app Skim SKAutoReloadFileUpdate -boolean true
        # Synctex (with neovim)
        defaults write -app Skim SKTeXEditorPreset "Custom"
        defaults write -app Skim SKTeXEditorCommand  "nvr"
        defaults write -app Skim SKTeXEditorArguments "--remote-silent +\'\'%line\'\' %file"
    fi
else
    # Create XDG directories
    if type "xdg-user-dirs-update" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Creating missing XDG directories...\\033[0m"
        dirs=("Desktop" "Documents" "Downloads" "Music" "Pictures" "Videos"
        "Public" "Templates")
        for dir in "${dirs[@]}"; do
            if [ "$dir" ==  "Templates" ]; then
                xdg-user-dirs-update --set "${dir^^}" "$HOME"
                continue
            fi
            mkdir -p "$HOME/$dir"
            xdg-user-dirs-update --set "${dir^^}" "$HOME/$dir"
        done
    fi

    # Set some default apps on Linux
    if type "xdg-mime" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Setting default apps for specific filetypes...\\033[0m"
        if type "zathura" > /dev/null 2>&1; then
            xdg-mime default org.pwmt.zathura-pdf-mupdf.desktop application/pdf
        fi
        if type "vimiv" > /dev/null 2>&1; then
            xdg-mime default vimiv.desktop image/gif
        fi
        if type "freeoffice-textmaker" > /dev/null 2>&1; then
            xdg-mime default freeoffice-textmaker.desktop application/octet-stream
        fi
    fi

    # Manage docker as non-root and change image directory
    if type "docker" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Managing docker as non-root...\\033[0m"
        sudo groupadd docker
        sudo usermod -aG docker "$USER"
        echo -e "\\033[1;34m--> Changing image cache dir...\\033[0m"
        # Note we can check that this worked with `docker info`
        sudo -E /usr/bin/bash -c 'cat > /etc/docker/daemon.json << EOF
        {
          "data-root": "$HOME/.cache/docker"
        }
        EOF'
        sudo systemctl enable docker
        sudo systemctl restart docker
    fi

    # Enable some services
    if [ -f /etc/systemd/system/sleeplock.service ]; then
        echo -e "\\033[1;34m--> Enabling some systemd services...\\033[0m"
        # Start pulseaudio (if daemon is not already running which it should)
        pulseaudio --start
        # Connman
        sudo systemctl enable connman.service
        # Lock
        sudo systemctl enable sleeplock.service
        sudo systemctl start sleeplock.service
        # Bluetooth
        sudo systemctl enable bluetooth.service
        sudo systemctl start bluetooth.service
        # TLP
        sudo systemctl enable tlp.service
        sudo systemctl start tlp.service
        # Printer
        sudo systemctl enable org.cups.cupsd.service
        sudo systemctl start org.cups.cupsd.service
    fi

    # Remove previous pacman cache dir (we changed it in pacman.conf)
    echo -e "\\033[1;34m--> Removing old pacman cache dir...\\033[0m"
    sudo rm -rf /var/cache/pacman
fi
