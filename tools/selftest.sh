#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
"$repo/dist/Virtual Keys Please.app/Contents/MacOS/VirtualKeysPlease" --selftest
