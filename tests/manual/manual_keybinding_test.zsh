#!/usr/bin/env zsh
# Manual keybinding test instructions

cat << 'EOF'
=== z-skk Manual Keybinding Test ===

This test must be run interactively in a real zsh session.

1. Start a new zsh session
2. Source the plugin:
   $ source /path/to/z-skk.plugin.zsh

3. Test mode switching:
   - Press Ctrl+J -> Should toggle between ASCII and hiragana mode
   - In hiragana mode, press 'l' or 'L' -> Should switch to ASCII mode
   - Press Ctrl+L -> Should switch to ASCII mode

4. Test hiragana input:
   - Press Ctrl+J to enter hiragana mode
   - Type: nihongo
   - Expected output: にほんご
   - Type: arigatou
   - Expected output: ありがとう

5. Verify widgets are registered:
   $ echo ${widgets[z-skk-self-insert]}
   $ echo ${widgets[z-skk-toggle-kana]}
   $ echo ${widgets[z-skk-ascii-mode]}
   $ echo ${widgets[z-skk-hiragana-mode]}

6. Check key bindings:
   $ bindkey | grep z-skk

EOF