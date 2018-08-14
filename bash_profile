if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    if [[ ! $DISPLAY &&  "$(tty)" == '/dev/tty1' ]]; then
        exec startx; exit
    fi
fi
