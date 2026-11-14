extends SceneTree
## Mesh quality of every hand-built landmark (loop 0.1 + 0.2 of the landmarks plan, 2026-10-31):
## each site is built alone through `landmarks.gd` (a stub map with flat ground, the same way
## `check_sites.gd` does it, from the committed `map/centrum.json` only, so it runs in CI) and
## its triangles are examined, the defects a judge looking at a shot misses:
##   - triangle BUDGET per site (every site that emits triangles must have one: a new site
##     without an entry fails, so detail never goes in without a limit);
##   - draw calls: every triangle carries a landmark material code (UV2.x >= 2), so a site is
##     part of the city's one building surface and adds no draw call of its own;
##   (the examination itself lives in tools/mesh_probe.gd, shared with check_places.gd)
##   - ZFIGHT: same-facing triangles on one plane (within 2 cm) that overlap by more than
##     0.01 m^2 flicker when the camera moves;
##   - DEGENERATE: zero-area triangles (< 1e-5 m^2) and BADNORMAL: triangles whose declared
##     normal disagrees with their geometry (|cos| < 0.5), which light wrongly;
##   - FLOAT: connected parts (welded to 5 cm) that touch neither the ground (y <= 0.2) nor the
##     box of a part that does (grown 10 cm): detail hanging in the air.
##     A site in ON_ROOF stands on a mapped roof: its lowest level counts as its ground.
## The defects that exist today are a ratchet in KNOWN (counts per site and kind): the check
## fails when a count goes ABOVE it, and says so when it went below (lower the number). New
## defects fail at once. Not checked (the art-director judges them): parts inside parts, T gaps.
## Prints a line per site, then `check_mesh_quality: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_mesh_quality.gd

const MapBuilderRef := preload("res://scripts/map_builder.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const MeshProbe := preload("res://tools/mesh_probe.gd")
const Fakes := preload("res://tools/fakes.gd")
## Triangles a site may hold: measured on 2026-10-31 plus about 20 % (raise on purpose only).
const BUDGET := {
	"scena_relax": 600,
	"smolna38": 2700,
	"tides": 8000,
	"ujazdowskie47": 3000,
	"krasinski_ogrod": 900,
	"lawrynowicz": 8000,
	"wedel": 8000,
	"szpitalna5": 8000,
	"gigantami": 4000,
	"filtry": 3000,
	"level26_club": 860,
	"church_alberta": 950,  # 2026-11-14: the whole classicist frontage on Plac Teatralny, portico and two wings, from photos (measured 818)
	"church_antoniego": 990,
	"church_augustyn": 1750,  # 2026-11-14: the whole brick basilica and its 70 m tower (measured 1603)
	"church_bazylianie": 1000,  # 2026-11-14: the Basilian monastery's street wing and back wings (measured 896)
	"church_cerkiew": 410,  # 2026-11-14: the Basilians' church hall from LoD2 and the street front (measured 288)
	"church_czestochowska": 620,  # 2026-11-14: the modernist A-frame church and its pylons from photos (measured 551)
	"church_duch": 3300,  # 2026-11-14: the whole Holy Spirit church and both towers from photos (measured 3010)
	"church_dzieciatka": 1800,  # 2026-11-14: the whole brick Child Jesus church from photos (measured 1594)
	"church_jacek": 2800,  # 2026-11-14: the whole St Hyacinth church from photos (measured 2550)
	"church_jerozolimska": 1050,  # 2026-11-14: the whole brick church, its portico and the bell tower next door, from photos (measured 921)
	"church_kapucyni": 2400,  # 2026-11-14: the whole Capuchin church from photos (measured 2136)
	"church_karol": 1850,  # 2026-11-14: the whole classicist church on Chłodna, two west towers and the apse, from photos (measured 1693)
	"church_katedra_polowa": 3200,  # 2026-11-14: the whole Field Cathedral from photos (measured 2917)
	"church_miloserdzie": 640,  # 2026-11-14: the whole Divine Mercy church and its bell tower from photos (measured 560)
	"church_narodzenia": 1450,  # 2026-11-14: the whole Baroque church and its clock turret from photos (measured 1305)
	"church_niepokalanego": 720,  # 2026-11-14: the whole Res Sacra Miser church from photos (measured 644)
	"church_nozykow": 2900,  # 2026-11-14: the whole Nożyk Synagogue from photos (measured 2625)
	"church_piotr_pawel": 1020,
	"church_reformowany": 1150,  # 2026-11-14: the whole neo-Gothic church and its spire from photos (measured 1020)
	"church_sw_marcin": 2400,  # 2026-11-14: the whole St Martin church and its tower from photos (measured 2043)
	"church_trojca_praga": 520,  # 2026-11-14: Holy Trinity on Solec, temple front and crossing turret from photos (measured 469)
	"church_zielonoswiatkowy": 1000,  # 2026-11-14: the whole modernist Pentecostal hall from photos (measured 919)
	"church_zwycieska": 950,
	"jezuici": 3800,  # 2026-11-13: the whole Jesuit church replaces LoD2 (nave, roofs, front, aisle, tower, turret)
	"aleksander": 2600,  # 2026-11-13 photo rebuild: podium, upper drum windows, Corinthian porticoes
	"barbakan": 1500,  # 2026-11-06 photo pass: merlon caps and swollen cone roofs
	"piano_house": 180,
	"cube_house": 390,
	"hortus": 590,
	"moderna": 90,
	"pomnik_powstania": 1820,
	"krasinski": 1810,
	"sad_najwyzszy": 8000,
	"ostrogski": 870,
	"brama_uw": 950,
	"bristol": 2450,
	"polonia": 1450,
	"ujazdowski": 1650,
	"sobieski": 1500,
	"vitkac": 1400,
	"jablkowscy": 1450,
	"sheraton": 2400,
	"bgk": 2700,
	"foksal": 3000,
	"mlotek": 2400,
	"kozia9": 7000,
	"karowa18a": 1500,
	"nowogrodzka31": 3200,
	"marszalkowska99": 5000,
	"cparking": 6500,
	"hotel_kasztel": 330,
	"hotel_canaletto": 330,
	"hotel_starowka": 330,
	"karmelici": 1300,
	"kordegarda": 950,
	"mdm": 4100,
	"mickiewicz": 1150,
	"potocki": 760,
	"prus": 250,
	"wyszynski": 300,
	"arkadia": 20300,
	"blekitny": 910,
	"bridge": 700,
	"grzybowska77": 2000,
	"buw": 9000,  # 2026-11-13 pass 4 from F's photos (copper frieze and letters, ribbed vault, ivy fronts, pink lattice, drums, dome, Collegium Iuridicum IV, lower garden): 8672 tris, +0 draw calls
	"central": 340,
	"centralna": 1650,
	"chalubinskiego8": 1520,
	"cosmopolitan": 420,  # 2026-11-08 photo rebuild (F)
	"plac_grzybowski": 1500,  # 2026-11-08 photo build (F): 1429 tris, the cascade field is 48 blocks
	"prozna": 5100,  # 2026-11-08 photo build (F): 5014 tris, 1,300 of them the 90 bollards
	"dom_partii": 6200,  # 2026-11-12 rebuilt whole from F's photos (towers, colonnade, frieze, courtyard fountain): 5202 tris, +0 draw calls
	"eon41": 1300,  # 2026-11-13 photo rebuild (F): the power company's L-block, curve, medallions, glass tower, lantern
	"asp37": 1600,  # 2026-11-13 the Academy of Fine Arts: the 1914 school and JEMS's wing
	"deski": 2300,
	"rynek": 3100,
	"syrenka": 480,
	"syrenka_powisle": 260,
	"dworzec_wodny": 310,
	"kaskada": 260,
	"dtc": 1950,
	"europejski": 8000,
	"flaga": 170,
	"forest": 4900,
	"gpy": 2000,  # RD-3 (2026-11-06): black patches, the wings' decks, trees and tables
	"gaulle": 880,
	"rondo": 7000,
	"sunken": 5600,  # 2026-11-05: the Patelnia and the Rotunda's stair: walls, railings, treads, two barrels
	"metro_tubes": 1500,  # 2026-11-09: Metro Centrum's two barrels by the Palace park: ribs, pink walls, escalators
	"defilad_ramp": 1500,  # 2026-11-09: the Plac Defilad car park ramp: two pink walls, 22 ribbed strips
	"underpass": 3000,  # 2026-11-06: the Emilii Plater underpass: five entrances, parapets, treads, two canopies
	"gbc": 750,
	"grob": 340,
	"grzybowska63": 500,
	"gwardii": 1450,
	"hub_b": 260,  # RD-4: parapet, roof plant, podium skylight
	"hub_c": 220,  # RD-4: parapet, roof plant
	"ilmet": 400,
	"jp2_21": 280,
	"kopernik": 1720,
	"legia": 700,
	"lim": 1700,  # the podium from F's photos (2026-11-06): 1415 measured
	"loretka": 1120,
	"lucka": 850,  # 2026-11-06: rebuilt from F's photos (white stepped block, INTERBRUK board, masts)
	"prosta28": 1400,  # 2026-11-06: X-braced base, stepped tree terraces, stone stack, annex
	"prosta32": 3300,  # 2026-11-06: the diamond lattice, ~480 members of six triangles
	"marszalkowska94": 590,  # rebuilt from F's photos (2026-11-07): 402 -> 490 tris
	"mariensztat": 660,
	"mennica": 650,
	"mirowska": 2050,
	# Open courtyards (F, 2026-11-03): mf and muzeum gained their walled, windowed courts.
	"mf": 2350,
	"poczta": 710,
	"pasta": 580,
	"msn": 500,
	# Norblin on its real block (2026-11-02, photo report): two blocks, Plater and Galwan, about
	# three times the first footprint, arched windows round their courts, green roofs and terraces.
	# 2026-11-03 look check: the copper base, finned storeys, set-back tops, the passage roof and
	# the old white workshops under zinc (the Mac's spec).
	"norblin": 5700,
	# Browary + the Central Garden's gravel path, café clearings and the sedum roofs (2026-11-02).
	"browary": 3900,   # 2026-11-03: paved main path and clearing edges (look check)
	"koszyki": 1370,
	"elektrownia": 7600,  # 2026-11-13: the whole complex (hall, halls, passage, office, old wing, gardens): 1634 -> ~6850
	"rotunda_dynasy": 1400,
	"mpw": 3200,
	"metropolitan": 3100,
	"metropolsign": 320,  # 2026-11-10: Hotel Metropol rebuilt whole from F's photos (255 measured)
	"muzeum": 3500,  # 2026-11-06 photo pass: a stone pier on every bay boundary, fence, flagpoles
	"palace": 7600,   # 2026-11-07: 3696 -> 7288, Bar Studio's 34 deck chairs, tables, festoons and frame signs (same mesh, no new draw call)
	"pawilony": 2100,
	"plater49": 140,
	"platinum_a": 80,
	"platinum_b": 80,
	"pepeo_tower": 130,  # 2026-11-08 top-50 T37: mapped parts in their skins, the crown sign
	"poniatowski": 4800,  # 2026-11-03: the towers strengthened (F), 2556 -> 4574 tris over four groups; +0 draw calls
	"prezydencki": 1300,
	"q22": 720,  # 2026-11-08 photo rebuild (top-50 T02): 607 tris
	"rondo1": 900,  # 2026-11-08 photo rebuild (top-50 T03): 769 tris
	"rotunda": 2450,  # 2026-11-11: + the plaza's dark stone grid and its bollards
	"skyliner": 400,
	"skysawa": 170,
	"powstancow_blue": 100,
	"slabs": 1100,   # 2026-11-03: balcony bands, a ledge every storey on the long faces (look check)
	"zelazna": 1030,
	"pokorna2": 1500,
	"pko_branch": 220,  # 2026-11-09 photo rebuild (F): 162 tris (granite slab, glass bays, wings, courtyard)
	"dekalog_estate": 18000,
	"inflancka_pools": 1000,
	"spektrum": 3900,  # 2026-11-13 rebuild from F's photos (3567 tris): fin, podium, crown screens, the rooftop club THE WJU and its lounge; +0 draw calls
	"spire": 6600,  # 2026-11-06 photo rebuild (F), 6151 tris (vase, steel crown ring, drum): steel columns, canopy bow, Spire B/C crowns and eaves, plaza kerbs, channel, 26 trees; +0 draw calls
	"tr": 500,
	"tower75": 220,
	"cepelia": 1100,  # 2026-11-08 photo rebuild (F): 970 tris
	"pijana": 2200,  # 2026-11-08 PIJANA CZEREŚNIA kiosk (F): 1806 tris (octagon, drum, painted windows, deck rail, string lights)
	"zodiak": 720,  # 2026-11-08 photo rebuild (F): 620 tris
	"cmarsz": 2200,
	"sowa": 1500,  # SOWA CLUB and CITY 25 (F's photos, 2026-11-06): 1298 tris
	"brama": 100,
	"equator": 120,
	"equator2": 120,
	"wiecha": 1800,
	"orly": 1600,
	"hotel_warszawa": 2300,
	"cedet": 2300,
	"polin": 450,
	# Krakowskie Przedmieście and Plac Piłsudskiego from photos (2026-11-02)
	"czapski": 860,
	"kazimierzowski": 280,
	"smolensk": 120,
	"pilsudski": 160,
	"kaczynski": 100,
	"plac_maszty": 520,
	"plac_centralny": 700,  # 2026-11-10 the field draped on the ground (no walls)
	"trybuna": 900,  # 2026-11-08 the tribune from F's photos: 751 tris
	"plac_centralny_lamps": 700,
	"getto": 650,
	"nike": 200,
	"slowacki": 320,
	"starzynski": 150,
	"maly_powstaniec": 520,
	"kilinski": 200,
	"umschlagplatz": 250,
	"pomnik_wschod": 1280,
	"ochota": 1420,
	"powisle": 6800,
	"powisle_towers": 1900,   # the viaduct's Powiśle gate towers, arcade, wing and kiosk (2026-11-13, 1608)
	"barka_wieczor": 1820,
	"barka_biala": 1400,
	"barka_marina": 2240,
	"barka_kaskada": 1880,
	"houseboats": 1080,
	"bulwary_pawilony": 3500,
	"bulwary_bary": 1760,
	"bulwary_pomosty": 1450,
	"bulwary_basen": 700,
	"marina": 5200,
	"port_majami": 4200,
	"port_wtw": 1400,
	"port_halls": 900,
	"monkey_love": 2400,
	"stadion_pkp": 1900,
	"wschodnia": 7000,
	"srodmiescie": 580,
	"wkd_srodmiescie": 460,
	"wkd_ochota": 650,  # the stair has up to 40 steps on the real ground (6 on the flat stub)
	"stadium": 4750,
	"swieto": 240,
	"teatr": 820,  # 2026-11-08 photo pass (top-50 T06): ten columns, pediment, quadriga: 705 tris
	# Plac Bankowy, Filharmonia, Teatr Polski (the Mac photo reports, 2026-11-02): fronts on kept skins.
	"ratusz": 2500,
	"gielda": 1050,
	"filharmonia": 1450,
	"teatr_polski": 760,
	"teresy": 900,  # 2026-11-13 photo rebuild (cream plaster, round-headed windows, porch, spire)
	"flisac": 4200,  # 2026-11-13: the grid of panes, loggias and shop glass, 3,552 triangles
	"florian": 2480,
	"bazar": 2210,
	"sw_krzyz": 1250,  # 2026-11-06 photo pass: the real flat front, balustrade and statue
	"sejm": 1400,
	"staszic": 360,
	"zamek": 4300,
	"zamkowy": 1700,
	"arkady": 2600,
	"kino_muranow": 6000,
	"zbawiciela": 3400,
	"zbawiciela_plac": 2200,
	"tarasy": 9400,  # 2026-11-11 F's photos: the triangular glass wave, the guitar, the café (5455); the whole complex: podium ledges, shop boards, Lumen's setback (7781)
	"tarasy_plaza": 2750,  # 2026-11-11: the sunken plaza by the station: walls, shopfronts, railings, treads, umbrellas (2290)
	"trojca": 3700,  # 2026-11-14 photo rebuild: rusticated drum, arched windows, framed oculi, Doric porticoes with lunettes, dormers, glazed lantern (measured 3361)
	"unit": 1160,
	"varso": 2500,
	"varso_place": 1100,
	"wcf": 1400,  # 2026-11-08 F's 13 photos: the Emilii Plater portico, piers, fins, the low roof's rail (1319)
	"wszystkich": 1300,
	"wizytki": 3600,  # 2026-11-14: the whole Visitationist church replaces LoD2 (front, nave, aisles, chancel, wing, turret; measured 3248)
	"branickich": 1500,
	"archikatedra": 1100,
	"sw_anna": 1050,  # 2026-11-06 photo pass: giant order, niches, attic, tower dome
	"widok": 450,
	"pzu": 900,
	"jm": 900,
	"wiktoria": 230,
	"wtt": 1640,
	"zacheta": 720,
	"zlota44": 1800,
	"zygmunt": 320,
	# Towarowa 22 built as finished (2026-11-03): seven towers and blocks, the hall's steel frame,
	# the pavilion, the park, the drone port and the gilded crane.
	"towarowa22": 5000,
	# The Warsaw HUB's round-ended hotel tower (the photo report, 2026-11-03).
	"crowne": 380,
	# Wola's 19. Dzielnica (F's photos, 2026-11-07): the drug works' building site (four concrete
	# frames, cores, three cranes, the yard), the Kolejowa estate's 58 mapped parts, Asbud's towers.
	"noho": 12700,
	"d19": 9000,
	"asbud": 3900,
	# Stacja Muzeum (the Mac's Commons photos, 2026-11-07): the arched hall, its wings, 17 engines
	# and coaches on the four sidings; Nocny Targ's two platform canopies (F's photos).
	"stacja_muzeum": 9000,
	"nocny": 7000,
	# Kolejowa's old railway warehouses, the pinball museum and the teal club (F's photos).
	"kolejowa": 2500,
	# The facade kit's test building (facade_kit.gd kit_sampler): every part and style once.
	"kit_sampler": 3600,  # 2985 measured: the facade kit's test building
}
## Known defects per site: {"zfight": n, "degenerate": n, "badnormal": n, "float": n}.
## Towarowa 22's drone taxi hovers 7 m over its pad by design (the "Warsaw of the future").
const KNOWN := {"towarowa22": {"float": 8}}

var _probe: MeshProbe
var problems: Array[String] = []
var notes: Array[String] = []


func _initialize() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_mesh_quality: 1 problem\n  map/centrum.json missing or unreadable")
		quit(1)
		return
	var map := Fakes.BuilderMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	_probe = MeshProbe.new(data)
	var marks = Landmarks.new(map, data)
	var keys: Array[String] = []
	for s: Dictionary in marks.sites:
		if not s.has("block") and not s.has("fronts"):  # city fabric, not landmarks: no budget of their own
			keys.append(s["key"])
	keys.sort()
	var measured := {}
	for key in keys:
		var rec := MeshProbe.Recorder.new()
		marks.build(rec, Rect2(), key)
		var tris := rec.pos.size() / 3
		if tris == 0:
			continue  # a skin site: it builds nothing of its own
		var found := _probe.examine(key, rec)
		measured[key] = found
		_judge(key, found)
	# The facade kit's sampler (facade_kit.gd `kit_sampler`, docs/design/facade-kit.md section 6):
	# not a site, built and judged like one, so a kit part that flickers, floats or lights wrongly fails here.
	var kit_rec := MeshProbe.Recorder.new()
	marks.build(kit_rec, Rect2(), "kit_sampler")
	if kit_rec.pos.size() > 0:
		var kit_found := _probe.examine("kit_sampler", kit_rec)
		measured["kit_sampler"] = kit_found
		_judge("kit_sampler", kit_found)
	for key: String in BUDGET:
		if not measured.has(key):
			problems.append("%s: has a budget but builds nothing (site gone?)" % key)
	# Every sunken ground (map_builder SUNKEN) needs its site's walls, stairs and parapets: without
	# them the ground is a bare slope (a merge dropped the site once, 2026-11-07, #495).
	for e: Dictionary in MapBuilderRef.SUNKEN:
		var site := String(e.get("site", "sunken"))
		if not measured.has(site) and not problems.has(site + ": SUNKEN ground without its site"):
			problems.append(site + ": SUNKEN ground without its site")
	map.free()
	for n in notes:
		print("  note: " + n)
	if problems.is_empty():
		print("check_mesh_quality: OK (%d sites)" % measured.size())
		quit(0)
	else:
		print("check_mesh_quality: %d problems" % problems.size())
		for p in problems:
			print("  " + p)
		quit(1)


func _judge(key: String, f: Dictionary) -> void:
	var tris: int = f["tris"]
	var known: Dictionary = KNOWN.get(key, {})
	print("check_mesh_quality: %-16s %5d tris (budget %s)  zfight %d  degenerate %d  badnormal %d  float %d  plain %d" % [
			key, tris, str(BUDGET.get(key, "NONE")), f["zfight"], f["degenerate"], f["badnormal"], f["float"], f["plain"]])
	if not BUDGET.has(key):
		problems.append("%s: %d triangles and no BUDGET entry (add one)" % [key, tris])
	elif tris > int(BUDGET[key]):
		problems.append("%s: %d triangles (budget %d)" % [key, tris, BUDGET[key]])
	if f["plain"] > 0:
		problems.append("%s: %d triangles without a landmark material code (a draw call of its own)" % [key, f["plain"]])
	for kind: String in ["zfight", "degenerate", "badnormal", "float"]:
		var allowed := int(known.get(kind, 0))
		if f[kind] > allowed:
			problems.append("%s: %d %s (known %d)%s" % [key, f[kind], kind, allowed, _where(f, kind)])
		elif f[kind] < allowed:
			notes.append("%s: %s is down to %d (KNOWN says %d): lower it" % [key, kind, f[kind], allowed])


func _where(f: Dictionary, kind: String) -> String:
	var at: Array = f["at_" + kind]
	if at.is_empty():
		return ""
	var parts: Array[String] = []
	for v in at.slice(0, 3):
		parts.append("(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z])
	return " e.g. at " + ", ".join(parts)
