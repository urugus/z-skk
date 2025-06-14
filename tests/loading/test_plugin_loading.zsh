#!/usr/bin/env zsh
# Test plugin loading

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Debug: Show environment
if [[ "${CI:-}" == "true" ]]; then
    print "CI Environment detected"
    print "PROJECT_DIR: $PROJECT_DIR"
    print "PWD: $PWD"
    ls -la "$PROJECT_DIR" | head -5
    ls -la "$PROJECT_DIR/lib" | head -5
fi

# Test plugin file exists
assert "[[ -f '$PROJECT_DIR/z-skk.plugin.zsh' ]]" "Plugin file exists"

# Test plugin can be sourced
assert "source '$PROJECT_DIR/z-skk.plugin.zsh' 2>/dev/null" "Plugin can be sourced"

# Test plugin sets version variable
assert "[[ -n \$Z_SKK_VERSION ]]" "Plugin sets version variable"

# Test plugin sets directory variable
assert "[[ -n \$Z_SKK_DIR ]]" "Plugin sets directory variable"

# Test lib directory exists
assert "[[ -d '$PROJECT_DIR/lib' ]]" "Lib directory exists"

# Test core.zsh exists
assert "[[ -f '$PROJECT_DIR/lib/core/core.zsh' ]]" "Core.zsh exists"

# Test z-skk-init function is defined
assert "(( \${+functions[z-skk-init]} ))" "z-skk-init function is defined"

# Test z-skk-unload function is defined
assert "(( \${+functions[z-skk-unload]} ))" "z-skk-unload function is defined"

# Print summary and exit
print_test_summary