#!/usr/bin/env zsh
# Test refactoring changes

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test display utilities
test_display_utilities() {
    # Test marker functions exist
    assert '(( ${+functions[z-skk-clear-marker]} ))' "z-skk-clear-marker exists"
    assert '(( ${+functions[z-skk-add-marker]} ))' "z-skk-add-marker exists"
    assert '(( ${+functions[z-skk-update-marker]} ))' "z-skk-update-marker exists"
    assert '(( ${+functions[z-skk-safe-redraw]} ))' "z-skk-safe-redraw exists"

    # Test marker operations
    LBUFFER="test"
    RBUFFER=""
    z-skk-add-marker "▽" "かんじ"
    assert_equals "Add marker" "test▽かんじ" "$LBUFFER"

    z-skk-clear-marker "▽" "かんじ"
    assert_equals "Clear marker" "test" "$LBUFFER"
}

# Test utility functions
test_utility_functions() {
    # Test utils loading
    assert '(( ${+functions[z-skk-safe-execute]} ))' "z-skk-safe-execute exists"
    assert '(( ${+functions[z-skk-save-state]} ))' "z-skk-save-state exists"
    assert '(( ${+functions[z-skk-restore-state]} ))' "z-skk-restore-state exists"
    assert '(( ${+functions[z-skk-full-reset]} ))' "z-skk-full-reset exists"

    # Test state save/restore
    Z_SKK_MODE="hiragana"
    Z_SKK_BUFFER="test"
    Z_SKK_CONVERTING=1

    z-skk-save-state

    # Change state
    Z_SKK_MODE="ascii"
    Z_SKK_BUFFER=""
    Z_SKK_CONVERTING=0

    z-skk-restore-state

    assert_equals "Mode restored" "hiragana" "$Z_SKK_MODE"
    assert_equals "Buffer restored" "test" "$Z_SKK_BUFFER"
    assert_equals "Converting restored" "1" "$Z_SKK_CONVERTING"
}

# Test refactored conversion functions
test_conversion_refactoring() {
    # Test new internal functions exist
    assert '(( ${+functions[_z-skk-lookup-candidates]} ))' "_z-skk-lookup-candidates exists"
    assert '(( ${+functions[_z-skk-prepare-candidates]} ))' "_z-skk-prepare-candidates exists"
    assert '(( ${+functions[_z-skk-switch-to-selection-mode]} ))' "_z-skk-switch-to-selection-mode exists"

    # Test conversion still works
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="かんじ"

    z-skk-start-conversion

    assert_equals "Candidates loaded" "2" "$Z_SKK_CONVERTING"
    assert '[[ ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]' "Has candidates"
}

# Test full reset functionality
test_full_reset() {
    # Set various states
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=2
    Z_SKK_BUFFER="test"
    Z_SKK_CANDIDATES=("候補1" "候補2")
    Z_SKK_CANDIDATE_INDEX=1
    Z_SKK_ROMAJI_BUFFER="k"
    Z_SKK_REGISTERING=1
    Z_SKK_REGISTER_READING="test"
    Z_SKK_REGISTER_CANDIDATE="テスト"
    LBUFFER="▽test"

    # Full reset
    z-skk-full-reset

    assert_equals "Buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "Converting reset" "0" "$Z_SKK_CONVERTING"
    assert_equals "Candidates cleared" "0" "${#Z_SKK_CANDIDATES[@]}"
    assert_equals "Romaji buffer cleared" "" "$Z_SKK_ROMAJI_BUFFER"
    assert_equals "Registration reset" "0" "$Z_SKK_REGISTERING"
    assert_equals "Register reading cleared" "" "$Z_SKK_REGISTER_READING"
    assert_equals "Register candidate cleared" "" "$Z_SKK_REGISTER_CANDIDATE"
}

# Test error handling wrapper
test_error_handling() {
    # Test safe execute with success
    local result
    z-skk-safe-execute "test operation" true
    assert_equals "Safe execute success" "0" "$?"

    # Test safe execute with failure
    z-skk-safe-execute "test operation" false 2>/dev/null
    assert_equals "Safe execute failure" "1" "$?"
}

# Run tests
test_display_utilities
test_utility_functions
test_conversion_refactoring
test_full_reset
test_error_handling

print_test_summary