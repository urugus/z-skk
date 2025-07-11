#!/usr/bin/env zsh
# Test okurigana processing

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test okurigana mode detection
test_okurigana_detection() {
    # Test uppercase followed by lowercase detection
    assert 'z-skk-check-okurigana-start "K" "a"' "Should detect okurigana"
    assert 'z-skk-check-okurigana-start "O" "k"' "Should detect okurigana"
    assert '! z-skk-check-okurigana-start "k" "a"' "Should not detect okurigana"
    assert '! z-skk-check-okurigana-start "K" "A"' "Should not detect okurigana"
}

# Test okurigana mode initialization
test_okurigana_mode_init() {
    # Reset state
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    Z_SKK_BUFFER="おく"

    # Start okurigana mode
    z-skk-start-okurigana

    assert_equals "Okurigana mode active" "1" "$Z_SKK_OKURIGANA_MODE"
    assert_equals "Prefix stored" "おく" "$Z_SKK_OKURIGANA_PREFIX"
    assert_equals "Buffer kept for okurigana" "おく" "$Z_SKK_BUFFER"
}

# Test okurigana key building
test_okurigana_key_building() {
    # Test key with okurigana
    local key=$(z-skk-build-okurigana-key "おく" "り")
    assert_equals "Built key with okurigana" "おく*り" "$key"

    # Test key without okurigana
    key=$(z-skk-build-okurigana-key "かんじ" "")
    assert_equals "Built key without okurigana" "かんじ" "$key"
}

# Test okurigana lookup
test_okurigana_lookup() {
    # Test direct okurigana lookup
    local result=$(z-skk-lookup-with-okurigana "おく" "り")
    assert_equals "Found okurigana entry" "送り:send" "$result"

    # Test okurigana filtering fallback
    result=$(z-skk-lookup-with-okurigana "おく" "る")
    assert_equals "Found okurigana entry る" "送る:to send" "$result"
}

# Test okurigana input processing
test_okurigana_input_processing() {
    # Reset state
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    LBUFFER=""
    Z_SKK_LAST_INPUT=""

    # Simulate "OkuRi" input
    # O -> start conversion (already in converting mode)
    Z_SKK_ROMAJI_BUFFER="o"
    z-skk-convert-romaji
    if [[ -n "$Z_SKK_CONVERTED" ]]; then
        Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
    fi
    assert_equals "Buffer has お" "お" "$Z_SKK_BUFFER"

    # ku -> complete "ku"
    Z_SKK_ROMAJI_BUFFER="ku"
    z-skk-convert-romaji
    if [[ -n "$Z_SKK_CONVERTED" ]]; then
        Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
    fi
    assert_equals "Buffer has おく" "おく" "$Z_SKK_BUFFER"

    # R -> should set last input for okurigana detection
    Z_SKK_LAST_INPUT="R"

    # ri -> complete okurigana
    # First check if should start okurigana
    if [[ "r" =~ ^[a-z]$ && "$Z_SKK_LAST_INPUT" =~ ^[A-Z]$ && -n "$Z_SKK_BUFFER" ]]; then
        z-skk-start-okurigana
        z-skk-process-okurigana "r"
        z-skk-process-okurigana "i"
    fi

    assert_equals "Okurigana mode active" "1" "$Z_SKK_OKURIGANA_MODE"
    assert_equals "Okurigana suffix" "り" "$Z_SKK_OKURIGANA_SUFFIX"
}

# Test okurigana conversion
test_okurigana_conversion() {
    # Reset and set up okurigana state
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="おくり"  # Buffer contains full text before conversion
    Z_SKK_OKURIGANA_MODE=1
    Z_SKK_OKURIGANA_PREFIX="おく"
    Z_SKK_OKURIGANA_SUFFIX=""  # Will be set by complete_okurigana
    LBUFFER=""

    # Start conversion
    z-skk-start-conversion

    assert_equals "Conversion successful" "2" "$Z_SKK_CONVERTING"
    assert '[[ ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]' "Has candidates"
    assert_equals "First candidate" "送り" "${Z_SKK_CANDIDATES[1]}"
}

# Test SKK okuri-ari format lookup (NEW)
test_okuri_ari_format_lookup() {
    # Add SKK format okuri-ari entry
    Z_SKK_DICTIONARY=()
    Z_SKK_DICTIONARY[おくr]="送る/贈る"
    Z_SKK_DICTIONARY[かえs]="返す/帰す"
    Z_SKK_DICTIONARY[さがs]="探す:to search"

    # Test lookup with okurigana
    local result=$(z-skk-lookup-with-okurigana "おく" "る")
    assert '[[ -n "$result" ]]' "Found okuri-ari entry"
    assert '[[ "$result" == *"送る"* ]]' "Contains 送る"

    # Test with different okurigana
    local result2=$(z-skk-lookup-with-okurigana "かえ" "す")
    assert '[[ -n "$result2" ]]' "Found かえs entry"
    assert '[[ "$result2" == *"返す"* ]]' "Contains 返す"

    # Test SagaSu -> 探す conversion
    local result3=$(z-skk-lookup-with-okurigana "さが" "す")
    assert '[[ -n "$result3" ]]' "Found さがs entry"
    assert '[[ "$result3" == *"探す"* ]]' "Contains 探す"
}

# Test okurigana display
test_okurigana_display() {
    # Reset state
    z-skk-reset-state
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_OKURIGANA_MODE=1
    Z_SKK_OKURIGANA_PREFIX="おく"
    Z_SKK_BUFFER="おく"
    # Calculate the suffix from buffer and prefix
    Z_SKK_OKURIGANA_SUFFIX="り"
    LBUFFER=""

    # Update display
    z-skk-update-conversion-display

    # The display shows buffer with asterisk and suffix
    assert '[[ "$LBUFFER" == "▽おく*り" ]]' "Display has marker and suffix"
}

# Test okurigana reset
test_okurigana_reset() {
    # Set okurigana state
    Z_SKK_OKURIGANA_MODE=1
    Z_SKK_OKURIGANA_PREFIX="test"
    Z_SKK_OKURIGANA_SUFFIX="suffix"

    # Reset
    z-skk-reset-okurigana

    assert_equals "Mode reset" "0" "$Z_SKK_OKURIGANA_MODE"
    assert_equals "Prefix cleared" "" "$Z_SKK_OKURIGANA_PREFIX"
    assert_equals "Suffix cleared" "" "$Z_SKK_OKURIGANA_SUFFIX"
}

# Run tests
test_okurigana_detection
test_okurigana_mode_init
test_okurigana_key_building
test_okurigana_lookup
test_okurigana_input_processing
test_okurigana_conversion
test_okuri_ari_format_lookup
test_okurigana_display
test_okurigana_reset

print_test_summary