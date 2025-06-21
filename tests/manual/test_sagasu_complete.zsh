#!/usr/bin/env zsh
# Complete test for SagaSu input

# Load the plugin
source "${0:A:h:h:h}/z-skk.plugin.zsh"

# Initialize
z-skk-init

# Set to hiragana mode
Z_SKK_MODE="hiragana"

# Enable debugging
typeset -g Z_SKK_DEBUG=1

print "Testing complete 'SagaSu' input sequence..."

# Mock LBUFFER
LBUFFER=""

# Complete sequence: S-a-g-a-S-u
local sequence=("S" "a" "g" "a" "S" "u")

for key in "${sequence[@]}"; do
    print "\nInput '$key':"

    # Handle input based on conversion state
    if [[ $Z_SKK_CONVERTING -eq 0 ]]; then
        _z-skk-handle-hiragana-input "$key"
    else
        _z-skk-handle-converting-input "$key"
    fi

    print "  CONVERTING: $Z_SKK_CONVERTING"
    print "  OKURIGANA_MODE: $Z_SKK_OKURIGANA_MODE"
    print "  BUFFER: '$Z_SKK_BUFFER'"
    print "  OKURIGANA_SUFFIX: '$Z_SKK_OKURIGANA_SUFFIX'"
    print "  OKURIGANA_ROMAJI: '$Z_SKK_OKURIGANA_ROMAJI'"
    print "  ROMAJI: '$Z_SKK_ROMAJI_BUFFER'"
    print "  LBUFFER: '$LBUFFER'"
done

print "\n=== Expected vs Actual ==="
print "Expected: ▽さが*す"
print "Actual: $LBUFFER"

# Now test the complete conversion flow
print "\n=== Testing conversion (Space key) ==="
z-skk-start-conversion
print "Candidates: ${Z_SKK_CANDIDATES[@]}"