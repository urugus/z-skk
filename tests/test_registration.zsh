#!/usr/bin/env zsh
# Test dictionary registration functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"
typeset -g TEST_DICT_DIR="${TEST_DIR}/test_dict_$$"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Create test directory
mkdir -p "$TEST_DICT_DIR"

# Set test dictionary paths
export SKK_JISYO_PATH="$TEST_DICT_DIR/test.jisyo"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Force load registration module for testing
if (( ${+functions[z-skk-lazy-load-module]} )); then
    z-skk-lazy-load-module "registration"
else
    # Fallback: source directly
    source "$PROJECT_DIR/lib/registration.zsh"
fi

# Test registration mode initialization
test_registration_init() {
    # Clear state
    z-skk-reset-state

    # Start registration
    z-skk-start-registration "あたらしい"

    assert_equals "Registration mode active" "1" "$Z_SKK_REGISTERING"
    assert_equals "Registration reading" "あたらしい" "$Z_SKK_REGISTER_READING"
    assert_equals "Registration candidate empty" "" "$Z_SKK_REGISTER_CANDIDATE"
}

# Test registration input handling
test_registration_input() {
    # Setup
    z-skk-reset-state
    z-skk-start-registration "テスト"

    # Input characters
    z-skk-registration-input "t"
    assert_equals "First char" "t" "$Z_SKK_REGISTER_CANDIDATE"

    z-skk-registration-input "e"
    assert_equals "Second char" "te" "$Z_SKK_REGISTER_CANDIDATE"

    z-skk-registration-input "s"
    assert_equals "Third char" "tes" "$Z_SKK_REGISTER_CANDIDATE"

    z-skk-registration-input "t"
    assert_equals "Fourth char" "test" "$Z_SKK_REGISTER_CANDIDATE"
}

# Test registration confirmation
test_registration_confirm() {
    # Clear dictionaries
    Z_SKK_USER_DICTIONARY=()
    Z_SKK_DICTIONARY=()

    # Setup
    z-skk-reset-state
    LBUFFER=""
    z-skk-start-registration "てすと"

    # Input word
    z-skk-registration-input "テ"
    z-skk-registration-input "ス"
    z-skk-registration-input "ト"

    # Confirm
    z-skk-confirm-registration

    assert_equals "Registration mode inactive" "0" "$Z_SKK_REGISTERING"
    assert_equals "Word added to user dict" "テスト" "${Z_SKK_USER_DICTIONARY[てすと]}"
    assert_equals "Word added to main dict" "テスト" "${Z_SKK_DICTIONARY[てすと]}"
    assert_equals "Word inserted in buffer" "テスト" "$LBUFFER"
}

# Test registration cancellation
test_registration_cancel() {
    # Setup
    z-skk-reset-state
    LBUFFER=""
    local original_dict_size=${#Z_SKK_DICTIONARY[@]}

    z-skk-start-registration "きゃんせる"
    z-skk-registration-input "c"
    z-skk-registration-input "a"

    # Cancel
    z-skk-cancel-registration

    assert_equals "Registration mode inactive" "0" "$Z_SKK_REGISTERING"
    assert_equals "Original reading inserted" "きゃんせる" "$LBUFFER"
    assert_equals "Dictionary unchanged" "$original_dict_size" "${#Z_SKK_DICTIONARY[@]}"
}

# Test backspace in registration
test_registration_backspace() {
    # Setup
    z-skk-reset-state
    z-skk-start-registration "ばっく"

    # Input and delete
    z-skk-registration-input "b"
    z-skk-registration-input "a"
    z-skk-registration-input "c"
    assert_equals "Before backspace" "bac" "$Z_SKK_REGISTER_CANDIDATE"

    # Backspace
    z-skk-registration-input $'\x7f'
    assert_equals "After backspace" "ba" "$Z_SKK_REGISTER_CANDIDATE"

    # Another backspace
    z-skk-registration-input $'\x7f'
    assert_equals "After second backspace" "b" "$Z_SKK_REGISTER_CANDIDATE"
}

# Test conversion to registration flow
test_conversion_to_registration() {
    # Setup - ensure word is not in dictionary
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    LBUFFER=""

    # Clear the word from dictionary if it exists
    if [[ -n "${Z_SKK_DICTIONARY[みとうろく]+x}" ]]; then
        unset "Z_SKK_DICTIONARY[みとうろく]"
    fi
    if [[ -n "${Z_SKK_USER_DICTIONARY[みとうろく]+x}" ]]; then
        unset "Z_SKK_USER_DICTIONARY[みとうろく]"
    fi

    # Start conversion with non-existent word
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="みとうろく"

    # Trigger conversion (Space key)
    z-skk-start-conversion

    # Should be in registration mode
    assert_equals "Registration mode active" "1" "$Z_SKK_REGISTERING"
    assert_equals "Registration reading" "みとうろく" "$Z_SKK_REGISTER_READING"
}

# Run tests
test_registration_init
test_registration_input
test_registration_confirm
test_registration_cancel
test_registration_backspace
test_conversion_to_registration

# Cleanup
rm -rf "$TEST_DICT_DIR"

print_test_summary