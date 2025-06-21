#!/usr/bin/env zsh
# Debug okurigana processing with detailed tracking

# Load the plugin
source "${0:A:h:h:h}/z-skk.plugin.zsh"

# Initialize
z-skk-init

# Set to hiragana mode
Z_SKK_MODE="hiragana"

print "Testing okurigana processing with detailed tracking..."

# Mock LBUFFER
LBUFFER=""

# Start conversion with 'Saga'
print "\n=== Setting up conversion state with 'Saga' ==="
Z_SKK_CONVERTING=1
Z_SKK_BUFFER="さが"
LBUFFER="▽さが"

print "Initial state:"
print "  CONVERTING: $Z_SKK_CONVERTING"
print "  BUFFER: '$Z_SKK_BUFFER'"
print "  LBUFFER: '$LBUFFER'"

# Input 'S' (uppercase during conversion)
print "\n=== Input 'S' (uppercase during conversion) ==="
local saved_romaji="$Z_SKK_OKURIGANA_ROMAJI"

# Call the handler
_z-skk-handle-converting-input "S"

print "After 'S':"
print "  OKURIGANA_MODE: $Z_SKK_OKURIGANA_MODE"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"
print "  LBUFFER: '$LBUFFER'"

# Check if romaji buffer was properly initialized
if [[ "$Z_SKK_OKURIGANA_ROMAJI" != "s" ]]; then
    print "ERROR: OKURIGANA_ROMAJI should be 's' but is '$Z_SKK_OKURIGANA_ROMAJI'"
fi

# Input 'u'
print "\n=== Input 'u' ==="
_z-skk-handle-converting-input "u"

print "After 'u':"
print "  OKURIGANA_MODE: $Z_SKK_OKURIGANA_MODE"
print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"
print "  LBUFFER: '$LBUFFER'"

# Expected vs Actual
print "\n=== Expected vs Actual ==="
print "Expected OKURIGANA_SUFFIX: 'す'"
print "Actual OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"
print "Expected LBUFFER: '▽さが*す'"
print "Actual LBUFFER: '$LBUFFER'"