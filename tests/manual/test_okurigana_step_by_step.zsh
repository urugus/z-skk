#!/usr/bin/env zsh
# Step by step okurigana processing test

# Load the plugin
source "${0:A:h:h:h}/z-skk.plugin.zsh"

# Initialize and load okurigana module
z-skk-init
z-skk-lazy-load okurigana

print "Step by step okurigana processing test..."

# Set up initial state
Z_SKK_OKURIGANA_MODE=1
Z_SKK_OKURIGANA_SUFFIX=""
Z_SKK_OKURIGANA_ROMAJI="s"

print "\nInitial state:"
print "  ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"

print "\nProcessing 'u' with 's' already in buffer..."

# Manually do what _z-skk-process-okurigana-romaji does
key="u"
print "\n1. Adding '$key' to romaji buffer"
Z_SKK_OKURIGANA_ROMAJI+="$key"
print "   ROMAJI is now: '$Z_SKK_OKURIGANA_ROMAJI'"

print "\n2. Trying to convert '$Z_SKK_OKURIGANA_ROMAJI'"
converted=$(z-skk-romaji-to-hiragana "$Z_SKK_OKURIGANA_ROMAJI")
print "   Conversion result: '$converted'"

if [[ -n "$converted" ]]; then
    print "\n3. Conversion successful, updating suffix"
    Z_SKK_OKURIGANA_SUFFIX+="$converted"
    Z_SKK_OKURIGANA_ROMAJI=""
    print "   SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"
    print "   ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
fi

# Now test what happens if we process just 'u' alone
print "\n\n=== Testing 'u' alone ==="
Z_SKK_OKURIGANA_SUFFIX=""
Z_SKK_OKURIGANA_ROMAJI=""

print "Processing 'u' with empty buffer:"
_z-skk-process-okurigana-romaji "u"
print "  ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"