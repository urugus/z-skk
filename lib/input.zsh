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
        /)
            # Switch to abbrev mode
            z-skk-start-abbrev-mode
            zle -R
            return 0
            ;;
        q)
            # Switch to katakana mode
            z-skk-katakana-mode
            zle -R
            return 0
            ;;
        X)
            # Convert previous character to katakana
            z-skk-convert-previous-to-katakana
            zle -R
            return 0
            ;;
        @)
            # Insert today's date
            z-skk-insert-date
            zle -R
            return 0
            ;;
        ";")
            # Start JIS code input
            z-skk-code-input
            zle -R
            return 0
            ;;
        ">")
            # Start suffix input mode
            z-skk-start-suffix-input
            zle -R
            return 0
            ;;
        "?")
            # Start prefix input mode
            z-skk-start-prefix-input
            zle -R
            return 0
            ;;
    esac

    return 1  # Not a special key
}



# Handle input in hiragana mode
_z-skk-handle-hiragana-input() {
    local key="$1"

    # Check if in special input mode (code input, etc.)
    if (( ${+functions[z-skk-is-special-input-mode]} )); then
        if z-skk-is-special-input-mode; then
            if [[ ${Z_SKK_CODE_INPUT_MODE:-0} -eq 1 ]]; then
                z-skk-process-code-input "$key"
                z-skk-safe-redraw
                return
            fi
            # Handle other special modes in the future
        fi
    fi

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
        # Don't set Z_SKK_LAST_INPUT here - it will be set after processing
        # Convert uppercase to lowercase for romaji processing
        processed_key="${key:l}"
    fi

    # Process romaji input
    z-skk-process-romaji-input "$processed_key"
    
    # Store the key after processing (important for okurigana detection)
    Z_SKK_LAST_INPUT="$key"

    # Update display with marker if converting
    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        z-skk-update-conversion-display
    fi

    # Redraw the line
    z-skk-safe-redraw
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
    else
        # In pre-conversion mode (CONVERTING=1)
        _z-skk-handle-pre-conversion-input "$key"
    fi
}

# Handle input during pre-conversion state
_z-skk-handle-pre-conversion-input() {
    local key="$1"

    # Try special key handling first
    if _z-skk-handle-pre-conversion-key "$key"; then
        return
    fi

    # Check for okurigana start
    if _z-skk-should-start-okurigana "$key"; then
        z-skk-start-okurigana
        z-skk-process-okurigana "$key"
        Z_SKK_LAST_INPUT="$key"
        z-skk-update-conversion-display
        return
    fi

    # Normal character processing
    _z-skk-process-converting-character "$key"
}

# Check if we should start okurigana mode
_z-skk-should-start-okurigana() {
    local key="$1"

    # Okurigana starts when:
    # 1. Current input is lowercase
    # 2. Last input was uppercase 
    # 3. We're already in conversion mode
    # 4. We're NOT at the very beginning of conversion
    #    (i.e., the uppercase that started conversion doesn't count)
    if [[ "$key" =~ ^[a-z]$ ]]; then
        local last_input="${Z_SKK_LAST_INPUT:-}"
        if [[ "$last_input" =~ ^[A-Z]$ && 
              $Z_SKK_CONVERTING -eq 1 && 
              -n "$Z_SKK_BUFFER" && 
              -z "$Z_SKK_ROMAJI_BUFFER" ]]; then
            # Additional check: the uppercase letter should not be the one
            # that started the conversion (i.e., buffer should have more than
            # just the initial converted character)
            # This prevents "Ok" from immediately starting okurigana
            return 0
        fi
    fi
    return 1
}

# Process a character during conversion
_z-skk-process-converting-character() {
    local key="$1"
    
    # Check for uppercase during conversion - this means okurigana start marker
    if [[ "$key" =~ ^[A-Z]$ && ! z-skk-is-okurigana-mode ]]; then
        # This is the marker for okurigana start
        # Store it but don't process the character
        Z_SKK_LAST_INPUT="$key"
        # Still need to update display to show the romaji buffer
        z-skk-update-conversion-display
        return
    fi
    
    local lower_key="${key:l}"

    # Process based on current mode
    if z-skk-is-okurigana-mode; then
        z-skk-process-okurigana "$lower_key"
    else
        z-skk-process-romaji-input "$lower_key"
    fi

    # Store last input and update display
    Z_SKK_LAST_INPUT="$key"
    z-skk-update-conversion-display
}

# Handle input in katakana mode
_z-skk-handle-katakana-input() {
    local key="$1"

    # Check if already in conversion mode
    if [[ $Z_SKK_CONVERTING -ge 1 ]]; then
        # Handle input during conversion (same as hiragana)
        _z-skk-handle-converting-input "$key"
        return
    fi

    # Special key handling for katakana mode
    if z-skk-handle-katakana-special "$key"; then
        return
    fi

    # Check for uppercase (conversion start)
    local processed_key="$key"
    if [[ "$key" =~ ^[A-Z]$ ]]; then
        # Start conversion mode
        Z_SKK_CONVERTING=1
        Z_SKK_BUFFER=""
        Z_SKK_LAST_INPUT="$key"
        # Convert uppercase to lowercase for romaji processing
        processed_key="${key:l}"
    fi

    # Process romaji input as katakana
    z-skk-process-katakana-input "$processed_key"

    # Update display with marker if converting
    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        z-skk-update-conversion-display
    fi

    # Redraw the line
    z-skk-safe-redraw
}

# Handle input in zenkaku mode
_z-skk-handle-zenkaku-input() {
    local key="$1"

    # Special key handling for zenkaku mode
    if z-skk-handle-zenkaku-special "$key"; then
        return
    fi

    # Process as zenkaku
    z-skk-process-zenkaku-input "$key"

    # Redraw the line
    z-skk-safe-redraw
}

# Handle input in abbrev mode
_z-skk-handle-abbrev-input() {
    local key="$1"

    # Special key handling for abbrev mode
    if z-skk-handle-abbrev-special "$key"; then
        return
    fi

    # Process abbreviation input
    z-skk-process-abbrev-input "$key"

    # Redraw the line
    z-skk-safe-redraw
}

# Main input dispatcher
z-skk-handle-input() {
    local key="${1:-$KEYS}"

    # Check if in registration mode first
    if z-skk-is-registering; then
        z-skk-registration-input "$key"
        z-skk-safe-redraw
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