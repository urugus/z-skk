#!/usr/bin/env zsh
# Test to ensure zle reset-prompt is not called during normal input

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

test_no_reset_prompt_during_input() {
    print_section "No reset-prompt during normal input"

    # Track if reset-prompt is called
    local reset_prompt_called=0

    # Mock zle to detect reset-prompt
    zle() {
        case "$1" in
            reset-prompt)
                reset_prompt_called=1
                ;;
            -R)
                # Normal redraw is fine
                ;;
        esac
    }

    # Test hiragana input
    z-skk-set-mode "hiragana"
    reset_prompt_called=0
    z-skk-handle-input "a"
    assert_equals "No reset-prompt during hiragana input" "0" "$reset_prompt_called"

    # Test katakana input
    z-skk-set-mode "katakana"
    reset_prompt_called=0
    z-skk-handle-input "a"
    assert_equals "No reset-prompt during katakana input" "0" "$reset_prompt_called"

    # Test ASCII input
    z-skk-set-mode "ascii"
    reset_prompt_called=0
    z-skk-handle-input "a"
    assert_equals "No reset-prompt during ASCII input" "0" "$reset_prompt_called"
}

test_reset_prompt_only_on_mode_change() {
    print_section "reset-prompt allowed during mode changes"

    # Track if update-mode-display is using safe redraw
    local uses_safe_redraw=0

    # Check the actual implementation
    if (( ${+functions[z-skk-update-mode-display]} )); then
        local func_body=$(type -f z-skk-update-mode-display 2>/dev/null)
        if [[ "$func_body" == *"z-skk-safe-redraw"* ]]; then
            uses_safe_redraw=1
        fi
    fi

    assert_equals "update-mode-display uses safe redraw" "1" "$uses_safe_redraw"
}

# Run tests
reset_test_counters
test_no_reset_prompt_during_input
test_reset_prompt_only_on_mode_change
print_test_summary