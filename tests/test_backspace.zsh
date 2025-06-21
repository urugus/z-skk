#!/usr/bin/env zsh

# テストユーティリティの読み込み
source "${0:A:h}/test_utils.zsh"

# プラグイン本体の読み込み
Z_SKK_DIR="${0:A:h:h}"
source "$Z_SKK_DIR/z-skk.plugin.zsh"

test_backspace_in_conversion_mode() {
    print_section "変換モード中のバックスペース処理"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="にほん"
    Z_SKK_ROMAJI_BUFFER="nihon"
    Z_SKK_CONVERSION_START_POS=0
    LBUFFER="▽にほん"
    RBUFFER=""
    CURSOR=7  # "▽にほん" の末尾

    # バックスペース処理を実行
    z-skk-backspace

    # 検証: バッファが正しく更新されること
    assert_equals "変換バッファが更新される" "にほ" "$Z_SKK_BUFFER"
    assert_equals "ローマ字バッファが更新される" "niho" "$Z_SKK_ROMAJI_BUFFER"
    assert_equals "表示バッファが更新される" "▽にほ" "$LBUFFER"
    assert_equals "変換モードは維持される" "1" "$Z_SKK_CONVERTING"
}

test_backspace_at_conversion_start() {
    print_section "変換開始位置でのバックスペース"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="あ"
    Z_SKK_ROMAJI_BUFFER="a"
    Z_SKK_CONVERSION_START_POS=0
    LBUFFER="▽あ"
    RBUFFER=""
    CURSOR=3

    # バックスペース処理を実行
    z-skk-backspace

    # 検証: 変換モードが解除されること
    assert_equals "変換バッファがクリアされる" "" "$Z_SKK_BUFFER"
    assert_equals "ローマ字バッファがクリアされる" "" "$Z_SKK_ROMAJI_BUFFER"
    assert_equals "表示バッファが空になる" "" "$LBUFFER"
    assert_equals "変換モードが解除される" "0" "$Z_SKK_CONVERTING"
}

test_backspace_in_normal_mode() {
    print_section "通常モードでのバックスペース"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=0
    Z_SKK_BUFFER=""
    Z_SKK_ROMAJI_BUFFER=""
    LBUFFER="あいうえお"
    RBUFFER=""
    CURSOR=15  # "あいうえお" の末尾（3バイト×5文字）

    # ZLE関数のモック
    backward-delete-char() {
        LBUFFER="あいうえ"
    }
    zle() {
        if [[ "$1" == "backward-delete-char" ]]; then
            backward-delete-char
        fi
    }

    # バックスペース処理を実行
    z-skk-backspace

    # 検証: 通常のバックスペース動作
    assert_equals "通常のバックスペース動作" "あいうえ" "$LBUFFER"
    assert_equals "変換モードは維持される" "0" "$Z_SKK_CONVERTING"
}

test_backspace_with_okurigana() {
    print_section "送り仮名付き変換モードでのバックスペース"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="おく"
    Z_SKK_ROMAJI_BUFFER="oku"
    Z_SKK_OKURIGANA="り"
    Z_SKK_CONVERSION_START_POS=0
    LBUFFER="▽おく*り"
    RBUFFER=""
    CURSOR=10

    # バックスペース処理を実行（送り仮名の削除）
    z-skk-backspace

    # 検証: 送り仮名が削除されること
    assert_equals "変換バッファは維持される" "おく" "$Z_SKK_BUFFER"
    assert_equals "送り仮名がクリアされる" "" "$Z_SKK_OKURIGANA"
    assert_equals "表示から送り仮名が削除される" "▽おく" "$LBUFFER"
}

test_backspace_in_candidate_selection() {
    print_section "候補選択モードでのバックスペース"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=2
    Z_SKK_BUFFER="かんじ"
    Z_SKK_ROMAJI_BUFFER="kanji"
    Z_SKK_CANDIDATES=("漢字" "感じ" "幹事")
    Z_SKK_CANDIDATE_INDEX=0
    Z_SKK_CONVERSION_START_POS=0
    LBUFFER="▼漢字"
    RBUFFER=""
    CURSOR=7

    # バックスペース処理を実行
    z-skk-backspace

    # 検証: 候補選択モードから変換モードに戻ること
    assert_equals "変換モードに戻る" "1" "$Z_SKK_CONVERTING"
    assert_equals "変換前の状態に戻る" "▽かんじ" "$LBUFFER"
    assert_equals "候補インデックスがリセットされる" "0" "$Z_SKK_CANDIDATE_INDEX"
}

test_backspace_with_prefix() {
    print_section "プレフィックス付きバックスペース"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="にほん"
    Z_SKK_ROMAJI_BUFFER="nihon"
    # "こんにちは" = 5文字 = 5文字分のバイト位置
    Z_SKK_CONVERSION_START_POS=5
    LBUFFER="こんにちは▽にほん"
    RBUFFER=""
    CURSOR=9  # LBUFFER全体の長さ

    # バックスペース処理を実行
    z-skk-backspace

    # 検証: プレフィックスは保持されること
    assert_equals "変換バッファが更新される" "にほ" "$Z_SKK_BUFFER"
    assert_equals "プレフィックスは保持される" "こんにちは▽にほ" "$LBUFFER"
}

test_backspace_romaji_buffer_sync() {
    print_section "ローマ字バッファの同期"

    # 環境の初期化
    Z_SKK_MODE="hiragana"
    Z_SKK_CONVERTING=1
    Z_SKK_BUFFER="きょう"
    Z_SKK_ROMAJI_BUFFER="kyou"
    Z_SKK_CONVERSION_START_POS=0
    LBUFFER="▽きょう"
    RBUFFER=""
    CURSOR=11

    # バックスペース処理を実行
    z-skk-backspace

    # 検証: "きょう" → "きょ" の場合、"kyou" → "kyo" になること
    assert_equals "変換バッファが更新される" "きょ" "$Z_SKK_BUFFER"
    assert_equals "ローマ字バッファが正しく更新される" "kyo" "$Z_SKK_ROMAJI_BUFFER"
}

# テストの実行
print_header "Backspace Function Tests"

test_backspace_in_conversion_mode
test_backspace_at_conversion_start
test_backspace_in_normal_mode
test_backspace_with_okurigana
test_backspace_in_candidate_selection
test_backspace_with_prefix
test_backspace_romaji_buffer_sync

# テスト結果のサマリー表示
print_test_summary