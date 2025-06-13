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

# Lookup word in dictionary
z-skk-lookup() {
    local reading="$1"

    # Check if reading exists in dictionary
    if [[ -n "${Z_SKK_DICTIONARY[$reading]}" ]]; then
        # Return the entry
        print "${Z_SKK_DICTIONARY[$reading]}"
        return 0
    fi

    # Not found
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
    # For now, just ensure the dictionary is loaded
    # In the future, this will load from files
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
