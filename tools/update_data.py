"""Bakes the collected data, pushes it to the data repo, and makes the CurseForge zip.

    python tools/update_data.py            bake + push the data to GitHub (PetalsOfIron/Data-wow) + build the zip
    python tools/update_data.py --no-zip   bake + push only

1. tools/bake_collected.py writes the collected folder from your saved data (and keeps what earlier bakes had).
2. The collected folder is copied to the clone of the data repo (C:/Users/<you>/Projects/Data-wow), committed and pushed.
3. The addon folder is copied to C:/Users/<you>/Projects/sut-curse-release/SeviathsUsefulTools (without .git, .github, .gitignore, tools and
   backup files) and zipped next to it: that zip is the one file to upload to CurseForge.
Run it after a play session, after the game is closed or after /reload (the game writes the saved data then).
"""
import glob
import os
import shutil
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ADDON = os.path.abspath(os.path.join(HERE, ".."))
HOME = os.path.expanduser("~")
DATA_REPO = os.path.join(HOME, "Projects", "Data-wow")
CURSE = os.path.join(HOME, "Projects", "sut-curse-release")
SKIP_DIRS = {".git", ".github", "tools"}
SKIP_FILES = {".gitignore", ".gitattributes"}


def run(*args, cwd=None):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr).strip()


def version():
    for line in open(os.path.join(ADDON, "SeviathsUsefulTools.toc"), encoding="utf-8"):
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    return "x"


def sync_toc():
    """The .toc lists every file of the collected folder (the game loads only what is listed)."""
    toc = os.path.join(ADDON, "SeviathsUsefulTools.toc")
    raw = open(toc, "rb").read().decode("utf-8")
    nl = chr(13) + chr(10) if chr(13) + chr(10) in raw else chr(10)
    keep = [l for l in raw.split(nl) if not l.startswith("collected" + chr(92))]
    names = sorted(f for f in os.listdir(os.path.join(ADDON, "collected")) if f.endswith(".lua"))
    at = next(i for i, l in enumerate(keep) if l.strip() == "CollectedImport.lua")
    keep[at:at] = ["collected" + chr(92) + n for n in names]
    open(toc, "wb").write(nl.join(keep).encode("utf-8"))
    print("toc: %d collected files" % len(names))


def load_check():
    """Loads the shipped data and the player's saved data the way the game does (offline, with a Lua interpreter) before anything is pushed:
    a data file that would not load in the game stops the push. Needs node with the fengari package (see tools/load_test.js)."""
    saved = glob.glob(os.path.join(os.path.abspath(os.path.join(HERE, "..", "..", "..", "..")), "WTF", "Account", "*", "SavedVariables", "SeviathsUsefulTools.lua"))
    modules = os.path.join(os.environ.get("TEMP", ""), "lchk", "node_modules")
    if not (saved and os.path.isdir(modules)):
        print("load check: skipped (no saved data or no fengari)")
        return True
    env = dict(os.environ, NODE_PATH=modules)
    r = subprocess.run(["node", "--max-old-space-size=8192", os.path.join(HERE, "load_test.js"), ADDON, saved[0]],
                       capture_output=True, text=True, env=env)
    ok = r.returncode == 0 and "done, total" in r.stdout
    print("load check:", "passed" if ok else "FAILED")
    if not ok:
        print((r.stdout + r.stderr)[-1500:])
    return ok


def push_data():
    if not os.path.isdir(os.path.join(DATA_REPO, ".git")):
        sys.exit("clone https://github.com/PetalsOfIron/Data-wow.git to " + DATA_REPO + " first")
    dst = os.path.join(DATA_REPO, "collected")
    shutil.rmtree(dst, ignore_errors=True)
    shutil.copytree(os.path.join(ADDON, "collected"), dst)
    readme = os.path.join(HERE, "README-FOR-CLAUDE.md")   # the recovery notes also live in the data repo (outside the addon zip)
    if os.path.exists(readme):
        shutil.copy2(readme, os.path.join(DATA_REPO, "README-FOR-CLAUDE.md"))
    run("git", "add", "-A", cwd=DATA_REPO)
    code, out = run("git", "diff", "--cached", "--quiet", cwd=DATA_REPO)
    if code == 0:
        print("data repo: nothing new")
        return
    msg = "Collected data update\n\nCo-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
    print(run("git", "commit", "-q", "-m", msg, cwd=DATA_REPO)[1])
    print(run("git", "push", "origin", "main", cwd=DATA_REPO)[1] or "data repo: pushed")


GITDIR = os.path.join(HOME, "Projects", "sut-retail-gitdir")   # the addon's git folder is kept outside the addon folder


def push_addon():
    """Commits and pushes the addon itself (with the fresh collected folder) to its GitHub repo."""
    if not os.path.isdir(GITDIR):
        print("addon repo: git folder not found, not pushed")
        return
    base = ["git", "--git-dir=" + GITDIR, "--work-tree=" + ADDON]
    run(*base, "add", "-A")
    code, _ = run(*base, "diff", "--cached", "--quiet")
    if code == 0:
        print("addon repo: nothing new")
        return
    msg = "Auto update: collected data and addon files" + chr(10) + chr(10) + "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
    print(run(*base, "-c", "user.name=santamadaraneilande-ctrl", "-c", "user.email=santamadaraneilande@gmail.com",
              "commit", "-q", "-m", msg)[1])
    print(run(*base, "push", "origin", "main")[1] or "addon repo: pushed")


def build_zip():
    target = os.path.join(CURSE, "SeviathsUsefulTools")
    shutil.rmtree(target, ignore_errors=True)
    os.makedirs(CURSE, exist_ok=True)

    def ignore(folder, names):
        out = []
        for n in names:
            p = os.path.join(folder, n)
            if os.path.isdir(p) and n in SKIP_DIRS and folder == ADDON:
                out.append(n)
            elif os.path.isfile(p) and (n in SKIP_FILES or n.endswith(".bak")):
                out.append(n)
        return out

    shutil.copytree(ADDON, target, ignore=ignore)
    zpath = os.path.join(CURSE, "SeviathsUsefulTools-%s.zip" % version())
    if os.path.exists(zpath):
        os.remove(zpath)
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(target):
            for f in files:
                full = os.path.join(root, f)
                z.write(full, os.path.relpath(full, CURSE))
    print("zip: %s (%.1f MB)" % (zpath, os.path.getsize(zpath) / 1e6))
    # only the zip goes to the folder you upload from (older zips there are replaced)
    out = os.path.join(HOME, "Downloads", "curse")
    os.makedirs(out, exist_ok=True)
    for old in os.listdir(out):
        if old.lower().endswith(".zip") and old.startswith("SeviathsUsefulTools"):
            os.remove(os.path.join(out, old))
    shutil.copy2(zpath, out)
    print("copied to " + out)


if __name__ == "__main__":
    print(run(sys.executable, os.path.join(HERE, "bake_collected.py"))[1].splitlines()[-1])
    print(run(sys.executable, os.path.join(HERE, "bake_gold.py"))[1])
    sync_toc()
    if not load_check():
        sys.exit("the data did not load in the check: nothing was pushed")
    push_data()
    push_addon()
    if "--no-zip" not in sys.argv:
        build_zip()
