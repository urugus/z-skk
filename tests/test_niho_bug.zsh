#!/usr/bin/env zsh
# Test for the "Niho" → "んほ*" bug fix
# This tests that uppercase N at the start of conversion doesn't trigger okurigana mode

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

print "Testing uppercase N handling (Niho bug fix):"

# Test 1: Basic "Niho" conversion
print "\nTest 1: 'Niho' should convert to 'にほ', not 'んほ*'"

# Reset state
Z_SKK_MODE="hiragana"
Z_SKK_CONVERTING=0
Z_SKK_BUFFER=""
Z_SKK_ROMAJI_BUFFER=""
Z_SKK_LAST_INPUT=""
Z_SKK_OKURIGANA_MODE=0

# Simulate typing "Niho"
_z-skk-detect-conversion-trigger "N"
_z-skk-process-hiragana-character "N"
assert_equals "After 'N': converting state" "1" "$Z_SKK_CONVERTING"
assert_equals "After 'N': buffer empty" "" "$Z_SKK_BUFFER"
assert_equals "After 'N': romaji has 'n'" "n" "$Z_SKK_ROMAJI_BUFFER"

# Check that 'i' doesn't trigger okurigana
local should_start_okurigana=0
if _z-skk-should-start-okurigana "i"; then
    should_start_okurigana=1
fi
assert_equals "After 'N', 'i' should NOT trigger okurigana" "0" "$should_start_okurigana"

_z-skk-process-hiragana-character "i"
assert_equals "After 'Ni': buffer has 'に'" "に" "$Z_SKK_BUFFER"
assert_equals "After 'Ni': okurigana mode off" "0" "$Z_SKK_OKURIGANA_MODE"

_z-skk-process-hiragana-character "h"
_z-skk-process-hiragana-character "o"
assert_equals "After 'Niho': buffer" "にほ" "$Z_SKK_BUFFER"
assert_equals "After 'Niho': no romaji pending" "" "$Z_SKK_ROMAJI_BUFFER"

# Test 2: Uppercase during conversion should trigger okurigana
print "\nTest 2: 'kaKu' should trigger okurigana mode"

# Reset state
Z_SKK_MODE="hiragana"
Z_SKK_CONVERTING=0
Z_SKK_BUFFER=""
Z_SKK_ROMAJI_BUFFER=""
Z_SKK_LAST_INPUT=""
Z_SKK_OKURIGANA_MODE=0

# Type "ka" then "K" (uppercase during conversion)
_z-skk-detect-conversion-trigger "k"  # lowercase doesn't start conversion
_z-skk-process-hiragana-character "k"
_z-skk-process-hiragana-character "a"
assert_equals "After 'ka': not converting" "0" "$Z_SKK_CONVERTING"

# Now uppercase K to start conversion
_z-skk-detect-conversion-trigger "K"
Z_SKK_CONVERTING=1  # Start conversion
Z_SKK_BUFFER=""     # Reset buffer for conversion
Z_SKK_ROMAJI_BUFFER=""
_z-skk-process-hiragana-character "K"
_z-skk-process-hiragana-character "a"
assert_equals "After 'Ka': buffer" "か" "$Z_SKK_BUFFER"

# Another uppercase K during conversion
Z_SKK_LAST_INPUT="K"
_z-skk-process-hiragana-character "K"
_z-skk-process-hiragana-character "u"

# Now lowercase 'u' after uppercase 'K' should trigger okurigana
should_start_okurigana=0
if _z-skk-should-start-okurigana "u"; then
    should_start_okurigana=1
fi
assert_equals "After second 'K', 'u' SHOULD trigger okurigana" "1" "$should_start_okurigana"

# Test 3: Single 'N' at start shouldn't immediately convert to 'ん'
print "\nTest 3: Single 'N' shouldn't immediately convert to 'ん'"

# Reset state
Z_SKK_MODE="hiragana"
Z_SKK_CONVERTING=0
Z_SKK_BUFFER=""
Z_SKK_ROMAJI_BUFFER=""

# Type just 'N'
_z-skk-detect-conversion-trigger "N"
_z-skk-process-hiragana-character "N"

# The 'n' should stay in romaji buffer, not convert immediately
assert_equals "Single 'N': romaji buffer" "n" "$Z_SKK_ROMAJI_BUFFER"
assert_equals "Single 'N': SKK buffer empty" "" "$Z_SKK_BUFFER"

# Print summary
print_test_summary