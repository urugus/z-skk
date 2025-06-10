#!/usr/bin/env zsh
# Test input handling functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test input handler functions exist
assert '[[ -n ${functions[z-skk-handle-input]} ]]' "z-skk-handle-input function exists"
assert '[[ -n ${functions[_z-skk-handle-ascii-input]} ]]' "_z-skk-handle-ascii-input function exists"
assert '[[ -n ${functions[_z-skk-handle-hiragana-input]} ]]' "_z-skk-handle-hiragana-input function exists"
assert '[[ -n ${functions[_z-skk-handle-katakana-input]} ]]' "_z-skk-handle-katakana-input function exists"
assert '[[ -n ${functions[_z-skk-handle-zenkaku-input]} ]]' "_z-skk-handle-zenkaku-input function exists"
assert '[[ -n ${functions[_z-skk-handle-abbrev-input]} ]]' "_z-skk-handle-abbrev-input function exists"

# Mock ZLE functions for testing
zle() {
    case "$1" in
        .self-insert) return 0 ;;
        -R) return 0 ;;
        *) return 1 ;;
    esac
}

# Test mode-specific input handling
# ASCII mode
Z_SKK_MODE="ascii"
Z_SKK_ROMAJI_BUFFER=""
_z-skk-handle-ascii-input
assert_equals "ASCII mode romaji buffer" "" "$Z_SKK_ROMAJI_BUFFER"

# Hiragana mode - special keys
Z_SKK_MODE="hiragana"
Z_SKK_ROMAJI_BUFFER=""
_z-skk-handle-hiragana-input "a"
assert_equals "Hiragana mode 'a' input" "a" "$Z_SKK_ROMAJI_BUFFER"

# Test mode switching with 'l' key
Z_SKK_MODE="hiragana"
current_mode="$Z_SKK_MODE"
_z-skk-handle-hiragana-input "l"
assert_equals "Mode after 'l' in hiragana" "ascii" "$Z_SKK_MODE"

# Cleanup mock
unfunction zle 2>/dev/null || true

print_test_summary