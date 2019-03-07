# Options {{{

# Set base dir
base_pkg_dir='/usr'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi
fi

# Enable completion and key bindings (note: we override some of these mappings
# below)
if [[ "$OSTYPE" == 'darwin'* ]]; then
    [[ $- == *i* ]] && . "$base_pkg_dir/opt/fzf/shell/completion.bash" 2> /dev/null
    . "$base_pkg_dir/opt/fzf/shell/key-bindings.bash"
else
    [[ $- == *i* ]] && . "$base_pkg_dir/share/fzf/completion.bash" 2> /dev/null
    . "$base_pkg_dir/share/fzf/key-bindings.bash"
fi

# Change default options (show 15 lines, use top-down layout)
export FZF_DEFAULT_OPTS='--height 15 --reverse --bind=ctrl-space:toggle+down'

# Use fd for files and dirs
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
if type "bat" > /dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color always --style numbers \
--theme TwoDark --line-range :200 {}' \
--expect=ctrl-e,ctrl-o,alt-f \
--header=enter=paste,\ ctrl-e=vim,\ ctrl-o=open,\ alt-f=ranger"
fi
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
if type "tree" > /dev/null 2>&1; then
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200' \
--expect=ctrl-t,alt-c,alt-f \
--header=enter=cd,\ ctrl-t=fzf-file,\ alt-c=fzf-dir,\ alt-f=ranger"
fi

# Disable tmux integration (use ncurses directly)
export FZF_TMUX='0'

# Extend list of commands with fuzzy completion (basically add our aliases)
complete -F _fzf_path_completion -o default -o bashdefault v o dog

# }}}
# File and dirs {{{

# Custom Ctrl-t mapping (also Alt-t to ignore git-ignored files)
__fzf_select_custom() {
    local cmd dir
    cmd="$FZF_CTRL_T_COMMAND"
    if [ "$1" == 'no-ignore' ]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [ "$2" ]; then
        cmd="$cmd . $2"  # use narrow dir
    fi
    out=$(eval "$cmd" |
    FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf +m)
    key=$(head -1 <<< "$out")
    file=$(head -2 <<< "$out" | tail -1)

    if [[ -n $file ]]; then
        if [[ "$key" = ctrl-e ]]; then
            printf 'v %q' "$file"
        elif [[ "$key" = ctrl-o ]]; then
            printf 'open %q' "$file"
        elif [[ "$key" = alt-f ]]; then
            # FIXME: Not working due to ranger bug
            printf 'ranger %q' "$file"
        else
            printf '%q' "$file"
        fi
    else
        return 1
    fi
}
fzf-file-widget-custom() {
    local selected=""
    # shellcheck disable=SC2119
    selected="$(__fzf_select_custom "$1" "$2")"
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
# shellcheck disable=SC2016
bind -x '"\C-t": "fzf-file-widget-custom"'
bind -m vi-command '"\C-t": "i\C-t"'
bind -x '"\et": "fzf-file-widget-custom no-ignore"'
bind -m vi-command '"\et": "i\et"'


# Helper that defines actions for keys in directory-like maps
__fzf_cd_action_key__() {
    out="$1"
    key=$(head -1 <<< "$out")
    dir=$(head -2 <<< "$out" | tail -1)
    if [[ -n $dir ]]; then
        if [[ "$key" = alt-f ]]; then
            printf 'ranger %q' "$dir"
        elif [[ "$key" = ctrl-t ]]; then
            # Note: this will execute an action directly (paste, with <CR>,
            # won't work)
            __fzf_select_custom "no-ignore" "$dir"
        elif [[ "$key" = alt-c ]]; then
            __fzf_cd_custom__ "no-ignore" "$dir"
        else
            printf 'cd %q' "$dir"
        fi
    else
        return 1
    fi
}

# Custom Alt-c maps (also Alt-d to ignore git-ignored dirs)
__fzf_cd_custom__() {
    local cmd dir
    cmd="$FZF_ALT_C_COMMAND"
    if [ "$1" == 'no-ignore' ]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [ "$2" ]; then
        cmd="$cmd . $2"  # use narrow dir
    fi
    out=$(eval "$cmd" | \
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf +m)
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ec": "\C-x\C-addi`__fzf_cd_custom__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ec": "i\ec"'
# shellcheck disable=SC2016
bind '"\ed": "\C-x\C-addi`__fzf_cd_custom__ no-ignore`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ed": "i\ed"'

# Alt-h map to cd from home dir
# shellcheck disable=SC2016
bind '"\eh": "\C-x\C-addi`__fzf_cd_custom__ no-ignore ~`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\eh": "i\eh"'

# Alt-p mapping to cd to selected parent directory (sister to Alt-c)
__fzf_cd_parent__() {
    local dirs=()
    get_parent_dirs() {
        if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
        if [[ "${1}" == '/' ]]; then
            for _dir in "${dirs[@]}"; do echo "$_dir"; done
        else
            get_parent_dirs "$(dirname "$1")"
        fi
    }
    start_dir="$(dirname "$PWD")"  # start with parent dir
    cmd="get_parent_dirs $(realpath "${1:-$start_dir}")"
    out=$(eval "$cmd" | \
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf +m)
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ep": "\C-x\C-addi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ep": "i\ep"'

# Z
z() {
    [ $# -gt 0 ] && _z "$*" && return
    out="$(_z -l 2>&1 | fzf --nth 2..  --inline-info +s --tac \
        --expect=ctrl-t,alt-c,alt-f --query "${*##-* }" \
        --preview 'tree -C {2..} | head -200' \
        --header=enter=cd,\ alt-f=ranger,\ ctrl-t=fzf | \
        sed 's/^[0-9,.]* *//')"
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ez": "\C-x\C-addi`z`\C-x\C-e\C-x\C-r\C-m"'
# shellcheck disable=SC2016
bind -m vi-command '"\ez": "ddi`z`\C-x\C-e\C-x\C-r\C-m"'

# }}}
# Tmux {{{

# Tmux session switcher (`tms foo` attaches to `foo` if exists, else creates
# it)
tms() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ "$1" ]; then
        if [ "$1" = "-ask" ]; then
            read -r -p "New tmux session name: " session_name
        else
            session_name="$1"
        fi
        tmux $change -t "$session_name" 2>/dev/null || \
            (tmux -f "$HOME/.tmux/tmux.conf" new-session -d -s "$session_name" && \
            tmux $change -t "$session_name");
        return
    fi
    session=$(tmux list-sessions -F \
        "#{session_name}" 2>/dev/null | fzf --exit-0) && \
        tmux $change -t "$session" || echo "No sessions found."
}
# Tmux session killer
tmk() {
    local session
    session=$(tmux list-sessions -F "#{session_name}" | \
        fzf --query="$1" --exit-0) &&
    tmux kill-session -t "$session"
}

# }}}
# Git {{{

# Forgit (git and fzf)
export FORGIT_NO_ALIASES="1"
alias gl=__forgit_log
alias gd=__forgit_diff
alias ga=__forgit_add
alias gcu=__forgit_restore
alias gsv=__forgit_stash_show
if [ -f "$HOME/.local/bin/forgit.plugin.sh" ]; then
    . "$HOME/.local/bin/forgit.plugin.sh"
fi

# }}}
