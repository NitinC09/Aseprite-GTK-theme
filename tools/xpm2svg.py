#!/usr/bin/env python3
"""Convert the xfwm4 title-button pixmaps into pixel-exact SVGs for gtk-4.0.

GTK 4 always draws its own (client-side) window decorations on Wayland, so
the GTK 4 headerbar buttons have to reproduce the xfwm4 buttons for windows
to look the same under xfwm4, niri, Sway, Hyprland, etc.

The xfwm4 button pixmaps are 20x34 and include the titlebar background
around the button. We crop out just the button (plus its drop shadow) and
make the titlebar colour transparent, so the SVG sits on any headerbar.

Usage:  python3 tools/xpm2svg.py            (run from the repository root)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "xfwm4")
DST = os.path.join(ROOT, "gtk-4.0", "assets")

# crop window inside the 20x34 pixmap: rows 6..27, cols 1..18
ROW0, ROW1 = 6, 28
COL0, COL1 = 1, 19

# xfwm4 name -> gtk-4.0 asset name
BUTTONS = {
    "close": "titlebutton-close",
    "maximize": "titlebutton-maximize",
    "maximize-toggled": "titlebutton-restore",
    "hide": "titlebutton-minimize",
}
STATES = {
    "active": "",            # focused window, normal state
    "prelight": "-hover",
    "pressed": "-active",
    "inactive": "-backdrop",
}


def read_xpm(path):
    with open(path) as f:
        strings = re.findall(r'"([^"]*)"', f.read())
    w, h, ncolors, cpp = map(int, strings[0].split()[:4])
    colors = {}
    for line in strings[1:1 + ncolors]:
        key = line[:cpp]
        m = re.search(r"\bc\s+(\S+)", line[cpp:])
        colors[key] = m.group(1)
    rows = strings[1 + ncolors:1 + ncolors + h]
    grid = [[colors[r[i:i + cpp]] for i in range(0, w * cpp, cpp)] for r in rows]
    return grid


def to_svg(grid):
    bg = grid[4][0].lower()  # titlebar fill colour just above the button
    crop = [row[COL0:COL1] for row in grid[ROW0:ROW1]]
    h, w = len(crop), len(crop[0])
    rects = []
    for y, row in enumerate(crop):
        x = 0
        while x < w:  # merge horizontal runs of equal colour
            c = row[x].lower()
            run = 1
            while x + run < w and row[x + run].lower() == c:
                run += 1
            if c != bg and c != "none":
                rects.append(f'<rect x="{x}" y="{y}" width="{run}" height="1" fill="{c}"/>')
            x += run
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {w} {h}" shape-rendering="crispEdges">\n'
        + "\n".join(rects) + "\n</svg>\n"
    )


def main():
    os.makedirs(DST, exist_ok=True)
    for src_name, dst_name in BUTTONS.items():
        for state, suffix in STATES.items():
            path = os.path.join(SRC, f"{src_name}-{state}.xpm")
            if not os.path.exists(path):
                print("missing", path, file=sys.stderr)
                continue
            out = os.path.join(DST, f"{dst_name}{suffix}.svg")
            with open(out, "w") as f:
                f.write(to_svg(read_xpm(path)))
            print("wrote", os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main()
