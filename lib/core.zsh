#!/usr/bin/env zsh
# Core functionality for z-skk

# State variables
typeset -g SKK_MODE="ascii"          # Current input mode
typeset -g SKK_CONVERTING=0          # Conversion state flag
typeset -g SKK_BUFFER=""             # Input buffer
typeset -g -a SKK_CANDIDATES=()      # Conversion candidates
typeset -g SKK_CANDIDATE_INDEX=0     # Current candidate index

# Mode definitions
typeset -gA SKK_MODES=(
    [hiragana]="かな"
    [katakana]="カナ"
    [ascii]="英数"
    [zenkaku]="全英"
    [abbrev]="Abbrev"
)

# Reset state function
z-skk-reset-state() {
    SKK_BUFFER=""
    SKK_CONVERTING=0
    SKK_CANDIDATES=()
    SKK_CANDIDATE_INDEX=0
}

# Initialize z-skk
z-skk-init() {
    # Initialize state
    z-skk-reset-state

    # Set default mode
    SKK_MODE="ascii"

    # Load modules
    local lib_dir="${Z_SKK_DIR}/lib"

    # Load conversion module
    if [[ -f "$lib_dir/conversion.zsh" ]]; then
        source "$lib_dir/conversion.zsh"
    fi

    # Load keybindings module
    if [[ -f "$lib_dir/keybindings.zsh" ]]; then
        source "$lib_dir/keybindings.zsh"
    fi

    print "z-skk: Initialized (v${Z_SKK_VERSION})"
    return 0
}
