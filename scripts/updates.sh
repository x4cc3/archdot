#!/bin/bash

# -----------------------------------------------------
# Define thresholds for color indicators
# -----------------------------------------------------

threshold_green=0
threshold_yellow=25
threshold_red=100

# -----------------------------------------------------
# Calculate available updates pacman and aur
# -----------------------------------------------------

errors=()

if command -v checkupdates >/dev/null 2>&1; then
    arch_err=$(mktemp)
    arch_out=$(checkupdates 2>"$arch_err")
    arch_status=$?
    arch_msg=$(<"$arch_err")
    rm -f "$arch_err"

    # checkupdates exits with 2 when there are no updates, so only treat it as
    # a failure when it produced an actual error message.
    if [ "$arch_status" -ne 0 ] && [ -n "$arch_msg" ]; then
        updates_arch=0
        errors+=("pacman check failed")
    else
        updates_arch=$(printf '%s\n' "$arch_out" | sed '/^$/d' | wc -l)
    fi
else
    updates_arch=0
    errors+=("checkupdates not installed")
fi

if command -v yay >/dev/null 2>&1; then
    aur_err=$(mktemp)
    aur_out=$(yay -Qua 2>"$aur_err")
    aur_status=$?
    rm -f "$aur_err"

    if [ "$aur_status" -ne 0 ]; then
        updates_aur=0
        errors+=("AUR check failed")
    else
        updates_aur=$(printf '%s\n' "$aur_out" | sed '/^$/d' | wc -l)
    fi
else
    updates_aur=0
    errors+=("yay not installed")
fi

updates=$((updates_arch + updates_aur))

# -----------------------------------------------------
# Testing
# -----------------------------------------------------

# Overwrite updates with numbers for testing
# updates=100

# test JSON output
# printf '{"text": "0", "alt": "0", "tooltip": "0 Updates", "class": "red"}'
# exit

# -----------------------------------------------------
# Output in JSON format for Waybar Module custom-updates
# -----------------------------------------------------

css_class="green"

if [ "$updates" -gt "$threshold_yellow" ]; then
    css_class="yellow"
fi

if [ "$updates" -gt "$threshold_red" ]; then
    css_class="red"
fi

tooltip="${updates} Updates\\npacman: ${updates_arch}\\nAUR: ${updates_aur}"

if [ "${#errors[@]}" -gt 0 ]; then
    css_class="yellow"
    text="${updates}!"
    tooltip="${tooltip}\\nWarning: ${errors[*]}"
elif [ "$updates" -gt "$threshold_green" ]; then
    text="$updates"
else
    text="0"
    css_class="green"
fi

printf '{"text": "%s", "alt": "%s", "tooltip": "%s", "class": "%s"}' "$text" "$updates" "$tooltip" "$css_class"
