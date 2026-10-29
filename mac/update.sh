#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 hrmcngs

# Run from any directory:
#   bash "$HOME/Documents/github/other/Galtype/mac/update.sh"
# Show help without starting the input method:
#   bash "$HOME/Documents/github/other/Galtype/mac/update.sh" --help
# This updates and starts Galtype. Avoid running while investigating crashes.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$HOME/Library/Input Methods/Galtype.app"

case "${1:-}" in
    -h|--help)
        echo "Usage: bash mac/update.sh"
        echo "Test, build, install, verify, and select the local Mac input method."
        exit 0 ;;
    "") ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
esac
[[ $# -le 1 ]] || { echo "Too many arguments" >&2; exit 1; }
[[ "$(uname)" == Darwin ]] || { echo "This updater requires macOS." >&2; exit 1; }

# Native checks exit the input-method process; restore it even if a check fails.
restore_input() {
    local result=$?
    trap - EXIT
    if ! bash "$here/start-input-method.sh" "$app" ||
       ! "$app/Contents/MacOS/Galtype" --register-input-source ||
       ! swift "$here/select-input-source.swift"; then
        echo "Could not select Galtype. Choose it from the input menu." >&2
        [[ $result -ne 0 ]] || result=1
    fi
    exit "$result"
}
trap restore_input EXIT
MELTYPE_SKIP_START=1 bash "$here/build-cli.sh" --test --install
"$app/Contents/MacOS/Galtype" --check-inputs "$here/Resources/InputChecks.tsv"
echo "Galtype update and input checks completed."
