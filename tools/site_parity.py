#!/usr/bin/env python3
"""Compare two folders written by game/tools/site_dump.gd (a landmark refactor's parity proof).

    python3 -I tools/site_parity.py BEFORE AFTER [--eps=0.06] [--allow=key,key] [--unordered]

For every site: `same` (bit for bit), `near` (same triangle count and order, every float within
--eps: positions in metres, colours and normals as they are), or `DIFF`. Exit 0 when every site is
`same`, or `near`/`DIFF` only for the sites named in --allow (the ones a change means to touch);
exit 1 otherwise. A site in only one folder is always a failure.

--unordered: a site that is not `same` is matched triangle by triangle in any order. Each
triangle needs a twin of its own in the other folder with the same colour, normal and material
code (within 0.004) and its three corners within --eps (in any rotation). When every triangle on
both sides has one, the site is `twin` and passes without --allow: the change redrew the same
things in another order, moved by less than --eps. Triangles without a twin are printed (the
first few) and the site is `DIFF`.
"""
import os
import struct
import sys

FLOATS = 14  # per vertex: position 3, normal 3, colour 4, uv 2, uv2 2
NAMES = ["x", "y", "z", "nx", "ny", "nz", "r", "g", "b", "a", "u", "v", "mode", "top"]


def load(path):
    with open(path, "rb") as f:
        raw = f.read()
    return raw, struct.unpack("<%df" % (len(raw) // 4), raw)


def triangles(f):
    """(centroid, corners, key) per triangle; key = colour, normal and material code, rounded."""
    out = []
    for t in range(len(f) // (FLOATS * 3)):
        v = [f[(t * 3 + k) * FLOATS:(t * 3 + k + 1) * FLOATS] for k in range(3)]
        corners = [c[0:3] for c in v]
        cen = tuple(sum(c[d] for c in corners) / 3.0 for d in range(3))
        out.append((cen, corners, v[0][3:10] + (v[0][12],)))
    return out


def close(a, b, eps):
    return abs(a[0] - b[0]) <= eps and abs(a[1] - b[1]) <= eps and abs(a[2] - b[2]) <= eps


def distance(ta, tb, eps):
    """How far apart two triangles are (the worst corner, in the best rotation); None: no twin."""
    if any(abs(x - y) > 0.004 for x, y in zip(ta[2], tb[2])):
        return None
    ca, cb = ta[1], tb[1]
    best = None
    for order in ((0, 1, 2), (1, 2, 0), (2, 0, 1), (0, 2, 1), (2, 1, 0), (1, 0, 2)):
        if all(close(ca[k], cb[order[k]], eps) for k in range(3)):
            worst = max(abs(ca[k][d] - cb[order[k]][d]) for k in range(3) for d in range(3))
            if best is None or worst < best:
                best = worst
    return best


def twins(fa, fb, eps):
    """Pair the triangles of fa and fb one to one; returns the unpaired of both sides.

    Nearest free twin first, then augmenting paths (Kuhn) for what is left: thin parts a few
    centimetres apart (the bars of a balcony) have several possible twins each.
    """
    cell = max(eps * 4.0, 0.25)
    ta, tb = triangles(fa), triangles(fb)
    grid = {}
    for i, t in enumerate(tb):
        grid.setdefault(tuple(int(c // cell) for c in t[0]), []).append(i)

    def candidates(t):
        base = tuple(int(c // cell) for c in t[0])
        out = []
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for i in grid.get((base[0] + dx, base[1] + dy, base[2] + dz), ()):
                        d = distance(t, tb[i], eps)
                        if d is not None:
                            out.append((d, i))
        out.sort()
        return [i for _, i in out]

    owner = [-1] * len(tb)  # which triangle of fa holds each triangle of fb
    cands = {}
    left = []
    for k, t in enumerate(ta):
        for i in candidates(t):
            if owner[i] < 0:
                owner[i] = k
                break
        else:
            left.append(k)

    def place(k, seen):
        if k not in cands:
            cands[k] = candidates(ta[k])
        for i in cands[k]:
            if i in seen:
                continue
            seen.add(i)
            if owner[i] < 0 or place(owner[i], seen):
                owner[i] = k
                return True
        return False

    sys.setrecursionlimit(max(10000, sys.getrecursionlimit()))
    lost = [ta[k] for k in left if not place(k, set())]
    return lost, [t for i, t in enumerate(tb) if owner[i] < 0]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    eps = 0.06
    allow = set()
    unordered = "--unordered" in sys.argv[1:]
    for a in sys.argv[1:]:
        if a.startswith("--eps="):
            eps = float(a[6:])
        elif a.startswith("--allow="):
            allow = set(a[8:].split(","))
    if len(args) != 2:
        print(__doc__)
        return 2
    before, after = args
    keys_a = {n for n in os.listdir(before) if n.endswith(".bin")}
    keys_b = {n for n in os.listdir(after) if n.endswith(".bin")}
    bad = []
    counts = {"same": 0, "near": 0, "twin": 0, "DIFF": 0}
    for name in sorted(keys_a | keys_b):
        key = name[:-4]
        if name not in keys_a or name not in keys_b:
            bad.append("%s: only in %s" % (key, before if name in keys_a else after))
            continue
        raw_a, fa = load(os.path.join(before, name))
        raw_b, fb = load(os.path.join(after, name))
        if raw_a == raw_b:
            counts["same"] += 1
            continue
        if len(fa) == len(fb):
            worst = 0.0
            where = 0
            for i, (x, y) in enumerate(zip(fa, fb)):
                d = abs(x - y)
                if d > worst:
                    worst, where = d, i
            verdict = "near" if worst <= eps else "DIFF"
            detail = "largest difference %.5f in %s of vertex %d" % (worst, NAMES[where % FLOATS], where // FLOATS)
        else:
            verdict = "DIFF"
            detail = "%d triangles before, %d after" % (len(fa) // FLOATS // 3, len(fb) // FLOATS // 3)
        if unordered and verdict == "DIFF":
            lost, extra = twins(fa, fb, eps)
            if not lost and not extra:
                verdict = "twin"
                detail = "%d triangles, each with a twin within %.2f m" % (len(fb) // FLOATS // 3, eps)
            else:
                detail += "; %d triangles gone, %d new" % (len(lost), len(extra))
                for name2, group in (("gone", lost), ("new", extra)):
                    for t in group[:4]:
                        print("      %s at (%.2f, %.2f, %.2f) colour (%.2f, %.2f, %.2f) code %.2f" % (
                            (name2,) + t[0] + t[2][3:6] + (t[2][7],)))
        counts[verdict] += 1
        print("%-5s %-24s %s" % (verdict, key, detail))
        if key not in allow and verdict != "twin":
            bad.append("%s: %s (%s)" % (key, verdict, detail))
    for extra in ("_signs.txt",):
        pa, pb = os.path.join(before, extra), os.path.join(after, extra)
        if os.path.exists(pa) and os.path.exists(pb) and open(pa, "rb").read() != open(pb, "rb").read():
            bad.append("%s differs" % extra)
    print("site_parity: %d same, %d near, %d DIFF" % (counts["same"], counts["near"], counts["DIFF"])
          + (", %d twin" % counts["twin"] if unordered else ""))
    if bad:
        print("site_parity: %d problems" % len(bad))
        for b in bad:
            print("  " + b)
        return 1
    print("site_parity: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
