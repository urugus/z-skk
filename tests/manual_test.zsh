#!/usr/bin/env zsh
# Manual test for z-skk functionality

print "=== z-skk Manual Test ==="
print "Loading z-skk plugin..."

# Source the plugin
source "${0:A:h:h}/z-skk.plugin.zsh"

print "\nCurrent settings:"
print "  SKK_MODE: $SKK_MODE"
print "  Z_SKK_ENABLED: $Z_SKK_ENABLED"

print "\nKeybinding check:"
print "  'a' is bound to: $(bindkey 'a' | cut -d' ' -f2-)"
print "  'A' is bound to: $(bindkey 'A' | cut -d' ' -f2-)"

print "\nTesting z-skk-disable/enable:"
z-skk-disable
print "  After disable - Z_SKK_ENABLED: $Z_SKK_ENABLED"
z-skk-enable
print "  After enable - Z_SKK_ENABLED: $Z_SKK_ENABLED"

print "\n=== Setup complete ==="
print "You can now test typing in this shell."
print "All input should pass through normally in ASCII mode."
print ""
print "To test: Try typing some text after this message."
print "Press Ctrl+C to exit the test."
print ""

# Start an interactive shell for testing
exec zsh -i