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

# Reset state function - delegates to unified reset
z-skk-reset-state() {
    # Use unified reset function from utils.zsh
    if (( ${+functions[z-skk-unified-reset]} )); then
        z-skk-unified-reset "basic"
    else
        # Fallback if utils.zsh not loaded yet
        Z_SKK_BUFFER=""
        Z_SKK_CONVERTING=0
        Z_SKK_CANDIDATES=()
        Z_SKK_CANDIDATE_INDEX=0
        [[ -v Z_SKK_ROMAJI_BUFFER ]] && Z_SKK_ROMAJI_BUFFER=""
    fi
}

# Module loading configuration
typeset -gA Z_SKK_MODULES=(
    # Required modules (loading failure is fatal)
    [error]="required"
    [error-handling]="required"
    [reset]="required"
    [conversion-tables]="required"
    [utils]="required"
    [command-dispatch]="optional"
    [conversion]="required"
    [dictionary-data]="required"
    [dictionary]="required"
    [modes]="required"
    [input]="required"
    [keybindings]="required"

    # Optional modules (loading failure is non-fatal)
    [dictionary-io]="optional"
    [registration]="optional"
    [okurigana]="optional"
    [input-modes]="optional"
    [special-keys]="optional"
    [display]="optional"
)

# Module loading order (important for dependencies)
typeset -ga Z_SKK_MODULE_ORDER=(
    error error-handling reset conversion-tables utils
    command-dispatch conversion dictionary-data dictionary
    dictionary-io registration okurigana input-modes
    special-keys modes display input keybindings
)

# Load a single module
_z-skk-load-module() {
    local module="$1"
    local requirement="${Z_SKK_MODULES[$module]:-optional}"
    local lib_dir="${Z_SKK_DIR}/lib"
    local module_file="$lib_dir/$module.zsh"

    if [[ ! -f "$module_file" ]]; then
        if [[ "$requirement" == "required" ]]; then
            print "z-skk: Required module not found: $module" >&2
            return 1
        fi
        return 0
    fi

    # Special case for error module (no safe-source yet)
    if [[ "$module" == "error" ]]; then
        source "$module_file" || {
            print "z-skk: Failed to load error handling" >&2
            return 1
        }
        return 0
    fi

    # Use safe-source for other modules
    if ! z-skk-safe-source "$module_file"; then
        if [[ "$requirement" == "required" ]]; then
            _z-skk-log-error "error" "Failed to load required module: $module"
            return 1
        else
            _z-skk-log-error "warn" "Failed to load optional module: $module"
        fi
    fi

    return 0
}

# Load all modules in order
_z-skk-load-all-modules() {
    local module

    for module in "${Z_SKK_MODULE_ORDER[@]}"; do
        _z-skk-load-module "$module" || return 1
    done

    return 0
}

# Initialize z-skk
z-skk-init() {
    # Initialize state
    z-skk-reset-state

    # Set default mode
    Z_SKK_MODE="ascii"

    # Load all modules
    _z-skk-load-all-modules || return 1

    # Post-load initialization
    _z-skk-post-load-init

    print "z-skk: Initialized (v${Z_SKK_VERSION})"
    return 0
}

# Post-load initialization tasks
_z-skk-post-load-init() {
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
}
