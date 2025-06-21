#!/usr/bin/env zsh

# バックスペース動作の手動確認スクリプト

print "=== z-skk Backspace Interactive Test ==="
print ""
print "このスクリプトは、z-skkプラグインのバックスペース動作を確認します。"
print ""

# プラグインの読み込み
Z_SKK_DIR="${0:A:h:h:h}"
source "$Z_SKK_DIR/z-skk.plugin.zsh"

print "操作方法:"
print "1. Ctrl+J でかなモードに切り替え"
print "2. 'Nihon' のように大文字で入力開始（変換モード）"
print "3. Backspace で文字を削除してみる"
print "4. 通常モードでもBackspaceが正常に動作することを確認"
print "5. Ctrl+C で終了"
print ""
print "準備ができたらEnterを押してください..."
read

# インタラクティブシェル開始
print ""
print "テスト用シェルを開始します..."
print ""

# 新しいzshセッションを開始
exec zsh