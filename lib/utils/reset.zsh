#!/usr/bin/env zsh
# Unified reset functionality for z-skk

# Component flags for reset operations
typeset -gA Z_SKK_RESET_COMPONENTS=(
    [core]=1        # Core state (buffer, converting, candidates)
    [romaji]=1      # Romaji buffer
    [registration]=0 # Registration mode state
    [okurigana]=0   # Okurigana state
    [abbrev]=0      # Abbreviation mode state
    [special]=0     # Special input modes
    [display]=0     # Display markers
)

# Main reset function with component control
# Usage: z-skk-reset [component:flag ...]
# Examples:
#   z-skk-reset                     # Reset core components only
#   z-skk-reset all                 # Reset everything
#   z-skk-reset core:1 display:1    # Reset core and display
#   z-skk-reset registration:1      # Reset only registration
z-skk-reset() {
    local -A components=()

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        # Default: reset core components
        components=(${(kv)Z_SKK_RESET_COMPONENTS})
    elif [[ "$1" == "all" ]]; then
        # Reset all components
        for key in ${(k)Z_SKK_RESET_COMPONENTS}; do
            components[$key]=1
        done
    else
        # Start with defaults, then apply overrides
        components=(${(kv)Z_SKK_RESET_COMPONENTS})
        for arg in "$@"; do
            if [[ "$arg" =~ ^([^:]+):([01])$ ]]; then
                components[${match[1]}]=${match[2]}
            fi
        done
    fi

    # Core reset
    if [[ ${components[core]} -eq 1 ]]; then
        Z_SKK_BUFFER=""
        z-skk-set-converting-state 0 2>/dev/null || Z_SKK_CONVERTING=0
        Z_SKK_CANDIDATES=()
        Z_SKK_CANDIDATE_INDEX=0
        Z_SKK_CONVERSION_START_POS=0
    fi

    # Romaji buffer reset
    if [[ ${components[romaji]} -eq 1 ]] && [[ -v Z_SKK_ROMAJI_BUFFER ]]; then
        Z_SKK_ROMAJI_BUFFER=""
    fi

    # Registration state reset
    if [[ ${components[registration]} -eq 1 ]]; then
        if (( ${+functions[z-skk-is-registering]} )); then
            if z-skk-is-registering; then
                [[ -v Z_SKK_REGISTERING ]] && Z_SKK_REGISTERING=0
                [[ -v Z_SKK_REGISTER_READING ]] && Z_SKK_REGISTER_READING=""
                [[ -v Z_SKK_REGISTER_CANDIDATE ]] && Z_SKK_REGISTER_CANDIDATE=""
            fi
        else
            # Fallback if registration module not loaded
            [[ -v Z_SKK_REGISTERING ]] && Z_SKK_REGISTERING=0
            [[ -v Z_SKK_REGISTER_READING ]] && Z_SKK_REGISTER_READING=""
            [[ -v Z_SKK_REGISTER_CANDIDATE ]] && Z_SKK_REGISTER_CANDIDATE=""
        fi
    fi

    # Okurigana state reset
    if [[ ${components[okurigana]} -eq 1 ]]; then
        if (( ${+functions[z-skk-reset-okurigana]} )); then
            z-skk-reset-okurigana
        elif [[ -v Z_SKK_OKURIGANA_MODE ]]; then
            Z_SKK_OKURIGANA_MODE=0
            Z_SKK_OKURIGANA_PREFIX=""
            Z_SKK_OKURIGANA_SUFFIX=""
        fi
    fi

    # Abbreviation state reset
    if [[ ${components[abbrev]} -eq 1 ]] && [[ -v Z_SKK_ABBREV_BUFFER ]]; then
        Z_SKK_ABBREV_BUFFER=""
        Z_SKK_ABBREV_ACTIVE=0
    fi

    # Special input modes reset
    if [[ ${components[special]} -eq 1 ]]; then
        if (( ${+functions[z-skk-reset-special-modes]} )); then
            z-skk-reset-special-modes
        else
            [[ -v Z_SKK_CODE_INPUT_MODE ]] && Z_SKK_CODE_INPUT_MODE=0
            [[ -v Z_SKK_CODE_BUFFER ]] && Z_SKK_CODE_BUFFER=""
            [[ -v Z_SKK_SUFFIX_MODE ]] && Z_SKK_SUFFIX_MODE=0
            [[ -v Z_SKK_SUFFIX_BUFFER ]] && Z_SKK_SUFFIX_BUFFER=""
            [[ -v Z_SKK_PREFIX_MODE ]] && Z_SKK_PREFIX_MODE=0
            [[ -v Z_SKK_PREFIX_BUFFER ]] && Z_SKK_PREFIX_BUFFER=""
        fi
    fi

    # Display reset
    if [[ ${components[display]} -eq 1 ]] && (( ${+functions[z-skk-clear-marker]} )); then
        z-skk-clear-marker "▽" ""
        z-skk-clear-marker "▼" ""
        z-skk-clear-marker "[" ""
        [[ -v Z_SKK_DISPLAY_DIRTY ]] && Z_SKK_DISPLAY_DIRTY=0
    fi
}

# Context-specific reset aliases for convenience
z-skk-reset-conversion() {
    z-skk-reset core:1 romaji:1 display:1
}

z-skk-reset-registration() {
    z-skk-reset registration:1 display:1
}

z-skk-reset-input-modes() {
    z-skk-reset abbrev:1 special:1 display:1
}

# Legacy compatibility functions (to be deprecated)
z-skk-reset-state() {
    z-skk-reset core:1 romaji:1
}

z-skk-unified-reset() {
    local level="${1:-basic}"

    case "$level" in
        basic)
            z-skk-reset core:1 romaji:1
            ;;
        full)
            z-skk-reset all
            ;;
        display)
            z-skk-reset all display:1
            ;;
    esac
}

z-skk-full-reset() {
    z-skk-reset all display:1
}