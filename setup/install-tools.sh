#!/usr/bin/env bash
set -euo pipefail

uv tool install --force aws-mfa
uv tool install --force black
uv tool install --force --with-executables-from jupyter-core --with jupyter,numpy,pandas,matplotlib,jupyter-ruff jupyterlab
uv tool install --force --with numpy,pandas,matplotlib,matplotlib-backend-kitty --with git+https://github.com/petobens/ipython-ctrlr-fzf@ui ipython
uv tool install --force mypy
uv tool install --force nbdime
uv tool install --force pgcli
uv tool install --force --with poetry-plugin-up poetry
uv tool install --force pre-commit
uv tool install --force pylint
uv tool install --force ruff
uv tool install --force sqlfluff
uv tool install --force uv-upx
uv tool install --force yamllint
uv tool install --force zuban

npm config set prefix "$HOME/.npm-global"
npm_packages=(
	@agentclientprotocol/claude-agent-acp
	@agentclientprotocol/codex-acp
	@fsouza/prettierd
	eslint
	htmlhint
	js-beautify
	jsonlint
)
npm install --global "${npm_packages[@]}"

rustup default stable
cargo install cargo-update devicon-lookup
