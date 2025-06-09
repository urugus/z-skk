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
assert "Z_SKK_MODE is defined" "[[ -n \${Z_SKK_MODE+x} ]]"
assert "Z_SKK_MODE default is 'ascii'" "[[ \$Z_SKK_MODE == 'ascii' ]]"

assert "Z_SKK_CONVERTING is defined" "[[ -n \${Z_SKK_CONVERTING+x} ]]"
assert "Z_SKK_CONVERTING default is 0" "[[ \$Z_SKK_CONVERTING -eq 0 ]]"

assert "Z_SKK_BUFFER is defined" "[[ -n \${Z_SKK_BUFFER+x} ]]"
assert "Z_SKK_BUFFER default is empty" "[[ -z \$Z_SKK_BUFFER ]]"

assert "Z_SKK_CANDIDATES is defined" "[[ -n \${Z_SKK_CANDIDATES+x} ]]"
assert "Z_SKK_CANDIDATES is array" "[[ \${(t)Z_SKK_CANDIDATES} == array* ]]"
assert "Z_SKK_CANDIDATES default is empty" "[[ \${#Z_SKK_CANDIDATES[@]} -eq 0 ]]"

assert "Z_SKK_CANDIDATE_INDEX is defined" "[[ -n \${Z_SKK_CANDIDATE_INDEX+x} ]]"
assert "Z_SKK_CANDIDATE_INDEX default is 0" "[[ \$Z_SKK_CANDIDATE_INDEX -eq 0 ]]"

# Test mode definitions
assert "Z_SKK_MODES is defined" "[[ -n \${Z_SKK_MODES+x} ]]"
assert "Z_SKK_MODES is associative array" "[[ \${(t)Z_SKK_MODES} == association* ]]"
assert "Z_SKK_MODES has hiragana mode" "[[ -n \${Z_SKK_MODES[hiragana]} ]]"
assert "Z_SKK_MODES has katakana mode" "[[ -n \${Z_SKK_MODES[katakana]} ]]"
assert "Z_SKK_MODES has ascii mode" "[[ -n \${Z_SKK_MODES[ascii]} ]]"

# Test initialization function
assert "z-skk-reset-state function exists" "(( \${+functions[z-skk-reset-state]} ))"

# Test reset functionality
Z_SKK_MODE="hiragana"
Z_SKK_BUFFER="test"
Z_SKK_CONVERTING=1
z-skk-reset-state

assert "Reset clears Z_SKK_BUFFER" "[[ -z \$Z_SKK_BUFFER ]]"
assert "Reset sets Z_SKK_CONVERTING to 0" "[[ \$Z_SKK_CONVERTING -eq 0 ]]"
assert "Reset clears Z_SKK_CANDIDATES" "[[ \${#Z_SKK_CANDIDATES[@]} -eq 0 ]]"
assert "Reset sets Z_SKK_CANDIDATE_INDEX to 0" "[[ \$Z_SKK_CANDIDATE_INDEX -eq 0 ]]"

# Print summary and exit
print_test_summary