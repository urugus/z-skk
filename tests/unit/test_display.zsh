#!/usr/bin/env zsh
# Test display functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test display functions exist
assert '[[ -n ${functions[z-skk-display-init]} ]]' "z-skk-display-init function exists"
assert '[[ -n ${functions[z-skk-update-display]} ]]' "z-skk-update-display function exists"
assert '[[ -n ${functions[z-skk-precmd-hook]} ]]' "z-skk-precmd-hook function exists"
assert '[[ -n ${functions[z-skk-display-setup]} ]]' "z-skk-display-setup function exists"
assert '[[ -n ${functions[z-skk-display-cleanup]} ]]' "z-skk-display-cleanup function exists"

# Test mode indicator function
mode_indicator=$(z-skk-mode-indicator)
assert_equals "ASCII mode indicator" "[_A]" "$mode_indicator"

# Switch to hiragana mode
z-skk-hiragana-mode
mode_indicator=$(z-skk-mode-indicator)
assert_equals "Hiragana mode indicator" "[あ]" "$mode_indicator"

# Switch to katakana mode
z-skk-katakana-mode
mode_indicator=$(z-skk-mode-indicator)
assert_equals "Katakana mode indicator" "[ア]" "$mode_indicator"

# Test update display with disabled state
RPROMPT=""
Z_SKK_ORIGINAL_RPROMPT="original"
Z_SKK_ENABLED=0
z-skk-update-display
assert_equals "RPROMPT restored when disabled" "original" "$RPROMPT"

# Test update display with enabled state
Z_SKK_ENABLED=1
z-skk-ascii-mode
z-skk-update-display
assert '[[ "$RPROMPT" == "[_A] original" ]]' "Mode indicator prepended when enabled"

# Test precmd_functions array
assert '[[ -n "${precmd_functions}" ]]' "precmd_functions variable exists"
assert '[[ "${precmd_functions[*]}" == *"z-skk-precmd-hook"* ]]' "precmd hook is in array"

# Test cleanup
z-skk-display-cleanup
assert_equals "RPROMPT restored after cleanup" "original" "$RPROMPT"

print_test_summary