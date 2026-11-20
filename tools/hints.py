# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
#!/usr/bin/env python3
"""Build Pathway/Hints/Hints.lua from RestedXP Guides (CC BY-NC-SA 4.0).

The "where exactly" notes are kept, and short "how to" notes for objectives (inside, upstairs, the cave, the ramp,
behind the hut...), tied to the quest and the spot they belong to. RestedXP's
routing, step order and combat advice are left out: Pathway plans its own route.

usage: tools/hints.py <RXPGuides checkout> <Pathway root>
"""
import re, sys, os, glob

rxp, root = sys.argv[1], sys.argv[2]

# uiMapIDs by zone name (map ids are game facts)
MAPS = {}
for m in re.finditer(r'\["([^"]+)"\]\s*=\s*(\d+)', open(os.path.join(rxp, "DB/classic/db.lua"), encoding="utf-8").read()):
    MAPS.setdefault(m.group(1), int(m.group(2)))
for alias, real in (("StormwindClassic", "Stormwind City"), ("StormwindNew", "Stormwind City"),
                    ("EPLClassic", "Eastern Plaguelands"), ("EPLNew", "Eastern Plaguelands")):
    if real in MAPS: MAPS[alias] = MAPS[real]

PLACE = re.compile(r"\b(inside|indoors|enter|entrance|upstairs|downstairs|up the stairs|down the stairs|stairs|staircase|"
                   r"cave|caves|mine|tunnel|building|house|inn|barn|tower|crypt|tomb|cellar|basement|attic|"
                   r"top floor|second floor|top of|on top|roof|balcony|ramp|bridge|ledge|cliff|hill|ridge|"
                   r"behind|under|underneath|beneath|next to|in front of|on the ground|on the table|table|shelf|"
                   r"crate|barrel|cart|wagon|tent|hut|camp|boat|ship|dock|pier|room|hall|chamber|nook|corner|"
                   r"back of|far end|middle path|left path|right path|jump|patrols?|walks around|wanders|ruins|graveyard|farmhouse|mill|lighthouse|"
                   r"tavern|smithy|forge|stable|dock|statue|fountain|chest|crypt|altar|platform|bottom|top|"
                   r"upper|lower|ground floor|outside|in the water|underwater|island|hidden|behind the)\b", re.I)
NOISE = re.compile(r"\b(grind|sheep|los|line of sight|pull|kite|aoe|frost nova|blizzard|xp|level up|hearth|"
                   r"vendor|repair|train your|skip|abandon|wait for|respawn|careful|dangerous|elite|"
                   r"safespot|loot them for|if you|you can|optional|faster|speedrun|this guide|restedxp|rxp|tip|note|clear|spawns?|reward|questlog|quest log)\b", re.I)


def clean(t):
    t = re.sub(r"::\d+", "", t)
    t = re.sub(r"\|T[^|]*\|t", "", t)
    t = re.sub(r"\|c(?:RXP_[A-Z]+_|[0-9a-fA-F]{8})", "", t)
    t = t.replace("|r", "")
    t = re.sub(r"\[([^\]]*)\]", r"\1", t)
    t = re.sub(r"\s*<<.*$", "", t)
    t = re.sub(r"\s+", " ", t).strip(" .>")
    return t


HOW = re.compile(r"^(kill|loot|use|click|collect|open|escort|follow|protect|defend|gather|pick up|grab|find|look for|get|search|burn|place|plant|fill|dig|free|rescue|destroy|slay|hunt|fish|throw|bring|interact|right click|speak|wait)\b", re.I)
HOW_NOISE = re.compile(r"\b(grind|xp|level up|hearth|vendor|repair|train your|skip|abandon|speedrun|this guide|restedxp|rxp|"
                       r"questlog|quest log|faster|optional|aoe|frost nova|blizzard|kite|pull|line of sight|los|safespot|"
                       r"delete|macro|keybind|addon|bag space|sell|buy)\b", re.I)


def howto(note):
    keep = []
    for s in re.split(r"(?<=[.!])\s+|\s*\|n\s*|\\n", note):
        s = clean(s)
        if len(s) < 8 or len(s) > 110: continue
        if not HOW.search(s) or HOW_NOISE.search(s): continue
        if re.match(r"^(talk to|speak (with|to)) [^ ]+( [^ ]+)?$", s, re.I): continue
        keep.append(s[0].upper() + s[1:])
    return keep


def sentences(note):
    keep = []
    for s in re.split(r"(?<=[.!])\s+|\s*\|n\s*|\\n", note):
        s = clean(s)
        if len(s) < 6 or len(s) > 110: continue
        if not PLACE.search(s) or NOISE.search(s): continue
        if re.match(r"^(accept|turn in|complete|talk to [^ ]+$)", s, re.I): continue
        keep.append(s[0].upper() + s[1:])
    return keep


def parse(path):
    out = []
    txt = open(path, encoding="utf-8", errors="ignore").read()
    zone = None
    for block in re.split(r"\n\s*step\b", txt)[1:]:
        gotos, acts, notes = [], [], []
        for line in block.split("\n"):
            l = line.strip()
            if l.startswith("<<") or l.startswith("#name") or l.startswith("]]"): break
            m = re.match(r"\.goto\s+([^,]+),\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)", l)
            if m:
                z, a, b = m.group(1).strip(), float(m.group(2)), float(m.group(3))
                w = re.match(r"(\d+)/(\d+)$", z)
                if w: gotos.append(("w", int(w.group(2)), a, b))
                elif z in MAPS and 0 <= a <= 100 and 0 <= b <= 100: gotos.append(("m", MAPS[z], a / 100, b / 100))
                continue
            m = re.match(r"\.(accept|turnin|complete)\s+(\d+)(?:\s*,\s*(\d+))?", l)
            if m:
                acts.append((m.group(1), int(m.group(2)), int(m.group(3) or 0)))
                continue
            if l.startswith(">>"):
                notes.append(l[2:])
        if not (acts and notes): continue
        g = gotos[-1] if gotos else None
        hint = []
        for n in notes:
            for s in sentences(n):
                if s not in hint: hint.append(s)
        if hint and g:
            text = ". ".join(hint[:2])
            for kind, q, obj in acts:
                out.append((q, {"accept": "p", "turnin": "t", "complete": "o"}[kind], obj, g, text))
        # how to do an objective ("Kill Defias Thugs. Loot them for Bandanas"): no place needed
        how = []
        for n in notes:
            for s in howto(n):
                if s not in how and s not in hint: how.append(s)
        if how:
            text = ". ".join(how[:2])
            for kind, q, obj in acts:
                if kind == "complete": out.append((q, "h", obj, g or ("w", 0, 0.0, 0.0), text))
    return out


# Forever's own guides first, then classic, Season of Discovery and TBC-era guides
# for the same old-world quests (Outland, Draenei and Blood Elf guides left out)
SKIP = r"Import|farm|Herbalism|Mining|Skinning|Deathknight|Draenei|BloodElf|Boost|Outland|Hellfire|Zangar|Terokkar|Nagrand|Netherstorm|Shadowmoon|Blade|Eversong|Ghostlands|Azuremyst|Bloodmyst|Incursion|Attune"
files = sorted(glob.glob(os.path.join(rxp, "Guides/forever/**/*.lua"), recursive=True))
files += sorted(f for f in glob.glob(os.path.join(rxp, "Guides/*.lua")) if not re.search(SKIP, f))
files += sorted(f for f in glob.glob(os.path.join(rxp, "Guides/SoD/**/*.lua"), recursive=True) if not re.search(SKIP, f))
files += sorted(f for f in glob.glob(os.path.join(rxp, "Guides/tbc/*.lua")) if not re.search(SKIP, f) and re.search(r"A-|H-", os.path.basename(f)))

# only quests Pathway knows (WoW: Forever's quest list)
KNOWN = set(int(m) for m in re.findall(r"^\[(\d+)\]=", open(os.path.join(root, "Data/Quests.lua"), encoding="utf-8").read(), re.M))

def near(a, b):
    if a[0] != b[0] or a[1] != b[1]: return False
    if a[0] == "w": return (a[2] - b[2]) ** 2 + (a[3] - b[3]) ** 2 < 25 * 25
    return (a[2] - b[2]) ** 2 + (a[3] - b[3]) ** 2 < 0.01 ** 2


hints, seen = {}, set()
for f in files:
    for q, kind, obj, g, text in parse(f):
        if q not in KNOWN: continue
        key = (q, kind, obj, text.lower())
        if key in seen: continue
        seen.add(key)
        rows = hints.setdefault(q, [])
        if kind == "h" and any(r[0] == "h" and r[1] == obj for r in rows): continue
        if kind != "h" and any(r[0] == kind and r[1] == obj and near(r[2], g) for r in rows): continue
        rows.append((kind, obj, g, text))


def lua(s): return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


os.makedirs(os.path.join(root, "Hints"), exist_ok=True)
with open(os.path.join(root, "Hints/Hints.lua"), "w", encoding="utf-8", newline="\n") as o:
    o.write("-- Pathway step hints: where exactly a quest's people and things are.\n")
    o.write("-- Taken from RestedXP Guides (https://github.com/RestedXP/RXPGuides) by the RestedXP team,\n")
    o.write("-- licensed CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/).\n")
    o.write("-- Changes: only location and how-to notes are kept, trimmed and re-keyed by quest. This file is shared\n")
    o.write("-- under the same license (see LICENSE.md beside it). Regenerate with tools/hints.py.\n")
    o.write("local _, P = ...\n")
    o.write("-- [quest] = { { kind (p pickup, t turn-in, o objective, h how to do objective), objective, where, text }, ... }\n")
    o.write("-- where: { map, x, y } (0..1 on that map) or { false, instance, wx, wy } (world yards)\n")
    o.write("P.HINTS = {\n")
    n = 0
    for q in sorted(hints):
        rows = []
        for kind, obj, g, text in hints[q]:
            if g[0] == "m": where = "{%d,%.4f,%.4f}" % (g[1], g[2], g[3])
            else: where = "{false,%d,%.1f,%.1f}" % (g[1], g[2], g[3])
            rows.append('{"%s",%d,%s,%s}' % (kind, obj, where, lua(text)))
            n += 1
        o.write("[%d]={%s},\n" % (q, ",".join(rows)))
    o.write("}\n")
print("quests", len(hints), "hints", n)
