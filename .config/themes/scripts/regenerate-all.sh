#!/bin/bash
# Regenerate all theme configs from palette files
# Usage: ./regenerate-all.sh [--cursors]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/lib/config.sh"
source "$LIB_DIR/utils.sh"
cd "$SCRIPT_DIR"

BUILD_CURSORS=false
for arg in "$@"; do
    case "$arg" in
        --cursors) BUILD_CURSORS=true ;;
    esac
done

echo "=== Regenerating all themes ==="

# Create temp dir for output
tmpdir=$(mktemp -d)
trap "rm -rf $tmpdir" EXIT

# Generate theme configs in parallel
pids=()
themes=()
for palette in "$THEMES_DIR"/palettes/*.json; do
    [[ ! -f "$palette" ]] && continue
    theme=$(basename "$palette" .json)
    themes+=("$theme")
    ./generate-theme.sh "$theme" > "$tmpdir/$theme.log" 2>&1 &
    pids+=($!)
done

# Wait for all and collect results
failed=()
for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
        failed+=("${themes[$i]}")
    fi
done

# Print gradient blocks for a theme
print_gradient() {
    local palette="$THEMES_DIR/palettes/$1.json"
    [[ ! -f "$palette" ]] && return
    local colors=$(jq -r '.gradient[]' "$palette" 2>/dev/null)
    for color in $colors; do
        # Resolve color references
        if [[ ! "$color" =~ ^# ]]; then
            color=$(jq -r ".colors.$color // \"$color\"" "$palette" 2>/dev/null)
        fi
        [[ "$color" =~ ^# ]] && color_block "$color"
    done
}

# Print summary
for theme in "${themes[@]}"; do
    if [[ " ${failed[*]} " =~ " $theme " ]]; then
        echo "  ✗ $theme"
        echo "--- output ---"
        cat "$tmpdir/$theme.log"
        echo "--------------"
    else
        printf "  ✓ %-12s " "$theme"
        print_gradient "$theme"
        echo ""
        # Per-theme output is only shown on failure, which would bury override
        # drift warnings in the one path that regenerates every theme.
        grep -h "WARNING:" "$tmpdir/$theme.log" 2>/dev/null | sed "s/^/    /"
    fi
done

# starship.toml is assembled per-theme by generate-theme.sh (build-starship.sh)

# Build cursor themes (optional)
if [[ "$BUILD_CURSORS" == true ]]; then
    ./build-cursors.sh > "$tmpdir/cursors.log" 2>&1 && echo "  ✓ cursors" || echo "  ✗ cursors"
fi

echo ""
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "=== Failed: ${failed[*]} ==="
    exit 1
else
    echo "=== Done ==="
fi
