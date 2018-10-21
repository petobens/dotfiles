#!/usr/bin/env bash

# Python binaries (can also be mostly installed with ia package manager but we
# do it with pipx to avoid dependency clash)
if ! type "pipx" > /dev/null 2>&1; then
    mkdir -p "$HOME"/.local/pipx/venvs
    curl https://raw.githubusercontent.com/cs01/pipx/master/get-pipx.py | python3
fi

pipx install --spec git+https://github.com/PyCQA/flake8 flake8 --verbose
pipx install beautysh --verbose
pipx install ipython --verbose
pipx install jupyter-core --verbose
pipx install mycli --verbose
pipx install pgcli --verbose
pipx install vim-vint --verbose
pipx install yamllint --verbose
pipx install yapf --verbose
# TODO: Replace this once it's merged
pipx install --spec git+https://github.com/cs01/mssql-cli@593d7f6516 mssql-cli --verbose
