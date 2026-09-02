#!/usr/bin/env bash
# PostToolUse(Edit|MultiEdit) hook: enforce the TODO/DONE split.
# ~/TODO.md holds OPEN items only; a completed block MOVES to ~/DONE.md under
# the mirrored heading. Ticking an item done (- [x]) IN PLACE in TODO.md is the
# mistake this catches. Fires only when an edit INCREASES the [x] count, so
# pre-existing done items (e.g. the caster section) and edits that REMOVE
# ticked items (the correct move-to-DONE action) never trigger it.

input=$(cat)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
case "$fp" in
  */TODO.md|TODO.md) ;;
  *) exit 0 ;;
esac

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
if [ "$tool" = "MultiEdit" ]; then
  oldtext=$(printf '%s' "$input" | jq -r '[.tool_input.edits[].old_string] | join("\n")')
  newtext=$(printf '%s' "$input" | jq -r '[.tool_input.edits[].new_string] | join("\n")')
elif [ "$tool" = "Edit" ]; then
  oldtext=$(printf '%s' "$input" | jq -r '.tool_input.old_string // ""')
  newtext=$(printf '%s' "$input" | jq -r '.tool_input.new_string // ""')
else
  exit 0  # Write is a full rewrite (no reliable pre-image here); skip
fi

count() { printf '%s' "$1" | grep -oiE '^[[:space:]]*- \[x\]' | wc -l; }
oldc=$(count "$oldtext")
newc=$(count "$newtext")

if [ "$newc" -gt "$oldc" ]; then
  echo "TODO/DONE split: this edit added a completed-item tick (- [x]) to ~/TODO.md, which holds OPEN items only. MOVE the finished block to ~/DONE.md under the mirrored heading and REMOVE it from TODO.md, rather than ticking it in place. (Inline ~~strikethrough~~ roadmap markers and pre-existing [x] items are fine — this only fires on a net-new tick.)" >&2
  exit 2
fi
exit 0
