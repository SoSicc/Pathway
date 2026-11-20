# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
import sys
from PIL import Image, ImageDraw, ImageFilter
out = sys.argv[1]; S = 8
def save(img, name, size):
    img = img.resize((size, size), Image.LANCZOS)
    img.save(f"{out}/{name}.tga", compression=None, orientation=-1)
n = 64 * S
def circle(d, r, fill): c = n/2; d.ellipse([c-r*n, c-r*n, c+r*n, c+r*n], fill=fill)

# Pip: a white disc with a crisp dark outline and a soft dark shadow.
# Tinted, the disc takes the quest's color and the outline stays dark.
img = Image.new("RGBA", (n, n), (0,0,0,0))
sh = Image.new("RGBA", (n, n), (0,0,0,0)); circle(ImageDraw.Draw(sh), 0.44, (0,0,0,150))
img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(n*0.035)))
d = ImageDraw.Draw(img)
circle(d, 0.39, (10,10,12,255))
circle(d, 0.29, (255,255,255,255))
save(img, "Pip", 64)

# PipHollow: a checked spot, the same outline with nothing inside
img = Image.new("RGBA", (n, n), (0,0,0,0)); d = ImageDraw.Draw(img)
circle(d, 0.40, (10,10,12,235)); circle(d, 0.32, (255,255,255,255)); circle(d, 0.22, (10,10,12,235))
# punch the middle out
mask = Image.new("L", (n, n), 0); circle(ImageDraw.Draw(mask), 0.16, 255)
img.paste((0,0,0,0), (0,0), mask)
save(img, "PipHollow", 64)

# Halo: the pulse round the next spot, a bright ring with a dark edge
img = Image.new("RGBA", (n, n), (0,0,0,0)); d = ImageDraw.Draw(img)
circle(d, 0.48, (10,10,12,200)); circle(d, 0.44, (255,255,255,255)); circle(d, 0.36, (10,10,12,200))
mask = Image.new("L", (n, n), 0); circle(ImageDraw.Draw(mask), 0.33, 255)
img.paste((0,0,0,0), (0,0), mask)
save(img, "Halo", 64)

# Pointer: a chevron pointing up with a dark outline, for the minimap's edge
img = Image.new("RGBA", (n, n), (0,0,0,0)); d = ImageDraw.Draw(img)
c = n/2
pts = [(c, n*0.12), (n*0.84, n*0.80), (c, n*0.62), (n*0.16, n*0.80)]
d.polygon(pts, fill=(10,10,12,255))
inner = Image.new("RGBA", (n, n), (0,0,0,0))
ImageDraw.Draw(inner).polygon([(c, n*0.22), (n*0.74, n*0.73), (c, n*0.57), (n*0.26, n*0.73)], fill=(255,255,255,255))
img.alpha_composite(inner)
# a dark stroke all round
stroke = img.filter(ImageFilter.MaxFilter(int(S*3)|1))
bg = Image.new("RGBA", (n, n), (0,0,0,0))
r,g,b,a = stroke.split(); dark = Image.merge("RGBA", (r.point(lambda v:10), g.point(lambda v:10), b.point(lambda v:12), a))
bg.alpha_composite(dark); bg.alpha_composite(img)
save(bg, "Pointer", 64)
