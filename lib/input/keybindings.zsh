#!/usr/bin/env zsh
# Keybinding definitions and ZLE widgets for z-skk

# Enable/disable flag
typeset -g Z_SKK_ENABLED=1

# Enable z-skk
z-skk-enable() {
    Z_SKK_ENABLED=1
    # Future: Update prompt/indicators
}

# Disable z-skk
z-skk-disable() {
    Z_SKK_ENABLED=0
    # Reset any active conversion state
    z-skk-reset-state
    # Future: Update prompt/indicators
}

# Check if input should pass through
z-skk-should-pass-through() {
    # Pass through if disabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        Z_SKK_PASS_THROUGH=1
        return 0
    fi

    # In ASCII mode, everything passes through
    if [[ $Z_SKK_MODE == "ascii" ]]; then
        Z_SKK_PASS_THROUGH=1
        return 0
    fi

    # Default: don't pass through (will be handled by SKK logic)
    Z_SKK_PASS_THROUGH=0
    return 1
}

# Main character input widget
z-skk-self-insert() {
    # Check if functions are loaded
    if ! (( ${+functions[z-skk-should-pass-through]} )) || ! (( ${+functions[z-skk-handle-input]} )); then
        # Functions not loaded yet, pass through
        zle .self-insert
        return
    fi

    # Check if we should pass through
    if z-skk-should-pass-through; then
        # Pass through to default self-insert
        zle .self-insert
        return
    fi

    # Delegate to input handler
    z-skk-handle-input "$KEYS"
}

# Accept line widget (Enter key)
z-skk-accept-line() {
    # Handle special states first
    if z-skk-is-registering; then
        z-skk-registration-input $'\r'
        return
    elif [[ $Z_SKK_CONVERTING -eq 2 ]]; then
        # In candidate selection
        z-skk-confirm-candidate
        return
    elif [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        # In pre-conversion
        z-skk-cancel-conversion
        return
    fi

    # Default behavior
    zle accept-line
}

# Cancel key widget (C-g)
z-skk-keyboard-quit() {
    # Handle special states
    if z-skk-is-registering; then
        z-skk-registration-input $'\x07'
        return
    elif [[ $Z_SKK_CONVERTING -ge 1 ]]; then
        z-skk-cancel-conversion
        return
    fi

    # Default behavior
    zle send-break
}

# Backspace widget
z-skk-backspace() {
    # Handle registration mode
    if z-skk-is-registering; then
        z-skk-registration-input $'\x7f'
        return
    fi

    # Handle conversion modes
    if [[ $Z_SKK_CONVERTING -eq 2 ]]; then
        # In candidate selection mode, go back to pre-conversion
        Z_SKK_CONVERTING=1
        Z_SKK_CANDIDATE_INDEX=0

        # Restore pre-conversion display
        local prefix="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
        LBUFFER="${prefix}▽${Z_SKK_BUFFER}${Z_SKK_OKURIGANA:+*$Z_SKK_OKURIGANA}"
        return
    elif [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        # In pre-conversion mode
        if [[ -n "$Z_SKK_OKURIGANA" ]]; then
            # Remove okurigana first
            Z_SKK_OKURIGANA=""
            local prefix="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
            LBUFFER="${prefix}▽${Z_SKK_BUFFER}"
            return
        elif [[ -n "$Z_SKK_BUFFER" ]]; then
            # Remove last character from buffers
            # Handle multi-byte characters properly
            local last_char="${Z_SKK_BUFFER: -1}"
            Z_SKK_BUFFER="${Z_SKK_BUFFER%?}"

            # Update romaji buffer
            if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
                # Simple heuristic: remove corresponding romaji
                case "$last_char" in
                    あ|ア) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%a}" ;;
                    い|イ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%i}" ;;
                    う|ウ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%u}" ;;
                    え|エ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%e}" ;;
                    お|オ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%o}" ;;
                    か|カ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ka}" ;;
                    き|キ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ki}" ;;
                    く|ク) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ku}" ;;
                    け|ケ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ke}" ;;
                    こ|コ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ko}" ;;
                    が|ガ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ga}" ;;
                    ぎ|ギ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%gi}" ;;
                    ぐ|グ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%gu}" ;;
                    げ|ゲ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ge}" ;;
                    ご|ゴ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%go}" ;;
                    さ|サ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%sa}" ;;
                    し|シ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%si}" ;;
                    す|ス) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%su}" ;;
                    せ|セ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%se}" ;;
                    そ|ソ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%so}" ;;
                    た|タ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ta}" ;;
                    ち|チ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ti}" ;;
                    つ|ツ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%tu}" ;;
                    て|テ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%te}" ;;
                    と|ト) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%to}" ;;
                    な|ナ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%na}" ;;
                    に|ニ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ni}" ;;
                    ぬ|ヌ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%nu}" ;;
                    ね|ネ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ne}" ;;
                    の|ノ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%no}" ;;
                    は|ハ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ha}" ;;
                    ひ|ヒ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%hi}" ;;
                    ふ|フ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%hu}" ;;
                    へ|ヘ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%he}" ;;
                    ほ|ホ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ho}" ;;
                    ま|マ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ma}" ;;
                    み|ミ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%mi}" ;;
                    む|ム) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%mu}" ;;
                    め|メ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%me}" ;;
                    も|モ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%mo}" ;;
                    や|ヤ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ya}" ;;
                    ゆ|ユ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%yu}" ;;
                    よ|ヨ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%yo}" ;;
                    ら|ラ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ra}" ;;
                    り|リ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ri}" ;;
                    る|ル) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ru}" ;;
                    れ|レ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%re}" ;;
                    ろ|ロ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%ro}" ;;
                    わ|ワ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%wa}" ;;
                    を|ヲ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%wo}" ;;
                    ん|ン) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%n}" ;;
                    # For きょ -> kyo etc.
                    ょ|ョ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%o}" ;;
                    ゃ|ャ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%a}" ;;
                    ゅ|ュ) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%u}" ;;
                    # Default: try to remove last character
                    *) Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER%?}" ;;
                esac
            fi

            # Update display
            if [[ -n "$Z_SKK_BUFFER" ]]; then
                local prefix="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
                LBUFFER="${prefix}▽${Z_SKK_BUFFER}"
            else
                # Buffer is empty, cancel conversion
                z-skk-cancel-conversion
            fi
            return
        else
            # Buffer is already empty, cancel conversion
            z-skk-cancel-conversion
            return
        fi
    fi

    # Default backspace behavior
    zle backward-delete-char
}

# Register ZLE widgets
z-skk-register-widgets() {
    # Skip if already registered
    [[ -n "${Z_SKK_WIDGETS_REGISTERED:-}" ]] && return 0

    # Check if zle is available
    if ! (( ${+builtins[zle]} )); then
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "ZLE not available, skipping widget registration"
        return 0
    fi

    # Debug: Check which functions exist
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registering widgets..."

    # Register widgets only if the functions exist
    if (( ${+functions[z-skk-self-insert]} )); then
        zle -N z-skk-self-insert
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-self-insert"
    fi

    if (( ${+functions[z-skk-toggle-kana]} )); then
        zle -N z-skk-toggle-kana
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-toggle-kana"
    else
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Function z-skk-toggle-kana not found!"
    fi

    (( ${+functions[z-skk-ascii-mode]} )) && zle -N z-skk-ascii-mode
    (( ${+functions[z-skk-hiragana-mode]} )) && zle -N z-skk-hiragana-mode
    (( ${+functions[z-skk-katakana-mode]} )) && zle -N z-skk-katakana-mode
    (( ${+functions[z-skk-zenkaku-mode]} )) && zle -N z-skk-zenkaku-mode
    (( ${+functions[z-skk-accept-line]} )) && zle -N z-skk-accept-line
    (( ${+functions[z-skk-keyboard-quit]} )) && zle -N z-skk-keyboard-quit
    (( ${+functions[z-skk-backspace]} )) && zle -N z-skk-backspace

    # Mark as registered
    typeset -g Z_SKK_WIDGETS_REGISTERED=1
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Widget registration complete"
}

# Setup keybindings
z-skk-setup-keybindings() {
    # Skip if already setup
    [[ -n "${Z_SKK_KEYBINDINGS_SETUP:-}" ]] && return 0

    # Ensure widgets are registered first
    z-skk-register-widgets

    # Double-check that widgets were actually registered
    if ! (( ${+widgets[z-skk-self-insert]} )); then
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Warning: widgets not properly registered, aborting keybinding setup"
        return 1
    fi

    # Save original self-insert widget if not already saved
    if ! (( ${+widgets[.self-insert]} )); then
        zle -A self-insert .self-insert
    fi

    # Bind printable characters to our widget
    local c
    # ASCII printable characters (space to ~)
    # Only bind if the widget exists
    if (( ${+widgets[z-skk-self-insert]} )); then
        for c in {' '..'~'}; do
            # Use -- to properly handle special characters like '-'
            bindkey -- "$c" z-skk-self-insert
        done
    else
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Warning: z-skk-self-insert widget not found, skipping character bindings"
    fi

    # Mode switching keys - only bind if widgets exist
    if (( ${+widgets[z-skk-toggle-kana]} )); then
        bindkey "^J" z-skk-toggle-kana    # Toggle hiragana/ascii
    else
        # Debug: widget not found, try to register it
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Widget z-skk-toggle-kana not found during keybinding setup"
        # Try to register the widget if the function exists
        if (( ${+functions[z-skk-toggle-kana]} )); then
            zle -N z-skk-toggle-kana
            bindkey "^J" z-skk-toggle-kana
            (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered and bound z-skk-toggle-kana to ^J"
        fi
    fi
    (( ${+widgets[z-skk-ascii-mode]} )) && bindkey "^L" z-skk-ascii-mode     # Force ASCII mode
    (( ${+widgets[z-skk-zenkaku-mode]} )) && bindkey "^Q" z-skk-zenkaku-mode   # Zenkaku (full-width) mode

    # Special keys - only bind if widgets exist
    (( ${+widgets[z-skk-accept-line]} )) && bindkey "^M" z-skk-accept-line    # Enter
    (( ${+widgets[z-skk-keyboard-quit]} )) && bindkey "^G" z-skk-keyboard-quit  # C-g
    (( ${+widgets[z-skk-backspace]} )) && bindkey "^?" z-skk-backspace        # Backspace
    (( ${+widgets[z-skk-backspace]} )) && bindkey "^H" z-skk-backspace        # Ctrl-H (alternate backspace)

    # Mark as setup
    typeset -g Z_SKK_KEYBINDINGS_SETUP=1
}

# Initialize keybindings
# Widgets and keybindings will be set up via zle-line-init and precmd hooks
# to ensure zle is fully initialized

# Try to register widgets early if ZLE is available
# This prevents "undefined-key" messages during startup
_z-skk-early-widget-setup() {
    # Check if we're in an interactive shell with ZLE available
    if [[ -o interactive ]] && (( ${+builtins[zle]} )); then
        # Try to register widgets if not already done
        if [[ -z "${Z_SKK_WIDGETS_REGISTERED:-}" ]]; then
            (( ${+functions[z-skk-debug]} )) && z-skk-debug "Attempting early widget registration"
            z-skk-register-widgets
        fi
    fi
}

# Setup keybindings on first line edit to ensure zle is ready
z-skk-line-init() {
    # Register widgets and setup keybindings if not already done
    if [[ -z "${Z_SKK_KEYBINDINGS_SETUP:-}" ]]; then
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Running zle-line-init setup"
        z-skk-register-widgets
        z-skk-setup-keybindings

        # Verify Ctrl+J is bound
        if [[ "$(bindkey '^J' 2>/dev/null)" != *"z-skk-toggle-kana"* ]]; then
            (( ${+functions[z-skk-debug]} )) && z-skk-debug "Warning: Ctrl+J binding failed"
        fi
    fi

    # Call original zle-line-init if it exists
    if (( ${+functions[_z-skk-orig-line-init]} )); then
        _z-skk-orig-line-init "$@"
    fi
}

# Alternative setup function that can be called manually if needed
z-skk-setup() {
    z-skk-register-widgets
    z-skk-setup-keybindings
}

# Only setup hooks in interactive shells
if [[ -o interactive ]]; then
    # Save original zle-line-init if it exists
    if (( ${+functions[zle-line-init]} )); then
        functions[_z-skk-orig-line-init]="${functions[zle-line-init]}"
    fi

    # Register our line-init
    zle -N zle-line-init z-skk-line-init

    # Try early widget setup to prevent "undefined-key" messages
    _z-skk-early-widget-setup
fi
