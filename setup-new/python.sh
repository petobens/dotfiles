#!/usr/bin/env bash
if type "pip3" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Installing Python3 modules...\\033[0m"
    pip_install_cmd='pip3 install --user '
    $pip_install_cmd cython
    $pip_install_cmd jedi
    $pip_install_cmd matplotlib
    $pip_install_cmd numpy
    $pip_install_cmd pandas
    $pip_install_cmd pdbpp
    if type "nvim" > /dev/null 2>&1; then
        $pip_install_cmd pynvim
    fi
    $pip_install_cmd pytest-cov
    $pip_install_cmd pytest
    $pip_install_cmd requests
    $pip_install_cmd Send2Trash
    $pip_install_cmd scikit-learn
    $pip_install_cmd scipy
fi

# Python binaries (can also be mostly installed with a package manager but we
# do it with pipx to avoid dependency clash)
if ! type "pipx" > /dev/null 2>&1; then
    mkdir -p "$HOME"/.local/pipx/venvs
    curl https://raw.githubusercontent.com/cs01/pipx/master/get-pipx.py | python3
fi
echo -e "\\033[1;34m--> Installing python binaries (with pipx)...\\033[0m"
pipx install --spec git+https://github.com/PyCQA/flake8 flake8 --verbose
pipx install beautysh --verbose
pipx install black --verbose
pipx install ipython --verbose
pipx install isort --spec git+https://github.com/timothycrosley/isort@develop --verbose
pipx install jupyter-core --verbose
pipx install mycli --verbose
pipx install mypy --verbose
if type "nvim" > /dev/null 2>&1; then
    pipx install neovim-remote --verbose
fi
pipx install pgcli --verbose
if type "i3" > /dev/null 2>&1; then
    pipx install raiseorlaunch --verbose
fi
pipx install ranger-fm --verbose
pipx install sqlparse --verbose
pipx install trash-cli --verbose
pipx install vim-vint --verbose
pipx install yamllint --verbose
# TODO: Replace this once there is a new (fixed) mssql-cli release
# See https://github.com/dbcli/mssql-cli/pull/229
# pipx install --spec git+https://github.com/cs01/mssql-cli mssql-cli --verbose

# Install some missing libraries in each venv
pipx_home="$HOME/.local/pipx/venvs"
if [ -d "$pipx_home/jupyter-core" ]; then
    echo "Installing jupyter notebook..."
    "$pipx_home"/jupyter-core/bin/pip install jupyter
fi
if [ -d "$pipx_home/ranger-fm" ]; then
    echo "Adding desktop entry for ranger-fm..."
    xdg-desktop-menu install --novendor "$pipx_home"/ranger-fm/share/applications/ranger.desktop
    echo "xdg-mime query default inode/directory is: $(xdg-mime query default inode/directory)"
fi
if [ -d "$pipx_home/ipython" ]; then
    echo "Installing pandas for ipython..."
    "$pipx_home"/ipython/bin/pip install pandas
fi
if [ -d "$pipx_home/flake8" ]; then
    echo "Installing bugbear for flake8..."
    "$pipx_home"/flake8/bin/pip install flake8-bugbear
fi
