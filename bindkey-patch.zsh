#!/usr/bin/env zsh
# Patch for bindkey.zsh to fix z-skk Ctrl+J

echo "This patch will fix the Ctrl+J keybinding for z-skk."
echo ""
echo "Add the following lines to your ~/.config/zsh/rc/bindkey.zsh"
echo "right after the 'bindkey -e' line (after line 6):"
echo ""
echo "----------------------------------------"
cat << 'EOF'
# Restore z-skk keybindings after emacs mode reset
# The bindkey -e command resets all keybindings to defaults,
# so we need to restore z-skk's Ctrl+J binding
if (( ${+widgets[z-skk-toggle-kana]} )); then
    bindkey "^J" z-skk-toggle-kana
fi
EOF
echo "----------------------------------------"
echo ""
echo "Or add this single line at the END of bindkey.zsh:"
echo '  bindkey "^J" z-skk-toggle-kana'