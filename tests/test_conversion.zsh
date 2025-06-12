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
assert "[[ -n \${Z_SKK_ROMAJI_TO_HIRAGANA+x} ]]" "Z_SKK_ROMAJI_TO_HIRAGANA table exists"
assert "[[ \${(t)Z_SKK_ROMAJI_TO_HIRAGANA} == association* ]]" "Z_SKK_ROMAJI_TO_HIRAGANA is associative array"

# Test single vowel conversions
assert_equals "Convert 'a' to 'あ'" "あ" "${Z_SKK_ROMAJI_TO_HIRAGANA[a]}"
assert_equals "Convert 'i' to 'い'" "い" "${Z_SKK_ROMAJI_TO_HIRAGANA[i]}"
assert_equals "Convert 'u' to 'う'" "う" "${Z_SKK_ROMAJI_TO_HIRAGANA[u]}"
assert_equals "Convert 'e' to 'え'" "え" "${Z_SKK_ROMAJI_TO_HIRAGANA[e]}"
assert_equals "Convert 'o' to 'お'" "お" "${Z_SKK_ROMAJI_TO_HIRAGANA[o]}"

# Test basic consonant + vowel combinations
assert_equals "Convert 'ka' to 'か'" "か" "${Z_SKK_ROMAJI_TO_HIRAGANA[ka]}"
assert_equals "Convert 'ki' to 'き'" "き" "${Z_SKK_ROMAJI_TO_HIRAGANA[ki]}"
assert_equals "Convert 'ku' to 'く'" "く" "${Z_SKK_ROMAJI_TO_HIRAGANA[ku]}"
assert_equals "Convert 'ke' to 'け'" "け" "${Z_SKK_ROMAJI_TO_HIRAGANA[ke]}"
assert_equals "Convert 'ko' to 'こ'" "こ" "${Z_SKK_ROMAJI_TO_HIRAGANA[ko]}"

# Test 'n' conversion
assert_equals "Convert 'n' to 'ん'" "ん" "${Z_SKK_ROMAJI_TO_HIRAGANA[n]}"
assert_equals "Convert 'nn' to 'ん'" "ん" "${Z_SKK_ROMAJI_TO_HIRAGANA[nn]}"

# Test special cases
assert_equals "Convert 'shi' to 'し'" "し" "${Z_SKK_ROMAJI_TO_HIRAGANA[shi]}"
assert_equals "Convert 'chi' to 'ち'" "ち" "${Z_SKK_ROMAJI_TO_HIRAGANA[chi]}"
assert_equals "Convert 'tsu' to 'つ'" "つ" "${Z_SKK_ROMAJI_TO_HIRAGANA[tsu]}"

# Test conversion function
assert "(( \${+functions[z-skk-convert-romaji]} ))" "z-skk-convert-romaji function exists"

# Test romaji buffer management
assert "[[ -n \${Z_SKK_ROMAJI_BUFFER+x} ]]" "Z_SKK_ROMAJI_BUFFER variable exists"

# Test conversion logic
Z_SKK_ROMAJI_BUFFER="a"
z-skk-convert-romaji
assert_equals "Convert buffer 'a' to 'あ'" "あ" "$Z_SKK_CONVERTED"
assert_equals "Romaji buffer cleared after conversion" "" "$Z_SKK_ROMAJI_BUFFER"

Z_SKK_ROMAJI_BUFFER="ka"
z-skk-convert-romaji
assert_equals "Convert buffer 'ka' to 'か'" "か" "$Z_SKK_CONVERTED"
assert_equals "Romaji buffer cleared after conversion" "" "$Z_SKK_ROMAJI_BUFFER"

# Test partial matches
Z_SKK_ROMAJI_BUFFER="k"
z-skk-convert-romaji
assert_equals "Partial match 'k' returns empty" "" "$Z_SKK_CONVERTED"
assert_equals "Romaji buffer keeps 'k' for partial match" "k" "$Z_SKK_ROMAJI_BUFFER"

# Print summary and exit
print_test_summary