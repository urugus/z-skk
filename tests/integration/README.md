# z-skk 統合テスト

このディレクトリには、z-skkプラグインの統合テストが含まれています。

## テストの種類

### 1. zptyベースのテスト（`test_*.zsh`）
- zshの`zpty`モジュールを使用して擬似端末でテストを実行
- 実際のキー入力をシミュレート
- CI環境では動作が不安定な場合がある

### 2. expectベースのテスト（`*.exp`）
- expectコマンドを使用したインタラクティブテスト
- より現実的な端末環境でのテスト
- expectがインストールされている環境でのみ動作

### 3. シンプルテスト（`simple_*.zsh`）
- 直接関数を呼び出すシンプルなテスト
- CI環境でも安定して動作

## テストの実行

### すべての統合テストを実行
```bash
zsh tests/integration/run_integration_tests.zsh
```

### 個別のテストを実行
```bash
# zptyテスト
zsh tests/integration/test_basic_input.zsh

# expectテスト（expectが必要）
expect tests/integration/test_with_expect.exp

# シンプルテスト
zsh tests/integration/simple_integration_test.zsh
```

## CI環境での実行

GitHub ActionsのCI環境では、以下の制限があります：

1. **インタラクティブな端末環境がない**
   - zptyテストは擬似端末の制限により不安定
   - expectテストは環境によっては動作しない

2. **推奨事項**
   - CI環境では主にユニットテスト（`tests/test_*.zsh`）を使用
   - 統合テストは開発環境でのローカルテストとして活用

## トラブルシューティング

### zptyテストが失敗する場合
- `zmodload zsh/zpty`が利用可能か確認
- プロンプトやZLE設定が影響している可能性

### expectテストが動作しない場合
- `expect`コマンドがインストールされているか確認
- macOS: `brew install expect`
- Ubuntu: `sudo apt-get install expect`

### テストの安定性を向上させるには
- タイムアウト値を調整（`INTEGRATION_TEST_TIMEOUT`）
- `sleep`の時間を調整
- より単純なテストケースから始める