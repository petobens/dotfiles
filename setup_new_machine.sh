#!/usr/bin/env bash
#===============================================================================
#          File: setup_new_machine.sh
#        Author: Pedro Ferrari
#       Created: 25 Mar 2017
# Last Modified: 10 Jul 2017
#   Description: Script to setup a new machine; run it with
#                `bash setup_new_machine.sh`
#===============================================================================
read -p 'This script will erase/override many files. Do you want to run it (y/n)? ' -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[  "$OSTYPE" == 'darwin'* ]]; then
    if ! xcode-select --print-path > /dev/null 2>&1; then
        echo Xcode Command Line Tools...
        xcode-select --install &> /dev/null
        # Wait until XCode command tools are installed
        until xcode-select --print-path > /dev/null 2>&1; do
            sleep 5
        done
    fi
fi

echo Italics tmux terminfo...
tic "$current_dir/tmux-xterm-256color-italic.terminfo"

echo Fonts...
if [[  "$OSTYPE" == 'darwin'* ]]; then
    brew tap caskroom/fonts
    brew cask install font-sourcecodepro-nerd-font
else
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts || exit
    curl -fLo "Sauce Code Pro Nerd Font Complete.ttf" \
    https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/\
    patched-fonts/SourceCodePro/Regular/complete/\
    Sauce%20Code%20Pro%20Nerd%20Font%20Complete.ttf
    echo Installed Sauce Code Pro Nerd Font Complete.ttf font
    cd "$current_dir" || exit
fi

echo Brew...
. "$current_dir/brew.sh"
brew_dir=$(brew --prefix)

echo Python...
pip3 install -r "$current_dir"/requirements.txt
if [  -f "$brew_dir"/bin/python2 ]; then
    pip install -r "$current_dir"/requirements.txt
    # Enable both python2 and python3 ipython kernels
    ipython kernel install
    ipython3 kernel install
fi

if type "tlmgr" > /dev/null 2>&1; then
    echo Latex...
    . "$current_dir/latex.sh"
fi

# TODO: complete this
if type "R" > /dev/null 2>&1; then
    echo R...
    mkdir -p "$brew_dir/lib/R/site-library"
fi

if type "npm" > /dev/null 2>&1; then
    echo Node.js...
    . "$current_dir/npm.sh"
fi

echo Ruby...
sudo gem install sqlint --conservative

echo Symlinks...
. "$current_dir/symlinks.sh"

echo Nvim...
nvim +qall

echo Extra settings...
. "$current_dir/extras.sh"
