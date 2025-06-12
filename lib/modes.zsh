#!/usr/bin/env zsh
# Input mode management for z-skk

# Set the input mode
# Note: This function is replaced by the one in input-modes.zsh
_z-skk-set-mode-old() {
    local new_mode="$1"

    # Validate mode
    if [[ -z "${Z_SKK_MODE_NAMES[$new_mode]}" ]]; then
        # Invalid mode, do nothing
        return 1
    fi

    # Clear buffers when switching modes
    if [[ "$Z_SKK_MODE" != "$new_mode" ]]; then
        # Reset old mode's specific states
        case "$Z_SKK_MODE" in
            abbrev)
                # Leaving abbrev mode, clear its state
                Z_SKK_ABBREV_BUFFER=""
                Z_SKK_ABBREV_ACTIVE=0
                ;;
        esac

        local old_mode="$Z_SKK_MODE"
        z-skk-reset-state
        Z_SKK_MODE="$new_mode"

        # Emit mode change event
        if (( ${+functions[z-skk-emit]} )); then
            z-skk-emit mode:changed "$old_mode" "$new_mode"
        fi

        # Mode-specific initialization
        case "$new_mode" in
            hiragana|katakana)
                Z_SKK_ROMAJI_BUFFER=""
                ;;
            ascii|zenkaku)
                # No special initialization needed
                ;;
            abbrev)
                # Initialize abbrev mode state
                Z_SKK_ABBREV_BUFFER=""
                Z_SKK_ABBREV_ACTIVE=0
                ;;
        esac

        # Update display if available
        if (( ${+functions[z-skk-update-display]} )); then
            z-skk-update-display
        fi
    fi

    return 0
}

# Switch to ASCII mode
z-skk-ascii-mode() {
    z-skk-set-mode "ascii"
}

# Switch to hiragana mode
z-skk-hiragana-mode() {
    z-skk-set-mode "hiragana"
}

# Switch to katakana mode
z-skk-katakana-mode() {
    z-skk-set-mode "katakana"
}

# Switch to zenkaku mode
z-skk-zenkaku-mode() {
    z-skk-set-mode "zenkaku"
}

# Switch to abbrev mode
z-skk-abbrev-mode() {
    z-skk-set-mode "abbrev"
}

# Toggle between hiragana and ASCII (C-j behavior)
z-skk-toggle-kana() {
    case "$Z_SKK_MODE" in
        ascii)
            z-skk-hiragana-mode
            ;;
        katakana|zenkaku|abbrev)
            z-skk-hiragana-mode
            ;;
        *)
            z-skk-ascii-mode
            ;;
    esac
}

# Get current mode display string
z-skk-get-mode-string() {
    echo "${Z_SKK_MODE_NAMES[$Z_SKK_MODE]:-$Z_SKK_MODE}"
}

# Mode indicator for prompts (future use)
z-skk-mode-indicator() {
    local mode_str="$(z-skk-get-mode-string)"
    case "$Z_SKK_MODE" in
        hiragana)
            echo "[あ]"
            ;;
        katakana)
            echo "[ア]"
            ;;
        ascii)
            echo "[_A]"
            ;;
        zenkaku)
            echo "[Ａ]"
            ;;
        abbrev)
            echo "[aA]"
            ;;
        *)
            echo "[$mode_str]"
            ;;
    esac
}
