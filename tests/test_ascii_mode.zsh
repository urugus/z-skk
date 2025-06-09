#!/usr/bin/env zsh
# Test ASCII mode functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test ASCII mode is default
assert "Default mode is ASCII" "[[ \$Z_SKK_MODE == 'ascii' ]]"

# Test widget functions exist
assert "z-skk-self-insert widget exists" "(( \${+functions[z-skk-self-insert]} ))"
assert "z-skk-enable function exists" "(( \${+functions[z-skk-enable]} ))"
assert "z-skk-disable function exists" "(( \${+functions[z-skk-disable]} ))"

# Test enable/disable functionality
z-skk-disable
assert "z-skk-disable sets enabled flag to 0" "[[ \$Z_SKK_ENABLED -eq 0 ]]"

z-skk-enable
assert "z-skk-enable sets enabled flag to 1" "[[ \$Z_SKK_ENABLED -eq 1 ]]"

# Test pass-through in ASCII mode
# Note: Testing actual ZLE behavior requires a more complex setup
# For now, we'll test the logic that determines pass-through

# Mock KEYS variable for testing
KEYS="a"
typeset -g Z_SKK_PASS_THROUGH=0

# Call the input handler logic (will be implemented)
if (( ${+functions[z-skk-should-pass-through]} )); then
    z-skk-should-pass-through
    assert "ASCII mode passes through regular characters" "[[ \$Z_SKK_PASS_THROUGH -eq 1 ]]"
fi

# Test that ASCII mode doesn't activate conversion
KEYS="A"  # Capital letter
Z_SKK_PASS_THROUGH=0
if (( ${+functions[z-skk-should-pass-through]} )); then
    z-skk-should-pass-through
    assert "ASCII mode passes through capital letters" "[[ \$Z_SKK_PASS_THROUGH -eq 1 ]]"
fi

# Print summary and exit
print_test_summary