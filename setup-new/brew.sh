#!/usr/bin/env bash
# Install brew if not installed
if ! type "brew" > /dev/null 2>&1; then
    brew_prefix='Home'
    brew_dir='/usr/local'
    echo -e "\033[1;34m--> Installing brew....\033[0m"
    ruby -e "$(curl -fsSl 'https://raw.githubusercontent.com/'$brew_prefix'brew/install/master/install')"
    export PATH="$brew_dir/bin:$brew_dir/sbin:$PATH"
else
    brew_dir=$(brew --prefix)
fi

# Use latest homebrew and update any already installed formulae
echo -e "\033[1;34m-->Updating Brew...\033[0m"
brew update && brew upgrade

# Fonts
brew tap caskroom/fonts
brew cask install font-sourcecodepro-nerd-font
# Nerd fonts Source Code Pro version doesn't have italics so we install
# the official version
brew cask install font-source-code-pro

# Latest bash with completions
brew install bash
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
read -p $'\033[1mDo you want to install python2 (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install python2
fi
if ! type "tlmgr" > /dev/null 2>&1; then
    read -p $'\033[1mDo you want to install LaTeX (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew cask install basictex
        # Wait until basictex is installed
        while [ ! -f "/Library/TeX/texbin/tlmgr" ]; do
            sleep 5
        done
        export PATH="/Library/TeX/texbin:$PATH"
    fi
fi
read -p $'\033[1mDo you want to install R (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install R --with-openblas
fi
read -p $'\033[1mDo you want to install Node.js (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install node
fi

# Neovim and tmux latest versions
brew tap neovim/neovim
brew install --HEAD neovim
brew install neovim-remote
brew install --HEAD tmux

# Databases
brew install postgresql
brew install mysql
brew install protobuf # Required by python's mysql-connector
brew install redis
brew install sqlite3

# Other useful binaries
brew install the_silver_searcher
brew install fzf
brew install z
brew install htop
brew install reattach-to-user-namespace
brew install rmtrash
brew install --HEAD universal-ctags/universal-ctags/universal-ctags
brew install unrar
brew install --HEAD neomutt --with-sidebar-patch --with-notmuch-patch
brew install shellcheck
brew install pandoc
brew install pandoc-citeproc
brew install neofetch
brew install imgcat
brew install rsync
brew install bat
brew install fd
brew install tree
brew install pyenv
brew install socat  # for faster powerline
brew install powerline
brew install ranger

# Remove outdated versions
brew cleanup
