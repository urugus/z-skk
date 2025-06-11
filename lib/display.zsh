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

# ============================================
# Buffer manipulation utilities
# ============================================

# Clear marker and content from buffer
z-skk-clear-marker() {
    local marker="$1"
    local content="$2"

    # Clear from LBUFFER - find and remove marker and everything after it
    if [[ -n "$marker" ]]; then
        # Find the last occurrence of the marker
        local marker_pos="${LBUFFER%${marker}*}"
        if [[ "$marker_pos" != "$LBUFFER" ]]; then
            # Marker found, clear it and content
            LBUFFER="$marker_pos"
        fi
        
        # Also clear from RBUFFER if needed
        RBUFFER="${RBUFFER#*${content}}"
        RBUFFER="${RBUFFER#*]}"  # For registration mode
    fi
}

# Add marker and content to buffer
z-skk-add-marker() {
    local marker="$1"
    local content="$2"

    # Add to LBUFFER
    LBUFFER+="${marker}${content}"
}

# Update marker display (clear old, add new)
z-skk-update-marker() {
    local old_marker="$1"
    local old_content="$2"
    local new_marker="$3"
    local new_content="$4"

    # Clear old display
    z-skk-clear-marker "$old_marker" "$old_content"

    # Add new display
    z-skk-add-marker "$new_marker" "$new_content"
}

# Safe ZLE redraw with error handling
z-skk-safe-redraw() {
    zle -R || {
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "warn" "Failed to redraw line"
        fi
        return 1
    }
    return 0
}

# Batch display update helper
typeset -g Z_SKK_DISPLAY_DIRTY=0

z-skk-mark-display-dirty() {
    Z_SKK_DISPLAY_DIRTY=1
}

z-skk-flush-display() {
    if [[ $Z_SKK_DISPLAY_DIRTY -eq 1 ]]; then
        z-skk-safe-redraw
        Z_SKK_DISPLAY_DIRTY=0
    fi
}

