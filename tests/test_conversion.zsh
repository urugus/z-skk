#!/usr/bin/env zsh
# Test romaji to hiragana conversion

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test conversion table exists
assert "ROMAJI_TO_HIRAGANA table exists" "[[ -n \${ROMAJI_TO_HIRAGANA+x} ]]"
assert "ROMAJI_TO_HIRAGANA is associative array" "[[ \${(t)ROMAJI_TO_HIRAGANA} == association* ]]"

# Test single vowel conversions
assert_equals "Convert 'a' to 'あ'" "あ" "${ROMAJI_TO_HIRAGANA[a]}"
assert_equals "Convert 'i' to 'い'" "い" "${ROMAJI_TO_HIRAGANA[i]}"
assert_equals "Convert 'u' to 'う'" "う" "${ROMAJI_TO_HIRAGANA[u]}"
assert_equals "Convert 'e' to 'え'" "え" "${ROMAJI_TO_HIRAGANA[e]}"
assert_equals "Convert 'o' to 'お'" "お" "${ROMAJI_TO_HIRAGANA[o]}"

# Test basic consonant + vowel combinations
assert_equals "Convert 'ka' to 'か'" "か" "${ROMAJI_TO_HIRAGANA[ka]}"
assert_equals "Convert 'ki' to 'き'" "き" "${ROMAJI_TO_HIRAGANA[ki]}"
assert_equals "Convert 'ku' to 'く'" "く" "${ROMAJI_TO_HIRAGANA[ku]}"
assert_equals "Convert 'ke' to 'け'" "け" "${ROMAJI_TO_HIRAGANA[ke]}"
assert_equals "Convert 'ko' to 'こ'" "こ" "${ROMAJI_TO_HIRAGANA[ko]}"

# Test 'n' conversion
assert_equals "Convert 'n' to 'ん'" "ん" "${ROMAJI_TO_HIRAGANA[n]}"
assert_equals "Convert 'nn' to 'ん'" "ん" "${ROMAJI_TO_HIRAGANA[nn]}"

# Test special cases
assert_equals "Convert 'shi' to 'し'" "し" "${ROMAJI_TO_HIRAGANA[shi]}"
assert_equals "Convert 'chi' to 'ち'" "ち" "${ROMAJI_TO_HIRAGANA[chi]}"
assert_equals "Convert 'tsu' to 'つ'" "つ" "${ROMAJI_TO_HIRAGANA[tsu]}"

# Test conversion function
assert "z-skk-convert-romaji function exists" "(( \${+functions[z-skk-convert-romaji]} ))"

# Test romaji buffer management
assert "ROMAJI_BUFFER variable exists" "[[ -n \${ROMAJI_BUFFER+x} ]]"

# Test conversion logic
ROMAJI_BUFFER="a"
z-skk-convert-romaji
assert_equals "Convert buffer 'a' to 'あ'" "あ" "$Z_SKK_CONVERTED"
assert_equals "Romaji buffer cleared after conversion" "" "$ROMAJI_BUFFER"

ROMAJI_BUFFER="ka"
z-skk-convert-romaji
assert_equals "Convert buffer 'ka' to 'か'" "か" "$Z_SKK_CONVERTED"
assert_equals "Romaji buffer cleared after conversion" "" "$ROMAJI_BUFFER"

# Test partial matches
ROMAJI_BUFFER="k"
z-skk-convert-romaji
assert_equals "Partial match 'k' returns empty" "" "$Z_SKK_CONVERTED"
assert_equals "Romaji buffer keeps 'k' for partial match" "k" "$ROMAJI_BUFFER"

# Print summary and exit
print_test_summary