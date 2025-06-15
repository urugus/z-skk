#!/usr/bin/env zsh
# Test dictionary cache functionality

# Test framework setup
typeset -g TEST_DIR="${0:A:h:h}"
typeset -g PROJECT_DIR="${TEST_DIR:h}"
typeset -g TEST_CACHE_DIR="${TEST_DIR}/test_cache_$$"

# Source test utilities
source "$TEST_DIR/test_utils.zsh"

# Create test directories
mkdir -p "$TEST_CACHE_DIR"

# Set cache directory for tests
export Z_SKK_CACHE_DIR="$TEST_CACHE_DIR"

# Source necessary modules directly (bypass lazy loading)
source "$PROJECT_DIR/lib/dictionary/dictionary-data.zsh"
source "$PROJECT_DIR/lib/dictionary/dictionary-io.zsh"
source "$PROJECT_DIR/lib/dictionary/dictionary-cache.zsh"

# Create a test dictionary file
test_dict="${TEST_DIR}/test_dict_$$/test.dict"
mkdir -p "${test_dict:h}"
cat > "$test_dict" <<'EOF'
;; Test dictionary
あい /愛/
かんじ /漢字/感じ/
にほん /日本/
EOF

# Ensure debug function exists
z-skk-debug() { [[ "${Z_SKK_DEBUG:-0}" == "1" ]] && print "z-skk DEBUG: $*" >&2 ; }
_z-skk-log-error() { print "z-skk: $2" >&2 ; }

# Test cache path generation
print "\n### Cache path generation ###"
cache_path="$(_z-skk-get-cache-path "/path/to/dict.txt")"
assert_equals "Cache path for dict.txt" "$TEST_CACHE_DIR/dict.txt.cache" "$cache_path"

cache_path="$(_z-skk-get-cache-path "/another/path/SKK-JISYO.L")"
assert_equals "Cache path for SKK-JISYO.L" "$TEST_CACHE_DIR/SKK-JISYO.L.cache" "$cache_path"

# Test cache validation
print "\n### Cache validation ###"
cache_path="$(_z-skk-get-cache-path "$test_dict")"

# Cache doesn't exist - should be invalid
if _z-skk-is-cache-valid "$test_dict" "$cache_path"; then
    print "✗ Cache should be invalid when it doesn't exist"
else
    print "✓ Cache correctly identified as invalid when missing"
fi

# Create a valid cache
mkdir -p "${cache_path:h}"
echo "Z_SKK_CACHE_v${Z_SKK_CACHE_VERSION}" > "$cache_path"
echo "# Test cache" >> "$cache_path"

# Cache exists and is newer - should be valid
touch -t 202501010000 "$test_dict"
touch -t 202501020000 "$cache_path"
if _z-skk-is-cache-valid "$test_dict" "$cache_path"; then
    print "✓ Valid cache correctly identified"
else
    print "✗ Cache should be valid when newer than dictionary"
fi

# Dictionary is newer - should be invalid
touch -t 202501030000 "$test_dict"
if _z-skk-is-cache-valid "$test_dict" "$cache_path"; then
    print "✗ Cache should be invalid when dictionary is newer"
else
    print "✓ Cache correctly identified as invalid when dictionary is newer"
fi

# Wrong cache version - should be invalid
echo "Z_SKK_CACHE_v0.1" > "$cache_path"
touch -t 202501040000 "$cache_path"
if _z-skk-is-cache-valid "$test_dict" "$cache_path"; then
    print "✗ Cache should be invalid with wrong version"
else
    print "✓ Cache correctly identified as invalid with wrong version"
fi

# Test cache saving
print "\n### Cache saving ###"
typeset -gA Z_SKK_DICTIONARY=()
z-skk-load-dictionary-file "$test_dict"

cache_path="$(_z-skk-get-cache-path "$test_dict")"
if _z-skk-save-cache "$test_dict" "$cache_path"; then
    print "✓ Cache saved successfully"
else
    print "✗ Failed to save cache"
fi

# Verify cache file exists
if [[ -f "$cache_path" ]]; then
    print "✓ Cache file exists"
else
    print "✗ Cache file not created"
fi

# Check cache header
header=$(head -n1 "$cache_path")
assert_equals "Cache header" "Z_SKK_CACHE_v${Z_SKK_CACHE_VERSION}" "$header"

# Check that entries were saved
if grep -q 'あい	愛' "$cache_path"; then
    print "✓ Entry 'あい' saved to cache"
else
    print "✗ Entry 'あい' not found in cache"
fi

if grep -q 'かんじ	漢字/感じ' "$cache_path"; then
    print "✓ Entry 'かんじ' saved to cache"
else
    print "✗ Entry 'かんじ' not found in cache"
fi

# Test cache loading
print "\n### Cache loading ###"
cache_path="${TEST_CACHE_DIR}/test.cache"

# Create a cache file manually
cat > "$cache_path" <<EOF
Z_SKK_CACHE_v${Z_SKK_CACHE_VERSION}
# Test cache
# Generated at: 2025-01-15

あい	愛
かんじ	漢字/感じ
にほん	日本
EOF

# Clear dictionary
Z_SKK_DICTIONARY=()

# Load cache
if _z-skk-load-cache "$cache_path"; then
    print "✓ Cache loaded successfully"
else
    print "✗ Failed to load cache"
fi

# Verify entries were loaded
assert_equals "Dictionary entry あい" "愛" "${Z_SKK_DICTIONARY[あい]}"
assert_equals "Dictionary entry かんじ" "漢字/感じ" "${Z_SKK_DICTIONARY[かんじ]}"
assert_equals "Dictionary entry にほん" "日本" "${Z_SKK_DICTIONARY[にほん]}"

# Test integrated cache loading
print "\n### Integrated dictionary loading with cache ###"
test_dict2="${TEST_DIR}/test_dict_$$/test2.dict"
cat > "$test_dict2" <<'EOF'
;; Test dictionary 2
てすと /テスト/test/
さんぷる /サンプル/sample/
EOF

# First load - should create cache
Z_SKK_DICTIONARY=()
if z-skk-load-dictionary-with-cache "$test_dict2"; then
    print "✓ Dictionary loaded successfully (first time)"
else
    print "✗ Failed to load dictionary"
fi

# Verify dictionary was loaded
assert_equals "Dictionary entry てすと" "テスト/test" "${Z_SKK_DICTIONARY[てすと]}"

# Verify cache was created
cache_path2="$(_z-skk-get-cache-path "$test_dict2")"
if [[ -f "$cache_path2" ]]; then
    print "✓ Cache created after first load"
else
    print "✗ Cache not created after first load"
fi

# Clear dictionary and load again - should use cache
Z_SKK_DICTIONARY=()

# Make cache newer than dictionary
touch -t 202501010000 "$test_dict2"
touch -t 202501020000 "$cache_path2"

# Load should use cache
if z-skk-load-dictionary-with-cache "$test_dict2"; then
    print "✓ Dictionary loaded successfully (from cache)"
else
    print "✗ Failed to load from cache"
fi

assert_equals "Dictionary entry てすと (from cache)" "テスト/test" "${Z_SKK_DICTIONARY[てすと]}"

# Test cache clearing
print "\n### Cache clearing ###"
# Create some cache files
cache1="${TEST_CACHE_DIR}/test1.cache"
cache2="${TEST_CACHE_DIR}/test2.cache"
echo "test" > "$cache1"
echo "test" > "$cache2"

# Verify files exist
if [[ -f "$cache1" ]] && [[ -f "$cache2" ]]; then
    print "✓ Test cache files created"
else
    print "✗ Failed to create test cache files"
fi

# Clear cache
z-skk-clear-cache 2>/dev/null

# Verify cache directory was removed
if [[ -d "$TEST_CACHE_DIR" ]]; then
    print "✗ Cache directory should be removed"
else
    print "✓ Cache directory successfully cleared"
fi

# Cleanup
rm -rf "${TEST_DIR}/test_dict_$$"
rm -rf "$TEST_CACHE_DIR"

# Summary
print_test_summary