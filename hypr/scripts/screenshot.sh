#!/usr/bin/env bash
#  ____                               _           _
# / ___|  ___ _ __ ___  ___ _ __  ___| |__   ___ | |_
# \___ \ / __| '__/ _ \/_ \ '_ \ / __| '_ \ / _ \| __|
#  ___) | (__| | |  __/  __/ | | \__ \ | | | (_) | |_
# |____/ \___|_|  \___|\___|_| |_|___/_| |_|\___/ \__|
#
#
# by Stephan Raabe (2023)
# -----------------------------------------------------

DIR="$HOME/Pictures/Screenshots/"
NAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FILE="$DIR$NAME"

mkdir -p "$DIR"

option1="Area"
option2="Area + edit"
option3="Fullscreen"
option4="Fullscreen (delay 3 sec)"
option5="Fullscreen + edit"

options="$option1\n$option2\n$option3\n$option4\n$option5"

choice=$(echo -e "$options" | rofi -dmenu -replace -theme ~/.config/rofi/launchers/type-1/glass-screenshot.rasi -i -no-show-icons -l 5 -p "screenshot")

finish_copy() {
    wl-copy --type image/png < "$FILE"
    notify-send "Screenshot saved" "$NAME copied to clipboard"
}

case $choice in
    $option1)
        geometry=$(slurp) || exit 0
        sleep 0.12
        grim -g "$geometry" "$FILE" || exit 1
        finish_copy
    ;;
    $option2)
        geometry=$(slurp) || exit 0
        sleep 0.12
        grim -g "$geometry" "$FILE" || exit 1
        finish_copy
        swappy -f "$FILE"
    ;;
    $option3)
        grim "$FILE" || exit 1
        finish_copy
    ;;
    $option4)
        sleep 3
        grim "$FILE" || exit 1
        finish_copy
    ;;
    $option5)
        grim "$FILE" || exit 1
        finish_copy
        swappy -f "$FILE"
    ;;
esac
