#!/usr/bin/env zsh
# Unit tests for mode-related functionality
# Merged from test_mode_switching.zsh and test_input_modes.zsh

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Force load input-modes module for testing
if (( ${+functions[z-skk-lazy-load-module]} )); then
    z-skk-lazy-load-module "input-modes"
else
    # Fallback: source directly
    source "$PROJECT_DIR/lib/input/input-modes.zsh"
fi

# ==============================================================================
# Basic Mode Functions
# ==============================================================================

test_mode_functions_exist() {
    print_section "Mode Function Existence"
    
    assert "(( \${+functions[z-skk-set-mode]} ))" "z-skk-set-mode function exists"
    assert "(( \${+functions[z-skk-toggle-kana]} ))" "z-skk-toggle-kana function exists"
    assert "(( \${+functions[z-skk-ascii-mode]} ))" "z-skk-ascii-mode function exists"
    assert "(( \${+functions[z-skk-hiragana-mode]} ))" "z-skk-hiragana-mode function exists"
    assert "(( \${+functions[z-skk-katakana-mode]} ))" "z-skk-katakana-mode function exists"
    assert "(( \${+functions[z-skk-zenkaku-mode]} ))" "z-skk-zenkaku-mode function exists"
    assert "(( \${+functions[z-skk-start-abbrev-mode]} ))" "z-skk-start-abbrev-mode function exists"
}

# ==============================================================================
# Initial State and Basic Mode Switching
# ==============================================================================

test_initial_state() {
    print_section "Initial State"
    
    # Reset to ensure clean state
    z-skk-reset-state
    
    assert_equals "Initial mode is ascii" "ascii" "$Z_SKK_MODE"
    assert_equals "Initial romaji buffer is empty" "" "$Z_SKK_ROMAJI_BUFFER"
    assert_equals "Initial main buffer is empty" "" "$Z_SKK_BUFFER"
}

test_basic_mode_switching() {
    print_section "Basic Mode Switching"
    
    # Reset state
    z-skk-reset-state
    
    # Test switching to hiragana
    z-skk-hiragana-mode
    assert_equals "Switch to hiragana mode" "hiragana" "$Z_SKK_MODE"
    assert_equals "Romaji buffer cleared on mode switch" "" "$Z_SKK_ROMAJI_BUFFER"
    
    # Test switching to ascii
    z-skk-ascii-mode
    assert_equals "Switch to ascii mode" "ascii" "$Z_SKK_MODE"
    
    # Test switching to katakana
    z-skk-katakana-mode
    assert_equals "Switch to katakana mode" "katakana" "$Z_SKK_MODE"
    
    # Test switching to zenkaku
    z-skk-zenkaku-mode
    assert_equals "Switch to zenkaku mode" "zenkaku" "$Z_SKK_MODE"
}

test_set_mode_function() {
    print_section "z-skk-set-mode Function"
    
    # Test valid modes
    z-skk-set-mode "katakana"
    assert_equals "Set mode to katakana" "katakana" "$Z_SKK_MODE"
    
    z-skk-set-mode "hiragana"
    assert_equals "Set mode to hiragana" "hiragana" "$Z_SKK_MODE"
    
    z-skk-set-mode "ascii"
    assert_equals "Set mode to ascii" "ascii" "$Z_SKK_MODE"
    
    z-skk-set-mode "zenkaku"
    assert_equals "Set mode to zenkaku" "zenkaku" "$Z_SKK_MODE"
    
    # Test invalid mode
    local current_mode="$Z_SKK_MODE"
    z-skk-set-mode "invalid"
    assert_equals "Invalid mode doesn't change current mode" "$current_mode" "$Z_SKK_MODE"
}

test_mode_switching_clears_buffers() {
    print_section "Mode Switching Clears Buffers"
    
    # Set up state with data
    Z_SKK_MODE="hiragana"
    Z_SKK_ROMAJI_BUFFER="test"
    Z_SKK_BUFFER="buffer"
    
    # Switch mode
    z-skk-ascii-mode
    
    assert_equals "Mode switch clears romaji buffer" "" "$Z_SKK_ROMAJI_BUFFER"
    assert_equals "Mode switch clears main buffer" "" "$Z_SKK_BUFFER"
}

# ==============================================================================
# Mode Display and Indicators
# ==============================================================================

test_mode_display_names() {
    print_section "Mode Display Names"
    
    assert "[[ -n \${Z_SKK_MODE_NAMES[hiragana]} ]]" "Mode display names are defined"
    assert_equals "Hiragana mode display" "かな" "${Z_SKK_MODE_NAMES[hiragana]}"
    assert_equals "ASCII mode display" "英数" "${Z_SKK_MODE_NAMES[ascii]}"
    assert_equals "Katakana mode display" "カナ" "${Z_SKK_MODE_NAMES[katakana]}"
    assert_equals "Zenkaku mode display" "全英" "${Z_SKK_MODE_NAMES[zenkaku]}"
    assert_equals "Abbrev mode display" "Abbrev" "${Z_SKK_MODE_NAMES[abbrev]}"
}

test_mode_indicators() {
    print_section "Mode Indicators"
    
    z-skk-hiragana-mode
    assert_equals "Hiragana mode indicator" "[あ]" "$(z-skk-mode-indicator)"
    
    z-skk-katakana-mode
    assert_equals "Katakana mode indicator" "[ア]" "$(z-skk-mode-indicator)"
    
    z-skk-ascii-mode
    assert_equals "ASCII mode indicator" "[_A]" "$(z-skk-mode-indicator)"
    
    z-skk-zenkaku-mode
    assert_equals "Zenkaku mode indicator" "[Ａ]" "$(z-skk-mode-indicator)"
    
    z-skk-start-abbrev-mode
    assert_equals "Abbrev mode indicator" "[aA]" "$(z-skk-mode-indicator)"
}

# ==============================================================================
# Toggle Kana Function (C-j behavior)
# ==============================================================================

test_toggle_kana_basic() {
    print_section "Basic Toggle Kana (C-j)"
    
    # From ASCII to hiragana
    Z_SKK_MODE="ascii"
    z-skk-toggle-kana
    assert_equals "Toggle from ascii goes to hiragana" "hiragana" "$Z_SKK_MODE"
    
    # From hiragana to ascii
    z-skk-toggle-kana
    assert_equals "Toggle from hiragana goes to ascii" "ascii" "$Z_SKK_MODE"
}

test_toggle_kana_all_modes() {
    print_section "Toggle Kana from All Modes"
    
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

# ==============================================================================
# Katakana Mode
# ==============================================================================

test_katakana_mode() {
    print_section "Katakana Mode"
    
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

test_katakana_mode_switching() {
    print_section "Katakana Mode Switching"
    
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

# ==============================================================================
# Zenkaku Mode
# ==============================================================================

test_zenkaku_mode() {
    print_section "Zenkaku Mode"
    
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

test_zenkaku_mode_switching() {
    print_section "Zenkaku Mode Switching"
    
    z-skk-reset-state
    z-skk-zenkaku-mode
    
    # C-j returns to hiragana
    z-skk-handle-zenkaku-special "C-j"
    assert_equals "C-j switches to hiragana" "hiragana" "$Z_SKK_MODE"
}

# ==============================================================================
# Abbrev Mode
# ==============================================================================

test_abbrev_mode() {
    print_section "Abbrev Mode"
    
    # Reset state
    z-skk-reset-state
    z-skk-start-abbrev-mode
    
    assert_equals "Mode is abbrev" "abbrev" "$Z_SKK_MODE"
    assert_equals "Abbrev active" "1" "$Z_SKK_ABBREV_ACTIVE"
    assert_equals "Mode display" "[aA]" "$(z-skk-mode-indicator)"
}

test_abbrev_input_processing() {
    print_section "Abbrev Input Processing"
    
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

# ==============================================================================
# Mode State Cleanup
# ==============================================================================

test_mode_state_cleanup() {
    print_section "Mode State Cleanup"
    
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

# ==============================================================================
# Run All Tests
# ==============================================================================

print_header "Mode Unit Tests"

# Basic functionality
test_mode_functions_exist
test_initial_state
test_basic_mode_switching
test_set_mode_function
test_mode_switching_clears_buffers

# Display
test_mode_display_names
test_mode_indicators

# Toggle kana
test_toggle_kana_basic
test_toggle_kana_all_modes

# Individual modes
test_katakana_mode
test_katakana_mode_switching
test_zenkaku_mode
test_zenkaku_mode_switching
test_abbrev_mode
test_abbrev_input_processing

# Cleanup
test_mode_state_cleanup

print_test_summary