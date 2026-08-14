#!/usr/bin/env bash

global_npm_dir="$HOME/.npm-global"
mkdir -p "$global_npm_dir"
chown -R "$USER" "$global_npm_dir"
npm config set prefix "$global_npm_dir"
PATH="$global_npm_dir/bin:$PATH"

# Linters and formatters
npm install -g oxfmt
npm install -g oxlint

# AI
npm install -g @agentclientprotocol/claude-agent-acp
npm install -g @agentclientprotocol/codex-acp
