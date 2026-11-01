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
                              "itemFrom", "playerIDs", "nameRealms", "nameRealm", "seenPlayers", "seenBuilds", "petPrices", "realmGroups", "knownItems", "itemExp", "itemIcon", "petSpots", "petInfo", "itemSpots", "mountStats", "instanceEntrances", "learnedCurios", "lib"],
    "SeviathsCodexDB": ["quests", "loot", "matUses", "items", "qloc", "lootZones", "npcs", "vendors", "beasts", "vendorItems", "rares"],
    "SeviathsDungeonsRaidsDB": ["dungeon", "raid", "delve", "mplus", "quest"],
}
SKIP_FIELDS = {"noGuildT"}
# the big tables are shipped as one short Lua string per record, decoded only when an entry is read (a table per record costs 5 to 10 times
# more memory in the game than its text)
PACK = {("SeviathsCodexDB", k) for k in ("quests", "loot", "matUses", "items")} | {("SeviathsUsefulToolsDB", k) for k in ("knownItems", "learnedDecor")}
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
        for m in re.finditer(r'^;?\(function\(\) (Dp|D)\("(\w+)","(\w+)",', text, re.M):
            v, _ = p.value(m.end())
            db, key = m.group(2), m.group(3)
            if m.group(1) == "Dp":
                v = {k: P(x).value(0)[0] for k, x in v.items()}
            cur = out.setdefault(db, {}).get(key)
            out[db][key] = merge(cur, v) if cur is not None else v
    return out


def main():
    data = read_old()
    files = glob.glob(os.path.join(RETAIL, "WTF", "Account", "*", "SavedVariables", "SeviathsUsefulTools.lua"))
    files += [a for a in sys.argv[1:] if a.endswith(".lua") and os.path.exists(a)]   # extra saved files (older backups) can be added
    if not files:
        sys.exit("no saved data found under " + RETAIL)
    # the saved files of the addons this one grew out of (Codex, Farm Pack, Dungeons & Raids): their data is read too
    old_dir = os.path.dirname(files[0])
    for old in ("SeviathsCodex.lua", "SeviathsCodex.lua.bak", "SeviathsFarmPack.lua", "SeviathsFarmPack.lua.bak",
                "SeviathsDungeonsRaids.lua", "SeviathsDungeonsRaids.lua.bak"):
        p = os.path.join(old_dir, old)
        if os.path.exists(p) and p not in files:
            files.append(p)
    for f in files:
        saved = parse_file(f)
        # the Farm Pack's data is what the Useful Tools database holds now
        if "SeviathsFarmPackDB" in saved:
            saved.setdefault("SeviathsUsefulToolsDB", {})
            for k, v in (saved["SeviathsFarmPackDB"] or {}).items():
                saved["SeviathsUsefulToolsDB"].setdefault(k, v)
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
            packed = (db, key) in PACK
            fn = "Dp" if packed else "D"
            for k, x in v.items():
                s = lua(x)
                if packed:
                    s = esc(s)   # one string per record
                batch[k] = s
                w += (2 if packed else weight(s)) + 1
                if w >= BATCH:
                    lines.append((db, key, ';(function() %s(%s,%s,{%s}) end)()' % (fn, esc(db), esc(key), ",".join(
                        "[%s]=%s" % (esc(a) if isinstance(a, str) else a, b) for a, b in batch.items()))))
                    batch, w = {}, 0
            if batch:
                lines.append((db, key, ';(function() %s(%s,%s,{%s}) end)()' % (fn, esc(db), esc(key), ",".join(
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
    # a table is split into parts of about MAX_FILE bytes (name.key.1.lua, name.key.2.lua ...), so no single file gets huge as the data grows;
    # update_data.py lists whatever files exist in the .toc
    MAX_FILE = 2_500_000
    n_files = 0
    for (db, key), group in by_file.items():
        parts, cur, size = [], [], 0
        for text in group:
            if cur and size + len(text) > MAX_FILE:
                parts.append(cur)
                cur, size = [], 0
            cur.append(text)
            size += len(text)
        if cur:
            parts.append(cur)
        for i, part in enumerate(parts, 1):
            name = "%s.%s%s.lua" % (short.get(db, db), key, ("." + str(i)) if len(parts) > 1 else "")
            path = os.path.join(OUT, name)
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write("-- generated by tools/bake_collected.py: what was collected in the game (%s / %s, part %d of %d)\n" % (db, key, i, len(parts)))
                fh.write("local C = SeviathsUsefulToolsCollected or { data = {} }\nSeviathsUsefulToolsCollected = C\nC.date = %d\nC.packed = C.packed or {}\n" % stamp)
                fh.write("local function Dp(db, key, t)\n  local d = C.packed[db]\n  if not d then d = {}; C.packed[db] = d end\n")
                fh.write("  local cur = d[key]\n  if not cur then d[key] = t return end\n  for k, v in pairs(t) do cur[k] = v end\nend\n")
                fh.write("local function D(db, key, t)\n  local d = C.data[db]\n  if not d then d = {}; C.data[db] = d end\n")
                fh.write("  local cur = d[key]\n  if not cur then d[key] = t return end\n  for k, v in pairs(t) do cur[k] = v end\nend\n")
                for text in part:
                    fh.write(text + "\n")
            total += os.path.getsize(path)
            n_files += 1
    print({db: {k: (len(v) if hasattr(v, "__len__") else 1) for k, v in keys.items()} for db, keys in data.items()})
    print("%s: %d tables in %d files, %.1f MB" % (os.path.abspath(OUT), len(by_file), n_files, total / 1e6))


if __name__ == "__main__":
    main()
