#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
shots=${APP_SNAPSHOT:-$repo/shots}
mkdir -p "$shots"
APP_SNAPSHOT="$shots" "$repo/dist/Virtual Keys Please.app/Contents/MacOS/VirtualKeysPlease"
"$repo/tools/grid-lint.sh"
swift "$repo/tools/check-layout.swift" "$shots"/*-layout.json
