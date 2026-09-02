#!/bin/bash

CACHE="${XDG_RUNTIME_DIR:-/tmp}/ddc-brightness"
ICONS=(󱩎 󱩏 󱩐 󱩑 󱩒 󱩓 󱩔 󱩕 󱩖)
DDC_OPTS=(--sleep-multiplier 0.1 --noverify)

fetch_ddc() {
  local out
  out=$(ddcutil "${DDC_OPTS[@]}" getvcp 10 2>/dev/null) || return 1
  [[ $out =~ current\ value\ =\ +([0-9]+) ]] && echo "${BASH_REMATCH[1]}"
}

# True when nothing is awake to talk to: every monitor is dpms-off, or
# Hyprland reports no outputs at all (link down mid-retrain).
monitor_asleep() {
  local mons
  mons=$(hyprctl monitors -j 2>/dev/null) || return 1
  jq -e 'length == 0 or all(.[]; .dpmsStatus == false)' <<<"$mons" >/dev/null 2>&1
}

read_value() {
  local now age val
  now=$(date +%s)
  if [[ -f "$CACHE" ]]; then
    age=$(( now - $(stat -c %Y "$CACHE") ))
    val=$(cat "$CACHE")
    if [[ -n "$val" ]] && { (( age < 60 )) || monitor_asleep; }; then
      echo "$val"
      return
    fi
  fi
  # Never probe a sleeping panel. DDC/CI traffic to a monitor in DPMS standby
  # can drop the DP link; Hyprland then recycles the wl_output global and every
  # client bound to it dies (hyprlock, waybar, awww, the portals).
  monitor_asleep && return 1
  val=$(fetch_ddc) || return 1
  echo "$val" > "$CACHE"
  echo "$val"
}

val=$(read_value) || {
  printf '{"text": "N/A", "tooltip": "DDC unavailable"}\n'
  exit 0
}

idx=$(( val * ${#ICONS[@]} / 101 ))
(( idx >= ${#ICONS[@]} )) && idx=$(( ${#ICONS[@]} - 1 ))

printf '{"text": "%s %d%%", "tooltip": "Monitor brightness: %d%%"}\n' \
  "${ICONS[$idx]}" "$val" "$val"
