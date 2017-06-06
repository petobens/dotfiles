#===============================================================================
#          File: bashrc
#        Author: Pedro Ferrari
#       Created: 11 Apr 2016
# Last Modified: 05 Jun 2017
#   Description: My bashrc file
#===============================================================================
# Options {{{

# Brew directory
if type "brew" > /dev/null 2>&1; then
    brew_dir=$(brew --prefix)
else
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        if [ -d '/usr/local/bin' ]; then
            brew_dir='/usr/local'
        fi
    else
        if [ -d "$HOME/.linuxbrew" ]; then
            brew_dir="$HOME/.linuxbrew"
        else
            brew_dir='/mnt/.linuxbrew'
        fi
    fi
fi

if [[ "$OSTYPE" == 'darwin'* ]]; then
    # Path settings
    PATH="/usr/bin:/bin:/usr/sbin:/sbin"
    export PATH="$brew_dir/bin:$brew_dir/sbin:$PATH" # homebrew
    if [ -d "/Library/TeX/texbin" ]; then
        export PATH="/Library/TeX/texbin:$PATH" # basictex
    fi
    if [ -d "/Applications/MATLAB_R2015b.app/bin" ]; then
        export PATH="/Applications/MATLAB_R2015b.app/bin/matlab:$PATH" #matlab
    fi

    # Symlink cask apps to Applications folder
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    # Set english utf-8 locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Enable terminal colors and highlight directories in blue, symbolic links
    # in purple and executable files in red (the actual colors depend on iTerm's
    # colorscheme)
    # Note: in Iterm we use ether the afterglow colorscheme or
    # https://github.com/anunez/one-dark-iterm
    export CLICOLOR=1
    export LSCOLORS=exfxCxDxbxegedabagaced
else
    export PATH="$brew_dir/bin:$brew_dir/sbin:$PATH"
    export MANPATH="$brew_dir/share/man:$MANPATH"
    export INFOPATH="$brew_dir/share/info:$INFOPATH"

    # Highlight directories in blue, symbolic links in purple and executable
    # files in red
    export LS_COLORS="di=0;34:ln=0;35:ex=0;31:"
fi

# Set editor to nvim
export EDITOR=nvim

# Set shell to latest bash (this should be redundant if we previously ran
# `sudo chsh -s $(brew --prefix)/bin/bash`)
if [ -f "$brew_dir/bin/bash" ]; then
    export SHELL="$brew_dir/bin/bash"
fi

# R libraries (note: first create this folder if it doesn't exist)
export R_LIBS="$brew_dir/lib/R/site-library"

# Disable control flow (necessary to enable C-s bindings in vim)
stty -ixon

# History settings
HISTCONTROL=ignoreboth:erasedups  # avoid duplicates
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend # append to history i.e don't overwrite it

# Save and reload the history after each command finishes (we wrap it in a
# function to preserve exit status when using powerline on tmux)
save_reload_hist() {
    local last_exit_status=$?
    history -a; history -c; history -r
    return $last_exit_status
}
export PROMPT_COMMAND=$'save_reload_hist\n'"$PROMPT_COMMAND"

# Powerline prompt (to see changes when customizing use `powerline-daemon
# --replace`)
if type "powerline-daemon" > /dev/null 2>&1; then
    powerline-daemon -q
    POWERLINE_BASH_CONTINUATION=1
    POWERLINE_BASH_SELECT=1
    py_exec='python2'
    if type "python3" > /dev/null 2>&1; then
        py_exec='python3'
    fi
    . $(dirname $($py_exec -c 'import powerline.bindings; '\
'print(powerline.bindings.__file__)'))/bash/powerline.sh
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

# Command mode
bind -m vi-command '"H": beginning-of-line'
bind -m vi-command '"L": end-of-line'
bind -m vi-command '"k": ""'
bind -m vi-command '"j": ""'
# bind -m vi-command '"v": ""' # Edit command with vim

# Paste with p if in a tmux session
if { [[ "$OSTYPE" == 'darwin'* ]] && [[ "$TMUX" ]]; } then
    # FIXME: This is flaky
    bind -m vi-command -x '"p": "reattach-to-user-namespace pbpaste | tmux load-buffer - && tmux paste-buffer"'
fi

# }}}
# Completion (readline) {{{

# Improved bash completion (install them with `brew install bash-completion2`)
if [ -f $brew_dir/share/bash-completion/bash_completion ]; then
. $brew_dir/share/bash-completion/bash_completion
fi

# Note: we pass Readline commands as a single argument to
# bind built in function instead of adding them to inputrc file)
bind "set completion-ignore-case on"
bind "set menu-complete-display-prefix on" # show candidates before cycling
bind "set show-all-if-ambiguous on"
bind "set colored-stats on" # color completion candidates

# Show mode in command prompt (note: 38 is fg color and 48 bg color; 2 means
# truecolor (i.e rgb) and 5 256color)
bind "set show-mode-in-prompt on"
bind 'set vi-ins-mode-string \1\e[38;5;235;48;2;97;175;239;1m\2 I '\
'\1\e[38;2;97;175;239;48;2;208;208;208;1m\2\1\e[0m\2\1\e[6 q\2'
bind 'set vi-cmd-mode-string \1\e[38;5;235;48;2;152;195;121;1m\2 N '\
'\1\e[38;2;152;195;121;48;2;208;208;208;1m\2\1\e[0m\2\1\e[2 q\2'
# Switch to block cursor before executing a command
bind -m vi-insert 'RETURN: "\e\n"'

# Cycle forward with TAB and backwards with S-Tab when using menu-complete
bind -m vi-insert '"\C-i": menu-complete'
bind -m vi-insert '"\e[Z": menu-complete-backward'

# Use bracketed paste (i.e distinguish between typed and pasted text)
bind 'set enable-bracketed-paste on'

# }}}
# Alias {{{

# Bash
alias sh='bash'
alias u='cd ..'
alias h='cd ~'
alias q='exit'
alias c='clear all'
alias v='NVIM_LISTEN_ADDRESS=/tmp/nvimsocket nvim'
alias ht='htop'
alias o='open'
alias rg='ranger'

# Colorized cat (with Python's pygment library)
if type "pygmentize" > /dev/null 2>&1; then
    alias dog='pygmentize -O style=monokai -f terminal16m -g'
fi

# Git (similar to vim's fugitive); also bind auto-complete functions to each
# alias
alias gs='git status'
alias gco='git checkout'
_completion_loader git
__git_complete gco _git_checkout
alias gcp='git cherry-pick'
alias gb='git branch'
__git_complete gb _git_branch
alias gp='git push'
__git_complete gp _git_push
alias gP='git pull'
__git_complete gp _git_pull

# Python
if [ ! -f "$brew_dir"/bin/python2 ]; then
    alias python='python3'
    alias pip='pip3'
fi
alias jn='jupyter notebook'

# Update all binaries (with brew) and language libraries
ua='brew update && brew upgrade && brew cleanup; '\
'python3 -m pip_review --interactive'
if [ -f "$brew_dir"/bin/python2 ]; then
    ua=$ua'; python2 -m pip_review --interactive'
fi
if type "R" > /dev/null 2>&1; then
    ua=$ua'; R --slave --no-save --no-restore -e '\
'"update.packages(ask=FALSE, checkBuilt=TRUE)"'
fi
if type "tlmgr" > /dev/null 2>&1; then
    ua=$ua'; sudo tlmgr update --all'
fi
if type "npm" > /dev/null 2>&1; then
    ua=$ua'; npm update -g'
fi
alias ua="$ua"

if [[ "$OSTYPE" == 'darwin'* ]]; then
    # Differentiate and use colors for directories, symbolic links, etc.
    alias ls='ls -GF'

    # Change directory and list files
    cd() { builtin cd "$@" && ls -GF; }

    # Matlab
    alias matlab='/Applications/MATLAB_R2015b.app/bin/matlab -nodisplay '\
'-nodesktop -nosplash '

    # Alias to open vim/nvim sourcing minimal vimrc file
    alias mvrc='vim -u $HOME/git-repos/private/dotfiles/vim/vimrc_min'
    alias mnvrc='nvim -u $HOME/git-repos/private/dotfiles/vim/vimrc_min'

    # Start Tmux attaching to an existing session named petobens or creating one
    # with such name (we also indicate the tmux.conf file location)
    alias tm='tmux -f "$HOME/.tmux/tmux.conf" new -A -s petobens'

    # SSH and Tmux: connect to emr via ssh and then start tmux creating a new
    # session called pedrof or attaching to an existing one with that name.
    # Add -X after ssh to enable X11 forwarding
    alias emr='ssh pedrof@stg-amber-pivot.jampp.com -t tmux new -A -s pedrof'
    # Presto client
    alias pcli='ssh pedrof@stg-amber-pivot.jampp.com -t tmux new -A -s pedrof '\
'"presto-cli\ --server\ emr-prd-queries.jampp.com:8889\ --catalog\ hive\ '\
'--schema\ aleph\ --user\ pedrof"'
    # Gerry instance (with tmux)
    alias ui='ssh gerry'
    # When using linux brew we need to specify a full path to the tmux
    # executable
    alias utm='ssh gerry -t /mnt/.linuxbrew/bin/tmux -f'\
'"/home/ubuntu/.tmux/tmux.conf" new -A -s pedrof'

    # Fix open in tmux (requires installing reattach-to-user-namespace)
    if [[ '$TMUX' ]]; then
        alias open='reattach-to-user-namespace open'
    fi

else
    # Differentiate and use colors for directories, symbolic links, etc.
    alias ls='ls -F --color=auto'
    # Change directory and list files
    cd() { builtin cd "$@" && ls -F --color=auto; }
    # Expand aliases when using sudo
    alias sudo='sudo '
    # Update packages (using apt-get)
    alias aptu='sudo apt-get update && sudo apt-get dist-upgrade && sudo '\
'apt-get autoremove'
    # Open tmux loading config file
    alias tm='tmux -f "$HOME/.tmux/tmux.conf" new -A -s pedrof'
fi

# }}}
# Fzf {{{

if type "fzf" > /dev/null 2>&1; then
    # Enable completion and key bindings
    [[ $- == *i* ]] && . "$brew_dir/opt/fzf/shell/completion.bash" 2> /dev/null
    . "$brew_dir/opt/fzf/shell/key-bindings.bash"

    # Change default options (show 15 lines, use top-down layout)
    export FZF_DEFAULT_OPTS='--height 15 --reverse '\
'--bind=ctrl-space:toggle+down'

    # Use ag (not that this will only list files and not directories)
    export FZF_DEFAULT_COMMAND='ag -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

    # Extend list of commands with fuzzy completion (basically add our aliases)
    complete -F _fzf_file_completion -o default -o bashdefault v o

    # Enable tmux integration
    # export FZF_TMUX='1'
    export FZF_TMUX_HEIGHT='15'

    # Fix Alt-C mapping (needed for when we set Alt to act as meta key in Iterm
    # preferences; for instance to make alt key work on vim)
    bind '"ã": "\C-x\C-addi$(__fzf_cd__)\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"ã": "ddi$(__fzf_cd__)\C-x\C-e\C-x\C-r\C-m"'
fi

# }}}
