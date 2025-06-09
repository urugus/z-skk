#!/usr/bin/env zsh
# Test mode switching functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test mode switching functions exist
assert "z-skk-set-mode function exists" "(( \${+functions[z-skk-set-mode]} ))"
assert "z-skk-toggle-kana function exists" "(( \${+functions[z-skk-toggle-kana]} ))"
assert "z-skk-ascii-mode function exists" "(( \${+functions[z-skk-ascii-mode]} ))"
assert "z-skk-hiragana-mode function exists" "(( \${+functions[z-skk-hiragana-mode]} ))"

# Test initial state
assert_equals "Initial mode is ascii" "ascii" "$Z_SKK_MODE"

# Test mode switching
z-skk-hiragana-mode
assert_equals "Switch to hiragana mode" "hiragana" "$Z_SKK_MODE"
assert_equals "Romaji buffer cleared on mode switch" "" "$Z_SKK_ROMAJI_BUFFER"

z-skk-ascii-mode
assert_equals "Switch to ascii mode" "ascii" "$Z_SKK_MODE"

# Test z-skk-set-mode function
z-skk-set-mode "katakana"
assert_equals "Set mode to katakana" "katakana" "$Z_SKK_MODE"

z-skk-set-mode "hiragana"
assert_equals "Set mode to hiragana" "hiragana" "$Z_SKK_MODE"

# Test invalid mode
z-skk-set-mode "invalid"
assert_equals "Invalid mode doesn't change current mode" "hiragana" "$Z_SKK_MODE"

# Test toggle kana function (C-j behavior)
Z_SKK_MODE="ascii"
z-skk-toggle-kana
assert_equals "Toggle from ascii goes to hiragana" "hiragana" "$Z_SKK_MODE"

z-skk-toggle-kana
assert_equals "Toggle from hiragana goes to ascii" "ascii" "$Z_SKK_MODE"

# Test mode switching clears buffers
Z_SKK_MODE="hiragana"
Z_SKK_ROMAJI_BUFFER="test"
Z_SKK_BUFFER="buffer"
z-skk-ascii-mode
assert_equals "Mode switch clears romaji buffer" "" "$Z_SKK_ROMAJI_BUFFER"
assert_equals "Mode switch clears main buffer" "" "$Z_SKK_BUFFER"

# Test mode display names
assert "Mode display names are defined" "[[ -n \${Z_SKK_MODES[hiragana]} ]]"
assert_equals "Hiragana mode display" "かな" "${Z_SKK_MODES[hiragana]}"
assert_equals "ASCII mode display" "英数" "${Z_SKK_MODES[ascii]}"

# Print summary and exit
print_test_summary