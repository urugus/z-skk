#!/usr/bin/env zsh
# Test refactoring improvements

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test unified reset function
test_unified_reset() {
    # Set up various states
    Z_SKK_BUFFER="test"
    Z_SKK_CONVERTING=1
    Z_SKK_CANDIDATES=("a" "b" "c")
    Z_SKK_CANDIDATE_INDEX=2
    Z_SKK_ROMAJI_BUFFER="ro"

    # Test basic reset
    z-skk-reset
    assert_equals "Core buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "Converting cleared" "0" "$Z_SKK_CONVERTING"
    assert_equals "Candidates cleared" "0" "${#Z_SKK_CANDIDATES[@]}"
    assert_equals "Romaji cleared" "" "$Z_SKK_ROMAJI_BUFFER"

    # Test selective reset
    Z_SKK_BUFFER="test"
    Z_SKK_ROMAJI_BUFFER="ro"
    z-skk-reset core:1 romaji:0
    assert_equals "Core cleared" "" "$Z_SKK_BUFFER"
    assert_equals "Romaji not cleared" "ro" "$Z_SKK_ROMAJI_BUFFER"

    # Test all reset
    Z_SKK_BUFFER="test"
    Z_SKK_CODE_INPUT_MODE=1
    Z_SKK_CODE_BUFFER="1234"
    z-skk-reset all
    assert_equals "All: buffer cleared" "" "$Z_SKK_BUFFER"
    assert_equals "All: special mode cleared" "0" "$Z_SKK_CODE_INPUT_MODE"
    assert_equals "All: special buffer cleared" "" "$Z_SKK_CODE_BUFFER"
}

# Test conversion table performance
test_conversion_tables() {
    # Test hiragana to katakana
    assert_equals "Table: あ->ア" "ア" "${Z_SKK_HIRAGANA_TO_KATAKANA[あ]}"
    assert_equals "Table: ん->ン" "ン" "${Z_SKK_HIRAGANA_TO_KATAKANA[ん]}"

    # Test function with table
    assert_equals "Func: か->カ" "カ" "$(z-skk-hiragana-to-katakana 'か')"

    # Test ASCII to zenkaku
    assert_equals "Table: A->Ａ" "Ａ" "${Z_SKK_ASCII_TO_ZENKAKU[A]}"
    assert_equals "Table: 1->１" "１" "${Z_SKK_ASCII_TO_ZENKAKU[1]}"

    # Test function with table
    assert_equals "Func: a->ａ" "ａ" "$(z-skk-convert-to-zenkaku 'a')"

    # Test JIS conversion
    assert_equals "JIS: 3042->あ" "あ" "${Z_SKK_JIS_TO_CHAR[3042]}"
    assert_equals "Func: 30a2->ア" "ア" "$(z-skk-jis-to-char '30a2')"
}

# Test error handling standardization
test_error_handling() {
    # Mock error function
    _z-skk-log-error() { : ; }

    # Test safe operation with success
    local result
    z-skk-safe-operation "test" echo "success"
    result=$?
    assert_equals "Safe op success" "0" "$result"

    # Test safe operation with failure
    # Set up recovery table for test - ensure clean state
    typeset -gA Z_SKK_ERROR_RECOVERY
    Z_SKK_ERROR_RECOVERY[test]=":"
    z-skk-safe-operation "test" false
    result=$?
    assert_equals "Safe op failure" "1" "$result"

    # Test safe call
    result=$(z-skk-safe-call "test" echo "hello")
    assert_equals "Safe call result" "hello" "$result"

    # Test recovery strategy
    Z_SKK_BUFFER="test"
    z-skk-safe-operation "conversion" false
    assert_equals "Recovery executed" "" "$Z_SKK_BUFFER"
}

# Test command dispatch
test_command_dispatch() {
    # Mock command functions
    z-skk-test-cmd1() { echo "cmd1"; }
    z-skk-test-cmd2() { echo "cmd2"; }

    # Create test dispatch table
    typeset -gA Z_SKK_TEST_COMMANDS=(
        [a]="z-skk-test-cmd1"
        [b]="z-skk-test-cmd2"
    )

    # Test successful dispatch
    local result=$(z-skk-dispatch-command "TEST" "a")
    assert_equals "Dispatch a" "cmd1" "$result"

    result=$(z-skk-dispatch-command "TEST" "b")
    assert_equals "Dispatch b" "cmd2" "$result"

    # Test unknown key with default
    z-skk-dispatch-command "TEST" "x" "return:1"
    assert_equals "Unknown key returns 1" "1" "$?"
}

# Test hiragana command dispatch
test_hiragana_commands() {
    # Ensure command table exists
    assert '[[ -v Z_SKK_HIRAGANA_COMMANDS ]]' "Hiragana commands exist"

    # Check key mappings
    assert_equals "l -> ascii" "z-skk-ascii-mode" "${Z_SKK_HIRAGANA_COMMANDS[l]}"
    assert_equals "q -> katakana" "z-skk-katakana-mode" "${Z_SKK_HIRAGANA_COMMANDS[q]}"
    assert_equals "X -> convert" "z-skk-convert-previous-to-katakana" "${Z_SKK_HIRAGANA_COMMANDS[X]}"
    local at_key="@"
    assert_equals "@ -> date" "z-skk-insert-date" "${Z_SKK_HIRAGANA_COMMANDS[$at_key]}"
}

# Test reset aliases
test_reset_aliases() {
    # Test conversion reset
    Z_SKK_BUFFER="test"
    Z_SKK_ROMAJI_BUFFER="ro"
    z-skk-reset-conversion
    assert_equals "Conv reset: buffer" "" "$Z_SKK_BUFFER"
    assert_equals "Conv reset: romaji" "" "$Z_SKK_ROMAJI_BUFFER"

    # Test registration reset
    Z_SKK_REGISTERING=1
    Z_SKK_REGISTER_READING="test"
    z-skk-reset-registration
    assert_equals "Reg reset: mode" "0" "$Z_SKK_REGISTERING"
    assert_equals "Reg reset: reading" "" "$Z_SKK_REGISTER_READING"
}

# Run tests
test_unified_reset
test_conversion_tables
test_error_handling
test_command_dispatch
test_hiragana_commands
test_reset_aliases

print_test_summary