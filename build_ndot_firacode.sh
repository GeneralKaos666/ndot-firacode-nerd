#!/usr/bin/env bash
# build_ndot_firacode.sh — build a merged, dot-matrixed NDOT + FiraCode Nerd Font face.
#
#   1. FontForge merges an NDOT base (base wins) with FiraCode Nerd Font
#      (scaled to the base's units-per-em) -> OUTPUT (TrueType by default).
#   2. ndot_nerd_symbols.py redraws every Nerd Font icon as NDOT-style dots
#      in place (FontForge's script language can't rasterize outlines).
#   3. Embeds the licence notice (copyright + full OFL 1.1 text + URL) into the
#      font's `name` table, so the terms travel with the .ttf file itself.
#
# Usage:
#   ./build_ndot_firacode.sh                 # NDOT 47 -> ndot-firacode-nerd.ttf
#   BASE=... OUT=... FAMILY=... PSNAME=... ./build_ndot_firacode.sh
#
# Any extra arguments are passed through to the restyle step, e.g.:
#   ./build_ndot_firacode.sh --cells 20      # finer dot grid
#
# Step 3 is controlled by environment variables:
#   LICENSE_FILE=OFL-1.1.txt  licence text to embed (empty string skips it)
#   LICENSE_URL               default: https://openfontlicense.org
#   LICENSE_COPYRIGHT         default: NDOT 47 + Fira Code + Nerd Fonts
#   LICENSE_TRADEMARK         default: FontStruct / Fira Mono / Nothing
#
# The default base is the open NDOT 47 font, so the default build embeds the
# OFL notice. A build from a proprietary base must skip it.
#
# Ndot57 example (the base is proprietary — see the licence note below):
#   BASE="/data/data/com.termux/files/home/downloads/xeji01 nothingfont main/fonts/Ndot57-Regular.otf" \
#   OUT=ndot57-firacode-nerd.ttf FAMILY="NDOT57 FiraCode Nerd" \
#   PSNAME="NDOT57FiraCodeNerd-Regular" LICENSE_FILE= ./build_ndot_firacode.sh
#
# Nothing's NDOT font EULA allows the font on Nothing brand materials only and
# forbids modifying, sharing or redistributing it. The Ndot57 build modifies
# the base, so it is for personal/local use only and must NOT be redistributed
# (LICENSE_FILE= also keeps the OFL notice out of it).
set -euo pipefail
cd "$(dirname "$0")"

BASE="${BASE:-ndot-47-inspired-by-nothing.ttf}"
MERGE="${MERGE:-FiraCodeNerdFont-Regular.ttf}"
OUT="${OUT:-ndot-firacode-nerd.ttf}"
FAMILY="${FAMILY:-NDOT FiraCode Nerd}"
PSNAME="${PSNAME:-NDOTFiraCodeNerd-Regular}"

# Set FONTFORGE=/path/to/fontforge if it is not on PATH.
FONTFORGE="${FONTFORGE:-fontforge}"

# Source fonts are bundled at the repo root (see README -> "Source fonts").
missing=""
[[ -f "$BASE" ]] || missing="$missing $BASE"
[[ -f "$MERGE" ]] || missing="$missing $MERGE"
if [[ -n "$missing" ]]; then
  echo "error: source font(s) not found:$missing" >&2
  echo "  They live at the repo root; restore them, or point BASE= / MERGE=" >&2
  echo "  at your own local copies." >&2
  exit 1
fi

echo "==> Merging ($BASE + $MERGE) -> $OUT"
"$FONTFORGE" -script native_merge.pe "$BASE" "$MERGE" "$OUT" "$FAMILY" "$PSNAME"

echo "==> Restyling Nerd icons as NDOT dots"
python3 -u ndot_nerd_symbols.py "$OUT" "$@"

# Step 3: embed the licence notice in the font's name table. The new name table
# is appended and the sfnt checksums recomputed, so every other table stays
# byte-for-byte identical.
LICENSE_FILE="${LICENSE_FILE-OFL-1.1.txt}"
if [[ -n "$LICENSE_FILE" ]]; then
  if [[ ! -f "$LICENSE_FILE" ]]; then
    echo "error: licence file not found: $LICENSE_FILE" >&2
    echo "  set LICENSE_FILE= to skip embedding, or point it at a licence text." >&2
    exit 1
  fi
  echo "==> Embedding licence notice ($LICENSE_FILE)"
  OUT="$OUT" LICENSE_FILE="$LICENSE_FILE" python3 - <<'PY'
import os
import struct

from fontTools.ttLib import TTFont

OUT = os.environ["OUT"]
with open(os.environ["LICENSE_FILE"], encoding="utf-8") as fh:
    LICENSE_TEXT = fh.read().strip()

DEFAULT_COPYRIGHT = (
    'Copyright (c) 2021 Interactivate (NDOT 47 "inspired by NOTHING", '
    "https://fontstruct.com/fontstructions/show/2047444/ndot-45-inspired-by-nothing-1); "
    "Copyright (c) 2014-2021 The Fira Code Project Authors (https://github.com/tonsky/FiraCode); "
    "Copyright (c) 2014 Ryan L McIntyre and Nerd Fonts contributors "
    "(https://github.com/ryanoasis/nerd-fonts). "
    'This modified font ("NDOT FiraCode Nerd") merges and restyles those fonts.'
)
DEFAULT_TRADEMARK = (
    "FontStruct is a trademark of FontStruct.com. Fira Mono is a trademark of "
    "The Mozilla Corporation. NOTHING, Ndot and NType are trademarks of Nothing "
    "Technology Ltd. This font is unofficial and unaffiliated with Nothing."
)

copyright_notice = os.environ.get("LICENSE_COPYRIGHT") or DEFAULT_COPYRIGHT
trademark = os.environ.get("LICENSE_TRADEMARK") or DEFAULT_TRADEMARK
license_url = "https://openfontlicense.org"

license_desc = (
    copyright_notice + "\n\n"
    "This Font Software is licensed under the SIL Open Font License, Version 1.1.\n"
    "This license is copied below, and is also available with a FAQ at:\n"
    + license_url + "\n\n"
    + LICENSE_TEXT
)


def pad4(data):
    return data + b"\0" * ((-len(data)) % 4)


def checksum(data):
    data = pad4(data)
    total = 0
    for i in range(0, len(data), 4):
        total = (total + struct.unpack(">I", data[i:i + 4])[0]) & 0xFFFFFFFF
    return total


# --- build the replacement name table ---
font = TTFont(OUT, lazy=True)
name = font["name"]
for record in list(name.names):
    if record.nameID in (0, 7, 13, 14):
        name.names.remove(record)
for plat, enc, lang in ((3, 1, 0x409), (1, 0, 0)):
    name.setName(copyright_notice, 0, plat, enc, lang)
    name.setName(trademark, 7, plat, enc, lang)
    name.setName(license_desc, 13, plat, enc, lang)
    name.setName(license_url, 14, plat, enc, lang)
new_name = name.compile(font)

# --- patch the sfnt: append the name table, fix checksums in place ---
buf = bytearray(open(OUT, "rb").read())
num_tables = struct.unpack(">H", buf[4:6])[0]
records = {}
for i in range(num_tables):
    off = 12 + i * 16
    tag = bytes(buf[off:off + 4]).decode("latin1")
    cksum, toff, tlen = struct.unpack(">III", buf[off + 4:off + 16])
    records[tag] = (off, cksum, toff, tlen)
if "name" not in records or "head" not in records:
    raise SystemExit("error: %s is not a valid sfnt (missing name/head)" % OUT)

buf += b"\0" * ((-len(buf)) % 4)
new_off = len(buf)
buf += pad4(new_name)
struct.pack_into(">III", buf, records["name"][0] + 4, checksum(new_name), new_off, len(new_name))

# Recompute head.checkSumAdjustment. Its directory checksum assumes the field
# is zero, so clear it first, checksum head, then set the real adjustment.
head_dir_off, _head_cksum, head_off, head_len = records["head"]
struct.pack_into(">I", buf, head_off + 8, 0)
struct.pack_into(">I", buf, head_dir_off + 4, checksum(bytes(buf[head_off:head_off + head_len])))
adjust = (0xB1B0AFBA - checksum(bytes(buf))) & 0xFFFFFFFF
struct.pack_into(">I", buf, head_off + 8, adjust)
final_checksum = checksum(bytes(buf))

with open(OUT, "wb") as fh:
    fh.write(buf)

print("    name table: %d bytes, whole-file checksum 0x%08X" % (len(new_name), final_checksum))
PY
fi

echo "==> Done: $OUT"
