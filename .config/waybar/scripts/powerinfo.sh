#!/bin/bash

source "$HOME/.config/themes/current/waybar-script-colors.sh" 2>/dev/null
: "${COLOR_ERR:=#f38ba8}"
: "${COLOR_WARN:=#f9e2af}"

if ! command -v nvidia-smi &>/dev/null; then
	printf '{"text": "<span color=\\"%s\\">N/A</span>", "tooltip": "nvidia-smi not found"}\n' "$COLOR_ERR"
	exit 0
fi

out=$(nvidia-smi --query-gpu=power.draw,power.limit,temperature.gpu,fan.speed,utilization.gpu \
	--format=csv,noheader,nounits 2>/dev/null)
if [[ -z "$out" ]]; then
	printf '{"text": "<span color=\\"%s\\">N/A</span>", "tooltip": "nvidia-smi query failed"}\n' "$COLOR_ERR"
	exit 0
fi

IFS=', ' read -r draw limit temp fan util <<< "$out"
draw_int=${draw%.*}
limit_int=${limit%.*}
if [[ -z "$limit_int" || "$limit_int" -eq 0 ]]; then
	pct=0
else
	pct=$(( draw_int * 100 / limit_int ))
fi

if (( pct >= 80 )); then
	color="$COLOR_ERR"
elif (( pct >= 50 )); then
	color="$COLOR_WARN"
else
	color=""
fi

if [[ -n "$color" ]]; then
	text=$(printf "<span color='%s'>󱐥 %dW</span>" "$color" "$draw_int")
else
	text=$(printf "󱐥 %dW" "$draw_int")
fi

tooltip=$(printf 'GPU: %dW / %dW (%d%%)\nTemp: %d°C\nFan:  %d%%\nUtil: %d%%' \
	"$draw_int" "$limit_int" "$pct" "$temp" "$fan" "$util")
tooltip_json=${tooltip//$'\n'/\\n}
printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip_json"
