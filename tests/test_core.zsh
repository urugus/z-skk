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
assert "SKK_MODE is defined" "[[ -n \${SKK_MODE+x} ]]"
assert "SKK_MODE default is 'ascii'" "[[ \$SKK_MODE == 'ascii' ]]"

assert "SKK_CONVERTING is defined" "[[ -n \${SKK_CONVERTING+x} ]]"
assert "SKK_CONVERTING default is 0" "[[ \$SKK_CONVERTING -eq 0 ]]"

assert "SKK_BUFFER is defined" "[[ -n \${SKK_BUFFER+x} ]]"
assert "SKK_BUFFER default is empty" "[[ -z \$SKK_BUFFER ]]"

assert "SKK_CANDIDATES is defined" "[[ -n \${SKK_CANDIDATES+x} ]]"
assert "SKK_CANDIDATES is array" "[[ \${(t)SKK_CANDIDATES} == array* ]]"
assert "SKK_CANDIDATES default is empty" "[[ \${#SKK_CANDIDATES[@]} -eq 0 ]]"

assert "SKK_CANDIDATE_INDEX is defined" "[[ -n \${SKK_CANDIDATE_INDEX+x} ]]"
assert "SKK_CANDIDATE_INDEX default is 0" "[[ \$SKK_CANDIDATE_INDEX -eq 0 ]]"

# Test mode definitions
assert "SKK_MODES is defined" "[[ -n \${SKK_MODES+x} ]]"
assert "SKK_MODES is associative array" "[[ \${(t)SKK_MODES} == association* ]]"
assert "SKK_MODES has hiragana mode" "[[ -n \${SKK_MODES[hiragana]} ]]"
assert "SKK_MODES has katakana mode" "[[ -n \${SKK_MODES[katakana]} ]]"
assert "SKK_MODES has ascii mode" "[[ -n \${SKK_MODES[ascii]} ]]"

# Test initialization function
assert "z-skk-reset-state function exists" "(( \${+functions[z-skk-reset-state]} ))"

# Test reset functionality
SKK_MODE="hiragana"
SKK_BUFFER="test"
SKK_CONVERTING=1
z-skk-reset-state

assert "Reset clears SKK_BUFFER" "[[ -z \$SKK_BUFFER ]]"
assert "Reset sets SKK_CONVERTING to 0" "[[ \$SKK_CONVERTING -eq 0 ]]"
assert "Reset clears SKK_CANDIDATES" "[[ \${#SKK_CANDIDATES[@]} -eq 0 ]]"
assert "Reset sets SKK_CANDIDATE_INDEX to 0" "[[ \$SKK_CANDIDATE_INDEX -eq 0 ]]"

# Print summary and exit
print_test_summary