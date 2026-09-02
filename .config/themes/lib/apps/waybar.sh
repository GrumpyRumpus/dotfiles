#!/bin/bash
# Waybar theme handler

# Restart waybar to pick up structural config changes.
#
# Where waybar.service is running, systemd owns the process: killing it here
# gets it restarted a second later anyway, and the bare instance this used to
# spawn would leave a duplicate bar on screen. Only fall back to kill+relaunch
# when nothing is supervising it.
restart_waybar() {
    if systemctl --user is-active --quiet waybar.service 2>/dev/null; then
        systemctl --user restart waybar.service
        return
    fi

    if pgrep -x waybar >/dev/null; then
        pkill -x waybar 2>/dev/null
        sleep 0.3
        waybar &>/dev/null &
        disown
    fi
}

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
        applied=true
    fi

    if $applied; then
        # Full restart needed for structural changes
        restart_waybar
        report_ok "waybar"
    else
        report_skip "waybar (no theme file)"
    fi
}
