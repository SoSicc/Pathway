# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
#!/usr/bin/env python3
"""Build Pathway/Data/Loot.lua: what rares, elites and bosses drop.

From QuestieDB's Forever data (GPLv3). Only gear, recipes and curios that drop
from a handful of creatures (not world drops), and only for creatures ranked
elite, rare elite, boss or rare.

usage: python3 -I tools/loot.py <QuestieDB checkout> <Pathway root>
"""
import os, sys
from lupa import lua51

ROOT, OUT = sys.argv[1], sys.argv[2]
L = lua51.LuaRuntime(unpack_returned_tuples=True)
COMB = "src/corrections/Forever/combined/"

def lua_file(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return L.execute(f.read())

def ltab(t):
    if t is None or not hasattr(t, "items"): return t
    return {k: v for k, v in t.items()}

def llist(t):
    if t is None: return []
    if not hasattr(t, "items"): return [t]
    d = ltab(t)
    return [d[k] for k in sorted(k for k in d if isinstance(k, int))]

npcs = ltab(lua_file(COMB + "foreverNpcDB.lua"))
items = ltab(lua_file(COMB + "foreverItemDB.lua"))

ranked = {}
for nid, row in npcs.items():
    r = ltab(row)
    rank = r.get(6) if r else None
    if isinstance(rank, int) and rank > 0: ranked[nid] = rank

# gear (2 weapon, 4 armor), recipes (9), curios (15 misc: pets, mounts) and quest starters
WANT = {2, 4, 9, 15}
loot = {}
for iid, row in items.items():
    it = ltab(row)
    if not it: continue
    cls = it.get(12)
    starts = it.get(5)
    if cls not in WANT and not starts: continue
    drops = [n for n in llist(it.get(2)) if isinstance(n, int)]
    if not drops or len(drops) > 8: continue          # world drops left out
    for n in drops:
        if n in ranked: loot.setdefault(n, []).append(iid)

with open(os.path.join(OUT, "Data", "Loot.lua"), "w", encoding="utf-8", newline="\n") as f:
    f.write("-- Pathway quest data for World of Warcraft: Forever.\n")
    f.write("-- Generated from QuestieDB's Forever data (GPLv3, (c) the Questie team and contributors).\n")
    f.write("-- https://github.com/Questie/QuestieDB  -  do not edit by hand; regenerate with tools/loot.py\n")
    f.write("local _, P = ...\n")
    f.write("-- what rares, elites and bosses drop: [npc] = { item, ... } (gear, recipes, curios, quest starters)\n")
    f.write("P.LOOT = {\n")
    n = 0
    for nid in sorted(loot):
        ids = sorted(set(loot[nid]))[:16]
        n += len(ids)
        f.write("[%d]={%s},\n" % (nid, ",".join(map(str, ids))))
    f.write("}\n")
print("creatures", len(loot), "items", n)
