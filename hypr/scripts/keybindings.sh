#!/bin/bash

rofi -theme ~/.config/rofi/launchers/type-1/style-11.rasi \
  -dmenu \
  -i \
  -markup \
  -eh 2 \
  -replace \
  -p "Keybinds" <<'KEYBINDS'
SUPER + RETURN  -  Terminal (ghostty)
SUPER + W       -  Browser
SUPER + E       -  File manager
SUPER + C       -  VSCode
SUPER + D       -  WebCord
SUPER + A       -  Spotify
SUPER + Q       -  Close active window
SUPER + F       -  Fullscreen
SUPER + T       -  Toggle floating
SUPER + S       -  Toggle split
SUPER + H/J/K/L -  Focus window left/down/up/right
SUPER + SHIFT + H/J/K/L - Move window left/down/up/right
SUPER + P       -  Screenshot menu
Print           -  Area screenshot to clipboard
SHIFT + Print   -  Area screenshot to file
CTRL + Print    -  Fullscreen screenshot to clipboard
SUPER + X       -  Logout menu
SUPER + SPACE   -  Application launcher
ALT + SHIFT     -  Toggle keyboard layout
SUPER + CTRL + H - Show keybindings
SUPER + SHIFT + B - Reload waybar
SUPER + SHIFT + R - Reload Hyprland config
SUPER + CTRL + C - Clipboard manager
SUPER + 1-0     -  Switch workspace 1-10
SUPER + SHIFT + 1-0 - Move window to workspace 1-10
SUPER + mouse wheel - Switch workspace
SUPER + CTRL + Down - Next empty workspace
SUPER + CTRL + W - Random wallpaper
KEYBINDS
