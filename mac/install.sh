#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yukishiro
#
# テスト版の Galtype.app を ~/Library/Input Methods に入れる。zip を展開したフォルダーで実行する:
#   bash install.sh
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -d Galtype.app ]]; then
    echo "Galtype.app が見つかりません。zip を展開したフォルダーで実行してください。" >&2
    exit 1
fi
for helper in install-app.sh start-input-method.sh select-input-source.swift; do
    [[ -f "$helper" ]] || { echo "必要なファイルがありません: ${helper}。zip 全体を展開してください。" >&2; exit 1; }
done

# 入力ソースの「+」の一覧に Galtype が出ない Mac がある (macOS 26、#21)。
# アプリ内の登録処理で、有効な入力ソースを追加し、Galtype の重複だけを整理する。
enable_input_source() {
    "$TARGET/Galtype.app/Contents/MacOS/Galtype" --register-input-source || {
        echo "入力ソースに Galtype を追加できませんでした。ログアウトしてログインし直すと直ります。" >&2
        return 0
    }
    echo "Galtype の入力ソースの登録処理を実行しました"
}

# 入力ソースの登録をやり直す (#134)。Galtype.app を入れ替えるとき、バンドルが無い一瞬に入力ソースの
# 走査が走ると、macOS は登録を消す。消えたあとは、バンドルを戻して走査し直しても戻らないことがあり、
# これまではログアウトするしかなかった。TISRegisterInputSource なら実行中でも戻せる。
register_input_source() {
    local tool="$TARGET/Galtype.app/Contents/MacOS/GaltypeRegisterInputSource"
    # この道具が入っていない Galtype.app (これまでの版) のときは何もしない。
    [[ -x "$tool" ]] || return 0
    "$tool" "$TARGET/Galtype.app" ||
        echo "入力ソースに登録できませんでした。ログアウトしてログインし直すと直ります。" >&2
}

TARGET="$HOME/Library/Input Methods"
bash ./install-app.sh Galtype.app "$TARGET/Galtype.app"
# インターネットから取ってきた印 (隔離属性) を外す。署名が自分用なので、外さないと macOS が起動させない。
xattr -dr com.apple.quarantine "$TARGET/Galtype.app" 2>/dev/null || true

echo "インストールしました: $TARGET/Galtype.app"
enable_input_source
register_input_source
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$TARGET/Galtype.app"
bash ./start-input-method.sh "$TARGET/Galtype.app"
# swift はコマンドライン・デベロッパ・ツールが無い Mac では使えない。選べなくてもインストールは終わっている。
if swift ./select-input-source.swift; then
    echo
    echo "Galtype を起動し、入力ソースとして選択しました。"
else
    echo
    echo "Galtype を起動しました。入力メニューから Galtype を選んでください。"
fi
