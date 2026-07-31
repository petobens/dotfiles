# Environment
set -gx BROWSER xdg-open
# Exported so tools such as git-delta know the terminal width
set -gx COLUMNS $COLUMNS
set -gx EDITOR nvim
set -gx MANPAGER 'nvim +Man!'
set -gx PAGER less
set -gx RIPGREP_CONFIG_PATH "$HOME/.config/ripgrep/ripgreprc"
set -gx SHELLCHECK_OPTS '-e SC1090'
set -gx TERMINAL ghostty
set -gx VISUAL nvim

# Shell behavior
function fish_should_add_to_history --description 'Filter low-value shell history entries'
    string match -qr '^\s' -- "$argv[1]"; and return 1
    set -l commandline (string trim -- "$argv[1]")
    test (string length -- "$commandline") -le 2; and return 1
    string match -qr '^(cd|fm|nvim|v|yazi)(\s|$)' -- "$commandline"; and return 1
    return 0
end

set -g fish_greeting
set -g fish_history main
if status is-interactive
    stty -ixon
end

# Key bindings
function __set_vi_key_bindings
    set -g fish_key_bindings fish_vi_key_bindings
    bind -M default \ce edit_command_buffer
    bind -M default H beginning-of-line
    bind -M default j true
    bind -M default k true
    bind -M default L end-of-line
    bind -M default v true
end

function __toggle_key_bindings
    if test "$fish_key_bindings" = fish_vi_key_bindings
        set -g fish_key_bindings fish_default_key_bindings
        bind --erase -M default \ce H j k L v
        bind -M default \cw __toggle_key_bindings
    else
        __set_vi_key_bindings
    end
end

__set_vi_key_bindings
bind -M default \cw __toggle_key_bindings
bind -M insert \ca beginning-of-line
bind -M insert \ce end-of-line
bind -M insert \cn history-search-forward
bind -M insert \cp history-search-backward
bind -M insert \cw __toggle_key_bindings
bind -M insert \cx backward-kill-line
bind -M insert \ex backward-kill-word
bind -M insert -m default jj repaint-mode

# Interactive tools
if type -q fzf
    set -l FZF_ALT_C_COMMAND
    set -l FZF_CTRL_T_COMMAND
    fzf --fish | source
    source "$__fish_config_dir/fzf_workflows.fish"
end
if type -q starship
    starship init fish | source
end
if type -q zoxide
    zoxide init fish | source
end

# Completions
complete -c pass -w gopass

# Aliases
alias 2u 'cd ../..'
alias 3u 'cd ../../..'
alias 4u 'cd ../../../..'
alias c clear
alias cp 'cp -i'
alias df 'df -h'
alias diff 'diff -u --color'
alias dog bat
alias ff fastfetch
alias fm yazi
alias h 'cd ~'
alias ht htop
if type -q unimatrix
    alias iamneo 'unimatrix -s 90'
end
if type -q eza
    alias ls 'eza -F --color=auto --icons=auto'
end
alias md 'mkdir -p'
alias mv 'mv -i'
alias o open
alias open xdg-open
alias ping 'prettyping --nolegend --last 30'
alias py python
alias q exit
alias rm 'rm -v'
alias rsync 'rsync -auP'
alias ss 'sudo -i'
alias ti hyperfine
alias u 'cd ..'
alias v nvim
alias yay 'yay --diffmenu=false --answerclean N --removemake'

# Git abbreviations
abbr -a ga 'git-forgit add'
abbr -a gap 'git apply'
abbr -a gb 'git branch'
abbr -a gbd 'git branch -D'
abbr -a gbdr 'git push origin --delete'
abbr -a gcb 'git-forgit checkout_branch'
abbr -a gcl 'git clone'
abbr -a gco 'git switch'
abbr -a gcob 'git switch -c'
abbr -a gcp 'git cherry-pick'
abbr -a gd 'git-forgit diff'
abbr -a gdb 'git-forgit branch_delete'
abbr -a gF 'git push --force-with-lease'
abbr -a gf 'git fetch'
abbr -a gl 'git-forgit log'
abbr -a glg 'env FORGIT_LOG_GRAPH_ENABLE=false git-forgit log'
abbr -a gp 'git push'
abbr -a gP 'git pull'
abbr -a gPr 'git pull --rebase'
abbr -a gr 'git rebase'
abbr -a gra 'git remote add'
abbr -a grc 'git rebase --continue'
abbr -a grl 'git reset --soft HEAD^'
abbr -a gs 'git status'
abbr -a gsp 'git stash pop'
abbr -a gst 'git stash'
abbr -a gsv 'git-forgit stash_show'

# GitHub abbreviations
abbr -a ghcp 'gh pr checkout'
abbr -a ghi 'gh issue'
abbr -a ghp 'gh pr'
abbr -a ghr 'gh repo'

# AI abbreviations
abbr -a aisp ai_session_prune
abbr -a aisu ai_session_usage

# Python abbreviations
abbr -a nbd 'nbdiff-web HEAD'
abbr -a uva 'uv add'
abbr -a uvad 'uv add --dev'
abbr -a uvd 'uv run python -m pdb -cc'
abbr -a uvh 'uv run pre-commit run --all-files'
abbr -a uvi 'uv sync --locked'
abbr -a uvj 'uv run jupyter lab'
abbr -a uvl 'uv pip list'
abbr -a uvp 'uv run python'
abbr -a uvr 'uv run'
abbr -a uvrm 'uv remove'
abbr -a uvrmd 'uv remove --dev'
abbr -a uvs 'uv sync'
abbr -a uvt 'uv run pytest -n auto --cov'

# Network storage abbreviations
abbr -a mfnfs 'sudo mount synology-flor:/volume1/Shared-DS220 /mnt/nfs'
abbr -a mpnfs 'sudo mount synology-ds:/volume1/Shared-DS220 /mnt/nfs'
abbr -a unfs 'sudo umount /mnt/nfs'

# System abbreviations
abbr -a ua sys_update_all

# Terminal and file helpers
function cd --description 'Change directory and list its contents'
    builtin cd $argv; or return
    ls
end

function ds --description 'Browse disk usage with FZF'
    set -l targets $argv
    if not set -q targets[1]
        set targets *
    end
    du -shc $targets | sort -rh | fzf
end

function tm --description 'Attach to the main tmux session'
    set -l session (test "$USER" = pedro; and echo petobens; or echo "$USER")
    command tmux -f "$HOME/.config/tmux/tmux.conf" new -A -s "$session" $argv
end

function up --description 'Extract an archive'
    test -f "$argv[1]"; or begin
        echo "Not a file: $argv[1]" >&2
        return 1
    end
    switch "$argv[1]"
        case '*.tar.bz2' '*.tbz2'
            tar xjf "$argv[1]"
        case '*.tar.gz' '*.tgz'
            tar xzf "$argv[1]"
        case '*.tar' '*.tar.xz' '*.tar.zst'
            tar xf "$argv[1]"
        case '*.bz2'
            bunzip2 "$argv[1]"
        case '*.gz'
            gunzip "$argv[1]"
        case '*.rar'
            unrar x "$argv[1]"
        case '*.zip'
            unzip "$argv[1]"
        case '*.7z' '*.7Z'
            7z x "$argv[1]"
        case '*'
            echo "Unsupported archive: $argv[1]" >&2
            return 1
    end
end

function yazi --description 'Run Yazi and change to its final directory'
    set -l config_home "$HOME/.config"
    set -q XDG_CONFIG_HOME; and set config_home "$XDG_CONFIG_HOME"
    for plugin in full-border git toggle-pane
        if not test -d "$config_home/yazi/plugins/$plugin.yazi"
            set -l state_home "$HOME/.local/state"
            set -q XDG_STATE_HOME; and set state_home "$XDG_STATE_HOME"
            command mkdir -p "$state_home/yazi"
            command ya pkg install; or return
            break
        end
    end

    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    command yazi $argv --cwd-file="$tmp"
    set -l yazi_status $status
    if read -z cwd <"$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
    return $yazi_status
end

# Python helpers
function uvsh --description 'Activate the nearest uv virtual environment'
    set -l dir "$PWD"
    while test "$dir" != /
        if test -f "$dir/pyproject.toml"
            if test -f "$dir/.venv/bin/activate.fish"
                source "$dir/.venv/bin/activate.fish"
                return
            end
            echo "Python venv not found: $dir/.venv" >&2
            return 1
        end
        set dir (path dirname "$dir")
    end
    echo 'pyproject.toml not found in a parent directory' >&2
    return 1
end

# Remote access helpers
function nfssh --description 'SSH into the Flor Synology'
    set -lx SSHPASS (pass show -o synology/synology-flor/flor)
    sshpass -e ssh synology-flor -t 'cd /volume1/Shared-DS220; bash --login'
end

function npssh --description 'SSH into the DS220 Synology'
    set -lx SSHPASS (pass show -o synology/synology-ds/petobens)
    sshpass -e ssh synology -t 'cd /volume1/Shared-DS220; bash --login'
end

# AI helpers
function claude --description 'Run Claude with the GitHub MCP token'
    set -l github_token (pass show git/github/petobens/api-key)
    or return
    set -lx GITHUB_TOKEN "$github_token"
    command claude $argv
end

function codex --description 'Run Codex with the GitHub MCP token'
    set -l github_token (pass show git/github/petobens/api-key)
    or return
    set -lx GITHUB_TOKEN "$github_token"
    command codex $argv
end

# System maintenance
function sys_update_all --description 'Update system, firmware, and language tooling'
    sudo true; or return
    set -l section_color (set_color --bold blue)
    set -l normal_color (set_color normal)

    printf '%s\n-> System packages...%s\n' $section_color $normal_color
    if type -q yay
        command yay -Syu --devel --diffmenu=false --answerclean N \
            --removemake --cleanafter; or return
        command yay -Sc --noconfirm; or return
    else
        sudo pacman -Syu; or return
    end
    if type -q fwupdmgr
        printf '%s\n-> Firmware (check only)...%s\n' $section_color $normal_color
        fwupdmgr get-updates; or true
    end
    if type -q python
        printf '%s\n-> Python user packages...%s\n' $section_color $normal_color
        set -l outdated (python -m pip list --user --outdated --format=json | jq -r '.[].name')
        if test (count $outdated) -gt 0
            printf '%s\n' $outdated
            python -m pip install --user --break-system-packages --upgrade $outdated
        end
    end
    if type -q uv
        printf '%s\n-> Python tools...%s\n' $section_color $normal_color
        uv tool upgrade --all
    end
    if type -q tlmgr
        printf '%s\n-> LaTeX packages...%s\n' $section_color $normal_color
        sudo -E env "PATH=$PATH" tlmgr update --all
    end
    if type -q npm
        printf '%s\n-> Node packages...%s\n' $section_color $normal_color
        npm update --global --no-fund
    end
    if type -q rustup
        printf '%s\n-> Rust toolchains...%s\n' $section_color $normal_color
        rustup update
    end
end
