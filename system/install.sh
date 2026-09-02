#!/usr/bin/env bash
# Install the root-owned config under system/etc into /etc.
#
# These files can't live in the normal dotfiles tree: the repo's work-tree is
# $HOME and these belong to root. The layout under system/etc mirrors the real
# destination paths, so installing is a straight copy with the prefix swapped.
#
# Usage:   sudo system/install.sh          # install
#          system/install.sh --diff        # show what differs from live, no root

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/etc"

if [[ ${1:-} == --diff ]]; then
    rc=0
    while IFS= read -r -d '' f; do
        rel="${f#"$SRC"/}"
        if ! diff -q "$f" "/etc/$rel" >/dev/null 2>&1; then
            echo "differs: /etc/$rel"
            diff -u "/etc/$rel" "$f" 2>/dev/null | sed 's/^/  /' || true
            rc=1
        fi
    done < <(find "$SRC" -type f -print0)
    ((rc == 0)) && echo "in sync with /etc"
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo "needs root: sudo $0" >&2
    exit 1
fi

while IFS= read -r -d '' f; do
    rel="${f#"$SRC"/}"
    install -Dm644 "$f" "/etc/$rel"
    echo "installed /etc/$rel"
done < <(find "$SRC" -type f -print0)

sysctl --system >/dev/null
systemctl daemon-reexec

echo
echo "watchdog=$(systemctl show -p RuntimeWatchdogUSec --value) state=$(cat /sys/class/watchdog/watchdog0/state 2>/dev/null)"
sysctl kernel.hardlockup_panic kernel.panic_on_oops kernel.panic
