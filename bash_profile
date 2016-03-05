# Path settings
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH" # homebrew
export PATH="/usr/texbin:$PATH"  # basictex
export PATH="/Users/Pedro/miniconda3/bin:$PATH" # miniconda

# Symlink cask apps to Applications folder
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# For basictex manual
export MANPATH="/Library/TeX/Distributions/.DefaultTeX/Contents/Man:$MANPATH"

# Alias
alias python='python3'
alias vim='mvim'
alias mvrc='mvim -u ~/.vim/vimrc_min'

# Set english utf-8 locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# For powerline
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. /Users/Pedro/miniconda3/lib/python3.5/site-packages/powerline/bindings/bash/powerline.sh

# Set vi mode
set -o vi
