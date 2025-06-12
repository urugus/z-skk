#!/usr/bin/env zsh
# Test various input modes

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Load the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test katakana mode
test_katakana_mode() {
    # Reset state
    z-skk-reset-state
    z-skk-katakana-mode

    assert_equals "Mode is katakana" "katakana" "$Z_SKK_MODE"
    assert_equals "Mode display" "[ア]" "$(z-skk-mode-indicator)"

    # Test katakana conversion
    local result=$(z-skk-convert-romaji-to-katakana "ka")
    assert_equals "ka -> カ" "カ" "$result"

    result=$(z-skk-convert-romaji-to-katakana "shi")
    assert_equals "shi -> シ" "シ" "$result"

    # Single n with space or at end should convert
    Z_SKK_ROMAJI_BUFFER="n"
    result=$(z-skk-convert-romaji-to-katakana "nn")
    assert_equals "nn -> ン" "ン" "$result"

    # Test partial input
    result=$(z-skk-convert-romaji-to-katakana "k")
    assert_equals "k is partial" "" "$result"
}

# Test katakana input processing
test_katakana_input_processing() {
    z-skk-reset-state
    z-skk-katakana-mode
    LBUFFER=""
    RBUFFER=""
    Z_SKK_ROMAJI_BUFFER=""

    # Simulate "konnichiwa" in katakana
    _z-skk-handle-katakana-input "k"
    _z-skk-handle-katakana-input "o"
    assert_equals "ko -> コ" "コ" "$LBUFFER"

    # Reset romaji buffer for next input
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="コ"
    _z-skk-handle-katakana-input "n"
    assert_equals "n doesn't convert yet" "コ" "$LBUFFER"

    _z-skk-handle-katakana-input "n"
    assert_equals "nn -> ン" "コン" "$LBUFFER"

    # Reset for next
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="コン"
    _z-skk-handle-katakana-input "n"
    _z-skk-handle-katakana-input "i"
    assert_equals "ni -> ニ" "コンニ" "$LBUFFER"

    # Reset for next
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="コンニ"
    _z-skk-handle-katakana-input "c"
    _z-skk-handle-katakana-input "h"
    _z-skk-handle-katakana-input "i"
    assert_equals "chi -> チ" "コンニチ" "$LBUFFER"
}

# Test zenkaku mode
test_zenkaku_mode() {
    # Reset state
    z-skk-reset-state
    z-skk-zenkaku-mode

    assert_equals "Mode is zenkaku" "zenkaku" "$Z_SKK_MODE"
    assert_equals "Mode display" "[Ａ]" "$(z-skk-mode-indicator)"

    # Test ASCII to zenkaku conversion
    local result=$(z-skk-convert-to-zenkaku "A")
    assert_equals "A -> Ａ" "Ａ" "$result"

    result=$(z-skk-convert-to-zenkaku "1")
    assert_equals "1 -> １" "１" "$result"

    result=$(z-skk-convert-to-zenkaku " ")
    assert_equals "space -> 　" "　" "$result"

    result=$(z-skk-convert-to-zenkaku "!")
    assert_equals "! -> ！" "！" "$result"
}

# Test zenkaku input processing
test_zenkaku_input_processing() {
    z-skk-reset-state
    z-skk-zenkaku-mode
    LBUFFER=""
    RBUFFER=""

    # Simulate "Hello 123" in zenkaku
    _z-skk-handle-zenkaku-input "H"
    assert_equals "H -> Ｈ" "Ｈ" "$LBUFFER"

    _z-skk-handle-zenkaku-input "e"
    _z-skk-handle-zenkaku-input "l"
    _z-skk-handle-zenkaku-input "l"
    _z-skk-handle-zenkaku-input "o"
    assert_equals "Hello in zenkaku" "Ｈｅｌｌｏ" "$LBUFFER"

    _z-skk-handle-zenkaku-input " "
    _z-skk-handle-zenkaku-input "1"
    _z-skk-handle-zenkaku-input "2"
    _z-skk-handle-zenkaku-input "3"
    assert_equals "Hello 123 in zenkaku" "Ｈｅｌｌｏ　１２３" "$LBUFFER"
}

# Test abbrev mode
test_abbrev_mode() {
    # Reset state
    z-skk-reset-state
    z-skk-start-abbrev-mode

    assert_equals "Mode is abbrev" "abbrev" "$Z_SKK_MODE"
    assert_equals "Abbrev active" "1" "$Z_SKK_ABBREV_ACTIVE"
    assert_equals "Mode display" "[aA]" "$(z-skk-mode-indicator)"
}

# Test abbrev input processing
test_abbrev_input_processing() {
    z-skk-reset-state
    z-skk-hiragana-mode
    LBUFFER=""
    RBUFFER=""

    # Start abbrev mode with /
    _z-skk-handle-hiragana-input "/"
    assert_equals "Abbrev mode started" "abbrev" "$Z_SKK_MODE"

    # Type abbreviation
    _z-skk-handle-abbrev-input "s"
    _z-skk-handle-abbrev-input "k"
    _z-skk-handle-abbrev-input "k"
    assert_equals "Abbrev buffer" "skk" "$Z_SKK_ABBREV_BUFFER"
    assert_equals "Display shows abbrev" "skk" "$LBUFFER"

    # Space completes abbreviation
    _z-skk-handle-abbrev-input " "
    assert_equals "Conversion started" "1" "$Z_SKK_CONVERTING"
    assert_equals "Buffer has abbrev" "skk" "$Z_SKK_BUFFER"
    # Display should now show conversion marker
    assert '[[ "$LBUFFER" == "▽skk" ]]' "Display shows conversion marker"
}

# Test mode switching from katakana
test_katakana_mode_switching() {
    z-skk-reset-state
    z-skk-katakana-mode

    # q returns to hiragana
    z-skk-handle-katakana-special "q"
    assert_equals "q switches to hiragana" "hiragana" "$Z_SKK_MODE"

    z-skk-katakana-mode
    # l/L switches to ASCII
    z-skk-handle-katakana-special "l"
    assert_equals "l switches to ASCII" "ascii" "$Z_SKK_MODE"
}

# Test mode switching from zenkaku
test_zenkaku_mode_switching() {
    z-skk-reset-state
    z-skk-zenkaku-mode

    # C-j returns to hiragana
    z-skk-handle-zenkaku-special $'\x0a'
    assert_equals "C-j switches to hiragana" "hiragana" "$Z_SKK_MODE"
}

# Test C-j toggle behavior
test_toggle_kana() {
    z-skk-reset-state

    # From ASCII to hiragana
    Z_SKK_MODE="ascii"
    z-skk-toggle-kana
    assert_equals "ASCII -> hiragana" "hiragana" "$Z_SKK_MODE"

    # From katakana to hiragana
    Z_SKK_MODE="katakana"
    z-skk-toggle-kana
    assert_equals "katakana -> hiragana" "hiragana" "$Z_SKK_MODE"

    # From zenkaku to hiragana
    Z_SKK_MODE="zenkaku"
    z-skk-toggle-kana
    assert_equals "zenkaku -> hiragana" "hiragana" "$Z_SKK_MODE"

    # From abbrev to hiragana
    Z_SKK_MODE="abbrev"
    z-skk-toggle-kana
    assert_equals "abbrev -> hiragana" "hiragana" "$Z_SKK_MODE"

    # From hiragana to ASCII
    Z_SKK_MODE="hiragana"
    z-skk-toggle-kana
    assert_equals "hiragana -> ASCII" "ascii" "$Z_SKK_MODE"
}

# Test mode state cleanup
test_mode_state_cleanup() {
    # Start abbrev mode with state
    z-skk-start-abbrev-mode
    Z_SKK_ABBREV_BUFFER="test"
    Z_SKK_ABBREV_ACTIVE=1

    # Switch to another mode
    z-skk-hiragana-mode

    # Check abbrev state is cleared
    assert_equals "Abbrev buffer cleared" "" "$Z_SKK_ABBREV_BUFFER"
    assert_equals "Abbrev not active" "0" "$Z_SKK_ABBREV_ACTIVE"
}

# Run tests
test_katakana_mode
test_katakana_input_processing
test_zenkaku_mode
test_zenkaku_input_processing
test_abbrev_mode
test_abbrev_input_processing
test_katakana_mode_switching
test_zenkaku_mode_switching
test_toggle_kana
test_mode_state_cleanup

print_test_summary