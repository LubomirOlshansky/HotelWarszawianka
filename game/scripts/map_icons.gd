extends RefCounted
## F's ask (2026-10-31, BACKLOG top): the full map's landmark icons. Each is a round badge on a
## pin (a dark rim, its category's colour) with a small flat silhouette in it, drawn from a few
## primitives in a unit box (-1..1, y down) into hud.gd's triangle batch, so all of them together
## are one draw call. Original shapes, our own: a stepped tower with a spire for Pałac Kultury,
## a dome for the Rotunda, a bowl for the stadium, a tower over a long front for the Castle...
##
## Primitives: ["r", x0, y0, x1, y1] a rectangle; ["t", ax, ay, bx, by, cx, cy] a triangle;
## ["c", cx, cy, radius] a disc; ["h", cx, cy, radius] the disc's top half; ["e", cx, cy, rx, ry,
## thickness] an elliptic ring; ["q", ax, ay, bx, by, cx, cy, dx, dy] a quad. A primitive's last
## element may be a colour key ("ink" when left out): ink (the silhouette's cream), dark (the
## rim), red, green, badge (the badge's own colour: to cut a hole).

## G11: the shapes of the side-job places' marks (hud.gd `poi_mark`; the minimap and the full map).
const POI_SQUARE := 0
const POI_KEBAB := 1
const POI_STATION := 2
const POI_DEPOT := 3
const POI_SCOOTER := 4
## The free-ride boat at the start pontoon (boat_race.gd, F 2026-11-07).
const POI_BOAT := 5

const INK := Color("#fff8e8")
const DARK := Color("#1d1a24")
const RED := Color("#e0313c")
const GREEN := Color("#3fae49")

## Category colours.
const ROYAL := Color("#c8324a")
const CULTURE := Color("#7b52d1")
const TOWER := Color("#2f63d6")
const GOLD := Color("#e39b16")
const RAIL := Color("#169b8b")
const BRIDGE := Color("#1f7fc0")
const SPORT := Color("#e2483c")
const SHOP := Color("#f07b1f")
const FUN := Color("#e04b93")
## G11: the underground's and the hospitals' (not landmarks: the ordinary places the car needs).
const METRO := Color("#3a3f9a")
const HOSPITAL := Color("#f4f1ea")

const _PORTICO := [["t", -0.72, -0.28, 0.72, -0.28, 0.0, -0.66], ["r", -0.66, -0.28, 0.66, -0.14],
		["r", -0.56, -0.14, -0.4, 0.44], ["r", -0.22, -0.14, -0.06, 0.44], ["r", 0.06, -0.14, 0.22, 0.44],
		["r", 0.4, -0.14, 0.56, 0.44], ["r", -0.72, 0.44, 0.72, 0.6]]

const SHAPES := {
	"palace": [["r", -0.62, 0.56, 0.62, 0.7], ["r", -0.62, 0.22, -0.34, 0.56], ["r", 0.34, 0.22, 0.62, 0.56],
		["r", -0.34, -0.06, 0.34, 0.56], ["r", -0.22, -0.34, 0.22, -0.06], ["r", -0.13, -0.52, 0.13, -0.34],
		["t", -0.07, -0.52, 0.07, -0.52, 0.0, -0.9]],
	"rotunda": [["h", 0.0, 0.18, 0.56], ["r", -0.62, 0.18, 0.62, 0.46], ["r", -0.08, -0.5, 0.08, -0.36],
		["r", -0.44, 0.24, -0.3, 0.42, "badge"], ["r", -0.07, 0.24, 0.07, 0.42, "badge"],
		["r", 0.3, 0.24, 0.44, 0.42, "badge"]],
	"stadium": [["e", 0.0, 0.0, 0.72, 0.5, 0.2], ["e", 0.0, 0.0, 0.72, 0.5, 0.08, "red"],
		["q", -0.34, -0.18, 0.34, -0.18, 0.34, 0.18, -0.34, 0.18, "green"]],
	"zamek": [["r", -0.68, -0.02, 0.68, 0.58], ["r", -0.15, -0.46, 0.15, -0.02],
		["t", -0.22, -0.46, 0.22, -0.46, 0.0, -0.88], ["r", -0.5, 0.14, -0.34, 0.34, "badge"],
		["r", 0.34, 0.14, 0.5, 0.34, "badge"], ["r", -0.08, 0.26, 0.08, 0.58, "badge"]],
	"zygmunt": [["r", -0.08, -0.42, 0.08, 0.46], ["r", -0.28, 0.46, 0.28, 0.66], ["c", 0.0, -0.62, 0.14],
		["r", -0.3, -0.56, 0.3, -0.48], ["r", -0.18, -0.46, 0.18, -0.38]],
	"barbakan": [["r", -0.56, 0.02, 0.56, 0.6], ["r", -0.7, -0.24, -0.3, 0.6], ["r", 0.3, -0.24, 0.7, 0.6],
		["t", -0.76, -0.24, -0.24, -0.24, -0.5, -0.66], ["t", 0.24, -0.24, 0.76, -0.24, 0.5, -0.66],
		["h", 0.0, 0.6, 0.2, "badge"]],
	"kopernik": [["c", 0.0, 0.0, 0.44], ["e", 0.0, 0.0, 0.82, 0.26, 0.09], ["c", 0.52, -0.42, 0.1]],
	"poniatowski": [["r", -0.8, 0.14, 0.8, 0.3], ["r", -0.48, -0.42, -0.3, 0.14], ["r", 0.3, -0.42, 0.48, 0.14],
		["t", -0.54, -0.42, -0.24, -0.42, -0.39, -0.62], ["t", 0.24, -0.42, 0.54, -0.42, 0.39, -0.62],
		["h", -0.62, 0.62, 0.22], ["h", 0.0, 0.62, 0.26], ["h", 0.62, 0.62, 0.22]],
	"swieto": [["r", -0.82, 0.32, 0.82, 0.44], ["q", -0.1, 0.32, 0.12, 0.32, 0.06, -0.8, -0.02, -0.8],
		["t", 0.01, -0.72, 0.05, -0.62, -0.72, 0.32], ["t", 0.01, -0.58, 0.04, -0.48, -0.44, 0.32],
		["t", 0.03, -0.72, 0.07, -0.62, 0.74, 0.32], ["t", 0.04, -0.58, 0.07, -0.48, 0.46, 0.32]],
	"bridge": [["r", -0.8, -0.04, 0.8, 0.12], ["h", 0.0, 0.62, 0.42], ["h", 0.0, 0.62, 0.3, "badge"],
		["h", -0.66, 0.62, 0.22], ["h", 0.66, 0.62, 0.22]],
	"varso": [["r", -0.2, -0.36, 0.2, 0.72], ["t", -0.2, -0.36, 0.2, -0.36, 0.0, -0.58],
		["r", -0.03, -0.92, 0.03, -0.5], ["r", -0.48, 0.3, -0.24, 0.72], ["r", 0.24, 0.12, 0.46, 0.72]],
	"spire": [["q", -0.24, 0.72, 0.24, 0.72, 0.24, -0.56, -0.24, -0.84], ["r", -0.52, 0.24, -0.3, 0.72],
		["r", 0.3, 0.36, 0.52, 0.72], ["r", -0.02, -0.4, 0.02, 0.62, "badge"]],
	"zlota44": [["q", -0.3, 0.72, 0.3, 0.72, 0.2, -0.4, -0.12, -0.8], ["t", 0.2, -0.4, -0.12, -0.8, 0.3, -0.62]],
	"tarasy": [["r", -0.72, 0.18, 0.72, 0.56], ["h", -0.4, 0.18, 0.32], ["h", 0.02, 0.18, 0.42], ["h", 0.44, 0.18, 0.3],
		["r", -0.6, 0.3, 0.6, 0.38, "badge"]],
	"centralna": [["q", -0.66, -0.44, 0.5, -0.44, 0.7, 0.36, -0.66, 0.36], ["r", -0.52, -0.3, -0.12, -0.04, "badge"],
		["r", 0.0, -0.3, 0.38, -0.04, "badge"], ["c", -0.34, 0.46, 0.16], ["c", 0.34, 0.46, 0.16],
		["r", -0.8, 0.62, 0.8, 0.7]],
	"sejm": [["h", 0.0, -0.14, 0.5], ["r", -0.66, -0.14, 0.66, -0.02], ["r", -0.56, -0.02, -0.4, 0.44],
		["r", -0.22, -0.02, -0.06, 0.44], ["r", 0.06, -0.02, 0.22, 0.44], ["r", 0.4, -0.02, 0.56, 0.44],
		["r", -0.72, 0.44, 0.72, 0.6]],
	"portico": _PORTICO,
	"grob": [["r", -0.72, -0.28, 0.72, 0.56], ["r", -0.6, 0.02, -0.28, 0.56, "badge"], ["h", -0.44, 0.02, 0.16, "badge"],
		["r", -0.16, 0.02, 0.16, 0.56, "badge"], ["h", 0.0, 0.02, 0.16, "badge"],
		["r", 0.28, 0.02, 0.6, 0.56, "badge"], ["h", 0.44, 0.02, 0.16, "badge"],
		["t", -0.12, -0.28, 0.12, -0.28, 0.0, -0.74, "red"]],
	"bag": [["r", -0.5, -0.18, 0.5, 0.66], ["e", 0.0, -0.18, 0.26, 0.36, 0.1], ["r", -0.5, -0.2, 0.5, 0.0]],
	"flaga": [["r", -0.52, -0.8, -0.42, 0.74], ["r", -0.42, -0.74, 0.58, -0.4], ["r", -0.42, -0.4, 0.58, -0.06, "red"],
		["r", -0.66, 0.62, -0.28, 0.74]],
	"palm": [["q", -0.06, 0.72, 0.1, 0.72, 0.1, -0.38, 0.0, -0.38], ["t", 0.04, -0.42, -0.72, -0.2, -0.4, -0.58, "green"],
		["t", 0.04, -0.42, 0.76, -0.2, 0.44, -0.6, "green"], ["t", 0.04, -0.42, -0.2, -0.86, 0.22, -0.84, "green"],
		["t", 0.04, -0.42, -0.62, 0.06, -0.62, -0.3, "green"], ["t", 0.04, -0.42, 0.68, 0.08, 0.7, -0.28, "green"]],
	"metro": [["r", -0.62, -0.5, -0.4, 0.56], ["r", 0.4, -0.5, 0.62, 0.56],
		["q", -0.62, -0.5, -0.36, -0.5, 0.0, 0.1, 0.0, 0.46], ["q", 0.62, -0.5, 0.36, -0.5, 0.0, 0.1, 0.0, 0.46]],
	"hospital": [["r", -0.2, -0.64, 0.2, 0.64, "red"], ["r", -0.64, -0.2, 0.64, 0.2, "red"]],
	"hall": [["r", -0.66, -0.06, 0.66, 0.6], ["t", -0.76, -0.06, 0.76, -0.06, 0.0, -0.6],
		["h", -0.34, 0.6, 0.16, "badge"], ["h", 0.0, 0.6, 0.2, "badge"], ["h", 0.34, 0.6, 0.16, "badge"]],
}

## The icons, most important first (they win where icons crowd): [landmark key (landmarks.gd INFO;
## "palm" and "most:<name>" are found otherwise), shape, colour, label pl, label en].
const ICONS := [
	["palace", "palace", GOLD, "Pałac Kultury", "Palace of Culture"],
	["zamek", "zamek", ROYAL, "Zamek Królewski", "Royal Castle"],
	["stadium", "stadium", SPORT, "Stadion Narodowy", "National Stadium"],
	["rotunda", "rotunda", FUN, "Rotunda", "the Rotunda"],
	["centralna", "centralna", RAIL, "Dworzec Centralny", "Central Station"],
	["swieto", "swieto", BRIDGE, "Most Świętokrzyski", "Świętokrzyski Bridge"],
	["poniatowski", "poniatowski", BRIDGE, "Most Poniatowskiego", "Poniatowski Bridge"],
	["most:Most Śląsko-Dąbrowski", "bridge", BRIDGE, "Most Śląsko-Dąbrowski", "Śląsko-Dąbrowski Bridge"],
	["most:Most Łazienkowski", "bridge", BRIDGE, "Most Łazienkowski", "Łazienkowski Bridge"],
	["zygmunt", "zygmunt", ROYAL, "Kolumna Zygmunta", "Sigismund's Column"],
	["kopernik", "kopernik", CULTURE, "Centrum Kopernik", "Copernicus Centre"],
	["palm", "palm", GREEN, "Palma", "the Palm"],
	["varso", "varso", TOWER, "Varso", "Varso Tower"],
	["zlota44", "zlota44", TOWER, "Złota 44", "Złota 44"],
	["spire", "spire", TOWER, "Warsaw Spire", "Warsaw Spire"],
	["tarasy", "tarasy", SHOP, "Złote Tarasy", "Złote Tarasy"],
	["barbakan", "barbakan", ROYAL, "Barbakan", "the Barbican"],
	["grob", "grob", ROYAL, "Grób Nieznanego Żołnierza", "Tomb of the Unknown Soldier"],
	["teatr", "portico", CULTURE, "Teatr Wielki", "Grand Theatre"],
	["sejm", "sejm", CULTURE, "Sejm", "the Sejm"],
	["muzeum", "portico", CULTURE, "Muzeum Narodowe", "National Museum"],
	["prezydencki", "portico", ROYAL, "Pałac Prezydencki", "Presidential Palace"],
	["mirowska", "hall", SHOP, "Hala Mirowska", "Mirowska Hall"],
	["gwardii", "hall", SHOP, "Hala Gwardii", "Gwardii Hall"],
	["arkadia", "bag", SHOP, "Arkadka", "Arkadka mall"],
	["flaga", "flaga", FUN, "Flaga", "the Flag"],
]


## The icons placed: [{at (map m), shape, colour, pl, en}] in ICONS' order, for the landmarks
## that exist on this map (`info`: map_builder.gd `landmark_info`), the palm (centrum.json `palm`)
## and the bridges (map_art.gd `bridges`).
static func place(info: Array, palm: Array, bridges: Dictionary) -> Array[Dictionary]:
	var at := {}
	for l: Dictionary in info:
		var k := str(l.get("key", ""))
		if not at.has(k):
			at[k] = l["centre"]
	if palm.size() >= 2:
		at["palm"] = Vector2(float(palm[0]), float(palm[1]))
	for n in bridges:
		at["most:" + str(n)] = bridges[n]
	var out: Array[Dictionary] = []
	for row: Array in ICONS:
		if at.has(row[0]):
			out.append({"key": row[0], "at": at[row[0]], "shape": row[1], "colour": row[2], "pl": row[3], "en": row[4]})
	return out


## G11: the ordinary places' pins, after the landmarks (they give way where pins crowd): one metro
## pin for each cluster of subway entrances within 160 m (at their mean), one for each hospital.
## `pois` is centrum.json's list ({k, x, z, name}).
static func place_extras(pois: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var clusters: Array[Dictionary] = []
	for p: Dictionary in pois:
		var at := Vector2(float(p.get("x", 0.0)), float(p.get("z", 0.0)))
		match str(p.get("k", "")):
			"subway_entrance":
				var hit := false
				for c in clusters:
					if (c["sum"] as Vector2 / float(c["n"])).distance_to(at) < 160.0:
						c["sum"] = (c["sum"] as Vector2) + at
						c["n"] = int(c["n"]) + 1
						hit = true
						break
				if not hit:
					clusters.append({"sum": at, "n": 1})
			"hospital":
				var name := str(p.get("name", "Szpital"))
				out.append({"key": "hospital", "at": at, "shape": "hospital", "colour": HOSPITAL, "pl": name, "en": name})
	for c in clusters:
		out.append({"key": "metro", "at": (c["sum"] as Vector2) / float(c["n"]), "shape": "metro", "colour": METRO,
				"pl": "Metro", "en": "Metro"})
	return out


## One icon, its pin's point at `tip` (px), the badge's radius r (px), into hud's batch.
static func paint(hud, shape: String, colour: Color, tip: Vector2, r: float) -> void:
	var c := tip - Vector2(0.0, r * 1.45)
	# The pin's tail, the rim, the badge.
	hud._tri(tip + Vector2(0.0, r * 0.12), c + Vector2(-r * 0.62, r * 0.6), c + Vector2(r * 0.62, r * 0.6), DARK, DARK, DARK)
	_disc(hud, c, r + maxf(1.5, r * 0.14), DARK)
	_disc(hud, c, r, colour)
	_ring(hud, c, r * 0.86, r * 0.92, colour.lightened(0.35))
	_shape(hud, shape, c, r * 0.62, {"ink": INK, "dark": DARK, "red": RED, "green": GREEN, "badge": colour})


## F (2026-11-07): "the landmarks shout; draw them on the map, quieter". A landmark as a small
## silhouette printed on the map itself, centred at `at` (`r` about the old badge's radius): no
## pin and no badge, the shape in its category's colour darkened, on a soft cream halo so it reads
## on the streets. The main star, the questline "!" badges and the jobs stay the loud marks.
static func paint_quiet(hud, shape: String, colour: Color, at: Vector2, r: float, alpha := 0.9) -> void:
	var ink := Color(colour.darkened(0.35), alpha)
	var halo := Color(1.0, 0.97, 0.9, 0.55 * alpha)
	_disc(hud, at, r * 0.95, Color(halo, halo.a * 0.6))
	var hole := Color(1.0, 0.97, 0.9, 0.85 * alpha)
	_shape(hud, shape, at, r * 0.78, {"ink": ink, "dark": ink, "red": Color(RED, alpha), "green": Color(GREEN, alpha), "badge": hole})


## A shape's primitives (SHAPES[shape]) round `c` at scale `k` (px per unit), each in `cols`'s
## colour for its key (ink when left out).
static func _shape(hud, shape: String, c: Vector2, k: float, cols: Dictionary) -> void:
	for p: Array in SHAPES.get(shape, []):
		var key := "ink"
		if p.size() > 1 and p[p.size() - 1] is String:
			key = p[p.size() - 1]
		var col: Color = cols.get(key, cols["ink"])
		var at := func(i: int) -> Vector2: return c + Vector2(float(p[i]), float(p[i + 1])) * k
		match String(p[0]):
			"r":
				var a: Vector2 = at.call(1)
				var b: Vector2 = at.call(3)
				hud._tri_rect(Rect2(a, b - a), col)
			"t":
				hud._tri(at.call(1), at.call(3), at.call(5), col, col, col)
			"q":
				hud._tri_quad(at.call(1), at.call(3), at.call(5), at.call(7), [col, col, col, col])
			"c":
				_disc(hud, at.call(1), float(p[3]) * k, col)
			"h":
				_half(hud, at.call(1), float(p[3]) * k, col)
			"e":
				_ellipse(hud, at.call(1), float(p[3]) * k, float(p[4]) * k, float(p[5]) * k, col)


static func _disc(hud, c: Vector2, r: float, col: Color, n := 20) -> void:
	for i in n:
		hud._tri(c, c + Vector2.from_angle(TAU * i / n) * r, c + Vector2.from_angle(TAU * (i + 1) / n) * r, col, col, col)


static func _ring(hud, c: Vector2, r0: float, r1: float, col: Color, n := 24) -> void:
	for i in n:
		var u := Vector2.from_angle(TAU * i / n)
		var v := Vector2.from_angle(TAU * (i + 1) / n)
		hud._tri_quad(c + u * r0, c + u * r1, c + v * r1, c + v * r0, [col, col, col, col])


## The top half of a disc (screen y down).
static func _half(hud, c: Vector2, r: float, col: Color, n := 10) -> void:
	for i in n:
		var a0 := PI + PI * i / n
		var a1 := PI + PI * (i + 1) / n
		hud._tri(c, c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a1) * r, col, col, col)


static func _ellipse(hud, c: Vector2, rx: float, ry: float, w: float, col: Color, n := 20) -> void:
	for i in n:
		var u := Vector2.from_angle(TAU * i / n)
		var v := Vector2.from_angle(TAU * (i + 1) / n)
		var s0 := Vector2(rx, ry)
		var s1 := Vector2(maxf(rx - w, 0.0), maxf(ry - w, 0.0))
		hud._tri_quad(c + u * s1, c + u * s0, c + v * s0, c + v * s1, [col, col, col, col])
