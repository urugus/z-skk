#!/usr/bin/env zsh
# Test dictionary I/O functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
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

# Test dictionary format parsing
test_parse_dict_line() {
    # Valid line
    local result=($(_z-skk-parse-dict-line "かんじ /漢字/感じ;feeling/幹事/"))
    assert_equals "Parse reading" "かんじ" "${result[1]}"
    assert_equals "Parse candidates" "漢字/感じ;feeling/幹事" "${result[2]}"

    # Comment line
    _z-skk-parse-dict-line ";; comment" >/dev/null 2>&1
    assert_equals "Skip comment" "1" "$?"

    # Empty line
    _z-skk-parse-dict-line "" >/dev/null 2>&1
    assert_equals "Skip empty" "1" "$?"

    # Invalid format
    _z-skk-parse-dict-line "invalid line" >/dev/null 2>&1
    assert_equals "Skip invalid" "1" "$?"
}

# Test dictionary file loading
test_load_dictionary_file() {
    # Create test dictionary file
    local test_dict="$TEST_DICT_DIR/test_load.jisyo"
    cat > "$test_dict" <<'EOF'
;; Test dictionary
あい /愛/相/
かき /柿/牡蠣;oyster/
;; Another comment

さけ /酒/鮭/
EOF

    # Clear dictionary first
    Z_SKK_DICTIONARY=()

    # Load file
    z-skk-load-dictionary-file "$test_dict"

    # Check loaded entries
    assert '[[ -n "${Z_SKK_DICTIONARY[あい]}" ]]' "あい loaded"
    assert_equals "あい candidates" "愛/相" "${Z_SKK_DICTIONARY[あい]}"

    assert '[[ -n "${Z_SKK_DICTIONARY[かき]}" ]]' "かき loaded"
    assert_equals "かき candidates" "柿/牡蠣;oyster" "${Z_SKK_DICTIONARY[かき]}"

    assert '[[ -n "${Z_SKK_DICTIONARY[さけ]}" ]]' "さけ loaded"
    assert_equals "さけ candidates" "酒/鮭" "${Z_SKK_DICTIONARY[さけ]}"
}

# Test user dictionary saving
test_save_user_dictionary() {
    # Setup user dictionary
    typeset -gA Z_SKK_USER_DICTIONARY
    Z_SKK_USER_DICTIONARY=()
    Z_SKK_USER_DICTIONARY[てすと]="テスト/test"
    Z_SKK_USER_DICTIONARY[ほぞん]="保存"

    # Save
    z-skk-save-user-dictionary

    # Check file exists
    assert "[[ -f '$SKK_JISYO_PATH' ]]" "Dictionary saved"

    # Check content
    local content=$(cat "$SKK_JISYO_PATH")
    assert '[[ "$content" == *"z-skk user dictionary"* ]]' "Has header"
    assert '[[ "$content" == *"てすと /テスト/test/"* ]]' "Has てすと"
    assert '[[ "$content" == *"ほぞん /保存/"* ]]' "Has ほぞん"
}

# Test adding user entries
test_add_user_entry() {
    # Clear dictionaries
    Z_SKK_USER_DICTIONARY=()
    Z_SKK_DICTIONARY=()

    # Add new entry
    z-skk-add-user-entry "あたらしい" "新しい"

    assert_equals "User dict updated" "新しい" "${Z_SKK_USER_DICTIONARY[あたらしい]}"
    assert_equals "Main dict updated" "新しい" "${Z_SKK_DICTIONARY[あたらしい]}"

    # Add another candidate to same reading
    z-skk-add-user-entry "あたらしい" "新しい;new"

    assert_equals "User dict merged" "新しい;new/新しい" "${Z_SKK_USER_DICTIONARY[あたらしい]}"
    assert_equals "Main dict merged" "新しい;new/新しい" "${Z_SKK_DICTIONARY[あたらしい]}"

    # Try to add duplicate
    z-skk-add-user-entry "あたらしい" "新しい"

    # Should not duplicate
    assert '[[ "${Z_SKK_USER_DICTIONARY[あたらしい]}" != *"新しい/新しい"* ]]' "No duplicate"
}

# Test dictionary initialization
test_init_dictionary_loading() {
    # Create test user dictionary
    cat > "$SKK_JISYO_PATH" <<'EOF'
;; User dictionary
ゆーざー /ユーザー/user/
EOF

    # Clear and reinit
    Z_SKK_DICTIONARY=()
    z-skk-init-dictionary-loading

    # Check if loaded
    assert '[[ -n "${Z_SKK_DICTIONARY[ゆーざー]}" ]]' "User dict loaded"
    assert_equals "User entry" "ユーザー/user" "${Z_SKK_DICTIONARY[ゆーざー]}"
}

# Run tests
test_parse_dict_line
test_load_dictionary_file
test_save_user_dictionary
test_add_user_entry
test_init_dictionary_loading

# Cleanup
rm -rf "$TEST_DICT_DIR"

print_test_summary