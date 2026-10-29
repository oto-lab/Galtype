# Galtype への貢献

Galtype は Meltype を元にした、ギャル文字を入力するジョークソフトです。不具合や提案は [Galtype の Issue](https://github.com/oto-lab/Galtype/issues) に送ってください。本家 Meltype の窓口へ Galtype 固有の不具合を送らないでください。

## 変更と確認

変更は目的に必要な範囲に絞ってください。判定や変換を変えたときは、報告された入力と近い入力のテストを追加します。

```powershell
npm --prefix tools/galjp-runtime ci --omit=dev
dotnet build Meltype.sln -c Release
dotnet run --project src/Meltype.Core.Tests -c Release
dotnet run --project src/Meltype.Tests -c Release
```

Windows 以外では共通コアのテストを実行してください。辞書の変更時は `node tools/check-dictionaries.mjs` も実行します。詳しくは [開発手順](docs/DEVELOPMENT.md) を参照してください。

Pull Request はテンプレートに沿って、変更の理由と確認結果を日本語で書いてください。確かめる例は `入力 → 期待` の形にします。AI 利用の申告は必須にしません。

## ライセンス

貢献は GPL-3.0-or-later の条件で扱います。Galtype では独自の CLA 同意を求めません。上流から引き継いだ著作権表示と第三者通知は残してください。

新しいソースファイルには SPDX と著作権の行を付けてください。既存ファイルの著作権者を自分の名前に置き換えず、新しく書いた部分の著作権者を記載します。

```text
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 あなたの名前
```

入力した文字や秘密情報を、テスト結果や Issue に含めないようにしてください。
