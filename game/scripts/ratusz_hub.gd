extends Node3D
## The Ratusz Arsenał interchange (F's six photos, 2026-11-07): the tram stops at the junction of
## Al. Solidarności and Andersa beside Metro Ratusz-Arsenał, as the real place has them:
##  - **the arched canopies** over the three tram platforms at the junction (Solidarności's two east
##    of Andersa, Andersa's southbound one): a row of white steel arches every RIB m, each springing
##    from the platform's back edge, rising and curving over towards the tracks like a breaking
##    wave; longitudinal tubes along them, a glass wall at the back and one band of glass high on the
##    curve (the rest drawn open, so the camera sees the people waiting under it). The arches are
##    LIT_SIGN, so at night every one glows white, as in F's night photo;
##  - under each canopy **benches** along the back glass and two **passenger information boards**
##    (amber departure lines on a dark screen, lit at night);
##  - **the round stone tower** on the setts strip across Andersa's tracks from the canopy: a
##    plinth, a drum of cream ashlar with its joints, a frieze of roundels, a cornice, a low dark
##    green roof, a ribbed zinc spire and a gold ball; a dark wooden door and a barred window;
##  - **black railings** round the tower, kept clear of the tracks.
## The station's own entrances are Props.add_metro_entrance's Ratusz forms (storefronts.metro_form):
## the glass escalator pavilion, the stone M1 entrances with the white canopy and the stone
## stairwells, all with the yellow roundel.
##
## Built at runtime on both city paths, like street_details.gd: ONE mesh in the actors' material
## (models.gd), so one draw call while the junction is in view, no shadow (the canopy's shade is a
## pale band painted on the platform instead), and one StaticBody for the tower. Generic shelters
## standing inside a hub platform are dropped by map_builder (`covers`). check_ratusz_hub.gd holds it.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

const FIXED := Models.FIXED
const LIT_SIGN := Models.LIT_SIGN
const LIT_WINDOW := Models.LIT_WINDOW

## The station (OSM's name on the entrances).
const STATION := "Ratusz-Arsenał"
## The hub platforms' centres (the bake's tram platforms at the junction): a platform whose centre
## lies within MATCH m of one of these carries a canopy. Only the two Solidarności platforms (stops
## 09 and 10, covered on both sides); stop 03 on Andersa keeps its ordinary shelters (F, 2026-11-07).
const PLATFORMS := [Vector2(-1488.1, -1188.9), Vector2(-1480.5, -1170.0)]
const MATCH := 8.0
## Gruba Kaśka na Tłomackiem (the 18th-century well house): between the two Solidarności tracks,
## across from the east end of the north canopy (F's satellite view and photos, 2026-11-07).
const TOWER := Vector2(-1461.0, -1192.5)
const TOWER_R := 2.1
## Railings round the tower at this radius; a railing piece within RAIL_CLEAR m of a track stays out.
const FENCE_R := 3.5
const RAIL_CLEAR := 2.3
## Canopy: the arches' spacing (m), the longest canopy (m), its share of the platform's length,
## its deepest reach from the back edge (m), and the inset from the platform's edges (m).
const RIB := 2.4
const CANOPY_MAX := 48.0
const CANOPY_SHARE := 0.72
const DEPTH_MAX := 5.6
const INSET := 0.35
## The arch's side profile as (share of the depth from the back edge, height over the platform).
const PROFILE := [Vector2(0.0, 0.0), Vector2(0.015, 1.4), Vector2(0.06, 2.6), Vector2(0.16, 3.55),
		Vector2(0.32, 4.2), Vector2(0.52, 4.42), Vector2(0.76, 4.28), Vector2(1.0, 3.9)]
## Which profile segments are glazed (one band high on the back of the curve); the rest is drawn
## open (the mesh is opaque: real glass would hide nobody, ours would hide everyone under it).
const GLAZED := [3]

const WHITE := Color("#eef3f6")
const TUBE := Color("#c9ced2")
const GLASS := Color("#a3bcc8")
const SHADE := Color("#a9a59d")
const STONE := Color("#dccfae")
const STONE_JOINT := Color("#b8a988")
const ROOF := Color("#4d6358")
const COPPER := Color("#5a9c80")
const BASE_GREY := Color("#8d8b86")
const GOLD := Color("#d6a83e")
const DOOR := Color("#4a3f35")
const RAILING := Color("#232427")

var map: Node3D
## What was built (the check reads these).
var canopies := 0
var arches := 0
var boards := 0
var benches := 0
var triangles := 0


## The hub platforms in `data`: [{poly, h, c (centre), a (along), n (towards the tracks),
## u0, u1 (along range), v0, v1 (across range, v1 the track side)}].
static func hub_platforms(data: Dictionary) -> Array:
	var out: Array = []
	var tracks := _track_segments(data, PLATFORMS[0], 220.0)
	for pl: Dictionary in data.get("platforms", []):
		var flat: Array = pl.get("p", [])
		if flat.size() < 6:
			continue
		var poly := PackedVector2Array()
		var c := Vector2.ZERO
		for i in range(0, flat.size() - 1, 2):
			poly.append(Vector2(float(flat[i]), float(flat[i + 1])))
			c += poly[poly.size() - 1]
		c /= float(poly.size())
		var hit := false
		for want: Vector2 in PLATFORMS:
			if want.distance_to(c) <= MATCH:
				hit = true
		if not hit:
			continue
		# The long axis: the farthest pair of corners.
		var best := 0.0
		var a := Vector2.RIGHT
		for p in poly:
			for q in poly:
				if p.distance_to(q) > best:
					best = p.distance_to(q)
					a = (q - p).normalized()
		var n := Vector2(-a.y, a.x)
		# The tracks' side: the nearest track point's side of the axis.
		var nearest := INF
		var side := 1.0
		for sg: Array in tracks:
			var cp := Geometry2D.get_closest_point_to_segment(c, sg[0], sg[1])
			if cp.distance_to(c) < nearest:
				nearest = cp.distance_to(c)
				side = signf((cp - c).dot(n))
		if side == 0.0:
			side = 1.0
		n *= side
		var u0 := INF
		var u1 := -INF
		var v0 := INF
		var v1 := -INF
		for p in poly:
			u0 = minf(u0, (p - c).dot(a))
			u1 = maxf(u1, (p - c).dot(a))
			v0 = minf(v0, (p - c).dot(n))
			v1 = maxf(v1, (p - c).dot(n))
		out.append({"poly": poly, "h": float(pl.get("h", 0.25)), "c": c, "a": a, "n": n,
				"u0": u0, "u1": u1, "v0": v0, "v1": v1})
	return out


## Whether (x, z) stands inside a hub platform (map_builder drops the generic shelter there).
static func covers(x: float, z: float, plats: Array) -> bool:
	for p: Dictionary in plats:
		if Geometry2D.is_point_in_polygon(Vector2(x, z), p["poly"]):
			return true
	return false


## The tram tracks' segments within `reach` m of `at`, as [a, b] pairs.
static func _track_segments(data: Dictionary, at: Vector2, reach: float) -> Array:
	var out: Array = []
	for t: Dictionary in data.get("trams", []):
		var p: Array = t["p"]
		for i in range(0, p.size() - 3, 2):
			var a := Vector2(float(p[i]), float(p[i + 1]))
			var b := Vector2(float(p[i + 2]), float(p[i + 3]))
			if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) <= reach:
				out.append([a, b])
	return out


## The canopy's plan for a hub platform: [u start, u end, depth, the back edge's v].
static func canopy_span(p: Dictionary) -> Array:
	var length: float = float(p["u1"]) - float(p["u0"])
	var span := minf(length * CANOPY_SHARE, CANOPY_MAX)
	var mid: float = (float(p["u0"]) + float(p["u1"])) * 0.5
	var depth := minf(float(p["v1"]) - float(p["v0"]) - 2.0 * INSET, DEPTH_MAX)
	return [mid - span * 0.5, mid + span * 0.5, depth, float(p["v0"]) + INSET]


## The platform's walking top: map_builder's own when it has one, else its slab's formula (the
## outline's lowest ground + h + 0.1).
func _top(p: Dictionary) -> float:
	var c: Vector2 = p["c"]
	if map != null and map.has_method("platform_top"):
		var t: float = map.call("platform_top", c.x, c.y)
		if not is_nan(t):
			return t
	var ground := INF
	for q: Vector2 in p["poly"]:
		ground = minf(ground, map.terrain_height(q.x, q.y) if map != null else 0.0)
	return ground + float(p["h"]) + 0.1


## Builds the mesh and the tower's collider from `data` (centrum.json).
func build(data: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Dictionary in hub_platforms(data):
		_canopy(st, p, _top(p))
	var g: float = map.terrain_height(TOWER.x, TOWER.y) if map != null else 0.0
	var face := Vector2(1, 0)
	var plats := hub_platforms(data)
	if not plats.is_empty():
		face = ((plats[0]["c"] as Vector2) - TOWER).normalized()
	_tower(st, Vector3(TOWER.x, g, TOWER.y), Vector3(face.x, 0.0, face.y))
	_railings(st, g, _track_segments(data, TOWER, 30.0))
	var mesh := st.commit()
	if mesh.get_surface_count() == 0:
		return
	triangles = mesh.surface_get_array_len(0) / 3
	var mi := MeshInstance3D.new()
	mi.name = "RatuszHubMesh"
	mi.mesh = mesh
	mi.material_override = Models.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = "RatuszTowerSolid"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = TOWER_R + 0.15
	cyl.height = 7.0
	shape.shape = cyl
	shape.position = Vector3(TOWER.x, g + 3.5, TOWER.y)
	body.add_child(shape)
	add_child(body)


## One platform's canopy, benches and boards; `top` the platform's walking surface.
func _canopy(st: SurfaceTool, p: Dictionary, top: float) -> void:
	var span := canopy_span(p)
	var u0: float = span[0]
	var u1: float = span[1]
	var depth: float = span[2]
	var vb: float = span[3]
	if depth < 2.0 or u1 - u0 < RIB * 2.0:
		return
	canopies += 1
	var c: Vector2 = p["c"]
	var a: Vector2 = p["a"]
	var n: Vector2 = p["n"]
	var at := func(u: float, k: int) -> Vector3:
		var pr: Vector2 = PROFILE[k]
		var q := c + a * u + n * (vb + pr.x * depth)
		return Vector3(q.x, top + pr.y, q.y)
	var ribs := int(floorf((u1 - u0) / RIB)) + 1
	var step := (u1 - u0) / float(ribs - 1)
	var up := Vector3.UP
	var along := Vector3(a.x, 0.0, a.y)
	# The pale band of the canopy's shade on the platform under the glazed half.
	var s0: Vector3 = at.call(u0, 0)
	var s1: Vector3 = at.call(u1, 0)
	var f0: Vector3 = at.call(u0, 5)
	var f1: Vector3 = at.call(u1, 5)
	Props.tri(st, s0 + up * 0.012, s1 + up * 0.012, Vector3(f1.x, top + 0.012, f1.z), up, SHADE)
	Props.tri(st, s0 + up * 0.012, Vector3(f1.x, top + 0.012, f1.z), Vector3(f0.x, top + 0.012, f0.z), up, SHADE)
	for i in ribs:
		var u := u0 + step * i
		# The arch: one tube per profile segment, a foot plate at the back.
		for k in PROFILE.size() - 1:
			Props.beam(st, at.call(u, k), at.call(u, k + 1), 0.17, 0.17, WHITE, along, LIT_SIGN)
		var foot: Vector3 = at.call(u, 0)
		Props.obox(st, foot + up * 0.04, _basis(a, n), Vector3(0.5, 0.08, 0.5), TUBE)
		arches += 1
	# The longitudinal tubes along the profile's points and the back's glass wall.
	for k in range(1, PROFILE.size()):
		Props.beam(st, at.call(u0, k), at.call(u1, k), 0.08, 0.08, TUBE, at.call(u0, k) - at.call(u0, k - 1))
	var g0: Vector3 = at.call(u0, 0)
	var g1: Vector3 = at.call(u1, 0)
	var back := Vector3(-n.x, 0.0, -n.y)
	_quad2(st, g0 + up * 0.25, g1 + up * 0.25, g1 + up * 2.2, g0 + up * 2.2, back, GLASS)
	Props.beam(st, g0 + up * 0.2, g1 + up * 0.2, 0.1, 0.1, TUBE, up)
	# The glass over the back of the curve.
	for k: int in GLAZED:
		var a0: Vector3 = at.call(u0, k)
		var a1: Vector3 = at.call(u1, k)
		var b1: Vector3 = at.call(u1, k + 1)
		var b0: Vector3 = at.call(u0, k + 1)
		var e := (b0 - a0)
		var nn := along.cross(e).normalized()
		if nn.y < 0.0:
			nn = -nn
		_quad2(st, a0 + nn * 0.1, a1 + nn * 0.1, b1 + nn * 0.1, b0 + nn * 0.1, nn, GLASS)
	# Benches along the back glass (facing the tracks), one every third bay.
	var face := atan2(n.x, n.y)  # the bench's back (+z) away from the tracks
	var i := 1
	while i < ribs - 1:
		var q := c + a * (u0 + step * (i + 0.5)) + n * (vb + 0.75)
		Props.add_stop_bench(st, Transform3D(Basis(Vector3.UP, face + PI), Vector3(q.x, top, q.y)))
		benches += 1
		i += 3
	# Two passenger information boards, a third of the way in from each end, under the curve's top.
	for k: float in [0.3, 0.7]:
		var q := c + a * lerpf(u0, u1, k) + n * (vb + depth * 0.62)
		_board(st, Vector3(q.x, top, q.y), a)
		boards += 1


## A basis with x along `a` and z along `n` (plan vectors).
static func _basis(a: Vector2, n: Vector2) -> Basis:
	return Basis(Vector3(a.x, 0.0, a.y), Vector3.UP, Vector3(n.x, 0.0, n.y))


## A two-sided quad.
static func _quad2(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3, col: Color, part := FIXED) -> void:
	for s: float in [1.0, -1.0]:
		var o := n * 0.01 * s
		if s > 0.0:
			Props.tri(st, p0 + o, p1 + o, p2 + o, n, col, part)
			Props.tri(st, p0 + o, p2 + o, p3 + o, n, col, part)
		else:
			Props.tri(st, p0 + o, p2 + o, p1 + o, -n, col, part)
			Props.tri(st, p0 + o, p3 + o, p2 + o, -n, col, part)


## A passenger information board (the stop's departures display): a grey post, a dark case with an
## amber screen of four departure lines on both faces (lit at night), its faces along the platform.
static func _board(st: SurfaceTool, at: Vector3, a: Vector2) -> void:
	var b := Basis(Vector3(-a.y, 0.0, a.x), Vector3.UP, Vector3(a.x, 0.0, a.y))
	var xf := Transform3D(b, at)
	Props.obox(st, xf * Vector3(0, 1.4, 0), b, Vector3(0.1, 2.8, 0.1), Color("#5d6168"))
	Props.obox(st, xf * Vector3(0, 2.65, 0), b, Vector3(1.3, 0.62, 0.14), Color("#202226"))
	for s: float in [-1.0, 1.0]:
		Props.obox(st, xf * Vector3(0, 2.65, 0.075 * s), b, Vector3(1.16, 0.5, 0.01), Color("#141518"))
		for row in 4:
			var w := [0.95, 0.8, 0.9, 0.6][row] as float
			Props.obox(st, xf * Vector3(-0.53 + w * 0.5, 2.83 - row * 0.12, 0.082 * s), b, Vector3(w, 0.05, 0.006),
					Color("#ffb21e"), LIT_SIGN)


## Gruba Kaśka at `base` (its foot's centre on the ground), its door facing `door` (F's photos): a
## grey base, a tall cream ashlar drum, a roundel frieze under a projecting cornice, a stepped
## dark roof, a tall green-copper spire and a gold ball; a tall dark wooden door, a barred window.
func _tower(st: SurfaceTool, base: Vector3, door: Vector3) -> void:
	var sides := 18
	var r := TOWER_R
	_frustum(st, base, r + 0.18, 0.0, r + 0.18, 0.7, sides, BASE_GREY, true)
	_frustum(st, base, r + 0.18, 0.7, r, 0.82, sides, BASE_GREY.lightened(0.1), true)
	_frustum(st, base, r, 0.82, r, 5.3, sides, STONE, false)
	# The ashlar's bed joints.
	for k in 9:
		var y := 1.25 + k * 0.45
		_frustum(st, base, r + 0.012, y, r + 0.012, y + 0.03, sides, STONE_JOINT, false)
	# The frieze band with its roundels, the cornice projecting over it.
	_frustum(st, base, r + 0.04, 5.3, r + 0.04, 5.85, sides, STONE.lightened(0.05), false)
	for k in 12:
		var ang := TAU * (k + 0.5) / 12.0
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var cen := base + dir * (r + 0.06) + Vector3.UP * 5.575
		Props.obox(st, cen, Basis(dir.cross(Vector3.UP), Vector3.UP, dir), Vector3(0.32, 0.32, 0.03), STONE_JOINT)
	_frustum(st, base, r + 0.06, 5.85, r + 0.42, 6.05, sides, STONE.lightened(0.08), false)
	_frustum(st, base, r + 0.42, 6.05, r + 0.42, 6.18, sides, STONE.lightened(0.08), true)
	# The stepped dark roof, the green-copper spire, the gold ball.
	var y := 6.18
	for ring: float in [2.35, 1.95, 1.55, 1.2]:
		_frustum(st, base, ring, y, ring - 0.12, y + 0.18, sides, ROOF, true)
		y += 0.18
	_frustum(st, base, 0.75, y, 0.18, 9.0, 10, COPPER, true)
	_frustum(st, base, 0.06, 9.0, 0.06, 9.08, 6, GOLD, false)
	_frustum(st, base, 0.06, 9.08, 0.32, 9.3, 8, GOLD, false)
	_frustum(st, base, 0.32, 9.3, 0.0, 9.6, 8, GOLD, false)
	# The tall door on its stone step, with a stone surround, and the barred window round the back.
	var b := Basis(door.cross(Vector3.UP).normalized(), Vector3.UP, door)
	Props.obox(st, base + door * (r + 0.2) + Vector3.UP * 1.4, b, Vector3(1.36, 2.7, 0.06), STONE_JOINT)
	Props.obox(st, base + door * (r + 0.23) + Vector3.UP * 1.33, b, Vector3(1.0, 2.5, 0.06), DOOR)
	Props.obox(st, base + door * (r + 0.27) + Vector3.UP * 1.33, b, Vector3(0.03, 2.5, 0.03), DOOR.darkened(0.3))
	Props.obox(st, base + door * (r + 0.45) + Vector3.UP * 0.06, b, Vector3(1.5, 0.12, 0.5), BASE_GREY)
	var w := -door
	var bw := Basis(w.cross(Vector3.UP).normalized(), Vector3.UP, w)
	Props.obox(st, base + w * (r + 0.02) + Vector3.UP * 3.9, bw, Vector3(0.5, 0.6, 0.05), Color("#1e1f22"))
	for k in 3:
		Props.obox(st, base + w * (r + 0.05) + Vector3.UP * 3.9 + bw.x * (-0.15 + k * 0.15), bw,
				Vector3(0.03, 0.6, 0.03), RAILING)


## A ring of `n` sides from radius r0 at y0 to r1 at y1 (over `base`), with a top cap when `cap`.
static func _frustum(st: SurfaceTool, base: Vector3, r0: float, y0: float, r1: float, y1: float, n: int, col: Color, cap: bool) -> void:
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var p0 := base + d0 * r0 + Vector3.UP * y0
		var p1 := base + d1 * r0 + Vector3.UP * y0
		var q0 := base + d0 * r1 + Vector3.UP * y1
		var q1 := base + d1 * r1 + Vector3.UP * y1
		var nn := ((d0 + d1) * 0.5).normalized() * (y1 - y0) + Vector3.UP * (r0 - r1)
		nn = nn.normalized()
		Props.tri(st, p0, q1, p1, nn, col)
		Props.tri(st, p0, q0, q1, nn, col)
		if cap and r1 > 0.01:
			Props.tri(st, base + Vector3.UP * y1, q1, q0, Vector3.UP, col)


## Black railings round the tower: a post every 1.5 m and two rails, a piece left out where it
## comes within RAIL_CLEAR m of a track (the trams pass the tower's track side).
static func _railings(st: SurfaceTool, g: float, tracks: Array) -> void:
	var n := 14
	var pts: Array[Vector2] = []
	for k in n:
		pts.append(TOWER + Vector2.from_angle(TAU * k / n) * FENCE_R)
	for k in n:
		var p := pts[k]
		var q := pts[(k + 1) % n]
		if _near_track(p, tracks) or _near_track(q, tracks) or _near_track((p + q) * 0.5, tracks):
			continue
		var a := Vector3(p.x, g, p.y)
		var b := Vector3(q.x, g, q.y)
		for y: float in [0.45, 1.05]:
			Props.beam(st, a + Vector3.UP * y, b + Vector3.UP * y, 0.05, 0.05, RAILING)
		Props.beam(st, a, a + Vector3.UP * 1.1, 0.06, 0.06, RAILING, b - a)
		Props.beam(st, b, b + Vector3.UP * 1.1, 0.06, 0.06, RAILING, b - a)


static func _near_track(p: Vector2, tracks: Array) -> bool:
	for sg: Array in tracks:
		if Geometry2D.get_closest_point_to_segment(p, sg[0], sg[1]).distance_to(p) < RAIL_CLEAR:
			return true
	return false
