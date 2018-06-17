#!/usr/bin/env bash
# Install brew if not installed
if ! type "brew" > /dev/null 2>&1; then
    brew_prefix='Home'
    brew_dir='/usr/local'
    if [[ ! "$OSTYPE" == 'darwin'* ]]; then
        brew_prefix='Linux'
        brew_dir="$HOME/.linuxbrew"
    fi
    echo "Installing brew..."
    ruby -e "$(curl -fsSl 'https://raw.githubusercontent.com/'$brew_prefix'brew/install/master/install')"
    export PATH="$brew_dir/bin:$brew_dir/sbin:$PATH"
else
    brew_dir=$(brew --prefix)
fi

# Use latest homebrew and update any already installed formulae
echo "Updating Brew..."
brew update && brew upgrade

# Latest bash with completions
brew install bash
sudo bash -c "echo $brew_dir/bin/bash >> /etc/shells"
sudo chsh -s "$brew_dir"/bin/bash
brew install bash-completion@2

# Git
brew install git

# Compiler related
brew install gcc
brew install llvm
brew install libomp
brew install openblas
brew install coreutils  # (realpath, etc)

# Languages: Rust, Python3, R, latex, node, java
brew install rust  # We need this for Alacritty
brew install python3
read -p "Do you want to install python2 (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install python2
fi
if ! type "tlmgr" > /dev/null 2>&1; then
    read -p "Do you want to install latex (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[  "$OSTYPE" == 'darwin'* ]]; then
            brew cask install basictex
            # Wait until basictex is installed
            while [ ! -f "/Library/TeX/texbin/tlmgr" ]; do
                sleep 5
            done
            export PATH="/Library/TeX/texbin:$PATH"
        else
            brew install texlive --with-basic
        fi
    fi
fi
read -p "Do you want to install R (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install R --with-openblas
fi
read -p "Do you want to install Node.js (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install node
fi

# Neovim and tmux latest versions
brew tap neovim/neovim
brew install --HEAD neovim
brew install --HEAD tmux

# Databases
brew install postgresql
brew install mysql
brew install protobuf # Required by python's mysql-connector
brew install redis

# Other useful binaries
brew install the_silver_searcher
brew install fzf
brew install z
brew install htop
if [[  "$OSTYPE" == 'darwin'* ]]; then
    brew install reattach-to-user-namespace
    brew install rmtrash
fi
brew install --HEAD universal-ctags/universal-ctags/universal-ctags
brew install unrar
brew install --HEAD neomutt --with-sidebar-patch --with-notmuch-patch
# FIXME: the following two do not install on Linux due to ghc error
brew install shellcheck
brew install pandoc
brew install pandoc-citeproc
brew install neofetch
brew install imgcat
brew install rsync
brew install bat
brew install fd

# Remove outdated versions
brew cleanup
