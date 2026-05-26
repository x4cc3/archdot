#!/bin/sh
set -eu

BATTERY="AC"
for BAT in /sys/class/power_supply/BAT*; do
  [ -e "$BAT/capacity" ] || continue
  CAPACITY=$(cat "$BAT/capacity")
  STATUS=$(cat "$BAT/status" 2>/dev/null || echo "Unknown")
  BATTERY="${CAPACITY}% (${STATUS})"
  break
done

LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)
RAM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //')
[ -z "$UPTIME" ] && UPTIME="unknown"

printf "BAT %s | Load %s | RAM %s | %s" "$BATTERY" "$LOAD" "$RAM" "$UPTIME"
