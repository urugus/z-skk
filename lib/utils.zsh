#!/usr/bin/env zsh
# Utility functions for z-skk

# Error handling wrapper for general operations
z-skk-safe-execute() {
    local operation="$1"
    shift

    {
        "$@"
    } always {
        if [[ $? -ne 0 ]]; then
            _z-skk-log-error "warn" "Error during $operation"
            return 1
        fi
    }

    return 0
}

# State management utilities
z-skk-save-state() {
    typeset -g Z_SKK_SAVED_MODE="$Z_SKK_MODE"
    typeset -g Z_SKK_SAVED_CONVERTING="$Z_SKK_CONVERTING"
    typeset -g Z_SKK_SAVED_BUFFER="$Z_SKK_BUFFER"
    typeset -g -a Z_SKK_SAVED_CANDIDATES=("${Z_SKK_CANDIDATES[@]}")
    typeset -g Z_SKK_SAVED_CANDIDATE_INDEX="$Z_SKK_CANDIDATE_INDEX"
    typeset -g Z_SKK_SAVED_ROMAJI_BUFFER="${Z_SKK_ROMAJI_BUFFER:-}"
}

z-skk-restore-state() {
    Z_SKK_MODE="${Z_SKK_SAVED_MODE:-ascii}"
    Z_SKK_CONVERTING="${Z_SKK_SAVED_CONVERTING:-0}"
    Z_SKK_BUFFER="${Z_SKK_SAVED_BUFFER:-}"
    Z_SKK_CANDIDATES=("${Z_SKK_SAVED_CANDIDATES[@]}")
    Z_SKK_CANDIDATE_INDEX="${Z_SKK_SAVED_CANDIDATE_INDEX:-0}"
    [[ -v Z_SKK_SAVED_ROMAJI_BUFFER ]] && Z_SKK_ROMAJI_BUFFER="$Z_SKK_SAVED_ROMAJI_BUFFER"
}

# Unified state reset function with levels
# Usage: z-skk-reset-state [level]
# Levels:
#   basic - Reset only basic conversion state (default)
#   full  - Reset all state including mode-specific state
#   display - Reset state and clear display
z-skk-unified-reset() {
    local level="${1:-basic}"

    # Basic reset - always performed
    Z_SKK_BUFFER=""
    Z_SKK_CONVERTING=0
    Z_SKK_CANDIDATES=()
    Z_SKK_CANDIDATE_INDEX=0
    [[ -v Z_SKK_ROMAJI_BUFFER ]] && Z_SKK_ROMAJI_BUFFER=""

    # Full reset - include mode-specific state
    if [[ "$level" == "full" || "$level" == "display" ]]; then
        # Reset registration state if available
        if (( ${+functions[z-skk-is-registering]} )); then
            if z-skk-is-registering; then
                Z_SKK_REGISTERING=0
                Z_SKK_REGISTER_READING=""
                Z_SKK_REGISTER_CANDIDATE=""
            fi
        fi

        # Reset okurigana state if available
        if (( ${+functions[z-skk-reset-okurigana]} )); then
            z-skk-reset-okurigana
        fi

        # Reset abbrev state if available
        if [[ -v Z_SKK_ABBREV_BUFFER ]]; then
            Z_SKK_ABBREV_BUFFER=""
            Z_SKK_ABBREV_ACTIVE=0
        fi
    fi

    # Display reset - clear all visual markers
    if [[ "$level" == "display" ]]; then
        z-skk-clear-marker "▽" ""
        z-skk-clear-marker "▼" ""
        z-skk-clear-marker "[" ""
        Z_SKK_DISPLAY_DIRTY=0
    fi
}

# Compatibility wrapper - will be deprecated
z-skk-full-reset() {
    z-skk-unified-reset "display"
}

# Function naming convention helper
z-skk-is-public-function() {
    local func_name="$1"
    [[ "$func_name" =~ ^z-skk-[^_] ]]
}

# Debug logging utility
z-skk-debug() {
    if [[ "${Z_SKK_DEBUG:-0}" -eq 1 ]]; then
        print "z-skk: $*" >&2
    fi
}