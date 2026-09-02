#!/bin/bash
# Build cursor themes from catppuccin SVG sources
# Uses our palette colors for fill and outline

# Don't exit on error - we want to build all themes even if some fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$(dirname "$SCRIPT_DIR")"
PALETTES_DIR="$THEMES_DIR/palettes"
CURSOR_OUTPUT_DIR="$HOME/.local/share/icons"
# Source and scratch live under the cache, NOT /tmp: /tmp is tmpfs, so a reboot
# wipes the clone, and the next build renders nothing while still creating the
# alias symlinks -- every theme silently becomes 33 dangling links.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/theme-cursors"
CURSOR_SRC_DIR="$CACHE_DIR/catppuccin-cursors"
SVG_SRC_DIR="$CURSOR_SRC_DIR/src/svgs"
BUILD_DIR="$CACHE_DIR/build"

# Cursor sizes to render
SIZES=(24 32 48 64 72)

# Fetch the SVG source, once, and prove it is usable before anything renders.
#
# generate-theme.sh calls this script per theme and regenerate-all.sh fans those
# out in parallel, so without the lock 16 clones race into one directory and
# leave it half-written. Failures here are fatal on purpose: exiting 0 with no
# SVGs is what silently produced empty cursor themes.
clone_source() {
    mkdir -p "$CACHE_DIR"

    exec 9>"$CACHE_DIR/.clone.lock"
    flock 9

    if [[ ! -d "$CURSOR_SRC_DIR/.git" ]]; then
        echo "Cloning catppuccin cursors source into $CURSOR_SRC_DIR..."
        rm -rf "$CURSOR_SRC_DIR"
        if ! git clone --depth 1 https://github.com/catppuccin/cursors.git "$CURSOR_SRC_DIR"; then
            echo "Error: failed to clone the cursor SVG source" >&2
            rm -rf "$CURSOR_SRC_DIR"
            exit 1
        fi
    fi

    flock -u 9

    if ! compgen -G "$SVG_SRC_DIR/*.svg" >/dev/null; then
        echo "Error: no SVGs under $SVG_SRC_DIR -- refusing to build empty cursor themes" >&2
        exit 1
    fi
}

# Get color from palette JSON
get_color() {
    local palette="$1"
    local key="$2"
    local color

    color=$(jq -r ".colors.$key // empty" "$palette")

    # If it's a reference to another color, resolve it
    if [[ -n "$color" && ! "$color" =~ ^# ]]; then
        color=$(jq -r ".colors.$color // empty" "$palette")
    fi

    # Strip # prefix and return uppercase
    echo "${color#\#}" | tr '[:lower:]' '[:upper:]'
}

# Blend two hex colors (50/50 mix)
blend_colors() {
    local c1="$1"
    local c2="$2"

    # Extract RGB components
    local r1=$((16#${c1:0:2}))
    local g1=$((16#${c1:2:2}))
    local b1=$((16#${c1:4:2}))

    local r2=$((16#${c2:0:2}))
    local g2=$((16#${c2:2:2}))
    local b2=$((16#${c2:4:2}))

    # Average them
    local r=$(( (r1 + r2) / 2 ))
    local g=$(( (g1 + g2) / 2 ))
    local b=$(( (b1 + b2) / 2 ))

    printf "%02X%02X%02X" "$r" "$g" "$b"
}

# Process SVG - replace placeholder colors
process_svg() {
    local src="$1"
    local dst="$2"
    local fill_color="$3"
    local outline_color="$4"

    # Replace placeholders: FF0000=fill, 00FF00=outline
    sed -e "s/FF0000/$fill_color/gi" \
        -e "s/00FF00/$outline_color/gi" \
        "$src" > "$dst"
}

# Render SVG to PNG at multiple sizes
render_pngs() {
    local svg="$1"
    local out_dir="$2"
    local base_name="$3"

    for size in "${SIZES[@]}"; do
        rsvg-convert -w "$size" -h "$size" "$svg" -o "$out_dir/${base_name}_${size}.png"
    done
}

# Generate xcursor config file
generate_xcursor_config() {
    local png_dir="$1"
    local base_name="$2"
    local config_file="$3"
    local hotspot_x="${4:-0}"
    local hotspot_y="${5:-0}"

    > "$config_file"
    for size in "${SIZES[@]}"; do
        local png="$png_dir/${base_name}_${size}.png"
        if [[ -f "$png" ]]; then
            # Calculate hotspot in pixels
            local xhot=$((size * hotspot_x / 100))
            local yhot=$((size * hotspot_y / 100))
            echo "$size $xhot $yhot $png" >> "$config_file"
        fi
    done
}

# Animated shapes ship as per-frame SVGs (wait-01.svg .. wait-12.svg). One
# Xcursor file holds every frame: repeat the size with a trailing ms delay,
# frames in order. FRAME_TIME matches upstream catppuccin's build.
FRAME_TIME=30

generate_animated_xcursor_config() {
    local png_dir="$1"
    local base_name="$2"
    local config_file="$3"
    local hotspot_x="${4:-0}"
    local hotspot_y="${5:-0}"

    > "$config_file"
    for size in "${SIZES[@]}"; do
        local xhot=$((size * hotspot_x / 100))
        local yhot=$((size * hotspot_y / 100))
        local frame
        for frame in $(ls "$png_dir/${base_name}"-[0-9]*_"${size}".png 2>/dev/null | sort); do
            echo "$size $xhot $yhot $frame $FRAME_TIME" >> "$config_file"
        done
    done
}

# Build cursor theme for a palette
build_cursor_theme() {
    local palette_file="$1"
    local palette_name
    palette_name=$(basename "$palette_file" .json)

    # Skip light themes
    if [[ "$palette_name" == "win98" ]]; then
        echo "Skipping $palette_name (light theme)"
        return
    fi

    echo "Building cursor theme for $palette_name..."

    # Get colors - crust for fill (main body), blend of text+accent for outline
    local fill_color outline_color text_color accent_color
    fill_color=$(get_color "$palette_file" "crust")
    text_color=$(get_color "$palette_file" "text")
    accent_color=$(get_color "$palette_file" "accent")
    outline_color=$(blend_colors "$text_color" "$accent_color")

    if [[ -z "$fill_color" || -z "$outline_color" ]]; then
        echo "  Error: Could not get colors from palette"
        return 1
    fi

    echo "  Fill: #$fill_color, Outline: #$outline_color"

    local theme_name="${palette_name}-cursors"
    local work_dir="$BUILD_DIR/$palette_name"
    local svg_dir="$work_dir/svgs"
    local png_dir="$work_dir/pngs"
    local output_theme="$CURSOR_OUTPUT_DIR/$theme_name"

    # Clean and create directories
    rm -rf "$work_dir" "$output_theme"
    mkdir -p "$svg_dir" "$png_dir" "$output_theme/cursors" "$output_theme/hyprcursors"

    # Process each SVG
    echo "  Processing SVGs..."
    for svg in "$SVG_SRC_DIR"/*.svg; do
        local name
        name=$(basename "$svg" .svg)
        process_svg "$svg" "$svg_dir/$name.svg" "$fill_color" "$outline_color"
    done

    # Render PNGs
    echo "  Rendering PNGs..."
    for svg in "$svg_dir"/*.svg; do
        local name
        name=$(basename "$svg" .svg)
        render_pngs "$svg" "$png_dir" "$name"
    done

    # Build xcursors
    echo "  Building xcursors..."

    # Cursor hotspots (percentage from top-left)
    declare -A HOTSPOTS=(
        ["default"]="6 3"
        ["pointer"]="10 3"
        ["text"]="50 50"
        ["crosshair"]="50 50"
        ["cell"]="50 50"
        ["all-scroll"]="50 50"
        ["col-resize"]="50 50"
        ["row-resize"]="50 50"
        ["size_hor"]="50 50"
        ["size_ver"]="50 50"
        ["size_bdiag"]="50 50"
        ["size_fdiag"]="50 50"
        ["help"]="6 3"
        ["context-menu"]="6 3"
        ["progress"]="6 3"
        ["wait"]="50 50"
        ["zoom-in"]="50 50"
        ["zoom-out"]="50 50"
    )

    local -A built_animated=()
    for svg in "$svg_dir"/*.svg; do
        local name config out_name
        name=$(basename "$svg" .svg)

        # Animated cursors (progress-01 .. wait-12) collapse to one output per
        # base name. Writing per frame leaves `wait`/`progress` nonexistent and
        # their aliases (watch, left_ptr_watch, half-busy) dangling.
        local base_name="${name%-[0-9][0-9]}"
        local animated=false
        [[ "$base_name" != "$name" ]] && animated=true

        if $animated; then
            [[ -n "${built_animated[$base_name]:-}" ]] && continue
            built_animated[$base_name]=1
            out_name="$base_name"
        else
            out_name="$name"
        fi

        # Get hotspot
        local hotspot="${HOTSPOTS[$base_name]:-6 3}"
        local hx="${hotspot%% *}"
        local hy="${hotspot##* }"

        config="$work_dir/xcursor-$out_name.conf"
        if $animated; then
            generate_animated_xcursor_config "$png_dir" "$base_name" "$config" "$hx" "$hy"
        else
            generate_xcursor_config "$png_dir" "$name" "$config" "$hx" "$hy"
        fi

        if [[ -s "$config" ]]; then
            xcursorgen "$config" "$output_theme/cursors/$out_name" 2>/dev/null || true
        fi
        rm -f "$config"
    done

    # Create cursor symlinks
    echo "  Creating symlinks..."
    pushd "$output_theme/cursors" > /dev/null

    # Standard aliases
    for alias in left_ptr arrow top_left_arrow; do ln -sf default "$alias" 2>/dev/null || true; done
    for alias in hand hand2 hand1; do ln -sf pointer "$alias" 2>/dev/null || true; done
    for alias in xterm ibeam; do ln -sf text "$alias" 2>/dev/null || true; done
    for alias in question_arrow whats_this; do ln -sf help "$alias" 2>/dev/null || true; done
    for alias in left_ptr_watch half-busy; do ln -sf progress "$alias" 2>/dev/null || true; done
    ln -sf wait watch 2>/dev/null || true
    for alias in cross tcross; do ln -sf crosshair "$alias" 2>/dev/null || true; done
    for alias in forbidden no-drop; do ln -sf not-allowed "$alias" 2>/dev/null || true; done
    for alias in ew-resize h_double_arrow sb_h_double_arrow; do ln -sf size_hor "$alias" 2>/dev/null || true; done
    for alias in ns-resize v_double_arrow sb_v_double_arrow; do ln -sf size_ver "$alias" 2>/dev/null || true; done
    for alias in nesw-resize fd_double_arrow; do ln -sf size_bdiag "$alias" 2>/dev/null || true; done
    for alias in nwse-resize bd_double_arrow; do ln -sf size_fdiag "$alias" 2>/dev/null || true; done
    for alias in fleur move grabbing closedhand; do ln -sf all-scroll "$alias" 2>/dev/null || true; done
    ln -sf openhand grab 2>/dev/null || true
    ln -sf copy dnd-copy 2>/dev/null || true

    popd > /dev/null

    # Build hyprcursors
    echo "  Building hyprcursors..."
    local hl_dir="$work_dir/hl"
    mkdir -p "$hl_dir/hyprcursors"

    # Create manifest
    cat > "$hl_dir/manifest.hl" << EOF
name = ${theme_name}
description = Cursor theme for ${palette_name}
version = 1.0
cursors_directory = hyprcursors
EOF

    # Create hyprcursor entries for each cursor
    for name in default pointer text help crosshair not-allowed all-scroll size_hor size_ver size_bdiag size_fdiag openhand pencil zoom-in zoom-out; do
        local cursor_dir="$hl_dir/hyprcursors/$name"
        mkdir -p "$cursor_dir"

        # Get hotspot
        local hotspot="${HOTSPOTS[$name]:-6 3}"
        local hx="${hotspot%% *}"
        local hy="${hotspot##* }"
        local hx_frac=$(awk "BEGIN {printf \"%.2f\", $hx/100}")
        local hy_frac=$(awk "BEGIN {printf \"%.2f\", $hy/100}")

        cat > "$cursor_dir/meta.hl" << EOF
resize_algorithm = none
hotspot_x = $hx_frac
hotspot_y = $hy_frac
EOF

        local idx=0
        for size in "${SIZES[@]}"; do
            local png="$png_dir/${name}_${size}.png"
            if [[ -f "$png" ]]; then
                cp "$png" "$cursor_dir/${name}_$(printf '%03d' $idx).png"
                echo "define_size = $size, ${name}_$(printf '%03d' $idx).png" >> "$cursor_dir/meta.hl"
                ((idx++))
            fi
        done
    done

    # Handle animated cursors (progress, wait)
    for base in progress wait; do
        local cursor_dir="$hl_dir/hyprcursors/$base"
        mkdir -p "$cursor_dir"

        local hotspot="${HOTSPOTS[$base]:-50 50}"
        local hx="${hotspot%% *}"
        local hy="${hotspot##* }"
        local hx_frac=$(awk "BEGIN {printf \"%.2f\", $hx/100}")
        local hy_frac=$(awk "BEGIN {printf \"%.2f\", $hy/100}")

        cat > "$cursor_dir/meta.hl" << EOF
resize_algorithm = none
hotspot_x = $hx_frac
hotspot_y = $hy_frac
EOF

        for size in "${SIZES[@]}"; do
            for frame in 01 02 03 04 05 06 07 08 09 10 11 12; do
                local png="$png_dir/${base}-${frame}_${size}.png"
                if [[ -f "$png" ]]; then
                    cp "$png" "$cursor_dir/${base}_${size}_${frame}.png"
                    echo "define_size = $size, ${base}_${size}_${frame}.png, 50" >> "$cursor_dir/meta.hl"
                fi
            done
        done
    done

    # Compile hyprcursor
    local created_dir="$CURSOR_OUTPUT_DIR/theme_${theme_name}"
    rm -rf "$created_dir"
    hyprcursor-util -c "$hl_dir" -o "$CURSOR_OUTPUT_DIR" 2>&1 | tail -1 || true
    if [[ -d "$created_dir" ]]; then
        mv "$created_dir/hyprcursors" "$output_theme/" 2>/dev/null || true
        mv "$created_dir/manifest.hl" "$output_theme/" 2>/dev/null || true
        rm -rf "$created_dir"
    fi

    # Create index.theme
    cat > "$output_theme/index.theme" << EOF
[Icon Theme]
Name=${palette_name^} Cursors
Comment=Custom cursor theme for $palette_name
Inherits=default
EOF

    echo "  Installed to $output_theme"

    # This build's scratch only -- see the cleanup note in main().
    rm -rf "$work_dir"
}

# Main
main() {
    echo "=== Building cursor themes from SVG sources ==="

    # Check dependencies
    for cmd in jq rsvg-convert xcursorgen hyprcursor-util; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: $cmd is required"
            exit 1
        fi
    done

    # Get source SVGs
    clone_source

    # Create output directory
    mkdir -p "$CURSOR_OUTPUT_DIR"

    # Build for specified themes or all
    if [[ $# -gt 0 ]]; then
        # Build only specified themes
        for theme in "$@"; do
            local palette="$PALETTES_DIR/$theme.json"
            if [[ -f "$palette" ]]; then
                build_cursor_theme "$palette"
            else
                echo "Warning: palette '$theme' not found, skipping"
            fi
        done
    else
        # Build for all palettes
        for palette in "$PALETTES_DIR"/*.json; do
            build_cursor_theme "$palette"
        done
    fi

    # Cleanup. Only drop the shared parent if nothing else is still using it --
    # concurrent builds each own a $BUILD_DIR/<theme> subdir, and wiping the
    # parent here deleted their in-progress PNGs mid-render.
    rmdir --ignore-fail-on-non-empty "$BUILD_DIR" 2>/dev/null || true

    echo ""
    echo "=== Done ==="
    echo "Cursor themes installed to $CURSOR_OUTPUT_DIR"
    echo "Set cursor with: hyprctl setcursor <theme-name> 24"
}

main "$@"
