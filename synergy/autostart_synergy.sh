#!/bin/sh
server_ip=$(smbutil lookup pedro-acer | grep response | awk '{print $4}')

# Check for synergys running
number=$(ps ax | grep "[/]synergyc" | wc -l)

# Start synergyc in foreground if not already running
if [ $number -gt 0 ]
    then
        echo Synergy is already running
    else
        /Applications/Synergy.app/Contents/MacOS/synergyc -n pedro-macbook -1 -f $server_ip
fi
