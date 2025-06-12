#!/usr/bin/env zsh
# Test core functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Source the plugin
source "$PROJECT_DIR/z-skk.plugin.zsh"

# Test state variables
assert "[[ -n \${Z_SKK_MODE+x} ]]" "Z_SKK_MODE is defined"
assert "[[ \$Z_SKK_MODE == 'ascii' ]]" "Z_SKK_MODE default is 'ascii'"

assert "[[ -n \${Z_SKK_CONVERTING+x} ]]" "Z_SKK_CONVERTING is defined"
assert "[[ \$Z_SKK_CONVERTING -eq 0 ]]" "Z_SKK_CONVERTING default is 0"

assert "[[ -n \${Z_SKK_BUFFER+x} ]]" "Z_SKK_BUFFER is defined"
assert "[[ -z \$Z_SKK_BUFFER ]]" "Z_SKK_BUFFER default is empty"

assert "[[ -n \${Z_SKK_CANDIDATES+x} ]]" "Z_SKK_CANDIDATES is defined"
assert "[[ \${(t)Z_SKK_CANDIDATES} == array* ]]" "Z_SKK_CANDIDATES is array"
assert "[[ \${#Z_SKK_CANDIDATES[@]} -eq 0 ]]" "Z_SKK_CANDIDATES default is empty"

assert "[[ -n \${Z_SKK_CANDIDATE_INDEX+x} ]]" "Z_SKK_CANDIDATE_INDEX is defined"
assert "[[ \$Z_SKK_CANDIDATE_INDEX -eq 0 ]]" "Z_SKK_CANDIDATE_INDEX default is 0"

# Test mode definitions
assert "[[ -n \${Z_SKK_MODE_NAMES+x} ]]" "Z_SKK_MODE_NAMES is defined"
assert "[[ \${(t)Z_SKK_MODE_NAMES} == association* ]]" "Z_SKK_MODE_NAMES is associative array"
assert "[[ -n \${Z_SKK_MODE_NAMES[hiragana]} ]]" "Z_SKK_MODE_NAMES has hiragana mode"
assert "[[ -n \${Z_SKK_MODE_NAMES[katakana]} ]]" "Z_SKK_MODE_NAMES has katakana mode"
assert "[[ -n \${Z_SKK_MODE_NAMES[ascii]} ]]" "Z_SKK_MODE_NAMES has ascii mode"

# Test initialization function
assert "(( \${+functions[z-skk-reset-state]} ))" "z-skk-reset-state function exists"

# Test reset functionality
Z_SKK_MODE="hiragana"
Z_SKK_BUFFER="test"
Z_SKK_CONVERTING=1
z-skk-reset-state

assert "[[ -z \$Z_SKK_BUFFER ]]" "Reset clears Z_SKK_BUFFER"
assert "[[ \$Z_SKK_CONVERTING -eq 0 ]]" "Reset sets Z_SKK_CONVERTING to 0"
assert "[[ \${#Z_SKK_CANDIDATES[@]} -eq 0 ]]" "Reset clears Z_SKK_CANDIDATES"
assert "[[ \$Z_SKK_CANDIDATE_INDEX -eq 0 ]]" "Reset sets Z_SKK_CANDIDATE_INDEX to 0"

# Print summary and exit
print_test_summary