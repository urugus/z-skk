#!/usr/bin/env zsh
# Core functionality for z-skk

# State variables
typeset -g Z_SKK_MODE="ascii"          # Current input mode
typeset -g Z_SKK_CONVERTING=0          # Conversion state flag
typeset -g Z_SKK_BUFFER=""             # Input buffer
typeset -g -a Z_SKK_CANDIDATES=()      # Conversion candidates
typeset -g Z_SKK_CANDIDATE_INDEX=0     # Current candidate index
typeset -g Z_SKK_PASS_THROUGH=0        # Pass through flag for input handling
typeset -g Z_SKK_LAST_INPUT=""          # Last input character for okurigana detection

# Mode definitions
typeset -gA Z_SKK_MODES=(
    [hiragana]="かな"
    [katakana]="カナ"
    [ascii]="英数"
    [zenkaku]="全英"
    [abbrev]="Abbrev"
)

# Reset state function
z-skk-reset-state() {
    Z_SKK_BUFFER=""
    Z_SKK_CONVERTING=0
    Z_SKK_CANDIDATES=()
    Z_SKK_CANDIDATE_INDEX=0
    # Reset romaji buffer if it exists (from conversion module)
    [[ -v Z_SKK_ROMAJI_BUFFER ]] && Z_SKK_ROMAJI_BUFFER=""
}

# Initialize z-skk
z-skk-init() {
    # Initialize state
    z-skk-reset-state

    # Set default mode
    Z_SKK_MODE="ascii"

    # Load modules
    local lib_dir="${Z_SKK_DIR}/lib"

    # Load error handling first
    if [[ -f "$lib_dir/error.zsh" ]]; then
        source "$lib_dir/error.zsh" || {
            print "z-skk: Failed to load error handling" >&2
            return 1
        }
    fi

    # Load utilities
    z-skk-safe-source "$lib_dir/utils.zsh" || {
        _z-skk-log-error "error" "Failed to load utilities"
        return 1
    }

    # Load conversion module
    z-skk-safe-source "$lib_dir/conversion.zsh" || {
        _z-skk-log-error "error" "Failed to load conversion module"
        return 1
    }

    # Load dictionary data first
    z-skk-safe-source "$lib_dir/dictionary-data.zsh" || {
        _z-skk-log-error "error" "Failed to load dictionary data"
        return 1
    }

    # Load dictionary operations
    z-skk-safe-source "$lib_dir/dictionary.zsh" || {
        _z-skk-log-error "error" "Failed to load dictionary module"
        return 1
    }

    # Load dictionary I/O
    z-skk-safe-source "$lib_dir/dictionary-io.zsh" || {
        _z-skk-log-error "warn" "Failed to load dictionary I/O module"
        # Continue without file I/O support
    }

    # Load registration module
    z-skk-safe-source "$lib_dir/registration.zsh" || {
        _z-skk-log-error "warn" "Failed to load registration module"
        # Continue without registration support
    }

    # Load okurigana module
    z-skk-safe-source "$lib_dir/okurigana.zsh" || {
        _z-skk-log-error "warn" "Failed to load okurigana module"
        # Continue without okurigana support
    }

    # Load input modes module
    z-skk-safe-source "$lib_dir/input-modes.zsh" || {
        _z-skk-log-error "warn" "Failed to load input modes module"
        # Continue without extended input modes
    }

    # Load modes module
    z-skk-safe-source "$lib_dir/modes.zsh" || {
        _z-skk-log-error "error" "Failed to load modes module"
        return 1
    }

    # Load display module
    z-skk-safe-source "$lib_dir/display.zsh" || {
        _z-skk-log-error "warn" "Failed to load display module"
        # Continue without display
    }

    # Load input module
    z-skk-safe-source "$lib_dir/input.zsh" || {
        _z-skk-log-error "error" "Failed to load input module"
        return 1
    }

    # Load keybindings module
    z-skk-safe-source "$lib_dir/keybindings.zsh" || {
        _z-skk-log-error "error" "Failed to load keybindings module"
        return 1
    }

    # Initialize dictionary
    if (( ${+functions[z-skk-init-dictionary]} )); then
        z-skk-init-dictionary
    fi

    # Initialize dictionary loading
    if (( ${+functions[z-skk-init-dictionary-loading]} )); then
        z-skk-init-dictionary-loading
    fi

    # Setup display
    if (( ${+functions[z-skk-display-setup]} )); then
        z-skk-display-setup
    fi

    print "z-skk: Initialized (v${Z_SKK_VERSION})"
    return 0
}
