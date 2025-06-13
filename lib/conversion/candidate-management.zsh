#!/usr/bin/env zsh
# Candidate management for z-skk conversions

# Look up candidates for a reading
_z-skk-lookup-candidates() {
    local reading="$1"
    local entry

    # Check if we have okurigana
    if [[ -n "$Z_SKK_OKURIGANA_SUFFIX" ]]; then
        # Try lookup with okurigana first
        if entry=$(z-skk-lookup-with-okurigana "$reading" "$Z_SKK_OKURIGANA_SUFFIX"); then
            # Use the filtered candidates
            echo "$entry"
            return 0
        fi
    fi

    # Normal lookup
    if entry=$(z-skk-lookup "$reading"); then
        # Split candidates
        local -a candidates=()
        candidates=("${(@f)$(z-skk-split-candidates "$entry")}")

        if [[ ${#candidates[@]} -gt 0 ]]; then
            print -r -- "${candidates[@]}"
            return 0
        fi
    fi

    return 1
}

# Prepare candidates for selection (remove annotations)
_z-skk-prepare-candidates() {
    local -a raw_candidates=("$@")
    local -a clean_candidates=()
    local candidate

    for candidate in "${raw_candidates[@]}"; do
        clean_candidates+=($(z-skk-get-candidate-word "$candidate"))
    done

    print -r -- "${clean_candidates[@]}"
}

# Switch to candidate selection mode
_z-skk-switch-to-selection-mode() {
    z-skk-set-candidate-index 0
    z-skk-start-candidate-selection  # 2 means selecting candidates

    # Emit event
    if (( ${+functions[z-skk-emit]} )); then
        z-skk-emit conversion:candidates-ready "${#Z_SKK_CANDIDATES[@]}"
    fi

    z-skk-update-candidate-display
}

# Navigate candidates
_z-skk-navigate-candidate() {
    local direction="$1"  # "next" or "previous"

    if z-skk-is-selecting-candidate && [[ ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]; then
        # Clear current display
        local current_candidate="${Z_SKK_CANDIDATES[$((Z_SKK_CANDIDATE_INDEX + 1))]}"
        z-skk-clear-marker "▼" "$current_candidate"

        # Move index based on direction
        if [[ "$direction" == "next" ]]; then
            z-skk-set-candidate-index $(( (Z_SKK_CANDIDATE_INDEX + 1) % ${#Z_SKK_CANDIDATES[@]} ))
        else  # previous
            if [[ $Z_SKK_CANDIDATE_INDEX -eq 0 ]]; then
                z-skk-set-candidate-index $(( ${#Z_SKK_CANDIDATES[@]} - 1 ))
            else
                z-skk-set-candidate-index $(( Z_SKK_CANDIDATE_INDEX - 1 ))
            fi
        fi

        # Update display
        z-skk-update-candidate-display
    fi
}

# Move to next candidate
z-skk-next-candidate() {
    _z-skk-navigate-candidate "next"
}

# Move to previous candidate
z-skk-previous-candidate() {
    _z-skk-navigate-candidate "previous"
}