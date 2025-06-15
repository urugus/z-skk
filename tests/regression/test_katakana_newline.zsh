#!/usr/bin/env zsh
# Test for katakana input newline issue

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

test_katakana_input_no_newline() {
    echo -n "Test: Katakana input should not produce newlines..."

    # Initialize z-skk
    z-skk-initialize

    # Switch to katakana mode
    z-skk-set-mode "katakana"

    # Clear buffers
    LBUFFER=""
    RBUFFER=""

    # Process katakana input
    z-skk-handle-input "k"
    z-skk-handle-input "a"

    # Check if LBUFFER contains newline
    if [[ "$LBUFFER" == *$'\n'* ]]; then
        echo "FAIL - Found newline in buffer: '$LBUFFER'"
        return 1
    fi

    # Check expected output
    if [[ "$LBUFFER" != "カ" ]]; then
        echo "FAIL - Expected 'カ', got '$LBUFFER'"
        return 1
    fi

    echo "PASS"
}

test_multiple_katakana_no_newlines() {
    echo -n "Test: Multiple katakana characters should not produce newlines..."

    # Initialize z-skk
    z-skk-initialize

    # Switch to katakana mode
    z-skk-set-mode "katakana"

    # Clear buffers
    LBUFFER=""
    RBUFFER=""

    # Process multiple katakana
    z-skk-handle-input "k"
    z-skk-handle-input "a"
    z-skk-handle-input "t"
    z-skk-handle-input "a"
    z-skk-handle-input "k"
    z-skk-handle-input "a"
    z-skk-handle-input "n"
    z-skk-handle-input "a"

    # Check if LBUFFER contains newline
    if [[ "$LBUFFER" == *$'\n'* ]]; then
        echo "FAIL - Found newline in buffer"
        # Count newlines
        local newlines=$(echo -n "$LBUFFER" | grep -c $'\n')
        echo "  Found $newlines newlines in: '$LBUFFER'"
        return 1
    fi

    # Check expected output
    if [[ "$LBUFFER" != "カタカナ" ]]; then
        echo "FAIL - Expected 'カタカナ', got '$LBUFFER'"
        return 1
    fi

    echo "PASS"
}

# Run tests
print "===== Katakana Newline Regression Tests ====="
test_katakana_input_no_newline
test_multiple_katakana_no_newlines
print_test_summary