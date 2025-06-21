#!/usr/bin/env zsh
# 改善された統合テストユーティリティ

# テスト用の環境を設定
setup_test_environment() {
    # 必要な環境変数を設定
    export Z_SKK_TEST_MODE=1
    export Z_SKK_USE_CACHE=0

    # プロジェクトルートを取得
    local script_path="${(%):-%x}"
    if [[ -z "$script_path" ]]; then
        script_path="$0"
    fi
    export PROJECT_ROOT="${script_path:A:h:h:h}"

    # z-skkを読み込む
    source "$PROJECT_ROOT/z-skk.plugin.zsh"
}

# 単体テストスタイルで統合テストを実行
test_basic_conversion() {
    setup_test_environment

    echo "=== Testing Basic Conversion ==="

    # かなモードに設定
    z-skk-set-mode hiragana

    # 直接関数を呼び出してテスト
    Z_SKK_ROMAJI_BUFFER="nihongo"
    z-skk-convert-romaji

    if [[ "$Z_SKK_BUFFER" == "にほんご" ]]; then
        echo "✓ Basic conversion works"
        return 0
    else
        echo "✗ Basic conversion failed"
        echo "  Expected: にほんご"
        echo "  Actual: $Z_SKK_BUFFER"
        return 1
    fi
}

# キーバインディングのシミュレーション
simulate_key_input() {
    local input="$1"

    # キー入力を文字ごとに処理
    for (( i=1; i<=${#input}; i++ )); do
        local char="${input:$((i-1)):1}"

        # 大文字の場合は変換開始
        if [[ "$char" =~ [A-Z] ]]; then
            z-skk-start-conversion
            char="${char:l}"  # 小文字に変換
        fi

        # 入力処理
        z-skk-handle-input "$char"
    done
}

# モード切り替えのテスト
test_mode_switching() {
    setup_test_environment

    echo "=== Testing Mode Switching ==="

    # ASCIIモードから開始
    z-skk-set-mode ascii
    [[ "$Z_SKK_MODE" == "ascii" ]] && echo "✓ Initial ASCII mode" || echo "✗ Initial ASCII mode failed"

    # かなモードへ切り替え
    z-skk-toggle-kana
    [[ "$Z_SKK_MODE" == "hiragana" ]] && echo "✓ Switch to hiragana" || echo "✗ Switch to hiragana failed"

    # カタカナモードへ切り替え
    z-skk-toggle-katakana-mode
    [[ "$Z_SKK_MODE" == "katakana" ]] && echo "✓ Switch to katakana" || echo "✗ Switch to katakana failed"

    return 0
}

# 変換フローのテスト
test_conversion_flow() {
    setup_test_environment

    echo "=== Testing Conversion Flow ==="

    # かなモードに設定
    z-skk-set-mode hiragana

    # 変換開始
    z-skk-start-conversion
    [[ "$Z_SKK_CONVERTING" -eq 1 ]] && echo "✓ Conversion started" || echo "✗ Conversion start failed"

    # 入力シミュレーション
    simulate_key_input "kanji"
    [[ "$Z_SKK_BUFFER" == "かんじ" ]] && echo "✓ Input converted to kana" || echo "✗ Kana conversion failed"

    # スペースで変換
    z-skk-handle-space
    [[ "$Z_SKK_CONVERTING" -eq 2 ]] && echo "✓ Candidate selection mode" || echo "✗ Candidate selection failed"

    # 変換確定
    z-skk-confirm-candidate
    [[ "$Z_SKK_CONVERTING" -eq 0 ]] && echo "✓ Conversion confirmed" || echo "✗ Confirmation failed"

    return 0
}

# メイン実行部分
if [[ "${0:A}" == "${(%):-%x}" ]] || [[ -z "${(%):-%x}" ]]; then
    # このファイルが直接実行された場合
    echo "Running improved integration tests..."
    echo
    test_basic_conversion
    echo
    test_mode_switching
    echo
    test_conversion_flow
fi