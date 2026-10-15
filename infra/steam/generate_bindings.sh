#!/usr/bin/env bash
# Regenerates packages/steam_api from the Steamworks SDK in infra/steam/sdk,
# using aeb-dev's steamworks_gen. Run after updating the SDK.
#
# One set serves Windows and macOS: the functions are the same on both, and
# the only difference, struct packing, is handled in the game where it
# reads Steam's replies (lib/steam/).
set -euo pipefail
cd "$(dirname "$0")"

JSON=$PWD/sdk/sdk/public/steam/steam_api.json
[[ -f $JSON ]] || { echo "No Steamworks SDK at infra/steam/sdk" >&2; exit 1; }
OUT=$PWD/../../packages/steam_api/lib/src
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/pubspec.yaml" <<YAML
name: steam_gen_work
environment:
  sdk: ^3.5.0
YAML
(cd "$WORK" && dart pub add -d steamworks_gen:0.4.5 >/dev/null && dart pub add ffi >/dev/null &&
  dart run steamworks_gen -o generated -t mac "$JSON" >/dev/null)
python3 -I patch_bindings.py "$WORK/generated"
rm -rf "$OUT" && mkdir -p "$OUT" && cp -R "$WORK/generated/." "$OUT/"
(cd ../../packages/steam_api && dart pub get >/dev/null && dart analyze lib)
echo "Generated packages/steam_api from $JSON"
