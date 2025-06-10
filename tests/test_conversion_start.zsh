#!/usr/bin/env zsh
# Test conversion start functionality

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

# Test uppercase detection starts conversion
test_uppercase_starts_conversion() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""

    # Input uppercase 'K'
    _z-skk-handle-hiragana-input "K"

    assert_equals "Conversion mode after uppercase" "1" "$Z_SKK_CONVERTING"
    assert_equals "Romaji buffer has lowercase k" "k" "$Z_SKK_ROMAJI_BUFFER"
    assert_equals "Conversion buffer is empty" "" "$Z_SKK_BUFFER"
}

# Test lowercase doesn't start conversion
test_lowercase_no_conversion() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""

    # Input lowercase 'k'
    _z-skk-handle-hiragana-input "k"

    assert_equals "No conversion mode after lowercase" "0" "$Z_SKK_CONVERTING"
    assert_equals "Romaji buffer has k" "k" "$Z_SKK_ROMAJI_BUFFER"
}

# Test conversion buffer accumulation
test_conversion_buffer_accumulation() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""

    # Start conversion with 'K'
    _z-skk-handle-hiragana-input "K"
    assert_equals "Conversion started" "1" "$Z_SKK_CONVERTING"

    # Add 'a' to complete 'ka'
    _z-skk-handle-hiragana-input "a"
    assert_equals "Conversion buffer has か" "か" "$Z_SKK_BUFFER"
    assert_equals "Romaji buffer is empty" "" "$Z_SKK_ROMAJI_BUFFER"

    # Add 'n'
    _z-skk-handle-hiragana-input "n"
    assert_equals "Romaji buffer has n" "n" "$Z_SKK_ROMAJI_BUFFER"

    # Add 'j' to complete 'nj' -> 'ん' + 'j'
    _z-skk-handle-hiragana-input "j"
    assert_equals "Conversion buffer has かん" "かん" "$Z_SKK_BUFFER"
    assert_equals "Romaji buffer has j" "j" "$Z_SKK_ROMAJI_BUFFER"

    # Add 'i' to complete 'ji' -> 'じ'
    _z-skk-handle-hiragana-input "i"
    assert_equals "Conversion buffer has かんじ" "かんじ" "$Z_SKK_BUFFER"
    assert_equals "Romaji buffer is empty after conversion" "" "$Z_SKK_ROMAJI_BUFFER"
}

# Test display marker update
test_conversion_display_marker() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER=""
    RBUFFER=""

    # Start conversion
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="かんじ"

    # Update display
    z-skk-update-conversion-display

    assert "Display has ▽ marker" '[[ "$RBUFFER" == "▽かんじ"* ]]'
}

# Test C-g cancels conversion
test_cancel_conversion() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="かんじ"
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="test"
    RBUFFER=""

    # Send C-g
    _z-skk-handle-converting-input $'\x07'

    assert_equals "Conversion mode cancelled" "0" "$Z_SKK_CONVERTING"
    assert_equals "Buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "LBUFFER has converted text" "testかんじ" "$LBUFFER"
}

# Test Space key during conversion
test_space_during_conversion() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="かんじ"
    Z_SKK_ROMAJI_BUFFER=""

    # Send Space
    _z-skk-handle-converting-input " "

    # For now, it should cancel (no dictionary yet)
    assert_equals "Conversion cancelled (no dictionary)" "0" "$Z_SKK_CONVERTING"
}

# Test Enter key during conversion
test_enter_during_conversion() {
    # Reset state
    z-skk-hiragana-mode
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="かんじ"
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="test"
    RBUFFER=""

    # Send Enter
    _z-skk-handle-converting-input $'\r'

    assert_equals "Conversion confirmed" "0" "$Z_SKK_CONVERTING"
    assert_equals "Buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "LBUFFER has converted text" "testかんじ" "$LBUFFER"
}

# Run tests
test_uppercase_starts_conversion
test_lowercase_no_conversion
test_conversion_buffer_accumulation
test_conversion_display_marker
test_cancel_conversion
test_space_during_conversion
test_enter_during_conversion

# Cleanup
unfunction zle 2>/dev/null || true

print_test_summary