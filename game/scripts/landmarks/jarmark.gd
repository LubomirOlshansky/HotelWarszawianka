extends "res://scripts/landmarks/kladka.gd"
## Jarmark Warszawski 2026, the Christmas market at the foot of the Palace (F, 2026-11-20: "make it
## 10 over 10, like for the best trailer", by day and by night). One link of landmarks.gd's base
## chain (TD-10): it uses this file, common.gd and the facade kit, never another area. Refs (never
## shipped): /mnt/project-files/refs/jarmark-2026/ (the organiser's drone reel, the opening-day
## gallery, the Palace's own reel of the tower carousel). Spec docs/landmarks/specs/jarmark.md.
##
## The market's frame is the museum's (MSN: u along Marszałkowska to the south-south-east, v from
## Marszałkowska towards the Palace). The layout is the organiser's official site map
## (refs/jarmark-2026/official-map: jarmark.waw.pl/mapa, an oblique render with every object
## labelled), georeferenced to this frame by a ground-plane homography on seven anchors (the south
## obelisk, the two porticoes of the Palace's south wing, Metro Centrum's two glass tubes and its
## pavilion, the MSN's south-east corner): 1-5 m off on the anchors, 4-17 m left out one at a time
## (the obelisk, at the map's edge, worst). Checked against F's drone frames (2026-11-21: the
## kurant in front of the tubes, the tree and the tower behind them). Two parts:
##  - the main market on the Defilad car park (u 147-263, v -9..93), from the MSN's south lawn to
##    the access road by the south obelisk: rows of gable-roofed chalets parallel to the street,
##    facing each other across wide aisles under zig-zag strings of warm bulbs; by Marszałkowska
##    the big tree (the tree carousel: its baubles are the cars) on a round platform ringed with
##    yellow benches and a big lit snowman, the kurant (the tiered Christmas pyramid) by the metro
##    tubes, a row of yellow-roofed food stalls between them; on the Palace side the castle stage,
##    the red food-zone pavilion with its three bells, Santa's house;
##  - the Plac Centralny part (u 50-150, v 25-140): the viewing tower carousel (a 38 m rainbow LED
##    mast, the gold carrier with lit spokes and swinging chairs, the orange crown), the Venetian
##    carousel by the Palace's south wing, the teacups, double rows of chalets along the promenade.
## Everything is the city's building surface (+0 draw calls); every light is M_LAMP (its colour by
## day, glowing at night; the tree's strands M_LAMP + 0.5, green by day and blue at night). The
## bulbs over the aisles are kept out of the roof grid. The cars that park there the rest of the
## year are cleared (`parked_free`), and the trees under the market and in the rides' swing.

## The real market's object kit (shutters, flaps, plank grooves, multicolour bulbs on every chalet).
const JmKit := preload("res://scripts/landmarks/jarmark_kit.gd")

const JM_O := Vector2(-1022.4, 100.15)
const JM_AXIS := Vector2(0.3445, 0.9388)

const JM_WHITE := Color("#f2f0ea")
const JM_TRIM := Color("#2a2b2f")
const JM_ROOF := Color("#323438")
const JM_ROOF_LIGHT := Color("#d6d3cc")
const JM_RED := Color("#b0232a")
const JM_YELLOW := Color("#e9b62c")
const JM_TIMBER := Color("#6b4a2e")
const JM_FIR := Color("#25603a")
const JM_BOW := Color("#d0222c")
const JM_GLOW := Color("#cf8d4c")
const JM_BULB := Color(1.0, 0.84, 0.55)
const JM_LED := Color(0.9, 0.94, 1.0)
const JM_GOLD := Color("#e3b34a")
const JM_BLUE := Color(0.32, 0.55, 1.0)
const JM_ASPHALT := Color("#56585c")
const JM_WIRE := Color("#2b2c2f")
const JM_RAINBOW := [Color("#e8333a"), Color("#f08a24"), Color("#f2d230"), Color("#4cc35a"), Color("#2fa8e0"),
		Color("#3a5be0"), Color("#9a4ad8")]

## Hut kinds: white with black trim, white half-timbered (black frame and cross braces), red, the
## small dark food stall with a yellow roof, the big white chalet (a double stand on the map).
enum Hut { WHITE, TIMBER, RED, FOOD, BIG }

## Every chalet of the official map, [u, v, quarter (front turned from -v: 0 faces -v, 2 faces +v,
## 1 faces +u, 3 faces -u), kind (-1 mixed)], row by row (the map's domek numbers in the comments).
## Made from objects.json by a small script (refs/jarmark-2026/official-map; the scratch script
## geo.py + gen.py of 2026-11-21): each hut's box bottom through the homography, half a hut back
## from its front edge; snapped to its row's median v (a column's median u) so the rows run straight
## along the street; a map width over 46 px (two stands in one) a BIG; fronts so that rows face each
## other across the aisles. Moved off what stands there: domki 86-90 1.8 m south of the metro tube,
## 91-94 1.5 m off the vent box, 71 into its row's gap; 126 dropped (inside the tree's bench ring).
const JM_HUT_LIST := [
	# Main market, the Palace side to the street. R1 (domki 1, 3-9) behind the stage's plaza.
	[249.0, 85.5, 0, -1], [245.0, 85.5, 0, -1], [241.1, 85.5, 0, -1], [237.3, 85.5, 0, -1], [233.6, 85.5, 0, -1],
	[229.6, 85.5, 0, -1], [225.8, 85.5, 0, -1], [219.9, 85.5, 0, -1],
	# R2 (2, 10-23) facing the stage's plaza.
	[159.4, 75.0, 2, -1], [151.1, 75.0, 2, Hut.BIG], [165.3, 75.0, 2, -1], [169.2, 75.0, 2, -1],
	[173.4, 75.0, 2, -1], [177.3, 75.0, 2, -1], [181.4, 75.0, 2, -1], [185.4, 75.0, 2, -1], [196.9, 75.0, 2, -1],
	[200.8, 75.0, 2, -1], [204.8, 75.0, 2, -1], [208.5, 75.0, 2, -1], [212.2, 75.0, 2, -1], [216.1, 75.0, 2, -1],
	[221.6, 75.0, 2, -1],
	# R3 (25-43, 186-187) and R4 (45-60) face each other; R3b (24) faces R1 beside Santa's house.
	[249.6, 67.0, 0, -1], [245.6, 67.0, 0, -1], [241.7, 67.0, 0, -1], [237.8, 67.0, 0, -1], [234.1, 67.0, 0, -1],
	[230.0, 67.0, 0, -1], [216.3, 67.0, 0, -1], [211.9, 67.0, 0, -1], [206.6, 67.0, 0, Hut.BIG],
	[201.4, 67.0, 0, -1], [197.1, 67.0, 0, -1], [193.7, 67.0, 0, -1], [188.1, 67.0, 0, -1], [184.4, 67.0, 0, -1],
	[179.3, 67.0, 0, -1], [174.9, 67.0, 0, -1], [170.2, 67.0, 0, -1], [165.7, 67.0, 0, -1], [148.9, 67.0, 0, -1],
	[152.4, 67.0, 0, -1],
	[237.8, 72.0, 2, Hut.BIG],
	[165.8, 53.5, 2, -1], [170.7, 53.5, 2, -1], [175.1, 53.5, 2, -1], [181.3, 53.5, 2, Hut.BIG],
	[186.5, 53.5, 2, -1], [197.0, 53.5, 2, Hut.BIG], [201.6, 53.5, 2, -1], [205.7, 53.5, 2, -1],
	[209.6, 53.5, 2, -1], [222.9, 53.5, 2, -1], [227.2, 53.5, 2, -1], [232.8, 53.5, 2, Hut.BIG],
	[239.8, 53.5, 2, Hut.BIG], [248.9, 53.5, 2, Hut.BIG],
	# R5 (30a, 61-78) and R6 (79-85, 85a-d, 69).
	[162.1, 46.5, 0, -1], [225.8, 46.5, 0, -1], [222.3, 46.5, 0, -1], [217.0, 46.5, 0, -1], [213.4, 46.5, 0, -1],
	[209.4, 46.5, 0, -1], [204.4, 46.5, 0, Hut.BIG], [199.4, 46.5, 0, -1], [194.2, 46.5, 0, -1],
	[190.8, 46.5, 0, -1], [187.3, 46.5, 0, -1], [182.1, 46.5, 0, Hut.BIG], [177.1, 46.5, 0, -1],
	[173.4, 46.5, 0, -1], [169.6, 46.5, 0, -1], [165.5, 46.5, 0, -1],
	[167.3, 33.0, 2, -1], [171.3, 33.0, 2, -1], [176.5, 33.0, 2, Hut.BIG], [181.3, 33.0, 2, -1],
	[185.6, 33.0, 2, -1], [189.2, 33.0, 2, -1],
	[203.2, 35.5, 2, -1], [208.5, 35.5, 2, -1], [221.7, 35.5, 2, -1], [225.7, 35.5, 2, -1], [229.0, 35.5, 2, -1],
	# R7 (95-96), R8 (97-100), R8b (91-94), R8c (86-90) and R9 (101-102) round the tree's north aisle.
	[195.3, 28.5, 0, -1], [189.6, 28.5, 0, -1],
	[179.2, 25.0, 0, -1], [174.8, 25.0, 0, -1], [170.5, 25.0, 0, -1], [165.9, 25.0, 0, -1],
	[209.2, 22.0, 0, Hut.BIG], [203.8, 22.0, 0, -1], [198.3, 22.0, 0, Hut.BIG],
	[245.5, 21.5, 0, -1], [241.8, 21.5, 0, -1], [237.8, 21.5, 0, -1], [233.9, 21.5, 0, -1], [230.5, 21.5, 0, -1],
	[174.8, 16.5, 2, -1], [179.2, 16.5, 2, -1],
	# The yellow-roofed food stalls between the tree and the kurant: R10 (123-125), R11 (127-129), 122.
	[220.3, 11.0, 2, Hut.FOOD], [215.1, 11.0, 2, Hut.FOOD], [210.4, 11.0, 2, Hut.FOOD],
	[210.3, 6.5, 0, Hut.FOOD], [215.4, 6.5, 0, Hut.FOOD], [220.2, 6.5, 0, Hut.FOOD],
	[230.1, 5.0, 0, Hut.FOOD],
	# The two short columns: C1 (103-105) facing the tree, C2 (119-121) facing the kurant.
	[182.0, 12.4, 1, -1], [182.0, 7.4, 1, -1], [182.0, 2.6, 1, -1],
	[255.0, 1.8, 3, -1], [255.0, 7.5, 3, -1], [255.0, 10.9, 3, -1],
	# R12 (106-118): the row along the street fence, facing in.
	[185.7, -5.0, 2, -1], [190.2, -5.0, 2, -1], [195.0, -5.0, 2, -1], [199.5, -5.0, 2, -1], [204.8, -5.0, 2, -1],
	[216.4, -5.0, 2, -1], [221.1, -5.0, 2, -1], [235.0, -5.0, 2, -1], [230.8, -5.0, 2, -1], [239.2, -5.0, 2, -1],
	[243.2, -5.0, 2, -1], [246.8, -5.0, 2, -1], [251.3, -5.0, 2, -1],
	# Plac Centralny: P1 (130-134, 139, 182-183) and P2 (135-141) by the Venetian carousel.
	[115.4, 133.0, 0, -1], [110.4, 133.0, 0, -1], [105.4, 133.0, 0, -1], [94.7, 133.0, 0, -1],
	[99.8, 133.0, 0, -1], [79.9, 133.0, 0, -1], [74.2, 133.0, 0, -1],
	[126.6, 117.0, 2, -1], [121.8, 117.0, 2, -1], [111.7, 117.0, 2, -1], [106.8, 117.0, 2, -1],
	[102.1, 117.0, 2, -1], [96.6, 117.0, 2, -1],
	# The promenade: PC1 (164-172) and PC2 (173-181) back to back, PC3 (142-147) facing PC2.
	[82.0, 49.5, 3, -1], [82.0, 55.6, 3, -1], [82.0, 62.1, 3, -1], [82.0, 68.2, 3, -1], [82.0, 74.6, 3, -1],
	[82.0, 81.2, 3, -1], [82.0, 88.1, 3, -1], [82.0, 94.8, 3, -1],
	[86.5, 49.2, 1, -1], [86.5, 55.4, 1, -1], [86.5, 61.8, 1, -1], [86.5, 68.1, 1, -1], [86.5, 74.5, 1, -1],
	[86.5, 81.0, 1, -1], [86.5, 87.7, 1, -1], [86.5, 94.6, 1, -1],
	[94.5, 75.1, 3, -1], [94.5, 69.4, 3, -1], [94.5, 63.5, 3, -1], [94.5, 57.7, 3, -1], [94.5, 52.2, 3, -1],
	[94.5, 46.3, 3, -1],
	# P3 (148-151) facing the teacups; P4 (158-163) and P5 (152-157) back to back along the museum's
	# south wall (F's photos on site, 2026-11-22: the rows stand beside the wall, a planted walk between;
	# moved 12 m along and 3 m in from the map's spot).
	[99.3, 44.0, 0, -1], [104.3, 44.0, 0, -1], [108.4, 44.0, 0, -1], [113.4, 44.0, 0, -1],
	[41.3, 39.5, 2, -1], [46.1, 39.5, 2, -1], [51.1, 39.5, 2, -1], [55.9, 39.5, 2, -1], [60.9, 39.5, 2, -1],
	[65.8, 39.5, 2, -1],
	[64.8, 35.0, 0, -1], [60.3, 35.0, 0, -1], [55.6, 35.0, 0, -1], [50.7, 35.0, 0, -1], [45.8, 35.0, 0, -1],
	[40.8, 35.0, 0, -1],
]

## Every other object of the official map at its georeferenced spot (u, v): the box's bottom through
## the homography, a ride's radius back. Placeholder anchors for the kit's new models
## (landmarks/jarmark_kit.gd wires them: the kurant, the tree carousel, the castle stage, the food
## zone, the fun house, the bars, the photo booths...) and the source for the constants below.
const JM_PLAN := {
	"wejscie-01": Vector2(176.8, -8.4), "wejscie-02": Vector2(226.2, -5.6), "wejscie-03": Vector2(271.0, -9.4),
	"wejscie-04": Vector2(161.4, 16.3), "wejscie-05": Vector2(161.1, 38.8), "wejscie-06": Vector2(91.6, 23.9),
	"wejscie-07": Vector2(270.2, 29.4), "wejscie-08": Vector2(267.6, 73.0), "wejscie-09": Vector2(136.2, 95.7),
	"wejscie-10": Vector2(86.4, 133.6), "metro-1": Vector2(226.5, 20.3), "metro-3": Vector2(142.4, -24.3),
	"metro-2": Vector2(227.5, -21.4), "p2-l": Vector2(170.5, 86.7), "kontenery-na-odpady": Vector2(239.4, 88.8),
	"wino-1": Vector2(177.6, 87.3), "strefa-gastronomiczna": Vector2(193.0, 89.2), "bar-1": Vector2(158.9, 67.8),
	"p1-k": Vector2(205.6, 87.9), "kiosk-k1": Vector2(214.4, 86.3), "wino-4": Vector2(141.4, 44.6),
	"wino-5": Vector2(151.3, 44.2), "bar-2": Vector2(225.2, 64.3), "wino-3": Vector2(216.1, 51.6),
	"wino-2": Vector2(264.5, 64.4), "bar-4": Vector2(186.1, 23.2), "kiosk-k2": Vector2(265.1, 53.1),
	"wino-6": Vector2(216.7, 21.5), "bar-3": Vector2(265.3, 41.3), "plac-zabaw": Vector2(48.6, 129.5),
	"trybuna": Vector2(79.9, 100.8), "karuzela-wenecka": Vector2(134.8, 124.4),
	"namiot-piernikowy": Vector2(120.0, 84.2), "fotel-mikolaja-zet": Vector2(135.5, 83.9),
	"koszykowka-2": Vector2(152.4, 87.7), "koszykowka-1": Vector2(160.9, 87.2),
	"labirynt-swiateczny": Vector2(118.1, 63.9), "karuzela-widokowa": Vector2(137.7, 63.2),
	"sciana-murali": Vector2(130.3, 46.1), "karuzela-filizanki": Vector2(101.3, 25.8),
	"carnival-2": Vector2(226.2, 72.2), "carnival-1": Vector2(231.9, 71.9), "budka-telefoniczna": Vector2(250.0, 70.9),
	"carnival-3": Vector2(199.2, 32.4), "automaty-pluszaki": Vector2(216.4, 30.2),
	"karuzela-choinka": Vector2(198.6, 9.8), "carnival-4": Vector2(210.5, -5.7), "kurant": Vector2(243.4, 7.2),
	"fotobudka-1": Vector2(60.0, 135.2), "fotobudka-2": Vector2(129.8, 99.8), "bankomat-1": Vector2(129.4, 98.3),
	"fotobudka-3": Vector2(146.2, 73.6), "fotobudka-6": Vector2(118.9, 44.9), "medycyna": Vector2(229.6, 44.8),
	"dla-pracownikow-2": Vector2(234.9, 44.1), "ochrona": Vector2(232.0, 41.5),
	"serwis-sprzatajacy": Vector2(235.5, 40.8), "punkt-m": Vector2(164.9, 8.6), "wc-damskie-2": Vector2(239.3, 40.8),
	"wc-damskie-1": Vector2(241.8, 40.5), "wc-meskie-2": Vector2(245.2, 40.6), "wc-meskie-1": Vector2(247.9, 40.3),
	"dla-pracownikow": Vector2(250.6, 40.2), "tech-supp": Vector2(166.0, -0.4), "biuro": Vector2(175.8, -0.0),
	"fotobudka-5": Vector2(264.1, 36.7), "bankomat-2": Vector2(264.1, 34.5), "fotobudka-4": Vector2(223.6, 12.2),
	"bankomat-3": Vector2(223.5, 5.7), "domek-mikolaja": Vector2(246.6, 70.8),
}

## Every placed object of the market by name (gen_anchors.py, 2026-11-21): [kit builder, u, v, quarter, arg].
## The official map's labelled objects (JM_PLAN), its unlabelled decorations read by eye (+-2 m) and the
## photo details F asked for. An empty builder is a reference point or a thing jarmark.gd builds itself;
## "led_figure_hung" is led_figure 5 m up. `_jm_kit_objects` builds each one whose builder the kit has.
const JM_ANCHORS := {
	"wejscie-01": ["entrance_board", 176.8, -8.4, 0, null],
	"wejscie-02": ["entrance_board", 226.2, -5.6, 0, null],
	"wejscie-03": ["entrance_board", 271.0, -9.4, 0, null],
	"wejscie-04": ["entrance_board", 161.4, 16.3, 0, null],
	"wejscie-05": ["entrance_board", 161.1, 38.8, 0, null],
	"wejscie-06": ["entrance_board", 91.6, 23.9, 3, null],
	"wejscie-07": ["entrance_board", 270.2, 29.4, 1, null],
	"wejscie-08": ["entrance_board", 267.6, 73.0, 1, null],
	"wejscie-09": ["entrance_board", 136.2, 95.7, 2, null],
	"wejscie-10": ["entrance_board", 86.4, 133.6, 2, null],
	"metro-1": ["", 226.5, 20.3, 0, null],
	"metro-3": ["", 142.4, -24.3, 0, null],
	"metro-2": ["", 227.5, -21.4, 0, null],
	"p2-l": ["pavilion_p2l", 170.5, 86.7, 0, null],
	"kontenery-na-odpady": ["bins", 239.4, 88.8, 0, 1],
	"wino-1": ["container", 177.6, 87.3, 0, 0],
	"strefa-gastronomiczna": ["", 193.0, 89.2, 0, null],
	"bar-1": ["", 158.9, 67.8, 0, null],
	"p1-k": ["", 205.6, 87.9, 0, null],
	"kiosk-k1": ["kiosk_k1", 214.4, 86.3, 0, null],
	"wino-4": ["container", 141.4, 44.6, 0, 0],
	"wino-5": ["container", 151.3, 44.2, 0, 0],
	"bar-2": ["", 225.2, 64.3, 0, null],
	"wino-3": ["container", 216.1, 51.6, 0, 0],
	"wino-2": ["container", 264.5, 64.4, 0, 0],
	"bar-4": ["", 186.1, 23.2, 0, null],
	"kiosk-k2": ["container", 265.1, 53.1, 0, 2],
	"wino-6": ["container", 216.7, 21.5, 0, 0],
	"bar-3": ["container", 265.3, 41.3, 0, 1],
	"plac-zabaw": ["fun_house", 48.6, 129.5, 0, null],
	"trybuna": ["stand", 79.9, 100.8, 0, null],
	"karuzela-wenecka": ["", 134.8, 124.4, 0, null],
	"namiot-piernikowy": ["gingerbread_tent", 120.0, 84.2, 0, null],
	"fotel-mikolaja-zet": ["santa_chair", 135.5, 83.9, 0, null],
	"koszykowka-2": ["basketball", 152.4, 87.7, 0, null],
	"koszykowka-1": ["basketball", 160.9, 87.2, 0, null],
	"labirynt-swiateczny": ["maze", 118.1, 63.9, 0, null],
	"karuzela-widokowa": ["", 137.7, 63.2, 0, null],
	"sciana-murali": ["mural_wall", 130.3, 46.1, 0, null],
	"karuzela-filizanki": ["", 101.3, 25.8, 0, null],
	"carnival-2": ["carnival", 226.2, 72.2, 0, null],
	"carnival-1": ["carnival", 231.9, 71.9, 0, null],
	"budka-telefoniczna": ["booth", 250.0, 70.9, 0, 1],
	"carnival-3": ["carnival", 199.2, 32.4, 0, null],
	"automaty-pluszaki": ["claw_machines", 216.4, 30.2, 0, null],
	"karuzela-choinka": ["", 198.6, 9.8, 0, null],
	"carnival-4": ["carnival", 210.5, -5.7, 0, null],
	"kurant": ["", 243.4, 7.2, 0, null],
	"fotobudka-1": ["photo_booth", 60.0, 135.2, 0, null],
	"fotobudka-2": ["photo_booth", 129.8, 99.8, 0, null],
	"bankomat-1": ["cash_machine", 129.4, 98.3, 0, null],
	"fotobudka-3": ["photo_booth", 146.2, 73.6, 0, null],
	"fotobudka-6": ["photo_booth", 118.9, 44.9, 0, null],
	"medycyna": ["cabin", 229.6, 44.8, 0, 2],
	"dla-pracownikow-2": ["cabin", 234.9, 44.1, 0, 1],
	"ochrona": ["cabin", 232.0, 41.5, 0, 3],
	"serwis-sprzatajacy": ["cabin", 235.5, 40.8, 0, 1],
	"punkt-m": ["cabin", 164.9, 8.6, 0, 5],
	"wc-damskie-2": ["cabin", 239.3, 40.8, 0, 0],
	"wc-damskie-1": ["cabin", 241.8, 40.5, 0, 0],
	"wc-meskie-2": ["cabin", 245.2, 40.6, 0, 0],
	"wc-meskie-1": ["cabin", 247.9, 40.3, 0, 0],
	"dla-pracownikow": ["cabin", 250.6, 40.2, 0, 1],
	"tech-supp": ["cabin", 166.0, -0.4, 0, 4],
	"biuro": ["cabin", 175.8, -0.0, 0, 4],
	"fotobudka-5": ["photo_booth", 264.1, 36.7, 0, null],
	"bankomat-2": ["cash_machine", 264.1, 34.5, 0, null],
	"fotobudka-4": ["photo_booth", 223.6, 12.2, 0, null],
	"bankomat-3": ["cash_machine", 223.5, 5.7, 0, null],
	"domek-mikolaja": ["", 246.6, 70.8, 0, null],
	"light-arch-1": ["light_arch", 95.8, 8.2, 0, null],
	"light-arch-2": ["light_arch", 96.0, -1.0, 0, null],
	"light-arch-3": ["light_arch", 96.3, -8.3, 0, null],
	"light-arch-4": ["light_arch", 96.7, -16.1, 0, null],
	"light-arch-west": ["light_arch", 260.0, 99.8, 0, null],
	"ornament-ball-1": ["ornament_ball", 207.5, 31.7, 0, null],
	"ornament-ball-2": ["ornament_ball", 244.2, -16.2, 0, null],
	"ornament-ball-3": ["ornament_ball", 102.2, 62.9, 0, null],
	"reindeer-1": ["reindeer", 25.9, 131.7, 0, null],
	"reindeer-2": ["reindeer", 68.7, -2.4, 0, null],
	"reindeer-3": ["reindeer", 103.6, 105.4, 0, null],
	"gift-box-1": ["gift_box", 14.0, 124.1, 0, null],
	"gift-box-2": ["gift_box", 82.1, 2.6, 0, null],
	"sleigh-scene": ["sleigh_scene", 263.6, 84.8, 0, null],
	"palace-corner-tree-1": ["palace_corner_tree", 20.5, 125.1, 0, null],
	"palace-corner-tree-2": ["palace_corner_tree", 100.8, 96.8, 0, null],
	"lit-tree-plaza": ["palace_corner_tree", 74.9, -0.8, 0, null],
	"lit-tree-lawn-1": ["palace_corner_tree", 253.7, 67.8, 0, null],
	"lit-tree-lawn-2": ["palace_corner_tree", 253.8, 48.5, 0, null],
	"lit-tree-lawn-3": ["palace_corner_tree", 258.7, 25.7, 0, null],
	"lit-tree-lawn-4": ["palace_corner_tree", 158.1, -11.5, 0, null],
	"lit-tree-lawn-5": ["palace_corner_tree", 64.7, 105.6, 0, null],
	"lit-tree-lawn-6": ["palace_corner_tree", 84.3, 105.2, 0, null],
	"wesolych-swiat-south": ["wesolych_swiat_sign", 257.0, 66.0, 1, null],
	"grzaniec-south": ["grzaniec_booth", 260.6, 61.0, 1, null],
	"led-tree-arch-south": ["led_tree_arch", 257.5, 50.0, 1, null],
	"grzaniec-kurant": ["grzaniec_booth", 234.5, 7.2, 3, null],
	"hanging-fir-1-1": ["led_figure_hung", 229.8, 80.4, 0, 0],
	"led-fir-1-1a": ["led_figure", 229.8, 78.1, 2, 0],
	"led-fir-1-1b": ["led_figure", 229.8, 82.7, 0, 0],
	"hanging-fir-1-2": ["led_figure_hung", 241.2, 80.4, 0, 0],
	"hanging-fir-2-1": ["led_figure_hung", 159.2, 79.4, 0, 0],
	"led-fir-2-1a": ["led_figure", 159.2, 78.0, 2, 0],
	"led-fir-2-1b": ["led_figure", 159.2, 80.8, 0, 0],
	"hanging-fir-2-2": ["led_figure_hung", 169.5, 79.4, 0, 0],
	"hanging-fir-2-3": ["led_figure_hung", 179.8, 79.4, 0, 0],
	"led-angel-2-3a": ["led_figure", 179.8, 78.0, 2, 1],
	"led-angel-2-3b": ["led_figure", 179.8, 80.8, 0, 1],
	"hanging-fir-2-4": ["led_figure_hung", 190.2, 79.4, 0, 0],
	"hanging-fir-2-5": ["led_figure_hung", 200.5, 79.4, 0, 0],
	"led-fir-2-5a": ["led_figure", 200.5, 78.0, 2, 0],
	"led-fir-2-5b": ["led_figure", 200.5, 80.8, 0, 0],
	"hanging-fir-2-6": ["led_figure_hung", 210.8, 79.4, 0, 0],
	"hanging-fir-3-1": ["led_figure_hung", 158.9, 60.3, 0, 0],
	"led-fir-3-1a": ["led_figure", 158.9, 56.5, 2, 0],
	"led-fir-3-1b": ["led_figure", 158.9, 64.1, 0, 0],
	"hanging-fir-3-2": ["led_figure_hung", 170.6, 60.3, 0, 0],
	"hanging-fir-3-3": ["led_figure_hung", 182.4, 60.3, 0, 0],
	"led-angel-3-3a": ["led_figure", 182.4, 56.5, 2, 1],
	"led-angel-3-3b": ["led_figure", 182.4, 64.1, 0, 1],
	"hanging-fir-3-4": ["led_figure_hung", 194.1, 60.3, 0, 0],
	"hanging-fir-3-5": ["led_figure_hung", 205.9, 60.3, 0, 0],
	"led-fir-3-5a": ["led_figure", 205.9, 56.5, 2, 0],
	"led-fir-3-5b": ["led_figure", 205.9, 64.1, 0, 0],
	"hanging-fir-3-6": ["led_figure_hung", 217.6, 60.3, 0, 0],
	"hanging-fir-3-7": ["led_figure_hung", 229.4, 60.3, 0, 0],
	"led-angel-3-7a": ["led_figure", 229.4, 56.5, 2, 1],
	"led-angel-3-7b": ["led_figure", 229.4, 64.1, 0, 1],
	"hanging-fir-3-8": ["led_figure_hung", 241.1, 60.3, 0, 0],
	"hanging-fir-4-1": ["led_figure_hung", 171.2, 39.8, 0, 0],
	"led-fir-4-1a": ["led_figure", 171.2, 35.9, 2, 0],
	"led-fir-4-1b": ["led_figure", 171.2, 43.7, 0, 0],
	"hanging-fir-4-2": ["led_figure_hung", 181.8, 39.8, 0, 0],
	"hanging-fir-5-1": ["led_figure_hung", 209.0, 41.1, 0, 0],
	"led-fir-5-1a": ["led_figure", 209.0, 38.5, 2, 0],
	"led-fir-5-1b": ["led_figure", 209.0, 43.7, 0, 0],
	"hanging-fir-5-2": ["led_figure_hung", 221.0, 41.1, 0, 0],
	"hanging-fir-6-1": ["led_figure_hung", 172.5, 20.6, 0, 0],
	"led-fir-6-1a": ["led_figure", 172.5, 19.1, 2, 0],
	"led-fir-6-1b": ["led_figure", 172.5, 22.1, 0, 0],
	"hanging-fir-6-2": ["led_figure_hung", 179.5, 20.6, 0, 0],
	"hanging-fir-7-1": ["led_figure_hung", 216.2, 15.1, 0, 0],
	"led-fir-7-1a": ["led_figure", 216.2, 13.7, 2, 0],
	"led-fir-7-1b": ["led_figure", 216.2, 16.5, 0, 0],
	"hanging-fir-7-2": ["led_figure_hung", 224.8, 15.1, 0, 0],
	"hanging-fir-8-1": ["led_figure_hung", 103.2, 125.0, 0, 0],
	"led-fir-8-1a": ["led_figure", 103.2, 119.9, 2, 0],
	"led-fir-8-1b": ["led_figure", 103.2, 130.1, 0, 0],
	"hanging-fir-8-2": ["led_figure_hung", 111.5, 125.0, 0, 0],
	"hanging-fir-8-3": ["led_figure_hung", 119.8, 125.0, 0, 0],
	"led-angel-8-3a": ["led_figure", 119.8, 119.9, 2, 1],
	"led-angel-8-3b": ["led_figure", 119.8, 130.1, 0, 1],
	"hanging-fir-9-1": ["led_figure_hung", 61.5, 33.2, 0, 0],
	"led-fir-9-1a": ["led_figure", 61.5, 31.3, 2, 0],
	"led-fir-9-1b": ["led_figure", 61.5, 35.1, 0, 0],
	"hanging-fir-9-2": ["led_figure_hung", 72.5, 33.2, 0, 0],
	"hanging-fir-9-3": ["led_figure_hung", 83.5, 33.2, 0, 0],
	"led-angel-9-3a": ["led_figure", 83.5, 31.3, 2, 1],
	"led-angel-9-3b": ["led_figure", 83.5, 35.1, 0, 1],
}

## The rides and the big pieces (from JM_PLAN, nudged where the map's 1-5 m error put them on huts).
const JM_TREE := Vector2(197.0, 9.5)
const JM_CAROUSEL := Vector2(134.8, 124.4)
const JM_TOWER := Vector2(137.7, 63.2)
## The teacups stand 3 m along and 2 m in from the map's spot (101.3, 25.8): there the ride's platform
## and the WESOŁYCH ŚWIĄT sign's rail left a 3.6 m funnel where a car crossing the plaza got pinned
## for a minute (Autopilot PT-60, 2026-11-26); now the gap is about 7 m.
const JM_TEACUPS := Vector2(104.3, 27.8)
## The tree is the tree carousel (the map's karuzela-choinka): its bauble cars go round its foot.
const JM_TREE_RIDE := JM_TREE
const JM_SANTA := Vector2(246.6, 71.5)
## The kurant, the tiered Christmas pyramid (pyramid-real.png, the drone's frames): until the kit's
## model stands here, the red hexagonal bar is its stand-in.
const JM_KURANT := Vector2(243.4, 7.2)
const JM_HEXBAR := JM_KURANT
## The south gate's sign and GRZANIEC booth (F's drone img4); the LED hat stands 16 m towards the
## street from it. Strings and figures keep clear of both.
const JM_SOUTH_GATE := Vector2(258.5, 66.0)
## The castle stage (the map's p1-k, Zamek Krakus) and the red food-zone pavilion beside it.
const JM_STAGE := Vector2(205.6, 88.0)
const JM_FOODZONE := Vector2(192.5, 88.5)
## The mast the drone frame shows strings fanning from, between the tree and the kurant.
const JM_FAN := Vector2(214.0, 1.6)
## The main market's part of the crowds (crowds.gd: 0 from here on along u, 1 Plac Centralny).
const JM_SPLIT_U := 147.0

## The strings of bulbs zig-zagging over the aisles: [u0, u1, v_a, v_b, step along u] (v_a, v_b the
## two rows' fronts).
const JM_STRINGS := [[221.0, 250.0, 76.8, 84.0, 5.0], [151.0, 219.0, 76.8, 82.0, 6.0],
		[150.0, 250.0, 55.2, 65.4, 6.0], [163.0, 190.0, 34.6, 45.0, 6.0], [200.0, 230.0, 37.2, 45.0, 6.0],
		[166.0, 186.0, 17.8, 23.4, 5.0], [209.0, 232.0, 12.4, 17.8, 5.0], [96.0, 127.0, 118.6, 131.4, 6.0],
		[41.0, 80.0, 23.0, 33.4, 6.0]]
## Straight strings along v down the cross aisles: [u, v0, v1].
const JM_LINES := [[158.0, 0.0, 60.0], [259.0, -3.0, 80.0], [90.5, 46.0, 95.0]]

## The market's ground: the car park's asphalt under the main market (over its lawn islands).
const JM_PAVED := [[147.0, 263.0, -9.5, 93.0]]
## Kept clear of parked cars besides JM_PAVED: the Plac Centralny part, [u0, u1, v0, v1] (its chalets, rides
## and kit objects span u 14-147, v -24-135; v from -9.5 so Marszałkowska's own parking lane stays).
const JM_PARK_FREE := [[10.0, 147.0, -9.5, 140.0]]
## The car park's old bay lines that still show in the aisles (v).
const JM_BAYS := [17.0, 40.0, 60.0]
const JM_LIFT := 0.28
## The tower carousel's carrier at its top (metres over the ground); jarmark_rides.gd runs it down to the base.
const TOWER_TOP := 26.0
## How far the carrier comes down to load: the chairs (6 m under it) stop just over the base.
const TOWER_DROP := 18.9
## The riders' coats (the reels: dark winter coats, a few bright ones).
const JM_SHIRTS := [Color("#2c3440"), Color("#7a1f26"), Color("#e7e2d6"), Color("#344a2e"), Color("#1c1d22"),
		Color("#c25a2a"), Color("#4a5a8a"), Color("#8a7a62")]


## The quit fix: the sector this builds in is told to stop (map_builder.gd `cancel_build`; the game
## quits while the streamer's worker builds it). Read by name: some tools build on a stand-in map.
func _quit_stop() -> bool:
	return map.get(&"cancel_build") == true and map.get(&"_in_sector") == true


func _jm_frame() -> void:
	_o = JM_O
	_a = JM_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)


func _jm_p(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, y, p.y)


func _jm_bar(u0: float, v0: float, y0: float, u1: float, v1: float, y1: float, w: float, col: Color, mode := M_STONE) -> void:
	_beam(_jm_p(u0, v0, y0), _jm_p(u1, v1, y1), w, col, true, mode)


func _jm_ground(u: float, v: float) -> float:
	var p := _w(u, v)
	return map.terrain_height(p.x, p.y)


## Turn the frame to a spot: origin at local (u, v) of the market, the front `quarter` turns from -v.
func _jm_at(u: float, v: float, quarter: int) -> float:
	_jm_frame()
	var pos := _w(u, v)
	_o = pos
	for q in posmod(quarter, 4):
		_a = Vector2(-_a.y, _a.x)
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(pos.x, pos.y)
	return _g


## Every hut: [u, v, quarter, kind, n], JM_HUT_LIST with the mixed kinds dealt (white, half-timbered,
## a red one in seven).
static func _jm_huts() -> Array:
	var out: Array = []
	var n := 0
	for h: Array in JM_HUT_LIST:
		var kind: int = h[3]
		if kind < 0:
			kind = Hut.RED if n % 7 == 3 else (Hut.TIMBER if n % 3 == 0 else Hut.WHITE)
		out.append([float(h[0]), float(h[1]), int(h[2]), kind, n])
		n += 1
	return out


## A market point (u, v) in the world plan, without the instance frame (crowds.gd's plan).
static func _jm_world(u: float, v: float) -> Vector2:
	var a := JM_AXIS.normalized()
	return JM_O + a * u + Vector2(-a.y, a.x) * v


## How far over the terrain the market's ground is at a world point: the asphalt's JM_LIFT on the
## paved parts (over the lawns' own lift), 0 elsewhere (crowds.gd stands the shoppers on it).
static func jarmark_lift(p: Vector2) -> float:
	var a := JM_AXIS.normalized()
	var d := p - JM_O
	var u := d.dot(a)
	var v := d.dot(Vector2(-a.y, a.x))
	for r: Array in JM_PAVED:
		if u >= float(r[0]) and u <= float(r[1]) and v >= float(r[2]) and v <= float(r[3]):
			return JM_LIFT
	return 0.0


## Where the market's shoppers stand (crowds.gd, kind `jarmark`): [plan point, the way they face,
## part (0 the main market, 1 the annex and Plac Centralny)]. Two at most counters, looking at the
## goods; a ring round the tree; queues at the carousel, the tower and the teacups; a few in the
## aisles looking about. Deterministic, so both city paths and every run agree.
static func jarmark_plan() -> Array:
	var out: Array = []
	var a := JM_AXIS.normalized()
	var b := Vector2(-a.y, a.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for h: Array in _jm_huts():
		var au := a
		for q in int(h[2]):
			au = Vector2(-au.y, au.x)
		var bv := Vector2(-au.y, au.x)
		var hv := 1.0 if h[3] == Hut.FOOD else 1.15
		var c := _jm_world(h[0], h[1])
		var part := 0 if float(h[0]) >= JM_SPLIT_U else 1
		for k in [0, 1, 2, 3]:
			if k == 3 and int(h[4]) % 2 != 0:
				continue
			var off := rng.randf_range(-1.3, 1.3)
			var p: Vector2 = c - bv * (hv + rng.randf_range(0.75, 1.3)) + au * off
			out.append([p, bv.rotated(rng.randf_range(-0.4, 0.4)), part])
	for k in 26:
		var t := TAU * (float(k) + rng.randf()) / 26.0
		var d := (a * cos(t) + b * sin(t))
		out.append([_jm_world(JM_TREE.x, JM_TREE.y) + d * rng.randf_range(8.3, 11.0), -d, 0])
	for ride: Array in [[JM_CAROUSEL, 7.5, 18, 1], [JM_TOWER, 6.0, 16, 1], [JM_TEACUPS, 6.8, 10, 1], [JM_TREE_RIDE, 8.0, 9, 0]]:
		var rc: Vector2 = ride[0]
		for k in int(ride[2]):
			var t := -PI * 0.5 + rng.randf_range(-1.2, 1.2)
			var d := (a * cos(t) + b * sin(t))
			out.append([_jm_world(rc.x, rc.y) + d * (float(ride[1]) + rng.randf_range(0.0, 2.5)), -d, ride[3]])
	for s: Array in JM_STRINGS:
		var u := float(s[0]) + 2.0
		while u < float(s[1]) - 2.0:
			# To one side of the aisle (the strollers of jarmark_life.gd keep to its middle).
			var f := rng.randf_range(0.28, 0.36)
			var v := lerpf(float(s[2]), float(s[3]), f if rng.randf() < 0.5 else 1.0 - f)
			var t := rng.randf() * TAU
			var at := _jm_world(u, v)
			var part := 0 if u >= JM_SPLIT_U else 1
			out.append([at, Vector2(cos(t), sin(t)), part])
			# Half the time a friend: two who stopped to talk, face to face.
			if rng.randf() < 0.5:
				var d := Vector2(cos(t), sin(t))
				out.append([at + d * 0.8, -d, part])
			u += rng.randf_range(2.2, 4.5)
	return out


func _find_jarmark() -> void:
	_jm_frame()
	var zones: Array = []
	for h: Array in _jm_huts():
		var big := 2.8 if h[3] == Hut.BIG else 1.9
		zones.append(_rect(h[0], h[1], big, big))
	for c: Vector2 in [JM_TREE, JM_CAROUSEL, JM_TOWER, JM_TEACUPS, JM_SANTA, JM_KURANT, JM_STAGE, JM_FOODZONE]:
		zones.append(_rect(c.x, c.y, 4.0, 4.0))
	_add_site("jarmark", zones)
	# The cars that park on Plac Defilad the rest of the year, and the trees in the rides' way.
	for p: Array in JM_PAVED:
		var ring := _urect(p[0], p[1], p[2], p[3])
		parked_free.append([ring, _box_of([ring])])
		tree_free.append([ring, 0.0, _box_of([ring])])
	# The Plac Centralny part too (F 2026-11-23, Play 14: "cars parked right in the market by the
	# swings"): its rides, the Workshop and the chalets by the museum stand where cars park the rest of the year.
	for p: Array in JM_PARK_FREE:
		var ring := _urect(p[0], p[1], p[2], p[3])
		parked_free.append([ring, _box_of([ring])])
	for c: Array in [[JM_TOWER, 12.5], [JM_TEACUPS, 7.0], [JM_CAROUSEL, 7.5], [JM_SANTA, 5.0]]:
		tree_free.append([_w(c[0].x, c[0].y), c[1]])
	# The chalets on Plac Centralny stand on its paving, among its planted trees.
	for h: Array in _jm_huts():
		if jarmark_lift(_w(h[0], h[1])) == 0.0:
			tree_free.append([_w(h[0], h[1]), 2.6])


## Loop 3c: the box a sector build keeps, its own tiles (landmarks.gd build; empty: the whole map).
var _near := Rect2()
## How far one market part (a chalet, a ride, a sign, a kit object) reaches from its spot, with slack.
const JM_PART_REACH := 30.0


## Does the market part at (u, v) reach into the sector being built? A sector keeps only its own
## triangles, so a part wholly outside `near` is skipped there instead of built and thrown away
## (perf, 2026-11-27: the whole market was built again in every sector it touched). The frame is
## kept as it was, so a part built after a skipped one comes out the same.
func _jm_here(u: float, v: float, r := JM_PART_REACH) -> bool:
	if not _near.has_area():
		return true
	var o := _o
	var a := _a
	var b := _b
	_jm_frame()
	var p := _w(u, v)
	_o = o
	_a = a
	_b = b
	return _near.grow(r).has_point(p)


## Does the stretch u0..u1 x v0..v1 (a light string, the fence, the paving) reach the sector?
func _jm_here_box(u0: float, u1: float, v0: float, v1: float, r := JM_PART_REACH) -> bool:
	if not _near.has_area():
		return true
	var o := _o
	var a := _a
	var b := _b
	_jm_frame()
	var box := Rect2(_w(u0, v0), Vector2.ZERO).expand(_w(u1, v0)).expand(_w(u0, v1)).expand(_w(u1, v1))
	_o = o
	_a = a
	_b = b
	return _near.grow(r).intersects(box, true)


func _build_jarmark(_site: Dictionary) -> void:
	_jm_frame()
	_mode = M_STONE
	for p: Array in JM_PAVED:
		if _jm_here_box(p[0], p[1], p[2], p[3]):
			_jm_drape(p[0], p[1], p[2], p[3])
	for h: Array in _jm_huts():
		if _quit_stop():
			return  # the quit fix (map_builder.gd `cancel_build`): this site takes seconds a sector
		if _jm_here(h[0], h[1]):
			_jm_hut(h[0], h[1], h[2], h[3], h[4])
	# The tree's plaza by Marszałkowska: the platform, the ring of yellow benches (open towards the
	# fan mast's square), the big snowman on the ring towards the Palace.
	if _jm_here(JM_TREE.x, JM_TREE.y):
		_jm_tree(JM_TREE)
	var gap := (JM_FAN - JM_TREE).angle()
	for k in 16:
		var t := TAU * (float(k) + 0.5) / 16.0
		if absf(wrapf(t - gap, -PI, PI)) < 0.45 or absf(wrapf(t - 2.4, -PI, PI)) < 0.25:
			continue
		if _jm_here(JM_TREE.x, JM_TREE.y):
			_jm_bench(JM_TREE + Vector2(cos(t), sin(t)) * 9.6, t)
	if _jm_here(JM_TREE.x, JM_TREE.y):
		_jm_snowman(JM_TREE.x + cos(2.4) * 9.9, JM_TREE.y + sin(2.4) * 9.9, 1.5)
	if _jm_here(169.0, 6.0):
		_jm_hat(169.0, 6.0)
	if _jm_here(JM_FAN.x, JM_FAN.y):
		_jm_fan(JM_FAN)
	if _jm_here(JM_CAROUSEL.x, JM_CAROUSEL.y):
		_jm_carousel(JM_CAROUSEL)
	if _jm_here(186.1, 23.2):
		_jm_redbar(186.1, 23.2, 3.2, 2.2, "KIEŁBASKI")
	if _jm_here(JM_KURANT.x, JM_KURANT.y):
		_jm_hexbar(JM_KURANT)
	if _jm_here(JM_STAGE.x, JM_STAGE.y, 60.0):
		_jm_stage(JM_STAGE)
	if _jm_here(JM_FOODZONE.x, JM_FOODZONE.y, 60.0):
		_jm_foodzone(JM_FOODZONE)
	if _jm_here(158.9, 68.2):
		_jm_redbar(158.9, 68.2, 4.2, 3.0, "GRZANIEC")
	if _jm_here(223.2, 67.2):
		_jm_redbar(223.2, 67.2, 3.0, 2.0, "GRZANIEC")
	# The red and green barrel tables in the plazas.
	var barrels := [[189.0, 83.5], [192.5, 84.0], [196.0, 83.5], [184.5, 19.0], [206.5, 15.0], [156.0, 63.0],
			[161.0, 63.0], [221.0, 63.5], [225.5, 63.0], [95.0, 33.0], [112.0, 34.0], [120.0, 112.0], [125.0, 112.5]]
	for i in barrels.size():
		if _jm_here(barrels[i][0], barrels[i][1]):
			_jm_barrel(barrels[i][0], barrels[i][1], JM_RED if i % 2 == 0 else Color("#2f7a3c"))
	# The light strings over the aisles.
	for s: Array in JM_STRINGS:
		if _jm_here_box(s[0], s[1], s[2], s[3]):
			_jm_zigzag(s[0], s[1], s[2], s[3], s[4])
	for l: Array in JM_LINES:
		if _jm_here_box(l[0], l[0], l[1], l[2]):
			_jm_line(l[0], l[1], l[2])
	# The kit objects at their anchors: every small thing on the official map, the photo details.
	_jm_kit_objects()
	if _quit_stop():
		return
	# The fence along Marszałkowska with its white banners and along the south access road, the
	# entrances (the map's wejście 1, 2, 7, 8) open.
	if _jm_here_box(147.0, 263.0, -9.5, -9.5):
		_jm_fence(147.0, 263.0, -9.5, [[171.5, 182.5], [219.0, 236.0]])
	if _jm_here_box(263.0, 263.0, -9.5, 93.0):
		_jm_fence_v(263.0, -9.5, 93.0, [[24.0, 35.0], [67.0, 79.0]])
	for bu: float in [158.0, 205.0, 250.0]:
		if _jm_here(bu, -9.6):
			_jm_banner(bu, -9.6)
	# The gold sign and the light-up trees at the entrances, big stars.
	if _jm_here(177.0, -7.0):
		_jm_greeting(177.0, -7.0)
	if _quit_stop():
		return
	# The plaza sign stands 11.5 m along from the map's spot (91.5): there it ran 1 m beside the lawn
	# railing's north edge (u 91.5..105, v 16), a slot that pinned cars sliding along the railing
	# (Autopilot PT-60 re-run, 2026-11-27). Now its east end is 6 m short of the railing's corner.
	if _jm_here(80.0, 17.0):
		_jm_greeting(80.0, 17.0)
	for t: Array in [[150.5, -6.5], [168.5, -7.0], [236.5, -7.0], [261.0, 22.0], [261.0, 37.0],
			[261.0, 81.0], [155.0, 12.0], [155.0, 21.0], [92.0, 40.0], [74.5, 13.0], [85.5, 13.0]]:
		if _jm_here(t[0], t[1]):
			_jm_ledtree(t[0], t[1], 3.4)
	if _jm_here(160.0, -6.5):
		_jm_bigstar(160.0, -6.5, 1.9)
	if _jm_here(262.0, 50.0):
		_jm_bigstar(262.0, 50.0, 1.6)
	# Plac Centralny: the tower, the teacups; Santa's cabin by the stage's plaza.
	if _jm_here(JM_TOWER.x, JM_TOWER.y):
		_jm_tower(JM_TOWER)
	if _jm_here(JM_TEACUPS.x, JM_TEACUPS.y):
		_jm_teacups(JM_TEACUPS)
	if _jm_here(JM_SANTA.x, JM_SANTA.y):
		_jm_santa(JM_SANTA, 2)
	_jm_frame()


## The world place of a named anchor (JM_ANCHORS): Vector3(x, z, yaw), yaw as jarmark_kit.gd takes it
## (the object's local u axis turned from world +x towards +z; its front is local -v, as a hut of that
## quarter). To wire a kit builder by hand: `JmKit.name(self, Vector2(r.x, r.y), r.z)`.
static func jm_anchor(name: String) -> Vector3:
	var e: Array = JM_ANCHORS[name]
	var a := JM_AXIS.normalized()
	var p := JM_O + a * float(e[1]) + Vector2(-a.y, a.x) * float(e[2])
	return Vector3(p.x, p.y, a.angle() + PI * 0.5 * float(e[3]))


## Builds every JM_ANCHORS entry whose builder jarmark_kit.gd has (looked up by name, so a builder the
## kit gains later is wired with no change here). Until the kit has them, the GRZANIEC booth falls back
## to `_jm_redbar` and the LED tree arch to `_jm_hat`; "led_figure_hung" is led_figure 5 m up.
func _jm_kit_objects() -> void:
	var kit: Script = JmKit
	var have := {}
	for m: Dictionary in kit.get_script_method_list():
		have[m["name"]] = m["args"]
	for name: String in JM_ANCHORS:
		if _quit_stop():
			return
		var e: Array = JM_ANCHORS[name]
		var bld: String = e[0]
		if bld.is_empty():
			continue
		_jm_frame()
		var r := jm_anchor(name)
		var at := Vector2(r.x, r.y)
		if _near.has_area() and not _near.grow(JM_PART_REACH).has_point(at):
			continue
		var g := NAN
		if bld == "led_figure_hung":
			bld = "led_figure"
			g = map.terrain_height(at.x, at.y) + 5.0
		if have.has(bld):
			# Fill the builder's own arguments by name (the kit is still growing, and a few builders
			# take no yaw): b, at, yaw, g, then the anchor's int argument for the first int one (a
			# cabin's size before its kind keeps the default); defaults for the rest.
			var sig: Array = have[bld]
			var args: Array = []
			var put_arg := e[4] == null
			if is_nan(g) == false and not sig.any(func(d: Dictionary) -> bool: return d["name"] == "g"):
				continue
			for d: Dictionary in sig:
				var an: String = d["name"]
				if an == "b":
					args.append(self)
				elif an == "at":
					args.append(at)
				elif an == "yaw":
					args.append(r.z)
				elif an == "g":
					args.append(g)
				elif not put_arg and int(d["type"]) == TYPE_VECTOR2 and bld == "cabin":
					args.append(Vector2(1.5, 1.2))
				elif not put_arg and int(d["type"]) == TYPE_INT:
					args.append(e[4])
					put_arg = true
				else:
					break
			kit.callv(bld, args)
		elif bld == "grzaniec_booth":
			_jm_redbar(float(e[1]), float(e[2]), 1.5, 2.6, "GRZANIEC")
		elif bld == "led_tree_arch":
			_jm_hat(float(e[1]), float(e[2]))
	_jm_frame()


## Is the spot (u, v) at least r clear of every chalet, the tree's ring and the kurant (where a pole
## for a string may stand)?
static func jm_clear(u: float, v: float, r: float) -> bool:
	for h: Array in JM_HUT_LIST:
		var hu := 2.6 if h[3] == Hut.BIG else 1.6
		var hv := 1.5 if h[3] == Hut.BIG else 1.15
		if int(h[2]) % 2 == 1:
			var t := hu
			hu = hv
			hv = t
		if absf(u - float(h[0])) < hu + r and absf(v - float(h[1])) < hv + r:
			return false
	for c: Array in [[JM_TREE, 10.2], [JM_KURANT, 7.6], [JM_STAGE, 7.5], [JM_SOUTH_GATE, 5.5],
			[JM_SOUTH_GATE + Vector2(-1.0, -16.0), 3.0]]:
		if Vector2(u, v).distance_to(c[0]) < float(c[1]) + r:
			return false
	return true


## The mast in the square between the tree and the kurant (the drone frame): 9 m, strings of bulbs
## fanning from its top to poles 9-11 m round, where they stand clear of the chalets.
func _jm_fan(at: Vector2) -> void:
	var top := _jm_pole(at.x, at.y, 9.0)
	for k in 14:
		var t := TAU * float(k) / 14.0
		for rr: float in [10.5, 9.0]:
			var p := at + Vector2(cos(t), sin(t)) * rr
			if p.y > -8.5 and jm_clear(p.x, p.y, 0.5):
				_jm_string(top, _jm_pole(p.x, p.y, 4.0), 0.6)
				break


## The red food-zone pavilion by the stage (the map's strefa gastronomiczna, the drone frame's red
## house with three bells): a long red stand lit on its front, a white roof board with three white
## bells and a lit rim, white parasols and fir trees before it.
func _jm_foodzone(at: Vector2) -> void:
	var g := _jm_at(at.x, at.y, 0)
	var hu := 5.0
	var hv := 2.0
	_lbox(0.0, 0.0, hu, hv, g, g + 3.2, JM_RED, M_STONE, JM_RED.darkened(0.15))
	_ubox(-hu + 0.4, hu - 0.4, -hv - 0.03, -hv, g + 1.05, g + 2.6, JM_GLOW, M_LAMP)
	_ubox(-hu, hu, -hv - 0.45, -hv, g + 0.93, g + 1.03, JM_WHITE, M_STONE)
	# The board over the front with its three bells.
	_ubox(-hu + 0.6, hu - 0.6, -0.15, 0.15, g + 3.2, g + 5.4, JM_RED.darkened(0.1), M_STONE)
	for su: float in [-2.6, 0.0, 2.6]:
		var c := _w(su, -0.2)
		_frustum(_circle(c, 0.75, 8), g + 3.45, _circle(c, 0.35, 8), g + 4.85, JM_WHITE, JM_WHITE)
	_no_roof = true
	_jm_bar(-hu + 0.6, -0.2, g + 5.35, hu - 0.6, -0.2, g + 5.35, 0.08, JM_BULB, M_LAMP)
	_jm_bar(-hu, -hv - 0.42, g + 3.1, hu, -hv - 0.42, g + 3.1, 0.07, JM_BULB, M_LAMP)
	_no_roof = false
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	_jm_frame()
	for su: float in [-3.4, 0.0, 3.4]:
		var c := _w(at.x + su, at.y - 4.6)
		var gg: float = map.terrain_height(c.x, c.y)
		_beam(Vector3(c.x, gg, c.y), Vector3(c.x, gg + 2.3, c.y), 0.06, JM_WIRE)
		_frustum(_circle(c, 1.4, 8), gg + 2.0, _circle(c, 0.1, 8), gg + 2.6, JM_WHITE, JM_WHITE)
	for su: float in [-hu - 0.8, hu + 0.8]:
		_jm_ledtree(at.x + su, at.y - 1.0, 2.6)


## The asphalt laid over the car park and the lawns between its aisles (the drone frames show the
## whole market on dark asphalt with faint white bay lines), draped on the terrain in 4 m cells.
func _jm_drape(u0: float, u1: float, v0: float, v1: float) -> void:
	_jm_frame()
	var cols := ceili((u1 - u0) / 4.0)
	var rows := ceili((v1 - v0) / 4.0)
	var pts: Array[Vector3] = []
	for j in rows + 1:
		for i in cols + 1:
			var w := _w(lerpf(u0, u1, float(i) / cols), lerpf(v0, v1, float(j) / rows))
			pts.append(Vector3(w.x, map.terrain_height(w.x, w.y) + JM_LIFT, w.y))
	_mode = M_STONE
	for j in rows:
		for i in cols:
			var k := j * (cols + 1) + i
			var col := JM_ASPHALT.lightened(0.03 * float((i * 7 + j * 3) % 3))
			_quad(pts[k], pts[k + 1], pts[k + cols + 2], pts[k + cols + 1], Vector3.UP, col,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The car park's old bay lines, white, across the aisles of the main market.
	for vl: float in JM_BAYS:
		var uu := u0 + 2.0
		while uu < u1 - 2.0:
			if jm_clear(uu, vl, 2.5):
				var g := _jm_ground(uu, vl)
				_ubox(uu - 0.06, uu + 0.06, vl - 2.4, vl + 2.4, g + JM_LIFT, g + JM_LIFT + 0.05, Color("#c9c9c4"), M_STONE)
			uu += 2.6


## One chalet, its front (the counter) to -v after `quarter` turns. 3.2 x 2.3 m (the food stall
## 2.6 x 2.0, the big chalet 5.2 x 3.0), gable roof along the front, the counter lit from inside,
## goods on the shelf, a fir garland with red bows and a string of bulbs on most.
func _jm_hut(u: float, v: float, quarter: int, kind: int, n: int) -> void:
	var g := _jm_at(u, v, quarter)
	var hu := 1.6
	var hv := 1.15
	var eave := 2.3
	var rise := 0.95
	var wall := JM_WHITE
	var roof := JM_ROOF
	var trim := JM_TRIM
	match kind:
		Hut.RED:
			wall = JM_RED
			trim = JM_WHITE
		Hut.FOOD:
			hu = 1.3
			hv = 1.0
			eave = 2.2
			rise = 0.75
			wall = Color("#3a3634")
			roof = JM_YELLOW
			trim = JM_YELLOW
		Hut.BIG:
			hu = 2.6
			hv = 1.5
			eave = 2.6
			rise = 1.25
	if kind == Hut.WHITE and n % 4 == 1:
		roof = JM_ROOF_LIGHT
	_mode = M_STONE
	_lbox(0.0, 0.0, hu, hv, g, g + eave, wall, M_STONE, wall.darkened(0.1))
	# The counter: the open front lit from inside (goods by day, a warm glow at night), the shelf.
	var top := g + eave - 0.3
	_ubox(-hu + 0.22, hu - 0.22, -hv - 0.03, -hv, g + 1.05, top, JM_GLOW, M_LAMP)
	_ubox(-hu, hu, -hv - 0.4, -hv, g + 0.93, g + 1.03, JM_TIMBER, M_STONE)
	var goods := [Color("#c23b2e"), Color("#e7c14a"), Color("#3d7a4a"), Color("#f3efe6"), Color("#7a4a8c")]
	for k in 2:
		var gu := -hu * 0.5 + float(k) * hu
		var col: Color = goods[(n + k) % goods.size()]
		_ubox(gu - 0.22, gu + 0.22, -hv - 0.32, -hv - 0.08, g + 1.03, g + 1.3 + 0.1 * float((n + k) % 3), col, M_STONE)
	# The roof, overhanging the counter.
	_gable(hu + 0.15, -hu - 0.15, 0.0, hv + 0.4, g + eave, rise, wall, roof, true)
	# Trim: corner posts, the eave beam, the plinth.
	for su: float in [-hu, hu - 0.12]:
		_ubox(su, su + 0.12, -hv - 0.03, hv + 0.03, g, g + eave - 0.05, trim, M_STONE)
	_ubox(-hu, hu, -hv - 0.05, -hv, g + eave - 0.14, g + eave, trim, M_STONE)
	_ubox(-hu, hu, -hv - 0.05, -hv, g, g + 0.18, trim, M_STONE)
	if kind == Hut.TIMBER or kind == Hut.BIG:
		# The half-timbered look: black braces below the counter, a black post in the middle.
		var parts := 3 if kind == Hut.TIMBER else 4
		var w := (2.0 * hu - 0.24) / parts
		for k in parts:
			var b0 := -hu + 0.12 + k * w
			_jm_bar(b0 + 0.05, -hv - 0.06, g + 0.2, b0 + w - 0.05, -hv - 0.06, g + 0.95, 0.07, JM_TRIM)
			_jm_bar(b0 + w - 0.05, -hv - 0.06, g + 0.2, b0 + 0.05, -hv - 0.06, g + 0.95, 0.07, JM_TRIM)
		for sv: float in [-1.0, 1.0]:
			var sx := sv * (hu + 0.04)
			_jm_bar(sx, -hv + 0.1, g + 0.2, sx, hv - 0.1, g + eave - 0.2, 0.07, JM_TRIM)
			_jm_bar(sx, hv - 0.1, g + 0.2, sx, -hv + 0.1, g + eave - 0.2, 0.07, JM_TRIM)
	# The fir garland with red bows along the front eave, and the bulbs under it.
	if kind != Hut.FOOD and n % 5 != 4:
		_jm_bar(-hu - 0.15, -hv - 0.42, g + eave - 0.05, hu + 0.15, -hv - 0.42, g + eave - 0.05, 0.22, JM_FIR)
		for bu: float in [-hu, hu]:
			_ubox(bu - 0.13, bu + 0.13, -hv - 0.58, -hv - 0.46, g + eave - 0.32, g + eave - 0.06, JM_BOW, M_STONE)
	if n % 5 != 2:
		_no_roof = true
		_jm_bar(-hu - 0.1, -hv - 0.36, g + eave - 0.2, hu + 0.1, -hv - 0.36, g + eave - 0.2, 0.06, JM_BULB, M_LAMP)
		_no_roof = false
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	# The official huts' shutters, flaps and grooves (jarmark_kit.gd); not its multicolour bulbs: the
	# real ones are warm white (lighting-decision.md, 2026-11-21).
	JmKit.hut_extras(self, _o, _a.angle(), g, hu, hv, eave, rise, false, true, false, n)
	_jm_frame()


## A string of bulbs from p to q (world), sagging, a bulb every ~1.3 m. Out of the roof grid.
func _jm_string(p: Vector3, q: Vector3, sag: float) -> void:
	_no_roof = true
	var sagged := func(t: float) -> Vector3:
		return p.lerp(q, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t)
	var prev := p
	for k in range(1, 5):
		var at: Vector3 = sagged.call(float(k) / 4.0)
		_beam(prev, at, 0.03, JM_WIRE, false)
		prev = at
	var n := maxi(3, ceili(p.distance_to(q) / 1.25))
	for k in range(1, n):
		var at: Vector3 = sagged.call(float(k) / n)
		_prism(_circle(Vector2(at.x, at.z), 0.15, 3), at.y - 0.26, at.y - 0.04, JM_BULB, JM_BULB, M_LAMP, M_LAMP)
	_no_roof = false


## A thin dark pole at local (u, v) up to `h` over the ground; its top.
func _jm_pole(u: float, v: float, h: float) -> Vector3:
	var g := _jm_ground(u, v)
	_jm_bar(u, v, g, u, v, g + h, 0.09, JM_WIRE)
	return _jm_p(u, v, g + h)


## Strings zig-zagging across an aisle between the lines v_a and v_b, from u0 to u1.
func _jm_zigzag(u0: float, u1: float, va: float, vb: float, step: float) -> void:
	_jm_frame()
	var u := u0
	var at_a := true
	var prev := _jm_pole(u, va, 4.2)
	while u + step * 0.5 <= u1:
		u += step * 0.5
		at_a = not at_a
		var nxt := _jm_pole(u, va if at_a else vb, 4.2)
		_jm_string(prev, nxt, 0.45)
		prev = nxt


## A straight string down a cross aisle, between poles every 8 m.
func _jm_line(u: float, v0: float, v1: float) -> void:
	_jm_frame()
	var n := maxi(1, ceili((v1 - v0) / 8.0))
	var prev := _jm_pole(u, v0, 4.6)
	for k in range(1, n + 1):
		var nxt := _jm_pole(u, lerpf(v0, v1, float(k) / n), 4.6)
		_jm_string(prev, nxt, 0.35)
		prev = nxt


## The big tree (nm-01, the drone frames): about 15 m, eight tiers of fir green with big red, gold
## and white baubles, LED strands round every tier and down the cone (blue at night, as the reels
## show it), white bulbs on the rims and the gold star; on a round platform with a red rail.
func _jm_tree(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_mode = M_STONE
	_prism(_circle(c, 7.5, 24), g, g + 0.35, Color("#7a5a3c"), Color("#cfc8bc"), M_STONE, M_STONE)
	_no_roof = true
	var ring := _circle(c, 7.35, 24)
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		_beam(Vector3(a.x, g + 0.36, a.y), Vector3(b.x, g + 0.36, b.y), 0.08, JM_LED, false, M_LAMP)
		_beam(Vector3(a.x, g + 1.1, a.y), Vector3(b.x, g + 1.1, b.y), 0.07, JM_BOW, false)
		_beam(Vector3(a.x, g + 0.36, a.y), Vector3(a.x, g + 1.1, a.y), 0.07, JM_BOW, false)
	_no_roof = false
	var g0 := g + 0.35
	var tiers := 8
	var apex := g0 + 0.5 + tiers * 1.75 + 0.6
	for k in tiers:
		var y0 := g0 + 0.5 + k * 1.75
		var r0 := 4.7 - 0.53 * k
		# The tiers themselves are the LED net: fir green by day, blue at night (the reels).
		var keep_mode := _mode
		_mode = M_LAMP + 0.5
		_frustum(_circle(c, r0, 12), y0, _circle(c, r0 * 0.32, 12), y0 + 2.5, JM_FIR, JM_FIR.darkened(0.2))
		_mode = keep_mode
		var rim := _circle(c, r0 + 0.05, 12)
		_no_roof = true
		for j in rim.size():
			var a := rim[j]
			var b := rim[(j + 1) % rim.size()]
			_beam(Vector3(a.x, y0 + 0.05, a.y), Vector3(b.x, y0 + 0.05, b.y), 0.09, JM_FIR.lightened(0.15), false, M_LAMP + 0.5)
			_prism(_circle(a, 0.14, 4), y0 - 0.12, y0 + 0.12, JM_LED, JM_LED, M_LAMP, M_LAMP)
		_no_roof = false
		for j in 6:
			var t := TAU * (float(j) + 0.5 * (k % 2)) / 6.0
			var p := c + Vector2(cos(t), sin(t)) * (r0 * 0.86)
			var col: Color = [Color("#c8232c"), Color("#d9a82b"), Color("#f2efe8")][(j + k) % 3]
			var br := 0.48 - 0.03 * k
			_frustum(_circle(p, br * 0.7, 8), y0 - br * 0.9, _circle(p, br, 8), y0 - br * 0.3, col)
			_frustum(_circle(p, br, 8), y0 - br * 0.3, _circle(p, br * 0.6, 8), y0 + br * 0.5, col, col)
	# The strands down the cone, blue at night.
	_no_roof = true
	for j in 16:
		var t := TAU * (float(j) + 0.25) / 16.0
		var foot := c + Vector2(cos(t), sin(t)) * 4.75
		_beam(Vector3(c.x, apex - 0.4, c.y), Vector3(foot.x, g0 + 0.55, foot.y), 0.07, JM_FIR.lightened(0.15), false, M_LAMP + 0.5)
	_no_roof = false
	_jm_star(Vector3(c.x, apex + 0.9, c.y), 1.1, Vector3(_a.x, 0.0, _a.y), JM_GOLD)
	_jm_star(Vector3(c.x, apex + 0.9, c.y), 1.1, Vector3(_b.x, 0.0, _b.y), JM_GOLD)
	_collide(_circle(c, 7.5, 12))


## A five-pointed star of radius r in the upright plane along `side`, lit, seen from both faces.
func _jm_star(c: Vector3, r: float, side: Vector3, col: Color) -> void:
	var keep := _mode
	_mode = M_LAMP
	var n := side.cross(Vector3.UP).normalized()
	var pts: Array[Vector3] = []
	for k in 10:
		var t := PI * 0.5 + TAU * float(k) / 10.0
		var rr := r if k % 2 == 0 else r * 0.42
		pts.append(c + (side.normalized() * cos(t) + Vector3.UP * sin(t)) * rr)
	for k in 10:
		var a := pts[k]
		var b := pts[(k + 1) % 10]
		var off := n * 0.06
		_tri(c + off, a + off, b + off, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
		_tri(c - off, b - off, a - off, -n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = keep


## A yellow bench at a local spot of the market (u, v), facing the tree (angle t round it).
func _jm_bench(at: Vector2, t: float) -> void:
	_jm_frame()
	var p := _w(at.x, at.y)
	var g: float = map.terrain_height(p.x, p.y)
	var out := (_a * cos(t) + _b * sin(t)).normalized()
	var d := Vector2(-out.y, out.x)
	_pow_box(p, d, 0.95, 0.24, g + 0.4, g + 0.5, JM_YELLOW, JM_YELLOW.lightened(0.1))
	_pow_box(p + out * 0.22, d, 0.95, 0.05, g + 0.5, g + 0.95, JM_YELLOW, JM_YELLOW)
	for s: float in [-0.8, 0.8]:
		_pow_box(p + d * s, d, 0.06, 0.2, g, g + 0.4, Color("#9a7a2a"), Color("#9a7a2a"))


## The big snowman lit white (the drone frame: on the tree's bench ring): three balls, a black hat, a
## carrot nose; `s` scales the 3.7 m one.
func _jm_snowman(u: float, v: float, s := 1.0) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	var balls := [[1.0, 0.0, 1.7], [0.75, 1.6, 2.8], [0.52, 2.75, 3.7]]
	for b: Array in balls:
		var r: float = float(b[0]) * s
		var y0: float = g + float(b[1]) * s
		var y1: float = g + float(b[2]) * s
		var ym := (y0 + y1) * 0.5
		_frustum(_circle(c, r * 0.55, 10), y0, _circle(c, r, 10), ym, JM_LED)
		_frustum(_circle(c, r, 10), ym, _circle(c, r * 0.5, 10), y1, JM_LED, JM_LED)
	_prism(_circle(c, 0.6 * s, 10), g + 3.68 * s, g + 3.76 * s, JM_TRIM, JM_TRIM)
	_prism(_circle(c, 0.36 * s, 10), g + 3.76 * s, g + 4.3 * s, JM_TRIM, JM_TRIM)
	_jm_bar(u, v - 0.45 * s, g + 3.2 * s, u, v - 0.95 * s, g + 3.15 * s, 0.12 * s, Color("#e87a24"))
	_collide(_circle(c, s, 8))


## The Santa-hat photo spot (the drone frame): a 5 m teal LED hat with a white fur rim and pompom,
## a lit heart arch in front where people stand for the photo.
func _jm_hat(u: float, v: float) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	var teal := Color(0.14, 0.52, 0.66)
	_prism(_circle(c, 2.35, 14), g, g + 0.85, JM_LED, JM_LED, M_LAMP, M_LAMP)
	var tip := c + _a * 0.9
	_frustum(_circle(c, 2.0, 14), g + 0.85, _circle(tip, 0.35, 14), g + 4.6, teal)
	_frustum(_circle(tip, 0.35, 14), g + 4.6, _circle(tip + _a * 0.5, 0.15, 14), g + 4.9, teal)
	var pom := tip + _a * 0.75
	_prism(_circle(pom, 0.42, 8), g + 4.6, g + 5.4, JM_LED, JM_LED, M_LAMP, M_LAMP)
	# Re-draw the cone's skin as lit strands so it glows at night.
	_no_roof = true
	for k in 10:
		var t := TAU * float(k) / 10.0
		var f := c + Vector2(cos(t), sin(t)) * 2.02
		_beam(Vector3(f.x, g + 0.85, f.y), Vector3(tip.x, g + 4.6, tip.y), 0.08, teal.lightened(0.3), false, M_LAMP)
	# The heart in front.
	var hv := v - 3.0
	var pts: Array[Vector2] = []
	for k in 17:
		var t := TAU * float(k) / 16.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(Vector2(x, y) * 0.09)
	var hg := _jm_ground(u, hv)
	for k in 16:
		_jm_bar(u + pts[k].x, hv, hg + 1.6 + pts[k].y, u + pts[k + 1].x, hv, hg + 1.6 + pts[k + 1].y, 0.12,
				Color(1.0, 0.45, 0.62), M_LAMP)
	_jm_bar(u - 1.2, hv, hg, u - 1.2, hv, hg + 1.4, 0.1, JM_WIRE)
	_jm_bar(u + 1.2, hv, hg, u + 1.2, hv, hg + 1.4, 0.1, JM_WIRE)
	_no_roof = false
	_collide(_circle(c, 2.35, 8))


## The Venetian carousel (frame 004): a floor on a red plinth, a ring of gold posts, white horses on
## gold poles, the mirrored lit drum in the middle, the striped cream-and-red canopy with its lit
## valance and a gold finial (the strings fanning from a top are the kurant's, F 2026-11-21).
func _jm_carousel(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 6.0, 16), g, g + 0.45, Color("#7a2228"), Color("#d8c9a6"), M_STONE, M_STONE)
	_prism(_circle(c, 1.3, 8), g + 0.45, g + 4.0, Color("#c99a48"), Color("#c99a48"), M_LAMP, M_STONE)
	_collide(_circle(c, 6.4, 12))


## The Venetian carousel's turning part (jarmark_rides.gd turns it in its shader): `part` -1 the
## gold posts, the canopy with its lit valance and finial; 0-11 one horse on its pole, a rider on
## seven of them (the horses bob, so each is its own batch).
func _jm_carousel_spin(at: Vector2, part: int) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	if part < 0:
		for p: Vector2 in _circle(c, 5.5, 16):
			_beam(Vector3(p.x, g + 0.45, p.y), Vector3(p.x, g + 4.0, p.y), 0.16, JM_GOLD, false)
		var rim := _circle(c, 6.5, 16)
		_prism(rim, g + 3.9, g + 4.35, Color("#f3dfa8"), Color(0, 0, 0, 0), M_LAMP, M_STONE)
		var apex := Vector3(c.x, g + 6.8, c.y)
		_mode = M_STONE
		for k in rim.size():
			var a := rim[k]
			var b := rim[(k + 1) % rim.size()]
			var pa := Vector3(a.x, g + 4.35, a.y)
			var pb := Vector3(b.x, g + 4.35, b.y)
			var nrm := (pb - pa).cross(apex - pa).normalized()
			if Vector2(nrm.x, nrm.z).dot((a + b) * 0.5 - c) < 0.0:
				nrm = -nrm
			_tri(pa, pb, apex, nrm, Color("#efe6d2") if k % 2 == 0 else Color("#b3262d"), Vector2(-1, -1), Vector2(-1, -1),
					Vector2(-1, -1), -1.0, false)
		_frustum(_circle(c, 0.35, 8), g + 6.6, _circle(c, 0.12, 8), g + 7.6, JM_GOLD, JM_GOLD)
		_prism(_circle(c, 0.22, 6), g + 7.6, g + 7.95, JM_BULB, JM_BULB, M_LAMP, M_LAMP)
		return
	var k := part
	var t := TAU * float(k) / 12.0
	var r := 4.2 if k % 2 == 0 else 2.9
	var p := c + Vector2(cos(t), sin(t)) * r
	var d := Vector2(-sin(t), cos(t))
	var hy := g + 1.4 + 0.3 * float(k % 3)
	_beam(Vector3(p.x, g + 0.45, p.y), Vector3(p.x, g + 4.0, p.y), 0.06, JM_GOLD, false)
	var tail := p - d * 0.55
	var head := p + d * 0.55
	_beam(Vector3(tail.x, hy, tail.y), Vector3(head.x, hy, head.y), 0.42, Color("#f4f1ea"), false)
	_beam(Vector3(head.x, hy, head.y), Vector3(head.x + d.x * 0.25, hy + 0.55, head.y + d.y * 0.25), 0.22, Color("#f4f1ea"), false)
	_beam(Vector3(p.x, hy + 0.2, p.y), Vector3(p.x, hy + 0.3, p.y), 0.44, [JM_RED, JM_BLUE, JM_GOLD][k % 3], false)
	if k % 12 in [0, 1, 3, 4, 6, 8, 10]:
		_jm_rider(p - d * 0.1, d, hy + 0.3, k)

## A red stand (the sausage stand, the mulled-wine bar): a red box with white trim, counters lit on
## three sides, a dark red gable roof, and its word in white on a red board on two posts above.
func _jm_redbar(u: float, v: float, hu: float, hv: float, word: String) -> void:
	var g := _jm_at(u, v, 0)
	var h := 2.9
	_lbox(0.0, 0.0, hu, hv, g, g + h, JM_RED, M_STONE, JM_RED.darkened(0.1))
	_ubox(-hu + 0.3, hu - 0.3, -hv - 0.03, -hv, g + 1.05, g + 2.5, JM_GLOW, M_LAMP)
	_ubox(-hu - 0.03, -hu, -hv + 0.3, hv - 0.3, g + 1.05, g + 2.5, JM_GLOW, M_LAMP)
	_ubox(hu, hu + 0.03, -hv + 0.3, hv - 0.3, g + 1.05, g + 2.5, JM_GLOW, M_LAMP)
	_ubox(-hu, hu, -hv - 0.45, -hv, g + 0.93, g + 1.03, JM_WHITE, M_STONE)
	for su: float in [-hu, hu - 0.14]:
		_ubox(su, su + 0.14, -hv - 0.04, hv + 0.04, g, g + h - 0.05, JM_WHITE, M_STONE)
	_gable(hu + 0.25, -hu - 0.25, 0.0, hv + 0.45, g + h, 1.2, JM_RED, Color("#7a1c20"), true)
	_no_roof = true
	_jm_bar(-hu - 0.2, -hv - 0.42, g + h - 0.15, hu + 0.2, -hv - 0.42, g + h - 0.15, 0.07, JM_BULB, M_LAMP)
	_no_roof = false
	# The board.
	var by := g + h + 1.6
	var bw := _jm_word_w(word, 0.55) + 0.8
	for su: float in [-bw * 0.4, bw * 0.4]:
		_ubox(su - 0.06, su + 0.06, -0.06, 0.06, g + h + 0.6, by, JM_TRIM, M_STONE)
	_ubox(-bw * 0.5, bw * 0.5, -0.12, 0.12, by, by + 1.1, JM_RED.darkened(0.1), M_STONE)
	_jm_word(word, 0.0, -0.13, by + 0.3, 0.55, JM_WHITE, M_LAMP)
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	_jm_frame()


## A word in solid pixel blocks on the current local frame's -v face at v, centred on u, its body's
## bottom at y and `h` tall. The reader faces +v, so their left-to-right runs along -u.
func _jm_word_w(text: String, h: float) -> float:
	var w := 0.0
	for ch in text:
		w += (_pow_glyph_w(ch) + 1) * h / 7.0
	return w - h / 7.0


func _jm_word(text: String, u: float, v: float, y: float, h: float, col: Color, mode: float) -> void:
	var sx := h / 7.0
	var width := 0.0
	for ch in text:
		width += (_pow_glyph_w(ch) + 1) * sx
	width -= sx
	var at := u + width * 0.5
	for ch in text:
		if ch == " ":
			at -= (_pow_glyph_w(ch) + 1) * sx
			continue
		var lit := {}
		for q: Vector2i in _pow_glyph(ch):
			lit[q] = true
		for q: Vector2i in lit:
			if lit.has(q - Vector2i(1, 0)):
				continue
			var e := q
			while lit.has(e + Vector2i(1, 0)):
				e += Vector2i(1, 0)
			var row := PixelFont.BODY + 6 - q.y
			_ubox(at - (e.x + 1) * sx, at - q.x * sx, v - 0.08, v, y + row * sx, y + (row + 1) * sx, col, mode)
		at -= (_pow_glyph_w(ch) + 1) * sx


## The two-storey hexagonal bar (nm-75, nm-76), the kurant's stand-in (JM_KURANT): a red six-sided bar with a lit counter round it and
## a white band, a smaller red storey above with its own lights, a red pyramid roof and a gold star.
func _jm_hexbar(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 3.3, 6), g, g + 1.0, JM_RED, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_circle(c, 3.32, 6), g + 1.0, g + 1.12, JM_WHITE, JM_WHITE, M_STONE, M_STONE)
	_prism(_circle(c, 3.0, 6), g + 1.12, g + 2.5, JM_GLOW, Color(0, 0, 0, 0), M_LAMP, M_STONE)
	_prism(_circle(c, 3.4, 6), g + 2.5, g + 3.05, JM_WHITE, JM_WHITE, M_STONE, M_STONE)
	_prism(_circle(c, 2.1, 6), g + 3.05, g + 5.2, JM_RED, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_circle(c, 2.12, 6), g + 3.9, g + 4.7, JM_GLOW, Color(0, 0, 0, 0), M_LAMP, M_STONE)
	_pyramid(_circle(c, 2.7, 6), g + 5.2, g + 7.6, Color("#8e1c22"))
	_no_roof = true
	for ring: Array in [[3.45, g + 3.0], [2.75, g + 5.15]]:
		var pts := _circle(c, ring[0], 6)
		for k in 6:
			var a := pts[k]
			var b := pts[(k + 1) % 6]
			_beam(Vector3(a.x, ring[1], a.y), Vector3(b.x, ring[1], b.y), 0.08, JM_BULB, false, M_LAMP)
	_no_roof = false
	_jm_star(Vector3(c.x, g + 8.05, c.y), 0.6, Vector3(_a.x, 0.0, _a.y), JM_GOLD)
	_collide(_circle(c, 3.4, 6))


## The stage on the Palace side (the drone frame): a white pavilion open to the market, its back
## wall lit cool, a lit truss along the front, light-up trees on both sides, SCENA in gold above.
func _jm_stage(at: Vector2) -> void:
	var g := _jm_at(at.x, at.y, 0)
	var hu := 7.0
	var hv := 3.5
	_lbox(0.0, 0.4, hu, hv - 0.4, g, g + 0.9, Color("#3a3c40"), M_STONE, Color("#4a4c50"))
	_lbox(0.0, hv - 0.15, hu, 0.15, g + 0.9, g + 4.92, Color("#c8d4f0"), M_PAVILION + 0.5, Color("#e8e8e4"))
	for su: float in [-hu + 0.15, hu - 0.15]:
		_lbox(su, 0.0, 0.15, hv, g, g + 4.97, JM_WHITE, M_STONE, JM_WHITE)
	_lbox(0.0, 0.0, hu + 0.2, hv + 0.2, g + 5.0, g + 5.5, JM_WHITE, M_STONE, Color("#dcdad4"))
	_no_roof = true
	_jm_bar(-hu, -hv - 0.25, g + 4.8, hu, -hv - 0.25, g + 4.8, 0.22, JM_LED, M_LAMP)
	for su: float in [-hu, hu]:
		_jm_bar(su, -hv - 0.25, g + 0.9, su, -hv - 0.25, g + 4.8, 0.14, JM_LED, M_LAMP)
	_no_roof = false
	_jm_word("SCENA", 0.0, -hv - 0.2, g + 5.5, 1.1, JM_GOLD, M_LAMP)
	_collide(_rect(0.0, 0.0, hu + 0.2, hv + 0.2))
	_jm_frame()
	_jm_ledtree(at.x - 9.0, at.y - 3.0, 3.8)
	_jm_ledtree(at.x + 9.0, at.y - 3.0, 3.8)


## A red or green barrel standing table.
func _jm_barrel(u: float, v: float, col: Color) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_frustum(_circle(c, 0.32, 8), g, _circle(c, 0.38, 8), g + 0.55, col)
	_frustum(_circle(c, 0.38, 8), g + 0.55, _circle(c, 0.33, 8), g + 1.05, col, Color("#5a3a24"))
	_prism(_circle(c, 0.39, 8), g + 0.3, g + 0.36, JM_TRIM, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_circle(c, 0.39, 8), g + 0.8, g + 0.86, JM_TRIM, Color(0, 0, 0, 0), M_STONE, M_STONE)


## The low black mesh fence along Marszałkowska, posts every 2.5 m, two rails, open at the gates.
func _jm_fence(u0: float, u1: float, v: float, gaps: Array) -> void:
	_jm_frame()
	var u := u0
	while u < u1:
		var nu := minf(u + 2.5, u1)
		var open := false
		for gp: Array in gaps:
			if nu > float(gp[0]) and u < float(gp[1]):
				open = true
		if not open:
			var g0 := _jm_ground(u, v)
			var g1 := _jm_ground(nu, v)
			_jm_bar(u, v, g0, u, v, g0 + 1.2, 0.08, JM_WIRE)
			_jm_bar(u, v, g0 + 1.15, nu, v, g1 + 1.15, 0.1, JM_WIRE)
			_jm_bar(u, v, g0 + 0.15, nu, v, g1 + 0.15, 0.1, JM_WIRE)
			_ubox(u, nu, v - 0.02, v + 0.02, minf(g0, g1) + 0.15, minf(g0, g1) + 1.15, Color("#55595d"), M_STONE)
			_collide(_urect(u, nu, v - 0.1, v + 0.1))
		u = nu


## The same fence along v at u (the south end by the access road).
func _jm_fence_v(u: float, v0: float, v1: float, gaps: Array) -> void:
	_jm_frame()
	var v := v0
	while v < v1:
		var nv := minf(v + 2.5, v1)
		var open := false
		for gp: Array in gaps:
			if nv > float(gp[0]) and v < float(gp[1]):
				open = true
		if not open:
			var g0 := _jm_ground(u, v)
			var g1 := _jm_ground(u, nv)
			_jm_bar(u, v, g0, u, v, g0 + 1.2, 0.08, JM_WIRE)
			_jm_bar(u, v, g0 + 1.15, u, nv, g1 + 1.15, 0.1, JM_WIRE)
			_jm_bar(u, v, g0 + 0.15, u, nv, g1 + 0.15, 0.1, JM_WIRE)
			_ubox(u - 0.02, u + 0.02, v, nv, minf(g0, g1) + 0.15, minf(g0, g1) + 1.15, Color("#55595d"), M_STONE)
			_collide(_urect(u - 0.1, u + 0.1, v, nv))
		v = nv


## A white banner on the fence: JARMARK over WARSZAWSKI in dark red, facing the street.
func _jm_banner(u: float, v: float) -> void:
	_jm_frame()
	var g := _jm_ground(u, v)
	_ubox(u - 2.6, u + 2.6, v - 0.06, v, g + 0.3, g + 1.75, JM_WHITE, M_STONE)
	_ubox(u + 1.7, u + 2.5, v - 0.08, v - 0.06, g + 0.5, g + 1.55, JM_RED, M_STONE)
	_jm_word("JARMARK", u - 0.4, v - 0.06, g + 1.1, 0.45, JM_RED, M_STONE)
	_jm_word("WARSZAWSKI", u - 0.4, v - 0.06, g + 0.5, 0.42, JM_TRIM, M_STONE)


## The gold WESOŁYCH ŚWIĄT sign (the drone frames): the words on a gold arched frame on two posts,
## blue stars along the top, facing the street (-v; turned `quarter` as a chalet).
func _jm_greeting(u: float, v: float, quarter := 0) -> void:
	var g := _jm_at(u, v, quarter)
	_no_roof = true
	_jm_word("WESOŁYCH", 0.0, 0.0, g + 3.3, 1.2, JM_GOLD, M_LAMP)
	_jm_word("ŚWIĄT", 0.0, 0.0, g + 1.0, 2.0, JM_GOLD, M_LAMP)
	var hw := 5.2
	for s: float in [-1.0, 1.0]:
		_ubox(s * hw - 0.06, s * hw + 0.06, 0.0, 0.12, g, g + 4.6, JM_WIRE, M_STONE)
	# The rails the letters stand on, post to post.
	_ubox(-hw, hw, -0.02, 0.1, g + 0.88, g + 1.0, JM_WIRE, M_STONE)
	_ubox(-hw, hw, -0.02, 0.1, g + 3.18, g + 3.3, JM_WIRE, M_STONE)
	var prev := Vector2(-hw, 4.5)
	for k in range(1, 15):
		var t := float(k) / 14.0
		var x := lerpf(-hw, hw, t)
		var y := 4.5 + 1.2 * sin(PI * t)
		_jm_bar(prev.x, 0.04, g + prev.y, x, 0.04, g + y, 0.14, JM_GOLD, M_LAMP)
		prev = Vector2(x, y)
	for k in 7:
		var t := (float(k) + 0.5) / 7.0
		var x := lerpf(-hw + 0.4, hw - 0.4, t)
		var sr := 0.5 if k % 2 == 0 else 0.34
		var y := 4.5 + 1.2 * sin(PI * t) + sr * 0.75
		_jm_star(_jm_p(x, 0.0, g + y), sr, Vector3(_a.x, 0.0, _a.y), JM_BLUE)
	_no_roof = false
	_collide(_rect(0.0, 0.0, hw + 0.1, 0.3))
	_jm_frame()


## A light-up tree on a pole `pole` m tall: three tiers of white LED, glowing at night, h metres tall.
func _jm_ledtree(u: float, v: float, h: float, pole := 0.8) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	_beam(Vector3(c.x, g, c.y), Vector3(c.x, g + pole, c.y), 0.1, JM_WIRE)
	var r := h * 0.3
	var keep := _mode
	_mode = M_LAMP
	for k in 3:
		var y0 := g + pole + h * 0.3 * k
		var r0 := r * (1.0 - 0.28 * k)
		_frustum(_circle(c, r0, 8), y0, _circle(c, r0 * 0.25, 8), y0 + h * 0.42, Color(0.78, 0.84, 0.92))
	_mode = keep
	_no_roof = false


## A big standing star of warm white tubes on a post (the drone frame by the entrance).
func _jm_bigstar(u: float, v: float, r: float) -> void:
	_jm_frame()
	var g := _jm_ground(u, v)
	_no_roof = true
	var cy := g + 1.2 + r
	_jm_bar(u, v + 0.08, g, u, v + 0.08, cy, 0.12, JM_WIRE)
	var prev := Vector2.ZERO
	for k in 11:
		var t := PI * 0.5 + TAU * float(k) / 10.0
		var rr := r if k % 2 == 0 else r * 0.42
		var p := Vector2(cos(t), sin(t)) * rr
		if k > 0:
			_jm_bar(u + prev.x, v, cy + prev.y, u + p.x, v, cy + p.y, 0.12, JM_BULB, M_LAMP)
		prev = p
	_no_roof = false


## The viewing tower carousel (nm-02, nm-12, the Palace's reel at night): a 38 m mast in rainbow LED
## bands on a round lit base, the gold carrier at 26 m with sixteen lit white spokes and chairs
## swinging out on chains, the orange crown on top.
func _jm_tower(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 5.0, 16), g, g + 0.6, Color("#d6d2ca"), Color("#c6c0b5"), M_STONE, M_STONE)
	_prism(_circle(c, 1.6, 8), g + 0.6, g + 2.2, Color("#3a3c40"), Color("#3a3c40"), M_STONE, M_STONE)
	_no_roof = true
	var ring := _circle(c, 4.75, 16)
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		_beam(Vector3(a.x, g + 0.66, a.y), Vector3(b.x, g + 0.66, b.y), 0.08, JM_RAINBOW[k % 7], false, M_LAMP)
		_beam(Vector3(a.x, g + 0.6, a.y), Vector3(a.x, g + 1.7, a.y), 0.06, JM_WIRE, false)
		_beam(Vector3(a.x, g + 1.7, a.y), Vector3(b.x, g + 1.7, b.y), 0.06, JM_WIRE, false)
	_no_roof = false
	# The mast in rainbow bands.
	var y := g + 2.2
	var top := g + 38.0
	var k := 0
	while y < top - 0.01:
		var y1 := minf(y + 1.8, top)
		_prism(_circle(c, 0.72, 8), y, y1, JM_RAINBOW[k % 7], Color(0, 0, 0, 0), M_LAMP, M_STONE)
		y = y1
		k += 1
	# The crown.
	_frustum(_circle(c, 0.8, 8), top, _circle(c, 1.7, 8), top + 1.3, Color("#f09a28"), Color("#f09a28"))
	_no_roof = true
	var crown := _circle(c, 1.7, 8)
	for p: Vector2 in crown:
		_beam(Vector3(p.x, top + 1.3, p.y), Vector3(p.x, top + 2.2, p.y), 0.16, JM_GOLD, false, M_LAMP)
	_no_roof = false
	_prism(_circle(c, 0.5, 8), top + 1.3, top + 2.4, JM_GOLD, JM_GOLD, M_LAMP, M_LAMP)
	_collide(_circle(c, 5.0, 12))
	# The ticket booth.
	_jm_hut(at.x + 7.5, at.y - 2.0, 3, Hut.RED, 0)


## The tower carousel's carrier (jarmark_rides.gd turns it and runs it up and down the mast): a
## gold bowl under a gold dome, bulbs round its belly, sixteen lit spokes, the chairs on their
## chains swung out to 10 m, a rider in twelve of them. Built at the top (26 m).
func _jm_tower_spin(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	var yc := g + TOWER_TOP
	_frustum(_circle(c, 1.0, 16), yc - 2.0, _circle(c, 3.4, 16), yc, JM_GOLD)
	_frustum(_circle(c, 3.4, 16), yc, _circle(c, 1.0, 16), yc + 1.4, JM_GOLD, JM_GOLD)
	for p: Vector2 in _circle(c, 3.0, 16):
		_prism(_circle(p, 0.1, 4), yc - 0.6, yc - 0.4, JM_LED, JM_LED, M_LAMP, M_LAMP)
	var chair_cols := [JM_YELLOW, JM_RED, JM_BLUE, Color("#3fb24f")]
	for j in 16:
		var t := TAU * (float(j) + 0.5) / 16.0
		var d := Vector2(cos(t), sin(t))
		var hub := c + d * 1.0
		var mid := c + d * 3.3
		var tip := c + d * 7.8
		_beam(Vector3(hub.x, yc + 1.4, hub.y), Vector3(tip.x, yc - 0.3, tip.y), 0.14, JM_LED, false, M_LAMP)
		_beam(Vector3(mid.x, yc, mid.y), Vector3(tip.x, yc - 0.3, tip.y), 0.08, JM_LED, false)
		var seat := c + d * 10.0
		var sy := yc - 6.0
		var side := Vector2(-d.y, d.x) * 0.3
		_beam(Vector3(tip.x + side.x, yc - 0.3, tip.y + side.y), Vector3(seat.x + side.x, sy + 0.6, seat.y + side.y), 0.03, JM_WIRE, false)
		_beam(Vector3(tip.x - side.x, yc - 0.3, tip.y - side.y), Vector3(seat.x - side.x, sy + 0.6, seat.y - side.y), 0.03, JM_WIRE, false)
		var col: Color = chair_cols[j % 4]
		_pow_box(seat, Vector2(-d.y, d.x), 0.3, 0.28, sy, sy + 0.12, col, col, M_LAMP)
		_pow_box(seat - d * 0.26, Vector2(-d.y, d.x), 0.3, 0.04, sy, sy + 0.6, col, col, M_LAMP)
		if j % 4 != 3:
			_jm_rider(seat - d * 0.08, Vector2(-d.y, d.x), sy + 0.12, j)


## The teacups (the PIK article's list): a blue platform with a lit rim, six white cups with blue
## bands on saucers, the big teapot in the middle.
func _jm_teacups(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 6.0, 16), g, g + 0.35, Color("#2e5fa8"), Color("#e6ecf4"), M_STONE, M_STONE)
	_prism(_circle(c, 6.03, 16), g + 0.2, g + 0.32, JM_LED, Color(0, 0, 0, 0), M_LAMP, M_STONE)
	_frustum(_circle(c, 1.0, 12), g + 0.35, _circle(c, 1.7, 12), g + 1.6, Color("#f4f2ee"))
	_frustum(_circle(c, 1.7, 12), g + 1.6, _circle(c, 0.9, 12), g + 2.8, Color("#f4f2ee"), Color("#f4f2ee"))
	_prism(_circle(c, 0.25, 8), g + 2.8, g + 3.2, Color("#3a6fc0"), Color("#3a6fc0"), M_STONE, M_STONE)
	_beam(_jm_p(at.x + 1.5, at.y, g + 1.6), _jm_p(at.x + 2.6, at.y, g + 2.6), 0.3, Color("#3a6fc0"))
	_beam(_jm_p(at.x - 1.6, at.y, g + 2.3), _jm_p(at.x - 2.2, at.y, g + 1.7), 0.18, Color("#3a6fc0"))
	_collide(_circle(c, 6.0, 12))


## The teacups' turning part (jarmark_rides.gd): six white cups with blue bands on their saucers,
## two riders in each, going round the teapot.
func _jm_teacups_spin(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	for k in 6:
		var t := TAU * float(k) / 6.0
		var p := c + Vector2(cos(t), sin(t)) * 3.9
		var col := Color("#f4f2ee")
		_prism(_circle(p, 1.3, 12), g + 0.35, g + 0.45, Color("#3a6fc0"), Color("#3a6fc0"), M_STONE, M_STONE)
		_frustum(_circle(p, 0.75, 12), g + 0.45, _circle(p, 1.15, 12), g + 1.35, col, Color("#7a4a30"))
		_prism(_circle(p, 1.17, 12), g + 1.05, g + 1.2, Color("#3a6fc0"), Color(0, 0, 0, 0), M_STONE, M_STONE)
		var d := Vector2(cos(t + 0.7 * k), sin(t + 0.7 * k))
		_jm_rider(p + d * 0.4, Vector2(-d.y, d.x), g + 0.75, k * 2)
		_jm_rider(p - d * 0.4, Vector2(-d.y, d.x), g + 0.75, k * 2 + 1)

## The Christmas-tree carousel's turning part (jarmark_rides.gd): the big tree is the carousel (the
## map's karuzela-choinka, the drone frame's white and red pods at its foot), so this is the ring of
## ten bauble cars on its platform going round the trunk, red and white with a gold cap, a child in
## six. The tree itself stands still (`_jm_tree`).
func _jm_tree_ride_spin(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y) + 0.35
	_g = g
	_no_roof = true
	for k in 10:
		var t := TAU * float(k) / 10.0
		var d := Vector2(cos(t), sin(t))
		var p := c + d * 6.1
		var col := JM_RED if k % 2 == 0 else Color("#f4f1ea")
		_frustum(_circle(p, 0.35, 10), g, _circle(p, 0.62, 10), g + 0.5, col, col)
		_frustum(_circle(p, 0.62, 10), g + 0.5, _circle(p, 0.3, 10), g + 1.15, col, col)
		_prism(_circle(p, 0.16, 6), g + 1.15, g + 1.35, JM_GOLD, JM_GOLD, M_STONE, M_STONE)
		if k % 5 in [0, 1, 3]:
			_jm_rider(p, Vector2(-d.y, d.x), g + 0.45, k + 3, 0.7)


## A rider (jarmark_rides.gd's rides): a shirt and a head, `n` picks the colours, `s` scales a child.
func _jm_rider(p: Vector2, d: Vector2, y: float, n: int, s := 1.0) -> void:
	var shirt: Color = JM_SHIRTS[n % JM_SHIRTS.size()]
	var skin: Color = [Color("#e8c4a4"), Color("#d6a882"), Color("#b98463"), Color("#f0d2b8")][n % 4]
	var hair: Color = [Color("#2a2420"), Color("#6b4a2e"), Color("#c9a25a"), Color("#3a2a22"), Color("#d8d4cc")][n % 5]
	if n % 3 == 0:
		hair = [JM_RED, Color("#f4f2ee"), JM_BLUE][n % 9 / 3]  # a winter hat
	_pow_box(p, d, 0.19 * s, 0.12 * s, y, y + 0.52 * s, shirt, shirt)
	_pow_box(p, d, 0.1 * s, 0.1 * s, y + 0.52 * s, y + 0.74 * s, skin, hair)

## Santa's house: a log cabin with snow on the roof, a red door, warm windows, a brick chimney and
## DOM MIKOŁAJA in gold over the door, its front turned `quarter` from -v (as a chalet's).
func _jm_santa(at: Vector2, quarter: int) -> void:
	var g := _jm_at(at.x, at.y, quarter)
	var hu := 3.0
	var hv := 2.4
	var logc := Color("#7a4a2a")
	_lbox(0.0, 0.0, hu, hv, g, g + 2.8, logc, M_STONE, logc.darkened(0.1))
	var y := g + 0.3
	while y < g + 2.8:
		_ubox(-hu - 0.06, hu + 0.06, -hv - 0.06, -hv, y, y + 0.1, logc.darkened(0.35), M_STONE)
		_ubox(-hu - 0.06, -hu, -hv, hv, y, y + 0.1, logc.darkened(0.35), M_STONE)
		_ubox(hu, hu + 0.06, -hv, hv, y, y + 0.1, logc.darkened(0.35), M_STONE)
		y += 0.36
	_gable(hu + 0.4, -hu - 0.4, 0.0, hv + 0.5, g + 2.8, 1.8, logc, JM_WHITE, true)
	_ubox(-0.55, 0.55, -hv - 0.1, -hv - 0.06, g, g + 2.0, JM_RED, M_STONE)
	for su: float in [-2.0, 2.0]:
		_ubox(su - 0.5, su + 0.5, -hv - 0.1, -hv - 0.06, g + 1.0, g + 2.0, JM_GLOW.lightened(0.15), M_LAMP)
	_ubox(1.4, 2.1, 0.5, 1.2, g + 3.5, g + 5.2, Color("#8a3a2c"), M_STONE, Color("#3a3a3a"))
	_jm_word("DOM MIKOŁAJA", 0.0, -hv - 0.6, g + 2.95, 0.45, JM_GOLD, M_LAMP)
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	_jm_frame()
