#!/usr/bin/env zsh
# Manual test for SagaSu input

# Load the plugin
source "${0:A:h:h:h}/z-skk.plugin.zsh"

# Initialize
z-skk-init

# Set to hiragana mode
Z_SKK_MODE="hiragana"

# Enable debugging
typeset -g Z_SKK_DEBUG=1

print "Testing 'SagaSu' input..."

# Mock LBUFFER
LBUFFER=""

# Input S - should start conversion
print "\n1. Input 'S'"
_z-skk-handle-hiragana-input "S"
print "  CONVERTING: $Z_SKK_CONVERTING"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

# Input a
print "\n2. Input 'a'"
_z-skk-handle-hiragana-input "a"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

# Input g
print "\n3. Input 'g'"
_z-skk-handle-hiragana-input "g"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

# Input a (completes が)
print "\n4. Input 'a'"
_z-skk-handle-hiragana-input "a"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

# Input S (should prepare for okurigana)
print "\n5. Input 'S'"
_z-skk-handle-converting-input "S"
print "  OKURIGANA_MODE: $Z_SKK_OKURIGANA_MODE"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

# Input u (should trigger okurigana)
print "\n6. Input 'u'"
_z-skk-handle-converting-input "u"
print "  OKURIGANA_MODE: $Z_SKK_OKURIGANA_MODE"
print "  OKURIGANA_PREFIX: '$Z_SKK_OKURIGANA_PREFIX'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

print "\nFinal display should be '▽さが*す', not '▽さがす*す'"