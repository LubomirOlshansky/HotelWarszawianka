"""Write game/data/house_types.json and building.gdshader's HOUSE_TYPES rows (docs/design/house-types.md): the zones as lat/lon boxes
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
 "4": {"name": "old_town", "rhythm": 0, "family": "prewar", "walls": []},
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
# PR 2a: each type's drawn facade, read by building.gdshader's house_facade() from the const
# block this script writes there (HOUSE_A..HOUSE_D, row = type). Metres unless noted.
#   A: ground floor height, upper floor height, window axis spacing, cornice depth (0 none)
#   B: window half width, window height, window foot over the floor line, surround width (0 none)
#   C: share of ground-floor axes with a shop window, ribbon (1 = one band of glass), panel joints
#      (0..1), share of bays with a loggia
#   D: rusticated ground floor (0/1), mix towards pale panel concrete (0..1), share of lit rooms
#      at night, roof (0 by the photo's colour, 1 tar paper, 2 membrane)
# The share of the bake's parked cars a zone keeps (map_builder.gd, seeded by place): the estates
# and the pre-war streets stay full, the office belt (garages under the towers), MDM's wide paid
# avenues, the embassies of Ujazdów and the Ściana Wschodnia's shopping street run thinner.
PARKED = {"wola_offices": 0.55, "sciana_wschodnia": 0.6, "mdm": 0.75, "ujazdow": 0.65,
          "srodmiescie_polnoc": 0.75, "port_praski": 0.8}

FACADE = {
 "0":  [4.0, 3.4, 2.8, 0.7,  0.45, 1.8, 0.85, 0.0,   0.6, 0.0, 0.0, 0.0,   0.0, 0.0, 0.34, 0.0],
 "1":  [4.4, 3.7, 2.8, 0.9,  0.55, 2.1, 0.85, 0.18,  0.75, 0.0, 0.0, 0.0,  1.0, 0.0, 0.34, 0.0],
 "2":  [3.8, 3.4, 2.5, 0.6,  0.45, 1.9, 0.8, 0.12,   0.45, 0.0, 0.0, 0.0,  0.0, 0.0, 0.32, 0.0],
 "3":  [3.4, 3.2, 3.0, 0.0,  0.75, 1.5, 0.95, 0.0,   0.4, 0.0, 0.0, 0.15,  0.0, 0.0, 0.34, 0.0],
 "4":  [3.6, 3.2, 2.5, 0.8,  0.45, 1.6, 0.8, 0.15,   0.7, 0.0, 0.0, 0.0,   0.0, 0.0, 0.34, 0.0],
 "5":  [6.2, 3.6, 2.6, 1.3,  0.55, 1.8, 0.9, 0.2,    0.9, 0.0, 0.0, 0.0,   1.0, 0.0, 0.34, 0.0],
 "6":  [3.0, 2.9, 2.6, 0.35, 0.5, 1.5, 0.9, 0.1,     0.1, 0.0, 0.0, 0.0,   0.0, 0.0, 0.34, 1.0],
 "7":  [3.0, 2.8, 3.0, 0.0,  0.75, 1.45, 0.9, 0.0,   0.3, 0.0, 0.0, 0.15,  0.0, 0.1, 0.34, 1.0],
 "8":  [2.8, 2.8, 3.2, 0.0,  0.8, 1.4, 0.95, 0.0,    0.05, 0.0, 1.0, 0.35, 0.0, 0.35, 0.34, 1.0],
 "9":  [2.8, 2.8, 3.2, 0.0,  0.8, 1.4, 0.95, 0.0,    0.05, 0.0, 0.1, 0.3, 0.0, 0.0, 0.34, 1.0],
 "10": [2.8, 2.8, 2.9, 0.0,  0.7, 1.4, 0.95, 0.0,    0.05, 0.0, 0.5, 0.45, 0.0, 0.2, 0.34, 1.0],
 "11": [3.8, 3.3, 1.5, 0.0,  0.7, 1.7, 0.9, 0.0,     0.9, 1.0, 0.0, 0.0,   0.0, 0.0, 0.42, 2.0],
 "12": [4.2, 3.5, 2.7, 0.3,  0.8, 1.6, 0.9, 0.08,    0.9, 0.0, 0.0, 0.0,   0.0, 0.0, 0.42, 2.0],
 "13": [3.6, 3.0, 3.4, 0.0,  1.0, 1.9, 0.3, 0.0,     0.4, 0.0, 0.0, 0.5,   0.0, 0.0, 0.34, 2.0],
 "14": [4.0, 3.4, 2.8, 0.7,  0.45, 1.8, 0.85, 0.0,   0.6, 0.0, 0.0, 0.0,   0.0, 0.0, 0.34, 0.0],
 "15": [4.5, 4.5, 3.6, 0.5,  0.9, 2.6, 1.0, 0.15,    0.0, 0.0, 0.0, 0.0,   0.0, 0.0, 0.2, 1.0],
}
for k, t in TYPES.items():
	t["facade"] = FACADE[k]

out = {
 "_about": "House types (docs/design/house-types.md, PR 1). zones: first match wins; mix = type weights inside the zone. "
           "Zone outlines are boxes drawn from Warsaw's building history (lat/lon to map metres like tools/bake_osm.py), "
           "not yet photo-checked (phase 4). types: rhythm = the roof dress class (0 generic, 1 tenement chimneys, 2 slab, 3 office coping), "
           "facade = the drawn facade (tools/house_zones.py FACADE, copied into building.gdshader), "
           "4 old_town is drawn by its own street list (map_builder _tenement_facades), never picked by a zone; "
           "family = what floor height and shape can tell (prewar, postwar, office), walls = sRGB palette.",
 "floor_prewar": 3.6, "floor_postwar": 3.05,
 "default_mix": {"1": 5, "9": 3, "13": 2},
 "family_default": {"prewar": "1", "postwar": "9", "office": "11"},
 "types": TYPES,
 "zones": [{"id": i, "about": a, "p": p, "mix": m, "grey_override": True, "parked": PARKED.get(i, 1.0)} for i, a, p, m in Z],
}
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game', 'data', 'house_types.json'), 'w').write(json.dumps(out, ensure_ascii=False, indent='\t') + "\n")

def shader_block():
	"""building.gdshader's const rows, between the HOUSE_TYPES markers (check_house_types compares)."""
	lines = ["// HOUSE_TYPES_BEGIN (written by tools/house_zones.py from FACADE; do not edit by hand)"]
	for i, name in enumerate("ABCD"):
		rows = ", ".join("vec4(%s)" % ", ".join("%g" % v for v in FACADE[str(t)][i * 4:i * 4 + 4]) for t in range(16))
		lines.append("const vec4 HOUSE_%s[16] = vec4[16](%s);" % (name, rows))
	lines.append("// HOUSE_TYPES_END")
	return "\n".join(lines)

sh = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game', 'shaders', 'building.gdshader')
code = open(sh, encoding='utf-8').read()
a, b = code.find("// HOUSE_TYPES_BEGIN"), code.find("// HOUSE_TYPES_END")
if a >= 0 and b > a:
	code = code[:a] + shader_block() + code[b + len("// HOUSE_TYPES_END"):]
	open(sh, 'w', encoding='utf-8').write(code)
else:
	print("house_zones: no HOUSE_TYPES markers in building.gdshader")
