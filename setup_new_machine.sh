#!/usr/bin/env bash
#===============================================================================
#          File: setup_new_machine.sh
#        Author: Pedro Ferrari
#       Created: 25 Mar 2017
# Last Modified: 26 Mar 2017
#   Description: Script to setup a new machine
#===============================================================================
# Ask for sudo right away and get this script directory
# TODO: Give message about commenting some parts
sudo echo -n
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo Brew...
source "$current_dir/brew.sh"
brew_dir=$(brew --prefix)

echo Symlinks...
source "$current_dir/symlinks.sh"

echo Fonts...
if [[  "$OSTYPE" == 'darwin'* ]]; then
    cd ~/Library/Fonts || exit
else
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts || exit
fi
curl -fLo "Sauce Code Pro Nerd Font Complete.ttf" \
https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/\
SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete.ttf
echo Installed Sauce Code Pro Nerd Font Complete.ttf font
cd "$current_dir" || exit

echo Nvim...
nvim +qall

echo Python...
pip3 install -r "$current_dir"/requirements.txt
if [  -f "$brew_dir"/bin/python2 ]; then
    pip install -r "$current_dir"/requirements.txt
fi

echo Latex...
# TODO: complete this; move my biblatex settings to github and use lacheck

echo R...
# TODO: complete this

echo Node.js...
npm install -g eslint
npm install -g jsonlint

echo Ruby...
sudo gem install sqlint --conservative
