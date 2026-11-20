# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
"""Convert the merged QuestieDB Forever export into Pathway's compact Lua data.

Usage: python3 -I convert.py <QuestieDB checkout> <output Data dir>
"""
import os, sys, math
from lupa import lua51

ROOT, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
L = lua51.LuaRuntime(unpack_returned_tuples=True)

def lua_file(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return L.execute(f.read())

def lua_string_table(src):
    return L.execute(src)

# ---------------------------------------------------------------- entities
COMB = "src/corrections/Forever/combined/"
quests = lua_file(COMB + "foreverQuestDB.lua")
npcs = lua_file(COMB + "foreverNpcDB.lua")
objects = lua_file(COMB + "foreverObjectDB.lua")
items = lua_file(COMB + "foreverItemDB.lua")

# ---------------------------------------------------------------- zones
L.execute("""
ZoneDB = { private = {} }
Expansions = { Current = 1, Era = 1, Tbc = 2, Wotlk = 3, Cata = 4, MoP = 5 }
QuestieLoader = { ImportModule = function(_, n) if n == 'ZoneDB' then return ZoneDB end return Expansions end }
UnitFactionGroup = function() return 'Alliance' end
""")
Z = "support/Forever/Zones/"
lua_file(Z + "areaIdToUiMapId.lua")
lua_file(Z + "subZoneToParentZone.lua")
lua_file(Z + "dungeons.lua")
zp = L.globals().ZoneDB.private
area_main = lua_string_table(zp.areaIdToUiMapId)
area_over = lua_string_table(zp.areaIdToUiMapIdOverride)
sub_parent = lua_string_table(zp.subZoneToParentZoneOverride) if zp.subZoneToParentZoneOverride else {}
dungeons = zp.dungeons if zp.dungeons else None
if dungeons is not None and isinstance(dungeons, str):
    dungeons = lua_string_table(dungeons)

def ltab(t):
    """lupa table -> python dict (shallow); None stays None."""
    if t is None:
        return None
    if not hasattr(t, "items"):
        return t
    return {k: v for k, v in t.items()}

def llist(t):
    if t is None:
        return []
    if not hasattr(t, "items"):
        return [t]
    d = ltab(t)
    return [d[k] for k in sorted(k for k in d if isinstance(k, int))]

area_main = ltab(area_main); area_over = ltab(area_over); sub_parent = ltab(sub_parent) or {}

# dungeon area -> entrance points in its parent zone
dungeon_entr = {}
dungeon_name = {}
if dungeons is not None:
    for aid, entry in ltab(dungeons).items():
        e = ltab(entry)
        if isinstance(e.get(1), str):
            dungeon_name[aid] = e.get(1)
            for alt in llist(e.get(2)):
                dungeon_name.setdefault(alt, e.get(1))
        pts = []
        for triple in llist(e.get(4)):
            c = llist(triple)
            if len(c) >= 3:
                pts.append((c[0], c[1], c[2]))
        dungeon_entr[aid] = pts
        for alt in llist(e.get(2)):
            dungeon_entr.setdefault(alt, pts)

DUNGEON_MAPS = set()
for aid, m in area_over.items():
    if aid in dungeon_entr:
        DUNGEON_MAPS.add(m)

def ui_map(area):
    if area in dungeon_entr and area not in area_main:
        return None
    if area in area_over:
        m = area_over[area]
        if m in (0,) or area in dungeon_entr:
            return None
        return m
    if area in area_main:
        return area_main[area]
    if area in sub_parent:
        return ui_map(sub_parent[area])
    return None

CONTINENTS = {1414, 1415, 947}

# ---------------------------------------------------------------- spawns
MAX_PTS = 24

def pack(x, y):
    xi = int(round(x * 100)); yi = int(round(y * 100))
    return xi * 10001 + yi

def sample(points, n):
    if len(points) <= n:
        return points
    step = len(points) / n
    return [points[int(i * step)] for i in range(n)]

def spawns_of(raw):
    """raw spawn table {areaId = {{x,y},...}} -> {uiMap: [packed,...]}, dungeon name (or False)."""
    out, dungeon = {}, False
    for area, coords in (ltab(raw) or {}).items():
        pts = []
        for c in llist(coords):
            c = llist(c)
            if len(c) < 2 or c[0] is None or c[1] is None:
                continue
            x, y = c[0], c[1]
            if x < 0 or y < 0 or x > 100 or y > 100:
                continue
            pts.append((x, y))
        if area in dungeon_entr:
            dungeon = dungeon_name.get(area, True)
            for zone, x, y in dungeon_entr[area]:
                m = ui_map(zone)
                if m and m not in CONTINENTS:
                    out.setdefault(m, set()).add(pack(x, y))
            continue
        m = ui_map(area)
        if not m or m in CONTINENTS or not pts:
            continue
        s = out.setdefault(m, set())
        for x, y in pts:
            s.add(pack(x, y))
    return {m: sample(sorted(v), MAX_PTS) for m, v in out.items() if v}, dungeon

# ---------------------------------------------------------------- races
RACE_BITS = {1: 1, 2: 2, 3: 4, 4: 8, 5: 16, 6: 32, 7: 64, 8: 128, 95: 1 << 32, 96: 1 << 33}
ALLI = {1, 3, 4, 7, 95}; HORDE = {2, 5, 6, 8, 96}

def races(mask):
    if not mask:
        return None
    ids = {r for r, b in RACE_BITS.items() if mask & b}
    if not ids:
        return None
    if ids >= (ALLI - {95}) | (HORDE - {96}):
        return None
    if ids <= ALLI and ids >= ALLI - {95}:
        return "A"
    if ids <= HORDE and ids >= HORDE - {96}:
        return "H"
    return sorted(ids)

# ---------------------------------------------------------------- quests
Qkeys = {}
need_npc, need_obj, need_item = set(), set(), set()
qout = {}
for qid, row in ltab(quests).items():
    r = ltab(row)
    name = r.get(1)
    if not name or not isinstance(name, str):
        continue
    sb = llist(r.get(2)); fb = llist(r.get(3))
    sN = llist(sb[0]) if len(sb) > 0 else []
    sO = llist(sb[1]) if len(sb) > 1 else []
    eN = llist(fb[0]) if len(fb) > 0 else []
    eO = llist(fb[1]) if len(fb) > 1 else []
    st = ltab(r.get(2)) or {}; ft = ltab(r.get(3)) or {}
    sN = llist(st.get(1)); sO = llist(st.get(2)); sI = llist(st.get(3))
    eN = llist(ft.get(1)); eO = llist(ft.get(2))
    ob = ltab(r.get(10)) or {}
    oN = [llist(o)[0] for o in llist(ob.get(1)) if llist(o)]
    oO = [llist(o)[0] for o in llist(ob.get(2)) if llist(o)]
    oI = [llist(o)[0] for o in llist(ob.get(3)) if llist(o)]
    for kc in llist(ob.get(5)):
        kc = llist(kc)
        if kc:
            oN.extend(llist(kc[0]))
    texts = llist(r.get(8))
    text = (texts[0] if texts and isinstance(texts[0], str) else "") or ""
    if len(text) > 160:
        text = text[:157].rsplit(" ", 1)[0] + "..."
    zone = r.get(17)
    zmap = ui_map(zone) if isinstance(zone, int) and zone > 0 else None
    if zmap in CONTINENTS:
        zmap = None
    # exploration triggers
    trig = None
    te = llist(r.get(9))
    if len(te) >= 2:
        sp, _ = spawns_of(te[1])
        if sp:
            m = next(iter(sp))
            trig = (m, sp[m][0])
    use = []
    if isinstance(r.get(11), int) and r.get(11) > 0: use.append(r.get(11))
    use += [i for i in llist(r.get(21)) if isinstance(i, int)]
    skill = llist(r.get(18))
    q = {
        "name": name, "req": r.get(4) or 0, "lvl": r.get(5) or 0,
        "race": races(r.get(6) or 0), "cls": r.get(7) or 0,
        "sN": sN, "sO": sO, "sI": sI, "eN": eN, "eO": eO,
        "pre": llist(r.get(12)), "preAny": llist(r.get(13)), "excl": llist(r.get(16)),
        "next": r.get(22), "flags": r.get(24) or 0, "zone": zmap,
        "oN": oN, "oO": oO, "oI": oI, "text": text,
        "max": r.get(32), "parent": r.get(25), "crumb": r.get(27),
        "skill": skill[0] if skill else None, "trig": trig, "use": use, "sort": zone if isinstance(zone, int) and zone < 0 else None,
    }
    qout[qid] = q
    need_npc.update(sN, eN, oN); need_obj.update(sO, eO, oO); need_item.update(oI)

# item drop sources for objective items
iout = {}
for iid in sorted(need_item):
    it = ltab(items[iid])
    if not it:
        continue
    n = llist(it.get(2))[:12]; o = llist(it.get(3))[:12]
    if n or o:
        iout[iid] = (it.get(1) or "", n, o)
        need_npc.update(n); need_obj.update(o)

def entity_out(table, ids, name_i, spawn_i, faction_i=None):
    out = {}
    for eid in sorted(ids):
        row = table[eid]
        if row is None:
            continue
        r = ltab(row)
        sp, dun = spawns_of(r.get(spawn_i))
        fac = r.get(faction_i) if faction_i else None
        if not isinstance(fac, str):
            fac = None
        rank = r.get(6) if faction_i else None          # NPCs: 1 elite, 2 rare elite, 3 boss, 4 rare
        lvl = r.get(5) if faction_i else None
        out[eid] = (r.get(name_i) or "", sp, dun, fac,
                    rank if isinstance(rank, int) and rank > 0 else None,
                    lvl if isinstance(lvl, int) and lvl > 0 else None)
    return out

# where to get items: quest rewards, vendors and (for curios like pets, mounts
# and sleeping bags) drops, for "guide me to get this"
src_out = {}
for iid, row in ltab(items).items():
    it = ltab(row)
    if not it:
        continue
    rew = [q for q in llist(it.get(6)) if isinstance(q, int) and q in qout][:6]
    ven = [n for n in llist(it.get(14)) if isinstance(n, int)][:8]
    misc = it.get(12) == 15
    drp = [n for n in llist(it.get(2)) if isinstance(n, int)][:6] if misc else []
    obj = [o for o in llist(it.get(3)) if isinstance(o, int)][:6] if misc else []
    if rew or ven or drp or obj:
        src_out[iid] = (it.get(1) or "", rew, ven, drp, obj)
        need_npc.update(ven); need_npc.update(drp); need_obj.update(obj)

nout = entity_out(npcs, need_npc, 1, 7, 13)
oout = entity_out(objects, need_obj, 1, 4)

# ---------------------------------------------------------------- write
def lstr(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "") + '"'

def llst(v):
    return "{" + ",".join(str(x) for x in v) + "}" if v else "nil"

def lval(v):
    if v is None or v == 0 and False:
        return "nil"
    if isinstance(v, str):
        return lstr(v)
    if isinstance(v, list):
        return llst(v)
    return str(v)

def trim(fields):
    while fields and fields[-1] == "nil":
        fields.pop()
    return ",".join(fields)

HEADER = ("-- Pathway quest data for World of Warcraft: Forever.\n"
          "-- Generated from QuestieDB's Forever data (GPLv3, (c) the Questie team and contributors).\n"
          "-- https://github.com/Questie/QuestieDB  -  do not edit by hand; regenerate with tools/convert.py\n"
          "local _, P = ...\n")

with open(os.path.join(OUT, "Quests.lua"), "w", encoding="utf-8") as f:
    f.write(HEADER)
    f.write("-- name, req, lvl, race, cls, sN, sO, eN, eO, pre, preAny, excl, next, flags, zone, oN, oO, oI, text, max, parent, crumb, skill, trigMap, trigPt, sI, useItems, sort\n")
    f.write("P.Q = {\n")
    for qid in sorted(qout):
        q = qout[qid]
        race = q["race"]
        race_s = "nil" if race is None else (lstr(race) if isinstance(race, str) else llst(race))
        fields = [lstr(q["name"]), str(q["req"]), str(q["lvl"]), race_s, str(q["cls"]) if q["cls"] else "nil",
                  llst(q["sN"]), llst(q["sO"]), llst(q["eN"]), llst(q["eO"]),
                  llst(q["pre"]), llst(q["preAny"]), llst(q["excl"]),
                  str(q["next"]) if q["next"] else "nil", str(q["flags"]) if q["flags"] else "nil",
                  str(q["zone"]) if q["zone"] else "nil",
                  llst(q["oN"]), llst(q["oO"]), llst(q["oI"]),
                  lstr(q["text"]) if q["text"] else "nil",
                  str(q["max"]) if q["max"] else "nil", str(q["parent"]) if q["parent"] else "nil",
                  str(q["crumb"]) if q["crumb"] else "nil", str(q["skill"]) if q["skill"] else "nil",
                  str(q["trig"][0]) if q["trig"] else "nil", str(q["trig"][1]) if q["trig"] else "nil",
                  llst(q["sI"]), llst(q["use"]), str(q["sort"]) if q["sort"] else "nil"]
        f.write("[%d]={%s},\n" % (qid, trim(fields)))
    f.write("}\n")

def write_entities(fname, var, data, with_fac):
    with open(os.path.join(OUT, fname), "w", encoding="utf-8") as f:
        f.write(HEADER)
        f.write("-- name, { [uiMapID] = { packed x*100*10001 + y*100, ... } }, dungeon name (inside a dungeon)%s\n" % (", friendly (A/H/AH), rank (1 elite, 2 rare elite, 3 boss, 4 rare), level" if with_fac else ""))
        f.write("P.%s = {\n" % var)
        for eid, (name, sp, dun, fac, rank, lvl) in data.items():
            spawn = "{" + ",".join("[%d]={%s}" % (m, ",".join(map(str, pts))) for m, pts in sorted(sp.items())) + "}" if sp else "nil"
            fields = [lstr(name), spawn, (lstr(dun) if isinstance(dun, str) else "true") if dun else "nil"]
            if with_fac:
                fields.append(lstr(fac) if fac else "nil")
                fields.append(str(rank) if rank else "nil")
                fields.append(str(lvl) if lvl else "nil")
            f.write("[%d]={%s},\n" % (eid, trim(fields)))
        f.write("}\n")

write_entities("NPCs.lua", "N", nout, True)
write_entities("Objects.lua", "O", oout, False)
with open(os.path.join(OUT, "Items.lua"), "w", encoding="utf-8") as f:
    f.write(HEADER)
    f.write("-- objective items: name, dropped by NPCs, found in objects\n")
    f.write("P.I = {\n")
    for iid, (name, n, o) in iout.items():
        f.write("[%d]={%s},\n" % (iid, trim([lstr(name), llst(n), llst(o)])))
    f.write("}\n")

fm = {}
for nid, row in ltab(npcs).items():
    r = ltab(row)
    flags = r.get(15) or 0
    fac = r.get(13)
    if not isinstance(flags, int) or not (flags & 8) or not isinstance(fac, str):
        continue
    sp, dun = spawns_of(r.get(7))
    if not sp or dun:
        continue
    m = sorted(sp)[0]
    fm[nid] = (r.get(1) or "", m, sp[m][0], fac)
with open(os.path.join(OUT, "Flight.lua"), "w", encoding="utf-8") as f:
    f.write(HEADER)
    f.write("-- flight masters: name, uiMapID, packed position, friendly to (A/H/AH)\n")
    f.write("P.FM = {\n")
    for nid in sorted(fm):
        name, m, pt, fac = fm[nid]
        f.write("[%d]={%s,%d,%d,%s},\n" % (nid, lstr(name), m, pt, lstr(fac)))
    f.write("}\n")
print("flight masters", len(fm))
with open(os.path.join(OUT, "Sources.lua"), "w", encoding="utf-8") as f:
    f.write(HEADER)
    f.write("-- where items come from: name, reward of quests, sold by NPCs, dropped by NPCs (curios), found in objects (curios)\n")
    f.write("P.SRC = {\n")
    for iid in sorted(src_out):
        name, rew, ven, drp, obj = src_out[iid]
        f.write("[%d]={%s},\n" % (iid, trim([lstr(name), llst(rew), llst(ven), llst(drp), llst(obj)])))
    f.write("}\n")
print("item sources", len(src_out))

# collections: companion pets, mounts and curios worth going after (all with a known source)
import re as _re
PET_RE = _re.compile(r"(Carrier|Cage|Crate|Whelpling|Kingsnake|Snake|Owl|Cockroach|Ancona|Chicken Egg|Darter Egg|Frog Box|Prairie Dog|Squirrel|Bombling|Lil' Smoky|Mechanical Toad|Oozeling|Hatchling|Pup)", _re.I)
MOUNT_RE = _re.compile(r"^(Reins of|Horn of the|Whistle of the)|Mechanostrider|Skeletal Horse|Skeletal Warhorse|Kodo$|Ram$|Galestrider|Nightsaber|Outrider Wolf|War Kodo|Kodo$", _re.I)
NOT_PET = _re.compile(r"(Key|Desecrated|Supply Crate|Heavy Crate|Severed|Teeth|Ribcage|Frostwolf Howler)", _re.I)
NOT_MOUNT = _re.compile(r"(Tooth|Fragment|Scale|Hair|Horn of the Dawn)", _re.I)
EXTRA_MOUNTS = {19029}          # Horn of the Frostwolf Howler
CURIOS = {211527}               # Cozy Sleeping Bag
coll = {"pets": [], "mounts": [], "curios": []}
for iid in sorted(src_out):
    it = ltab(ltab(items)[iid])
    if it.get(12) != 15:
        continue
    nm, sc = it.get(1) or "", it.get(13)
    if iid in CURIOS:
        coll["curios"].append(iid)
    elif iid in EXTRA_MOUNTS or ((sc == 5 or MOUNT_RE.search(nm)) and not NOT_MOUNT.search(nm)):
        coll["mounts"].append(iid)
    elif (sc == 2 or PET_RE.search(nm)) and not NOT_PET.search(nm):
        coll["pets"].append(iid)
with open(os.path.join(OUT, "Sources.lua"), "a", encoding="utf-8") as f:
    f.write("-- collections: companion pets, mounts and curios with a known source\n")
    f.write("P.COLL = { pets = {%s}, mounts = {%s}, curios = {%s} }\n" % (
        ",".join(map(str, coll["pets"])), ",".join(map(str, coll["mounts"])), ",".join(map(str, coll["curios"]))))
print("collections", {k: len(v) for k, v in coll.items()})

# services: vendors, repair, trainers, innkeepers, banks, auction houses, stables,
# spirit healers (classic NPC flags), for "find the nearest ..."
SERVICE = 4 | 16 | 32 | 128 | 256 | 4096 | 8192 | 16384
svc = {}
for nid, row in ltab(npcs).items():
    r = ltab(row)
    flags = r.get(15) or 0
    if not isinstance(flags, int) or not (flags & SERVICE):
        continue
    sp, dun = spawns_of(r.get(7))
    if not sp or dun:
        continue
    fac = r.get(13)
    sub = r.get(14)
    pts = []                          # one spot per map (spirit healers stand at every graveyard)
    for m in sorted(sp):
        for pt in (sp[m] if flags & 32 else sp[m][:1]):
            pts += [m, pt]
    svc[nid] = (r.get(1) or "", sub if isinstance(sub, str) else "", flags & SERVICE, pts, fac if isinstance(fac, str) else "")
with open(os.path.join(OUT, "Services.lua"), "w", encoding="utf-8") as f:
    f.write(HEADER)
    f.write("-- service NPCs: name, title, flags (4 vendor, 16 trainer, 32 spirit healer, 128 innkeeper, 256 banker,\n")
    f.write("-- 4096 auctioneer, 8192 stable master, 16384 repair), { uiMapID, packed position, ... }, friendly to (A/H/AH)\n")
    f.write("P.SV = {\n")
    for nid in sorted(svc):
        name, sub, fl, pts, fac = svc[nid]
        f.write("[%d]={%s,%s,%d,{%s}%s},\n" % (nid, lstr(name), lstr(sub), fl, ",".join(map(str, pts)), ("," + lstr(fac)) if fac else ""))
    f.write("}\n")
print("services", len(svc))

# mailboxes (any object called Mailbox), for "find the nearest mailbox"
mb = []
for oid, row in ltab(objects).items():
    r = ltab(row)
    if r.get(1) != "Mailbox":
        continue
    sp, dun = spawns_of(r.get(4))
    if not sp or dun:
        continue
    for m in sorted(sp):
        for pt in sp[m]:
            mb += [m, pt]
with open(os.path.join(OUT, "Services.lua"), "a", encoding="utf-8") as f:
    f.write("-- mailboxes: uiMapID, packed position, ...\n")
    f.write("P.MB = {%s}\n" % ",".join(map(str, mb)))
print("mailboxes", len(mb) // 2)
with_spawn = sum(1 for v in nout.values() if v[1])
print("quests", len(qout), "npcs", len(nout), "with spawns", with_spawn, "objects", len(oout), "items", len(iout))
for fn in ("Quests.lua", "NPCs.lua", "Objects.lua", "Items.lua"):
    print(fn, os.path.getsize(os.path.join(OUT, fn)))
