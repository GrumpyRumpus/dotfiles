#!/bin/bash
# Reconfigure workspaces and waybar based on connected monitors
# Usage: handle-monitors.sh [--listen | --waybar-only]
#   --listen:      stay running and react to monitor hotplug events
#   --waybar-only: only rewrite waybar's persistent-workspaces, no hyprctl reload
#                  (used by the theme system after it overwrites config.jsonc)

RULES_CONF="$HOME/.config/hypr/environment/rules.conf"
WAYBAR_CONF="$HOME/.config/waybar/config.jsonc"

monitor_count() { hyprctl monitors -j | jq 'length'; }
primary_monitor() { hyprctl monitors -j | jq -r '.[0].name'; }

# ---- Hyprland workspace rules ----
apply_workspace_rules() {
    local count="$1"

    # Remove existing workspace assignments between markers
    sed -i '/^# >>WORKSPACE_ASSIGNMENTS<</,/^# <<WORKSPACE_ASSIGNMENTS>>/d' "$RULES_CONF"

    {
        echo "# >>WORKSPACE_ASSIGNMENTS<<"
        if [ "$count" -eq 1 ]; then
            echo "# Single monitor: all workspaces on primary"
            local mon
            mon=$(primary_monitor)
            for i in $(seq 1 10); do
                if [ "$i" -le 5 ]; then
                    echo "workspace = $i, monitor:$mon, persistent:true"
                else
                    echo "workspace = $i, monitor:$mon"
                fi
            done
        else
            echo "# Dual monitor: odd on eDP-1, even on HDMI-A-1"
            echo "workspace = 1, monitor:eDP-1"
            echo "workspace = 2, monitor:HDMI-A-1"
            echo "workspace = 3, monitor:eDP-1"
            echo "workspace = 4, monitor:HDMI-A-1"
            echo "workspace = 5, monitor:eDP-1"
            echo "workspace = 6, monitor:HDMI-A-1, persistent:true"
            echo "workspace = 7, monitor:eDP-1, persistent:true"
            echo "workspace = 8, monitor:HDMI-A-1, persistent:true"
            echo "workspace = 9, monitor:eDP-1, persistent:true"
            echo "workspace = 10, monitor:HDMI-A-1, persistent:true"
        fi
        echo "# <<WORKSPACE_ASSIGNMENTS>>"
    } >> "$RULES_CONF"
}

# ---- Waybar persistent-workspaces ----
# Only the live config is patched. Templates keep a static single-monitor
# default; whatever regenerates config.jsonc must call --waybar-only after.
apply_waybar_workspaces() {
    local count="$1"
    [ -f "$WAYBAR_CONF" ] || return 0

    local tmpfile
    tmpfile=$(mktemp)
    if [ "$count" -eq 1 ]; then
        printf '"persistent-workspaces": {\n      "%s": [1, 2, 3, 4, 5]\n    },' "$(primary_monitor)" > "$tmpfile"
    else
        printf '"persistent-workspaces": {\n      "eDP-1": [1, 3, 5, 7, 9],\n      "HDMI-A-1": [2, 4, 6, 8, 10]\n    },' > "$tmpfile"
    fi

    perl -0777 -i -pe '
        BEGIN { local $/; open my $fh, "<", "'"$tmpfile"'"; $rep = <$fh>; chomp $rep; }
        s/"persistent-workspaces":\s*\{[^}]*\},/$rep/s
    ' "$WAYBAR_CONF"
    rm -f "$tmpfile"
}

apply_config() {
    local count
    count=$(monitor_count)
    apply_workspace_rules "$count"
    apply_waybar_workspaces "$count"

    # Reload
    hyprctl reload
    killall -SIGUSR2 waybar 2>/dev/null
}

# ---- Entry point ----
if [ "$1" = "--waybar-only" ]; then
    apply_waybar_workspaces "$(monitor_count)"
    exit 0
fi

# Run once immediately
apply_config

# If --listen, stay running and react to monitor events
if [ "$1" = "--listen" ]; then
    socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
        case "$line" in
            monitoradded*|monitorremoved*)
                sleep 1  # brief settle
                apply_config
                ;;
        esac
    done
fi
