# Interactive shell defaults
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx TERMINAL ghostty
set -gx BROWSER xdg-open
set -gx RIPGREP_CONFIG_PATH "$HOME/.config/ripgrep/ripgreprc"
fish_add_path \
    "$HOME/bin" \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.npm-global/bin"

set -g fish_greeting
set -g fish_history main
fish_vi_key_bindings
bind -M insert -m default jj repaint-mode
bind -M insert \cp history-search-backward
bind -M insert \cn history-search-forward
bind -M insert \ce end-of-line
bind -M insert \ca beginning-of-line
bind -M default H beginning-of-line
bind -M default L end-of-line

# Short commands used throughout the terminal workflow
abbr -a u 'cd ..'
abbr -a 2u 'cd ../..'
abbr -a 3u 'cd ../../..'
abbr -a 4u 'cd ../../../..'
abbr -a h 'cd ~'
abbr -a q exit
abbr -a c clear
abbr -a md 'mkdir -p'
abbr -a open xdg-open
abbr -a ss 'sudo -i'
abbr -a df 'df -h'
abbr -a rsync 'rsync -auP'
abbr -a ff fastfetch
abbr -a ht htop
abbr -a fm yazi
abbr -a dog bat
abbr -a v nvim
abbr -a py python
abbr -a gs 'git status'
abbr -a gcl 'git clone'
abbr -a gco 'git switch'
abbr -a gcob 'git switch -c'
abbr -a gcp 'git cherry-pick'
abbr -a gb 'git branch'
abbr -a gbd 'git branch -D'
abbr -a gp 'git push'
abbr -a gF 'git push --force-with-lease'
abbr -a gP 'git pull'
abbr -a gPr 'git pull --rebase'
abbr -a gf 'git fetch'
abbr -a gr 'git rebase'
abbr -a grc 'git rebase --continue'
abbr -a gst 'git stash'
abbr -a gsp 'git stash pop'
abbr -a ghp 'gh pr'
abbr -a uva 'uv add'
abbr -a uvad 'uv add --dev'
abbr -a uvrm 'uv remove'
abbr -a uvs 'uv sync'
abbr -a uvi 'uv sync --locked'
abbr -a uvl 'uv pip list'
abbr -a uvr 'uv run'
abbr -a uvp 'uv run python'
abbr -a uvd 'uv run python -m pdb -cc'
abbr -a uvt 'uv run pytest -n auto --cov'
abbr -a uvh 'uv run pre-commit run --all-files'
abbr -a ua sys_update_all
if type -q lsd
    abbr -a ls 'lsd -F --color=auto'
end

# Initialize interactive tools
if type -q zoxide
    zoxide init fish | source
end
if type -q fzf
    fzf --fish | source
end
if type -q starship
    starship init fish | source
end

function tm --description 'Attach to the main tmux session'
    set -l session (test "$USER" = pedro; and echo petobens; or echo "$USER")
    command tmux -f "$HOME/.config/tmux/tmux.conf" new -A -s "$session" $argv
end

function y --description 'Run Yazi and change to its final directory'
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

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

function up --description 'Extract an archive'
    test -f "$argv[1]"; or begin; echo "Not a file: $argv[1]" >&2; return 1; end
    switch "$argv[1]"
        case '*.tar.bz2' '*.tbz2'; tar xjf "$argv[1]"
        case '*.tar.gz' '*.tgz'; tar xzf "$argv[1]"
        case '*.tar' '*.tar.xz' '*.tar.zst'; tar xf "$argv[1]"
        case '*.bz2'; bunzip2 "$argv[1]"
        case '*.gz'; gunzip "$argv[1]"
        case '*.rar'; unrar x "$argv[1]"
        case '*.zip'; unzip "$argv[1]"
        case '*.7z' '*.7Z'; 7z x "$argv[1]"
        case '*'; echo "Unsupported archive: $argv[1]" >&2; return 1
    end
end

function sys_update_all --description 'Update system and language tooling'
    sudo true; or return
    if type -q yay
        yay -Syu --diffmenu=false --answerclean N --removemake --cleanafter; or return
        yay -Sc --noconfirm; or return
    else
        sudo pacman -Syu; or return
    end
    type -q uv; and uv tool upgrade --all
    type -q cargo-install-update; and cargo install-update --all
    type -q npm; and npm update --global --no-fund
end
