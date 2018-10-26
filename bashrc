# Options {{{

if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi

    # Path settings
    PATH="$HOME/local/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    export PATH="$base_pkg_dir/bin:$base_pkg_dir/sbin:$PATH" # homebrew
    if [ -d "/Library/TeX/texbin" ]; then
        export PATH="/Library/TeX/texbin:$PATH" # basictex
    fi
    if [ -d "/Applications/MATLAB_R2015b.app/bin" ]; then
        export PATH="/Applications/MATLAB_R2015b.app/bin/matlab:$PATH" # matlab
    fi
    export PKG_CONFIG_PATH="$base_pkg_dir/lib/pkgconfig:$base_pkg_dir/lib"
    if [ -d "/usr/local/opt/sqlite/bin" ]; then
        export PATH="/usr/local/opt/sqlite/bin:$PATH"
    fi

    # Symlink cask apps to Applications folder
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    # Set english utf-8 locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Enable terminal colors and highlight directories in blue, symbolic links
    # in purple and executable files in red
    export CLICOLOR=1
    export LSCOLORS=exfxCxDxbxegedabagaced
else
    base_pkg_dir='/usr'

    # PATH is originally defined in /etc/profile
    # export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin"
    if [ -d "$base_pkg_dir/local/texlive" ]; then
        export PATH="/usr/local/texlive/2018/bin/x86_64-linux:$PATH"
        export MANPATH="$MANPATH:/usr/local/texlive/2018/texmf-dist/doc/man"
        export INFOPATH="$INFOPATH:/usr/local/texlive/2018/texmf-dist/doc/info"
    fi

    # Local paths first
    export PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"
    export MANPATH="$HOME/local/share/man:$HOME/.local/share/man:$MANPATH"

    # Highlight directories in blue, symbolic links in purple and executable
    # files in red
    export LS_COLORS="di=0;34:ln=0;35:ex=0;31:"

    export BROWSER='chromium'

    # Scaling
    export GDK_SCALE=2
    export GDK_DPI_SCALE=0.5
fi

# Path OS agnostic settings
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi
if type "npm" > /dev/null 2>&1; then
    PATH="$HOME/.node_modules/bin:$PATH"
    export npm_config_prefix="$HOME/.node_modules"
fi
if type "go" > /dev/null 2>&1; then
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
fi
if type "pyenv" > /dev/null 2>&1; then
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi
if type "pipenv" > /dev/null 2>&1; then
    eval "$(pipenv --completion)"
    # Always create a pipenv venv (useful when running from vim)
    export PIPENV_IGNORE_VIRTUALENVS=1
fi
if type "pipx" > /dev/null 2>&1; then
    export PIPX_HOME=$HOME/.local/pipx/venvs
    export PIPX_BIN_DIR=$HOME/.local/bin
fi
if type "sqlplus" > /dev/null 2>&1; then
    export SQLPATH="$HOME/.config/sqlplus"
fi
if type "mssql-cli" > /dev/null 2>&1; then
    export MSSQL_CLI_TELEMETRY_OPTOUT=1
fi

# Set editor to nvim and use it as a manpager
export EDITOR=nvim
export MANPAGER="nvim -c 'set ft=man' -"

# Set shell to latest bash (check "$(command -v bash)")
if [ -f "$base_pkg_dir/bin/bash" ]; then
    export SHELL="$base_pkg_dir/bin/bash"
fi

# R libraries (note: first create this folder if it doesn't exist)
if type "R" > /dev/null 2>&1; then
    export R_LIBS_USER="$HOME/.local/lib/R/site-library"
fi

# Disable control flow (necessary to enable C-s bindings in vim)
stty -ixon
# Update values of lines and columns after running each command
shopt -s checkwinsize

# History settings
HISTCONTROL=ignoreboth:erasedups  # era duplicate entries
HISTIGNORE='?:??' # don't save one and two character commands (q, ls, aliases)
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend # append to history i.e don't overwrite it

# Unset the prompt so we can set it properly afterwards
unset PROMPT_COMMAND
export PROMPT_COMMAND=$'save_reload_hist\n'"$PROMPT_COMMAND"

# Powerline prompt (to see changes when customizing use `powerline-daemon
# --replace`)
if type "powerline-daemon" > /dev/null 2>&1; then
    powerline-daemon -q
    POWERLINE_BASH_CONTINUATION=1
    POWERLINE_BASH_SELECT=1
    . /usr/lib/python3.7/site-packages/powerline/bindings/bash/powerline.sh
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
bind -m vi-insert '"\ef": forward-word'
bind -m vi-insert '"\eb": backward-word'

# Command (normal) mode
bind -m vi-command '"H": beginning-of-line'
bind -m vi-command '"L": end-of-line'
bind -m vi-command '"k": ""'
bind -m vi-command '"j": ""'
bind -m vi-command '"v": ""' # Don't edit command with default editor (nvim)

# Paste with p if in a tmux session
if { [[ "$OSTYPE" == 'darwin'* ]] && [[ "$TMUX" ]]; } then
    bind -m vi-command -x '"p": "pbpaste | tmux load-buffer - && tmux paste-buffer"'
fi

# }}}
# Completion (readline) {{{

# Improved bash completion (install them with `brew install bash-completion@2`)
if [ -f $base_pkg_dir/share/bash-completion/bash_completion ]; then
    . $base_pkg_dir/share/bash-completion/bash_completion
fi

# Note: we pass Readline commands as a single argument to
# bind built in function instead of adding them to inputrc file)
# TODO: Consider moving all this to inputrc
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

# Bind C-p and C-n to search the history conditional on input (like zsh) instead
# of simply going up or down
bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

# Use bracketed paste (i.e distinguish between typed and pasted text)
bind 'set enable-bracketed-paste on'

# }}}
# Aliases {{{

# Bash
alias sh='bash'
alias u='cd ..'
alias 2u='cd ../..'
alias 3u='cd ../../..'
alias 4u='cd ../../../..'
alias h='cd ~'
alias ll='ls -lah'
alias q='exit'
alias c='clear'
alias o='open'
if [ "$OSTYPE" == 'linux-gnu' ]; then
    alias open='xdg-open'
    alias ss='sudo su'
    if type "feh" > /dev/null 2>&1; then
        alias iv='feh'
    fi
fi
alias rm='rm -v'
alias sudo='sudo ' # Expand aliases when using sudo
alias ssh='TERM=xterm-256color; ssh'
alias ds='du -shc * | sort -rh'

# Other binaries
if [ -f $base_pkg_dir/share/bash-completion/bash_completion ]; then
    . $base_pkg_dir/share/bash-completion/completions/man
    alias m='man'
    complete -F _man m
fi
if type "htop" > /dev/null 2>&1; then
    alias ht='htop'
fi
if type "nvim" > /dev/null 2>&1; then
    alias v='NVIM_LISTEN_ADDRESS=/tmp/nvimsocket nvim'
    if [ -f "$HOME/git-repos/private/dotfiles/vim/vimrc_min" ]; then
        alias mnvrc='nvim -u $HOME/git-repos/private/dotfiles/vim/vimrc_min'
    fi
fi
if type "ranger" > /dev/null 2>&1; then
    alias rg='ranger'
fi
if type "bat" > /dev/null 2>&1; then
    # Colorized cat
    alias dog='bat --style numbers --theme TwoDark'
fi
if type "unimatrix" > /dev/null 2>&1; then
    alias iamneo='unimatrix -s 90'
fi
if type "R" > /dev/null 2>&1; then
    alias R='R --no-save --quiet'
fi
if type "tmux" > /dev/null 2>&1 && [ -f "$HOME/.tmux/tmux.conf" ]; then
    alias tm='tmux -f "$HOME/.tmux/tmux.conf" new -A -s petobens'
fi
if type "mpv" > /dev/null 2>&1; then
    # (P)hot(b)ooth (webcam)
    alias pb='mpv tv:// --tv-height=500 --tv-width=400 --tv-fps=60 '\
'--no-quiet'
fi

# Git (similar to vim's fugitive); also bind auto-complete functions to each
# alias
if type "git" > /dev/null 2>&1; then
    _completion_loader git
    alias gs='git status'
    alias gcl='git clone'
    alias gco='git checkout'
    __git_complete gco _git_checkout
    alias gcp='git cherry-pick'
    alias gb='git branch'
    __git_complete gb _git_branch
    alias gp='git push'
    __git_complete gp _git_push
    alias gP='git pull'
    __git_complete gp _git_pull
    alias gdr='git push origin --delete'
    __git_complete gdr _git_push
fi

# Python
if type "python" > /dev/null 2>&1; then
    if [ ! -f "$base_pkg_dir"/bin/python2 ]; then
        alias python='python3'
        alias pip='pip3'
    fi
    if type "jupyter" > /dev/null 2>&1; then
        # TODO: Hack for notebooks with python 3.7
        # See: https://github.com/jupyter/notebook/issues/3837
        alias jn='unset BROWSER;jupyter notebook'
    fi
    if type "pip" > /dev/null 2>&1; then
        alias piu='pip install --user'
    fi
    if type "ipython3" > /dev/null 2>&1; then
        alias ip='ipython3'
    fi
    if type "pipenv" > /dev/null 2>&1; then
        alias pel='pipenv run pip list'
        alias pei='pipenv install'
        alias pes='pipenv shell'
        alias pep='pipenv run python'
    fi
fi

# Package manager
if type "yay" > /dev/null 2>&1; then
    # Note yay will prompt twice: https://github.com/Jguer/yay/issues/170
    alias yay='yay --nodiffmenu --answerclean N --removemake'
    # Update pacman mirrorlist
    if type "reflector" > /dev/null 2>&1; then
        alias upm='sudo reflector --verbose --latest 25 -p http -p https '\
'--sort rate --save /etc/pacman.d/mirrorlist'
    fi
fi

# Update system (and language libraries); see function below
alias ua=sys_update_all

if [[ "$OSTYPE" == 'darwin'* ]]; then
    # Differentiate and use colors for directories, symbolic links, etc.
    alias ls='ls -GF'

    # Change directory and list files
    cd() { builtin cd "$@" && ls -GF; }

    # Matlab
    alias matlab='/Applications/MATLAB_R2015b.app/bin/matlab -nodisplay '\
'-nodesktop -nosplash '
else
    # Differentiate and use colors for directories, symbolic links, etc.
    alias ls='ls -F --color=auto'
    # Change directory and list files
    cd() { builtin cd "$@" && ls -F --color=auto; }

    if [ -f "$HOME/bin/multimon" ]; then
        # Dual monitor
        alias mm=multimon
    fi

    if type "pacman" > /dev/null 2>&1; then
        alias lsip='comm -23 <(pacman -Qqett | sort) <(pacman -Qqg base'\
' -g base-devel -g xorg | sort | uniq)'
    fi
fi

# }}}
# Work Aliases {{{

# Mostly vpn and databases; ssh hosts are defined in .ssh/config
alias kvpn='sudo pkill -INT -f "openconnect|openvpn|vpnc"'

# Claro
# Note: this requires a passwordless stoken (use token-mode=rsa if password is
# enabled)
alias cvpn='sudo pkill -INT -f openconnect; stoken | sudo openconnect '\
'--background --authgroup=1 --user=EXB77159 --passwd-on-stdin vpn.claro.com.ar'
alias cmssh='TERM=xterm-256color; sshpass -p "$(pass claro/ssh)" ssh mjolnir'
alias cvssh='TERM=xterm-256color; sshpass -p "$(pass claro/ssh)" ssh varas'
alias cdb='rlwrap -c sqlplus dracing/"$(pass claro/oracle/rac8/dracing)"'\
'@exa1-scan.claro.amx:1521/RAC8.WORLD @login'

# AUSA
alias avpn='sudo vpnc ausa_vpn.conf && '\
'sudo \ip route add 172.25.0.0/16 dev tun0 scope link &&'\
'sudo \ip route del default dev tun0 scope link'
alias adb='mssql-cli -S 172.25.1.70 -U pfarina -P '\
'"$(pass ausa/sqlserver/pfarina)"'

# Min Prod
alias mpvpn='sudo pkill -INT -f openvpn; sudo openvpn --daemon --cd '\
'~/OneDrive/arch/vpn --config microstrategy.ovpn'
alias mpssh='TERM=xterm-256color; sshpass -p '\
'"$(pass minprod/ssh/microstrategy)" ssh minprod'

# Humber
alias hdb='mongo mongodb://humberDbRead:"$(pass humber/mongodb/humberDbRead)"'\
'@db1.humber.com.ar:37117,db2.humber.com.ar:37117,'\
'arbiter.humber.com.ar:37117/humberPro001?replicaSet=humber-replica-set'

# }}}
# Fzf {{{

if type "fzf" > /dev/null 2>&1; then
    # Enable completion and key bindings

    if [[ "$OSTYPE" == 'darwin'* ]]; then
        [[ $- == *i* ]] && . "$base_pkg_dir/opt/fzf/shell/completion.bash" 2> /dev/null
        . "$base_pkg_dir/opt/fzf/shell/key-bindings.bash"
    else
        [[ $- == *i* ]] && . "$base_pkg_dir/share/fzf/completion.bash" 2> /dev/null
        . "$base_pkg_dir/share/fzf/key-bindings.bash"
    fi

    # Change default options (show 15 lines, use top-down layout)
    export FZF_DEFAULT_OPTS='--height 15 --reverse '\
'--bind=ctrl-space:toggle+down'
    # Use ag for files and fd for dirs
    export FZF_DEFAULT_COMMAND='ag -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    if type "tree" > /dev/null 2>&1; then
        export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
    fi
    # Disable tmux integration (use ncurses directly)
    export FZF_TMUX='0'

    # Extend list of commands with fuzzy completion (basically add our aliases)
    complete -F _fzf_path_completion -o default -o bashdefault v o dog

    # Alt-p mapping to cd to selected parent directory (sister to Alt-c)
    __fzf_cd_parent__() {
        local declare dirs=()
        get_parent_dirs() {
            if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
            if [[ "${1}" == '/' ]]; then
                for _dir in "${dirs[@]}"; do echo "$_dir"; done
            else
                get_parent_dirs "$(dirname "$1")"
            fi
    }
        local start_dir="$(dirname "$PWD")"  # start with parent dir
        local DIR=$(get_parent_dirs $(realpath "${1:-$start_dir}") | \
            fzf --preview 'tree -C -d -L 2 {} | head -200')
        if [[ ! -z $DIR ]]; then
            printf 'cd %q' "$DIR"
        else
            return 1
        fi
    }
    bind '"\ep": "\C-x\C-addi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"\ep": "ddi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'

    # Z
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        if [ -f "$base_pkg_dir/etc/profile.d/z.sh" ]; then
            . "$base_pkg_dir/etc/profile.d/z.sh"
        fi
    else
        if [ -f "$HOME/.local/bin/z.sh" ]; then
            . "$HOME/.local/bin/z.sh"
        fi
    fi
    unalias z 2> /dev/null
    z() {
        [ $# -gt 0 ] && _z "$*" && return
        dir="$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse \
            --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
        if [[ ! -z $dir ]]; then
            printf 'cd %q' "$dir"
        else
            return 1
        fi
    }
    bind '"\ez": "\C-x\C-addi`z`\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"\ez": "ddi`z`\C-x\C-e\C-x\C-r\C-m"'

    # Git
    gl() {
        # TODO: Add preview
        git log --graph --color=always \
            --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
        fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
            --bind "ctrl-m:execute:
                        (grep -o '[a-f0-9]\{7\}' | head -1 |
                        xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                        {}
        FZF-EOF"
    }
fi

# }}}
# Functions {{{

# Save and reload the history after each command finishes (we wrap it in a
# function to preserve exit status when using powerline on tmux)
# See: https://unix.stackexchange.com/a/18443
save_reload_hist() {
    local last_exit_status=$?
    history -n; history -w; history -c; history -r
    return $last_exit_status
}

# Update the system  package and language libraries
sys_update_all() {
    sudo echo -n
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        if type "brew" > /dev/null 2>&1; then
            echo -e "\033[1;34m-> Brew...\033[0m"
            brew update && brew upgrade && brew cleanup
        fi
    else
        if type "yay" > /dev/null 2>&1; then
            echo -e "\033[1;34m-> YaY...\033[0m"
            yay -Syu --nodiffmenu --answerclean N --removemake --devel \
                --timeupdate --combinedupgrade
            yay -c
        fi
        if type "flatpak" > /dev/null 2>&1; then
            echo -e "\033[1;34m\n-> Updating flatpaks...\033[0m"
            flatpak update
        fi
    fi
    if type "python3" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python...\033[0m"
        outdated="$(pip list --user --outdated)"
        if [ ! -z "$outdated" ]; then
            echo "$outdated"
            u_list=$(pip list --user --outdated --format=freeze | \
                        grep -v ‘^\-e’ | cut -d = -f 1)
            for i in $u_list; do
                read -p "Do you want to update $i (y/n)? " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    pip install --user -U "$i"
                fi
            done
        fi
    fi
    if type "pipx" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python binaries with pipx...\033[0m"
        pipx upgrade-all
    fi
    if type "R" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating R...\033[0m"
        R --slave --no-save --no-restore -e \
'update.packages(ask=TRUE, checkBuilt=TRUE, lib.loc=Sys.getenv("R_LIBS_USER"))'
    fi
    if type "tlmgr" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Latex...\033[0m"
        sudo tlmgr update --all
    fi
    if type "npm" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Node...\033[0m"
        npm update -g
    fi
}

# }}}
