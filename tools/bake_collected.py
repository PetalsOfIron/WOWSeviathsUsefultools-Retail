"""Bakes Data/Collected.lua: everything the addon collected (players, nameplates, inspects, Raider.IO answers, guilds, NPCs, quests,
loot, materials, towns, spots ...), so the addon uploaded to CurseForge carries it and every player who installs it starts with that data.

    python tools/bake_collected.py            (then upload the addon folder; no /reload needed)

Reads your saved data (WTF/.../SavedVariables/SeviathsUsefulTools.lua) and the file it wrote last time and keeps both: your newer data wins
on the same entry, nothing is lost between bakes. In the game the data is merged into what a player already has (CollectedImport.lua):
world data is overwritten by these values, player records keep the newer one.

What is left out on purpose: your settings, window places, characters/alts, history, and the auction prices (they are old the moment they
are saved).
"""
import glob
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.setrecursionlimit(20000)
from luadata import P, parse_file   # noqa: E402

OUT = os.path.join(HERE, "..", "collected")   # one file per saved table
RETAIL = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))

# which saved tables are shipped: { saved global: [keys] }
SHIP = {
    "SeviathsUsefulToolsDB": ["seenInfo", "inspected", "rioCache", "guildDir", "nameplateText", "npcs", "learned", "learnedDecor",
                              "vendorLearned", "itemZones", "hiddenSpots", "bestSpots", "objects", "towns", "npcPos", "killPos",
                              "itemFrom", "playerIDs", "nameRealms", "nameRealm", "seenPlayers", "seenBuilds", "realmGroups", "knownItems", "learnedCurios", "lib"],
    "SeviathsCodexDB": ["quests", "loot", "matUses", "items", "qloc", "lootZones", "npcs", "vendors", "beasts", "vendorItems", "rares"],
    "SeviathsDungeonsRaidsDB": ["dungeon", "raid", "delve", "mplus", "quest"],
}
SKIP_FIELDS = {"noGuildT"}
BATCH = 40000   # constants per generated function (Lua allows 262143 per function)


def merge(old, new):
    """new wins on the same entry/field; everything only in old stays."""
    if isinstance(old, dict) and isinstance(new, dict):
        out = dict(old)
        for k, v in new.items():
            out[k] = merge(old[k], v) if k in old else v
        return out
    return new


def esc(s):
    return '"%s"' % str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "")


def lua(v):
    if isinstance(v, dict):
        parts = []
        for k, x in v.items():
            if k in SKIP_FIELDS or x is None:
                continue
            parts.append("[%s]=%s" % (esc(k) if isinstance(k, str) else k, lua(x)))
        return "{" + ",".join(parts) + "}"
    if isinstance(v, list):
        return "{" + ",".join(lua(x) for x in v if x is not None) + "}"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return ("%.4f" % v).rstrip("0").rstrip(".") or "0"
    if isinstance(v, int):
        return str(v)
    return esc(v)


def weight(s):
    return s.count(",") + 2


def read_old():
    """The tables of the files written last time: { db: { key: value } }."""
    out = {}
    import re
    for path in sorted(glob.glob(os.path.join(OUT, "*.lua"))):
        text = open(path, encoding="utf-8").read()
        p = P(text)
        for m in re.finditer(r'^;?\(function\(\) D\("(\w+)","(\w+)",', text, re.M):
            v, _ = p.value(m.end())
            db, key = m.group(1), m.group(2)
            cur = out.setdefault(db, {}).get(key)
            out[db][key] = merge(cur, v) if cur is not None else v
    return out


def main():
    data = read_old()
    files = glob.glob(os.path.join(RETAIL, "WTF", "Account", "*", "SavedVariables", "SeviathsUsefulTools.lua"))
    files += [a for a in sys.argv[1:] if a.endswith(".lua") and os.path.exists(a)]   # extra saved files (older backups) can be added
    if not files:
        sys.exit("no saved data found under " + RETAIL)
    for f in files:
        saved = parse_file(f)
        for db, keys in SHIP.items():
            for key in keys:
                v = (saved.get(db) or {}).get(key)
                if isinstance(v, (dict, list)) and v:
                    cur = data.setdefault(db, {}).get(key)
                    data[db][key] = merge(cur, v) if cur is not None else v
    stamp = int(time.time())
    lines = []
    for db, keys in data.items():
        for key, v in keys.items():
            if not isinstance(v, dict):
                lines.append((db, key, ';(function() D(%s,%s,%s) end)()' % (esc(db), esc(key), lua(v))))
                continue
            batch, w = {}, 0
            for k, x in v.items():
                s = lua(x)
                batch[k] = s
                w += weight(s) + 1
                if w >= BATCH:
                    lines.append((db, key, ';(function() D(%s,%s,{%s}) end)()' % (esc(db), esc(key), ",".join(
                        "[%s]=%s" % (esc(a) if isinstance(a, str) else a, b) for a, b in batch.items()))))
                    batch, w = {}, 0
            if batch:
                lines.append((db, key, ';(function() D(%s,%s,{%s}) end)()' % (esc(db), esc(key), ",".join(
                    "[%s]=%s" % (esc(a) if isinstance(a, str) else a, b) for a, b in batch.items()))))
    os.makedirs(OUT, exist_ok=True)
    for old in glob.glob(os.path.join(OUT, "*.lua")):
        if not os.path.basename(old).startswith("gold."):   # the prices are kept by bake_gold.py
            os.remove(old)
    short = {"SeviathsUsefulToolsDB": "tools", "SeviathsCodexDB": "codex", "SeviathsDungeonsRaidsDB": "dungeonsraids"}
    total = 0
    by_file = {}
    for db, key, text in lines:
        by_file.setdefault((db, key), []).append(text)
    for (db, key), group in by_file.items():
        name = "%s.%s.lua" % (short.get(db, db), key)
        path = os.path.join(OUT, name)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("-- generated by tools/bake_collected.py: what was collected in the game (%s / %s)\n" % (db, key))
            fh.write("local C = SeviathsUsefulToolsCollected or { data = {} }\nSeviathsUsefulToolsCollected = C\nC.date = %d\n" % stamp)
            fh.write("local function D(db, key, t)\n  local d = C.data[db]\n  if not d then d = {}; C.data[db] = d end\n")
            fh.write("  local cur = d[key]\n  if not cur then d[key] = t return end\n  for k, v in pairs(t) do cur[k] = v end\nend\n")
            for text in group:
                fh.write(text + "\n")
        total += os.path.getsize(path)
    print({db: {k: (len(v) if hasattr(v, "__len__") else 1) for k, v in keys.items()} for db, keys in data.items()})
    print("%s: %d files, %.1f MB" % (os.path.abspath(OUT), len(by_file), total / 1e6))


if __name__ == "__main__":
    main()
