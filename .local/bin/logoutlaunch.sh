#!/bin/bash

# Check if wlogout is already running, and terminate if so
if pgrep -x "wlogout" >/dev/null; then
  pkill -x "wlogout"
  exit 0
fi

config="$HOME/.config/wlogout"
layout="${config}/layout"
style="${config}/style.css"

# Detect monitor resolution and scaling.
#
# scale_factor is the scale x100 (100 = 1.0). This used to strip the dot out of
# "1.00" with sed, but jq prints the float 1.0 as plain "1", so the sed became a
# no-op and scale_factor came out as 1 instead of 100 -- margins 100x too big.
# GTK keeps margins in an int16, so 1920*30 overflowed G_MAXINT16 and wlogout
# segfaulted instead of opening. Let jq do the arithmetic; formatting can't bite.
read -r screen_width screen_height scale_factor < <(
  hyprctl -j monitors |
    jq -r '.[] | select(.focused==true) | "\(.width) \(.height) \(.scale * 100 | round)"'
)

if [[ -z "$screen_width" || -z "$screen_height" ]]; then
  echo "logoutlaunch: no focused monitor reported by hyprctl" >&2
  exit 1
fi
[[ -n "$scale_factor" && "$scale_factor" -gt 0 ]] || scale_factor=100

# Outer margin to center the grid
margin_tb=$((screen_height * 30 / scale_factor))
margin_lr=$((screen_width * 30 / scale_factor))

# Safety net: a margin wider than the screen is always wrong, and overflowing
# GTK's int16 crashes rather than erroring. Keep it bounded and usable.
((margin_tb > screen_height / 2)) && margin_tb=$((screen_height / 3))
((margin_lr > screen_width / 2)) && margin_lr=$((screen_width / 3))

# Substitute variables in the style template
style_content=$(envsubst <"$style")

# Launch wlogout — 3 columns, 2 rows, centered with outer margins
wlogout -b 3 -c 10 -r 10 \
  -T "$margin_tb" -B "$margin_tb" \
  -L "$margin_lr" -R "$margin_lr" \
  --layout "${layout}" --css <(echo "${style_content}") --protocol layer-shell
