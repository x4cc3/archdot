#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/wallpaper" >&2
    exit 2
fi

WALLPAPER_PATH="$1"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
HYPRLOCK_WALLPAPER_LINK="$HOME/.cache/hyprlock_wallpaper"

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Wallpaper file does not exist: $WALLPAPER_PATH" >&2
    exit 1
fi

if [ ! -f "$HYPRLOCK_CONFIG" ]; then
    echo "Hyprlock config does not exist: $HYPRLOCK_CONFIG" >&2
    exit 1
fi

mkdir -p "$(dirname "$HYPRLOCK_WALLPAPER_LINK")"
ln -sfn "$WALLPAPER_PATH" "$HYPRLOCK_WALLPAPER_LINK"

# Keep hyprlock.conf stable by pointing it at a cache symlink instead of
# rewriting the selected wallpaper path on every wallpaper change.
python - "$HYPRLOCK_CONFIG" "$HYPRLOCK_WALLPAPER_LINK" <<'PY'
from pathlib import Path
import sys

config = Path(sys.argv[1])
wallpaper = sys.argv[2]
lines = config.read_text().splitlines()
in_background = False
updated = False

for index, line in enumerate(lines):
    stripped = line.strip()
    if stripped == "background {":
        in_background = True
        continue
    if in_background and stripped == "}":
        in_background = False
        continue
    if in_background and stripped.startswith("path ="):
        indent = line[:len(line) - len(line.lstrip())]
        desired = f"{indent}path = {wallpaper}"
        if lines[index] != desired:
            lines[index] = desired
            config.write_text("\n".join(lines) + "\n")
        updated = True
        break

if not updated:
    raise SystemExit("No background path found in hyprlock config")
PY
