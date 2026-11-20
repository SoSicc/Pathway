# Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
"""Build the shipped add-on from Pathway's source files.

Pathway is written as many small files (Core.lua, Engine.lua, GoodMap/GoodMap.lua...).
The add-on ships them joined into three: Data.lua, Pathway.lua and Modules.lua, so the
add-on folder stays tidy. Hints/ and WoWPro/ are other people's work under their own
licenses and ship exactly as they are.

Each source file runs inside its own function, exactly as the game ran it as a file:
the same locals, the same early returns, the same "..." (add-on name, namespace), in
the same order. A table at the top of each bundle records where every part starts, so
error lines and the performance meter can still name the original file and line.

Usage: python3 -I bundle.py <source dir> <output dir>
       python3 -I bundle.py --split <add-on dir> <source dir>   (the separate files back again)
"""
import os, re, shutil, sys

HEADER = ("-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software "
          "under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.")
VARARG_RE = re.compile(r"^(local [A-Za-z_][A-Za-z_0-9]*[ \t]*,[ \t]*[A-Za-z_][A-Za-z_0-9]*[ \t]*)=[ \t]*\.\.\.[ \t]*$", re.M)



DESCRIBE = {
    "Data.lua": "Quest, NPC, object, item and flight data, generated from QuestieDB's Forever data (GPLv3, (c) the Questie team and contributors) by tools/convert.py and friends.",
    "Pathway.lua": "The core: quests, routes, trips, the guide, the arrow, map pins and everything they lean on.",
    "Modules.lua": "Setup, journal, talents, outfits, Go to, the bags, the minimap (GoodMap and its ride effects), fishing and settings.",
}


def main(src, out):
    toc_path = os.path.join(src, "Pathway.toc")
    lines = open(toc_path, encoding="utf-8").read().split("\n")
    files = [l.strip() for l in lines if l.strip() and not l.startswith("#") and l.strip().endswith(".lua")]
    meta = [l for l in lines if l.startswith("#")]

    # Pathway's own files before the WoW-Pro guides go in Pathway.lua, those after in Modules.lua;
    # the data goes first (it only fills tables, nothing reads it while loading)
    plan, seen_guides = [], False
    for f in files:
        p = f.replace("\\", "/")
        if p.startswith("WoWPro/"):
            seen_guides = True
            plan.append((None, f))
        elif p.startswith("Hints/"):
            plan.append((None, f))
        elif p.startswith("Data/"):
            plan.append(("Data.lua", f))
        else:
            plan.append(("Modules.lua" if seen_guides else "Pathway.lua", f))

    bundles = {}
    for b, f in plan:
        if b:
            bundles.setdefault(b, []).append(f)

    if os.path.exists(out):
        shutil.rmtree(out)
    # everything that isn't a bundled Lua file ships as it is
    bundled = set(f.replace("\\", "/") for b, f in plan if b)
    for root, dirs, fnames in os.walk(src):
        rel_root = os.path.relpath(root, src)
        for fn in fnames:
            rel = os.path.normpath(os.path.join(rel_root, fn)).replace("\\", "/")
            if rel in bundled or rel == "Pathway.toc":
                continue
            dst = os.path.join(out, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(os.path.join(root, fn), dst)

    for name, parts in bundles.items():
        body, sections = [], []
        HEAD_LINES = 5          # the lines written before the first part (fixed)
        line = HEAD_LINES + 1
        for f in parts:
            text = open(os.path.join(src, f.replace("\\", "/")), encoding="utf-8").read()
            text = text.replace("\r\n", "\n")
            if not text.endswith("\n"):
                text += "\n"
            # the file's "local ADDON, P = ..." takes the add-on's two values from its part instead,
            # so the part needs no "..." of its own (in Lua 5.1 that costs a hidden local, and a
            # file can already be at the 200-local limit)
            text, n = VARARG_RE.subn(r"\1= __addon, __ns", text, count=1)
            if n != 1:      # (any other top-level "..." is a compile error, which the build's compile check catches)
                raise SystemExit("bundle: %s has no 'local X, Y = ...' line for its add-on values" % f)
            label = f.replace("\\", "/")[:-4]
            body.append("-- " + "=" * 20 + " " + label + ".lua\n")
            body.append("do local __addon, __ns = ... local function part()\n")
            sections.append((line + 2, label))           # its first line in the bundle
            body.append(text)
            body.append("end part() end\n")
            line += 2 + text.count("\n") + 1
        table = ", ".join('%d, "%s"' % (start, label) for start, label in sections)
        head = [
            HEADER + "\n",
            "-- Pathway: " + DESCRIBE.get(name, "") + "\n",
            "-- Built from %d source files by tools/bundle.py; each part runs as its own file did, in the same order.\n" % len(parts),
            "local _, P = ...; P.SECTIONS = P.SECTIONS or {}\n",
            'P.SECTIONS["%s"] = { %s }\n' % (name, table),
        ]
        assert len(head) == HEAD_LINES
        with open(os.path.join(out, name), "w", encoding="utf-8", newline="\n") as fh:
            fh.write("".join(head + body))

    # the shipped toc: same metadata, the bundles in place of their parts
    out_files, done = [], set()
    for b, f in plan:
        if b is None:
            out_files.append(f)
        elif b not in done:
            done.add(b)
            out_files.append(b)
    # Data.lua first
    out_files.sort(key=lambda f: 0 if f == "Data.lua" else 1)
    with open(os.path.join(out, "Pathway.toc"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(meta) + "\n\n" + "\n".join(out_files) + "\n")
    # the source files' own toc rides along, so --split can put everything back exactly
    os.makedirs(os.path.join(out, "tools"), exist_ok=True)
    shutil.copy2(toc_path, os.path.join(out, "tools", "Pathway.src.toc"))
    print("bundled:", {k: len(v) for k, v in bundles.items()}, "toc entries:", len(out_files))


def split(addon, out):
    """The bundles back into their source files, exactly."""
    for name in ("Data.lua", "Pathway.lua", "Modules.lua"):
        path = os.path.join(addon, name)
        if not os.path.exists(path):
            continue
        lines = open(path, encoding="utf-8").read().split("\n")
        label, body = None, None
        for ln in lines:
            if label is None:
                m = re.match(r"^-- =+ (.+)\.lua$", ln)
                if m:
                    label = m.group(1)
                continue
            if body is None:
                body = []                         # the "do local __addon..." line
                continue
            if ln == "end part() end":
                text = "\n".join(body) + "\n"
                text = text.replace("= __addon, __ns", "= ...", 1)
                dst = os.path.join(out, label + ".lua")
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                open(dst, "w", encoding="utf-8", newline="\n").write(text)
                label, body = None, None
                continue
            body.append(ln)
    for root, dirs, fnames in os.walk(addon):
        for fn in fnames:
            rel = os.path.relpath(os.path.join(root, fn), addon)
            if rel in ("Data.lua", "Pathway.lua", "Modules.lua", "Pathway.toc"):
                continue
            dst = os.path.join(out, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(os.path.join(root, fn), dst)
    shutil.copy2(os.path.join(addon, "tools", "Pathway.src.toc"), os.path.join(out, "Pathway.toc"))
    os.remove(os.path.join(out, "tools", "Pathway.src.toc"))
    print("split into", out)


if __name__ == "__main__":
    if sys.argv[1] == "--split":
        split(sys.argv[2], sys.argv[3])
    else:
        main(sys.argv[1], sys.argv[2])
