#!/bin/bash
# waybar custom/powerdraw — GPU board power.
#
# Source order: discrete AMD (amdgpu hwmon) -> NVIDIA (nvidia-smi) -> placeholder.
#
# The Granite Ridge iGPU also exposes an amdgpu power1_input, but it reports the
# PPT rail at ~0.1 W and does not move with load (measured 2026-09-02: 159 mW
# idle, 110 mW at 100% busy). Showing that would be worse than showing nothing,
# so a card only counts if it exposes power1_cap — a settable board cap that
# discrete Radeons have and the iGPU does not.

source "$HOME/.config/themes/current/waybar-script-colors.sh" 2>/dev/null
: "${COLOR_ERR:=#f38ba8}"
: "${COLOR_WARN:=#f9e2af}"
: "${COLOR_INFO:=#89b4fa}"

emit() { # text tooltip
	local tip=${2//$'\n'/\\n}
	printf '{"text": "%s", "tooltip": "%s"}\n' "$1" "$tip"
	exit 0
}

colorize() { # pct -> color name or empty
	if   (( $1 >= 80 )); then printf '%s' "$COLOR_ERR"
	elif (( $1 >= 50 )); then printf '%s' "$COLOR_WARN"
	fi
}

render() { # draw limit pct temp fan util
	local color text
	color=$(colorize "$3")
	if [[ -n $color ]]; then
		text=$(printf "<span color='%s'>󱐥 %dW</span>" "$color" "$1")
	else
		text=$(printf "󱐥 %dW" "$1")
	fi
	emit "$text" "$(printf 'GPU: %dW / %dW (%d%%)\nTemp: %d°C\nFan:  %s\nUtil: %s' \
		"$1" "$2" "$3" "$4" "$5" "$6")"
}

read_or() { [[ -r $1 ]] && cat "$1" 2>/dev/null || printf '%s' "$2"; }

# ---- discrete AMD ----
for h in /sys/class/hwmon/hwmon*/; do
	[[ $(read_or "$h/name" "") == amdgpu ]] || continue
	[[ -r $h/power1_cap ]] || continue          # iGPU has no cap -> skip it
	raw=$(read_or "$h/power1_average" "")
	[[ -n $raw ]] || raw=$(read_or "$h/power1_input" "")
	[[ $raw =~ ^[0-9]+$ ]] || continue

	cap=$(read_or "$h/power1_cap" 0)
	draw=$(( raw / 1000000 ))
	limit=$(( cap / 1000000 ))
	(( limit > 0 )) && pct=$(( draw * 100 / limit )) || pct=0
	temp=$(( $(read_or "$h/temp1_input" 0) / 1000 ))

	pwm=$(read_or "$h/pwm1" "")
	if [[ $pwm =~ ^[0-9]+$ ]]; then fan="$(( pwm * 100 / 255 ))%"
	else fan="$(read_or "$h/fan1_input" "n/a") RPM"; fi

	busy=$(read_or "$h/device/gpu_busy_percent" "")
	[[ $busy =~ ^[0-9]+$ ]] && util="$busy%" || util="n/a"

	render "$draw" "$limit" "$pct" "$temp" "$fan" "$util"
done

# ---- NVIDIA ----
# With no card present nvidia-smi prints "NVIDIA-SMI has failed ..." on STDOUT,
# not stderr, and exits 9. So 2>/dev/null hides nothing and a -z test passes,
# leaving the error text to be parsed as CSV. Gate on the exit status instead.
if command -v nvidia-smi &>/dev/null &&
   out=$(nvidia-smi --query-gpu=power.draw,power.limit,temperature.gpu,fan.speed,utilization.gpu \
	--format=csv,noheader,nounits 2>/dev/null) &&
   [[ ${out%%,*} =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	IFS=', ' read -r draw limit temp fan util <<< "$out"
	draw=${draw%.*}; limit=${limit%.*}
	(( limit > 0 )) && pct=$(( draw * 100 / limit )) || pct=0
	render "$draw" "$limit" "$pct" "$temp" "${fan}%" "${util}%"
fi

# ---- nothing reports board power ----
emit "<span color='$COLOR_INFO'>󱐥 —</span>" "no discrete GPU installed"
