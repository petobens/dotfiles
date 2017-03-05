#!/usr/bin/env bash
#===============================================================================
#          File: symlinks.sh
#        Author: Pedro Ferrari
#       Created: 12 Sep 2016
# Last Modified: 04 Mar 2017
#   Description: Create all necessary symbolic links from my dotfiles
#===============================================================================
dotfiles_dir="$HOME/git-repos/private/dotfiles"

echo Removing any existing dotfiles from your home directory...
rm -rf "$HOME/.ctags" "$HOME/.gitignore" "$HOME/.tmux" "$HOME/.vim" \
"$HOME/.vimrc"  "$HOME/.config/nvim" "$HOME/.config/nvim/init.vim" \
"$HOME/.vintrc.yaml" "$HOME/.eslintrc.yaml" "$HOME/.Rprofile" \
"$HOME/.bash_profile" "$HOME/.config/powerline" "$HOME/.gitconfig" \
"$HOME/.hammerspoon" "$HOME/.arararc.yaml" "$HOME/.pentadactyl" \
"$HOME/.pentadactylrc" "$HOME/.bashrc"

echo Creating .config directory...
mkdir -p "$HOME/.config/"

echo Creating symlinks in your home directory...
ln -s "$dotfiles_dir/ctags" "$HOME/.ctags"
ln -s "$dotfiles_dir/gitignore" "$HOME/.gitignore"
ln -s "$dotfiles_dir/tmux" "$HOME/.tmux"
ln -s "$dotfiles_dir/vim/" "$HOME/.vim"
ln -s "$dotfiles_dir/vimrc" "$HOME/.vimrc"
ln -s "$dotfiles_dir/vim/" "$HOME/.config/nvim"
ln -s "$dotfiles_dir/vimrc" "$HOME/.config/nvim/init.vim"
ln -s "$dotfiles_dir/vintrc.yaml" "$HOME/.vintrc.yaml"
ln -s "$dotfiles_dir/eslintrc.yaml" "$HOME/.eslintrc.yaml"
ln -s "$dotfiles_dir/Rprofile" "$HOME/.Rprofile"
ln -s "$dotfiles_dir/bash_profile" "$HOME/.bash_profile"
ln -s "$dotfiles_dir/bashrc" "$HOME/.bashrc"
ln -s "$dotfiles_dir/config/powerline" "$HOME/.config/powerline"

if [[ "$OSTYPE" == 'darwin'* ]]; then
    ln -s "$dotfiles_dir/gitconfig_mac" "$HOME/.gitconfig"
    ln -s "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
    ln -s "$dotfiles_dir/arararc.yaml" "$HOME/.arararc.yaml"
    ln -s "$dotfiles_dir/pentadactyl" "$HOME/.pentadactyl"
    ln -s "$dotfiles_dir/pentadactylrc" "$HOME/.pentadactylrc"
else
    ln -s "$dotfiles_dir/gitconfig_linux" "$HOME/.gitconfig"
fi
