# Path and os dependent settings {{{

# OS dependent settings
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
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
        PATH="$PATH:/usr/local/texlive/2019/bin/x86_64-linux"
        export MANPATH="$MANPATH:/usr/local/texlive/2019/texmf-dist/doc/man"
        export INFOPATH="$INFOPATH:/usr/local/texlive/2019/texmf-dist/doc/info"
    fi

    export BROWSER='chromium'

    # Scaling
    export GDK_SCALE=2
    export GDK_DPI_SCALE=0.5
fi

# Path OS agnostic settings
if [[ -d "$HOME/bin" ]]; then
    PATH="$HOME/bin:$PATH"
fi
if type "npm" > /dev/null 2>&1; then
    PATH="$HOME/.node_modules/bin:$PATH"
    export npm_config_prefix="$HOME/.node_modules"
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
    eval "$(pyenv init - --no-rehash bash)"
fi
# We use sqlcl instead of sqlplus (it must be manually installed to this dir)
if [ -d "$HOME/.local/sqlcl" ]; then
    PATH="$PATH:$HOME/.local/sqlcl/bin"
fi
# Prepend python virtual env to path if exists (this is useful when spawning a
# new terminal form within neovim). Note: this must be the very last PATH mod
if [ -n "$VIRTUAL_ENV" ]; then
    PATH="$VIRTUAL_ENV/bin:$PATH"
    # Also set airflow home to this dir (pipenv shell reads .env file)
    export AIRFLOW_HOME="$VIRTUAL_ENV/airflow"
fi

# Remove duplicate path entries
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')

# }}}
# Enviromental variables {{{

# Set editor to nvim and use it as a manpager
export EDITOR='nvim --listen /tmp/nvimsocket'
export MANPAGER='nvim +Man!'

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
if type "python" > /dev/null 2>&1; then
    export AIRFLOW_GPL_UNIDECODE='yes'
fi
# R libraries (note: first create this folder if it doesn't exist)
if type "R" > /dev/null 2>&1; then
    export R_LIBS_USER="$HOME/.local/lib/R/site-library"
fi
if type "pipenv" > /dev/null 2>&1; then
    # Always create a pipenv venv (useful when running from vim)
    export PIPENV_IGNORE_VIRTUALENVS=1
    # Don't lock dependencies automatically when install/uninstall commands
    export PIPENV_SKIP_LOCK=1
fi
if type "pipx" > /dev/null 2>&1; then
    eval "$(register-python-argcomplete pipx)"
    export PIPX_HOME=$HOME/.local/pipx
    export PIPX_BIN_DIR=$HOME/.local/bin
fi
if type "sqlplus" > /dev/null 2>&1; then
    export SQLPATH="$HOME/.config/sqlplus"
fi
if type "mssql-cli" > /dev/null 2>&1; then
    export MSSQL_CLI_TELEMETRY_OPTOUT=1
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

# }}}
# Xorg {{{

if [ "$OSTYPE" == 'linux-gnu' ]; then
    if [[ ! $DISPLAY &&  "$(tty)" == '/dev/tty1' ]]; then
        exec startx &> /tmp/startx.log; exit
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
