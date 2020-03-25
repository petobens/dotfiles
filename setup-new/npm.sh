#!/usr/bin/env bash

mkdir -p "$HOME/.node_modules"
chown -R "$USER" "$HOME/.node_modules"
PATH="$HOME/.node_modules/bin:$PATH"

npm install -g eslint
npm install -g htmlhint
npm install -g js-beautify
npm install -g jsonlint
npm install -g markdownlint-cli
npm install -g prettier
npm install -g tern
