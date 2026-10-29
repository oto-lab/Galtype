<p align="center">
  <img src="docs/images/galtype-logo.svg" alt="Galtype" width="520"><br>
  <sub>Meltype を元にした、galjp 対応のギャル文字入力。</sub>
</p>

<p align="center">
  <a href="https://github.com/oto-lab/Galtype"><img src="https://img.shields.io/badge/fork-Meltype-ff6f9f" alt="Meltype fork"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-7a96f0" alt="GPL-3.0-or-later"></a>
  <a href="https://github.com/otnc/galjp"><img src="https://img.shields.io/badge/galjp-5.0.0-3aaee8" alt="galjp 5.0.0"></a>
</p>

<p align="center"><b>ローマ字で打つ。入力中から、ギャル文字になる。</b></p>

<p align="center">
  <img src="docs/images/galtype-demo.svg" alt="kyouhagakkou と入力すると、⊇ょぅ￡學木交になる" width="760">
</p>

## Galtype とは

Galtype は、[yksr-melt/Meltype](https://github.com/yksr-melt/Meltype) を元にした fork です。Meltype の日本語・英語自動判定、ライブ変換、候補選択、学習、コード入力への配慮を残し、出力に [otnc/galjp](https://github.com/otnc/galjp) のギャル文字変換を重ねます。

```text
kyouhagakkou
    → 今日は学校
    → ⊇ょぅ￡學木交
```

Galjp の設定は変更できます。入力中の表示と確定結果には同じ設定を使うため、表示だけギャル文字になって確定時に戻ることはありません。

## できること

- 日本語と英語を自動判定する Meltype の入力方式
- 入力中からのギャル文字変換
- 英字・数字・ひらがな・カタカナ・漢字・記号のレイヤー別設定
- `horizontal` / `balanced` / `aggressive` の漢字分割方針
- 旧字体、単体漢字の装飾、最大分解深度、シードの変更
- URL と絵文字の保護
- リテラル辞書置換
- Windows / macOS / Linux の入力経路

Galtype の変換を OFF にすると、Meltype に近い通常の出力で入力できます。

## 本家 Meltype との共存

Galtype は本家 Meltype と別のソフトとして配布します。設定・ログ・学習データ・入力方式登録・インストール先・更新先を共有しない方針です。両方を同じ PC に入れて使えることをリリース条件にします。

## インストール

Windows / macOS / Linux の配布境界は Meltype と分離して整備中です。開発版を試す場合は、[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) を確認してください。

初回起動時は Galmoji が ON です。設定画面から OFF に戻せます。

Galjp の変換器は常駐プロセスとして起動します。Windows の配布物には `galjp-runtime` と必要な npm パッケージを同梱します。開発版では Node.js 18 以降が必要です。Node.js または Galjp が利用できない場合も入力自体は止めず、理由をログに残して Galmoji 部分だけを無効にします。

## ライセンスと権利表記

Galtype の Meltype 由来部分は GPL-3.0-or-later で、原著作物は [yksr-melt/Meltype](https://github.com/yksr-melt/Meltype) です。Galtype 側で新しく作るコードの著作権者は `otoneko.` です。

Galjp は ISC License で、著作権者は otoneko. です。Galjp が利用する KanjiVG と Unicode Character Database の通知を含め、詳しくは [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) を参照してください。

## 方針書

実装・配布・本家との共存に関する方針は [docs/GALTYPE-PLAN.md](docs/GALTYPE-PLAN.md) にまとめています。
