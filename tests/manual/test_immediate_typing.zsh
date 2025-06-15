#!/usr/bin/env zsh
# Test that simulates immediate typing after Ctrl+J

# Load the plugin
source "${0:A:h}/../../z-skk.plugin.zsh"

echo "=== Testing Immediate Typing After Mode Switch ==="
echo ""

# Function to simulate the exact user scenario
simulate_user_typing() {
    echo "Simulating: User presses Ctrl+J and immediately types 'Kanji'"

    # Start in ASCII mode
    Z_SKK_MODE="ascii"
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    Z_SKK_LAST_INPUT=""
    LBUFFER=""

    echo "1. Initial state: ASCII mode"

    # Simulate Ctrl+J (toggle to hiragana)
    z-skk-toggle-kana
    echo "2. After Ctrl+J: Mode is $Z_SKK_MODE"

    # Simulate typing 'K' immediately
    echo "3. Typing 'K'..."
    _z-skk-handle-hiragana-input "K"

    if [[ $Z_SKK_CONVERTING -eq 1 ]]; then
        echo "   ✓ Conversion started (CONVERTING=$Z_SKK_CONVERTING)"
    else
        echo "   ✗ Conversion not started (CONVERTING=$Z_SKK_CONVERTING)"
    fi

    # Simulate typing 'a'
    echo "4. Typing 'a'..."
    _z-skk-handle-hiragana-input "a"

    echo "   Buffer: '$Z_SKK_BUFFER'"
    echo "   Romaji: '$Z_SKK_ROMAJI_BUFFER'"

    # Simulate typing 'n'
    echo "5. Typing 'n'..."
    _z-skk-handle-hiragana-input "n"

    echo "   Buffer: '$Z_SKK_BUFFER'"
    echo "   Romaji: '$Z_SKK_ROMAJI_BUFFER'"

    # Simulate typing 'j'
    echo "6. Typing 'j'..."
    _z-skk-handle-hiragana-input "j"

    echo "   Buffer: '$Z_SKK_BUFFER'"
    echo "   Romaji: '$Z_SKK_ROMAJI_BUFFER'"

    # Simulate typing 'i'
    echo "7. Typing 'i'..."
    _z-skk-handle-hiragana-input "i"

    echo "   Buffer: '$Z_SKK_BUFFER'"
    echo "   Romaji: '$Z_SKK_ROMAJI_BUFFER'"

    # Check final state
    if [[ "$Z_SKK_BUFFER" == "かんじ" ]]; then
        echo ""
        echo "✓ Successfully converted 'Kanji' to 'かんじ'"
    else
        echo ""
        echo "✗ Failed to convert properly. Buffer: '$Z_SKK_BUFFER'"
        return 1
    fi

    return 0
}

# Test with okurigana scenario
test_okurigana_scenario() {
    echo ""
    echo "Testing okurigana scenario: 'OkuRi'"

    # Reset state
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    Z_SKK_LAST_INPUT=""
    Z_SKK_OKURIGANA=""
    Z_SKK_OKURIGANA_MODE=0

    echo "1. Typing 'O' (start conversion)..."
    _z-skk-handle-hiragana-input "O"
    echo "   Converting: $Z_SKK_CONVERTING"

    echo "2. Typing 'k'..."
    _z-skk-handle-hiragana-input "k"
    echo "   Buffer: '$Z_SKK_BUFFER'"

    echo "3. Typing 'u'..."
    _z-skk-handle-hiragana-input "u"
    echo "   Buffer: '$Z_SKK_BUFFER'"

    echo "4. Typing 'R' (okurigana marker)..."
    _z-skk-handle-hiragana-input "R"
    echo "   Okurigana mode: $Z_SKK_OKURIGANA_MODE"
    echo "   Buffer: '$Z_SKK_BUFFER'"

    echo "5. Typing 'i' (okurigana)..."
    _z-skk-handle-hiragana-input "i"
    echo "   Buffer: '$Z_SKK_BUFFER'"
    echo "   Okurigana: '$Z_SKK_OKURIGANA'"

    if [[ "$Z_SKK_BUFFER" == "おく" && "$Z_SKK_OKURIGANA" == "り" ]]; then
        echo ""
        echo "✓ Okurigana handling works correctly"
    else
        echo ""
        echo "✗ Okurigana handling failed"
        echo "  Expected: Buffer='おく', Okurigana='り'"
        echo "  Got: Buffer='$Z_SKK_BUFFER', Okurigana='$Z_SKK_OKURIGANA'"
        return 1
    fi

    return 0
}

# Run tests
simulate_user_typing || exit 1
test_okurigana_scenario || exit 1

echo ""
echo "=== All immediate typing tests passed! ==="