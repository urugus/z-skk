#!/usr/bin/env zsh
# Test okurigana romaji processing

# Load the plugin
source "${0:A:h:h:h}/z-skk.plugin.zsh"

# Initialize
z-skk-init

# Force load okurigana module
z-skk-lazy-load okurigana

print "Testing okurigana romaji processing..."

# Direct test of romaji to hiragana conversion
print "\n1. Testing romaji-to-hiragana conversion:"
print "  'u' -> '$(z-skk-romaji-to-hiragana "u")'"
print "  'su' -> '$(z-skk-romaji-to-hiragana "su")'"

# Test the okurigana romaji processing function
print "\n2. Testing _z-skk-process-okurigana-romaji:"

# Set up okurigana state
Z_SKK_OKURIGANA_MODE=1
Z_SKK_OKURIGANA_SUFFIX=""
Z_SKK_OKURIGANA_ROMAJI=""

# Process 's'
print "\nProcessing 's':"
_z-skk-process-okurigana-romaji "s"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"

# Process 'u'
print "\nProcessing 'u':"
_z-skk-process-okurigana-romaji "u"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"

# Test with fresh state
print "\n3. Testing with fresh state:"
Z_SKK_OKURIGANA_SUFFIX=""
Z_SKK_OKURIGANA_ROMAJI="s"
print "Initial state:"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"

print "\nProcessing 'u' with 's' already in buffer:"
_z-skk-process-okurigana-romaji "u"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"