#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
BUILD_DIR="${TMPDIR:-/tmp}/trackedge-build"
APP="$BUILD_DIR/TrackEdge.app"
mkdir -p "$BUILD_DIR/cache" "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -swift-version 5 -module-cache-path "$BUILD_DIR/cache" Assets/RenderIcon.swift -o "$BUILD_DIR/render-icon"
"$BUILD_DIR/render-icon" "$BUILD_DIR/AppIcon.iconset"
iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
cp "$BUILD_DIR/AppIcon.iconset/icon_512x512@2x.png" Assets/AppIcon.png
xcrun clang -fobjc-arc -mmacosx-version-min=13.0 -c Sources/Bridge.m -o "$BUILD_DIR/Bridge.o" -I Sources -fmodules-cache-path="$BUILD_DIR/cache"
xcrun swiftc -swift-version 5 -O -target "$(uname -m)-apple-macosx13.0" -module-cache-path "$BUILD_DIR/cache" -import-objc-header Sources/Bridge.h Sources/Gestures.swift Sources/SystemControls.swift Sources/ControlPanel.swift Sources/CursorLock.swift Sources/StatusIcon.swift Sources/main.swift "$BUILD_DIR/Bridge.o" -o "$APP/Contents/MacOS/TrackEdge" -framework AppKit -framework CoreAudio -framework AudioToolbox -framework IOKit -framework ApplicationServices -framework ServiceManagement
cp Info.plist "$APP/Contents/Info.plist"
xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
codesign --force --sign - --identifier local.trackedge.app "$APP"
codesign --verify --deep --strict "$APP"
ditto --norsrc "$APP" TrackEdge.app
xattr -dr com.apple.FinderInfo TrackEdge.app 2>/dev/null || true
ditto -c -k --norsrc --keepParent "$APP" ../TrackEdge.zip
printf 'App creada: %s/TrackEdge.app\n' "$PWD"
