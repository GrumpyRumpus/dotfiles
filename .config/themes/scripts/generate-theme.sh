#!/bin/bash
# Theme generator script
# Usage: ./generate-theme.sh <theme-name>
# Generates theme config files from templates using the specified palette

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/lib/config.sh"
source "$LIB_DIR/utils.sh"

if [[ -z "$1" ]]; then
    echo "Usage: $0 <theme-name>"
    echo "Available themes:"
    for f in "$PALETTES_DIR"/*.json; do
        basename "$f" .json
    done
    exit 1
fi

THEME_NAME="$1"
PALETTE_FILE="$PALETTES_DIR/$THEME_NAME.json"
OUTPUT_DIR="$GENERATED_DIR/$THEME_NAME"

if [[ ! -f "$PALETTE_FILE" ]]; then
    echo "Error: Palette file not found: $PALETTE_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Load JSON palette and resolve color references
declare -A COLORS
load_palette_colors COLORS "$PALETTE_FILE"

# Load style settings with defaults
export STYLE_CORNER_RADIUS=$(jq -r '.style.corner_radius // 3' "$PALETTE_FILE")
export STYLE_BORDER_WIDTH=$(jq -r '.style.border_width // 1' "$PALETTE_FILE")
export STYLE_GAPS_IN=$(jq -r '.style.gaps_in // 5' "$PALETTE_FILE")
export STYLE_GAPS_OUT=$(jq -r '.style.gaps_out // 10' "$PALETTE_FILE")
export STYLE_DECORATION=$(jq -r '.style.decoration // "none"' "$PALETTE_FILE")
export STYLE_BAR=$(jq -r '.style.bar // "rounded"' "$PALETTE_FILE")
export STYLE_WAYBAR=$(jq -r '.style.waybar // "rounded"' "$PALETTE_FILE")

# Map waybar style to separator characters
case "$STYLE_WAYBAR" in
    angular)
        export WAYBAR_SEP_LEFT=$'\ue0b2'
        export WAYBAR_SEP_RIGHT=$'\ue0b0'
        ;;
    flame)
        export WAYBAR_SEP_LEFT=$'\ue0c2 '
        export WAYBAR_SEP_RIGHT=$'\ue0c0 '
        ;;
    pixels)
        export WAYBAR_SEP_LEFT=$'\ue0c5 '
        export WAYBAR_SEP_RIGHT=$'\ue0c4 '
        ;;
    waveform)
        export WAYBAR_SEP_LEFT=$'\ue0ca '
        export WAYBAR_SEP_RIGHT=$'\ue0c8 '
        ;;
    slashes)
        export WAYBAR_SEP_LEFT=$'\ue0bc'
        export WAYBAR_SEP_RIGHT=$'\ue0bc'
        ;;
    boxy)
        export WAYBAR_SEP_LEFT=' '
        export WAYBAR_SEP_RIGHT=' '
        ;;
    rounded|*)
        export WAYBAR_SEP_LEFT=$'\ue0b6'
        export WAYBAR_SEP_RIGHT=$'\ue0b4'
        ;;
esac

# When both separators use the same glyph, one set of separators needs its fg/bg
# swapped since the glyph fills the opposite side. Which set depends on whether
# the left or right variant is used. window#waybar prefix for higher specificity.
WAYBAR_SEPARATOR_CSS=""
if [[ "$WAYBAR_SEP_LEFT" == "$WAYBAR_SEP_RIGHT" && "$STYLE_WAYBAR" != "boxy" ]]; then
    # Detect which variant: left-variant glyphs (odd codepoints) need right-sep swaps,
    # right-variant glyphs (even codepoints) need left-sep swaps.
    sep_byte=$(printf '%s' "$WAYBAR_SEP_LEFT" | xxd -p | tail -c 3 | head -c 2)
    sep_last=$((16#$sep_byte))
    if (( sep_last % 2 == 0 )); then
        # Right variant for both: swap left-position separators
        read -r -d '' WAYBAR_SEPARATOR_CSS << 'SEPCSS' || true
/* Same-direction separator overrides: swap fg/bg on left-position separators.
   Uses window#waybar prefix for higher specificity than style.css rules. */
window#waybar #custom-left-ws-workspaces { color: @main-bg; background: @workspaces; padding-left: 0; }
window#waybar #custom-left-bar-fans { color: @main-bg; background: @module1-bg; border-radius: 0; }
window#waybar #custom-left-fans-temp { color: @module1-bg; background: @module2-bg; }
window#waybar #custom-left-temp-gpu { color: @module2-bg; background: @module3-bg; }
window#waybar #custom-left-gpu-memory { color: @module3-bg; background: @module4-bg; }
window#waybar #custom-left-memory-cpu { color: @module4-bg; background: @module5-bg; }
window#waybar #custom-leftin-cpu-idle { color: @module5-bg; background: @main-bg; }
window#waybar #custom-left-idle-center { color: @main-bg; background: @idle-bg; }
window#waybar #custom-left-cava-audio { color: @main-bg; background: @pulseaudio; }
window#waybar #custom-left-audio-backlight { color: @pulseaudio; background: @backlight; }
window#waybar #custom-left-backlight-battery { color: @backlight; background: @battery; }
window#waybar #custom-leftin-battery-power { color: @battery; background: @main-bg; }
SEPCSS
    else
        # Left variant for both: swap right-position separators
        read -r -d '' WAYBAR_SEPARATOR_CSS << 'SEPCSS' || true
/* Same-direction separator overrides: swap fg/bg on right-position separators.
   Uses window#waybar prefix for higher specificity than style.css rules. */
window#waybar #custom-right-workspaces-window { color: @main-bg; background: @workspaces; }
window#waybar #custom-right-center-clock { color: @main-bg; background: @idle-bg; }
window#waybar #custom-rightin-clock-time { color: @module5-bg; background: @main-bg; }
window#waybar #custom-right-time-date { color: @module4-bg; background: @module5-bg; }
window#waybar #custom-right-date-pomodoro { color: @module3-bg; background: @module4-bg; }
window#waybar #custom-right-pomodoro-bluetooth { color: @module2-bg; background: @module3-bg; }
window#waybar #custom-right-bluetooth-wifi { color: @module1-bg; background: @module2-bg; }
window#waybar #custom-right-wifi-end { color: @main-bg; background: @module1-bg; }
window#waybar #custom-left-bar-fans { border-radius: 0; }
SEPCSS
    fi
fi
export WAYBAR_SEPARATOR_CSS

# Load font settings with defaults
export FONT_FAMILY=$(jq -r '.font.family // "FiraCode Nerd Font"' "$PALETTE_FILE")
export FONT_SIZE=$(jq -r '.font.size // 11' "$PALETTE_FILE")

# Export theme metadata
export THEME_NAME
THEME_DESCRIPTION=$(jq -r '.description // ""' "$PALETTE_FILE")
export THEME_DESCRIPTION="${THEME_DESCRIPTION:-$THEME_NAME theme}"

# Cursor theme name from palette, defaulting to the <theme>-cursors convention.
# Lets a palette point at an externally-installed cursor set whose name doesn't
# match the theme (e.g. catppuccin -> catppuccin-mocha-dark-cursors).
CURSOR_THEME=$(jq -r '.cursor // empty' "$PALETTE_FILE")
export CURSOR_THEME="${CURSOR_THEME:-$THEME_NAME-cursors}"
export CURSOR_SIZE=$(jq -r '.cursor_size // 24' "$PALETTE_FILE")

# Relative luminance (ITU-R BT.709) of #rrggbb, as 0-1000.
color_luminance() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    echo $(( (2126 * r + 7152 * g + 722 * b) / 2550 ))
}

# Icon set follows the palette background -- a light base needs the light
# Papirus variant or the icons vanish into it. Override per palette with
# .icon_theme. This reproduces every hand-written choice across the 16 themes.
GTK_ICON_THEME=$(jq -r '.icon_theme // empty' "$PALETTE_FILE")
if [[ -z "$GTK_ICON_THEME" ]]; then
    _base=$(jq -r '.colors.base // "#000000"' "$PALETTE_FILE")
    if [[ $(color_luminance "$_base") -gt 500 ]]; then
        GTK_ICON_THEME="Papirus-Light"
    else
        GTK_ICON_THEME="Papirus-Dark"
    fi
fi
export GTK_ICON_THEME

# Optional, inert metadata: nothing reads these yet, but theme.conf has always
# carried them and build-catppuccin-retheme.sh expects the file to exist.
export THEME_SHADER=$(jq -r '.shader // empty' "$PALETTE_FILE")
export QT_COLOR_SCHEME=$(jq -r '.qt_color_scheme // empty' "$PALETTE_FILE")

# Get MODULE_FG values for contrast calculation
MODULE_FG="${COLORS[module_fg]}"
MODULE_FG_LIGHT="${COLORS[module_fg_light]}"

# Function to get contrasting foreground color based on background luminance
get_contrast_fg() {
    local bg_color="$1"
    local lum=$(hex_luminance "$bg_color")
    if [[ $lum -gt $LUMINANCE_THRESHOLD ]]; then
        echo "$MODULE_FG"
    else
        echo "$MODULE_FG_LIGHT"
    fi
}

# Export all colors as environment variables (uppercase)
for key in "${!COLORS[@]}"; do
    upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
    value="${COLORS[$key]}"
    export "$upper_key=$value"
    export "${upper_key}_NOHASH=${value#\#}"
    export "${upper_key}_RGB=$(hex_to_rgb "$value")"
done

# Load and resolve gradient
readarray -t GRADIENT_REFS < <(jq -r '.gradient[]' "$PALETTE_FILE")
declare -a GRADIENT
for ref in "${GRADIENT_REFS[@]}"; do
    if [[ "$ref" == \#* ]]; then
        GRADIENT+=("$ref")
    else
        resolved="${COLORS[$ref]}"
        GRADIENT+=("${resolved:-$ref}")
    fi
done

# Export gradient variables
export GRADIENT_LEN="${#GRADIENT[@]}"
for i in "${!GRADIENT[@]}"; do
    value="${GRADIENT[$i]}"
    export "GRADIENT_$i=$value"
    export "GRADIENT_${i}_NOHASH=${value#\#}"
    export "GRADIENT_${i}_RGB=$(hex_to_rgb "$value")"
    # Auto-contrast foreground for this gradient color
    fg_color=$(get_contrast_fg "$value")
    export "GRADIENT_FG_$i=$fg_color"
    export "GRADIENT_FG_${i}_RGB=$(hex_to_rgb "$fg_color")"
done

# Build hyprland active border value from style.border flag
STYLE_BORDER=$(jq -r '.style.border // "solid"' "$PALETTE_FILE")
if [[ "$STYLE_BORDER" == "gradient" ]]; then
    border_parts=()
    for i in $(seq 0 9); do
        nohash_var="GRADIENT_${i}_NOHASH"
        border_parts+=("rgb(${!nohash_var})")
    done
    export HYPR_ACTIVE_BORDER="${border_parts[*]} 45deg"
else
    export HYPR_ACTIVE_BORDER="rgba(${ACCENT_NOHASH}FF)"
fi

# Build list of variables to substitute
VARS='$THEME_NAME $THEME_DESCRIPTION $CURSOR_THEME $CURSOR_SIZE $GTK_ICON_THEME $THEME_SHADER $QT_COLOR_SCHEME'

# Add all color variables (uppercase versions)
for key in "${!COLORS[@]}"; do
    upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
    VARS="$VARS \$$upper_key \$${upper_key}_NOHASH \$${upper_key}_RGB"
done

# Add gradient variables
VARS="$VARS \$GRADIENT_LEN"
for i in $(seq 0 9); do
    VARS="$VARS \$GRADIENT_$i \$GRADIENT_${i}_NOHASH \$GRADIENT_${i}_RGB"
    VARS="$VARS \$GRADIENT_FG_$i \$GRADIENT_FG_${i}_RGB"
done

# Add style variables
VARS="$VARS \$STYLE_CORNER_RADIUS \$STYLE_BORDER_WIDTH \$STYLE_GAPS_IN \$STYLE_GAPS_OUT \$STYLE_DECORATION \$STYLE_BAR \$STYLE_WAYBAR \$WAYBAR_SEP_LEFT \$WAYBAR_SEP_RIGHT \$WAYBAR_SEPARATOR_CSS \$HYPR_ACTIVE_BORDER"

# Add font variables
VARS="$VARS \$FONT_FAMILY \$FONT_SIZE"

# Generate each config file from template
echo "Generating $THEME_NAME theme..."

for template in "$TEMPLATES_DIR"/*.tmpl; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .tmpl)
        # Skip fsh.ini - handled separately below
        [[ "$filename" == "fsh.ini" ]] && continue
        # Check for override in templates/overrides/<theme>/ first, then in output dir
        override=""
        if [[ -f "$TEMPLATES_DIR/overrides/$THEME_NAME/$filename.override" ]]; then
            override="$TEMPLATES_DIR/overrides/$THEME_NAME/$filename.override"
        elif [[ -f "$OUTPUT_DIR/$filename.override" ]]; then
            override="$OUTPUT_DIR/$filename.override"
        fi
        output="$OUTPUT_DIR/$filename"

        if [[ -n "$override" ]]; then
            # Use override file directly (still run envsubst for color variables)
            echo "  -> $filename (override)"
            envsubst "$VARS" < "$override" > "$output"
        else
            # Use template
            echo "  -> $filename"
            envsubst "$VARS" < "$template" > "$output"
        fi
        # Make shell scripts executable
        [[ "$filename" == *.sh ]] && chmod +x "$output"
    fi
done

# Append hyprbars plugin config if decoration style requests it (skip if override already includes it)
if [[ "$STYLE_DECORATION" == "hyprbars" ]] && ! grep -q "hyprbars" "$OUTPUT_DIR/hypr-colors.conf" 2>/dev/null; then
    cat >> "$OUTPUT_DIR/hypr-colors.conf" <<EOF

# Hyprbars (window title bars)
plugin {
    hyprbars {
        bar_height = 18
        bar_color = rgb(${ACCENT_NOHASH})
        bar_text_size = 11
        bar_text_font = ${FONT_FAMILY}
        col.text = rgb(ffffff)
        bar_part_of_window = true
        bar_precedence_over_border = true

        hyprbars-button = rgb(c0c0c0), 13, 󰖭, hyprctl dispatch killactive
        hyprbars-button = rgb(c0c0c0), 13, 󰖯, hyprctl dispatch fullscreen 1
        hyprbars-button = rgb(c0c0c0), 13, 󰖰, hyprctl dispatch movetospecialnamed minimize
    }
}
EOF
    echo "  -> hypr-colors.conf (+ hyprbars)"
fi

# Generate fsh theme (fast-syntax-highlighting)
if [[ -f "$TEMPLATES_DIR/fsh.ini.tmpl" ]]; then
    FSH_OUTPUT="$OUTPUT_DIR/fsh"
    mkdir -p "$FSH_OUTPUT"
    echo "  -> fsh/$THEME_NAME.ini"
    envsubst "$VARS" < "$TEMPLATES_DIR/fsh.ini.tmpl" > "$FSH_OUTPUT/$THEME_NAME.ini"
fi

# Generate dunst icons from templates
DUNST_ICONS_TMPL="$TEMPLATES_DIR/dunst-icons"
if [[ -d "$DUNST_ICONS_TMPL" ]]; then
    ICONS_OUTPUT="$OUTPUT_DIR/dunst-icons"
    mkdir -p "$ICONS_OUTPUT"
    echo "  -> dunst-icons/"
    for template in "$DUNST_ICONS_TMPL"/*.svg.tmpl; do
        if [[ -f "$template" ]]; then
            filename=$(basename "$template" .tmpl)
            envsubst "$VARS" < "$template" > "$ICONS_OUTPUT/$filename"
        fi
    done
fi

# Generate Stylus userstyles
STYLUS_TMPL="$TEMPLATES_DIR/stylus"
if [[ -d "$STYLUS_TMPL" ]]; then
    STYLUS_OUTPUT="$OUTPUT_DIR/stylus"
    mkdir -p "$STYLUS_OUTPUT"
    echo "  -> stylus/"
    for template in "$STYLUS_TMPL"/*.user.less.tmpl; do
        if [[ -f "$template" ]]; then
            filename=$(basename "$template" .tmpl)
            envsubst "$VARS" < "$template" > "$STYLUS_OUTPUT/$filename"
        fi
    done
    # Bundle into importable JSON
    if [[ -x "$SCRIPTS_DIR/bundle-styles.py" ]]; then
        echo "  -> stylus-bundle.json"
        "$SCRIPTS_DIR/bundle-styles.py" "$THEME_NAME" > /dev/null
    fi
fi

# Build GTK + Kvantum themes (idempotent; required for apply step to find them
# at ~/.themes/<theme>/ and ~/.config/Kvantum/<theme>/)
if [[ -x "$SCRIPT_DIR/build-gtk-theme.sh" ]]; then
    "$SCRIPT_DIR/build-gtk-theme.sh" "$THEME_NAME" >/dev/null 2>&1 \
        && echo "  -> gtk theme (~/.themes/$THEME_NAME/)" \
        || echo "  -> gtk theme skipped (no base installed)"
fi
if [[ -x "$SCRIPT_DIR/build-kvantum-theme.sh" ]]; then
    "$SCRIPT_DIR/build-kvantum-theme.sh" "$THEME_NAME" >/dev/null 2>&1 \
        && echo "  -> kvantum theme (~/.config/Kvantum/$THEME_NAME/)" \
        || echo "  -> kvantum theme skipped (no base installed)"
fi
# Build the recolored cursor theme (-> ~/.local/share/icons/<theme>-cursors), unless
# the palette pins an external cursor via .cursor. Only the build-cursors.sh path
# (and bulk regenerate-all.sh) produced these before, so single-theme generates
# silently shipped configs referencing a cursor theme that didn't exist.
if [[ -z "$(jq -r '.cursor // empty' "$PALETTE_FILE")" && -x "$SCRIPT_DIR/build-cursors.sh" ]]; then
    "$SCRIPT_DIR/build-cursors.sh" "$THEME_NAME" >/dev/null 2>&1 \
        && echo "  -> cursor theme (~/.local/share/icons/$CURSOR_THEME/)" \
        || echo "  -> cursor theme skipped (build failed)"
fi

# Assemble starship.toml (format block + base modules + all palette blocks)
if [[ -x "$SCRIPT_DIR/build-starship.sh" ]]; then
    "$SCRIPT_DIR/build-starship.sh" "$THEME_NAME" >/dev/null 2>&1 \
        && echo "  -> starship.toml" \
        || echo "  -> starship.toml skipped (build failed)"
fi

echo "Done! Generated files in: $OUTPUT_DIR"
