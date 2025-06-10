#!/usr/bin/env zsh
# Okurigana (送り仮名) processing for z-skk

# Okurigana state
typeset -g Z_SKK_OKURIGANA_MODE=0      # 0: not in okurigana, 1: in okurigana mode
typeset -g Z_SKK_OKURIGANA_PREFIX=""   # Reading prefix before okurigana
typeset -g Z_SKK_OKURIGANA_SUFFIX=""   # Okurigana suffix

# Check if we should start okurigana mode
# Called when uppercase letter is followed by lowercase
z-skk-check-okurigana-start() {
    local prev_char="$1"
    local curr_char="$2"

    # If previous was uppercase and current is lowercase, start okurigana mode
    if [[ "$prev_char" =~ ^[A-Z]$ && "$curr_char" =~ ^[a-z]$ ]]; then
        return 0
    fi

    return 1
}

# Start okurigana mode
z-skk-start-okurigana() {
    Z_SKK_OKURIGANA_MODE=1
    Z_SKK_OKURIGANA_PREFIX="$Z_SKK_BUFFER"
    Z_SKK_OKURIGANA_SUFFIX=""
    # Don't reset buffer - we'll continue building it
}

# Process okurigana input
z-skk-process-okurigana() {
    local key="$1"

    if [[ $Z_SKK_OKURIGANA_MODE -ne 1 ]]; then
        return 1
    fi

    # Process the lowercase letter for okurigana
    z-skk-process-romaji-input "$key"

    # Store as okurigana suffix
    if [[ -n "$Z_SKK_CONVERTED" ]]; then
        Z_SKK_OKURIGANA_SUFFIX+="$Z_SKK_CONVERTED"
    fi

    return 0
}

# Build okurigana search key
# For example: "おく" + "り" → "おく*り"
z-skk-build-okurigana-key() {
    local prefix="$1"
    local suffix="$2"

    if [[ -z "$suffix" ]]; then
        echo "$prefix"
    else
        echo "${prefix}*${suffix}"
    fi
}

# Look up word with okurigana
z-skk-lookup-with-okurigana() {
    local reading="$1"
    local okurigana="$2"

    # Build search key with * marker
    local search_key=$(z-skk-build-okurigana-key "$reading" "$okurigana")

    # Look up in dictionary
    local entry
    if entry=$(z-skk-lookup "$search_key"); then
        echo "$entry"
        return 0
    fi

    # Try without okurigana marker as fallback
    if entry=$(z-skk-lookup "$reading"); then
        # Filter candidates that could match with okurigana
        local -a candidates=()
        local -a all_candidates=("${(@f)$(z-skk-split-candidates "$entry")}")
        local candidate word

        for candidate in "${all_candidates[@]}"; do
            word=$(z-skk-get-candidate-word "$candidate")
            # Simple check: if word ends with okurigana character
            if [[ "${word: -1}" == "$okurigana" ]]; then
                candidates+=("$candidate")
            fi
        done

        if [[ ${#candidates[@]} -gt 0 ]]; then
            # Return filtered candidates
            printf '%s\n' "${candidates[@]}"
            return 0
        fi
    fi

    return 1
}

# Complete okurigana conversion
z-skk-complete-okurigana() {
    if [[ $Z_SKK_OKURIGANA_MODE -ne 1 ]]; then
        return 1
    fi

    # The buffer already contains the full reading
    # Just need to extract the okurigana part
    local okurigana="${Z_SKK_BUFFER:${#Z_SKK_OKURIGANA_PREFIX}}"

    # Store okurigana for lookup
    Z_SKK_OKURIGANA_SUFFIX="$okurigana"

    # Reset to the prefix for lookup
    Z_SKK_BUFFER="$Z_SKK_OKURIGANA_PREFIX"

    # Reset okurigana mode flag but keep suffix for lookup
    Z_SKK_OKURIGANA_MODE=0

    return 0
}

# Reset okurigana state
z-skk-reset-okurigana() {
    Z_SKK_OKURIGANA_MODE=0
    Z_SKK_OKURIGANA_PREFIX=""
    Z_SKK_OKURIGANA_SUFFIX=""
}

# Check if in okurigana mode
z-skk-is-okurigana-mode() {
    [[ $Z_SKK_OKURIGANA_MODE -eq 1 ]]
}