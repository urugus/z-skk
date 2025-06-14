#!/usr/bin/env zsh
# 基本的な入力操作の統合テスト

source "${0:A:h}/integration_test_utils.zsh"

echo "=== Basic Input Integration Test ==="

# テストカウンターをリセット
reset_integration_test_counters

# テストセッションを開始
echo "Starting test session..."
start_test_session || {
    echo "Failed to start test session"
    exit 1
}

echo
echo "Test 1: English input (passthrough mode)"
send_keys "hello world"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "hello world" "$output" "English input passthrough"

echo
echo "Test 2: Switch to Hiragana mode and input"
send_keys "C-j"
sleep 0.1
send_keys "nihongo"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "にほんご" "$output" "Hiragana input (nihongo)"

echo
echo "Test 3: Hiragana input with various patterns"
send_keys "C-j"
send_keys "aiueo"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "あいうえお" "$output" "Hiragana vowels"

send_keys "C-j"
send_keys "kakikukeko"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "かきくけこ" "$output" "Hiragana ka-row"

echo
echo "Test 4: Switch back to ASCII mode"
send_keys "C-j"
send_keys "l"
sleep 0.1
send_keys "ascii mode"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "ascii mode" "$output" "ASCII mode after switching"

echo
echo "Test 5: Special romaji patterns"
send_keys "C-j"
send_keys "sshi"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "っし" "$output" "Small tsu (sshi)"

send_keys "C-j"
send_keys "nynyo"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "んにょ" "$output" "N + nya patterns"

echo
echo "Test 6: Mode persistence"
send_keys "C-j"
send_keys "test"
send_keys "Enter"
sleep 0.1
send_keys "mode"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "てすと" "$output" "First word in hiragana mode"
assert_output_contains "もで" "$output" "Second word in same mode"

# テストセッションを終了
end_test_session

# サマリーを表示
print_integration_test_summary