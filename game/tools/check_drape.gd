extends SceneTree
## Loop 3b-2: what the ground hides, and what an area hides, over the whole map, from the
## builder's own meshes.
##
## 1. The bare ground poking through the flat areas laid on it (the water, the grass and parks,
##    plazas, sand). The ground is the terrain grid's two triangles per 10 m cell
##    (map_builder._build_ground); an area drawn in pieces whose planes don't follow the grid's
##    folds dips under the ground there, and the ground shows through as jagged beige patches
##    (the river's "torn paper sandbars", lumps in the parks). Each area triangle is sampled at
##    four points (its centroid and half way from it to each corner, a quarter of its area
##    each); a sample more than POKE m under the ground counts.
## 2. A thin strip laid over an area (footways and paving, cycle paths, steps, the natural banks'
##    wet bands and foam, the sandbars' rims) hidden by it: a strip piece is a plane through
##    terrain points that sags over the grid's folds, and where it sags further than its depth
##    bias and height lift it over the area under it, the area covers it (the Praga beach's
##    footpath came out in dashes when the beach became sand). With the camera's 30° pitch a
##    point's depth towards the camera is height * PITCH_SIN + its bias; a strip sample counts
##    when an area triangle under it (the same x, z) is as near the camera or nearer.
##
## 3. The railway's flat layers in the cutting west of Centralna (rail_cut.gd's box): the floor, the
##    tracks' gravel shoulders and dark beds, the rails. Where the drawn ground stands over one of
##    them by more than twice its depth bias (the 30° pitch), the beige ground shows through it
##    (F's phone videos, 2026-11-07: the ground tore through the ballast and cut the rails into
##    crawling dashes from the helicopter). Under RAIL_ALLOWED m2 each.
##
## Prints the area per kind and `check_drape: OK` when every kind has under ALLOWED m2 (strips:
## ALLOWED_STRIPS); else exit 1. ~12 s (6 s of it building the city).
##   godot --headless --path game --script res://tools/check_drape.gd [-- --verbose]
## --verbose lists the 20 worst places (x, z, kind, how far).

const MapBuilder := preload("res://scripts/map_builder.gd")
const MAP_PATH := "res://map/centrum.json"
const POKE := 0.1
const ALLOWED := 1.0
## Strips: one footbridge's ramp (deck group 12 at -18, -281, the ramp's end 0.46 m under the park
## it lands in: the deck solver's, not the drape's) hides ~2 m2 of itself; anything more fails.
const ALLOWED_STRIPS := 5.0
## Loop 3d-1: strips not counted here, each with why (centre, radius in metres).
const EXCUSED := [
	# The cycle footbridge over Trasa Łazienkowska's trench by Plac Na Rozdrożu: the deck solver
	# can't give it its clearance over the trench the 10 m grid doesn't show (the bake warns), so
	# its ramps end 0.1-0.2 m under the grass they land in: loop 3e's structure (DEMO 4.6).
	[Vector2(382.0, 1505.0), 45.0],
]
const KINDS := {1: "grass and parks", 2: "plazas", 3: "water", 16: "sand"}
## The areas' pass: depth biases up to this (the areas 0.01, the sandbars' fill 0.02).
const AREA_BIAS_MAX := 0.065
## The strips checked against them: depth biases above the areas' and up to this (footways and
## steps 0.1, the banks' bands and foam 0.07 / 0.09, the sandbars' rims 0.07, paving 0.08).
const STRIP_BIAS_MAX := 0.2
## main.gd camera_pitch is -30°: a metre up is half a metre nearer the camera.
const PITCH_SIN := 0.5
## No area stands more than this over the ground (the sandbars' fill: Y_AREA + 0.012) or has a
## bias over AREA_BIAS_MAX: a strip sample clear of that is clear of every area.
const AREA_TOP_Y := 0.032
const CELL := 8.0
## Pass 3: the cutting's box (rail_cut.gd BOX), the layers and the area each may lose (m2; rails
## 6 and 6 m2 after the fix, 5,872, 687 and 30 before it; gravel: 318).
const RAIL_BOX := Rect2(-3140.0, 740.0, 1250.0, 460.0)
const RAILS := {8: "rails", 9: "track beds", 15: "track gravel and the cutting's floor"}
const RAIL_ALLOWED := 400.0
const STRIPS := {4: "footways and paving", 5: "cycle paths", 10: "steps", 17: "wet bands and rims", 18: "foam lines"}


func _initialize() -> void:
	var verbose := "--verbose" in OS.get_cmdline_user_args()
	var t0 := Time.get_ticks_msec()
	var map: Node3D = MapBuilder.new()
	root.add_child(map)
	var flat := ShaderMaterial.new()
	map.build(MAP_PATH, ShaderMaterial.new(), flat)
	var poked := {}
	var total := {}
	var hidden := {}
	var strips := {}
	var rail_hid := {}
	var rail_total := {}
	var worst: Array = []
	# The areas' triangles (a, b, c each) and their bias; the strip samples some area could hide
	# (x, y, z and bias), with their kind and share of area, and the cells they are in.
	var tris := PackedVector3Array()
	var tri_bias := PackedFloat32Array()
	var cand := PackedVector3Array()
	var cand_bias := PackedFloat32Array()
	var cand_info: Array = []
	var cand_cells := {}
	for c in map.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.material_override != flat or mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var count := idx.size() if idx.size() > 0 else v.size()
			for t in range(0, count, 3):
				var i0 := idx[t] if idx.size() > 0 else t
				var id := int(round(uv[i0].y))
				var bias := uv[i0].x
				var area_pass := KINDS.has(id) and bias >= 0.0 and bias <= AREA_BIAS_MAX
				var strip := STRIPS.has(id) and bias > AREA_BIAS_MAX and bias <= STRIP_BIAS_MAX
				var rail := RAILS.has(id) and bias > STRIP_BIAS_MAX - 0.05 and bias <= 0.5
				if not area_pass and not strip and not rail:
					continue
				var a := v[i0]
				var b := v[idx[t + 1] if idx.size() > 0 else t + 1]
				var cc := v[idx[t + 2] if idx.size() > 0 else t + 2]
				var area := absf((b.x - a.x) * (cc.z - a.z) - (cc.x - a.x) * (b.z - a.z)) * 0.5
				var centre := (a + b + cc) / 3.0
				if rail:
					if not RAIL_BOX.has_point(Vector2(centre.x, centre.z)):
						continue
					rail_total[id] = float(rail_total.get(id, 0.0)) + area
					for p: Vector3 in [centre, (centre + a) * 0.5, (centre + b) * 0.5, (centre + cc) * 0.5]:
						var over: float = map._drawn_height(p.x, p.z) - p.y
						if over * PITCH_SIN >= bias:
							rail_hid[id] = float(rail_hid.get(id, 0.0)) + area * 0.25
							if verbose:
								worst.append([over, p.x, p.z, RAILS[id]])
					continue
				if area_pass:
					total[id] = float(total.get(id, 0.0)) + area
					tris.append_array([a, b, cc])
					tri_bias.append(bias)
				else:
					strips[id] = float(strips.get(id, 0.0)) + area
				for p: Vector3 in [centre, (centre + a) * 0.5, (centre + b) * 0.5, (centre + cc) * 0.5]:
					var ground: float = map._drawn_height(p.x, p.z)  # map round 2: the drawn ground (it follows the aprons)
					if area_pass:
						var depth := ground - p.y
						if depth > POKE:
							poked[id] = float(poked.get(id, 0.0)) + area * 0.25
							if verbose:
								worst.append([depth, p.x, p.z, KINDS[id]])
					elif (ground + AREA_TOP_Y) * PITCH_SIN + AREA_BIAS_MAX >= p.y * PITCH_SIN + bias:
						cand.append(p)
						cand_bias.append(bias)
						cand_info.append([id, area * 0.25])
						cand_cells[Vector2i(floori(p.x / CELL), floori(p.z / CELL))] = true
	# The area triangles over the cells the candidates are in.
	var cells := {}
	for k in tri_bias.size():
		var a := tris[k * 3]
		var b := tris[k * 3 + 1]
		var cc := tris[k * 3 + 2]
		var lo := Vector2(minf(a.x, minf(b.x, cc.x)), minf(a.z, minf(b.z, cc.z)))
		var hi := Vector2(maxf(a.x, maxf(b.x, cc.x)), maxf(a.z, maxf(b.z, cc.z)))
		for cz in range(floori(lo.y / CELL), floori(hi.y / CELL) + 1):
			for cx in range(floori(lo.x / CELL), floori(hi.x / CELL) + 1):
				var key := Vector2i(cx, cz)
				if cand_cells.has(key):
					var list: PackedInt32Array = cells.get(key, PackedInt32Array())
					list.append(k)
					cells[key] = list
	for n in cand.size():
		var p := cand[n]
		var near := p.y * PITCH_SIN + cand_bias[n]
		var excused := false
		for ex: Array in EXCUSED:
			if Vector2(p.x, p.z).distance_to(ex[0]) <= float(ex[1]):
				excused = true
		if excused:
			continue
		for k: int in cells.get(Vector2i(floori(p.x / CELL), floori(p.z / CELL)), PackedInt32Array()):
			var a := tris[k * 3]
			var b := tris[k * 3 + 1]
			var cc := tris[k * 3 + 2]
			var w := Geometry3D.get_triangle_barycentric_coords(Vector3(p.x, 0.0, p.z), Vector3(a.x, 0.0, a.z),
					Vector3(b.x, 0.0, b.z), Vector3(cc.x, 0.0, cc.z))
			if w.x < -0.0001 or w.y < -0.0001 or w.z < -0.0001 or w == Vector3.ZERO:
				continue
			var short := (a.y * w.x + b.y * w.y + cc.y * w.z) * PITCH_SIN + tri_bias[k] - near
			if short >= 0.0:
				var id: int = cand_info[n][0]
				hidden[id] = float(hidden.get(id, 0.0)) + float(cand_info[n][1])
				if verbose:
					worst.append([short / PITCH_SIN, p.x, p.z, STRIPS[id]])
				break
	var fails := 0
	for id in KINDS:
		var p := float(poked.get(id, 0.0))
		print("check_drape: %s: %.0f m2 of %.0f m2 under the ground by more than %.1f m" % [KINDS[id], p,
				float(total.get(id, 0.0)), POKE])
		if p >= ALLOWED:
			fails += 1
	for id in STRIPS:
		var h := float(hidden.get(id, 0.0))
		print("check_drape: %s: %.0f m2 of %.0f m2 hidden by an area under them" % [STRIPS[id], h, float(strips.get(id, 0.0))])
		if h >= ALLOWED_STRIPS:
			fails += 1
	for id in RAILS:
		var h := float(rail_hid.get(id, 0.0))
		print("check_drape: %s in the cutting: %.0f m2 of %.0f m2 under the ground" % [RAILS[id], h, float(rail_total.get(id, 0.0))])
		if h >= RAIL_ALLOWED:
			fails += 1
	if verbose:
		worst.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
		for w in worst.slice(0, 20):
			print("  %.2f m at %.0f, %.0f (%s)  --at=%.0f,%.0f" % [w[0], w[1], w[2], w[3], w[1], w[2]])
	print("check_drape: %s in %d ms" % ["OK" if fails == 0 else "%d kinds fail" % fails, Time.get_ticks_msec() - t0])
	map.free()
	quit(0 if fails == 0 else 1)
