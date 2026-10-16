#!/usr/bin/env bash
# Builds dist/U2422HControl.app (ad-hoc signed, not notarized) and zips it for a release.
# usage: packaging/bundle-app.sh <version>
set -euo pipefail

version="${1:?usage: $0 <version>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/dist/U2422HControl.app"

swift build -c release --package-path "$root"

rm -rf "$root/dist"
mkdir -p "$app/Contents/MacOS"
cp "$root/.build/release/U2422HControl" "$app/Contents/MacOS/"
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>U2422HControl</string>
	<key>CFBundleIdentifier</key><string>io.github.inwamos.U2422HControl</string>
	<key>CFBundleName</key><string>U2422H Control</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>$version</string>
	<key>CFBundleVersion</key><string>$version</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>LSUIElement</key><true/>
</dict>
</plist>
EOF
codesign --force --sign - "$app"
ditto -c -k --norsrc --keepParent "$app" "$root/dist/U2422HControl-$version.zip"
