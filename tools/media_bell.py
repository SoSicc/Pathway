# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
import sys
from PIL import Image, ImageDraw, ImageFilter
out = sys.argv[1]; S = 8; n = 64 * S
img = Image.new("RGBA", (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
W = (255, 255, 255, 255)
c = n / 2
# the bell's dome and body
d.ellipse([c - 0.20 * n, 0.16 * n, c + 0.20 * n, 0.56 * n], fill=W)
d.polygon([(c - 0.20 * n, 0.36 * n), (c + 0.20 * n, 0.36 * n), (c + 0.27 * n, 0.70 * n), (c - 0.27 * n, 0.70 * n)], fill=W)
# the lip
d.rounded_rectangle([c - 0.33 * n, 0.66 * n, c + 0.33 * n, 0.75 * n], radius=0.04 * n, fill=W)
# the clapper and the top loop
d.ellipse([c - 0.075 * n, 0.74 * n, c + 0.075 * n, 0.88 * n], fill=W)
d.ellipse([c - 0.05 * n, 0.09 * n, c + 0.05 * n, 0.19 * n], fill=W)
# a dark outline all round, so any color reads on any background
a = img.split()[3]
grown = a.filter(ImageFilter.MaxFilter(S * 3 | 1))
bg = Image.new("RGBA", (n, n), (10, 10, 12, 0)); bg.putalpha(grown)
bg.alpha_composite(img)
bg.resize((64, 64), Image.LANCZOS).save(f"{out}/Bell.tga", compression=None, orientation=-1)
