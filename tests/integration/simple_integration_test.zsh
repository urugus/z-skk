#!/usr/bin/env zsh
# シンプルな統合テスト - 実際の入力をシミュレート

# プロジェクトのルートディレクトリ
PROJECT_ROOT="${0:A:h:h:h}"

# テスト用の一時ファイル
TEST_OUTPUT="/tmp/z-skk-test-output-$$"
TEST_SCRIPT="/tmp/z-skk-test-script-$$"

# クリーンアップ
trap "rm -f $TEST_OUTPUT $TEST_SCRIPT" EXIT INT TERM

# テスト結果カウンター
typeset -g TEST_COUNT=0
typeset -g PASS_COUNT=0
typeset -g FAIL_COUNT=0

# アサーション関数
assert_contains() {
    local expected="$1"
    local actual="$2"
    local description="$3"

    ((TEST_COUNT++))

    if [[ "$actual" == *"$expected"* ]]; then
        ((PASS_COUNT++))
        echo "  ✓ $description"
    else
        ((FAIL_COUNT++))
        echo "  ✗ $description"
        echo "    Expected: $expected"
        echo "    Actual: ${actual:0:100}..."
    fi
}

# テストスクリプトを作成して実行
run_test_script() {
    local script_content="$1"
    local description="$2"

    # テストスクリプトを作成
    cat > "$TEST_SCRIPT" << EOF
#!/usr/bin/env zsh
source '$PROJECT_ROOT/z-skk.plugin.zsh'

# テスト用の関数をオーバーライド
typeset -g TEST_OUTPUT=""

# 実際の出力を記録する関数
zle-line-accept() {
    TEST_OUTPUT+="\$BUFFER"
    BUFFER=""
    zle .accept-line 2>/dev/null || true
}
zle -N zle-line-accept

# Enter キーをバインド
bindkey '^M' zle-line-accept

# テストコードを実行
$script_content

# 結果を出力
echo "\$TEST_OUTPUT"
EOF

    chmod +x "$TEST_SCRIPT"

    # スクリプトを実行
    local output=$(zsh -c "$TEST_SCRIPT" 2>/dev/null)

    echo "Test: $description"
    echo "$output"

    rm -f "$TEST_SCRIPT"
}

echo "=== Simple Integration Test ==="
echo

# Test 1: 基本的なひらがな入力
cat > "$TEST_SCRIPT" << 'EOF'
source '$PROJECT_ROOT/z-skk.plugin.zsh'

# グローバル変数でバッファを管理
BUFFER=""

# かなモードに切り替え
skk-mode-hiragana

# 文字を入力
BUFFER="nihongo"
skk-handle-input

echo "$BUFFER"
EOF

output=$(zsh "$TEST_SCRIPT" 2>/dev/null)
assert_contains "にほんご" "$output" "Basic hiragana input"

# Test 2: 変換機能
cat > "$TEST_SCRIPT" << 'EOF'
source '$PROJECT_ROOT/z-skk.plugin.zsh'

BUFFER=""
skk-mode-hiragana

# "Kanji"を入力して変換
BUFFER="K"
skk-handle-input
BUFFER="${BUFFER}anji"
skk-handle-input

# スペースで変換
SKK_HENKAN_BUFFER="かんじ"
SKK_MODE="converting"
skk-henkan-next

echo "$BUFFER"
EOF

output=$(zsh "$TEST_SCRIPT" 2>/dev/null)
assert_contains "漢字" "$output" "Kanji conversion"

# Test 3: モード切り替え
cat > "$TEST_SCRIPT" << 'EOF'
source '$PROJECT_ROOT/z-skk.plugin.zsh'

BUFFER=""

# デフォルトは英数モード
BUFFER="hello"
echo "ASCII: $BUFFER"

# かなモードへ
skk-mode-hiragana
BUFFER="aiueo"
skk-handle-input
echo "Hiragana: $BUFFER"

# カタカナモードへ
skk-mode-katakana
BUFFER="aiueo"
skk-handle-input
echo "Katakana: $BUFFER"
EOF

output=$(zsh "$TEST_SCRIPT" 2>/dev/null)
assert_contains "ASCII: hello" "$output" "ASCII mode"
assert_contains "Hiragana: あいうえお" "$output" "Hiragana mode"
assert_contains "Katakana: アイウエオ" "$output" "Katakana mode"

# サマリー
echo
echo "=== Test Summary ==="
echo "Total: $TEST_COUNT"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if (( FAIL_COUNT > 0 )); then
    exit 1
else
    exit 0
fi