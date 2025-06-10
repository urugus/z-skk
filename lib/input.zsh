#!/usr/bin/env zsh
# Input handling for z-skk

# Handle input in ASCII mode
_z-skk-handle-ascii-input() {
    # ASCII mode always passes through
    zle .self-insert
}

# Handle input in hiragana mode
_z-skk-handle-hiragana-input() {
    local key="$1"

    # Special key handling
    case "$key" in
        l|L)
            # Switch to ASCII mode
            z-skk-ascii-mode
            zle -R
            return 0
            ;;
        q)
            # Switch to katakana mode (future implementation)
            # For now, continue to romaji processing
            ;;
    esac

    # Add key to romaji buffer
    Z_SKK_ROMAJI_BUFFER+="$key"

    # Try to convert
    if z-skk-convert-romaji; then
        # If we got a conversion, insert it
        if [[ -n "$Z_SKK_CONVERTED" ]]; then
            LBUFFER+="$Z_SKK_CONVERTED"
        fi
    fi

    # Redraw the line
    zle -R || {
        if (( ${+functions[_z-skk-log-error]} )); then
            _z-skk-log-error "warn" "Failed to redraw line"
        fi
    }
}

# Handle input in katakana mode
_z-skk-handle-katakana-input() {
    local key="$1"

    # TODO: Implement katakana mode
    # For now, treat as hiragana mode
    _z-skk-handle-hiragana-input "$key"
}

# Handle input in zenkaku mode
_z-skk-handle-zenkaku-input() {
    local key="$1"

    # TODO: Implement zenkaku mode
    # For now, pass through
    zle .self-insert
}

# Handle input in abbrev mode
_z-skk-handle-abbrev-input() {
    local key="$1"

    # TODO: Implement abbrev mode
    # For now, pass through
    zle .self-insert
}

# Main input dispatcher
z-skk-handle-input() {
    local key="${1:-$KEYS}"

    # Dispatch to appropriate handler based on mode
    case "$Z_SKK_MODE" in
        ascii)
            _z-skk-handle-ascii-input
            ;;
        hiragana)
            _z-skk-handle-hiragana-input "$key"
            ;;
        katakana)
            _z-skk-handle-katakana-input "$key"
            ;;
        zenkaku)
            _z-skk-handle-zenkaku-input "$key"
            ;;
        abbrev)
            _z-skk-handle-abbrev-input "$key"
            ;;
        *)
            # Unknown mode, pass through
            zle .self-insert
            ;;
    esac
}