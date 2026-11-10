extends Node3D
## Plac Pięciu Rogów (F, 2026-11-06): the furniture of the square the junction of Chmielna,
## Szpitalna, Zgoda, Bracka and Krucza became (opened 5 July 2022). tools/car_free.py takes the
## asphalt out, lays the pale slabs over the whole outline, keeps the buses' and permit holders'
## route Szpitalna - Bracka/Krucza open to traffic (same slabs, no kerb), plants the three maples
## the scan lacks and turns OSM's raised pond into the flush wet patch; this adds what the map
## data has no layer for, from F's photos (/mnt/project-files/p5r-krucza/f-photos) and the GUGiK
## orthophoto read on the Mac (positions +-1-2 m): the concrete cubes with wooden seats in pairs
## along the route and under the trees, the plain cubes, the slim single-head lamps on the route's
## west edge, the café gardens (white and cream square umbrellas) by the facades, the speckled
## blue egg by the wet patch, and the bollards where the route turns into Krucza; and Chmielna's
## lamps and café gardens either side of it (CHMIELNA_ITEMS).
## Built at runtime on both city paths (it isn't in the sector scenes), as skwer_zlota.gd: one mesh
## in the actors' material (models.gd), one draw call in view. Cubes and the egg stop the car; the
## rest is drive-through like the map's benches.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

## The bus route's heading across the square (Szpitalna at -600,142 to Krucza at -556,203): the
## cubes are laid square to it, as on the photos.
const ROUTE_YAW := 0.62
const CONCRETE := [Color("#d9d5cc"), Color("#cfcac0"), Color("#e0ddd5")]
const SEAT := Color("#b8743f")
const EGG := Color("#4c78ae")

## [kind, x, z, extra]. seat: a 1.1 m cube with a wooden top; cube: a plain one ([w, h, d]);
## cafe: canopy colour; lamp; bollards: [count, yaw]; egg.
const ITEMS := [
	# Cubes with wooden seats (the ortho: 17, orange tops), along both sides of the route and
	# under the west trees.
	["seat", -592.2, 144.3, null], ["seat", -601.3, 148.7, null], ["seat", -598.2, 153.2, null],
	["seat", -583.6, 154.4, null], ["seat", -592.2, 161.1, null], ["seat", -626.3, 162.9, null],
	["seat", -592.7, 171.2, null], ["seat", -584.6, 171.6, null], ["seat", -570.5, 173.4, null],
	["seat", -577.2, 181.3, null], ["seat", -583.7, 183.3, null], ["seat", -580.7, 184.1, null],
	["seat", -559.7, 186.8, null], ["seat", -571.4, 188.9, null], ["seat", -554.8, 195.0, null],
	["seat", -553.7, 196.4, null], ["seat", -564.7, 198.4, null],
	# Plain cubes beside the middle row of maples (F's street-level photo: bare cubes between the
	# trees; the ortho can't pick them out, so these follow the row, low confidence).
	["cube", -596.6, 165.6, [1.4, 0.5, 1.4]], ["cube", -591.0, 177.8, [1.4, 0.5, 1.4]],
	["cube", -588.0, 176.2, [1.2, 0.45, 1.2]], ["cube", -582.0, 179.0, [1.4, 0.5, 1.4]],
	["cube", -604.0, 162.8, [1.2, 0.45, 1.2]], ["cube", -599.0, 179.8, [1.4, 0.5, 1.4]],
	# Slim lamps on the route's west edge, ~11 m apart (their shadows on the ortho).
	["lamp", -599.3, 150.5, null], ["lamp", -593.3, 159.0, null], ["lamp", -588.0, 166.0, null],
	["lamp", -581.7, 174.7, null], ["lamp", -574.8, 183.4, null], ["lamp", -568.3, 192.4, null],
	["lamp", -562.0, 201.0, null],
	# Café gardens: the north-west terrace under the trees, the tan umbrellas by Zgoda, the white
	# ones along the south-west facade.
	["cafe", -616.0, 161.0, "#f1ebdc"], ["cafe", -612.0, 161.0, "#f1ebdc"],
	["cafe", -616.0, 165.5, "#f1ebdc"], ["cafe", -612.0, 165.5, "#f1ebdc"],
	["cafe", -616.0, 178.5, "#cdb48a"], ["cafe", -612.5, 178.5, "#cdb48a"], ["cafe", -609.0, 178.5, "#cdb48a"],
	["cafe", -593.5, 190.0, "#f4f1e8"], ["cafe", -590.0, 192.3, "#f4f1e8"],
	["cafe", -576.5, 200.0, "#f4f1e8"], ["cafe", -573.0, 202.3, "#f4f1e8"],
	# The egg by the wet patch.
	["egg", -585.7, 189.7, null],
	# Bollards where the route meets Krucza (the dotted row on the ortho) and at the south-west.
	["bollards", -554.5, 207.5, [4, 0.55]], ["bollards", -551.8, 212.5, [4, 0.55]],
	["bollards", -609.5, 186.0, [4, 1.15]],
]

## ul. Chmielna either side of the square (F's photos, 2026-11-06: white café umbrellas along the
## facades under the young elms, slim single-head lamps): OSM maps 6 lamps on its 565 m and the
## street-details pass doesn't reach it. Laid along planted_trees.py's CHMIELNA line on 2026-11-06:
## a lamp every ~22 m on alternate sides (at most 4.5 m out, 1.2 m off the fronts), café sets in
## threes every ~38 m 1.8 m off a front 3.5-9.5 m away, all clear of the trees and benches.
const CHMIELNA_ITEMS := [
	["lamp", -842.0, 254.8, null], ["lamp", -824.1, 239.2, null], ["lamp", -800.4, 240.5, null],
	["lamp", -782.5, 224.8, null], ["lamp", -758.8, 226.1, null], ["lamp", -740.7, 210.7, null],
	["lamp", -717.0, 212.6, null], ["lamp", -698.7, 197.4, null], ["lamp", -675.1, 199.5, null],
	["lamp", -635.7, 177.8, null], ["lamp", -562.0, 165.8, null], ["lamp", -523.1, 143.8, null],
	["lamp", -499.7, 143.9, null], ["lamp", -481.6, 129.2, null], ["lamp", -437.1, 123.1, null],
	["lamp", -356.9, 85.8, null], ["lamp", -333.5, 86.0, null], ["cafe", -831.0, 249.9, "#f4f1e8"],
	["cafe", -827.6, 248.5, "#efe9dc"], ["cafe", -762.1, 216.5, "#f4f1e8"], ["cafe", -758.5, 216.1, "#e9e1cf"],
	["cafe", -755.0, 214.9, "#f4f1e8"], ["cafe", -725.7, 205.3, "#e9e1cf"], ["cafe", -722.2, 204.2, "#f4f1e8"],
	["cafe", -718.8, 203.2, "#efe9dc"], ["cafe", -687.0, 201.6, "#f4f1e8"], ["cafe", -679.8, 200.4, "#f4f1e8"],
	["cafe", -653.0, 182.8, "#efe9dc"], ["cafe", -649.6, 181.7, "#f4f1e8"], ["cafe", -534.6, 155.6, "#f4f1e8"],
	["cafe", -504.6, 137.4, "#f4f1e8"], ["cafe", -501.2, 136.2, "#e9e1cf"], ["cafe", -472.7, 124.4, "#f4f1e8"],
	["cafe", -468.7, 124.9, "#e9e1cf"], ["cafe", -465.3, 123.7, "#f4f1e8"], ["cafe", -433.3, 121.7, "#e9e1cf"],
	["cafe", -430.5, 119.0, "#f4f1e8"], ["cafe", -394.5, 106.8, "#efe9dc"], ["cafe", -391.1, 105.6, "#f4f1e8"],
	["cafe", -360.9, 87.7, "#f4f1e8"], ["cafe", -357.5, 86.6, "#e9e1cf"], ["cafe", -326.2, 82.7, "#f4f1e8"],
	["cafe", -322.8, 81.5, "#e9e1cf"],
]

var map: Node3D
var count := 0


## Builds the mesh and the solids' colliders; `map` gives the ground (map_builder.ground_height).
func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "PlacPieciuRogowSolids"
	for item: Array in ITEMS + CHMIELNA_ITEMS:
		var kind: String = item[0]
		var x := float(item[1])
		var z := float(item[2])
		var yaw := ROUTE_YAW
		if kind == "bollards":
			yaw = float(item[3][1])
		var xf := Transform3D(Basis(Vector3.UP, yaw), Vector3(x, map.ground_height(x, z), z))
		match kind:
			"seat":
				var size := Vector3(1.1, 0.42, 1.1)
				Props.add_stone_block(st, xf, size, CONCRETE[count % CONCRETE.size()])
				Props.obox(st, xf * Vector3(0, 0.45, 0), xf.basis, Vector3(1.0, 0.06, 1.0), SEAT)
				_solid(body, xf, Vector3(1.1, 0.5, 1.1))
			"cube":
				var size := Vector3(item[3][0], item[3][1], item[3][2])
				Props.add_stone_block(st, xf, size, CONCRETE[count % CONCRETE.size()])
				_solid(body, xf, size)
			"lamp":
				Props.add_park_lamp(st, xf)
			"cafe":
				Props.add_cafe_set(st, xf, Color(item[3]))
			"bollards":
				Props.add_bollards(st, xf, int(item[3][0]))
			"egg":
				_egg(st, xf)
				_solid(body, xf, Vector3(3.2, 2.4, 2.3))
		count += 1
	var mi := MeshInstance3D.new()
	mi.name = "PlacPieciuRogowProps"
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	add_child(mi)
	add_child(body)


func _solid(body: StaticBody3D, xf: Transform3D, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * size.y * 0.5)
	body.add_child(shape)


## The egg: an ellipsoid 3.5 m long (along x), 2.4 m high and 2.4 m across lying on the slabs,
## its pointed end a little narrower, speckled by alternating facets of two blues. 8 x 12 facets.
func _egg(st: SurfaceTool, xf: Transform3D) -> void:
	var rings := 8
	var segs := 12
	var pts: Array = []
	for i in rings + 1:
		var a := PI * i / rings  # 0 at the blunt end, PI at the point
		var along := -cos(a) * 1.75
		var r := sin(a) * 1.2 * (1.0 - 0.12 * (1.0 - cos(a)) * 0.5)
		var row: Array = []
		for j in segs:
			var b := TAU * j / segs
			row.append(xf * Vector3(along, 1.2 + r * cos(b), r * sin(b)))
		pts.append(row)
	for i in rings:
		for j in segs:
			var p00: Vector3 = pts[i][j]
			var p01: Vector3 = pts[i][(j + 1) % segs]
			var p10: Vector3 = pts[i + 1][j]
			var p11: Vector3 = pts[i + 1][(j + 1) % segs]
			var col := EGG if (i + j) % 3 != 0 else EGG.darkened(0.25)
			# Outward: from the egg's centre through the facet (tri winds the triangle to face n).
			var n := ((p00 + p11) * 0.5 - xf * Vector3(0, 1.2, 0)).normalized()
			Props.tri(st, p00, p10, p01, n, col)
			Props.tri(st, p01, p10, p11, n, col)
