"""Write game/data/house_types.json (docs/design/house-types.md): the zones as lat/lon boxes
turned into map metres (tools/bake_osm.py's projection), the types and their palettes.

Usage: python3 -I tools/house_zones.py   (edit the tables here, never the JSON by hand)
"""
import json, math, os
LAT0, LON0 = 52.2340, 21.0240
MLAT = 110574.0; MLON = 111320.0 * math.cos(math.radians(LAT0))
def P(lat, lon): return [round((lon - LON0) * MLON, 1), round((LAT0 - lat) * MLAT, 1)]
def box(s, w, n, e): return [*P(s, w), *P(s, e), *P(n, e), *P(n, w)]
Z = [
 ("mdm", "MDM: Marszałkowska, Plac Konstytucji, Plac Zbawiciela (1950-56 socrealism)", box(52.2188, 21.0118, 52.2248, 21.0168), {"5": 8, "1": 2}),
 ("sciana_wschodnia", "Ściana Wschodnia: Marszałkowska east, Świętokrzyska to Jerozolimskie (1960s)", box(52.2303, 21.0102, 52.2352, 21.0150), {"11": 6, "7": 4}),
 ("za_zelazna_brama", "Za Żelazną Bramą estate (1965-72 slabs and point blocks)", box(52.2338, 20.9930, 52.2402, 21.0045), {"9": 55, "8": 20, "10": 25}),
 ("stawki", "Stawki and Inflancka estates north of Muranów", box(52.2535, 20.9880, 52.2600, 21.0060), {"9": 60, "8": 20, "10": 20}),
 ("muranow", "Muranów (Lachert's 1950s blocks on the ghetto's rubble)", box(52.2385, 20.9830, 52.2540, 21.0040), {"6": 75, "7": 10, "13": 15}),
 ("wola_offices", "Wola office belt: Prosta, Grzybowska, Rondo Daszyńskiego to ONZ", box(52.2280, 20.9780, 52.2340, 21.0000), {"12": 4, "13": 4, "11": 2}),
 ("mirow", "Mirów and east Wola: 1950s-60s blocks and new builds", box(52.2338, 20.9780, 52.2385, 20.9930), {"7": 3, "9": 3, "13": 4}),
 ("srodmiescie_polnoc", "Śródmieście Północne: Świętokrzyska, Królewska, Grzybowski square", box(52.2305, 21.0000, 52.2400, 21.0200), {"7": 35, "11": 25, "1": 20, "13": 20}),
 ("solec_ludna", "Solec, Ludna, Czerniakowska estates", box(52.2225, 21.0300, 52.2300, 21.0460), {"7": 3, "9": 5, "13": 2}),
 ("powisle", "Powiśle: pre-war and interwar houses, post-war blocks, new builds", box(52.2300, 21.0230, 52.2420, 21.0420), {"3": 3, "1": 3, "7": 2, "13": 2}),
 ("ujazdow", "Ujazdów and Frascati: villas, interwar houses, embassies", box(52.2150, 21.0230, 52.2290, 21.0360), {"1": 5, "3": 3, "11": 2}),
 ("srodmiescie_poludnie", "Śródmieście Południowe: Hoża, Wilcza, Poznańska, Koszyki (pre-war kamienice)", box(52.2160, 20.9980, 52.2305, 21.0270), {"1": 85, "3": 10, "13": 5}),
 ("ochota", "Ochota by Plac Narutowicza: interwar blocks", box(52.2150, 20.9780, 52.2280, 20.9980), {"3": 6, "1": 2, "9": 2}),
 ("port_praski", "Praga riverside and Port Praski: new builds by old brick", box(52.2440, 21.0270, 52.2505, 21.0360), {"13": 6, "2": 4}),
 ("praga_polnoc", "Praga Północ: Ząbkowska, Targowa, Brzeska, Stalowa (brick kamienice)", box(52.2440, 21.0270, 52.2620, 21.0600), {"2": 65, "9": 15, "13": 10, "15": 10}),
 ("kamionek", "Kamionek and Praga Południe west: blocks, brick, new builds", box(52.2280, 21.0400, 52.2440, 21.0600), {"9": 4, "2": 3, "13": 3}),
]
TYPES = {
 "1": {"name": "kamienica", "rhythm": 1, "family": "prewar", "walls": ["#d9c7a0", "#c9b38a", "#bfb8a8", "#e3d3b0", "#d1a77f", "#c8a89a", "#a9a89a", "#d8cdb8", "#b8a184", "#cfc0a2"]},
 "2": {"name": "praga_brick", "rhythm": 1, "family": "prewar", "walls": ["#9a4f3c", "#8c4a3a", "#a5604a", "#7e4436", "#b06a4f", "#94574a", "#a8a196"]},
 "3": {"name": "modernist", "rhythm": 1, "family": "prewar", "walls": ["#ece6d6", "#e8e0cc", "#f1ece0", "#d9d4c6", "#e5dcc5"]},
 "5": {"name": "mdm", "rhythm": 1, "family": "prewar", "walls": ["#d6c7a6", "#cdbd99", "#c9b48e", "#bfb39c", "#d9ccb0"]},
 "6": {"name": "muranow", "rhythm": 2, "family": "postwar", "walls": ["#c9aea0", "#bf9f90", "#c7b39f", "#b89a8a", "#d1bba8", "#a89386"]},
 "7": {"name": "postthaw", "rhythm": 2, "family": "postwar", "walls": ["#e6e4dc", "#dcdad2", "#e9e0c8", "#cfd6d6", "#e4d2c2"]},
 "8": {"name": "panel", "rhythm": 2, "family": "postwar", "walls": ["#bdbab2", "#b1aea6", "#c7c3b9", "#a9a69e"]},
 "9": {"name": "docieplony", "rhythm": 2, "family": "postwar", "walls": ["#f0e6b8", "#e9d7a1", "#d8e3c3", "#cfe0e6", "#f2d4c2", "#e8e8e2", "#f1e2c6", "#d9d2e6"]},
 "10": {"name": "point_block", "rhythm": 2, "family": "postwar", "walls": ["#e8e8e2", "#f0e6b8", "#cfe0e6", "#bdbab2", "#f2d4c2"]},
 "11": {"name": "prl_office", "rhythm": 3, "family": "office", "walls": ["#b9b6ad", "#a8a59c", "#c4bfb2", "#9d9a92"]},
 "12": {"name": "postmodern", "rhythm": 3, "family": "office", "walls": ["#b8a99a", "#9c8f84", "#c6b8a5", "#8e8a86"]},
 "13": {"name": "developer", "rhythm": 2, "family": "postwar", "walls": ["#eeeeec", "#e4e3df", "#d9d8d4", "#6a6c71", "#f0ebe0"]},
 "15": {"name": "factory", "rhythm": 0, "family": "prewar", "walls": ["#9a4f3c", "#8a4636", "#a5604a"]},
}
out = {
 "_about": "House types (docs/design/house-types.md, PR 1). zones: first match wins; mix = type weights inside the zone. "
           "Zone outlines are boxes drawn from Warsaw's building history (lat/lon to map metres like tools/bake_osm.py), "
           "not yet photo-checked (phase 4). types: rhythm = the drawn facade today (0 generic, 1 tenement, 2 slab, 3 office), "
           "family = what floor height and shape can tell (prewar, postwar, office), walls = sRGB palette.",
 "floor_prewar": 3.6, "floor_postwar": 3.05,
 "default_mix": {"1": 5, "9": 3, "13": 2},
 "family_default": {"prewar": "1", "postwar": "9", "office": "11"},
 "types": TYPES,
 "zones": [{"id": i, "about": a, "p": p, "mix": m, "grey_override": True} for i, a, p, m in Z],
}
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game', 'data', 'house_types.json'), 'w').write(json.dumps(out, ensure_ascii=False, indent='\t') + "\n")
