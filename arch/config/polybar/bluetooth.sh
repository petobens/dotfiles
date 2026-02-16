#!/usr/bin/env bash

_btctl() {
    bluetoothctl 2> /dev/null <<< "$*"
}

bluetooth_status="$(
    _btctl show | awk '/Powered:/ {print $2; exit}'
)"

BLACKLIST_NAMES=(
    "MX Master 3S"
)

is_blacklisted() {
    local name_lc=${1,,} b
    for b in "${BLACKLIST_NAMES[@]}"; do
        [[ $name_lc == *"${b,,}"* ]] && return 0
    done
    return 1
}

[[ $bluetooth_status == "yes" ]] || {
    echo -n '  '
    exit 0
}

connected_device="no"
while IFS= read -r line; do
    [[ $line == Device\ * ]] || continue

    name="${line#Device }"
    name="${name#* }"

    is_blacklisted "$name" && continue
    connected_device="yes"
    break
done < <(_btctl devices Connected)

if [[ $connected_device == "yes" ]]; then
    echo -n '󰂯 '
else
    echo -n '󰂲 '
fi
