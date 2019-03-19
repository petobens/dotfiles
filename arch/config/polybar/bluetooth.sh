#!/usr/bin/env bash

has_bluetooth=$(bluetoothctl info | grep '^Device')
if [[ -n "$has_bluetooth" ]]; then
    echo -n ' '
else
    echo -n ' '
fi
