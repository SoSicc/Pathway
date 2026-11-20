# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
"""Quest XP for Pathway: QuestieDB's Forever QuestXP support data
(support/Forever/QuestXP/xpDB-classic.lua and xpDB-traces.lua) -> Data/QuestXP.lua.
Each entry is the base experience at the quest's level: P.XP[questID] = xp * 100 + level."""
import re, sys, os
src, out = sys.argv[1], sys.argv[2]
d = os.path.join(src, "support", "Forever", "QuestXP")
xp = {}
for name in ("xpDB-classic.lua", "xpDB-traces.lua"):        # traces (seen on Forever) win
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{\s*(-?\d+)\s*,\s*(\d+)\s*\}", open(os.path.join(d, name), encoding="utf-8").read()):
        q, lvl, x = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if x > 0 and 0 < lvl < 100: xp[q] = x * 100 + lvl
lines = ["-- Pathway quest experience for World of Warcraft: Forever.",
         "-- Generated from QuestieDB's Forever QuestXP data (GPLv3, (c) the Questie team and contributors).",
         "-- https://github.com/Questie/QuestieDB  -  do not edit by hand; regenerate with tools/convert_xp.py",
         "-- P.XP[questID] = base experience * 100 + the quest's level",
         "local _, P = ...",
         "P.XP = {"]
row = []
for q in sorted(xp):
    row.append(f"[{q}]={xp[q]},")
    if len(row) == 12: lines.append("".join(row)); row = []
if row: lines.append("".join(row))
lines.append("}")
open(out, "w", newline="\n").write("\n".join(lines) + "\n")
print(len(xp), "quests,", os.path.getsize(out), "bytes")
