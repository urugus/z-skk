#!/usr/bin/env zsh
# CI環境でも動作する統合テスト

# プロジェクトルートを取得
PROJECT_ROOT="${0:A:h:h:h}"

# 環境設定
export Z_SKK_TEST_MODE=1
export Z_SKK_USE_CACHE=0

# z-skkを読み込む
source "$PROJECT_ROOT/z-skk.plugin.zsh"

# テスト結果カウンター
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# アサーション関数
assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ $description"
        ((TESTS_PASSED++))
    else
        echo "✗ $description"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((TESTS_FAILED++))
    fi
}

echo "=== CI Compatible Integration Test ==="
echo

# Test 1: Basic mode switching
echo "Test 1: Mode switching"
z-skk-set-mode ascii
assert_equals "Initial ASCII mode" "ascii" "$Z_SKK_MODE"

z-skk-set-mode hiragana
assert_equals "Switch to hiragana" "hiragana" "$Z_SKK_MODE"

z-skk-set-mode katakana
assert_equals "Switch to katakana" "katakana" "$Z_SKK_MODE"

echo

# Test 2: Basic conversion
echo "Test 2: Basic conversion"
z-skk-set-mode hiragana

# デバッグ情報
echo "  Debug: Z_SKK_ROMAJI_TO_HIRAGANA table exists: ${+Z_SKK_ROMAJI_TO_HIRAGANA}"
echo "  Debug: z-skk-convert-romaji function exists: ${+functions[z-skk-convert-romaji]}"

# "nihongo"を文字単位で変換
Z_SKK_BUFFER=""
for char in n i h o n g o; do
    Z_SKK_ROMAJI_BUFFER+="$char"
    z-skk-convert-romaji
    if [[ -n "$Z_SKK_CONVERTED" ]]; then
        Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
    fi
done
assert_equals "Convert nihongo" "にほんご" "$Z_SKK_BUFFER"

Z_SKK_BUFFER=""
Z_SKK_ROMAJI_BUFFER="kanji"
z-skk-convert-romaji
if [[ -n "$Z_SKK_CONVERTED" ]]; then
    Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
fi
assert_equals "Convert kanji" "かんじ" "$Z_SKK_BUFFER"

echo

# Test 3: Katakana conversion
echo "Test 3: Katakana conversion"
z-skk-set-mode katakana
Z_SKK_BUFFER=""
Z_SKK_ROMAJI_BUFFER="konpyuuta"
z-skk-convert-romaji
if [[ -n "$Z_SKK_CONVERTED" ]]; then
    Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
fi
assert_equals "Convert to katakana" "コンピュータ" "$Z_SKK_BUFFER"

echo

# Test 4: Dictionary lookup
echo "Test 4: Dictionary lookup"
z-skk-load-dictionary  # 辞書を読み込む
candidates=$(z-skk-lookup "かんじ")
if [[ -n "$candidates" ]]; then
    echo "✓ Dictionary lookup successful"
    ((TESTS_PASSED++))
else
    echo "✗ Dictionary lookup failed"
    ((TESTS_FAILED++))
fi

echo

# Test 5: Conversion flow simulation
echo "Test 5: Conversion flow simulation"
z-skk-set-mode hiragana
z-skk-reset-state

# 変換開始
Z_SKK_CONVERTING=1
Z_SKK_CONVERSION_START_POS=0
LBUFFER=""

# かな入力
Z_SKK_ROMAJI_BUFFER="ka"
z-skk-convert-romaji
if [[ -n "$Z_SKK_CONVERTED" ]]; then
    Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
fi
LBUFFER="▽$Z_SKK_BUFFER"

Z_SKK_ROMAJI_BUFFER="n"
z-skk-convert-romaji
if [[ -n "$Z_SKK_CONVERTED" ]]; then
    Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
fi
LBUFFER="▽$Z_SKK_BUFFER"

Z_SKK_ROMAJI_BUFFER="ji"
z-skk-convert-romaji
if [[ -n "$Z_SKK_CONVERTED" ]]; then
    Z_SKK_BUFFER+="$Z_SKK_CONVERTED"
fi
LBUFFER="▽$Z_SKK_BUFFER"

assert_equals "Pre-conversion buffer" "かんじ" "$Z_SKK_BUFFER"

# 変換実行
if z-skk-lookup "$Z_SKK_BUFFER" >/dev/null; then
    Z_SKK_CANDIDATES=($(z-skk-split-candidates "$(z-skk-lookup "$Z_SKK_BUFFER")"))
    Z_SKK_CANDIDATE_INDEX=0
    Z_SKK_CONVERTING=2
    LBUFFER="▼${Z_SKK_CANDIDATES[1]}"
    echo "✓ Conversion executed"
    ((TESTS_PASSED++))
else
    echo "✗ Conversion failed"
    ((TESTS_FAILED++))
fi

echo
echo "=== Test Summary ==="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

[[ $TESTS_FAILED -eq 0 ]]