"""Bakes Data/MountGuide.lua: where each Battle for Azeroth mount comes from, and what it costs (gold or a special token / currency).

Source: Wowhead's "Battle for Azeroth Mount Guide" (https://www.wowhead.com/guide/mount-collecting-battle-for-azeroth), whose tables ("Mount<TAB>Source")
were saved as text in tools/bfa_mounts.txt (read in a browser).
Output: SFP.MountGuide["Mount name"] = "source text"
Run: python tools/bake_mount_guide.py
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ADDON = os.path.dirname(HERE)
guide = {}
for line in open(os.path.join(HERE, "bfa_mounts.txt"), encoding="utf8"):
    if "\t" not in line:
        continue
    name, _, src = line.rstrip("\n").partition("\t")
    name = re.sub(r"\s+", " ", name).strip()
    src = re.sub(r"\s+", " ", src).strip()
    name = re.sub(r"\s*\((Horde|Alliance) Only\)", "", name)
    if not name or not src or name == "Mount" or src == "Source":
        continue
    guide.setdefault(name, src)
out = ["-- SeviathsUsefulTools - where Battle for Azeroth mounts come from and what they cost (made by tools/bake_mount_guide.py from Wowhead's guide)",
       "", "local _, SFP = ...", "", "SFP.MountGuide = {"]
for name in sorted(guide):
    out.append('    ["%s"] = "%s",' % (name.replace('"', '\\"'), guide[name].replace("\\", "\\\\").replace('"', '\\"')))
out.append("}")
open(os.path.join(ADDON, "Data", "MountGuide.lua"), "w", encoding="utf8", newline="\n").write("\n".join(out) + "\n")
print(len(guide), "mounts")
