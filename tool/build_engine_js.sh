#!/usr/bin/env bash
# Compiles the Dart game engine to JavaScript for the `match` Edge Function.
# The output is committed so a deploy never depends on a local Dart SDK; run
# this after ANY change under lib/features/game/domain/ and commit the result.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=supabase/functions/match/engine.js
dart compile js -O2 --no-source-maps --no-frequency-based-minification \
  -o "$OUT" tool/engine_js/engine_bridge.dart
# dart2js emits a trailing source-map comment even with maps disabled.
sed -i '/^\/\/# sourceMappingURL=/d' "$OUT"
rm -f "$OUT.deps"
echo "engine.js: $(wc -c < "$OUT") bytes, sha256 $(sha256sum "$OUT" | cut -c1-16)"
