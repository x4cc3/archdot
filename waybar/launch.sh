#!/bin/bash
#  ____  _             _    __        __          _
# / ___|| |_ __ _ _ __| |_  \ \      / /_ _ _   _| |__   __ _ _ __
# \___ \| __/ _` | '__| __|  \ \ /\ / / _` | | | | '_ \ / _` | '__|
#  ___) | || (_| | |  | |_    \ V  V / (_| | |_| | |_) | (_| | |
# |____/ \__\__,_|_|   \__|    \_/\_/ \__,_|\__, |_.__/ \__,_|_|
#                                           |___/
# by Stephan Raabe (2023)
# -----------------------------------------------------

# Check if waybar-disabled file exists
if [ -f "$HOME/.cache/waybar-disabled" ]; then
  pkill -x waybar 2>/dev/null
  exit 1
fi

# -----------------------------------------------------
# Quit all running waybar instances
# -----------------------------------------------------
pkill -x waybar 2>/dev/null
while pgrep -x waybar >/dev/null; do
  sleep 0.1
done
# -----------------------------------------------------
# Loading the configuration
# -----------------------------------------------------
config_file="config"
style_file="style.css"

waybar -c "$HOME/.config/waybar/$config_file" -s "$HOME/.config/waybar/$style_file" > /tmp/waybar.log 2>&1 &
