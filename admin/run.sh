#!/usr/bin/env bash
# Builds (if needed) and opens Donut Admin. Uses this Mac's AWS CLI
# credentials (the default profile, or AWS_PROFILE).
set -euo pipefail
cd "$(dirname "$0")"
APP="build/macos/Build/Products/Release/Donut Admin.app"
if [[ ! -d "$APP" || -n "$(find lib ../packages/donut_engine/lib ../packages/donut_server/lib -newer "$APP" -name '*.dart' | head -1)" ]]; then
  flutter build macos --release
fi
open "$APP"
