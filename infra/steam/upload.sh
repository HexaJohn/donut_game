#!/usr/bin/env bash
# Uploads Donut to Steam with SteamPipe, from this Mac.
#
#   ./upload.sh BUILD_ACCOUNT [--windows PATH] [--no-mac] [--beta BRANCH] [--preview]
#
# BUILD_ACCOUNT  the Steam account with build permissions (asks for its
#                password and Steam Guard code the first time)
# --windows PATH the Windows build: the contents of
#                build\windows\x64\runner\Release, as a folder or a .zip.
#                Without it, only the macOS depot is uploaded.
# --no-mac       leave the macOS depot out (Windows-only releases)
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
WINDOWS="" BETA="" PREVIEW=0 MAC=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --windows) WINDOWS=$2; shift 2 ;;
    --beta) BETA=$2; shift 2 ;;
    --preview) PREVIEW=1; shift ;;
    --no-mac) MAC=0; shift ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done
((MAC)) || [[ -n $WINDOWS ]] || { echo "Nothing to upload: --no-mac needs --windows" >&2; exit 1; }
[[ -x $BUILDER ]] || { echo "No Steam uploader at $BUILDER; unzip the Steamworks SDK into infra/steam/sdk" >&2; exit 1; }

VERSION=$(grep '^version:' ../../pubspec.yaml | awk '{print $2}')
COMMIT=$(git rev-parse --short HEAD)
rm -rf content && mkdir -p content output

DEPOTS=""
if ((MAC)); then
  echo "Building macOS..."
  # Launched outside Steam, a Steam build relaunches through it
  (cd ../.. && flutter build macos --release --dart-define=STEAM_RESTART=true >/dev/null)
  # ditto keeps the app's symlinks and permissions
  ditto ../../build/macos/Build/Products/Release/Donut.app content/macos/Donut.app
  codesign --verify --deep --strict content/macos/Donut.app
  [[ -f content/macos/Donut.app/Contents/Frameworks/libsteam_api.dylib ]] ||
    { echo "The Mac build has no Steam library: is the Steamworks SDK in infra/steam/sdk?" >&2; exit 1; }
  DEPOTS="    \"$MAC_DEPOT\" { \"FileMapping\" { \"LocalPath\" \"macos/*\" \"DepotPath\" \".\" \"Recursive\" \"1\" } }"
fi
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
  KEEP=" flutter_windows.dll steam_api64.dll "
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
  # Valve's Steam library, which the game loads from beside its .exe
  cp sdk/sdk/redistributable_bin/win64/steam_api64.dll content/windows/
  [[ -n $DEPOTS ]] && DEPOTS+=$'\n'
  DEPOTS+="    \"$WINDOWS_DEPOT\" { \"FileMapping\" { \"LocalPath\" \"windows/*\" \"DepotPath\" \".\" \"Recursive\" \"1\" } }"
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

PLATFORMS=$( ((MAC)) && echo "macOS${WINDOWS:+ and Windows}" || echo "Windows" )
echo "Uploading Donut $VERSION ($COMMIT) to app $APP_ID: $PLATFORMS${BETA:+, live on $BETA}$( ((PREVIEW)) && echo ' (preview, nothing uploaded)')"
"$BUILDER" +login "$ACCOUNT" +run_app_build "$PWD/app_build.vdf" +quit
