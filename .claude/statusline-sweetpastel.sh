#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Function to abbreviate large numbers (e.g., 150000 -> 150k)
abbreviate_num() {
  local num=$1
  if [ "$num" -ge 1000000 ]; then
    printf "%.1fm" "$(echo "$num / 1000000" | bc -l)"
  elif [ "$num" -ge 1000 ]; then
    printf "%.1fk" "$(echo "$num / 1000" | bc -l)"
  else
    echo "$num"
  fi
}

# Extract all JSON values in one jq call for performance
eval "$(echo "$input" | jq -r '
  @sh "dir=\(.workspace.current_dir // "")",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "model_name=\(.model.display_name // "Unknown")",
  @sh "context_size=\(.context_window.context_window_size // 200000)",
  @sh "input_tokens=\((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0))",
  @sh "output_tokens=\(.context_window.current_usage.output_tokens // 0)",
  @sh "lines_added=\(.cost.total_lines_added // 0)",
  @sh "lines_removed=\(.cost.total_lines_removed // 0)",
  @sh "output_style=\(.output_style.name // "default")",
  @sh "total_cost=\(.cost.total_cost_usd // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)"
')"

# Trim model name to just the family (e.g. "Opus 4.6 (1M context)" -> "Opus")
model_name="${model_name%% [0-9]*}"

# Get split directory parts
dir_first=$(~/.local/bin/directory-split first "$dir")
dir_second=$(~/.local/bin/directory-split second "$dir")


# Get git info if in a git repo
git_branch=''
git_dirty=''
git_ahead=0
git_behind=0
if git -C "$cwd" rev-parse --git-dir &>/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo 'HEAD')
  # Check for uncommitted changes
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_dirty='*'
  fi
  # Get ahead/behind counts
  git_status=$(git -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
  if [ -n "$git_status" ]; then
    git_ahead=$(echo "$git_status" | cut -f1)
    git_behind=$(echo "$git_status" | cut -f2)
  fi
fi

# Format cost
total_cost=$(printf "%.2f" $total_cost)

# Calculate context usage percentage
if [ "$context_size" -gt 0 ]; then
  context_percent=$(awk "BEGIN {printf \"%.0f\", ($input_tokens / $context_size) * 100}")
else
  context_percent=0
fi

# Format duration (convert ms to minutes:seconds)
duration_sec=$((duration_ms / 1000))
duration_min=$((duration_sec / 60))
duration_sec=$((duration_sec % 60))
duration=$(printf "%dm%02ds" $duration_min $duration_sec)

# SweetPastel colors - Rainbow spread
# Foreground colors
fg_text=$'\033[38;2;255;222;222m'      # #ffdede
fg_mantle=$'\033[38;2;22;26;30m'       # #161a1e
fg_base=$'\033[38;2;27;31;35m'         # #1b1f23
fg_surface0=$'\033[38;2;22;26;30m'     # #161a1e
fg_maroon=$'\033[38;2;237;168;168m'    # #eda8a8 - pastel red (0°)
fg_peach=$'\033[38;2;240;201;168m'     # #f0c9a8 - orange (30°)
fg_yellow=$'\033[38;2;237;232;168m'    # #ede8a8 - yellow (55°)
fg_green=$'\033[38;2;168;237;186m'     # #a8edba - green (135°)
fg_sky=$'\033[38;2;168;223;237m'       # #a8dfed - cyan (190°)
fg_sapphire=$'\033[38;2;168;201;237m'  # #a8c9ed - sky blue (210°)
fg_blue=$'\033[38;2;168;184;237m'      # #a8b8ed - blue (230°)
fg_lavender=$'\033[38;2;186;168;237m'  # #baa8ed - indigo (260°)
fg_mauve=$'\033[38;2;217;168;237m'     # #d9a8ed - purple (285°)
fg_pink=$'\033[38;2;237;168;201m'      # #eda8c9 - pink (330°)
fg_subtext0=$'\033[38;2;238;239;240m'  # #eeeff0

# Background colors
bg_surface0=$'\033[48;2;22;26;30m'     # #161a1e
bg_maroon=$'\033[48;2;237;168;168m'    # #eda8a8 - pastel red
bg_peach=$'\033[48;2;240;201;168m'     # #f0c9a8 - orange
bg_yellow=$'\033[48;2;237;232;168m'    # #ede8a8 - yellow
bg_green=$'\033[48;2;168;237;186m'     # #a8edba - green
bg_sky=$'\033[48;2;168;223;237m'       # #a8dfed - cyan
bg_sapphire=$'\033[48;2;168;201;237m'  # #a8c9ed - sky blue
bg_blue=$'\033[48;2;168;184;237m'      # #a8b8ed - blue
bg_lavender=$'\033[48;2;186;168;237m'  # #baa8ed - indigo
bg_mauve=$'\033[48;2;217;168;237m'     # #d9a8ed - purple
bg_pink=$'\033[48;2;237;168;201m'      # #eda8c9 - pink
bg_subtext0=$'\033[48;2;238;239;240m'  # #eeeff0

reset=$'\033[0m'

# Powerline separators (rounded)
sep_left=$'\ue0b6'  # U+E0B6 left-facing semicircle (used at the start)
sep_right=$'\ue0b4' # U+E0B4 right-facing semicircle (used between sections)

# Build statusline with spread out values
# Start with surface0 section (Arch icon)
echo -ne "${fg_surface0}${sep_left}${reset}"
echo -ne "${fg_text}${bg_surface0}\U000f011b${reset}"

# Maroon section (first part of path)
echo -ne "${fg_surface0}${bg_maroon}${sep_right}${reset}"
echo -ne "${fg_mantle}${bg_maroon}${dir_first} ${reset}"
echo -ne "${fg_maroon}${bg_peach}${sep_right}${reset}"

# Peach section (second part of path)
echo -ne "${fg_base}${bg_peach}${dir_second} ${reset}"
echo -ne "${fg_peach}${bg_yellow}${sep_right}${reset}"

# Git branch (yellow background, mantle text)
if [ -n "$git_branch" ]; then
  git_info="${git_branch}${git_dirty}"
  [ "$git_ahead" -gt 0 ] && git_info+=" ↑${git_ahead}"
  [ "$git_behind" -gt 0 ] && git_info+=" ↓${git_behind}"
  echo -ne "${fg_mantle}${bg_yellow} \U0000f126 ${git_info} ${reset}"
else
  echo -ne "${fg_mantle}${bg_yellow} \U0000f126 — ${reset}"
fi
echo -ne "${fg_yellow}${bg_green}${sep_right}${reset}"

# Model name (green background, base text)
echo -ne "${fg_base}${bg_green} \U0000ee9c [${model_name}] ${reset}"
echo -ne "${fg_green}${bg_sky}${sep_right}${reset}"

# Output style (sky background, mantle text)
echo -ne "${fg_mantle}${bg_sky} \U0000f075 ${output_style} ${reset}"
echo -ne "${fg_sky}${bg_sapphire}${sep_right}${reset}"

# Tokens in/out (sapphire background, mantle text)
echo -ne "${fg_mantle}${bg_sapphire} \U0000f063 $(abbreviate_num $input_tokens) \U0000f062 $(abbreviate_num $output_tokens) ${reset}"
echo -ne "${fg_sapphire}${bg_blue}${sep_right}${reset}"

# Context percentage (blue background, mantle text)
echo -ne "${fg_mantle}${bg_blue} \U0000f200 ${context_percent}% ${reset}"
echo -ne "${fg_blue}${bg_lavender}${sep_right}${reset}"

# Lines changed (lavender background, mantle text)
echo -ne "${fg_mantle}${bg_lavender} \U0000f040 +${lines_added} -${lines_removed} ${reset}"
echo -ne "${fg_lavender}${bg_mauve}${sep_right}${reset}"

# Cost (mauve background, mantle text)
echo -ne "${fg_mantle}${bg_mauve} \U0000f155 ${total_cost} ${reset}"
echo -ne "${fg_mauve}${bg_pink}${sep_right}${reset}"

# Duration (pink background, mantle text)
echo -ne "${fg_mantle}${bg_pink} \U0000f017 ${duration} ${reset}"
echo -ne "${fg_pink}${bg_subtext0}${sep_right}${reset}"

# Decorative ending transition (subtext0 to background)
echo -ne "${fg_subtext0}${sep_right}${reset}"
