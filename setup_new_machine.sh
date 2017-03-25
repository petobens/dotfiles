#!/usr/bin/env bash
#===============================================================================
#          File: setup_new_machine.sh
#        Author: Pedro Ferrari
#       Created: 25 Mar 2017
# Last Modified: 25 Mar 2017
#   Description: Script to setup a new machine
#===============================================================================
# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo Brew...
source "$current_dir/brew.sh"
brew_dir=$(brew --prefix)

echo Symlinks...
source "$current_dir/symlinks.sh"

echo Nvim...
nvim +qall

echo Python...
pip3 install -r "$current_dir"/requirements.txt
if [  -f "$brew_dir"/bin/python2 ]; then
    pip install -r "$current_dir"/requirements.txt
fi

echo Latex...
# TODO: complete this


echo R...
# TODO: complete this

echo Node.js...
npm install -g eslint
npm install -g jsonlint

echo Ruby...
sudo gem install sqlint --conservative
