#!/usr/bin/env bash
#===============================================================================
#          File: brew.sh
#        Author: Pedro Ferrari
#       Created: 24 Mar 2017
# Last Modified: 24 Mar 2017
#   Description: Brew, symlinks and python installation for new computer
#===============================================================================
# Install brew if not installed
if ! type "brew" > /dev/null; then
    brew_prefix='Home'
    if [[ ! "$OSTYPE" == 'darwin'* ]]; then
        brew_prefix='Linux'
    fi
    echo "Installing brew..."
    ruby -e "$(curl -fsSl 'https://raw.githubusercontent.com/'$brew_prefix'brew/install/master/install')"
fi
brew_dir=$(brew --prefix)

# Use latest homebrew and update any already installed formulae
brew update && brew upgrade

# Git
brew install git

# Latest bash with completions (and linter)
brew install bash
brew tap homebrew/versions
brew install bash-completion2
brew install shellcheck

# Python3, R, latex, node
brew install python3
brew tap homebrew/science
brew install r
if [[  "$OSTYPE" == 'darwin'* ]]; then
    brew cask install basictex
else
    brew install texlive with-basic
fi
brew install node

# Neovim and tmux latest versions
brew tap neovim/neovim
brew install --HEAD neovim
brew install --HEAD tmux

# Databases
brew install postgresql
brew install mysql
brew install redis

# Other useful binaries
brew install the_silver_searcher
brew install fzf
"$brew_dir"/opt/fzf/install
brew install htop
brew install gcc
if [[  "$OSTYPE" == 'darwin'* ]]; then
    brew install reattach-to-user-namespace
fi
brew tap universal-ctags/universal-ctags
brew install --HEAD universal-ctags
brew install unrar

# Remove outdated versions from the cellar.
brew cleanup
