#!/usr/bin/env bash

set -u

if ! command -v yay >/dev/null 2>&1; then
    printf 'Error: yay is not installed.\n'
    printf 'Press Enter to close...'
    read -r _
    exit 1
fi

yay -Syu
rc=$?

if [ "$rc" -eq 0 ]; then
    pkill -RTMIN+8 waybar
    exit 0
fi

printf '\nUpdate failed with exit code %s.\n' "$rc"
printf 'Press Enter to close...'
read -r _
exit "$rc"
