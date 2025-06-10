#!/usr/bin/env zsh
# Error handling for z-skk

# Error log level
typeset -g Z_SKK_ERROR_LEVEL="${Z_SKK_ERROR_LEVEL:-warn}"

# Log an error message
_z-skk-log-error() {
    local level="$1"
    local message="$2"

    case "$level" in
        error)
            print "z-skk: ERROR: $message" >&2
            ;;
        warn)
            [[ "$Z_SKK_ERROR_LEVEL" == "warn" || "$Z_SKK_ERROR_LEVEL" == "info" ]] && \
                print "z-skk: WARN: $message" >&2
            ;;
        info)
            [[ "$Z_SKK_ERROR_LEVEL" == "info" ]] && \
                print "z-skk: INFO: $message" >&2
            ;;
    esac
}

# Safe source a file with error handling
z-skk-safe-source() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        _z-skk-log-error "warn" "File not found: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        _z-skk-log-error "error" "Cannot read file: $file"
        return 1
    fi

    source "$file" || {
        _z-skk-log-error "error" "Failed to source: $file"
        return 1
    }

    return 0
}

# Safe ZLE operation
z-skk-safe-zle() {
    local widget="$1"
    shift

    # Check if we're in ZLE context
    if [[ -z "$WIDGET" ]]; then
        _z-skk-log-error "warn" "ZLE operation outside widget context: $widget"
        return 1
    fi

    # Check if widget exists
    if ! (( ${+widgets[$widget]} )); then
        _z-skk-log-error "error" "Widget not found: $widget"
        return 1
    fi

    zle "$widget" "$@" || {
        _z-skk-log-error "error" "ZLE operation failed: $widget"
        return 1
    }

    return 0
}

# Reset to safe state on error
z-skk-error-reset() {
    local context="${1:-unknown}"

    _z-skk-log-error "warn" "Resetting due to error in: $context"

    # Reset all state
    z-skk-reset-state

    # Switch to ASCII mode (safest)
    Z_SKK_MODE="ascii"

    # Clear any partial input
    [[ -n "$Z_SKK_ROMAJI_BUFFER" ]] && Z_SKK_ROMAJI_BUFFER=""

    # Update display if possible
    if (( ${+functions[z-skk-update-display]} )); then
        z-skk-update-display
    fi

    return 0
}