#!/usr/bin/env zsh
# 変換機能の統合テスト

source "${0:A:h}/integration_test_utils.zsh"

echo "=== Conversion Integration Test ==="

# テストカウンターをリセット
reset_integration_test_counters

# テストセッションを開始
echo "Starting test session..."
start_test_session || {
    echo "Failed to start test session"
    exit 1
}

echo
echo "Test 1: Basic conversion (Kanji -> 漢字)"
send_keys "C-j"
send_keys "Kanji"
send_keys "Space"
sleep 0.3
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "漢字" "$output" "Basic kanji conversion"

echo
echo "Test 2: Multiple candidates selection"
send_keys "C-j"
send_keys "Kanji"
send_keys "Space"
sleep 0.2
send_keys "Space"  # 次の候補
sleep 0.2
send_keys "x"      # 前の候補
sleep 0.2
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "漢字" "$output" "Candidate navigation"

echo
echo "Test 3: Conversion cancellation"
send_keys "C-j"
send_keys "Henkan"
send_keys "Space"
sleep 0.2
send_keys "C-g"    # キャンセル
sleep 0.2
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "へんかん" "$output" "Conversion cancelled"

echo
echo "Test 4: Okurigana conversion (OkuRi -> 送り)"
send_keys "C-j"
send_keys "OkuRi"
send_keys "Space"
sleep 0.3
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "送り" "$output" "Okurigana conversion"

echo
echo "Test 5: Mixed input (conversion and non-conversion)"
send_keys "C-j"
send_keys "kore"
send_keys "ha"
send_keys "Nihongo"
send_keys "Space"
sleep 0.2
send_keys "Enter"
send_keys "desu"
send_keys "Enter"
sleep 0.3
output=$(get_output)
assert_output_contains "これは日本語です" "$output" "Mixed conversion input"

echo
echo "Test 6: Unknown word handling"
send_keys "C-j"
send_keys "TestWord"
send_keys "Space"
sleep 0.2
send_keys "C-g"    # 辞書登録をキャンセル
sleep 0.2
output=$(get_output)
# 変換できない単語はひらがなのまま残る
assert_output_contains "てすとわーど" "$output" "Unknown word remains in hiragana"

echo
echo "Test 7: Continuous conversion"
send_keys "C-j"
send_keys "Kyou"
send_keys "Space"
send_keys "Enter"
send_keys "ha"
send_keys "Ii"
send_keys "Space"
send_keys "Enter"
send_keys "Tenki"
send_keys "Space"
send_keys "Enter"
send_keys "desu"
send_keys "Enter"
sleep 0.5
output=$(get_output)
assert_output_contains "今日はいい天気です" "$output" "Continuous conversion"

# テストセッションを終了
end_test_session

# サマリーを表示
print_integration_test_summary