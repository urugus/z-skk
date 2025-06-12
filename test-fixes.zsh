#!/usr/bin/env zsh
# Test script to verify the fixes

print "=== Testing z-skk fixes ==="
print ""

# Test 1: Check widget registration order
print "Test 1: Widget registration order"
print "Loading keybindings module in isolation..."
(
    # Create a minimal test environment
    Z_SKK_DIR="${PWD}"

    # Check if widgets exist before loading
    print "Before loading:"
    zle -la 2>/dev/null | grep -c "z-skk-" | xargs -I {} print "  z-skk widgets: {}"

    # Load keybindings
    source ./lib/keybindings.zsh 2>&1 | grep -E "(undefined-key|error)" && print "  ERROR: undefined-key issue detected" || print "  No undefined-key errors"

    # Check widgets after loading
    print "After loading:"
    zle -la 2>/dev/null | grep -c "z-skk-" | xargs -I {} print "  z-skk widgets: {}"
)
print ""

# Test 2: Check lazy loading
print "Test 2: Lazy loading behavior"
(
    Z_SKK_DIR="${PWD}"
    Z_SKK_DEBUG=1

    # Source only the core module
    source ./lib/core.zsh

    # Check if dictionary-io functions exist (they shouldn't)
    if (( ${+functions[z-skk-load-dictionary-file]} )); then
        print "  WARNING: dictionary-io seems to be loaded at startup"
    else
        print "  GOOD: dictionary-io is not loaded at startup"
    fi

    # Check if lazy stubs exist
    source ./lib/lazy-load.zsh
    if (( ${+functions[z-skk-load-dictionary-file]} )); then
        print "  GOOD: lazy load stub for dictionary-io exists"
    else
        print "  ERROR: lazy load stub missing"
    fi
)
print ""

# Test 3: Full startup time
print "Test 3: Full startup time"
start=$(date +%s)
zsh -c 'source ./z-skk.plugin.zsh; exit' 2>&1 | grep -E "(error|Error)" && print "  Errors during load" || print "  No errors during load"
end=$(date +%s)
duration=$((end - start))
print "  Startup time: ${duration}s"
if [[ $duration -gt 5 ]]; then
    print "  WARNING: Startup takes more than 5 seconds"
else
    print "  GOOD: Startup is reasonably fast"
fi
print ""

print "=== Tests complete ==="