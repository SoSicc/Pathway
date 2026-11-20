# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
# Ride effects: the tram's tunnel rings, wind and speed streaks, water light,
# bubbles and lift bands. White on transparent; the game tints them.
import sys
import numpy as np
from PIL import Image
out = sys.argv[1]

def save(a, name):
    a = np.clip(a, 0, 1)
    h, w = a.shape
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(f"{out}/Ride-{name}.tga", compression=None, orientation=-1)

def grid(n):
    y, x = np.mgrid[0:n, 0:n]
    return (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1

# a thin bright ring with a soft glow (tunnel rings, ripples)
x, y = grid(256); r = np.hypot(x, y)
core = np.exp(-((r - 0.86) / 0.025) ** 2)
glow = 0.45 * np.exp(-((r - 0.86) / 0.09) ** 2)
save((core + glow) * (r < 0.99), "Ring")

# a streak: bright in the middle, tapering to nothing at both ends
w, h = 256, 32
xs = np.linspace(-1, 1, w)[None, :]; ys = np.linspace(-1, 1, h)[:, None]
along = np.clip(1 - np.abs(xs), 0, 1) ** 0.7
across = np.exp(-(ys / 0.28) ** 2)
save(along * across, "Streak")

# water light: soft caustic lines that tile seamlessly
n = 256
rng = np.random.default_rng(7)
g = 5
pts = np.array([((i + 0.2 + 0.6 * rng.random()) * n / g, (j + 0.2 + 0.6 * rng.random()) * n / g) for i in range(g) for j in range(g)])
yy, xx = np.mgrid[0:n, 0:n].astype(float)
# a gentle warp so the cells look like light on water, not tiles
wx = xx + 6 * np.sin(yy / n * 2 * np.pi * 2) ; wy = yy + 6 * np.sin(xx / n * 2 * np.pi * 3)
ds = []
for px, py in pts:
    for ox in (-n, 0, n):
        for oy in (-n, 0, n):
            ds.append(np.hypot(wx - px - ox, wy - py - oy))
ds = np.sort(np.stack(ds), axis=0)
edge = ds[1] - ds[0]
save(np.exp(-(edge / 5.0) ** 2) * 0.9 + np.exp(-(edge / 14.0) ** 2) * 0.25, "Caustics")

# a bubble: a thin rim and a little highlight
x, y = grid(64); r = np.hypot(x, y)
rim = np.exp(-((r - 0.8) / 0.08) ** 2)
fill = 0.12 * (r < 0.8)
hi = np.exp(-(((x + 0.32) ** 2 + (y + 0.32) ** 2) / 0.02))
save(rim + fill + hi, "Bubble")

# a band of light across (lifts)
ys = np.linspace(-1, 1, 64)[:, None] * np.ones((1, 64))
save(np.exp(-(ys / 0.35) ** 2), "Band")
