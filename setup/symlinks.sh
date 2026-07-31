#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
backup_root=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backup/$(date +%Y%m%d-%H%M%S-%N)

declare netrc personal_config ssh_config ssh_public

# shellcheck disable=SC1091
source "$repo/setup/load_personal.sh"

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

symlink() {
    local source=$1 target=$2
    mkdir -p "$(dirname "$target")"
    # Preserve real files but replace existing symlinks
    if [[ -e $target && ! -L $target ]]; then
        local backup="$backup_root/${target#"$HOME"/}"
        mkdir -p "$(dirname "$backup")"
        mv "$target" "$backup"
        printf 'Backed up %s to %s\n' "$target" "$backup"
    fi
    ln -sfn "$source" "$target"
}

symlink_if_exists() {
    local source=$1 target=$2
    if [[ -e $source ]]; then
        symlink "$source" "$target"
    else
        printf 'Skipped missing source: %s\n' "$source"
    fi
}

printf '\033[1;32m\n:: Starting dotfile symlinking\033[0m\n'

section 'Symlinking configuration'

# Home-directory configuration
symlink "$repo/bin" "$HOME/bin"
symlink "$repo/config/home/arararc.yaml" "$HOME/.arararc.yaml"
symlink "$repo/config/home/fdignore" "$HOME/.fdignore"
symlink "$repo/config/home/gitconfig" "$HOME/.gitconfig"
symlink "$repo/config/home/gitignore" "$HOME/.gitignore"
symlink "$repo/config/home/inputrc" "$HOME/.inputrc"
symlink "$repo/config/home/lesskey" "$HOME/.lesskey"
symlink "$repo/config/home/surfingkeysrc.js" "$HOME/.surfingkeysrc"

# Application configuration
symlink "$repo/config/bat" "$HOME/.config/bat"
symlink "$repo/config/brave-flags.conf" "$HOME/.config/brave-flags.conf"
symlink "$repo/config/fish" "$HOME/.config/fish"
symlink "$repo/config/ghostty" "$HOME/.config/ghostty"
symlink "$repo/hypr" "$HOME/.config/hypr"
symlink "$repo/config/imv" "$HOME/.config/imv"
symlink "$repo/config/kitty" "$HOME/.config/kitty"
symlink "$repo/config/mako" "$HOME/.config/mako"
symlink "$repo/config/microsoft-edge-dev-flags.conf" \
    "$HOME/.config/microsoft-edge-dev-flags.conf"
symlink "$repo/config/mpv" "$HOME/.config/mpv"
symlink "$repo/nvim" "$HOME/.config/nvim"
symlink "$repo/config/onedrive" "$HOME/.config/onedrive"
symlink "$repo/config/pgcli/config" "$HOME/.config/pgcli/config"
symlink "$repo/config/ripgrep" "$HOME/.config/ripgrep"
symlink "$repo/config/rofi" "$HOME/.config/rofi"
symlink "$repo/config/starship.toml" "$HOME/.config/starship.toml"
symlink "$repo/config/tmux" "$HOME/.config/tmux"
symlink "$repo/config/waybar" "$HOME/.config/waybar"
symlink "$repo/config/xkb" "$HOME/.config/xkb"
symlink "$repo/config/yazi" "$HOME/.config/yazi"
symlink "$repo/config/zathura" "$HOME/.config/zathura"

# Formatter and linter configuration
symlink "$repo/config/linters/hadolint.yaml" "$HOME/.config/hadolint.yaml"
symlink "$repo/config/linters/luacheckrc" "$HOME/.config/.luacheckrc"
symlink "$repo/config/linters/markdownlint.json" "$HOME/.markdownlint.json"
symlink "$repo/config/linters/prettierrc.yaml" "$HOME/.prettierrc.yaml"
symlink "$repo/config/linters/sqlfluff" "$HOME/.sqlfluff"
symlink "$repo/config/linters/stylua.toml" "$HOME/.config/stylua.toml"
symlink "$repo/config/linters/taplo.toml" "$HOME/taplo.toml"
symlink "$repo/config/linters/yamllint.yaml" "$HOME/.config/yamllint/config"

# Python tooling
symlink "$repo/config/python/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"
symlink "$repo/config/python/ipython_startup.py" "$HOME/.ipython/profile_default/startup/ipython_startup.py"
symlink "$repo/config/python/jupyterlab/jupyterlab_code_formatter" "$HOME/.jupyter/lab/user-settings/jupyterlab_code_formatter"
symlink "$repo/config/python/jupyterlab/overrides.json" "$HOME/.jupyter/lab/user-settings/overrides.json"
symlink "$repo/config/python/matplotlib" "$HOME/.config/matplotlib"
symlink "$repo/config/python/mypy.ini" "$HOME/.mypy.ini"
symlink "$repo/config/python/pdbrc" "$HOME/.pdbrc"
symlink "$repo/config/python/pdbrc.py" "$HOME/.pdbrc.py"
symlink "$repo/config/pip" "$HOME/.config/pip"
symlink "$repo/config/python/ruff" "$HOME/.config/ruff"

# Agent configuration
symlink "$repo/config/claude/settings.json" "$HOME/.claude/settings.json"
symlink "$repo/config/claude/statusline.sh" "$HOME/.claude/statusline.sh"
symlink "$repo/config/codex/config.toml" "$HOME/.codex/config.toml"
user_rules="$repo/../ai-harness/rules/USER.md"
symlink_if_exists "$user_rules" "$HOME/.claude/CLAUDE.md"
symlink_if_exists "$user_rules" "$HOME/.codex/AGENTS.md"
skills_dir="$repo/../ai-harness/skills"
symlink_if_exists "$skills_dir" "$HOME/.agents/skills"
symlink_if_exists "$skills_dir" "$HOME/.claude/skills"

# Credentials synchronized after the personal setup
install -d -m700 "$HOME/.gnupg"
symlink "$repo/config/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
symlink /usr/bin/gopass "$HOME/.local/bin/pass"
if [[ -r $personal_config ]]; then
    load_personal
    symlink_if_exists "$netrc" "$HOME/.netrc.gpg"
    symlink_if_exists "$ssh_config" "$HOME/.ssh/config"
    symlink_if_exists "$ssh_public" "$HOME/.ssh/id_rsa.pub"
else
    printf 'Skipped missing personal configuration: %s\n' "$personal_config"
fi

printf 'Symlinked Wayland dotfiles from %s\n' "$repo"
[[ ! -d $backup_root ]] || printf 'Previous files: %s\n' "$backup_root"
