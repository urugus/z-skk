#!/usr/bin/env zsh
# Run all tests

typeset -g TEST_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"
typeset -g TOTAL_PASSED=0
typeset -g TOTAL_FAILED=0
typeset -g TOTAL_SKIPPED=0
typeset -A TEST_RESULTS

# Color definitions
typeset -g RED='\033[0;31m'
typeset -g GREEN='\033[0;32m'
typeset -g YELLOW='\033[0;33m'
typeset -g RESET='\033[0m'

print "=== Running all z-skk tests ===\n"

# Function to run a single test
run_test() {
    local test_file="$1"
    local test_name="${test_file:t}"

    # Skip interactive and manual tests
    if [[ "$test_name" =~ "^(test_interactive|manual_)" ]]; then
        print "${YELLOW}Skipping interactive/manual test: $test_name${RESET}"
        TEST_RESULTS[$test_name]="SKIPPED"
        (( TOTAL_SKIPPED++ ))
        return
    fi
    
    # Skip input handling test in CI as it requires interactive terminal
    if [[ -n "$CI" && "$test_name" == "test_input_handling.zsh" ]]; then
        print "${YELLOW}Skipping $test_name in CI environment (requires interactive terminal)${RESET}"
        TEST_RESULTS[$test_name]="SKIPPED"
        (( TOTAL_SKIPPED++ ))
        return
    fi

    print "Running: $test_name"
    print "---"

    # Run test and capture result
    if zsh "$test_file"; then
        TEST_RESULTS[$test_name]="PASSED"
        (( TOTAL_PASSED++ ))
    else
        TEST_RESULTS[$test_name]="FAILED"
        (( TOTAL_FAILED++ ))
    fi

    print ""
}

# Function to run tests in a directory
run_tests_in_dir() {
    local dir="$1"
    local pattern="${2:-test_*.zsh}"

    for test_file in "$dir"/$~pattern; do
        [[ -f "$test_file" ]] || continue
        run_test "$test_file"
    done
}

# Run unit tests
if [[ -d "$TEST_DIR/unit" ]]; then
    echo "\n${YELLOW}Running Unit Tests...${RESET}"
    run_tests_in_dir "$TEST_DIR/unit"
fi

# Run integration tests
if [[ -d "$TEST_DIR/integration" ]]; then
    # Skip integration tests in CI environment as they require interactive terminal
    if [[ -n "$CI" ]]; then
        echo "\n${YELLOW}Skipping Integration Tests in CI environment...${RESET}"
        for test_file in "$TEST_DIR/integration"/test_*.zsh; do
            [[ -f "$test_file" ]] || continue
            local test_name="${test_file:t}"
            TEST_RESULTS[$test_name]="SKIPPED"
            (( TOTAL_SKIPPED++ ))
            print "${YELLOW}⚬ $test_name (skipped - requires interactive terminal)${RESET}"
        done
    else
        echo "\n${YELLOW}Running Integration Tests...${RESET}"
        run_tests_in_dir "$TEST_DIR/integration" "test_*.zsh"
    fi
fi

# Run regression tests
if [[ -d "$TEST_DIR/regression" ]]; then
    echo "\n${YELLOW}Running Regression Tests...${RESET}"
    run_tests_in_dir "$TEST_DIR/regression"
fi

# Run loading tests
if [[ -d "$TEST_DIR/loading" ]]; then
    echo "\n${YELLOW}Running Loading Tests...${RESET}"
    run_tests_in_dir "$TEST_DIR/loading"
fi

# Run tests in root directory (for backward compatibility)
echo "\n${YELLOW}Running Root Tests...${RESET}"
run_tests_in_dir "$TEST_DIR"

# Summary
print "\n=== Test Summary ==="
for test_name result in ${(kv)TEST_RESULTS}; do
    if [[ "$result" == "PASSED" ]]; then
        print "${GREEN}✓ $test_name${RESET}"
    elif [[ "$result" == "SKIPPED" ]]; then
        print "${YELLOW}⚬ $test_name (skipped)${RESET}"
    else
        print "${RED}✗ $test_name${RESET}"
    fi
done

print "\nTotal Passed: ${GREEN}$TOTAL_PASSED${RESET}"
print "Total Failed: ${RED}$TOTAL_FAILED${RESET}"
print "Total Skipped: ${YELLOW}$TOTAL_SKIPPED${RESET}"
print "==================="

# Exit with failure if any tests failed
[[ $TOTAL_FAILED -eq 0 ]]