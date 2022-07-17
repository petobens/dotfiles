# Note: this also uses several rust binaries: fd, rg, bat, lsd and devicon-lookup

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
--prompt="   "
--marker="> "
--bind=ctrl-space:toggle+up,ctrl-d:half-page-down,ctrl-u:half-page-up
--bind=alt-v:toggle-preview,alt-j:preview-down,alt-k:preview-up
--bind=alt-d:preview-half-page-down,alt-u:preview-half-page-up
--color=bg+:#282c34,bg:#24272e,fg:#abb2bf,fg+:#abb2bf,hl:#528bff,hl+:#528bff
--color=prompt:#c678dd,header:#566370,info:#5c6370,pointer:#c678dd
--color=marker:#d19a66,spinner:#e06c75,border:#282c34
'

# Override FZF stock commands (ctrl-t,al-tc) and their options
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git \
    --color=always"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--multi
--ansi
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
export FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS_BASE
--bind 'ctrl-y:execute-silent(echo -n {2..} | $COPY_CMD)+abort'
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {2} | head -200'
"

# Completions
export FZF_COMPLETION_TRIGGER='jk'
complete -F _fzf_path_completion -o default -o bashdefault v o dog

# }}}
# Bindings/Functions {{{

# Helpers {{{

if [[ -o vi ]]; then
    # Bind unused key, "\C-x\C-a", to enter vi-movement-mode quickly and then
    # use that thereafter
    bind '"\C-x\C-a": vi-movement-mode'
    # Define other bindings to be used in mappings
    bind '"\C-x\C-e": shell-expand-line'
    bind '"\C-x\C-r": redraw-current-line'
    bind '"\C-x^": history-expand-line'
else
    # To refresh the prompt after fzf
    bind '"\er": redraw-current-line'
    bind '"\e^": history-expand-line'
fi

# }}}
# File and dirs {{{

# ls-like {{{

FZF_LL_OPTS="
--ansi
--bind 'ctrl-y:execute-silent(echo -n {-1} | $COPY_CMD)+abort'
--header='enter=open, C-y=yank'
"

ll() {
    cmd="lsd -F -lah --color=always"
    out="$(eval "$cmd" "$@" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_LL_OPTS" fzf)"
    key=$(head -1 <<< "$out")
    res=$(head -2 <<< "$out" | tail -1)

    if [[ -z "$res" ]]; then
        return 1
    else
        curr_dir="$(realpath "$PWD")"
        res=$(echo "$res" | rev | tr -s ' ' | cut -d ' ' -f 1 | rev)
        path="$curr_dir/$res"
        if [[ -d "$path" ]]; then
            cmd="cd"
        else
            cmd="${EDITOR:-nvim}"
        fi
    fi

    case "$key" in
        **)
            eval "$(printf "%s %s" "$cmd" "$path")"
            ;;
    esac
}

# }}}
# Files {{{

# Custom Ctrl-t mapping (also Alt-t to ignore git-ignored files)
__fzf_select_custom__() {
    local cmd dir
    cmd="$FZF_CTRL_T_COMMAND"
    if [[ "$1" == 'no-ignore' ]]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [[ "$2" ]]; then
        cmd="$cmd . $2" # use narrow dir
    fi
    out=$(eval "$cmd" | devicon-lookup --color |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf)
    key=$(head -1 <<< "$out")
    mapfile -t _files <<< "$(tail -n+2 <<< "$out")"

    if [ ${#_files[@]} -eq 1 ] && [[ -z "${_files[0]}" ]]; then
        return 1
    else
        files=()
        for f in "${_files[@]}"; do
            files+=("${f#* }")
        done
    fi
    printf -v files_str "%s " "${files[@]}"

    case "$key" in
        tab)
            printf '%q ' "${files[@]}"
            ;;
        ctrl-t)
            __fzf_select_custom__ "no-ignore" "$(dirname "${files[0]}")"
            ;;
        ctrl-o)
            printf 'open %q' "${files[0]}"
            ;;
        alt-c)
            printf 'cd %q' "$(dirname "${files[0]}")"
            ;;
        alt-p)
            __fzf_cd_parent__ "$(dirname "${files[0]}")"
            ;;
        alt-f)
            printf 'ranger --selectfile %q' "${files[0]}"
            ;;
        *)
            printf '%s %s' "${EDITOR:-nvim}" "$files_str"
            ;;
    esac
}
fzf-file-widget-custom() {
    local selected=""
    selected="$(__fzf_select_custom__ "$1" "$2")"
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + ${#selected}))
}
# Note this will insert output to the prompt and there is no way to choose to
# execute it instead: https://github.com/junegunn/fzf/issues/477
bind -m emacs-standard -x '"\C-t": "fzf-file-widget-custom"'
bind -m emacs-standard -x '"\et": "fzf-file-widget-custom no-ignore"'
bind -m vi-command -x '"\C-t": fzf-file-widget-custom'
bind -m vi-command -x '"\et": fzf-file-widget-custom no-ignore'
bind -m vi-insert -x '"\C-t": fzf-file-widget-custom'
bind -m vi-insert -x '"\et": fzf-file-widget-custom no-ignore'

# }}}
# Dirs {{{

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
            printf 'cd %q' "$dir"
            ;;
        alt-f)
            printf 'ranger %q' "$dir"
            ;;
        alt-c)
            __fzf_cd_custom__ "no-ignore" "$dir"
            ;;
        alt-p)
            __fzf_cd_parent__ "$dir"
            ;;
        *)
            __fzf_select_custom__ "no-ignore" "$dir"
            ;;
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
        cmd="$cmd . $2" # use narrow dir
    fi
    out=$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf)
    __fzf_cd_action_key__ "$out"
}

if [[ -o vi ]]; then
    # shellcheck disable=SC2016
    bind '"\ec": "\C-x\C-addi`__fzf_cd_custom__`\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"\ec": "i\ec"'
    # shellcheck disable=SC2016
    bind '"\ed": "\C-x\C-addi`__fzf_cd_custom__ no-ignore`\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"\ed": "i\ed"'
else
    # shellcheck disable=SC2016
    bind '"\ec": " \C-e\C-u`__fzf_cd_custom__`\e\C-e\er\C-m"'
    # shellcheck disable=SC2016
    bind '"\ed": " \C-e\C-u`__fzf_cd_custom__ no-ignore`\e\C-e\er\C-m"'
fi

# Alt-h map to cd from home dir
if [[ -o vi ]]; then
    # shellcheck disable=SC2016
    bind '"\eh": "\C-x\C-addi`__fzf_cd_custom__ no-ignore ~`\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"\eh": "i\eh"'
else
    # shellcheck disable=SC2016
    bind '"\eh": " \C-e\C-u`__fzf_cd_custom__ no-ignore ~`\e\C-e\er\C-m"'
fi

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
if [[ -o vi ]]; then
    # shellcheck disable=SC2016
    bind '"\ep": "\C-x\C-addi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'
    bind -m vi-command '"\ep": "i\ep"'
else
    # shellcheck disable=SC2016
    bind '"\ep": " \C-e\C-u`__fzf_cd_parent__`\e\C-e\er\C-m"'
fi

# }}}
# Z {{{

export FZF_ALT_Z_OPTS="$FZF_ALT_C_OPTS_BASE
--bind 'ctrl-y:execute-silent(echo -n {3..} | $COPY_CMD)+abort'
--no-sort
--tac
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {3} | head -200'
"
z() {
    [ $# -gt 0 ] && _z "$*" && return
    cmd="_z -l 2>&1"
    out="$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_Z_OPTS" fzf |
        sed 's/^\W\s[0-9,.]* *//')"
    __fzf_cd_action_key__ "$out"
}
if [[ -o vi ]]; then
    # shellcheck disable=SC2016
    bind '"\ez": "\C-x\C-addi`z`\C-x\C-e\C-x\C-r\C-m"'
    # shellcheck disable=SC2016
    bind -m vi-command '"\ez": "ddi`z`\C-x\C-e\C-x\C-r\C-m"'
else
    # shellcheck disable=SC2016
    bind '"\ez": " \C-e\C-u`z`\e\C-e\er\C-m"'
fi

# }}}

# }}}
# Grep {{{

FZF_GREP_OPTS="
--header 'enter=open, alt-q=quit-search'
--multi
--ansi
--disabled
--query=''
--delimiter=:
"

ig() {
    # shellcheck disable=SC2124
    grep_cmd="rg --smart-case --vimgrep --no-heading --color=always $@ {q}"
    grep_cmd+=" | devicon-lookup --color --prefix :"
    # shellcheck disable=SC2016,SC1004
    preview_cmd='bat --color always --style numbers --theme TwoDark \
--highlight-line {2} $(echo {1} | sed "s/[^ ] //")'
    # shellcheck disable=SC2154
    out=$(eval "true" | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_GREP_OPTS" \
        fzf --bind "change:reload:$grep_cmd || true" --preview "$preview_cmd" \
        --bind "alt-q:unbind(change,alt-q)+change-prompt(fzf> )+enable-search+clear-query" \
        --prompt 'rg> ' \
        --preview-window "+{2}-/2")
    key=$(head -1 <<< "$out")
    mapfile -t _files <<< "$(head -2 <<< "$out")"

    if [[ ${#_files[@]} -eq 1 ]] && [[ -z "${_files[0]}" ]]; then
        return 1
    else
        files=()
        for f in "${_files[@]}"; do
            # We need real path for vim to work (the first line removes devicon
            # icon from the filename)
            f="${f#* }"
            file="$(realpath "$(echo "$f" | cut -d ':' -f 1)")"
            line_nr=$(echo "$f" | cut -d ':' -f 2)
            files+=("+'e +$line_nr $file'")
        done
    fi
    printf -v files_str "%s " "${files[@]}"
    eval "$(printf "${EDITOR:-nvim} %s" "$files_str")"
}

# }}}
# History {{{

export FZF_CTRL_R_OPTS="
--bind 'ctrl-y:execute-silent(echo -n {2..} | $COPY_CMD)+abort,tab:accept'
--header 'enter=insert, tab=insert, C-y=yank'
--nth=2..,..
--tiebreak=index
--no-multi
--read0
"

__fzf_history__() {
    local output
    output=$(
        builtin fc -lnr -2147483648 |
            last_hist=$(HISTTIMEFORMAT='' builtin history 1) perl -n -l0 -e 'BEGIN { getc; $/ = "\n\t"; $HISTCMD = $ENV{last_hist} + 1 } s/^[ *]//; print $HISTCMD - $. . "\t$_" if !$seen{$_}++' |
            FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_R_OPTS" fzf --query "$READLINE_LINE"
    ) || return
    READLINE_LINE=${output#*$'\t'}
    if [ -z "$READLINE_POINT" ]; then
        echo "$READLINE_LINE"
    else
        READLINE_POINT=0x7fffffff
    fi
}

bind -m emacs-standard -x '"\C-r": __fzf_history__'
bind -m vi-command -x '"\C-r": __fzf_history__'
bind -m vi-insert -x '"\C-r": __fzf_history__'

# }}}
# Tmux {{{

FZF_TMUX_OPTIONS="
--multi
--exit-0
--expect=alt-k,alt-r,enter
--header='enter=switch, A-k=kill, A-r=rename'
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
        tmux $change -t "$session_name" 2> /dev/null ||
            (tmux -f "$HOME/.tmux/tmux.conf" new-session -d -s "$session_name" &&
                tmux $change -t "$session_name")
        return
    fi

    # If no arg is given use fzf to choose a session to switch or kill
    cmd='tmux list-sessions -F "#{session_name}"'
    out=$(eval "$cmd" | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_TMUX_OPTIONS" fzf)
    key=$(head -1 <<< "$out")
    mapfile -t sessions <<< "$(tail -n+2 <<< "$out")"

    case "$key" in
        alt-k)
            for s in "${sessions[@]}"; do
                tmux kill-session -t "$s"
            done
            ;;
        alt-r)
            for s in "${sessions[@]}"; do
                read -r -p "Rename tmux session '$s' to: " new_session_name
                tmux rename-session -t "$s" "$new_session_name"
            done
            ;;
        enter)
            tmux "$change" -t "${sessions[0]}"
            ;;
    esac
}

# }}}
# Bluetooth {{{

FZF_BT_OPTS="
--multi
--tac
--bind 'ctrl-y:execute-silent(echo -n {2} | $COPY_CMD)+abort,tab:accept'
--expect=alt-t,alt-u,alt-p,alt-d,alt-r
--header='enter=connect, A-t=trust, A-u=untrust, A-p=pair,
A-d=disconnect, A-r=remove/unpair, C-y=yank'
--with-nth=3..
--preview 'bluetoothctl info {2} | bat --color always --theme TwoDark \
--style plain -H 6 -H 7 -H 9'
"

bt() {
    cmd="bluetoothctl devices"
    out=$(eval "$cmd" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_BT_OPTS" fzf |
        cut -d ' ' -f 2)
    key=$(head -1 <<< "$out")
    mapfile -t devices <<< "$(tail -n+2 <<< "$out")"

    if [[ ${#devices[@]} -eq 1 ]] && [[ -z "${devices[0]}" ]]; then
        return 1
    fi
    case "$key" in
        alt-p)
            sub_cmd="pair"
            ;;
        alt-t)
            sub_cmd="trust"
            ;;
        alt-u)
            sub_cmd="untrust"
            ;;
        alt-d)
            sub_cmd="disconnect"
            ;;
        alt-r)
            sub_cmd="remove"
            ;;
        *)
            sub_cmd="connect"
            ;;
    esac
    for d in "${devices[@]}"; do
        bluetoothctl "$sub_cmd" "$d"
    done
}

# }}}
# Git {{{

# Forgit (git and fzf)
export FORGIT_COPY_CMD="$COPY_CMD "
export FORGIT_NO_ALIASES="1"
export FORGIT_FZF_DEFAULT_OPTS="--preview-window='right'"
# shellcheck disable=SC2016
export FORGIT_LOG_FZF_OPTS='
--header="enter=view, C-o=nvim, C-y=yank"
--bind="ctrl-y:execute-silent(echo {} |grep -Eo [a-f0-9]+ | head -1 | tr -d ''\n'' | $FORGIT_COPY_CMD)"
--bind="ctrl-o:execute(echo {} | grep -Eo [a-f0-9]+ | head -1 | xargs git show | nvim -)"
'

alias gl=forgit::log
alias glg='FORGIT_LOG_GRAPH_ENABLE=false gl -G'
alias gd=forgit::diff
alias ga=forgit::add
alias gu=forgit::restore
alias gsv=forgit::stash::show

# Load
if [ -f "/usr/share/zsh/plugins/forgit-git/forgit.plugin.zsh" ]; then
    . "/usr/share/zsh/plugins/forgit-git/forgit.plugin.zsh"
fi

# }}}
# Docker {{{

FZF_DOCKER_OPTS_BASE="
--multi
--exit-0
--bind 'ctrl-y:execute-silent(echo -n {1} | $COPY_CMD)+abort'
"

FZF_DOCKER_IMAGE_OPTS="$FZF_DOCKER_OPTS_BASE
--expect=ctrl-i,alt-d
--header='enter=run, C-i=interactive, A-d=rm, C-y=yank'
"
di() {
    cmd="docker image ls | tail -n +2"
    out=$(eval "$cmd" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_DOCKER_IMAGE_OPTS" fzf)
    key=$(head -1 <<< "$out")
    out="$(echo "$out" | awk '{print $3}')"
    mapfile -t images <<< "$(tail -n+2 <<< "$out")"

    if [[ ${#images[@]} -eq 1 ]] && [[ -z "${images[0]}" ]]; then
        return 1
    fi

    case "$key" in
        ctrl-i)
            image_cmd="docker run --rm -ti --entrypoint /bin/bash"
            ;;
        alt-d)
            image_cmd="docker image rm --force"
            ;;
        **)
            image_cmd="docker run -td"
            ;;
    esac

    for image in "${images[@]}"; do
        eval "$image_cmd $image"
    done
}

FZF_DOCKER_CONTAINER_OPTS="$FZF_DOCKER_OPTS_BASE
--expect=ctrl-a,ctrl-e,ctrl-s,ctrl-r,ctrl-b,alt-k,alt-d
--header='enter=logs, C-e=exec, C-a=attach, C-b=start, C-s=stop, C-r=restart, \
A-k=kill, A-d=rm'
"
dc() {
    cmd="docker container ls -a | tail -n +2"
    out=$(eval "$cmd" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_DOCKER_CONTAINER_OPTS" fzf |
        cut -d ' ' -f 1)
    key=$(head -1 <<< "$out")
    mapfile -t containers <<< "$(tail -n+2 <<< "$out")"
    if [[ ${#containers[@]} -eq 1 ]] && [[ -z "${containers[0]}" ]]; then
        return 1
    fi

    post_cmd=''
    case "$key" in
        ctrl-a)
            sub_cmd="attach"
            ;;
        ctrl-e)
            sub_cmd="exec -ti"
            post_cmd="/bin/bash"
            ;;
        ctrl-s)
            sub_cmd="stop"
            ;;
        ctrl-b)
            sub_cmd="start"
            ;;
        ctrl-r)
            sub_cmd="restart"
            ;;
        alt-k)
            sub_cmd="kill"
            ;;
        alt-d)
            sub_cmd="rm"
            ;;
        **)
            sub_cmd="logs"
            ;;
    esac
    for container in "${containers[@]}"; do
        eval "docker container $sub_cmd $container $post_cmd"
    done
}

# }}}
# Man (Search) {{{

FZF_MAN_OPTS='
--header "enter=open"
--preview="man -Pcat {1} 2>/dev/null | bat -l man --color always --style numbers"
'
m() {
    query_str="$1"
    [ -n "$query_str" ] && man "$query_str" && return 0 ||
        manual=$(
            apropos . | grep -v -E '^.+ \(0\)' | awk '{print $1 " "$2}' |
                FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_MAN_OPTS" fzf --query "$query_str" | awk '{print $1}'
        )
    [ -z "$manual" ] && return 1
    man "$manual"
}

# }}}

# }}}
