#!/usr/bin/env zsh
# Keybinding definitions and ZLE widgets for z-skk

# Enable/disable flag
typeset -g Z_SKK_ENABLED=1

# Enable z-skk
z-skk-enable() {
    Z_SKK_ENABLED=1
    # Future: Update prompt/indicators
}

# Disable z-skk
z-skk-disable() {
    Z_SKK_ENABLED=0
    # Reset any active conversion state
    z-skk-reset-state
    # Future: Update prompt/indicators
}

# Check if input should pass through
z-skk-should-pass-through() {
    # Pass through if disabled
    if [[ $Z_SKK_ENABLED -eq 0 ]]; then
        Z_SKK_PASS_THROUGH=1
        return 0
    fi

    # In ASCII mode, everything passes through
    if [[ $Z_SKK_MODE == "ascii" ]]; then
        Z_SKK_PASS_THROUGH=1
        return 0
    fi

    # Default: don't pass through (will be handled by SKK logic)
    Z_SKK_PASS_THROUGH=0
    return 1
}

# Main character input widget
z-skk-self-insert() {
    # Check if we should pass through
    if z-skk-should-pass-through; then
        # Pass through to default self-insert
        zle .self-insert
        return
    fi

    # Handle hiragana mode
    if [[ $Z_SKK_MODE == "hiragana" ]]; then
        # Special key handling in hiragana mode
        case "$KEYS" in
            l|L)
                # 'l' or 'L' switches to ASCII mode
                z-skk-ascii-mode
                zle -R
                return
                ;;
            q)
                # 'q' switches to katakana mode (future)
                # For now, just insert 'q'
                ;;
        esac

        # Add key to romaji buffer
        Z_SKK_ROMAJI_BUFFER+="$KEYS"

        # Try to convert
        z-skk-convert-romaji

        # If we got a conversion, insert it
        if [[ -n "$Z_SKK_CONVERTED" ]]; then
            LBUFFER+="$Z_SKK_CONVERTED"
        fi

        # Redraw the line to show the update
        zle -R

        return
    fi

    # Default: pass through
    zle .self-insert
}

# Register ZLE widgets
zle -N z-skk-self-insert
zle -N z-skk-toggle-kana
zle -N z-skk-ascii-mode
zle -N z-skk-hiragana-mode

# Setup keybindings
z-skk-setup-keybindings() {
    # Only bind if in interactive shell
    [[ -o interactive ]] || return 0

    # Save original self-insert widget if not already saved
    if ! (( ${+widgets[.self-insert]} )); then
        zle -A self-insert .self-insert
    fi

    # Bind printable characters to our widget
    local c
    # ASCII printable characters (space to ~)
    for c in {' '..'~'}; do
        bindkey "$c" z-skk-self-insert
    done

    # Mode switching keys
    bindkey "^J" z-skk-toggle-kana    # Toggle hiragana/ascii
    bindkey "^L" z-skk-ascii-mode     # Force ASCII mode
}

# Initialize keybindings when sourced
z-skk-setup-keybindings
