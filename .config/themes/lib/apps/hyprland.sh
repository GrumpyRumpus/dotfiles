#!/bin/bash
# Hyprland theme handler

# Re-export the cursor vars from the freshly applied colors.conf.
#
# Anything the theme script spawns (waybar) is a child of that script, so it
# inherits the invoking SHELL's environment -- not the compositor's. Hyprland's
# `env =` lines only reach processes the compositor itself launches, so without
# this waybar comes back carrying whatever cursor theme the terminal was
# started with, and the cursor changes as you move onto the bar.
export_cursor_env() {
    local colors="$HOME/.config/hypr/appearance/colors.conf"
    [[ -f "$colors" ]] || return 0

    local ctheme csize
    ctheme=$(grep '^\$cursor_theme' "$colors" | sed 's/.*= *//')
    csize=$(grep '^\$cursor_size' "$colors" | sed 's/.*= *//')
    [[ -n "$ctheme" ]] || return 0

    export XCURSOR_THEME="$ctheme"  HYPRCURSOR_THEME="$ctheme"
    export XCURSOR_SIZE="${csize:-24}"  HYPRCURSOR_SIZE="${csize:-24}"
}

apply_hyprland() {
    local theme="$1"
    if copy_to_current "$theme" "hypr-colors.conf"; then
        hyprctl reload &>/dev/null || true
        # Set cursor theme
        if [[ -x "$HOME/.config/hypr/scripts/set-cursor.sh" ]]; then
            "$HOME/.config/hypr/scripts/set-cursor.sh" &>/dev/null
        fi
        report_ok "hyprland"

        # Toggle hyprbars plugin based on decoration style
        local json_palette="$PALETTES_DIR/$theme.json"
        local decoration=$(jq -r '.style.decoration // "none"' "$json_palette" 2>/dev/null)
        local hyprbars_so="/var/cache/hyprpm/wiz/hyprland-plugins/hyprbars.so"
        if [[ "$decoration" == "hyprbars" && -f "$hyprbars_so" ]]; then
            hyprctl plugin load "$hyprbars_so" &>/dev/null
        else
            hyprctl plugin unload "$hyprbars_so" &>/dev/null
        fi
    else
        report_skip "hyprland (no theme file)"
    fi
}

apply_hyprlock()    { apply_simple "$1" "hyprlock-colors.conf" "hyprlock"; }
apply_hyprtoolkit() { apply_simple "$1" "hyprtoolkit.conf"     "hyprtoolkit"; }

