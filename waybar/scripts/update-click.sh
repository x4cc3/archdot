#!/usr/bin/env bash

ws=$(hyprctl activeworkspace -j | jq -r '.id')
hyprctl dispatch exec "[workspace $ws] ghostty -e $HOME/.config/waybar/scripts/run-update.sh"
