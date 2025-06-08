#!/usr/bin/env zsh
# Test plugin loading

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Simple assertion function
assert() {
    local description="$1"
    local condition="$2"

    if eval "$condition"; then
        print "✓ $description"
        (( TESTS_PASSED++ ))
    else
        print "✗ $description"
        print "  Condition failed: $condition"
        (( TESTS_FAILED++ ))
    fi
}

# Test plugin file exists
assert "Plugin file exists" "[[ -f '$PROJECT_DIR/z-skk.plugin.zsh' ]]"

# Test plugin can be sourced
assert "Plugin can be sourced" "source '$PROJECT_DIR/z-skk.plugin.zsh' 2>/dev/null"

# Test plugin sets version variable
assert "Plugin sets version variable" "[[ -n \$Z_SKK_VERSION ]]"

# Test plugin sets directory variable
assert "Plugin sets directory variable" "[[ -n \$Z_SKK_DIR ]]"

# Test lib directory exists
assert "Lib directory exists" "[[ -d '$PROJECT_DIR/lib' ]]"

# Test core.zsh exists
assert "Core.zsh exists" "[[ -f '$PROJECT_DIR/lib/core.zsh' ]]"

# Test z-skk-init function is defined
assert "z-skk-init function is defined" "(( \${+functions[z-skk-init]} ))"

# Test z-skk-unload function is defined
assert "z-skk-unload function is defined" "(( \${+functions[z-skk-unload]} ))"

# Summary
print "\n===== Test Summary ====="
print "Passed: $TESTS_PASSED"
print "Failed: $TESTS_FAILED"
print "======================="

# Exit with appropriate code
[[ $TESTS_FAILED -eq 0 ]]