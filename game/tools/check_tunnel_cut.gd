extends SceneTree
## F (2026-11-08): the tunnel cutaway (shaders/tunnel_cut.gdshaderinc, main.gd `_update_tunnel_cut`):
## while the car drives in a tunnel the ground over it opens round the car. From the map's data alone
## (no meshes), with a CPU copy of the shader's test:
##
## 1. Every tunnel piece's centreline every STEP m, the car on its floor wherever the piece runs
##    under the ground (map_builder.gd `in_tunnel`): `tunnel_cut_chords` gives chords, the car stands
##    inside their corridor, and the ground that hides the car from the camera (YAWS directions at
##    the game's pitch) opens. At least PIECE_MIN samples (the Wisłostrada, Trasa W-Z and Plac Zawiszy tubes...).
## 2. The car up on the street over the same points: no chords (the ground stays whole).
## 3. Open streets: no chords.
## 4. The ground FAR m to the side of a tunnel never opens (the cut keeps to the corridor).
##
## Prints `check_tunnel_cut: OK` or the failures and exit 1. ~10 s.
##   godot --headless --path game --script res://tools/check_tunnel_cut.gd [-- --verbose]

const MapBuilder := preload("res://scripts/map_builder.gd")
const MAP_PATH := "res://map/centrum.json"
const PITCH := 30.0
const YAWS := 4
const STEP := 10.0
const REACH := 18.0      # main.gd: clampf(cam.size * TUNNEL_CUT_SIZE, ...) at the default view
const PAST := 24.0       # main.gd TUNNEL_CUT_PAST
const CHORDS := 6        # main.gd TUNNEL_CUT_CHORDS, the shader's TUNNEL_SEGS
const OVER := 2.5        # the shader's TUNNEL_CUT_OVER
const FAR := 30.0
## A view ray that comes out of the ground this close to a portal leaves through the mouth.
const END := 8.0
const PIECE_MIN := 100

## [x, z, what]: no tunnel under the car here.
const OPEN := [
	[-1013.0, -45.0, "Marszałkowska by Centrum"],
	[-387.0, -187.0, "Nowy Świat"],
]


func _initialize() -> void:
	var verbose := "--verbose" in OS.get_cmdline_user_args()
	var map: Node3D = MapBuilder.new()
	root.add_child(map)
	map._setup(JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)), ShaderMaterial.new(), ShaderMaterial.new())
	var fails: Array[String] = []
	var views: Array[Vector3] = []
	for k in YAWS:
		var yaw := TAU * k / YAWS
		var c := cos(deg_to_rad(PITCH))
		views.append(-Vector3(sin(yaw) * c, sin(deg_to_rad(PITCH)), cos(yaw) * c))

	var samples := 0
	var pieces := 0
	for d: Dictionary in map._tunnels:
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		var here := 0
		for k in pts.size() - 1:
			var n := maxi(1, ceili(pts[k].distance_to(pts[k + 1]) / STEP))
			for i in n:
				var t := float(i) / n
				var p := pts[k].lerp(pts[k + 1], t)
				var floor_y := lerpf(hs[k], hs[k + 1], t)
				if not map.in_tunnel(p.x, p.y, floor_y):
					continue
				here += 1
				var chords: Array = map.tunnel_cut_chords(p.x, p.y, floor_y, REACH + PAST, CHORDS)
				var where := "piece %d at (%.0f, %.0f)" % [int(d["g"]), p.x, p.y]
				if chords.is_empty():
					fails.append("%s: the car in the tunnel gets no cut" % where)
					continue
				if _across(chords, p) >= 0.0:
					fails.append("%s: the car stands outside its cut's corridor" % where)
				for v in views:
					# The ground that hides the car: where the view ray from the car up to the camera
					# comes out of it.
					var h: float = map.terrain_height(p.x, p.y) - floor_y
					var g: Vector2 = p - Vector2(v.x, v.z) * (h / -v.y)
					if is_nan(map.tunnel_floor_under(g.x, g.y)) or g.distance_to(pts[0]) < END or g.distance_to(pts[pts.size() - 1]) < END:
						continue  # at or past a portal: the ray leaves through the mouth, over the open ramp
					var ground := Vector3(g.x, map.terrain_height(g.x, g.y), g.y)
					if not _open(chords, Vector3(p.x, floor_y, p.y), v, ground):
						fails.append("%s: the ground that hides the car stays shut looking %s" % [where, v])
						break
				var side := (pts[k + 1] - pts[k]).normalized().orthogonal() * FAR
				for s in [side, -side]:
					var q: Vector2 = p + s
					if map.tunnel_floor_under(q.x, q.y) == map.tunnel_floor_under(q.x, q.y):
						continue  # another tube there
					if _open(chords, Vector3(p.x, floor_y, p.y), views[0], Vector3(q.x, map.terrain_height(q.x, q.y), q.y)):
						fails.append("%s: the ground %.0f m to the side opens" % [where, FAR])
				if not map.tunnel_cut_chords(p.x, p.y, map.terrain_height(p.x, p.y), REACH + PAST, CHORDS).is_empty():
					fails.append("%s: the car on the street over the tunnel gets a cut" % where)
		if here > 0:
			pieces += 1
		samples += here
		if verbose:
			print("  piece %d: %d samples under the ground" % [int(d["g"]), here])
	print("  %d samples in %d tunnel pieces under the ground (min %d)" % [samples, pieces, PIECE_MIN])
	if samples < PIECE_MIN:
		fails.append("only %d tunnel samples (min %d)" % [samples, PIECE_MIN])

	for s: Array in OPEN:
		var x := float(s[0])
		var z := float(s[1])
		if not map.tunnel_cut_chords(x, z, map.ground_height(x, z), REACH + PAST, CHORDS).is_empty():
			fails.append("%s: a cut on an open street" % s[2])

	# The per-frame cost while in a tunnel (main.gd calls it once a frame there).
	var at: Vector2 = map._tunnels[0]["pts"][map._tunnels[0]["pts"].size() / 2]
	var fy: float = map.tunnel_floor_under(at.x, at.y)
	var t0 := Time.get_ticks_usec()
	for i in 500:
		map.tunnel_cut_chords(at.x, at.y, fy, REACH + PAST, CHORDS)
	print("  tunnel_cut_chords: %.0f µs a call in the Wisłostrada tunnel" % ((Time.get_ticks_usec() - t0) / 500.0))

	map.free()
	for f in fails.slice(0, 40):
		print("check_tunnel_cut: FAIL " + f)
	if fails.is_empty():
		print("check_tunnel_cut: OK")
	quit(0 if fails.is_empty() else 1)


## The shader's tunnel_across: how far `p` lies outside the chords' corridor (< 0 inside).
func _across(chords: Array, p: Vector2) -> float:
	var segs: PackedVector4Array = chords[0]
	var reach: PackedVector2Array = chords[1]
	var out_by := 1e4
	for k in segs.size():
		var a := Vector2(segs[k].x, segs[k].y)
		var ab := Vector2(segs[k].z, segs[k].w) - a
		var ap := p - a
		var l2 := maxf(ab.length_squared(), 1e-4)
		var u := ap.dot(ab) / l2
		var lat := ab.cross(ap) / sqrt(l2)
		if u > -0.05 and u < 1.05:
			out_by = minf(out_by, maxf(-lat - reach[k].x, lat - reach[k].y))
	return out_by


## The shader's tunnel_open for the ground point `wp`, the car at `car` (on its floor), the camera
## looking along `view`.
func _open(chords: Array, car: Vector3, view: Vector3, wp: Vector3) -> bool:
	if wp.y < car.y + OVER:
		return false
	var hit := Vector2(wp.x, wp.z) + Vector2(view.x, view.z) * ((wp.y - car.y) / maxf(-view.y, 0.1))
	if hit.distance_to(Vector2(car.x, car.z)) > REACH:
		return false
	return _across(chords, hit) < 0.0 or _across(chords, Vector2(wp.x, wp.z)) < 0.0
