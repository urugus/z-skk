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

    # Delegate to input handler
    z-skk-handle-input "$KEYS"
}

# Register ZLE widgets
zle -N z-skk-self-insert
zle -N z-skk-toggle-kana
zle -N z-skk-ascii-mode
zle -N z-skk-hiragana-mode

# Setup keybindings
z-skk-setup-keybindings() {
    # Skip if already setup
    [[ -n "${Z_SKK_KEYBINDINGS_SETUP:-}" ]] && return 0

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

    # Mark as setup
    typeset -g Z_SKK_KEYBINDINGS_SETUP=1
}

# Initialize keybindings
# For interactive shells, setup immediately
if [[ -o interactive ]]; then
    z-skk-setup-keybindings
fi

# For non-interactive shells (like when loaded by zinit),
# setup keybindings on first line edit
z-skk-line-init() {
    # Setup keybindings if not already done
    z-skk-setup-keybindings

    # Call original zle-line-init if it exists
    if (( ${+functions[_z_skk_orig_line_init]} )); then
        _z_skk_orig_line_init "$@"
    fi
}

# Only setup zle-line-init in interactive shells
if [[ -o interactive ]]; then
    # Save original zle-line-init if it exists
    if (( ${+functions[zle-line-init]} )); then
        functions[_z_skk_orig_line_init]="${functions[zle-line-init]}"
    fi

    # Register our line-init
    zle -N zle-line-init z-skk-line-init
fi
