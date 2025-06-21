#!/usr/bin/env zsh
# Test romaji conversion directly

# Load the plugin
source "${0:A:h:h:h}/z-skk.plugin.zsh"

# Initialize
z-skk-init

print "Testing romaji conversion..."

# Test basic conversions
print "\nBasic conversions:"
print "  'u' -> '$(z-skk-romaji-to-hiragana "u")'"
print "  's' -> '$(z-skk-romaji-to-hiragana "s")'"
print "  'su' -> '$(z-skk-romaji-to-hiragana "su")'"

# Check if conversion table has the entries
print "\nChecking conversion table:"
print "  Z_SKK_ROMAJI_TO_HIRAGANA[u] = '${Z_SKK_ROMAJI_TO_HIRAGANA[u]}'"
print "  Z_SKK_ROMAJI_TO_HIRAGANA[s] = '${Z_SKK_ROMAJI_TO_HIRAGANA[s]}'"
print "  Z_SKK_ROMAJI_TO_HIRAGANA[su] = '${Z_SKK_ROMAJI_TO_HIRAGANA[su]}'"

# Test partial romaji check
print "\nPartial romaji checks:"
print "  Is 's' partial? $(z-skk-is-partial-romaji 's' && echo 'yes' || echo 'no')"
print "  Is 'u' partial? $(z-skk-is-partial-romaji 'u' && echo 'yes' || echo 'no')"
print "  Is 'su' partial? $(z-skk-is-partial-romaji 'su' && echo 'yes' || echo 'no')"

# Test the logic manually
print "\nManual logic test:"
Z_SKK_OKURIGANA_ROMAJI="s"
print "Initial: ROMAJI='$Z_SKK_OKURIGANA_ROMAJI'"

# Add 'u'
Z_SKK_OKURIGANA_ROMAJI+="u"
print "After adding 'u': ROMAJI='$Z_SKK_OKURIGANA_ROMAJI'"

# Try conversion
converted=$(z-skk-romaji-to-hiragana "$Z_SKK_OKURIGANA_ROMAJI")
print "Conversion result: '$converted'"
print "Conversion empty? $([[ -z "$converted" ]] && echo 'yes' || echo 'no')"