#!/usr/bin/env zsh
# Test zinit loading simulation

print "=== Testing zinit-style plugin loading ==="

# Simulate zinit environment
typeset -g ZINIT_HOME="/tmp/zinit-test"
typeset -g ZPFX="/tmp/zinit-test/polaris"

# Get absolute path to our plugin
typeset -g PLUGIN_DIR="${0:A:h:h:h}"

# Source the plugin (simulating zinit load)
print "Loading plugin from: $PLUGIN_DIR"
source "$PLUGIN_DIR/z-skk.plugin.zsh"

# Verify loading
if (( ${+Z_SKK_VERSION} )); then
    print "✓ Plugin loaded successfully"
    print "  Version: $Z_SKK_VERSION"
    print "  Directory: $Z_SKK_DIR"
else
    print "✗ Plugin failed to load"
    exit 1
fi

# Test unload function
if (( ${+functions[z-skk-unload]} )); then
    print "✓ Unload function available"
    z-skk-unload
else
    print "✗ Unload function not found"
    exit 1
fi

print "\n=== zinit loading test completed successfully ==="