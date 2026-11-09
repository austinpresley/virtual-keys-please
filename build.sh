#!/bin/zsh
set -euo pipefail
repo=${0:A:h}
name=VirtualKeysPlease
scratch="$HOME/Library/Developer/$name/universal"
configuration=release
architectures=(--arch arm64 --arch x86_64)
if [[ " $* " == *" --debug "* ]]; then
  configuration=debug
  architectures=(--arch arm64)
fi
swift build -c "$configuration" "${architectures[@]}" --package-path "$repo" --scratch-path "$scratch"
bin_dir=$(swift build -c "$configuration" "${architectures[@]}" --package-path "$repo" --scratch-path "$scratch" --show-bin-path)
"$repo/tools/make_icon.sh"
app="$repo/dist/Virtual Keys Please.app"
mkdir -p "$repo/dist"
if [[ -d "$app" ]]; then rm -rf "$app"; fi
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/$name" "$app/Contents/MacOS/$name"
sed 's/__BUILD__/1/' "$repo/Info.plist.in" > "$app/Contents/Info.plist"
cp "$repo/Resources/Assets.car" "$repo/Resources/AppIcon.icns" "$repo/Resources/How it works.html" "$app/Contents/Resources/"
identity=${SIGN_IDENTITY:-}
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -1)
fi
if [[ -n "$identity" ]]; then
  codesign --force --options runtime --timestamp --sign "$identity" "$app"
else
  codesign --force --sign - "$app"
fi
codesign --verify --deep --strict "$app"
echo "Built $app"
