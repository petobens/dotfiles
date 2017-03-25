#!/usr/bin/env bash
#===============================================================================
#          File: symlinks.sh
#        Author: Pedro Ferrari
#       Created: 12 Sep 2016
# Last Modified: 24 Mar 2017
#   Description: Create all necessary symbolic links from my dotfiles
#===============================================================================
# Ask for dotfiles dir. Note: the -i flag is only available on Bash 4
read -r -e -p "Enter dotfiles directory: " -i "$HOME/" dotfiles_dir
while [ ! -d "$dotfiles_dir" ]; do
    (>&2 echo "$dotfiles_dir: No such directory")
    read -r -e -p "Enter dotfiles directory: " -i "$HOME/" dotfiles_dir
done
# Strip last (potential) slash
dotfiles_dir=${dotfiles_dir%/}

echo Creating symlinks in your home directory...
if type "ctags" > /dev/null; then
    rm -rf "$HOME/.ctags"
    ln -s "$dotfiles_dir/ctags" "$HOME/.ctags"
    echo Created .ctags symlink
fi
if type "git" > /dev/null; then
    rm -rf "$HOME/.gitignore"
    rm -rf "$HOME/.gitconfig"
    ln -s "$dotfiles_dir/gitignore" "$HOME/.gitignore"
    echo Created .gitignore symlink
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        ln -s "$dotfiles_dir/gitconfig_mac" "$HOME/.gitconfig"
    else
        ln -s "$dotfiles_dir/gitconfig_linux" "$HOME/.gitconfig"
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
    echo Created ./config/nvim folder symlink
    ln -s "$dotfiles_dir/vim/" "$HOME/.config/nvim"
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
if type "r" > /dev/null; then
    rm -rf "$HOME/.Rprofile"
    ln -s "$dotfiles_dir/Rprofile" "$HOME/.Rprofile"
    echo Created .Rprofile symlink
fi
if type "bash" > /dev/null; then
    rm -rf "$HOME/.bashrc"
    ln -s "$dotfiles_dir/bashrc" "$HOME/.bashrc"
    echo Created .bashrc symlink
    rm -rf "$HOME/.bash_profile"
    ln -s "$dotfiles_dir/bash_profile" "$HOME/.bash_profile"
    echo Created .bash_profile symlink
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
if open -Ra "firefox"; then
    rm -rf "$HOME/.pentadactyl"
    ln -s "$dotfiles_dir/pentadactyl" "$HOME/.pentadactyl"
    echo Created .pentadactyl folder symlink
    rm -rf "$HOME/.pentadactylrc"
    ln -s "$dotfiles_dir/pentadactylrc" "$HOME/.pentadactylrc"
    echo Created .pentadactylrc symlink
fi
if open -Ra "hammerspoon" ; then
    rm -rf "$HOME/.hammerspoon"
    ln -s "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
    echo Created .hammerspoon folder symlink
fi
