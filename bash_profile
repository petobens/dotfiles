# shellcheck disable=SC2148
# Path and os dependent settings {{{

# OS dependent settings
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        # shellcheck disable=SC2155
        export BASE_PKG_DIR=$(brew --prefix)
    else
        export BASE_PKG_DIR='/usr/local'
    fi

    # Path settings
    PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"
    PATH="$BASE_PKG_DIR/bin:$BASE_PKG_DIR/sbin:$PATH" # homebrew
    if [ -d "/Library/TeX/texbin" ]; then
        PATH="/Library/TeX/texbin:$PATH" # basictex
    fi
    # Symlink cask apps to Applications folder
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    # Set english utf-8 locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
else
    export BASE_PKG_DIR='/usr'

    # Local paths first (note that path is originally defined in /etc/profile)
    PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"
    export MANPATH="$HOME/local/share/man:$HOME/.local/share/man:$MANPATH"

    # Texlive
    if [ -d "$BASE_PKG_DIR/local/texlive" ]; then
        # Note: we put this first (even before local so that if there is some
        # other pdflatex installed tlmgr is found first)
        PATH="/usr/local/texlive/2024/bin/x86_64-linux:$PATH"
        # FIXME: If we set this then we cannot jump between Man tags with nvim
        # export MANPATH="$MANPATH:/usr/local/texlive/2021/texmf-dist/doc/man"
        export INFOPATH="$INFOPATH:/usr/local/texlive/2024/texmf-dist/doc/info"
    fi

    # GTK scaling and themes (we don't do this here because we use the Xft.dpi
    # setting to scale most GTK apps (note: i) we might need to restart the app
    # to see the effect and ii) this won't work for all apps/dialogs))
    # export GDK_SCALE=2
    # export GDK_DPI_SCALE=0.5 #
    export GTK_THEME=Adwaita:dark
fi

# Path OS agnostic settings
if [[ -d "$HOME/bin" ]]; then
    # Append this after local paths
    PATH="$PATH:$HOME/bin"
fi
if type "npm" > /dev/null 2>&1; then
    PATH="$HOME/.npm-global/bin:$PATH"
    export npm_config_prefix="$HOME/.npm-global"
fi
if type "go" > /dev/null 2>&1; then
    export GOPATH=$HOME/go
    PATH=$PATH:$GOPATH/bin
fi
if type "cargo" > /dev/null 2>&1; then
    PATH=$PATH:$HOME/.cargo/bin
fi
if type "ruby" > /dev/null 2>&1; then
    export GEM_HOME=$HOME/.gem
    PATH="$PATH:$GEM_HOME/bin"
fi
if type "pyenv" > /dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path --no-rehash bash)"
fi
# Prepend python virtual env to path if exists (this is useful when spawning a
# new terminal form within neovim). Note: this must be the very last PATH mod
if [ -n "$VIRTUAL_ENV" ]; then
    PATH="$VIRTUAL_ENV/bin:$PATH"
fi

# Remove duplicate path entries
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')

# }}}
# Enviromental variables {{{

export COLUMNS # used for instance by git-delta

# Set editor to nvim and use it as a manpager
if type "nvim" > /dev/null 2>&1; then
    export EDITOR='nvim'
    export MANPAGER='nvim +Man!'
fi

# Set shell to latest bash (check "$(command -v bash)")
if [ -f "$BASE_PKG_DIR/bin/bash" ]; then
    export SHELL="$BASE_PKG_DIR/bin/bash"
fi

# Language/binaries environmental variables
if type "vivid" > /dev/null 2>&1; then
    # shellcheck disable=SC2155
    export LS_COLORS="$(vivid generate onedarkish)"
else
    # Highlight directories in blue, symbolic links in purple, executable
    # files in red and sticky dirs in green
    export LS_COLORS="di=0;34:ln=0;35:ex=0;31:tw=0;32"
fi
if type "pipx" > /dev/null 2>&1; then
    eval "$(register-python-argcomplete pipx)"
    export PIPX_HOME=$HOME/.local/pipx
    export PIPX_BIN_DIR=$HOME/.local/bin
fi
if type "gpg" > /dev/null 2>&1; then
    GPG_TTY=$(tty)
    export GPG_TTY
fi
if type "shellcheck" > /dev/null 2>&1; then
    export SHELLCHECK_OPTS="-e SC1090"
fi
if type "rg" > /dev/null 2>&1; then
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"
fi
if type "upower" > /dev/null 2>&1; then
    # Read and set battery and adapter types
    UPOWER_BATTERY="$(upower -e | grep battery | cut -d '_' -f2)"
    export UPOWER_BATTERY
    UPOWER_ADAPTER="$(upower -e | grep line | cut -d '_' -f3)"
    export UPOWER_ADAPTER
fi
if type "kitty" > /dev/null 2>&1; then
    # Control matplotlib kitty backend figure resize manually
    export MPLBACKEND_KITTY_SIZING=manual
fi
if type "qt5ct" > /dev/null 2>&1; then
    export QT_QPA_PLATFORMTHEME="qt5ct"
fi

# }}}
# Xorg (and linux specific) {{{

if [ "$OSTYPE" == 'linux-gnu' ]; then
    # Define laptop brightness (will be read by Xresource upon starting X)
    LAPTOP_XBRIGHTNESS=30
    export LAPTOP_XBRIGHTNESS

    # Override default ethernet interface (for polybar)
    DEFAULT_ETHERNET_INTERFACE='eth0'
    if [[ "$HOSTNAME" == 'Aspire3' ]]; then
        DEFAULT_ETHERNET_INTERFACE='eth1'
    fi
    export DEFAULT_ETHERNET_INTERFACE

    # Immediately startx after login
    if [[ ! $DISPLAY && "$(tty)" == '/dev/tty1' ]]; then
        exec startx &> /tmp/startx.log
        exit
    fi
fi

# }}}
# OSX {{{

if [[ "$OSTYPE" == 'darwin'* ]]; then
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi
fi

# }}}
