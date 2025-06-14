#!/usr/bin/env zsh
# モード切り替えの統合テスト

source "${0:A:h}/integration_test_utils.zsh"

echo "=== Mode Switching Integration Test ==="

# テストカウンターをリセット
reset_integration_test_counters

# テストセッションを開始
echo "Starting test session..."
start_test_session || {
    echo "Failed to start test session"
    exit 1
}

echo
echo "Test 1: Default mode is ASCII"
send_keys "default mode"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "default mode" "$output" "Default ASCII mode"

echo
echo "Test 2: Switch to Hiragana mode (C-j)"
send_keys "C-j"
send_keys "hiragana"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "ひらがな" "$output" "Hiragana mode after C-j"

echo
echo "Test 3: Switch to Katakana mode (q in Hiragana mode)"
send_keys "C-j"
send_keys "q"
send_keys "katakana"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "カタカナ" "$output" "Katakana mode after q"

echo
echo "Test 4: Switch to ASCII mode (l in Hiragana mode)"
send_keys "C-j"
send_keys "l"
send_keys "ascii"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "ascii" "$output" "ASCII mode after l"

echo
echo "Test 5: Switch to Zenkaku mode (C-q)"
send_keys "C-q"
send_keys "ABC123"
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "ＡＢＣ１２３" "$output" "Zenkaku mode input"

echo
echo "Test 6: Complex mode switching sequence"
# ASCII -> Hiragana -> ASCII -> Katakana -> ASCII
send_keys "start"
send_keys "Space"
send_keys "C-j"
send_keys "naka"
send_keys "Space"
send_keys "l"
send_keys "middle"
send_keys "Space"
send_keys "C-j"
send_keys "q"
send_keys "owari"
send_keys "Space"
send_keys "l"
send_keys "end"
send_keys "Enter"
sleep 0.3
output=$(get_output)
assert_output_contains "start なか middle オワリ end" "$output" "Complex mode switching"

echo
echo "Test 7: Mode persistence across multiple inputs"
send_keys "C-j"
send_keys "ichi"
send_keys "Enter"
sleep 0.1
send_keys "ni"
send_keys "Enter"
sleep 0.1
send_keys "san"
send_keys "Enter"
sleep 0.3
output=$(get_output)
assert_output_contains "いち" "$output" "First hiragana input"
assert_output_contains "に" "$output" "Second hiragana input"
assert_output_contains "さん" "$output" "Third hiragana input"

echo
echo "Test 8: Abbrev mode (/ in Hiragana mode)"
send_keys "C-j"
send_keys "/"
send_keys "skk"
send_keys "Space"
sleep 0.2
# Abbrevモードでは変換候補がない場合そのまま
send_keys "Enter"
sleep 0.2
output=$(get_output)
assert_output_contains "skk" "$output" "Abbrev mode input"

# テストセッションを終了
end_test_session

# サマリーを表示
print_integration_test_summary