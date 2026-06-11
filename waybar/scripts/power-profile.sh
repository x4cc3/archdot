#!/usr/bin/env bash
# power-profile.sh - Power profile indicator for Waybar

profile=$(powerprofilesctl get)

case "$profile" in
    performance) icon="󰓅" ;;
    balanced)    icon="󰖟" ;;
    power-saver) icon="󰌪" ;;
    *)           icon="?" ;;
esac

jq -nc \
    --arg text "$icon $profile" \
    --arg tooltip "Profile: $profile\nClick to cycle" \
    --arg class "$profile" \
    --arg alt "$profile" \
    '{text: $text, tooltip: $tooltip, class: $class, alt: $alt, interval: 5}'
