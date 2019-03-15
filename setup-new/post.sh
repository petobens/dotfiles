#!/usr/bin/env bash

# Set default shell to latest bash
sudo bash -c "echo $(command -v bash) >> /etc/shells"
sudo chsh -s "$(command -v bash)"

# Extra packages
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

# Pipenv completions (see: https://github.com/pypa/pipenv/issues/1247)
if type "pipenv" > /dev/null 2>&1; then
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        if type "brew" > /dev/null 2>&1; then
            base_pkg_dir=$(brew --prefix)
        else
            base_pkg_dir='/usr/local'
        fi
    else
        base_pkg_dir='/usr'
    fi
    pipenv --completion | sudo tee "$base_pkg_dir/share/bash-completion/completions/pipenv"
fi

# Git access tokens
if type "pass" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Generating gitlab access token file...\\033[0m"
    pass git/gitlab/access_token > "$HOME/.gitlab_access_token"
    echo "Created .gitlab_access_token file"
fi
# Make git use diff-so-fancy
if type "diff-so-fancy" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Setting diff-so-fancy as default git diff tool...\\033[0m"
    diff-so-fancy --set-defaults
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
        if type "mpv" > /dev/null 2>&1; then
            xdg-mime default mpv.desktop image/gif
        fi
    fi

    # Manage docker as non-root
    if type "docker" > /dev/null 2>&1; then
        echo -e "\\033[1;34m--> Managing docker as non-root...\\033[0m"
        sudo groupadd docker
        sudo usermod -aG docker "$USER"
    fi

    # Enable some services
    if [ -f /etc/systemd/system/sleeplock.service ]; then
        echo -e "\\033[1;34m--> Enabling some systemd services...\\033[0m"
        sudo systemctl enable sleeplock.service
        sudo systemctl start sleeplock.service
    fi
fi
