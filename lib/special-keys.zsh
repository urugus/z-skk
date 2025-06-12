#!/usr/bin/env zsh
# Special key handlers for z-skk

# Convert previous hiragana character(s) to katakana (X key)
z-skk-convert-previous-to-katakana() {
    # Only works in hiragana mode
    if [[ "$Z_SKK_MODE" != "hiragana" ]]; then
        return 1
    fi

    # Get the last character from LBUFFER
    if [[ -z "$LBUFFER" ]]; then
        return 1
    fi

    # Extract the last character (considering multi-byte)
    local last_char="${LBUFFER[-1]}"
    local remaining="${LBUFFER[1,-2]}"

    # Convert hiragana to katakana
    local katakana=$(z-skk-hiragana-to-katakana "$last_char")

    if [[ -n "$katakana" ]]; then
        # Replace the last character with katakana
        LBUFFER="${remaining}${katakana}"
        return 0
    fi

    return 1
}

# Note: z-skk-hiragana-to-katakana is now defined in conversion-tables.zsh

# Insert today's date (@ key)
z-skk-insert-date() {
    local format="${1:-%Y-%m-%d}"  # Default format: YYYY-MM-DD
    local date_str=$(date "+$format")

    # Convert to Japanese format if in hiragana/katakana mode
    if [[ "$Z_SKK_MODE" == "hiragana" || "$Z_SKK_MODE" == "katakana" ]]; then
        # Convert to Japanese date format (令和6年11月7日)
        local year=$(date +%Y)
        # Use sed to remove leading zeros for portability
        local month=$(date +%m | sed 's/^0//')
        local day=$(date +%d | sed 's/^0//')

        # Calculate Reiwa year (2019 = Reiwa 1)
        local reiwa_year=$((year - 2018))

        # Convert numbers to Japanese
        date_str="令和${reiwa_year}年${month}月${day}日"
    fi

    LBUFFER+="$date_str"
}

# JIS code input (; key)
z-skk-code-input() {
    # Start code input mode
    typeset -g Z_SKK_CODE_INPUT_MODE=1
    typeset -g Z_SKK_CODE_BUFFER=""

    # Show prompt
    LBUFFER+=";"
}

# Process code input
z-skk-process-code-input() {
    local key="$1"

    # Check if we're in code input mode
    if [[ ${Z_SKK_CODE_INPUT_MODE:-0} -ne 1 ]]; then
        return 1
    fi

    case "$key" in
        [0-9a-fA-F])
            # Add to code buffer
            Z_SKK_CODE_BUFFER+="$key"
            LBUFFER+="$key"

            # Check if we have 4 digits (JIS code)
            if [[ ${#Z_SKK_CODE_BUFFER} -eq 4 ]]; then
                z-skk-complete-code-input
            fi
            ;;
        $'\r')  # Enter
            z-skk-complete-code-input
            ;;
        $'\x07')  # C-g
            z-skk-cancel-code-input
            ;;
        *)
            # Invalid input, cancel
            z-skk-cancel-code-input
            ;;
    esac
}

# Complete code input
z-skk-complete-code-input() {
    if [[ -z "$Z_SKK_CODE_BUFFER" ]]; then
        z-skk-cancel-code-input
        return
    fi

    # Remove the code display from buffer
    local code_len=$((${#Z_SKK_CODE_BUFFER} + 1))  # +1 for semicolon
    LBUFFER="${LBUFFER[1,-$((code_len + 1))]}"

    # Convert JIS code to character
    local char=$(z-skk-jis-to-char "$Z_SKK_CODE_BUFFER")

    if [[ -n "$char" ]]; then
        LBUFFER+="$char"
    fi

    # Reset code input mode
    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_CODE_BUFFER=""
}

# Cancel code input
z-skk-cancel-code-input() {
    # Remove the semicolon and any code from buffer
    if [[ $Z_SKK_CODE_INPUT_MODE -eq 1 ]]; then
        local code_len=$((${#Z_SKK_CODE_BUFFER} + 1))
        LBUFFER="${LBUFFER[1,-$((code_len + 1))]}"
    fi

    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_CODE_BUFFER=""
}

# Convert JIS code to character
# Note: z-skk-jis-to-char is now defined in conversion-tables.zsh

# Suffix input mode (> key)
z-skk-start-suffix-input() {
    typeset -g Z_SKK_SUFFIX_MODE=1
    typeset -g Z_SKK_SUFFIX_BUFFER=""

    # Show marker
    LBUFFER+=">"
}

# Prefix input mode (? key)
z-skk-start-prefix-input() {
    typeset -g Z_SKK_PREFIX_MODE=1
    typeset -g Z_SKK_PREFIX_BUFFER=""

    # Show marker
    LBUFFER+="?"
}

# Check if in special input mode
z-skk-is-special-input-mode() {
    [[ ${Z_SKK_CODE_INPUT_MODE:-0} -eq 1 ]] || \
    [[ ${Z_SKK_SUFFIX_MODE:-0} -eq 1 ]] || \
    [[ ${Z_SKK_PREFIX_MODE:-0} -eq 1 ]]
}

# Reset special input modes
z-skk-reset-special-modes() {
    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_CODE_BUFFER=""
    Z_SKK_SUFFIX_MODE=0
    Z_SKK_SUFFIX_BUFFER=""
    Z_SKK_PREFIX_MODE=0
    Z_SKK_PREFIX_BUFFER=""
}