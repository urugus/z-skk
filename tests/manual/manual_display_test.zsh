#!/usr/bin/env zsh
# Manual display test instructions

cat << 'EOF'
=== z-skk Manual Display Test ===

This test verifies RPROMPT mode display functionality.

1. Start a new zsh session
2. Source the plugin:
   $ source /path/to/z-skk.plugin.zsh

3. Check initial RPROMPT:
   - You should see "[_A]" in the right prompt (ASCII mode)

4. Test mode switching display:
   - Press Ctrl+J to switch to hiragana mode
   - RPROMPT should now show "[あ]"
   - Press Ctrl+J again to switch back to ASCII
   - RPROMPT should show "[_A]"

5. Test with existing RPROMPT:
   $ RPROMPT="existing"
   $ source /path/to/z-skk.plugin.zsh
   - RPROMPT should show "[_A] existing"

6. Test disable/enable:
   $ z-skk-disable
   - Mode indicator should disappear from RPROMPT
   $ z-skk-enable
   - Mode indicator should reappear

7. Test unload:
   $ z-skk-unload
   - RPROMPT should be restored to original state

EOF
