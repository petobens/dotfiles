if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ "$OSTYPE" == 'linux-gnu' ]; then
    if [[ ! $DISPLAY &&  "$(tty)" == '/dev/tty1' ]]; then
        exec startx &> /tmp/startx.log; exit
    fi
fi
