#!/usr/bin/env zsh
# Test for missing candidates behavior

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Force load modules needed for testing
if (( ${+functions[z-skk-lazy-load-module]} )); then
    z-skk-lazy-load-module "registration"
else
    # Fallback: source directly
    source "$PROJECT_DIR/lib/dictionary/registration.zsh"
fi

test_missing_candidate_starts_registration() {
    # Setup
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    LBUFFER=""

    # Simulate typing "Sato"
    z-skk-handle-input "S"
    assert_equals "Should start conversion mode" "1" "$Z_SKK_CONVERTING"

    z-skk-handle-input "a"
    z-skk-handle-input "t"
    z-skk-handle-input "o"

    # Check buffer contains "さと"
    assert_equals "Buffer should contain 'さと'" "さと" "$Z_SKK_BUFFER"

    # Simulate pressing Space
    z-skk-handle-input " "

    # Debug output
    print "After Space: CONVERTING=$Z_SKK_CONVERTING, REGISTERING=$Z_SKK_REGISTERING"
    print "LBUFFER='$LBUFFER'"
    print "BUFFER='$Z_SKK_BUFFER', REGISTER_READING='$Z_SKK_REGISTER_READING'"

    # Should be in registration mode
    assert_equals "Should enter registration mode" "1" "$Z_SKK_REGISTERING"
    assert_equals "Should store reading" "さと" "$Z_SKK_REGISTER_READING"

    # The display should show ▼さと[]
    # Check if LBUFFER contains the registration marker
    local expected="▼さと[]"
    if [[ "$LBUFFER" == *"$expected"* ]]; then
        assert_equals "Should show registration marker" "$expected" "$expected"
    else
        assert_equals "Should show registration marker" "$expected" "$LBUFFER"
    fi
}

test_missing_candidate_cancel_registration() {
    # Setup
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    LBUFFER=""

    # Enter registration mode
    z-skk-handle-input "S"
    z-skk-handle-input "a"
    z-skk-handle-input "t"
    z-skk-handle-input "o"
    z-skk-handle-input " "

    # Cancel with C-g
    z-skk-handle-input $'\x07'

    # Should output original reading
    if [[ "$LBUFFER" == *"さと"* ]]; then
        assert_equals "Should output original reading" "contains さと" "contains さと"
    else
        assert_equals "Should output original reading" "contains さと" "$LBUFFER"
    fi
    assert_equals "Should exit registration mode" "0" "$Z_SKK_REGISTERING"
}

# Run tests
reset_test_counters

print "=== Testing missing candidates behavior ==="

test_missing_candidate_starts_registration
test_missing_candidate_cancel_registration

print_test_summary