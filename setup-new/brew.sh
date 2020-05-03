#!/usr/bin/env bash
# Install brew if not installed
if ! type "brew" > /dev/null 2>&1; then
    brew_prefix='Home'
    brew_dir='/usr/local'
    echo -e "\\033[1;34m--> Installing brew....\\033[0m"
    ruby -e "$(curl -fsSl 'https://raw.githubusercontent.com/'$brew_prefix'brew/install/master/install')"
    export PATH="$brew_dir/bin:$brew_dir/sbin:$PATH"
else
    brew_dir=$(brew --prefix)
fi

# Use latest homebrew and update any already installed formulae
echo -e "\\033[1;34m-->Updating Brew...\\033[0m"
brew update && brew upgrade

# Brew and brew cask install commands
brew_install_cmd='brew install'
brew_cask_install_cmd='brew cask install'

# Fonts
brew tap caskroom/fonts
$brew_cask_install_cmd font-sourcecodepro-nerd-font
# Nerd fonts Source Code Pro version doesn't have italics so we install
# the official version
$brew_cask_install_cmd font-source-code-pro

# Latest bash with completions
$brew_install_cmd bash
$brew_install_cmd bash-completion@2

# Git
$brew_install_cmd git

# Compiler related
$brew_install_cmd gcc
$brew_install_cmd llvm
$brew_install_cmd libomp
$brew_install_cmd openblas
$brew_install_cmd coreutils  # (realpath, ln, etc)

# Languages: Rust, Python3, R, latex, node, java
$brew_install_cmd python3
$brew_install_cmd pyenv
$brew_install_cmd rust
if ! java -version >/dev/null 2>&1;  then
    $brew_cask_install_cmd java
fi
if ! type "tlmgr" > /dev/null 2>&1; then
    read -p $'\033[1mDo you want to install LaTeX (y/n)? \033[0m' -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $brew_cask_install_cmd basictex
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
    $brew_install_cmd R --with-openblas
fi
read -p $'\033[1mDo you want to install Node.js (y/n)? \033[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    $brew_install_cmd node
fi

# Neovim and tmux and more bash
brew tap neovim/neovim
brew unlink neovim
$brew_install_cmd neovim --HEAD
$brew_install_cmd neovim-remote
$brew_install_cmd tmux

# Databases
$brew_install_cmd mongodb
$brew_install_cmd mysql
$brew_install_cmd postgresql
$brew_install_cmd protobuf # Required by python's mysql-connector
$brew_install_cmd redis
$brew_install_cmd sqlite3

# Other useful binaries
$brew_install_cmd bat
$brew_install_cmd ctop
$brew_install_cmd diff-so-fancy
$brew_install_cmd dust
$brew_install_cmd fd
$brew_install_cmd fzf
$brew_install_cmd gnupg
$brew_install_cmd gopass
$brew_install_cmd hadolint
$brew_install_cmd htop
$brew_install_cmd hyperfine
$brew_install_cmd imgcat
$brew_install_cmd lsd
$brew_install_cmd neofetch --HEAD
$brew_install_cmd neomutt --HEAD --with-sidebar-patch --with-notmuch-patch
$brew_install_cmd openconnect --HEAD --with-stoken
$brew_install_cmd openssh
$brew_install_cmd openvpn
$brew_install_cmd pandoc
$brew_install_cmd pandoc-citeproc
$brew_install_cmd prettyping
$brew_install_cmd qrendcode
$brew_install_cmd reattach-to-user-namespace
$brew_install_cmd ripgrep
$brew_install_cmd rlwrap
$brew_install_cmd rsync
$brew_install_cmd sd
$brew_install_cmd shellcheck
$brew_install_cmd shellpass
$brew_install_cmd shfmt
$brew_install_cmd sk
$brew_install_cmd stoken
$brew_install_cmd tldr
$brew_install_cmd tree
$brew_install_cmd universal-ctags/universal-ctags/universal-ctags --HEAD
$brew_install_cmd unrar
$brew_install_cmd unzip
$brew_install_cmd vivid
$brew_install_cmd z
$brew_install_cmd zip

# Apps
$brew_cask_install_cmd alacritty
$brew_cask_install_cmd brave
$brew_cask_install_cmd docker
$brew_install_cmd docker-compose
$brew_cask_install_cmd kitty
$brew_cask_install_cmd skype
$brew_cask_install_cmd spotify
$brew_cask_install_cmd thunderbird
$brew_cask_install_cmd slack
$brew_cask_install_cmd vlc
$brew_cask_install_cmd vuze

# Remove outdated versions
brew cleanup
