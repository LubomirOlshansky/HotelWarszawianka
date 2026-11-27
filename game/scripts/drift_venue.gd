extends RefCounted
## Bokiem na Narodowym, PR 2 (2026-11-27, docs/design/drift-narodowy.md 0b.4 and 6, critique-drift.md
## change 14): the Stadion Narodowy round the grey box's floor, as a cutaway diorama. Static builders that
## drift_stadium.gd calls once, on the first visit (nothing here runs per frame):
##   - `bowl_mesh`: the two stepped tiers in the Narodowy's red and white (the treads full of people, a
##     shader's cells), the walkway and the hospitality band between them, the roof ring with its membrane,
##     the pitch-side LED ring, the LED band under the upper tier, the track wall's banners and the
##     stages' screens: one mesh, one draw call, in the venue's unshaded material (drift_venue.gdshader).
##     The near quadrant (towards the iso camera, yaw 45°) keeps only its lower tier, capped with the
##     red and white facade panels, so the camera never looks through a wall; the far upper tier and roof
##     land off the track on screen (`footprint`; check_drift V1).
##   - `spire_mesh`: the centre spire with its hub, the hanging screen cube and the cables to the roof's far
##     side (its own node: WIDOK Z GÓRY hides it, it would hang over the crossover).
##   - `crowd`: one MultiMesh of figures on the treads, front rows first, so a tier's cap takes the first N.
##   - `dress`: the lit dressing added to the floor's mesh (the actors' material, no extra draw call): the
##     apron to the stands, the concrete track wall along the loops' offsets (visual only: the drift model
##     decides walls, critique change 13), tyre stacks on the loops' far sides, the islands' red and white
##     kerbs, the stages and their truss, the inflatable Turbo Tur can, the flame posts.
##   - `flame_mesh`, `flame_spots`: the flame jets' shape and where they stand (drift_stadium.gd pools them).
##   - `atlas`: the boards' words (drift_tracks.json `boards`, Polish only in the world, the 5×7 pixel font)
##     as one small texture, one row a board.
## Sizes (m) in the stadium's own coordinates (drift_stadium.gd PLACE is 0, 0, 0).

const PixelFont := preload("res://scripts/pixel_font.gd")
const Models := preload("res://scripts/models.gd")
const DriftLine := preload("res://scripts/drift_line.gd")

const SHADER := "res://shaders/drift_venue.gdshader"
## Half the floor (drift_stadium.gd FLOOR / 2).
const HALF := Vector2(75.0, 45.0)
## The venue shader's parts (UV2.x).
const PLAIN := 0.0
const LAMP := 1.0
const LED := 2.0
const TREAD := 3.0
const PRINT := 4.0
const HEAD := 5.0
const PHONE := 6.0
## The bowl's inner edge: a rounded rectangle round the floor, CORE the corners' centres, RC their radius
## (82 × 52 m half, enclosing the floor's corners), sampled CORNER_STEPS a corner and SIDE_STEPS a side.
const CORE := Vector2(58.0, 28.0)
const RC := 24.0
const CORNER_STEPS := 8
const SIDE_STEPS := Vector2i(20, 10)
## The lower tier: the pitch-side wall (its LED ring), then LOW_ROWS rows up to LOW_T m back, LOW_Y m high.
const FRONT_Y := 2.2
const LOW_ROWS := 12
const LOW_T := 24.0
const LOW_Y := 13.0
## The walkway, the hospitality band and the upper tier.
const WALK_T := 27.0
const UP_Y0 := 18.0
const UP_ROWS := 12
const UP_T := 55.0
const UP_Y := 40.0
const BACK_Y := 43.0
## The roof ring: from ROOF_IN m off the floor's edge (over the walkway) to ROOF_OUT, rising a little.
const ROOF_IN := 20.0
const ROOF_OUT := 60.0
const ROOF_Y0 := 47.0
const ROOF_Y1 := 50.0
## The spire: the hub, the needle's top, the screen cube under the hub.
const HUB_R := 7.0
const HUB_Y := 54.0
const NEEDLE_Y := 100.0
const CUBE := Vector2(8.0, 5.0)
## Towards the iso camera on the floor (yaw 45°); a section whose outward normal is past NEAR_CUT is cut.
const CAM := Vector2(0.70710678, 0.70710678)
const NEAR_CUT := 0.35
## The iso camera's pitch (drift_stadium.gd ISO_PITCH): `occludes` projects along it.
const ISO_TAN := 0.83910
## The track wall: the loops' radius plus WALL_OFF, WALL_H high; tyre stacks on each loop's far side.
const WALL_OFF := 8.0
const WALL_H := 1.15
const TYRE_ARC := 0.75
## The kerb round each island and the flame posts on it.
const KERB_W := 0.6
const FLAMES_PER_ISLAND := 4
## The boards' atlas: a row a board, ROW_PX high, ATLAS_PX wide; a board is BOARD_LEN m along.
const ATLAS_PX := 128
const ROW_PX := 12
const BOARD_LEN := 9.0
## The baked light on the unshaded venue.
const SUN := Vector3(0.35, 0.85, 0.4)

const SEAT_RED := Color("#c42a2f")
const SEAT_WHITE := Color("#e4e0d8")
const RISER := Color("#4a4646")
const CONCRETE := Color("#8f8c85")
const SECTION := Color("#7c7973")
const GLASS := Color("#2b3746")
const WINDOW := Color("#ffcf8a")
const MEMBRANE := Color("#ecebe6")
const MEMBRANE_RIB := Color("#c9c7c0")
const STEEL := Color("#3d4046")
const LAMPS := Color("#fff4d6")
const FACADE := [Color("#d42e32"), Color("#f0ece4"), Color("#d42e32"), Color("#b9bcc0")]
const BOARD_DARK := Color("#16181d")
const APRON := Color("#6f6c66")
const WALL := Color("#b5b1a7")
const TYRE := Color("#1c1c1f")
const TYRE_PAINT := Color("#d8d4cc")
const KERB_RED := Color("#d23a35")
const KERB_WHITE := Color("#f1ede4")
const STAGE := Color("#2c2d31")
const TRUSS := Color("#9a9ca1")
const CAN := Color("#ff7a1a")
const CAN_TOP := Color("#c9ccd1")
const SHIRTS := [Color("#1d1f26"), Color("#e9e6df"), Color("#c8202a"), Color("#2b3a5c"), Color("#5b5e63"),
		Color("#ffffff"), Color("#c8202a"), Color("#13151a"), Color("#7a2230"), Color("#d9b44a")]


# --- the shape ------------------------------------------------------------------------------------

## The ring's samples: Vector4(base x, base z, outward normal x, z); a point `t` m off the floor's side
## is base + normal × (RC + t). Counter-clockwise from the east side's south end.
static func ring() -> Array[Vector4]:
	var out: Array[Vector4] = []
	var a := CORE.x
	var b := CORE.y
	var sides := [[Vector2(a, -b), Vector2(a, b), Vector2(1, 0), SIDE_STEPS.y], [Vector2(a, b), Vector2(-a, b), Vector2(0, 1), SIDE_STEPS.x],
			[Vector2(-a, b), Vector2(-a, -b), Vector2(-1, 0), SIDE_STEPS.y], [Vector2(-a, -b), Vector2(a, -b), Vector2(0, -1), SIDE_STEPS.x]]
	for k in 4:
		var sd: Array = sides[k]
		var n: Vector2 = sd[2]
		for i in int(sd[3]):
			var p: Vector2 = (sd[0] as Vector2).lerp(sd[1], float(i) / float(sd[3]))
			out.append(Vector4(p.x, p.y, n.x, n.y))
		var c: Vector2 = sd[1]
		var a0 := atan2(n.y, n.x)
		for i in CORNER_STEPS:
			var ang := a0 + PI * 0.5 * float(i) / CORNER_STEPS
			out.append(Vector4(c.x, c.y, cos(ang), sin(ang)))
	return out


static func _at(r: Vector4, t: float) -> Vector2:
	return Vector2(r.x, r.y) + Vector2(r.z, r.w) * (RC + t)


static func _n(r: Vector4) -> Vector2:
	return Vector2(r.z, r.w)


## Whether the section between two samples faces the iso camera (cut to its lower tier).
static func near(a: Vector4, b: Vector4) -> bool:
	return (_n(a) + _n(b)).normalized().dot(CAM) > NEAR_CUT


## Where the iso camera's line of sight through a point meets the ground: the floor point it hides.
static func footprint(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) - CAM * (p.y / ISO_TAN)


## The lower tier's profile (t, y) from the floor up to its last riser's top.
static func _low_profile() -> PackedVector2Array:
	var pr := PackedVector2Array([Vector2(0, 0), Vector2(0, FRONT_Y)])
	var w := LOW_T / LOW_ROWS
	var h := (LOW_Y - FRONT_Y) / LOW_ROWS
	for k in LOW_ROWS:
		var y := FRONT_Y + h * k
		pr.append(Vector2(w * (k + 1), y))
		pr.append(Vector2(w * (k + 1), y + h))
	return pr


## The far sections' profile above the lower tier: the walkway, the hospitality band, the upper tier,
## its back wall.
static func _up_profile() -> PackedVector2Array:
	var pr := PackedVector2Array([Vector2(LOW_T, LOW_Y), Vector2(WALK_T, LOW_Y), Vector2(WALK_T, UP_Y0)])
	var w := (UP_T - WALK_T) / UP_ROWS
	var h := (UP_Y - UP_Y0) / UP_ROWS
	for k in UP_ROWS:
		var y := UP_Y0 + h * k
		pr.append(Vector2(WALK_T + w * (k + 1), y))
		pr.append(Vector2(WALK_T + w * (k + 1), y + h))
	pr.append(Vector2(UP_T, BACK_Y))
	pr.append(Vector2(UP_T + 3.0, BACK_Y))
	return pr


# --- faces ----------------------------------------------------------------------------------------

## The colour lit by the baked SUN (the venue is unshaded).
static func shade(c: Color, n: Vector3) -> Color:
	var k := 0.62 + 0.38 * maxf(0.0, n.dot(SUN.normalized()))
	return Color(c.r * k, c.g * k, c.b * k, c.a)


## One quad of the venue mesh, wound to face `n`; `uv` the four corners' UV (the boards' metres along, 0-1 up).
static func _face(st: SurfaceTool, q: Array, n: Vector3, c: Color, part := PLAIN, forced := -1.0, uv: Array = []) -> void:
	var pts := q.duplicate()
	var uvs: Array = uv.duplicate() if uv.size() == 4 else [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	if ((pts[1] as Vector3) - (pts[0] as Vector3)).cross((pts[2] as Vector3) - (pts[0] as Vector3)).dot(n) > 0.0:
		pts = [pts[0], pts[3], pts[2], pts[1]]
		uvs = [uvs[0], uvs[3], uvs[2], uvs[1]]
	var col := shade(c, n) if part != LED and part != PRINT else c
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(uvs[k])
		st.set_uv2(Vector2(part, forced))
		st.add_vertex(pts[k])


## A triangle of the venue mesh, wound to face `n`.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color) -> void:
	var pts := [a, b, c]
	if (b - a).cross(c - a).dot(n) > 0.0:
		pts = [a, c, b]
	var cc := shade(col, n)
	for p: Vector3 in pts:
		st.set_color(cc)
		st.set_normal(n)
		st.set_uv(Vector2.ZERO)
		st.set_uv2(Vector2(PLAIN, -1.0))
		st.add_vertex(p)


## A box of the venue mesh (no bottom), turned by `yaw` about its centre.
static func _vbox(st: SurfaceTool, c: Vector3, size: Vector3, yaw_r: float, col: Color, part := PLAIN) -> void:
	var b := Basis(Vector3.UP, yaw_r)
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			if axis == 1 and sgn < 0.0:
				continue
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var m := n * h[axis]
			_face(st, [c + b * (m - u - v), c + b * (m + u - v), c + b * (m + u + v), c + b * (m - u + v)], b * n, col, part)


## A lit quad for the floor's mesh (the actors' material: drift_stadium.gd's HERO part, glow by UV.y).
static func lit_quad(st: SurfaceTool, q: Array, n: Vector3, c: Color, glow: float) -> void:
	var pts := q.duplicate()
	if ((pts[1] as Vector3) - (pts[0] as Vector3)).cross((pts[2] as Vector3) - (pts[0] as Vector3)).dot(n) > 0.0:
		pts = [pts[0], pts[3], pts[2], pts[1]]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(c)
		st.set_normal(n)
		st.set_uv(Vector2(Models.HERO, glow))
		st.add_vertex(pts[k])


## A lit box for the floor's mesh (no bottom), turned by `yaw`.
static func lit_box(st: SurfaceTool, c: Vector3, size: Vector3, yaw_r: float, col: Color, glow: float) -> void:
	var b := Basis(Vector3.UP, yaw_r)
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			if axis == 1 and sgn < 0.0:
				continue
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var m := n * h[axis]
			lit_quad(st, [c + b * (m - u - v), c + b * (m + u - v), c + b * (m + u + v), c + b * (m - u + v)], b * n, col, glow)


## A lit upright prism of `sides` sides (no bottom): the tyre stacks, the can.
static func lit_prism(st: SurfaceTool, c: Vector3, r: float, h: float, sides: int, col: Color, top: Color, glow: float) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := c + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := c + Vector3(cos(a1) * r, 0, sin(a1) * r)
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		lit_quad(st, [p0, p1, p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0)], n, col, glow)
		var ct := c + Vector3(0, h, 0)
		lit_quad(st, [ct, p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), ct.lerp(p1 + Vector3(0, h, 0), 0.001)], Vector3.UP, top, glow)


# --- the track's own shapes -------------------------------------------------------------------------

## The line's loops: [centre (Vector2), radius], one each (the west loop's two arcs are one).
static func loops(ln: RefCounted) -> Array:
	var out: Array = []
	for d: Dictionary in ln.segments:
		if d["kind"] != "arc":
			continue
		var c: Vector2 = d["centre"]
		var seen := false
		for l: Array in out:
			if (l[0] as Vector2).distance_to(c) < 1.0:
				seen = true
		if not seen:
			out.append([c, float(d["r"])])
	return out


## The track wall's path: round both loops at their radius + WALL_OFF, joined by the outer tangents
## (a closed polygon, points about 1.5 m apart). Empty unless the line has two loops.
static func wall_path(ln: RefCounted) -> PackedVector2Array:
	var out := PackedVector2Array()
	var lp := loops(ln)
	if lp.size() != 2:
		return out
	var c1: Vector2 = lp[0][0]
	var r1: float = float(lp[0][1]) + WALL_OFF
	var c2: Vector2 = lp[1][0]
	var r2: float = float(lp[1][1]) + WALL_OFF
	var d := c1.distance_to(c2)
	var a0 := (c2 - c1).angle()
	var th := acos(clampf((r1 - r2) / d, -1.0, 1.0))
	# The far side of loop 2, the tangent back to loop 1, round loop 1's far side, the tangent to loop 2.
	_arc(out, c2, r2, a0 - th, a0 + th)
	_arc(out, c1, r1, a0 + th, a0 + TAU - th)
	return out


static func _arc(out: PackedVector2Array, c: Vector2, r: float, a0: float, a1: float) -> void:
	var n := maxi(2, ceili(r * (a1 - a0) / 1.5))
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(c + Vector2(cos(a), sin(a)) * r)


## The flame posts' tops (stadium coordinates): FLAMES_PER_ISLAND round each island's rim.
static func flame_spots(ln: RefCounted) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for isl: Array in ln.islands:
		out.append_array(flame_spots_for(isl))
	return out


## The stage's yaw: its screen faces the iso camera.
static func _stage_yaw() -> float:
	return atan2(CAM.x, CAM.y)


# --- the lit dressing (into the floor's mesh) ------------------------------------------------------

static func dress(st: SurfaceTool, ln: RefCounted, glow: float) -> void:
	# The apron from the floor's edge to the stands.
	var rg := ring()
	for i in rg.size():
		var a := _at(rg[i], 0.0)
		var b := _at(rg[(i + 1) % rg.size()], 0.0)
		var ai := Vector2(clampf(a.x, -HALF.x, HALF.x), clampf(a.y, -HALF.y, HALF.y))
		var bi := Vector2(clampf(b.x, -HALF.x, HALF.x), clampf(b.y, -HALF.y, HALF.y))
		lit_quad(st, [Vector3(ai.x, 0, ai.y), Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(bi.x, 0, bi.y)], Vector3.UP, APRON, glow)
	# The track wall along the loops' offsets, and its tyre stacks on each loop's far side.
	var wp := wall_path(ln)
	var lp := loops(ln)
	for i in wp.size() - 1:
		var a := wp[i]
		var b := wp[i + 1]
		if a.distance_to(b) < 0.05:
			continue
		var mid := (a + b) * 0.5
		var out_n := _out_normal(wp, i)
		var c := mid + out_n * 0.3
		lit_box(st, Vector3(c.x, WALL_H * 0.5, c.y), Vector3(0.6, WALL_H, a.distance_to(b) + 0.02), atan2(-(b - a).x, -(b - a).y), WALL, glow)
	if lp.size() == 2:
		var c1: Vector2 = lp[0][0]
		var c2: Vector2 = lp[1][0]
		var k := 0
		for pair in [[c1, float(lp[0][1]), (c1 - c2).angle()], [c2, float(lp[1][1]), (c2 - c1).angle()]]:
			var r: float = float(pair[1]) + WALL_OFF - 0.45
			var n := int(r * TYRE_ARC * 2.0 / 0.72)
			for j in n + 1:
				var a: float = float(pair[2]) - TYRE_ARC + 2.0 * TYRE_ARC * float(j) / n
				var p: Vector2 = (pair[0] as Vector2) + Vector2(cos(a), sin(a)) * r
				k += 1
				lit_prism(st, Vector3(p.x, 0, p.y), 0.36, 0.85, 8, TYRE_PAINT if k % 3 == 0 else TYRE, TYRE.lightened(0.15), glow)
	# The islands' kerbs, their stages and flame posts; the can on the first.
	var first := true
	for isl: Array in ln.islands:
		var ic := Vector2(float(isl[0]), float(isl[1]))
		var rx := float(isl[2])
		var rz := float(isl[3])
		var n := maxi(24, int(TAU * rx / 1.6))
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var e0 := Vector2(cos(a0), sin(a0))
			var e1 := Vector2(cos(a1), sin(a1))
			var q := [Vector2(e0.x * rx, e0.y * rz), Vector2(e0.x * (rx + KERB_W), e0.y * (rz + KERB_W)),
					Vector2(e1.x * (rx + KERB_W), e1.y * (rz + KERB_W)), Vector2(e1.x * rx, e1.y * rz)]
			var q3: Array = []
			for p: Vector2 in q:
				q3.append(Vector3(ic.x + p.x, 0.02, ic.y + p.y))
			lit_quad(st, q3, Vector3.UP, KERB_RED if i % 2 == 0 else KERB_WHITE, glow)
		var yaw := _stage_yaw()
		var bs := Basis(Vector3.UP, yaw)
		var sc := Vector3(ic.x, 0, ic.y) + bs * Vector3(0, 0, -1.0)
		lit_box(st, sc + Vector3(0, 0.5, 0), Vector3(9.0, 1.0, 6.0), yaw, STAGE, glow * 0.5)
		for side in [-1.0, 1.0]:
			lit_box(st, sc + bs * Vector3(4.3 * side, 3.5, -2.6), Vector3(0.3, 7.0, 0.3), yaw, TRUSS, glow)
		lit_box(st, sc + bs * Vector3(0, 7.1, -2.6), Vector3(9.2, 0.4, 0.4), yaw, TRUSS, glow)
		lit_box(st, sc + bs * Vector3(0, 4.0, -2.75), Vector3(7.6, 3.8, 0.2), yaw, BOARD_DARK, 0.0)
		for p: Vector3 in flame_spots_for(isl):
			lit_box(st, Vector3(p.x, 0.3, p.z), Vector3(0.6, 0.6, 0.6), 0.0, STEEL, glow)
		if first:
			first = false
			var cp := Vector3(ic.x, 0, ic.y) + Vector3(-rx * 0.45, 0, rz * 0.35)
			lit_prism(st, cp, 1.6, 5.2, 12, CAN, CAN_TOP, glow)


## One island's flame posts' tops.
static func flame_spots_for(isl: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for k in FLAMES_PER_ISLAND:
		var a := PI * 0.25 + TAU * k / FLAMES_PER_ISLAND
		out.append(Vector3(float(isl[0]) + cos(a) * (float(isl[2]) - 2.5), 0.6, float(isl[1]) + sin(a) * (float(isl[3]) - 2.5)))
	return out


## The outward normal of the wall path's edge i (away from the polygon's middle: it is convex).
static func _out_normal(wp: PackedVector2Array, i: int) -> Vector2:
	var a := wp[i]
	var b := wp[i + 1]
	var n := Vector2(-(b - a).y, (b - a).x).normalized()
	var mid := Vector2.ZERO
	for p in wp:
		mid += p
	mid /= float(wp.size())
	return n if n.dot((a + b) * 0.5 - mid) > 0.0 else -n


# --- the bowl (the venue's material) ----------------------------------------------------------------

static func bowl_mesh(ln: RefCounted) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rg := ring()
	var n_rg := rg.size()
	var low := _low_profile()
	var up := _up_profile()
	# Arc length round the pitch-side ring and the walkway's band (the boards' metres).
	var along := _along(rg, 0.0)
	var along_up := _along(rg, WALK_T)
	for i in n_rg:
		var ra := rg[i]
		var rb := rg[(i + 1) % n_rg]
		var cut := near(ra, rb)
		var nmid := ((_n(ra) + _n(rb)) * 0.5).normalized()
		# The lower tier: the pitch-side wall with its LED ring, then the rows.
		for k in low.size() - 1:
			var p0 := low[k]
			var p1 := low[k + 1]
			var nrm := _profile_normal(p0, p1, nmid)
			var q := [_pt(ra, p0), _pt(rb, p0), _pt(rb, p1), _pt(ra, p1)]
			if k == 0:
				# The pitch-side wall: dark, an LED band from 0.3 m to 1.3 m.
				var lo := 0.3
				var hi := 1.3
				_face(st, [_pt(ra, Vector2(0, 0)), _pt(rb, Vector2(0, 0)), _pt(rb, Vector2(0, lo)), _pt(ra, Vector2(0, lo))], nrm, BOARD_DARK)
				_face(st, [_pt(ra, Vector2(0, lo)), _pt(rb, Vector2(0, lo)), _pt(rb, Vector2(0, hi)), _pt(ra, Vector2(0, hi))], nrm, Color.WHITE, LED, -1.0,
						[Vector2(along[i], 0), Vector2(along[i + 1], 0), Vector2(along[i + 1], 1), Vector2(along[i], 1)])
				_face(st, [_pt(ra, Vector2(0, hi)), _pt(rb, Vector2(0, hi)), _pt(rb, Vector2(0, FRONT_Y)), _pt(ra, Vector2(0, FRONT_Y))], nrm, BOARD_DARK)
				continue
			if p0.y == p1.y:
				var row := k >> 1
				_face(st, q, nrm, SEAT_WHITE if row % 4 == 3 else SEAT_RED, TREAD)
			else:
				_face(st, q, nrm, RISER)
		if cut:
			# The near quadrant ends at the lower tier: its back, the facade's red and white panels.
			var rows := 5
			for r in rows:
				var y0 := LOW_Y * r / rows
				var y1 := LOW_Y * (r + 1) / rows
				var col: Color = FACADE[(i * 7 + r * 3 + (i * r) % 5) % FACADE.size()]
				_face(st, [_pt(ra, Vector2(LOW_T, y0)), _pt(rb, Vector2(LOW_T, y0)), _pt(rb, Vector2(LOW_T, y1)), _pt(ra, Vector2(LOW_T, y1))],
						Vector3(nmid.x, 0, nmid.y), col)
			continue
		# The far sections: the walkway, the hospitality band (its LED band, the glass), the upper tier.
		for k in up.size() - 1:
			var p0 := up[k]
			var p1 := up[k + 1]
			var nrm := _profile_normal(p0, p1, nmid)
			if k == 1:
				# The band under the upper tier: an LED ring, then the boxes' glass with their windows.
				var lo := LOW_Y + 0.15
				var hi := LOW_Y + 1.15
				_face(st, [_pt(ra, Vector2(WALK_T, LOW_Y)), _pt(rb, Vector2(WALK_T, LOW_Y)), _pt(rb, Vector2(WALK_T, lo)), _pt(ra, Vector2(WALK_T, lo))], nrm, BOARD_DARK)
				var ua := along_up[i]
				var ub := along_up[i + 1]
				_face(st, [_pt(ra, Vector2(WALK_T, lo)), _pt(rb, Vector2(WALK_T, lo)), _pt(rb, Vector2(WALK_T, hi)), _pt(ra, Vector2(WALK_T, hi))], nrm, Color.WHITE, LED, -1.0,
						[Vector2(ua, 0), Vector2(ub, 0), Vector2(ub, 1), Vector2(ua, 1)])
				_face(st, [_pt(ra, Vector2(WALK_T, hi)), _pt(rb, Vector2(WALK_T, hi)), _pt(rb, Vector2(WALK_T, UP_Y0 - 1.2)), _pt(ra, Vector2(WALK_T, UP_Y0 - 1.2))], nrm, GLASS)
				_face(st, [_pt(ra, Vector2(WALK_T, UP_Y0 - 1.2)), _pt(rb, Vector2(WALK_T, UP_Y0 - 1.2)), _pt(rb, Vector2(WALK_T, UP_Y0 - 0.4)), _pt(ra, Vector2(WALK_T, UP_Y0 - 0.4))], nrm, WINDOW.darkened(0.55), LAMP)
				_face(st, [_pt(ra, Vector2(WALK_T, UP_Y0 - 0.4)), _pt(rb, Vector2(WALK_T, UP_Y0 - 0.4)), _pt(rb, Vector2(WALK_T, UP_Y0)), _pt(ra, Vector2(WALK_T, UP_Y0))], nrm, GLASS)
				continue
			var q := [_pt(ra, p0), _pt(rb, p0), _pt(rb, p1), _pt(ra, p1)]
			if p0.y == p1.y:
				var tread := k >= 2 and k < up.size() - 3
				var row := (k - 2) >> 1
				_face(st, q, nrm, (SEAT_WHITE if row % 4 == 1 else SEAT_RED) if tread else CONCRETE, TREAD if tread else PLAIN)
			else:
				_face(st, q, nrm, RISER if k < up.size() - 3 else CONCRETE)
		# The roof ring: the steel edge with its lamps, then the membrane, ribbed.
		var roof := [[ROOF_IN, ROOF_IN + 1.2, STEEL, PLAIN], [ROOF_IN + 1.2, ROOF_IN + 1.7, LAMPS, LAMP],
				[ROOF_IN + 1.7, ROOF_OUT, MEMBRANE if i % 2 == 0 else MEMBRANE_RIB, PLAIN]]
		for band: Array in roof:
			var t0: float = band[0]
			var t1: float = band[1]
			var y0 := lerpf(ROOF_Y0, ROOF_Y1, (t0 - ROOF_IN) / (ROOF_OUT - ROOF_IN))
			var y1 := lerpf(ROOF_Y0, ROOF_Y1, (t1 - ROOF_IN) / (ROOF_OUT - ROOF_IN))
			_face(st, [_pt(ra, Vector2(t0, y0)), _pt(rb, Vector2(t0, y0)), _pt(rb, Vector2(t1, y1)), _pt(ra, Vector2(t1, y1))], Vector3.UP, band[2], band[3])
		# The roof's inner fringe, seen from the floor side.
		_face(st, [_pt(ra, Vector2(ROOF_IN, ROOF_Y0 - 1.5)), _pt(rb, Vector2(ROOF_IN, ROOF_Y0 - 1.5)), _pt(rb, Vector2(ROOF_IN, ROOF_Y0)), _pt(ra, Vector2(ROOF_IN, ROOF_Y0))],
				Vector3(-nmid.x, 0, -nmid.y), STEEL)
	# Caps where a far section meets a cut one: the stand's section in concrete.
	for i in n_rg:
		var prev := near(rg[(i - 1 + n_rg) % n_rg], rg[i])
		var nxt := near(rg[i], rg[(i + 1) % n_rg])
		if prev == nxt:
			continue
		var r := rg[i]
		var tng := Vector2(-r.w, r.z)
		var face := Vector3(tng.x, 0, tng.y) * (-1.0 if prev else 1.0)
		var poly := PackedVector2Array([Vector2(LOW_T, 0.0)])
		poly.append_array(up)
		poly.append(Vector2(up[up.size() - 1].x, 0.0))
		var tris := Geometry2D.triangulate_polygon(poly)
		for j in range(0, tris.size(), 3):
			_tri(st, _pt(r, poly[tris[j]]), _pt(r, poly[tris[j + 1]]), _pt(r, poly[tris[j + 2]]), face, SECTION)
	# The track wall's banners (printed, its track side).
	var wp := wall_path(ln)
	var u := 0.0
	for i in wp.size() - 1:
		var a := wp[i]
		var b := wp[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len < 0.05:
			continue
		var on := -_out_normal(wp, i)
		var o := on * 0.02
		_face(st, [Vector3(a.x + o.x, 0.12, a.y + o.y), Vector3(b.x + o.x, 0.12, b.y + o.y), Vector3(b.x + o.x, WALL_H - 0.1, b.y + o.y), Vector3(a.x + o.x, WALL_H - 0.1, a.y + o.y)],
				Vector3(on.x, 0, on.y), Color.WHITE, PRINT, -1.0, [Vector2(u, 0), Vector2(u + seg_len, 0), Vector2(u + seg_len, 1), Vector2(u, 1)])
		u += seg_len
	# The stages' screens: two LED rows on each, facing the iso camera.
	var yaw := _stage_yaw()
	var bs := Basis(Vector3.UP, yaw)
	var fn := bs * Vector3(0, 0, 1)
	for isl: Array in ln.islands:
		var sc := Vector3(float(isl[0]), 0, float(isl[1])) + bs * Vector3(0, 0, -1.0)
		var face := sc + bs * Vector3(0, 0, -2.6)
		for row: Array in [[5.0, 4.6, 5.3], [0.0, 2.7, 3.4]]:
			var y0: float = row[1]
			var y1: float = row[2]
			var l := face + bs * Vector3(-3.6, 0, 0)
			var r2 := face + bs * Vector3(3.6, 0, 0)
			_face(st, [l + Vector3(0, y0, 0), r2 + Vector3(0, y0, 0), r2 + Vector3(0, y1, 0), l + Vector3(0, y1, 0)], fn, Color.WHITE, LED, row[0],
					[Vector2(0, 0), Vector2(BOARD_LEN, 0), Vector2(BOARD_LEN, 1), Vector2(0, 1)])
		# A picture on the big screen: the floor's own colours, lit.
		var l2 := face + bs * Vector3(-3.6, 0, 0)
		var r3 := face + bs * Vector3(3.6, 0, 0)
		_face(st, [l2 + Vector3(0, 3.55, 0), r3 + Vector3(0, 3.55, 0), r3 + Vector3(0, 4.45, 0), l2 + Vector3(0, 4.45, 0)], fn, Color("#3e6fb0"), LAMP)
	st.index()
	return st.commit()


## The metres round the ring `t` m off the floor's side, at each sample (and the whole round last).
static func _along(rg: Array[Vector4], t: float) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for i in rg.size():
		out.append(out[i] + _at(rg[i], t).distance_to(_at(rg[(i + 1) % rg.size()], t)))
	return out


## A ring sample's point at profile (t, y), in the stadium's coordinates.
static func _pt(r: Vector4, p: Vector2) -> Vector3:
	var g := _at(r, p.x)
	return Vector3(g.x, p.y, g.y)


## The normal of a profile segment (towards the field and up) at a section whose outward normal is `n`.
static func _profile_normal(p0: Vector2, p1: Vector2, n: Vector2) -> Vector3:
	var d := (p1 - p0).normalized()
	return (Vector3(n.x, 0, n.y) * -d.y + Vector3.UP * d.x).normalized()


# --- the spire -------------------------------------------------------------------------------------

static func spire_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 16
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var e0 := Vector3(cos(a0), 0, sin(a0))
		var e1 := Vector3(cos(a1), 0, sin(a1))
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		# The hub's drum: a lamp ring at its foot, steel above, a cone on top.
		_face(st, [e0 * HUB_R + Vector3(0, HUB_Y, 0), e1 * HUB_R + Vector3(0, HUB_Y, 0), e1 * HUB_R + Vector3(0, HUB_Y + 0.7, 0), e0 * HUB_R + Vector3(0, HUB_Y + 0.7, 0)], n, LAMPS, LAMP)
		_face(st, [e0 * HUB_R + Vector3(0, HUB_Y + 0.7, 0), e1 * HUB_R + Vector3(0, HUB_Y + 0.7, 0), e1 * HUB_R + Vector3(0, HUB_Y + 6, 0), e0 * HUB_R + Vector3(0, HUB_Y + 6, 0)], n, STEEL)
		_face(st, [e0 * HUB_R + Vector3(0, HUB_Y + 6, 0), e1 * HUB_R + Vector3(0, HUB_Y + 6, 0), e1 * 1.2 + Vector3(0, HUB_Y + 8, 0), e0 * 1.2 + Vector3(0, HUB_Y + 8, 0)],
				(n + Vector3.UP).normalized(), MEMBRANE_RIB)
		# Its underside (seen from the floor in a wide shot).
		_tri(st, Vector3(0, HUB_Y, 0), e0 * HUB_R + Vector3(0, HUB_Y, 0), e1 * HUB_R + Vector3(0, HUB_Y, 0), Vector3.DOWN, STEEL)
	# The needle: six sides, narrowing, its top a red lamp.
	for i in 6:
		var a0 := TAU * i / 6
		var a1 := TAU * (i + 1) / 6
		var e0 := Vector3(cos(a0), 0, sin(a0))
		var e1 := Vector3(cos(a1), 0, sin(a1))
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		_face(st, [e0 * 0.9 + Vector3(0, HUB_Y + 8, 0), e1 * 0.9 + Vector3(0, HUB_Y + 8, 0), e1 * 0.25 + Vector3(0, NEEDLE_Y, 0), e0 * 0.25 + Vector3(0, NEEDLE_Y, 0)], n, SEAT_WHITE)
		_face(st, [e0 * 0.25 + Vector3(0, NEEDLE_Y, 0), e1 * 0.25 + Vector3(0, NEEDLE_Y, 0), e1 * 0.25 + Vector3(0, NEEDLE_Y + 1.2, 0), e0 * 0.25 + Vector3(0, NEEDLE_Y + 1.2, 0)], n, Color("#ff2a2a"), LAMP)
	# The screen cube under the hub: a dark body, two LED rows a side.
	var cy := HUB_Y - 1.0 - CUBE.y * 0.5
	_vbox(st, Vector3(0, cy, 0), Vector3(CUBE.x, CUBE.y, CUBE.x), 0.0, BOARD_DARK)
	_vbox(st, Vector3(0, HUB_Y - 0.5, 0), Vector3(0.6, 1.0, 0.6), 0.0, STEEL)
	for k in 4:
		var yaw := PI * 0.5 * k
		var b := Basis(Vector3.UP, yaw)
		var fn := b * Vector3(0, 0, 1)
		var c := Vector3(0, cy, 0) + fn * (CUBE.x * 0.5 + 0.03)
		var l := c + b * Vector3(-CUBE.x * 0.45, 0, 0)
		var r := c + b * Vector3(CUBE.x * 0.45, 0, 0)
		for row: Array in [[2.0, 0.6, 1.35], [0.0, -1.35, -0.6]]:
			var y0: float = row[1]
			var y1: float = row[2]
			_face(st, [l + Vector3(0, y0, 0), r + Vector3(0, y0, 0), r + Vector3(0, y1, 0), l + Vector3(0, y1, 0)], fn, Color.WHITE, LED, row[0],
					[Vector2(0, 0), Vector2(BOARD_LEN, 0), Vector2(BOARD_LEN, 1), Vector2(0, 1)])
	# The cables from the hub to the roof's inner edge, on the far side only (the near roof is cut).
	var rg := ring()
	for i in range(0, rg.size(), 4):
		var r := rg[i]
		if _n(r).dot(CAM) > NEAR_CUT - 0.2:
			continue
		var end := _pt(r, Vector2(ROOF_IN, ROOF_Y0))
		var dir := Vector3(end.x, 0, end.z).normalized()
		var start := dir * HUB_R + Vector3(0, HUB_Y + 3.0, 0)
		var side := dir.cross(Vector3.UP).normalized() * 0.18
		_face(st, [start - side, start + side, end + side, end - side], Vector3.UP, STEEL)
	st.index()
	return st.commit()


# --- the crowd -------------------------------------------------------------------------------------

## One figure (16 triangles): a body, a head, a phone held up (the shader folds it away but for a few, at night).
## Faces -Z (the field).
static func figure_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_vbox(st, Vector3(0, 0.3, 0), Vector3(0.46, 0.6, 0.32), 0.0, Color.WHITE)
	# The head: a four-sided point (4 triangles, not a box's 10: the crowd is the venue's biggest cost).
	var apex := Vector3(0, 0.88, 0)
	var hb := [Vector3(-0.12, 0.6, -0.12), Vector3(0.12, 0.6, -0.12), Vector3(0.12, 0.6, 0.12), Vector3(-0.12, 0.6, 0.12)]
	for k in 4:
		var a: Vector3 = hb[k]
		var b: Vector3 = hb[(k + 1) % 4]
		var n := (b - a).cross(apex - a).normalized()
		if n.dot((a + b) * 0.5 - Vector3(0, 0.6, 0)) < 0.0:
			n = -n
		var pts := [a, b, apex]
		if (b - a).cross(apex - a).dot(n) > 0.0:
			pts = [a, apex, b]
		for q: Vector3 in pts:
			st.set_color(Color.WHITE)
			st.set_normal(n)
			st.set_uv(Vector2.ZERO)
			st.set_uv2(Vector2(HEAD, -1.0))
			st.add_vertex(q)
	var p := Vector3(0.12, 0.98, -0.2)
	_face(st, [p + Vector3(-0.06, 0, -0.08), p + Vector3(0.06, 0, -0.08), p + Vector3(0.06, 0, 0.08), p + Vector3(-0.06, 0, 0.08)], Vector3.UP, Color.WHITE, PHONE)
	st.index()
	return st.commit()


## The crowd: `count` figures on the treads, in order of who comes first (the front rows weigh more), so a
## tier's cap is the first N (MultiMesh.visible_instance_count). Seeded: the same seats every build.
static func crowd(count: int) -> MultiMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 87_3
	var rg := ring()
	var seats: Array = []  # [key, Transform3D]
	var low := _low_profile()
	var up := _up_profile()
	for tier in 2:
		var pr := low if tier == 0 else up
		for k in pr.size() - 1:
			var p0 := pr[k]
			var p1 := pr[k + 1]
			if p0.y != p1.y or (tier == 0 and k == 0):
				continue
			if tier == 1 and (k < 2 or k >= pr.size() - 3):
				continue
			var row := k >> 1
			var weight := 1.0 / (1.0 + 0.25 * row) if tier == 0 else 0.35
			var t := (p0.x + p1.x) * 0.5 + 0.1
			for i in rg.size():
				var ra := rg[i]
				var rb := rg[(i + 1) % rg.size()]
				if tier == 1 and near(ra, rb):
					continue
				var a := _at(ra, t)
				var b := _at(rb, t)
				var n := int(a.distance_to(b) / 0.85)
				var nm := ((_n(ra) + _n(rb)) * 0.5).normalized()
				for j in n:
					var p := a.lerp(b, (j + 0.5) / n)
					var bas := Basis.looking_at(Vector3(-nm.x, 0, -nm.y), Vector3.UP).rotated(Vector3.UP, rng.randf_range(-0.25, 0.25))
					var s := rng.randf_range(0.9, 1.1)
					seats.append([rng.randf() / weight, Transform3D(bas.scaled(Vector3(s, s, s)), Vector3(p.x, p0.y, p.y))])
	seats.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = figure_mesh()
	mm.instance_count = mini(count, seats.size())
	for i in mm.instance_count:
		mm.set_instance_transform(i, seats[i][1])
		var c: Color = SHIRTS[rng.randi() % SHIRTS.size()]
		mm.set_instance_custom_data(i, Color(c.r, c.g, c.b, rng.randf()))
	return mm


# --- the flames and the boards' words ----------------------------------------------------------------

## A flame jet: a tall six-sided double cone (1 m high: the pool scales it), yellow at its foot, orange to the tip.
static func flame_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, 1.0, 0)
	var core := Color(1.0, 0.93, 0.45, 0.95)
	var tip := Color(1.0, 0.35, 0.05, 0.75)
	for i in 6:
		var a0 := TAU * i / 6
		var a1 := TAU * (i + 1) / 6
		var e0 := Vector3(cos(a0) * 0.3, 0.25, sin(a0) * 0.3)
		var e1 := Vector3(cos(a1) * 0.3, 0.25, sin(a1) * 0.3)
		for v: Array in [[Vector3.ZERO, core], [e0, core], [e1, core], [e0, Color(1.0, 0.6, 0.12, 0.9)], [top, tip], [e1, Color(1.0, 0.6, 0.12, 0.9)]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
	return st.commit()


## The boards' words as one texture: a row (ROW_PX high) a board of drift_tracks.json `boards`, the text
## centred in its colour on the board's.
static func atlas() -> ImageTexture:
	var boards: Array = DriftLine.data().get("boards", [])
	var n := maxi(1, boards.size())
	var img := Image.create(ATLAS_PX, ROW_PX * n, false, Image.FORMAT_RGBA8)
	img.fill(BOARD_DARK)
	for i in boards.size():
		var bd: Dictionary = boards[i]
		var text := str((bd.get("text", [""]) as Array)[0])
		img.fill_rect(Rect2i(0, i * ROW_PX, ATLAS_PX, ROW_PX), Color(str(bd.get("bg", "#16181d"))))
		var w := PixelFont.width(text)
		PixelFont.draw(img, text, maxi(0, (ATLAS_PX - w) / 2), i * ROW_PX + 1, Color(str(bd.get("fg", "#ffffff"))))
	return ImageTexture.create_from_image(img)


## The venue's material (`crowd` true: the crowd's, with the bob and the wave).
static func material(tex: Texture2D, is_crowd: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	m.set_shader_parameter("atlas", tex)
	m.set_shader_parameter("rows", float(maxi(1, (DriftLine.data().get("boards", []) as Array).size())))
	m.set_shader_parameter("atlas_px", float(ATLAS_PX))
	m.set_shader_parameter("row_px", float(ROW_PX))
	m.set_shader_parameter("board_len", BOARD_LEN)
	m.set_shader_parameter("crowd", 1.0 if is_crowd else 0.0)
	return m
