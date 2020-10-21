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
# Bindings {{{

# Set vi mode
set -o vi

# Switch between vi and emacs mode (first unbind ctrl-w)
stty werase undef
bind -m vi-command '"\C-w": emacs-editing-mode'
bind -m vi-insert '"\C-w": emacs-editing-mode'
bind -m emacs-standard '"\C-w": vi-editing-mode'

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
alias mv='mv -i'
alias rm='rm -v'
alias md='mkdir -p'
alias rd='rmdir'
alias sudo='sudo ' # Expand aliases when using sudo
alias ssh='TERM=xterm-256color; ssh'
ds() {
    # shellcheck disable=SC2086
    du -shc ${1:-*} | sort -rh | fzf
}
alias df='df -h'
alias diff='diff -u --color'
alias ur='unrar x'
alias uz='unzip'
alias rsync='rsync -auP'
alias ti='hyperfine'
alias ping='prettyping --nolegend --last 30'
alias wbs='curl v2.wttr.in/Buenos_Aires'

# Unpack helper
up() {
    if [[ -f "$1" ]]; then
        case $1 in
            *.tar.bz2) cmd="tar xjf" ;;
            *.tar.gz) cmd="tar xzf" ;;
            *.bz2) cmd="bunzip2" ;;
            *.rar) cmd="unrar x" ;;
            *.gz) cmd="gunzip" ;;
            *.tar) cmd="tar xf " ;;
            *.tbz2) cmd="tar xjf" ;;
            *.tgz) cmd="tar xzf" ;;
            *.zip) cmd="unzip" ;;
            *.Z) cmd="uncompress" ;;
            *.7z) cmd="7z x" ;;
            *.deb) cmd="ar x" ;;
            *.tar.xz) cmd="tar xf" ;;
            *.tar.zst) cmd="unzstd" ;;
            *) echo "'$1' cannot be extracted via unpack function" ;;
        esac
        if [[ -n "$cmd" ]]; then
            eval "$cmd $1"
        fi
    else
        echo "'$1' is not a valid file"
    fi
}

# Other binaries
if [[ -f "$BASE_PKG_DIR/share/bash-completion/bash_completion" ]]; then
    . "$BASE_PKG_DIR/share/bash-completion/completions/man"
    complete -F _man m # this is actually defined in fzf_bash file
fi
if type "htop" > /dev/null 2>&1; then
    alias ht='htop'
fi
if type "ctop" > /dev/null 2>&1; then
    alias ct='TERM=xterm-256 ctop'
fi
if type "progress" > /dev/null 2>&1; then
    alias pg='progress -w'
fi
if type "proxychains" > /dev/null 2>&1; then
    pc() {
        proxychains -q "$@"
    }
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
if type "dust" > /dev/null 2>&1; then
    alias rds='dust -r -b'
fi
if type "fusermount3" > /dev/null 2>&1; then
    alias fu='fusermount3 -zu'
fi
if type "unimatrix" > /dev/null 2>&1; then
    alias iamneo='unimatrix -s 90'
fi
if type "R" > /dev/null 2>&1; then
    alias R='R --no-save --quiet'
    alias rs='Rscript'
    if type "radian" > /dev/null 2>&1; then
        alias r='radian --quiet'
    fi
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
    alias pb='mpv av://v4l2:/dev/video0 --really-quiet --title=webcam ' \
        '--screenshot-directory=~/Pictures/Screenshots'
fi

# Git (similar to vim's fugitive); also bind auto-complete functions to each
# alias
if type "git" > /dev/null 2>&1; then
    _completion_loader git
    alias gs='git status'
    alias gcl='git clone'
    alias gco='git checkout'
    __git_complete gco _git_checkout
    alias gcb='git checkout $(git branch | fzf | tr -d "*")'
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
    alias grc='git rebase --continue'
    __git_complete gr _git_rebase
    alias gra='git remote add'
    alias gst='git stash'
    alias gsp='git stash pop'
    alias gap='git apply'
    gdp() {
        git diff > "$1"
    }
    alias dsf='git diff --no-index'
fi
if type "gh" > /dev/null 2>&1; then
    alias ghi='gh issue'
    alias ghp='gh pr'
    alias ghr='gh repo'
fi

# Docker
if type "docker" > /dev/null 2>&1; then
    alias db='docker build -t'
    alias dr='docker run'
    alias dcr='docker container rename'
    alias drd='docker rmi -f $(docker images -f "dangling=true" -q)'
    alias dre='docker container rm $(docker container ls --all -q -f status=exited)'
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
        alias ipy='ipython3'
    fi
    if type "pipenv" > /dev/null 2>&1; then
        alias pel='pipenv run pip list'
        alias pei='pipenv install'
        alias peu='pipenv uninstall'
        alias peg='pipenv graph'
        alias pes='pipenv shell'
        alias pep='pipenv run python'
        alias ped='pipenv run python -m pdb -cc'
        alias pet='pipenv run pytest'
        alias pej='pipenv run jupyter notebook'
    fi
    if type "poetry" > /dev/null 2>&1; then
        alias pol='poetry run pip list'
        alias poa='poetry add'
        alias poad='poetry add --dev'
        alias poi='poetry install'
        alias pou='poetry update'
        alias por='poetry remove'
        alias pord='poetry remove --dev'
        alias pog='poetry show --tree'
        alias poe='poetry env'
        alias pop='poetry run python'
        alias pod='poetry run python -m pdb -cc'
        alias pot='poetry run pytest'
        alias poj='poetry run jupyter notebook'
        alias poh='poetry run pre-commit run --all-files'
        pos() {
            # Load .env file before launching poetry shell
            cur_dir="$PWD"
            pyproject_base='pyproject.toml'
            for _ in 1 2; do
                pyproject_file="$cur_dir/$pyproject_base"
                if [ -f "$pyproject_file" ]; then
                    break
                else
                    cur_dir="$(dirname "$cur_dir")"
                fi
            done
            pyproject_dir="$(dirname "$pyproject_file")"
            if [ -f "$pyproject_dir/.env" ]; then
                set -a
                source "$pyproject_dir/.env"
                set +a
            fi
            poetry shell -q
        }
    fi
fi

# Package manager
if type "yay" > /dev/null 2>&1; then
    # Note yay will prompt twice: https://github.com/Jguer/yay/issues/170
    alias yay='yay --nodiffmenu --answerclean N --removemake'
    # Update pacman mirrorlist
    if type "reflector" > /dev/null 2>&1; then
        alias upm='sudo reflector --verbose --latest 25 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist'
    fi
fi
if type "vagrant" > /dev/null 2>&1; then
    alias vg='vagrant'
    alias vgs='vagrant global-status'
    alias vgh='vagrant halt'
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
        alias lsip='comm -23 <(pacman -Qqett | sort) <(pacman -Qqg base -g base-devel -g xorg | sort | uniq)'
    fi
fi

# }}}
# Work Aliases {{{

# Mostly vpn and databases; ssh hosts are defined in .ssh/config
alias kvpn='sudo pkill -INT -f "openconnect|openvpn|vpnc|snx"'

# Claro
# Note: this requires a passwordless stoken (use token-mode=rsa if password is
# enabled)
alias covpn='sudo pkill -INT -f openconnect; stoken | sudo openconnect '\
'--background --authgroup=1 --user="$(pass show claro/vpn/user)" '\
'--passwd-on-stdin "$(pass show claro/vpn/host-old)"'
alias cvpn='sudo pkill -INT -f snx; stoken | '\
'snx -s "$(pass show claro/vpn/host)" -u "$(pass show claro/vpn/user)"'
alias cmssh='TERM=xterm-256color; sshpass -p "$(pass show claro/ssh/pytonp01)" '\
'ssh mjolnir'
alias cpfssh='sshpass -p "$(pass show arch/localhost)" ssh localhost -N -D 54321'
alias cmtssh='TERM=xterm-256color; sshpass -p "$(pass show claro/ssh/pytonp01)" '\
'ssh mjolnir -R 9090:127.0.0.1:54321'
alias ctssh='TERM=xterm-256color; sshpass -p "$(pass show claro/ssh/tcal)" '\
'ssh tcal'
alias cttssh='TERM=xterm-256color; sshpass -p "$(pass show claro/ssh/tcal)" '\
'ssh tcal -R 9090:127.0.0.1:54321'
alias coddb='rlwrap -a"$(pass show claro/oracle/delver/pass)" -N '\
'sql DELVER/"$(pass show claro/oracle/delver/pass)"'\
'@"$(pass show claro/oracle/delver/host)":1521/RAC8.WORLD'
alias coldb='rlwrap -a -N sql system/oracle@localhost:49161/xe'
alias cptdb=' PGPASSWORD="$(pass show claro/postgres/tcalt/pass)" pgcli '\
'-h "$(pass show claro/postgres/tcalt/host)" -p 5432 -U airflow -d delver'
alias cpldb='pgcli -h localhost -U pedro -d delver_dev'

# Habitat
alias hsshp='TERM=xterm-256color; ssh habitat-server-prd'
alias hsshs='TERM=xterm-256color; ssh habitat-server-stg'
alias hdb='PGPASSWORD="$(pass show habitat/postgres/pass)" pgcli -h '\
'"$(pass show habitat/postgres/host)" -U mutt -d habitat'

# Meli
alias mgpp='echo $(pass show meli/vpn/pin)'\
'$(oathtool --base32 --totp $(pass show meli/vpn/secret))'
mvssh() {
    (
        command cd "/home/pedro/OneDrive/mutt/clients/meli/vpn" || exit
        vg_status=$(vagrant status | grep -P "^default\S*\W" | rev | cut -d ' ' -f 2 | rev)
        if [[ "$vg_status" != 'running' ]]; then
            vagrant up
        fi
        vg_ssh_cmd="vagrant ssh"
        if [[ "$1" ]]; then
            case "$1" in
                proxy)
                    vg_ssh_cmd="$vg_ssh_cmd -- -v -N -D $2"
                    ;;
                *)
                    vg_ssh_cmd="$vg_ssh_cmd -t -c '$1'"
                    ;;
            esac
        fi
        eval "$vg_ssh_cmd"
    )
}
alias mvp='mvssh proxy 12345'
alias mvsvpn='mvssh "sudo service gpd start; globalprotect show --status"'
alias mvtt='vagrant ssh -- -L 127.0.0.1:1025:$(pass show meli/teradata/host):1025 -v -N'
alias mvpt='vagrant ssh -- -L 127.0.0.1:8443:$(pass show meli/presto/host):443 -v -N'

# UC
uvpn() {
    vpn_cmd="openvpn --daemon --config $(pass show urban/vpn/config-path)"
    vpn_cmd+=" --auth-user-pass <(echo -e \"$(pass show urban/vpn/user)\n$(pass show urban/vpn/pass)\")"
    cmd="sudo pkill -INT -f openvpn; sudo bash -c '$vpn_cmd'"
    eval "$cmd"
}
alias ussh='TERM=xterm-256color; sshpass -p "$(pass show urban/server/187/pass)" ssh urban'

# }}}
# Functions {{{

# Save and reload the history after each command finishes (this must be called
# by the PROMPT_COMMAND; see: https://unix.stackexchange.com/a/18443)
# Note that we need to save the last_exit_status to be reused by the prompt
save_reload_hist() {
    local last_exit_status=$?
    history -n
    history -w
    history -c
    history -r
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
        pipx upgrade-all
    fi
    if type "python3" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python user modules...\033[0m"
        outdated="$(pip list --user --outdated)"
        if [ -n "$outdated" ]; then
            echo "$outdated"
            u_list=$(pip list --user --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1)
            for i in $u_list; do
                # FIXME: remove this once jedi upgrades
                if [[ "$i" == 'parso' ]]; then
                    continue
                fi
                pip install --user -U "$i"
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
# Prompt {{{

# shellcheck disable=SC2034
TRUELINE_SHOW_VIMODE=true
source ~/git-repos/private/trueline/trueline.sh
PROMPT_COMMAND=$'save_reload_hist\n'"$PROMPT_COMMAND"

# }}}
# Fzf and cli apps {{{

# Z (load it but unalias it to override it with fzf version). Note: we must load
# if after the prompt since it modifies the prompt command
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if [ -f "$BASE_PKG_DIR/etc/profile.d/z.sh" ]; then
        . "$BASE_PKG_DIR/etc/profile.d/z.sh"
    fi
else
    if [[ -f "/usr/share/z/z.sh" ]]; then
        source /usr/share/z/z.sh
    fi
fi
unalias z 2> /dev/null

# Fzf
if type "fzf" > /dev/null 2>&1; then
    if [ -f "$HOME/.fzf_bash.sh" ]; then
        . "$HOME/.fzf_bash.sh"
    fi
fi

# Pass
if type "gopass" > /dev/null 2>&1; then
    source <(pass completion bash)
    alias pass='TERM=xterm-256color; gopass'
fi

# }}}
