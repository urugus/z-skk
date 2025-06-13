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

# Note: Reset functions have been moved to reset.zsh
# For reset functionality, use:
#   z-skk-reset [components...]
#   z-skk-reset-state (legacy compatibility)

# Function naming convention helper
z-skk-is-public-function() {
    local func_name="$1"
    [[ "$func_name" =~ ^z-skk-[^_] ]]
}

# Debug logging utility is now in debug.zsh