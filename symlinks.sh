#!/usr/bin/env bash
#===============================================================================
#          File: symlinks.sh
#        Author: Pedro Ferrari
#       Created: 12 Sep 2016
# Last Modified: 12 Sep 2016
#   Description: Create all necessary symbolic links
#===============================================================================
# TODO: Use a loop and check if symlinks already exist
dotfiles_dir="$HOME/git-repos/dotfiles"
ln -s "$dotfiles_dir/ctags" "$HOME/.ctags"
ln -s "$dotfiles_dir/hammerspoon" "$HOME/.hammerspoon"
ln -s "$dotfiles_dir/pentadactyl" "$HOME/.pentadactyl"
ln -s "$dotfiles_dir/pentadactylrc" "$HOME/.pentadactylrc"
ln -s "$dotfiles_dir/gitignore" "$HOME/.gitignore"
ln -s "$dotfiles_dir/tmux" "$HOME/.tmux"
ln -s "$dotfiles_dir/vim/" "$HOME/.vim"
ln -s "$dotfiles_dir/vintrc.yaml" "$HOME/.vintrc.yaml"
ln -s "$dotfiles_dir/arararc.yaml" "$HOME/.arararc.yaml"
ln -s "$dotfiles_dir/Rprofile" "$HOME/.Rprofile"
ln -s "$dotfiles_dir/bash_profile" "$HOME/.bash_profile"
ln -s "$dotfiles_dir/powerline_config.json" "$HOME/.config/powerline/config.json"

if [[ "$OSTYPE" == 'darwin'* ]]; then
    ln -s "$dotfiles_dir/gitconfig_mac" "$HOME/.gitconfig"
else
    ln -s "$dotfiles_dir/gitconfig_linux" "$HOME/.gitconfig"
fi
