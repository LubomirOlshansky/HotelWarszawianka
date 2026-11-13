extends "res://scripts/place.gd"
## Skwer Linearny na Złotej (F, 2026-11-02): the furniture of the linear park Złota became between
## Marszałkowska and Jasna (opened 3 August 2026; RS Architektura Krajobrazu for the city). The map
## data has its lawns, tree pits, walks, flowerbeds and both fountains (OpenStreetMap), and
## tools/car_free.py takes the old car loop out and plants the limes; this adds what the data
## lacks, from the opening's photos and news: the pale stone blocks scattered on the lawns (people
## sit on them), the rock fountain mid-street (blocks round its pool, two low jets), long larch
## benches along the walks, the curved bench facing the fountain on the old tunnel ramp, café
## gardens under the trees by the facades, slim lamps and the retractable bollards at Jasna.
## Built at runtime on both city paths (it isn't in the sector scenes), as first_scene.gd: one mesh
## in the actors' material (models.gd), one draw call in view. The blocks stop the car; the rest is
## drive-through like the map's benches.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

## Marszałkowska's frame (first_scene.gd): `s` metres north along it, `t` metres east of it. Złota
## runs along t at s 37-72 (the facades), from the fountain (t 37-62) to Jasna (t 192).
const FRAME_O := Vector2(-937.0, 210.1)
const FRAME_S := Vector2(-0.34917, -0.93706)
const FRAME_T := Vector2(0.93706, -0.34917)
## Which way a piece's front faces in the frame: n (+s), s (-s), e (+t), w (-t), or an angle in
## degrees from +t towards +s.
const FACES := {"n": 90.0, "s": -90.0, "e": 0.0, "w": 180.0}
const STONE := [Color("#ddd6c6"), Color("#d2cab8"), Color("#e4dfd2"), Color("#c9c2b2")]

## [kind, s, t, face, extra]. block: extra = [w, h, d]; bench: extra = length; cafe: extra = canopy.
const ITEMS := [
	# The rock fountain: blocks round its pool (s 49-54, t 120-128), one in the water, two jets.
	["block", 55.2, 121.0, 8.0, [1.9, 0.75, 1.3]], ["block", 55.0, 126.6, -14.0, [1.6, 0.6, 1.2]],
	["block", 52.4, 130.0, 31.0, [2.1, 0.8, 1.4]], ["block", 48.3, 126.2, -6.0, [1.7, 0.7, 1.2]],
	["block", 48.1, 121.4, 19.0, [1.5, 0.55, 1.1]], ["block", 51.2, 118.0, -22.0, [1.8, 0.65, 1.3]],
	["block", 51.6, 124.4, 12.0, [1.4, 0.95, 1.1]],
	["spout", 52.4, 122.6, "e", null], ["spout", 50.6, 125.9, "e", null],
	# The big lawn round it: blocks loose in the grass.
	["block", 56.0, 112.0, 25.0, [2.0, 0.6, 1.2]], ["block", 49.4, 113.2, -9.0, [1.7, 0.55, 1.1]],
	["block", 53.0, 115.4, 40.0, [1.4, 0.5, 1.0]], ["block", 47.6, 132.4, 14.0, [2.2, 0.65, 1.3]],
	["block", 56.6, 131.0, -30.0, [1.6, 0.6, 1.2]], ["block", 52.6, 135.0, 5.0, [1.9, 0.7, 1.2]],
	["block", 48.2, 144.0, -18.0, [1.5, 0.55, 1.0]],
	# The lawns west and east.
	["block", 49.0, 97.8, 17.0, [1.8, 0.6, 1.2]], ["block", 50.6, 101.6, -25.0, [1.4, 0.5, 1.0]],
	["block", 48.0, 170.2, 8.0, [1.9, 0.65, 1.3]], ["block", 53.0, 178.0, -12.0, [1.6, 0.6, 1.1]],
	["block", 47.4, 182.4, 33.0, [1.4, 0.5, 1.0]],
	# Benches between the limes, facing the lawns.
	["bench", 66.0, 50.0, "s", 4.0], ["bench", 66.0, 67.5, "s", 4.0], ["bench", 66.0, 115.0, "s", 4.0],
	["bench", 66.0, 131.0, "s", 4.0], ["bench", 66.0, 171.5, "s", 4.0],
	["bench", 44.0, 66.5, "n", 4.0], ["bench", 44.0, 103.0, "n", 4.0], ["bench", 44.0, 130.5, "n", 4.0],
	["bench", 44.0, 145.8, "n", 3.5], ["bench", 44.0, 167.0, "n", 4.0],
	# The curved bench facing the fountain on the old tunnel ramp (centre s 52, t 48, radius 19).
	["arc", 52.0, 48.0, 19.0, [-0.36, 0.36, 5]],
	# Café gardens by the facades, under the limes.
	["cafe", 69.6, 78.0, "s", "#2f6b4f"], ["cafe", 69.6, 82.0, "s", "#f4f1de"], ["cafe", 69.6, 86.0, "s", "#2f6b4f"],
	["cafe", 69.6, 112.0, "s", "#c8282a"], ["cafe", 69.6, 116.0, "s", "#f4f1de"], ["cafe", 69.6, 120.0, "s", "#c8282a"],
	["cafe", 39.8, 100.0, "n", "#24324a"], ["cafe", 39.8, 104.0, "n", "#e8d36a"], ["cafe", 39.8, 108.0, "n", "#24324a"],
	["cafe", 39.8, 146.0, "n", "#e07a5f"], ["cafe", 39.8, 150.0, "n", "#f4f1de"], ["cafe", 39.8, 154.0, "n", "#e07a5f"],
	# Slim lamps along the walks (the photos' lamp posts), every 20 m or so.
	["lamp", 62.8, 44.0, "s", null], ["lamp", 62.8, 82.0, "s", null], ["lamp", 62.8, 104.0, "s", null],
	["lamp", 62.8, 125.0, "s", null], ["lamp", 62.8, 146.0, "s", null], ["lamp", 62.8, 168.0, "s", null],
	["lamp", 47.0, 70.0, "n", null], ["lamp", 46.6, 112.0, "n", null], ["lamp", 46.6, 137.0, "n", null],
	["lamp", 46.6, 160.0, "n", null], ["lamp", 46.6, 186.0, "n", null],
	# The retractable bollards across the Jasna end (residents and deliveries only).
	["bollards", 46.0, 188.0, "w", 5], ["bollards", 56.0, 188.0, "w", 5], ["bollards", 64.0, 188.0, "w", 4],
]



static func at(s: float, t: float) -> Vector2:
	return FRAME_O + FRAME_S * s + FRAME_T * t


## The yaw that turns a prop's -z front to `face` (FACES key or degrees from +t towards +s).
static func yaw_of(face: Variant) -> float:
	var deg: float = FACES[face] if face is String else float(face)
	var f := FRAME_T * cos(deg_to_rad(deg)) + FRAME_S * sin(deg_to_rad(deg))
	return atan2(-f.x, -f.y)


## Builds the mesh and the blocks' colliders; `map` gives the ground (map_builder.ground_height).
func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "SkwerZlotaSolids"
	body.set_meta(&"solid", &"prop")  # the city objects plan's solid class (solidity.gd)
	for item: Array in ITEMS:
		var kind: String = item[0]
		if kind == "arc":
			_arc(st, float(item[1]), float(item[2]), float(item[3]), item[4])
			continue
		var p := at(float(item[1]), float(item[2]))
		var xf := Transform3D(Basis(Vector3.UP, yaw_of(item[3])), Vector3(p.x, map.ground_height(p.x, p.y), p.y))
		match kind:
			"block":
				var size := Vector3(item[4][0], item[4][1], item[4][2])
				Props.add_stone_block(st, xf, size, STONE[count % STONE.size()])
				var shape := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = size
				shape.shape = box
				shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * size.y * 0.5)
				body.add_child(shape)
			"spout":
				Props.add_spout(st, xf)
			"bench":
				Props.add_long_bench(st, xf, float(item[4]))
			"cafe":
				Props.add_cafe_set(st, xf, Color(item[4]))
			"bollards":
				Props.add_bollards(st, xf, int(item[4]))
			"lamp":
				Props.add_park_lamp(st, xf)
		count += 1
	pour(st.commit(), true, "SkwerZlotaProps")
	part(body)


## A bench bent round a circle (centre s, t; radius r) from angle a0 to a1 (radians from +t towards
## +s) in n straight pieces, each facing the centre.
func _arc(st: SurfaceTool, s: float, t: float, r: float, spec: Array) -> void:
	var a0: float = spec[0]
	var a1: float = spec[1]
	var n: int = spec[2]
	var piece := 2.0 * r * sin((a1 - a0) / n * 0.5) - 0.15
	for k in n:
		var a := lerpf(a0, a1, (k + 0.5) / n)
		var p := at(s + r * sin(a), t + r * cos(a))
		var xf := Transform3D(Basis(Vector3.UP, yaw_of(rad_to_deg(a) + 180.0)), Vector3(p.x, map.ground_height(p.x, p.y), p.y))
		Props.add_long_bench(st, xf, piece)
		count += 1
