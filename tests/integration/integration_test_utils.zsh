#!/usr/bin/env zsh
# 統合テスト用のユーティリティ関数

# zptyモジュールを読み込み
zmodload zsh/zpty || {
    echo "Error: zsh/zpty module not available. Integration tests cannot run."
    exit 1
}

# グローバル変数
typeset -g ZPTY_SESSION="skk-test-$$"
typeset -g INTEGRATION_TEST_DIR="${0:A:h}"
typeset -g PROJECT_ROOT="${INTEGRATION_TEST_DIR:h:h}"
typeset -g INTEGRATION_TEST_COUNT=0
typeset -g INTEGRATION_TEST_PASSED=0
typeset -g INTEGRATION_TEST_FAILED=0
typeset -g INTEGRATION_TEST_TIMEOUT=5  # デフォルトタイムアウト（秒）

# テストセッションを開始
start_test_session() {
    local session_name="${1:-$ZPTY_SESSION}"

    # 既存のセッションがあれば削除
    zpty -d "$session_name" 2>/dev/null

    # 新しいセッションを開始
    zpty -b "$session_name" zsh -f || {
        echo "Error: Failed to start zpty session"
        return 1
    }

    # 初期化を待つ
    sleep 0.2

    # 初期出力をクリア
    zpty -r "$session_name" line 2>/dev/null

    # 基本設定
    zpty -w "$session_name" "setopt NO_BEEP"
    zpty -w "$session_name" "PS1='$ '"
    zpty -w "$session_name" "unsetopt zle"  # 一旦ZLEを無効化

    # z-skkプラグインを読み込み
    zpty -w "$session_name" "source '$PROJECT_ROOT/z-skk.plugin.zsh'"

    # ZLEを有効化
    zpty -w "$session_name" "setopt zle"

    # プラグイン読み込みを待つ
    sleep 0.3

    # 初期プロンプトまで読み飛ばし
    local dummy
    while zpty -r "$session_name" dummy 2>/dev/null && [[ -n "$dummy" ]]; do
        sleep 0.05
    done

    return 0
}

# テストセッションを終了
end_test_session() {
    local session_name="${1:-$ZPTY_SESSION}"
    zpty -d "$session_name" 2>/dev/null
}

# キー入力を送信
send_keys() {
    local keys="$1"
    local session_name="${2:-$ZPTY_SESSION}"

    # 特殊キーの変換
    keys="${keys//C-j/$'\x0a'}"
    keys="${keys//C-g/$'\x07'}"
    keys="${keys//C-q/$'\x11'}"
    keys="${keys//Enter/$'\r'}"
    keys="${keys//Space/ }"
    keys="${keys//Tab/$'\t'}"

    zpty -w "$session_name" "$keys" || {
        echo "Error: Failed to send keys to session"
        return 1
    }
}

# 出力を取得（タイムアウト付き）
get_output() {
    local session_name="${1:-$ZPTY_SESSION}"
    local timeout="${2:-$INTEGRATION_TEST_TIMEOUT}"
    local output=""
    local line

    # タイムアウトを設定してループで読み取り
    local start_time=$SECONDS
    while (( SECONDS - start_time < timeout )); do
        if zpty -r "$session_name" line 2>/dev/null; then
            output+="$line"
        else
            # データがない場合は少し待つ
            sleep 0.05
        fi

        # プロンプトが表示されたら終了
        if [[ "$output" == *"$ "* ]]; then
            break
        fi
    done

    echo "$output"
}

# バッファ内容を取得（クリーンな状態で）
get_buffer_content() {
    local session_name="${1:-$ZPTY_SESSION}"

    # Ctrl+U で行をクリア
    send_keys $'\x15' "$session_name"
    sleep 0.05

    # テスト用の特殊コマンドで現在のバッファを出力
    send_keys "echo \"BUFFER:[\$BUFFER]\"" "$session_name"
    send_keys "Enter" "$session_name"

    local output=$(get_output "$session_name")

    # BUFFER:[...]の部分を抽出
    if [[ "$output" =~ "BUFFER:\[([^\]]*)\]" ]]; then
        echo "${match[1]}"
    else
        echo ""
    fi
}

# 現在の行の内容を取得
get_current_line() {
    local session_name="${1:-$ZPTY_SESSION}"

    # エコーバックから現在の行を推測
    local output=$(get_output "$session_name" 1)

    # 最後の$ の後の内容を取得
    local lines=("${(@f)output}")
    local last_line="${lines[-1]}"

    if [[ "$last_line" == "$ "* ]]; then
        echo "${last_line#\$ }"
    else
        echo "$last_line"
    fi
}

# アサーション関数
assert_output_contains() {
    local expected="$1"
    local output="$2"
    local test_name="${3:-Output assertion}"

    ((INTEGRATION_TEST_COUNT++))

    if [[ "$output" == *"$expected"* ]]; then
        ((INTEGRATION_TEST_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((INTEGRATION_TEST_FAILED++))
        echo "  ✗ $test_name"
        echo "    Expected to contain: $expected"
        echo "    Actual output: $output"
        return 1
    fi
}

assert_buffer_equals() {
    local expected="$1"
    local session_name="${2:-$ZPTY_SESSION}"
    local test_name="${3:-Buffer assertion}"

    local actual=$(get_buffer_content "$session_name")

    ((INTEGRATION_TEST_COUNT++))

    if [[ "$actual" == "$expected" ]]; then
        ((INTEGRATION_TEST_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((INTEGRATION_TEST_FAILED++))
        echo "  ✗ $test_name"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        return 1
    fi
}

assert_line_contains() {
    local expected="$1"
    local session_name="${2:-$ZPTY_SESSION}"
    local test_name="${3:-Line assertion}"

    local actual=$(get_current_line "$session_name")

    ((INTEGRATION_TEST_COUNT++))

    if [[ "$actual" == *"$expected"* ]]; then
        ((INTEGRATION_TEST_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((INTEGRATION_TEST_FAILED++))
        echo "  ✗ $test_name"
        echo "    Expected line to contain: $expected"
        echo "    Actual line: $actual"
        return 1
    fi
}

# 統合テストのサマリーを表示
print_integration_test_summary() {
    echo
    echo "Integration Test Summary:"
    echo "  Total: $INTEGRATION_TEST_COUNT"
    echo "  Passed: $INTEGRATION_TEST_PASSED"
    echo "  Failed: $INTEGRATION_TEST_FAILED"

    if (( INTEGRATION_TEST_FAILED > 0 )); then
        return 1
    else
        return 0
    fi
}

# テストの初期化
reset_integration_test_counters() {
    INTEGRATION_TEST_COUNT=0
    INTEGRATION_TEST_PASSED=0
    INTEGRATION_TEST_FAILED=0
}

# クリーンアップ用のトラップを設定
trap 'end_test_session' EXIT INT TERM