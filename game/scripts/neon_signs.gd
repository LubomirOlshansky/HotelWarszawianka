extends RefCounted
## Neon shop signs for the night: generic Polish shop words (no brands) in a tiny
## 5×7 pixel font, drawn into one atlas texture at build time, and placed on the
## ground floors of buildings that face a street. Each sign is one quad of a
## MultiMesh (neon.gdshader): the instance colour is the tube colour, the custom
## data picks the word and how it is mounted (on a dark plate or bare on the wall).
## The map builder adds them under a "Neon" node, which the game hides by day.
## A word with a letter this font lacks (the Polish ones: DO WYNAJĘCIA, ORANŻADA) is drawn with
## pixel_font.gd's glyphs instead, their accents in the row's top padding, as storefronts.gd's
## venue rows are.

const PixelFont := preload("res://scripts/pixel_font.gd")

const WORDS := ["KEBAB 24H", "BAR MLECZNY", "APTEKA", "KWIATY", "HOTEL", "KANTOR", "PIZZA", "KLUB", "NOCNY"]
## The landmarks loop: words only the landmarks wear (never a shop's), after WORDS in the atlas:
## the parody of the brand on Warsaw Spire's crown, the mall by Rondo Radosława's.
const LANDMARK_WORDS := ["SAMSONG", "ARKADKA", "PREZYDENT", "NOWOTEL", "WESTYNKA", "CHILTON", "INTERKONTI", "N", "O", "W", "T", "E", "L", "BANK POLSKA", "PEPEO ŻUBR", "ERZATZ",
		"METROPOLKA", "ENELMEDIK", "ACORN", "HOTELS", "--",
		# First scene item 3: the Eastern Wall's stores (parodies of their roof names).
		"JUNIOREK", "SAWKA", "WARSIK",
		# The stores' printed ad banners (the Mac photo check, 2026-11-01).
		"PROMOCJA", "LODY",
		# The tower and the slab behind the stores (specs C and D): a parody and a drink.
		"KOKA-KOLKA", "ORANŻADA",
		# The tower75 crown from F's photos (2026-11-05): the appliance maker as a parody.
		"PRALKA PLUS",
		# MDM's roofs (F's Street View shots, 2026-11-05): the red MDM, a parody of the phone maker
		# and of the car maker, and the hotel's own sign on the corner block.
		"MDM", "XIAOMY", "BYDŁO", "HOTEL MDM",
		# The Pawilony (2026-10-31): the bars' little words and the gate's name.
		"PIWO", "BAR", "SHOTY", "DISCO", "KARAOKE", "OTWARTE", "PAWILONY",
		# The start area as real Warsaw (R1, docs/design/start-area-real.md, 2026-11-01): the
		# Eastern Wall as it is in 2025/26, half empty after H&M, Zara and C&A left, the H&M
		# corner turning into a two-storey Frogs, a shoe chain on Zara's floor.
		"WYPRZEDAŻ", "DO WYNAJĘCIA", "DO", "WYNAJĘCIA", "FROGS XXL", "FROGS", "XXL", "KAPCIE", "SCENA RELAX",
		# R5: the Cepelia pavilion's book and vinyl store (a parody) and Zodiak.
		"EMPIRYK", "ZODIAK",
		# Dom pod Orłami's metal letters over Złota's square (a parody of the council's name).
		"KRAJOWA", "RADA SPÓŁDZIELNI ORŁÓW",
		# Gdański Business Center: parodies of two tenants' logos on the tower and the blocks.
		"AWIWA", "NIELZEN",
		# Dom Partii's roof sign (docs/design/gaulle-and-food-hype.md G2): the oak in Latin again.
		"ROBUR",
		# HOTEL PIURE's rooftop date bar (G3).
		"LORETKA",
		# Arkadka from F's photos (2026-11-03): Westfield as "west field" in Polish, the
		# hypermarket, the DIY store and the cinema on the sign tower.
		"ZACHODNIE", "POLE", "KARFUREK", "MERLINEK", "KINO SITKO",
		# The railway (docs/design/railway.md, S2): the round pavilion's letters at Powiśle.
		"WARSZAWA", "POWIŚLE",
		# F's photos (2026-11-06): the round pavilion's letters one box each (the ones N, O, W, T, E, L
		# don't give), and the jazz stage's valance.
		"A", "R", "S", "Z", "P", "I", "Ś", "JAZZ",
		# S3a: Warszawa Stadion's roof letters.
		"STADION",
		# S3e: Warszawa Wschodnia's fascia letters (with WARSZAWA above).
		"WSCHODNIA",
		# The river's bar barges (docs/landmarks/specs/barki.md): parodies of their names.
		"WIECZOREK", "BARKA", "MARINKA", "KASKADKA", "PRZYSTAŃ",
		# S3b: Warszawa Śródmieście's pavilions.
		"ŚRÓDMIEŚCIE",
		# The Mac photo check (2026-11-01): Ochota's letters by the entrance.
		"OCHOTA",
		# The Old Town hotels' names (parodies of Castle Inn and Hotel Bellotto, an aparthotel).
		"KASZTEL INN", "CANALETTO", "STARÓWKA",
		# Level 26, the rooftop club on the Atlas Tower.
		"LEVEL 26",
		# The hotel on Plac Zawiszy (a parody of the Radisson Blu Sobieski).
		"RADYSŁAW BLU",
		# Varso Place's name stone on the corner plaza (Krajobraz K3; a parody, never the real mark).
		"VERSO PLACE",
		# The Skyliner's crown (docs/design/city-life-satire.md #12): a small agency with a large nose.
		"NOSE AGENCY", "NOSE", "AGENCY",
		# Warsaw Unit's crown (the photo report, 2026-11-03): a parody of the insurer's logo.
		"WARTKA", "MBĄK",
		# Bracka and Plac Trzech Krzyży (photo builds, 2026-11-03): Vitkac's and the Sheraton's
		# names as parodies, a generic word over Jabłkowski's door.
		"VIPKAC", "SZERATON", "DOM MODY",
		# Filharmonia Narodowa's own green neon on its corner (the institution's name, not a brand;
		# SALA KONCERTOWA in two rows, as one it is wider than the atlas).
		"FN", "SALA", "KONCERTOWA",
		# Poczta Główna's red band over the colonnade (a parody of the operator's own band).
		"POCZTA",
		# The Vistula boulevards' bar pavilions and containers (docs/landmarks/specs/bulwary.md):
		# parody bar names and what the hatches sell.
		"CUDAK", "POMOSTEK", "RZECZKA", "LEMONIADA", "ZAPIEKANKI",
		# Towarowa 22 built as finished (2026-11-03): the drone port, the superblock's name and the
		# gilded last crane's plaque (the "Warsaw of the future" jokes).
		"WARSZAWA 2050", "DRONOPORT", "TOWAROWA 22", "OSTATNI ŻURAW WOLI",
		# Wola's 19. Dzielnica (F's photos, 2026-11-07): parodies of the building site's name on its
		# hoarding, the contractor's on its cabins and the developer's on the towers' crown.
		"OHO ONE", "ATLAS WIATR", "ASBUDKA",
		# Stacja Muzeum's gold letters over its canopy and the night market on the old platform.
		"WARSZAWA GŁÓWNA", "NOCNY TARG",
		# Kolejowa: parodies of the pinball museum's and the teal club's names.
		"FLIPEROWNIA", "ODESSKA",
		# Prosta 32, Prosta 28 and Łucka City from F's photos (2026-11-06): parodies of the
		# developer's red roof letters, a tenant's small red logo and the printer's roof board.
		"MARZYPOL", "PROSTO", "INTERBRUK",
		# SOWA CLUB and CITY 25 (F's photos, 2026-11-06): the pavilion's parody names, its menu
		# words, the soda's and the beer's parodies on its panel and terrace banners.
		"SOWA", "CLUB", "CITY", "25", "RESTAURANT", "GRILL BAR", "CITY 25", "PEPSZY", "STEKI", "BURGERY",
		"ZAPRASZAMY", "24H", "KACBERG",
		# Centrum LIM's podium from F's night photos (2026-11-06): parodies of the tenants' signs
		# (the casino chain, the small casino, the airline, the clinic, the frozen-food maker, the
		# design shop, the chemist, the bank), the roof screens' adverts and the car maker's name
		# on the Chałubińskiego 8 tower behind.
		"KASYNOS", "WAWKA", "KASYNKO", "LOD", "LINIE LODOWE", "LUZMED", "MROSTA", "TYGRYS", "KOPENHAGA",
		"ROSZMAN", "MILENIUSZ", "PALUSZKI", "HYM", "LEKSUS", "CZERY",
		# The Palace of Culture's venues (F, 2026-11-07): its stages, cinema, bars, museum and terrace.
		"KINOTEKA", "KULTURALNA", "TEATR", "DRAMATYCZNY", "MUZEUM", "TECHNIKI", "KONGRESOWA", "STUDIO",
		"TARAS", "30 PIĘTRO", "LALKA", "THE FUTURE", "SHOULD", "ALWAYS BE", "BETTER"]
## Tube colours (linear, bright): pink, cyan, violet, and a few words' usual colours.
const PINK := Color(1.0, 0.1, 0.55)
const CYAN := Color(0.1, 0.9, 1.0)
const VIOLET := Color(0.62, 0.25, 1.0)
const WORD_COLOURS := {"APTEKA": Color(0.2, 1.0, 0.45), "KANTOR": Color(1.0, 0.72, 0.12), "HOTEL": Color(1.0, 0.22, 0.25)}
## Font pixel size in metres, and the atlas row layout (pixels).
const PIXEL := 0.2
const PAD := 2
const GLYPH_H := 7
const ROW_H := GLYPH_H + 2 * PAD
const ATLAS_W := 72

const FONT := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
}


## Width of a word in font pixels (5 per letter, 1 between letters, 3 for a space).
static func word_width(word: String) -> int:
	if not own_font(word):
		return PixelFont.width(word)
	var w := 0
	for i in word.length():
		if i > 0:
			w += 1
		w += 2 if word[i] == " " else 5
	return w


## The atlas: one row per word, red = the tube, green = its glow (the tube grown by
## a pixel or two and faded), so the shader can draw a pixel-art halo.
static func atlas() -> ImageTexture:
	var all := all_words()
	var h := ROW_H * all.size()
	var img := Image.create_empty(ATLAS_W, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	for r in all.size():
		var word: String = all[r]
		var x := PAD
		var tube := {}
		if not own_font(word):
			PixelFont.each_pixel(word, PAD, func(px: int, row: int) -> void:
				if px < ATLAS_W:
					tube[Vector2i(px, r * ROW_H + row)] = true)
			word = ""
		for i in word.length():
			if i > 0:
				x += 1
			var ch := word[i]
			if ch == " ":
				x += 2
				continue
			var rows: Array = FONT[ch]
			for gy in GLYPH_H:
				var line: String = rows[gy]
				for gx in 5:
					if line[gx] == "#":
						tube[Vector2i(x + gx, r * ROW_H + PAD + gy)] = true
			x += 5
		for p in tube:
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var q := Vector2i(p.x + dx, p.y + dy)
					if q.x < 0 or q.y < r * ROW_H or q.x >= ATLAS_W or q.y >= (r + 1) * ROW_H:
						continue
					var g := 1.0 - (absi(dx) + absi(dy)) / 4.0
					var c := img.get_pixelv(q)
					img.set_pixelv(q, Color(c.r, maxf(c.g, g), 0, 1))
		for p in tube:
			img.set_pixelv(p, Color(1, 1, 0, 1))
	return ImageTexture.create_from_image(img)


## Whether every letter of `word` is in this file's FONT (else pixel_font.gd draws it).
static func own_font(word: String) -> bool:
	for ch in word:
		if ch != " " and not FONT.has(ch):
			return false
	return true


## The atlas rows: the shop words, the landmarks' words, then the Eastern Wall stores' shop and
## ad words from data/eastern_wall_shops.json (swapped there as the shops change; landmarks.gd
## _dtc_banners), each once.
static var _all: Array = []
static func all_words() -> Array:
	if not _all.is_empty():
		return _all
	var out: Array = WORDS + LANDMARK_WORDS
	var f := FileAccess.get_file_as_string("res://data/eastern_wall_shops.json")
	var json: Variant = JSON.parse_string(f) if f != "" else null
	if json is Dictionary and (json as Dictionary).get("stores") is Dictionary:
		var stores: Dictionary = json["stores"]
		for k: String in stores.keys():
			for list: String in ["banners", "fronts"]:
				for spec: Variant in (stores[k] as Dictionary).get(list, []):
					if spec is Dictionary:
						for l: Variant in (spec as Dictionary).get("lines", []):
							if not str(l) in out:
								out.append(str(l))
	_all = out
	return _all


## The tube colour for a word, varied by a 0..1 pick.
static func colour_for(word: String, pick: float) -> Color:
	if WORD_COLOURS.has(word) and pick < 0.7:
		return WORD_COLOURS[word]
	var choices := [PINK, CYAN, VIOLET]
	return choices[int(pick * 30.0) % 3]


## The quad every sign uses: 1 × 1, facing +Z, UV.y = 0 at the top.
static func quad() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(-0.5, 0.5, 0), Vector3(0.5, 0.5, 0), Vector3(0.5, -0.5, 0), Vector3(-0.5, -0.5, 0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.BACK)
		st.set_uv(uvs[k])
		st.add_vertex(corners[k])
	return st.commit()


## A sign's transform on a wall: `at` is the middle of its bottom edge on the
## wall face, `out` the wall's outward normal. Text reads left to right from
## outside: the quad's +X is (out.z, 0, -out.x).
static func place(word: String, at: Vector3, out: Vector3) -> Transform3D:
	var length := (word_width(word) + 2 * PAD) * PIXEL
	var height := ROW_H * PIXEL
	var right := Vector3(out.z, 0.0, -out.x).normalized()
	var basis := Basis(right * length, Vector3.UP * height, out.normalized())
	return Transform3D(basis, at + Vector3.UP * height * 0.5 + out.normalized() * 0.14)


static func length_of(word: String) -> float:
	return (word_width(word) + 2 * PAD) * PIXEL
