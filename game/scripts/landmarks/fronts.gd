extends "res://scripts/landmarks/works.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the kept skins (SKINS), the
## street blocks with modelled fronts, the photo fronts and the single houses' fronts. Moved as it
## was from the one big file. landmarks.gd is the class the game makes; every file of
## game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd, then the areas
## in the order of landmarks.gd's `extends` chain), so code here may use this file, common.gd and
## the facade kit, never another area: a helper two areas need goes to common.gd.


# --- the low-rise landmarks (the landmarks loop) -----------------------------------------------

const SKINS := [
	{"key": "teatr", "osm": "Teatr Wielki", "mode": M_MONUMENT, "wall": "#ddd2b6", "roof": "#7fa894"},
	# F's look check (2026-11-03): LoD2's steep roof slopes in the roof's tile (`steep`), and its
	# walls on the river side of the courtyard in the Vistula front's cream (`pale`), not salmon.
	# The Royal Castle is one model, whole (F, 2026-11-26, pass 3: old_town.gd `_build_zamek`): no LoD2 is left.
	{"key": "zamek", "osm": "Zamek Królewski", "model": true, "mode": M_MONUMENT, "wall": ZAMEK_WALL, "roof": ZAMEK_ROOF},
	# The cathedral's roof is green copper (2026-11-14, photo and orthophoto); LoD2 draws it steeper than
	# the default 0.7, so `steep` 0.3 keeps its slopes in the roof colour, not the brick.
	# Floodlit at night like the real one (F, 2026-11-26; M_GOTHIC_LIT).
	{"key": "archikatedra", "osm": "Archikatedra pw. Świętego Jana Chrzciciela", "mode": M_GOTHIC_LIT, "wall": "#9a4b38", "roof": "#829a8f",
			"steep": 0.3},
	# The Jesuit church (F's Old Town trailer pass, 2026-11-08): LoD2 draws the church with its tower
	# over 55 m, so the bake gave it the office towers' blue glass. Salmon plaster with white
	# pilasters on Świętojańska and the brick tower above the roofs (Mapillary photos, refs/oldtown_jezuici2).
	{"key": "jezuici", "osm": "Sanktuarium Matki Bożej Łaskawej", "model": true, "mode": M_MONUMENT, "wall": "#dd8f82", "roof": "#6a4d44"},
	# St Anne's is a model now, whole (F, 2026-11-26): the church and, by `runs`, the bell tower's two
	# OSM blocks (the square and the octagon on it, both centred there).
	{"key": "sw_anna", "osm": "Kościół pw. Świętej Anny", "model": true, "runs": [[-689.2, -1379.6]], "mode": M_MONUMENT,
			"wall": "#e6dcc4", "roof": "#6f9f8a"},
	{"key": "sw_krzyz", "osm": "Kościół pw. Świętego Krzyża", "mode": M_MONUMENT, "wall": "#e3d9c0", "roof": "#5d6e64"},
	{"key": "staszic", "osm": "Pałac Staszica", "mode": M_MONUMENT, "wall": "#e6dcc4", "roof": "#6a8f80"},
	{"key": "wszystkich", "osm": "Kościół Wszystkich Świętych", "model": true, "mode": M_MONUMENT, "wall": "#c6b186", "roof": "#96b8a4"},
	{"key": "wizytki", "osm": "Kościół Wizytek", "model": true, "mode": M_MONUMENT, "wall": "#ecdfc0", "roof": "#6d8f7f"},
	{"key": "karmelici", "osm": "Kościół Wniebowzięcia Najświętszej Maryi Panny i świętego Józefa Oblubieńca", "mode": M_MONUMENT, "wall": "#d9cba6", "roof": "#5e8f80"},
	{"key": "zamoyski", "osm": "Pałac Zamoyskich", "mode": M_MONUMENT, "wall": "#e7dcba", "roof": "#6a6762"},
	{"key": "mikulski55", "osm": "Kamienica Mikulskiego przy Nowym Świecie 55", "mode": M_MONUMENT, "wall": "#e3c9a2", "roof": "#6d625a"},
	{"key": "mikulski53", "osm": "Kamienica Mikulskiego przy Nowym Świecie 53", "mode": M_MONUMENT, "wall": "#d8cfb6", "roof": "#6d625a"},
	{"key": "burger", "osm": "Kamienica Bürgera", "mode": M_MONUMENT, "wall": "#e8d7a8", "roof": "#6f655d"},
	{"key": "jasinski", "osm": "Kamienica Jasińskiego", "mode": M_MONUMENT, "wall": "#e5b9a0", "roof": "#6b6059"},
	{"key": "kossakowski", "osm": "Pałac Kossakowskich", "mode": M_MONUMENT, "wall": "#efe3c4", "roof": "#6e6a64"},
	# The LoD2 run for the whole U is centred in the open court, outside the mapped walls. A map-space
	# point: re-check it after a LoD2 re-bake (the court must show grass, no LoD2 mass, in a city shot).
	{"key": "potocki", "osm": "Pałac Potockich", "model": true, "run": [-669.55, -944.90],
			"mode": M_MONUMENT, "wall": "#ede8dc", "roof": "#d0643a"},
	{"key": "bristol", "osm": "Hotel Bristol", "mode": M_MONUMENT, "wall": "#e9e1c8", "roof": "#a9adb0", "model": true},
	# Plac Bankowy (2026-11-02): the palaces round the square in their real colours.
	# The Mac photo report (ratusz.md, 2026-11-02): pale ochre-cream walls under green copper;
	# the colonnades, the portico and the rotunda are models (_build_ratusz, _build_gielda).
	{"key": "ratusz", "osm": "Urząd Miasta Stołecznego Warszawy", "mode": M_MONUMENT, "wall": "#e6d6ae", "roof": "#7da894"},
	{"key": "wojewodzki", "osm": "Mazowiecki Urząd Wojewódzki", "mode": M_MONUMENT, "wall": "#e6d6ae", "roof": "#7da894"},
	{"key": "gielda", "osm": "Gmach Giełdy i Banku Polskiego", "mode": M_MONUMENT, "wall": "#e6d6ae", "roof": "#7da894"},
	{"key": "arsenal", "osm": "Arsenał", "mode": M_MONUMENT, "wall": "#e8dfc6", "roof": "#8b5a44"},
	{"key": "mniszchow", "osm": "Pałac Mniszchów", "mode": M_MONUMENT, "wall": "#e2cdb6", "roof": "#7a6a62"},
	{"key": "landau", "osm": "Dom Bankowy Landaua", "mode": M_MONUMENT, "wall": "#d9b99e", "roof": "#6e6660"},
	{"key": "kazimierzowski", "osm": "Pałac Kazimierzowski", "mode": M_MONUMENT, "wall": "#e2c77a", "roof": "#b5503a"},
	# The University's campus (F's photos, 2026-11-15, docs/landmarks/specs/uw_kampus.md): the
	# buildings in their real plaster under their real roofs; the Old Library's and Pałac Uruskich's
	# fronts are models (old_town.gd _build_stara_buw, _build_uruski). OSM names them by faculty.
	# LoD2 draws Uruski, the Tyszkiewicz palace and its annex as one model, centred outside Uruski's
	# outline (`run`): the three take the cream (the Tyszkiewicz palace is pale stone, close enough)
	# and the green copper roof F's photos 8047 and 8049 show behind Uruski's sculpture group.
	{"key": "uruski", "osm": "Wydział Geografii i Studiów Regionalnych UW", "mode": M_MONUMENT, "wall": "#ebdcb6", "roof": "#86a894",
			"run": [-469.4, -712.7]},
	{"key": "stara_buw", "osm": "Stary BUW", "mode": M_MONUMENT, "wall": "#ede4c9", "roof": "#7aa08e"},
	{"key": "uw_roch", "osm": "Instytut Kultury Polskiej UW", "mode": M_MONUMENT, "wall": "#eeebe2", "roof": "#8e908d"},
	{"key": "uw_jezyki", "osm": "Centrum Nauczania Języków Obcych UW", "mode": M_MONUMENT, "wall": "#e9e9e3", "roof": "#9a9c9a"},
	{"key": "uw_pomuzealny", "osm": "Wydział Historii UW", "mode": M_MONUMENT, "wall": "#e8e0c9", "roof": "#8a8d8a"},
	{"key": "uw_szkola_glowna", "osm": "Wydział Archeologii UW", "mode": M_MONUMENT, "wall": "#e2c77e", "roof": "#b5553c"},
	{"key": "uw_porektorski", "osm": "Wydział Kultur Azji i Afryki", "mode": M_MONUMENT, "wall": "#e8dcbc", "roof": "#b5553c"},
	{"key": "uw_poseminaryjny", "osm": "Wydział Prawa i Administracji UW", "mode": M_MONUMENT, "wall": "#ece6d6", "roof": "#b65a3c"},
	{"key": "uw_audytoryjny", "osm": "Wydział Nauk Politycznych i Studiów Międzynarodowych", "mode": M_MONUMENT, "wall": "#e8dfc8", "roof": "#8a8d8a"},
	{"key": "uw_mineralogiczny", "osm": "Wydział Polonistyki UW", "mode": M_MONUMENT, "wall": "#e9dcc0", "roof": "#b5553c"},
	{"key": "auditorium_maximum", "osm": "Auditorium Maximum", "mode": M_MONUMENT, "wall": "#e4ddcc", "roof": "#8d8e8a"},
	{"key": "sejm", "osm": "Sejm RP", "mode": M_MONUMENT, "wall": "#e2e0d8", "roof": "#8d8f8c"},
	# The Mac photo reports (2026-11-02): the masses in their stone; the fronts are models.
	{"key": "filharmonia", "osm": "Filharmonia Narodowa", "mode": M_MONUMENT, "wall": "#e3ded2", "roof": "#8e9392"},
	{"key": "teatr_polski", "osm": "Teatr Polski", "mode": M_MONUMENT, "wall": "#e2ddcd", "roof": "#76a08c"},
	# Poczta Główna (the Mac photo report and F's look check, 2026-11-03): pale warm stone with a
	# pink cast (POCZTA_WALL); its
	# front, corner dome and glazed hall are the site's own model (_build_poczta).
	{"key": "poczta", "osm": "Poczta Główna", "mode": M_MONUMENT, "wall": "#ecd2c2", "roof": "#77706b"},
	# Politechnika's main building (F's photos, 2026-11-15, spec politechnika.md): cream plaster
	# over a grey zinc roof; the main hall's glass roof (`keep`) keeps LoD2's own colour; the
	# columned middle of the front on Plac Politechniki is the site's own model (_build_politechnika).
	{"key": "politechnika", "osm": "Gmach Główny PW", "mode": M_MONUMENT, "wall": "#ece6d8", "roof": "#8b9094",
			"keep": [Vector2(-958.0, 1459.0), Vector2(-914.0, 1459.0), Vector2(-914.0, 1508.0), Vector2(-958.0, 1508.0)]},
	# Miodowa's and Senatorska's palaces from F's photos (2026-11-07, docs/landmarks/specs/miodowa.md):
	# cream and pink plaster under tile-red roofs; Paca's roofs are green copper.
	{"key": "branickich", "osm": "Pałac Branickich", "near": Vector2(-852.0, -1425.0), "mode": M_MONUMENT,
			"wall": "#ecd7c2", "roof": "#a85f45"},
	{"key": "mlodziejowski", "osm": "Pałac Młodziejowskiego", "mode": M_MONUMENT, "wall": "#f0e8d2", "roof": "#b3583c"},
	{"key": "szaniawski", "osm": "Pałac Szaniawskich", "mode": M_MONUMENT, "wall": "#efe9db", "roof": "#a85f45"},
	{"key": "chodkiewicz", "osm": "Pałac Chodkiewiczów", "mode": M_MONUMENT, "wall": "#eadfc4", "roof": "#a85f45"},
	{"key": "arcybiskupi", "osm": "Pałac Arcybiskupi d. Pałac Borchów", "mode": M_MONUMENT, "wall": "#e8dcae", "roof": "#ad6446"},
	{"key": "paca", "osm": "Pałac Paca", "mode": M_MONUMENT, "wall": "#ebe3cc", "roof": "#7fa391"},
	{"key": "nobilium", "osm": "Collegium Nobilium", "mode": M_MONUMENT, "wall": "#e8dcc2", "roof": "#8c8f86"},

	# Saski Crescent and Senator from F's photos (2026-11-07, docs/landmarks/specs/saski.md): the
	# crescent's green-teal curtain wall (M_GLASS) and Senator's pale cladding with punched windows.
	{"key": "saski", "osm": "Saski Crescent", "hull": true, "mode": M_GLASS, "wall": "#5f948f", "roof": "#7d8589"},
	{"key": "senator", "osm": "Senator", "mode": M_SKIN + float(S_PUNCHED) / 16.0, "wall": "#dbd0bc", "roof": "#a3a7a8"},
	# The office pass from F's photos (2026-11-07, docs/landmarks/specs/offices.md): Brama Zachodnia's apricot
	# cladding, Proximo I's glass with ochre mullions, Proximo II's dark glass.
	{"key": "brama_zach", "osm": "Brama Zachodnia", "hull": true, "mode": M_SKIN + float(S_PUNCHED) / 16.0, "wall": "#d9a27c", "roof": "#878d8f"},
	{"key": "proximo1", "osm": "Proximo I", "hull": true, "mode": M_GLASS, "wall": "#667f93", "roof": "#6d7377"},
	{"key": "proximo2", "osm": "Proximo II", "hull": true, "mode": M_SKIN + float(S_DARK) / 16.0, "wall": "#35495b", "roof": "#596168"},
	# NBP's regional branch on Plac Powstańców from F's photos (2026-11-16, docs/landmarks/specs/nbp.md):
	# the whole building is the site's own model (_build_nbp), dark folded panels over a glass ground floor.
	{"key": "nbp", "osm": "NBP Oddział Okręgowy w Warszawie", "model": true, "mode": M_STONE, "wall": "#4d4446", "roof": "#6f7173"},
	# The mapped theatre registers here as a whole model, so its LoD2 run is replaced.
	{"key": "powszechny", "osm": "Teatr Powszechny", "model": true, "mode": M_STONE, "wall": "#ebe8df", "roof": "#b9babc"},
	# PKO BP's office on Marszałkowska by Nowogrodzka from Mapillary photos (2026-11-16,
	# docs/landmarks/specs/pko_marszalkowska.md): light grey bands round the floors with blue ribbon
	# glazing between them, not the dark glass box LoD2 gave it.
	{"key": "pko_marszalkowska", "osm": "PKO BP", "mode": M_SKIN + float(S_RIBBON) / 16.0, "wall": "#4f7db8", "roof": "#8a9094"},
	# Its neighbour Wolf Marszałkowska (the same photos): a glass tower with silver floor bands
	# over a dark stone and glass base, not a dark punched block.
	{"key": "wolf_marszalkowska", "osm": "Wolf Marszałkowska", "mode": M_SKIN + float(S_BANDS) / 16.0, "wall": "#5f7a90", "roof": "#596066"},
	{"key": "mostowski", "osm": "Pałac Mostowskich", "model": true, "mode": M_STONE, "wall": "#eee3c9", "roof": "#818594"},
]


func _find_skins() -> void:
	for t: Dictionary in SKINS:
		# `near` picks one of several outlines that share a name (two "Pałac Branickich")
		var outline := _landmark_near(t["osm"], t["near"], 60.0) if t.has("near") else _landmark(t["osm"])
		if outline.size() < 3:
			continue
		# `hull`: a curved plan's centre falls outside it (Saski Crescent), so the hull joins the zone
		var zones: Array = [outline, Geometry2D.convex_hull(outline)] if t.get("hull", false) else [outline]
		# `run`: a point inside a LoD2 model that merges this building with its neighbours, whose
		# centre falls outside the outline (Pałac Uruskich, the Tyszkiewicz palace and its annex are
		# one LoD2 run): a 2 m square there joins the zone, so `skin_at` finds that run too
		# `runs`: the same for several points (a model's other blocks: St Anne's bell tower)
		var runs: Array = t.get("runs", [])
		if t.has("run"):
			runs = runs + [t["run"]]
		for r: Array in runs:
			var c := Vector2(float(r[0]), float(r[1]))
			zones.append(PackedVector2Array([c + Vector2(-1, -1), c + Vector2(1, -1), c + Vector2(1, 1), c + Vector2(-1, 1)]))
		_add_site(t["key"], zones)
		# `model`: the whole building is a model now (it replaces LoD2); the entry keeps its place in
		# the site order (tap ids) and its wall colour for the skyline (tower_colour)
		if t.get("model", false):
			continue
		if not sites.is_empty() and sites[-1]["key"] == t["key"]:
			sites[-1]["skin"] = {"mode": M_MONUMENT_FLOOD if FLOODLIT_SITES.has(t["key"]) and t["mode"] == M_MONUMENT else t["mode"], "wall": Color(t["wall"]), "roof": Color(t["roof"])}
			if t.has("steep"):
				sites[-1]["skin"]["steep"] = t["steep"]
			if t.has("upper"):
				sites[-1]["skin"]["upper"] = {"over": float(t["upper"][0]), "wall": Color(t["upper"][1])}
			if t.has("keep"):
				sites[-1]["skin"]["keep"] = PackedVector2Array(t["keep"])


# --- Domy Towarowe Centrum (the Eastern Wall) ----------------------------------------------

## R1 (docs/design/start-area-real.md): the old Kino Relax behind Junior (Złota 8, 1970, Poland's
## first 70 mm cinema), heritage-listed and reopened as the theatre Scena Relax: its name in
## letters on the roof edge the start's camera sees. Only a sign (the building stays the map's).
const RELAX_RED := Color(0.86, 0.1, 0.16)  # the red word on the yellow banner
## The word in a 3 x 5 grid, row by row from the top.
const RELAX_GLYPHS := ["110101110101101", "111100110100111", "100100100100111", "010101111101101", "101101010101101"]


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

# --- street blocks with modelled fronts ------------------------------------------------------

const BLOCKS_DIR := "res://data/street_blocks"

## game/data/street_blocks/index.json lists each modelled block's id and our outline: a site
## "blk_<id>" over it. `extra` claims an L-shaped LoD2 block's box centre, which falls outside the
## outline. A skin on the same outline stays (its card and name); only the block's LoD2 goes.


# --- The Dekalog estate and the Inflancka pools (F's photos, 2026-11-07) -------------------------

## The street blocks (game/data/street_blocks) that stood in for four of them: the site builds those.
const DE_BLOCKS := ["118344657", "118344539", "279988290", "138607846"]
## The Institute next to St Anne's (Krakowskie Przedmieście 66): a model of its own since
## 2026-11-26 (churches.gd `_build_nikidw`), its street block no longer stands in for it.
const NIKIDW_BLOCK := "43281056"
## The Mansjonaria on Plac Zamkowy, likewise (old_town.gd `_build_mansjonaria`, 2026-11-26).
const MANSJONARIA_BLOCK := "101331240"

## Street blocks that stood under a landmark built whole, so the building was drawn twice (z-fighting
## walls, two roofs; check_sites lists the pairs). Looked at in the city one by one (2026-11-26):
## the landmark reads better in each, so the block goes.
const LM_BLOCKS := [
	"28010955", "28010954", "44190667", "44190669",  # Aleje Jerozolimskie 57-63: the four houses, built whole
	"1456269648", "1149651967",  # Prosta 28: the tower and its annex from the photos
	"1186516012", "1186516013",  # Towarowa Towers (asbud): the quarter is rebuilt whole
	"32129912",  # the blue glass tower on Plac Powstańców: its LoD2 mesh is open (see-through)
	"338542425",  # Marszałkowska 99's white slab
	"6520917",  # Grzybowska 77 (Bellona): the brick house from F's photos
	"905863487",  # Unique Tower's north and shoulder outline, rebuilt by the unique site
	"141043447",  # Kino Muranów: whole complex (podium + residential blocks) rebuilt in muranow.gd
	"1371716",  # Pałac Mostowskich: the whole palace and its roofs are built in muranow.gd
]


func _find_blocks() -> void:
	if not FileAccess.file_exists(BLOCKS_DIR + "/index.json"):
		return
	var list = JSON.parse_string(FileAccess.get_file_as_string(BLOCKS_DIR + "/index.json"))
	if not list is Array:
		return
	for d: Dictionary in list:
		var q := _pts(d["outline"])
		if q.size() < 3:
			continue
		if str(d["id"]) in DE_BLOCKS or str(d["id"]) in LM_BLOCKS \
				or str(d["id"]) in [CM_BLOCK, MP_BLOCK, UP_BLOCK, NIKIDW_BLOCK, MANSJONARIA_BLOCK]:
			continue
		var key := "blk_" + str(d["id"])
		var zone: Array = [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))]
		for e: Array in d.get("extra", []):
			var c := Vector2(e[0], e[1])
			zone.append(PackedVector2Array([c + Vector2(-2, -2), c + Vector2(2, -2), c + Vector2(2, 2), c + Vector2(-2, 2)]))
		_add_site(key, zone)
		if not sites.is_empty() and sites[-1]["key"] == key:
			sites[-1]["ring"] = q
			sites[-1]["raw"] = q
			sites[-1]["block"] = str(d["id"])
			if d.get("lawn", false):
				sites[-1]["lawn"] = true
			if d.has("cap"):
				sites[-1]["cap"] = d["cap"]
			if d.get("roof", false):
				sites[-1]["lod2_roof"] = true
				if d.has("eaves") and (d["eaves"] as Array).size() == q.size():
					sites[-1]["eaves"] = d["eaves"]


## A covered filter bed: a flat grass plateau over the outline, lifted clear of the terrain under
## it (the real beds are raised lawns), and the block's vents and chambers stand on top of it.
func _block_lawn(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["raw"]
	var box := _box_of([ring])
	var hi := _g
	var x := box.position.x
	while x < box.end.x:
		var z := box.position.y
		while z < box.end.y:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), ring):
				hi = maxf(hi, map.terrain_height(x, z))
			z += 6.0
		x += 6.0
	var lawn := Color("#7ca057")
	_prism(ring, _g - 1.0, hi + 0.35, lawn.darkened(0.12), lawn, M_STONE, M_STONE)
	_g = hi - 1.9  # their lawn lies at about 2.5 m, about the plateau's top


## A modelled block: its triangles as they are, on our ground. Walls and trim are plain stone in
## their own colours, the real panes are M_PANE (lit one by one at night), a `facade` wall takes the
## ordinary building shader's windows, roofs take the roof material. One gzipped file per block:
## u32 header size, the JSON header, then per group int16 centimetres from (ox, oz) and, for glass,
## one byte per triangle, the pane's number. Read only when its sector is built.
func _build_block(site: Dictionary) -> void:
	var raw := FileAccess.get_file_as_bytes(BLOCKS_DIR + "/" + site["block"] + ".bin")
	if raw.is_empty():
		return
	var data := raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var head_size := data.decode_u32(0)
	var d = JSON.parse_string(data.slice(4, 4 + head_size).get_string_from_utf8())
	var at := 4 + head_size
	_g = _ground_under(site["raw"])
	var seed := fposmod(float(str(site["block"]).hash() % 1000) / 1000.0, 1.0) * 0.98 + 0.01
	if site.has("lawn"):
		_block_lawn(site)
	if site.has("cap"):  # a hall whose model leaves its middle open: a slate roof over the outline
		var slate := Color("#4f5558")
		_prism(_largest(Geometry2D.offset_polygon(site["raw"], -0.4, Geometry2D.JOIN_MITER)), _g + float(site["cap"]) - 0.4, _g + float(site["cap"]), slate, slate, M_STONE, M_STONE)
	var keep := _mode
	var ox: float = d["ox"]
	var oz: float = d["oz"]
	var top: float = d["top"]
	var piure: bool = site["block"] == PIURE_BLOCK
	var plain_front: bool = site["block"] in PLAIN_FRONT_BLOCKS
	var piure_wins: Array = []
	for grp: Dictionary in d["groups"]:
		var col := Color(grp["color"])
		var role: String = grp["role"]
		var tris: int = grp["n"]
		var panes := at + tris * 18
		var wins: bool = piure and str(grp["color"]).to_lower() == PIURE_WINDOW
		for i in tris:
			var q: Array[Vector3] = []
			for k in 3:
				var o := at + i * 18 + k * 6
				q.append(Vector3(data.decode_s16(o) * 0.01 + ox, data.decode_s16(o + 2) * 0.01 + _g, data.decode_s16(o + 4) * 0.01 + oz))
			var n := (q[1] - q[0]).cross(q[2] - q[0])
			if n.length_squared() < 1e-8:
				continue
			n = n.normalized()
			if n.y < -0.3:
				n = -n
			if wins and absf(n.y) < 0.3:
				piure_wins.append([q[0], q[1], q[2], n])
			if role == "roof":
				_mode = seed
				_tri(q[0], q[1], q[2], n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), 0.0)
				continue
			if absf(n.y) >= 0.3:
				_mode = M_STONE
				_tri(q[0], q[1], q[2], n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), 0.0)
				continue
			var t := Vector2(-n.z, n.x).normalized()
			var ua := Vector2(Vector2(q[0].x, q[0].z).dot(t), q[0].y - _g)
			var ub := Vector2(Vector2(q[1].x, q[1].z).dot(t), q[1].y - _g)
			var uc := Vector2(Vector2(q[2].x, q[2].z).dot(t), q[2].y - _g)
			if role == "facade" and plain_front:
				_mode = M_STONE  # its own modelled windows only (PLAIN_FRONT_BLOCKS)
				_tri(q[0], q[1], q[2], n, col, ua, ub, uc, 0.0, false)
			elif role == "facade":
				_mode = seed
				_tri(q[0], q[1], q[2], n, col, ua, ub, uc, top, false)
			else:
				_mode = M_PANE + data[panes + i] / 256.0 if role == "glass" else M_STONE
				_tri(q[0], q[1], q[2], n, col, ua, ub, uc, 0.0, false)
		at = panes + (tris if role == "glass" else 0)
	if piure:
		_piure_strips(piure_wins)
	_mode = keep
	_collide_raw(site)


## Blocks whose `facade` walls are their main fronts, in front of their own modelled windows: the
## building shader's windows on those walls stood among the model's, two grids of different
## panes and sills over each other (F, 2026-11-26, Kamienica Roesslera i Hurtiga opposite St Anne's:
## "some have artifacts"). Their facade walls are plain plaster in the block's colour.
const PLAIN_FRONT_BLOCKS := ["30302033"]


## HOTEL PIURE (Widok 9, F's photos 2026-11-11): the street block's white panel fronts carry a
## beige textured strip beside every window, lit from below at dusk, on the window's right on one
## floor and its left on the next, so the fronts read as the real staggered weave. Built from the
## block's own window boxes on its two long fronts (LORETKA's frame, `loretka_plan`): a strip
## stands on the window's outer face, beside it, unless another window is there.
const PIURE_BLOCK := "28759008"
const PIURE_WINDOW := "#55717b"
const PIURE_STRIP := Color("#e2d3b2")
const PIURE_STRIP_W := 0.55
const PIURE_STRIP_GAP := 0.05
const PIURE_FLOOR := 3.8   # the block's storey (its windows start at 4.68 m and repeat every 3.8 m)


func _piure_strips(wins: Array) -> void:
	var plan := loretka_plan(data)
	if plan.is_empty() or wins.is_empty():
		return
	_o = plan["o"]
	_a = plan["a"]
	_b = plan["b"]
	var mid := (float(plan["v1"]) + 1.3) * 0.5
	# Each window box's outer face on a long front: [front (-1 the frame's own side, +1 the far
	# one), u0, u1, y0, y1, v of the face], keyed by its rectangle (a quad's two triangles share it).
	var rects := {}
	for w: Array in wins:
		var n: Vector3 = w[3]
		var along_b := Vector2(n.x, n.z).dot(_b)
		if absf(along_b) < 0.9:
			continue
		var us := PackedFloat32Array()
		var vs := 0.0
		var y0 := INF
		var y1 := -INF
		for k in 3:
			var p: Vector3 = w[k]
			var d := Vector2(p.x, p.z) - _o
			us.append(d.dot(_a))
			vs += d.dot(_b) / 3.0
			y0 = minf(y0, p.y)
			y1 = maxf(y1, p.y)
		var front := -1 if vs < mid else 1
		if (along_b > 0.0) != (front > 0):
			continue  # the box's inner face
		var u0 := minf(us[0], minf(us[1], us[2]))
		var u1 := maxf(us[0], maxf(us[1], us[2]))
		if u1 - u0 < 0.8 or y1 - y0 < 1.5 or y1 - y0 > 3.5:
			continue
		var key := "%d:%.1f:%.1f:%.1f" % [front, u0, u1, y0]
		var r: Array = rects.get(key, [front, u0, u1, y0, y1, vs])
		r[5] = minf(float(r[5]), vs) if front < 0 else maxf(float(r[5]), vs)
		rects[key] = r
	var list := rects.values()
	_mode = M_LAMP
	for r: Array in list:
		var front: int = r[0]
		var u0: float = r[1]
		var u1: float = r[2]
		var y0: float = r[3]
		var y1: float = r[4]
		var floor_i := roundi((y0 - _g) / PIURE_FLOOR)
		var right := floor_i % 2 == 0
		for attempt in 2:
			var su := u1 + PIURE_STRIP_GAP + PIURE_STRIP_W * 0.5 if right else u0 - PIURE_STRIP_GAP - PIURE_STRIP_W * 0.5
			if not _piure_free(list, r, su, y0, y1):
				right = not right
				continue
			# 10 cm proud of the window's face (outwards is -_b on the near front, +_b on the far
			# one), 4 cm into it.
			var cv := float(r[5]) + 0.03 * front
			_lbox(su, cv, PIURE_STRIP_W * 0.5, 0.07, y0, y1, PIURE_STRIP, M_LAMP, PIURE_STRIP)
			break
	_mode = M_STONE


## Whether a strip centred at `su` from y0 to y1 on `own`'s front keeps clear of every other window.
func _piure_free(list: Array, own: Array, su: float, y0: float, y1: float) -> bool:
	var h := PIURE_STRIP_W * 0.5 + 0.05
	for r: Array in list:
		if r == own or int(r[0]) != int(own[0]):
			continue
		if float(r[4]) <= y0 + 0.1 or float(r[3]) >= y1 - 0.1:
			continue
		if float(r[2]) > su - h and float(r[1]) < su + h:
			return false
	return true


# --- Kamienica Pod Gigantami (F, 2026-11-06): spec docs/landmarks/specs/gigantami.md ------------

const GG_OUTLINE := [2.6, 757.7, 4.1, 766.2, -3.0, 767.5, -6.0, 768.0, -6.5, 767.5, -15.6, 769.0, -15.0, 773.6, -14.0, 773.5,
		-13.4, 774.2, -13.2, 777.5, -12.7, 778.1, -12.2, 781.6, -12.7, 782.3, -14.0, 782.4, -13.6, 784.8, -11.5, 786.3,
		-9.9, 784.3, -3.9, 783.6, -4.1, 782.3, -0.6, 781.8, 6.5, 780.4, 7.9, 788.7, -27.7, 793.6, -31.8, 764.9, -32.1, 763.1]
const GG_N := Vector2(-32.1, 763.1)  # the street front's north corner, on Aleje Ujazdowskie
const GG_S := Vector2(-27.7, 793.6)
const GG_STONE := Color("#b5ae9f")
const GG_BASE := Color("#a29b8c")
const GG_PALE := Color("#cfc8b8")
const GG_GLASS := Color("#2e3840")
const GG_IRON := Color("#2b2d2e")
const GG_BAY := 3.42
const GG_FLOORS := [5.4, 9.6, 13.4, 17.0]  # sills of the four upper storeys


## A giant, a block figure of about 4 m: legs on the pier, a bowed torso and head, one arm up to the
## balcony. `side` is -1 or 1 from the gate: the arm reaching up stands on the gate's side.
func _gg_giant(u: float, side: float, g: float) -> void:
	var c := GG_PALE.lightened(0.08)
	_lbox(u - 0.2, 0.92, 0.18, 0.22, g + 1.5, g + 3.0, c)
	_lbox(u + 0.2, 0.92, 0.18, 0.22, g + 1.5, g + 3.0, c)
	_lbox(u, 0.98, 0.42, 0.28, g + 3.0, g + 4.3, c)
	_lbox(u + side * 0.14, 1.04, 0.34, 0.24, g + 4.3, g + 4.8, c)
	_lbox(u + side * 0.2, 1.14, 0.17, 0.17, g + 4.8, g + 5.14, c)
	_lbox(u - side * 0.5, 0.92, 0.13, 0.15, g + 3.7, g + 5.5, c)
	_lbox(u + side * 0.56, 0.98, 0.12, 0.14, g + 2.7, g + 4.0, c)


## The street front on Aleje Ujazdowskie, 30.8 m and nine bays: a banded stone ground floor, patterned
## stone above, pale pilasters round the middle bays, the long iron balcony on the third storey, a
## deep cornice with a balustrade, and the gate with its two giants under a small balcony.
func _build_gigantami(site: Dictionary) -> void:
	_o = GG_N
	_a = (GG_S - GG_N).normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front
	kit_face(0.34)
	var width := GG_N.distance_to(GG_S)
	var mid := width * 0.5
	var ring := _pts(GG_OUTLINE)
	_g = _ground_under(ring)
	var g := _g
	_lbox(mid, 0.14, mid, 0.2, g - 0.3, g + 4.9, GG_BASE)
	_lbox(mid, 0.14, mid, 0.2, g + 4.9, g + 21.0, GG_STONE)
	for y: float in [1.2, 2.4, 3.6]:
		_lbox(mid, 0.34, mid, 0.03, g + y, g + y + 0.09, GG_BASE.darkened(0.14))
	_lbox(mid, 0.36, mid, 0.08, g + 4.75, g + 5.1, GG_PALE)
	for k in 9:
		var u := mid + (k - 4) * GG_BAY
		if k != 4:
			_lbox(u, 0.36, 0.95, 0.03, g + 1.0, g + 3.8, GG_GLASS)
			_lbox(u, 0.4, 1.05, 0.1, g + 3.8, g + 4.0, GG_PALE)
		for i in GG_FLOORS.size():
			kit_window(u, g + GG_FLOORS[i], 2.5 if i < 2 else 2.2, Win.HOODED if i == 1 else Win.FRAMED, GG_PALE, GG_GLASS, 0.72)
	for k: float in [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]:  # the pilasters round the middle
		_lbox(mid + k * GG_BAY, 0.42, 0.26, 0.12, g + 9.3, g + 19.6, GG_PALE)
	# The long balcony, seven bays, on brackets, and the two small ones above it.
	var half := GG_BAY * 3.6
	_lbox(mid, 0.9, half, 0.62, g + 9.2, g + 9.42, GG_PALE)
	_lbox(mid, 1.48, half, 0.04, g + 10.32, g + 10.4, GG_IRON)
	_lbox(mid, 1.48, half, 0.03, g + 9.42, g + 9.56, GG_IRON)
	var bars := 40
	for k in bars + 1:
		_lbox(mid - half + 2.0 * half * k / bars, 1.48, 0.03, 0.03, g + 9.56, g + 10.32, GG_IRON)
	_lbox(mid - half, 0.9, 0.03, 0.6, g + 9.42, g + 10.4, GG_IRON)
	_lbox(mid + half, 0.9, 0.03, 0.6, g + 9.42, g + 10.4, GG_IRON)
	for k: int in [-3, 3]:
		var u: float = mid + k * GG_BAY
		_lbox(u, 0.78, 1.1, 0.42, g + 13.1, g + 13.3, GG_PALE)
		_lbox(u, 1.18, 1.1, 0.03, g + 14.12, g + 14.2, GG_IRON)
		for j in 7:
			_lbox(u - 1.1 + j * 2.2 / 6.0, 1.18, 0.03, 0.03, g + 13.3, g + 14.12, GG_IRON)
	# The cornice, its frieze and the balustrade on top.
	_lbox(mid, 0.3, mid, 0.14, g + 19.7, g + 20.2, GG_PALE)
	_lbox(mid, 0.72, mid + 0.4, 0.56, g + 20.6, g + 21.2, GG_PALE)
	_lbox(mid, 0.32, mid, 0.14, g + 21.2, g + 22.2, GG_STONE)
	_lbox(mid, 0.32, mid + 0.1, 0.18, g + 22.2, g + 22.4, GG_PALE)
	# The gate, its piers, the giants and the small balcony they hold.
	_lbox(mid, 0.38, 1.25, 0.04, g, g + 3.4, Color("#241d1a"))
	_prism(_rect(mid, 0.38, 0.9, 0.05), g + 3.4, g + 4.1, Color("#241d1a"), Color("#241d1a"), M_STONE, M_STONE)
	_lbox(mid - 1.95, 0.72, 0.6, 0.58, g, g + 1.5, GG_PALE)
	_lbox(mid + 1.95, 0.72, 0.6, 0.58, g, g + 1.5, GG_PALE)
	_gg_giant(mid - 1.95, 1.0, g)
	_gg_giant(mid + 1.95, -1.0, g)
	_lbox(mid, 1.0, 2.7, 0.76, g + 5.5, g + 5.84, GG_PALE)
	_lbox(mid, 1.7, 2.7, 0.1, g + 5.84, g + 6.7, GG_PALE)
	_lbox(mid - 2.65, 1.0, 0.1, 0.72, g + 5.84, g + 6.7, GG_PALE)
	_lbox(mid + 2.65, 1.0, 0.1, 0.72, g + 5.84, g + 6.7, GG_PALE)


# --- Szpitalna 5 (F's photos, 2026-11-06): spec docs/landmarks/specs/szpitalna5.md --------------

const SZ_OUTLINE := [-669.3, 128.2, -673.5, 120.4, -673.2, 120.3, -677.4, 112.8, -679.6, 106.5, -644.4, 93.2, -643.4, 92.8,
		-636.4, 105.1, -634.7, 108.2, -627.5, 120.5, -641.8, 126.5, -655.0, 131.9, -665.1, 136.1]
const SZ_CORNER := Vector2(-643.4, 92.8)  # Szpitalna meets Przeskok
const SZ_SOUTH := Vector2(-627.5, 120.5)
const SZ_WEST := Vector2(-679.6, 106.5)
const SZ_WALL := Color("#e8c9a6")
const SZ_WHITE := Color("#f1ece0")
const SZ_BASE := Color("#e6dfd1")
const SZ_GLASS := Color("#2e3a44")
const SZ_IRON := Color("#26282a")
const SZ_FLOORS := [5.3, 9.3, 13.2, 17.1, 20.8]  # sills of the five upper storeys
const SZ_TOP := 24.6


## One street front from `from` to `to`, seen with the street on its left-hand normal: `bays` bays;
## storeys above the first carry balconies at `balconies`; `arch` is the bay with the blind arch.
func _sz_front(from: Vector2, to: Vector2, bays: int, balconies: Array, arch: int) -> void:
	_o = from
	_a = (to - from).normalized()
	_b = Vector2(-_a.y, _a.x)
	kit_face(0.34)
	var width := from.distance_to(to)
	var bay := width / bays
	var mid := width * 0.5
	var g := _g
	_lbox(mid, 0.14, mid, 0.2, g - 0.3, g + 4.9, SZ_BASE)
	_lbox(mid, 0.14, mid, 0.2, g + 4.9, g + SZ_TOP, SZ_WALL)
	for y: float in [1.3, 2.5, 3.7]:
		_lbox(mid, 0.34, mid, 0.03, g + y, g + y + 0.08, SZ_BASE.darkened(0.1))
	_lbox(mid, 0.38, mid, 0.1, g + 4.7, g + 5.05, SZ_WHITE)
	_lbox(mid, 0.38, mid, 0.08, g + 12.9, g + 13.05, SZ_WHITE)
	_lbox(mid, 0.38, mid, 0.08, g + 16.8, g + 16.95, SZ_WHITE)
	for k in bays:
		var u := (k + 0.5) * bay
		_lbox(u, 0.36, 1.0, 0.03, g + 0.9, g + 3.8, SZ_GLASS)
		_lbox(u, 0.4, 1.12, 0.09, g + 3.8, g + 4.0, SZ_WHITE)
		for i in SZ_FLOORS.size():
			if k == arch and i >= 3:
				continue
			kit_window(u, g + SZ_FLOORS[i], 2.35 if i < 3 else 2.0, Win.PEDIMENT if i == 0 else Win.SILL_HEAD, SZ_WHITE, SZ_GLASS, 0.68)
			if i > 0 and k in balconies:
				kit_balcony(u, g + SZ_FLOORS[i], 1.25, Balcony.IRON, SZ_IRON, SZ_WHITE)
	if arch >= 0:  # the blind arch over the top two storeys: white frame, peach panel
		var u := (arch + 0.5) * bay
		_lbox(u - 1.2, 0.36, 0.14, 0.1, g + 17.0, g + 22.6, SZ_WHITE)
		_lbox(u + 1.2, 0.36, 0.14, 0.1, g + 17.0, g + 22.6, SZ_WHITE)
		_lbox(u, 0.36, 1.2, 0.1, g + 23.4, g + 23.6, SZ_WHITE)
		_lbox(u, 0.36, 0.85, 0.1, g + 23.0, g + 23.4, SZ_WHITE)
		_lbox(u, 0.36, 1.05, 0.1, g + 22.6, g + 23.0, SZ_WHITE)
	# Corner pilasters, the cornice and a white band under it.
	_lbox(0.3, 0.4, 0.34, 0.12, g + 5.1, g + SZ_TOP - 0.6, SZ_WHITE)
	_lbox(width - 0.3, 0.4, 0.34, 0.12, g + 5.1, g + SZ_TOP - 0.6, SZ_WHITE)
	_lbox(mid, 0.34, mid, 0.14, g + SZ_TOP - 0.7, g + SZ_TOP - 0.3, SZ_WHITE)
	_lbox(mid, 0.75, mid + 0.5, 0.58, g + SZ_TOP - 0.3, g + SZ_TOP + 0.2, SZ_WHITE)


## Szpitalna 5, from F's two photos: five plastered storeys over a banded white ground floor, iron
## balconies on the Szpitalna front, the blind arch at the corner on the Przeskok front.
func _build_szpitalna5(site: Dictionary) -> void:
	_g = _ground_under(_pts(SZ_OUTLINE))
	_sz_front(SZ_SOUTH, SZ_CORNER, 10, [3, 7], -1)
	_sz_front(SZ_CORNER, SZ_WEST, 12, [], 1)


# --- Kamienica Wedla (F's photos, 2026-11-06): spec docs/landmarks/specs/wedel.md ---------------

const WD_OUTLINE := [-635.4, 66.8, -597.4, 53.2, -593.1, 65.7, -592.5, 67.3, -602.6, 71.1, -602.3, 71.9, -607.1, 73.6, -607.4, 72.9,
		-611.9, 74.5, -612.4, 74.3, -613.4, 71.3, -616.5, 72.4, -616.6, 73.3, -616.7, 74.0, -616.1, 74.2, -614.6, 77.0, -615.0, 78.3,
		-614.2, 79.7, -613.6, 80.6, -611.6, 81.5, -603.4, 78.6, -602.7, 78.6, -602.2, 80.8, -599.9, 80.0, -599.3, 80.4, -598.3, 83.3,
		-611.5, 88.0, -622.2, 91.8, -623.7, 92.7, -627.5, 86.4, -636.7, 70.1, -636.4, 70.0, -635.7, 67.9, -635.4, 67.1]
const WD_CORNER := Vector2(-636.2, 67.0)  # the corner under the zebra
const WD_EAST := Vector2(-597.4, 53.2)  # the Górskiego front's far end
const WD_SOUTH := Vector2(-623.7, 92.7)  # the Szpitalna front's far end
const WD_WHITE := Color("#efe9dc")
const WD_SHADE := Color("#d9d1c0")
const WD_ZINC := Color("#71828a")
const WD_BAND := Color("#6a5f53")
const WD_AWNING := Color("#6e2a2e")
const WD_GLASS := Color("#2c3640")
const WD_IRON := Color("#23262a")
const WD_EAVE := 19.6


## A dormer standing on the mansard at bay centre u: a window in a white frame under a zinc cap.
func _wd_dormer(u: float, g: float) -> void:
	_lbox(u, -0.6, 0.82, 0.7, g + WD_EAVE - 0.1, g + WD_EAVE + 2.6, WD_WHITE)
	_lbox(u, 0.13, 0.52, 0.03, g + WD_EAVE + 0.7, g + WD_EAVE + 2.2, WD_GLASS)
	_lbox(u, -0.6, 1.0, 0.82, g + WD_EAVE + 2.6, g + WD_EAVE + 2.85, WD_WHITE)
	_lbox(u, -0.6, 0.6, 0.6, g + WD_EAVE + 2.85, g + WD_EAVE + 3.1, WD_ZINC)


## One street front from `from` to `to` in `bays` bays: dark banded piers and burgundy awnings at
## street level, three white storeys (arched on top), a heavy cornice, dormers on the mansard.
func _wd_front(from: Vector2, to: Vector2, bays: int) -> void:
	_o = from
	_a = (to - from).normalized()
	_b = Vector2(-_a.y, _a.x)
	kit_face(0.34)
	var width := from.distance_to(to)
	var bay := width / bays
	var mid := width * 0.5
	var g := _g
	_lbox(mid, 0.14, mid, 0.2, g - 0.3, g + 5.4, WD_SHADE)
	_lbox(mid, 0.14, mid, 0.2, g + 5.4, g + WD_EAVE, WD_WHITE)
	_lbox(mid, 0.42, mid, 0.14, g + 5.1, g + 5.6, WD_WHITE)
	_lbox(mid, 0.42, mid, 0.1, g + 9.5, g + 9.72, WD_SHADE)
	_lbox(mid, 0.42, mid, 0.1, g + 13.5, g + 13.72, WD_SHADE)
	for k in bays:
		var u := (k + 0.5) * bay
		_lbox(u, 0.36, 1.05, 0.03, g + 0.4, g + 4.0, WD_GLASS)
		var awning := PackedVector2Array([_w(u - 1.2, 0.3), _w(u + 1.2, 0.3), _w(u + 1.2, 1.5), _w(u - 1.2, 1.5)])
		_prism(awning, g + 3.5, g + 4.7, WD_AWNING, WD_AWNING, M_STONE, M_STONE)
		for y: float in [0.5, 1.3, 2.1, 2.9]:  # the banded pier beside the shop
			_lbox(k * bay, 0.4, 0.42, 0.1, g + y, g + y + 0.4, WD_BAND)
		kit_window(u, g + 6.3, 2.5, Win.SILL_HEAD, WD_WHITE, WD_GLASS, 0.72)
		kit_window(u, g + 10.3, 2.4, Win.SILL_HEAD, WD_WHITE, WD_GLASS, 0.72)
		kit_window(u, g + 14.5, 2.2, Win.ARCHED, WD_WHITE, WD_GLASS, 0.72)
		if k % 2 == 1:
			_wd_dormer(u, g)
	_lbox(mid, 0.45, mid, 0.18, g + WD_EAVE - 1.4, g + WD_EAVE - 0.7, WD_SHADE)
	_lbox(mid, 0.8, mid + 0.4, 0.6, g + WD_EAVE - 0.7, g + WD_EAVE, WD_WHITE)
	# Two long stone balconies with balusters over the shops, a third of the way along.
	for c: float in [0.3, 0.72]:
		_lbox(width * c, 0.95, 2.4, 0.62, g + 5.5, g + 5.76, WD_WHITE)
		_lbox(width * c, 1.5, 2.4, 0.08, g + 5.76, g + 6.6, WD_WHITE)


## The rooftop zebra: a black-and-white striped body on a mast with a rider in red. Lit at night.
func _wd_zebra(c: Vector2, y: float) -> void:
	_o = c
	_a = Vector2(0.94, -0.34)
	_b = Vector2(-_a.y, _a.x)
	var white := Color("#f6f2e8")
	var black := Color("#191a1c")
	_lbox(0.0, 0.0, 0.08, 0.08, y, y + 1.6, WD_IRON)
	_lbox(-2.2, 0.0, 2.5, 0.05, y + 1.6, y + 1.8, WD_IRON)
	for k in 6:
		var u := -1.5 + k * 0.6
		_lbox(u, 0.0, 0.3, 0.18, y + 3.0, y + 4.0, white if k % 2 == 0 else black, M_LAMP)
	for u: float in [-1.4, -0.9, 1.0, 1.5]:
		_lbox(u, 0.0, 0.1, 0.12, y + 1.8, y + 3.0, white, M_LAMP)
	_lbox(1.9, 0.0, 0.26, 0.15, y + 3.6, y + 5.0, white, M_LAMP)
	_lbox(2.2, 0.0, 0.42, 0.14, y + 4.7, y + 5.2, black, M_LAMP)
	_lbox(-2.0, 0.0, 0.26, 0.08, y + 3.5, y + 3.7, black, M_LAMP)
	_lbox(0.0, 0.0, 0.3, 0.2, y + 4.0, y + 5.1, Color("#c23a40"), M_LAMP)
	_lbox(0.0, 0.0, 0.17, 0.17, y + 5.1, y + 5.5, Color("#e6c7a8"), M_LAMP)


## Kamienica Wedla, from F's three photos: LoD2's mass; the Górskiego and Szpitalna fronts; at the
## corner a pediment, the bays of two storeys, a tall zinc roof between two turrets and the zebra.
func _build_wedel(site: Dictionary) -> void:
	_g = _ground_under(_pts(WD_OUTLINE))
	var g := _g
	_wd_front(WD_EAST, WD_CORNER, 12)
	_wd_front(WD_CORNER, WD_SOUTH, 8)
	# The corner, in a frame on its diagonal.
	_o = WD_CORNER
	_a = Vector2(0.86, 0.51)
	_b = Vector2(-_a.y, _a.x)
	_a = (Vector2(-0.34, -0.94) + Vector2(-0.89, 0.46)).normalized()  # out of the corner
	_b = Vector2(_a.y, -_a.x)
	var white := WD_WHITE
	_lbox(0.3, 0.0, 1.0, 2.2, g + 5.6, g + 13.4, white)  # the bay of two storeys
	_lbox(1.32, 0.0, 0.03, 1.1, g + 6.4, g + 8.8, WD_GLASS)
	_lbox(1.32, 0.0, 0.03, 1.1, g + 10.3, g + 12.6, WD_GLASS)
	_lbox(0.3, 0.0, 1.3, 2.5, g + 13.4, g + 13.7, white)
	_lbox(1.45, 0.0, 0.03, 2.3, g + 13.7, g + 14.6, WD_IRON)
	_lbox(1.3, 0.0, 0.24, 2.6, g + 5.3, g + 5.7, white)
	_prism(PackedVector2Array([_w(-3.2, -3.2), _w(0.5, -3.2), _w(0.5, 3.2), _w(-3.2, 3.2)]), g + WD_EAVE, g + WD_EAVE + 1.1, white, white, M_STONE, M_STONE)
	_lbox(0.0, 0.0, 0.0 + 0.5, 2.0, g + WD_EAVE + 1.1, g + WD_EAVE + 1.6, white)
	# The tall zinc roof and its two turrets.
	var roof := PackedVector2Array([_w(-5.2, -3.1), _w(-0.4, -3.1), _w(-0.4, 3.1), _w(-5.2, 3.1)])
	_prism(roof, g + WD_EAVE, g + WD_EAVE + 3.4, WD_ZINC, WD_ZINC, M_STONE, M_STONE)
	_prism(PackedVector2Array([_w(-4.6, -2.3), _w(-1.0, -2.3), _w(-1.0, 2.3), _w(-4.6, 2.3)]), g + WD_EAVE + 3.4, g + WD_EAVE + 4.6, WD_ZINC, WD_ZINC, M_STONE, M_STONE)
	for v: float in [-3.2, 3.2]:
		_lbox(-0.4, v, 0.55, 0.55, g + WD_EAVE, g + WD_EAVE + 3.2, white)
		_lbox(-0.4, v, 0.32, 0.32, g + WD_EAVE + 3.2, g + WD_EAVE + 3.9, WD_ZINC)
	_wd_zebra(_w(-2.8, 0.0), g + WD_EAVE + 4.6)


# --- Kamienica Ławrynowicza (F's photos, 2026-11-06): spec docs/landmarks/specs/lawrynowicz.md --

const LW_OUTLINE := [-27.4, 795.5, -27.7, 793.6, 7.9, 788.7, 10.8, 788.4, 15.3, 812.6, -23.5, 820.1]
const LW_N := Vector2(-27.4, 795.5)  # the street front on Aleje Ujazdowskie
const LW_S := Vector2(-23.5, 820.1)
const LW_BRICK := Color("#d8b67a")
const LW_RED := Color("#a7523a")
const LW_STONE := Color("#d9c9a4")
const LW_GLASS := Color("#2c3944")
const LW_IRON := Color("#25272a")
const LW_EAVE := 20.6


## An arched window: pane with a stepped head, a red-and-yellow arch over it and a stone sill.
func _lw_window(u: float, v: float, y: float, w: float, h: float) -> void:
	_lbox(u, v + 0.22, w, 0.03, y, y + h, LW_GLASS, _lit(u, y))
	_lbox(u, v + 0.22, w * 0.62, 0.03, y + h, y + h + 0.28, LW_GLASS)
	_lbox(u, v + 0.26, w + 0.2, 0.1, y + h, y + h + 0.14, LW_RED)
	_lbox(u, v + 0.26, w * 0.82, 0.1, y + h + 0.28, y + h + 0.46, LW_RED)
	_lbox(u, v + 0.28, w + 0.18, 0.14, y - 0.2, y - 0.04, LW_STONE)


## A balcony slab with a brick parapet, standing out from v at height y.
func _lw_balcony(u: float, v: float, half: float, y: float) -> void:
	_lbox(u, v + 0.75, half, 0.6, y - 0.28, y - 0.06, LW_STONE)
	_lbox(u, v + 1.3, half, 0.07, y - 0.06, y + 0.8, LW_BRICK)
	_lbox(u, v + 1.3, half, 0.09, y + 0.8, y + 0.92, LW_RED)


## A stepped gable centred at u on top of the wall at height y: `steps` narrowing brick courses.
func _lw_gable(u: float, v: float, half: float, y: float, steps: int) -> void:
	for k in steps:
		var w := half * (1.0 - float(k) / steps)
		_lbox(u, v + 0.18, w, 0.2, y + k * 0.9, y + (k + 1) * 0.9, LW_BRICK if k % 2 == 0 else LW_RED)
	_lbox(u, v + 0.18, 0.3, 0.2, y + steps * 0.9, y + steps * 0.9 + 0.6, LW_RED)


## Kamienica Ławrynowicza, from F's photos: 24.9 m of banded yellow and red brick, a slightly proud
## tower at each end with paired arched windows and a stepped gable, arcades at street level, a
## middle gable with a round window, balconies down the front and iron cresting along the roof.
func _build_lawrynowicz(site: Dictionary) -> void:
	_o = LW_N
	_a = (LW_S - LW_N).normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front
	_g = _ground_under(_pts(LW_OUTLINE))
	var g := _g
	var width := LW_N.distance_to(LW_S)
	var mid := width * 0.5
	var tower := 2.45  # a tower's half width
	_lbox(mid, 0.14, mid, 0.2, g - 0.3, g + LW_EAVE, LW_BRICK)
	for c: float in [tower, width - tower]:
		_lbox(c, 0.3, tower, 0.3, g - 0.3, g + LW_EAVE + 2.0, LW_BRICK)
	var y := 0.8
	while y < LW_EAVE + 2.0:  # the red courses, closer together low down
		_lbox(mid, 0.36, mid, 0.03, g + y, g + y + 0.26, LW_RED)
		_lbox(tower, 0.62, tower, 0.03, g + y, g + y + 0.26, LW_RED)
		_lbox(width - tower, 0.62, tower, 0.03, g + y, g + y + 0.26, LW_RED)
		y += 1.05
	# Street level: wide arches, and the gate with its dark door in the middle.
	for k in 5:
		var u := 2.5 + k * 5.0
		if k == 2:
			_lbox(u, 0.36, 1.5, 0.03, g, g + 3.6, Color("#20262c"))
			_lbox(u, 0.4, 1.9, 0.16, g + 3.6, g + 4.2, LW_RED)
			_lbox(u, 0.4, 1.3, 0.16, g + 4.2, g + 4.7, LW_BRICK)
		else:
			_lw_window(u, 0.4 if k == 0 or k == 4 else 0.14, g + 0.9, 1.5, 2.7)
	# The towers: paired windows on four storeys, balconies on three, then the gables.
	for c: float in [tower, width - tower]:
		for y2: float in [6.0, 9.5, 13.0, 16.4]:
			_lw_window(c - 0.95, 0.38, g + y2, 0.7, 2.2)
			_lw_window(c + 0.95, 0.38, g + y2, 0.7, 2.2)
		for y3: float in [9.3, 12.8, 16.2]:
			_lw_balcony(c, 0.4, 2.1, g + y3)
		_lw_gable(c, 0.4, tower, g + LW_EAVE + 2.0, 4)
	# The middle: five bays on four storeys, a long balcony and a gable with a round window.
	for k in 5:
		var u := mid + (k - 2) * 2.85
		for y2: float in [6.0, 9.5, 13.0, 16.4]:
			_lw_window(u, 0.12, g + y2, 0.8, 2.2)
	_lw_balcony(mid, 0.14, 4.2, g + 9.3)
	_lbox(mid, 0.3, mid - 4.4, 0.16, g + LW_EAVE - 0.4, g + LW_EAVE + 0.1, LW_STONE)
	_lw_gable(mid, 0.14, 3.2, g + LW_EAVE + 0.1, 4)
	_lbox(mid, 0.5, 0.75, 0.06, g + LW_EAVE + 0.8, g + LW_EAVE + 2.2, LW_GLASS, _lit(mid, 21.0))
	# Iron cresting along the roof between the gables.
	_lbox(mid, -0.5, mid - 5.0, 0.03, g + LW_EAVE + 1.0, g + LW_EAVE + 1.08, LW_IRON)
	for k in 14:
		_lbox(5.2 + k * (width - 10.4) / 13.0, -0.5, 0.03, 0.03, g + LW_EAVE + 0.1, g + LW_EAVE + 1.0, LW_IRON)


# --- Aleje Ujazdowskie 47 (F's photos, 2026-11-06): spec docs/landmarks/specs/ujazdowskie47.md --

const U47_OUTLINE := [-63.4, 769.7, -60.0, 788.5, -78.1, 793.4, -91.9, 797.1, -94.8, 797.9, -95.1, 795.4, -94.1, 794.3, -94.0, 792.9,
		-93.4, 787.1, -89.8, 787.5, -87.5, 788.5, -73.8, 784.7, -75.4, 774.6, -75.8, 774.3, -76.2, 771.6, -75.9, 771.6]
const U47_S := Vector2(-60.0, 788.5)
const U47_N := Vector2(-63.4, 769.7)
const U47_WALL := Color("#6c6f70")
const U47_BASE := Color("#5a5d5f")
const U47_TRIM := Color("#7c7f80")
const U47_FRAME := Color("#e4e0d6")
const U47_GLASS := Color("#2b343c")
const U47_IRON := Color("#222426")
const U47_GREEN := Color("#1f7a55")


## A tall window with a pale frame, a pane that lights at night and a dark sill.
func _u47_window(u: float, y: float, h: float) -> void:
	_lbox(u, 0.33, 0.72, 0.03, y, y + h, U47_GLASS, _lit(u, y))
	_lbox(u, 0.35, 0.8, 0.04, y + h, y + h + 0.1, U47_FRAME)
	_lbox(u, 0.35, 0.8, 0.04, y - 0.1, y, U47_FRAME)
	_lbox(u, 0.4, 0.95, 0.12, y - 0.26, y - 0.1, U47_TRIM)


## An iron balcony at bay centre u on the storey with sill y.
func _u47_balcony(u: float, y: float) -> void:
	_lbox(u, 0.7, 1.0, 0.36, y - 0.3, y - 0.08, U47_TRIM)
	_lbox(u, 1.04, 1.0, 0.03, y + 0.72, y + 0.8, U47_IRON)
	for j in 6:
		_lbox(u - 1.0 + j * 0.4, 1.04, 0.025, 0.025, y - 0.08, y + 0.72, U47_IRON)


## The front from F's two photos: 19 m and six bays of dark grey render. Two storeys between tall
## piers under a heavy cornice, arched openings and the green pharmacy signs at street level, three
## storeys above with hooded windows and balconies, a balustraded attic.
func _build_ujazdowskie47() -> void:
	_o = U47_S
	_a = (U47_N - U47_S).normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front
	_g = _ground_under(_pts(U47_OUTLINE))
	var g := _g
	var width := U47_S.distance_to(U47_N)
	var mid := width * 0.5
	var bay := width / 6.0
	_lbox(mid, 0.14, mid, 0.18, g - 0.3, g + 9.4, U47_BASE)
	_lbox(mid, 0.14, mid, 0.18, g + 9.4, g + 23.4, U47_WALL)
	_lbox(mid, 0.5, mid, 0.34, g + 9.3, g + 9.9, U47_BASE.darkened(0.14))
	_lbox(mid, 0.36, mid, 0.14, g + 22.7, g + 23.4, U47_BASE)
	_lbox(mid, 0.74, mid + 0.3, 0.5, g + 23.4, g + 23.7, U47_TRIM)
	_lbox(mid, 0.26, mid, 0.14, g + 23.7, g + 24.8, U47_WALL)
	for k in 7:  # the piers between the bays of the two lower storeys
		_lbox(k * bay, 0.42, 0.42, 0.16, g, g + 9.3, U47_WALL)
	for k in 6:
		var u := (k + 0.5) * bay
		if k == 0:
			_lbox(u, 0.33, 0.9, 0.03, g + 0.2, g + 3.7, Color("#30231b"))
		else:
			_lbox(u, 0.33, 1.0, 0.03, g + 0.9, g + 3.5, U47_GLASS, _lit(u, 1.0))
		_lbox(u, 0.38, 0.6, 0.06, g + 3.7, g + 4.1, U47_GLASS)
		_lbox(u, 0.42, 1.2, 0.1, g + 4.1, g + 4.3, U47_TRIM)
		if k >= 2:  # the pharmacy
			_lbox(u, 0.42, 0.92, 0.05, g + 3.2, g + 3.55, U47_GREEN)
		_u47_window(u, g + 5.7, 2.5)
		if k > 0 and k < 5:
			_lbox(u, 0.56, 0.95, 0.22, g + 4.9, g + 5.6, U47_TRIM)
		_u47_window(u, g + 11.0, 2.4)
		if k > 0 and k < 5:
			_lbox(u, 0.36, 0.75, 0.1, g + 13.6, g + 14.2, U47_TRIM)  # the hood
		_u47_window(u, g + 15.1, 2.2)
		_u47_window(u, g + 19.1, 2.2)
		if k == 0 or k == 5:
			_u47_balcony(u, g + 15.1)
		elif k < 5:
			_u47_balcony(u, g + 19.1)


# --- Street fronts read from photos (F, 2026-11-06) --------------------------------------------

const PF_PATH := "res://data/photo_fronts.json"


## Each entry keeps LoD2's mass in its plaster and gets its street fronts: a site "pf_<id>".
func _find_photo_fronts() -> void:
	if not FileAccess.file_exists(PF_PATH):
		return
	var list = JSON.parse_string(FileAccess.get_file_as_string(PF_PATH))
	if not list is Array:
		return
	for d: Dictionary in list:
		# The theatre's whole-building site already supplies this frontage.
		if str(d["id"]) == "b12747":
			continue
		var key := "pf_" + str(d["id"])
		_add_site(key, [_pts(d["outline"])])
		if not sites.is_empty() and sites[-1]["key"] == key:
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": Color(d["wall"]), "roof": Color(d["roof"])}
			sites[-1]["fronts"] = d
			sites[-1]["quiet"] = true


func _build_photo_fronts(site: Dictionary) -> void:
	var d: Dictionary = site["fronts"]
	_g = _ground_under(_pts(d["outline"]))
	for f: Dictionary in d["fronts"]:
		_pf_front(f, d)
	match str(d["id"]):
		"b1399":
			_pz_12()
		"101302509":
			_pf_karnickich(d)
		"145110262":
			_pf_puslowski(d)


## One street front in the house's style. `classic`: sills, heads, string courses and a cornice;
## `plain`: sills only; `ribbon`: long panes between floor bands; `glass`: a curtain wall;
## `fins`: plain windows between upright fins.
func _pf_front(f: Dictionary, d: Dictionary) -> void:
	var from := Vector2(f["a"][0], f["a"][1])
	var to := Vector2(f["b"][0], f["b"][1])
	_o = from
	_a = (to - from).normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front
	var width := from.distance_to(to)
	var mid := width * 0.5
	var g := _g
	var h: float = f["h"]
	var gf: float = d["gf"]
	var bays: int = f["bays"]
	var floors: int = f["floors"]
	var bay := width / bays
	var fh := (h - gf - 0.7) / floors
	var wall := Color(d["wall"])
	var base := Color(d["base"])
	var trim := Color(d["trim"])
	var style: String = d["style"]
	var glass := Color("#2c3640")
	_lbox(mid, 0.12, mid, 0.16, g - 0.3, g + gf, base)
	_lbox(mid, 0.12, mid, 0.16, g + gf, g + h, wall)
	_lbox(mid, 0.34, mid, 0.08, g + gf - 0.25, g + gf, trim)
	var shops: bool = d.get("shops", false)
	for k in bays:  # street level
		var u := (k + 0.5) * bay
		# `shops`: the ground floor is shops and cafés, every window lit warm at night (Krakowskie
		# Przedmieście's row, F's night photos 2026-11-26); otherwise lit by chance.
		_lbox(u, 0.32, bay * 0.36, 0.03, g + 0.7, g + gf - 0.8, glass, M_PAVILION if shops else _lit(u, 1.0))
	_pf_extras(f, d, width, h, gf, fh, bay, bays, floors, trim)
	for i in floors:
		var y := g + gf + 0.7 + i * fh
		match style:
			"ribbon":
				_lbox(mid, 0.32, mid - 0.4, 0.03, y, y + fh * 0.58, glass, _lit(mid, y))
				_lbox(mid, 0.36, mid, 0.08, y - 0.4, y - 0.15, trim)
			"glass":
				for k in bays:
					_lbox((k + 0.5) * bay, 0.31, bay * 0.47, 0.03, y - 0.5, y + fh - 0.75, wall.darkened(0.25), _lit(k, y))
				_lbox(mid, 0.35, mid, 0.05, y - 0.75, y - 0.55, trim)
			_:
				for k in bays:
					var u := (k + 0.5) * bay
					var w := minf(bay * 0.3, 0.8)
					var wh := minf(fh * 0.62, 2.4)
					_lbox(u, 0.31, w, 0.03, y, y + wh, glass, _lit(u, y))
					_lbox(u, 0.36, w + 0.14, 0.09, y - 0.18, y - 0.04, trim)
					if style == "classic":
						_lbox(u, 0.36, w + 0.1, 0.09, y + wh + 0.04, y + wh + 0.2, trim)
		if style == "classic" and i == 1:
			_lbox(mid, 0.34, mid, 0.07, y - 0.5, y - 0.36, trim)
	if style == "fins":
		for k in bays + 1:
			_lbox(k * bay, 0.42, 0.1, 0.26, g + gf, g + h - 0.2, trim)
	if style == "classic":
		_lbox(mid, 0.62, mid + 0.3, 0.44, g + h - 0.5, g + h, trim)
	else:
		_lbox(mid, 0.3, mid, 0.14, g + h - 0.3, g + h, trim)


## A photo front's optional extras (Krakowskie Przedmieście's tenements, F's night photos and
## Street View, 2026-11-26), each a field of the entry (`d`) or of the front (`f`):
## - `sign` (front or entry): a colour; a lit sign board over the ground floor across the middle of
##   the front (M_LAMP: its colour by day, glowing at night), the shops' and cafés' boards.
## - `dormers` (front): that many dormers in the roof over the front, each a small plastered box with
##   a window and a little gable roof, set back from the cornice into the roof.
## - `balcony` (front): the storey (1 = the first floor) with an iron balcony across the middle bays.
## - `awning` (front): a colour; a café awning over the middle bays of the ground floor.
func _pf_extras(f: Dictionary, d: Dictionary, width: float, h: float, gf: float, fh: float, bay: float, bays: int,
		floors: int, trim: Color) -> void:
	var g := _g
	var mid := width * 0.5
	var wall := Color(d["wall"])
	var sign_col: String = f.get("sign", d.get("sign", ""))
	if sign_col != "":
		var sw := clampf(width * 0.55, 3.0, 14.0)
		_lbox(mid, 0.42, sw * 0.5, 0.08, g + gf - 0.75, g + gf - 0.3, Color(sign_col), M_LAMP)
	var awning: String = f.get("awning", "")
	if awning != "":
		var aw := clampf(width * 0.6, 3.0, 14.0)
		_lbox(mid, 1.1, aw * 0.5, 0.9, g + 2.6, g + 2.75, Color(awning), M_STONE)
		_lbox(mid, 1.95, aw * 0.5, 0.04, g + 2.3, g + 2.7, Color(awning).darkened(0.15), M_STONE)
	var balcony: int = f.get("balcony", 0)
	if balcony > 0 and balcony <= floors:
		var y := g + gf + 0.7 + (balcony - 1) * fh
		var bw := minf(bay * clampf(bays - 2, 1, 3), width - 1.0) * 0.5
		var keep := _face
		_face = 0.28  # the front wall's face (`_pf_front`: 0.12 out, 0.16 thick)
		kit_balcony(mid, y, bw, Balcony.IRON, PAL_IRON, trim)
		_face = keep
	var dormers: int = f.get("dormers", 0)
	if dormers > 0:
		var roof := Color(d["roof"])
		for k in dormers:
			var u := (k + 0.5) * width / dormers
			_lbox(u, -1.3, 0.7, 0.6, g + h - 0.3, g + h + 1.5, wall, M_STONE)
			_lbox(u, -0.68, 0.38, 0.03, g + h + 0.15, g + h + 1.2, Color("#2c3640"), _lit(u, h + 1.0))
			_lbox(u, -1.3, 0.82, 0.72, g + h + 1.5, g + h + 1.7, roof, M_STONE)
			_lbox(u, -1.3, 0.5, 0.5, g + h + 1.7, g + h + 2.0, roof, M_STONE)


# --- The Tides (F's photos, 2026-11-06): spec docs/landmarks/specs/tides.md ---------------------

const TD_OUTLINE := [1073.6, 101.5, 1069.7, 91.6, 1065.0, 83.1, 1049.8, 55.4, 1046.6, 46.0, 1043.7, 38.6, 1044.9, 37.9, 1043.1, 34.6,
		1037.5, 23.9, 1028.1, 7.3, 1043.0, -1.1, 1058.4, 25.7, 1068.7, 43.3, 1075.7, 56.9, 1077.8, 60.6, 1092.7, 83.9, 1101.4, 101.8, 1080.7, 113.3]
## The two long fronts as the street and the river see them, ends included, each with the outside on
## the frame's +v: the street side from the cantilever south, the river side back north.
const TD_FACES := [[1028.1, 7.3, 1037.5, 23.9], [1037.5, 23.9, 1043.7, 38.6], [1043.7, 38.6, 1049.8, 55.4], [1049.8, 55.4, 1065.0, 83.1],
		[1065.0, 83.1, 1073.6, 101.5], [1073.6, 101.5, 1080.7, 113.3], [1080.7, 113.3, 1101.4, 101.8], [1101.4, 101.8, 1092.7, 83.9],
		[1092.7, 83.9, 1075.7, 56.9], [1075.7, 56.9, 1058.4, 25.7], [1058.4, 25.7, 1043.0, -1.1], [1043.0, -1.1, 1028.1, 7.3]]
const TD_COPPER := Color("#e09a55")
const TD_DARK := Color("#26282b")
const TD_PANE := Color("#2f4048")
const TD_FLOOR := 4.3  # the slab over the street level
const TD_EAVE := 19.6
const TD_STOREY := 3.05


## A number in 0..1 that stays put for a spot on the building.
func _td_hash(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


## One wall of folded copper panels: a grid pushed in and out, so the sun picks out its facets.
func _td_wall(width: float, g: float) -> void:
	var cols := maxi(2, ceili(width / 5.5))
	var rows := 4
	var at := func(i: int, j: int) -> Vector3:
		var edge := i == 0 or i == cols or j == 0 or j == rows
		var v := 0.08 if edge else 0.08 + 0.7 * _td_hash(_o.x + i * 3.1, _o.y + j * 7.7)
		var q := _w(width * i / cols, v)
		return Vector3(q.x, g + TD_FLOOR + (TD_EAVE - TD_FLOOR) * j / rows, q.y)
	for i in cols:
		for j in rows:
			var p00: Vector3 = at.call(i, j)
			var p10: Vector3 = at.call(i + 1, j)
			var p01: Vector3 = at.call(i, j + 1)
			var p11: Vector3 = at.call(i + 1, j + 1)
			var flip := _td_hash(_o.x + i, j) > 0.5
			var tris := [[p00, p10, p11], [p00, p11, p01]] if flip else [[p00, p10, p01], [p10, p11, p01]]
			for k in 2:
				var q: Array = tris[k]
				var n: Vector3 = (q[1] - q[0]).cross(q[2] - q[0]).normalized()
				if n.dot(Vector3(_b.x, 0.0, _b.y)) < 0.0:
					n = -n
				var col := TD_COPPER.darkened(0.14 * _td_hash(i + k * 5.0, j + _o.x))
				_mode = M_STONE
				_tri(q[0], q[1], q[2], n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), 0.0, false)


## The windows of one wall: storey by storey an irregular run of wide panes and pairs of slits.
func _td_windows(width: float, g: float) -> void:
	for s in 5:
		var y := g + TD_FLOOR + 0.75 + s * TD_STOREY
		var u := 1.0 + 1.6 * _td_hash(_o.x, s)
		while u < width - 1.4:
			var h := _td_hash(u + _o.y, s * 3.0)
			if h < 0.34:  # a wide pane
				_lbox(u + 1.1, 0.86, 1.1, 0.05, y, y + 1.85, TD_PANE, _lit(u, y))
				u += 2.2
			else:  # a pair of slits
				_lbox(u + 0.28, 0.86, 0.28, 0.05, y, y + 1.85, TD_DARK, _lit(u, y))
				_lbox(u + 1.2, 0.86, 0.28, 0.05, y, y + 1.85, TD_DARK, _lit(u + 1.0, y))
				u += 1.5
			u += 0.9 + 1.5 * _td_hash(u, s + 9.0)


## The Tides on the Vistula: a long bent slab in folded copper panels on five storeys with an
## irregular run of windows, a black ribbed roof sloping back from the eaves, the north end carried
## out over a glass lobby, three big bays on the south end, a dark glazed street level.
func _build_tides(site: Dictionary) -> void:
	var ring := _pts(TD_OUTLINE)
	_g = _ground_under(ring)
	var g := _g
	# Street level: a dark glazed core, short of the north end, under the slab.
	var core := _largest(Geometry2D.offset_polygon(ring, -1.4, Geometry2D.JOIN_MITER))
	var cut := PackedVector2Array([Vector2(1020, -8), Vector2(1056, -8), Vector2(1056, 12), Vector2(1036, 24), Vector2(1020, 24)])
	var kept := Geometry2D.clip_polygons(core, cut)
	if not kept.is_empty():
		core = kept[0]
	_prism(core, g - 0.3, g + TD_FLOOR, Color("#28333a"), TD_DARK, M_STONE, M_STONE)
	_prism(PackedVector2Array([Vector2(1036, 13), Vector2(1045, 8), Vector2(1051, 18), Vector2(1042, 24)]), g - 0.3, g + TD_FLOOR, Color("#5d7a86"), TD_DARK, M_STONE, M_STONE)
	_prism(ring, g + TD_FLOOR - 0.3, g + TD_FLOOR + 0.1, Color("#d7cdbd"), Color("#d7cdbd"), M_STONE, M_STONE)
	# The top of the walls, then the black roof going back in steps.
	_prism(ring, g + TD_EAVE - 0.05, g + TD_EAVE + 0.05, TD_DARK, TD_DARK, M_STONE, M_STONE)
	for k in 4:
		var r := _largest(Geometry2D.offset_polygon(ring, -0.9 * (k + 1), Geometry2D.JOIN_MITER))
		if r.size() >= 3:
			_prism(r, g + TD_EAVE + k * 0.8, g + TD_EAVE + (k + 1) * 0.8, TD_DARK, TD_DARK.lightened(0.05), M_STONE, M_STONE)
	for f: Array in TD_FACES:
		var from := Vector2(f[0], f[1])
		var to := Vector2(f[2], f[3])
		_o = from
		_a = (to - from).normalized()
		_b = Vector2(-_a.y, _a.x)
		var width := from.distance_to(to)
		_td_wall(width, g)
		_td_windows(width, g)
		var piers := int(width / 5.0) if from.y > 24.0 and to.y > 24.0 else 0  # none under the cantilever
		for k in piers:  # copper piers along the street level
			_lbox((k + 0.5) * width / piers, -0.9, 0.3, 0.4, g, g + TD_FLOOR, TD_COPPER.darkened(0.1))
	# The south end's three big bays.
	_o = Vector2(1080.7, 113.3)
	_a = (Vector2(1101.4, 101.8) - _o).normalized()
	_b = Vector2(-_a.y, _a.x)
	for s: int in [0, 2, 4]:
		var y := g + TD_FLOOR + 0.5 + s * TD_STOREY
		_lbox(6.0, 1.0, 3.0, 1.0, y - 0.3, y + 2.6, TD_COPPER)
		_lbox(6.0, 2.04, 2.6, 0.05, y, y + 2.2, TD_PANE, _lit(6.0, y))
	_collide_raw(site)


## Sets the frame on the house's main front; returns [width, height].
func _pf_frame(d: Dictionary) -> Array:
	var f: Dictionary = d["fronts"][0]
	var from := Vector2(f["a"][0], f["a"][1])
	var to := Vector2(f["b"][0], f["b"][1])
	_o = from
	_a = (to - from).normalized()
	_b = Vector2(-_a.y, _a.x)
	return [from.distance_to(to), float(f["h"])]


## Pałac Karnickich's loggia: three open bays over two storeys between paired columns, a balustrade
## at its foot and a pediment over each side window.
func _pf_karnickich(d: Dictionary) -> void:
	var fr := _pf_frame(d)
	var mid: float = fr[0] * 0.5
	var h: float = fr[1]
	var g := _g
	var trim := Color(d["trim"])
	var half := 5.4
	var y0 := g + 5.6
	var y1 := g + h - 2.2
	_lbox(mid, 0.4, half, 0.04, y0, y1, Color("#6a6044"))
	_lbox(mid, 0.72, half + 0.4, 0.3, y1, y1 + 0.5, trim)
	_lbox(mid, 0.72, half + 0.4, 0.3, y0 - 0.3, y0, trim)
	_lbox(mid, 0.88, half + 0.3, 0.07, y0, y0 + 0.9, trim)
	_lbox(mid, 0.72, half + 0.3, 0.26, (y0 + y1) * 0.5 - 0.15, (y0 + y1) * 0.5 + 0.1, trim)
	for k: float in [-1.5, -0.5, 0.5, 1.5]:
		_column(mid + k * 3.5, 0.8, 0.24, y0, y1, trim)
	for s: float in [-1.0, 1.0]:
		var u := mid + s * (half + 2.0)
		_lbox(u, 0.5, 1.2, 0.2, y1 - 2.9, y1 - 2.7, trim)
		_lbox(u, 0.5, 0.7, 0.2, y1 - 2.7, y1 - 2.45, trim)


## Kamienica Pusłowskiego's portico: four columns to a heavy beam, a rail along its top, and iron
## balconies on the two storeys above.
func _pf_puslowski(d: Dictionary) -> void:
	var fr := _pf_frame(d)
	var mid: float = fr[0] * 0.5
	var g := _g
	var trim := Color(d["trim"])
	var iron := Color("#26282a")
	for k: float in [-1.5, -0.5, 0.5, 1.5]:
		_column(mid + k * 2.5, 1.9, 0.3, g, g + 4.9, trim)
	_lbox(mid, 1.1, 4.7, 1.0, g + 4.9, g + 5.5, trim)
	_lbox(mid, 2.06, 4.7, 0.04, g + 5.5, g + 6.4, iron)
	_lbox(mid, 1.1, 0.04, 1.0, g + 5.5, g + 6.4, iron)
	_lbox(mid - 4.7, 1.1, 0.04, 1.0, g + 5.5, g + 6.4, iron)
	_lbox(mid + 4.7, 1.1, 0.04, 1.0, g + 5.5, g + 6.4, iron)
	_lbox(mid, 0.4, 1.4, 0.05, g + 0.2, g + 4.2, Color("#2b2320"))


# --- Scena Relax (F's photos, 2026-11-06): spec docs/landmarks/specs/scena_relax.md -------------

## The old Kino Relax on Złota: a glazed foyer under a concrete band, a plain hall behind, and on the
## south front the big yellow banner that carries the red word (`_dtc_relax`).
func _build_scena_relax(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["raw"]
	_g = _ground_under(ring)
	var g := _g
	var concrete := Color("#b9b6ad")
	_prism(ring, g - 0.3, g + 4.0, Color("#2e3c44"), concrete, M_STONE, M_STONE)
	_prism(ring, g + 4.0, g + 5.2, concrete, concrete, M_STONE, M_STONE)
	_prism(ring, g + 5.2, g + 14.0, Color("#918e87"), Color("#77756f"), M_STONE, M_STONE)
	_o = Vector2(-889.4, 117.9)
	_a = (Vector2(-866.9, 109.8) - _o).normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the south front
	var width := _o.distance_to(Vector2(-866.9, 109.8))
	var mid := width * 0.5
	_lbox(mid, 0.45, mid - 0.4, 0.25, g + 5.4, g + 13.4, Color("#ecb92c"))
	_lbox(mid, 2.2, mid + 0.6, 2.2, g + 3.7, g + 4.1, concrete)
	for l in RELAX_GLYPHS.size():
		for r in 5:
			for c in 3:
				if RELAX_GLYPHS[l][r * 3 + c] == "1":
					_lbox(mid + (l - 2) * 4.3 + (c - 1) * 1.05, 0.74, 0.52, 0.03, g + 11.9 - r * 1.05, g + 12.95 - r * 1.05, RELAX_RED, M_LAMP)
	for k in 7:
		_lbox(1.2 + k * (width - 2.4) / 6.0, 0.15, 0.12, 0.12, g, g + 3.9, concrete.darkened(0.2))
	_collide_raw(site)



## F's ask (2026-11-07, eleven photos: three drone views and a courtyard of the estate, five of the
## Towarowa Towers, Street View of the estate's last stage going up, the Polfa plot's building site
## and NOHO ONE's hoarding, a satellite crop of Kolejowa and Przyokopowa). Spec
## docs/landmarks/specs/dzielnica19.md. Three sites:
##   `noho`    the cleared drug-works plot between Kasprzaka, Karolkowa and the estate (OpenStreetMap
##             `construction`), as a building site: the new blocks' bare concrete frames (glazed only
##             low down, a cascade of terraces stepping off the top), two cores ahead of their
##             floors, three tower cranes, a yard of insulation pallets, cabins, cars and sand, a
##             foundation slab with starter bars, and a hoarding with the parody name OHO ONE.
##             The strip south of it (the estate's last stage, Street View) has two more frames.
##   `d19`     the estate's blocks (Kolejowa, Przyokopowa), rebuilt from their mapped parts: cream
##             walls with punched windows and rust-brown window frames scattered over them (the
##             drone views and the courtyard photo); the two blocks on the east green in the dark
##             grid of the plaza photo (charcoal floor bands and piers over warm bronze glass);
##             the glazed ground floors and green courtyard roofs over the podiums.
##   `asbud`   the Towarowa Towers (two 97 m blocks of flats) in dark blue glass with staggered
##             frames, orange low down and gold higher up, a white stone spine and an orange
##             base, the frames running past the roof as an open crown with the parody ASBUDKA;
##             the white blocks at their feet with orange balcony stacks.
## Built from F's photos; what they don't show (the frames' storey counts, which estate block wears
## which look) is the spec's default, listed in /mnt/project-files/dzielnica19/PHOTOS-NEEDED.txt.


# --- Centrum Marszałkowska (F's photos, 2026-11-08): spec docs/landmarks/specs/cmarsz.md ----------

## The street block (game/data/street_blocks) that stood in for it: this site builds it now.
const CM_BLOCK := "579369105"


# --- Próżna and Plac Grzybowski (F's photos, 2026-11-08) ---------------------------------------

## Próżna 12 (Neufeld house, 1910-12; F's photo F-IMG_7527): 14 m of greige plaster on the east part of the
## b1399 outline, six storeys with a flat roof, a rusticated ground floor, two rounded bay oriels
## on corbels that rise four storeys to a stone-railed balcony, a flat centre bay of paired windows (small
## pediments on the 2nd floor) and a stacked black balcony at each edge. Próżna 14 (the west part)
## stays the photo front under its netting.
func _pz_12() -> void:
	_o = Vector2(-1341.3, -258.2)
	_a = Vector2(0.922, -0.386).normalized()
	_b = Vector2(-_a.y, _a.x)
	var g := _ground_under(PackedVector2Array([_o, _w(14.0, 0.0), _w(14.0, 4.0), _w(0.0, 4.0)]))
	var wall := Color("#cdc4b1")
	var trim := Color("#e9e2d1")
	var pane := Color("#33404b")
	var iron := Color("#1e1f21")
	var gf := 4.6
	var st := 3.3
	var top := gf + 5.0 * st
	_lbox(7.0, 0.35, 7.0, 0.1, g - 0.3, g + gf, wall.darkened(0.04))
	_lbox(7.0, 0.35, 7.0, 0.1, g + gf, g + top, wall)
	_lbox(7.0, 0.5, 7.0, 0.3, g + top - 0.2, g + top + 0.35, trim)
	for k in 4:  # the ground floor's wide windows between rusticated piers
		var u := 1.75 + 3.5 * k
		_lbox(u, 0.42, 1.0, 0.04, g + 0.5, g + gf - 0.7, pane, _lit(u, 1.0))
		_lbox(u, 0.44, 1.2, 0.06, g + gf - 0.7, g + gf - 0.55, trim)
	for u: float in [2.5, 11.5]:  # the two oriels: a half-cylinder on a corbel, a rail on top
		var c := _w(u, 0.75)
		_prism(_circle(c, 2.0, 12), g + gf, g + gf + 0.45, trim, trim, M_STONE, M_STONE)
		_prism(_circle(c, 1.85, 12), g + gf + 0.45, g + gf + 4.0 * st, wall.lightened(0.04), trim, M_STONE, M_STONE)
		_prism(_circle(c, 2.1, 12), g + gf + 4.0 * st, g + gf + 4.0 * st + 0.2, trim, trim, M_STONE, M_STONE)
		for i in 4:
			var wy := g + gf + 0.9 + i * st
			_lbox(u, 2.5, 0.8, 0.05, wy, wy + 1.9, pane, _lit(u, wy))
	for i in 5:  # the centre bay's paired windows, a pediment on the 2nd floor, cartouches under them
		var wy := g + gf + 0.7 + i * st
		for u: float in [5.9, 8.1]:
			_lbox(u, 0.4, 0.45, 0.04, wy, wy + 2.0, pane, _lit(u, wy))
			_lbox(u, 0.44, 0.55, 0.06, wy - 0.15, wy - 0.05, trim)
			if i == 1:
				_lbox(u, 0.44, 0.6, 0.06, wy + 2.0, wy + 2.35, trim)
		if i > 0:
			_lbox(7.0, 0.42, 0.3, 0.04, wy - 0.7, wy - 0.3, trim)
	for i in 5:  # the stacked black iron balconies at both edges
		var by := g + gf + 0.3 + i * st
		for u: float in [0.3, 13.7]:
			_lbox(u, 0.7, 0.3, 0.6, by, by + 0.85, iron)
