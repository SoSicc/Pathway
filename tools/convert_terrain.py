# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
# Data/Terrain.lua from the community WoW listfile (github.com/wowdev/wow-listfile):
# the file ID of every minimap terrain square of Eastern Kingdoms and Kalimdor.
#   curl -L https://github.com/wowdev/wow-listfile/releases/latest/download/community-listfile.csv | grep -i world/minimaps/ > minimaps.csv
#   python3 tools/convert_terrain.py minimaps.csv Data/Terrain.lua
import re, sys
src, out = sys.argv[1], sys.argv[2]
cont = {'azeroth': 0, 'kalimdor': 1}
tiles = {0: {}, 1: {}}
for line in open(src):
    fid, path = line.strip().split(';', 1)
    m = re.fullmatch(r'world/minimaps/(azeroth|kalimdor)/map(\d+)_(\d+)\.blp', path.lower())
    if m: tiles[cont[m.group(1)]][(int(m.group(2)), int(m.group(3)))] = int(fid)
lines = ["-- The game's own minimap terrain squares (one per 533 1/3 yards), by continent:",
         "-- [instance] = { [x * 64 + y] = fileID }. From the community file list",
         "-- (github.com/wowdev/wow-listfile): names to file IDs only; the pictures are the game's own.",
         "local _, P = ...", "P.TERRAIN_TILES = {"]
for c in (0, 1):
    parts = [f'[{x * 64 + y}]={fid}' for (x, y), fid in sorted(tiles[c].items())]
    lines.append(f'\t[{c}] = {{')
    for i in range(0, len(parts), 12): lines.append('\t\t' + ','.join(parts[i:i + 12]) + ',')
    lines.append('\t},')
lines.append('}')
open(out, 'w').write('\n'.join(lines) + '\n')
