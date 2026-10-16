#!/usr/bin/env bash
# Builds dist/U2422HControl.app (ad-hoc signed, not notarized) and zips it for a release.
# usage: packaging/bundle-app.sh <version>
set -euo pipefail

version="${1:?usage: $0 <version>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/dist/U2422HControl.app"

swift build -c release --package-path "$root"
bin_dir="$(swift build -c release --package-path "$root" --show-bin-path)"

rm -rf "$root/dist"
mkdir -p "$app/Contents/MacOS"
cp "$bin_dir/U2422HControl" "$app/Contents/MacOS/"
sed "s/__VERSION__/$version/g" "$root/packaging/Info.plist" > "$app/Contents/Info.plist"
codesign --force --sign - "$app"
ditto -c -k --norsrc --keepParent "$app" "$root/dist/U2422HControl-$version.zip"
echo "$root/dist/U2422HControl-$version.zip"
