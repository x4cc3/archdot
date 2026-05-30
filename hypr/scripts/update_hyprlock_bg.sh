#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/wallpaper" >&2
    exit 2
fi

WALLPAPER_PATH="$1"
HYPRLOCK_WALLPAPER_LINK="$HOME/.cache/hyprlock_wallpaper"

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Wallpaper file does not exist: $WALLPAPER_PATH" >&2
    exit 1
fi

mkdir -p "$(dirname "$HYPRLOCK_WALLPAPER_LINK")"
ln -sfn "$WALLPAPER_PATH" "$HYPRLOCK_WALLPAPER_LINK"
