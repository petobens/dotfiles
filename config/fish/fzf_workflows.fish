function __fzf_path
    string replace -r '^[^[:space:]]+[[:space:]]+' '' -- "$argv[1]"
end

function __fzf_icons
    eza --stdin --oneline --list-dirs --icons=always --color=never --no-quotes
end

function __fzf_dir_icons
    while read -l dir
        printf ' %s\n' "$dir"
    end
end

function __fzf_fd
    set -l fd_args --type "$argv[1]" --hidden --follow --exclude .git --color never
    if test "$argv[2]" = no-ignore
        set -a fd_args --no-ignore-vcs
    end
    if test -n "$argv[3]"
        set -a fd_args . "$argv[3]"
    else
        set -a fd_args --strip-cwd-prefix
    end
    fd $fd_args
end

function __fzf_files
    set -l out (__fzf_fd f "$argv[1]" "$argv[2]" | __fzf_icons | fzf \
        --multi --scheme=path --border-label='Find Files' \
        --with-shell='sh -c' \
        --expect=enter,tab,ctrl-t,ctrl-o,alt-c,alt-p,alt-f,alt-g \
        --bind='ctrl-y:execute-silent(printf "%s\n" {+2..} | head -c -1 | wl-copy)+abort' \
        --header='enter=edit, tab=insert, C-t=find here, C-o=open, A-c=cd, A-p=parents, A-f=yazi, A-g=grep, C-y=yank' \
        --preview='if file --mime-type {2..} | grep -qF image/; then /usr/share/fzf/fzf-preview.sh {2..}; else bat --line-range :200 {2..}; fi')
    or return
    test (count $out) -gt 1; or return 1

    set -l key $out[1]
    set -l files
    for line in $out[2..]
        set -a files (__fzf_path "$line")
    end

    switch "$key"
        case tab
            commandline -i (string join ' ' (string escape -- $files))
        case ctrl-t
            __fzf_files no-ignore (path dirname "$files[1]")
        case ctrl-o
            xdg-open "$files[1]" >/dev/null 2>&1 &
        case alt-c
            builtin cd (path dirname "$files[1]")
        case alt-p
            __fzf_parents (path dirname "$files[1]")
        case alt-f
            yazi "$files[1]"
        case alt-g
            ig (path dirname "$files[1]")
        case '*'
            "$EDITOR" $files
    end
end

function __fzf_dirs
    set -l out (__fzf_fd d "$argv[1]" "$argv[2]" | __fzf_icons | fzf \
        --scheme=path --border-label='Find Dirs' \
        --expect=enter,ctrl-o,alt-c,alt-p,alt-f,alt-g \
        --bind='ctrl-y:execute-silent(printf %s {2..} | wl-copy)+abort' \
        --header='enter=find files, C-o=cd, A-c=find dirs, A-p=parents, A-f=yazi, A-g=grep, C-y=yank' \
        --preview='eza -F --tree --level=2 --color=always --icons=always {2..} | head -200')
    or return
    test (count $out) -gt 1; or return 1
    __fzf_dir_action $out
end

function __fzf_dir_action
    set -l key $argv[1]
    set -l dir (__fzf_path "$argv[2]")
    switch "$key"
        case ctrl-o
            builtin cd "$dir"
        case alt-f
            yazi "$dir"
        case alt-c
            __fzf_dirs no-ignore "$dir"
        case alt-p
            __fzf_parents "$dir"
        case alt-g
            ig "$dir"
        case '*'
            __fzf_files no-ignore "$dir"
    end
end

function __fzf_parents
    set -l dir (path dirname "$PWD")
    if test -n "$argv[1]"
        set dir (path resolve "$argv[1]")
    end
    set -l dirs
    while true
        set -a dirs "$dir"
        test "$dir" = /; and break
        set dir (path dirname "$dir")
    end

    set -l out (printf '%s\n' $dirs | __fzf_dir_icons | fzf \
        --scheme=path --border-label='Parent Dirs' \
        --expect=enter,ctrl-o,alt-c,alt-p,alt-f,alt-g \
        --bind='ctrl-y:execute-silent(printf %s {2..} | wl-copy)+abort' \
        --header='enter=find files, C-o=cd, A-c=find dirs, A-p=parents, A-f=yazi, A-g=grep, C-y=yank' \
        --preview='eza -F --tree --level=2 --color=always --icons=always {2..} | head -200')
    or return
    test (count $out) -gt 1; or return 1
    __fzf_dir_action $out
end

function zoi --description 'Select a directory from zoxide history'
    set -l out (zoxide query --list --score | while read -l score dir
        printf '%6s  %s\n' "$score" "$dir"
    end | fzf \
        --no-sort --border-label='Zoxide Dirs' \
        --expect=enter,ctrl-o,alt-c,alt-p,alt-f,alt-g \
        --bind='ctrl-y:execute-silent(printf %s {3..} | wl-copy)+abort' \
        --preview='eza -F --tree --level=2 --color=always --icons=always {3..} | head -200')
    or return
    test (count $out) -gt 1; or return 1
    set out[2] (string replace -r '^[[:space:]]*[0-9.,]+[[:space:]]+[^[:space:]]+[[:space:]]+' '' -- "$out[2]")
    set out[2] "x $out[2]"
    __fzf_dir_action $out
end

function ig --description 'Search files with ripgrep and FZF'
    set -l paths $argv
    test (count $paths) -gt 0; or set paths .
    set -l escaped_paths (string join ' ' (string escape -- $paths))
    set -l reload "rg --smart-case --vimgrep --no-heading --color=always --colors=path:none --colors=line:none --colors=column:none --trim {q} $escaped_paths | sed 's/^/󰈔 /'"
    set -l out (fzf --ansi --disabled --multi --delimiter=: \
        --border-label='Live Grep' --header='enter=open, A-r=refine search' \
        --bind="start:reload:$reload || true" \
        --bind="change:reload:sleep 0.1; $reload || true" \
        --bind='alt-r:unbind(change,alt-r)+change-border-label(Find Word)+enable-search+clear-query' \
        --preview='bat --highlight-line {2} $(printf %s {1} | sed "s/^[^ ]* //")' \
        --preview-window='+{2}-/2')
    or return
    test (count $out) -gt 0; or return 1

    set -l edit_commands
    for result in $out
        set result (string replace -ra '\x1b\[[0-9;]*m' '' -- "$result")
        set result (__fzf_path "$result")
        set -l fields (string split -m 2 : "$result")
        set -l file (path resolve "$fields[1]")
        set -a edit_commands (
            string join '' '+edit +' "$fields[2]" ' ' (string escape -n -- "$file")
        )
    end
    "$EDITOR" $edit_commands
end

function ll --description 'Browse the current directory with FZF'
    set -l root .
    test (count $argv) -gt 0; and set root "$argv[1]"
    set -l out (fd --hidden --no-ignore --min-depth 1 --max-depth 1 --color never . "$root" |
        __fzf_icons | fzf --scheme=path --border-label=Files \
        --with-shell='sh -c' \
        --bind='ctrl-y:execute-silent(printf %s {2..} | wl-copy)+abort' \
        --header='enter=open, C-y=yank' \
        --preview='if [ -d {2..} ]; then eza -F --tree --level=2 --color=always --icons=always {2..}; else bat --line-range :200 {2..}; fi')
    or return
    set -l selected (__fzf_path "$out")
    if test -d "$selected"
        builtin cd "$selected"
    else
        "$EDITOR" "$selected"
    end
end

function tms --description 'Create or select a tmux session'
    set -l action attach-session
    test -n "$TMUX"; and set action switch-client

    if test (count $argv) -gt 0
        set -l session "$argv[1]"
        if test "$session" = -ask
            read -P 'New tmux session name: ' session
        end
        test -n "$session"; or return 1
        tmux "$action" -t "$session" 2>/dev/null
        or begin
            tmux -f "$HOME/.config/tmux/tmux.conf" new-session -d -s "$session"
            and tmux "$action" -t "$session"
        end
        return
    end

    set -l out (tmux list-sessions -F '#{session_name}' 2>/dev/null | fzf \
        --multi --exit-0 --border-label='Tmux Sessions' \
        --expect=enter,alt-k,alt-r \
        --header='enter=switch, A-k=kill, A-r=rename' \
        --preview="tmux_tree '{}' | bat --style plain")
    or return
    test (count $out) -gt 1; or return 1

    switch "$out[1]"
        case alt-k
            for session in $out[2..]
                tmux kill-session -t "$session"
            end
        case alt-r
            for session in $out[2..]
                read -P "Rename tmux session '$session' to: " new_session
                test -n "$new_session"; and tmux rename-session -t "$session" "$new_session"
            end
        case '*'
            tmux "$action" -t "$out[2]"
    end
end

function bt --description 'Manage Bluetooth devices with FZF'
    set -l out (bluetoothctl devices 2>/dev/null | fzf \
        --multi --tac --with-nth=3.. --border-label='Bluetooth Control' \
        --expect=enter,alt-t,alt-u,alt-p,alt-d,alt-r \
        --bind='ctrl-y:execute-silent(printf %s {2} | wl-copy)+abort' \
        --header='enter=connect, A-t=trust, A-u=untrust, A-p=pair, A-d=disconnect, A-r=remove, C-y=yank' \
        --preview='bluetoothctl info {2} 2>/dev/null | bat --style plain -H 6 -H 7 -H 9')
    or return
    test (count $out) -gt 1; or return 1

    set -l action connect
    switch "$out[1]"
        case alt-p
            set action pair
        case alt-t
            set action trust
        case alt-u
            set action untrust
        case alt-d
            set action disconnect
        case alt-r
            set action remove
    end
    for device in $out[2..]
        if test "$action" = pair
            bluetoothctl --agent KeyboardDisplay pair (string split ' ' "$device")[2]
        else
            bluetoothctl "$action" (string split ' ' "$device")[2]
        end
    end
end

function di --description 'Manage Docker images with FZF'
    set -l out (docker image ls | tail -n +2 | fzf \
        --multi --exit-0 --border-label='Docker Images' \
        --expect=enter,ctrl-i,alt-d \
        --bind='ctrl-y:execute-silent(printf %s {3} | wl-copy)+abort' \
        --header='enter=run, C-i=interactive, A-d=remove, C-y=yank')
    or return
    test (count $out) -gt 1; or return 1

    for image in $out[2..]
        set image (string split -n ' ' "$image")[3]
        switch "$out[1]"
            case ctrl-i
                docker run --rm -ti --entrypoint /bin/bash "$image"
            case alt-d
                docker image rm --force "$image"
            case '*'
                docker run -td "$image"
        end
    end
end

function dc --description 'Manage Docker containers with FZF'
    set -l out (docker container ls -a | tail -n +2 | fzf \
        --multi --exit-0 --border-label='Docker Containers' \
        --expect=enter,ctrl-a,ctrl-e,ctrl-s,ctrl-r,ctrl-b,alt-k,alt-d \
        --bind='ctrl-y:execute-silent(printf %s {1} | wl-copy)+abort' \
        --header='enter=logs, C-e=exec, C-a=attach, C-b=start, C-s=stop, C-r=restart, A-k=kill, A-d=remove')
    or return
    test (count $out) -gt 1; or return 1

    for container in $out[2..]
        set container (string split -n ' ' "$container")[1]
        switch "$out[1]"
            case ctrl-a
                docker container attach "$container"
            case ctrl-e
                docker container exec -ti "$container" /bin/bash
            case ctrl-s
                docker container stop "$container"
            case ctrl-r
                docker container restart "$container"
            case ctrl-b
                docker container start "$container"
            case alt-k
                docker container kill "$container"
            case alt-d
                docker container rm "$container"
            case '*'
                docker container logs "$container"
        end
    end
end

function m --description 'Search and open man pages with FZF'
    if test -n "$argv[1]"; and man "$argv[1]"
        return
    end
    set -l manual (apropos . | string match -rv '^.+ \(0\)' | awk '{print $1 " " $2}' |
        fzf --border-label=Man --header='enter=open' --query="$argv[1]" \
        --preview='man -Pcat {1} 2>/dev/null | bat -l man --color always --style numbers')
    or return
    man (string split ' ' "$manual")[1]
end

complete -c m -w man

# Files
bind -M insert \ct '__fzf_files; commandline -f repaint'
bind -M default \ct '__fzf_files; commandline -f repaint'
bind -M insert \et '__fzf_files no-ignore; commandline -f repaint'
bind -M default \et '__fzf_files no-ignore; commandline -f repaint'

# Directories
bind -M insert \ec '__fzf_dirs; commandline -f repaint'
bind -M default \ec '__fzf_dirs; commandline -f repaint'
bind -M insert \ed '__fzf_dirs no-ignore; commandline -f repaint'
bind -M default \ed '__fzf_dirs no-ignore; commandline -f repaint'
bind -M insert \eh '__fzf_dirs no-ignore "$HOME"; commandline -f repaint'
bind -M default \eh '__fzf_dirs no-ignore "$HOME"; commandline -f repaint'
bind -M insert \ep '__fzf_parents; commandline -f repaint'
bind -M default \ep '__fzf_parents; commandline -f repaint'
bind -M insert \ez 'zoi; commandline -f repaint'
bind -M default \ez 'zoi; commandline -f repaint'

# Search
bind -M insert \eg 'ig; commandline -f repaint'
bind -M default \eg 'ig; commandline -f repaint'
