#!/bin/bash

# Pastel Win98 Statusline for Claude Code

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

# Pastel Win98 colors
fg_text=$'\033[38;2;74;74;94m'

reset=$'\033[0m'

# Powerline separators (angular)
sep_right=$'\uE0B0'

# Color block definitions (pastel palette - arranged by hue)
bg_block1=$'\033[48;2;244;165;165m'   # Coral (red)
fg_block1=$'\033[38;2;244;165;165m'
bg_block2=$'\033[48;2;247;200;165m'   # Peach (orange)
fg_block2=$'\033[38;2;247;200;165m'
bg_block3=$'\033[48;2;247;232;165m'   # Yellow
fg_block3=$'\033[38;2;247;232;165m'
bg_block4=$'\033[48;2;165;232;184m'   # Mint (green)
fg_block4=$'\033[38;2;165;232;184m'
bg_block5=$'\033[48;2;165;212;212m'   # Teal (cyan)
fg_block5=$'\033[38;2;165;212;212m'
bg_block6=$'\033[48;2;165;184;244m'   # Blue
fg_block6=$'\033[38;2;165;184;244m'
bg_block7=$'\033[48;2;184;196;224m'   # Periwinkle
fg_block7=$'\033[38;2;184;196;224m'
bg_block8=$'\033[48;2;200;196;244m'   # Lavender (purple)
fg_block8=$'\033[38;2;200;196;244m'
bg_block9=$'\033[48;2;212;165;212m'   # Mauve (magenta)
fg_block9=$'\033[38;2;212;165;212m'
bg_block10=$'\033[48;2;244;192;224m'  # Pink
fg_block10=$'\033[38;2;244;192;224m'

# Semantic colors (darker for readability)
fg_added=$'\033[38;2;74;144;104m'     # Dark mint green
fg_removed=$'\033[38;2;192;96;96m'    # Dark coral red

# Build powerline statusline with color blocks (hue gradient)

# Section 1: Arch icon (coral)
echo -ne "${fg_text}${bg_block1} \U000f011b ${reset}"
echo -ne "${fg_block1}${bg_block2}${sep_right}${reset}"

# Section 2: Directory path (peach)
echo -ne "${fg_text}${bg_block2} ${dir_first}/${dir_second} ${reset}"
echo -ne "${fg_block2}${bg_block3}${sep_right}${reset}"

# Section 3: Git branch (yellow)
if [ -n "$git_branch" ]; then
  git_info="${git_branch}${git_dirty}"
  [ "$git_ahead" -gt 0 ] && git_info+=" +${git_ahead}"
  [ "$git_behind" -gt 0 ] && git_info+=" -${git_behind}"
  echo -ne "${fg_text}${bg_block3} \U0000f126 ${git_info} ${reset}"
else
  echo -ne "${fg_text}${bg_block3} \U0000f126 --- ${reset}"
fi
echo -ne "${fg_block3}${bg_block4}${sep_right}${reset}"

# Section 4: Model name (mint)
echo -ne "${fg_text}${bg_block4} ${model_name} ${reset}"
echo -ne "${fg_block4}${bg_block5}${sep_right}${reset}"

# Section 5: Output style (teal)
echo -ne "${fg_text}${bg_block5} ${output_style} ${reset}"
echo -ne "${fg_block5}${bg_block6}${sep_right}${reset}"

# Section 6: Tokens in/out (blue)
echo -ne "${fg_text}${bg_block6} IN:$(abbreviate_num $input_tokens) OUT:$(abbreviate_num $output_tokens) ${reset}"
echo -ne "${fg_block6}${bg_block7}${sep_right}${reset}"

# Section 7: Context percentage (periwinkle) - color text based on usage
if [ "$context_percent" -ge 80 ]; then
  ctx_text_color=$'\033[38;2;180;80;80m'
elif [ "$context_percent" -ge 50 ]; then
  ctx_text_color=$'\033[38;2;180;140;60m'
else
  ctx_text_color="$fg_text"
fi
echo -ne "${ctx_text_color}${bg_block7} CTX:${context_percent}% ${reset}"
echo -ne "${fg_block7}${bg_block8}${sep_right}${reset}"

# Section 8: Lines changed (lavender) - green for added, red for removed
echo -ne "${fg_added}${bg_block8} +${lines_added}${reset}"
echo -ne "${fg_text}${bg_block8}/${reset}"
echo -ne "${fg_removed}${bg_block8}-${lines_removed} ${reset}"
echo -ne "${fg_block8}${bg_block9}${sep_right}${reset}"

# Section 9: Cost (mauve)
echo -ne "${fg_text}${bg_block9} \$${total_cost} ${reset}"
echo -ne "${fg_block9}${bg_block10}${sep_right}${reset}"

# Section 10: Duration (pink)
echo -ne "${fg_text}${bg_block10} ${duration} ${reset}"

# End cap
echo -ne "${fg_block10}${reset}${sep_right}${reset}"
