#!/usr/bin/env bash
# Uploads Donut to Steam with SteamPipe, from this Mac.
#
#   ./upload.sh BUILD_ACCOUNT [--windows PATH] [--beta BRANCH] [--preview]
#
# BUILD_ACCOUNT  the Steam account with build permissions (asks for its
#                password and Steam Guard code the first time)
# --windows PATH the Windows build: the contents of
#                build\windows\x64\runner\Release, as a folder or a .zip.
#                Without it, only the macOS depot is uploaded.
# --beta BRANCH  also set the build live on this beta branch (it must exist
#                in Steamworks). The default branch is set live by hand.
# --preview      check everything without uploading
#
# The macOS depot is uploaded from a Mac on purpose: a Mac app has symlinks
# and an executable bit that copying through Windows destroys.
set -euo pipefail
cd "$(dirname "$0")"

APP_ID=${STEAM_APP_ID:-1905500}
WINDOWS_DEPOT=1905502
MAC_DEPOT=1905503
BUILDER=sdk/sdk/tools/ContentBuilder/builder_osx/steamcmd.sh

ACCOUNT=${1:?usage: upload.sh BUILD_ACCOUNT [--windows PATH] [--beta BRANCH] [--preview]}
shift
WINDOWS="" BETA="" PREVIEW=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --windows) WINDOWS=$2; shift 2 ;;
    --beta) BETA=$2; shift 2 ;;
    --preview) PREVIEW=1; shift ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done
[[ -x $BUILDER ]] || { echo "No Steam uploader at $BUILDER; unzip the Steamworks SDK into infra/steam/sdk" >&2; exit 1; }

VERSION=$(grep '^version:' ../../pubspec.yaml | awk '{print $2}')
COMMIT=$(git rev-parse --short HEAD)
rm -rf content && mkdir -p content/macos output

echo "Building macOS..."
(cd ../.. && flutter build macos --release >/dev/null)
# ditto keeps the app's symlinks and permissions
ditto ../../build/macos/Build/Products/Release/Donut.app content/macos/Donut.app
codesign --verify --deep --strict content/macos/Donut.app

DEPOTS="    \"$MAC_DEPOT\" { \"FileMapping\" { \"LocalPath\" \"macos/*\" \"DepotPath\" \".\" \"Recursive\" \"1\" } }"
if [[ -n $WINDOWS ]]; then
  mkdir -p content/windows
  if [[ $WINDOWS == *.zip ]]; then
    ditto -x -k "$WINDOWS" content/windows
  else
    ditto "$WINDOWS" content/windows
  fi
  # A zip of the Release folder itself unpacks into a Release subfolder
  if [[ ! -f content/windows/donut_game.exe && -d content/windows/Release ]]; then
    mv content/windows/Release/* content/windows/ && rmdir content/windows/Release
  fi
  [[ -f content/windows/donut_game.exe && -f content/windows/flutter_windows.dll && -d content/windows/data ]] ||
    { echo "The Windows build needs donut_game.exe, flutter_windows.dll and the data folder" >&2; exit 1; }
  # Flutter never clears old files out of Release, so DLLs from plugins the
  # game no longer uses ride along; keep only the ones it lists now
  KEEP=" flutter_windows.dll "
  for plugin in $(sed -n '/FLUTTER_PLUGIN_LIST$/,/)/p' ../../windows/flutter/generated_plugins.cmake | grep -v '[()]'); do
    KEEP+="${plugin}_plugin.dll "
  done
  for dll in content/windows/*.dll; do
    name=$(basename "$dll")
    if [[ $KEEP != *" $name "* ]]; then
      echo "Leaving out $name (left over from an older build)"
      rm "$dll"
    fi
  done
  DEPOTS+=$'\n'"    \"$WINDOWS_DEPOT\" { \"FileMapping\" { \"LocalPath\" \"windows/*\" \"DepotPath\" \".\" \"Recursive\" \"1\" } }"
fi

cat > app_build.vdf <<VDF
"AppBuild"
{
  "AppID" "$APP_ID"
  "Desc" "Donut $VERSION ($COMMIT)"
  "ContentRoot" "content/"
  "BuildOutput" "output/"
  "Preview" "$PREVIEW"
$( [[ -n $BETA ]] && echo "  \"SetLive\" \"$BETA\"" )
  "Depots"
  {
$DEPOTS
  }
}
VDF

echo "Uploading Donut $VERSION ($COMMIT) to app $APP_ID: macOS${WINDOWS:+ and Windows}${BETA:+, live on $BETA}$( ((PREVIEW)) && echo ' (preview, nothing uploaded)')"
"$BUILDER" +login "$ACCOUNT" +run_app_build "$PWD/app_build.vdf" +quit
