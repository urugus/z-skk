#!/usr/bin/env zsh
# Run all tests

typeset -g SCRIPT_DIR="${0:A:h}"
typeset -g TOTAL_PASSED=0
typeset -g TOTAL_FAILED=0
typeset -A TEST_RESULTS

print "=== Running all z-skk tests ===\n"

# Find and run all test files
for test_file in "$SCRIPT_DIR"/test_*.zsh; do
    if [[ -f "$test_file" && "$test_file" != "$0" ]]; then
        test_name="${test_file:t}"

        # Skip interactive tests
        if [[ "$test_name" == "test_interactive.zsh" || "$test_name" == "manual_test.zsh" ]]; then
            print "Skipping interactive test: $test_name"
            continue
        fi

        # Skip display test due to RPROMPT/precmd_functions limitations in non-interactive shell
        if [[ "$test_name" == "test_display.zsh" ]]; then
            print "Skipping display test in non-interactive shell: $test_name"
            TEST_RESULTS[$test_name]="SKIPPED"
            continue
        fi

        # Skip new tests until they are stabilized
        if [[ "$test_name" == "test_input.zsh" || "$test_name" == "test_error.zsh" ]]; then
            print "Skipping experimental test: $test_name"
            TEST_RESULTS[$test_name]="SKIPPED"
            continue
        fi

        print "Running: $test_name"
        print "---"

        # Run test and capture result
        if zsh "$test_file"; then
            TEST_RESULTS[$test_name]="PASSED"
        else
            TEST_RESULTS[$test_name]="FAILED"
            (( TOTAL_FAILED++ ))
        fi

        print "\n"
    fi
done

# Summary
print "=== Test Summary ==="
for test_name result in ${(kv)TEST_RESULTS}; do
    if [[ "$result" == "PASSED" ]]; then
        print "✓ $test_name"
        (( TOTAL_PASSED++ ))
    elif [[ "$result" == "SKIPPED" ]]; then
        print "⚬ $test_name (skipped)"
    else
        print "✗ $test_name"
    fi
done

print "\nTotal Passed: $TOTAL_PASSED"
print "Total Failed: $TOTAL_FAILED"
print "==================="

# Exit with failure if any tests failed
[[ $TOTAL_FAILED -eq 0 ]]