extends "res://scripts/place.gd"
## The light garden in Park Świętokrzyski (F, 2026-11-15, the Palace's own photos of the opening
## and the news of 15 October 2026: "całoroczny ogród światła", made by Multidekor for the city).
## The park between Świętokrzyska and the Palace is in the map data (its walks, lawns, trees,
## lamps, benches and the fountain); this adds the installation, which stands all year:
##  - the installation follows one walk (F's red line on the aerial, 2026-11-16): from the Pijana
##    Czereśnia kiosk along Świętokrzyska the giant dandelions come first, then, from the fountain's
##    longitude to the east end, six arches of giant flower stems meet over the walk, green tube
##    bundles out of round planters printed with mushrooms and autumn flowers, each ending in a white
##    lace bell flower with a green calyx and a bunch of pearl beads (F's own photos, 2026-11-15);
##    warm bulb strings run from arch to arch and big butterflies hang from them on two cords (the
##    news: "at least six light hangings over the alley along Świętokrzyska");
##  - giant dandelions (ten): a pale green stem, a warm-white clock of radial spikes with a bulb on
##    each tip, long toothed leaves, a dark round base painted with flowers;
##  - five single bell flowers on their own stems between the arches, and butterflies on thin rods
##    among the dandelions (eighteen butterflies in all, with the ones on the arches);
##  - the 50 m interactive alley from the fountain towards the Palace: a row of mirror-steel pylons
##    on round concrete feet down its west side, each with an arm over the walk carrying a
##    projector; after dark the walk is a carpet of projected flowers (light_garden.gdshader), and
##    a second projection rings the fountain;
##  - the gold lattice photo frame on the north side of the fountain, set so the Palace stands in it.
## Built at runtime on both city paths, as skwer_zlota.gd: the dressing is poured (one draw call
## per sector with every other place); the projection is one mesh of its own (additive, night
## only). The flowers, bulbs and butterflies use the actors' material's night glow (LIT_SIGN), no
## lights. Nothing here is solid: drive-through like the map's benches.
## The projection answers the car like the real one's motion sensors answer walkers: `_process`
## hands the shader the car's ground point while it is near (one uniform, nothing else a frame),
## and round the wheels the motifs swap and swell, the light rises and rings run out.
## Not built (yet): the light figures' slow colour changes.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

const LIT := Models.LIT_SIGN
const FIXED := Models.FIXED

## The alley from the kiosk (its deck faces this walk) to the fountain's link path (OSM walk).
const ALLEY := [Vector2(-1407.9, 29.0), Vector2(-1404.9, 23.8), Vector2(-1398.7, 17.6), Vector2(-1394.0, 13.9),
		Vector2(-1388.9, 10.8), Vector2(-1383.4, 8.3), Vector2(-1377.9, 6.3), Vector2(-1372.1, 5.0),
		Vector2(-1364.5, 3.9), Vector2(-1346.6, 2.7), Vector2(-1339.3, 1.6), Vector2(-1332.0, -0.2),
		Vector2(-1326.2, -2.2), Vector2(-1320.5, -4.6), Vector2(-1310.5, -8.5)]
## The arches' feet either side of the walk (F's red line on the aerial, 2026-11-16: from the kiosk the
## walk first passes the dandelions, and from the fountain's longitude on the bell-flower arches stand
## over it, to the east end by the sundial; placed clear of tree trunks, lamps, benches and side paths).
const ARCHES := [
	[Vector2(-1288.9, -13.5), Vector2(-1290.7, -18.2)],
	[Vector2(-1274.2, -19.5), Vector2(-1276.2, -24.0)],
	[Vector2(-1259.7, -25.0), Vector2(-1261.3, -29.7)],
	[Vector2(-1242.9, -30.1), Vector2(-1244.2, -34.9)],
	[Vector2(-1229.5, -33.9), Vector2(-1231.1, -38.6)],
	[Vector2(-1215.5, -42.8), Vector2(-1218.8, -46.6)],
]
## Which spans between arches (span i runs from arch i to arch i + 1) hang a butterfly on two cords
## from the festoon (F's photos: the butterflies hang from the light strings, not on the arches).
const SPAN_BUTTERFLY := [0, 1, 3, 4]
## A planter's height and radius at an arch's foot.
const FOOT_H := 0.8
const FOOT_R := 0.95
## [kind, x, z, height]: d a dandelion, f a single bell flower. F's red line: from the kiosk along
## the walk the dandelions come first (west of the fountain's longitude, x < -1330, both sides of
## the alley) and then the bell flowers (arches and singles, east of the fountain), nothing off that
## walk.
const FIGURES := [
	["d", -1412.0, 22.0, 4.2], ["d", -1404.5, 15.7, 3.6], ["d", -1392.0, 17.7, 4.0], ["d", -1379.9, 11.5, 3.9],
	["d", -1376.5, 1.7, 4.3], ["d", -1363.4, 9.3, 4.1], ["d", -1362.2, -3.3, 3.6], ["d", -1349.1, -1.3, 4.2],
	["d", -1340.7, -3.8, 3.8], ["d", -1331.5, -7.8, 3.5],
	["f", -1281.0, -14.8, 4.3], ["f", -1266.4, -20.7, 4.5], ["f", -1251.9, -25.8, 4.4],
	["f", -1236.8, -29.9, 4.6], ["f", -1221.1, -36.3, 4.3],
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

const STEM := Color("#2f8a3c")
const STEM_LIT := Color("#3f9f46")
const LEAF := Color("#2f8a3c")
const LEAF_BLUE := Color("#3f8f78")
const SEPAL := Color("#1f6b3a")
const GRATE := Color("#245c30")
const BULB := Color("#ffe2a0")
const BELL := Color("#f2f0ea")
const BELL_DEEP := Color("#c9cfd8")
const NEON := Color("#dfe9ff")
const PEARL := Color("#f4eedb")
const PUFF := Color("#fff1d6")
const PUFF_TIP := Color("#fffaf0")
const BASE := Color("#2b3a1c")
const BASE_ART := [Color("#d8443a"), Color("#f0a030"), Color("#8a5ac8"), Color("#e8c43a")]
const MUSHROOM_STEM := Color("#efe6d2")
const STEEL := Color("#c6ced6")
const STEEL_DARK := Color("#7d868e")
const CONCRETE := Color("#b9b5ac")
const DARK := Color("#2a2d33")
const WING := [Color("#e8941e"), Color("#d8405a"), Color("#6cae3a"), Color("#c84a9a"), Color("#f0782e"), Color("#a83a4a")]
const FRAME_GOLD := Color("#d6b04a")
const FRAME_LATTICE := Color("#8a6a22")
const FRAME_POSTER := [Color("#c8403a"), Color("#e8903a"), Color("#8a3a6a")]

var _st: SurfaceTool
## The apex of each arch (over the walk), where the festoon strings hang from.
var _tops: Array[Vector3] = []
## The projection's material (its `visitor` uniform follows the car) and the car, from ctx.
var _mat: ShaderMaterial
var _vehicle: Callable
## The last `visitor` w sent, so a far car costs no uniform write.
var _sent := -1.0
## The middle of the garden's projections and how near the car must be for them to answer.
const NEAR_FROM := Vector2(-1286.0, 50.0)
const NEAR_R := 70.0


func build() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in ARCHES.size():
		_arch(ARCHES[i][0], ARCHES[i][1])
	_festoons()
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


## A bell flower hanging mouth down from `top` (F's photos: a white lace bell, its rim in big soft
## waves, a calyx of dark green sepals on top, a bunch of pearl beads hanging from the mouth).
func _bell(top: Vector3, r: float, yaw: float) -> void:
	var drop := r * 1.5
	var n := 12
	var rim: Array[Vector3] = []
	var mid: Array[Vector3] = []
	for k in n:
		var a := yaw + TAU * k / float(n)
		var wave := 1.0 + (0.16 if k % 2 == 0 else -0.04)
		rim.append(top + Vector3(cos(a) * r * wave, -drop - (0.08 if k % 2 == 0 else 0.0), sin(a) * r * wave))
		mid.append(top + Vector3(cos(a) * r * 0.5, -drop * 0.5, sin(a) * r * 0.5))
	for k in n:
		var k2 := (k + 1) % n
		var a := yaw + TAU * (k + 0.5) / float(n)
		var nrm := Vector3(cos(a), 0.4, sin(a)).normalized()
		var col := BELL if k % 2 == 0 else BELL_DEEP
		Props.tri(_st, top, mid[k], mid[k2], nrm, BELL_DEEP, LIT)
		Props.tri(_st, mid[k], rim[k], rim[k2], nrm, col, LIT)
		Props.tri(_st, mid[k], rim[k2], mid[k2], nrm, col, LIT)
		Props.beam(_st, rim[k], rim[k2], 0.05, 0.05, NEON, Vector3.UP, LIT)
	# The calyx: five pointed dark-green sepals folded down over the bell's shoulder.
	for k in 5:
		var a := yaw + TAU * k / 5.0 + 0.3
		var out := Vector3(cos(a), 0, sin(a))
		var base_at := top + out * r * 0.12 + Vector3(0, 0.12, 0)
		var tip := top + out * r * 0.78 + Vector3(0, -drop * 0.4, 0)
		_leaf(base_at, tip, r * 0.34, SEPAL)
	# The pearl bunch: seven beads hanging from the mouth on the pistil.
	Props.beam(_st, top, top + Vector3(0, -drop * 1.05, 0), 0.04, 0.04, PEARL, Vector3.RIGHT, LIT)
	for k in 7:
		var a := yaw + TAU * k / 7.0
		var ring := 0.0 if k == 0 else 0.2
		# Each bead a little lower than the last, so no two share a face plane.
		Props.box(_st, top + Vector3(cos(a) * ring, -drop * 1.0 - 0.065 * k, sin(a) * ring),
				Vector3(0.22, 0.22, 0.22), PEARL, LIT)


## A flat leaf from `a` (the stalk end) to `b` (the tip), `width` across at its widest, closed (two
## faces) so it reads from both sides.
func _leaf(a: Vector3, b: Vector3, width: float, col: Color) -> void:
	var d := b - a
	var side := d.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized() * width * 0.5
	var m1 := a + d * 0.4
	var up := Vector3.UP * width * 0.12
	var nrm := side.cross(d).normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	# Two faces a hand's breadth apart (a leaf is a thin shell), so no two faces share a plane.
	var t := nrm * 0.03
	Props.tri(_st, a + t, m1 + side + up + t, m1 - side + up + t, nrm, col, LIT)
	Props.tri(_st, m1 + side + up + t, b + t, m1 - side + up + t, nrm, col, LIT)
	Props.tri(_st, a - t, m1 - side + up - t, m1 + side + up - t, -nrm, col.darkened(0.25), LIT)
	Props.tri(_st, m1 + side + up - t, m1 - side + up - t, b - t, -nrm, col.darkened(0.25), LIT)


## One arch (F's photos, 2026-11-15): from each round painted planter a bundle of green tube stems
## (one thick, two thin that wind round it) rises over the walk, the thick one crosses the other
## and hangs its white lace bell past the middle; broad leaves at three heights up the stems.
func _arch(a2: Vector2, b2: Vector2) -> void:
	var a := _v(a2, _g(a2))
	var b := _v(b2, _g(b2))
	_base(a2, a.y, FOOT_R, FOOT_H)
	_base(b2, b.y, FOOT_R, FOOT_H)
	a.y += FOOT_H
	b.y += FOOT_H
	var mid := (a + b) * 0.5
	var across := (b - a).normalized()
	# The two stems pass each other 0.5 m apart along the walk.
	var along3 := Vector3(-across.z, 0, across.x)
	var shift := 0.25
	var top_end := Vector3.ZERO
	for side in [[a, b], [b, a]]:
		var from: Vector3 = side[0]
		var to: Vector3 = side[1]
		var dir := (to - from).normalized()
		var end := mid + dir * 1.15 + Vector3.UP * 4.3 + along3 * shift
		var ctl := from.lerp(mid, 0.55) + Vector3.UP * 8.4 + along3 * shift
		_stem(from, ctl, end, 12, 0.22, false)
		# Two thin strands winding up beside the main one, ending on the bell's stalk.
		for sgn: float in [-1.0, 1.0]:
			var foot := from + along3 * 0.35 * sgn
			var wind := from.lerp(mid, 0.4) + Vector3.UP * 6.0 - along3 * 0.6 * sgn + along3 * shift
			_stem(foot, wind, end - Vector3.UP * 0.15, 8, 0.08, false)
		shift = -shift
		_bell(end, 0.95, atan2(dir.z, dir.x))
		_leaves(from, dir, along3)
		if top_end == Vector3.ZERO:
			top_end = _quad(from, ctl, end, 0.5)
	_tops.append(Vector3(mid.x, top_end.y, mid.z))


## Broad leaves up the stems from a foot: two at the planter, one higher, a bluish one on the
## stem's far side, as on the photos.
func _leaves(foot: Vector3, dir: Vector3, along3: Vector3) -> void:
	var specs := [[0.5, 0.9, 1.7, 0], [0.3, -0.9, 1.5, 1], [1.8, 0.8, 1.4, 0], [3.0, -0.7, 1.2, 1]]
	for sp: Array in specs:
		var base_at := foot + Vector3.UP * float(sp[0]) + dir * 0.35 * float(sp[0]) * 0.3
		var out := (dir * 0.6 + along3 * float(sp[1])).normalized()
		var tip := base_at + out * float(sp[2]) + Vector3.UP * 0.5
		_leaf(base_at, tip, float(sp[2]) * 0.55, LEAF if int(sp[3]) == 0 else LEAF_BLUE)


## `n` broad leaves from a foot, spreading round `yaw` (the dandelions and single bell flowers).
func _ground_leaves(foot: Vector3, yaw: float, n: int, length: float) -> void:
	for k in n:
		var a := yaw + PI * 0.5 + (k - (n - 1) * 0.5) * 0.9 + PI * (k % 2)
		var out := Vector3(cos(a), 0, sin(a))
		_leaf(foot, foot + out * length * 0.7 + Vector3.UP * length * 0.8, length * 0.4, LEAF)


## The bulb strings (F's photos): from each arch's crown to the next, sagging, a warm bulb at every
## joint; on some spans a butterfly hangs from it by two cords.
func _festoons() -> void:
	for i in _tops.size() - 1:
		var a := _tops[i]
		var b := _tops[i + 1]
		var n := 10
		var prev := a
		for k in range(1, n + 1):
			var t := float(k) / n
			var p := a.lerp(b, t) + Vector3.DOWN * 1.4 * sin(PI * t)
			Props.beam(_st, prev, p, 0.035, 0.035, DARK)
			if k < n:
				Props.box(_st, p + Vector3(0, -0.1, 0), Vector3(0.13, 0.13, 0.13), BULB, LIT)
			prev = p
		if SPAN_BUTTERFLY.has(i):
			var c1 := a.lerp(b, 0.43) + Vector3.DOWN * 1.4 * sin(PI * 0.43)
			var c2 := a.lerp(b, 0.57) + Vector3.DOWN * 1.4 * sin(PI * 0.57)
			var hang := (c1 + c2) * 0.5 + Vector3.DOWN * 1.5
			Props.beam(_st, c1, hang + (c1 - c2).normalized() * 0.4, 0.02, 0.02, STEEL_DARK)
			Props.beam(_st, c2, hang - (c1 - c2).normalized() * 0.4, 0.02, 0.02, STEEL_DARK)
			var f := b - a
			_butterfly(hang + Vector3(0, 0.05, 0), atan2(f.z, f.x) + PI * 0.5, i, 2.2)


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
		Props.tri(_st, _v(p, y + h), _v(q0, y + h), _v(q1, y + h), Vector3.UP, GRATE)
		var c := _v((q0 + q1) * 0.5, y + h * (0.35 + 0.3 * (k % 2))) + n * 0.02
		if k % 4 == 1:
			# A mushroom printed on the panel: a pale stem under a red cap.
			Props.box(_st, c - Vector3(0, h * 0.12, 0), Vector3(0.1 * r + 0.06, h * 0.3, 0.1 * r + 0.06), MUSHROOM_STEM)
			Props.box(_st, c + Vector3(0, h * 0.1, 0), Vector3(0.3 * r + 0.1, h * 0.2, 0.3 * r + 0.1), BASE_ART[0])
		else:
			Props.box(_st, c, Vector3(0.22 * r + 0.1, 0.2 * r + 0.1, 0.22 * r + 0.1), BASE_ART[(k + count) % BASE_ART.size()])


## A giant dandelion `h` high: base, pale stem, leaves, and the clock of spikes with warm tips.
func _dandelion(p: Vector2, h: float) -> void:
	var y := _g(p)
	_base(p, y, 0.6, 0.5)
	var lean := Vector3(sin(p.x * 1.7) * 0.35, 0, cos(p.y * 1.3) * 0.35)
	var head := _v(p, y + h) + lean
	_stem(_v(p, y), _v(p, y + h * 0.6), head, 6, 0.12, false)
	_ground_leaves(_v(p, y + 0.5), p.x * 0.7, 3, 1.7)
	var r := 1.45
	var n := 44
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
	_ground_leaves(foot, yaw, 2, 1.4)
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


## The gold lattice photo frame north of the fountain (F's photos): a squared-off gold arch of
## three thick panels (two posts, a lintel) with a diamond lattice, a sill, painted poster panels
## on the outer sides; stand at it and the Palace fills the opening.
func _photo_frame() -> void:
	var to_palace := (PALACE - FOUNTAIN).normalized()
	var p := FOUNTAIN - to_palace * (RING_R + 4.6)
	var y := _g(p)
	var fwd := Vector3(to_palace.x, 0, to_palace.y)
	var across := Vector3(-fwd.z, 0, fwd.x)
	var basis := Basis(across, Vector3.UP, fwd)
	var c := _v(p, y)
	var half := 1.5       # the opening's half width
	var post := 0.75
	var depth := 0.55
	var top := 2.9
	# A low dark platform, the two posts, the lintel and the sill.
	Props.obox(_st, c + Vector3.UP * 0.05, basis, Vector3(half * 2 + post * 2 + 0.3, 0.1, depth + 0.7), FRAME_LATTICE)
	var ph := top - 0.65     # the posts end a hand inside the lintel
	for sgn: float in [-1.0, 1.0]:
		var at := c + across * (half + post * 0.5) * sgn + Vector3.UP * (ph * 0.5 + 0.1)
		Props.obox(_st, at, basis, Vector3(post, ph, depth), FRAME_GOLD, LIT)
		# The painted poster on the outer side, and a diamond lattice on the front and back faces.
		Props.obox(_st, at + across * (post * 0.5 + 0.02) * sgn, basis, Vector3(0.05, ph * 0.85, depth * 0.9),
				FRAME_POSTER[0 if sgn < 0.0 else 1], LIT)
		for face: float in [-1.0, 1.0]:
			var f := fwd * (depth * 0.5 + 0.02) * face
			for j in 3:
				var y0 := 0.1 + j * 0.72
				Props.beam(_st, at + f + Vector3(0, y0 - ph * 0.5, 0) - across * post * 0.4 * sgn,
						at + f + Vector3(0, y0 + 0.6 - ph * 0.5, 0) + across * post * 0.4 * sgn, 0.035, 0.035, FRAME_LATTICE, Vector3.UP, LIT)
				# The crossing diagonal sits a finger proud of the first.
				var g := f * 1.0 + fwd * 0.04 * face
				Props.beam(_st, at + g + Vector3(0, y0 + 0.6 - ph * 0.5, 0) - across * post * 0.4 * sgn,
						at + g + Vector3(0, y0 - ph * 0.5, 0) + across * post * 0.4 * sgn, 0.035, 0.035, FRAME_LATTICE, Vector3.UP, LIT)
	var lintel := c + Vector3.UP * (top - 0.3)
	Props.obox(_st, lintel, basis, Vector3(half * 2 + post * 2 + 0.08, 0.6, depth + 0.06), FRAME_GOLD, LIT)
	for face: float in [-1.0, 1.0]:
		var f := fwd * (depth * 0.5 + 0.06) * face
		for j in 7:
			var x0 := -half - post + 0.2 + j * ((half * 2 + post * 2 - 0.4) / 6.0)
			Props.beam(_st, lintel + f + across * x0 - Vector3.UP * 0.25, lintel + f + across * (x0 + 0.4) + Vector3.UP * 0.25,
					0.035, 0.035, FRAME_LATTICE, Vector3.UP, LIT)
	Props.obox(_st, c + Vector3.UP * 0.55, basis, Vector3(half * 2, 0.5, depth * 0.8), FRAME_GOLD, LIT)
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
	_mat = mat
	_vehicle = ctx.get("vehicle", Callable())
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


## The sensors: the car's ground point to the shader while it drives near the projections (not
## from the helicopter), w 0 once when it leaves.
func _process(_dt: float) -> void:
	if _mat == null or not _vehicle.is_valid():
		return
	var v: Array = _vehicle.call()
	var at: Vector3 = v[0]
	var on := not bool(v[2]) and Vector2(at.x, at.z).distance_to(NEAR_FROM) < NEAR_R
	if on:
		_mat.set_shader_parameter("visitor", Vector4(at.x, at.z, 0.0, 1.0))
		_sent = 1.0
	elif _sent != 0.0:
		_mat.set_shader_parameter("visitor", Vector4(0.0, 0.0, 0.0, 0.0))
		_sent = 0.0
