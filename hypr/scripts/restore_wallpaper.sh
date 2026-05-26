#!/usr/bin/env bash
set -euo pipefail

CURRENT_WALLPAPER_CACHE="$HOME/.cache/current_wallpaper"
DEFAULT_WALLPAPER_DIR="$HOME/Pictures"
AWWW_FLAGS=(--transition-type none --transition-duration 0 --resize crop)

sleep 1

set_wallpaper() {
    local wallpaper="$1"
    "$HOME/.config/hypr/scripts/update_hyprlock_bg.sh" "$wallpaper" || true
    exec awww img "$wallpaper" "${AWWW_FLAGS[@]}"
}

if [ -f "$CURRENT_WALLPAPER_CACHE" ]; then
    cached_wallpaper=$(<"$CURRENT_WALLPAPER_CACHE")
    if [ -f "$cached_wallpaper" ]; then
        set_wallpaper "$cached_wallpaper"
    fi
fi

if awww restore >/dev/null 2>&1; then
    exit 0
fi

first_wallpaper=""
while IFS= read -r -d $'\0' wallpaper; do
    first_wallpaper="$wallpaper"
    break
done < <(find "$DEFAULT_WALLPAPER_DIR" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -type f -print0 | sort -z)

if [ -n "$first_wallpaper" ]; then
    set_wallpaper "$first_wallpaper"
fi
