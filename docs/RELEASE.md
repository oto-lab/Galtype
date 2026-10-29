# Galtype のリリース

## v1.0.0 の準備

版番号は次のファイルでそろえます。ソースのプロジェクト名と C ABI の `meltype_*` は、内部の互換性のため維持しています。

- `src/Meltype/Meltype.csproj`
- `src/Meltype.Core/Meltype.Core.csproj`
- `mac/Resources/Info.plist`
- `linux/galtype.xml`

`docs/release-notes/1.0.0.md` は Windows アプリ内で表示するリリースノートでもあります。タグを付ける前に本文を確認してください。

## 公開前の確認

Pull Request の build、linux、mac、ime-tests、quality、pr-checks、CodeQL の結果を確認します。手動実行では Windows の通常版とポータブル版、インストーラー、macOS の zip、Linux の zip と deb と rpm を作れます。タグを作る前に、同じコミットの成果物を確認してください。

- Node.js を PATH から外した環境で起動し、ギャル文字へ変換できる。
- `gakkou` を入力して、入力中と Enter で確定した文字が一致する。
- ギャル文字変換を OFF にすると通常の日本語を入力できる。
- Meltype と Galtype を同じ端末に入れ、一方の更新とアンインストールで他方のプロセス、設定、入力方式登録が変わらない。
- 各 OS の配布物に Node.js、Galjp、依存パッケージ、ライセンス通知が入っている。

OS の実入力や共存をまだ確認していない項目は、確認済みとして扱わないでください。

## タグと配布物

レビュー後に main へ取り込み、公開するコミットへ `v1.0.0` タグを付けます。タグの push で Windows、macOS、Linux の workflow が配布物を作り、GitHub Release に添付します。タグの作成とリリース公開は別途、明示的に判断してください。

Windows のパッケージは Node.js の Windows x64 版を、macOS と Linux はビルドした OS と CPU に対応する Node.js を同梱します。ビルドには Node.js と npm が必要ですが、利用者側での追加インストールは不要です。

署名鍵が未設定なら Windows のコード署名、macOS の配布署名と公証は行いません。Linux の apt と dnf リポジトリ公開にも署名鍵と Pages の設定が必要です。秘密を設定せず、CI を通すためだけに検査を外さないでください。

## パッケージマネージャー

`tools/make-manifests.mjs` は Galtype の成果物から Scoop、winget、Homebrew の定義を生成します。公開済みファイルの SHA-256 を使い、存在しない配布物や本家 Meltype のハッシュを使い回しません。

Homebrew の定義は mac workflow の成果物から確認して、初回リリース後に tap へ追加します。winget の識別子は `otolab.Galtype` です。初回の登録が完了するまでは `WINGET_TOKEN` を設定しません。
