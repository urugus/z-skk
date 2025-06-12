#!/usr/bin/env zsh
# Test special key functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test X key - convert previous character to katakana
test_x_key_conversion() {
    # Test single hiragana to katakana
    Z_SKK_MODE="hiragana"
    LBUFFER="あいうえお"

    z-skk-convert-previous-to-katakana
    assert_equals "Last char converted" "あいうえオ" "$LBUFFER"

    # Test with mixed content
    LBUFFER="こんにちは"
    z-skk-convert-previous-to-katakana
    assert_equals "は -> ハ" "こんにちハ" "$LBUFFER"

    # Test empty buffer
    LBUFFER=""
    local result=$(z-skk-convert-previous-to-katakana; echo $?)
    assert_equals "Empty buffer returns error" "1" "$result"

    # Test in non-hiragana mode
    Z_SKK_MODE="ascii"
    LBUFFER="test"
    result=$(z-skk-convert-previous-to-katakana; echo $?)
    assert_equals "Non-hiragana mode returns error" "1" "$result"
}

# Test hiragana to katakana conversion function
test_hiragana_to_katakana() {
    # Test basic conversions
    assert_equals "あ -> ア" "ア" "$(z-skk-hiragana-to-katakana 'あ')"
    assert_equals "か -> カ" "カ" "$(z-skk-hiragana-to-katakana 'か')"
    assert_equals "が -> ガ" "ガ" "$(z-skk-hiragana-to-katakana 'が')"
    assert_equals "ん -> ン" "ン" "$(z-skk-hiragana-to-katakana 'ん')"

    # Test small characters
    assert_equals "っ -> ッ" "ッ" "$(z-skk-hiragana-to-katakana 'っ')"
    assert_equals "ゃ -> ャ" "ャ" "$(z-skk-hiragana-to-katakana 'ゃ')"

    # Test non-hiragana input
    assert_equals "Non-hiragana returns empty" "" "$(z-skk-hiragana-to-katakana 'A')"
}

# Test @ key - date insertion
test_at_key_date() {
    # Test in ASCII mode
    Z_SKK_MODE="ascii"
    LBUFFER=""
    z-skk-insert-date

    # Check format YYYY-MM-DD
    assert '[[ "$LBUFFER" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]' "Date format"

    # Test in hiragana mode (Japanese format)
    Z_SKK_MODE="hiragana"
    LBUFFER=""
    z-skk-insert-date

    # Check Japanese format
    assert '[[ "$LBUFFER" =~ ^令和[0-9]+年[0-9]+月[0-9]+日$ ]]' "Japanese date format"
}

# Test ; key - code input mode
test_semicolon_key_code_input() {
    # Start code input
    Z_SKK_MODE="hiragana"
    LBUFFER=""
    z-skk-code-input

    assert_equals "Code input mode active" "1" "$Z_SKK_CODE_INPUT_MODE"
    assert_equals "Semicolon shown" ";" "$LBUFFER"

    # Input code digits
    z-skk-process-code-input "3"
    assert_equals "First digit added" ";3" "$LBUFFER"
    assert_equals "Code buffer" "3" "$Z_SKK_CODE_BUFFER"

    z-skk-process-code-input "0"
    z-skk-process-code-input "4"
    z-skk-process-code-input "2"

    # Should auto-complete after 4 digits
    assert_equals "Code input completed" "0" "$Z_SKK_CODE_INPUT_MODE"

    # Cancel code input
    LBUFFER=""  # Clear buffer before test
    z-skk-code-input
    z-skk-process-code-input "1"
    z-skk-process-code-input "2"
    z-skk-cancel-code-input

    assert_equals "Code input cancelled" "0" "$Z_SKK_CODE_INPUT_MODE"
    assert_equals "Buffer restored" "" "$LBUFFER"
}

# Test special input mode check
test_special_input_mode_check() {
    # Reset all modes
    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_SUFFIX_MODE=0
    Z_SKK_PREFIX_MODE=0

    assert '! z-skk-is-special-input-mode' "Not in special mode"

    # Test code input mode
    Z_SKK_CODE_INPUT_MODE=1
    assert 'z-skk-is-special-input-mode' "In code input mode"

    # Test suffix mode
    Z_SKK_CODE_INPUT_MODE=0
    Z_SKK_SUFFIX_MODE=1
    assert 'z-skk-is-special-input-mode' "In suffix mode"

    # Test prefix mode
    Z_SKK_SUFFIX_MODE=0
    Z_SKK_PREFIX_MODE=1
    assert 'z-skk-is-special-input-mode' "In prefix mode"
}

# Test > key - suffix input
test_suffix_input() {
    Z_SKK_MODE="hiragana"
    LBUFFER=""

    z-skk-start-suffix-input

    assert_equals "Suffix mode active" "1" "$Z_SKK_SUFFIX_MODE"
    assert_equals "Marker shown" ">" "$LBUFFER"
}

# Test ? key - prefix input
test_prefix_input() {
    Z_SKK_MODE="hiragana"
    LBUFFER=""

    z-skk-start-prefix-input

    assert_equals "Prefix mode active" "1" "$Z_SKK_PREFIX_MODE"
    assert_equals "Marker shown" "?" "$LBUFFER"
}

# Test special mode reset
test_special_mode_reset() {
    # Set all modes
    Z_SKK_CODE_INPUT_MODE=1
    Z_SKK_CODE_BUFFER="test"
    Z_SKK_SUFFIX_MODE=1
    Z_SKK_SUFFIX_BUFFER="suffix"
    Z_SKK_PREFIX_MODE=1
    Z_SKK_PREFIX_BUFFER="prefix"

    z-skk-reset-special-modes

    assert_equals "Code mode reset" "0" "$Z_SKK_CODE_INPUT_MODE"
    assert_equals "Code buffer cleared" "" "$Z_SKK_CODE_BUFFER"
    assert_equals "Suffix mode reset" "0" "$Z_SKK_SUFFIX_MODE"
    assert_equals "Suffix buffer cleared" "" "$Z_SKK_SUFFIX_BUFFER"
    assert_equals "Prefix mode reset" "0" "$Z_SKK_PREFIX_MODE"
    assert_equals "Prefix buffer cleared" "" "$Z_SKK_PREFIX_BUFFER"
}

# Test special key handling in input
test_special_key_handling() {
    Z_SKK_MODE="hiragana"

    # Test X key handling
    assert '_z-skk-handle-hiragana-special-key "X"' "X key handled"

    # Test @ key handling
    assert '_z-skk-handle-hiragana-special-key "@"' "@ key handled"

    # Test ; key handling
    assert '_z-skk-handle-hiragana-special-key ";"' "; key handled"

    # Test > key handling
    assert '_z-skk-handle-hiragana-special-key ">"' "> key handled"

    # Test ? key handling
    assert '_z-skk-handle-hiragana-special-key "?"' "? key handled"

    # Test non-special key
    assert '! _z-skk-handle-hiragana-special-key "a"' "a key not special"
}

# Run tests
test_x_key_conversion
test_hiragana_to_katakana
test_at_key_date
test_semicolon_key_code_input
test_special_input_mode_check
test_suffix_input
test_prefix_input
test_special_mode_reset
test_special_key_handling

print_test_summary