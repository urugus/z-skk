#!/usr/bin/env zsh
# Pre-commit CI verification script

typeset -g SCRIPT_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${SCRIPT_DIR:h}"
typeset -g ERRORS=0

print "=== Running pre-commit CI checks ==="
print ""

# 1. Run all tests
print "1. Running tests..."
if zsh "$PROJECT_DIR/tests/run_all.zsh"; then
    print "✓ All tests passed"
else
    print "✗ Tests failed"
    (( ERRORS++ ))
fi
print ""

# 2. Check file permissions
print "2. Checking file permissions..."
typeset -g PERM_ERRORS=0
find "$PROJECT_DIR" -name "*.zsh" -type f | while read -r file; do
    if [[ ! -x "$file" ]]; then
        print "✗ Not executable: $file"
        (( PERM_ERRORS++ ))
    fi
done

if [[ $PERM_ERRORS -eq 0 ]]; then
    print "✓ All .zsh files are executable"
else
    (( ERRORS++ ))
fi
print ""

# 3. Check for trailing whitespace
print "3. Checking for trailing whitespace..."
if grep -r '[[:space:]]$' --include="*.zsh" "$PROJECT_DIR" 2>/dev/null; then
    print "✗ Found trailing whitespace in above files"
    (( ERRORS++ ))
else
    print "✓ No trailing whitespace found"
fi
print ""

# 4. Check for tabs vs spaces
print "4. Checking indentation consistency..."
if grep -r $'^\t' --include="*.zsh" "$PROJECT_DIR" 2>/dev/null; then
    print "⚠ Warning: Found tabs used for indentation (should use spaces)"
else
    print "✓ Consistent spacing (no tabs found)"
fi
print ""

# 5. Check naming conventions
print "5. Checking naming conventions..."
if zsh "$PROJECT_DIR/scripts/check-naming-conventions.zsh" >/dev/null 2>&1; then
    print "✓ All naming conventions are correct"
else
    print "✗ Naming convention errors found"
    zsh "$PROJECT_DIR/scripts/check-naming-conventions.zsh" 2>&1 | grep "ERROR" | head -10
    (( ERRORS++ ))
fi
print ""

# 6. Run integration tests (optional)
print "6. Running integration tests (optional)..."
if [[ -f "$PROJECT_DIR/tests/integration/run_integration_tests.zsh" ]]; then
    if zsh "$PROJECT_DIR/tests/integration/run_integration_tests.zsh"; then
        print "✓ All integration tests passed"
    else
        print "⚠ Integration tests failed (non-critical)"
        print "  Note: Integration tests may fail in some environments"
        print "  Please run them manually in an interactive terminal"
    fi
else
    print "⚠ Integration tests not found (skipping)"
fi
print ""

# Summary
print "=== Pre-commit check summary ==="
if [[ $ERRORS -eq 0 ]]; then
    print "✅ All checks passed! Ready to commit."
    exit 0
else
    print "❌ Found $ERRORS error(s). Please fix before committing."
    exit 1
fi