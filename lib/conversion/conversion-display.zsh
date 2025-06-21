#!/usr/bin/env zsh
# Display management for z-skk conversions

# Update display during pre-conversion (▽ marker)
z-skk-update-conversion-display() {
    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        # Build display text based on mode
        local display_text="$Z_SKK_BUFFER"

        # Add current romaji buffer if any
        if [[ -n "$Z_SKK_ROMAJI_BUFFER" ]]; then
            display_text+="$Z_SKK_ROMAJI_BUFFER"
        fi

        # Add okurigana marker if in okurigana mode
        if (( ${+functions[z-skk-is-okurigana-mode]} )) && z-skk-is-okurigana-mode; then
            display_text+="*"

            # Add okurigana suffix if any
            if [[ -n "$Z_SKK_OKURIGANA_SUFFIX" ]]; then
                display_text+="$Z_SKK_OKURIGANA_SUFFIX"
            fi

            # Add current romaji for okurigana if any
            if [[ -n "$Z_SKK_OKURIGANA_ROMAJI" ]]; then
                display_text+="$Z_SKK_OKURIGANA_ROMAJI"
            fi
        fi

        # Clear previous marker before adding new one
        z-skk-clear-marker "▽" ""

        # Instead of just appending, we need to replace from the conversion start position
        # This ensures that when we start a new conversion after a cancellation,
        # the marker appears at the correct position
        local before_conversion="${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}"
        LBUFFER="${before_conversion}▽${display_text}"

        # Emit display updated event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit display:updated "conversion" "$display_text"
        fi
    fi
}

# Update candidate display with ▼ marker
z-skk-update-candidate-display() {
    if [[ $Z_SKK_CONVERTING -eq 2 && ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]; then
        # Show ▼ marker with current candidate
        local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
        z-skk-add-marker "▼" "$current_candidate"

        # Emit display updated event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit display:updated "candidate" "$current_candidate"
        fi
    fi
}