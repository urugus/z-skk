#!/usr/bin/env zsh
# Test dictionary functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test dictionary module loaded
# Functions should be loaded by plugin initialization
assert "z-skk-lookup function exists" '(( ${+functions[z-skk-lookup]} ))'
assert "z-skk-split-candidates function exists" '(( ${+functions[z-skk-split-candidates]} ))'
assert "z-skk-get-candidate-word function exists" '(( ${+functions[z-skk-get-candidate-word]} ))'
assert "z-skk-get-candidate-annotation function exists" '(( ${+functions[z-skk-get-candidate-annotation]} ))'

# Test dictionary entries exist
assert "Z_SKK_DICTIONARY exists" '[[ -v Z_SKK_DICTIONARY ]]'
assert "Z_SKK_DICTIONARY is associative array" '[[ ${(t)Z_SKK_DICTIONARY} == *"association"* ]]'

# Test basic lookup
test_basic_lookup() {
    local result

    # Test existing word
    result=$(z-skk-lookup "かんじ")
    assert_equals "Lookup かんじ" "漢字:kanji/感じ:feeling/幹事:organizer" "$result"

    # Test non-existing word
    z-skk-lookup "ないよ" >/dev/null 2>&1
    assert_equals "Non-existing word returns failure" "1" "$?"
}

# Test candidate splitting
test_candidate_splitting() {
    local -a candidates

    # Split candidates
    candidates=("${(@f)$(z-skk-split-candidates "漢字:kanji/感じ:feeling/幹事:organizer")}")

    assert_equals "Number of candidates" "3" "${#candidates[@]}"
    assert_equals "First candidate" "漢字:kanji" "${candidates[1]}"
    assert_equals "Second candidate" "感じ:feeling" "${candidates[2]}"
    assert_equals "Third candidate" "幹事:organizer" "${candidates[3]}"
}

# Test candidate word extraction
test_candidate_word_extraction() {
    local word

    # Extract word without annotation
    word=$(z-skk-get-candidate-word "漢字:kanji")
    assert_equals "Extract word" "漢字" "$word"

    # Extract from word without annotation
    word=$(z-skk-get-candidate-word "漢字")
    assert_equals "Extract word without annotation" "漢字" "$word"
}

# Test candidate annotation extraction
test_candidate_annotation() {
    local annotation

    # Extract annotation
    annotation=$(z-skk-get-candidate-annotation "漢字:kanji")
    assert_equals "Extract annotation" "kanji" "$annotation"

    # Extract from word without annotation
    annotation=$(z-skk-get-candidate-annotation "漢字")
    assert_equals "No annotation returns empty" "" "$annotation"
}

# Test multiple meaning words
test_multiple_meanings() {
    local result
    local -a candidates

    # Lookup word with multiple meanings
    result=$(z-skk-lookup "はし")
    candidates=("${(@f)$(z-skk-split-candidates "$result")}")

    assert_equals "はし has 3 candidates" "3" "${#candidates[@]}"

    # Check each candidate
    local word
    word=$(z-skk-get-candidate-word "${candidates[1]}")
    assert_equals "First candidate is 橋" "橋" "$word"

    word=$(z-skk-get-candidate-word "${candidates[2]}")
    assert_equals "Second candidate is 箸" "箸" "$word"

    word=$(z-skk-get-candidate-word "${candidates[3]}")
    assert_equals "Third candidate is 端" "端" "$word"
}

# Run tests
test_basic_lookup
test_candidate_splitting
test_candidate_word_extraction
test_candidate_annotation
test_multiple_meanings

print_test_summary