#!/usr/bin/env bash
brew_dir=$(brew --prefix)

# Skim (PDF viewer)
if [ -d "/Applications/Skim.app/" ]; then
    # Auto reload files
    defaults write -app Skim SKAutoReloadFileUpdate -boolean true
    # Synctex (with neovim)
    defaults write -app Skim SKTeXEditorPreset "Custom"
    defaults write -app Skim SKTeXEditorCommand  "nvr"
    defaults write -app Skim SKTeXEditorArguments "--remote-silent +\'\'%line\'\' %file"
fi

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
        fi
    )
    rm -rf alacritty
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

# Install fzf plugins
if type "fzf" > /dev/null 2>&1; then
    git clone https://github.com/urbainvaes/fzf-marks.git
    (
        cd fzf-marks || exit
        cp fzf-marks.plugin.bash  "$brew_dir/opt/fzf/shell"
    )
    rm -rf fzf-marks
fi
