#!/usr/bin/env bash
# PreToolUse(Bash) hook: long bench/training runs must be wrapped in
# systemd-inhibit (suspend killed an overnight bench 2026-05-30) and
# ideally systemd-run -p MemoryMax (endgame solver OOM'd the desktop 2026-07-09).
# Escape hatch for short smoke runs: prefix the command with CLAUDE_SMOKE=1

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Only care about actual python invocations of the heavy scripts,
# not greps/edits that merely mention them.
if ! printf '%s' "$cmd" | grep -qE 'python[0-9.]*[^|;&]*(bench_monotype|bench_value_net|selfplay|rebuild_ab|train_)[[:alnum:]_]*\.py'; then
  exit 0
fi

# Already wrapped, or explicitly marked as a quick smoke run.
if printf '%s' "$cmd" | grep -qE 'systemd-inhibit|CLAUDE_SMOKE=1'; then
  exit 0
fi

reason='Long bench/training runs must be wrapped so suspend/OOM cannot kill them. Rewrite as: systemd-inhibit --mode=block systemd-run --user --scope -p MemoryMax=20G --same-dir bash -c "<original command>". For a short smoke run (<5 min) prefix the command with CLAUDE_SMOKE=1 instead.'

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
