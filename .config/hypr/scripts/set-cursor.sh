#!/bin/bash
# Set cursor theme based on current theme

COLORS_CONF="$HOME/.config/hypr/appearance/colors.conf"

if [[ -f "$COLORS_CONF" ]]; then
    # Extract cursor_theme from colors.conf
    cursor_theme=$(grep '^\$cursor_theme' "$COLORS_CONF" | sed 's/.*= *//')
    cursor_size=$(grep '^\$cursor_size' "$COLORS_CONF" | sed 's/.*= *//' || echo "24")

    if [[ -n "$cursor_theme" ]]; then
        size="${cursor_size:-24}"

        # Compositor-drawn cursor (desktop, and any surface that sets none).
        hyprctl setcursor "$cursor_theme" "$size"

        # GTK clients on Wayland take their cursor from xdg-desktop-portal-gtk,
        # which proxies these gsettings keys — NOT gtk-3.0/settings.ini. Leave
        # these unset and waybar falls back to 'default' -> Adwaita, so the whole
        # cursor theme flips the moment you hover a clickable widget.
        if command -v gsettings &>/dev/null; then
            gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"
            gsettings set org.gnome.desktop.interface cursor-size "$size"
        fi

        # XWayland/Qt apps read XCURSOR_* from the env instead. Hyprland 0.56 has
        # no runtime env setter (`hyprctl setenv` is not a request), so those are
        # declared in environment/theme.conf where $cursor_theme is in scope.
    fi
fi
