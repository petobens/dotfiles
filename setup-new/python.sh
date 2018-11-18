#!/usr/bin/env bash
if type "pip3" > /dev/null 2>&1; then
    echo -e "\033[1;34m--> Installing Python3 modules...\033[0m"
    pip_install_cmd='pip3 install --user '
    $pip_install_cmd cython
    $pip_install_cmd jedi
    $pip_install_cmd matplotlib
    $pip_install_cmd numpy
    $pip_install_cmd pandas
    if type "nvim" > /dev/null 2>&1; then
        $pip_install_cmd pynvim
    fi
    $pip_install_cmd pytest-cov
    $pip_install_cmd pytest
    $pip_install_cmd requests
    $pip_install_cmd scikit-learn
    $pip_install_cmd scipy
fi

# Python binaries (can also be mostly installed with a package manager but we
# do it with pipx to avoid dependency clash)
if ! type "pipx" > /dev/null 2>&1; then
    mkdir -p "$HOME"/.local/pipx/venvs
    curl https://raw.githubusercontent.com/cs01/pipx/master/get-pipx.py | python3
fi
echo -e "\033[1;34m--> Installing python binaries (with pipx)...\033[0m"
pipx install --spec git+https://github.com/PyCQA/flake8 flake8 --verbose
pipx install beautysh --verbose
pipx install black --verbose
pipx install ipython --verbose
pipx install jupyter-core --verbose
pipx install mycli --verbose
pipx install mypy --verbose
pipx install neovim-remote --verbose
pipx install pgcli --verbose
if type "i3" > /dev/null 2>&1; then
    pipx install raiseorlaunch --verbose
fi
pipx install sqlparse --verbose
pipx install vim-vint --verbose
pipx install yamllint --verbose
# TODO: Replace this once it's merged (and actually works)
# See: https://github.com/dbcli/mssql-cli/pull/228
# pipx install --spec git+https://github.com/cs01/mssql-cli@593d7f6516 mssql-cli --verbose


# Install some missing libraries in each venv
if type "pipx" > /dev/null 2>&1; then
    pipx_home="$HOME/.local/pipx/venvs"
    if [ -d "$pipx_home/jupyter-core" ]; then
        echo "Installing jupyter notebook..."
        "$pipx_home"/jupyter-core/bin/pip install jupyter
    fi
    if [ -d "$pipx_home/ipython" ]; then
        echo "Installing pandas for ipython..."
        "$pipx_home"/ipython/bin/pip install pandas
    fi
    if [ -d "$pipx_home/flake8" ]; then
        echo "Installing bugbear for flake8..."
        "$pipx_home"/flake8/bin/pip install flake8-bugbear
    fi
fi
