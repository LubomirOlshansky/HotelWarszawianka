"""Regenerate docs/CITY_INVENTORY.md's counts and Part 2 (street by street).

Usage: python3 -I tools/city_inventory.py [--check]

Part 1 (the ranked list) is written by hand; this script reads its rows and their status marks,
then lists every named outline in game/map/centrum.json (OSM `landmarks` and named `buildings`)
under its street (the nearest OSM address point) and district (game/data/districts.json). A
named outline that a Part 1 row names (whole words, or "(OSM: name)") takes that row's status;
one named in a quoted string of the game's scripts or data is "○ in game"; the rest are ✗.
Ranked places that have no outline (monuments, bars) are listed under their row's first street.
Part 2 also lists the OpenStreetMap points the map does not bake (docs/inventory/osm_candidates.json, the
Overpass cache that tools/city_list.py fetches): monuments and sculptures, murals, bars and clubs,
museums, galleries, theatres, cinemas, malls, hotels and office buildings, plus a count of the
plaques and memorial stones per street. Their status is a name match against Part 1 and the game.
--check exits 1 when the file on disk differs from what the script would write.
"""
import collections
import glob
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, 'docs', 'CITY_INVENTORY.md')
MARKS = ['★', '◐', '○', '⏳', '✗']
SKIP_KINDS = {'kiosk', 'service', 'outbuilding', 'toilets', 'garage', 'allotment_house', 'plinth',
              'bunker', 'demolished'}
SHORT = {'apartments': 'flats', 'residential': 'flats', 'office': 'offices', 'commercial': 'commercial',
         'retail': 'shop', 'university': 'university', 'church': 'church', 'chapel': 'chapel',
         'cathedral': 'cathedral', 'government': 'government', 'public': 'public', 'hotel': 'hotel',
         'palace': 'palace', 'hospital': 'hospital', 'school': 'school', 'monastery': 'monastery',
         'convent': 'convent', 'dormitory': 'dormitory', 'train_station': 'station', 'theatre': 'theatre',
         'museum': 'museum', 'synagogue': 'synagogue', 'detached': 'house', 'industrial': 'industrial',
         'boat': 'boat', 'sports_hall': 'sports hall', 'sports_centre': 'sports', 'civic': 'civic'}
CHARACTERISTIC = re.compile(r'Kamienic|Pałac|Kości|Dom |Hotel|Muzeum|Teatr|Kino|Synagog|Cerkiew|Klasztor|'
                            r'Willa|Gmach|Hala|Zamek|Baszta|Brama|Wieża|Rezydencja|Apartament|Tower')


def centroid(p):
    xs, zs = p[0::2], p[1::2]
    n = len(xs)
    a = cx = cz = 0.0
    for i in range(n):
        j = (i + 1) % n
        c = xs[i] * zs[j] - xs[j] * zs[i]
        a += c
        cx += (xs[i] + xs[j]) * c
        cz += (zs[i] + zs[j]) * c
    if abs(a) < 1e-6:
        return sum(xs) / n, sum(zs) / n, 0.0
    return cx / (3 * a), cz / (3 * a), abs(a) / 2


def inside(x, z, p):
    xs, zs = p[0::2], p[1::2]
    n = len(xs)
    c = False
    j = n - 1
    for i in range(n):
        if (zs[i] > z) != (zs[j] > z) and x < (xs[j] - xs[i]) * (z - zs[i]) / (zs[j] - zs[i] + 1e-12) + xs[i]:
            c = not c
        j = i
    return c


def street_of(addr):
    return re.sub(r'\s+\S*\d\S*$', '', addr).strip()


def parse_rows(text):
    """Part 1's rows: (number, place, street, status)."""
    rows = []
    part1 = text.split('## Part 1.', 1)[1].split('## Part 3.', 1)[0]
    for line in part1.splitlines():
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) >= 6 and cells[0].isdigit():
            mark = next((m for m in MARKS if m in cells[4]), '✗')
            rows.append((int(cells[0]), cells[1], cells[2], mark))
    return rows


OSM_CATS = [  # (label, test on the tags), first match wins; None = count only
    ('plaques', lambda t: t.get('memorial') in ('plaque', 'stolperstein', 'stone', 'stele', 'cross', 'blue_plaque')
     or t.get('historic') in ('wayside_shrine', 'wayside_cross', 'boundary_stone')),
    ('monuments', lambda t: 'memorial' in t or t.get('historic') in ('memorial', 'monument')
     or (t.get('tourism') == 'artwork' and t.get('artwork_type') not in ('mural', 'graffiti'))),
    ('murals', lambda t: t.get('tourism') == 'artwork'),
    ('bars', lambda t: t.get('amenity') in ('bar', 'pub', 'nightclub')),
    ('museums', lambda t: t.get('tourism') in ('museum', 'gallery') or t.get('amenity') == 'arts_centre'),
    ('stages', lambda t: t.get('amenity') in ('theatre', 'cinema')),
    ('malls', lambda t: t.get('shop') in ('mall', 'department_store')),
    ('hotels', lambda t: t.get('tourism') == 'hotel'),
    ('offices', lambda t: t.get('building') in ('office', 'commercial') or ('office' in t and 'building' in t)),
]


# OSM statue names that stand inside a hand-built site (Part 1 names them another way).
BUILT_STATUES = {'Adam Mickiewicz': '◐', 'Bolesław Prus': '◐', 'Charles de Gaulle': '◐', 'Józef Poniatowski': '◐',
                 'Mikołaj Kopernik': '◐', 'Stefan Wyszyński': '◐', 'Stefan Kardynał Wyszyński': '◐',
                 'Syrenka Warszawska': '◐'}


def osm_points():
    """(label, name, x, z) for the cached OSM candidates, in map metres."""
    path = os.path.join(ROOT, 'docs', 'inventory', 'osm_candidates.json')
    if not os.path.exists(path):
        return []
    m_lat = 110574.0
    m_lon = 111320.0 * math.cos(math.radians(52.234))
    pts = []
    for e in json.load(open(path, encoding='utf-8')).get('elements', []):
        t = e.get('tags') or {}
        c = e.get('center') or e
        if 'lat' not in c:
            continue
        label = next((lab for lab, test in OSM_CATS if test(t)), None)
        if not label:
            continue
        name = t.get('name') or t.get('inscription', '')[:60] or ''
        if label != 'plaques' and not t.get('name'):
            continue
        pts.append((label, name.strip(), (c['lon'] - 21.024) * m_lon, -(c['lat'] - 52.234) * m_lat))
    return pts


def build(text):
    data = json.load(open(os.path.join(ROOT, 'game', 'map', 'centrum.json'), encoding='utf-8'))
    districts = json.load(open(os.path.join(ROOT, 'game', 'data', 'districts.json'), encoding='utf-8'))['districts']
    order = [d['name_pl'] for d in districts]

    def district(x, z):
        for d in districts:
            for ar in d.get('areas', []):
                if inside(x, z, ar):
                    return d['name_pl']
        return 'poza dzielnicami'

    addr = [(p['x'], p['z'], p['name']) for p in data['pois'] if p['k'] == 'address']
    grid = collections.defaultdict(list)
    for a in addr:
        grid[(int(a[0] // 100), int(a[1] // 100))].append(a)

    def nearest(x, z):
        best, bd = None, 1e18
        gx, gz = int(x // 100), int(z // 100)
        for r in range(6):
            for i in range(gx - r, gx + r + 1):
                for j in range(gz - r, gz + r + 1):
                    for a in grid.get((i, j), []):
                        dd = (a[0] - x) ** 2 + (a[1] - z) ** 2
                        if dd < bd:
                            bd, best = dd, a
            if best and math.sqrt(bd) < r * 100:
                break
        return best

    street_district = collections.defaultdict(collections.Counter)
    for x, z, name in addr[::3]:
        street_district[street_of(name)][district(x, z)] += 1

    code = ''
    for f in glob.glob(os.path.join(ROOT, 'game', 'scripts', '*.gd')) + glob.glob(os.path.join(ROOT, 'game', 'scripts', 'landmarks', '*.gd')) + glob.glob(os.path.join(ROOT, 'game', 'data', '*.json')):
        code += open(f, encoding='utf-8').read()

    outlines = {}
    for lm in data['landmarks']:
        x, z, a = centroid(lm['p'])
        o = outlines.setdefault(lm['name'], {'x': x, 'z': z, 'area': 0.0, 'kinds': set(), 'polys': []})
        o['area'] += a
        o['polys'].append(lm['p'])
    for b in data['buildings']:
        if not b['name']:
            continue
        x, z, a = centroid(b['p'])
        o = outlines.setdefault(b['name'], {'x': x, 'z': z, 'area': 0.0, 'kinds': set(), 'polys': []})
        o['kinds'].add(b['kind'])
        o['polys'].append(b['p'])
        if not o['area']:
            o['area'] = a

    # hand-built sites placed by position (the church kit, hotels' fronts): `"at": Vector2(x, z)`
    sites = [(float(a), float(b)) for a, b in
             re.findall(r'"at": Vector2\(([-\d.]+), ([-\d.]+)\)', ''.join(open(f, encoding='utf-8').read() for f in [os.path.join(ROOT, 'game', 'scripts', 'landmarks.gd')]
                        + sorted(glob.glob(os.path.join(ROOT, 'game', 'scripts', 'landmarks', '*.gd')))))]  # TD-10: and its area files

    rows = parse_rows(text)
    entries = collections.defaultdict(list)   # (district, street) -> [(sort, label)]
    covered = set()
    counts = collections.Counter()
    for name, o in outlines.items():
        pat = re.compile(r'(?<!\w)' + re.escape(name) + r'(?!\w)')
        hit = next((r for r in rows if pat.search(r[1])), None)
        if hit:
            covered.add(hit[0])
            continue
        kinds = o['kinds'] - {'yes'}
        if kinds and kinds <= SKIP_KINDS:
            continue
        if o['area'] < 150 and not CHARACTERISTIC.search(name):
            continue
        a = nearest(o['x'], o['z'])
        street = street_of(a[2]) if a else '?'
        dist = district(o['x'], o['z'])
        if any(inside(sx, sz, p) for sx, sz in sites for p in o['polys']):
            mark = '◐ model'
        elif ('"' + name + '"') in code:
            mark = '○ in game'
        elif dist == 'Stare Miasto' and name.startswith('Kamienica'):
            mark = '○ old-town dress'
        else:
            mark = '✗'
        kind = ', '.join(sorted(SHORT.get(k, k) for k in kinds)) if kinds else ''
        label = name + (' (' + kind + ')' if kind else '') + ' ' + mark
        entries[(dist, street)].append((1, mark != '✗', label))
        counts['c_' + mark.split()[0]] += 1
    seen = set(outlines)
    bounds = data['bounds']
    outside = data.get('outside') or []
    extra = collections.defaultdict(lambda: collections.defaultdict(list))
    for label, name, x, z in osm_points():
        if not (bounds[0] <= x <= bounds[2] and bounds[1] <= z <= bounds[3]):
            continue
        if any(o[0] <= x <= o[2] and o[1] <= z <= o[3] for o in outside):
            continue
        if label != 'plaques':
            if name in seen:
                continue
            seen.add(name)
        a = nearest(x, z)
        key = (district(x, z), street_of(a[2]) if a else '?')
        if label == 'plaques':
            extra[key]['plaques'].append(name)
            counts['o_plaques'] += 1
            continue
        pat = re.compile(r'(?<!\w)' + re.escape(name) + r'(?!\w)')
        hit = next((r for r in rows if pat.search(r[1])), None)
        mark = hit[3] if hit else BUILT_STATUES.get(name) or ('○ in game' if ('"' + name + '"') in code else '✗')
        extra[key][label].append(name + ' ' + mark)
        counts['o_' + label] += 1
    for key, cats in extra.items():
        parts = []
        for label, _ in OSM_CATS:
            if label == 'plaques' or not cats.get(label):
                continue
            parts.append('*%s:* %s' % (label, ', '.join(sorted(cats[label]))))
        if cats.get('plaques'):
            parts.append('*plaques and memorial stones:* %d' % len(cats['plaques']))
        entries[key].append((2, False, '; '.join(parts)))
    for num, place, street, mark in rows:
        first = re.split(r' / |, | \(', street)[0].strip()
        if not first or first.startswith('('):
            dist, first = 'Across the city', 'many streets'
        else:
            dist = street_district[first].most_common(1)[0][0] if street_district.get(first) else 'poza dzielnicami'
        entries[(dist, first)].append((0, -num, '**#%d %s** %s' % (num, re.sub(r' \(OSM: [^)]*\)', '', place), mark)))
        counts[mark] += 1

    out = []
    by_d = collections.defaultdict(list)
    for (d, s), items in entries.items():
        by_d[d].append((s, items))
    for d in ['Across the city'] + order + sorted(set(by_d) - set(order) - {'Across the city'}):
        if d not in by_d:
            continue
        streets = sorted(by_d[d], key=lambda si: (-sum(1 for i in si[1] if i[0] == 0), -len(si[1]), si[0]))
        total = sum(1 for _, i in streets for e in i if e[0] < 2)
        out.append('### %s (%d places)\n' % (d, total))
        for s, items in streets:
            items.sort(key=lambda i: (i[0], -i[1] if i[0] == 0 else 0, not i[1] if i[0] == 1 else 0, i[2]))
            out.append('- **%s**: %s' % (s, '; '.join(i[2] for i in items)))
        out.append('')
    part2 = ('## Part 2. Street by street\n\nGenerated by `python3 -I tools/city_inventory.py` from the map '
             'data and Part 1. Ranked places in bold with their number; the rest are named outlines '
             'in OpenStreetMap (tier C), marked "◐ model" when a hand-built site stands in them (the church kit, the hotels\' '
             'fronts), "○ in game" when the game names them (a card, a sign, a skin), "○ old-town dress" '
             'for the dressed Old Town houses, and ✗ when they are a plain block. Streets are the nearest address point, so a '
             'corner building can sit on the cross street. After the buildings, each street lists the '
             'OpenStreetMap points the map does not bake as buildings (monuments, murals, bars, museums, stages, malls, '
             'hotels, offices; real venue names, which the game only shows as parodies) and a count of its '
             'plaques and memorial stones. Monuments marked "○ in game" stand as a generic piece at least '
             '(tools/bake_monuments.py, game/data/monuments.json), as do the plaques.\n\n' + '\n'.join(out).rstrip() + '\n')
    tier_c = sum(v for k, v in counts.items() if k.startswith('c_'))
    count_md = ('**Counts** (Part 1, %d ranked rows): ★ %d photo builds · ◐ %d outline builds · '
                '○ %d dress only · ⏳ %d in progress · ✗ %d not done. Part 2 adds %d named outlines '
                '(tier C): %d with a model of their own, %d dressed or named in the game, %d plain blocks. From '
                'OpenStreetMap points (the monuments and plaques stand as generic pieces from tools/bake_monuments.py '
                'since 2026-11-02, the rest are not baked): %d monuments and sculptures, %d murals, %d bars and '
                'clubs, %d museums and galleries, %d theatres and cinemas, %d malls, %d hotels, %d plaques and '
                'memorial stones (the named office buildings are already outlines above).\n'
                % (len(rows), counts['★'], counts['◐'], counts['○'], counts['⏳'], counts['✗'],
                   tier_c, counts['c_◐'], counts['c_○'], counts['c_✗'], counts['o_monuments'], counts['o_murals'],
                   counts['o_bars'], counts['o_museums'], counts['o_stages'], counts['o_malls'], counts['o_hotels'],
                   counts['o_plaques']))
    text = re.sub(r'<!-- counts:start -->.*?<!-- counts:end -->',
                  lambda m: '<!-- counts:start -->\n' + count_md + '<!-- counts:end -->', text, flags=re.S)
    text = re.sub(r'<!-- streets:start -->.*?<!-- streets:end -->',
                  lambda m: '<!-- streets:start -->\n' + part2 + '<!-- streets:end -->', text, flags=re.S)
    return text


def main():
    text = open(DOC, encoding='utf-8').read()
    new = build(text)
    if '--check' in sys.argv:
        if new != text:
            print('city_inventory: docs/CITY_INVENTORY.md is stale, run python3 -I tools/city_inventory.py')
            sys.exit(1)
        print('city_inventory: OK')
        return
    open(DOC, 'w', encoding='utf-8').write(new)
    print('city_inventory: wrote', DOC)


if __name__ == '__main__':
    main()
