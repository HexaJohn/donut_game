#!/bin/sh
# Xcode build step (macOS Runner, "Embed Steam API"): copies Valve's Steam
# library into the app's Frameworks, where lib/steam loads it from. Valve's
# own signature is kept; the app's entitlements allow loading it. Without
# the SDK the app is built without it and simply runs without Steam.
LIB="$PROJECT_DIR/../infra/steam/sdk/sdk/redistributable_bin/osx/libsteam_api.dylib"
DEST="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"
if [ ! -f "$LIB" ]; then
  echo "warning: No Steamworks SDK in infra/steam/sdk; building without Steam"
  exit 0
fi
mkdir -p "$DEST"
cp -f "$LIB" "$DEST/libsteam_api.dylib"
