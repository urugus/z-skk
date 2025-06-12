#!/usr/bin/env zsh
# Debug utilities for z-skk

# Enable debug mode
typeset -g Z_SKK_DEBUG="${Z_SKK_DEBUG:-0}"

# Debug log function
z-skk-debug() {
    [[ "$Z_SKK_DEBUG" == "1" ]] || return 0
    local timestamp=$(date +%s.%N 2>/dev/null || date +%s)
    print "[z-skk:${timestamp}] $*" >&2
}

# Time a function call
z-skk-time-function() {
    local func="$1"
    shift
    local start=$(date +%s.%N 2>/dev/null || date +%s)
    "$func" "$@"
    local result=$?
    local end=$(date +%s.%N 2>/dev/null || date +%s)
    if [[ "$Z_SKK_DEBUG" == "1" ]]; then
        local duration=$(echo "$end - $start" | bc 2>/dev/null || echo "unknown")
        z-skk-debug "Function $func took ${duration}s"
    fi
    return $result
}