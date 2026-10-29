#!/bin/bash
# Renders the ExDisplay brand assets into ../docs/assets using your installed Chrome.
#   bash render.sh stills   # logo + banner PNGs
#   bash render.sh video    # launch.mp4 + poster.jpg
#   bash render.sh all
# Override the browser with CHROME=/path/to/chrome bash render.sh all
set -euo pipefail
cd "$(dirname "$0")"

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
OUT="../docs/assets"
mkdir -p "$OUT"
# --gl=angle avoids intermittent tiled/garbled frames seen with the default GL backend.
COMMON=(--gl=angle --browser-executable="$CHROME")

stills() {
  npx remotion still Banner     "$OUT/banner.png"        --image-format=png "${COMMON[@]}"
  npx remotion still LogoMark   "$OUT/logo-1024.png"     --image-format=png "${COMMON[@]}"
  npx remotion still LogoLockup "$OUT/logo-lockup.png"   --image-format=png "${COMMON[@]}"
}

video() {
  # Consensus render: see render_video.py for why a plain `remotion render` isn't used.
  CHROME="$CHROME" python3 render_video.py "$OUT/launch.mp4" "$OUT/poster.jpg"
}

case "${1:-all}" in
  stills) stills ;;
  video)  video ;;
  all)    stills; video ;;
  *) echo "usage: bash render.sh [stills|video|all]"; exit 1 ;;
esac
