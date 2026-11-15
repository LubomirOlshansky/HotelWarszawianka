extends "res://scripts/place.gd"
## Trasa W-Z's cutting under Plac Zamkowy, seen from the square looking east (F's five photos from
## the balustrade over the tunnel, 2026-11-15): the dressing the map data does not draw. The two
## slip roads' granite setts are ground.gdshader's (WZ_LINE); this script builds what stands on them.
##  - The W-Z approach's retaining walls (the bake's walls along Grodzka and above Nowy Zjazd): their
##    pilasters every 2.6 m and a cornice under the coping, and the white tube railing along the top,
##    which goes on along the Stare Miasto platform's edge over Grodzka and the south pavement's edge
##    over Nowy Zjazd.
##  - The escarpment under St Anne's: its foot walls faced in big dark sandstone blocks, and the
##    zigzag stairs up to the terrace given their stone balustrade on the road side.
##  - The Stare Miasto tram stop: two shelters with white louvred roofs on the platform between the
##    tracks and Grodzka, one more on the south pavement, the passenger information boards
##    ("STARE MIASTO 01/02" in amber), a ticket machine and the stop post.
##  - The kiosk on the Castle side's pavement ("PAMIĄTKI · NAPOJE · BILETY", souvenirs, drinks,
##    tickets), the black bollards along that kerb and the hire scooters (plain colours, no brand).
##  - The signs at the crossings: D-6 at both slip roads' zebras, Nowy Zjazd's street plate with B-5
##    (no lorries over 2,5 t), A-30 with the yellow "BUS + walkers" board, B-36 and D-3 by the wall,
##    B-2 at the platform's west nose, and the yellow posts on the islands' noses.
## Every position is a constant from the map (centrum.json walls, steps, platform 157, roads 246,
## 3708, 4393, 8071): walls and steps are sector-only data, so the phone's city (only the index)
## builds the same thing. One mesh poured into the sector's places mesh (no draw call of its own);
## nothing here is solid, as the stop furniture the map draws.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const WHITE := Color("#ecebe6")
const RAIL_WHITE := Color("#e9e8e2")
const POST := Color("#7b8087")
const PILASTER := Color("#8e887d")
const CORNICE := Color("#b3ada2")
const SANDSTONE := [Color("#8a8170"), Color("#7b7363"), Color("#958b79"), Color("#6f695c"), Color("#857c6b")]
const SAND_JOINT := Color("#4f4a42")
const BALUSTRADE := Color("#b9b0a0")
const BALUSTER := Color("#c8c0b0")
const RED := Color("#c8282a")
const BLUE := Color("#1f5aa6")
const YELLOW := Color("#f2c21b")
const INK := Color("#1b1b1d")
const AMBER := Color("#f3a72a")

## The W-Z approach's walls whose faces look onto a slip road (x, top, z per point; the foot per
## point): along Grodzka (the tall one, 2.7 to 6.5 m) and over Nowy Zjazd by the viaduct.
const WALLS_PILASTERED := [
	[[Vector3(-508.3, -6.74, -1446.6), Vector3(-510.7, -6.74, -1445.5), Vector3(-513.0, -6.73, -1444.4),
		Vector3(-515.7, -6.72, -1443.3), Vector3(-518.5, -6.72, -1442.1), Vector3(-521.2, -6.71, -1440.9),
		Vector3(-524.0, -6.70, -1439.8), Vector3(-526.4, -6.70, -1438.8), Vector3(-529.0, -6.69, -1437.8),
		Vector3(-531.5, -6.69, -1436.9), Vector3(-534.0, -6.68, -1435.9), Vector3(-536.3, -6.67, -1435.2),
		Vector3(-538.6, -6.67, -1434.5), Vector3(-541.0, -6.67, -1433.8), Vector3(-543.4, -6.66, -1433.1),
		Vector3(-545.8, -6.67, -1432.4), Vector3(-548.1, -6.68, -1431.7), Vector3(-550.5, -6.68, -1431.0),
		Vector3(-552.9, -6.68, -1430.3), Vector3(-555.5, -6.66, -1429.8), Vector3(-558.1, -6.64, -1429.2),
		Vector3(-560.8, -6.62, -1428.6), Vector3(-563.5, -6.60, -1428.0), Vector3(-566.2, -6.58, -1427.5),
		Vector3(-568.9, -6.55, -1426.9), Vector3(-570.8, -6.54, -1426.5), Vector3(-572.8, -6.52, -1426.2),
		Vector3(-574.8, -6.50, -1425.9), Vector3(-576.8, -6.48, -1425.5), Vector3(-578.9, -6.46, -1425.2),
		Vector3(-580.9, -6.45, -1424.9)],
	[-12.30, -11.91, -10.91, -13.19, -13.08, -12.94, -12.82, -12.68, -12.54, -12.39, -12.23, -12.10, -11.95,
		-11.79, -11.63, -11.47, -11.32, -11.16, -10.99, -10.81, -10.62, -10.45, -10.26, -10.08, -9.89, -9.76,
		-9.65, -9.51, -9.38, -9.26, -9.13]],
	[[Vector3(-511.4, -6.71, -1422.0), Vector3(-508.7, -6.72, -1423.2), Vector3(-506.2, -6.72, -1424.2),
		Vector3(-503.8, -6.73, -1425.3), Vector3(-501.4, -6.74, -1426.5), Vector3(-498.9, -6.74, -1427.5)],
	[-7.62, -8.15, -8.25, -9.11, -10.16, -11.54]],
]
## Low W-Z edge walls that only carry the railing: over Nowy Zjazd (two) and over Grodzka by the
## platform.
const WALLS_RAILED := [
	[Vector3(-539.0, -6.67, -1411.9), Vector3(-536.6, -6.66, -1412.6), Vector3(-534.3, -6.67, -1413.3),
		Vector3(-531.9, -6.67, -1414.0), Vector3(-529.8, -6.67, -1414.8), Vector3(-527.7, -6.68, -1415.6),
		Vector3(-525.6, -6.68, -1416.4), Vector3(-523.6, -6.69, -1417.1), Vector3(-521.5, -6.62, -1417.9),
		Vector3(-519.4, -6.56, -1418.7)],
	[Vector3(-580.6, -6.44, -1402.8), Vector3(-578.2, -6.46, -1403.1), Vector3(-575.9, -6.47, -1403.4),
		Vector3(-573.5, -6.48, -1403.7), Vector3(-571.0, -6.50, -1404.0), Vector3(-568.8, -6.52, -1404.5),
		Vector3(-566.6, -6.54, -1404.9), Vector3(-564.4, -6.55, -1405.4), Vector3(-562.2, -6.57, -1405.8),
		Vector3(-560.0, -6.58, -1406.3), Vector3(-557.8, -6.60, -1406.8), Vector3(-555.8, -6.58, -1407.2),
		Vector3(-553.9, -6.56, -1407.8), Vector3(-551.9, -6.51, -1408.2), Vector3(-549.9, -6.46, -1408.8)],
	[Vector3(-581.3, -6.44, -1422.3), Vector3(-584.2, -6.44, -1422.0), Vector3(-587.2, -6.44, -1421.6),
		Vector3(-590.1, -6.44, -1421.3), Vector3(-593.1, -6.44, -1420.9), Vector3(-595.0, -6.44, -1420.8)],
]
## Railings on the ground (their height is the ground's at each post): the Stare Miasto platform's
## edge over Grodzka (0.25 m platform), and the south pavement's edge over Nowy Zjazd from the
## crossing to the wall above (photo: the white tube rail curving down beside the setts).
const RAILS_GROUND := [
	[0.25, [Vector2(-595.0, -1423.6), Vector2(-616.2, -1422.35), Vector2(-629.1, -1421.75), Vector2(-633.3, -1421.35),
		Vector2(-636.9, -1420.75)]],
	[0.0, [Vector2(-637.5, -1399.4), Vector2(-633.0, -1400.4), Vector2(-624.0, -1401.6), Vector2(-610.1, -1402.4),
		Vector2(-591.5, -1403.5), Vector2(-580.6, -1402.8)]],
]
## The escarpment's foot walls under St Anne's (their faces look north onto Nowy Zjazd): top,
## foot and the parapet lift per piece (the bake's flag 2).
const WALLS_SANDSTONE := [
	[[Vector3(-613.9, -6.59, -1384.4), Vector3(-616.1, -6.05, -1384.6), Vector3(-618.4, -6.04, -1384.8),
		Vector3(-621.1, -6.03, -1385.2), Vector3(-623.0, -5.78, -1385.6), Vector3(-625.0, -5.50, -1386.1),
		Vector3(-627.0, -5.44, -1386.6), Vector3(-628.9, -5.61, -1387.0), Vector3(-630.8, -5.77, -1387.5),
		Vector3(-632.9, -5.95, -1388.0), Vector3(-635.3, -6.10, -1388.7), Vector3(-638.1, -6.12, -1389.4),
		Vector3(-640.5, -6.13, -1390.3), Vector3(-642.9, -5.87, -1391.3), Vector3(-644.6, -5.69, -1391.9),
		Vector3(-646.2, -5.55, -1392.6), Vector3(-647.9, -5.62, -1393.3), Vector3(-649.1, -5.67, -1393.8),
		Vector3(-651.0, -5.39, -1394.3), Vector3(-653.0, -4.81, -1394.8), Vector3(-655.0, -4.23, -1395.4),
		Vector3(-656.5, -3.99, -1395.8), Vector3(-658.8, -4.18, -1396.2), Vector3(-661.1, -4.37, -1396.6),
		Vector3(-663.4, -4.48, -1397.0), Vector3(-665.9, -4.18, -1397.5), Vector3(-668.8, -4.67, -1398.2)],
	[-7.35, -7.26, -7.19, -7.13, -7.07, -7.02, -6.96, -6.90, -6.84, -6.78, -6.71, -6.64, -6.56, -6.48, -6.42,
		-6.35, -6.31, -6.27, -6.28, -6.28, -6.28, -6.28, -6.27, -6.25, -6.22, -6.20, -6.17],
	[1, 3, 3, 3, 3, 3, 3, 3, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 3, 3, 3, 3, 3, 3, 3]],
	[[Vector3(-667.3, -4.95, -1398.5), Vector3(-669.8, -4.76, -1398.3), Vector3(-672.2, -4.63, -1398.1),
		Vector3(-674.0, -4.60, -1398.0), Vector3(-675.8, -4.45, -1397.9), Vector3(-677.5, -3.23, -1397.8),
		Vector3(-679.3, -1.94, -1397.6)],
	[-6.15, -6.12, -6.09, -6.09, -6.09, -6.09, -6.09],
	[3, 3, 3, 3, 3, 3]],
]
## The stairs up the escarpment (the bake's steps, map_builder.gd `_stair_flight`'s default 2.4 m
## width): the lower flights climb west along Nowy Zjazd, the upper one comes back east to the
## terrace. The balustrade stands on each flight's cheek on the north (road) side.
const STAIRS := [
	[Vector2(-650.7, -1392.5), Vector2(-647.5, -1392.1)],
	[Vector2(-656.8, -1393.2), Vector2(-655.9, -1393.1), Vector2(-652.8, -1392.7)],
	[Vector2(-662.2, -1393.4), Vector2(-658.2, -1393.3)],
	[Vector2(-671.7, -1392.9), Vector2(-667.8, -1393.3), Vector2(-667.3, -1393.3)],
	[Vector2(-677.1, -1392.4), Vector2(-673.2, -1392.8)],
	[Vector2(-676.7, -1386.1), Vector2(-665.7, -1386.8), Vector2(-662.9, -1386.7), Vector2(-660.2, -1386.3),
		Vector2(-657.8, -1385.7), Vector2(-652.2, -1383.4)],
]
const STAIR_HALF := 1.2
const STAIR_CHEEK := 0.28
const STAIR_CHEEK_UP := 0.16
## The tram stop: shelters [x, z, the way their open front looks], the information boards.
const SHELTERS := [
	[Vector2(-603.0, -1422.2), Vector2(0.06, 1.0)],
	[Vector2(-616.0, -1421.4), Vector2(0.05, 1.0)],
	[Vector2(-592.5, -1405.1), Vector2(-0.12, -1.0)],
]
const PLATFORM_H := 0.25

var _st: SurfaceTool


func build() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for w: Array in WALLS_PILASTERED:
		_pilasters(w[0], w[1])
		_wall_rail(w[0])
	for w: Array in WALLS_RAILED:
		_wall_rail(w)
	for r: Array in RAILS_GROUND:
		_ground_rail(r[1], float(r[0]))
	for w: Array in WALLS_SANDSTONE:
		_sandstone(w[0], w[1], w[2])
	for s: Array in STAIRS:
		_balustrade(s)
	_stop()
	_castle_pavement()
	_signs()
	pour(_st.commit(), true, "TrasaWZProps")


# --- the walls ------------------------------------------------------------------------------

## The way a wall's face looks (the bake's `out`: left of the line's direction).
static func _out(a: Vector3, b: Vector3) -> Vector3:
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	return Vector3(-d.z, 0.0, d.x)


## Pilasters every 2.6 m along a tall wall's face and a cornice band under its coping.
func _pilasters(tops: Array, lows: Array) -> void:
	var run := 0.0
	var next := 1.0
	for i in tops.size() - 1:
		var a: Vector3 = tops[i]
		var b: Vector3 = tops[i + 1]
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		if length < 0.05:
			continue
		var out := _out(a, b)
		var dir := Vector3(b.x - a.x, 0.0, b.z - a.z) / length
		var basis := Basis(dir, Vector3.UP, out)
		var la: float = lows[i]
		var lb: float = lows[i + 1]
		# The cornice: a band 0.3 m deep, 0.1 m proud, under the top.
		var mid := (a + b) * 0.5
		Props.obox(_st, Vector3(mid.x, mid.y - 0.2, mid.z) + out * 0.05, basis, Vector3(length + 0.04, 0.3, 0.1), CORNICE)
		while next <= run + length:
			var f := (next - run) / length
			var p := a.lerp(b, f)
			var top := p.y - 0.35
			var foot := lerpf(la, lb, f) - 0.3
			if top - foot > 1.6:
				Props.obox(_st, Vector3(p.x, (top + foot) * 0.5, p.z) + out * 0.13, basis,
						Vector3(0.5, top - foot, 0.26), PILASTER)
				count += 1
			next += 2.6
		run += length


## The white tube railing on a wall's coping: posts every 2 m, a top rail at 1.05 m and one at 0.55 m.
func _wall_rail(tops: Array) -> void:
	var line := PackedVector3Array()
	for i in tops.size():
		var a: Vector3 = tops[i]
		var o := _out(tops[maxi(i - 1, 0)], tops[mini(i + 1, tops.size() - 1)])
		line.append(a - o * 0.15)
	_rail(line)


## A railing along the ground (`lift` over it: a platform), its line in plan.
func _ground_rail(pts: Array, lift: float) -> void:
	var line := PackedVector3Array()
	var prev := Vector2.INF
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var n := maxi(1, ceili(a.distance_to(b) / 2.0))
		for j in n + (1 if k == pts.size() - 2 else 0):
			var p := a.lerp(b, float(j) / n)
			if p.distance_to(prev) < 0.05:
				continue
			line.append(Vector3(p.x, _gh(p.x, p.y) + lift, p.y))
			prev = p
	_rail(line)


## Posts about every 2 m and two rails along a 3D line (its points at the rail's foot).
func _rail(line: PackedVector3Array) -> void:
	var run := 0.0
	var next := 0.0
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		for h in [1.05, 0.55]:
			Props.beam(_st, a + Vector3.UP * h, b + Vector3.UP * h, 0.06, 0.06, RAIL_WHITE)
		while next <= run + length + 0.001:
			var p := a.lerp(b, clampf((next - run) / length, 0.0, 1.0))
			Props.box(_st, p + Vector3.UP * 0.53, Vector3(0.06, 1.06, 0.06), RAIL_WHITE)
			next += 2.0
		run += length
	count += 1


## A wall's face clad in sandstone: a dark joint backing and big blocks laid in courses 0.55 m
## high, 0.9-1.7 m long, each a shade of weathered grey-brown sandstone.
func _sandstone(tops: Array, lows: Array, flags: Array) -> void:
	var course := 0.55
	var run := 0.0
	for i in tops.size() - 1:
		var a: Vector3 = tops[i]
		var b: Vector3 = tops[i + 1]
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		if length < 0.05:
			continue
		var out := _out(a, b)
		var dir := Vector3(b.x - a.x, 0.0, b.z - a.z) / length
		var lift := 0.9 if int(flags[i]) & 2 else 0.0
		var ta := a.y + lift
		var tb := b.y + lift
		var la: float = float(lows[i]) - 0.3
		var lb: float = float(lows[i + 1]) - 0.3
		var a0 := Vector3(a.x, 0.0, a.z) + out * 0.03
		var b0 := Vector3(b.x, 0.0, b.z) + out * 0.03
		Props.tri(_st, Vector3(a0.x, la, a0.z), Vector3(b0.x, lb, b0.z), Vector3(b0.x, tb, b0.z), out, SAND_JOINT)
		Props.tri(_st, Vector3(a0.x, la, a0.z), Vector3(b0.x, tb, b0.z), Vector3(a0.x, ta, a0.z), out, SAND_JOINT)
		# Courses from the lower foot up to the lower top, each block cut at this piece's ends.
		var lo := minf(la, lb)
		var hi := minf(ta, tb)
		var row := 0
		var y := lo
		while y < hi - 0.12:
			var y1 := minf(y + course, hi)
			var s := -fposmod(run + row * 0.7, 1.3)
			while s < length:
				var blen := 0.9 + 0.8 * _hash(Vector2(run + s, y))
				var s0 := maxf(s, 0.0) + 0.03
				var s1 := minf(s + blen, length) - 0.03
				if s1 - s0 > 0.2:
					var c: Color = SANDSTONE[int(_hash(Vector2(s + run, y * 3.1)) * SANDSTONE.size()) % SANDSTONE.size()]
					var p0 := a0 + dir * s0 + out * 0.03
					var p1 := a0 + dir * s1 + out * 0.03
					Props.tri(_st, Vector3(p0.x, y + 0.03, p0.z), Vector3(p1.x, y + 0.03, p1.z), Vector3(p1.x, y1 - 0.03, p1.z), out, c)
					Props.tri(_st, Vector3(p0.x, y + 0.03, p0.z), Vector3(p1.x, y1 - 0.03, p1.z), Vector3(p0.x, y1 - 0.03, p0.z), out, c)
				s += blen
			y = y1
			row += 1
		run += length
	count += 1


## 0..1 from a point, stable between runs.
static func _hash(p: Vector2) -> float:
	return fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)


## A stone balustrade on a flight's north cheek: a plinth on the cheek, balusters every 0.3 m and
## a broad handrail, climbing with the ground under the flight (its highest across, as the stairs').
func _balustrade(pts: Array) -> void:
	var line := PackedVector3Array()
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var d := (b - a).normalized()
		var side := Vector2(-d.y, d.x)
		# The road side: the cheek on the side with lower ground (the flights' north).
		if side.y > 0.0:
			side = -side
		var n := maxi(1, ceili(a.distance_to(b) / 0.5))
		for j in n + (1 if k == pts.size() - 2 else 0):
			var p := a.lerp(b, float(j) / n)
			var g := maxf(_th(p.x, p.y), maxf(_th(p.x + side.x * STAIR_HALF, p.y + side.y * STAIR_HALF),
					_th(p.x - side.x * STAIR_HALF, p.y - side.y * STAIR_HALF)))
			var q := p + side * (STAIR_HALF + STAIR_CHEEK * 0.5)
			line.append(Vector3(q.x, g + STAIR_CHEEK_UP, q.y))
	if line.size() < 2:
		return
	# Monotone from the lower end (the flight's own climb), as the stair builder does.
	var up := line[0].y <= line[line.size() - 1].y
	var best := -INF
	for j in line.size():
		var k := j if up else line.size() - 1 - j
		best = maxf(best, line[k].y)
		line[k].y = best
	var run := 0.0
	var next := 0.15
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var length := a.distance_to(b)
		if length < 0.02:
			continue
		Props.beam(_st, a + Vector3.UP * 0.1, b + Vector3.UP * 0.1, STAIR_CHEEK, 0.2, BALUSTRADE)
		Props.beam(_st, a + Vector3.UP * 0.92, b + Vector3.UP * 0.92, 0.3, 0.14, BALUSTRADE)
		while next <= run + length:
			var p := a.lerp(b, (next - run) / length)
			Props.box(_st, p + Vector3.UP * 0.52, Vector3(0.13, 0.66, 0.13), BALUSTER)
			Props.box(_st, p + Vector3.UP * 0.52, Vector3(0.18, 0.16, 0.18), BALUSTER)
			next += 0.32
		run += length
	count += 1


# --- the tram stop --------------------------------------------------------------------------

## A basis whose -z looks along `front` (plan), +x to the left of a reader facing it.
static func _facing(front: Vector2) -> Basis:
	return Basis(Vector3.UP, atan2(-front.x, -front.y))


func _stop() -> void:
	for s: Array in SHELTERS:
		var at: Vector2 = s[0]
		var lift := PLATFORM_H if at.y < -1415.0 else 0.0
		var b := _facing((s[1] as Vector2).normalized())
		_shelter(Transform3D(b, Vector3(at.x, _gh(at.x, at.y) + lift, at.y)))
	# The information boards: on the platform's west end and beside the south shelter.
	_info_board(Vector2(-626.0, -1420.6), Vector2(0.05, 1.0), "STARE MIASTO 02", PLATFORM_H)
	_info_board(Vector2(-597.8, -1404.6), Vector2(-0.1, -1.0), "STARE MIASTO 01", 0.0)
	var mach := Vector2(-609.5, -1421.0)
	Props.add_ticket_machine(_st, Transform3D(_facing(Vector2(0.05, 1.0)), Vector3(mach.x, _gh(mach.x, mach.y) + PLATFORM_H, mach.y)))
	var post := Vector2(-631.5, -1420.6)
	Props.add_stop_post(_st, Transform3D(_facing(Vector2(0.05, 1.0)), Vector3(post.x, _gh(post.x, post.y) + PLATFORM_H, post.y)))


## The stop's shelter (the photos'): a white louvred roof on a white frame, a glass back and one
## glass side, a lit advert case at the other end and a bench. Open to -z, 4.6 x 1.6 m.
func _shelter(xf: Transform3D) -> void:
	var glass := Color("#bcd2dc")
	var frame := Color("#dcdcd8")
	Props._xbox(_st, xf, Vector3(0, 2.62, 0.05), Vector3(4.7, 0.08, 1.75), frame)
	for k in 9:
		Props._xbox(_st, xf, Vector3(-2.1 + k * 0.525, 2.72, 0.05), Vector3(0.36, 0.08, 1.7), WHITE)
	for x in [-2.25, 2.25]:
		for z in [-0.65, 0.7]:
			Props._xbox(_st, xf, Vector3(x, 1.3, z), Vector3(0.08, 2.6, 0.08), frame)
	Props._xbox(_st, xf, Vector3(0, 1.25, 0.72), Vector3(4.4, 2.0, 0.04), glass)
	Props._xbox(_st, xf, Vector3(-2.25, 1.25, 0.05), Vector3(0.04, 2.0, 1.2), glass)
	# The advert case (backlit at night), 1.2 m wide, at the open end's side.
	Props._xbox(_st, xf, Vector3(2.25, 1.3, 0.05), Vector3(0.16, 1.9, 1.3), Color("#2e3238"))
	for sx in [-0.09, 0.09]:
		Props._xbox(_st, xf, Vector3(2.25 + sx, 1.35, 0.05), Vector3(0.02, 1.6, 1.12), Color("#e7a6c9"), Models.LIT_WINDOW)
	Props._xbox(_st, xf, Vector3(-0.4, 0.46, 0.45), Vector3(2.4, 0.06, 0.4), Color("#8a6a45"))
	for x in [-1.4, 0.6]:
		Props._xbox(_st, xf, Vector3(x, 0.22, 0.45), Vector3(0.06, 0.44, 0.3), Color("#33363b"))
	count += 1


## A passenger information board on a grey post: a dark case with four amber lines and the stop's
## name in amber on its head, facing `front`.
func _info_board(at: Vector2, front: Vector2, name: String, lift: float) -> void:
	var b := _facing(front.normalized())
	var y := _gh(at.x, at.y) + lift
	var xf := Transform3D(b, Vector3(at.x, y, at.y))
	Props._xbox(_st, xf, Vector3(0, 1.4, 0.1), Vector3(0.1, 2.8, 0.1), POST)
	Props._xbox(_st, xf, Vector3(0, 2.25, 0), Vector3(1.0, 0.9, 0.12), Color("#25282d"))
	for k in 4:
		Props._xbox(_st, xf, Vector3(-0.08, 2.43 - k * 0.15, -0.065), Vector3(0.7, 0.05, 0.01), AMBER, Models.LIT_SIGN)
		Props._xbox(_st, xf, Vector3(0.38, 2.43 - k * 0.15, -0.065), Vector3(0.1, 0.05, 0.01), AMBER, Models.LIT_SIGN)
	var px := 0.018
	var w := PixelFont.width(name) * px
	var right: Vector3 = b * Vector3(-1, 0, 0)
	PixelFont.add_quads(_st, name, xf * Vector3(w * 0.5, 2.68, -0.07), right, Vector3.DOWN, px, AMBER, Models.LIT_SIGN)
	count += 1


# --- the Castle side's pavement -------------------------------------------------------------

## Grodzka's top piece (way 8071, from the stop to the portal) and its north normal.
const GRODZKA_TOP := [Vector2(-641.0, -1424.1), Vector2(-644.1, -1422.6), Vector2(-649.3, -1419.9),
	Vector2(-654.8, -1417.4), Vector2(-669.4, -1411.4)]
## The kiosk the map has on the Castle side (building 5432, a 4.8 x 4 m box): its front to the road.
const KIOSK_FRONT := Vector2(-657.1, -1425.38)


func _castle_pavement() -> void:
	var d := ((GRODZKA_TOP[4] as Vector2) - (GRODZKA_TOP[2] as Vector2)).normalized()
	var north := Vector2(d.y, -d.x)
	if north.y > 0.0:
		north = -north
	# The map's kiosk gets its front: the lit window of goods and the board, toward the road.
	_kiosk_front(Transform3D(_facing(Vector2(0.055, 0.998)), Vector3(KIOSK_FRONT.x, _gh(KIOSK_FRONT.x, KIOSK_FRONT.y), KIOSK_FRONT.y)))
	# Black bollards along the kerb, 1.6 m apart, from the crossing to past the kiosk.
	for k in 9:
		var p := _along(GRODZKA_TOP, 3.0 + k * 1.6) + north * 2.35
		_black_bollard(Vector3(p.x, _gh(p.x, p.y), p.y))
	# Hire scooters: a row by the castle lawns past the kiosk and three by the wall over Nowy Zjazd.
	var scoot := [Color("#2f9e55"), Color("#e9e8e2"), Color("#2f9e55"), Color("#3a6fc4"), Color("#2f9e55")]
	for k in 5:
		var p := _along(GRODZKA_TOP, 19.0 + k * 0.75) + north * 5.2
		_scooter(Vector3(p.x, _gh(p.x, p.y), p.y), north.angle() + 0.3, scoot[k])
	for k in 3:
		var p := Vector2(-617.0 - k * 0.8, -1385.4 - k * 0.12)
		_scooter(Vector3(p.x, _gh(p.x, p.y + 0.6), p.y), PI * 0.5 + 0.25, scoot[k + 1])


## The point `s` metres along a plan polyline.
static func _along(pts: Array, s: float) -> Vector2:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var l := a.distance_to(b)
		if s <= l:
			return a.lerp(b, s / maxf(l, 0.001))
		s -= l
	return pts[pts.size() - 1]


## The front of the souvenir kiosk (the photo's; the box is the map's): a lit window with rows of
## goods and a dark board with the yellow words, on the face at `xf` (local -z out of the box).
func _kiosk_front(xf: Transform3D) -> void:
	Props._xbox(_st, xf, Vector3(0.9, 1.45, -0.03), Vector3(1.8, 1.5, 0.04), Color("#f1d79a"), Models.LIT_WINDOW)
	var goods := [Color("#e07a5f"), Color("#81b29a"), Color("#f2cc8f"), Color("#9db4d8"), Color("#e8a6b8")]
	for r in 3:
		for c in 5:
			Props._xbox(_st, xf, Vector3(0.26 + c * 0.32, 0.9 + r * 0.42, -0.06), Vector3(0.24, 0.26, 0.02), goods[(r * 5 + c) % goods.size()])
	Props._xbox(_st, xf, Vector3(0.9, 0.78, -0.25), Vector3(2.0, 0.06, 0.5), Color("#c9c4b8"))
	Props._xbox(_st, xf, Vector3(-1.2, 1.45, -0.03), Vector3(1.4, 1.5, 0.04), INK)
	Props._xbox(_st, xf, Vector3(0, 2.35, -0.6), Vector3(4.6, 0.08, 1.2), Color("#2b2f36"))
	var px := 0.024
	var right: Vector3 = xf.basis * Vector3(-1, 0, 0)
	var words := ["PAMIĄTKI", "NAPOJE", "BILETY", "PRZEKĄSKI"]
	for k in words.size():
		var w := PixelFont.width(words[k]) * px
		PixelFont.add_quads(_st, words[k], xf * Vector3(-1.2 + w * 0.5, 2.05 - k * 0.3, -0.06), right, Vector3.DOWN, px, YELLOW, Models.LIT_SIGN)
	count += 1


## A black street bollard with a grey cap, 0.9 m.
func _black_bollard(at: Vector3) -> void:
	Props.box(_st, at + Vector3(0, 0.45, 0), Vector3(0.14, 0.9, 0.14), Color("#22252a"))
	Props.box(_st, at + Vector3(0, 0.91, 0), Vector3(0.16, 0.05, 0.16), Color("#8d939a"))
	count += 1


## A hire scooter on its stand: a deck, the stem and the bar, in one plain colour.
func _scooter(at: Vector3, yaw: float, colour: Color) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, 0.12), at)
	Props._xbox(_st, xf, Vector3(0, 0.12, 0), Vector3(0.18, 0.06, 1.0), colour)
	Props._xbox(_st, xf, Vector3(0, 0.6, -0.45), Vector3(0.06, 1.0, 0.06), Color("#2b2f36"))
	Props._xbox(_st, xf, Vector3(0, 1.08, -0.45), Vector3(0.5, 0.05, 0.05), Color("#2b2f36"))
	for z in [-0.42, 0.42]:
		Props._xbox(_st, xf, Vector3(0, 0.1, z), Vector3(0.06, 0.2, 0.2), INK)
	count += 1


# --- the signs ------------------------------------------------------------------------------

## The way drivers come along the slip roads at their crossings (the signs look back at them).
const FACE_WEST := Vector2(-1.0, -0.2)


func _signs() -> void:
	# Nowy Zjazd, at its zebra and the island between it and the W-Z.
	_d6(Vector2(-640.3, -1398.0), FACE_WEST)
	_d6(Vector2(-642.4, -1392.3), FACE_WEST)
	_plate_post(Vector2(-636.8, -1397.2), FACE_WEST)
	_a30_bus(Vector2(-630.5, -1395.6), FACE_WEST)
	_no_stop_one_way(Vector2(-612.2, -1386.3), FACE_WEST)
	_yellow_post(Vector2(-638.6, -1397.6))
	_yellow_post(Vector2(-643.0, -1399.3))
	# Grodzka, at its zebra and the platform's west nose.
	_d6(Vector2(-645.9, -1425.4), Vector2(1.0, 0.25))
	_no_entry(Vector2(-639.2, -1419.4), Vector2(-1.0, 0.0))
	_yellow_post(Vector2(-638.9, -1421.5))
	_yellow_post(Vector2(-642.0, -1416.8))


## A sign post 2.9 m with its foot on the ground, returning the post's frame (-z = the sign's face).
func _post(at: Vector2, front: Vector2, height := 2.9) -> Transform3D:
	var xf := Transform3D(_facing(front.normalized()), Vector3(at.x, _gh(at.x, at.y), at.y))
	Props._xbox(_st, xf, Vector3(0, height * 0.5, 0.06), Vector3(0.07, height, 0.07), POST)
	count += 1
	return xf


## A round plate (an octagon pair) of `r` at `c`, its face to the post's -z, the back grey.
func _disc(xf: Transform3D, c: Vector3, r: float, rim: Color, face: Color, inner := 0.78) -> void:
	for turn in [0.0, PI * 0.25]:
		var tb := xf.basis * Basis(Vector3.BACK, turn)
		var w := r * 1.53
		Props.obox(_st, xf * c, tb, Vector3(w, w * 0.414, 0.03), rim)
		Props.obox(_st, xf * c, tb, Vector3(w * 0.414, w, 0.03), rim)
		Props.obox(_st, xf * (c + Vector3(0, 0, -0.02)), tb, Vector3(w * inner, w * inner * 0.414, 0.02), face, Models.LIT_SIGN)
		Props.obox(_st, xf * (c + Vector3(0, 0, -0.02)), tb, Vector3(w * inner * 0.414, w * inner, 0.02), face, Models.LIT_SIGN)


## D-6 (przejście dla pieszych): a blue square, a white triangle and the walker.
func _d6(at: Vector2, front: Vector2) -> void:
	var xf := _post(at, front, 2.7)
	var c := Vector3(0, 2.45, 0)
	Props._xbox(_st, xf, c, Vector3(0.6, 0.6, 0.03), BLUE, Models.LIT_SIGN)
	var n := xf.basis * Vector3(0, 0, -1)
	var w := xf * (c + Vector3(0, 0, -0.02))
	var r := xf.basis * Vector3(0.24, 0, 0)
	var u := xf.basis * Vector3(0, 0.22, 0)
	Props.tri(_st, w - r - u, w + r - u, w + u * 1.1, n, WHITE, Models.LIT_SIGN)
	Props._xbox(_st, xf, c + Vector3(0, -0.06, -0.03), Vector3(0.04, 0.16, 0.01), INK)
	Props._xbox(_st, xf, c + Vector3(0, 0.06, -0.03), Vector3(0.05, 0.05, 0.01), INK)
	Props._xbox(_st, xf, c + Vector3(0, -0.18, -0.03), Vector3(0.36, 0.03, 0.01), INK)


## Nowy Zjazd's street plate over B-5 (no lorries) with its "2,5 t" disc.
func _plate_post(at: Vector2, front: Vector2) -> void:
	var xf := _post(at, front, 3.3)
	Props._street_plate(_st, xf, Vector3(0, 3.05, -0.06), "NOWY ZJAZD")
	var c := Vector3(0, 2.3, -0.05)
	_disc(xf, c, 0.32, RED, WHITE)
	Props._xbox(_st, xf, c + Vector3(0, 0.07, -0.04), Vector3(0.3, 0.13, 0.01), INK)
	var px := 0.016
	var right: Vector3 = xf.basis * Vector3(-1, 0, 0)
	PixelFont.add_quads(_st, "2,5T", xf * (c + Vector3(PixelFont.width("2,5T") * px * 0.5, -0.04, -0.045)), right, Vector3.DOWN, px, INK, Models.FIXED)
	Props._xbox(_st, xf, Vector3(0, 1.85, -0.05), Vector3(0.55, 0.18, 0.02), WHITE, Models.LIT_SIGN)


## A-30 (other danger: "!") over the yellow board with a bus and a walker (the photo's).
func _a30_bus(at: Vector2, front: Vector2) -> void:
	var xf := _post(at, front, 3.2)
	var n := xf.basis * Vector3(0, 0, -1)
	var c := xf * Vector3(0, 2.75, -0.05)
	var r := xf.basis * Vector3(0.36, 0, 0)
	var u := xf.basis * Vector3(0, 0.31, 0)
	Props.tri(_st, c - r - u, c + r - u, c + u, n, RED, Models.LIT_SIGN)
	var c2 := c + n * 0.01
	Props.tri(_st, c2 - r * 0.78 - u * 0.8, c2 + r * 0.78 - u * 0.8, c2 + u * 0.72, n, YELLOW, Models.LIT_SIGN)
	Props._xbox(_st, xf, Vector3(0, 2.72, -0.08), Vector3(0.05, 0.2, 0.01), INK)
	Props._xbox(_st, xf, Vector3(0, 2.57, -0.08), Vector3(0.05, 0.05, 0.01), INK)
	Props._xbox(_st, xf, Vector3(0, 1.95, -0.05), Vector3(0.66, 0.8, 0.03), YELLOW, Models.LIT_SIGN)
	Props._xbox(_st, xf, Vector3(0.12, 2.02, -0.07), Vector3(0.28, 0.24, 0.01), INK)
	Props._xbox(_st, xf, Vector3(-0.16, 1.98, -0.07), Vector3(0.06, 0.2, 0.01), INK)
	Props._xbox(_st, xf, Vector3(0, 1.66, -0.07), Vector3(0.56, 0.03, 0.01), INK)


## B-36 (no stopping) over D-3 (one way), by the escarpment wall.
func _no_stop_one_way(at: Vector2, front: Vector2) -> void:
	var xf := _post(at, front, 3.0)
	var c := Vector3(0, 2.65, -0.05)
	_disc(xf, c, 0.3, RED, BLUE)
	var b := xf.basis * Basis(Vector3.BACK, PI * 0.25)
	for turn in [0.0, PI * 0.5]:
		Props.obox(_st, xf * (c + Vector3(0, 0, -0.04)), b * Basis(Vector3.BACK, turn), Vector3(0.42, 0.05, 0.01), RED, Models.LIT_SIGN)
	Props._xbox(_st, xf, Vector3(0, 1.95, -0.05), Vector3(0.5, 0.6, 0.03), BLUE, Models.LIT_SIGN)
	Props._xbox(_st, xf, Vector3(0, 1.9, -0.07), Vector3(0.07, 0.34, 0.01), WHITE, Models.LIT_SIGN)
	var n := xf.basis * Vector3(0, 0, -1)
	var t := xf * Vector3(0, 2.14, -0.07)
	Props.tri(_st, t - xf.basis * Vector3(0.12, 0, 0), t + xf.basis * Vector3(0.12, 0, 0), t + Vector3.UP * 0.14, n, WHITE, Models.LIT_SIGN)


## B-2 (no entry): a red disc with a white bar.
func _no_entry(at: Vector2, front: Vector2) -> void:
	var xf := _post(at, front, 2.6)
	var c := Vector3(0, 2.3, -0.05)
	_disc(xf, c, 0.32, RED, RED, 0.6)
	Props._xbox(_st, xf, c + Vector3(0, 0, -0.04), Vector3(0.4, 0.1, 0.01), WHITE, Models.LIT_SIGN)


## A yellow post on an island's nose (black bands), 1.0 m.
func _yellow_post(at: Vector2) -> void:
	var p := Vector3(at.x, _gh(at.x, at.y), at.y)
	Props.box(_st, p + Vector3(0, 0.5, 0), Vector3(0.18, 1.0, 0.18), YELLOW)
	for h in [0.62, 0.86]:
		Props.box(_st, p + Vector3(0, h, 0), Vector3(0.19, 0.06, 0.19), INK)
	count += 1


## The drawn ground (roads, pavements, terrain) under a point, typed for the helpers above.
func _gh(x: float, z: float) -> float:
	return map.ground_height(x, z)


## The bare terrain under a point (the stairs' slope, not the flights themselves).
func _th(x: float, z: float) -> float:
	return map.terrain_height(x, z)
