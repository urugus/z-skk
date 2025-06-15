#!/usr/bin/env zsh
# Debug script for Ctrl+J keybinding issue

echo "=== z-skk Ctrl+J Debug Script ==="
echo ""

# Source the plugin
echo "1. Sourcing z-skk plugin..."
source /Users/urugus/private/z-skk/z-skk.plugin.zsh

# Check if debug mode is on
echo "2. Debug mode: ${Z_SKK_DEBUG:-0}"
echo ""

# Check if functions exist
echo "3. Checking required functions:"
echo "   z-skk-toggle-kana: ${(k)functions[(I)z-skk-toggle-kana]:-NOT FOUND}"
echo "   z-skk-set-mode: ${(k)functions[(I)z-skk-set-mode]:-NOT FOUND}"
echo "   z-skk-hiragana-mode: ${(k)functions[(I)z-skk-hiragana-mode]:-NOT FOUND}"
echo ""

# Check if widgets are registered
echo "4. Checking widgets:"
echo "   z-skk-toggle-kana widget: ${widgets[z-skk-toggle-kana]:-NOT FOUND}"
echo "   z-skk-self-insert widget: ${widgets[z-skk-self-insert]:-NOT FOUND}"
echo ""

# Check current keybindings
echo "5. Current keybindings for Ctrl+J:"
bindkey | grep '\^J'
echo ""

# Try to manually register and bind
echo "6. Manually registering widget and binding..."
if (( ${+functions[z-skk-toggle-kana]} )); then
    zle -N z-skk-toggle-kana
    bindkey "^J" z-skk-toggle-kana
    echo "   Widget registered and bound successfully"
else
    echo "   ERROR: z-skk-toggle-kana function not found!"
fi
echo ""

# Check again
echo "7. After manual registration:"
echo "   Widget: ${widgets[z-skk-toggle-kana]:-NOT FOUND}"
echo "   Binding:"
bindkey | grep '\^J'
echo ""

# Check for conflicts
echo "8. Checking for other Ctrl+J bindings in current keymap:"
bindkey -L | grep '\^J'
echo ""

# Test the function directly
echo "9. Testing z-skk-toggle-kana function directly:"
echo "   Current mode: $Z_SKK_MODE"
if (( ${+functions[z-skk-toggle-kana]} )); then
    z-skk-toggle-kana
    echo "   Mode after toggle: $Z_SKK_MODE"
    # Toggle back
    z-skk-toggle-kana
    echo "   Mode after second toggle: $Z_SKK_MODE"
else
    echo "   ERROR: Cannot test - function not found"
fi
echo ""

echo "=== Debug complete ==="
echo ""
echo "To test interactively:"
echo "1. Start a new zsh session"
echo "2. Source this script: source $0"
echo "3. Try pressing Ctrl+J"
echo "4. Check if mode changes in RPROMPT"