#!/usr/bin/env zsh

# バックスペース問題の手動テスト

print "=== Backspace Issue Test ==="
print "Testing backspace behavior in conversion mode"
print ""

# プラグインの読み込み
Z_SKK_DIR="${0:A:h:h:h}"
source "$Z_SKK_DIR/z-skk.plugin.zsh"

# デバッグモードを有効化
export Z_SKK_DEBUG=1

# テストケース関数
test_backspace_scenario() {
    print "\n--- Test Scenario: Backspace in conversion mode with prefix ---"

    # 初期状態の設定
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="にほん"
    Z_SKK_ROMAJI_BUFFER="nihon"
    Z_SKK_CONVERSION_START_POS=15
    LBUFFER="こんにちは▽にほん"
    RBUFFER=""
    CURSOR=28

    print "Initial state:"
    print "  LBUFFER='$LBUFFER' (length: ${#LBUFFER})"
    print "  Z_SKK_BUFFER='$Z_SKK_BUFFER'"
    print "  Z_SKK_CONVERSION_START_POS=$Z_SKK_CONVERSION_START_POS"
    print "  Prefix part: '${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}' (length: ${#${LBUFFER:0:$Z_SKK_CONVERSION_START_POS}})"

    print "\nCalling z-skk-backspace..."
    z-skk-backspace

    print "\nAfter backspace:"
    print "  LBUFFER='$LBUFFER' (length: ${#LBUFFER})"
    print "  Z_SKK_BUFFER='$Z_SKK_BUFFER'"
    print "  Expected LBUFFER: 'こんにちは▽にほ'"

    # 追加の診断情報
    local expected="こんにちは▽にほ"
    if [[ "$LBUFFER" != "$expected" ]]; then
        print "\nError: LBUFFER mismatch!"
        print "  Expected length: ${#expected}"
        print "  Actual length: ${#LBUFFER}"

        # 文字ごとに比較
        print "\nCharacter-by-character comparison:"
        local i
        for (( i=1; i<=${#LBUFFER} || i<=${#expected}; i++ )); do
            local actual_char="${LBUFFER:$((i-1)):1}"
            local expected_char="${expected:$((i-1)):1}"
            if [[ "$actual_char" != "$expected_char" ]]; then
                print "  Position $i: actual='$actual_char' expected='$expected_char'"
            fi
        done
    else
        print "\n✓ Test passed!"
    fi
}

# シンプルなケースのテスト
test_simple_backspace() {
    print "\n--- Test Scenario: Simple backspace without prefix ---"

    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="にほん"
    Z_SKK_ROMAJI_BUFFER="nihon"
    Z_SKK_CONVERSION_START_POS=0
    LBUFFER="▽にほん"
    RBUFFER=""
    CURSOR=10

    print "Initial state:"
    print "  LBUFFER='$LBUFFER'"
    print "  Z_SKK_BUFFER='$Z_SKK_BUFFER'"

    z-skk-backspace

    print "\nAfter backspace:"
    print "  LBUFFER='$LBUFFER'"
    print "  Z_SKK_BUFFER='$Z_SKK_BUFFER'"
    print "  Expected LBUFFER: '▽にほ'"

    if [[ "$LBUFFER" == "▽にほ" ]]; then
        print "\n✓ Test passed!"
    else
        print "\n✗ Test failed!"
    fi
}

# テスト実行
test_simple_backspace
test_backspace_scenario

print "\n=== Test Complete ===\n"