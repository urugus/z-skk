#!/usr/bin/env zsh
# Display control for z-skk

# Save original RPROMPT
typeset -g Z_SKK_ORIGINAL_RPROMPT=""

# Ensure precmd_functions array exists
typeset -ga precmd_functions

# Initialize display settings
z-skk-display-init() {
    # Save original RPROMPT if not already saved
    if [[ -z "$Z_SKK_ORIGINAL_RPROMPT" && -n "${RPROMPT:-}" ]]; then
        Z_SKK_ORIGINAL_RPROMPT="$RPROMPT"
    fi
}

# Update RPROMPT with mode indicator
z-skk-update-display() {
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        # Restore original RPROMPT when disabled
        RPROMPT="$Z_SKK_ORIGINAL_RPROMPT"
        return
    fi

    # Get mode indicator
    local mode_indicator="$(z-skk-mode-indicator)"

    # Update RPROMPT
    if [[ -n "$Z_SKK_ORIGINAL_RPROMPT" ]]; then
        # Append to existing RPROMPT
        RPROMPT="${mode_indicator} ${Z_SKK_ORIGINAL_RPROMPT}"
    else
        # Set as RPROMPT
        RPROMPT="$mode_indicator"
    fi
}

# Hook for precmd to update display
z-skk-precmd-hook() {
    z-skk-update-display
}

# Setup display hooks
z-skk-display-setup() {
    # Initialize display settings
    z-skk-display-init

    # Add precmd hook if not already added
    if [[ -z "${precmd_functions[(r)z-skk-precmd-hook]}" ]]; then
        precmd_functions+=(z-skk-precmd-hook)
    fi

    # Initial display update
    z-skk-update-display
}

# Cleanup display hooks
z-skk-display-cleanup() {
    # Remove precmd hook
    precmd_functions=(${precmd_functions:#z-skk-precmd-hook})

    # Restore original RPROMPT
    RPROMPT="$Z_SKK_ORIGINAL_RPROMPT"
}

