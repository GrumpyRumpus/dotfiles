#!/bin/bash
# Waybar theme handler

apply_waybar() {
    local theme="$1"
    local palette_path="$2"
    local applied=false

    if copy_to_current "$theme" "waybar.css"; then
        applied=true
    fi

    copy_to_current "$theme" "waybar-script-colors.sh" 2>/dev/null

    # Copy themed waybar config if it exists
    local theme_config="$GENERATED_DIR/$theme/waybar-config.jsonc"
    if [[ -f "$theme_config" ]]; then
        cp "$theme_config" "$HOME/.config/waybar/config.jsonc"
        # The theme config carries a static single-monitor default, so re-apply
        # the monitor-aware persistent-workspaces it just overwrote
        local monitors="$HOME/.config/hypr/scripts/handle-monitors.sh"
        [[ -x "$monitors" ]] && command -v hyprctl &>/dev/null && "$monitors" --waybar-only
        applied=true
    fi

    if $applied; then
        # Full restart needed for structural changes
        if pgrep -x waybar >/dev/null; then
            pkill -x waybar 2>/dev/null
            sleep 0.3
            waybar &>/dev/null &
            disown
        fi
        report_ok "waybar"
    else
        report_skip "waybar (no theme file)"
    fi
}
