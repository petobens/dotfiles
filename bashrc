# shellcheck disable=SC1091,SC2148

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

# Disable bracketed-paste (which annoyingly highlights pasted text)
bind 'set enable-bracketed-paste off'

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
alias df='df -h'
alias diff='diff -u --color'
alias rsync='rsync -auP'
alias ti='hyperfine'
alias ping='prettyping --nolegend --last 30'
alias wbs='curl v2.wttr.in/Buenos_Aires'
alias ff='fastfetch'

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
            *.7Z) cmd="7z x" ;;
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
if type "zoxide" > /dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi
if type "lsd" > /dev/null 2>&1; then
    alias ls='lsd -F --color=auto'
    cd() { builtin cd "$@" && lsd -F --color=auto; }
fi
if type "nvim" > /dev/null 2>&1; then
    alias v='nvim'
    if [ -f "$HOME/git-repos/private/dotfiles/nvim/minimal.lua" ]; then
        alias mnvi='nvim --clean -u $HOME/git-repos/private/dotfiles/nvim/minimal.lua'
    fi
fi
if type "ranger" > /dev/null 2>&1; then
    alias fm='ranger'
fi
if type "bat" > /dev/null 2>&1; then
    # Colorized cat
    alias dog='bat'
fi
if type "dust" > /dev/null 2>&1; then
    ds() {
        # shellcheck disable=SC2086
        du -shc ${1:-*} | sort -rh | fzf
    }
    alias rds='dust -r -b' # Rust Disk Space
fi
if type "unimatrix" > /dev/null 2>&1; then
    alias iamneo='unimatrix -s 90'
fi
if type "tmux" > /dev/null 2>&1 && [ -f "$HOME/.config/tmux/tmux.conf" ]; then
    if [ "$USER" = 'pedro' ]; then
        tmux_session_name='petobens'
    else
        tmux_session_name="$USER"
    fi
    # shellcheck disable=SC2139
    alias tm="tmux -f $HOME/.config/tmux/tmux.conf new -A -s $tmux_session_name"
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
    _comp_gco() {
        # As per https://github.com/scop/bash-completion/issues/545
        # shellcheck disable=SC2034
        local __git_cmd_idx=0
        _git_checkout
    }
    __git_complete gco _comp_gco
    alias gcob='git checkout -b'
    alias gcp='git cherry-pick'
    alias gb='git branch'
    __git_complete gb _git_branch
    alias gbd='git branch -D'
    __git_complete gbd _git_branch
    alias gbdr='git push origin --delete'
    __git_complete gbdr _git_branch
    alias gp='git push'
    __git_complete gp _git_push
    alias gF='git push --force-with-lease'
    __git_complete gF _git_push
    alias gP='git pull'
    __git_complete gP _git_pull
    alias gPr='git pull --rebase'
    __git_complete gPr _git_pull
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
    gdcp() {
        git diff --cached > "$1"
    }
    alias dgd='git diff --no-index' # Diff (with) git-delta
    alias grl='git reset --soft HEAD^'
fi
if type "gh" > /dev/null 2>&1; then
    alias ghi='gh issue'
    alias ghp='gh pr'
    alias ghr='gh repo'
    alias ghcp='gh pr checkout'
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
    if type "jupyter-lab" > /dev/null 2>&1; then
        alias jl='jupyter-lab'
    fi
    if type "pip" > /dev/null 2>&1; then
        alias piu='pip install --user'
    fi
    if type "ipython3" > /dev/null 2>&1; then
        alias ipy='ipython3'
    fi
    if type "poetry" > /dev/null 2>&1; then
        alias pol='poetry run pip list'
        alias poa='poetry add'
        alias poad='poetry add --group=dev'
        alias poao='poetry add --optional'
        alias poi='poetry install'
        alias poid='poetry install --with=dev'
        alias poud='poetry update'
        alias poug='poetry up --latest'
        alias por='poetry run'
        alias porm='poetry remove'
        alias pog='poetry show --tree'
        alias poe='poetry env'
        alias pop='poetry run python'
        alias pod='poetry run python -m pdb -cc'
        alias pot='poetry run pytest -n auto --cov'
        alias poj='poetry run jupyter lab'
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
    if type "uv" > /dev/null 2>&1; then
        alias uva='uv add'
        alias uvad='uv add --dev'
        alias uvrm='uv remove'
        alias uvs='uv sync'
        alias uvi='uv sync --locked' # install
        alias uvl='uv pip list'
        alias uvr='uv run'
        alias uvp='uv run python'
        alias uvd='uv run python -m pdb -cc'
        alias uvt='uv run pytest -n auto --cov'
        alias uvh='uv run pre-commit run --all-files' # hooks
        alias uvj='uv run jupyter lab'
        uvsh() {
            local venv_name=".venv"

            local dir="$PWD"
            local pyproject_dir=""
            while [[ "$dir" != "/" ]]; do
                if [[ -f "$dir/pyproject.toml" ]]; then
                    pyproject_dir="$dir"
                    break
                fi
                dir="$(dirname "$dir")"
            done
            if [[ -z "$pyproject_dir" ]]; then
                echo "[ERROR] pyproject.toml not found in any parent directory." >&2
                return 1
            fi

            local venv_path="${pyproject_dir}/${venv_name}"
            local activator="${venv_path}/bin/activate"
            if [[ ! -f "${activator}" ]]; then
                echo "[ERROR] Python venv not found: ${venv_path}" >&2
                return 1
            else
                echo "[INFO] Activating Python venv: ${venv_path}"
            fi

            . "${activator}"
        }
    fi
fi

# Latex
if type "tlmgr" > /dev/null 2>&1; then
    alias tlmgr='sudo -E env "PATH=$PATH" tlmgr'
fi

# Package manager
if type "yay" > /dev/null 2>&1; then
    # Note yay will prompt twice: https://github.com/Jguer/yay/issues/170
    alias yay='yay --diffmenu=false --answerclean N --removemake'
    alias yunv='yay -Syu --mflags --skipinteg --answerclean N --diffmenu=false --combinedupgrade'
    # Update pacman mirrorlist
    if type "reflector" > /dev/null 2>&1; then
        alias upm='sudo reflector --verbose --latest 25 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist'
    fi
    # List installed packages (query the database)
    alias yl='yay -Q'
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

# NFS
alias mpnfs='sudo mount synology-ds:/volume1/Shared-DS220 /mnt/nfs'
alias mfnfs='sudo mount synology-flor:/volume1/Shared-DS220 /mnt/nfs'
alias unfs='sudo umount /mnt/nfs'
alias npssh='sshpass -p "$(pass show synology/synology-ds/petobens)" ssh synology -t "cd /volume1/Shared-DS220; bash --login"'
alias nfssh='sshpass -p "$(pass show synology/synology-flor/flor)" ssh synology-flor -t "cd /volume1/Shared-DS220; bash --login"'

# VPN
alias kvpn='sudo pkill -INT -f "openconnect|openvpn|vpnc|snx"'

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
            yay -Syu --diffmenu=false --answerclean N --removemake --devel \
                --timeupdate --combinedupgrade
            yay -Yc --noconfirm
        fi
    fi
    if type "pipx" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python binaries with pipx...\033[0m"
        pipx upgrade-all --include-injected
    fi
    if type "uv" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python binaries with uv...\033[0m"
        uv tool upgrade --all
    fi
    if type "python3" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Python user modules...\033[0m"
        outdated="$(pip list --user --outdated)"
        if [ -n "$outdated" ]; then
            echo "$outdated"
            pip list --user --outdated | grep -v '^-e' | cut -d ' ' -f 1 | tail -n +3 | xargs -n 1 pip install --user --break-system-packages -U
        fi
    fi
    if type "tlmgr" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Latex packages...\033[0m"
        sudo -E env "PATH=$PATH" tlmgr update --all
    fi
    if type "npm" > /dev/null 2>&1; then
        echo -e "\033[1;34m\n-> Updating Node packages...\033[0m"
        npm_config_loglevel=error npm update --no-fund -g
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
