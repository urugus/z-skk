#!/usr/bin/env zsh
# 統合テストランナー

# スクリプトのディレクトリを取得
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"

# 色付き出力用の設定
autoload -U colors && colors

# グローバル変数
typeset -g TOTAL_TESTS=0
typeset -g PASSED_TESTS=0
typeset -g FAILED_TESTS=0
typeset -g FAILED_TEST_FILES=()

# エラーハンドリング
set -e
trap 'echo "${fg[red]}Integration test runner interrupted${reset_color}"' INT TERM

# ヘッダーを表示
echo "${fg[blue]}========================================${reset_color}"
echo "${fg[blue]}   z-skk Integration Test Runner${reset_color}"
echo "${fg[blue]}========================================${reset_color}"
echo

# zptyモジュールの確認
if ! zmodload zsh/zpty 2>/dev/null; then
    echo "${fg[red]}Error: zsh/zpty module is not available${reset_color}"
    echo "Integration tests require zsh with zpty support"
    exit 1
fi

# z-skkプラグインの存在確認
if [[ ! -f "$PROJECT_ROOT/z-skk.plugin.zsh" ]]; then
    echo "${fg[red]}Error: z-skk.plugin.zsh not found${reset_color}"
    echo "Expected location: $PROJECT_ROOT/z-skk.plugin.zsh"
    exit 1
fi

# expectコマンドの可用性をチェック
EXPECT_AVAILABLE=0
if command -v expect >/dev/null 2>&1; then
    EXPECT_AVAILABLE=1
    echo "expect command is available"
else
    echo "${fg[yellow]}expect command not found - skipping expect-based tests${reset_color}"
fi

# テストファイルを検索
echo "Searching for integration tests..."
test_files=("$SCRIPT_DIR"/test_*.zsh(N))
expect_files=()

# expectが利用可能な場合、expectテストも追加
if (( EXPECT_AVAILABLE )); then
    expect_files=("$SCRIPT_DIR"/*.exp(N))
fi

total_files=$(( ${#test_files[@]} + ${#expect_files[@]} ))

if (( total_files == 0 )); then
    echo "${fg[yellow]}No integration test files found${reset_color}"
    exit 0
fi

echo "Found $total_files integration test file(s)"
echo

# 各テストファイルを実行
all_test_files=("${test_files[@]}" "${expect_files[@]}")

for test_file in "${all_test_files[@]}"; do
    test_name="${test_file:t:r}"

    echo "${fg[cyan]}Running: $test_name${reset_color}"
    echo "${fg[cyan]}----------------------------------------${reset_color}"

    # テストを実行
    if [[ "$test_file" == *.exp ]]; then
        # expectテストの実行
        if expect "$test_file"; then
            ((PASSED_TESTS++))
            echo "${fg[green]}✓ $test_name passed${reset_color}"
        else
            ((FAILED_TESTS++))
            FAILED_TEST_FILES+=("$test_name")
            echo "${fg[red]}✗ $test_name failed${reset_color}"
        fi
    else
        # zshテストの実行
        if "$test_file"; then
            ((PASSED_TESTS++))
            echo "${fg[green]}✓ $test_name passed${reset_color}"
        else
            ((FAILED_TESTS++))
            FAILED_TEST_FILES+=("$test_name")
            echo "${fg[red]}✗ $test_name failed${reset_color}"
        fi
    fi

    ((TOTAL_TESTS++))
    echo
done

# 最終サマリー
echo "${fg[blue]}========================================${reset_color}"
echo "${fg[blue]}   Integration Test Summary${reset_color}"
echo "${fg[blue]}========================================${reset_color}"
echo "Total test files: $TOTAL_TESTS"
echo "${fg[green]}Passed: $PASSED_TESTS${reset_color}"
echo "${fg[red]}Failed: $FAILED_TESTS${reset_color}"

if (( FAILED_TESTS > 0 )); then
    echo
    echo "${fg[red]}Failed tests:${reset_color}"
    for failed_test in "${FAILED_TEST_FILES[@]}"; do
        echo "  - $failed_test"
    done
    exit 1
else
    echo
    echo "${fg[green]}All integration tests passed!${reset_color}"
    exit 0
fi