#!/usr/bin/env zsh
# Test script to verify Ctrl+J lazy loading fix

# Load the plugin
source "${0:A:h}/../../z-skk.plugin.zsh"

echo "=== Testing Ctrl+J Lazy Loading Fix ==="
echo "This test verifies that switching to Japanese input mode and immediately typing works correctly."
echo ""

# Test function to simulate the problematic scenario
test_immediate_typing_after_mode_switch() {
    echo "Test 1: Switch to hiragana mode and immediately type"

    # Start in ASCII mode
    Z_SKK_MODE="ascii"

    # Simulate switching to hiragana mode (what Ctrl+J does)
    z-skk-toggle-kana

    # Check if okurigana functions are available after mode switch
    if (( ${+functions[z-skk-start-okurigana]} )); then
        echo "✓ Okurigana functions are loaded after mode switch"
    else
        echo "✗ Okurigana functions NOT loaded after mode switch"
        return 1
    fi

    # Simulate typing immediately after mode switch
    # This would previously fail because okurigana functions weren't loaded
    Z_SKK_LAST_INPUT="K"
    local result=$(_z-skk-should-start-okurigana "a" 2>&1)
    local ret_status=$?

    if [[ -n "$result" && "$result" == *"command not found"* ]]; then
        echo "✗ Error occurred: $result"
        return 1
    else
        echo "✓ No errors when checking for okurigana start"
    fi

    return 0
}

test_preloading_on_mode_switch() {
    echo ""
    echo "Test 2: Verify preloading mechanism"

    # Reset state
    unset "Z_SKK_LOADED_MODULES[okurigana]"

    # Start in ASCII mode
    Z_SKK_MODE="ascii"

    # Check okurigana functions before switch
    if (( ${+functions[z-skk-start-okurigana]} )); then
        echo "- Okurigana already loaded (unexpected)"
    else
        echo "✓ Okurigana not loaded initially"
    fi

    # Switch to hiragana mode
    z-skk-set-mode "hiragana"

    # Check if okurigana functions were preloaded
    if (( ${+functions[z-skk-start-okurigana]} )); then
        echo "✓ Okurigana preloaded when switching to hiragana"
    else
        echo "✗ Okurigana NOT preloaded when switching to hiragana"
        return 1
    fi

    # Reset and test katakana mode
    unset "Z_SKK_LOADED_MODULES[okurigana]"
    unset -f z-skk-start-okurigana 2>/dev/null

    # Switch to katakana mode
    z-skk-set-mode "katakana"

    # Check if okurigana functions were preloaded
    if (( ${+functions[z-skk-start-okurigana]} )); then
        echo "✓ Okurigana preloaded when switching to katakana"
    else
        echo "✗ Okurigana NOT preloaded when switching to katakana"
        return 1
    fi

    return 0
}

# Run tests
test_immediate_typing_after_mode_switch || exit 1
test_preloading_on_mode_switch || exit 1

echo ""
echo "=== All tests passed! ==="
echo "The Ctrl+J lazy loading issue has been fixed."