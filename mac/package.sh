#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 hrmcngs

# Package the built app and all installer helpers without installing anything.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"
[[ -d "$here/build/Galtype.app" ]] || { echo "Run mac/build-cli.sh --build first." >&2; exit 1; }
name="${1:-Galtype-mac-test-$(date +%Y%m%d-%H%M%S).zip}"
[[ "$name" != */* && "$name" == *.zip ]] || { echo "Expected a zip filename without a directory." >&2; exit 1; }
mkdir -p "$root/dist"
stage="$(mktemp -d "$root/dist/.galtype-package.XXXXXX")"
cleanup() {
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$stage/Galtype-mac/Galtype.app" 2>/dev/null || true
    rm -rf "$stage"
}
trap cleanup EXIT
package="$stage/Galtype-mac"
mkdir -p "$package"
cp -R "$here/build/Galtype.app" "$package/"
cp "$here/install.sh" "$here/Install Galtype.command" "$here/install-app.sh" "$here/start-input-method.sh" "$here/select-input-source.swift" "$package/"
cp "$here/TESTER-README.txt" "$package/はじめにお読みください.txt"
cp "$root/LICENSE" "$root/THIRD-PARTY-NOTICES.md" "$package/"
chmod +x "$package/install.sh" "$package/Install Galtype.command" "$package/start-input-method.sh"
ditto -c -k --keepParent "$package" "$root/dist/$name"
echo "Created: $root/dist/$name"
