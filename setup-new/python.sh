#!/usr/bin/env bash
if type "pyenv" > /dev/null 2>&1; then
    pyenv rehash
fi

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
    $pip_install_cmd pipx
    $pip_install_cmd Send2Trash
    if [ "$OSTYPE" == 'linux-gnu' ]; then
        $pip_install_cmd Xlib
    fi
fi

# Python binaries (can also be mostly installed with a package manager but we
# do it with pipx to avoid dependency clash)
# Note: when upgrading python minor version we might need to remove the
# ~/.local/pipx folder and reinstall all packages by running this file
# See https://github.com/pipxproject/pipx/issues/278#issuecomment-557132753
echo -e "\\033[1;34m--> Installing python binaries (with pipx)...\\033[0m"
if ! type "pipx" > /dev/null 2>&1; then
    python3 -m pipx ensurepath
fi
pipx_install_cmd="$HOME/.local/bin/pipx install --force --verbose"
if [[ "$OSTYPE" == 'darwin'* ]]; then
    # We seem to need sudo on osx
    pipx_install_cmd="sudo $pipx_install_cmd"
fi
pipx_inject_cmd="$HOME/.local/bin/pipx inject --verbose"

$pipx_install_cmd aws-mfa
$pipx_install_cmd black
$pipx_install_cmd isort
$pipx_install_cmd jupyter --include-deps
$pipx_inject_cmd jupyter numpy pandas matplotlib
$pipx_install_cmd ipython
$pipx_inject_cmd ipython numpy pandas matplotlib matplotlib-backend-kitty black
$pipx_inject_cmd ipython git+https://github.com/petobens/ipython-ctrlr-fzf@ui
$pipx_install_cmd litecli
$pipx_install_cmd mycli
$pipx_install_cmd mypy
if type "nvim" > /dev/null 2>&1; then
    $pipx_install_cmd neovim-remote
fi
$pipx_install_cmd pgcli
$pipx_install_cmd poetry
$pipx_inject_cmd poetry poetry-plugin-up
$pipx_install_cmd pylint
if type "i3" > /dev/null 2>&1; then
    $pipx_install_cmd git+https://github.com/open-dynaMIX/raiseorlaunch
fi
$pipx_install_cmd ranger-fm
$pipx_install_cmd ruff
$pipx_install_cmd sqlfluff
$pipx_install_cmd trash-cli
$pipx_install_cmd git+https://github.com/will8211/unimatrix
$pipx_install_cmd vimiv
$pipx_install_cmd yamllint

pipx_venvs="$PIPX_HOME/venvs"

# Set some mime defaults
if [ -d "$pipx_venvs/ranger-fm" ]; then
    echo "Adding desktop entry for ranger-fm..."
    xdg-desktop-menu install --novendor "$pipx_venvs/ranger-fm/share/applications/ranger.desktop"
    echo "xdg-mime query default inode/directory is: $(xdg-mime query default inode/directory)"
    echo "Adding man pages ranger-fm..."
    local_man_path="$HOME/.local/share/man/man1"
    mkdir -p "$local_man_path"
    cp -a "$pipx_venvs/ranger-fm/share/man/man1/." "$local_man_path"
    echo "Updating man's internal db..."
    sudo mandb
fi
if [ -d "$pipx_venvs/vimiv" ]; then
    echo "Adding desktop entry for vimiv..."
    mkdir -p "$pipx_venvs/vimiv/share"
    wget -P "$pipx_venvs/vimiv/share" "https://raw.githubusercontent.com/karlch/vimiv-qt/master/misc/vimiv.desktop"
    xdg-desktop-menu install --novendor "$pipx_venvs/vimiv/share/vimiv.desktop"
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
    if [ -d "$pipx_venvs/$cli" ]; then
        styles_dir="$pipx_venvs/$cli/lib/python$python_version/site-packages/pygments/styles"
        if [ -d "$styles_dir" ]; then
            $ln_cmd -fTs "$python_dir/onedarkish.py" "$styles_dir/onedarkish.py"
            echo Created symlink in "$styles_dir/onedarkish.py"
        fi
    fi
done
