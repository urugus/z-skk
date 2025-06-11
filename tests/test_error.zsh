#!/usr/bin/env zsh
# Test error handling functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test error handling functions exist
assert '[[ -n ${functions[_z-skk-log-error]} ]]' "_z-skk-log-error function exists"
assert '[[ -n ${functions[z-skk-safe-source]} ]]' "z-skk-safe-source function exists"
assert '[[ -n ${functions[z-skk-safe-zle]} ]]' "z-skk-safe-zle function exists"
assert '[[ -n ${functions[z-skk-error-reset]} ]]' "z-skk-error-reset function exists"

# Test safe source with non-existent file
z-skk-safe-source "/tmp/non-existent-file.zsh" 2>&1
exit_code=$?
result=$(z-skk-safe-source "/tmp/non-existent-file.zsh" 2>&1)
assert "[[ $exit_code -ne 0 ]]" "Safe source returns error for non-existent file"
assert '[[ "$result" == *"WARN"* ]]' "Safe source logs warning for non-existent file"

# Test error reset
Z_SKK_MODE="hiragana"
Z_SKK_ROMAJI_BUFFER="test"
z-skk-error-reset "test-context"
assert_equals "Mode after error reset" "ascii" "$Z_SKK_MODE"
assert_equals "Romaji buffer after error reset" "" "$Z_SKK_ROMAJI_BUFFER"

# Test error logging levels
Z_SKK_ERROR_LEVEL="error"
output=$(_z-skk-log-error "info" "Test info" 2>&1)
assert_equals "Info not logged at error level" "" "$output"

output=$(_z-skk-log-error "error" "Test error" 2>&1)
assert '[[ "$output" == *"ERROR"* ]]' "Error logged at error level"

print_test_summary