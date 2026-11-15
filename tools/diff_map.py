"""Compare two baked centrum.json files key by key.

Usage: python3 -I tools/diff_map.py A.json B.json [--keys=a,b] [--examples=N] [--quiet]

Prints one row per top-level key: kind, how many elements each side has, how many of A's
elements have no identical element in B ("only A") and the other way ("only B"), and
"same" / "DIFF". Elements are compared as a multiset of their canonical JSON, so a pure
reordering shows as "order" (same multiset, different sequence). `--examples=N` prints up to N
elements of each side's difference. Exit 0 when every key is identical, 1 otherwise.
The from-scratch comparison (Mac, data/raw present, about 10 minutes):
    cp game/map/centrum.json /tmp/main_centrum.json
    python3 -I tools/bake_osm.py data/work/demo/osm_demo.json data/work/demo/osm_demo.json game/map/centrum.json \\
        data/work/demo/osm_demo.json data/work/demo/osm_demo.json > /tmp/osm2.log
    python3 -I tools/diff_map.py /tmp/main_centrum.json game/map/centrum.json --quiet
    git checkout game/map/centrum.json        # derived files are never committed
Scalars and dicts of scalars are compared by value; dicts of lists are compared per sub-key.
"""
import collections
import json
import sys


def canon(v):
    return json.dumps(v, sort_keys=True, separators=(",", ":"))


def multiset(lst):
    return collections.Counter(canon(e) for e in lst)


def compare(a, b, ex):
    """Returns (kind, na, nb, only_a, only_b, status)."""
    if isinstance(a, list) and isinstance(b, list):
        ma, mb = multiset(a), multiset(b)
        oa, ob = ma - mb, mb - ma
        n_a, n_b = sum(oa.values()), sum(ob.values())
        if not n_a and not n_b:
            return "list", len(a), len(b), 0, 0, "same" if a == b else "order", [], []
        return "list", len(a), len(b), n_a, n_b, "DIFF", list(oa)[:ex], list(ob)[:ex]
    if isinstance(a, dict) and isinstance(b, dict):
        same = canon(a) == canon(b)
        return "dict", len(a), len(b), 0, 0, "same" if same else "DIFF", [], []
    same = canon(a) == canon(b)
    return "scalar", 1, 1, 0, 0, "same" if same else "DIFF", ([canon(a)[:200]] if not same else []), ([canon(b)[:200]] if not same else [])


def main(argv):
    args = [x for x in argv if not x.startswith("--")]
    opts = dict(x[2:].split("=", 1) if "=" in x else (x[2:], "1") for x in argv if x.startswith("--"))
    if len(args) != 2:
        print(__doc__)
        return 2
    a, b = (json.load(open(p)) for p in args)
    ex = int(opts.get("examples", 0))
    keys = opts["keys"].split(",") if "keys" in opts else sorted(set(a) | set(b))
    bad = 0
    print("%-22s %-6s %9s %9s %8s %8s  %s" % ("key", "kind", "A", "B", "only A", "only B", "status"))
    for k in keys:
        if k not in a or k not in b:
            print("%-22s %-6s %9s %9s %8s %8s  %s" % (k, "-", "yes" if k in a else "-", "yes" if k in b else "-", "", "", "DIFF (missing)"))
            bad += 1
            continue
        va, vb = a[k], b[k]
        if isinstance(va, dict) and isinstance(vb, dict) and any(isinstance(x, list) for x in va.values()):
            for sk in sorted(set(va) | set(vb)):
                r = compare(va.get(sk, []), vb.get(sk, []), ex)
                if r[5] != "same" or opts.get("quiet") is None:
                    print("%-22s %-6s %9d %9d %8d %8d  %s" % ((k + "." + sk)[:22], r[0], r[1], r[2], r[3], r[4], r[5]))
                bad += r[5] == "DIFF"
                for e in r[6]:
                    print("   A:", e[:300])
                for e in r[7]:
                    print("   B:", e[:300])
            continue
        r = compare(va, vb, ex)
        if r[5] != "same" or opts.get("quiet") is None:
            print("%-22s %-6s %9d %9d %8d %8d  %s" % (k[:22], r[0], r[1], r[2], r[3], r[4], r[5]))
        bad += r[5] == "DIFF"
        for e in r[6]:
            print("   A:", e[:300])
        for e in r[7]:
            print("   B:", e[:300])
    print("diff_map: %s" % ("identical" if not bad else "%d keys differ" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
