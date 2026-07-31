#!/usr/bin/env bash
set -euo pipefail

section() {
    printf '\033[1;34m\n-> %s...\033[0m\n' "$1"
}

printf '\033[1;32m\n:: Starting language tool installation\033[0m\n'

section 'Installing Python user packages'
python -m pip install --user --break-system-packages --upgrade pdbpp

section 'Installing Python language tools'
uv tool install --force aws-mfa
uv tool install --force --with-executables-from jupyter-core --with jupyter,numpy,pandas,matplotlib,jupyter-ruff jupyterlab
uv tool install --force --with numpy,pandas,matplotlib --with git+https://github.com/petobens/ipython-ctrlr-fzf@ui ipython
for tool in \
    mypy \
    nbdime \
    pgcli \
    pre-commit \
    ruff \
    sqlfluff \
    git+https://github.com/will8211/unimatrix \
    uv-upx \
    yamllint \
    zuban; do
    uv tool install --force "$tool"
done

section 'Installing Node language tools'
npm config set prefix "$HOME/.npm-global"
npm_packages=(
    @agentclientprotocol/claude-agent-acp
    @agentclientprotocol/codex-acp
    @fsouza/prettierd
    jsonlint
)
npm install --global "${npm_packages[@]}"
npm list --global --depth=0 "${npm_packages[@]}"

section 'Configuring Rust toolchain'
rustup default stable
