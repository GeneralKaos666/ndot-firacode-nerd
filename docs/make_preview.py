#!/usr/bin/env python3
"""Generate the README preview images from a built ndot-firacode-nerd.ttf.

Usage:
    python3 docs/make_preview.py [path/to/ndot-firacode-nerd.ttf]

Defaults to ./ndot-firacode-nerd.ttf (the build output). Requires Pillow and
fontTools. Writes docs/hero.png, docs/preview.png and docs/icons.png.
"""
import os
import sys
import math

from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FONT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "ndot-firacode-nerd.ttf")
if not os.path.exists(FONT):
    sys.exit(f"font not found: {FONT}\nBuild it first (./build_ndot_firacode.sh), or pass a path.")

CMAP = TTFont(FONT).getBestCmap()
_cache = {}


def F(size):
    if size not in _cache:
        _cache[size] = ImageFont.truetype(FONT, size)
    return _cache[size]


def g(cp):
    return chr(cp) if cp in CMAP else ""


# palette (Nothing-ish: near-black + white + red accent)
BG    = (13, 15, 18, 255)
PANEL = (22, 24, 29, 255)
BAR   = (31, 34, 40, 255)
EDGE  = (46, 50, 57, 255)
FG    = (233, 233, 235, 255)
DIM   = (140, 144, 152, 255)
FAINT = (96, 100, 108, 255)
RED   = (215, 25, 33, 255)
GREEN = (96, 184, 96, 255)
BLUE = (74, 149, 222, 255)
GOLD = (208, 168, 64, 255)
CYAN = (70, 180, 190, 255)

# (codepoint, label) — a spread of Nerd Font icon families.
ICONS = [
    (0xF07B, "fa-folder"), (0xF15B, "fa-file"), (0xF1D3, "fa-git"),
    (0xF09B, "fa-github"), (0xF296, "fa-gitlab"), (0xF120, "fa-terminal"),
    (0xF1C0, "fa-database"), (0xF121, "fa-code"), (0xF004, "fa-heart"),
    (0xF00C, "fa-check"), (0xF0C2, "fa-cloud"), (0xF17C, "fa-linux"),
    (0xF179, "fa-apple"), (0xF17A, "fa-windows"), (0xF17B, "fa-android"),
    (0xF13B, "fa-html5"), (0xF13C, "fa-css3"), (0xF2EE, "fa-js"),
    (0xED1B, "fa-python"), (0xED44, "fa-node"), (0xF21F, "fa-docker"),
    (0xE73C, "dev-python"), (0xE7A8, "dev-rust"), (0xE781, "dev-javascript"),
    (0xE719, "dev-nodejs"), (0xE7B0, "dev-docker"), (0xE702, "dev-git"),
    (0xE73D, "dev-php"), (0xE738, "dev-java"), (0xE7BA, "dev-react"),
    (0xE7A3, "dev-cplusplus"), (0xE724, "dev-go"), (0xE627, "seti-go"),
    (0xE605, "seti-ruby"), (0xE606, "seti-python"), (0xE68B, "seti-rust"),
    (0xF31A, "linux-tux"), (0xF303, "linux-archlinux"), (0xF31B, "linux-ubuntu"),
    (0xF306, "linux-debian"), (0xF30A, "linux-fedora"), (0xF300, "linux-alpine"),
    (0xE30D, "weather-day-sunny"), (0xE33D, "weather-cloud"), (0xE318, "weather-rain"),
    (0xE31A, "weather-snow"), (0xE315, "weather-lightning"), (0xF408, "oct-mark-github"),
    (0xF418, "oct-git-branch"), (0xF417, "oct-git-commit"), (0xF401, "oct-repo"),
    (0xF489, "oct-terminal"), (0xF02DC, "md-home"), (0xF024B, "md-folder"),
    (0xF0320, "md-language-python"), (0xF1617, "md-language-rust"), (0xF02A2, "md-git"),
    (0xF0868, "md-docker"), (0xF015F, "md-cloud"), (0xF012C, "md-check"),
    (0xEA85, "cod-terminal"), (0xEB00, "cod-github-alt"), (0xEB05, "cod-heart"),
    (0xE0A0, "pl-branch"), (0xE0B0, "pl-left-hard-divider"), (0xE0B2, "pl-right-hard-divider"),
    (0xE0C0, "ple-flame-thick"), (0xE5FF, "custom-folder"), (0xE629, "custom-msdos"),
    (0xE62B, "custom-vim"), (0xE617, "custom-home"),
]


def rich(d, xy, parts):
    """Draw [(text, colour, font), ...] left-to-right; return the end x."""
    x, y = xy
    for s, col, fnt in parts:
        d.text((x, y), s, font=fnt, fill=col)
        x += d.textlength(s, font=fnt)
    return x


def make_hero():
    W, H = 1600, 600
    img = Image.new("RGBA", (W, H), BG)
    d = ImageDraw.Draw(img)

    # subtle top accent bar
    d.rectangle((0, 0, W, 6), fill=RED)

    d.text((80, 70), "NDOT FiraCode Nerd", font=F(104), fill=FG)
    d.text((84, 210), "a dot-matrix terminal typeface", font=F(36), fill=RED)
    d.text((84, 262), "Fira Code letterforms  +  the whole Nerd Font icon set, redrawn from dots",
           font=F(26), fill=DIM)

    # specimen
    y = 350
    d.text((84, y),      "ABCDEFGHIJKLMNOPQRSTUVWXYZ", font=F(34), fill=FG)
    d.text((84, y + 52), "abcdefghijklmnopqrstuvwxyz  0123456789", font=F(34), fill=FG)
    d.text((84, y + 104), "{}[]()<>/\\|~`!@#$%^&*+-=_  \"'.,:;", font=F(34), fill=DIM)
    d.text((84, y + 156), "The quick brown fox jumps over the lazy dog.",
           font=F(34), fill=DIM)

    # icon strip down the right
    strip = [(0xF1D3, RED), (0xE73C, GOLD), (0xE7A8, DIM), (0xE627, BLUE),
             (0xF418, GREEN), (0xF408, FG), (0xE0A0, RED), (0xE7BA, BLUE)]
    iy = 250
    for cp, col in strip:
        if cp in CMAP:
            d.text((W - 150, iy), chr(cp), font=F(52), fill=col, anchor="mm")
        iy += 40

    img.save(os.path.join(HERE, "hero.png"))


def make_preview():
    W, H = 1600, 600
    img = Image.new("RGBA", (W, H), BG)
    d = ImageDraw.Draw(img)

    win = (60, 40, W - 60, H - 40)
    d.rounded_rectangle(win, radius=26, fill=PANEL, outline=EDGE, width=2)
    d.rounded_rectangle((60, 40, W - 60, 112), radius=26, fill=BAR,
                        corners=(True, True, False, False))
    for i, col in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse((92 + i * 34, 66, 112 + i * 34, 86), fill=col)
    d.text((W / 2, 76), "ndot-firacode-nerd  —  ~/.termux/font.ttf",
           font=F(22), fill=DIM, anchor="mm")

    # powerline prompt (dividers drawn directly, so they match the segment)
    fs = F(30)
    x, y, seg_h = 96, 150, 46
    tri = int(seg_h * 0.55)
    segs = [(" user@phone ", RED, (255, 255, 255, 255)),
            (" ~/repos/ndot-firacode-nerd ", (48, 52, 60, 255), FG),
            (" " + g(0xF418) + " main ", GREEN, (12, 14, 17, 255)),
            (" v1.0.0 ", BLUE, (12, 14, 17, 255))]
    for txt, bgc, fgc in segs:
        w = d.textlength(txt, font=fs) + 34
        d.rectangle((x, y, x + w, y + seg_h), fill=bgc)
        d.text((x + 17, y + seg_h / 2), txt, font=fs, fill=fgc, anchor="lm")
        d.polygon([(x + w, y), (x + w + tri, y + seg_h / 2), (x + w, y + seg_h)],
                  fill=bgc)
        x += w + tri

    # output
    lh = 42
    yy = y + seg_h + 40
    chev = g(0x276F) or ">"

    def out(parts):
        nonlocal yy
        rich(d, (96, yy), parts)
        yy += lh

    out([(chev + " ", RED, F(28)), ("./build_ndot_firacode.sh", FG, F(28))])
    out([("==> ", DIM, F(26)), ("Merging ", FG, F(26)),
         ("ndot-47-inspired-by-nothing.ttf + FiraCodeNerdFont-Regular.ttf", GOLD, F(26))])
    out([("==> ", DIM, F(26)), ("Restyling Nerd icons as NDOT dots", FG, F(26))])
    out([("==> ", DIM, F(26)), ("Done: ndot-firacode-nerd.ttf", GREEN, F(26))])
    yy += 12
    out([(g(0xF07B) + " fonts/", BLUE, F(28)), ("      ", FG, F(28)),
         (g(0xF401) + " ndot-firacode-nerd.ttf", FG, F(28)),
         ("   38 MB", DIM, F(26))])
    out([(g(0xF02DC) + " home", GOLD, F(28)), ("       ", FG, F(28)),
         (g(0xF015F) + " synced", DIM, F(28)),
         ("     " + g(0xF012C) + " ok", GREEN, F(28)),
         ("     " + g(0xE315) + " 5 ms", GOLD, F(28))])

    img.save(os.path.join(HERE, "preview.png"))


def make_icons():
    cols = 8
    cell_w, cell_h = 176, 152
    pad, top = 60, 150
    rows = math.ceil(len(ICONS) / cols)
    W = cols * cell_w + 2 * pad
    H = rows * cell_h + top + pad
    img = Image.new("RGBA", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, 6), fill=RED)
    d.text((pad, 52), "Nerd Font icons, redrawn as NDOT dots", font=F(40), fill=FG)
    d.text((pad, 104), "Powerline · Font Awesome · Devicons · Seti · Font Logos · Weather · Octicons · Material Design · Codicons",
           font=F(19), fill=DIM)
    for i, (cp, label) in enumerate(ICONS):
        r, c = divmod(i, cols)
        cx = pad + c * cell_w + cell_w // 2
        cy = top + r * cell_h + 56
        if cp in CMAP:
            d.text((cx, cy), chr(cp), font=F(78), fill=FG, anchor="mm")
        d.text((cx, top + r * cell_h + 124), label, font=F(20), fill=DIM, anchor="mm")
    img.save(os.path.join(HERE, "icons.png"))


if __name__ == "__main__":
    make_hero()
    make_preview()
    make_icons()
    print("wrote docs/hero.png, docs/preview.png, docs/icons.png")
