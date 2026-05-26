#!/usr/bin/env bash

threshold_green=0
threshold_yellow=25
threshold_red=100

errors=()

if command -v checkupdates >/dev/null 2>&1; then
    arch_err=$(mktemp)
    arch_out=$(checkupdates 2>"$arch_err")
    arch_rc=$?
    arch_msg=$(<"$arch_err")
    rm -f "$arch_err"

    if [ "$arch_rc" -ne 0 ] && [ -n "$arch_msg" ]; then
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
    aur_rc=$?
    aur_msg=$(<"$aur_err")
    rm -f "$aur_err"

    if [ "$aur_rc" -ne 0 ] && [ -n "$aur_msg" ]; then
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
fi

jq -nc \
    --arg text "$text" \
    --arg alt "$updates" \
    --arg tooltip "$tooltip" \
    --arg class "$css_class" \
    '{text: $text, alt: $alt, tooltip: $tooltip, class: $class}'
