# Windows:
We symlink from our dotfiles the vimrc file containing only: `source
C:/OD/OneDrive/Users/Pedro/vimfiles/vimrc` point it to our home directory and
call it `_vimrc`

If we use the `winpython` distribution in order for gvim to work we need to
create a PYTHONHOME env variable: C:\prog-lang\winpython\python-3.4.3.amd64

In order to use most Unix tools we install msys2 and then, through `pacman -S
{package_name}`, the following binaries (and their dependencies):
mingw-w64-x86_64-gcc, mingw64/mingw-w64-x86_64-make, diffutils, autoconf,
automake (installs perl as dependency), libtool, mingw64/mingw-w64-x86_64-ag
We then add msys2 and mingw64 to the path like this:
C:\prog-tools\msys2\usr\bin; C:\prog-tools\msys2\mingw64\bin
Finally (for convinience) copy and rename mingw32-make.exe as make.exe

# Mac:

To build MacVim manually (i.e without homebrew) run the following then
inside the src directory:
CC=clang ./configure --with-features=huge \
 --enable-multibyte \
 --enable-rubyinterp \
 --enable-python3interp \
 --with-python3-config-dir=/usr/local/Cellar/python3/3.5.1/Frameworks/Python.framework/Versions/3.5/lib/python3.5/config-3.5m/ \
 --enable-perlinterp \
 --enable-tclinterp \
 --enable-luainterp \
 --with-lua-prefix=/usr/local \
 --enable-cscope \
 --with-tlib=ncurses \
 --enable-fail-if-missing && make

Note that:
- On Lion (10.7.5) we need first to remove the Quicklook folder (by opening
  Macvim.xcodeproj with xcode app)
- If compiled with `--with-luajit` then macvim crashes when entering insert
mode and using neocomplete so avoid it
- We can only compile with one python version so if we want to use python3
avoid including `--enable-pythoninterp` flag.
- At least on Lion to compile python3 we seem to need the osx-gcc-installer
compilers.
- To open macvim from terminal copy mvim to /usr/local/bin
- To make Dispatch plugin work in a similar fashion to windows we need to install
  and have an open session of iTerm2

- On El Capitan it is enough to do:
brew install macvim --with-cscope --with-lua --with-override-system-vim --with-python3

- To use regular (terminal) vim. Install it with
brew install vim --with-lua --with-python3
- If we want client-server feature instead do
brew install vim --with-lua --with-python3 --with-client-server

# Linux

- Build it from source following:
https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source

- Or simply install it with linuxbrew using
brew install vim --with-lua --with-python3 --with-client-server
Note: we need to set the terminfo right for vim to work properly (i.e place
xterm256-italic terminfo in both $HOME/.terminfo/x and /lib/terminfo/x
directories).
