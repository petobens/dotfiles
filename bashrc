# Options {{{

# Disable control flow (necessary to enable C-s bindings in vim)
stty -ixon
# Update values of lines and columns after running each command
shopt -s checkwinsize
# cd into a dir by just typing its name
shopt -s autocd
# Fix cd spell mistakes (minor typos actually)
shopt -s cdspell

# History settings (don't save lines beginning with space or matching the
# previous entry, remove duplicates and don't save one and two character
# commands)
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='?:??:cd*:ranger*:v*'
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend # append to history i.e don't overwrite it

# Save multiline commands in same history entry with embedded newlines
shopt -s cmdhist
shopt -s lithist

# Improved bash completion
if [[ -f "$BASE_PKG_DIR/share/bash-completion/bash_completion" ]]; then
    . "$BASE_PKG_DIR/share/bash-completion/bash_completion"
fi

# }}}
# Prompt {{{

# shellcheck disable=SC2034
TRUELINE_SHOW_VIMODE=true
source ~/git-repos/private/trueline/trueline.sh
PROMPT_COMMAND=$'save_reload_hist\n'"$PROMPT_COMMAND"

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
bind -m vi-insert '"\C-x": backward-kill-line'
bind -m vi-insert '"\ex": backward-kill-word'
bind -m vi-insert '"\ef": forward-word'
bind -m vi-insert '"\eb": backward-word'
# Cycle forward with TAB and backwards with S-Tab when using menu-complete
bind -m vi-insert '"\C-i": menu-complete'
bind -m vi-insert '"\e[Z": menu-complete-backward'

# Command (normal) mode
bind -m vi-command '"H": beginning-of-line'
bind -m vi-command '"L": end-of-line'
bind -m vi-command '"k": ""'
bind -m vi-command '"j": ""'
bind -m vi-command '"v": ""' # Don't edit command with default editor (nvim)
bind -m vi-command '"\C-e": edit-and-execute-command'

# Bind C-p and C-n to search the history conditional on input (like zsh) instead
# of simply going up or down (note: we cannot seem to set this in the inputrc so
# we do it here instead)
bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

# }}}
# Aliases {{{

# Bash
alias sh='bash'
alias sbp='source ~/.bash_profile'
alias u='cd ..'
alias 2u='cd ../..'
alias 3u='cd ../../..'
alias 4u='cd ../../../..'
alias h='cd ~'
alias q='exit'
alias c='clear'
alias o='open'
if [ "$OSTYPE" == 'linux-gnu' ]; then
    alias open='xdg-open'
    alias ss='sudo su'
    if type "vimiv" > /dev/null 2>&1; then
        alias iv='vimiv'
    fi
fi
alias cp='cp -i'
alias rm='rm -v'
alias md='mkdir -p'
alias rd='rmdir'
alias sudo='sudo ' # Expand aliases when using sudo
alias ssh='TERM=xterm-256color; ssh'
ds() {
    # shellcheck disable=SC2086
    du -shc ${1:-*} | sort -rh | fzf
}
alias diff='diff -u --color'
alias dsf='git diff --no-index'
alias ur='unrar x'
alias uz='unzip'
alias rsync='rsync -auP'
alias ti='hyperfine'
alias ping='prettyping --nolegend --last 30'

# Other binaries
if [[ -f "$BASE_PKG_DIR/share/bash-completion/bash_completion" ]]; then
    . "$BASE_PKG_DIR/share/bash-completion/completions/man"
    alias m='man'
    complete -F _man m
fi
if type "htop" > /dev/null 2>&1; then
    alias ht='htop'
fi
if type "lsd" > /dev/null 2>&1; then
    alias ls='lsd -F --color=auto'
    cd() { builtin cd "$@" && lsd -F --color=auto; }
fi
if type "nvim" > /dev/null 2>&1; then
    alias v='nvim --listen /tmp/nvimsocket'
    if [ -f "$HOME/git-repos/private/dotfiles/vim/vimrc_min" ]; then
        alias mnvrc='nvim -u $HOME/git-repos/private/dotfiles/vim/vimrc_min'
    fi
fi
if type "ranger" > /dev/null 2>&1; then
    alias fm='ranger'
fi
if type "bat" > /dev/null 2>&1; then
    # Colorized cat
    alias dog='bat --color always --style numbers --theme TwoDark'
fi
if type "unimatrix" > /dev/null 2>&1; then
    alias iamneo='unimatrix -s 90'
fi
if type "R" > /dev/null 2>&1; then
    alias R='R --no-save --quiet'
    alias rs='Rscript'
fi
if type "tmux" > /dev/null 2>&1 && [ -f "$HOME/.tmux/tmux.conf" ]; then
    if [ "$USER" = 'pedro' ]; then
        tmux_session_name='petobens'
    else
        tmux_session_name="$USER"
    fi
    # shellcheck disable=SC2139
    alias tm="tmux -f $HOME/.tmux/tmux.conf new -A -s $tmux_session_name"
    unset tmux_session_name
fi
if type "mpv" > /dev/null 2>&1; then
    # (P)hot(b)ooth (webcam)
    alias pb='mpv tv:// --tv-height=500 --tv-width=400 --tv-fps=60 '\
'--really-quiet --title=webcam --screenshot-directory=~/Pictures/Screenshots'
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
    alias gF='git push --force-with-lease'
    __git_complete gF _git_push
    alias gdr='git push origin --delete'
    __git_complete gdr _git_push
    alias gP='git pull'
    __git_complete gp _git_pull
    alias gf='git fetch'
    __git_complete gf _git_fetch
    alias gr='git rebase'
    __git_complete gr _git_rebase
    alias gra='git remote add'
    alias gst='git stash'
    alias gsp='git stash pop'
fi

# Docker
if type "docker" > /dev/null 2>&1; then
    alias db='docker build -t'
    alias dr='docker run'
    alias dcr='docker container rename'
fi

# Python
if type "python" > /dev/null 2>&1; then
    alias python='python3'
    alias py='python'
    alias pyd='python3 -m pdb -cc'
    alias pip='pip3'
    if type "jupyter-notebook" > /dev/null 2>&1; then
        alias jn='jupyter-notebook'
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
        alias peu='pipenv uninstall'
        alias peg='pipenv graph'
        alias pes='pipenv shell'
        alias pep='pipenv run python'
        alias ped='pipenv run python -m pdb -cc'
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

# Platform dependent aliases
if [[ "$OSTYPE" != 'darwin'* ]]; then
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
alias cmssh='TERM=xterm-256color; sshpass -p "$(pass claro/ssh/pytonp01)" '\
'ssh mjolnir'
alias cvssh='TERM=xterm-256color; sshpass -p "$(pass claro/ssh/varas)" '\
'ssh varas'
alias ctssh='TERM=xterm-256color; sshpass -p "$(pass claro/ssh/tcal)" '\
'ssh tcal'
alias codb='rlwrap -a"$(pass claro/oracle/rac8/dracing)" -N '\
'sql CTI22156/"$(pass claro/oracle/rac8/cti22156)"'\
'@exa1-scan.claro.amx:1521/RAC8.WORLD'
alias cowdb='rlwrap -a"$(pass claro/oracle/rac8/cti22156)" -N '\
'sql CTI22156/"$(pass claro/oracle/rac8/cti22156)"'\
'@exa1-scan.claro.amx:1521/RAC8.WORLD'
alias cpdb=' PGPASSWORD="$(pass claro/postgres/tcal)" pgcli '\
'-h tcalt-01.claro.amx -p 5432 -U airflow -d delver'

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
alias hdbr='mongo mongodb://humberDbRead:"$(pass humber/mongodb/humberDbRead)"'\
'@db1.humber.com.ar:37117,db2.humber.com.ar:37117,'\
'arbiter.humber.com.ar:37117/humberPro001?replicaSet=humber-replica-set'
alias hdbw='mongo mongodb://pedroFerrari:"$(pass humber/mongodb/pedroFerrari)"'\
'@db1.humber.com.ar:37117,db2.humber.com.ar:37117,'\
'arbiter.humber.com.ar:37117/humberPro001?replicaSet=humber-replica-set'

# Azure server
alias assh='TERM=xterm-256color; sshpass -p "$(pass azure/ssh/pedroazurevm)" '\
'ssh azurevm'

# }}}
# Fzf and cli apps {{{

# Z (load it but unalias it to override it with fzf version)
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if [ -f "$BASE_PKG_DIR/etc/profile.d/z.sh" ]; then
        . "$BASE_PKG_DIR/etc/profile.d/z.sh"
    fi
else
    if  [[ -f "/usr/share/z/z.sh" ]]; then
        .  '/usr/share/z/z.sh'
    fi
fi
unalias z 2> /dev/null

# Fzf
if type "fzf" > /dev/null 2>&1; then
    if [ -f "$HOME/.fzf_bash.sh" ]; then
        . "$HOME/.fzf_bash.sh"
    fi
fi

# }}}
# Functions {{{

# Save and reload the history after each command finishes (this must be called
# by the PROMPT_COMMAND; see: https://unix.stackexchange.com/a/18443)
# Note that we need to save the last_exit_status to be reused by the prompt
save_reload_hist() {
    local last_exit_status=$?
    history -n; history -w; history -c; history -r
    return $last_exit_status
}

# Update the system package and language libraries
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
    if type "pipx" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python binaries with pipx...\033[0m"
        pipx upgrade-all --skip unimatrix
    fi
    if type "python3" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python user modules...\033[0m"
        outdated="$(pip list --user --outdated)"
        if [ -n "$outdated" ]; then
            echo "$outdated"
            u_list=$(pip list --user --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1)
            for i in $u_list; do
                read -p "Do you want to update $i (y/n)? " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    pip install --user -U "$i"
                fi
            done
        fi
    fi
    if type "R" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating R packages...\033[0m"
        R --slave --no-save --no-restore -e \
'update.packages(ask=TRUE, checkBuilt=TRUE, lib.loc=Sys.getenv("R_LIBS_USER"))'
    fi
    if type "tlmgr" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Latex packages...\033[0m"
        sudo tlmgr update --all
    fi
    if type "npm" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Node packages...\033[0m"
        npm update -g
    fi
    if type "cargo-install-update" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating rust binaries...\033[0m"
        cargo install-update --all
    fi
}

# }}}
