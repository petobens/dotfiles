# Set base dir
base_pkg_dir='/usr'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi
fi

# Enable completion and key bindings
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
--header=ctrl-e=vim,\ ctrl-o=open,\ enter=paste"
fi
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
if type "tree" > /dev/null 2>&1; then
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200' \
--header=enter=cd"
fi
# Disable tmux integration (use ncurses directly)
export FZF_TMUX='0'

# Extend list of commands with fuzzy completion (basically add our aliases)
complete -F _fzf_path_completion -o default -o bashdefault v o dog

# Alt-t mapping to select files without ignoring gitignored ones
# shellcheck disable=SC2120
__fzf_select_noignore__() {
    local cmd dir
    cmd="$FZF_CTRL_T_COMMAND --no-ignore-vcs"
    eval "$cmd" | \
        FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} \
        --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf -m "$@" | \
        while read -r item; do
        printf '%q ' "$item"
    done
    echo
}
fzf-file-widget-no-ignore() {
    local selected=""
    # shellcheck disable=SC2119
    selected="$(__fzf_select_noignore__)"
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
# shellcheck disable=SC2016
bind -x '"\et": "fzf-file-widget-no-ignore"'
bind -m vi-command '"\et": "i\et"'

# Alt-d mapping to cd without ignoring gitignored dirs
__fzf_cd_noignore__() {
    local cmd dir
    cmd="$FZF_ALT_C_COMMAND --no-ignore-vcs"
    dir=$(eval "$cmd" | \
            FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} \
        --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m) \
        && printf 'cd %q' "$dir"
}
# shellcheck disable=SC2016
bind '"\ed": "\C-x\C-addi`__fzf_cd_noignore__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ed": "i\ed"'

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
    local start_dir=""
    local DIR=""
    start_dir="$(dirname "$PWD")"  # start with parent dir
    DIR=$(get_parent_dirs "$(realpath "${1:-$start_dir}")" | \
        fzf --preview 'tree -C -d -L 2 {} | head -200')
    if [[ -n $DIR ]]; then
        printf 'cd %q' "$DIR"
    else
        return 1
    fi
}
# shellcheck disable=SC2016
bind '"\ep": "\C-x\C-addi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ep": "i\ep"'

# Tmux session switcher (`tms foo` attaches to `foo` it exists, else creates
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
        --inline-info +s --tac --query "${*##-* }" \
        --preview 'tree -C {2..} | head -200' | sed 's/^[0-9,.]* *//')"
    if [[ -n $dir ]]; then
        printf 'cd %q' "$dir"
    else
        return 1
    fi
}
# shellcheck disable=SC2016
bind '"\ez": "\C-x\C-addi`z`\C-x\C-e\C-x\C-r\C-m"'
# shellcheck disable=SC2016
bind -m vi-command '"\ez": "ddi`z`\C-x\C-e\C-x\C-r\C-m"'

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
