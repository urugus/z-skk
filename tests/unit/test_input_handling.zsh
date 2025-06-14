#!/usr/bin/env zsh
# Merged unit test for input handling functionality
# Combines test cases from test_input.zsh, test_hiragana_input.zsh, and test_ascii_mode.zsh

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"  # Parent directory (tests/)
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# =============================================================================
# Function Existence Tests
# =============================================================================
print "Testing function existence:"

# Core input handler functions
assert '[[ -n ${functions[z-skk-handle-input]} ]]' "z-skk-handle-input function exists"
assert '[[ -n ${functions[_z-skk-handle-ascii-input]} ]]' "_z-skk-handle-ascii-input function exists"
assert '[[ -n ${functions[_z-skk-handle-hiragana-input]} ]]' "_z-skk-handle-hiragana-input function exists"
assert '[[ -n ${functions[_z-skk-handle-katakana-input]} ]]' "_z-skk-handle-katakana-input function exists"
assert '[[ -n ${functions[_z-skk-handle-zenkaku-input]} ]]' "_z-skk-handle-zenkaku-input function exists"
assert '[[ -n ${functions[_z-skk-handle-abbrev-input]} ]]' "_z-skk-handle-abbrev-input function exists"

# Widget and control functions
assert "(( \${+functions[z-skk-self-insert]} ))" "z-skk-self-insert widget exists"
assert "(( \${+functions[z-skk-enable]} ))" "z-skk-enable function exists"
assert "(( \${+functions[z-skk-disable]} ))" "z-skk-disable function exists"

# =============================================================================
# ASCII Mode Tests
# =============================================================================
print "\nTesting ASCII mode:"

# Test ASCII mode is default
assert "[[ \$Z_SKK_MODE == 'ascii' ]]" "Default mode is ASCII"

# Test enable/disable functionality
z-skk-disable
assert "[[ \$Z_SKK_ENABLED -eq 0 ]]" "z-skk-disable sets enabled flag to 0"

z-skk-enable
assert "[[ \$Z_SKK_ENABLED -eq 1 ]]" "z-skk-enable sets enabled flag to 1"

# Mock ZLE functions for testing
zle() {
    case "$1" in
        .self-insert) return 0 ;;
        -R) return 0 ;;
        *) return 1 ;;
    esac
}

# Test mode-specific input handling in ASCII mode
Z_SKK_MODE="ascii"
Z_SKK_ROMAJI_BUFFER=""
_z-skk-handle-ascii-input
assert_equals "ASCII mode romaji buffer remains empty" "" "$Z_SKK_ROMAJI_BUFFER"

# Test pass-through behavior (if function exists)
if (( ${+functions[z-skk-should-pass-through]} )); then
    # Mock KEYS variable for testing
    KEYS="a"
    typeset -g Z_SKK_PASS_THROUGH=0
    z-skk-should-pass-through
    assert "[[ \$Z_SKK_PASS_THROUGH -eq 1 ]]" "ASCII mode passes through regular characters"
    
    # Test capital letters
    KEYS="A"
    Z_SKK_PASS_THROUGH=0
    z-skk-should-pass-through
    assert "[[ \$Z_SKK_PASS_THROUGH -eq 1 ]]" "ASCII mode passes through capital letters"
fi

# =============================================================================
# Hiragana Mode Tests
# =============================================================================
print "\nTesting hiragana mode:"

# Test mode switching
Z_SKK_MODE="hiragana"
Z_SKK_ROMAJI_BUFFER=""
_z-skk-handle-hiragana-input "a"
assert_equals "Hiragana mode 'a' input" "a" "$Z_SKK_ROMAJI_BUFFER"

# Test mode switching with 'l' key
Z_SKK_MODE="hiragana"
current_mode="$Z_SKK_MODE"
_z-skk-handle-hiragana-input "l"
assert_equals "Mode after 'l' in hiragana" "ascii" "$Z_SKK_MODE"

# =============================================================================
# Romaji Conversion Tests
# =============================================================================
print "\nTesting romaji conversion:"

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

# Test 4: Sequential input - "nihongo" (にほんご)
local result=""

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

# Test 5: 'n' handling - "kana" vs "kann"
# Test "kana"
Z_SKK_ROMAJI_BUFFER="ka"
z-skk-convert-romaji
local kana_result="$Z_SKK_CONVERTED"  # Should be "か"

Z_SKK_ROMAJI_BUFFER="na"
z-skk-convert-romaji
kana_result+="$Z_SKK_CONVERTED"  # Should be "な"

assert_equals "Input 'kana' produces 'かな'" "かな" "$kana_result"

# Test "kann" (double n)
Z_SKK_ROMAJI_BUFFER="ka"
z-skk-convert-romaji
local kann_result="$Z_SKK_CONVERTED"  # Should be "か"

Z_SKK_ROMAJI_BUFFER="nn"
z-skk-convert-romaji
kann_result+="$Z_SKK_CONVERTED"  # Should be "ん"

assert_equals "Input 'kann' produces 'かん'" "かん" "$kann_result"

# =============================================================================
# Cleanup
# =============================================================================
# Remove mock functions
unfunction zle 2>/dev/null || true

# Print test summary
print_test_summary