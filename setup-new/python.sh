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
pipx install flake8 --spec git+https://github.com/PyCQA/flake8 --verbose
pipx inject flake8 flake8-bugbear --verbose
pipx inject flake8 flake8-docstrings --verbose
pipx install beautysh --verbose
pipx install black --verbose
pipx install ipython --verbose
pipx inject ipython numpy --verbose
pipx install isort --spec git+https://github.com/timothycrosley/isort@develop --verbose
pipx install jupyter-core --verbose
pipx inject jupyter-core jupyter --verbose
pipx install mycli --verbose
pipx install mypy --verbose
if type "nvim" > /dev/null 2>&1; then
    pipx install neovim-remote --verbose
fi
pipx install pgcli --verbose
pipx install pylint --verbose
if type "i3" > /dev/null 2>&1; then
    pipx install raiseorlaunch --verbose
fi
pipx install ranger-fm --verbose
pipx install sqlparse --spec git+https://github.com/andialbrecht/sqlparse --verbose
pipx install trash-cli --verbose
pipx install unimatrix --spec git+https://github.com/will8211/unimatrix --verbose
pipx install vim-vint --verbose
pipx install yamllint --verbose
# TODO: Replace this once there is a new (fixed) mssql-cli release
# See https://github.com/dbcli/mssql-cli/pull/229
# pipx install --spec git+https://github.com/cs01/mssql-cli mssql-cli --verbose

pipx_home="$HOME/.local/pipx/venvs"
if [ -d "$pipx_home/ranger-fm" ]; then
    echo "Adding desktop entry for ranger-fm..."
    xdg-desktop-menu install --novendor "$pipx_home"/ranger-fm/share/applications/ranger.desktop
    echo "xdg-mime query default inode/directory is: $(xdg-mime query default inode/directory)"
fi

# Copy pygment onedarkish style
echo -e "\\033[1;34m--> Installing onedarkish pygment style...\\033[0m"
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
parent_dir="$(dirname "$current_dir")"
python_dir="$parent_dir/python"

ln_cmd='ln'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "gln" > /dev/null 2>&1; then
        ln_cmd='gln'
    else
        echo "Coreutils ln (gln) command not found!" 1>&2
        exit 1
    fi
fi

for dbcli in mycli pgcli mssql-cli
do
    if [ -d "$pipx_home/$dbcli" ]; then
        styles_dir="$pipx_home/$dbcli/lib/python3.7/site-packages/pygments/styles"
        if [ -d "$styles_dir" ]; then
            $ln_cmd -fTs "$python_dir/onedarkish.py" "$styles_dir/onedarkish.py"
            echo Created symlink in "$styles_dir/onedarkish.py"
        fi
    fi
done
