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
    [[ $- == *i* ]] &&
    . "$base_pkg_dir/opt/fzf/shell/completion.bash" 2> /dev/null
    . "$base_pkg_dir/opt/fzf/shell/key-bindings.bash"
else
    [[ $- == *i* ]] &&
    . "$base_pkg_dir/share/fzf/completion.bash" 2> /dev/null
    . "$base_pkg_dir/share/fzf/key-bindings.bash"
fi

# Change default options and colors
export FZF_DEFAULT_OPTS='
--height 15
--inline-info
--prompt="❯ "
--bind=ctrl-space:toggle+up
--color=bg+:#282c34,bg:#24272e,fg:#abb2bf,fg+:#abb2bf,hl:#528bff,hl+:#528bff
--color=prompt:#61afef,header:#566370,info:#5c6370,pointer:#c678dd
--color=marker:#98c379,spinner:#e06c75,border:#282c34
'

# Use fd for files and dirs
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
if type "bat" > /dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="
--multi
--preview 'bat --color always --style numbers --theme TwoDark --line-range :200 {2}'
--expect=tab,ctrl-o,alt-c,alt-f
--header=enter=vim,\ tab=insert,\ ctrl-o=open,\ alt-c=cd-file-dir,\ alt-f=ranger
"
fi

export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
if type "lsd" > /dev/null 2>&1; then
    FZF_ALT_C_OPTS="
--no-multi
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {2} | head -200'
--expect=tab,ctrl-t,alt-c,alt-f
--header=enter=fzf-file,\ tab=cd,\ alt-c=fzf-dir,\ alt-f=ranger
"
fi

# Extend list of commands with fuzzy completion (basically add our aliases)
complete -F _fzf_path_completion -o default -o bashdefault v o dog

# }}}
# File and dirs {{{

# Custom Ctrl-t mapping (also Alt-t to ignore git-ignored files)
__fzf_select_custom() {
    local cmd dir
    cmd="$FZF_CTRL_T_COMMAND"
    if [[ "$1" == 'no-ignore' ]]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [[ "$2" ]]; then
        cmd="$cmd . $2"  # use narrow dir
    fi
    out=$(eval "$cmd" | devicon-lookup |
    FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf)
    key=$(head -1 <<< "$out")
    mapfile -t _files <<< "$(tail -n+2 <<< "$out")"

    if [ ${#_files[@]} -eq 1 ] && [[ -z "${_files[0]}" ]]; then
        return 1
    else
        files=();
        for f in "${_files[@]}"; do
            files+=("${f#* }")
        done
    fi

    case "$key" in
        tab)
            printf '%q ' "${files[@]}" ;;
        ctrl-o)
            printf 'open %q' "${files[0]}" ;;
        alt-c)
            printf 'cd %q' "$(dirname "${files[0]}")" ;;
        alt-f)
            printf 'ranger --selectfile %q' "${files[0]}" ;;
        *)
            printf 'v %q' "${files[@]}" ;;
    esac
}
fzf-file-widget-custom() {
    local selected=""
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

    if [[ -z $dir ]]; then
        return 1
    else
        dir="${dir#* }"
    fi

    case "$key" in
        tab)
            printf 'cd %q' "$dir" ;;
        alt-f)
            printf 'ranger %q' "$dir" ;;
        alt-c)
            __fzf_cd_custom__ "no-ignore" "$dir" ;;
        *)
            __fzf_select_custom "no-ignore" "$dir" ;;
    esac
}

# Custom Alt-c maps (also Alt-d to ignore git-ignored dirs)
__fzf_cd_custom__() {
    local cmd dir
    cmd="$FZF_ALT_C_COMMAND"
    if [[ "$1" == 'no-ignore' ]]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [[ "$2" ]]; then
        cmd="$cmd . $2"  # use narrow dir
    fi
    out=$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf)
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
    start_dir="$(dirname "$PWD")"
    cmd="get_parent_dirs $(realpath "${1:-$start_dir}")"
    out=$(eval "$cmd" | devicon-lookup |
    FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf)
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ep": "\C-x\C-addi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ep": "i\ep"'

# Z
z() {
    [ $# -gt 0 ] && _z "$*" && return
    cmd="_z -l 2>&1"
    out="$(eval "$cmd" | devicon-lookup | fzf --no-sort --tac \
        --preview 'lsd -F --tree --depth 2 --color=always --icon=always {3} | head -200' \
        --expect=tab,ctrl-t,alt-c,alt-f \
        --header=enter=fzf-file,\ tab=cd,\ alt-c=fzf-dir,\ alt-f=ranger |
        sed 's/^\W\s[0-9,.]* *//')"
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
    if [[ "$1" ]]; then
        if [[ "$1" == "-ask" ]]; then
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
