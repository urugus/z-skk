#!/usr/bin/env zsh
# Input mode management for z-skk

# Set the input mode
z-skk-set-mode() {
    local new_mode="$1"

    # Validate mode
    if [[ -z "${Z_SKK_MODES[$new_mode]}" ]]; then
        # Invalid mode, do nothing
        return 1
    fi

    # Clear buffers when switching modes
    if [[ "$Z_SKK_MODE" != "$new_mode" ]]; then
        z-skk-reset-state
        Z_SKK_MODE="$new_mode"

        # Mode-specific initialization
        case "$new_mode" in
            hiragana|katakana)
                Z_SKK_ROMAJI_BUFFER=""
                ;;
            ascii|zenkaku)
                # No special initialization needed
                ;;
            abbrev)
                # Future: Initialize abbrev mode
                ;;
        esac
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

# Toggle between hiragana and ASCII (C-j behavior)
z-skk-toggle-kana() {
    if [[ "$Z_SKK_MODE" == "hiragana" ]]; then
        z-skk-ascii-mode
    else
        z-skk-hiragana-mode
    fi
}

# Get current mode display string
z-skk-get-mode-string() {
    echo "${Z_SKK_MODES[$Z_SKK_MODE]:-$Z_SKK_MODE}"
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
