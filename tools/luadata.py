"""Small Lua data-table parser (what WoW saves in SavedVariables): tables with ["k"] = v, [n] = v, name = v and positional values.
Tables with only positional values come back as lists, the rest as dicts."""
import re

NUM = re.compile(r"-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")
WORD = re.compile(r"[A-Za-z_]\w*")


class P:
    def __init__(self, text):
        self.t = text
        self.n = len(text)

    def skip(self, p):
        t = self.t
        while p < self.n:
            c = t[p]
            if c in " \t\r\n,;":
                p += 1
            elif c == "-" and t.startswith("--", p):
                p = t.find("\n", p)
                if p < 0:
                    return self.n
            else:
                break
        return p

    def string(self, p):
        t = self.t
        q = t[p]
        j = p + 1
        buf = []
        while t[j] != q:
            if t[j] == "\\":
                j += 1
                c = t[j]
                buf.append({"n": "\n", "t": "\t", "r": "\r"}.get(c, c))
            else:
                buf.append(t[j])
            j += 1
        return "".join(buf), j + 1

    def value(self, p):
        t = self.t
        c = t[p]
        if c == "{":
            return self.table(p)
        if c in "\"'":
            return self.string(p)
        m = NUM.match(t, p)
        if m:
            raw = m.group(0)
            v = float(raw) if ("." in raw or "e" in raw.lower()) else int(raw)
            return v, m.end()
        m = WORD.match(t, p)
        raw = m.group(0)
        return {"true": True, "false": False, "nil": None}.get(raw, raw), m.end()

    def table(self, p):
        t = self.t
        p += 1
        d, lst = {}, []
        while True:
            p = self.skip(p)
            if t[p] == "}":
                p += 1
                break
            key = None
            if t[p] == "[":
                p = self.skip(p + 1)
                key, p = self.value(p)
                p = self.skip(p)
                assert t[p] == "]", t[p:p + 30]
                p = self.skip(p + 1)
                assert t[p] == "=", t[p:p + 30]
                p += 1
            else:
                m = WORD.match(t, p)
                if m:
                    q = self.skip(m.end())
                    if t[q] == "=" and t[q + 1] != "=":
                        key = m.group(0)
                        p = q + 1
            p = self.skip(p)
            v, p = self.value(p)
            if key is None:
                lst.append(v)
            else:
                d[key] = v
        if lst and not d:
            return lst, p
        for i, v in enumerate(lst):
            d[i + 1] = v
        return d, p


def parse_file(path):
    """{global name: value} of a SavedVariables file."""
    text = open(path, encoding="utf-8", errors="replace").read()
    out = {}
    for m in re.finditer(r"^(\w+) = ", text, re.M):
        v, _ = P(text).value(m.end())
        out[m.group(1)] = v
    return out
