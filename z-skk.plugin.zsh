#!/usr/bin/env zsh
# z-skk - SKK-like Japanese input method for zsh
#
# This is the main plugin file for zinit compatibility

# Plugin metadata
typeset -g Z_SKK_VERSION="0.1.0"
typeset -g Z_SKK_DIR="${0:A:h}"

# Initialize the plugin
() {
    local lib_dir="${Z_SKK_DIR}/lib"

    # Check if lib directory exists
    if [[ ! -d "$lib_dir" ]]; then
        print "z-skk: Error - lib directory not found at $lib_dir" >&2
        return 1
    fi

    # Source core functionality (will be implemented)
    if [[ -f "$lib_dir/core.zsh" ]]; then
        source "$lib_dir/core.zsh"
    fi

    # Initialize z-skk
    if (( ${+functions[z-skk-init]} )); then
        z-skk-init
    else
        print "z-skk: Loaded (v${Z_SKK_VERSION})"
    fi

    # Export setup function for external use
    if (( ${+functions[z-skk-setup-keybindings]} )); then
        typeset -gf z-skk-setup-keybindings
    fi
}

# Cleanup function for unloading
z-skk-unload() {
    # Clean up display
    if (( ${+functions[z-skk-display-cleanup]} )); then
        z-skk-display-cleanup
    fi

    # Reset state
    if (( ${+functions[z-skk-reset-state]} )); then
        z-skk-reset-state
    fi

    print "z-skk: Unloaded"
}

