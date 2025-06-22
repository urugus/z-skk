#!/usr/bin/env zsh
# Key bindings for z-skk (refactored version)

# Widget for self-insert (every printable character)
z-skk-self-insert() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        # Pass through to default behavior when disabled
        zle .self-insert
        return
    fi

    # Get the character that was typed
    local key="$KEYS"

    # Handle the character based on current mode
    case "$Z_SKK_MODE" in
        hiragana)
            _z-skk-handle-hiragana-input "$key"
            ;;
        katakana)
            _z-skk-handle-katakana-input "$key"
            ;;
        ascii)
            _z-skk-handle-ascii-input "$key"
            ;;
        zenkaku)
            _z-skk-handle-zenkaku-input "$key"
            ;;
        abbrev)
            _z-skk-handle-abbrev-input "$key"
            ;;
        *)
            # Unknown mode, fall back to ASCII
            zle .self-insert
            ;;
    esac
}

# Widget for space key (candidate selection)
z-skk-space() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        zle .self-insert
        return
    fi

    # Prioritize space handling by mode
    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        # Start conversion and candidate selection
        z-skk-start-conversion
    elif [[ $Z_SKK_CONVERTING -eq 2 ]]; then
        # Next candidate
        z-skk-next-candidate
    elif [[ "$Z_SKK_MODE" == "hiragana" ]] || [[ "$Z_SKK_MODE" == "katakana" ]]; then
        # Convert romaji buffer if any, then insert space
        if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
            z-skk-convert-romaji
            if [[ -n "$Z_SKK_CONVERTED" ]]; then
                if (( ${+functions[z-skk-display-append-batched]} )); then
                    z-skk-display-append-batched "$Z_SKK_CONVERTED"
                else
                    LBUFFER+="$Z_SKK_CONVERTED"
                fi
            fi
            if (( ${+functions[z-skk-romaji-buffer-clear]} )); then
                z-skk-romaji-buffer-clear
            else
                Z_SKK_ROMAJI_BUFFER=""
            fi
        fi
        # Insert space
        if (( ${+functions[z-skk-display-append-batched]} )); then
            z-skk-display-append-batched " "
        else
            LBUFFER+=" "
        fi
    else
        # Default space behavior
        zle .self-insert
    fi
}

# Widget for Enter/Return key
z-skk-accept-line() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        zle .accept-line
        return
    fi

    # If in conversion mode, confirm conversion
    if [[ $Z_SKK_CONVERTING -gt 0 ]]; then
        z-skk-confirm-conversion
    else
        # Convert any pending romaji
        if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
            z-skk-convert-romaji
            if [[ -n "$Z_SKK_CONVERTED" ]]; then
                if (( ${+functions[z-skk-display-append-batched]} )); then
                    z-skk-display-append-batched "$Z_SKK_CONVERTED"
                else
                    LBUFFER+="$Z_SKK_CONVERTED"
                fi
            fi
            if (( ${+functions[z-skk-romaji-buffer-clear]} )); then
                z-skk-romaji-buffer-clear
            else
                Z_SKK_ROMAJI_BUFFER=""
            fi
        fi
        # Default accept-line behavior
        zle .accept-line
    fi
}

# Widget for Ctrl-G (cancel)
z-skk-cancel() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        zle send-break
        return
    fi

    if [[ $Z_SKK_CONVERTING -gt 0 ]]; then
        z-skk-cancel-conversion
    else
        zle send-break
    fi
}

# Backspace widget (now uses refactored handlers)
z-skk-backspace() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        zle .backward-delete-char
        return
    fi

    # Load backspace handlers if not already loaded
    if ! (( ${+functions[z-skk-backspace-in-registration]} )); then
        # Try to lazy load backspace handlers
        (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load backspace-handlers
    fi

    # Handle registration mode
    if z-skk-is-registering; then
        z-skk-backspace-in-registration
        return
    fi

    # Handle conversion modes
    if [[ $Z_SKK_CONVERTING -eq 2 ]]; then
        # In candidate selection mode
        z-skk-backspace-in-candidate-selection
        return
    elif [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        # In pre-conversion mode
        z-skk-backspace-in-conversion
        return
    fi

    # Handle normal backspace (not in conversion mode)
    z-skk-backspace-normal
}

# Widget for 'x' key (previous candidate)
z-skk-previous-candidate-widget() {
    if [[ $Z_SKK_CONVERTING -eq 2 ]]; then
        z-skk-previous-candidate
    else
        # Pass through to normal input handling
        z-skk-self-insert
    fi
}

# Toggle kana mode (Ctrl-J)
z-skk-toggle-kana() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        zle .accept-line
        return
    fi

    case "$Z_SKK_MODE" in
        ascii)
            z-skk-hiragana-mode
            ;;
        hiragana)
            z-skk-ascii-mode
            ;;
        katakana|zenkaku|abbrev)
            z-skk-hiragana-mode
            ;;
        *)
            z-skk-ascii-mode  # Default fallback
            ;;
    esac
}

# ASCII mode (l/L key in hiragana mode is handled in input processing)
z-skk-ascii-mode() {
    # Check if z-skk is enabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        zle .self-insert
        return
    fi

    z-skk-set-mode "ascii"

    # Safe redraw
    if (( ${+functions[z-skk-display-safe-redraw]} )); then
        z-skk-display-safe-redraw
    else
        (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
    fi
}

# Register all widgets
z-skk-register-widgets() {
    # Check if ZLE is available
    if ! zle -l >/dev/null 2>&1; then
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

    if (( ${+functions[z-skk-backspace]} )); then
        zle -N z-skk-backspace
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-backspace"
    fi

    if (( ${+functions[z-skk-space]} )); then
        zle -N z-skk-space
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-space"
    fi

    if (( ${+functions[z-skk-accept-line]} )); then
        zle -N z-skk-accept-line
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-accept-line"
    fi

    if (( ${+functions[z-skk-cancel]} )); then
        zle -N z-skk-cancel
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-cancel"
    fi

    if (( ${+functions[z-skk-previous-candidate-widget]} )); then
        zle -N z-skk-previous-candidate-widget
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-previous-candidate-widget"
    fi

    if (( ${+functions[z-skk-ascii-mode]} )); then
        zle -N z-skk-ascii-mode
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Registered widget: z-skk-ascii-mode"
    fi

    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Widget registration completed"
}

# Set up key bindings
z-skk-setup-keybindings() {
    # Only set up if widgets are registered
    if ! zle -l z-skk-self-insert >/dev/null 2>&1; then
        (( ${+functions[z-skk-debug]} )) && z-skk-debug "Widgets not registered, skipping keybinding setup"
        return 1
    fi

    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Setting up keybindings..."

    # Bind self-insert to all printable characters
    local char
    for char in {a..z} {A..Z} {0..9} \! \" \# \$ \% \& \' \( \) \* \+ \, \- \. \/ \: \; \< \= \> \? \@ \[ \\ \] \^ \_ \` \{ \| \} \~; do
        bindkey "$char" z-skk-self-insert
    done

    # Special key bindings
    bindkey "^J" z-skk-toggle-kana      # Ctrl-J
    bindkey "^?" z-skk-backspace        # Backspace
    bindkey "^H" z-skk-backspace        # Ctrl-H (also backspace)
    bindkey " " z-skk-space             # Space
    bindkey "^M" z-skk-accept-line      # Enter
    bindkey "^G" z-skk-cancel           # Ctrl-G

    # Bind 'x' for previous candidate (will be handled contextually)
    bindkey "x" z-skk-previous-candidate-widget

    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Keybinding setup completed"
}

# Remove z-skk keybindings (restore defaults)
z-skk-remove-keybindings() {
    # Restore original key bindings to default behavior
    bindkey "^J" accept-line            # Ctrl-J (restore default)
    bindkey "^G" send-break             # Ctrl-G (restore default)
    bindkey " " self-insert             # Space (restore default)
    bindkey "^M" accept-line            # Enter (restore default)
    bindkey "x" self-insert             # x (restore default)

    # Remove character bindings - restore self-insert for printable characters
    local char
    for char in {a..z} {A..Z} {0..9}; do
        bindkey "$char" self-insert
    done

    # Restore special characters
    for char in "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" "-" "_" "=" "+" "[" "]" "{" "}" "\\" "|" ";" ":" "'" "\"" "," "." "<" ">" "/" "?"; do
        bindkey "$char" self-insert
    done

    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Keybindings removed"
}