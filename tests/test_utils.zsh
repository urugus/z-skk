#!/usr/bin/env zsh
# Test framework utilities

# Global test counters
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

# Assert equals function
assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then
        print "✓ $description"
        (( TESTS_PASSED++ ))
    else
        print "✗ $description"
        print "  Expected: '$expected'"
        print "  Actual: '$actual'"
        (( TESTS_FAILED++ ))
    fi
}

# Reset test counters
reset_test_counters() {
    TESTS_PASSED=0
    TESTS_FAILED=0
}

# Print test summary
print_test_summary() {
    print "\n===== Test Summary ====="
    print "Passed: $TESTS_PASSED"
    print "Failed: $TESTS_FAILED"
    print "======================="

    # Return appropriate exit code
    [[ $TESTS_FAILED -eq 0 ]]
}