#!/usr/bin/env zsh
# Test script to find the source of the 30-second delay

# Enable debug mode
export Z_SKK_DEBUG=1

# Function to time operations
time_it() {
    local name="$1"
    shift
    local start=$(/bin/date +%s)
    "$@"
    local end=$(/bin/date +%s)
    local duration=$((end - start))
    print "[$duration s] $name"
}

print "=== Testing z-skk startup time ==="
print "Starting at: $(date)"
print ""

# Test 1: Basic zsh startup
print "1. Testing basic zsh startup (no z-skk):"
time_it "zsh -c 'exit'" zsh -c 'exit'
print ""

# Test 2: Source z-skk without keybindings
print "2. Testing z-skk load without interactive mode:"
time_it "source z-skk (non-interactive)" zsh -c 'source ./z-skk.plugin.zsh; exit'
print ""

# Test 3: Interactive shell with z-skk
print "3. Testing interactive shell with z-skk:"
cat > /tmp/test-interactive.zsh << 'EOF'
source ./z-skk.plugin.zsh
exit
EOF
time_it "interactive z-skk" zsh -i < /tmp/test-interactive.zsh
print ""

# Test 4: Test keybinding setup specifically
print "4. Testing keybinding setup in isolation:"
cat > /tmp/test-keybindings.zsh << 'EOF'
# Minimal test
Z_SKK_DIR="${PWD}"
source ./lib/keybindings.zsh
exit
EOF
time_it "keybindings only" zsh -i < /tmp/test-keybindings.zsh
print ""

# Test 5: Test dictionary loading
print "5. Testing dictionary loading:"
time_it "dictionary check" zsh -c '
Z_SKK_DIR="${PWD}"
source ./lib/dictionary-io.zsh
[[ -f "$Z_SKK_USER_JISYO_PATH" ]] && echo "User dictionary exists"
exit
'
print ""

# Clean up
rm -f /tmp/test-interactive.zsh /tmp/test-keybindings.zsh

print "=== Test complete ==="
print "Finished at: $(date)"