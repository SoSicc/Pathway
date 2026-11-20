# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
import sys, math
from PIL import Image, ImageDraw, ImageFilter
out = sys.argv[1]
S = 4  # supersample

def save(img, name, size):
    img = img.resize((size, size), Image.LANCZOS)
    img.save(f"{out}/{name}.tga", compression=None, orientation=-1)

# Arrow: a clean chevron-style navigation arrow pointing up, white with a subtle inner shade
n = 128 * S
img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
c = n / 2
tip = (c, n * 0.08); left = (n * 0.16, n * 0.88); notch = (c, n * 0.66); right = (n * 0.84, n * 0.88)
shadow = Image.new("RGBA", (n, n), (0, 0, 0, 0))
ImageDraw.Draw(shadow).polygon([(p[0], p[1] + n * 0.025) for p in (tip, left, notch, right)], fill=(0, 0, 0, 150))
shadow = shadow.filter(ImageFilter.GaussianBlur(n * 0.02))
img.alpha_composite(shadow)
d = ImageDraw.Draw(img)
d.polygon([tip, left, notch, right], fill=(255, 255, 255, 255))
# right half slightly darker for a folded, dimensional look (still tintable)
d.polygon([tip, notch, right], fill=(205, 205, 205, 255))
save(img, "Arrow", 128)

# Ring: shown when you've arrived
img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
w = n * 0.07
d.ellipse([w, w, n - w, n - w], outline=(255, 255, 255, 255), width=int(w))
d.ellipse([n * 0.36, n * 0.36, n * 0.64, n * 0.64], fill=(255, 255, 255, 255))
save(img, "Ring", 64)

# Dot: objective pin
img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([n * 0.12, n * 0.12, n * 0.88, n * 0.88], fill=(0, 0, 0, 200))
d.ellipse([n * 0.22, n * 0.22, n * 0.78, n * 0.78], fill=(255, 255, 255, 255))
save(img, "Dot", 32)

# Glow: soft halo behind the current target pin
img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([n * 0.2, n * 0.2, n * 0.8, n * 0.8], fill=(255, 255, 255, 255))
img = img.filter(ImageFilter.GaussianBlur(n * 0.08))
save(img, "Glow", 64)
print("ok")
