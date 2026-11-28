extends "res://scripts/landmarks/niecala.gd"
## v0.8 "Landmarks": the buildings that make it Warsaw at a glance, built in code
## from the real footprints and heights in centrum.json (OpenStreetMap outlines and
## building parts, which carry `height` / `min_height`) instead of their GUGiK LoD2 or
## OpenStreetMap lumps: the Palace of Culture and Science (stepped tower, attics and
## pinnacles, clock faces, the gilded spire, the Congress Hall and the wings),
## Złote Tarasy's glass wave, the Rotunda, Varso Tower and its spire, Stadion Narodowy,
## Warszawa Centralna's roof and the gate towers of Most Poniatowskiego. The landmarks loop
## (2026-10-30) adds the skyline's towers (TOWERS: Złota 44, Warsaw Spire, Q22, Rondo 1 and
## the rest), each from its mapped parts in its own colour and skin, and Muzeum Narodowe.
##
## map_builder.gd asks `replaces(p)` for every LoD2 building and OpenStreetMap outline
## (whatever stands in a landmark's zone is dropped), then `build(st)` adds the models
## to the city's building meshes. building.gdshader draws them: UV2.x >= 2 is a
## material code (M_*), UV2.y the wall's top above the ground, UV the metres along and
## up a wall (UV.x < 0 on tops). Every triangle also goes into the helicopter's roof
## grid (map_builder._roof_triangle) and the grid the game picks a tapped landmark
## from; the walls at street level stop the car.
##
## TD-10 (2026-11-15): this file is the core, the site list (`_find_sites`, in card order with the
## quiet sites last), `build()`'s dispatch by key and what the map asks. The models are in
## game/scripts/landmarks/: common.gd (what two areas share) and one file per area, each the base of
## the next, this file extending the last. A new landmark goes into its area's file
## (docs/architecture/extending.md).

## The landmarks loop (2026-10-30): the skyline's towers, so each reads as itself and not as one
## more blue box. Each is built from its mapped building parts (the outline `osm` names; what
## else stands in it is dropped) in its skin, glass colour and roof colour; `crest` adds its
## top: "slope" (Złota 44's sail falls away from its high corner), "frame" (Rondo 1's open
## crown); `mapped` keeps the parts' mapped colours. Colours from photographs, kept a step
## paler than life for the game's palette. The Rondo Daszyńskiego towers (Spire, Skyliner, Unit,
## Mennica, Generation Park Y, the HUB) are the exception: dark navy glass as in life (F's photos,
## 2026-11-17: the light blue read wrong next to them).
const ChunkedSurface := preload("res://scripts/chunked_surface.gd")

const TOWERS := [
	{"key": "zlota44", "osm": "Złota 44", "style": S_SAIL, "glass": "#bccdd8", "roof": "#e4e8ea", "crest": "slope"},
	{"key": "spire", "osm": "Warsaw Spire", "style": S_MIRROR, "glass": "#2f4562", "roof": "#b9c4cc",
			"with": [Vector2(-2672.0, 195.0), Vector2(-2745.0, 150.0)]},  # the two crescent wings
	# Q22 and Rondo 1 rebuilt from the top-50 photo set (2026-11-08): _build_q22, _build_rondo1.
	{"key": "q22", "osm": "Q22", "style": S_BANDS, "glass": "#3f5e5c", "roof": "#9ea4a6", "sign": "DELOJT"},
	{"key": "rondo1", "osm": "Rondo 1", "style": S_BANDS, "glass": "#8aa3b5", "roof": "#a9b3b9",
			"base_sign": "ENELMEDIK"},
	{"key": "plater49", "osm": "InterContinental", "style": S_GRID, "glass": "#5f7f9a", "roof": "#c3c7c9", "sign": "INTERKONTI"},
	# Cosmopolitan (Twarda 2/4, F's photos 2026-11-08, docs/landmarks/photo-reports/cosmopolitan.md): a dark
	# glass shaft with a red-soffit cantilever over a stepped glass podium (_build_cosmopolitan).
	{"key": "cosmopolitan", "osm": "Cosmopolitan", "style": S_GRID, "glass": "#33485d", "roof": "#8d9399"},
	# WTT from the top-50 photo set (T05, 2026-11-08; reworked 2026-11-15, spec wtt.md): the parts by
	# their mapped colours, the dark grey glass drum in floor bands, the warm beige stone slab with
	# punched windows, the plain silver crown (its slits and the mast in skyline.gd) and its name.
	{"key": "wtt", "osm": "Warsaw Trade Tower", "style": S_RIBBON, "glass": "#36434e", "roof": "#8d979c",
			"crown_from": 162.0, "crown": "#c5c6c5", "crown_sign": true, "sign": "UNIKWA", "sign_col": Color(0.95, 0.97, 1.0),
			"skins": {"#f4d9c6": [S_PUNCHED, "#d8c1a5"], "#839099": [S_TILE, "#c5c6c5"], "#2e404e": [S_RIBBON, "#36434e"],
					"#a6abaa": [S_BANDS, "#9aa3a8"]}},
	# The Rondo Daszyńskiego towers rebuilt from the Mac's photo reports (F, 2026-11-03;
	# docs/landmarks/photo-reports/skyliner.md, warsaw_unit.md, mennica.md, gpy.md, warsaw_hub.md).
	# `crown_from`: parts standing from that height up are the black crown block (`crown`);
	# `crown_sign`: the `sign` goes on that block (in `sign_col`), not on the shaft; `slope_to`: the
	# roof's cut rises towards that side; `fin`: a glass plate on the cut's high corner; `strips`:
	# dark vertical strips at the long faces' ends and middles; `top`: a part's height cap.
	# Skyliner: dark navy mirror glass (a fine spandrel at every floor), the roof cut rising to the east (the Rondo)
	# with a glass fin on the high corner, the black crown block (130-180 m) and the mast at the
	# north end; no real sign up there, so the parody NOSE AGENCY sits on the block's east face.
	# F's HUB photos (2026-11-06): the fin is bronze-gold (the full-height gold strip under it: BACKLOG).
	{"key": "skyliner", "osm": "Skyliner", "style": S_MIRROR, "glass": "#2a4560", "roof": "#59636b", "sign": "NOSE AGENCY",
			"crown_from": 125.0, "crown": "#1e2226", "crown_sign": true, "slope_to": Vector2(1.0, 0.0), "fin": "#c9a24a",
			"shops": [["KANTOR", "#ffb81f", 0.25], ["SUSHI", "#ff4a6a", 0.7]], "shops_dir": Vector2(0.0, -1.0)},
	# Warsaw Unit: dark navy glass between black strips (each corner and the middle of the long
	# faces), the 22 m black crown block (180-202 m) with the insurer's logo, here WARTKA in red.
	# RD-1 (2026-11-06, the report and street photos): the shaft tapers from the 27 m base to
	# 90 % at 168.8 m and the crown stands on the narrowed top (`taper`: from, to, scale); the
	# base's lifted wings (9 m up) stand over a glass hall set 6 m in, so the tower's foot reads
	# as the two-storey gate (`hall`); F's photos (2026-11-06) show the podium blocks clad in a
	# fine grid of warm grey stone panels, floodlit at night (`podium`, `podium_style`).
	# The Dragon Skin (F's photos and notes, 2026-11-19): that "stone" is the kinetic skin of loose
	# aluminium plates over the podium box east of the shaft, crossed by white light slits, lit
	# salmon pink at night, with a green wall in a recess and the tenant's red name (`scales`: the
	# plates' colour, building.gdshader S_SCALES; skyline.gd _unit_skin_dress); the shaft's glass
	# runs down to the ground (`podium` is the tower's glass), and the café on the corner (`shops`).
	{"key": "unit", "osm": "Warsaw Unit", "style": S_MIRROR, "glass": "#2c4264", "roof": "#8a96a0", "sign": "WARTKA",
			"crown_from": 168.0, "crown": "#1b1e22", "crown_sign": true, "sign_col": Color(1.0, 0.15, 0.12), "strips": "#20252c",
			"taper": Vector3(27.0, 168.8, 0.9), "hall": 6.0, "podium": "#2c4264", "podium_style": S_MIRROR,
			"scales": "#80878e", "shops": [["STARY BAKS", "#2fd18a", 0.35]]},
	# Mennica Legacy Tower: dark blue glass with vertical silver fins, a flat top (no crown).
	# RD-2 (2026-11-06): the 13 m ground storeys are an open arcade: the copper-tinted lobby
	# set 5 m in under the shaft's soffit, the mapped posts as round stainless columns (`arcade`).
	# F's photos (2026-11-06): the bank's white name high on the faces, here the parody MBĄK.
	{"key": "mennica", "osm": "Mennica Legacy Tower", "style": S_FINS, "glass": "#3a5474", "roof": "#b5c0c9",
			"sign": "MBĄK", "sign_col": Color(0.95, 0.97, 1.0), "arcade": 13.0, "lobby": "#8a4a32", "columns": "#c9ced3",
			"shops": [["BISTRO", "#ffd27a", 0.3, 5.0], ["LUNCH", "#7fe0ff", 0.7, 5.0]]},
	# Generation Park Y: dark blue glass in a white grid (white piers every 3 m), a flat roof; 140 m.
	# RD-3 (2026-11-06): black spandrel patches a bay or two wide every few storeys and the two
	# dark top storeys (`patches`), and the decked roof terraces of the Z and X wings (`terraces`:
	# a point in each wing's roof, its deck at the roof's mapped height).
	{"key": "gpy", "osm": "Generation Park Y", "style": S_GRID, "glass": "#33506f", "roof": "#8d969c",
			"patches": "#1a1d22", "terraces": [Vector3(-2654.0, 43.9, 268.0), Vector3(-2687.0, 53.8, 286.0), Vector3(-2605.0, 37.3, 300.0)],
			"shops": [["PIEKARNIA", "#ffcf5a", 0.3], ["APTEKA", "#33ff73", 0.75]]},
	# The Warsaw HUB's two glass towers (unnamed in OpenStreetMap: found by a point, `at`, in
	# the tallest building there): dark blue glass, flat roofs; B (the south one) stands about
	# 15 % lower than A in the photos though OSM gives both 130 m.
	# RD-4 (2026-11-06): a 1.5 m parapet with a silver edge and the grey plant blocks on each
	# roof (`parapet`, `plant`), and the 8 x 12 m glazed skylight on the 10.9 m podium between
	# the two (`skylight`: its rectangle, the podium's height).
	{"key": "hub_b", "at": Vector2(-2677.0, 576.0), "style": S_MIRROR, "glass": "#34506e", "roof": "#b8bcbf",
			"parapet": "#c8ccd0", "plant": Vector2(17.0, 13.0), "skylight": [Rect2(-2678.0, 599.0, 9.0, 12.0), 10.9],
			"shops": [["RAMEN", "#ff6a3a", 0.3], ["KAWA", "#ffe2b0", 0.7],
					["ORAKEL", "#ff3b30", 0.18, 0.0, 7.6, 1.0], ["STANDARD CZARTER", "#3fb4ff", 0.62, 0.0, 7.6, 1.0]],
			"screen": 4.5},
	{"key": "hub_c", "at": Vector2(-2677.0, 633.0), "style": S_MIRROR, "glass": "#34506e", "roof": "#b8bcbf", "top": 112.0,
			"parapet": "#c8ccd0", "plant": Vector2(12.0, 8.0), "screen": 4.5,
			"shops": [["HUB", "#f2f4f6", 0.5, 0.0, 4.0, 2.4]]},
	# The HUB's third, round-ended tower is the hotel (85 m): cream fins over narrow windows, a
	# dark band over the glazed ground floors.
	# F's photos (2026-11-19): the office towers' glass runs 4.5 m over their roofs under a dark
	# crown band (`screen`), the tenants' names over the podium's street front (parodies); the
	# hotel's name twice on its band and The Roof bar on top (`the_roof`, `band_signs`:
	# [word, colour, facing, height, letter height]).
	{"key": "crowne", "at": Vector2(-2706.0, 512.0), "style": S_TILE, "glass": "#e8e4da", "roof": "#b8bcbf", "cool": true,
			"band": "#3a3c40", "the_roof": true,
			"band_signs": [["KORONA", "#f4f1ea", Vector2(0.0, -1.0), 10.1, 0.8], ["PLAZA", "#f4f1ea", Vector2(0.0, -1.0), 9.0, 0.8],
					["HOLIDEJ INN", "#7fd35a", Vector2(0.7, -0.7), 9.6, 0.8],
					["KORONA PLAZA", "#f4f1ea", Vector2(1.0, -0.3), 9.6, 0.8]]},
	# The Zachodnia offices by the tracks (F, 2026-11-06; street photos from Mapillary and Panoramax,
	# refs/equator*, refs/brama): Brama Zachodnia is the terracotta tower with a green-glazed ground
	# floor; Equator a graphite block in ribbon glazing over a perforated-metal car-park screen;
	# Equator II graphite with blue-grey ribbon glass. The software house on Equator II's 9th floor
	# gets the parody BLUZOFT on the roof edge.
	{"key": "brama", "osm": "Brama Zachodnia", "style": S_PUNCHED, "glass": "#c99573", "roof": "#8d8a86", "h": 47.2},
	# Both stand on modelled street blocks (blk_31002630, blk_305521858) that carry their roofs and
	# plant: `on_block` (the block's roof height) leaves the body to the block, the tower adds its sign.
	{"key": "equator", "osm": "Equator", "style": S_RIBBON, "glass": "#4a5a6c", "roof": "#8a8f93", "h": 53.8, "on_block": 63.4},
	{"key": "equator2", "osm": "Equator II", "style": S_RIBBON, "glass": "#5a7490", "roof": "#8a8f93", "h": 50.5, "sign": "BLUZOFT",
			"on_block": 61.9},
	{"key": "skysawa", "osm": "Skysawa", "style": S_BANDS, "glass": "#7e93a3", "roof": "#a7b0b6"},
	# Błękitny Wieżowiec (Plac Bankowy 2, 1991): untinted reflective float glass that mirrors the
	# sky, hence blue (its first cladding was copper, the "Golden Tower"; spec blekitny.md). Deep
	# blue panes in the kit's grid skin (F's look check, 2026-11-15): the glass shader read it grey.
	{"key": "blekitny", "osm": "Błękitny Wieżowiec", "style": S_GRID, "glass": "#2f6cbf", "roof": "#9aa3aa", "cool": true},
	# The blue glass office north of Hotel Warszawa on Plac Powstańców (F's photos, 2026-11-08): the
	# GUGiK LoD2 mesh of this 70 m tower is open (walls and roof in pieces: it read see-through with
	# a broken top), so the mapped outline is built whole, in solid blue reflective glass.
	{"key": "powstancow_blue", "at": Vector2(-792.0, -97.0), "style": S_MIRROR, "glass": "#35649f", "roof": "#8d969e",
			"h": 70.0, "cool": true},
	{"key": "wcf", "osm": "Warszawskie Centrum Finansowe", "style": S_DARK, "glass": "#4d6862", "roof": "#7d8580"},
	# The dusk loop (2026-10-31): Centrum LIM holds the Marriott (the 140 m tower at about
	# (-1308, 697)), so the one site is dressed as it: dark green-black glass in a fine grid,
	# dark bands, a lattice mast and the names (_marriott; rebuilt from photos 2026-11-15, spec lim.md).
	{"key": "lim", "osm": "Centrum LIM", "style": S_GRID, "glass": "#132a2e", "roof": "#6f777b", "sign": "PREZYDENT", "marriott": true},
	# Chałubińskiego 8 (Oxford Tower): the car maker's lit name on its crown (F's LIM photos,
	# 2026-11-06), as the parody CZERY.
	{"key": "chalubinskiego8", "osm": "Chałubińskiego 8", "style": S_FINS, "glass": "#2f6f8f", "roof": "#c9cfd2", "mapped": true,
			"sign": "CZERY"},
	# Spektrum from the top-50 photo set (T35, 2026-11-08): the parts by their mapped colours, the
	# drum in blue glass between white aluminium bands, the dark slabs in a square dark-glass grid.
	# Rebuilt from F's photos (2026-11-13, _build_spektrum): the glass fin, the podium, the crown's
	# screens and the rooftop club THE WJU, colours in its SPEKTRUM_* constants.
	{"key": "spektrum", "osm": "Spektrum Tower", "style": S_BANDS, "glass": "#4a6d86", "roof": "#7c878c", "mapped": true},
	# The Bridge is its own site now (_build_bridge, F's photos 2026-11-06).
	# The second pass: the rest of the skyline over 80 m (the hotels by their addresses).
	{"key": "grzybowska63", "osm": "Hilton Warsaw City", "style": S_BANDS, "glass": "#4d7590", "roof": "#9aa5ad", "sign": "CHILTON"},
	{"key": "jp2_21", "osm": "The Westin Warsaw", "style": S_GRID, "glass": "#86aca7", "roof": "#a9b5b3", "mapped": true, "sign": "WESTYNKA"},
	# The Novotel is modelled whole from F's five photos (2026-11-07): _build_novotel.
	{"key": "marszalkowska94", "osm": "Novotel Warszawa Centrum", "style": S_TILE, "glass": "#d9dcdf", "roof": "#c9c9c2", "novotel": true},
	{"key": "central", "osm": "Central Tower", "style": S_DARK, "glass": "#3e5c78", "roof": "#6f7d88"},
	# Ilmet (Mapillary 2026-02 and 2025 street photos): a round-cornered terracotta-banded shaft whose top steps in twice.
	{"key": "ilmet", "osm": "Ilmet", "style": S_BANDS, "glass": "#8a5e4c", "roof": "#8c8278", "chamfer": true},
	# Platinum Towers from the top-50 photo set (T36, 2026-11-08): cream stone piers with punched
	# windows at the corners, the glass between them banded by the balconies' white glass railings.
	{"key": "platinum_a", "osm": "Platinum Tower A", "style": S_RIBBON, "glass": "#6b7f8e", "roof": "#c4c8c8", "mapped": true,
			"skins": {"#c1a48b": [S_PUNCHED, "#e4e0d6"], "#647887": [S_BANDS, "#8aa1ad"]}},
	{"key": "platinum_b", "osm": "Platinum Tower B", "style": S_RIBBON, "glass": "#6b7f8e", "roof": "#c4c8c8", "mapped": true,
			"skins": {"#c1a48b": [S_PUNCHED, "#e4e0d6"], "#647887": [S_BANDS, "#8aa1ad"]}},
	# The bank tower on Grzybowska (T37, 2026-11-08; OSM name kept for the lookup only): beige stone with punched windows over a green
	# glass grid on the lower floors, the bank's name (the parody) on the crown, grey glass podium.
	# The street block under it (blk_238169923) is the better body (the stone crown, the glass grid): `on_block`.
	{"key": "pepeo_tower", "osm": "Pekao Tower", "style": S_PUNCHED, "glass": "#d9d2c2", "roof": "#a9a69c", "mapped": true,
			"sign": "PEPEO ŻUBR", "on_block": 82.2,
			"skins": {"#ffffff": [S_PUNCHED, "#d9d2c2"], "#2c4c50": [S_GRID, "#4f7a76"], "#545a56": [S_DARK, "#545a56"],
					"": [S_GRID, "#6f7c80"]}},
	# Widok Towers (F's photos, 2026-11-08, folder E4-widok): pale blue-grey glass in a white
	# aluminium grid, not green; a white roof edge.
	{"key": "widok", "osm": "Widok Towers", "style": S_GRID, "glass": "#86a3b8", "roof": "#c6cbcf", "cool": true},
	# The PZU Tower's two stepped glass volumes (92 and 97 m, one round-topped) in pale
	# green-blue glass with ribbon bands, and its slim white mast (106 m). JM Tower's grey fins
	# stand on dark navy glass (a dozen small mapped pilasters in #bfbfc4: kept as mapped).
	{"key": "pzu", "osm": "PZU Tower", "style": S_RIBBON, "glass": "#8fb5bd", "roof": "#c4cccf"},
	{"key": "jm", "osm": "JM Tower", "style": S_FINS, "glass": "#2b4560", "roof": "#7d878e", "mapped": true},
	# Babka Tower (Rondo Zgrupowania AK "Radosław", 2000; spec babka.md, F's photos): a pale grey
	# stone tower with punched windows and a glazed loggia column on each face, the cable firm's
	# parody name on the top floor, a red mast, and the stone office block round its foot (_babka).
	{"key": "babka", "osm": "Babka Tower", "style": S_PUNCHED, "glass": "#d9d8d3", "roof": "#9b9794", "sign": "WEKTRA",
			"sign_col": Color(0.3, 0.45, 1.0), "babka": true,
			"with": [Vector2(-2739.5, -2255.0)]},  # the 34 m office block round its foot (_babka_block)
]

## The info cards: name, then Polish and English lines. Facts kept to what is certain.
const INFO := {
	"kino_muranow": ["Kino Muranów",
			"Kino studyjne z 1951 roku. Przed nim fontanna z puttami.",
			"An arthouse cinema since 1951. A fountain with putti in front."],
	"palace": ["Pałac Kultury i Nauki",
			"237 m razem z iglicą. Otwarty w 1955 roku.",
			"237 m with its spire. Opened in 1955."],
	"lawrynowicz": ["Kamienica Ławrynowicza",
			"Pasiasta jak tort: żółta i czerwona cegła, arkady i schodkowe szczyty przy Alejach Ujazdowskich.",
			"Striped like a layer cake: yellow and red brick, arcades and stepped gables on Aleje Ujazdowskie."],
	"wedel": ["Kamienica Wedla",
			"Biała, bogato zdobiona kamienica, a nad jej rogiem cwałuje neonowa zebra.",
			"A white tenement with a neon zebra galloping over the corner."],
	"szpitalna5": ["Szpitalna 5",
			"Narożna kamienica w brzoskwiniowym tynku, z balkonami i ślepą arkadą na rogu.",
			"A corner tenement in peach plaster, with iron balconies and a blind arch at the corner."],
	"adwentysci": ["Kościół Adwentystów na Foksal", "Zbór w żółtej kamienicy za ogródkiem.", "A church inside a yellow house behind a front garden."],
	"plebania_zwycieskiej": ["Plebania parafii Matki Boskiej Zwycięskiej", "Plebania za ogrodzeniem, w kremowym tynku.", "The presbytery behind its railings, in cream plaster."],
	"plebania_pallotynow": ["Plebania przy Skaryszewskiej", "Plebania pallotynów obok kaplicy Matki Boskiej Częstochowskiej.", "The Pallottines' presbytery beside the Our Lady of Częstochowa chapel."],
	"pallotyni_dom": ["Dom pallotynów przy Skaryszewskiej", "Dom zakonny pallotynów za kościołem Chrystusa Króla.", "The Pallottine fathers' house behind the church of Christ the King."],
	"plebania_zagorna": ["Plebania przy Zagórnej", "Dom parafii Matki Bożej Częstochowskiej, w szarym tynku jak kościół.", "Our Lady of Częstochowa's parish house, in the church's grey render."],
	"rodziny_maryi_pawilon": ["Pawilon sióstr Rodziny Maryi", "Niski dom przy klasztorze sióstr, pod zieloną miedzią.", "The low house by the sisters' convent, under green copper."],
	"plebania_leszno": ["Plebania parafii Narodzenia NMP", "Plebania kościoła na Lesznie, w łososiowym tynku jak kościół.", "The presbytery of the church on Leszno, in the church's salmon plaster."],
	"misjonarze_tyl": ["Dom zakonny Księży Misjonarzy", "Tylne skrzydło domu misjonarzy przy kościele Świętego Krzyża.", "The back wing of the Missionaries' house by the Holy Cross church."],
	"solec_dom": ["Dom przy kościele Świętej Trójcy na Solcu", "Dom parafii Świętej Trójcy, w kremowym tynku jak kościół.", "Holy Trinity parish's house, in the church's cream plaster."],
	"dom_parafialny_barbara": ["Dom Parafialny im. Prymasa Tysiąclecia", "Dom parafii św. Barbary, w żółtym tynku przy Świętej Barbary.", "St Barbara's parish house, in yellow plaster on Świętej Barbary."],
	"szarytki_zaulek": ["Domy Szarytek przy zaułku", "Dwa domy sióstr miłosierdzia za klasztorem na Tamce.", "Two houses of the Sisters of Charity behind their convent on Tamka."],
	"faustyna_klasztor": ["Klasztor przy sanktuarium św. Faustyny", "Domy Zgromadzenia Sióstr Matki Bożej Miłosierdzia przy Żytniej.", "The Sisters of Our Lady of Mercy's houses round St Faustina's shrine."],
	"elzbietanki": ["Siostry Elżbietanki", "Dom prowincjalny sióstr za Piekarską, nad ogrodami Podwala.", "The Elizabethan sisters' provincial house behind Piekarska, over the Podwale gardens."],
	"szarytki": ["Siostry Szarytki na Tamce", "Klasztor sióstr miłosierdzia pod skarpą, z wieżyczką.", "The Sisters of Charity under the escarpment, with their turret."],
	"gigantami": ["Kamienica Pod Gigantami",
			"Dwaj kamienni giganci trzymają balkon nad bramą. Dobre miejsce na randkę, jeśli zdążysz.",
			"Two stone giants hold up the balcony over the gate. A fine place for a date, if you get there in time."],
	"filtry": ["Stacja Filtrów Lindleya",
			"Czysta woda dla Warszawy od 1886 roku. William Lindley, Sokrat Starynkiewicz i 36 filtrów ukrytych pod trawą.",
			"Clean water for Warsaw since 1886. William Lindley, Sokrat Starynkiewicz and 36 filter beds hidden under the grass."],
	"tarasy": ["Złote Tarasy",
			"Centrum handlowe pod falującym szklanym dachem, obok biurowce Lumen i Skylight. Otwarte w 2007 roku.",
			"A shopping centre under a rolling glass roof, with the Lumen and Skylight office buildings. Opened in 2007."],
	"rotunda": ["Rotunda",
			"Okrągły szklany pawilon u zbiegu Marszałkowskiej i Alej Jerozolimskich. Klasyczne miejsce spotkań: „pod Rotundą”.",
			"A round glass pavilion where Marszałkowska meets Al. Jerozolimskie. The classic place to meet: \"under the Rotunda\"."],
	"varso": ["Varso Tower",
			"310 m z iglicą: najwyższy budynek w Unii Europejskiej.",
			"310 m with its spire: the tallest building in the European Union."],
	"stadium": ["Stadion Narodowy",
			"Otwarty w 2012 roku na Euro 2012, w misie dawnego Stadionu Dziesięciolecia. Biało-czerwona plecionka fasady.",
			"Opened in 2012 for Euro 2012, in the bowl of the old Tenth-Anniversary Stadium. A red-and-white woven skin."],
	"legia": ["Stadion Leguminy",
			"Stadion przy Łazienkowskiej, dom stołecznych legionistów od 1930 roku, przebudowany w 2010. Biało-czerwono-zielone trybuny pod białym dachem.",
			"The ground on Łazienkowska, home of the capital's legionnaires since 1930, rebuilt in 2010. White, red and green stands under a white roof."],
	"centralna": ["Warszawa Centralna",
			"Dworzec otwarty w 1975 roku: szklana hala pod płaskim, wysuniętym dachem na paraboloidach hiperbolicznych.",
			"The main station, opened in 1975: a glass hall under a flat overhanging roof on hyperbolic paraboloid shells."],
	"poniatowski": ["Most Poniatowskiego",
			"Most otwarty w 1914 roku. Wieże strzegą wjazdów.",
			"The bridge opened in 1914. Its towers guard the way on."],
	"powisle_towers": ["Wieże wiaduktu przy Powiślu",
			"Druga para bram mostu Poniatowskiego, nad torami linii średnicowej. W jednej z wież od lat działa klub.",
			"The bridge's second pair of gates, over the cross-city line. One of the towers has held a club for years."],
	"zlota44": ["Złota 44",
			"192 m. Apartamentowiec Daniela Libeskinda, zwany Żaglem: biała wieża, której narożnik wygina się jak skrzydło orła aż po ostry szczyt.",
			"192 m. Daniel Libeskind's apartment tower, called the Sail: a white tower whose corner sweeps out like an eagle's wing to a sharp tip."],
	"spire": ["Warsaw Spire",
			"220 m. Szklana wieża, smukła przy ziemi i pękata w połowie, z lustrzanym daszkiem nad wejściem i stalowymi kolumnami. Obok dwa łukowe biurowce, Spire B i C, a między nimi plac z fontannami. Otwarta w 2016 roku.",
			"220 m. A glass tower, slim at the ground and swelling halfway up, with a mirrored canopy over the entrance and steel columns. Beside it two curved office blocks, Spire B and C, with a fountain plaza between them. Opened in 2016."],
	"q22": ["Q22",
			"155 m. Ciemnozielone szkło, grafitowa korona i maszt w biało-czerwone pasy. Obok niższe skrzydło ze szklanym, pochyłym dachem. Otwarty w 2016 roku.",
			"155 m. Dark green glass, a graphite crown and a red-and-white mast. Beside it a lower wing with a sloping glass roof. Opened in 2016."],
	"rondo1": ["Rondo 1",
			"159 m, a z anteną 192 m. Zaokrąglony, srebrny front do ronda, ciemna płyta z boku i szklany ekran ponad dachem. Otwarty w 2006 roku.",
			"159 m, 192 m to the antenna. A rounded silver front to the roundabout, a dark slab on its side and a glass screen over the roof. Opened in 2006."],
	"plater49": ["Emilii Plater 49",
			"164 m. Dolne piętra przecina wielki prześwit.",
			"164 m. A great gap cuts through its lower floors."],
	"cosmopolitan": ["Cosmopolitan",
			"160 m. Projekt Helmuta Jahna, białe pasy balkonów.",
			"160 m. Designed by Helmut Jahn: white bands of balconies."],
	"wtt": ["Warsaw Trade Tower",
			"208 m z iglicą. Ciemnoniebieski szklany walec, beżowa kamienna ściana z oknami i srebrna korona. Otwarty w 1999 roku.",
			"208 m with its spire. A dark blue glass drum, a beige stone wall of windows and a silver crown. Opened in 1999."],
	"skyliner": ["Skyliner",
			"195 m przy rondzie Daszyńskiego.",
			"195 m by Rondo Daszyńskiego."],
	"unit": ["Warsaw Unit",
			"202 m przy rondzie Daszyńskiego.",
			"202 m by Rondo Daszyńskiego."],
	"hub_b": ["The Warsaw HUB",
			"Dwie wieże po 130 m nad węzłem przesiadkowym przy rondzie Daszyńskiego.",
			"Two 130 m towers over the interchange at Rondo Daszyńskiego."],
	"hub_c": ["The Warsaw HUB",
			"Dwie wieże po 130 m nad węzłem przesiadkowym przy rondzie Daszyńskiego.",
			"Two 130 m towers over the interchange at Rondo Daszyńskiego."],
	"mennica": ["Mennica Legacy Tower",
			"140 m przy Prostej.",
			"140 m on Prosta."],
	"gpy": ["Generation Park Y",
			"140 m przy rondzie Daszyńskiego.",
			"140 m by Rondo Daszyńskiego."],
	"gpxz": ["Generation Park X i Z",
			"Dwa biurowce przy rondzie Daszyńskiego po bokach wieży Y.",
			"Two office blocks by Rondo Daszyńskiego framing tower Y."],
	"powstancow_blue": ["Szklana wieża przy placu Powstańców",
			"70 m niebieskiego szkła przy Hotelu Warszawa.",
			"70 m of blue glass beside Hotel Warszawa."],
	"skysawa": ["Skysawa",
			"155 m przy Świętokrzyskiej.",
			"155 m on Świętokrzyska."],
	"blekitny": ["Błękitny Wieżowiec",
			"120 m przy placu Bankowym. Szkło lustrzane z 1991 roku: błękitny, bo odbija niebo.",
			"120 m on Plac Bankowy. 1991 mirror glass: blue because it reflects the sky."],
	"wcf": ["Warszawskie Centrum Finansowe",
			"144 m. Otwarte w 1998 roku.",
			"144 m. Opened in 1998."],
	"lim": ["Centrum LIM",
			"Hotel Prezydent nad Dworcem Centralnym, 140 m, od 1989 roku.",
			"Hotel Prezydent over the Central Station, 140 m, since 1989."],
	"chalubinskiego8": ["Chałubińskiego 8",
			"140 m. Białe żebra na niebieskim szkle.",
			"140 m. White ribs on blue glass."],
	"spektrum": ["Spektrum Tower",
			"128 m przy Twardej. Niebieski walec w białych pasach, ukośna szklana płetwa, a na dachu klub THE WJU: białe kanapy, palmy, wieczorem DJ i pierścień światła nad miastem.",
			"128 m on Twarda. A blue drum in white bands, a slanted glass fin, and on the roof the club THE WJU: white sofas, palms, a DJ in the evening and a ring of light over the city."],
	"bridge": ["The Bridge",
			"174 m szkła przy Placu Europejskim. Fasada złamana ukośnymi szwami jak kartka papieru, na szczycie ciemna korona, a na dachu bank ERZATZ.",
			"174 m of glass on Plac Europejski. Its faces fold along diagonal seams like a sheet of paper, a dark crown on top, and the ERZATZ bank on the roof."],
	"grzybowska77": ["Grzybowska 77",
			"Biurowiec z cegły i kamienia w stylu lat 50.: kamienne filary parteru, długi balkon nad ulicą. Stoi u stóp The Bridge.",
			"An office block of brick and stone in the 1950s style: stone piers on the ground floor, a long balcony over the street. It stands at the foot of The Bridge."],
	"grzybowska63": ["Chilton", "Hotel przy Grzybowskiej 63, 94 m. Na luzie.", "A hotel at Grzybowska 63, 94 m. Chilled."],
	"unique": ["Unique Tower",
			"Białe balkony oplatają trzy budynki przy Grzybowskiej 51.",
			"White balconies wrap around three buildings at Grzybowska 51."],
	"jp2_21": ["Westynka", "Hotel przy Jana Pawła II 21, 94 m, z rurą szkła na fasadzie.", "A hotel at Jana Pawła II 21, 94 m, with a glass tube up its front."],
	"marszalkowska94": ["Nowotel", "Hotel przy Marszałkowskiej 94/98, 95 m. Nowy od 1974 roku.", "A hotel at Marszałkowska 94/98, 95 m. New since 1974."],
	"central": ["Central Tower", "115 m przy Alejach Jerozolimskich.", "115 m on Al. Jerozolimskie."],
	"ilmet": ["Ilmet", "103 m.", "103 m."],
	"platinum_a": ["Platinum Tower A", "83 m kremowego kamienia i szklanych balkonów.", "83 m of cream stone and glass balconies."],
	"platinum_b": ["Platinum Tower B", "Bliźniak A: kamienne narożniki, szklane balkony.", "A's twin: stone corners, glass balconies."],
	"pepeo_tower": ["Wieża PEPEO ŻUBR", "Beżowy kamień nad zielonym szkłem, na Grzybowskiej.", "Beige stone over green glass, on Grzybowska."],
	"lucka": ["Łucka City", "Biały wieżowiec mieszkalny przy Łuckiej 15, 100 m, schodkami w dół do Łuckiej i do Prostej. Na dachu INTERBRUK.",
			"A white residential tower at Łucka 15, 100 m, stepping down to Łucka and to Prosta. INTERBRUK on the roof."],
	"prosta32": ["Prosta 32",
			"Biurowiec w białej betonowej koronce z rombów na niebieskim szkle. Na dachu czerwony MARZYPOL.",
			"An office tower in a white concrete lace of diamonds over blue glass. MARZYPOL in red on the roof."],
	"prosta28": ["Prosta 28",
			"Zielona szklana wieża na stalowych iksach, z tarasami pełnymi drzew na szczycie.",
			"A green glass tower on steel X braces, with terraces full of trees at the top."],
	"widok": ["Widok Towers", "95 m przy Alejach Jerozolimskich.", "95 m on Al. Jerozolimskie."],
	"pzu": ["Wieża PZU", "Biurowiec przy Alejach Jana Pawła II: dwie szklane bryły, jedna z okrągłym szczytem.",
			"An office tower on Al. Jana Pawła II: two glass volumes, one with a round top."],
	"jm": ["JM Tower", "Biurowiec przy Alejach Jerozolimskich, ciemne szkło i szare żebra.",
			"An office tower on Al. Jerozolimskie, dark glass and grey fins."],
	"babka": ["Babka Tower",
			"96 m przy rondzie Babka. Mieszkania nad biurami, z 2000 roku.",
			"96 m at the Babka roundabout. Flats over offices, from 2000."],
	"teatr": ["Teatr Wielki",
			"Opera Narodowa. Gmach Antonia Corazziego z 1833 roku: dziesięć kolumn, tympanon z płaskorzeźbą i kwadryga Apollina na attyce.",
			"The National Opera. Antonio Corazzi's building of 1833: ten columns, a carved pediment and Apollo's quadriga on the attic."],
	"kopernik": ["Centrum Nauki Kopernik",
			"Otwarte w 2010 roku. Ogród na dachu, obok miedzianoczerwone planetarium.",
			"Opened in 2010. A roof garden, the copper-red planetarium beside it."],
	"buw": ["Biblioteka Uniwersytecka",
			"Otwarta w 1999 roku. Miedziane strony z tekstami, ogród na dachu.",
			"Opened in 1999. Copper pages of text out front, a garden on the roof."],
	"zamek": ["Zamek Królewski",
			"Zniszczony w 1944 roku, odbudowany w latach 1971–1984.",
			"Destroyed in 1944, rebuilt in 1971–1984."],
	"dekalog_estate": ["Osiedle Inflancka, Dzika 6",
			"Tu Kieślowski kręcił Dekalog: okna naprzeciw okien, 14 pięter.",
			"Kieślowski shot the Dekalog here: windows facing windows, 14 floors."],
	"inflancka_pools": ["Ośrodek Sportowy Inflancka",
			"Balon nad krytym basenem, latem okrągłe baseny i zjeżdżalnie.",
			"An air dome over the indoor pool; round pools and slides in summer."],
	"arkady": ["Arkady Kubickiego i ogrody zamkowe",
			"Arkady z 1821 roku, na nich Ogród Górny, niżej Ogród Dolny.",
			"Kubicki's arcades of 1821, the Upper Garden on top, the Lower below."],
	"barbakan": ["Barbakan",
			"Ceglana brama dawnych murów miejskich, odbudowana po wojnie.",
			"A brick gate of the old city walls, rebuilt after the war."],
	"archikatedra": ["Archikatedra św. Jana",
			"Gotycki kościół z cegły na Starym Mieście.",
			"A Gothic brick church in the Old Town."],
	"jezuici": ["Kościół Jezuitów",
			"Sanktuarium Matki Bożej Łaskawej przy Świętojańskiej, tuż obok katedry.",
			"The Jesuit church on Świętojańska, right next to the Cathedral."],
	"sw_anna": ["Kościół Świętej Anny",
			"Na początku Krakowskiego Przedmieścia.",
			"Where Krakowskie Przedmieście begins."],
	"mansjonaria": ["Mansjonaria",
			"Dom z wielkimi przyporami na rogu placu Zamkowego i Świętojańskiej, przy dębie.",
			"The house with the big buttresses on the corner of Castle Square and Świętojańska, by the oak."],
	"nikidw": ["Instytut Kultury Wsi",
			"Długa arkada na Krakowskim Przedmieściu, tuż za kościołem św. Anny.",
			"The long arcade on Krakowskie Przedmieście, right past St Anne's."],
	"prezydencki": ["Pałac Prezydencki",
			"Przed nim książę Józef Poniatowski na koniu i cztery kamienne lwy.",
			"Prince Józef Poniatowski on horseback and four stone lions before it."],
	"sw_krzyz": ["Kościół Świętego Krzyża",
			"W filarze kościoła spoczywa serce Chopina.",
			"Chopin's heart rests in one of its pillars."],
	"staszic": ["Pałac Staszica",
			"Przed nim stoi pomnik Kopernika.",
			"Copernicus's statue stands in front of it."],
	"zacheta": ["Zachęta",
			"Galeria sztuki w gmachu z 1900 roku.",
			"An art gallery in a building of 1900."],
	"trojca": ["Kościół Świętej Trójcy",
			"Luterańska rotunda Zuga z 1781 roku przy placu Małachowskiego.",
			"Zug's Lutheran rotunda of 1781 on Plac Małachowskiego."],
	"wszystkich": ["Kościół Wszystkich Świętych",
			"Przy placu Grzybowskim.",
			"On Plac Grzybowski."],
	"wizytki": ["Kościół Wizytek",
			"Rokokowa fasada z 1761 roku, tuż przy Krakowskim Przedmieściu.",
			"A rococo facade of 1761, right on Krakowskie Przedmieście."],
	"branickich": ["Pałac Branickich",
			"Barokowy pałac z 1740 roku przy Miodowej, z attyką pełną rzeźb i lukarnami z oculusami.",
			"The baroque palace of 1740 on Miodowa, its attic crowded with statues and oculus dormers."],
	"prymasowski": ["Pałac Prymasowski",
			"Klasycystyczny pałac przy Senatorskiej z półkolistymi kolumnadami.",
			"A classical palace on Senatorska with curved courtyard colonnades."],
	"jablonowskich": ["Pałac Jabłonowskich",
			"Neobarokowy pałac z wieżą zegarową przy placu Teatralnym.",
			"A neo-baroque palace with a clock tower on Plac Teatralny."],
	"karmelici": ["Kościół Karmelitów",
			"Rokokowo-klasycystyczna fasada z końca XVIII wieku, ze złotym globem na szczycie.",
			"A late-18th-century front with a gilt globe on top."],
	"czapski": ["Pałac Czapskich",
			"Barokowy pałac Krasińskich-Czapskich, dziś Akademia Sztuk Pięknych.",
			"The baroque Krasiński-Czapski palace, now the Academy of Fine Arts."],
	"prus": ["Pomnik Bolesława Prusa",
			"Pisarz z laską za plecami, z brązu, 3,6 m, na skwerze Twardowskiego.",
			"The novelist, bronze, 3.6 m, cane behind his back, on Twardowski Square."],
	"wyszynski": ["Pomnik Kardynała Wyszyńskiego",
			"Prymas Tysiąclecia na tronie, z brązu, przed kościołem Wizytek.",
			"The Primate seated in bronze before the Visitationists' church."],
	"zamoyski": ["Pałac Zamoyskich",
			"Klasycystyczny pałac przy Nowym Świecie, odbudowany po wojnie; dziś uniwersytecki instytut.",
			"A classicist palace on Nowy Świat, rebuilt after the war; today a university institute."],
	"mikulski55": ["Kamienice Mikulskiego",
			"Dwie sąsiednie kamienice z dolnego Nowego Światu, z lokalami w parterach i oficynami w podwórzach.",
			"Two neighbouring tenements of lower Nowy Świat, shops below and courtyard wings behind."],
	"mikulski53": ["Kamienice Mikulskiego",
			"Dwie sąsiednie kamienice z dolnego Nowego Światu, z lokalami w parterach i oficynami w podwórzach.",
			"Two neighbouring tenements of lower Nowy Świat, shops below and courtyard wings behind."],
	"burger": ["Kamienica Bürgera",
			"Czteropiętrowa kamienica przy Nowym Świecie, jedna z odbudowanych w latach 1948-1953.",
			"A four-storey tenement on Nowy Świat, rebuilt in the years 1948-1953."],
	"jasinski": ["Kamienica Jasińskiego",
			"Kamienica przy Nowym Świecie z kawiarnianymi ogródkami pod oknami.",
			"A tenement on Nowy Świat with café gardens below its windows."],
	"kossakowski": ["Pałac Kossakowskich",
			"Pałac przy dolnym Nowym Świecie, w parterze lokale i cukiernia.",
			"A palace on lower Nowy Świat, shops and a pastry café on its ground floor."],
	"mickiewicz": ["Pomnik Adama Mickiewicza",
			"Poeta z 1898 roku na wysokim cokole, na skwerze przy Krakowskim Przedmieściu.",
			"The poet, 1898, on a tall pedestal in the square on Krakowskie Przedmieście."],
	"brama_uw": ["Brama Główna Uniwersytetu",
			"Wejście na kampus najstarszej uczelni stolicy, z 1816 roku.",
			"The way into the campus of the capital's oldest university, 1816."],
	"ratusz": ["Ratusz przy placu Bankowym",
			"Pałac Komisji Rządowej Przychodów i Skarbu (Corazzi, 1825): żółty, z kolumnami, dziś urząd miasta.",
			"The Treasury palace (Corazzi, 1825): yellow, columned, today the city hall."],
	"wojewodzki": ["Mazowiecki Urząd Wojewódzki",
			"Skrzydło pałacu Komisji Skarbu od strony placu: tu załatwia się sprawy wojewody.",
			"The Treasury palace's wing on the square, where the voivode's paperwork gets done."],
	"gielda": ["Giełda i Bank Polski",
			"Klasycystyczny gmach Corazziego z rotundą, kiedyś giełda, dziś siedziba spółek.",
			"Corazzi's classical bourse and bank with its rotunda, now offices."],
	"filharmonia": ["Filharmonia Narodowa",
			"Sala koncertowa przy Jasnej, otwarta w 1901 roku, odbudowana w 1955. Tu odbywa się Konkurs Chopinowski.",
			"The concert hall on Jasna, opened in 1901, rebuilt in 1955. The Chopin Competition is played here."],
	"teatr_polski": ["Teatr Polski",
			"Teatr Arnolda Szyfmana przy Karasia, otwarty w 1913 roku.",
			"Arnold Szyfman's theatre on Karasia, opened in 1913."],
	"arsenal": ["Arsenał",
			"Siedemnastowieczny arsenał królewski, od 1953 Muzeum Archeologiczne.",
			"The seventeenth-century royal arsenal, the Archaeological Museum since 1953."],
	"mniszchow": ["Pałac Mniszchów",
			"Niski pałacyk przy Senatorskiej, z cegły i tynku.",
			"A low palace on Senatorska, brick and plaster."],
	"landau": ["Dom Bankowy Landaua",
			"Neorenesansowy dom bankiera przy placu Bankowym.",
			"A banker's neo-Renaissance house on Plac Bankowy."],
	"uruski": ["Pałac Uruskich",
			"Pałac z 1847 roku przy bramie uniwersytetu; dziś geografowie.",
			"An 1847 palace beside the University's gate; geographers inside now."],
	"stara_buw": ["Stara Biblioteka",
			"Dawna biblioteka uniwersytetu z zegarem i grupą rzeźb na attyce.",
			"The University's old library, a clock and three statues on its attic."],
	"uw_straz": ["Straż Uniwersytecka",
			"Zielona budka strażników kampusu. Tu wiedzą wszystko.",
			"The campus guards' green kiosk. They know everything here."],
	"uw_roch": ["Szpital św. Rocha",
			"Dawny szpital, dziś kultura polska i samorząd studentów.",
			"A former hospital, now Polish culture and the student union."],
	"uw_jezyki": ["Szkoła Języków Obcych",
			"Tu uczą się mówić po ludzku w każdym języku.",
			"Where students learn to talk like people in every language."],
	"uw_pomuzealny": ["Gmach Pomuzealny",
			"Dawne muzeum, dziś historycy i Sala Kolumnowa.",
			"A former museum, now the historians and the Column Hall."],
	"uw_szkola_glowna": ["Szkoła Główna",
			"Najstarszy gmach dydaktyczny kampusu; archeolodzy.",
			"The campus's oldest teaching house; the archaeologists."],
	"uw_porektorski": ["Gmach Porektorski",
			"Tu mieszkał Fryderyk Chopin.",
			"Fryderyk Chopin lived here."],
	"uw_poseminaryjny": ["Collegium Iuridicum I",
			"Dawne seminarium, dziś prawnicy.",
			"A former seminary, now the lawyers."],
	"uw_audytoryjny": ["Gmach Audytoryjny",
			"Sale wykładowe nauk politycznych.",
			"Lecture halls of the political scientists."],
	"uw_mineralogiczny": ["Pawilon Mineralogiczny",
			"Dawny pawilon minerałów, dziś poloniści.",
			"The old minerals pavilion, now the Polish department."],
	"auditorium_maximum": ["Auditorium Maximum",
			"Największa aula kampusu, imienia Mickiewicza.",
			"The campus's biggest hall, named after Mickiewicz."],
	"kazimierzowski": ["Pałac Kazimierzowski",
			"Barokowy pałac w głębi kampusu, siedziba rektoratu.",
			"A baroque palace deep in the campus, home of the rector's office."],
	"potocki": ["Pałac Potockich",
			"Pałac z dziedzińcem honorowym, dziś Ministerstwo Kultury.",
			"A palace round its court, today the Ministry of Culture."],
	"kordegarda": ["Kordegarda",
			"Dawna wartownia przy pałacu Potockich, dziś galeria sztuki.",
			"The palace's old guardhouse, today an art gallery."],
	"hotel_kasztel": ["Kasztel Inn",
			"Mały hotel w kamienicy tuż przy placu Zamkowym i Świętojańskiej.",
			"A small hotel in a tenement by Castle Square and Świętojańska."],
	"hotel_canaletto": ["Hotel Canaletto",
			"Hotel w starej kamienicy, nazwany od malarza widoków Warszawy.",
			"A hotel in an old tenement, named for the painter of Warsaw's views."],
	"hotel_starowka": ["Rezydencja Starówka",
			"Apartamenty w kamienicy przy Rynku, dla gości z walizką na kółkach.",
			"Apartments in a tenement on the Market, for wheeled-suitcase guests."],
	"bristol": ["Hotel Bristol",
			"Wielki hotel z 1901 roku, z mansardą i belwederem na rogu.",
			"A grand hotel of 1901, with a mansard and a belvedere on its corner."],
	"smolensk": ["Pomnik Ofiar Tragedii Smoleńskiej",
			"Czarne kamienne schody z 2018 roku, pamięci ofiar katastrofy z 10 kwietnia 2010.",
			"Black stone stairs of 2018, for the victims of the 10 April 2010 air crash."],
	"pilsudski": ["Pomnik Józefa Piłsudskiego",
			"Marszałek w płaszczu, z dłońmi na szabli, na granitowym głazie (1995).",
			"The Marshal in a greatcoat, hands on his sabre, on a granite block (1995)."],
	"kaczynski": ["Pomnik Lecha Kaczyńskiego",
			"Prezydent z brązu na niskim cokole, odsłonięty w 2021 roku.",
			"The President in bronze on a low plinth, unveiled in 2021."],
	"polonia": ["Hotel Polonia Palace",
			"Hotel z 1913 roku przy Alejach Jerozolimskich. Przetrwał powstanie.",
			"A hotel of 1913 on Al. Jerozolimskie. It outlived the Uprising."],
	"ujazdowski": ["Zamek Ujazdowski",
			"Z 1624 roku, zburzony w 1944, odbudowany. Dziś sztuka współczesna.",
			"Built 1624, razed 1944, rebuilt. Now a centre for modern art."],
	"polskie_radio": ["Polskie Radio",
			"Siedziba Polskiego Radia przy Myśliwieckiej, tuż obok Agrykoli.",
			"Polish Radio headquarters on Myśliwiecka, right beside Agrykola."],
	"dom_poselski": ["Dom Poselski",
			"Hotel posłów przy Sejmie.",
			"The deputies' hotel by the Sejm."],
	"stary_dom_poselski": ["Stary Dom Poselski",
			"Przedwojenny gmach przy Sejmie z okrągłym narożnikiem na Wiejskiej.",
			"Pre-war Sejm building with a rounded corner on Wiejska."],
	"rembielinskiego": ["Pałacyk Rembielińskiego",
			"Klasycystyczny pałacyk z lat 40. XIX w. z kolumnową loggią.",
			"An 1840s classical palace with a columned loggia on the avenue."],
	"willa_raua": ["Willa Raua",
			"Włoska willa z lat 60. XIX w. z boniowaniem i głębokim gzymsem.",
			"An 1860s Italianate villa with rusticated corners and deep eaves."],
	"dziewulskich": ["Pałacyk Dziewulskich",
			"Kameralny kremowy pałacyk w ogrodzie przy Alejach Ujazdowskich.",
			"A compact cream villa in a garden along Aleje Ujazdowskie."],
	"pod_karczochem": ["Pałac pod Karczochem",
			"Pałacowa kamienica z balkonami i wieżyczką z kamiennym karczochem.",
			"Five-storey tenement with balconies and a stone artichoke turret."],
	"sobieski": ["Radysław Blu",
			"Hotel przy placu Zawiszy, w kolorowych pasach.",
			"A hotel on Plac Zawiszy, in colourful bands."],
	"mariensztat": ["Rynek Mariensztacki",
			"Osiedle odbudowane w 1949 roku; bohater filmu „Przygoda na Mariensztacie” z 1954 roku.",
			"The estate rebuilt in 1949, and the star of the 1954 film \"Przygoda na Mariensztacie\"."],
	"zbawiciela": ["Kościół Najświętszego Zbawiciela",
			"Bazylika z 1911 roku w duchu polskiego renesansu i baroku, z dwiema smukłymi wieżami; od niej wziął nazwę plac.",
			"The 1911 basilica in the Polish Renaissance and Baroque manner, with two slender towers; the square is named after it."],
	"zbawiciela_plac": ["Plac Zbawiciela",
			"Okrągły plac MDM z lat 50.: kolumnady wokół ronda, a pod nimi kawiarnie do późnej nocy.",
			"MDM's round square of the 1950s: colonnades round the roundabout and cafés under them till late."],
	"aleksander": ["Kościół Świętego Aleksandra",
			"Rotunda Aignera z lat 1818-1825 z dwoma portykami; po wojnie odbudowana bez dawnych wież.",
			"Aigner's rotunda of 1818-1825 with two porticoes; rebuilt after the war without its later towers."],
	"zelazna": ["Osiedle Za Żelazną Bramą",
			"Jedenaście bloków z wielkiej płyty, zaprojektowanych przez Skolimowskiego.",
			"Eleven large-panel blocks of the 1960s-70s, designed by Jerzy Skolimowski."],
	"norblin": ["Fabryka Norblina",
			"Białe warsztaty przy uliczce, miedziane ściany i szklane piętra. Tu się teraz siedzi.",
			"White workshops along a lane, copper walls and glass storeys on top. People sit here now."],
	"browary": ["Browary Warszawskie",
			"Dawny browar Haberbuscha i Schielego, dziś biura i bary.",
			"The old Haberbusch and Schiele brewery, offices and bars now."],
	"koszyki": ["Hala Koszyki",
			"Ceglana hala targowa z 1909 roku. Dziś: ramen.",
			"The brick market hall of 1909. Now: ramen."],
	"torwar": ["Torwar",
			"Hala przy Łazienkowskiej z lat 50.: hokej, koncerty, gale. Od ulicy biały portyk na smukłych kolumnach, po meczu zawsze korek.",
			"The 1950s hall on Łazienkowska: hockey, concerts, galas. A white portico on slender columns faces the street, and there's a jam after every game."],
	"sad_okregowy": ["Sąd Okręgowy w Warszawie",
			"Sądy na Lesznie to dzieło Bohdana Pniewskiego z lat 1935–39. Za jasną fasadą kryje się pięć dziedzińców.",
			"Bohdan Pniewski designed the Leszno courts, built in 1935–39. Five courtyards lie behind the pale stone front."],
	"nbp": ["NBP, Oddział Okręgowy",
			"Oddział Narodowego Banku Polskiego przy placu Powstańców: długi dom w ciemnych, pochylonych blachach, szklany parter na tarasie, szerokie granitowe schody. Tu pieniądze śpią, zanim pójdą w miasto.",
			"The National Bank's Warsaw branch on Plac Powstańców: a long block in dark, leaning metal panels, a glass ground floor on a terrace, a wide flight of granite steps. The money sleeps here before it goes out into the city."],
	"city_gate": ["City Gate",
			"Biurowiec przy Wolskiej: białe pasy na wygiętym szkle.",
			"An office block on Wolska: white bands on curved glass."],
	"meridian": ["Meridian",
			"Jasne skrzydła z balkonami wokół otwartego dziedzińca.",
			"Pale wings with balconies round an open courtyard."],
	"oxygen": ["Oxygen",
			"Zaokrąglone narożniki, pasy okien, a z góry tarasy.",
			"Rounded corners, ribbons of windows and terraces on top."],
	"mostowski": ["Pałac Mostowskich",
			"Cztery kolumny w portyku Corazziego witają od strony alei Solidarności. Odbudowany po wojnie pałac jest dziś siedzibą stołecznej policji.",
			"Four columns in Corazzi’s portico greet you from al. Solidarności. Rebuilt after the war, the palace is now home to Warsaw’s police headquarters."],
	"hotel_saski": ["Hotel Saski",
			"Dawny hotel przy placu Bankowym, z dziedzińcem ukrytym za bramą.",
			"The old hotel on Plac Bankowy hides a courtyard behind its gate."],
	"dom_chlopa": ["Dom Chłopa",
			"Hotel na placu Powstańców z lat 1958-61, zbudowany dla chłopów przyjeżdżających do stolicy. Falisty gzyms na dachu, zielony neon, kasyno na parterze.",
			"The hotel on Plac Powstańców of 1958-61, built for farmers visiting the capital. A wavy roof edge, a green neon on top, a casino on the ground floor."],
	"batalion_kilinski": ["Pomnik Batalionu AK „Kiliński”",
			"Pomnik żołnierzy batalionu Armii Krajowej „Kiliński”, który w sierpniu 1944 roku zdobył PAST-ę. Pochyła granitowa płyta, białe stele z Kotwicą, 1939 i 1945, zawsze świeże kwiaty.",
			"The monument to the Home Army battalion \"Kiliński\", which took the PAST building in August 1944. A tilted granite slab, white stelae with the Kotwica, 1939 and 1945, and always fresh flowers."],
	"zyletkowiec": ["Żyletkowiec",
			"Biurowiec przy Marszałkowskiej z 1952 roku. Białe żyletki na każdej osi elewacji robią pasy światła i cienia, a ciemny dach wystaje nad ulicę.",
			"The 1952 office block on Marszałkowska. A white razor-blade fin on every bay makes bands of light and shadow, and a dark roof overhangs the street."],
	"rotunda_dynasy": ["Rotunda na Dynasach",
			"Okrągły dom na miejscu dawnej panoramy na Dynasach: ceglany parter, białe ramy, szkło.",
			"A round house where the old panorama stood on Dynasy: a brick base, white frames, glass."],
	"elektrownia": ["Elektrownia Powiśle",
			"Dawna elektrownia na Dobrej: ceglane hale, sklepy, hala z jedzeniem, ogródki w pasażach i cztery kominy, nocą na niebiesko.",
			"The old power station on Dobra: brick halls, shops, a food hall, beer gardens in the passages and four stacks, blue at night."],
	"mpw": ["Muzeum Powstania Warszawskiego",
			"Dawna elektrownia tramwajowa z 1908 roku. Wieża z Kotwicą, a w Parku Wolności Mur Pamięci z nazwiskami poległych.",
			"The tram power station of 1908. The tower with the Kotwica, and in Freedom Park the Wall of Remembrance with the names of the fallen."],
	"mirowska": ["Hala Mirowska",
			"Ceglana hala targowa.",
			"A brick market hall."],
	"gwardii": ["Hala Gwardii",
			"Ceglana hala przy Żelaznej Bramie, bliźniaczka Mirowskiej.",
			"A brick market hall by Żelazna Brama, Mirowska's twin."],
	"arkadia": ["Arkadka",
			"Największe centrum handlowe w mieście, przy rondzie Radosława: okrągły plac z fontanną, wieża z neonem i parking na dachu.",
			"The city's biggest mall, by Rondo Radosława: a round fountain plaza, a sign tower and a car park on the roof."],
	"forest": ["Forest",
			"Biurowiec z zielonymi tarasami i 120-metrową wieżą.",
			"An office block of planted terraces and a 120 m tower."],
	"towarowa22": ["Towarowa 22",
			"Superkwartał na miejscu drukarni Domu Słowa Polskiego: wieże, ogrody i park. W grze już gotowy, w prawdziwej Warszawie jeszcze się buduje.",
			"A superblock on the old Dom Słowa Polskiego printing works: towers, gardens and a park. Finished in the game; in the real Warsaw still being built."],
	"noho": ["OHO ONE (budowa)",
			"Tu robiono leki. Teraz rosną tarasowe kaskady apartamentów, a trzy żurawie liczą piętra.",
			"Medicines were made here. Now terraced cascades of flats are rising, and three cranes count the floors."],
	"stacja_muzeum": ["Stacja Muzeum",
			"Dawny dworzec Warszawa Główna. Na bocznicach śpią parowozy na czerwonych kołach; jeżdżą już tylko w pamięci.",
			"The old Warszawa Główna station. Steam engines on red wheels sleep on its sidings; they only run in memory now."],
	"nocny": ["Nocny Targ",
			"Stary peron pod graffiti. W weekend pachnie tu ramenem, pizzą i frytkami do świtu.",
			"An old platform under graffiti. At weekends it smells of ramen, pizza and chips until dawn."],
	"kolejowa": ["Kolejowa",
			"Stare magazyny kolejowe: w jednym grają flippery, w turkusowym klubie gra muzyka do rana.",
			"The old railway warehouses: pinball machines play in one, music plays till morning in the teal club."],
	"d19": ["19. Dzielnica",
			"Warszawa ma osiemnaście dzielnic. To osiedle przy Kolejowej uważa się za dziewiętnastą.",
			"Warsaw has eighteen districts. This estate on Kolejowa counts itself as the nineteenth."],
	"asbud": ["Towarowa Towers",
			"Dwie wieże mieszkalne w złotych i pomarańczowych ramach. Widok na Mordor w cenie.",
			"Two towers of flats in gold and orange frames. The view of Mordor comes with the rent."],
	"gbc": ["Gdański Business Center",
			"Biurowce przy Inflanckiej: szklana wieża ze ściętym czubkiem i dwa dziesięciopiętrowe bloki z białymi pasami pięter.",
			"The offices on Inflancka: a glass tower with a slanted crown and two ten-storey blocks with white floor bands."],
	"flaga": ["Flaga na rondzie Radosława",
			"Biało-czerwona na maszcie wysokim na prawie 58 m.",
			"The white-and-red on a mast almost 58 m tall."],
	"kladka": ["Kładka Abakanowicz",
			"452 metry z Karowej na Pragę, otwarta w 2024. Mówili: kładka donikąd. Pierwszy tydzień: 200 tysięcy ludzi idących donikąd. Samochodów zero, schodki do siedzenia, a czerwona linia to południk.",
			"452 metres from Karowa to Praga, opened in 2024. They called it the bridge to nowhere. First week: 200,000 people walking to nowhere. Zero cars, steps to sit on, and the red line is the meridian."],
	"wiadukt_markiewicza": ["Wiadukt Markiewicza",
			"1904: Karowa zawraca i przejeżdża nad sobą. Syrena Woydygi patrzy w dół, a w grudniu Barbórka robi tu Kryterium Asów i cała Warszawa stoi przy balustradzie.",
			"1904: Karowa turns back and drives over itself. Woydyga's mermaid looks down, and every December the Barbórka rally runs its Kryterium Asów here while all of Warsaw leans on the balustrade."],
	"szaja": ["Pomnik Krzysztofa „Szayi” Szaykowskiego",
			"Głos Kryterium Asów na Karowej przez lata. To on nazwał tę ulicę Panią Karową.",
			"The voice of the Kryterium Asów on Karowa for years. He was the one who named this street Lady Karowa."],
	"swieto": ["Most Świętokrzyski",
			"Most wantowy z 2000 roku: jeden pylon, wanty w jednej płaszczyźnie.",
			"A cable-stayed bridge of 2000: one pylon, its stays in one plane."],
	"ns4a": ["Nowy Świat 4A",
			"Szklany róg przy Dom Partii: cztery piętra świecących żeber, biało-czerwony pas, flaga na maszcie. Na górze PGR, na dole PRZEGRYWKI, gdzie gra się do rana.",
			"The glass corner by the Party House: four floors of glowing fins, a white-and-red band, a flag on the mast. PGR upstairs, PRZEGRYWKI downstairs, where the games run till morning."],
	"dom_partii": ["Dom Partii",
			"Biały gmach z 1952 roku. Była partia, giełda, dziś biura i bary.",
			"A white block from 1952. Once the Party, then the stock exchange, now offices and bars."],
	"deski": ["WTS DESKA",
			"Klub przy Zaruskiego nad Wisłą: hala tenisowa i jeden szklany kort do padla pod chmurką.",
			"The club on Zaruskiego by the Vistula: a closed tennis hall and one open-air glass padel court."],
	"gaulle": ["Pomnik generała de Gaulle'a",
			"Maszeruje Alejami od 2005 roku. Kopia tego z Paryża.",
			"Marching down the Avenues since 2005. A copy of the one in Paris."],
	"rynek": ["Rynek Starego Miasta",
			"Serce Starówki, odbudowane po wojnie z gruzów. Pod parasolami kawa, lody i turyści.",
			"The heart of the Old Town, rebuilt from rubble after the war. Coffee, ice cream and tourists under umbrellas."],
	"zamkowy": ["Plac Zamkowy",
			"Kolumna, zamek i parasole. Gołębie czekają na okruchy.",
			"The column, the castle and the umbrellas. Pigeons wait for crumbs."],
	"syrenka": ["Syrenka",
			"Z mieczem i tarczą, jak w herbie miasta. Stoi w fontannie pośrodku Rynku i pilnuje Warszawy.",
			"With her sword and shield, as on the city's coat of arms. She stands in the fountain in the middle of the square and watches over Warsaw."],
	"syrenka_powisle": ["Syrenka na Powiślu",
			"Brązowa, z 1939 roku, dłuta Ludwiki Nitschowej. Z mieczem nad głową stoi w fontannie na skraju bulwaru i patrzy na Wisłę. Nocą prowadzą do niej światła w bruku.",
			"Bronze, of 1939, by Ludwika Nitschowa. Sword over her head, she stands in her fountain at the boulevard's edge and watches the Vistula. At night the lights in the paving lead to her."],
	"dworzec_wodny": ["Dworzec Wodny",
			"Niski pawilon na nabrzeżu: szkło i drewno nad samą Wisłą.",
			"A low pavilion on the quay: glass and timber right over the Vistula."],
	"piano_house": ["Piano House",
			"Dom na Zajęczej, tuż pod Akademią Muzyczną. Elewacja jak klawiatura: białe klawisze, czarne okna.",
			"Flats on Zajęcza, just below the music university. The front is a keyboard: white keys, black windows."],
	"cube_house": ["Cube House",
			"Biała kostka przy Topieli, z wykuszami jak wysunięte szuflady.",
			"A white cube on Topiel, its bays sticking out like half-open drawers."],
	"hortus": ["Hortus",
			"Biura i kamienica wokół ogrodu, tam gdzie stała fabryka cukierków. Hortus to po łacinie ogród.",
			"Offices and a tenement-style block round a garden, where a sweet factory stood. Hortus is Latin for garden."],
	"pomnik_powstania": ["Pomnik Powstania Warszawskiego",
			"Wincenty Kućma, 1989. Powstańcy wybiegają spod walących się murów; obok zejście do kanału.",
			"Wincenty Kućma, 1989. Insurgents run out from under falling walls; beside them, the descent into the sewers."],
	"krasinski": ["Pałac Krasińskich",
			"Barok Tylmana z Gameren, 1677–1683. Dziś zbiory specjalne Biblioteki Narodowej.",
			"Tylman van Gameren's baroque palace, 1677–1683. Today the National Library's special collections."],
	"sad_najwyzszy": ["Sąd Najwyższy",
			"Marek Budzyński i Zbigniew Badowski, 1999. Zielone kolumny przed gmachem niosą łacińskie sentencje prawa.",
			"Marek Budzyński and Zbigniew Badowski, 1999. The green columns in front carry Latin maxims of the law."],
	"moderna": ["Modernka Powiśle",
			"Od frontu odnowiona przedwojenna kamienica, z tyłu nowe szkło i penthouse'y. Wisła trzysta kroków stąd.",
			"A restored pre-war tenement at the front, new glass and penthouses behind. The Vistula is three hundred steps away."],
	"kaskada": ["Kaskada",
			"Statek przycumowany do bulwarów. Zimą stoi, latem się kołysze.",
			"A vessel moored to the boulevards. Still in winter, rocking in summer."],
	"zygmunt": ["Kolumna Zygmunta",
			"Najstarszy świecki pomnik Warszawy, z 1644 roku.",
			"Warsaw's oldest secular monument, of 1644."],
	"metropolitan": ["Metropolitan",
			"Biurowiec Normana Fostera przy placu Piłsudskiego, z 2003 roku.",
			"Norman Foster's office building on Plac Piłsudskiego, of 2003."],
	"sejm": ["Sejm RP",
			"Przy Wiejskiej.",
			"On Wiejska."],
	"politechnika": ["Gmach Główny Politechniki",
			"Gmach Główny Politechniki Warszawskiej z 1901 roku. W środku Duża Aula pod szklanym dachem, na froncie Nauka z pochodnią.",
			"The Warsaw University of Technology's main building of 1901. Inside, the Great Hall under its glass roof; on the front, Science with her torch."],
	"poczta": ["Poczta Główna",
			"Główna poczta przy Świętokrzyskiej, z kopułką na rogu Jasnej. Kolejka do okienka jak zawsze.",
			"The main post office on Świętokrzyska, a small dome on the Jasna corner. A queue at the counter, as ever."],
	"pasta": ["PAST-a",
			"Wieża telefoniczna z 1908 roku. 20 sierpnia 1944 roku zdobyta przez powstańców z batalionu „Kiliński”.",
			"The telephone tower of 1908. Taken by the insurgents of the Kiliński Battalion on 20 August 1944."],
	"mf": ["Ministerstwo Finansów",
			"Gmach z lat 1953–56 przy Świętokrzyskiej. Tu liczą cudze pieniądze.",
			"1953–56 on Świętokrzyska: where the country's money is counted."],
	"florian": ["Katedra św. Floriana",
			"Neogotycka katedra na Pradze, 1888–1904. Dwie wieże po 75 m widać z drugiego brzegu Wisły.",
			"Praga's neo-Gothic cathedral, 1888–1904. Its two 75 m spires are seen from across the Vistula."],
	"kosciuszkowcy": ["Pomnik Kościuszkowców",
			"12 m brązu z 1985 roku: żołnierz sięga ręką ku drugiemu brzegowi. Warszawa mówi: „Pięć piw proszę”.",
			"12 m of bronze from 1985: a soldier reaching for the other bank. Warsaw calls it \"Five beers, please\"."],
	"port_praski": ["Port Praski",
			"Port budowany od 1919 roku, bez śluzy aż do 2017. Dziś kamienice, a doki wciąż za płotem.",
			"A port dug from 1919 with no lock until 2017. Now tenements, the docks still behind a fence."],
	"pp_basin": ["Basen Portu Praskiego",
			"Śluza, wieża i bulwar. Statków na razie brak, bobry są.",
			"A lock, a tower and a boulevard. No ships yet, beavers yes."],
	"bazar": ["Bazar Różyckiego",
			"Najstarszy bazar Warszawy, od 1882 roku. Stare budy obok nowych zielonych pawilonów. Kupisz tu wszystko.",
			"Warsaw's oldest market, since 1882. Old sheds face the new green kiosks. Everything is for sale."],
	"centrum_praha": ["Centrum Praha",
			"Piaskowcowy gmach na Pradze z fryzem twarzy i cynkową mansardą.",
			"A Praga sandstone block with a carved-faces frieze and zinc mansard."],
	"targowa33a": ["Pasaż Handlowy Targowa 33A",
			"Dwukondygnacyjny pasaż handlowy w głębi kwartału przy Targowej.",
			"A low two-storey trade podium tucked inside the Targowa block."],
	"powszechny": ["Teatr Powszechny im. Zygmunta Hübnera",
			"Przy Zamoyskiego 20 praska scena nosi imię Zygmunta Hübnera. Wysoka wieża nad dachem mieści sceniczne dekoracje.",
			"At Zamoyskiego 20, Praga's theatre bears Zygmunt Hübner's name. The tower above the roof holds the stage scenery."],
	"teresy": ["Kościół św. Teresy od Dzieciątka Jezus",
			"Jasny kościół parafialny przy Tamce, z wysokimi łukowymi oknami, okrągłym oknem i wielkim portalem.",
			"A light parish church on Tamka, with tall arched windows, a round window and a big arched porch."],
	"ateneum": ["Teatr Ateneum",
			"Szary dom teatru przy Jaracza, z kolumnowym portykiem i kolorowym napisem nad wejściem.",
			"The theatre's grey house on Jaracza, with a columned porch and the colourful name over the door."],
	"lipowa1a": ["Lipowa 1A",
			"Siedmiopiętrowy dom na Lipowej, naprzeciwko Biblioteki: biały cokół, szkło i zielonkawe żebra, taras na dachu.",
			"A seven-storey house on Lipowa across from the Library: white base, glass and teal fins, a roof terrace."],
	"flisac": ["Flisac, Tamka 2",
			"Apartamentowiec przy moście Świętokrzyskim: jasny kamienny szkielet, tarasy na dachu i kawa na rogu.",
			"The apartment block by the Świętokrzyski bridge: a light stone grid, roof terraces and coffee on the corner."],
	"muzeum": ["Muzeum Narodowe",
			"Gmach z lat 1927–1938 przy Alejach Jerozolimskich.",
			"The museum's building of 1927–1938 on Al. Jerozolimskie."],
	"wiktoria": ["Hotel Wiktoria",
			"Hotel z 1976 roku przy Królewskiej, z widokiem na plac Piłsudskiego.",
			"A hotel of 1976 on Królewska, looking out over Plac Piłsudskiego."],
	"bez_kantow": ["Dom bez Kantów",
			"Piaskowiec i zaokrąglone narożniki. Kantów tu nie ma.",
			"Sandstone and rounded corners: no kanty (edges, or swindles)."],
	"departament": ["Departament Wojskowej Służby Zdrowia",
			"Przy Królewskiej, na skraju placu Piłsudskiego.",
			"On Królewska, at the edge of Plac Piłsudskiego."],
	"europejski": ["Hotel Europejski",
			"Hotel Marconiego z 1877 roku, odnowiony i otwarty na nowo w 2018.",
			"Marconi's hotel of 1877, restored and reopened in 2018."],
	"msn": ["Muzeum Sztuki Nowoczesnej",
			"Biały gmach Thomasa Phifera przy Placu Defilad. Otwarty w 2024 roku.",
			"Thomas Phifer's white museum on Plac Defilad. Opened in 2024."],
	"trybuna": ["Trybuna honorowa",
			"Ocalały fragment trybuny z placu Defilad (1955), złożony z dawnego granitu. Dziś ogród widokowy na placu Centralnym.",
			"What is left of Plac Defilad's 1955 parade tribune, rebuilt in its old granite. Now a garden with a view over Plac Centralny."],
	"tr": ["Plac budowy TR Warszawa",
			"Betonowy szkielet nowego teatru, dwa czerwone żurawie i czarny płot.",
			"TR Warszawa's new theatre: a concrete shell, two red cranes, a black hoarding."],
	"nozyce": ["Złote nożyce",
			"Wielkie złote nożyce na granitowym cokole przed białym muzeum.",
			"Giant gold scissors on a granite plinth in front of the white museum."],
	"jarmark": ["Jarmark Warszawski",
			"Ponad 200 budek pod Pałacem, grzaniec, wielka choinka, karuzela wenecka, filiżanki i wieża z krzesełkami na placu Centralnym. Do 6 stycznia.",
			"Over 200 huts under the Palace: mulled wine, the big tree, a Venetian carousel, teacups and a chair-swing tower on Plac Centralny. Until 6 January."],
	"obeliski": ["Obeliski przy Pałacu",
			"Dwa granitowe obeliski z 1955 roku, po 12 metrów, w półkolach od strony Marszałkowskiej; obok nich wyjścia ewakuacyjne z podziemi Pałacu. Z czterech zostały dwa.",
			"Two 12 m granite obelisks of 1955 in the semicircles on the Marszałkowska side, beside the emergency exits from the Palace's underground. Two of the four survive."],
	"dtc": ["Domy Towarowe Centrum",
			"Trzy szklane domy towarowe Ściany Wschodniej, 1962–1970. Nazwy po Warsie i Sawie z legendy.",
			"The Eastern Wall's three glass department stores, 1962–1970, named after the legend's Wars and Sawa."],
	"grob": ["Grób Nieznanego Żołnierza",
			"Trzy łuki ocalałe z Pałacu Saskiego. Wieczny ogień i warta.",
			"Three arches left of the Saxon Palace. An eternal flame, a guard."],
	"hotel_warszawa": ["Hotel Warszawa",
			"Dawny Prudential z 1933 roku, pierwszy wieżowiec Warszawy. Kamienne lizeny, od 2018 znów hotel.",
			"The 1933 Prudential, Warsaw's first skyscraper: stone pilasters, a hotel again since 2018."],
	"cedet": ["Cedet",
			"Dawny Centralny Dom Towarowy z 1951 roku: pasy szkła, zaokrąglony narożnik, przebudowa 2018.",
			"The 1951 Central Department Store: ribbon glass, a rounded corner, rebuilt in 2018."],
	"polin": ["POLIN Muzeum Historii Żydów Polskich",
			"Muzeum z 2013 roku: szklana bryła przecięta kanionem holu, naprzeciw Pomnika Bohaterów Getta.",
			"The 2013 museum: a glass box split by the canyon of its hall, facing the Ghetto Heroes Monument."],
	"getto": ["Pomnik Bohaterów Getta",
			"Natan Rapaport, 1948: pomnik bojowników powstania w getcie warszawskim z 1943 roku.",
			"Nathan Rapoport, 1948: the memorial to the fighters of the 1943 Warsaw Ghetto Uprising."],
	"nike": ["Pomnik Bohaterów Warszawy",
			"Warszawska Nike Mariana Koniecznego, 1964: z mieczem w ręku, nad Trasą W-Z. Przeniesiona tu z placu Teatralnego w 1997 roku.",
			"The Warsaw Nike by Marian Konieczny, 1964, sword in hand over Trasa W-Z. Moved here from Plac Teatralny in 1997."],
	"slowacki": ["Pomnik Juliusza Słowackiego",
			"Poeta w długim płaszczu, z pochyloną głową, na wysokim słupie przed pałacem Ministra Skarbu.",
			"The poet in a long cloak, head bowed, on a tall pillar before the Treasury Minister's palace."],
	"starzynski": ["Pomnik Stefana Starzyńskiego",
			"Prezydent Warszawy, który we wrześniu 1939 roku poprowadził obronę miasta. Zapada się w wielki brązowy fotel.",
			"The mayor who led the city's defence in September 1939, sinking into a huge bronze armchair."],
	"maly_powstaniec": ["Pomnik Małego Powstańca",
			"Chłopiec w za dużym hełmie, z pistoletem maszynowym: pamięć dzieci, które walczyły w Powstaniu Warszawskim. Jerzy Jarnuszkiewicz, 1983.",
			"A boy in a helmet far too big, with a submachine gun: for the children who fought in the Warsaw Rising. Jerzy Jarnuszkiewicz, 1983."],
	"kilinski": ["Pomnik Jana Kilińskiego",
			"Szewc, który w 1794 roku poprowadził warszawiaków w insurekcji kościuszkowskiej. Stanisław Jackowski, 1936.",
			"The shoemaker who led the people of Warsaw in the 1794 Kościuszko Rising. Stanisław Jackowski, 1936."],
	"umschlagplatz": ["Umschlagplatz",
			"Stąd w latach 1942–1943 Niemcy wywieźli setki tysięcy Żydów z warszawskiego getta do obozu zagłady w Treblince.",
			"From here, in 1942–1943, the Germans deported hundreds of thousands of Jews from the Warsaw Ghetto to the Treblinka death camp."],
	"pomnik_wschod": ["Pomnik Poległym i Pomordowanym na Wschodzie",
			"Wagon pełen krzyży na torach, na podkładach nazwy miejsc kaźni. Pamięć ofiar sowieckiej napaści z 17 września 1939 roku.",
			"A wagon full of crosses on a track whose sleepers name the places of killing: for the victims of the Soviet invasion of 17 September 1939."],
	"vitkac": ["Vipkac",
			"Luksusowy dom towarowy przy Brackiej: ciemny kamień, ogród na dachu.",
			"A luxury store on Bracka: dark stone outside, a garden on the roof."],
	"jablkowscy": ["Dom Towarowy Braci Jabłkowskich",
			"Bracka 25, 1914: secesja, łuki witryn i dwie kolumny przy wejściu.",
			"Bracka 25, 1914: Art Nouveau, arched windows, two columns at the door."],
	"foksal": ["Kamienice Foksal 13 i 15",
			"Dwie odnowione przedwojenne kamienice: cegła, biały kamień, żeliwne balkony.",
			"Two restored pre-war tenements: brick, white stone, iron balconies."],
	"bgk": ["Gmach Banku Gospodarstwa Krajowego",
			"Al. Jerozolimskie 7, 1928–31: kamienny gmach Rudolfa Świerczyńskiego.",
			"Al. Jerozolimskie 7, 1928–31: Rudolf Świerczyński's granite bank."],
	"ufficio_primo": ["Ufficio Primo",
			"Wspólna 62, 1952: kamienna kostka Marka Leykama, dziś biura.",
			"Wspólna 62, 1952: Marek Leykam's stone cube, offices today."],
	"mlotek": ["Młotek",
			"Smolna 8, 1976: blok Bogusławskiego i Gniewiewskiego, głowa młotka nad skarpą.",
			"Smolna 8, 1976: Bogusławski and Gniewiewski's block, a hammer's head over the escarpment."],
	"kozia9": ["Kozia 9",
			"1974–76, Kuźmienko i Sembrat: blok wspina się po piętrze, okna chowają się w zębach.",
			"1974-76, Kuźmienko and Sembrat: the block climbs a storey at a time, windows hidden in its teeth."],
	"jerozolimskie57": ["Aleje Jerozolimskie 57-63",
			"Rząd kamienic naprzeciw Pałacu: odnowiona czerwona z pomarańczowym dachem (dawna Nowa Jerozolima), biała pod białą płachtą, dwie ozdobne z mansardą i zielone arkady z gablotami.",
			"The tenement row across from the Palace: the restored red one with the orange roof (where Nowa Jerozolima was), the white one under its white wrap, two ornate ones with zinc mansards, and the green arcades with their showcases."],
	"smolna38": ["Smolna 38",
			"Przedwojenna kamienica z bramą pod kamienną konsolą i erkerem; wieczorem czerwone światło i kolejka do klubu.",
			"A pre-war tenement: a gate under a stone console and an oriel; at night red light and the club queue."],
	"cparking": ["Cyfrowy Parking Novotel",
			"Nowogrodzka 27: osiem otwartych poziomów, murale w czerwone róże i na dole bar. Wjazd od Parkingowej.",
			"Nowogrodzka 27: eight open decks painted with red roses, a bar on the corner. The way in is off Parkingowa."],
	"karowa18a": ["Karowa 18a",
			"1978: blok-rzeźba na zakręcie Karowej, kolumny skrzyń przesunięte o piętro.",
			"1978: a block like a sculpture on Karowa's bend, columns of boxes a storey apart."],
	"sheraton": ["Szeraton Grand",
			"Hotel przy placu Trzech Krzyży: pasy na fasadzie, wieża na rogu.",
			"A hotel on Plac Trzech Krzyży: banded fronts, a drum on the corner."],
	"orly": ["Dom pod Orłami",
			"Jasna 1, 1912–17: dwa orły na narożnych wieżach patrzą na nowy skwer na Złotej.",
			"Jasna 1, 1912–17: two eagles on the corner towers look down on Złota's new park."],
	"cepelia": ["Pawilon Cepelii",
			"Szklany pawilon z 1966 roku na rogu Alej, odnowiony w 2024: książki i winyle na trzech poziomach.",
			"A 1966 glass pavilion on the Aleje corner, restored in 2024: books and vinyl on three levels."],
	"tapczan": ["The Tapczan",
			"Pub z piwem kraftowym na Sienkiewicza: szesnaście kranów, trzy poziomy i ogródek na paletach pod czarnymi parasolami. Tak, to parodia.",
			"A craft-beer pub on Sienkiewicza: sixteen taps, three floors and a pallet terrace under black umbrellas. Yes, a parody."],
	"sienkiewicza4": ["Sienkiewicza 4",
			"Secesyjna kamienica z zaokrąglonymi narożnikami, żelaznymi balkonami i ciemnymi fryzami z liśćmi. Na parterze pub, a stalowy daszek nad bramą.",
			"An Art Nouveau tenement with rounded corners, iron balconies and dark leafy friezes. A pub on the ground floor and a steel canopy over the gate."],
	"harczyk": ["Kamienica Harczyka",
			"Śnieżnobiała neobarokowa kamienica na rogu Jasnej: skośny narożnik z balkonami, mansarda z czerwonymi lukarnami i białymi szczytami.",
			"A brilliant-white neo-baroque corner tenement on Jasna: a chamfered corner stacked with balconies, a mansard with red-brick dormers and white gables."],
	"sienkiewicza3": ["Sienkiewicza 3",
			"Socrealistyczny blok z lat 50.: siatka piaskowych filarów, czerwonawe płyty, długi balkon nad arkadą i przejście na południe.",
			"A 1950s socialist-classicist block: a grid of sandstone piers, reddish panels, a long balcony over an arcade and a passage south."],
	"pijana": ["Pijana Czereśnia",
			"Ciemny ośmioboczny pawilon w parku, z beczkowatym bębnem na dachu. Nalewka z czereśni, drewniany taras i światełka. Tak, to parodia.",
			"A dark octagonal pavilion in the park with a barrel-like drum on its roof. Cherry liqueur, a timber deck and string lights. Yes, a parody."],
	"zodiak": ["Zodiak",
			"Pawilon w Pasażu Wiecha: dawny bar, dziś Warszawski Pawilon Architektury z kawiarnią.",
			"A pavilion in Pasaż Wiecha: once a bar, now the Warsaw Architecture Pavilion and its café."],
	"sowa": ["Sowa Club · City 25",
			"Szklany pawilon w Alejach, różowy neon od zmierzchu do świtu. CITY 25 grilluje 25 godzin na dobę, a SOWA CLUB jest dla nocnych sów.",
			"A glass pavilion on the Aleje, pink neon from dusk to dawn. CITY 25 grills 25 hours a day, and SOWA CLUB is for night owls."],
	"wiecha": ["Pasaż Wiecha",
			"Deptak za Domami Towarowymi Centrum, nazwany na cześć Stefana Wiecheckiego „Wiecha”. Pawilony z witrynami pod blokami.",
			"The walkway behind the Eastern Wall's stores, named after the writer Stefan Wiechecki, \"Wiech\". Shop pavilions under the slabs."],
	"niecala7": ["Rezydencja Opera · Niecała 7",
			"Luksusowa kamienica z 2005 roku tuż przy Ogrodzie Saskim: kremowy tynk na miodowym piaskowcu, okrągłe balkony na żelaznych wspornikach i pergola nad łukiem od strony ogrodu.",
			"A luxury block of 2005 beside the Saxon Garden: cream plaster on honey sandstone, round balconies on iron brackets and a pergola over the arc on the garden side."],
	"warsztat_mirka": ["Warsztat u Mirka",
			"Tuning, lakier i kawa z fusami. Na dachu stoi auto, bo „zrobi się”, a na podwórku czekają dwa wyścigowe i jedno na kołkach. Wjedź pod niebieski neon.",
			"Tuning, paint and coffee with grounds. There's a car on the roof because \"it'll get done\", and in the yard two racers and one on axle stands are waiting. Drive in under the blue neon."],
	"wiecha_swieta": ["Święta w Pasażu Wiecha",
			"Spadające gwiazdy na każdej latarni, piernikowy ludzik, przez którego się przechodzi, neonowa choinka i bombki, w których można usiąść. Do Trzech Króli.",
			"Shooting stars on every lamp mast, a gingerbread man you walk through, a neon fir and baubles you can sit in. Until Epiphany."],
	"ochota": ["Warszawa Ochota",
			"Dworzec z 1963 roku: szklana kasa na moście nad wykopem pod betonowym siodłem paraboloidy.",
			"A 1963 station: a glass ticket hall on a bridge over the cutting, under a concrete saddle roof."],
	"powisle": ["Warszawa Powiśle",
			"Stacja z 1963 roku: szklany pawilon pod skręconym dachem nad wylotem tunelu i okrągłe „UFO”, dziś bar z leżakami i wieczorami jazzu.",
			"A 1963 station: a glass pavilion under a twisted roof over the tunnel's mouth and a round \"UFO\", now a bar with deck chairs and jazz nights."],
	"srodmiescie": ["Warszawa Śródmieście",
			"Dwa szklane pawilony z 1963 roku nad schodami do podziemnej stacji linii średnicowej.",
			"Two 1963 glass pavilions over the stairs down to the cross-city line's underground station."],
	"wkd_srodmiescie": ["Warszawa Śródmieście WKD",
			"Końcówka kolejki WKD w wykopie przy Alejach: dwa betonowe śmigła nad schodami w dół.",
			"The WKD commuter line's terminus in a cutting by the Aleje: two concrete propellers over the stairs down."],
	"wkd_ochota": ["Warszawa Ochota WKD",
			"Przystanek kolejki WKD w wykopie przy placu Zawiszy: ciężki betonowy dach na nogach w kształcie litery V.",
			"The WKD stop in the cutting by Plac Zawiszy: a heavy concrete roof on V-shaped legs."],
	"stadion_pkp": ["Warszawa Stadion",
			"Przystanek z 1958 roku pod stadionem: biała hala z żaglem i perony w czerwono-białej mozaice.",
			"A 1958 stop by the stadium: a white hall with a sail and platforms in red-and-white mosaic."],
	"wschodnia": ["Warszawa Wschodnia",
			"Dworzec praski z 1969 roku, odnowiony na Euro 2012: przeszklona hala pod dachem z łamaną krawędzią na stalowych podporach V.",
			"Praga's station of 1969, refitted for Euro 2012: a glazed hall under a roof with a folded edge on V-shaped steel struts."],
	"barka_wieczor": ["Wieczorek nad Wisłą",
			"Barka-bar pod Starówką: przeszklony dół, taras na dachu, dwa bary i parasole.",
			"A bar barge below the Old Town: a glazed lower deck, a roof terrace, two bars."],
	"barka_biala": ["Biała Barka",
			"Biała barka przy kilometrze 512: food trucki na pokładzie, scena i lampki.",
			"The white barge at river km 512: food stalls on deck, a stage and fairy lights."],
	"barka_marina": ["Marinka Warszawka",
			"Barka w stylu marynarskim między Kopernikiem a kładką. Granat, biel, cień.",
			"A nautical barge between the Copernicus Centre and the footbridge: navy and white."],
	"port_majami": ["Majami Wawa",
			"Klub na cyplu Portu Czerniakowskiego: drewniany taras pod wierzbami, czerwony namiot, ogniska i biały ponton na Wiśle.",
			"The club on the tip of Port Czerniakowski: a timber deck under the willows, a red tent, fire pits and a white pontoon on the Vistula."],
	"monkey_love": ["Małpi Love",
			"Ogródek przy Bulwarze Flotylli Pińskiej, pod Mostem Łazienkowskim: drewniane domki, żółte drzwi, białe parasole i lampki pod drzewami.",
			"A garden on Bulwar Flotylli Pińskiej by Most Łazienkowski: timber cabins, a yellow door, white umbrellas and fairy lights under the trees."],
	"port_wtw": ["WTW · Warszawskie Towarzystwo Wioślarskie",
			"Klub wioślarski od 1878 roku, Zaruskiego 12: biały hangar z niebieskim dachem, kotwice przy bramie.",
			"A rowing club since 1878, Zaruskiego 12: a white boathouse under a blue roof, anchors at the gate."],
	"marina": ["Przystań w Porcie Czerniakowskim",
			"Port żeglarski przy Zaruskiego: klubowy domek, pomosty i jachty, które zimują tu od pokoleń.",
			"The sailing harbour by Zaruskiego street: a club house, finger piers and yachts that have wintered here for generations."],
	"bulwary_pawilony": ["Pawilony na bulwarach",
			"Betonowe pawilony wpuszczone w nabrzeże, z trawą na dachu. Latem bary, leżaki i kolejka po lemoniadę.",
			"Concrete pavilions set into the embankment, grass on their roofs. In summer: bars, deck chairs and a queue for lemonade."],
	"bulwary_bary": ["Kontenery na bulwarach",
			"Kontenery z okienkiem: piwo, lemoniada, zapiekanki. Leżak obok zawsze zajęty.",
			"Containers with a hatch: beer, lemonade, zapiekanki. The deck chair next to it is always taken."],
	"pawilon_tanca": ["Pawilon Tańca",
			"Biały pawilon nad bulwarem z napisem MUZEUM na dachu i cienkoliniowymi muralami; przy nim Palomka z białymi krzesłami.",
			"A white pavilion above the boulevard with MUZEUM on its roof and fine-line murals; Palomka's white chairs beside it."],
	"zachodni_brzezek": ["Zachodni Brzeżek",
			"Bar z wielkim tarasem przy Wioślarskiej: szary beton, białe litery, palmy w beczkach i lampiony nad Wisłą.",
			"A bar with a big terrace on Wioślarska: grey concrete, white letters, palms in barrels and bulbs above the Vistula."],
	"plyta_desantu": ["Płyta Desantu",
			"Piaszczysta plaża pod Mostem Poniatowskiego: trzy bary z leżakami, parasolami i pomostem prosto z desantu.",
			"The sandy beach under Most Poniatowskiego: three bars with deck chairs, parasols and a dock straight off the landing."],
	"barka_nowa_falka": ["Nowa Falka",
			"Długa czarna barka z piaskowym pokładem, białymi parasolami i stolikami przed Pawilonem Tańca.",
			"A long dark barge with a sand-coloured deck, white umbrellas and tables in front of the Dance Pavilion."],
	"barka_zanurzenie": ["Zanurzenie",
			"Barka pod płóciennym dachem: paletowe sofy, lampiony i kraftowe piwo kołyszące się przy trapie.",
			"A canopied barge: pallet sofas, lanterns and craft beer swaying by the gangplank."],
	"barka_wirek": ["Wirek",
			"Drewniana platforma na wodzie naprzeciw Schodków: leżaki, palety i industrialne lampy.",
			"A timber platform on the water facing the Steps: deck chairs, pallets and industrial lamps."],
	"barka_kalmar": ["Kalmar",
			"Pływająca plaża obok Dworca Wodnego: piasek pod stopami, leżaki i bar z białego muru.",
			"A floating beach next to Dworzec Wodny: sand underfoot, loungers and a whitewashed bar."],
	"barka_barkas": ["Barkas",
			"Biała barka z płaskim dachem i dwiema scenami; latem koncerty i kino pod gołym niebem.",
			"A white flat-topped barge with two stages; free concerts and open-air cinema in summer."],
	"barka_kaskada": ["Kaskadka",
			"Długa czarna barka koncertowa: industrial, minimalizm i bas słyszalny na Pradze.",
			"A long black concert barge: industrial, minimal, and bass you can hear in Praga."],
	"pawilony": ["Pawilony",
			"Labirynt barów wielkości kiosku za bramą przy Nowym Świecie.",
			"A maze of kiosk-sized bars behind a gate on Nowy Świat."],
	"ostrogski": ["Zamek Ostrogskich",
			"Pałac nad skarpą na Tamce; w nim Muzeum Fryderyka Chopina.",
			"A palace on the Tamka escarpment, home of the Fryderyk Chopin Museum."],
	"mdm": ["MDM",
			"Marszałkowska Dzielnica Mieszkaniowa, socrealizm z lat 1950–1952.",
			"The socialist-realist housing district of 1950–1952."],
	"church_sw_marcin": ["Kościół św. Marcina", "Kościół przy Piwnej na Starym Mieście.", "A church on Piwna, in the Old Town."],
	"church_kapucyni": ["Kościół Kapucynów", "Barokowy kościół Przemienienia Pańskiego na Miodowej.", "The baroque Church of the Transfiguration on Miodowa."],
	"church_niepokalanego": ["Kościół Niepokalanego Poczęcia NMP", "Mały klasycystyczny kościół Res Sacra Miser przy Krakowskim Przedmieściu.", "The small classicist Res Sacra Miser church on Krakowskie Przedmieście."],
	"church_katedra_polowa": ["Katedra Polowa Wojska Polskiego", "Barokowy kościół dawnych pijarów, dziś katedra wojskowa.", "A baroque former Piarist church, now the army's cathedral."],
	"church_duch": ["Kościół Świętego Ducha", "Barokowy kościół paulinów na Nowym Mieście.", "A baroque Pauline church in the New Town."],
	"church_jacek": ["Kościół św. Jacka", "Kościół dominikanów na Nowym Mieście.", "The Dominicans' church in the New Town."],
	"church_antoniego": ["Kościół św. Antoniego Padewskiego", "Kościół franciszkanów na Senatorskiej.", "The Franciscans' church on Senatorska."],
	"church_alberta": ["Kościół św. Brata Alberta i św. Andrzeja", "Kościół środowisk twórczych przy placu Teatralnym.", "The artists' church on Theatre Square."],
	"church_reformowany": ["Kościół Ewangelicko-Reformowany", "Neogotycki kościół z ażurową iglicą.", "A neo-Gothic church with an openwork spire."],
	"church_jerozolimska": ["Kościół Matki Bożej Jerozolimskiej", "Ceglany kościół z portykiem naprzeciw stadionu.", "A brick church with a portico across from the stadium."],
	"church_zielonoswiatkowy": ["Kościół Zielonoświątkowy", "Zbór zielonoświątkowy.", "A Pentecostal church."],
	"church_dzieciatka": ["Kościół Dzieciątka Jezus", "Kościół parafialny z wysoką wieżą.", "A parish church with a tall tower."],
	"church_narodzenia": ["Kościół Narodzenia NMP na Lesznie", "Barokowy kościół z wieżyczką zegarową.", "A Baroque church with a clock turret."],
	"church_karol": ["Kościół św. Karola Boromeusza", "Klasycystyczna bazylika przy Chłodnej.", "The classical basilica on Chłodna Street."],
	"church_augustyn": ["Kościół św. Augustyna", "Ceglana bazylika z wieżą na 70 metrów.", "A brick basilica with a 70-metre tower."],
	"church_miloserdzie": ["Kościół Miłosierdzia Bożego", "Kościół parafialny.", "A parish church."],
	"church_piotr_pawel": ["Kościół Świętych Piotra i Pawła", "Kościół parafialny z cegły.", "A brick parish church."],
	"church_trojca_praga": ["Kościół Świętej Trójcy na Solcu", "Klasycystyczny kościół z wieżyczką.", "A classicist church with a bell turret."],
	"church_czestochowska": ["Kościół Matki Bożej Częstochowskiej", "Modernistyczny kościół z dachem do ziemi.", "A modernist church with a roof down to the ground."],
	"church_zwycieska": ["Kościół Matki Boskiej Zwycięskiej", "Kościół parafialny z dwiema wieżami.", "A parish church with two towers."],
	"church_siostry_milosierdzia_zytnia": ["Siostry Matki Bożej Miłosierdzia", "Dom sióstr przy sanktuarium św. Faustyny na Żytniej.", "The Sisters of Our Lady of Mercy's house by St Faustina's shrine."],
	"church_uczennice_boskiego_mistrza": ["Siostry Uczennice Boskiego Mistrza", "Ceglany dom zakonny sióstr uczennic przy Żytniej.", "The Sister Disciples of the Divine Master's brick convent."],
	"church_kaplica_hoza": ["Kaplica przy Hożej", "Długa kaplica w podwórzu za domem przy Hożej.", "A long chapel in the yard behind a house on Hoża."],
	"church_kaplica_lucka": ["Kaplica przy Łuckiej", "Mała kaplica w podwórzu za domami przy Łuckiej.", "A small chapel in the yard behind the houses on Łucka."],
	"church_kaplica_florianska": ["Kaplica przy katedrze św. Floriana", "Ośmioboczna ceglana kaplica z łupkowym hełmem, przy ogrodzeniu katedry.", "A small octagonal brick chapel with a slate bell roof, by the cathedral's fence."],
	"church_zytnia_dom_zakonny_tyl": ["Dom zakonny na Żytniej, skrzydło", "Długie skrzydło domu zakonnego w głębi posesji przy Żytniej.", "The long wing of the convent behind its range on Żytnia."],
	"church_zytnia_dom_zakonny": ["Dom zakonny na Żytniej", "Dom zakonny po południowej stronie Żytniej, przy Wolności.", "The convent range on the south side of Żytnia, by Wolność."],
	"church_zwycieska_klasztor": ["Klasztor przy Matce Bożej Zwycięskiej", "Dom zakonny obok kościoła Matki Bożej Zwycięskiej na Kamionku.", "The religious house beside Our Lady of Victory in Kamionek."],
	"church_klopotowskiego_18": ["Okno Życia na Kłopotowskiego", "Dom kościelny z oknem życia przy Kłopotowskiego 18.", "A church house with a window of life on Kłopotowskiego."],
	"church_plebania_florian": ["Plebania katedry św. Floriana", "Plebania praskiej katedry przy Floriańskiej.", "The presbytery of Praga's cathedral on Floriańska."],
	"church_sluzki_dom_generalny": ["Dom Generalny Sióstr Sług Jezusa", "Dom generalny Zgromadzenia Sióstr Sług Jezusa na Sewerynowie.", "The generalate of the Servants of Jesus sisters."],
	"church_plebania_augustyn": ["Plebania św. Augustyna", "Plebania parafii św. Augustyna na Nowolipkach.", "St Augustine's presbytery on Nowolipki."],
	"church_plebania_katedra_polowa": ["Plebania Katedry Polowej", "Plebania katedry wojskowej przy Długiej.", "The Field Cathedral's presbytery on Długa."],
	"church_reformaci_klasztor": ["Klasztor Reformatów", "Klasztor franciszkanów reformatów przy kościele św. Antoniego.", "The Reformati Franciscans' friary beside St Anthony's."],
	"church_wizytki_klasztor": ["Klasztor Wizytek", "Klasztor sióstr wizytek za ich kościołem.", "The Visitation sisters' convent behind their church."],
	"church_sala_faustyny": ["Sala św. Faustyny", "Ceglana sala parafii św. Jakuba na Ochocie.", "The brick parish hall of St James', Ochota."],
	"church_franciszkanki_piwna": ["Siostry na Piwnej", "Dom sióstr franciszkanek przy kościele św. Marcina.", "The Franciscan sisters' house by St Martin's."],
	"church_kapucyni_klasztor": ["Klasztor Kapucynów", "Klasztor ojców kapucynów przy Miodowej.", "The Capuchin friars' monastery on Miodowa."],
	"church_misjonarze_radna": ["Misjonarze na Radnej", "Dom misjonarzy z kaplicą Cudownego Medalika.", "The Missionaries' house with the Miraculous Medal chapel."],
	"church_misjonarze": ["Dom Księży Misjonarzy", "Dom misjonarzy przy kościele Świętego Krzyża.", "The Missionaries' house by the Holy Cross church."],
	"church_barbara": ["Kaplica św. Barbary", "Ceglana kaplica na Koszykach.", "The brick chapel on Koszyki."],
	"church_baptysci": ["Kościół Baptystów", "Zbór baptystów przy Walicowie.", "The Baptist church on Waliców."],
	"church_chrystusa_krola": ["Kościół Chrystusa Króla Pokoju", "Kościół pallotynów i kaplica MB Częstochowskiej.", "The Pallottines' church and the Częstochowa chapel."],
	"church_pallotyni": ["Dom pallotynów", "Modernistyczny dom pallotynów przy Skaryszewskiej.", "The Pallottines' modernist house on Skaryszewska."],
	"church_rodziny_maryi": ["Siostry Rodziny Maryi", "Dom zgromadzenia sióstr franciszkanek Rodziny Maryi.", "The house of the Franciscan Sisters of the Family of Mary."],
	"church_dominikanie": ["Klasztor Dominikanów", "Klasztor dominikanów przy kościele św. Jacka.", "The Dominican priory beside St Hyacinth's."],
	"church_bazylianie": ["Klasztor Bazylianów", "Klasztor bazylianów z frontem cerkwi przy Miodowej.", "The Basilian monastery with the church's front on Miodowa."],
	"church_cerkiew": ["Cerkiew Zaśnięcia Matki Bożej", "Greckokatolicka cerkiew bazylianów przy Miodowej.", "The Basilians' Greek Catholic church on Miodowa."],
	"church_nozykow": ["Synagoga Nożyków", "Jedyna przedwojenna synagoga Warszawy, przy Twardej.", "Warsaw's only pre-war synagogue, on Twarda."],
}

## Courtyards (F, 2026-11-03: "some kamienica from the top have the hole in the center"): the
## sites whose model lifts a mapped outline that OpenStreetMap draws round real courts (bake_osm
## keeps only a multipolygon's outer ring), so their roofs came out solid. The courts are the
## LoD2 roofs' (tools/bake_courts.py, game/data/courts.json).
const COURT_SITES := ["mf", "muzeum", "bristol"]  # the Palace has its own (P_COURTS)
const COURTS_PATH := "res://data/courts.json"

## What the game shows when a landmark is tapped: [{key, name, pl, en, centre}], in id order.
var info: Array[Dictionary] = []


func _init(builder, map_data: Dictionary) -> void:
	map = builder
	data = map_data
	_find_sites()
	_find_courts()
	# Loop 3c: the info cards (and so the picking ids) for every site up front, in site order,
	# so a sector built alone gives its landmarks the same ids as the whole city.
	for s in sites:
		if s.has("block") or s.has("quiet"):
			continue  # street blocks and gardens come last and are no landmarks: no card, no map icon
		var card: Array = INFO.get(s["key"], [s["key"], "", ""])
		info.append({"key": s["key"], "name": card[0], "pl": card[1], "en": card[2],
				"centre": (s["box"] as Rect2).get_center(), "box": s["box"]})


## True when a LoD2 building or an OpenStreetMap outline centred at p is replaced.
func replaces(p: Vector2) -> bool:
	for s in sites:
		if s.has("skin") or not (s["box"] as Rect2).has_point(p):
			continue
		var inside := false
		for z: PackedVector2Array in s["zone"]:
			if Geometry2D.is_point_in_polygon(p, z):
				inside = true
				break
		if not inside:
			continue
		for k: PackedVector2Array in s["keep"]:
			if Geometry2D.is_point_in_polygon(p, k):
				inside = false
				break
		if inside:
			return true
	return false


## A modelled block that keeps LoD2's measured roof over its own walls.
func keeps_lod2_roof(p: Vector2) -> bool:
	for s in sites:
		if s.has("lod2_roof") and (s["box"] as Rect2).has_point(p):
			for z: PackedVector2Array in s["zone"]:
				if Geometry2D.is_point_in_polygon(p, z):
					return true
	return false


## The walls a kept LoD2 roof meets, for the modelled block that keeps it at p (as
## keeps_lod2_roof): {"ring": the block's outline, "eaves": one absolute wall-top height per
## outline edge (NAN where no wall of the model runs along it)}, or empty. From index.json's
## `eaves` (tools/block_eaves.py) over the block's own ground (_build_block's `_g`), so
## map_builder can lift a roof that sat a storey down inside its walls (F's shot, 2026-11-19).
func block_eaves_at(p: Vector2) -> Dictionary:
	for s in sites:
		if not s.has("lod2_roof") or not s.has("eaves") or not (s["box"] as Rect2).has_point(p):
			continue
		for z: PackedVector2Array in s["zone"]:
			if Geometry2D.is_point_in_polygon(p, z):
				var g := _ground_under(s["raw"])
				var tops := PackedFloat32Array()
				for e in s["eaves"]:
					tops.append(g + float(e) if e != null else NAN)
				return {"ring": s["raw"], "eaves": tops}
	return {}


## The skin of the kept skin (SKINS) `key`, the same Dictionary `skin_at` returns for its
## buildings (compare with is_same: two skins can share their colours), or empty. The turntable
## (`--solo=KEY`, tools/site_cams.gd) uses it to show a recoloured LoD2 building alone.
func skin_of(key: String) -> Dictionary:
	for s in sites:
		if s["key"] == key and s.has("skin"):
			return s["skin"]
	return {}


## The landmarks loop: how a kept building whose plan spans `box` is drawn instead of its own
## look (Muzeum Narodowe's stone): {"mode", "wall", "roof"}, or empty. A building counts when
## its centre is inside the site's outline, or its whole box inside the outline's box (the
## museum's LoD2 model is one run round its courtyards: its centre is in one).
func skin_at(box: Rect2) -> Dictionary:
	var p := box.get_center()
	for s in sites:
		if not s.has("skin") or not (s["box"] as Rect2).has_point(p):
			continue
		# One outline round courtyards (the museum): anything in its box. A site of many
		# blocks (MDM): only what has its centre in one of them.
		if s["zone"].size() == 1 and (s["box"] as Rect2).encloses(box):
			return s["skin"]
		for z: PackedVector2Array in s["zone"]:
			if Geometry2D.is_point_in_polygon(p, z):
				return s["skin"]
	return {}


## The landmarks loop: a tower's glass (or a low-rise landmark's wall) for the far skyline
## (sector_proxies.gd).
static func tower_colour(key: String, fallback: Color) -> Color:
	for t: Dictionary in TOWERS:
		if t["key"] == key:
			return Color(t["glass"])
	for t: Dictionary in SKINS:
		if t["key"] == key:
			return Color(t["wall"])
	# Plac Piłsudskiego, part 2: the square's models and skins.
	if PLAC_WALLS.has(key):
		return Color(PLAC_WALLS[key])
	if MALACHOWSKI_WALLS.has(key):
		return Color(MALACHOWSKI_WALLS[key])
	if key == "gbc":
		return GBC_GLASS
	if key == "prosta32":
		return P32_GLASS
	if key == "prosta28":
		return P28_GLASS
	if key == "lucka":
		return LUCKA_WHITE
	if key == "buw":
		return BUW_GLASS
	if key == "kopernik":
		return KOP_WALL
	if key == "mf":
		return MF_WALL
	if key == "pasta":
		return PASTA_WALL
	if key == "barbakan":
		return BARB_WALL
	if key == "teresy":
		return TERESY_BRICK
	if key == "flisac":
		return FLISAC_STONE
	if key == "ateneum":
		return ATE_WALL
	if key == "lipowa1a":
		return L1A_WHITE
	if key == "vitkac":
		return VITKAC_WALL
	if key == "dom_partii":
		return DOM_STONE
	if key == "ns4a":
		return NS4A_GLASS
	if key == "eon41":
		return EON_STONE
	if key == "asp37":
		return ASP_PLASTER
	if key == "jablkowscy":
		return JAB_WALL
	if key == "sheraton":
		return SHER_WHITE
	if key == "bgk":
		return BGK_STONE
	if key == "ufficio_primo":
		return UP_STONE
	if key == "mlotek":
		return ML_WALL
	if key == "kozia9":
		return KZ_WALL
	if key == "smolna38":
		return S38_CREAM
	if key == "cparking":
		return CP_RED
	if key == "karowa18a":
		return KR_TAN
	if key == "florian":
		return FL_BRICK
	if key == "mpw":
		return MPW_BRICK
	return fallback


## The court walls' colour: the model's own wall stone.
func _court_wall_colour(key: String) -> Color:
	match key:
		"muzeum":
			return MUZEUM_STONE
	return tower_colour(key, Color("#d9d2c4"))


## Whether an OpenStreetMap building of the bake should still be drawn.
func keeps_building(bld: Dictionary) -> bool:
	var poly := _pts(bld["p"])
	if poly.size() < 3:
		return true
	return not replaces(_centre(poly))


## Courtyards (F, 2026-11-03): each COURT_SITES site gets the courts of game/data/courts.json
## (tools/bake_courts.py: closed-in ground with no LoD2 roof over it) whose middle lies in its
## zone, as `courts`; build() cuts them out of its flat tops and walls them in.
func _find_courts() -> void:
	if not FileAccess.file_exists(COURTS_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(COURTS_PATH))
	if not parsed is Dictionary:
		return
	var rings: Array[PackedVector2Array] = []
	for flat: Array in parsed.get("courts", []):
		rings.append(_pts(flat))
	for s in sites:
		if not COURT_SITES.has(s["key"]):
			continue
		var mine: Array[PackedVector2Array] = []
		for r in rings:
			var c := _centre(r)
			if not (s["box"] as Rect2).has_point(c):
				continue
			for z: PackedVector2Array in s["zone"]:
				if Geometry2D.is_point_in_polygon(c, z):
					mine.append(r)
					break
		if not mine.is_empty():
			s["courts"] = mine


## The zones each landmark replaces, from the map data.
func _find_sites() -> void:
	var palace := _landmark("Pałac Kultury i Nauki")
	if palace.size() >= 3:
		_add_site("palace", [palace])
		# The glb's triangles read here, on the main thread, for every build of the Palace's
		# sector after, the streamer's worker's too (centre.gd `palace_glb_surfaces`).
		warm_palace_glb()
	# Złote Tarasy (spec docs/landmarks/specs/tarasy.md, 2026-10-31): the whole complex inside
	# its outline is the landmark, built from its mapped parts. The glass wave is mapped as
	# eight glass domes over the mall; the rest is the terraced mall, Lumen and Skylight.
	var tarasy := _landmark("Złote Tarasy")
	if tarasy.size() >= 3:
		var parts := _parts_in(tarasy, func(b: Dictionary) -> bool:
				return float(b["h"]) > float(b["mh"]) and not b.get("br", false))
		var domes: Array[Dictionary] = []
		for b in parts:
			if _tarasy_dome(b):
				domes.append(b)
		_add_site("tarasy", [tarasy])
		if not sites.is_empty() and sites[-1]["key"] == "tarasy":
			sites[-1]["domes"] = domes
			sites[-1]["parts"] = parts
	var rotunda := _landmark("Rotunda PKO")
	if rotunda.size() >= 3:
		_add_site("rotunda", [rotunda])
	var varso := _landmark("Varso Tower")
	if varso.size() >= 3:
		_add_site("varso", [varso])
	_find_varso_place()
	_find_stadium()
	_find_legia()
	_find_centralna()
	_find_towers()
	# Most Poniatowskiego's towers over the railway at Warszawa Powiśle (F, 2026-11-13).
	_find_powisle_towers()
	# The landmarks loop: the skyline's towers, then Muzeum Narodowe.
	for t: Dictionary in TOWERS:
		var outline := _landmark(t["osm"]) if t.has("osm") else _tallest_at(t["at"])
		if outline.size() >= 3:
			var zone: Array = [outline]
			for at: Vector2 in t.get("with", []):
				zone.append(_tallest_at(at))  # a tower's low wings, built with it (the Spire's)
			if t.get("babka", false) and zone.size() > 1:
				# Babka's block is a U round a courtyard: its centre is in the yard, so its hull
				# is what takes it off the map's own buildings.
				zone.append(Geometry2D.convex_hull(zone[1]))
			_add_site(t["key"], zone)
			if not sites.is_empty() and sites[-1]["key"] == t["key"]:
				sites[-1]["tower"] = t
				if t.has("terraces"):
					sites[-1]["terraces"] = _find_terraces(t["terraces"])
	_find_muzeum()
	_find_mdm()
	_find_skins()
	# The Institute next to St Anne's (F, 2026-11-26): a model instead of a street block.
	_find_nikidw()
	# The buttressed house by the oak (F, 2026-11-26): a model instead of a street block.
	_find_mansjonaria()
	# Before the column: a later site's tap cells win, and the column's must (check_landmarks).
	_find_zamkowy()
	_find_prymasowski()
	_find_jablonowskich()
	_find_zygmunt()
	_find_gaulle()
	_find_rondo()
	_find_sunken()
	_find_deski()
	_find_dom_partii()
	_find_ns4a()
	_find_eon41()
	_find_asp37()
	_find_rynek()
	_find_arkadia()
	_find_forest()
	_find_prosta32()
	_find_prosta28()
	_find_lucka()
	_find_towarowa22()
	# F's photos (2026-11-07): the Kolejowa estate, Asbud's towers, the drug works' building site.
	_find_dzielnica19()
	_find_stacja_muzeum()
	_find_kolejowa()
	_find_gbc()
	_find_bridge()
	_find_flag()
	_find_swieto()
	_find_kladka()
	# Teatr Ateneum and Lipowa 1A (F, 2026-11-20).
	_find_ateneum()
	_find_lipowa1a()
	# Karowa's serpentine (F, 2026-11-20): Wiadukt Markiewicza and the memorial to "Szaya".
	_find_markiewicz()
	_find_szaja()
	# The museum and Plac Piłsudskiego loop (2026-10-31): the square's edges.
	_find_plac()
	_find_pawilony()
	# G3 (gaulle-and-food-hype.md): LORETKA, the date bar on HOTEL PIURE's roof, in pink, like
	# METROPOLKA: a 0.2 m zone at the roof's south-east corner keeps the hotel the map's.
	var piure := _landmark("Puro Warszawa Centrum")
	if piure.size() >= 3:
		var pe := _box_of([piure]).end
		_add_site("loretka", [PackedVector2Array([pe, pe + Vector2(0.2, 0), pe + Vector2(0.2, 0.2), pe + Vector2(0, 0.2)])])
	# Level 26 (F, 2026-11-01): the rooftop club on the Atlas Tower, Al. Jerozolimskie 123A. The tower
	# stays the map's own; a 0.2 m zone at its bounding box's corner makes it a site.
	var atlas := _landmark("Atlas Tower")
	if atlas.size() >= 3:
		var ae := _box_of([atlas]).end
		_add_site("level26_club", [PackedVector2Array([ae, ae + Vector2(0.2, 0), ae + Vector2(0.2, 0.2), ae + Vector2(0, 0.2)])])
	var metropol := _landmark("Hotel Metropol")
	if metropol.size() >= 3:
		# The hotel is rebuilt whole (_build_metropol_sign, F's photos 2026-11-07): the zone is its outline.
		# The zone is the outline's convex hull: the slab's own centre falls in its courtyard notch.
		var hull := Geometry2D.convex_hull(metropol)
		_add_site("metropolsign", [hull])
		sites[-1]["outline"] = metropol
		sites[-1]["hull"] = hull
	# First scene item 1 (2026-10-31): the Museum of Modern Art on Plac Defilad.
	_find_msn()
	_find_tr()
	_find_nozyce()
	_find_jarmark()
	_find_obeliski()
	# First scene item 3 (2026-10-31): the Eastern Wall's three glass department stores.
	_find_dtc()
	# The Mac photo check (2026-11-01, specs C and D): the tower and the slabs behind the stores.
	_find_behind()
	# Osiedle Za Żelazną Bramą (2026-11-01): the eleven blocks between Żelazna and Jana Pawła II.
	_find_zelazna()
	# Generation Park X and Z (Rondo Daszyńskiego): the two stone-grid office blocks framing Y.
	_find_gpxz()
	# Pokorna 2 (F, 2026-11-01): the 57 m residential block by Muranów, a model with balconies.
	_find_pokorna2()
	# I Oddział PKO (F's photo, 2026-11-09): the first branch on Marszałkowska, rebuilt as one block.
	_find_pko_branch()
	_find_dekalog_estate()
	_find_inflancka_pools()
	# Kino Muranów (F's photos, 2026-11-07): the cinema pavilion, its terrace, the arch, the fountain.
	_find_kino_muranow()
	# R5 of docs/design/start-area-real.md: the Cepelia pavilion and Zodiak.
	_find_modern_pavilions()
	# F's photos (2026-11-08): the cherry-liqueur kiosk in the park by Emilii Plater, as a parody.
	_find_pijana()
	# F's photos (2026-11-24): THE TAPCZAN, the craft-beer pub on Sienkiewicza 4 and its terrace.
	_find_tapczan()
	# F (2026-11-24): the three houses round THE TAPCZAN: no. 4 itself, Harczyk's corner and the block opposite.
	_find_sienkiewicza4()
	_find_harczyk()
	_find_sienkiewicza3()
	# First scene items 4-5 (2026-11-02, the Mac photo report dt_pawilony): Pasaż Wiecha's pavilions.
	_find_wiecha()
	# F's photos and the opening night's Instagram (2026-11-22): the pasaż's Christmas lights.
	_find_wiecha_swieta()
	# F's photos (2026-11-06): SOWA CLUB and CITY 25, the neon glass pavilion on Al. Jerozolimskie.
	_find_sowa()
	# Skwer Linearny na Złotej (F's photo, 2026-11-02): Dom pod Orłami over the new square.
	_find_orly()
	# City inventory item 4 (2026-11-02, Mac photos refs/hotel_warszawa, refs/cedet): Hotel Warszawa
	# (the 1933 Prudential) on Plac Powstańców and Cedet on Al. Jerozolimskie at Krucza.
	_find_hotel_warszawa()
	_find_cedet()
	# Muranów (2026-11-02, spec polin.md): POLIN and the Ghetto Heroes Monument before it.
	_find_polin()
	# The monuments pass, part 2 (2026-11-02): seven monuments from the Mac's photo reports.
	_find_monuments()
	# The railway (docs/design/railway.md, S1): Warszawa Ochota's hall and its saddle roof.
	_find_ochota()
	# S2: Warszawa Powiśle's two pavilions and the platform canopies.
	_find_powisle()
	_find_stadion_pkp()
	# S3e (2026-11-03, the Mac photo report wschodnia): Warszawa Wschodnia's hall and platform roofs.
	_find_wschodnia()
	# The river's bar barges and houseboats (2026-11-01, spec docs/landmarks/specs/barki.md).
	_find_barges()
	_find_marina()
	# Port Czerniakowski's spit and basin (F, 2026-11-07, his photos: port-czerniakowski).
	_find_port()
	_find_monkey()
	# The boulevards' dressing (2026-11-02, spec docs/landmarks/specs/bulwary.md).
	_find_bulwar_dress()
	_find_bulwary_pool()
	# Schodki nad Wisłą (2026-11-19, spec docs/landmarks/specs/schodki_wisla.md): the seating steps' band.
	_find_schodki_wisla()
	# The boulevards, phase C (2026-11-19): the dance pavilion with Palomka, the bar barges.
	_find_pawilon_tanca()
	_find_zachodni_brzezek()
	_find_bbc_barges()
	_find_plyta_desantu()
	_find_srodmiescie()
	# The railway S3c-e (2026-11-02): the WKD stops, from the Mac photo gather.
	_find_wkd()
	# Plac Małachowskiego and the Presidential Palace (2026-10-31): models instead of skins.
	_find_trojca()
	_find_zacheta()
	_find_mirowska()
	_find_gwardii()
	_find_prezydencki()
	# St Alexander's church (2026-11-01): a model instead of a skin.
	_find_aleksander()
	# The Barbican (2026-11-02): a model instead of a skin.
	_find_barbakan()
	_find_arkady()
	# Powiśle's new flats (2026-11-02): Piano House and Cube House, models from their outlines.
	_find_piano_house()
	_find_cube_house()
	# Powiśle (2026-11-02): Hortus on Topiel and Moderna on Zajęcza, models from their outlines.
	_find_hortus()
	_find_moderna()
	_find_flisac()
	# Al. Jerozolimskie 57-63 (F's photos, 2026-11-15): Nowa Jerozolima's red tenement and the row beside it.
	_find_jerozolimskie57()
	# Plac Krasińskich (CITY_INVENTORY 22 and 79, 2026-11-02): the Uprising Monument and the palace.
	# Sąd Najwyższy's colonnade (2026-11-02): green ribbed columns instead of OSM's white boxes.
	# Found (and built) before the monument: its beams' cells would cover the monument's tap.
	_find_sad_najwyzszy()
	_find_pomnik_powstania()
	_find_krasinski()
	# Bracka and Plac Trzech Krzyży (CITY_INVENTORY 80-82, 2026-11-03): Vitkac, Jabłkowski's, the Sheraton.
	_find_bracka()
	# The BGK building next to Vitkac (F, 2026-11-03), from the Mac photo gather.
	_find_bgk()
	# Ufficio Primo, Wspólna 62 (spec 2026-11-26): the whole stone cube from its four corners.
	_find_ufficio_primo()
	# Foksal 13 and 15 (F's photos, 2026-11-05): the two restored tenements' street fronts.
	_find_foksal()
	# Warsaw modernism (F, 2026-11-03), from the Mac photo gathers.
	_find_mlotek()
	_find_kozia9()
	_find_karowa18a()
	# Smolna 38 (F's photos, 2026-11-08): the tenement with the club gate.
	_find_smolna38()
	# Nowogrodzka 31 and its rooftop billboard (F's four photos, 2026-11-07).
	_find_nowogrodzka31()
	_find_marszalkowska99()
	# The car park behind the Novotel (F's photos, 2026-11-07).
	_find_cparking()
	# Plac Zbawiciela (Marszałkowska street by street, 2026-11-01): the basilica, a model.
	_find_zbawiciela()
	# Plac Zbawiciela's colonnades and its MDM frontage (F's photos, 2026-11-13).
	_find_zbawiciela_plac()
	# F's ask (2026-11-01): every church designed by the same rules (the church kit).
	_find_churches()
	# The University Library (2026-10-31): a model instead of a skin.
	_find_buw()
	# The Copernicus Science Centre and its planetarium (2026-11-01): a model instead of a skin.
	_find_kopernik()
	_find_krakowskie()
	_find_mariensztat()
	# F's ask (2026-11-01): the Old Town hotels, as fronts on the tenements.
	_find_hotels()
	_find_ujazdowski()
	_find_polskie_radio()
	_find_dom_poselski()
	_find_stary_dom_poselski()
	_find_rembielinskiego()
	_find_willa_raua()
	_find_dziewulskich()
	_find_pod_karczochem()
	# F's ask (2026-11-01): Norblin, Browary Warszawskie, Hala Koszyki, Elektrownia Powiśle.
	_find_works()
	# F's ask (2026-11-02, CITY_INVENTORY #21): the Warsaw Rising Museum, from the Mac's photos.
	_find_mpw()
	# The Ministry of Finance (2026-11-01): a model instead of the mapped box.
	_find_mf()
	# Świętokrzyska's big three (2026-11-03, the Mac photo reports): PAST-a, a model instead of
	# the mapped block (Poczta Główna is a kept skin, SKINS).
	_find_pasta()
	# Powiśle, street by street (2026-11-01): Ostrogski Castle and the Chopin Institute, Tamka 41.
	_find_ostrogski()
	# The Powiśle parish church (2026-11-01): a model instead of the mapped box.
	_find_teresy()
	# The Powiśle boulevards (2026-11-01): the riverside Syrenka, the water station, the Kaskada.
	_find_bulwary()
	# Praga (2026-11-02, the Mac's photo reports): St Florian's cathedral and Bazar Różyckiego.
	_find_florian()
	_find_bazar()
	_find_centrum_praha()
	_find_targowa33a()
	_find_port_praski()
	_find_kosciuszkowcy()
	# Stacja Filtrów (F, 2026-11-06): the water tower and Starynkiewicz's bust.
	_add_site("filtry", [_circle(FT_C, FT_R + 1.0, 28)])
	if not sites.is_empty() and sites[-1]["key"] == "filtry":
		sites[-1]["raw"] = _circle(FT_C, FT_R, 16)
		sites[-1]["ring"] = sites[-1]["raw"]
	# Kamienica Pod Gigantami (F, 2026-11-06): LoD2's mass in its stone, the front is ours.
	_add_site("gigantami", [_pts(GG_OUTLINE)])
	if not sites.is_empty() and sites[-1]["key"] == "gigantami":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": GG_STONE, "roof": Color("#6c6a66")}
	# Szpitalna 5 (F's photos, 2026-11-06): LoD2's mass in its plaster, both street fronts are ours.
	_add_site("szpitalna5", [_pts(SZ_OUTLINE)])
	if not sites.is_empty() and sites[-1]["key"] == "szpitalna5":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": SZ_WALL, "roof": Color("#6c6a66")}
	# Kamienica Wedla (F's photos, 2026-11-06): LoD2's mass, both fronts and the corner are ours.
	_add_site("wedel", [_pts(WD_OUTLINE)])
	if not sites.is_empty() and sites[-1]["key"] == "wedel":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": WD_WHITE, "roof": WD_ZINC}
	# Kamienica Ławrynowicza (F's photos, 2026-11-06): LoD2's mass in its brick, the front is ours.
	_add_site("lawrynowicz", [_pts(LW_OUTLINE)])
	if not sites.is_empty() and sites[-1]["key"] == "lawrynowicz":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": LW_BRICK, "roof": Color("#6c6a66")}
	# The Sisters of Charity on Tamka (F's photos, 2026-11-15): LoD2's mass in white plaster and green
	# copper, the turret is ours. Sites with a card stay before the quiet ones below: the cards
	# (`info`) skip quiet sites, so a carded site after one gets another site's picking id.
	var szt := _outline_at(SZT_AT)
	if szt.size() >= 3:
		_add_site("szarytki", [szt])
		if not sites.is_empty() and sites[-1]["key"] == "szarytki":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": SZT_WALL, "roof": SZT_ROOF, "steep": 0.3}
	# The Adventist church on Foksal 8 (F's photos, 2026-11-15): LoD2's mass in its yellow plaster, the
	# gate, the balconies and the name band are ours.
	var adw := _outline_at(ADW_AT)
	if adw.size() >= 3:
		_add_site("adwentysci", [adw])
		if not sites.is_empty() and sites[-1]["key"] == "adwentysci":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": ADW_WALL, "roof": ADW_ROOF}
	# The Elizabethan sisters' provincial house behind Piekarska (LoD2 only, no photo, 2026-11-15):
	# LoD2's mass in default Old Town plaster and tiles; the rounded east end is ours.
	var elz := _outline_at(ELZ_AT)
	if elz.size() >= 3:
		_add_site("elzbietanki", [elz])
		if not sites.is_empty() and sites[-1]["key"] == "elzbietanki":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": ELZ_WALL, "roof": ELZ_ROOF}
	# The rest of St Faustina's convent on Żytnia (2026-11-15): LoD2's mass of three buildings in the
	# shrine's white plaster and grey roofs.
	var fkl: Array = []
	for at: Vector2 in FKL_AT:
		fkl.append(_outline_at(at))
	_add_site("faustyna_klasztor", fkl)
	if not sites.is_empty() and sites[-1]["key"] == "faustyna_klasztor":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": FKL_WALL, "roof": FKL_ROOF}
	# The Sisters of Charity's two houses by Zaułek Ku Szarytkom (LoD2 only, no photo, 2026-11-15):
	# LoD2's mass in the convent's white plaster and green copper. Provisional.
	var szz: Array = []
	for at: Vector2 in SZZ_AT:
		szz.append(_outline_at(at))
	_add_site("szarytki_zaulek", szz)
	if not sites.is_empty() and sites[-1]["key"] == "szarytki_zaulek":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": SZT_WALL, "roof": SZT_ROOF, "steep": 0.3}
	# St Barbara's parish house on Świętej Barbary (2026-11-15): LoD2's mass in its yellow plaster.
	var dpb := _outline_at(DPB_AT)
	if dpb.size() >= 3:
		_add_site("dom_parafialny_barbara", [dpb])
		if not sites.is_empty() and sites[-1]["key"] == "dom_parafialny_barbara":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": DPB_WALL, "roof": DPB_ROOF}
	# The presbytery by Our Lady of Victory (2026-11-15): its mass in cream plaster.
	var pzw := _outline_at(PZW_AT)
	if pzw.size() >= 3:
		_add_site("plebania_zwycieskiej", [pzw])
		if not sites.is_empty() and sites[-1]["key"] == "plebania_zwycieskiej":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": PZW_WALL, "roof": PZW_ROOF}
	# The Pallottines' presbytery on Skaryszewska (2026-11-15): its mass in the parish wings' plaster.
	var ppl := _outline_at(PPL_AT)
	if ppl.size() >= 3:
		_add_site("plebania_pallotynow", [ppl])
		if not sites.is_empty() and sites[-1]["key"] == "plebania_pallotynow":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": PPL_WALL, "roof": PPL_ROOF}
	# The Pallottines' house behind Christ the King on Skaryszewska (2026-11-15): its mass in the parish wings' plaster.
	var pdm := _outline_at(PDM_AT)
	if pdm.size() >= 3:
		_add_site("pallotyni_dom", [pdm])
		if not sites.is_empty() and sites[-1]["key"] == "pallotyni_dom":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": PDM_WALL, "roof": PDM_ROOF}
	# Our Lady of Częstochowa's parish house on Zagórna (2026-11-15): its mass in the church's grey render.
	var pzg := _outline_at(PZG_AT)
	if pzg.size() >= 3:
		_add_site("plebania_zagorna", [pzg])
		if not sites.is_empty() and sites[-1]["key"] == "plebania_zagorna":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": PZG_WALL, "roof": PZG_ROOF}
	# The low house east of the Family of Mary sisters' convent on Żytnia (2026-11-15): its mass in the convent's plaster.
	var rmp := _outline_at(RMP_AT)
	if rmp.size() >= 3:
		_add_site("rodziny_maryi_pawilon", [rmp])
		if not sites.is_empty() and sites[-1]["key"] == "rodziny_maryi_pawilon":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": RMP_WALL, "roof": RMP_ROOF}
	# The presbytery of the Nativity church on Leszno (2026-11-15): its mass in the neighbour's colours, provisional.
	var pls := _outline_at(PLS_AT)
	if pls.size() >= 3:
		_add_site("plebania_leszno", [pls])
		if not sites.is_empty() and sites[-1]["key"] == "plebania_leszno":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": PLS_WALL, "roof": PLS_ROOF}
	# The back wing of the Missionaries' house by Holy Cross (2026-11-15): its mass in the neighbour's colours, provisional.
	var mst := _outline_at(MST_AT)
	if mst.size() >= 3:
		_add_site("misjonarze_tyl", [mst])
		if not sites.is_empty() and sites[-1]["key"] == "misjonarze_tyl":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": MST_WALL, "roof": MST_ROOF}
	# Holy Trinity parish's house on Solec (2026-11-15): its mass in the neighbour's colours, provisional.
	var sld := _outline_at(SLD_AT)
	if sld.size() >= 3:
		_add_site("solec_dom", [sld])
		if not sites.is_empty() and sites[-1]["key"] == "solec_dom":
			sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": SLD_WALL, "roof": SLD_ROOF}
	# F (2026-11-24): Mirek's tuning workshop on the empty plot on Grzybowska (garage.gd's place).
	# It has a card, so it comes before the first quiet site below (the cards skip quiet sites).
	_find_warsztat_mirka()
	# Rezydencja Opera, Niecała 7 (F, 2026-11-26): a whole model over the mapped outline, with a card.
	_find_niecala7()
	_find_unique()
	# The University campus's escarpment wall and furniture (2026-11-15): quiet, so here.
	_find_uw_kampus_quiet()
	# The formal garden before Pałac Krasińskich (F's photos, 2026-11-06).
	if _landmark("Pałac Krasińskich").size() >= 3:
		_o = KRAS
		_a = KRAS_AXIS
		_b = Vector2(-_a.y, _a.x)
		_add_site("krasinski_ogrod", [_rect(0.0, 70.0, 44.0, 56.0)])
		if not sites.is_empty() and sites[-1]["key"] == "krasinski_ogrod":
			sites[-1]["quiet"] = true
	# Aleje Ujazdowskie 47 (F's photos, 2026-11-06): no landmark, LoD2's mass, the front is ours.
	_add_site("ujazdowskie47", [_pts(U47_OUTLINE)])
	if not sites.is_empty() and sites[-1]["key"] == "ujazdowskie47":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": U47_WALL, "roof": Color("#5f6264")}
		sites[-1]["quiet"] = true
	# Centrum Marszałkowska (F's photos, 2026-11-08): the stepped glass office on the corner.
	_find_cmarsz()
	_find_prozna()
	# Scena Relax (F's photos, 2026-11-06): the old cinema with its yellow banner.
	if _landmark("Scena Relax").size() >= 3:
		_add_site("scena_relax", [_landmark("Scena Relax")])
		if not sites.is_empty() and sites[-1]["key"] == "scena_relax":
			sites[-1]["raw"] = _landmark("Scena Relax")
			sites[-1]["ring"] = sites[-1]["raw"]
			sites[-1]["quiet"] = true
	# The Tides (F's photos, 2026-11-06): no landmark card, a full model over the mapped outline.
	_add_site("tides", [_pts(TD_OUTLINE)])
	if not sites.is_empty() and sites[-1]["key"] == "tides":
		sites[-1]["raw"] = _pts(TD_OUTLINE)
		sites[-1]["ring"] = sites[-1]["raw"]
		sites[-1]["quiet"] = true
	# Houses with street fronts read from F's photos (2026-11-06): game/data/photo_fronts.json.
	_find_photo_fronts()
	# Street blocks with modelled fronts (Nowy Świat, 2026-11-06).
	_find_blocks()


# --- building -------------------------------------------------------------------------

## `only` (the mesh-quality check, loop 0.1): build just the site with this key.
func build(surface, near := Rect2(), only := "") -> void:
	st = surface
	# What this build keeps: a sector's own tiles (chunked_surface.gd `only`) when it has them,
	# else `near`; the market skips the parts that reach none of it (jarmark.gd _jm_here).
	_near = near
	var tiles = surface.get("only") if near.has_area() else null
	if tiles is Rect2i and (tiles as Rect2i).has_area():
		var tile: float = ChunkedSurface.TILE
		_near = Rect2(Vector2((tiles as Rect2i).position) * tile, Vector2((tiles as Rect2i).size) * tile)
	pocket_rings.clear()
	_pick.resize(map._roof_nx * map._roof_nz * 2)
	_pick.fill(0)
	if only == "kit_sampler":  # the facade kit's test building (facade_kit.gd), not a site: `--solo=kit_sampler`
		_id = 0
		_walls.clear()
		_caps.clear()
		_holes = [] as Array[PackedVector2Array]
		kit_sampler()
		return
	var t0 := Time.get_ticks_msec()
	var built := 0
	for k in sites.size():
		if _quit_stop():
			return  # the quit fix: the game quits while this sector builds (map_builder.gd `cancel_build`)
		var s: Dictionary = sites[k]
		# Loop 3c: building one sector, only the sites that reach `near` (the sector grown by
		# the split's margin); the builder keeps the triangles that lie in the sector. Every
		# site sets its own frame, ground and material code, so it builds the same alone.
		if near.has_area() and not (s["box"] as Rect2).grow(SITE_REACH).intersects(near):
			continue
		var key: String = s["key"]
		if only != "" and key != only:
			continue
		_id = k + 1
		_r2 = {"site": key}
		_walls.clear()
		_caps.clear()
		_holes = s.get("courts", [] as Array[PackedVector2Array])
		_flood = FLOODLIT_SITES.has(key)
		built += 1
		match key:
			"palace":
				_build_palace(s)
			"tarasy":
				_build_tarasy(s)
			"rotunda":
				_build_rotunda(s)
			"varso":
				_build_varso(s)
			"varso_place":
				_build_varso_place(s)
			"stadium":
				_build_stadium(s)
			"legia":
				_build_legia(s)
			"centralna":
				_build_centralna(s)
			"poniatowski":
				_build_towers(s)
			"powisle_towers":
				_build_powisle_towers(s)
			"zygmunt":
				_build_zygmunt(s)
			"gaulle":
				_build_gaulle(s)
			"deski":
				_build_deski(s)
			"dom_partii":
				_build_dom_partii(s)
			"ns4a":
				_build_ns4a(s)
			"eon41":
				_build_eon41(s)
			"asp37":
				_build_asp37(s)
			"rynek":
				_build_rynek(s)
			"syrenka":
				_build_syrenka(s)
			"zamkowy":
				_build_zamkowy(s)
			"prymasowski":
				_build_prymasowski(s)
			"jablonowskich":
				_build_jablonowskich(s)
			"arkadia":
				_build_arkadia(s)
			"forest":
				_build_forest(s)
			"prosta32":
				_build_prosta32(s)
			"prosta28":
				_build_prosta28(s)
			"lucka":
				_build_lucka(s)
			"towarowa22":
				_build_towarowa22(s)
			"noho":
				_build_noho(s)
			"stacja_muzeum":
				_build_stacja_muzeum(s)
			"nocny":
				_build_nocny(s)
			"kolejowa":
				_build_kolejowa(s)
			"d19":
				_build_d19(s)
			"asbud":
				_build_asbud(s)
			"gbc":
				_build_gbc(s)
			"bridge":
				_build_bridge(s)
			"grzybowska77":
				_build_bellona(s)
			"flaga":
				_build_flag(s)
			"kladka":
				_build_kladka(s)
			"ateneum":
				_build_ateneum(s)
			"lipowa1a":
				_build_lipowa1a(s)
			"wiadukt_markiewicza":
				_build_markiewicz(s)
			"szaja":
				_build_szaja(s)
			"swieto":
				_build_swieto(s)
			"muzeum":
				_build_muzeum(s)
			"europejski":
				_build_europejski(s)
			"grob":
				_build_grob(s)
			"metropolitan":
				_build_metropolitan(s)
			"wiktoria":
				_build_wiktoria(s)
			"metropolsign":
				_build_metropol_sign(s)
			"loretka":
				_build_loretka(s)
			"level26_club":
				_build_level26_club(s)
			"msn":
				_build_msn(s)
			"tr":
				_build_tr(s)
			"nozyce":
				_build_nozyce(s)
			"jarmark":
				_build_jarmark(s)
			"obeliski":
				_build_obeliski(s)
			"dtc":
				_build_dtc(s)
			"trojca":
				_build_trojca(s)
			"zacheta":
				_build_zacheta(s)
			"mirowska":
				_build_mirowska(s)
			"gwardii":
				_build_gwardii(s)
			"prezydencki":
				_build_prezydencki(s)
			"aleksander":
				_build_aleksander(s)
			"barbakan":
				_build_barbakan(s)
			"piano_house":
				_build_piano_house(s)
			"cube_house":
				_build_cube_house(s)
			"hortus":
				_build_hortus(s)
			"moderna":
				_build_moderna(s)
			"flisac":
				_build_flisac(s)
			"pomnik_powstania":
				_build_pomnik_powstania(s)
			"krasinski":
				_build_krasinski(s)
			"sad_najwyzszy":
				_build_sad_najwyzszy(s)
			"zbawiciela":
				_build_zbawiciela(s)
			"zbawiciela_plac":
				_build_zbawiciela_plac(s)
			"buw":
				_build_buw(s)
			"kopernik":
				_build_kopernik(s)
			"norblin":
				_build_norblin(s)
			"browary":
				_build_browary(s)
			"koszyki":
				_build_koszyki(s)
			"torwar":
				_build_torwar(s)
			"sad_okregowy":
				_build_sad_okregowy(s)
			"nbp":
				_build_nbp(s)  # the whole branch (SKINS entry with `model`: it replaces LoD2)
			"city_gate":
				_build_city_gate(s)
			"meridian":
				_build_meridian(s)
			"oxygen":
				_build_oxygen(s)
			"mostowski":
				_build_mostowski(s)
			"hotel_saski":
				_build_hotel_saski(s)
			"dom_chlopa":
				_build_dom_chlopa(s)  # over its street block: the wavy roof edge and the signs
			"batalion_kilinski":
				_build_batalion_kilinski(s)  # the battalion's monument on Plac Powstańców Warszawy
			"zyletkowiec":
				_build_zyletkowiec(s)  # over its street block: the fins, the piers, the roof lid
			"elektrownia":
				_build_elektrownia(s)
			"rotunda_dynasy":
				_build_rotunda_dynasy(s)
			"mpw":
				_build_mpw(s)
			"mf":
				_build_mf(s)
			"poczta":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the front, the dome and the hall's glass are ours
				_build_poczta(s)
			"politechnika":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the rounded front pavilion is ours
				_build_politechnika(s)
			"pasta":
				_build_pasta(s)
			"teatr":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the portico is ours
				_build_teatr(s)
			"zamek":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the towers' helms, the Vistula front, the plinth are ours
				_build_zamek(s)
			"ratusz":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the colonnades and portico are ours
				_build_ratusz(s)
			"gielda":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the corner's arches and dome are ours
				_build_gielda(s)
			"filharmonia":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the Jasna front is ours
				_build_filharmonia(s)
			"teatr_polski":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the Karasia front is ours
				_build_teatr_polski(s)
			"arkady":
				_build_arkady(s)
			"sw_krzyz":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the facade and towers are ours
				_build_krzyz(s)
			"wszystkich":
				_build_wszystkich(s)  # the whole church (SKINS entry with `model`: it replaces LoD2)
			"archikatedra":
				_mark_zone(s)  # the nave stays LoD2's, in its brick; the stepped-gable front is ours
				_build_archikatedra(s)
			"jezuici":
				_build_jezuici(s)  # the whole church (SKINS entry with `model`: it replaces LoD2)
			"wizytki":
				_build_wizytki(s)  # the whole church (SKINS entry with `model`: it replaces LoD2)
			"karmelici":
				_mark_zone(s)  # the nave stays LoD2's, in its skin; the front is ours
				_build_karmelici(s)
			"branickich":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the pilasters, cornice and attic are ours
				_build_branickich(s)
			"mickiewicz":
				_build_mickiewicz(s)
			"prus":
				_build_prus(s)
			"wyszynski":
				_build_wyszynski(s)
			"brama_uw":
				_build_brama_uw(s)
			"potocki":
				_build_potocki(s)
			"kordegarda":
				_build_kordegarda(s)
			"smolensk":
				_build_smolensk(s)
			"pilsudski":
				_build_pilsudski(s)
			"kaczynski":
				_build_kaczynski(s)
			"plac_maszty":
				_id = 0  # the masts: no card, not on the picking grid
				_build_plac_masts(s)
			"plac_centralny":
				_id = 0  # the square's furniture: no card, not on the picking grid
				_build_plac_centralny(s)
			"trybuna":
				_build_trybuna(s)
			"plac_centralny_lamps":
				_id = 0
				_build_plac_centralny_lamps(s)
			"kazimierzowski":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the risalit's portico is ours
				_build_kazimierzowski(s)
				_build_kazimierzowski_garden()  # the garden front over the escarpment (2026-11-15)
			"uruski":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the street front is ours
				_build_uruski(s)
			"stara_buw":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the front and flanks are ours
				_build_stara_buw(s)
			"uw_skarpa":
				_id = 0  # the escarpment wall: no card, not on the picking grid
				_build_uw_skarpa(s)
			"uw_straz":
				_build_uw_straz(s)
			"uw_kampus":
				_id = 0  # the campus furniture: no card, not on the picking grid
				_build_uw_kampus(s)
			"czapski":
				_build_czapski(s)
			"mariensztat":
				_build_mariensztat(s)
			"hotel_kasztel", "hotel_canaletto", "hotel_starowka":
				_build_hotel(s)
			"polonia":
				_build_polonia(s)
			"ujazdowski":
				_build_ujazdowski(s)
			"polskie_radio":
				_build_polskie_radio(s)
			"dom_poselski":
				_build_dom_poselski(s)
			"stary_dom_poselski":
				_build_stary_dom_poselski(s)
			"rembielinskiego":
				_build_rembielinskiego(s)
			"willa_raua":
				_build_willa_raua(s)
			"dziewulskich":
				_build_dziewulskich(s)
			"pod_karczochem":
				_build_pod_karczochem(s)
			"sobieski":
				_build_sobieski(s)
			"bristol":
				_build_bristol(s)  # the whole hotel replaces LoD2
			"sw_anna":
				_mark_zone(s)  # the whole church and the bell tower are ours (a model, SKINS `runs`)
				_build_anna(s)
			"nikidw":
				_mark_zone(s)
				_build_nikidw(s)
			"mansjonaria":
				_mark_zone(s)
				_build_mansjonaria(s)
			"staszic":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the portico and the statue are ours
				_build_staszic(s)
			"sejm":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the hall's colonnade is ours
				_build_sejm(s)
			"tower75":
				_id = 0  # unnamed: no card, not on the picking grid
				_build_tower75(s)
			"unique":
				_build_unique(s)
			"slabs":
				_id = 0
				_build_slabs(s)
			"zelazna":
				_build_zelazna(s)
			"gpxz":
				_build_gpxz(s)
			"pokorna2":
				_id = 0
				_build_pokorna2(s)
			"pko_branch":
				_id = 0
				_build_pko_branch(s)
			"dekalog_estate":
				_build_dekalog_estate(s)
			"inflancka_pools":
				_build_inflancka_pools(s)
			"kino_muranow":
				_build_kino_muranow(s)
			"pawilony":
				_build_pawilony(s)
			"cepelia":
				_build_cepelia(s)
			"sowa":
				_build_sowa(s)
			"rondo":
				_id = 0
				_build_rondo(s)
			"sunken", "underpass", "defilad_ramp", "powstancow_ramp", "tarasy_plaza", "rondo_wells", "mw_cen", "mw_onz", "mw_dasz", "mw_ratusz", "mw_nsu", "mw_poli", "mw_cnk":
				_id = 0
				_build_sunken(s)
			"metro_tubes":
				_id = 0
				_build_metro_tubes()
			"metro_pavilion":
				_id = 0
				_build_metro_pavilion()
			"zodiak":
				_build_zodiak(s)
			"pijana":
				_build_pijana(s)
			"tapczan":
				_build_tapczan(s)
			"sienkiewicza4":
				_build_sienkiewicza4(s)  # the whole house (it replaces LoD2 and the mapped parts)
			"harczyk":
				_build_harczyk(s)
			"sienkiewicza3":
				_build_sienkiewicza3(s)
			"wiecha":
				_build_wiecha(s)
			"wiecha_swieta":
				_build_wiecha_swieta(s)
			"warsztat_mirka":
				_build_warsztat_mirka(s)
			"niecala7":
				_build_niecala7(s)
			"orly":
				_build_orly(s)
			"hotel_warszawa":
				_build_hotel_warszawa(s)
			"cedet":
				_build_cedet(s)
			"polin":
				_build_polin(s)
			"getto":
				_build_getto(s)
			"nike":
				_build_nike(s)
			"slowacki":
				_build_slowacki(s)
			"starzynski":
				_build_starzynski(s)
			"maly_powstaniec":
				_build_maly_powstaniec(s)
			"kilinski":
				_build_kilinski(s)
			"umschlagplatz":
				_build_umschlagplatz(s)
			"pomnik_wschod":
				_build_pomnik_wschod(s)
			"ochota":
				_build_ochota(s)
			"powisle":
				_build_powisle(s)
			"stadion_pkp":
				_build_stadion_pkp(s)
			"wschodnia":
				_build_wschodnia(s)
			"barka_wieczor", "barka_biala", "barka_marina", "barka_kaskada":
				_build_barge(s)
			"marina":
				_build_marina(s)
			"port_majami":
				_build_port_majami(s)
			"port_wtw":
				_build_port_wtw(s)
			"monkey_love":
				_build_monkey_love(s)
			"port_halls":
				_id = 0  # club halls and sheds: no card, not on the picking grid
				_build_port_halls(s)
			"port_basin":
				_id = 0  # moored boats: no card, not on the picking grid
				_build_port_basin(s)
			"houseboats":
				_id = 0  # private homes: no card, not on the picking grid
				_build_houseboats(s)
			"bulwary_pawilony":
				_build_bulwar_pavilions(s)
			"bulwary_bary":
				_build_bulwar_bars(s)
			"bulwary_pomosty":
				_id = 0  # deck strips: no card, not on the picking grid
				_build_bulwar_decks(s)
			"bulwary_basen":
				_id = 0  # the children's corner: no card, not on the picking grid
				_build_bulwary_pool(s)
			"schodki_wisla":
				_id = 0  # ground-level steps: no card, not on the picking grid
				_build_schodki_wisla(s)
			"pawilon_tanca":
				_build_pawilon_tanca(s)
			"zachodni_brzezek":
				_build_zachodni_brzezek(s)
			"plyta_desantu":
				_build_plyta_desantu(s)
			"barka_nowa_falka", "barka_zanurzenie", "barka_wirek", "barka_kalmar", "barka_barkas":
				_build_bbc_barge(s)
			"srodmiescie":
				_build_srodmiescie(s)
			"wkd_srodmiescie":
				_build_wkd_srodmiescie(s)
			"wkd_ochota":
				_build_wkd_ochota(s)
			"ostrogski":
				_build_ostrogski(s)


			"teresy":
				_build_teresy(s)
			"florian":
				_build_florian(s)
			"bazar":
				_build_bazar(s)
			"centrum_praha":
				_build_centrum_praha(s)
			"targowa33a":
				_build_targowa33a(s)
			"powszechny":
				_build_powszechny(s)
			"port_praski":
				_build_port_praski(s)
			"kosciuszkowcy":
				_build_kosciuszkowcy(s)
			"pp_basin":
				_build_pp_basin(s)
			"syrenka_powisle":
				_build_syrenka_powisle(s)
			"dworzec_wodny":
				_build_dworzec_wodny(s)
			"kaskada":
				_build_kaskada(s)
			"mdm":
				_mark_zone(s)  # the blocks stay LoD2's, in their skin; the arcades, towers and reliefs are ours
				_build_mdm(s)
			"vitkac":
				_build_vitkac(s)
			"jablkowscy":
				_build_jablkowscy(s)
			"sheraton":
				_build_sheraton(s)
			"bgk":
				_build_bgk(s)
			"ufficio_primo":
				_build_ufficio_primo(s)
			"foksal":
				_mark_zone(s)  # the masses and the mansards stay LoD2's, in their skin; the fronts are ours
				_build_foksal(s)
			"mlotek":
				_build_mlotek(s)
			"kozia9":
				_build_kozia9(s)
			"cparking":
				_build_cparking(s)
			"karowa18a":
				_build_karowa18a(s)
			"smolna38":
				_build_smolna38(s)
			"jerozolimskie57":
				_build_jerozolimskie57(s)
			"nowogrodzka31":
				_id = 0  # no card, not on the picking grid
				_build_nowogrodzka31(s)
			"marszalkowska99":
				_id = 0  # no card, not on the picking grid
				_build_marszalkowska99(s)
			"filtry":
				_build_filtry(s)
			"scena_relax":
				_id = 0  # not tappable
				_build_scena_relax(s)
			"cmarsz":
				_id = 0  # not tappable
				_build_cmarsz(s)
			"tides":
				_id = 0  # not tappable
				_build_tides(s)
			"ujazdowskie47":
				_id = 0  # not tappable
				_build_ujazdowskie47()
			"prozna":
				_id = 0  # not tappable
				_mark_zone(s)  # the mass stays LoD2's, in its plaster; the fronts and the street's furniture are ours
				_build_prozna(s)
			"plac_grzybowski":
				_id = 0  # not tappable
				_build_plac_grzybowski(s)
			"krasinski_ogrod":
				_id = 0  # not tappable
				_build_kras_garden()
			"adwentysci":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the gate, balconies and band are ours
				_build_adwentysci(s)
			"faustyna_klasztor":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"szarytki_zaulek":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"dom_parafialny_barbara":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"solec_dom":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"misjonarze_tyl":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"plebania_leszno":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"rodziny_maryi_pawilon":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"plebania_zagorna":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"pallotyni_dom":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"plebania_pallotynow":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"plebania_zwycieskiej":
				_mark_zone(s)  # the mass stays LoD2's, in its skin
			"elzbietanki":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the rounded east end is ours
				_build_elzbietanki(s)
			"szarytki":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the turret is ours
				_build_szarytki(s)
			"lawrynowicz":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the street front is ours
				_build_lawrynowicz(s)
			"wedel":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the fronts and the corner are ours
				_build_wedel(s)
			"szpitalna5":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the two street fronts are ours
				_build_szpitalna5(s)
			"gigantami":
				_mark_zone(s)  # the mass stays LoD2's, in its skin; the street front is ours
				_build_gigantami(s)
			"bez_kantow":
				_build_bez_kantow(s)  # the whole block, Królewska 2 included (it replaces LoD2's wings)
			_:
				if key.begins_with("church_"):
					_build_church(s)
				elif s.has("block"):
					_id = 0  # not tappable
					_build_block(s)
				elif s.has("fronts"):
					_id = 0  # not tappable
					_build_photo_fronts(s)
				elif s.has("tower"):
					_build_tower(s)
					if (s["tower"] as Dictionary).has("on_block"):
						_mark_zone(s)  # no body of its own to tap: the block's outline
				elif s.has("skin"):
					_mark_zone(s)
		if not _holes.is_empty():
			_court_walls(_court_wall_colour(key))
			_holes = []
	_id = 0
	_flood = false
	if not near.has_area():
		print("landmarks: %d built in %d ms" % [built, Time.get_ticks_msec() - t0])


## Loop 3c: how far a landmark's model may reach outside its site's box (slack: the models
## stand inside their zones); a sector builds every site whose box comes this close.
const SITE_REACH := 24.0


## Which landmark covers a roof-grid cell (0: none), for map_builder.landmark_at: a 16-bit id per
## cell, two bytes each, since one byte ran out at 255 sites (the 2026-11-08 merge train had 257).
func pick_grid() -> PackedByteArray:
	return _pick


# --- emitting ----------------------------------------------------------------------------

## Courtyards (F, 2026-11-03): the walls round the current site's courts, facing in, from the
## ground to the roof that rims each side (the highest flat top of the site 1 m behind it; a
## side with none takes the court's highest), with a window bay every COURT_STEP m on every
## storey.
func _court_walls(wall: Color) -> void:
	var keep := _mode
	for h in _holes:
		var tops := PackedFloat32Array()
		var best := -INF
		for i in h.size():
			var a := h[i]
			var b := h[(i + 1) % h.size()]
			var behind := (a + b) * 0.5 - _out(h, a, b) * -1.0
			var top := -INF
			for c in _caps:
				if float(c[0]) > top and Geometry2D.is_point_in_polygon(behind, c[1]):
					top = float(c[0])
			tops.append(top)
			best = maxf(best, top)
		if best == -INF:
			continue
		var run := 0.0
		for i in h.size():
			var a := h[i]
			var b := h[(i + 1) % h.size()]
			var inward := -_out(h, a, b)
			var top := tops[i] if tops[i] > -INF else best
			_mode = M_STONE
			_wall(a, b, _g - 0.6, top, inward, wall, run)
			var length := a.distance_to(b)
			run += length
			var n := floori((length - 1.5) / COURT_STEP)
			if n < 1:
				continue
			_mode = M_GLASS
			var e := (b - a) / length
			var t0 := (length - n * COURT_STEP) * 0.5 + COURT_STEP * 0.5
			var y := _g + 1.0
			while y + 2.4 < top - 0.8:
				for k in n:
					var p := a + e * (t0 + k * COURT_STEP) + inward * 0.07
					_wall(p - e * 0.7, p + e * 0.7, y, y + 2.4, inward, COURT_GLASS, floorf((t0 + k * COURT_STEP) / 1.5) * 1.5 + 0.05)
				y += COURT_FLOOR
	_mode = keep


# --- Most Świętokrzyski (the landmarks loop, the user's ask 2026-10-31) --------------------------

## A kept building's site (the museum) on the picking grid: every cell whose centre is inside.
func _mark_zone(site: Dictionary) -> void:
	var cell: float = map.ROOF_CELL
	var box: Rect2 = site["box"]
	var i0 := maxi(floori((box.position.x - map._roof_x0) / cell), 0)
	var i1 := mini(floori((box.end.x - map._roof_x0) / cell), map._roof_nx - 1)
	var j0 := maxi(floori((box.position.y - map._roof_z0) / cell), 0)
	var j1 := mini(floori((box.end.y - map._roof_z0) / cell), map._roof_nz - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var p := Vector2(map._roof_x0 + (i + 0.5) * cell, map._roof_z0 + (j + 0.5) * cell)
			for z: PackedVector2Array in site["zone"]:
				if Geometry2D.is_point_in_polygon(p, z):
					_pick.encode_u16((j * map._roof_nx + i) * 2, _id)
					break


# --- Plac Piłsudskiego, part 2 (2026-10-31) ---------------------------------------------------

## The far skyline's colour of each (sector_proxies.gd, through `tower_colour`).
const PLAC_WALLS := {"metropolitan": "#8a979c", "wiktoria": "#d9d7d0", "europejski": "#e7ddc5",
		"grob": "#ddd3bf", "bez_kantow": "#dccdac", "departament": "#dccfb2"}


# --- Filharmonia Narodowa and Teatr Polski ----------------------------------------------------

## The Sisters of Charity on Tamka (Zakład Sióstr Miłosierdzia św. Wincentego à Paulo, the
## "szarytki", Tamka 35; 1730s-1850s, rebuilt after 1944): long white two-storey ranges round a
## courtyard below the escarpment, under tall dull green copper roofs with rows of white dormers,
## and a slim green turret with an onion on the ridge. The mass stays GUGiK's LoD2 (OSM building
## 12823, unnamed; ridges about 14 m over the ground) in its white plaster and copper (`steep`:
## LoD2's tall roofs keep the roof colour); the turret is ours. From F's 11 Commons photos
## (refs/churches/szarytki_tamka, reference only, never shipped): 01 and 02 show the roofs and the
## turret from the escarpment, 03 and 11 the white courtyard fronts. Spec
## docs/landmarks/specs/szarytki.md. Not built: the dormers (the roofs are LoD2's, not ours).
const SZT_AT := Vector2(72.0, -200.0)        ## inside the outline (the east range)

const ADW_WALL := Color("#ead9a2")           ## pale yellow plaster (photos 01, 02, 05)
const ADW_ROOF := Color("#7b7d7f")

## The Presidential Palace (Pałac Prezydencki; Aigner's classical rebuilding, 1818-1819) on
## Krakowskie Przedmieście: the main block across the back of the forecourt with a portico of
## four giant columns under a pediment, two long wings to the street ending in pavilions with
## pediments, the iron fence with its gate between four stone lions on pedestals and two
## guardhouses, and Thorvaldsen's Prince Józef Poniatowski on horseback in the forecourt.
## Frame: u from the main block's front towards the street (WNW), v across (v < 0 north).
## The far skyline's colour of each (sector_proxies.gd, through `tower_colour`).
const MALACHOWSKI_WALLS := {"trojca": "#e9e7e1", "zacheta": "#ebeae4", "prezydencki": "#efe9da", "aleksander": "#ebe4d2"}


# --- Centrum Nauki Kopernik ---------------------------------------------------------------------

const KOP_WALL := Color("#a8958c")   # the strips' average (the far skyline)
