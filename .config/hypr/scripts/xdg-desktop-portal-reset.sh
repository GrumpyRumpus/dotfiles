#!/bin/bash
# Re-point the portal stack at the current compositor instance.
#
# Do NOT launch the portal binaries directly. Their D-Bus activation files in
# /usr/share/dbus-1/services/ all carry SystemdService=, so activation is routed
# through the systemd user manager. A bare `/usr/lib/xdg-desktop-portal &` fork
# squats the bus name, and the real unit then dies with
#   Couldn't create the dbus connection (Failed to request bus name (File exists))
# Worse, a bare fork belongs to no unit, so nothing stops it when the session
# ends -- it survives logout and wedges the portal stack of the next session.
#
# xdg-desktop-portal-hyprland.service has ConditionEnvironment=WAYLAND_DISPLAY,
# so the activation environment must be populated before we start anything.
# Hyprland's exec-once entries fire concurrently rather than in file order, so
# wait for the variable instead of assuming the export already ran.

UNITS=(
    xdg-desktop-portal.service
    xdg-desktop-portal-gtk.service
    xdg-desktop-portal-hyprland.service
)

for _ in $(seq 1 50); do
    systemctl --user show-environment | grep -q '^WAYLAND_DISPLAY=' && break
    sleep 0.2
done

systemctl --user stop "${UNITS[@]}"
systemctl --user reset-failed "${UNITS[@]}" 2>/dev/null

# Backend first: xdg-desktop-portal probes its implementations at startup and
# caches the result, so starting it before the backend owns its bus name yields
# "Not providing Settings portal: No working backend".
systemctl --user start xdg-desktop-portal-hyprland.service
systemctl --user start xdg-desktop-portal.service
