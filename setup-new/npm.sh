#!/usr/bin/env bash

global_npm_dir="$HOME/.npm-global"
mkdir -p "$global_npm_dir"
chown -R "$USER" "$global_npm_dir"
npm config set prefix "$global_npm_dir"
PATH="$global_npm_dir/bin:$PATH"

# Linters
npm install -g eslint
npm install -g htmlhint
npm install -g js-beautify
npm install -g jsonlint
npm install -g markdownlint-cli
npm install -g @fsouza/prettierd

# AI
npm install -g @agentclientprotocol/claude-agent-acp
npm install -g @agentclientprotocol/codex-acp
