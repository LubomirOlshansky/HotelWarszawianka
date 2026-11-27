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
##   godot --headless --path game --script res://tools/check_mesh_quality.gd [-- --site=KEY]
## `--site=KEY` judges that one site alone (budget, defects; no sampler, signs or SUNKEN checks): the
## builder's inner loop takes seconds instead of the whole run's minutes (Ufficio Primo pilot,
## 2026-11-26: 6.5 min in the cloud). The whole run stays the gate (verify step and CI).

const MapBuilderRef := preload("res://scripts/map_builder.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const MeshProbe := preload("res://tools/mesh_probe.gd")
const Fakes := preload("res://tools/fakes.gd")
const Neon := preload("res://scripts/neon_signs.gd")
## Triangles a site may hold: measured on 2026-10-31 plus about 20 % (raise on purpose only).
const BUDGET := {
	"scena_relax": 600,
	"smolna38": 2700,
	"jerozolimskie57": 10000,  # 2026-11-15: the Jerozolimskie row from F's photos: four fronts, canopies, showcases, the building site (measured 9179)
	"tides": 8000,
	"ujazdowskie47": 3000,
	"krasinski_ogrod": 900,
	"lawrynowicz": 8000,
	"wedel": 8000,
	"szpitalna5": 8000,
	"adwentysci": 500,  # 2026-11-15: the Adventist church on Foksal 8 (gate, balconies, band; the mass is LoD2's)
	"elzbietanki": 400,  # 2026-11-15: the Elizabethan sisters behind Piekarska (the rounded end; the mass is LoD2's)
	"szarytki": 300,  # 2026-11-15: the Sisters of Charity's turret (the mass is LoD2's)
	"gigantami": 4000,
	"filtry": 3000,
	"level26_club": 6900,  # 2026-11-22: rebuilt from F's photos: the terrace round the drum, railing, lanterns, deck chairs, birches, DJ truss, bar (measured 5753)
	"church_alberta": 950,  # 2026-11-14: the whole classicist frontage on Plac Teatralny, portico and two wings, from photos (measured 818)
	"church_antoniego": 1250,
	"church_augustyn": 1900,  # 2026-11-14: the whole brick basilica and its 70 m tower, checked against photos (measured 1759)
	"church_siostry_milosierdzia_zytnia": 1200,  # 2026-11-15: the Sisters of Our Lady of Mercy's house on Żytnia from photos and LoD2 (measured 874)
	"church_kaplica_hoza": 300,  # 2026-11-15: the yard chapel behind Hoża 55 from LoD2, provisional (measured 142)
	"church_kaplica_lucka": 300,  # 2026-11-15: the yard chapel behind Łucka from LoD2, provisional (measured 112)
	"church_kaplica_florianska": 400,  # 2026-11-15: the octagonal chapel by St Florian's from photos (measured 184)
	"church_zytnia_dom_zakonny_tyl": 1500,  # 2026-11-15: the range behind the convent on Żytnia from LoD2, provisional (measured 1299)
	"church_zytnia_dom_zakonny": 900,  # 2026-11-15: the convent range on Żytnia's south side by Wolność from photos and LoD2 (measured 582)
	"church_zwycieska_klasztor": 1200,  # 2026-11-15: the monastery block beside Our Lady of Victory from LoD2, provisional (measured 850)
	"church_klopotowskiego_18": 1500,  # 2026-11-15: the church house with the window of life on Kłopotowskiego from photos and LoD2 (measured 1288)
	"church_plebania_florian": 1500,  # 2026-11-15: St Florian's presbytery on Floriańska from photos and LoD2 (measured 1352)
	"church_sluzki_dom_generalny": 1200,  # 2026-11-15: the Servants of Jesus' generalate from photos and LoD2 (measured 798)
	"church_uczennice_boskiego_mistrza": 1400,  # 2026-11-15: the Sister Disciples' convent from photos and LoD2 (measured 1179)
	"church_plebania_augustyn": 500,  # 2026-11-15: St Augustine's presbytery from LoD2 (measured 311)
	"church_plebania_katedra_polowa": 600,  # 2026-11-15: the Field Cathedral's presbytery from photos and LoD2 (measured 537)
	"church_reformaci_klasztor": 500,  # 2026-11-15: the Reformati friary by St Anthony's from LoD2 (measured 396)
	"church_wizytki_klasztor": 900,  # 2026-11-15: the Visitation sisters' convent from LoD2
	"church_sala_faustyny": 250,  # 2026-11-14: the St Faustina hall in Ochota (measured 182)
	"church_franciszkanki_piwna": 1100,  # 2026-11-14: the Franciscan Sisters' house on Piwna (measured 969)
	"church_kapucyni_klasztor": 900,  # 2026-11-14: the Capuchin monastery on Miodowa (measured 797)
	"church_misjonarze_radna": 600,  # 2026-11-14: the Missionaries' house on Radna (measured 514)
	"church_misjonarze": 1150,  # 2026-11-14: the Missionaries' house on Krakowskie Przedmieście (measured 1053)
	"church_barbara": 220,  # 2026-11-14: St Barbara's brick chapel (measured 162)
	"church_baptysci": 200,  # 2026-11-14: the Baptists' box on Waliców (measured 146)
	"church_chrystusa_krola": 880,  # 2026-11-14: Christ the King and its chapel (measured 768)
	"church_pallotyni": 840,  # 2026-11-14: the Pallottines' modernist house (measured 726)
	"church_rodziny_maryi": 720,  # 2026-11-14: the sisters' long house, its middle block and annex (measured 622)
	"church_dominikanie": 600,  # 2026-11-14: the Dominican priory's wings round the cloister (measured 492)
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
	"church_piotr_pawel": 1650,  # 2026-11-26: 3D Tiles rework: pitched transept and wings, drum balustrade, fuller dome (was 1300)
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
	"brama_uw": 4000,  # 2026-11-15: rebuilt from F's photos, banded pilasters, iron gates, lamps, flags
	"uruski": 5000,  # 2026-11-15: Pałac Uruskich's street front and the risalit over the gate, from F's photos (4342 built)
	"stara_buw": 5000,  # 2026-11-15: the Old Library's front and flanks from F's photos
	"uw_skarpa": 7000,  # 2026-11-15: the escarpment's brick wall, piers, graffiti, railing
	"uw_straz": 900,  # 2026-11-15: the guards' kiosk
	"uw_kampus": 1500,  # 2026-11-15: bollards and chains, flagpoles
	"bristol": 7500,
	"polonia": 1450,
	"ujazdowski": 1650,
	"sobieski": 1500,
	"vitkac": 2600,  # 2026-11-21 teaser 4 (F's photo): rounded granite corners, glass ribbons, shop glass and mullions, the glass top storey and its bar terrace: 2403 tris
	"jablkowscy": 1450,
	"sheraton": 2400,
	"bgk": 2700,
	"ufficio_primo": 4400,  # 2026-11-26: the whole stone cube, doors, bronze guardians; L2 exception: the roof (dome, 71 bubbles, roof lights) is its identity from the camera
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
	"kordegarda": 1750,  # 2026-11-27 v2 whole gallery (Codex): 1,350 measured, ~1.3x room
	"mdm": 4100,
	"mickiewicz": 1150,
	"potocki": 6500,
	"prus": 250,
	"wyszynski": 300,
	"arkadia": 20300,
	"blekitny": 1850,  # 2026-11-15 photo pass (1521 tris): mirror glass, the glass barrel vault, the helipad box, the screen and the antennas
	"bridge": 700,
	"grzybowska77": 2000,
	"buw": 10600,  # 2026-11-20 pass 5 (rotunda dome and lookout drum on the corner, stair, funnel oculus, mound, pizzeria terrace and gate pier): 10391 tris, +0 draw calls; pass 4 was 8672
	"central": 340,
	"centralna": 1650,
	"chalubinskiego8": 1520,
	"cosmopolitan": 420,  # 2026-11-08 photo rebuild (F)
	"plac_grzybowski": 1500,  # 2026-11-08 photo build (F): 1429 tris, the cascade field is 48 blocks
	"prozna": 5100,  # 2026-11-08 photo build (F): 5014 tris, 1,300 of them the 90 bollards
	"ns4a": 1200,  # 2026-11-26 Nowy Świat 4A from F's night photo: lobby, copper fascia, glass with lit fins, flag band, top storey, roof box, flag: 1097 tris, +0 draw calls
	"dom_partii": 14300,  # 2026-11-21 teaser 4 (F): café guests and dogs at the tables, then the courtyard by the bar (deckchairs, a stage, crowds): 13593 tris; earlier: 2026-11-12 rebuilt whole from F's photos: 5202 tris; 2026-11-19 the arcade, terrace, cafés and tables: 7225 tris, +0 draw calls
	"eon41": 1300,  # 2026-11-13 photo rebuild (F): the power company's L-block, curve, medallions, glass tower, lantern
	"asp37": 1600,  # 2026-11-13 the Academy of Fine Arts: the 1914 school and JEMS's wing
	"deski": 2300,
	"rynek": 3100,
	"syrenka": 480,
	"syrenka_powisle": 1400,  # 2026-11-20: rebuilt at its real spot with the basin, the wall, the spouts and the slopes
	"dworzec_wodny": 310,
	"kaskada": 260,
	"dtc": 2250,
	"europejski": 8000,
	"flaga": 170,
	"forest": 8100,  # 2026-11-15: the real green roof (lawns, wavy corten beds, railing, pavilions, tent), measured 6739 (was 4260)
	"gpy": 2000,  # RD-3 (2026-11-06): black patches, the wings' decks, trees and tables
	"gpxz": 12000,  # Generation Park X and Z: two 11-16 storey stone-grid office blocks framing Y
	"gaulle": 880,
	"rondo": 10000,  # 2026-11-26: open wells, bent beds, arm beds, the square by the Empik pavilion: measured 8771
	"sunken": 5600,  # 2026-11-05: the Patelnia and the Rotunda's stair: walls, railings, treads, two barrels
	"metro_tubes": 1500,  # 2026-11-09: Metro Centrum's two barrels by the Palace park: ribs, pink walls, escalators
	"metro_pavilion": 800,  # 2026-11-19: Metro Centrum's big glass pavilion by the Palace park: 14 ribs, glazing bars, fan end
	"defilad_ramp": 1500,  # 2026-11-09: the Plac Defilad car park ramp: two pink walls, 22 ribbed strips
	"underpass": 3000,  # 2026-11-06: the Emilii Plater underpass: five entrances, parapets, treads, two canopies
	"gbc": 750,
	"grob": 340,
	"grzybowska63": 500,
	"gwardii": 1450,
	"hub_b": 380,  # RD-4: parapet, roof plant, podium skylight; 2026-11-19 the glass crown and the street-front boards
	"hub_c": 280,  # RD-4: parapet, roof plant; 2026-11-19 the glass crown and the HUB board
	"ilmet": 400,
	"jp2_21": 280,
	"kopernik": 1720,
	"legia": 950,  # 2026-11-15 photo rework (762 tris): the roof's membrane tents, podium, concourse columns and banners, glass corners; no corner masts
	"lim": 2500,  # podium from F's photos (2026-11-06) + the tower from 25 photos (2026-11-15): 2087 measured
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
	"bez_kantow": 8000,  # 2026-11-15 Dom bez Kantów and Królewska 2 rebuilt whole from F's photos and the orthophoto: the ring, arcades, panes, cornices (measured 6679)
	"politechnika": 950,  # 2026-11-15 front from F's photos: the columned middle on Plac Politechniki, attic and figures, stairs, lamp pillars
	"pasta": 580,
	"msn": 900,
	# Norblin on its real block (2026-11-02, photo report): two blocks, Plater and Galwan, about
	# three times the first footprint, arched windows round their courts, green roofs and terraces.
	# 2026-11-03 look check: the copper base, finned storeys, set-back tops, the passage roof and
	# the old white workshops under zinc (the Mac's spec).
	"norblin": 5700,
	# Browary + the Central Garden's gravel path, café clearings and the sedum roofs (2026-11-02).
	"browary": 3900,   # 2026-11-03: paved main path and clearing edges (look check)
	"koszyki": 1900,
	"torwar": 1500,  # 2026-11-15 from photos, over its street block: the portico's columns, entablature, parapet and letters; pilasters and lattice panels round the hall
	"nbp": 1000,  # 2026-11-16 from photos, the whole branch: the folded panel bands, the glass ground floor, the steps, the white wall with the eagle and NBP, the stair slot, planters
	"mostowski": 7000,  # the palace, portico and three open courts
	"powszechny": 6000,
	"dom_chlopa": 3000,  # 2026-11-16 from photos, over its street block: the wavy roof edge on every street front, GROMADKA, the HOTEL corner sign, KASYNO TRAF
	"batalion_kilinski": 1100,  # 2026-11-16 from photos: the tilted granite slab, the white step and four stelae, the white blocks, five flower bowls
	"powstancow_ramp": 1500,  # 2026-11-16: Plac Powstańców Warszawy's car park ramp: the concrete walls, 22 strips of setts
	"zyletkowiec": 2300,  # 2026-11-16 from photos (T15), over its street block: a white fin and a granite-grey pier on every bay of the street fronts, the dark overhanging roof lid
	"elektrownia": 7600,  # 2026-11-13: the whole complex (hall, halls, passage, office, old wing, gardens): 1634 -> ~6850
	"rotunda_dynasy": 1400,
	"mpw": 3200,
	"metropolitan": 3100,
	"metropolsign": 320,  # 2026-11-10: Hotel Metropol rebuilt whole from F's photos (255 measured)
	"muzeum": 4600,  # 2026-11-26 the lit roof sign (wave + MUZEUM NARODOWE in built serif letters, F's night photo): 4478 tris; 2026-11-06 photo pass: a stone pier on every bay boundary, fence, flagpoles
	"palace": 28500,   # 2026-11-26 the Blender Palace is the default (F, reel close-ups): 27,708 tris with the crown frieze, the glb's 23,084 plus the venues, one mesh, +0 draw calls (probe below). Before, 2026-11-07: 3696 -> 7288, Bar Studio's 34 deck chairs, tables, festoons and frame signs (same mesh, no new draw call)
	"pawilony": 2100,
	"plater49": 140,
	"platinum_a": 80,
	"platinum_b": 80,
	"poniatowski": 4800,  # 2026-11-03: the towers strengthened (F), 2556 -> 4574 tris over four groups; +0 draw calls
	"prezydencki": 7000,
	"q22": 720,  # 2026-11-08 photo rebuild (top-50 T02): 607 tris
	"rondo1": 900,  # 2026-11-08 photo rebuild (top-50 T03): 769 tris
	"rotunda": 2450,  # 2026-11-11: + the plaza's dark stone grid and its bollards
	"skyliner": 440,  # 2026-11-19: the KANTOR and SUSHI boards toward the Rondo
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
	"tr": 6500,  # 2026-11-15 rebuild from F's 13 photos: concrete shell with red formwork and rebar, two lattice cranes, flags, yard
	"nozyce": 700,  # the gold scissors on their granite plinth (F's photo, 2026-11-15)
	"jarmark": 192000,  # 2026-11-22 the official-map rebuild with the object kit (jarmark_kit.gd: shutters, plank grooves, bulbs on every chalet, Santa's Workshop, the castle stage), 190,815 tris, still one mesh, +0 draw calls; the iPhone bench near the Palace is owed before TestFlight. Before: 2026-11-20 the finished Jarmark Warszawski 2026 (F, for the trailer), 69,003 tris: over 200 stalls, the LED tree, the 38 m tower carousel, the Venetian carousel, bulb strings over every aisle; an exception to the L3 cap, a whole 160 by 90 m market in one site, +0 draw calls (one mesh)
	"obeliski": 600,  # the two 1955 granite obelisks by the Palace and their exit hatches (F, 2026-11-15, 2026-11-17)
	"tower75": 220,
	"unique": 7000,
	"cepelia": 1100,  # 2026-11-08 photo rebuild (F): 970 tris
	"tapczan": 4700,  # 2026-11-24 THE TAPCZAN pub on Sienkiewicza 4 (F's photos): street level, carved panels, sign, pallet terrace, 7 tables, 28 chairs, 2 umbrellas, planters
	"sienkiewicza4": 5300,  # 2026-11-24 the Art Nouveau tenement on Sienkiewicza 4 (F's photos): bows, friezes, canopy, windows, rear range
	"harczyk": 6800,  # 2026-11-24 Kamienica Harczyka: chamfered corner, mansard with dormers, balconies, three fronts
	"sienkiewicza3": 3200,  # 2026-11-24 the 1950s arcade block opposite: piers, arcade, balustrade, passage
	"pijana": 2200,  # 2026-11-08 PIJANA CZEREŚNIA kiosk (F): 1806 tris (octagon, drum, painted windows, deck rail, string lights)
	"zodiak": 1500,  # 2026-11-19 neon star, string lights on three poles
	"cmarsz": 2200,
	"sowa": 1500,  # SOWA CLUB and CITY 25 (F's photos, 2026-11-06): 1298 tris
	"brama": 100,  # equator, equator2 and pepeo_tower build only their signs on their street blocks (TOWERS on_block, 2026-11-26): no budget
	"wiecha": 3700,  # 2026-11-19 night life (lit displays, awnings, kebab hatch, bulbs); 2026-11-22 the cafés' own lit bays, words and bulb strings (3,042)
	"niecala7": 13000,  # 2026-11-26 Rezydencja Opera, Niecała 7 (F): the whole block on its mapped outline, stacked round balconies, pergola; +0 draw calls. 8000 → 11500 the same day: F asked for the balconies of the photos F sent (dish bowls, posts, hoops, a stack on every arc edge), 10930 tris; 13000 for the ivy and the geranium boxes (F, 12478 tris)
	"warsztat_mirka": 3600,  # 2026-11-24 Mirek's tuning workshop on Grzybowska (F): the hall with three doors, two lifts (a hatch, a stripped shell), two supercars, the Bawarka in its oil, a stripped car, tyres, the roof car, 2,981 tris; +0 draw calls
	"wiecha_swieta": 27000,  # 2026-11-22 Pasaż Wiecha at Christmas (F's photos): 22 shooting stars on the masts, the gingerbread tunnel, the neon fir, bauble benches, two photo frames, LED curtains, 26,230 tris; +0 draw calls (one mesh)
	"orly": 1600,
	"hotel_warszawa": 2300,
	"cedet": 2300,
	"polin": 450,
	# Krakowskie Przedmieście and Plac Piłsudskiego from photos (2026-11-02)
	"czapski": 860,
	"kazimierzowski": 2200,  # 2026-11-15: + the garden front, its gable and the howitzer (F's photos)
	"smolensk": 120,
	"pilsudski": 160,
	"kaczynski": 100,
	"plac_maszty": 520,
	"plac_centralny": 700,  # 2026-11-10 the field draped on the ground (no walls)
	"trybuna": 900,  # 2026-11-08 the tribune from F's photos: 751 tris
	"plac_centralny_lamps": 3500,  # 2026-11-15: the five-globe candelabras on granite columns (F's forecourt photo)
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
	"bulwary_bary": 2800,  # 2026-11-19: five extra dark kiosks before Pawilon Tańca (2282 measured)
	"bulwary_pomosty": 1450,
	"bulwary_basen": 700,
	"schodki_wisla": 3600,  # 2026-11-19: the seating band, ~195 m (L2): ten rows, the walking stairs, boards, coping, lamps, quay
	# The boulevards, phase C (2026-11-19, specs pawilon_tanca.md, zachodni_brzezek.md, barki_bary.md).
	"pawilon_tanca": 3800,  # the white MUZEUM pavilion, bold line murals on 60-70 % of each wall, solid 3D letters on a steel frame, Palomka's terrace (Phase D, 2026-11-19; 3532 measured)
	"zachodni_brzezek": 2500,  # the grey ground floor, white letters, glass rail, the deck with palms (2016 measured)
	"barka_nowa_falka": 3700,  # the 70 m sand-deck barge with its long dark hall, one site (3060 measured)
	"barka_zanurzenie": 950,
	"barka_wirek": 700,
	"barka_kalmar": 1800,
	"barka_barkas": 950,
	"plyta_desantu": 1900,  # the three beach bars and the dock (1516 measured)
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
	"stadium": 9300,  # 2026-11-21 the Arka's level cut (SUNKEN arka_cut: cheek walls, parapets): 9052 tris; teaser 5, the stadium thread (lit stairs, rails, path lamps, the Arka): 8638 tris; F's drone photo: a lit line on every step, lit stair edges, the east gate portal: 7622 tris; F's night photos: mast-tip lamps, the rim's light line, promenade lamps, stair light lines: 5886 tris
	"swieto": 240,
	"ateneum": 5200,  # 2026-11-21 the whole Ateneum block from F's photos: L of two wings, rounded colonnaded corner, bays, attic, ATENEUM sign (measured 4973: up from 800 for the first single-wing version on purpose, the whole block is two wings and a corner)
	"lipowa1a": 900,  # 2026-11-21 copper storeys, loggias on Lipowa, solid copper end, roof terrace (from the BUW thread's version, F: "i like")
	"kladka": 8000,  # 2026-11-20 Kładka Abakanowicz from F's photos: 451 m deck, seating bays, rails, 7 supports (measured 5944)
	"wiadukt_markiewicza": 8000,  # 2026-11-20 Wiadukt Markiewicza from F's photos: the ring, two vaults, balustrades, 8 obelisks, Syrena, the group
	"szaja": 60,  # 2026-11-20 the memorial to Krzysztof "Szaya" Szaykowski (a default until F's photo)
	"teatr": 820,  # 2026-11-08 photo pass (top-50 T06): ten columns, pediment, quadriga: 705 tris
	# Plac Bankowy, Filharmonia, Teatr Polski (the Mac photo reports, 2026-11-02): fronts on kept skins.
	"ratusz": 2500,
	"gielda": 1050,
	"filharmonia": 6400,  # 2026-11-24: the Jasna front from the photos (arcade, doors, inscription, balustrade); was 1450
	"teatr_polski": 760,
	"teresy": 900,  # 2026-11-13 photo rebuild (cream plaster, round-headed windows, porch, spire)
	"flisac": 4200,  # 2026-11-13: the grid of panes, loggias and shop glass, 3,552 triangles
	"florian": 2480,
	"bazar": 2210,
	"port_praski": 25000,  # 2026-11-20: the whole Port Praski district from photos: 13 tenement blocks in sections (glass balconies from kit_balcony), Krowia 6 works, the Minter hotel (measured 24161)
	"pp_basin": 8800,  # 2026-11-20: Port Praski basin: lock, tower, pump houses, sheds, boulevard, hoardings (measured 7776)
	"kosciuszkowcy": 400,  # 2026-11-20: Pomnik Kościuszkowców from the bridge-ramp photos: the 12 m soldier with the cape, the plinth, the skaters' ledges (measured 245)
	"sw_krzyz": 1250,  # 2026-11-06 photo pass: the real flat front, balustrade and statue
	"sejm": 1400,
	"staszic": 360,
	"zamek": 24500,  # 2026-11-26 pass 3: the whole castle as one model, LoD2 gone (the named exception to L3; spec section 7)
	"zamkowy": 2900,  # 2026-11-26: + the oak's granite block bench in two tiers and railing (measured 2778)
	"mansjonaria": 2700,  # 2026-11-26: the buttressed house by the oak modelled whole (measured 2458)
	"nikidw": 2400,  # 2026-11-26: the Institute modelled whole: 12-bay two-storey arcade, wings, hipped roofs (measured 2268)
	"arkady": 2600,
	"kino_muranow": 11000,  # 2026-11-27 v2 whole complex: both 4-storey blocks, arch block, arcaded podium, square
	"zbawiciela": 3400,
	"zbawiciela_plac": 2200,
	"tarasy": 9400,  # 2026-11-11 F's photos: the triangular glass wave, the guitar, the café (5455); the whole complex: podium ledges, shop boards, Lumen's setback (7781)
	"tarasy_plaza": 2750,  # 2026-11-11: the sunken plaza by the station: walls, shopfronts, railings, treads, umbrellas (2290)
	"rondo_wells": 6000,  # 2026-11-26: Rondo Dmowskiego's twelve stairwells sunk 3.5 m: coping, railings, treads, mouths
	"trojca": 3700,  # 2026-11-14 photo rebuild: rusticated drum, arched windows, framed oculi, Doric porticoes with lunettes, dormers, glazed lantern (measured 3361)
	"unit": 1450,  # 2026-11-19: the Dragon Skin dress (green wall, MODERATO) and the corner café board
	"varso": 4300,  # 2026-11-15 photo rebuild (3614 tris): grey frame, louvre crown, lattice spire with dish platforms, lobby, observation box; +0 draw calls
	"varso_place": 7200,  # 2026-11-17 the office wings from F's photos (stone frame, set-back top storey, terraces, atrium): 6846 tris, +0 draw calls
	"wcf": 1400,  # 2026-11-08 F's 13 photos: the Emilii Plater portico, piers, fins, the low roof's rail (1319)
	"wszystkich": 7000,
	"wizytki": 3600,  # 2026-11-14: the whole Visitationist church replaces LoD2 (front, nave, aisles, chancel, wing, turret; measured 3248)
	"branickich": 1500,
	"archikatedra": 1100,
	"sw_anna": 7800,  # 2026-11-26: the whole church (nave, presbytery, chapels, Loreto, monastery wing) and the bell tower rebuilt from photos and the 3D views (measured 7403)
	"widok": 820,  # 2026-11-22 rebuilt from F's photos: two slabs, the core, soffit, roof plant (682 tris)
	"pzu": 900,
	"jm": 900,
	"babka": 800,  # 2026-11-15 photo pass with F's photos (637 tris): stone tower, loggia columns, mast, the 34 m block
	"wiktoria": 4500,  # 2026-11-15 photo rebuild (about 4100 tris): two white volumes, 8 and 6 floors of niche windows, glazed base; an exception to the L2 cap, one 117 by 79 m outline
	"wtt": 1900,  # 2026-11-15 photo rework (1604 tris): crown slits, the mast from its mapped foot
	"zacheta": 720,
	"zlota44": 2160,  # 1659 measured 2026-11-26 (spec budget 2200: 1401 before the 3D Tiles + Street View pass)
	"zygmunt": 320,
	# Towarowa 22 built as finished (2026-11-03): seven towers and blocks, the hall's steel frame,
	# the pavilion, the park, the drone port and the gilded crane.
	"towarowa22": 5600,  # 2026-11-16 the paving now covers the whole plot (6 base rects, no brown earth), 5329 tris
	# The Warsaw HUB's round-ended hotel tower (the photo report, 2026-11-03).
	"crowne": 2500,  # 2026-11-19 The Roof: rail, deck, lounge, pergola, festoons, sofas, trees
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
## The Szarytki's turret stands on LoD2's ridge and the Adventists' balconies hang on LoD2's wall:
## the map's mass, not the site's mesh.
## port_praski "plain": its tenement sections' walls (two triangles each) take the ordinary facade
## shader's windows on purpose (UV2.x a seed 0..1 or the typed tenement 1.x), the way a street
## block's `facade` walls do (fronts.gd _build_block): they go into the same building surface, so no
## draw call of their own; any plain triangle more than that number still fails.
## dom_chlopa "plain": the one wall quad (works.gd _dch_fill_front) over its south-west front, the same way.
const KNOWN := {"jarmark": {"zfight": 1235, "float": 777}, "lipowa1a": {"zfight": 2}, "port_praski": {"plain": 750}, "dom_chlopa": {"plain": 2}, "towarowa22": {"float": 8}, "szarytki": {"float": 16}, "adwentysci": {"float": 17}, "tr": {"zfight": 8}, "palace": {"zfight": 101}}  # lipowa1a: 2 coplanar triangles where two cornice slabs meet at the base corners (12 m up, never seen); jarmark: coplanar panels on the chalets' fronts about 1 m up (1235, sampled in rows R3 and R4; not yet traced) and the bulbs hung on strings over the aisles (777, they hang by design); tr: 8 coplanar triangles in crane 1's A-frame legs at 36 m, not found (hidden in a lattice, never seen); palace: 101 coplanar triangles at 17-18 m where the wings' walls and cornices meet the base cornice (inside the stone, not seen in the close-ups; the steps and colonnade ones, 186 before, are fixed)

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
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--site="):
			only = a.trim_prefix("--site=")
	var keys: Array[String] = []
	for s: Dictionary in marks.sites:
		if not s.has("block") and not s.has("fronts"):  # city fabric, not landmarks: no budget of their own
			if only == "" or s["key"] == only:
				keys.append(s["key"])
	keys.sort()
	if only != "":
		if keys.is_empty():
			print("check_mesh_quality: no landmark site %s" % only)
			map.free()
			quit(1)
			return
		var one := MeshProbe.Recorder.new()
		marks.build(one, Rect2(), only)
		var one_found := _probe.examine(only, one)
		_judge(only, one_found)
		map.free()
		for n in notes:
			print("  note: " + n)
		if problems.is_empty():
			print("check_mesh_quality: OK (site %s)" % only)
			quit(0)
		else:
			print("check_mesh_quality: %d problems" % problems.size())
			for p in problems:
				print("  " + p)
			quit(1)
		return
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
	# Every landmark sign's word must be a row of the neon atlas (neon_signs.gd LANDMARK_WORDS):
	# a missing word draws nothing (Legia's LEGUMINA, 2026-11-01 to 2026-11-15), and a word wider
	# than the atlas is cut off (HOTEL EUROPEJSKI).
	var words := Neon.all_words()
	for sign: Array in marks.signs:
		var miss := "sign %s: not in the neon atlas (neon_signs.gd LANDMARK_WORDS)" % sign[0]
		if not words.has(sign[0]) and not problems.has(miss):
			problems.append(miss)
		var wide := "sign %s: wider than the neon atlas (neon_signs.gd ATLAS_W)" % sign[0]
		if Neon.word_width(sign[0]) + 2 * Neon.PAD > Neon.ATLAS_W and not problems.has(wide):
			problems.append(wide)
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
	if f["plain"] > int(known.get("plain", 0)):
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
