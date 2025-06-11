#!/usr/bin/env zsh
# Test refactoring changes

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test unified reset function
test_unified_reset() {
    # Test basic reset
    Z_SKK_BUFFER="test"
    Z_SKK_CONVERTING=1
    Z_SKK_CANDIDATES=("a" "b")

    z-skk-unified-reset "basic"

    assert_equals "Buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "Converting reset" "0" "$Z_SKK_CONVERTING"
    assert_equals "Candidates cleared" "0" "${#Z_SKK_CANDIDATES[@]}"

    # Test full reset with registration state
    Z_SKK_REGISTERING=1
    Z_SKK_REGISTER_READING="test"
    Z_SKK_REGISTER_CANDIDATE="テスト"

    z-skk-unified-reset "full"

    assert_equals "Registration reset" "0" "$Z_SKK_REGISTERING"
    assert_equals "Register reading cleared" "" "$Z_SKK_REGISTER_READING"
    assert_equals "Register candidate cleared" "" "$Z_SKK_REGISTER_CANDIDATE"

    # Test display reset
    LBUFFER="▽test"
    z-skk-unified-reset "display"

    # Display markers should be cleared (though we can't test visual output)
    assert_equals "Display dirty flag reset" "0" "$Z_SKK_DISPLAY_DIRTY"
}

# Test compatibility wrapper
test_reset_compatibility() {
    # z-skk-reset-state should use unified reset
    Z_SKK_BUFFER="test"
    z-skk-reset-state
    assert_equals "reset-state uses unified reset" "" "$Z_SKK_BUFFER"

    # z-skk-full-reset should use unified reset with display
    Z_SKK_BUFFER="test"
    Z_SKK_DISPLAY_DIRTY=1
    z-skk-full-reset
    assert_equals "full-reset clears buffer" "" "$Z_SKK_BUFFER"
    assert_equals "full-reset clears display" "0" "$Z_SKK_DISPLAY_DIRTY"
}

# Test module loading system
test_module_loading() {
    # Module configuration should exist
    assert "Module config exists" '[[ -v Z_SKK_MODULES ]]'
    assert "Module order exists" '[[ -v Z_SKK_MODULE_ORDER ]]'

    # Check required modules are marked correctly
    assert_equals "error is required" "required" "${Z_SKK_MODULES[error]}"
    assert_equals "utils is required" "required" "${Z_SKK_MODULES[utils]}"
    assert_equals "display is optional" "optional" "${Z_SKK_MODULES[display]}"

    # Module loading functions should exist
    assert "Load module function exists" '(( ${+functions[_z-skk-load-module]} ))'
    assert "Load all modules function exists" '(( ${+functions[_z-skk-load-all-modules]} ))'
}

# Test split converting input functions
test_split_converting_input() {
    # New functions should exist
    assert "_z-skk-handle-pre-conversion-input exists" '(( ${+functions[_z-skk-handle-pre-conversion-input]} ))'
    assert "_z-skk-should-start-okurigana exists" '(( ${+functions[_z-skk-should-start-okurigana]} ))'
    assert "_z-skk-process-converting-character exists" '(( ${+functions[_z-skk-process-converting-character]} ))'

    # Test okurigana detection
    Z_SKK_BUFFER="test"
    Z_SKK_LAST_INPUT="K"
    assert "Should detect okurigana" '_z-skk-should-start-okurigana "a"'

    Z_SKK_LAST_INPUT="k"
    assert "Should not detect okurigana" '! _z-skk-should-start-okurigana "a"'
}

# Test error handling functions
test_error_handling() {
    # Safe operation function should exist
    assert "Safe operation exists" '(( ${+functions[z-skk-safe-operation]} ))'

    # Test successful operation
    _test_success() { return 0; }
    assert "Safe operation succeeds" 'z-skk-safe-operation "test" _test_success'

    # Test failing operation with recovery
    _test_fail() { return 1; }
    Z_SKK_CONVERTING=1
    z-skk-safe-operation "conversion_test" _test_fail 2>/dev/null
    # Should attempt recovery (cancel conversion)
    assert_equals "Recovery performed" "0" "$Z_SKK_CONVERTING"
}

# Test perform conversion separation
test_perform_conversion() {
    # New function should exist
    assert "_z-skk-perform-conversion exists" '(( ${+functions[_z-skk-perform-conversion]} ))'

    # Test conversion start uses safe operation
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="かんじ"

    # This should use the new error handling
    z-skk-start-conversion

    # Should have candidates
    assert "Has candidates after conversion" '[[ ${#Z_SKK_CANDIDATES[@]} -gt 0 ]]'
}

# Run tests
test_unified_reset
test_reset_compatibility
test_module_loading
test_split_converting_input
test_error_handling
test_perform_conversion

print_test_summary