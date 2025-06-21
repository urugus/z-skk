#!/usr/bin/env zsh
# Romaji input processing for z-skk

# Romaji input buffer
typeset -g Z_SKK_ROMAJI_BUFFER=""

# Result of conversion
typeset -g Z_SKK_CONVERTED=""

# Simple romaji to hiragana conversion function
z-skk-romaji-to-hiragana() {
    local romaji="$1"
    echo "${Z_SKK_ROMAJI_TO_HIRAGANA[$romaji]:-}"
}

# Romaji prefix cache for performance
typeset -gA Z_SKK_ROMAJI_PREFIX_CACHE=()

# Build romaji prefix cache
_z-skk-build-romaji-prefix-cache() {
    local key prefix
    Z_SKK_ROMAJI_PREFIX_CACHE=()

    # Build cache of all possible prefixes
    for key in ${(k)Z_SKK_ROMAJI_TO_HIRAGANA}; do
        for (( i=1; i<=${#key}; i++ )); do
            prefix="${key:0:$i}"
            Z_SKK_ROMAJI_PREFIX_CACHE[$prefix]=1
        done
    done
}

# Check if a string could be the start of a valid romaji sequence
z-skk-is-partial-romaji() {
    local input="$1"

    # Build cache on first use
    if [[ ${#Z_SKK_ROMAJI_PREFIX_CACHE} -eq 0 ]]; then
        _z-skk-build-romaji-prefix-cache
    fi

    # Fast lookup using cache
    [[ -n "${Z_SKK_ROMAJI_PREFIX_CACHE[$input]}" ]]
}

# Convert romaji in buffer to hiragana
z-skk-convert-romaji() {
    Z_SKK_CONVERTED=""

    # Empty buffer
    if [[ -z "$Z_SKK_ROMAJI_BUFFER" ]]; then
        return 0
    fi

    # Special handling for single 'n' - don't convert if it could be part of na, ni, etc.
    if [[ "$Z_SKK_ROMAJI_BUFFER" == "n" ]] && z-skk-is-partial-romaji "n"; then
        return 0
    fi

    # Exact match found
    if [[ -n "${Z_SKK_ROMAJI_TO_HIRAGANA[$Z_SKK_ROMAJI_BUFFER]}" ]]; then
        Z_SKK_CONVERTED="${Z_SKK_ROMAJI_TO_HIRAGANA[$Z_SKK_ROMAJI_BUFFER]}"
        Z_SKK_ROMAJI_BUFFER=""
        return 0
    fi

    # Check if it could be a partial match
    if z-skk-is-partial-romaji "$Z_SKK_ROMAJI_BUFFER"; then
        # Keep buffer as is, waiting for more input
        return 0
    fi

    # No match possible - try to convert the longest prefix
    local i
    for (( i=${#Z_SKK_ROMAJI_BUFFER}; i>0; i-- )); do
        local prefix="${Z_SKK_ROMAJI_BUFFER:0:$i}"
        if [[ -n "${Z_SKK_ROMAJI_TO_HIRAGANA[$prefix]}" ]]; then
            Z_SKK_CONVERTED="${Z_SKK_ROMAJI_TO_HIRAGANA[$prefix]}"
            Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER:$i}"
            return 0
        fi
    done

    # No conversion possible - output first character as-is
    Z_SKK_CONVERTED="${Z_SKK_ROMAJI_BUFFER:0:1}"
    Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER:1}"
}

# Check if this is a double consonant that should be converted to sokuon
z-skk-check-sokuon() {
    local buffer="$1"
    local last_char="${buffer: -1}"

    # Check if we have at least 2 characters and the last two are the same consonant
    if [[ ${#buffer} -ge 2 ]] && [[ "${buffer: -2:1}" == "$last_char" ]]; then
        # Check if it's a consonant that can be doubled (not vowels or 'n')
        case "$last_char" in
            [bcdghjklmprstwyz])
                return 0  # This is a double consonant
                ;;
        esac
    fi
    return 1
}

# Process romaji input and update buffer
z-skk-process-romaji-input() {
    local key="$1"

    # Add key to romaji buffer
    Z_SKK_ROMAJI_BUFFER+="$key"

    # Check for double consonants (sokuon)
    if z-skk-check-sokuon "$Z_SKK_ROMAJI_BUFFER"; then
        # Remove the doubled consonant and add っ instead
        local consonant="${Z_SKK_ROMAJI_BUFFER: -1}"
        Z_SKK_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER:0:-2}"

        # Insert っ
        if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
            Z_SKK_BUFFER+="っ"
        else
            if (( ${+functions[z-skk-display-append]} )); then
                z-skk-display-append "っ"
            else
                LBUFFER+="っ"
            fi
        fi

        # Keep the single consonant for next conversion
        Z_SKK_ROMAJI_BUFFER="$consonant"

        # Emit sokuon event if available
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit input:processed "${consonant}${consonant}" "っ"
        fi
        return
    fi

    # Try to convert
    if z-skk-convert-romaji; then
        # If we got a conversion, insert it
        if [[ -n "$Z_SKK_CONVERTED" ]]; then
            if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
                # Add to conversion buffer instead of direct insert
                Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
            else
                if (( ${+functions[z-skk-display-append]} )); then
                    z-skk-display-append "$Z_SKK_CONVERTED"
                else
                    LBUFFER+="$Z_SKK_CONVERTED"
                fi
            fi

            # Emit input processed event
            if (( ${+functions[z-skk-emit]} )); then
                z-skk-emit input:processed "$key" "$Z_SKK_CONVERTED"
            fi
        fi
    fi
}

# Note: Cache initialization is done on first use in z-skk-is-partial-romaji