#!/usr/bin/env bash

bluetooth_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
if [ "$bluetooth_status" == "yes" ]; then
    connected_device=$(bluetoothctl info | grep "Connected:" | awk '{print $2}')
    if [ "$connected_device" == "yes" ]; then
        echo -n '󰂯 '
    else
        echo -n '󰂲 '
    fi
else
    echo -n '  '
fi
