#!/usr/bin/env bash
#===============================================================================
#          File: symlinks.sh
#        Author: Pedro Ferrari
#       Created: 12 Sep 2016
# Last Modified: 06 May 2017
#   Description: Create all necessary symbolic links from my dotfiles
#===============================================================================
# Check bash major version
bash_version=${BASH_VERSION:0:1}

# Ask for dotfiles dir. Note: the -i flag is only available on Bash 4
cur_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ $bash_version -gt 3 ]]; then
    read -r -e -p "Enter dotfiles directory: " -i "$cur_dir" dotfiles_dir
else
    read -r -e -p "Enter dotfiles directory: " dotfiles_dir
fi
while [ ! -d "$dotfiles_dir" ]; do
    (>&2 echo "$dotfiles_dir: No such directory")
    if [[ $bash_version -gt 3 ]]; then
        read -r -e -p "Enter dotfiles directory: " -i "$HOME/" dotfiles_dir
    else
        read -r -e -p "Enter dotfiles directory: " dotfiles_dir
    fi
done
# Strip last (potential) slash
dotfiles_dir=${dotfiles_dir%/}

echo Creating symlinks under "$HOME"/

# First symlink bashrc and reload it without logging out and back in
if type "bash" > /dev/null; then
    rm -rf "$HOME/.bashrc"
    ln -s "$dotfiles_dir/bashrc" "$HOME/.bashrc"
    echo Created .bashrc symlink
    rm -rf "$HOME/.bash_profile"
    ln -s "$dotfiles_dir/bash_profile" "$HOME/.bash_profile"
    echo Created .bash_profile symlink
fi
. "$HOME/.bashrc"

if type "ctags" > /dev/null; then
    rm -rf "$HOME/.ctags"
    ln -s "$dotfiles_dir/ctags" "$HOME/.ctags"
    echo Created .ctags symlink
fi
if type "git" > /dev/null; then
    rm -rf "$HOME/.gitignore"
    rm -rf "$HOME/.gitconfig"
    ln -s "$dotfiles_dir/git/gitignore" "$HOME/.gitignore"
    echo Created .gitignore symlink
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        ln -s "$dotfiles_dir/git/gitconfig_mac" "$HOME/.gitconfig"
    else
        ln -s "$dotfiles_dir/git/gitconfig_linux" "$HOME/.gitconfig"
    fi
    echo Created .gitconfig symlink
fi
if type "tmux" > /dev/null; then
    rm -rf "$HOME/.tmux"
    ln -s "$dotfiles_dir/tmux" "$HOME/.tmux"
    echo Created .tmux folder symlink
fi
if type "nvim" > /dev/null; then
    rm -rf "$HOME/.vim"
    ln -s "$dotfiles_dir/vim/" "$HOME/.vim"
    echo Created .vim folder symlink
    rm -rf "$HOME/.vimrc"
    ln -s "$dotfiles_dir/vimrc" "$HOME/.vimrc"
    echo Created .vimrc symlink
    mkdir -p "$HOME/.config/"
    rm -rf "$HOME/.config/nvim"
    ln -s "$dotfiles_dir/vim/" "$HOME/.config/nvim"
    echo Created ./config/nvim folder symlink
    rm -rf "$HOME/.config/nvim/init.vim"
    ln -s "$dotfiles_dir/vimrc" "$HOME/.config/nvim/init.vim"
    echo Created .init.vim symlink
fi
if type "vint" > /dev/null; then
    rm -rf "$HOME/.vintrc.yaml"
    ln -s "$dotfiles_dir/vintrc.yaml" "$HOME/.vintrc.yaml"
    echo Created .vintrc.yaml symlink
fi
if type "eslint" > /dev/null; then
    rm -rf "$HOME/.eslintrc.yaml"
    ln -s "$dotfiles_dir/eslintrc.yaml" "$HOME/.eslintrc.yaml"
    echo Created .eslintrc.yaml symlink
fi
if type "R" > /dev/null; then
    rm -rf "$HOME/.Rprofile"
    ln -s "$dotfiles_dir/Rprofile" "$HOME/.Rprofile"
    echo Created .Rprofile symlink
fi
if type "powerline-daemon" > /dev/null; then
    rm -rf  "$HOME/.config/powerline"
    ln -s "$dotfiles_dir/config/powerline" "$HOME/.config/powerline"
    echo Created .config/powerline folder symlink
fi
if type "arara" > /dev/null; then
    rm -rf "$HOME/.arararc.yaml"
    ln -s "$dotfiles_dir/arararc.yaml" "$HOME/.arararc.yaml"
    echo Created .arararc.yaml symlink
fi
if type "mutt" > /dev/null; then
    rm -rf "$HOME/.config/.mutt"
    ln -s "$dotfiles_dir/config/mutt" "$HOME/.config/mutt"
    echo Created .config/mutt folder symlink
fi
if type "ranger" > /dev/null; then
    rm -rf "$HOME/.config/ranger"
    ln -s "$dotfiles_dir/config/ranger" "$HOME/.config/ranger"
    echo Created .config/ranger folder symlink
fi
if open -Ra "firefox"; then
    rm -rf "$HOME/.pentadactyl"
    ln -s "$dotfiles_dir/pentadactyl" "$HOME/.pentadactyl"
    echo Created .pentadactyl folder symlink
    rm -rf "$HOME/.pentadactylrc"
    ln -s "$dotfiles_dir/pentadactylrc" "$HOME/.pentadactylrc"
    echo Created .pentadactylrc symlink
fi
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if open -Ra "hammerspoon" ; then
        rm -rf "$HOME/.hammerspoon"
        ln -s "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
        echo Created .hammerspoon folder symlink
    fi
fi
