#!/usr/bin/env zsh
# Input handling for z-skk

# Handle input in ASCII mode
_z-skk-handle-ascii-input() {
    # ASCII mode always passes through
    zle .self-insert
}

# Handle special keys in hiragana mode
_z-skk-handle-hiragana-special-key() {
    local key="$1"

    case "$key" in
        l|L)
            # Switch to ASCII mode
            z-skk-ascii-mode
            zle -R
            return 0
            ;;
        q)
            # Switch to katakana mode (future implementation)
            # For now, continue to romaji processing
            return 1
            ;;
    esac

    return 1  # Not a special key
}



# Handle input in hiragana mode
_z-skk-handle-hiragana-input() {
    local key="$1"

    # Check if already in conversion mode
    if [[ $Z_SKK_CONVERTING -ge 1 ]]; then
        # Handle input during conversion
        _z-skk-handle-converting-input "$key"
        return
    fi

    # Special key handling
    if _z-skk-handle-hiragana-special-key "$key"; then
        return
    fi

    # Check for uppercase (conversion start)
    local processed_key="$key"
    if [[ "$key" =~ ^[A-Z]$ ]]; then
        # Start conversion mode
        Z_SKK_CONVERTING=1
        Z_SKK_BUFFER=""
        # Convert uppercase to lowercase for romaji processing
        processed_key="${key:l}"
    fi

    # Process romaji input
    z-skk-process-romaji-input "$processed_key"

    # Update display with marker if converting
    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        z-skk-update-conversion-display
    fi

    # Redraw the line
    zle -R || {
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "warn" "Failed to redraw line"
        fi
    }
}

# Handle keys during candidate selection
_z-skk-handle-candidate-selection-key() {
    local key="$1"

    case "$key" in
        " ")
            # Space - next candidate
            z-skk-next-candidate
            return 0
            ;;
        "x")
            # x - previous candidate
            z-skk-previous-candidate
            return 0
            ;;
        $'\x07')  # C-g
            # Cancel conversion
            z-skk-cancel-conversion
            return 0
            ;;
        $'\r')    # Enter
            # Confirm current candidate
            z-skk-confirm-candidate
            return 0
            ;;
        *)
            # Any other key confirms and continues
            z-skk-confirm-candidate
            # Process the new key in normal mode
            _z-skk-handle-hiragana-input "$key"
            return 0
            ;;
    esac
}

# Handle keys during pre-conversion
_z-skk-handle-pre-conversion-key() {
    local key="$1"

    case "$key" in
        " ")
            # Space - start conversion
            z-skk-start-conversion
            return 0
            ;;
        $'\x07')  # C-g
            # Cancel conversion
            z-skk-cancel-conversion
            return 0
            ;;
        $'\r')    # Enter
            # Confirm as-is
            z-skk-cancel-conversion
            return 0
            ;;
    esac

    return 1  # Not handled
}

# Handle input during conversion mode
_z-skk-handle-converting-input() {
    local key="$1"

    # Handle based on conversion state
    if [[ $Z_SKK_CONVERTING -eq 2 ]]; then
        # In candidate selection mode
        _z-skk-handle-candidate-selection-key "$key"
        return
    else
        # In pre-conversion mode (CONVERTING=1)
        if _z-skk-handle-pre-conversion-key "$key"; then
            return
        fi

        # Continue adding to buffer
        local lower_key="${key:l}"
        z-skk-process-romaji-input "$lower_key"

        # Update display
        z-skk-update-conversion-display
    fi
}

# Handle input in katakana mode
_z-skk-handle-katakana-input() {
    local key="$1"

    # TODO: Implement katakana mode
    # For now, treat as hiragana mode
    _z-skk-handle-hiragana-input "$key"
}

# Handle input in zenkaku mode
_z-skk-handle-zenkaku-input() {
    local key="$1"

    # TODO: Implement zenkaku mode
    # For now, pass through
    zle .self-insert
}

# Handle input in abbrev mode
_z-skk-handle-abbrev-input() {
    local key="$1"

    # TODO: Implement abbrev mode
    # For now, pass through
    zle .self-insert
}

# Main input dispatcher
z-skk-handle-input() {
    local key="${1:-$KEYS}"

    # Check if in registration mode first
    if z-skk-is-registering; then
        z-skk-registration-input "$key"
        zle -R
        return
    fi

    # Dispatch to appropriate handler based on mode
    case "$Z_SKK_MODE" in
        ascii)
            _z-skk-handle-ascii-input
            ;;
        hiragana)
            _z-skk-handle-hiragana-input "$key"
            ;;
        katakana)
            _z-skk-handle-katakana-input "$key"
            ;;
        zenkaku)
            _z-skk-handle-zenkaku-input "$key"
            ;;
        abbrev)
            _z-skk-handle-abbrev-input "$key"
            ;;
        *)
            # Unknown mode, pass through
            zle .self-insert
            ;;
    esac
}