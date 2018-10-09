#!/usr/bin/env bash

# Set default shell to latest bash
sudo bash -c "echo $(command -v bash) >> /etc/shells"
sudo chsh -s "$(command -v bash)"

# Alacritty
if type "cargo" > /dev/null 2>&1; then
    echo "Installing Alacritty..."
    git clone https://github.com/jwilm/alacritty.git
    (
        cd alacritty || exit
        cargo build --release
        if [[  "$OSTYPE" == 'darwin'* ]]; then
            echo "Moving Alacritty.app to Applications folder..."
            make app
            cp -r target/release/osx/Alacritty.app /Applications/
        else
            sudo rm -rf /usr/local/bin/alacritty
            sudo cp target/release/alacritty /usr/local/bin
        fi
    )
    rm -rf alacritty
fi

# Mongo db improvements
if type "mongo" > /dev/null 2>&1; then
    echo "Installing mongo-hacker..."
    git clone https://github.com/TylerBrock/mongo-hacker
    (
        cd mongo-hacker || exit
        make install
    )
    # rm -rf mongo-hacker # (this erases config file)
fi

# Install ranger plugins and scope.sh executable
if type "ranger" > /dev/null 2>&1; then
    git clone https://github.com/alexanderjeurissen/ranger_devicons
    (
        cd ranger_devicons || exit
        make install
    )
    rm -rf ranger_devicons
    ranger --copy-config=scope
fi

# Mac
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if [ -d "/Applications/Skim.app/" ]; then
        # Auto reload files
        defaults write -app Skim SKAutoReloadFileUpdate -boolean true
        # Synctex (with neovim)
        defaults write -app Skim SKTeXEditorPreset "Custom"
        defaults write -app Skim SKTeXEditorCommand  "nvr"
        defaults write -app Skim SKTeXEditorArguments "--remote-silent +\'\'%line\'\' %file"
    fi
fi

# Linux
if [ "$OSTYPE" == 'linux-gnu' ]; then
    # Create XDG directories
    if type "xdg-user-dirs-update" > /dev/null 2>&1; then
        echo "Creating missing XDG directories..."
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
        echo "Setting default apps for specific filetypes..."
        if type "zathura" > /dev/null 2>&1; then
            xdg-mime default org.pwmt.zathura-pdf-mupdf.desktop application/pdf
        fi
        if type "mpv" > /dev/null 2>&1; then
            xdg-mime default mpv.desktop image/gif
        fi
    fi

    # Manage docker as non-root
    if type "docker" > /dev/null 2>&1; then
        echo "Manage docker as non-root..."
        sudo groupadd docker
        sudo usermod -aG docker "$USER"
    fi

    # Enable some services
    if [ -f /etc/systemd/system/sleeplock.service ]; then
        sudo systemctl enable sleeplock.service
        sudo systemctl start sleeplock.service
    fi
fi
