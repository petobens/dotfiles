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

if [[  "$OSTYPE" == 'darwin'* ]]; then
    read -p "Do you want to install brew packages (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo Installing Brew packages...
        . "$current_dir/brew.sh"
        brew_dir=$(brew --prefix)
        base_pkg_dir=$brew_dir
    fi
else
    read -p "Do you want to install pacman packages (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo Installing pacman/yay packages...
        . "$current_dir/yay.sh"
    fi
    base_pkg_dir='/usr'
fi

read -p "Do you want to install tmux terminfo with italics support (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Italics tmux terminfo...
    tic "$parent_dir/tmux-xterm-256color-italic.terminfo"
fi

read -p "Do you want to install python modules (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing Python3 modules...
    pip3 install --user -r "$parent_dir"/python/requirements.txt
    pip3 install jupyter
    if [  -f "$base_pkg_dir"/bin/python2 ]; then
        echo Installing Python2 modules...
        pip2 install --user -r "$parent_dir"/python/requirements.txt
        pip2 install jupyter
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

if type "R" > /dev/null 2>&1; then
    read -p "Do you want to install R libraries (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo Installing R libraries...
        . "$current_dir/R.sh"
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

read -p "Do you want to generate symlinks to these dotfiles (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Generating symlinks...
    . "$current_dir/symlinks.sh"
fi

read -p "Do you want to install vim packages (y/n)?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Installing nvim packages...
    nvim +qall
fi

read -p "Do you want to install extra stuff (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo Running post install...
    . "$current_dir/post.sh"
fi
