#!/bin/bash
# Reconfigure workspaces and waybar based on connected monitors
# Usage: handle-monitors.sh [--listen]
#   --listen: stay running and react to monitor hotplug events

RULES_CONF="$HOME/.config/hypr/environment/rules.conf"
WAYBAR_CONF="$HOME/.config/waybar/config.jsonc"
WAYBAR_TMPL="$HOME/.config/waybar/config.jsonc.template"

# Signature of the monitor set we last applied. A DP link that flaps on
# dpms-off fires monitoradded/monitorremoved repeatedly without the real
# monitor set ever changing; reapplying (and reloading) on each one churns
# wl_output globals and is what makes hyprlock abort. Only do work on a
# genuine change.
LAST_SIG=""

apply_config() {
    local monitors real_monitors monitor_count
    monitors=$(hyprctl monitors -j)
    # HEADLESS-* are Hyprland's fallback outputs, created while the real
    # monitor's DP link is down (lock/DPMS/suspend). Never count them or pin
    # workspaces to them, and remove them once a real monitor is back.
    real_monitors=$(jq '[.[] | select(.name | startswith("HEADLESS") | not)]' <<<"$monitors")
    monitor_count=$(jq 'length' <<<"$real_monitors")

    if [ "$monitor_count" -eq 0 ]; then
        # Only fallback outputs exist (screen asleep): leave rules untouched.
        return
    fi

    local headless sig
    headless=$(jq -r '.[].name | select(startswith("HEADLESS"))' <<<"$monitors")
    sig=$(jq -r '[.[].name] | sort | join(",")' <<<"$real_monitors")

    # Nothing to clean up and the same real monitors as last time: no-op.
    if [ -z "$headless" ] && [ "$sig" = "$LAST_SIG" ]; then
        return
    fi

    if [ -n "$headless" ]; then
        while read -r m; do
            [ -n "$m" ] && hyprctl output remove "$m"
        done <<<"$headless"
    fi

    # Removing fallbacks was the only change: don't rewrite configs or reload.
    if [ "$sig" = "$LAST_SIG" ]; then
        return
    fi
    LAST_SIG="$sig"

    # ---- Hyprland workspace rules ----
    # Remove existing workspace assignments between markers
    sed -i '/^# >>WORKSPACE_ASSIGNMENTS<</,/^# <<WORKSPACE_ASSIGNMENTS>>/d' "$RULES_CONF"

    {
        echo "# >>WORKSPACE_ASSIGNMENTS<<"
        if [ "$monitor_count" -eq 1 ]; then
            echo "# Single monitor: all workspaces on primary"
            local mon
            mon=$(jq -r '.[0].name' <<<"$real_monitors")
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

    # ---- Waybar persistent-workspaces ----
    local tmpfile
    tmpfile=$(mktemp)
    if [ "$monitor_count" -eq 1 ]; then
        local mon
        mon=$(jq -r '.[0].name' <<<"$real_monitors")
        printf '"persistent-workspaces": {\n      "%s": [1, 2, 3, 4, 5]\n    },' "$mon" > "$tmpfile"
    else
        printf '"persistent-workspaces": {\n      "eDP-1": [1, 3, 5, 7, 9],\n      "HDMI-A-1": [2, 4, 6, 8, 10]\n    },' > "$tmpfile"
    fi

    # Replace persistent-workspaces block in both config and template
    for conf in "$WAYBAR_CONF" "$WAYBAR_TMPL"; do
        [ -f "$conf" ] || continue
        perl -0777 -i -pe '
            BEGIN { local $/; open my $fh, "<", "'"$tmpfile"'"; $rep = <$fh>; chomp $rep; }
            s/"persistent-workspaces":\s*\{[^}]*\},/$rep/s
        ' "$conf"
    done
    rm -f "$tmpfile"

    # Reload
    hyprctl reload
    killall -SIGUSR2 waybar 2>/dev/null
}

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
