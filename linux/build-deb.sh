#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yukishiro
#
# linux/build.sh で組み立てたもの (または Galtype-<版>-linux.zip を展開したフォルダー) から、
# Debian / Ubuntu の .deb パッケージを作る。apt で入れる・更新する・外すためのもの (#863)。
#   linux/build-deb.sh [版] [組み立てたフォルダー] [出力先]
#   例: linux/build-deb.sh 1.2.2-pre.2 linux/build/Galtype-linux linux/build
#   使う人: sudo apt install ./galtype_1.2.2~pre.2_amd64.deb / sudo apt remove galtype
# 中身は install.sh が入れるものと同じ場所に置く:
#   /opt/galtype (本体)、/usr/share/ibus/component/galtype.xml (IBus)、
#   fcitx5 のアドオンがあれば <ライブラリのフォルダー>/fcitx5/galtype.so と /usr/share/fcitx5/{addon,inputmethod}/galtype.conf
# 必要なもの: dpkg-deb (1.19 以降。--root-owner-group を使うので fakeroot は要らない)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
target=/opt/galtype

src="${2:-$here/build/Galtype-linux}"
out="${3:-$here/build}"
# 版: 指定が無ければ galtype.xml の <version> を使う
version="${1:-}"
if [[ -z "$version" ]]; then
    version="$(sed -n 's|.*<version>\(.*\)</version>.*|\1|p' "$src/galtype.xml" | head -n 1)"
fi
version="${version#v}"
# Debian の版の決まり: 1.2.2-pre.2 は 1.2.2 より前なので「~」にする (1.2.2~pre.2 < 1.2.2)。
# 「-」は Debian ではパッケージの改訂の区切りなので、ほかの「-」も「~」にする
debversion="${version//-/\~}"
if [[ ! "$debversion" =~ ^[0-9][A-Za-z0-9.+~]*$ ]]; then
    echo "版の形が正しくありません: $version" >&2
    exit 1
fi

for f in libGaltypeNative.so ibus-engine-galtype galtype.xml icon.png LICENSE THIRD-PARTY-NOTICES.md mozc/galtype_mozc_helper; do
    [[ -e "$src/$f" ]] || { echo "必要なファイルがありません: $src/$f (先に linux/build.sh を実行してください)" >&2; exit 1; }
done
command -v dpkg-deb > /dev/null || { echo "dpkg-deb がありません (Debian / Ubuntu で実行してください)" >&2; exit 1; }

# CPU と、fcitx5 のアドオンの置き場所 (Debian / Ubuntu の multiarch のフォルダー)。
# install.sh は libclassicui.so のあるフォルダーを探すが、Debian / Ubuntu ではここになる
# libGaltypeNative.so (ELF) の e_machine (18 バイト目から 2 バイト) で見る
machine="$(od -An -tx1 -j18 -N2 "$src/libGaltypeNative.so" | tr -d ' \n')"
case "$machine" in
    3e00) arch=amd64; multiarch=x86_64-linux-gnu ;;
    b700) arch=arm64; multiarch=aarch64-linux-gnu ;;
    *) echo "libGaltypeNative.so の CPU が分かりません (e_machine: $machine)" >&2; exit 1 ;;
esac
addondir="${GALTYPE_FCITX5_ADDONDIR:-/usr/lib/$multiarch/fcitx5}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
root="$stage/root"

echo "== 中身を並べる ($root)"
mkdir -p "$root$target" "$root/usr/share/ibus/component" "$root/usr/share/doc/galtype" "$root/DEBIAN"
cp -R "$src/libGaltypeNative.so" "$src/ibus-engine-galtype" "$src/icon.png" "$src/mozc" "$src/LICENSE" "$src/THIRD-PARTY-NOTICES.md" "$root$target/"
chmod 644 "$root$target/libGaltypeNative.so" "$root$target/icon.png" "$root$target/LICENSE" "$root$target/THIRD-PARTY-NOTICES.md"
chmod 755 "$root$target/ibus-engine-galtype" "$root$target/mozc/galtype_mozc_helper"
sed "s|@DIR@|$target|g" "$src/galtype.xml" > "$root/usr/share/ibus/component/galtype.xml"
if [[ -f "$src/fcitx5/galtype.so" ]]; then
    mkdir -p "$root$addondir" "$root/usr/share/fcitx5/addon" "$root/usr/share/fcitx5/inputmethod"
    install -m 644 "$src/fcitx5/galtype.so" "$root$addondir/galtype.so"
    install -m 644 "$src/fcitx5/galtype-addon.conf" "$root/usr/share/fcitx5/addon/galtype.conf"
    sed "s|@DIR@|$target|g" "$src/fcitx5/galtype.conf" > "$root/usr/share/fcitx5/inputmethod/galtype.conf"
    with_fcitx5=true
else
    echo "fcitx5 のアドオンが無いので、IBus だけのパッケージにします。"
    with_fcitx5=false
fi
cat > "$root/usr/share/doc/galtype/copyright" << 'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Galtype
Source: https://github.com/oto-lab/Galtype

Files: *
Copyright: 2026 Yukishiro
License: GPL-3.0-or-later
 On Debian systems, the full text of the GNU General Public License
 version 3 can be found in /usr/share/common-licenses/GPL-3.
 Third-party components: /opt/galtype/THIRD-PARTY-NOTICES.md
EOF
find "$root" -type d -exec chmod 755 {} +

# 依存: 本体 (NativeAOT) と Mozc の変換ヘルパーが使う C / C++ のライブラリと zlib、IBus のエンジン (Python)。
# IBus は fcitx5 だけで使う人もいるので Recommends にする (install.sh も fcitx5 だけなら IBus を入れない)
installed_size="$(du -sk --exclude=DEBIAN "$root" | cut -f1)"
{
    echo "Package: galtype"
    echo "Version: $debversion"
    echo "Architecture: $arch"
    echo "Maintainer: Yukishiro <https://github.com/oto-lab/Galtype>"
    echo "Installed-Size: $installed_size"
    echo "Depends: libc6, libstdc++6, libgcc-s1, zlib1g, python3"
    echo "Recommends: ibus, python3-gi, gir1.2-ibus-1.0"
    if $with_fcitx5; then echo "Suggests: fcitx5"; fi
    echo "Section: utils"
    echo "Priority: optional"
    echo "Homepage: https://github.com/oto-lab/Galtype"
    echo "Description: Japanese input method without the Hankaku/Zenkaku key"
    echo " Galtype is a Japanese input method (IBus engine and fcitx5 addon)."
    echo " English words typed while writing Japanese stay as English,"
    echo " and romaji becomes Japanese, without switching the input mode."
} > "$root/DEBIAN/control"

# 入れたあと: IBus の一覧 (システムのキャッシュ) を作り直す。使っている人の IBus・fcitx5 は、
# ログインし直したとき (または ibus restart / fcitx5 -r) に読み込まれる
cat > "$root/DEBIAN/postinst" << 'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ]; then
    if command -v ibus > /dev/null 2>&1; then ibus write-cache --system > /dev/null 2>&1 || true; fi
    echo "Galtype を入れました。ログアウトしてログインし直してから、入力ソース (IBus) か fcitx5 の設定で Galtype を追加してください。"
fi
exit 0
EOF
# 外す前・更新の前: 動いている IBus のエンジンを止める (IBus は次に使うときに新しいものを起動する。install.sh の ibus restart と同じ目的)
cat > "$root/DEBIAN/prerm" << 'EOF'
#!/bin/sh
set -e
case "$1" in
    remove|upgrade|deconfigure)
        pkill -f /opt/galtype/ibus-engine-galtype > /dev/null 2>&1 || true
        ;;
esac
exit 0
EOF
# 外したあと: IBus の一覧から消す。設定と学習データ (~/.local/share/Galtype) は人ごとのものなので、purge でも消さない
cat > "$root/DEBIAN/postrm" << 'EOF'
#!/bin/sh
set -e
case "$1" in
    remove|purge)
        if command -v ibus > /dev/null 2>&1; then ibus write-cache --system > /dev/null 2>&1 || true; fi
        ;;
esac
exit 0
EOF
chmod 755 "$root/DEBIAN/postinst" "$root/DEBIAN/prerm" "$root/DEBIAN/postrm"

mkdir -p "$out"
deb="$out/galtype_${debversion}_${arch}.deb"
dpkg-deb --root-owner-group -Zxz --build "$root" "$deb"
echo "作成しました: $deb"
