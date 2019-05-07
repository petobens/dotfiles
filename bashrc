# Options {{{

if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi

    # Path settings
    PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"
    PATH="$base_pkg_dir/bin:$base_pkg_dir/sbin:$PATH" # homebrew
    if [ -d "/Library/TeX/texbin" ]; then
        PATH="/Library/TeX/texbin:$PATH" # basictex
    fi
    if [ -d "/Applications/MATLAB_R2015b.app/bin" ]; then
        PATH="/Applications/MATLAB_R2015b.app/bin/matlab:$PATH" # matlab
    fi
    export PKG_CONFIG_PATH="$base_pkg_dir/lib/pkgconfig:$base_pkg_dir/lib"
    if [ -d "/usr/local/opt/sqlite/bin" ]; then
        PATH="/usr/local/opt/sqlite/bin:$PATH"
    fi

    # Symlink cask apps to Applications folder
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    # Set english utf-8 locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Enable terminal colors and highlight directories in blue, symbolic links
    # in purple, executable files in red and sticky dirs in green
    if ! type "gls" > /dev/null 2>&1; then
        export CLICOLOR=1
        export LSCOLORS=exfxCxDxbxegedabagcxed
    fi
else
    base_pkg_dir='/usr'

    # Local paths first (note that path is originally defined in /etc/profile)
    PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"
    export MANPATH="$HOME/local/share/man:$HOME/.local/share/man:$MANPATH"

    # Texlive
    if [ -d "$base_pkg_dir/local/texlive" ]; then
        PATH="$PATH:/usr/local/texlive/2019/bin/x86_64-linux"
        export MANPATH="$MANPATH:/usr/local/texlive/2019/texmf-dist/doc/man"
        export INFOPATH="$INFOPATH:/usr/local/texlive/2019/texmf-dist/doc/info"
    fi

    export BROWSER='chromium'

    # Scaling
    export GDK_SCALE=2
    export GDK_DPI_SCALE=0.5
fi

# Path OS agnostic settings
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi
if type "npm" > /dev/null 2>&1; then
    PATH="$HOME/.node_modules/bin:$PATH"
    export npm_config_prefix="$HOME/.node_modules"
fi
if type "go" > /dev/null 2>&1; then
    export GOPATH=$HOME/go
    PATH=$PATH:$GOPATH/bin
fi
if type "cargo" > /dev/null 2>&1; then
    PATH=$PATH:$HOME/.cargo/bin
fi
if type "ruby" > /dev/null 2>&1; then
    export GEM_HOME=$HOME/.gem
    PATH="$PATH:$GEM_HOME/bin"
fi
if type "pyenv" > /dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - --no-rehash bash)"
fi
# We use sqlcl instead of sqlplus (it must be manually installed to this dir)
if [ -d "$HOME/.local/sqlcl" ]; then
    PATH="$PATH:$HOME/.local/sqlcl/bin"
fi
# Prepend python virtual env to path if exists (this is useful when spawning a
# new terminal form within neovim). Note: this must be the very last PATH mod
if [ -n "$VIRTUAL_ENV" ]; then
    PATH="$VIRTUAL_ENV/bin:$PATH"
    # Also set airflow home to this dir (pipenv shell reads .env file)
    export AIRFLOW_HOME="$VIRTUAL_ENV/airflow"
fi

# Remove duplicate path entries
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')

# Language/binaries environmental variables
if type "vivid" > /dev/null 2>&1; then
    # shellcheck disable=SC2155
    export LS_COLORS="$(vivid generate onedarkish)"
else
    # Highlight directories in blue, symbolic links in purple, executable
    # files in red and sticky dirs in green
    export LS_COLORS="di=0;34:ln=0;35:ex=0;31:tw=0;32"
fi
if type "python" > /dev/null 2>&1; then
    export AIRFLOW_GPL_UNIDECODE='yes'
fi
if type "pipenv" > /dev/null 2>&1; then
    # Always create a pipenv venv (useful when running from vim)
    export PIPENV_IGNORE_VIRTUALENVS=1
    # Don't lock dependencies automatically when install/uninstall commands
    export PIPENV_SKIP_LOCK=1
fi
if type "pipx" > /dev/null 2>&1; then
    export PIPX_HOME=$HOME/.local/pipx
    export PIPX_BIN_DIR=$HOME/.local/bin
fi
if type "sqlplus" > /dev/null 2>&1; then
    export SQLPATH="$HOME/.config/sqlplus"
fi
if type "mssql-cli" > /dev/null 2>&1; then
    export MSSQL_CLI_TELEMETRY_OPTOUT=1
fi
if type "gpg" > /dev/null 2>&1; then
    GPG_TTY=$(tty)
    export GPG_TTY
fi
if type "shellcheck" > /dev/null 2>&1; then
    export SHELLCHECK_OPTS="-e SC1090"
fi
if type "rg" > /dev/null 2>&1; then
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"
fi

# Set editor to nvim and use it as a manpager
export EDITOR='nvim --listen /tmp/nvimsocket'
export MANPAGER='nvim +Man!'

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
if [ -f $base_pkg_dir/share/bash-completion/bash_completion ]; then
    . $base_pkg_dir/share/bash-completion/bash_completion
fi

# }}}
# Prompt {{{

# Show vi-mode in command prompt (this is actually a readline setting)
# See: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
bind "set show-mode-in-prompt on"
bind 'set vi-ins-mode-string \1\e[38;5;235;48;2;97;175;239;1m\2 I '\
'\1\e[38;2;97;175;239;48;2;208;208;208;1m\2\1\e[0m\2\1\e[6 q\2'
bind 'set vi-cmd-mode-string \1\e[38;5;235;48;2;152;195;121;1m\2 N '\
'\1\e[38;2;152;195;121;48;2;208;208;208;1m\2\1\e[0m\2\1\e[2 q\2'
# Switch to block cursor before executing a command
bind -m vi-insert 'RETURN: "\e\n"'


_ps1_separator=''
declare -A _ps1_colors=(
    [Black]='36;39;46' #24272e
    [White]='208;208;208' #d0d0d0
    [Purple]='198;120;221' #c678dd
    [SpecialGrey]='59;64;72' #3b4048
    [CursorGrey]='40;44;52' #282c34
    [Grey]='171;178;191' #abb2bf
    [Red]='224;108;117' #e06c75
    [Orange]='209;154;102' #d19a66
    [Mono]='130;137;151' #828997
)
_ps1_content() {
    fg_c="${_ps1_colors[$1]}"
    bg_c="${_ps1_colors[$2]}"
    style="$3m" # 1 for bold; 2 for normal
    content="$4"
    echo "\[\033[38;2;$fg_c;48;2;$bg_c;$style\]$content\[\033[0m\]"
}

_ps1_has_ssh(){
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        echo 'has_ssh'
    fi
}
_ps1_user() {
    venv="$1"
    branch="$2"
    has_ssh="$3"

    user="$USER"
    if [[ -n "$has_ssh" ]]; then
        user=" $user@$HOSTNAME"
    fi
    segment="$(_ps1_content Black White 1 " $user ")"

    bg_color="Purple"
    if [[ -z "$venv" ]]; then
        if [[ -n "$branch" ]]; then
            bg_color="SpecialGrey"
        else
            bg_color="CursorGrey"
        fi
    fi
    segment+="$(_ps1_content White $bg_color 1 $_ps1_separator)"
    echo "$segment"
}

_ps1_has_venv(){
    printf "%s" "${VIRTUAL_ENV##*/}"
}
_ps1_venv() {
    venv="$1"
    branch="$2"
    if [[ -n "$venv" ]]; then
        segment="$(_ps1_content Black Purple 1 "  $venv ")"
        bg_color="CursorGrey"
        if [[ -n "$branch" ]]; then
            bg_color="SpecialGrey"
        fi
        segment+="$(_ps1_content Purple $bg_color 1 $_ps1_separator)"
        echo "$segment"
    fi
}

_ps1_has_git_branch() {
    printf "%s" "$(git rev-parse --abbrev-ref HEAD 2> /dev/null)"
}
_ps1_git_mod_files() {
    nr_mod_files="$(git diff --name-only --diff-filter=M 2> /dev/null | wc -l )"
    mod_files=''
    if [ ! "$nr_mod_files" -eq 0 ]; then
        mod_files="✚ $nr_mod_files "
    fi
    echo "$mod_files"
}
_ps1_git_behind_ahead() {
    branch="$1"
    upstream="$(git config --get branch."$branch".merge)"
    if [[ -n $upstream ]]; then
        nr_behind_ahead="$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)" || nr_behind_ahead=''
        nr_behind="${nr_behind_ahead%	*}"
        nr_ahead="${nr_behind_ahead#*	}"
        git_behind_ahead=''
        if [ ! "$nr_behind" -eq 0 ]; then
        git_behind_ahead+=" $nr_behind "
        fi
        if [ ! "$nr_ahead" -eq 0 ]; then
        git_behind_ahead+=" $nr_ahead "
        fi
        echo "$git_behind_ahead"
    fi
}
_ps1_git_remote_icon() {
    remote=$(command git ls-remote --get-url 2> /dev/null)
    remote_icon=''
    if [[ "$remote" =~ "github" ]]; then
        remote_icon=' '
    elif [[ "$remote" =~ "bitbucket" ]]; then
        remote_icon=' '
    elif [[ "$remote" =~ "gitlab" ]]; then
        remote_icon=' '
    fi
    echo "$remote_icon"
}
_ps1_git() {
    branch="$1"
    if [[ -n $branch ]]; then
        branch_icon="$(_ps1_git_remote_icon)"
        segment="$(_ps1_content Grey SpecialGrey 2 " $branch_icon $branch ")"
        mod_files="$(_ps1_git_mod_files)"
        if [[ -n "$mod_files" ]]; then
            segment+="$(_ps1_content Red SpecialGrey 2 "$mod_files")"
        fi
        behind_ahead="$(_ps1_git_behind_ahead "$branch")"
        if [[ -n "$behind_ahead" ]]; then
            segment+="$(_ps1_content Purple SpecialGrey 2 "$behind_ahead")"
        fi
        segment+="$(_ps1_content SpecialGrey CursorGrey 1 $_ps1_separator)"
        echo "$segment"
    fi
}

_ps1_path() {
    p="${1/$HOME/ }"
    IFS='/' read -r -a arr <<< "$p"
    path_size="${#arr[@]}"
    if [ "$path_size" -eq 1 ]; then
        segment="\[\033[1m\]${arr[0]:=/}"
    elif [ "$path_size" -eq 2 ]; then
        segment="${arr[0]:=/}  \[\033[1m\]${arr[-1]}"
    else
        if [ "$path_size" -gt 3 ]; then
            p="/"$(echo "$p" | rev | cut -d '/' -f-3 | rev)
        fi
        curr=$(basename "$p")
        p=$(dirname "$p")
        segment="${p//\//  }  \[\033[1m\]$curr"
        if [[ "${p:0:1}" = '/' ]]; then
            segment="/$segment"
        fi
    fi
    segment="$(_ps1_content Mono CursorGrey 2 " $segment ")"

    read_only="$2"
    status="$3"
    if [[ -n $read_only ]]; then
        bg_color="Orange"
    else
        bg_color="Black"
        if [ "$status" != 0 ]; then
            bg_color="Red"
        fi
    fi
    segment+="$(_ps1_content CursorGrey $bg_color 1 $_ps1_separator)"
    echo "$segment"
}


_ps1_is_read_only(){
    if [[ ! -w $1 ]]; then
        echo 'read_only'
    fi
}
_ps1_read_only() {
    read_only="$1"
    status="$2"
    if [[ -n $read_only ]]; then
        segment+="$(_ps1_content Black Orange 1 "  ")"
        bg_color="Black"
        if [ "$status" != 0 ]; then
            bg_color="Red"
        fi
        segment+="$(_ps1_content Orange $bg_color 1 $_ps1_separator)"
        echo "$segment"
    fi
}

_ps1_status() {
    status="$1"
    if [ "$status" != 0 ]; then
        segment+="$(_ps1_content Black Red 1 " $status ")"
        segment+="$(_ps1_content Red Black 1 $_ps1_separator)"
        echo "$segment"
    fi
}

_ps1_command() {
    exit_status="$?"
    curr_dir="$PWD"
    git_branch="$(_ps1_has_git_branch)"
    venv="$(_ps1_has_venv)"
    has_ssh="$(_ps1_has_ssh)"
    is_read_only="$(_ps1_is_read_only "$curr_dir")"

    PS1=""
    PS1+=$(_ps1_user "$venv" "$git_branch" "$has_ssh")
    PS1+=$(_ps1_venv "$venv" "$git_branch")
    PS1+=$(_ps1_git "$git_branch")
    PS1+=$(_ps1_path "$curr_dir" "$is_read_only" "$exit_status")
    PS1+=$(_ps1_read_only "$is_read_only" "$exit_status")
    PS1+=$(_ps1_status "$exit_status")
    PS1+=" "  # non-breakable space
}
unset PROMPT_COMMAND
PROMPT_COMMAND=_ps1_command
PROMPT_COMMAND=$'save_reload_hist\n'"$PROMPT_COMMAND"

# Continuation prompt
PS2=$(_ps1_content Black White 1 " ... ")$(_ps1_content White Black 1 "$_ps1_separator ")

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
if [ -f $base_pkg_dir/share/bash-completion/bash_completion ]; then
    . $base_pkg_dir/share/bash-completion/completions/man
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

# Python
if type "python" > /dev/null 2>&1; then
    alias py='python'
    if [ ! -f "$base_pkg_dir"/bin/python2 ]; then
        alias python='python3'
        alias pip='pip3'
    fi
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
if [[ "$OSTYPE" == 'darwin'* ]]; then
    # Matlab
    alias matlab='/Applications/MATLAB_R2015b.app/bin/matlab -nodisplay '\
'-nodesktop -nosplash '
else
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
    if [ -f "$base_pkg_dir/etc/profile.d/z.sh" ]; then
        . "$base_pkg_dir/etc/profile.d/z.sh"
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
