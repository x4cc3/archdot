#!/usr/bin/env bash

# vpn.sh - VPN status for Waybar (JSON output)
# Shows VPN state in the bar and keeps the IP in the tooltip/copy action.

INTERFACES=("tun0" "tun1" "wg0" "wg1" "proton0" "nordlynx")

get_vpn_ip() {
    for iface in "${INTERFACES[@]}"; do
        if ip link show "$iface" &>/dev/null; then
            local ip
            ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}')
            if [[ -n "$ip" ]]; then
                printf '%s' "$ip"
                return 0
            fi
        fi
    done
}

get_vpn_status() {
    for iface in "${INTERFACES[@]}"; do
        if ip link show "$iface" &>/dev/null; then
            local ip
            ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}')
            if [[ -n "$ip" ]]; then
                jq -nc \
                    --arg text "vpn $iface" \
                    --arg tooltip "Connected via $iface\nIP: $ip" \
                    '{text: $text, tooltip: $tooltip, class: "connected"}'
                return 0
            fi
        fi
    done
    jq -nc '{text: "vpn off", tooltip: "No VPN connected", class: "disconnected"}'
}

case "$1" in
    copy) get_vpn_ip | wl-copy -n ;;
    *) get_vpn_status ;;
esac
