#!/usr/bin/env zsh
# Fix for Ctrl+J keybinding issue

echo "=== z-skk Ctrl+J Fix ==="
echo ""
echo "The issue is that bindkey -e in your bindkey.zsh file resets all keybindings"
echo "to emacs defaults, which binds Ctrl+J to accept-line."
echo ""
echo "This happens AFTER z-skk sets up its keybindings in pluginlist.zsh."
echo ""
echo "Solutions:"
echo ""
echo "1. Quick fix - Add this line to the END of your ~/.config/zsh/rc/bindkey.zsh:"
echo '   bindkey "^J" z-skk-toggle-kana'
echo ""
echo "2. Better fix - Move the z-skk keybinding setup after bindkey -e:"
echo "   Edit ~/.config/zsh/rc/bindkey.zsh and add after line 6 (bindkey -e):"
echo '   # Restore z-skk keybindings after emacs mode reset'
echo '   if (( ${+widgets[z-skk-toggle-kana]} )); then'
echo '     bindkey "^J" z-skk-toggle-kana'
echo '   fi'
echo ""
echo "3. Alternative - Move bindkey -e to base.zsh before loading plugins"
echo ""
echo "Testing the fix now..."
echo ""

# Apply the fix temporarily
if (( ${+widgets[z-skk-toggle-kana]} )); then
    bindkey "^J" z-skk-toggle-kana
    echo "✓ Ctrl+J is now bound to z-skk-toggle-kana"
    echo ""
    echo "Current binding:"
    bindkey "^J"
else
    echo "✗ z-skk-toggle-kana widget not found. Make sure z-skk is loaded."
fi