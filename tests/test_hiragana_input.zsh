#!/usr/bin/env zsh
# Test hiragana input simulation

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Simulate romaji input sequences
print "Testing romaji input sequences:"

# Test 1: Simple vowel
Z_SKK_ROMAJI_BUFFER=""
Z_SKK_ROMAJI_BUFFER+="a"
z-skk-convert-romaji
assert_equals "Input 'a' produces 'あ'" "あ" "$Z_SKK_CONVERTED"

# Test 2: Consonant + vowel
Z_SKK_ROMAJI_BUFFER=""
Z_SKK_ROMAJI_BUFFER+="k"
z-skk-convert-romaji
assert_equals "Input 'k' produces nothing (partial)" "" "$Z_SKK_CONVERTED"
Z_SKK_ROMAJI_BUFFER+="a"
z-skk-convert-romaji
assert_equals "Input 'ka' produces 'か'" "か" "$Z_SKK_CONVERTED"

# Test 3: Special combinations
Z_SKK_ROMAJI_BUFFER=""
Z_SKK_ROMAJI_BUFFER+="s"
z-skk-convert-romaji
assert_equals "Input 's' produces nothing (partial)" "" "$Z_SKK_CONVERTED"
Z_SKK_ROMAJI_BUFFER+="h"
z-skk-convert-romaji
assert_equals "Input 'sh' produces nothing (partial)" "" "$Z_SKK_CONVERTED"
Z_SKK_ROMAJI_BUFFER+="i"
z-skk-convert-romaji
assert_equals "Input 'shi' produces 'し'" "し" "$Z_SKK_CONVERTED"

# Test 4: Sequential input
local result=""

# Simulate typing "nihongo" (にほんご)
# n -> (wait)
# ni -> に
# h -> (wait)
# ho -> ほ
# n -> (wait)
# ng -> ん + g
# go -> ご

Z_SKK_ROMAJI_BUFFER="n"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be empty

Z_SKK_ROMAJI_BUFFER+="i"  # "ni"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be "に"

Z_SKK_ROMAJI_BUFFER+="h"  # "h"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be empty

Z_SKK_ROMAJI_BUFFER+="o"  # "ho"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be "ほ"

Z_SKK_ROMAJI_BUFFER+="n"  # "n"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be empty

Z_SKK_ROMAJI_BUFFER+="g"  # "ng" -> "ん" + "g"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be "ん"

Z_SKK_ROMAJI_BUFFER+="o"  # "go"
z-skk-convert-romaji
result+="$Z_SKK_CONVERTED"  # Should be "ご"

assert_equals "Sequential input 'nihongo' produces 'にほんご'" "にほんご" "$result"

# Test 5: 'n' handling
# Type "kana" vs "kann"
Z_SKK_ROMAJI_BUFFER="ka"
z-skk-convert-romaji
local kana_result="$Z_SKK_CONVERTED"  # Should be "か"

Z_SKK_ROMAJI_BUFFER="na"
z-skk-convert-romaji
kana_result+="$Z_SKK_CONVERTED"  # Should be "な"

assert_equals "Input 'kana' produces 'かな'" "かな" "$kana_result"

# Test double n
Z_SKK_ROMAJI_BUFFER="ka"
z-skk-convert-romaji
local kann_result="$Z_SKK_CONVERTED"  # Should be "か"

Z_SKK_ROMAJI_BUFFER="nn"
z-skk-convert-romaji
kann_result+="$Z_SKK_CONVERTED"  # Should be "ん"

assert_equals "Input 'kann' produces 'かん'" "かん" "$kann_result"

# Print summary and exit
print_test_summary