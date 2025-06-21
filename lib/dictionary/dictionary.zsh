#!/usr/bin/env zsh
# Dictionary operations for z-skk

# Dictionary data is loaded from dictionary-data.zsh
# This file contains only the operations

# Split candidates by delimiter
z-skk-split-candidates() {
    local entry="$1"
    local -a candidates=()

    # Validate parameters
    if ! z-skk-validate-params 1 $# "z-skk-split-candidates"; then
        return 1
    fi

    if [[ -z "$entry" ]]; then
        print ""
        return 1
    fi

    # Split by '/' delimiter
    candidates=("${(@s:/:)entry}")

    # Return candidates
    print -l "${candidates[@]}"
}

# Lookup word in dictionary with unified search
z-skk-lookup() {
    local reading="$1"
    local -a all_candidates=()
    local -A seen_candidates=()

    # First check user dictionary (highest priority)
    if [[ -n "${Z_SKK_USER_DICTIONARY[$reading]}" ]]; then
        local -a user_candidates=("${(@s:/:)Z_SKK_USER_DICTIONARY[$reading]}")
        for cand in "${user_candidates[@]}"; do
            local base_word="${cand%%[;:]*}"
            if [[ -z "${seen_candidates[$base_word]}" ]]; then
                all_candidates+=("$cand")
                seen_candidates[$base_word]=1
            fi
        done
    fi

    # Then check main dictionary (includes built-in and loaded system dictionaries)
    if [[ -n "${Z_SKK_DICTIONARY[$reading]}" ]]; then
        local -a main_candidates=("${(@s:/:)Z_SKK_DICTIONARY[$reading]}")
        for cand in "${main_candidates[@]}"; do
            local base_word="${cand%%[;:]*}"
            if [[ -z "${seen_candidates[$base_word]}" ]]; then
                all_candidates+=("$cand")
                seen_candidates[$base_word]=1
            fi
        done
    fi

    # Return combined results
    if [[ ${#all_candidates[@]} -gt 0 ]]; then
        local IFS="/"
        print "${all_candidates[*]}"
        return 0
    fi

    # Not found in any dictionary
    return 1
}

# Get candidate without annotation
z-skk-get-candidate-word() {
    local candidate="$1"

    # Remove annotation part (everything after ':')
    print "${candidate%%:*}"
}

# Get candidate annotation
z-skk-get-candidate-annotation() {
    local candidate="$1"

    # Get annotation part (everything after ':')
    if [[ "$candidate" == *:* ]]; then
        print "${candidate#*:}"
    else
        print ""
    fi
}

# Initialize dictionary
z-skk-init-dictionary() {
    # Load built-in dictionary data
    if (( ${+functions[z-skk-load-dictionary-data]} )); then
        z-skk-load-dictionary-data
    fi
    return 0
}

# Add to dictionary (placeholder for future)
z-skk-add-to-dictionary() {
    local reading="$1"
    local kanji="$2"
    local annotation="${3:-}"

    # TODO: Implement personal dictionary
    # For now, just return success
    return 0
}
