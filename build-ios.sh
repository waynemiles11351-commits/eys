#!/bin/bash
set -euo pipefail
SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos -f clang++)"
mkdir -p dist
"$CLANG" \
  -arch arm64 \
  -isysroot "$SDKROOT" \
  -miphoneos-version-min=18.0 \
  -std=c++17 -fobjc-arc -fPIC -dynamiclib -O2 \
  -Wl,-install_name,@rpath/GGDIdentityOverlay.dylib \
  -framework Foundation -framework UIKit -framework QuartzCore -framework Metal \
  Tweak.xm GGDCore.mm GGDOverlay.mm \
  -o dist/GGDIdentityOverlay.dylib
file dist/GGDIdentityOverlay.dylib
xcrun --sdk iphoneos otool -hv dist/GGDIdentityOverlay.dylib
