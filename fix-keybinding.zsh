#!/usr/bin/env zsh
# Fix script for Ctrl+J keybinding issue

# Check current keybinding
echo "Current Ctrl+J binding:"
bindkey "^J" | cat -v

# Check if z-skk is loaded
echo -e "\nChecking z-skk status:"
echo "Z_SKK_ENABLED: $Z_SKK_ENABLED"
echo "Z_SKK_INITIALIZED: $Z_SKK_INITIALIZED"

# Check if widgets are registered
echo -e "\nChecking widgets:"
if zle -l | grep -q "z-skk-toggle-kana"; then
    echo "z-skk-toggle-kana widget is registered"
else
    echo "z-skk-toggle-kana widget is NOT registered"
fi

# Force re-registration and keybinding
echo -e "\nForcing widget registration and keybinding..."
if (( ${+functions[z-skk-register-widgets]} )); then
    z-skk-register-widgets
    echo "Widgets registered"
fi

if (( ${+functions[z-skk-setup-keybindings]} )); then
    z-skk-setup-keybindings
    echo "Keybindings set up"
fi

# Check again
echo -e "\nAfter setup - Ctrl+J binding:"
bindkey "^J" | cat -v

# Test the widget directly
echo -e "\nTesting widget directly:"
if (( ${+functions[z-skk-toggle-kana]} )); then
    echo "z-skk-toggle-kana function exists"
else
    echo "z-skk-toggle-kana function does NOT exist"
fi