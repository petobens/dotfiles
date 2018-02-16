#!/usr/bin/env bash
read -p 'This script will erase/override many files. Do you want to run it (y/n)? ' -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"

# We need xcode command tools on Mac
if [[  "$OSTYPE" == 'darwin'* ]]; then
    if ! xcode-select --print-path > /dev/null 2>&1; then
        echo Installing Xcode Command Line Tools...
        xcode-select --install &> /dev/null
        # Wait until XCode command tools are installed
        until xcode-select --print-path > /dev/null 2>&1; do
            sleep 5
        done
    fi
fi

read -p "Do you want to install brew packages (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Brew packages...
    . "$current_dir/brew.sh"
    brew_dir=$(brew --prefix)
fi

read -p "Do you want to install tmux terminfo with italics support (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Italics tmux terminfo...
    tic "$parent_dir/tmux-xterm-256color-italic.terminfo"
fi

read -p "Do you want to install Nerd fonts with fancy glyphs (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Nerd Fonts...
    if [[  "$OSTYPE" == 'darwin'* ]]; then
        brew tap caskroom/fonts
        brew cask install font-sourcecodepro-nerd-font
        # Nerd fonts Source Code Pro version doesn't have italics so we install
        # the official version
        brew cask install font-source-code-pro
    else
        mkdir -p ~/.local/share/fonts
        cd ~/.local/share/fonts || exit
        curl -fLo "Sauce Code Pro Nerd Font Complete.ttf" \
            https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/\
            patched-fonts/SourceCodePro/Regular/complete/\
            Sauce%20Code%20Pro%20Nerd%20Font%20Complete.ttf
        echo Installed Sauce Code Pro Nerd Font Complete.ttf font
        # TODO: Add ubuntu installation instructions for official Source Code
        # Pro
        cd "$current_dir" || exit
    fi
fi

read -p "Do you want to install python modules (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Python3 modules...
    pip3 install -r "$parent_dir"/requirements.txt
    if [  -f "$brew_dir"/bin/python2 ]; then
        echo Installing Python2 modules...
        pip install -r "$parent_dir"/requirements.txt
        # Enable both python2 and python3 ipython kernels
        ipython kernel install
    fi
    ipython3 kernel install
fi

if type "tlmgr" > /dev/null 2>&1; then
    read -p "Do you want to install LaTeX packages (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo Installing Latex packages...
        . "$current_dir/latex.sh"
    fi
fi

# TODO: complete this
if type "R" > /dev/null 2>&1; then
    read -p "Do you want to install R libraries (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo Installing R libraries...
        mkdir -p "$brew_dir/lib/R/site-library"
    fi
fi

if type "npm" > /dev/null 2>&1; then
    read -p "Do you want to install node libraries (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo Installing Node.js libraries...
        . "$current_dir/npm.sh"
    fi
fi

read -p "Do you want to install extra Ruby libraries (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Ruby libraries...
    sudo gem install sqlint --conservative
fi

read -p "Do you want to generate symlinks to these dotfiles? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Generating symlinks...
    . "$current_dir/symlinks.sh"
fi

echo Installing nvim packages...
nvim +qall

read -p "Do you want to install extra settings? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing extra settings...
    . "$current_dir/extras.sh"
fi
