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

# Mode definitions are now in input-modes.zsh

# Reset state function - delegates to reset.zsh
z-skk-reset-state() {
    # Use reset function from reset.zsh
    if (( ${+functions[z-skk-reset]} )); then
        z-skk-reset core:1 romaji:1
    else
        # Fallback if reset.zsh not loaded yet
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
    [error-handling]="required"
    [debug]="optional"  # Debug utilities (optional for production)
    [reset]="required"
    [conversion-tables]="required"
    [utils]="required"
    [events]="required"     # Event system for loose coupling
    [lazy-load]="required"  # Lazy loading infrastructure
    [command-dispatch]="optional"
    [romaji-processing]="required"
    [candidate-management]="required"
    [conversion-display]="required"
    [conversion-control]="required"
    [conversion]="optional"  # Compatibility layer
    [dictionary-data]="required"
    [dictionary]="required"
    [modes]="required"
    [input]="required"
    [keybindings]="required"
    [display]="optional"

    # Lazy-loaded modules (not loaded at startup)
    [dictionary-io]="lazy"  # Loaded when needed
    [registration]="lazy"   # Loaded when needed
    [okurigana]="lazy"      # Loaded when needed
    [input-modes]="lazy"    # Loaded when needed
    [special-keys]="lazy"   # Loaded when needed
)

# Module loading order (important for dependencies)
# Note: Lazy-loaded modules (dictionary-io, registration, okurigana, input-modes, special-keys)
# are NOT included here as they will be loaded on demand
typeset -ga Z_SKK_MODULE_ORDER=(
    # Base infrastructure (no dependencies)
    error-handling debug conversion-tables
    # Core utilities (minimal dependencies)
    utils events dictionary-data lazy-load
    # Display system (needed by many modules)
    display
    # Core systems
    reset dictionary modes
    # Optional modules
    command-dispatch
    # Conversion modules (split for modularity)
    romaji-processing candidate-management
    conversion-display conversion-control
    # Compatibility layer
    conversion
    # Top-level modules
    input keybindings
)

# Load a single module
_z-skk-load-module() {
    local module="$1"
    local requirement="${Z_SKK_MODULES[$module]:-optional}"
    local lib_dir="${Z_SKK_DIR}/lib"
    local module_file="$lib_dir/$module.zsh"

    # Skip lazy modules during initial load
    if [[ "$requirement" == "lazy" ]]; then
        _z-skk-log-error "info" "Skipping lazy module: $module"
        return 0
    fi

    if [[ ! -f "$module_file" ]]; then
        if [[ "$requirement" == "required" ]]; then
            print "z-skk: Required module not found: $module" >&2
            return 1
        fi
        return 0
    fi

    # Debug logging
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Loading module: $module"

    # Special case for error-handling module (no safe-source yet)
    if [[ "$module" == "error-handling" ]]; then
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
    # Debug will be loaded through module system
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Starting z-skk initialization"

    # Initialize state
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Resetting state"
    z-skk-reset-state

    # Set default mode
    Z_SKK_MODE="ascii"

    # Load all modules
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Loading modules"
    _z-skk-load-all-modules || return 1

    # Post-load initialization
    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Post-load initialization"
    _z-skk-post-load-init

    (( ${+functions[z-skk-debug]} )) && z-skk-debug "Initialization complete"
    print "z-skk: Initialized (v${Z_SKK_VERSION})"
    return 0
}

# Post-load initialization tasks
_z-skk-post-load-init() {
    # Initialize dictionary (basic setup only, no file loading)
    if (( ${+functions[z-skk-init-dictionary]} )); then
        z-skk-init-dictionary
    fi

    # Dictionary file loading is now lazy - will be loaded when first needed
    # This avoids startup delays from reading potentially large dictionary files

    # Setup display
    if (( ${+functions[z-skk-display-setup]} )); then
        z-skk-display-setup
    fi
}
