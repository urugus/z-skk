#!/usr/bin/env zsh
# Test plugin loading

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

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

# Print summary and exit
print_test_summary