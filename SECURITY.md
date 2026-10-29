# セキュリティ

Galtype はキー入力を扱うソフトです。変換とギャル文字への変換は端末内で行い、Galjp の処理にも外部の変換サービスを使いません。設定、学習データ、必要に応じて有効にした診断ログを Galtype 専用の保存先に置きます。

更新確認など、Meltype から引き継いだ通信機能は設定に応じて動作します。ログや不具合報告には入力した文字が含まれることがあるので、送る前に内容を確認してください。

## 脆弱性の報告

悪用できる問題は、[Galtype の非公開報告窓口](https://github.com/oto-lab/Galtype/security/advisories/new) へ送ってください。窓口を使えないときも、再現に秘密情報や未修正の攻撃手順が必要な問題を公開 Issue に書かないでください。本家 Meltype の作者のメールアドレスは Galtype の連絡先ではありません。

起きること、再現手順、Galtype の版、OS、考えられる影響を添えてください。修正対象は最新の Galtype です。

## 配布と権限

配布元は [oto-lab/Galtype の Releases](https://github.com/oto-lab/Galtype/releases) です。Node.js と Galjp は配布物に同梱します。秘密の署名鍵やトークンは同梱しません。

Windows の IME 登録には管理者権限が必要です。Galtype のファイルと登録先を使い、本家 Meltype の設定や IME を変更しません。署名や macOS の公証は、リポジトリに必要な秘密を設定したときだけ行います。

Windows 配布物は公開前に Defender で検査します。検査で検出された場合や検査できない場合は、配布物の公開を止めます。
