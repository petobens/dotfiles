#===============================================================================
#          File: bash_profile
#        Author: Pedro Ferrari
#       Created: 11 Apr 2016
# Last Modified: 19 May 2016
#   Description: My Bash Profile
#===============================================================================
# Note: in Iterm we use the afterglow colorscheme and powerline plugin. In
# addition we modifiy the cursor and background colors to match the hex values
# of those of our vim colorscheme

# Options {{{

# Path settings
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH" # homebrew
export PATH="$HOME/prog-tools/arara4:$PATH" # arara
export PATH="/Library/TeX/texbin:$PATH" # basictex
export PATH="$HOME/miniconda3/bin:$PATH" # miniconda

# Symlink cask apps to Applications folder
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# Set english utf-8 locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Disable control flow (necessary to enable C-s bindings in vim)
stty -ixon

# Ignore case when completing and show all possible matches (note that we pass
# Readline commands as a single argument to bind built in function instead of
# adding them to inputrc file)
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

# Show mode in command prompt
bind "set show-mode-in-prompt on"

# Powerline prompt
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. $HOME/miniconda3/lib/python3.5/site-packages/powerline/bindings/bash/powerline.sh

# }}}
# Bindings {{{

# Set vi mode
set -o vi

# Insert mode
bind -m vi-insert '"jj": vi-movement-mode'
bind -m vi-insert '"\C-p": previous-history'
bind -m vi-insert '"\C-n": next-history'
#  Paste system clipboard
# inoremap <A-p> <C-R>*

# Command mode
bind -m vi-command '"H": beginning-of-line'
bind -m vi-command '"L": end-of-line'
bind -m vi-command '"k": ""'
bind -m vi-command '"j": ""'
bind -m vi-command '"v": ""'

# FIXME: paste with p
# bind -m vi-command -x '"p": pbpaste'
# bind -m vi-command -x '"p": ls'
# bind -m vi-command -x '"p": "reattach-to-user-namespace pbpaste;tmux paste-buffer"'


# }}}
# Alias {{{

alias up='cd ..'
alias q='exit'
alias python='python3'
alias mvrc='vim -u $HOME/OneDrive/vimfiles/vimrc_min'

# Update brew, python, tlmgr and gems
alias uall='brew update && brew upgrade && conda update --all &&'\
'tlmgr update --all && sudo gem update'

# Start Tmux attaching to an existing session named petobens or creating one with
# such name
alias tm='tmux new -A -s petobens'

# SSH and Tmux: connect to ssh and then start tmux creating a new session called
# pedrof or attaching to an existing one with that name
alias emr-tmux='ssh prd-emr-master -t tmux new -A -s pedrof'
# Presto command line
alias presto='ssh prd-emr-master -t tmux new -A -s pedrof '\
'"presto-cli\ --catalog\ hive\ --schema\ fault\ --user\ pedrof"'

# Try something like the following
# alias run-presto='ssh prd-emr-master -t tmux new -A -s pedrof "presto-cli\ --catalog\ hive\ --schema\ fault\ --user\ pedrof\ --output-format\ CSV\ --execute\ \"SELECT\ ref_hash\ FROM\ all_events_monthly\ LIMIT\ 5;\"\ > /mnt1/pedrof-temp/output.csv"'

# }}}
