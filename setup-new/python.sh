#!/usr/bin/env bash

if type "pip3" > /dev/null 2>&1; then
    echo -e "\\033[1;34m--> Installing Python3 modules...\\033[0m"
    pip_install_cmd='pip3 install --user --break-system-packages'
    if type "i3" > /dev/null 2>&1; then
        $pip_install_cmd git+https://github.com/altdesktop/i3ipc-python
    fi
    $pip_install_cmd matplotlib
    $pip_install_cmd matplotlib-backend-kitty
    $pip_install_cmd numpy
    $pip_install_cmd pandas
    $pip_install_cmd Pillow # needed for gtk dialogs
    $pip_install_cmd pdbpp
    $pip_install_cmd Send2Trash
    if [ "$OSTYPE" == 'linux-gnu' ]; then
        $pip_install_cmd Xlib
    fi
fi

# Python binaries
echo -e "\\033[1;34m--> Installing python binaries (with uv)...\\033[0m"
uv_install_cmd='uv tool install --force'

$uv_install_cmd aws-mfa
$uv_install_cmd black
$uv_install_cmd isort
$uv_install_cmd --with-executables-from jupyter-core --with jupyter,numpy,pandas,matplotlib,jupyter-ruff jupyterlab
$uv_install_cmd --with numpy,pandas,matplotlib,matplotlib-backend-kitty --with git+https://github.com/petobens/ipython-ctrlr-fzf@ui ipython
$uv_install_cmd litecli
$uv_install_cmd mycli
$uv_install_cmd mypy
$uv_install_cmd nbdime
if type "nvim" > /dev/null 2>&1; then
    $uv_install_cmd neovim-remote
fi
$uv_install_cmd pgcli
$uv_install_cmd --with poetry-plugin-up poetry
$uv_install_cmd pylint
if type "i3" > /dev/null 2>&1; then
    $uv_install_cmd git+https://github.com/open-dynaMIX/raiseorlaunch
fi
$uv_install_cmd ranger-fm
$uv_install_cmd ruff
$uv_install_cmd sqlfluff
$uv_install_cmd trash-cli
$uv_install_cmd git+https://github.com/will8211/unimatrix
$uv_install_cmd vimiv
$uv_install_cmd yamllint

uv_venvs=$(uv tool dir)

# Set some mime defaults
if [ -d "$uv_venvs/ranger-fm" ]; then
    echo "Adding desktop entry for ranger-fm..."
    xdg-desktop-menu install --novendor "$uv_venvs/ranger-fm/share/applications/ranger.desktop"
    echo "xdg-mime query default inode/directory is: $(xdg-mime query default inode/directory)"
    echo "Adding man pages ranger-fm..."
    local_man_path="$HOME/.local/share/man/man1"
    mkdir -p "$local_man_path"
    cp -a "$uv_venvs/ranger-fm/share/man/man1/." "$local_man_path"
    echo "Updating man's internal db..."
    sudo mandb
fi
if [ -d "$uv_venvs/vimiv" ]; then
    echo "Adding desktop entry for vimiv..."
    mkdir -p "$uv_venvs/vimiv/share"
    wget -P "$uv_venvs/vimiv/share" "https://raw.githubusercontent.com/karlch/vimiv-qt/master/misc/vimiv.desktop"
    xdg-desktop-menu install --novendor "$uv_venvs/vimiv/share/vimiv.desktop"
    echo "xdg-mime query default image/png is: $(xdg-mime query default image/png)"
fi

# Copy pygment onedarkish style
echo -e "\\033[1;34m--> Installing onedarkish pygment styles...\\033[0m"
current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parent_dir="$(dirname "$current_dir")"
python_dir="$parent_dir/python"

# Get python version
python_version=$(python --version | cut -d ' ' -f2)
python_major=$(echo "$python_version" | cut -d '.' -f1)
python_minor=$(echo "$python_version" | cut -d '.' -f2)
python_version="$python_major.$python_minor"

ln_cmd='ln'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "gln" > /dev/null 2>&1; then
        ln_cmd='gln'
    else
        echo "Coreutils ln (gln) command not found!" 1>&2
        exit 1
    fi
fi

for cli in litecli mycli pgcli; do
    if [ -d "$uv_venvs/$cli" ]; then
        styles_dir="$uv_venvs/$cli/lib/python$python_version/site-packages/pygments/styles"
        if [ -d "$styles_dir" ]; then
            $ln_cmd -fTs "$python_dir/onedarkish.py" "$styles_dir/onedarkish.py"
            echo Created symlink in "$styles_dir/onedarkish.py"
        fi
    fi
done
