# Galtype のリリース

## v0.1.0 の対象

初回リリースは Windows のみです。macOS / Linux の実装は将来用に残しますが、ビルド、動作確認、パッケージの公開は今回の対象にしません。

版番号は `src/Meltype/Meltype.csproj` と `src/Meltype.Core/Meltype.Core.csproj` でそろえます。ソースのプロジェクト名と C ABI の `meltype_*` は内部名として維持します。

`docs/release-notes/0.1.0.md` は Windows アプリ内で表示するリリースノートでもあります。

## 公開前の確認

PR の Windows build、インストーラー、quality、pr-checks、CodeQL を確認します。共通コアのテストは Windows テストに含まれます。

- Node.js を PATH から外しても、同梱した `node.exe` でギャル文字へ変換できる。
- `gakkou` の入力中と Enter で確定した文字が一致する。
- ギャル文字変換を OFF にすると通常の日本語を入力できる。
- Meltype と Galtype を同じ PC に入れ、一方の更新とアンインストールで他方のプロセス、設定、IME 登録が変わらない。
- 通常版、ポータブル版、インストーラーに Node.js、Galjp、依存パッケージ、ライセンス通知が入っている。

実際の入力欄での操作や共存をまだ確かめていない項目は、確認済みとして扱わないでください。

## 配布物を作る

Actions の build を対象ブランチで手動実行すると、Mozc をビルドしたあとに次の成果物を作ります。タグや公開済みリリースは不要です。

- `Galtype-<version>-windows.zip`
- `Galtype-<version>-windows-portable.zip`
- `Galtype-<version>-setup.exe`

手動ビルドは日時を含むテスト版の名前になります。Windows の配布物は Defender 検査に通ってからアップロードします。署名鍵がなければコード署名は行いません。

レビュー後に main へ取り込み、公開するコミットへ `v0.1.0` タグを付けると、同じ workflow がリリースへ配布物を添付します。マージ、タグ作成、リリース公開は別途判断してください。

## パッケージマネージャー

Scoop / winget の定義は `tools/make-manifests.mjs` で、公開する Windows 配布物の SHA-256 を使って生成します。本家の配布物やハッシュは使いません。winget の識別子は `otolab.Galtype` です。初回登録が完了するまでは `WINGET_TOKEN` を設定しません。
