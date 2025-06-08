#!/usr/bin/env zsh
# Interactive test for z-skk hiragana input

print "=== z-skk Interactive Test ==="
print "Loading z-skk plugin..."

# Source the plugin
source "${0:A:h:h}/z-skk.plugin.zsh"

print "\nInstructions:"
print "1. Press Ctrl+J to switch to hiragana mode"
print "2. Type 'nihongo' to see it convert to にほんご"
print "3. Press Ctrl+L to switch back to ASCII mode"
print "4. Press Ctrl+C to exit"
print ""
print "Current mode: $SKK_MODE"
print ""

# Start interactive shell
exec zsh -i