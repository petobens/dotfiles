#!/usr/bin/env bash
# shellcheck disable=SC1091
read -p $'\033[1mThis script will erase/override many files. Do you want to run it (y/n)? \033[0m' -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Ask for sudo right away and get this script directory
sudo echo -n
current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create needed dirs and set proper permissions
for d in .cache .config .local; do
    d="$HOME/$d"
    if [ ! -d "$d" ]; then
        mkdir -p "$d"
        sudo chown -R "$USER" "$d"
        echo "Created $d"
    fi
done

# We need xcode command tools on Mac
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if ! xcode-select --print-path > /dev/null 2>&1; then
        echo -e "\\033[1;34m-> Installing Xcode Command Line Tools...\\033[0m"
        xcode-select --install &> /dev/null
        # Wait until XCode command tools are installed
        until xcode-select --print-path > /dev/null 2>&1; do
            sleep 5
        done
    fi
fi

if [[ "$OSTYPE" == 'darwin'* ]]; then
    read -p $'\033[1mDo you want to install brew packages (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\\033[1;34m-> Installing Brew packages...\\033[0m"
        . "$current_dir/brew.sh"
    fi
else
    read -p $'\033[1mDo you want to install pacman packages (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\\033[1;34m-> Installing pacman/yay packages...\\033[0m"
        . "$current_dir/yay.sh"
    fi
fi

read -p $'\033[1mDo you want to install python modules and binaries (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\\033[1;34m-> Installing python modules and binaries (with pipx)...\\033[0m"
    . "$current_dir/python.sh"
fi

read -p $'\033[1mDo you want to install LaTeX and packages (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\\033[1;34m-> Installing Latex...\\033[0m"
    . "$current_dir/latex.sh"
fi

if type "R" > /dev/null 2>&1; then
    read -p $'\033[1mDo you want to install R libraries (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\\033[1;34m-> Installing R libraries...\\033[0m"
        . "$current_dir/R.sh"
    fi
fi

if type "npm" > /dev/null 2>&1; then
    read -p $'\033[1mDo you want to install node libraries and binaries (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\\033[1;34m-> Installing Node.js libraries...\\033[0m"
        . "$current_dir/npm.sh"
    fi
fi

if type "cargo" > /dev/null 2>&1; then
    read -p $'\033[1mDo you want to install rust binaries (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\\033[1;34m-> Installing rust binaries...\\033[0m"
        . "$current_dir/rust.sh"
    fi
fi

read -p $'\033[1mDo you want to generate symlinks to these dotfiles (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\\033[1;34m-> Generating symlinks...\\033[0m"
    . "$current_dir/symlinks.sh"
fi

read -p $'\033[1mDo you want to install nvim packages (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\\033[1;34m-> Installing nvim packages...\\033[0m"
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
fi

read -p $'\033[1mDo you want to run post install script (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\\033[1;34m-> Running post install...\\033[0m"
    . "$current_dir/post.sh"
fi
