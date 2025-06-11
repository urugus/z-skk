#!/usr/bin/env zsh
# Check naming conventions for z-skk project

typeset -g SCRIPT_DIR="${0:A:h}"
typeset -g PROJECT_DIR="${SCRIPT_DIR:h}"
typeset -g ERRORS=0

print "=== Checking naming conventions ==="

# Check function naming conventions
print "\nChecking function naming..."
for file in "$PROJECT_DIR"/lib/*.zsh; do
    [[ ! -f "$file" ]] && continue

    # Use grep to find function definitions more accurately
    grep -E '^[a-zA-Z0-9_-]+\(\)[[:space:]]*\{?' "$file" | while read -r line; do
        # Extract function name
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)\(\) ]]; then
            func_name="${match[1]}"

            # Skip shell keywords that might appear in grep results
            case "$func_name" in
                if|fi|then|else|elif|esac|do|done|for|while|until|function|local|typeset|declare|eval|return|shift|echo|print|case)
                    continue
                    ;;
            esac

            # Skip zle widget functions (they have special naming)
            [[ "$func_name" == "zle-"* ]] && continue

            # Check public function naming (should be z-skk-*)
            if [[ "$func_name" =~ ^[a-z] ]] && [[ "$func_name" != "z-skk-"* ]] && [[ "$func_name" != "_"* ]]; then
                print "ERROR in $file: Public function '$func_name' should start with 'z-skk-'"
                ((ERRORS++))
            fi

            # Check private function naming (should be _z-skk-*)
            if [[ "$func_name" == "_"* ]] && [[ "$func_name" != "_z-skk-"* ]] && [[ "$func_name" != "_test_"* ]]; then
                print "ERROR in $file: Private function '$func_name' should start with '_z-skk-'"
                ((ERRORS++))
            fi

            # Check for underscores in function names (should use hyphens)
            if [[ "$func_name" =~ "z_skk" ]]; then
                print "ERROR in $file: Function '$func_name' uses underscores instead of hyphens"
                ((ERRORS++))
            fi
        fi
    done
done

# Check global variable naming conventions
print "\nChecking global variable naming..."
for file in "$PROJECT_DIR"/lib/*.zsh; do
    [[ ! -f "$file" ]] && continue

    # Extract typeset/declare statements for global variables
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*typeset[[:space:]]+-g[[:space:]]+([A-Z_][A-Z0-9_]*) ]] || \
           [[ "$line" =~ ^[[:space:]]*declare[[:space:]]+-g[[:space:]]+([A-Z_][A-Z0-9_]*) ]]; then
            var_name="${match[1]}"

            # Check global variable naming (should be Z_SKK_*)
            if [[ "$var_name" != "Z_SKK_"* ]] && [[ "$var_name" != "TEST_"* ]] && [[ "$var_name" != "SCRIPT_"* ]]; then
                print "ERROR in $file: Global variable '$var_name' should start with 'Z_SKK_'"
                ((ERRORS++))
            fi
        fi
    done < "$file"
done

# Check for common naming mistakes
print "\nChecking for common naming mistakes..."
if grep -r "z-skk_" "$PROJECT_DIR"/lib --include="*.zsh" > /dev/null 2>&1; then
    print "ERROR: Found mixed hyphen/underscore usage:"
    grep -r "z-skk_" "$PROJECT_DIR"/lib --include="*.zsh" | head -5
    ((ERRORS++))
fi

if grep -r "Z_skk_" "$PROJECT_DIR"/lib --include="*.zsh" > /dev/null 2>&1; then
    print "ERROR: Found inconsistent capitalization:"
    grep -r "Z_skk_" "$PROJECT_DIR"/lib --include="*.zsh" | head -5
    ((ERRORS++))
fi

# Summary
print "\n=== Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    print "✓ All naming conventions are correct!"
    exit 0
else
    print "✗ Found $ERRORS naming convention errors"
    exit 1
fi