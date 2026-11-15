"""Filter an outside list of Warsaw model names (Tiny Warsaw's gallery) on our map box.

Usage: python3 -I tools/tinywarsaw_area.py NAMES.txt [OUT.md]

NAMES.txt has one model name per line (copy the gallery's names; the file is not committed).
Each name is matched against our named outlines (centrum.json landmarks and buildings), our
metro entrances and Part 1 of docs/CITY_INVENTORY.md. A match takes the inventory's status
(★ photo build, ◐ outline/model, ○ dress or in game, ✗ plain block) and a district and street
(nearest address point). An unmatched name is sorted: outside the box, a street of ours (a gap
candidate), or unknown. Writes the markdown tables to OUT.md (default: stdout). Inspiration only:
names are facts about Warsaw; no model or asset of theirs is used.
"""
import collections
import importlib.util
import json
import math
import glob
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location('ci', os.path.join(ROOT, 'tools', 'city_inventory.py'))
ci = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ci)

OUTSIDE = re.compile(r'Airport|Babice|Terminal [A-Z]|LOT maintenance|HEMS|Hangar|Cargo|Aeroklub|PANSA|Courtyard by Marriott Warsaw Airport|'
                     r'Wydział Operacji Lotniczych|Lotnicz|Pomnik Lotnika|West-side mapped flight|Poczta Polska cargo|DHL|IBEX|Pałac w Wilanowie|'
                     r'Stadion RKS Skra|Zakład Filtrów|^Filtr|Zbiornik wody czystej|Stacja ozonowania|Muzeum Wodociągów|Wieża ciśnień Lindleya', re.I)


def norm(s):
    s = unicodedata.normalize('NFKD', s.lower().replace('ł', 'l'))
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'[^a-z0-9]+', ' ', s).strip()


def main():
    names = [l.strip() for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
    text = open(ci.DOC, encoding='utf-8').read()
    rows = ci.parse_rows(text)
    data = json.load(open(os.path.join(ROOT, 'game', 'map', 'centrum.json'), encoding='utf-8'))
    districts = json.load(open(os.path.join(ROOT, 'game', 'data', 'districts.json'), encoding='utf-8'))['districts']

    def district(x, z):
        for d in districts:
            if any(ci.inside(x, z, a) for a in d.get('areas', [])):
                return d['name_pl']
        return 'poza dzielnicami'

    addr = [(p['x'], p['z'], p['name']) for p in data['pois'] if p['k'] == 'address']
    grid = collections.defaultdict(list)
    for a in addr:
        grid[(int(a[0] // 100), int(a[1] // 100))].append(a)

    def street(x, z):
        gx, gz = int(x // 100), int(z // 100)
        best, bd = None, 1e18
        for r in range(6):
            for i in range(gx - r, gx + r + 1):
                for j in range(gz - r, gz + r + 1):
                    for a in grid.get((i, j), []):
                        dd = (a[0] - x) ** 2 + (a[1] - z) ** 2
                        if dd < bd:
                            bd, best = dd, a
            if best and math.sqrt(bd) < r * 100:
                break
        return ci.street_of(best[2]) if best else '?'

    code = ''
    import glob
    for f in glob.glob(os.path.join(ROOT, 'game', 'scripts', '*.gd')) + glob.glob(os.path.join(ROOT, 'game', 'scripts', 'landmarks', '*.gd')) + glob.glob(os.path.join(ROOT, 'game', 'data', '*.json')):
        code += open(f, encoding='utf-8').read()
    sites = [(float(a), float(b)) for a, b in re.findall(
        r'"at": Vector2\(([-\d.]+), ([-\d.]+)\)', ''.join(open(f, encoding='utf-8').read() for f in [os.path.join(ROOT, 'game', 'scripts', 'landmarks.gd')]
                        + sorted(glob.glob(os.path.join(ROOT, 'game', 'scripts', 'landmarks', '*.gd')))))]  # TD-10: and its area files

    outlines = {}
    for src in (data['landmarks'], [b for b in data['buildings'] if b['name']]):
        for o in src:
            x, z, a = ci.centroid(o['p'])
            e = outlines.setdefault(o['name'], {'x': x, 'z': z, 'polys': []})
            e['polys'].append(o['p'])

    def status(name, o):
        pat = re.compile(r'(?<!\w)' + re.escape(name) + r'(?!\w)')
        hit = next((r for r in rows if pat.search(r[1])), None)
        if hit:
            return hit[3], '#%d' % hit[0]
        if any(ci.inside(sx, sz, p) for sx, sz in sites for p in o['polys']):
            return '◐', 'model'
        if ('"' + name + '"') in code:
            return '○', 'in game'
        return '✗', ''

    by_norm = {norm(n): n for n in outlines}
    road_names = {norm(r['name']): r['name'] for r in data['roads'] if r.get('name')}
    road_names = {k: v for k, v in road_names.items() if len(k) >= 5}
    ent = collections.defaultdict(list)
    for p in data['pois']:
        if p['k'] == 'subway_entrance':
            ent[norm(p['st'])].append(p)

    addr_n = [(norm(a[2]), a[0], a[1]) for a in addr if len(norm(a[2])) >= 6 and re.search(r'\d', a[2])]
    addr_d = {a[0]: a for a in addr_n}
    bld = [(min(b['p'][0::2]), min(b['p'][1::2]), max(b['p'][0::2]), max(b['p'][1::2]), b) for b in data['buildings']]

    def building_at(x, z):
        for x0, z0, x1, z1, b in bld:
            if x0 <= x <= x1 and z0 <= z <= z1 and ci.inside(x, z, b['p']):
                return b
        return None

    matched = collections.defaultdict(list)   # district -> (name, street, mark, note)
    metro = collections.defaultdict(int)
    gaps, outside, unknown = [], [], []
    stats = collections.Counter()
    for n in names:
        m = re.match(r'Metro (.+?) · ', n)
        if m:
            st = norm(m.group(1))
            if st in ent:
                metro[m.group(1)] += 1
            else:
                stats['metro_out'] += 1
            continue
        key = norm(n)
        o = by_norm.get(key)
        if not o:
            c = [k for k in by_norm if len(key) >= 14 and (key in k or (len(k) >= 14 and k in key))]
            o = by_norm[c[0]] if len(c) == 1 else None
        if o:
            e = outlines[o]
            mark, note = status(o, e)
            matched[district(e['x'], e['z'])].append((n, street(e['x'], e['z']), mark, note))
            continue
        tk = key.split()
        ad = [addr_d[g] for i in range(len(tk)) for j in range(i + 1, min(len(tk), i + 5) + 1)
              for g in [' '.join(tk[i:j])] if g in addr_d]
        if ad and not OUTSIDE.search(n):
            a = max(ad, key=lambda t: len(t[0]))
            b = building_at(a[1], a[2])
            note = 'address, block %s m' % (b['h'] if b else '?')
            matched[district(a[1], a[2])].append((n, street(a[1], a[2]), '✗' if not b or not b['name'] else status(b['name'], outlines[b['name']])[0], note))
            stats['by_addr'] += 1
            continue
        if OUTSIDE.search(n):
            outside.append(n)
            continue
        k = next((v for kk, v in sorted(road_names.items(), key=lambda t: -len(t[0])) if re.search(r'(?<![a-z0-9])' + re.escape(kk) + r'(?![a-z0-9])', key)), None)
        (gaps if k else unknown).append((n, k) if k else n)

    out = []
    w = out.append
    tot = sum(len(v) for v in matched.values())
    w('Names given: %d. In our box (named outline or exact address): %d (+ %d metro stations with %d entrances in theirs). '
      'Street of ours in the name, number or name not found: %d. Outside the box (airport, Filtry, other districts): %d. Unknown: %d.\n'
      % (len(names), tot, len(metro), sum(metro.values()), len(gaps), len(outside) + stats['metro_out'], len(unknown)))
    mc = collections.Counter(r[2] for v in matched.values() for r in v)
    w('Status of the %d matched: %s.\n' % (tot, ', '.join('%s %d' % kv for kv in sorted(mc.items()))))
    order = [d['name_pl'] for d in districts] + ['poza dzielnicami']
    for d in order:
        v = matched.get(d)
        if not v:
            continue
        w('\n### %s (%d)\n\n| Name | Street | Status | Inventory |\n| --- | --- | --- | --- |' % (d, len(v)))
        for n, s, mk, note in sorted(v, key=lambda r: (r[1], r[0])):
            w('| %s | %s | %s | %s |' % (n.replace('|', '/'), s, mk, note))
    w('\n### Metro stations in our box (their entrance count / ours)\n\n| Station | Theirs | Ours |\n| --- | --- | --- |')
    for st, c in sorted(metro.items()):
        w('| %s | %d | %d |' % (st, c, len(ent[norm(st)])))
    w('\n### Gap candidates: the name holds one of our streets, we have no outline of that name\n')
    for n, k in sorted(gaps, key=lambda t: (t[1], t[0])):
        w('- %s (%s)' % (n, k))
    w('\n### Unknown (not matched, no street of ours)\n')
    for n in sorted(unknown):
        w('- ' + n)
    w('\n### Outside the box\n')
    w(', '.join(sorted(outside)[:200]))
    res = '\n'.join(out) + '\n'
    if len(sys.argv) > 2:
        open(sys.argv[2], 'w', encoding='utf-8').write(res)
    else:
        sys.stdout.write(res)


main()
