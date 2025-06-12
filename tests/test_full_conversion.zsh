#!/usr/bin/env zsh
# Test full conversion flow

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Mock ZLE functions for testing
zle() {
    case "$1" in
        .self-insert) return 0 ;;
        -R) return 0 ;;
        *) return 1 ;;
    esac
}

# Mock LBUFFER and RBUFFER
typeset -g LBUFFER=""
typeset -g RBUFFER=""

# Test full conversion flow
test_full_conversion_flow() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    Z_SKK_CANDIDATES=()
    Z_SKK_CANDIDATE_INDEX=0
    LBUFFER=""
    RBUFFER=""

    # Input "Kanji" to start conversion
    _z-skk-handle-hiragana-input "K"
    assert_equals "Conversion started" "1" "$Z_SKK_CONVERTING"

    _z-skk-handle-hiragana-input "a"
    assert_equals "Buffer has か" "か" "$Z_SKK_BUFFER"

    _z-skk-handle-hiragana-input "n"
    _z-skk-handle-hiragana-input "j"
    _z-skk-handle-hiragana-input "i"
    assert_equals "Buffer has かんじ" "かんじ" "$Z_SKK_BUFFER"

    # Press Space to start conversion
    _z-skk-handle-converting-input " "
    assert_equals "Moved to candidate selection" "2" "$Z_SKK_CONVERTING"
    assert '[[ ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]' "Has candidates"
    assert_equals "First candidate is 漢字" "漢字" "${Z_SKK_CANDIDATES[1]}"
}

# Test candidate navigation
test_candidate_navigation() {
    # Setup: already in candidate selection mode
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=2
    Z_SKK_BUFFER="かんじ"
    Z_SKK_CANDIDATES=("漢字" "感じ" "幹事")
    Z_SKK_CANDIDATE_INDEX=0
    LBUFFER=""
    RBUFFER=""

    # Initial candidate
    assert_equals "Initial candidate index" "0" "$Z_SKK_CANDIDATE_INDEX"

    # Press Space to go to next
    z-skk-next-candidate
    assert_equals "Next candidate index" "1" "$Z_SKK_CANDIDATE_INDEX"

    # Press Space again
    z-skk-next-candidate
    assert_equals "Next candidate index" "2" "$Z_SKK_CANDIDATE_INDEX"

    # Press Space to wrap around
    z-skk-next-candidate
    assert_equals "Wrapped to first" "0" "$Z_SKK_CANDIDATE_INDEX"

    # Press x to go back
    z-skk-previous-candidate
    assert_equals "Previous wraps to last" "2" "$Z_SKK_CANDIDATE_INDEX"
}

# Test candidate confirmation
test_candidate_confirmation() {
    # Setup
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=2
    Z_SKK_BUFFER="かんじ"
    Z_SKK_CANDIDATES=("漢字" "感じ" "幹事")
    Z_SKK_CANDIDATE_INDEX=1
    LBUFFER="test"
    RBUFFER=""

    # Confirm with Enter
    z-skk-confirm-candidate

    assert_equals "Conversion completed" "0" "$Z_SKK_CONVERTING"
    assert_equals "Buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "LBUFFER has selected candidate" "test感じ" "$LBUFFER"
}

# Test conversion cancellation
test_conversion_cancellation() {
    # Setup
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=2
    Z_SKK_BUFFER="かんじ"
    Z_SKK_CANDIDATES=("漢字" "感じ" "幹事")
    Z_SKK_CANDIDATE_INDEX=1
    LBUFFER="test"
    RBUFFER=""

    # Cancel with C-g
    z-skk-cancel-conversion

    assert_equals "Conversion cancelled" "0" "$Z_SKK_CONVERTING"
    assert_equals "Buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "LBUFFER has original text" "testかんじ" "$LBUFFER"
}

# Test word with no candidates
test_no_candidates() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="ないよ"
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="test"
    RBUFFER=""

    # Try to convert
    z-skk-start-conversion

    # Should enter registration mode since no candidates
    assert_equals "Registration mode started" "1" "$Z_SKK_REGISTERING"
    assert_equals "Registration reading" "ないよ" "$Z_SKK_REGISTER_READING"

    # Cancel registration to get original text
    z-skk-cancel-registration
    assert_equals "Registration cancelled" "0" "$Z_SKK_REGISTERING"
    assert_equals "LBUFFER has original text" "testないよ" "$LBUFFER"
}

# Run tests
test_full_conversion_flow
test_candidate_navigation
test_candidate_confirmation
test_conversion_cancellation
test_no_candidates

# Cleanup
unfunction zle 2>/dev/null || true

print_test_summary