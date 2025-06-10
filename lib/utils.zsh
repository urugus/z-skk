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

# Comprehensive state reset
z-skk-full-reset() {
    # Reset basic state
    Z_SKK_BUFFER=""
    Z_SKK_CONVERTING=0
    Z_SKK_CANDIDATES=()
    Z_SKK_CANDIDATE_INDEX=0
    [[ -v Z_SKK_ROMAJI_BUFFER ]] && Z_SKK_ROMAJI_BUFFER=""

    # Reset registration state if available
    if (( ${+functions[z-skk-is-registering]} )); then
        if z-skk-is-registering; then
            Z_SKK_REGISTERING=0
            Z_SKK_REGISTER_READING=""
            Z_SKK_REGISTER_CANDIDATE=""
        fi
    fi

    # Clear display
    z-skk-clear-marker "▽" ""
    z-skk-clear-marker "▼" ""

    # Reset display dirty flag
    Z_SKK_DISPLAY_DIRTY=0
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