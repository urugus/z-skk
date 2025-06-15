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
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        /)
            # Switch to abbrev mode
            if (( ${+functions[z-skk-start-abbrev-mode]} )); then
                z-skk-start-abbrev-mode
            else
                # Try to lazy load input-modes module
                (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load input-modes
                (( ${+functions[z-skk-start-abbrev-mode]} )) && z-skk-start-abbrev-mode
            fi
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        q)
            # Switch to katakana mode
            z-skk-katakana-mode
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        X)
            # Convert previous character to katakana
            if (( ${+functions[z-skk-convert-previous-to-katakana]} )); then
                z-skk-convert-previous-to-katakana
            else
                # Try to lazy load special-keys module
                (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load special-keys
                (( ${+functions[z-skk-convert-previous-to-katakana]} )) && z-skk-convert-previous-to-katakana
            fi
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        @)
            # Insert today's date
            if (( ${+functions[z-skk-insert-date]} )); then
                z-skk-insert-date
            else
                # Try to lazy load special-keys module
                (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load special-keys
                (( ${+functions[z-skk-insert-date]} )) && z-skk-insert-date
            fi
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        ";")
            # Start JIS code input
            if (( ${+functions[z-skk-code-input]} )); then
                z-skk-code-input
            else
                # Try to lazy load special-keys module
                (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load special-keys
                (( ${+functions[z-skk-code-input]} )) && z-skk-code-input
            fi
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        ">")
            # Start suffix input mode
            if (( ${+functions[z-skk-start-suffix-input]} )); then
                z-skk-start-suffix-input
            else
                # Try to lazy load special-keys module
                (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load special-keys
                (( ${+functions[z-skk-start-suffix-input]} )) && z-skk-start-suffix-input
            fi
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
        "?")
            # Start prefix input mode
            if (( ${+functions[z-skk-start-prefix-input]} )); then
                z-skk-start-prefix-input
            else
                # Try to lazy load special-keys module
                (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load special-keys
                (( ${+functions[z-skk-start-prefix-input]} )) && z-skk-start-prefix-input
            fi
            (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
            return 0
            ;;
    esac

    return 1  # Not a special key
}



# Check and handle special input modes
_z-skk-check-special-input-mode() {
    local key="$1"

    if (( ${+functions[z-skk-is-special-input-mode]} )); then
        if z-skk-is-special-input-mode; then
            if [[ ${Z_SKK_CODE_INPUT_MODE:-0} -eq 1 ]]; then
                if (( ${+functions[z-skk-process-code-input]} )); then
                    z-skk-process-code-input "$key"
                else
                    # Try to lazy load special-keys module
                    (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load special-keys
                    (( ${+functions[z-skk-process-code-input]} )) && z-skk-process-code-input "$key"
                fi
                (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
                return 0
            fi
            # Handle other special modes in the future
        fi
    fi
    return 1
}

# Detect and prepare conversion mode
_z-skk-detect-conversion-trigger() {
    local key="$1"

    if [[ "$key" =~ ^[A-Z]$ ]]; then
        z-skk-start-pre-conversion
        return 0
    fi
    return 1
}

# Process normal hiragana input
_z-skk-process-hiragana-character() {
    local key="$1"
    local processed_key="$key"

    # Convert uppercase to lowercase for romaji processing
    if [[ "$key" =~ ^[A-Z]$ ]]; then
        processed_key="${key:l}"
    fi

    # Process romaji input
    z-skk-process-romaji-input "$processed_key"

    # Store the key after processing (important for okurigana detection)
    Z_SKK_LAST_INPUT="$key"

    # Update display with marker if converting
    if z-skk-is-pre-converting; then
        z-skk-update-conversion-display
    fi
}

# Handle input in hiragana mode
_z-skk-handle-hiragana-input() {
    local key="$1"

    # Check if in special input mode
    if _z-skk-check-special-input-mode "$key"; then
        return
    fi

    # Check if already in conversion mode
    if z-skk-is-converting; then
        _z-skk-handle-converting-input "$key"
        return
    fi

    # Special key handling
    if _z-skk-handle-hiragana-special-key "$key"; then
        return
    fi

    # Detect conversion trigger and process input
    _z-skk-detect-conversion-trigger "$key"
    _z-skk-process-hiragana-character "$key"

    # Redraw the line
    (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
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
    if z-skk-is-selecting-candidate; then
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
        # Ensure okurigana functions are loaded
        if ! (( ${+functions[z-skk-start-okurigana]} )); then
            # Try to lazy load okurigana module
            (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load okurigana
        fi

        # Now call the functions if they exist
        if (( ${+functions[z-skk-start-okurigana]} )); then
            z-skk-start-okurigana
            if (( ${+functions[z-skk-process-okurigana]} )); then
                z-skk-process-okurigana "$key"
            fi
            Z_SKK_LAST_INPUT="$key"
            z-skk-update-conversion-display
            return
        fi
    fi

    # Normal character processing
    _z-skk-process-converting-character "$key"
}

# Check if we should start okurigana mode
_z-skk-should-start-okurigana() {
    local key="$1"

    # Ensure okurigana functions are loaded if needed
    if ! (( ${+functions[z-skk-is-pre-converting]} )); then
        return 1
    fi

    # Okurigana starts when:
    # 1. Current input is lowercase
    # 2. Last input was uppercase
    # 3. We're already in conversion mode
    # 4. The uppercase was NOT the one that started conversion
    if [[ "$key" =~ ^[a-z]$ ]]; then
        local last_input="${Z_SKK_LAST_INPUT:-}"
        if [[ "$last_input" =~ ^[A-Z]$ &&
              z-skk-is-pre-converting &&
              -n "$Z_SKK_BUFFER" ]]; then
            # The uppercase should be DURING conversion, not the initial one
            # Check if we have more than one character in the buffer
            # (The initial uppercase would only create one hiragana character)
            # Also check that the buffer has actual hiragana content, not just pending romaji
            if [[ ${#Z_SKK_BUFFER} -gt 1 ]]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Handle uppercase during conversion (okurigana marker)
_z-skk-handle-okurigana-marker() {
    local key="$1"

    if [[ "$key" =~ ^[A-Z]$ ]] && ( (( ! ${+functions[z-skk-is-okurigana-mode]} )) || ! z-skk-is-okurigana-mode ); then
        # Complete any pending romaji conversion first
        z-skk-convert-romaji
        if [[ -n "$Z_SKK_CONVERTED" ]]; then
            z-skk-append-to-buffer "$Z_SKK_CONVERTED"
        fi

        # Ensure okurigana functions are loaded
        if ! (( ${+functions[z-skk-start-okurigana]} )); then
            # Try to lazy load okurigana module
            (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load okurigana
        fi

        # Start okurigana mode with the complete prefix if function exists
        if (( ${+functions[z-skk-start-okurigana]} )); then
            z-skk-start-okurigana
            Z_SKK_LAST_INPUT="$key"
            z-skk-update-conversion-display
            return 0
        fi
    fi
    return 1
}

# Process character based on current mode
_z-skk-process-by-mode() {
    local key="$1"
    local lower_key="${key:l}"

    if (( ${+functions[z-skk-is-okurigana-mode]} )) && z-skk-is-okurigana-mode; then
        if (( ${+functions[z-skk-process-okurigana]} )); then
            z-skk-process-okurigana "$lower_key"
        else
            # Try to lazy load okurigana module
            (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load okurigana
            (( ${+functions[z-skk-process-okurigana]} )) && z-skk-process-okurigana "$lower_key"
        fi
    else
        z-skk-process-romaji-input "$lower_key"
    fi
}

# Process a character during conversion
_z-skk-process-converting-character() {
    local key="$1"

    # Check for okurigana marker
    if _z-skk-handle-okurigana-marker "$key"; then
        return
    fi

    # Process based on current mode
    _z-skk-process-by-mode "$key"

    # Store last input and update display
    Z_SKK_LAST_INPUT="$key"
    z-skk-update-conversion-display
}

# Handle input in katakana mode
_z-skk-handle-katakana-input() {
    local key="$1"

    # Check if already in conversion mode
    if z-skk-is-converting; then
        # Handle input during conversion (same as hiragana)
        _z-skk-handle-converting-input "$key"
        return
    fi

    # Special key handling for katakana mode
    if (( ${+functions[z-skk-handle-katakana-special]} )); then
        if z-skk-handle-katakana-special "$key"; then
            return
        fi
    else
        # Try to lazy load input-modes module
        (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load input-modes
        if (( ${+functions[z-skk-handle-katakana-special]} )); then
            if z-skk-handle-katakana-special "$key"; then
                return
            fi
        fi
    fi

    # Check for uppercase (conversion start)
    local processed_key="$key"
    if [[ "$key" =~ ^[A-Z]$ ]]; then
        # Start conversion mode
        z-skk-start-pre-conversion
        Z_SKK_LAST_INPUT="$key"
        # Convert uppercase to lowercase for romaji processing
        processed_key="${key:l}"
    fi

    # Process romaji input as katakana
    if (( ${+functions[z-skk-process-katakana-input]} )); then
        z-skk-process-katakana-input "$processed_key"
    else
        # Try to lazy load input-modes module
        (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load input-modes
        (( ${+functions[z-skk-process-katakana-input]} )) && z-skk-process-katakana-input "$processed_key"
    fi

    # Update display with marker if converting
    if z-skk-is-pre-converting; then
        z-skk-update-conversion-display
    fi

    # Redraw the line
    (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
}

# Handle input in zenkaku mode
_z-skk-handle-zenkaku-input() {
    local key="$1"

    # Special key handling for zenkaku mode
    if (( ${+functions[z-skk-handle-zenkaku-special]} )); then
        if z-skk-handle-zenkaku-special "$key"; then
            return
        fi
    else
        # Try to lazy load input-modes module
        (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load input-modes
        if (( ${+functions[z-skk-handle-zenkaku-special]} )); then
            if z-skk-handle-zenkaku-special "$key"; then
                return
            fi
        fi
    fi

    # Process as zenkaku
    if (( ${+functions[z-skk-process-zenkaku-input]} )); then
        z-skk-process-zenkaku-input "$key"
    else
        # Try to lazy load input-modes module
        (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load input-modes
        (( ${+functions[z-skk-process-zenkaku-input]} )) && z-skk-process-zenkaku-input "$key"
    fi

    # Redraw the line
    (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
}

# Handle input in abbrev mode
_z-skk-handle-abbrev-input() {
    local key="$1"

    # Process abbreviation input
    if (( ${+functions[z-skk-process-abbrev-input]} )); then
        z-skk-process-abbrev-input "$key"
    else
        # Try to lazy load input-modes module
        (( ${+functions[z-skk-lazy-load]} )) && z-skk-lazy-load input-modes
        (( ${+functions[z-skk-process-abbrev-input]} )) && z-skk-process-abbrev-input "$key"
    fi

    # Redraw the line
    (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
}

# Mode handler table
typeset -gA Z_SKK_MODE_HANDLERS=(
    [ascii]="_z-skk-handle-ascii-input"
    [hiragana]="_z-skk-handle-hiragana-input"
    [katakana]="_z-skk-handle-katakana-input"
    [zenkaku]="_z-skk-handle-zenkaku-input"
    [abbrev]="_z-skk-handle-abbrev-input"
)

# Main input dispatcher
z-skk-handle-input() {
    local key="${1:-$KEYS}"

    # Check if in registration mode first
    if (( ${+functions[z-skk-is-registering]} )) && z-skk-is-registering; then
        z-skk-registration-input "$key"
        (( ${+functions[z-skk-safe-redraw]} )) && z-skk-safe-redraw
        return
    fi

    # Get handler for current mode
    local handler="${Z_SKK_MODE_HANDLERS[$Z_SKK_MODE]}"

    if [[ -n "$handler" ]] && (( ${+functions[$handler]} )); then
        # Call mode-specific handler
        if [[ "$handler" == "_z-skk-handle-ascii-input" ]]; then
            "$handler"  # ASCII handler doesn't take key argument
        else
            "$handler" "$key"
        fi
    else
        # Unknown mode or handler not found, pass through
        zle .self-insert
    fi
}