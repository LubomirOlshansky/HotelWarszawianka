extends "res://scripts/place.gd"
## The light garden in Park Świętokrzyski (F, 2026-11-15, the Palace's own photos of the opening
## and the news of 15 October 2026: "całoroczny ogród światła", made by Multidekor for the city).
## The park between Świętokrzyska and the Palace is in the map data (its walks, lawns, trees,
## lamps, benches and the fountain); this adds the installation, which stands all year:
##  - over the alley that runs from the Pijana Czereśnia kiosk along Świętokrzyska to the fountain:
##    six arches of giant flower stems that meet over the walk, each stem ending in a lilac bell
##    flower that hangs over the path with pearl beads under it and a magenta neon ring, warm bulbs
##    strung along the stems, an orange butterfly on top of some (the news: "at least six light
##    hangings over the alley along Świętokrzyska");
##  - giant dandelions beside the walks (ten): a pale green stem, a warm-white clock of radial
##    spikes with a bulb on each tip, long toothed leaves, a dark round base painted with flowers;
##  - four single bell flowers on their own stems, and butterflies on thin rods among them
##    (eighteen butterflies in all, with the ones on the arches);
##  - the 50 m interactive alley from the fountain towards the Palace: a row of mirror-steel pylons
##    on round concrete feet down its west side, each with an arm over the walk carrying a
##    projector; after dark the walk is a carpet of projected flowers (light_garden.gdshader), and
##    a second projection rings the fountain;
##  - the photo frame on the north side of the fountain, set so the Palace stands in it.
## Built at runtime on both city paths, as skwer_zlota.gd: the dressing is poured (one draw call
## per sector with every other place); the projection is one mesh of its own (additive, night
## only). The flowers, bulbs and butterflies use the actors' material's night glow (LIT_SIGN), no
## lights. Nothing here is solid: drive-through like the map's benches.
## Not built (yet): the projection reacting to people walking on it (the real one has motion
## sensors), and the light figures' slow colour changes.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

const LIT := Models.LIT_SIGN
const FIXED := Models.FIXED

## The alley from the kiosk (its deck faces this walk) to the fountain's link path (OSM walk).
const ALLEY := [Vector2(-1407.9, 29.0), Vector2(-1404.9, 23.8), Vector2(-1398.7, 17.6), Vector2(-1394.0, 13.9),
		Vector2(-1388.9, 10.8), Vector2(-1383.4, 8.3), Vector2(-1377.9, 6.3), Vector2(-1372.1, 5.0),
		Vector2(-1364.5, 3.9), Vector2(-1346.6, 2.7), Vector2(-1339.3, 1.6), Vector2(-1332.0, -0.2),
		Vector2(-1326.2, -2.2), Vector2(-1320.5, -4.6), Vector2(-1310.5, -8.5)]
## The arches' feet either side of the walk (placed clear of the trees, lamps and benches).
const ARCHES := [
	[Vector2(-1397.3, 20.1), Vector2(-1401.2, 16.2)], [Vector2(-1384.8, 12.0), Vector2(-1387.1, 6.9)],
	[Vector2(-1370.3, 7.6), Vector2(-1371.1, 2.0)], [Vector2(-1354.6, 6.0), Vector2(-1354.9, 0.5)],
	[Vector2(-1338.2, 4.2), Vector2(-1339.5, -1.2)], [Vector2(-1322.5, -0.7), Vector2(-1324.7, -5.9)],
]
## Which arches carry a butterfly on top.
const ARCH_BUTTERFLY := [0, 2, 3, 5]
## [kind, x, z, height]: d a dandelion, f a single bell flower.
const FIGURES := [
	["d", -1412.0, 22.0, 4.2], ["d", -1404.5, 15.7, 3.6], ["f", -1392.0, 17.7, 4.6], ["d", -1379.9, 11.5, 3.9],
	["d", -1376.5, 1.7, 4.3], ["f", -1363.4, 9.3, 4.5], ["d", -1362.2, -3.3, 3.6], ["d", -1349.1, -1.3, 4.2],
	["f", -1340.7, -3.8, 4.4], ["d", -1331.5, -7.8, 3.5], ["f", -1311.8, -0.5, 4.3],
	["d", -1281.6, 84.3, 4.0], ["d", -1268.6, 89.2, 3.7],
]
## Butterflies on rods: [x, z, height, yaw, colour index].
const BUTTERFLIES := [
	[-1366.9, 9.8, 2.1, -3.0, 0], [-1318.2, -11.4, 1.9, 1.14, 1], [-1385.5, 15.3, 2.1, 2.89, 2],
	[-1330.6, -5.1, 2.0, 2.29, 3], [-1327.3, -9.3, 2.1, -2.99, 4], [-1390.3, 19.9, 3.1, -1.6, 5],
	[-1379.1, -0.6, 3.1, -1.94, 0], [-1395.9, 20.8, 2.0, 1.7, 1], [-1382.7, 3.6, 3.0, 2.2, 2],
	[-1376.0, 13.0, 3.1, -2.58, 3], [-1360.4, 9.1, 2.9, 1.3, 4], [-1401.3, 10.7, 2.6, 2.68, 5],
	[-1352.1, -2.4, 2.3, 2.88, 0], [-1368.5, -1.1, 1.9, 0.93, 2],
]
## The interactive alley: the walk from the fountain's ring straight towards the Palace (OSM).
const PROJ := [Vector2(-1291.3, 41.0), Vector2(-1280.3, 70.3), Vector2(-1277.9, 76.8), Vector2(-1270.2, 98.1)]
const PROJ_FROM := 4.0       # metres along PROJ where the projected carpet starts
const PROJ_LEN := 50.0
const PROJ_HALF := 1.6       # half its width
const PYLONS := 8
const PYLON_SIDE := 2.3      # metres west of the walk's middle line (the photos' right-hand side)
## The fountain (OSM water) and its ring walk's radius; the projection rings the walk.
const FOUNTAIN := Vector2(-1298.0, 24.2)
const RING_R := 18.2
const PALACE := Vector2(-1214.2, 247.0)

const STEM := Color("#5f9e3a")
const STEM_LIT := Color("#b8f07a")
const LEAF := Color("#7fd23f")
const BULB := Color("#ffe2a0")
const BELL := Color("#b79bf0")
const BELL_DEEP := Color("#8d6be0")
const NEON := Color("#e040ff")
const PEARL := Color("#f1e8f7")
const PUFF := Color("#fff1d6")
const PUFF_TIP := Color("#fffaf0")
const BASE := Color("#24243a")
const BASE_ART := [Color("#d8443a"), Color("#f0b429"), Color("#e86a9a"), Color("#4f9e4a")]
const STEEL := Color("#c6ced6")
const STEEL_DARK := Color("#7d868e")
const CONCRETE := Color("#b9b5ac")
const DARK := Color("#2a2d33")
const WING := [Color("#ff8a1e"), Color("#ffd23a"), Color("#ff4fa3"), Color("#3fb8ff"), Color("#a66bff"), Color("#5be37a")]
const FRAME_GOLD := Color("#f2d27a")

var _st: SurfaceTool


func build() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in ARCHES.size():
		_arch(ARCHES[i][0], ARCHES[i][1], ARCH_BUTTERFLY.has(i))
	for f: Array in FIGURES:
		var p := Vector2(f[1], f[2])
		if f[0] == "d":
			_dandelion(p, float(f[3]))
		else:
			_bell_flower(p, float(f[3]))
	for b: Array in BUTTERFLIES:
		var p := Vector2(b[0], b[1])
		var y := _g(p)
		Props.beam(_st, Vector3(p.x, y, p.y), Vector3(p.x, y + float(b[2]), p.y), 0.04, 0.04, DARK)
		_butterfly(Vector3(p.x, y + float(b[2]) + 0.02, p.y), float(b[3]), int(b[4]), 0.9)
	_pylons()
	_photo_frame()
	pour(_st.commit(), true, "LightGardenProps")
	_projection()


## The ground at a map point (flat 0 when the place is built alone without a map).
func _g(p: Vector2) -> float:
	return map.ground_height(p.x, p.y) if map != null else 0.0


func _v(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


## A point on a quadratic curve a-c-b at t.
static func _quad(a: Vector3, c: Vector3, b: Vector3, t: float) -> Vector3:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)


## A stem from `a` curving over `c` to `b` in `n` pieces, warm bulbs every other joint when `bulbs`.
func _stem(a: Vector3, c: Vector3, b: Vector3, n: int, w: float, bulbs: bool) -> void:
	# One square tube through the joints (shared corners, so the mesh check sees one welded part),
	# its pieces in two greens, a cap on the end.
	var pts: Array[Vector3] = []
	for k in n + 1:
		pts.append(_quad(a, c, b, float(k) / n))
	var rings: Array = []
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var side := (flat.normalized() if flat.length_squared() > 0.0001 else Vector3.RIGHT).cross(Vector3.UP)
	for k in n + 1:
		var t: Vector3 = (pts[mini(k + 1, n)] - pts[maxi(k - 1, 0)]).normalized()
		# Carried along the curve (kept square to it), so the tube never twists.
		side = (side - t * side.dot(t)).normalized()
		var up := t.cross(side).normalized()
		var h := w * 0.5
		rings.append([pts[k] + (side + up) * h, pts[k] + (-side + up) * h, pts[k] + (-side - up) * h, pts[k] + (side - up) * h])
	for k in n:
		var col := STEM_LIT if k % 2 == 1 else STEM
		var r0: Array = rings[k]
		var r1: Array = rings[k + 1]
		for j in 4:
			var q0: Vector3 = r0[j]
			var q1: Vector3 = r0[(j + 1) % 4]
			var q2: Vector3 = r1[(j + 1) % 4]
			var q3: Vector3 = r1[j]
			var mid := (q0 + q1 + q2 + q3) * 0.25
			var nrm := (mid - (pts[k] + pts[k + 1]) * 0.5).normalized()
			Props.tri(_st, q0, q1, q2, nrm, col, LIT)
			Props.tri(_st, q0, q2, q3, nrm, col, LIT)
		if bulbs and k % 2 == 1 and k < n - 1:
			Props.box(_st, pts[k + 1] + Vector3(0, -w * 0.5 - 0.04, 0), Vector3(0.16, 0.16, 0.16), BULB, LIT)
	var last: Array = rings[n]
	var tn: Vector3 = (pts[n] - pts[n - 1]).normalized()
	Props.tri(_st, last[0], last[1], last[2], tn, STEM, LIT)
	Props.tri(_st, last[0], last[2], last[3], tn, STEM, LIT)
	count += 1


## A bell flower hanging mouth down from `top`: eight lilac petals flaring out to a rim `r` wide,
## the magenta neon ring at the rim, pearl beads under it.
func _bell(top: Vector3, r: float, yaw: float) -> void:
	var drop := r * 1.35
	var rim: Array[Vector3] = []
	for k in 8:
		var a := yaw + TAU * k / 8.0
		rim.append(top + Vector3(cos(a) * r, -drop, sin(a) * r))
	for k in 8:
		var a := yaw + TAU * (k + 0.5) / 8.0
		var mid := top + Vector3(cos(a) * r * 0.55, -drop * 0.55, sin(a) * r * 0.55)
		var n := Vector3(cos(a), 0.4, sin(a)).normalized()
		Props.tri(_st, top, rim[k], mid, n, BELL_DEEP, LIT)
		Props.tri(_st, mid, rim[k], rim[(k + 1) % 8], n, BELL, LIT)
		Props.tri(_st, top, mid, rim[(k + 1) % 8], n, BELL, LIT)
		Props.beam(_st, rim[k], rim[(k + 1) % 8], 0.06, 0.06, NEON, Vector3.UP, LIT)
	# The pistil down the middle with the pearl beads clustered on it, the lowest below the rim.
	Props.beam(_st, top, top + Vector3(0, -drop * 1.2, 0), 0.05, 0.05, PEARL, Vector3.RIGHT, LIT)
	for k in 5:
		var a := yaw + TAU * k / 5.0
		Props.box(_st, top + Vector3(cos(a) * 0.1, -drop * (0.75 + 0.1 * k), sin(a) * 0.1),
				Vector3(0.18, 0.18, 0.18), PEARL, LIT)


## One arch: a stem from each foot rises over the walk, crosses the other and hangs its bell past
## the middle; long leaves at the feet.
func _arch(a2: Vector2, b2: Vector2, butterfly: bool) -> void:
	var a := _v(a2, _g(a2))
	var b := _v(b2, _g(b2))
	var mid := (a + b) * 0.5
	var across := (b - a).normalized()
	# The two stems pass each other 0.5 m apart along the walk.
	var along3 := Vector3(-across.z, 0, across.x)
	var shift := 0.25
	for side in [[a, b], [b, a]]:
		var from: Vector3 = side[0]
		var to: Vector3 = side[1]
		var dir := (to - from).normalized()
		var end := mid + dir * 1.15 + Vector3.UP * 4.3 + along3 * shift
		var ctl := from.lerp(mid, 0.55) + Vector3.UP * 8.4 + along3 * shift
		_stem(from, ctl, end, 12, 0.22, true)
		shift = -shift
		_bell(end, 0.85, atan2(dir.z, dir.x))
		_leaves(from, atan2(dir.z, dir.x), 2, 1.6)
	if butterfly:
		var top := _quad(a, a.lerp(mid, 0.55) + Vector3.UP * 8.4, mid + across * 1.15 + Vector3.UP * 4.3, 0.62) + along3 * 0.25
		_butterfly(top + Vector3(0, 0.09, 0), atan2(across.z, across.x), 0, 1.6)


## `n` long toothed leaves from a foot, spreading round `yaw`.
func _leaves(foot: Vector3, yaw: float, n: int, length: float) -> void:
	for k in n:
		var a := yaw + PI * 0.5 + (k - (n - 1) * 0.5) * 0.9 + PI * (k % 2)
		var out := Vector3(cos(a), 0, sin(a))
		var tip := foot + out * length * 0.7 + Vector3.UP * length
		var knee := foot + out * 0.25 + Vector3.UP * length * 0.45
		Props.beam(_st, foot - Vector3.UP * 0.05, knee, 0.34, 0.05, LEAF, out.cross(Vector3.UP), LIT)
		Props.beam(_st, knee, tip, 0.26, 0.05, LEAF, out.cross(Vector3.UP), LIT)
		Props.box(_st, knee, Vector3(0.11, 0.11, 0.11), LEAF, LIT)


## The dark round base painted with flowers that the figures stand in.
func _base(p: Vector2, y: float, r: float, h: float) -> void:
	var ring := PackedVector2Array()
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		ring.append(p + Vector2(cos(a), sin(a)) * r)
	for k in 8:
		var q0 := ring[k]
		var q1 := ring[(k + 1) % 8]
		var n := Vector3((q0 + q1).x * 0.5 - p.x, 0, (q0 + q1).y * 0.5 - p.y).normalized()
		Props.tri(_st, _v(q0, y), _v(q1, y), _v(q1, y + h), n, BASE)
		Props.tri(_st, _v(q0, y), _v(q1, y + h), _v(q0, y + h), n, BASE)
		Props.tri(_st, _v(p, y + h), _v(q0, y + h), _v(q1, y + h), Vector3.UP, BASE)
		var c := _v((q0 + q1) * 0.5, y + h * (0.35 + 0.3 * (k % 2))) + n * 0.02
		Props.box(_st, c, Vector3(0.22, 0.2, 0.22), BASE_ART[(k + count) % BASE_ART.size()])


## A giant dandelion `h` high: base, pale stem, leaves, and the clock of spikes with warm tips.
func _dandelion(p: Vector2, h: float) -> void:
	var y := _g(p)
	_base(p, y, 0.6, 0.5)
	var lean := Vector3(sin(p.x * 1.7) * 0.35, 0, cos(p.y * 1.3) * 0.35)
	var head := _v(p, y + h) + lean
	_stem(_v(p, y), _v(p, y + h * 0.6), head, 6, 0.12, false)
	_leaves(_v(p, y + 0.5), p.x * 0.7, 3, 1.7)
	var r := 1.45
	var n := 60
	for k in n:
		# A Fibonacci sphere; the lowest spikes (into the stem) are left out.
		var t := (k + 0.5) / n
		var cy := 1.0 - 2.0 * t
		if cy < -0.7:
			continue
		var rr := sqrt(1.0 - cy * cy)
		var a := k * 2.39996
		var d := Vector3(cos(a) * rr, cy, sin(a) * rr)
		Props.beam(_st, head - d * 0.05, head + d * r, 0.035, 0.035, PUFF, Vector3.UP, LIT)
		Props.box(_st, head + d * r, Vector3(0.13, 0.13, 0.13), PUFF_TIP, LIT)
	Props.box(_st, head, Vector3(0.3, 0.3, 0.3), PUFF, LIT)
	count += 1


## A single bell flower on its own arching stem, a butterfly on the bend.
func _bell_flower(p: Vector2, h: float) -> void:
	var y := _g(p)
	_base(p, y, 0.55, 0.45)
	var yaw := p.y * 0.9
	var out := Vector3(cos(yaw), 0, sin(yaw))
	var foot := _v(p, y + 0.45)
	var root := _v(p, y)
	var end := foot + out * 1.6 + Vector3.UP * (h - 0.6)
	var ctl := foot + out * 0.2 + Vector3.UP * (h + 1.2)
	_stem(root, ctl, end, 9, 0.15, true)
	_bell(end, 0.8, yaw)
	_leaves(foot, yaw, 2, 1.4)
	_butterfly(_quad(foot, ctl, end, 0.55) + Vector3(0, 0.08, 0), yaw + PI * 0.5, (count + 1) % WING.size(), 1.0)
	count += 1


## A butterfly at `c` facing `yaw`, `span` metres across: four wings tilted up, a dark body.
func _butterfly(c: Vector3, yaw: float, colour: int, span: float) -> void:
	var fwd := Vector3(cos(yaw), 0, sin(yaw))
	var side := Vector3(-fwd.z, 0, fwd.x)
	var col: Color = WING[colour % WING.size()]
	var hind: Color = col.lerp(Color.WHITE, 0.25)
	var s := span * 0.5
	Props.beam(_st, c - fwd * s * 0.45, c + fwd * s * 0.45, 0.07, 0.07, DARK)
	for sgn: float in [-1.0, 1.0]:
		var out: Vector3 = side * sgn
		var lift := Vector3.UP * s * 0.45
		var n := (out.cross(fwd) * sgn + Vector3.UP).normalized()
		Props.tri(_st, c + fwd * s * 0.3, c + out * s + fwd * s * 0.55 + lift, c + out * s * 0.85 - fwd * s * 0.05 + lift, n, col, LIT)
		Props.tri(_st, c + fwd * s * 0.3, c + out * s * 0.85 - fwd * s * 0.05 + lift, c, n, col, LIT)
		Props.tri(_st, c, c + out * s * 0.7 - fwd * s * 0.2 + lift * 0.7, c + out * s * 0.35 - fwd * s * 0.6 + lift * 0.5, n, hind, LIT)
	count += 1


## A point `s` metres along a polyline and its direction.
static func along(line: Array, s: float) -> Array:
	var left := s
	for i in line.size() - 1:
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var l := a.distance_to(b)
		if left <= l or i == line.size() - 2:
			return [a.lerp(b, clampf(left / l, 0.0, 1.0)), (b - a) / l]
		left -= l
	return [line[0], Vector2.RIGHT]


## The mirror-steel pylons down the interactive alley's west side, each with an arm over the walk
## and a projector looking down; the face to the walk shows the projection's colours.
func _pylons() -> void:
	for k in PYLONS:
		var s := PROJ_FROM + 2.0 + k * (PROJ_LEN - 4.0) / (PYLONS - 1)
		var at: Array = along(PROJ, s)
		var mid: Vector2 = at[0]
		var d: Vector2 = at[1]
		var west := Vector2(-d.y, d.x)
		var p: Vector2 = mid + west * PYLON_SIDE
		var y := _g(p)
		var fwd := Vector3(d.x, 0, d.y)
		var w3 := Vector3(west.x, 0, west.y)
		var basis := Basis(w3, Vector3.UP, fwd)
		# The round concrete foot, then the column (a square prism, a little twisted on the photos).
		_base_round(p, y, 0.55, 0.45)
		Props.obox(_st, _v(p, y + 0.4 + 2.35), basis, Vector3(0.42, 4.7, 0.42), STEEL)
		Props.obox(_st, _v(p, y + 0.45 + 2.3) + fwd * 0.21, basis, Vector3(0.36, 4.4, 0.06), STEEL_DARK)
		# The walk's colours caught in the mirror (a stripe that glows at night).
		var cols := [Color("#a76bff"), Color("#ffd23a"), Color("#ff6a3d"), Color("#7fd23f")]
		for j in 3:
			Props.obox(_st, _v(p, y + 0.9 + j * 1.2) - w3 * 0.21, basis, Vector3(0.06, 0.9, 0.36), cols[(j + k) % 4], LIT)
		# The arm over the walk and the projector.
		var top := _v(p, y + 0.45 + 4.6)
		var tip := top - w3 * (PYLON_SIDE - 0.2)
		Props.beam(_st, top, tip, 0.18, 0.22, DARK)
		Props.obox(_st, tip + Vector3(0, -0.2, 0), basis, Vector3(0.4, 0.3, 0.55), DARK)
		Props.obox(_st, tip + Vector3(0, -0.36, 0), basis, Vector3(0.22, 0.03, 0.22), Color("#f6f2ff"), LIT)
		count += 1


func _base_round(p: Vector2, y: float, r: float, h: float) -> void:
	var ring := PackedVector2Array()
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		ring.append(p + Vector2(cos(a), sin(a)) * r)
	for k in 8:
		var q0 := ring[k]
		var q1 := ring[(k + 1) % 8]
		var n := Vector3((q0 + q1).x * 0.5 - p.x, 0, (q0 + q1).y * 0.5 - p.y).normalized()
		Props.tri(_st, _v(q0, y), _v(q1, y), _v(q1, y + h), n, CONCRETE)
		Props.tri(_st, _v(q0, y), _v(q1, y + h), _v(q0, y + h), n, CONCRETE)
		Props.tri(_st, _v(p, y + h), _v(q0, y + h), _v(q1, y + h), Vector3.UP, CONCRETE)


## The photo frame north of the fountain: stand at it and the Palace fills it.
func _photo_frame() -> void:
	var to_palace := (PALACE - FOUNTAIN).normalized()
	var p := FOUNTAIN - to_palace * (RING_R + 4.6)
	var y := _g(p)
	var across := Vector3(-to_palace.y, 0, to_palace.x)
	var c := _v(p, y)
	var half := 1.4
	var top := 3.0
	for sgn: float in [-1.0, 1.0]:
		Props.beam(_st, c + across * half * sgn, c + across * half * sgn + Vector3.UP * top, 0.16, 0.16, FRAME_GOLD, Vector3.UP, LIT)
	Props.beam(_st, c - across * half + Vector3.UP * top, c + across * half + Vector3.UP * top, 0.16, 0.16, FRAME_GOLD, Vector3.UP, LIT)
	Props.beam(_st, c - across * half + Vector3.UP * 0.6, c + across * half + Vector3.UP * 0.6, 0.12, 0.12, FRAME_GOLD, Vector3.UP, LIT)
	_butterfly(c + across * half + Vector3.UP * (top + 0.1), atan2(across.z, across.x), 2, 0.9)
	count += 1


## The projected carpet: the interactive alley's 50 m and the fountain's ring, one mesh in
## light_garden.gdshader (additive, only at night).
func _projection() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 1.0
	var n := int(PROJ_LEN / step)
	for k in n:
		var s0 := PROJ_FROM + k * step
		var a0: Array = along(PROJ, s0)
		var a1: Array = along(PROJ, s0 + step)
		_strip_quad(st, a0[0], a1[0], a0[1], a1[1], s0 - PROJ_FROM, s0 - PROJ_FROM + step, PROJ_HALF)
	# The ring round the fountain (its walk, 2.2 m wide, and a little over its edges).
	var segs := 64
	var arc := TAU * RING_R / segs
	for k in segs:
		var t0 := TAU * k / segs
		var t1 := TAU * (k + 1) / segs
		var p0 := FOUNTAIN + Vector2(cos(t0), sin(t0)) * RING_R
		var p1 := FOUNTAIN + Vector2(cos(t1), sin(t1)) * RING_R
		var d0 := Vector2(-sin(t0), cos(t0))
		var d1 := Vector2(-sin(t1), cos(t1))
		_strip_quad(st, p0, p1, d0, d1, 100.0 + k * arc, 100.0 + (k + 1) * arc, 1.5)
	var mi := MeshInstance3D.new()
	mi.name = "LightGardenProjection"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/light_garden.gdshader")
	mat.render_priority = 1
	mi.material_override = mat
	part(mi)


## One quad of a ground strip from p0 to p1 (directions d0, d1), `half` wide either side, with UV.x
## the metres along it and UV.y the metres across.
func _strip_quad(st: SurfaceTool, p0: Vector2, p1: Vector2, d0: Vector2, d1: Vector2, u0: float, u1: float, half: float) -> void:
	var n0 := Vector2(-d0.y, d0.x) * half
	var n1 := Vector2(-d1.y, d1.x) * half
	var v := [
		[_v(p0 - n0, _g(p0 - n0) + 0.05), Vector2(u0, -half)],
		[_v(p1 - n1, _g(p1 - n1) + 0.05), Vector2(u1, -half)],
		[_v(p1 + n1, _g(p1 + n1) + 0.05), Vector2(u1, half)],
		[_v(p0 + n0, _g(p0 + n0) + 0.05), Vector2(u0, half)]]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.UP)
		st.set_uv(v[k][1])
		st.add_vertex(v[k][0])
