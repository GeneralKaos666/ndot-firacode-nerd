#!/usr/bin/env bash
# build_ndot_firacode.sh — build a merged, dot-matrixed NDOT + FiraCode Nerd Font face.
#
#   1. FontForge merges an NDOT base (base wins) with FiraCode Nerd Font
#      (scaled to the base's units-per-em) -> OUTPUT (TrueType by default).
#   2. ndot_nerd_symbols.py redraws every Nerd Font icon as NDOT-style dots
#      in place (FontForge's script language can't rasterize outlines).
#
# Usage:
#   ./build_ndot_firacode.sh                 # NDOT 47 -> ndot-firacode-nerd.ttf
#   BASE=... OUT=... FAMILY=... PSNAME=... ./build_ndot_firacode.sh
#
# Any extra arguments are passed through to the restyle step, e.g.:
#   ./build_ndot_firacode.sh --cells 20      # finer dot grid
#
# NDOT 57 example (NDOT 57 is OpenType/CFF, so keep the quoted path).
# NOTE: Ndot57 is a proprietary Nothing font — "must not modify, share or
# redistribute". It is NOT shipped in this repo; point BASE at your local copy
# (restored from ~/downloads). Building with it is for personal/local use only.
#   BASE="/data/data/com.termux/files/home/downloads/xeji01 nothingfont main/fonts/Ndot57-Regular.otf" \
#   OUT=ndot57-firacode-nerd.ttf FAMILY="NDOT57 FiraCode Nerd" \
#   PSNAME="NDOT57FiraCodeNerd-Regular" ./build_ndot_firacode.sh
set -euo pipefail
cd "$(dirname "$0")"

FONTFORGE="${FONTFORGE:-fontforge}"
BASE="${BASE:-ndot-47-inspired-by-nothing.ttf}"
MERGE="${MERGE:-FiraCodeNerdFont-Regular.ttf}"
OUT="${OUT:-ndot-firacode-nerd.ttf}"
FAMILY="${FAMILY:-NDOT FiraCode Nerd}"
PSNAME="${PSNAME:-NDOTFiraCodeNerd-Regular}"

# Source fonts are inputs fetched from upstream, not tracked in this repo.
missing=""
[[ -f "$BASE" ]] || missing="$missing $BASE"
[[ -f "$MERGE" ]] || missing="$missing $MERGE"
if [[ -n "$missing" ]]; then
  echo "error: source font(s) not found:$missing" >&2
  echo "  This repo does not ship font binaries; download the two inputs from upstream" >&2
  echo "  (see README -> 'Getting the source fonts') and place them here, or point" >&2
  echo "  BASE= / MERGE= at your local copies." >&2
  exit 1
fi

echo "==> Merging ($BASE + $MERGE) -> $OUT"
"$FONTFORGE" -script native_merge.pe "$BASE" "$MERGE" "$OUT" "$FAMILY" "$PSNAME"

echo "==> Restyling Nerd icons as NDOT dots"
python3 -u ndot_nerd_symbols.py "$OUT" "$@"

echo "==> Done: $OUT"
