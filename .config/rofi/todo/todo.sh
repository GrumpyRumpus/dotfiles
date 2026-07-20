#!/usr/bin/env bash
# vim:ft=bash
# ══════════════════════════════════════════════════════════════════════════════
# Rofi Todo Manager  —  front-end for ~/TODO.md (single source of truth)
#
# Lists every open item from ~/TODO.md as its own entry. Actions run through
# todo.py, which edits ~/TODO.md / ~/DONE.md and commits to ~/.todo.git.
#   Done   → moves the item's whole block to ~/DONE.md (mirrored section)
#   Delete → removes the block
#   Open   → opens ~/TODO.md at the item's line for full context
#   Add    → appends a new item under ## Inbox
# ══════════════════════════════════════════════════════════════════════════════

DIR="$(dirname "$(readlink -f "$0")")"
PY="python3 $DIR/todo.py"
ROFI="rofi -dmenu -i -p Todo -theme ${DIR}/style.rasi"
EDITOR_CMD="${EDITOR:-nvim}"
TERMINAL="${TERMINAL:-kitty}"
TODO_MD="$HOME/TODO.md"

open_at() {                          # open TODO.md at a given line, detached
    local line="$1"
    setsid "$TERMINAL" --class todo-edit -e "$EDITOR_CMD" "+${line}" "$TODO_MD" \
        >/dev/null 2>&1 &
}

item_actions() {
    local item="$1" action line
    action=$(printf '%s\n' "󰄬  Done" "  Open" "  Delete" "  Back" | $ROFI)
    case "$action" in
        *"Done")   $PY done   "$item" ;;
        *"Open")   line=$($PY line "$item"); open_at "$line"; exit 0 ;;
        *"Delete") $PY delete "$item" ;;
    esac
}

add_task() {
    local task
    if command -v zenity >/dev/null 2>&1; then
        task=$(zenity --entry --title="New Task" --text="Enter task:" 2>/dev/null)
    else
        task=$(printf '' | rofi -dmenu -p "New task" -theme "${DIR}/style.rasi")
    fi
    [[ -n "$task" ]] && $PY add "$task"
}

main_menu() {
    local todos options
    todos=$($PY list)
    options=$(printf '%s\n' "  Add Task" "󰈔  Open TODO.md")
    [[ -n "$todos" ]] && options="$options"$'\n'"$todos"
    printf '%s\n' "$options" | $ROFI
}

while true; do
    chosen=$(main_menu)
    case "$chosen" in
        "")                exit 0 ;;
        *"Add Task")       add_task ;;
        *"Open TODO.md")   open_at 1; exit 0 ;;
        *)                 item_actions "$chosen" ;;
    esac
done
