# Note: this uses several rust binaries: fd, rg, bat, lsd and devicon-lookup
# It also assumes (for bindings) that bash is used in vi-mode

# Setup {{{

# Set base dir and copy command
base_pkg_dir='/usr'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi
    COPY_CMD='pbcopy'
else
    COPY_CMD='xsel --clipboard'
fi

# Enable completions
if [[ $- == *i* ]]; then
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        completion_base_dir="$base_pkg_dir/opt/fzf/shell"
    else
        completion_base_dir="$base_pkg_dir/share/fzf"
    fi
    . "$completion_base_dir/completion.bash" 2> /dev/null
fi

# }}}
# Options {{{

# Change default options and colors
export FZF_DEFAULT_OPTS='
--height 15
--inline-info
--prompt="❯ "
--bind=ctrl-space:toggle+up,ctrl-d:half-page-down,ctrl-u:half-page-up
--bind=alt-v:toggle-preview,alt-j:preview-down,alt-k:preview-up
--color=bg+:#282c34,bg:#24272e,fg:#abb2bf,fg+:#abb2bf,hl:#528bff,hl+:#528bff
--color=prompt:#61afef,header:#566370,info:#5c6370,pointer:#c678dd
--color=marker:#98c379,spinner:#e06c75,border:#282c34
'

# fd for files and dirs
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--multi
--bind 'ctrl-y:execute-silent(echo -n {+2} | $COPY_CMD)+abort'
--preview 'bat --color always --style numbers --theme TwoDark \
    --line-range :200 {2}'
--expect=tab,ctrl-t,ctrl-o,alt-c,alt-p,alt-f
--header='enter=edit, tab=insert, C-t=fzf-files, C-o=open, A-c=cd-file-dir, \
A-p=parent-dirs, A-f=ranger, C-y=yank'
"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
FZF_ALT_C_OPTS_BASE="
--no-multi
--expect=ctrl-o,ctrl-t,alt-c,alt-p,alt-f
--header='enter=fzf-files, C-o=cd, A-c=fzf-dirs, A-p=parent-dirs, \
A-f=ranger, C-y=yank'
"
export FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS_BASE\
--bind 'ctrl-y:execute-silent(echo -n {2..} | $COPY_CMD)+abort'
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {2} | head -200'
"
export FZF_ALT_Z_OPTS="$FZF_ALT_C_OPTS_BASE\
--bind 'ctrl-y:execute-silent(echo -n {3..} | $COPY_CMD)+abort'
--no-sort
--tac
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {3} | head -200'
"

# History options
export FZF_CTRL_R_OPTS="
--bind 'ctrl-y:execute-silent(echo -n {2..} | $COPY_CMD)+abort,tab:accept'
--header 'enter=insert, tab=insert, C-y=yank'
--tac
--sync
--nth=2..,..
--tiebreak=index
"

# rg for grep
FZF_GREP_COMMAND='rg --smart-case --vimgrep --no-heading --color=always'
FZF_GREP_OPTS="
--multi
--ansi
--delimiter=:
--preview 'bat --color always --style numbers --theme TwoDark \
    --line-range {2}: --highlight-line {2} {1} | head -200'
"

# Bluetooth
FZF_BT_OPTS="
--expect=alt-p,alt-d
--header='enter=connect, A-p=pair, A-d=disconnect'
--with-nth=3..
--preview 'bluetoothctl info {2} | bat --theme TwoDark --style plain \
    --line-range 2: --highlight-line 6 --highlight-line 8'
"

# Completions
export FZF_COMPLETION_TRIGGER='jk'
complete -F _fzf_path_completion -o default -o bashdefault v o dog

# }}}
# Bindings/Functions {{{

# Helpers {{{

# Bind unused key, "\C-x\C-a", to enter vi-movement-mode quickly and then use
# that thereafter.
bind '"\C-x\C-a": vi-movement-mode'

bind '"\C-x\C-e": shell-expand-line'
bind '"\C-x\C-r": redraw-current-line'
bind '"\C-x^": history-expand-line'

# }}}
# File and dirs {{{

# Custom Ctrl-t mapping (also Alt-t to ignore git-ignored files)
__fzf_select_custom__() {
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
    printf -v files_str "%s " "${files[@]}"

    case "$key" in
        tab)
            printf '%q ' "${files[@]}" ;;
        ctrl-t)
            __fzf_select_custom__ "no-ignore" "$(dirname "${files[0]}")" ;;
        ctrl-o)
            printf 'open %q' "${files[0]}" ;;
        alt-c)
            printf 'cd %q' "$(dirname "${files[0]}")" ;;
        alt-p)
            __fzf_cd_parent__ "$(dirname "${files[0]}")" ;;
        alt-f)
            printf 'ranger --selectfile %q' "${files[0]}" ;;
        *)
            printf '%s %s' "${EDITOR:-nvim}" "$files_str" ;;
    esac
}
fzf-file-widget-custom() {
    local selected=""
    selected="$(__fzf_select_custom__ "$1" "$2")"
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
# Note this will insert output to the prompt and there is no way to choose to
# execute it instead: https://github.com/junegunn/fzf/issues/477
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

    if [[ -z "$dir" ]]; then
        return 1
    else
        dir="${dir#* }"
    fi

    case "$key" in
        ctrl-o)
            printf 'cd %q' "$dir" ;;
        alt-f)
            printf 'ranger %q' "$dir" ;;
        alt-c)
            __fzf_cd_custom__ "no-ignore" "$dir" ;;
        alt-p)
            __fzf_cd_parent__ "$dir" ;;
        *)
            __fzf_select_custom__ "no-ignore" "$dir" ;;
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
        if [[ -d "${1}" ]]; then
            dirs+=("$1")
        else
            return
        fi
        if [[ "${1}" == '/' ]]; then
            for _dir in "${dirs[@]}"; do
                echo "$_dir"
            done
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
    out="$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_Z_OPTS" fzf |
        sed 's/^\W\s[0-9,.]* *//')"
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ez": "\C-x\C-addi`z`\C-x\C-e\C-x\C-r\C-m"'
# shellcheck disable=SC2016
bind -m vi-command '"\ez": "ddi`z`\C-x\C-e\C-x\C-r\C-m"'

# }}}
# Grep {{{

rgz() {
    cmd="$FZF_GREP_COMMAND"
    out="$(eval "$cmd" "$@" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_GREP_OPTS" fzf)"
    key=$(head -1 <<< "$out")
    mapfile -t _files <<< "$(head -2 <<< "$out")"

    if [ ${#_files[@]} -eq 1 ] && [[ -z "${_files[0]}" ]]; then
        return 1
    else
        files=();
        for f in "${_files[@]}"; do
            # We need real path for vim to work
            file="$(realpath "$(echo "$f" | cut -d ':' -f 1)")"
            line_nr=$(echo "$f" | cut -d ':' -f 2)
            files+=("+'e +$line_nr $file'")
        done
    fi
    printf -v files_str "%s " "${files[@]}"
    eval "$(printf "nvim %s" "$files_str")"
}

# }}}
# History {{{

__fzf_history__() (
    local line
    shopt -u nocaseglob nocasematch
    cmd="HISTTIMEFORMAT= history"
    line=$(eval "$cmd" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_R_OPTS" fzf |
        command grep '^ *[0-9]'
    )
    sed 's/^ *\([0-9]*\)\** .*/!\1/' <<< "$line"
)
# shellcheck disable=SC2016
bind '"\C-r": "\C-x\C-addi`__fzf_history__`\C-x\C-e\C-x\C-r\C-x^\C-x\C-a$a"'
bind -m vi-command '"\C-r": "i\C-r"'

# }}}
# Tmux {{{

FZF_TMUX_OPTS="
--multi
--exit-0
--expect=alt-k
--header='enter=switch, A-k=kill'
--preview='tmux_tree {} | bat --theme TwoDark --style plain'
"

tms() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"

    if [[ -n "$1" ]]; then
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

    # If no arg is given use fzf to choose a session to switch or kill
    cmd='tmux list-sessions -F "#{session_name}"'
    out=$(eval "$cmd" | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_TMUX_OPTS" fzf)
    key=$(head -1 <<< "$out")
    mapfile -t sessions <<< "$(tail -n+2 <<< "$out")"

    case "$key" in
        alt-k)
            for s in "${sessions[@]}"; do
                tmux kill-session -t "$s"
            done
            ;;
        *)
            tmux "$change" -t "${sessions[0]}" ;;
    esac
}

# }}}
# Git {{{

# Forgit (git and fzf)
export FORGIT_COPY_CMD="$COPY_CMD "
export FORGIT_FZF_DEFAULT_OPTS="--preview-window='right'"
export FORGIT_NO_ALIASES="1"
alias gl=forgit::log
alias gd=forgit::diff
alias ga=forgit::add
alias gu=forgit::restore
alias gsv=forgit::stash::show
if [ -f "$HOME/.local/bin/forgit.plugin.zsh" ]; then
    . "$HOME/.local/bin/forgit.plugin.zsh"
fi

# }}}
# Bluetooth {{{

bt() {
    cmd="bluetoothctl devices"
    out=$(eval "$cmd" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_BT_OPTS" fzf |
        cut -d ' ' -f 2)
    key=$(head -1 <<< "$out")
    device=$(head -2 <<< "$out" | tail -1)

    if [[ -z "$device" ]]; then
        return 1
    fi
    case "$key" in
        alt-p)
            sub_cmd="pair" ;;
        alt-d)
            sub_cmd="disconnect" ;;
        *)
            sub_cmd="connect" ;;
    esac
    bluetoothctl "$sub_cmd" "$device"
}

# }}}

# }}}
