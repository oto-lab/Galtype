#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yukishiro
#
# Galtype の Linux 版 (IBus・fcitx5) を組み立てる。できたものは linux/build/Galtype-linux/ に置く。
#   linux/build.sh
# 先に Mozc の変換ヘルパーを native/mozc/build-mozc-helper.sh でビルドしておく (native/mozc/bin/linux/)。
# 必要なもの: .NET 10 SDK、clang (NativeAOT のリンクに使う)、zlib (zlib1g-dev)
# fcitx5 のアドオンは、cmake と fcitx5 の開発用のパッケージ (fcitx5-modules-dev) があればビルドする (無ければ IBus だけ)。
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"
out="$here/build/Galtype-linux"
mozc="$root/native/mozc/bin/linux"

case "$(uname -m)" in
    x86_64) rid=linux-x64 ;;
    aarch64) rid=linux-arm64 ;;
    *) echo "対応していない CPU です: $(uname -m)" >&2; exit 1 ;;
esac
if [[ ! -x "$mozc/meltype_mozc_helper" ]]; then
    echo "Mozc の変換ヘルパーがありません。先に native/mozc/build-mozc-helper.sh を実行してください。" >&2
    exit 1
fi

rm -rf "$here/build"
mkdir -p "$out/mozc"

echo "== 1/3 本体 (C#, NativeAOT) をビルド"
# リポジトリの nuget.config は NuGet を使わない設定 (Windows の開発環境用) なので、NativeAOT のコンパイラを取るために nuget.org を指定する。
dotnet publish "$root/src/Meltype.Mac.Native/Meltype.Mac.Native.csproj" -c Release -r "$rid" \
    -p:PublishAot=true -p:NativeLib=Shared -p:StripSymbols=true \
    --source https://api.nuget.org/v3/index.json -o "$here/build/native"
cp "$here/build/native/GaltypeNative.so" "$out/libGaltypeNative.so"

echo "== 2/3 fcitx5 のアドオン"
if command -v cmake > /dev/null && pkg-config --exists Fcitx5Core 2> /dev/null; then
    cmake -S "$here/fcitx5" -B "$here/build/fcitx5" -DGALTYPE_DIR=/opt/galtype -DCMAKE_BUILD_TYPE=Release > /dev/null
    cmake --build "$here/build/fcitx5" > /dev/null
    mkdir -p "$out/fcitx5"
    cp "$here/build/fcitx5/galtype.so" "$here/fcitx5/galtype-addon.conf" "$here/fcitx5/galtype.conf" "$out/fcitx5/"
else
    echo "fcitx5 の開発用のパッケージ (fcitx5-modules-dev) か cmake が無いので、fcitx5 のアドオンは入れません (IBus だけ)。"
fi

echo "== 3/3 組み立て"
cp "$here/ibus-engine-galtype" "$here/galtype.xml" "$here/icon.png" "$here/install.sh" "$here/uninstall.sh" "$out/"
cp "$here/TESTER-README.txt" "$out/はじめにお読みください.txt"
cp "$root/LICENSE" "$root/THIRD-PARTY-NOTICES.md" "$out/"
cp "$mozc/meltype_mozc_helper" "$mozc/MOZC-LICENSE.txt" "$mozc/MOZC-CREDITS.html" "$out/mozc/"
chmod +x "$out/ibus-engine-galtype" "$out/install.sh" "$out/uninstall.sh" "$out/mozc/meltype_mozc_helper"
runtime="$out/galjp-runtime"
npm --prefix "$root/tools/galjp-runtime" ci --omit=dev
mkdir -p "$runtime"
cp "$root/tools/galjp-runtime/"{index.mjs,package.json,package-lock.json} "$runtime/"
cp -R "$root/tools/galjp-runtime/node_modules" "$runtime/"
node_path="$(node -p 'process.execPath')"
cp "$node_path" "$runtime/node"
cp "$(dirname "$node_path")/../LICENSE" "$runtime/NODE-LICENSE.txt"
chmod +x "$runtime/node"

echo "作成しました: $out"
