extends RefCounted
## Powiśle's photographed houses off Tamka (F's photo set, docs/powisle-photos-needed.txt H list):
## each one's plaster and trim read from its photos, matched to the OpenStreetMap house whose outline
## holds the point. map_builder._tamka_look asks here first; Tamka's own houses stay in tamka.gd.
## Style keys as TenementTrim.wall takes them (balc: balcony rail colour, base: ground-floor band,
## shops: false for offices and glass ground floors) plus `fronts`: the outward normals of the walls
## that face a named street (from centrum.json), so balconies and bases go only there, in every
## sector, whatever roads the sector holds.

## Where the table applies (map metres): Powiśle from Foksal to Solec, Smolna to the river.
const AREA := Rect2(-200.0, -1150.0, 1100.0, 1300.0)
## How close a wall's normal must be to a front's (cosine).
const FRONT_DOT := 0.8

## [x, z (a point inside the house), plaster, style]
const HOUSES := [
	[23.0, -711.0, "#cdbf9f", {"balc": "#3b3a35", "fronts": [Vector2(0.5, 0.9), Vector2(0.9, -0.5)]}],  # Leszczyńska 10
	[156.0, -826.0, "#dcd5cb", {"balc": "#9db8b6", "fronts": [Vector2(-0.9, 0.5), Vector2(-0.5, -0.9), Vector2(-0.5, -0.8), Vector2(0.5, 0.9)]}],  # Leszczyńska 4
	[-85.0, -753.0, "#e1e4e8", {"balc": "#2c2d30", "base": "#2f5d45", "fronts": [Vector2(-0.9, 0.4), Vector2(0.5, 0.9), Vector2(0.9, -0.4)]}],  # Browarna 6
	[331.0, -383.0, "#e2bf58", {"base": "#33373c", "fronts": [Vector2(0.7, -0.7), Vector2(0.8, -0.6), Vector2(0.8, 0.6)]}],  # Dobra 17
	[127.0, -446.0, "#bab3a3", {"balc": "#3a3a3a", "fronts": [Vector2(-0.9, 0.4)]}],  # Topiel 6
	[446.0, -330.0, "#d0d1cf", {"balc": "#1f1f1f", "base": "#8e8f90", "fronts": [Vector2(-0.8, 0.7), Vector2(0.8, -0.6), Vector2(0.8, 0.6)]}],  # Dobra 8/10
	[759.0, -37.0, "#a19e98", {"base": "#7a4e4e", "fronts": [Vector2(-0.8, -0.6), Vector2(-0.6, 0.8), Vector2(-0.3, -0.9), Vector2(0.4, 0.9), Vector2(0.8, 0.6)]}],  # Solec 30A
	[533.0, -57.0, "#e7cf8c", {"balc": "#3a3530", "base": "#d6a34c", "fronts": [Vector2(-0.9, 0.3)]}],  # Aleja 3 Maja 14
	[636.0, 2.0, "#e8e6e0", {"balc": "#d6d6d2", "fronts": [Vector2(-0.9, 0.3), Vector2(-0.3, -1.0), Vector2(-0.3, -0.9), Vector2(0.7, -0.7)]}],  # Aleja 3 Maja 5
	[221.0, -527.0, "#a88670", {"balc": "#1e1e1e", "fronts": [Vector2(-0.5, -0.9), Vector2(0.8, -0.6), Vector2(0.9, -0.5)]}],  # Dobra 31 (Kamienica Struskiego)
	[65.0, -451.0, "#d4d0c6", {"base": "#3d3f42", "shops": false, "fronts": [Vector2(-0.9, 0.5), Vector2(-0.5, -0.9), Vector2(-0.4, -0.9), Vector2(0.4, 0.9), Vector2(0.9, -0.4)]}],  # Zajęcza 15 (Carpathia)
	[329.0, -685.0, "#e9e9e6", {"shops": false}],  # Zajęcza 2A (RPZ substation)
	[522.8, -414.8, "#e2dbc9", {"fronts": [Vector2(-0.6, 0.8), Vector2(0.8, 0.6)]}],  # Smulikowskiego 6/8 (ZNP)
	[-9.0, -77.0, "#a9aeb1", {"shops": false}],  # Foksal 2A (SARP pavilion)
	[353.0, -673.0, "#a3533b", {"shops": false, "fronts": [Vector2(-0.6, -0.8), Vector2(-0.6, 0.8), Vector2(0.6, -0.8), Vector2(0.6, 0.8), Vector2(0.8, -0.6)]}],  # Barceló hotel
	[493.1, -54.2, "#8b6b59", {"shops": false, "fronts": [Vector2(-0.7, 0.7), Vector2(-0.6, 0.8), Vector2(0.3, 0.9)]}],  # Nordic Park
	[177.0, -14.0, "#b0573b", {"shops": false}],  # Klub Bankowca
	[-48.0, 90.0, "#9f9a92", {"shops": false, "fronts": [Vector2(-0.3, -0.9), Vector2(0.3, 0.9), Vector2(0.9, -0.3)]}],  # XVIII LO Zamoyskiego
	[-60.0, -1090.0, "#ecebe6", {"shops": false}],  # Artes Liberales
]


## The photo look of the house with outline `poly`: {"plaster", "style"}, or {} for any other house.
static func look(poly: PackedVector2Array, centre: Vector2) -> Dictionary:
	if not AREA.has_point(centre):
		return {}
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	box = box.grow(1.0)
	for h: Array in HOUSES:
		var at := Vector2(float(h[0]), float(h[1]))
		if box.has_point(at) and Geometry2D.is_point_in_polygon(at, poly):
			return {"plaster": Color(h[2]), "style": h[3]}
	return {}


## Whether a wall with outward normal `n` (flat) faces one of the style's fronts.
static func faces_front(style: Dictionary, n: Vector2) -> bool:
	for f: Vector2 in style.get("fronts", []):
		if f.normalized().dot(n) > FRONT_DOT:
			return true
	return false
