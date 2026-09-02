#!/bin/bash
# Firefox theme handler — copies color CSS + ensures @import in userChrome

apply_firefox() {
    local theme="$1"
    local src="$GENERATED_DIR/$theme/firefox-colors.css"
    local applied=0

    if [[ ! -f "$src" ]]; then
        report_skip "firefox (no theme file)"
        return
    fi

    # Profiles live under the legacy path OR the newer XDG path. Firefox >=~140
    # uses ~/.config/mozilla for fresh profiles when ~/.mozilla doesn't exist.
    local profile_roots=("$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox")

    for profile_dir in "${profile_roots[@]}"; do
        [[ -d "$profile_dir" ]] || continue
        for profile in "$profile_dir"/*.default*; do
            [[ -d "$profile" ]] || continue

            local chrome_dir="$profile/chrome"
            mkdir -p "$chrome_dir"
            cp "$src" "$chrome_dir/theme-colors.css"

            # Ensure userChrome.css imports the theme colors
            local userchrome="$chrome_dir/userChrome.css"
            if [[ ! -f "$userchrome" ]] || ! grep -q "theme-colors.css" "$userchrome" 2>/dev/null; then
                if [[ -f "$userchrome" ]]; then
                    local existing=$(cat "$userchrome")
                    echo -e '@import "theme-colors.css";\n'"$existing" > "$userchrome"
                else
                    echo '@import "theme-colors.css";' > "$userchrome"
                fi
            fi

            # userChrome.css is only loaded when this pref is on; pin it via user.js
            local userjs="$profile/user.js"
            if [[ ! -f "$userjs" ]] || ! grep -qF 'legacyUserProfileCustomizations.stylesheets' "$userjs" 2>/dev/null; then
                echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$userjs"
            fi

            ((++applied))
        done
    done

    if [[ $applied -gt 0 ]]; then
        report_ok "firefox (restart to apply)"
    else
        report_skip "firefox (no profiles found)"
    fi
}
