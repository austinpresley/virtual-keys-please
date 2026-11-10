#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
app="$repo/dist/Virtual Keys Please.app"
codesign --verify --deep --strict "$app"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/Virtual Keys Please.app"
cp "$repo/Resources/How it works.html" "$stage/Start here.html"
cp "$repo/THIRD_PARTY_NOTICES.txt" "$stage/Third-party notices.txt"
dmg="$repo/dist/Virtual Keys Please.dmg"
hdiutil create -volname 'Virtual Keys Please' -srcfolder "$stage" -format UDZO -ov "$dmg"
identity=${SIGN_IDENTITY:-}
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -1)
fi
if [[ -n "$identity" ]]; then codesign --timestamp --sign "$identity" "$dmg"; fi
hdiutil verify "$dmg"
echo "Packaged $dmg"
