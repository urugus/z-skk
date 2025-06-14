#!/usr/bin/env zsh
# Conversion control and orchestration for z-skk

# Start actual conversion (Space key pressed)
z-skk-start-conversion() {
    if [[ $Z_SKK_CONVERTING -ne 1 || -z "$Z_SKK_BUFFER" ]]; then
        return 1
    fi

    # Complete any pending romaji conversion first
    if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
        # Force conversion of any remaining romaji
        z-skk-convert-romaji
        if [[ -n "$Z_SKK_CONVERTED" ]]; then
            Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
        elif [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
            # If no conversion possible, append romaji as-is
            Z_SKK_BUFFER+="$Z_SKK_ROMAJI_BUFFER"
            Z_SKK_ROMAJI_BUFFER=""
        fi
    fi

    # Complete okurigana if in okurigana mode
    if (( ${+functions[z-skk-is-okurigana-mode]} )) && z-skk-is-okurigana-mode; then
        z-skk-complete-okurigana
    fi

    # Emit conversion started event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit conversion:started "$Z_SKK_BUFFER"
    fi

    # Use standardized error handling
    z-skk-safe-operation "conversion_start" _z-skk-perform-conversion
}

# Perform the actual conversion (separated for error handling)
_z-skk-perform-conversion() {
    local -a raw_candidates=()

    # Clear display before lookup
    z-skk-clear-marker "▽" ""

    if raw_candidates=($(_z-skk-lookup-candidates "$Z_SKK_BUFFER")); then
        # Prepare candidates for selection
        Z_SKK_CANDIDATES=($(_z-skk-prepare-candidates "${raw_candidates[@]}"))

        # Switch to selection mode
        _z-skk-switch-to-selection-mode
        return 0
    fi

    # No candidates found - start registration mode
    z-skk-start-registration "$Z_SKK_BUFFER"
}

# Confirm current candidate
z-skk-confirm-candidate() {
    if [[ $Z_SKK_CONVERTING -eq 2 && ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]; then
        # Clear display
        local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
        z-skk-clear-marker "▼" "$current_candidate"

        # Insert the selected candidate
        if (( ${+functions[z-skk-display-append]} )); then
            z-skk-display-append "$current_candidate"
        else
            LBUFFER+="$current_candidate"
        fi

        # Emit conversion completed event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit conversion:completed "$current_candidate"
        fi

        # Reset all conversion-related state
        z-skk-reset core:1 romaji:1 okurigana:1
        # Also reset last input
        Z_SKK_LAST_INPUT=""
    fi
}

# Cancel conversion and output as-is
z-skk-cancel-conversion() {
    if [[ $Z_SKK_CONVERTING -ge 1 ]]; then
        # Clear any display
        if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
            z-skk-clear-marker "▽" ""
        elif [[ $Z_SKK_CONVERTING -eq 2 ]]; then
            local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
            z-skk-clear-marker "▼" "$current_candidate"
        fi

        # Output buffer content as-is
        if [[ -n "$Z_SKK_BUFFER" ]]; then
            if (( ${+functions[z-skk-display-append]} )); then
                z-skk-display-append "$Z_SKK_BUFFER"
                # Also output any pending romaji if in pre-conversion
                if [[ $Z_SKK_CONVERTING -eq 1 && -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
                    z-skk-display-append "$Z_SKK_ROMAJI_BUFFER"
                fi
            else
                LBUFFER+="$Z_SKK_BUFFER"
                # Also output any pending romaji if in pre-conversion
                if [[ $Z_SKK_CONVERTING -eq 1 && -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
                    LBUFFER+="$Z_SKK_ROMAJI_BUFFER"
                fi
            fi
        fi

        # Emit conversion cancelled event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit conversion:cancelled
        fi

        # Use unified reset including okurigana state
        z-skk-reset core:1 romaji:1 okurigana:1
        # Also reset last input
        Z_SKK_LAST_INPUT=""
    fi
}