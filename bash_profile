#===============================================================================
#          File: bash_profile
#        Author: Pedro Ferrari
#       Created: 11 Apr 2016
# Last Modified: 01 Aug 2016
#   Description: My Bash Profile
#===============================================================================
# Note: in Iterm we use the afterglow colorscheme and powerline plugin. In
# addition we modifiy the cursor and background colors to match the hex values
# of those of our vim colorscheme

# Options {{{

if [[ "$OSTYPE" == 'darwin'* ]]; then
    # Path settings
    PATH="/usr/bin:/bin:/usr/sbin:/sbin"
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH" # homebrew
    export PATH="$HOME/prog-tools/arara4:$PATH" # arara
    export PATH="/Library/TeX/texbin:$PATH" # basictex
    export PATH="/Applications/MATLAB_R2015b.app/bin/matlab:$PATH" #matlab

    # R libraries
    export R_LIBS="/usr/local/lib/R/site-library"

    # Symlink cask apps to Applications folder
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    # Set english utf-8 locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

else
    # Linuxbrew
    export PATH="$HOME/.linuxbrew/bin:$PATH"
    export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
    export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

    # R libraries
    export R_LIBS="$HOME/.linuxbrew/lib/R/site-library"

    # Highlight directories in blue, symbolic links in purple and executable
    # files in red
    export LS_COLORS="di=0;34:ln=0;35:ex=0;31:"
fi

# Disable control flow (necessary to enable C-s bindings in vim)
stty -ixon

# Ignore case when completing and show all possible matches (note that we pass
# Readline commands as a single argument to bind built in function instead of
# adding them to inputrc file)
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

# Show mode in command prompt
# bind "set show-mode-in-prompt on"

# Powerline prompt
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
if [[ "$OSTYPE" == 'darwin'* ]]; then
    . /usr/local/lib/python3.5/site-packages/powerline/bindings/bash/powerline.sh
else
    . $HOME/.linuxbrew/lib/python3.5/site-packages/powerline/bindings/bash/powerline.sh
fi

# }}}
# Bindings {{{

# Set vi mode
set -o vi

# Insert mode
bind -m vi-insert '"jj": vi-movement-mode'
bind -m vi-insert '"\C-p": previous-history'
bind -m vi-insert '"\C-n": next-history'
bind -m vi-insert '"\C-e": end-of-line'
bind -m vi-insert '"\C-a": beginning-of-line'
# TODO: Paste system clipboard
# inoremap <A-p> <C-R>*

# Command mode
bind -m vi-command '"H": beginning-of-line'
bind -m vi-command '"L": end-of-line'
bind -m vi-command '"k": ""'
bind -m vi-command '"j": ""'
bind -m vi-command '"v": ""'

# Paste with p if in a tmux session
if { [[ "$OSTYPE" == 'darwin'* ]] && [[ "$TMUX" ]]; } then
    # FIXME: This is flaky
    bind -m vi-command -x '"p": "tmux set-buffer \"$(pbpaste)\"; tmux paste-buffer"'
fi

# }}}
# Alias {{{

# Bash
alias u='cd ..'
alias h='cd ~'
alias q='exit'
alias c='clear all'
alias v='vim'
alias ht='htop'
alias o='open'

# Git (similar to vim's fugitive)
alias gs='git status'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gP='git pull'

# Python
alias python='python3'
alias pip='pip3'
alias jn='jupyter notebook'

if [[ "$OSTYPE" == 'darwin'* ]]; then

    # Differentiate and use colors for directories, symbolic links, etc.
    alias ls='ls -GF'

    # Matlab
    alias matlab='/Applications/MATLAB_R2015b.app/bin/matlab -nodisplay '\
'-nodesktop -nosplash '

    # Alias to open vim sourcing minimal vimrc file
    alias mvrc='vim -u $HOME/OneDrive/vimfiles/vimrc_min'

    # Update brew, python, R and tex (tlmgr requires password)
    alias ua='brew update && brew upgrade && pip-review --interactive && '\
'R --slave --no-save --no-restore -e "update.packages(ask=FALSE, '\
'checkBuilt=TRUE)" && sudo tlmgr update --all'

    # Start Tmux attaching to an existing session named petobens or creating one
    # with such name (we also indicate the tmux.conf file location)
    alias tm='tmux -f "$HOME/.tmux/tmux.conf" new -A -s petobens'

    # SSH and Tmux: connect to emr via ssh and then start tmux creating a new
    # session called pedrof or attaching to an existing one with that name.
    # Add -X after ssh to enable X11 forwarding
    alias emr='ssh prd-emr-master -t tmux -f '\
'"/home/hadoop/pedrof_files/tmux_emr.conf" new -A -s pedrof'
    # Presto client
    alias pcli='ssh prd-emr-master -t tmux -f '\
'"/home/hadoop/pedrof_files/tmux_emr.conf" new -A -s pedrof '\
'"presto-cli\ --catalog\ hive\ --schema\ fault\ --user\ pedrof"'

    # Ubuntu instance (with tmux)
    alias ui='ssh ubuntu-as'
    alias utm='ssh ubuntu-as -t tmux -f "/home/ubuntu/.tmux/tmux.conf" new -A '\
'-s pedrof'

else
    # Differentiate and use colors for directories, symbolic links, etc.
    alias ls='ls -F --color=auto'
    # Expand aliases when using sudo
    alias sudo='sudo '
    # Alias to open vim sourcing minimal vimrc file
    alias mvrc='vim -u $HOME/pedrof/vimfiles/vimrc_min'
    # Update packages (using apt-get)
    alias aptu='sudo apt-get update && sudo apt-get dist-upgrade && sudo '\
'apt-get autoremove'
    # Update brew and python
    alias ua='brew update && brew upgrade && pip-review --interactive && '\
'R --slave --no-save --no-restore -e "update.packages(ask=FALSE, '\
'checkBuilt=TRUE)"'
    # Open tmux loading config file
    alias tm='tmux -f "$HOME/.tmux/tmux.conf" new -A -s pedrof'
fi

# }}}
