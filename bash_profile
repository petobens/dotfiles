# Path settings
PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin"
export PATH="/Users/Pedro/miniconda3/bin:$PATH"

# Alias
alias python='python3'
alias vim='mvim'

# # Better colors in iterm?
export CLICOLOR=1

# Set english utf-8 locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# For powerline
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. /Users/Pedro/miniconda3/lib/python3.5/site-packages/powerline/bindings/bash/powerline.sh
