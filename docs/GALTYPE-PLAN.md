# Galtype 作業方針

v0.1.0 は Windows のみをリリース対象にする。macOS / Linux の記述は将来の対応方針として残し、今回の CI と配布には含めない。

## 目的

このリポジトリを Meltype の fork **Galtype** として整え、Meltype の入力判定・変換・候補・学習・各 OS 対応を活かしながら、`galjp` のギャル文字変換を入力中から適用する。

Galtype 側で新しく作るソースファイルの著作権者は `otoneko.` とする。Meltype から引き継いだ部分の権利表記は変更せず、`yksr-melt/Meltype` を原著作物として明記する。

Galtype はジョークソフトとして見せるが、入力エンジンとしての品質は Meltype の設計を引き継ぐ。通常の日本語入力を先に作り、その表示と確定結果に同じ Galjp 変換を適用する。

## 守ること

### Meltype に迷惑をかけない

- 本家 Meltype のリポジトリ、リリース、更新先を変更しない。
- 本家のプロセス、設定、学習データ、ログ、入力ソース、IME 登録を停止・削除・上書きしない。
- Galtype と Meltype を同じ PC にインストールし、同時に起動できるようにする。
- Galtype のインストーラーとアンインストーラーは Galtype のファイルだけを扱う。
- README や配布物では本家と公式版を混同させない。

### ライセンスを維持する

- Meltype から引き継いだ GPL-3.0-or-later、著作権表示、第三者通知を削除しない。
- `yksr-melt/Meltype` が原著作物であることと、Galtype が fork であることを README と About 表示に明記する。
- `galjp` の ISC License と著作権表示を追加する。
- `galjp` が利用する KanjiVG と Unicode Character Database の通知も追加する。
- 既存の Mozc、azooKey、辞書などの通知を維持する。

## 機能方針

### Meltype の機能を残す

- 日本語・英語の自動判定
- ローマ字入力・かな入力
- ライブ変換
- 文節分割と候補選択
- 学習・ユーザー辞書
- コード、URL、コマンド、絵文字などへの配慮
- Windows、macOS、Linux の入力方式

### Galjp を入力中から適用する

内部状態は変換前の Meltype の文字列として持ち、表示用と確定用に Galjp 変換を行う。

```text
入力キー       kyouhagakkou
Meltype の結果 今日は学校
表示            ⊇ょぅ￡學木交
確定            ⊇ょぅ￡學木交
```

Galjp の変換済み文字列を次の入力の内部状態には戻さない。これにより、バックスペース、候補変更、再変換、設定変更で二重変換が起きないようにする。

表示と確定は同じ共通コアの変換器を使う。Windows、macOS、Linux の各フロントエンドで個別に変換しない。

### Galjp の設定を変更できるようにする

Galtype の設定画面から、`galjp` の利用可能な設定を変更できるようにする。

- 変換全体の ON / OFF
- `latin`、`digit`、`hiragana`、`katakana`、`kanji`、`symbol` の有効・無効
- `horizontal`、`balanced`、`aggressive` の分割方針
- 旧字体変換
- 単体漢字の装飾
- 最大分解深度
- 候補選択用シード
- URL と絵文字の保護
- リテラル辞書置換

初期値は `galjp` の既定値に合わせる。設定を OFF にした場合は、Galjp の後処理をせず、Meltype 本来の出力に戻す。

## 実装方針

### Galjp の取り込み

`galjp` 5.0.0 は Node.js の常駐サイドカーとして使う。入力ごとにプロセスを起動せず、JSON Lines で変換を依頼する。アプリの配布物には `index.mjs`、固定した npm ロックファイル、依存パッケージ、ライセンス通知を同梱する。Node.js がない、起動できない、応答がタイムアウトした場合は入力を止めず、警告を記録して Galmoji だけを無効にする。

候補となる構成:

```text
src/Meltype.Core/Composition/GalmojiConverter.cs
src/Meltype.Core/Composition/GalmojiOptions.cs
tools/galjp-runtime/index.mjs
tools/galjp-runtime/package-lock.json
```

生成データはビルド時に外部ネットワークへ接続しなくても再現できるよう、必要な入力データまたは生成済みデータと生成手順をリポジトリで管理する。

### リアルタイム適用の境界

Galjp は次の全経路に同じ順序で適用する。

1. Meltype が入力中の内部結果を作る
2. Galjp 変換器が表示用文字列を作る
3. 候補表示・未確定表示を更新する
4. Enter、Space、候補選択、フォーカス移動などの確定時に同じ変換器を使う

保護されるテキスト、結合文字、補助面文字、外部アプリへそのまま渡すキーは、既存の Meltype の境界を優先する。

### 設定

既存の共通設定モデルに Galtype の設定を追加し、Windows の設定画面に表示する。macOS と Linux は同じ設定ファイル形式を使用する。

設定変更時に未確定文字列がある場合は、旧設定で意図せず再変換しない。未確定入力を安全に確定してから新設定を適用するか、既存の設定反映規則に合わせて扱う。

## 本家と衝突させない識別子

名称を変えるだけでなく、実行中の識別子と保存場所を分離する。

| 対象 | Galtype の方針 |
| --- | --- |
| Windows 実行ファイル | `Galtype.exe` |
| Windows インストール先 | `%LOCALAPPDATA%\Programs\Galtype` |
| Windows 設定・学習データ | `%LOCALAPPDATA%\Galtype` |
| Windows 環境変数 | `GALTYPE_DATA_DIR` など |
| Windows タスク・ショートカット | `Galtype` 専用 |
| Windows AppId / 登録名 | `Galtype` 専用 |
| macOS アプリ | `Galtype.app` |
| macOS Bundle ID / Input Source ID | Meltype と異なる固有値 |
| macOS データ | `~/Library/Application Support/Galtype` |
| Linux NativeAOT ライブラリ | `libGaltypeNative` |
| Linux インストール先 | `/opt/galtype` |
| Linux IBus / fcitx5 名 | `galtype` |

GUID、mutex、IPC 名、名前付きイベント、ログ名、更新リポジトリも本家と共有しない。

## README と画像

README は Galtype の説明に書き換える。ただし、Meltype の fork であることと原著作権者を明記する。

- タイトル画像、見出し画像、カード画像、デモ画像を Galtype 用に差し替える。
- 画像に埋め込まれた `Meltype`、本家 URL、通常の変換例を残さない。
- `tools/make-readme-art.py` を Galtype の入力・出力例に対応させ、生成物を更新する。
- 画像の生成に使うフォント等のライセンス表示は維持する。
- README のインストール手順は Galtype の配布物と保存先に合わせる。
- 本家 Meltype の URL は「この fork の元」という権利・出典の説明に限って使用する。

## テスト方針

### 共通コア

- `galjp` の README にある代表例
- 全レイヤーの ON / OFF
- 3 種類の分割方針
- 旧字体、単体漢字、最大深度
- シード指定と決定性
- 辞書置換
- URL・絵文字の保護
- 空文字列、結合文字、補助面文字
- 入力中の表示と確定結果の一致
- 二重変換が起きないこと
- Galtype OFF 時の Meltype 出力維持

### OS と配布

- 本家 Meltype と Galtype を同時にインストール・起動できる。
- 一方の終了・更新・アンインストールが他方に影響しない。
- 設定、ログ、学習データ、入力方式登録が分離されている。
- Windows、macOS、Linux の入力経路で共通コアと同じ結果になる。

## 作業順

1. この方針書を基準として、識別子・保存先・更新先の衝突箇所を洗い出す。
2. Galtype の名前、実行ファイル、保存先、OS 登録情報を分離する。
3. `galjp` のバージョン、ライセンス、生成データを固定する。
4. 共通コアへ Galjp 変換器と設定モデルを追加する。
5. Meltype の入力中表示・候補・確定経路へリアルタイム適用する。
6. 設定画面から Galjp の詳細設定を変更できるようにする。
7. README、画像、配布手順、第三者通知を Galtype 用に更新する。
8. 共存テストと各 OS のテストを実行する。

この順序を崩して先に配布物を作らない。特に、本家と衝突する識別子を残したままインストール機能を公開しない。
