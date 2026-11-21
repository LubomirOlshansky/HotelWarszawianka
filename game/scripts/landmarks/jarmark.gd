extends "res://scripts/landmarks/kladka.gd"
## Jarmark Warszawski 2026, the Christmas market at the foot of the Palace (F, 2026-11-20: "make it
## 10 over 10, like for the best trailer", by day and by night). One link of landmarks.gd's base
## chain (TD-10): it uses this file, common.gd and the facade kit, never another area. Refs (never
## shipped): /mnt/project-files/refs/jarmark-2026/ (the organiser's drone reel, the opening-day
## gallery, the Palace's own reel of the tower carousel). Spec docs/landmarks/specs/jarmark.md.
##
## The market's frame is the museum's (MSN: u along Marszałkowska to the south-south-east, v from
## Marszałkowska towards the Palace). Three parts, from the drone frames:
##  - the main market on the Defilad car park (u 115-200, v -15..75): the dark asphalt with rows of
##    gable-roofed chalets back to back, aisles between them under zig-zag strings of warm bulbs, a
##    central line of small food stalls with yellow roofs; by Marszałkowska the big LED tree on its
##    round platform with yellow benches and a lit snowman, the giant Santa-hat photo spot, the
##    Venetian carousel with light strings fanning from its top, the red sausage stand, the glass
##    greenhouse tunnel at the south end, the two-storey red hexagonal bar, and on the Palace side
##    the lit stage and the red mulled-wine bar;
##  - the annex south of the museum (u 40-115): the rows F photographed going up on 2026-11-15, now
##    finished, the gold WESOŁYCH ŚWIĄT sign at the Marszałkowska entrance, light-up trees, a star;
##  - the Plac Centralny part (u 50-86, v 40-78): the viewing tower carousel (a 38 m rainbow LED
##    mast, the gold carrier with lit spokes and swinging chairs, the orange crown), the teacups, the
##    Christmas-tree carousel and Santa's log cabin.
## Everything is the city's building surface (+0 draw calls); every light is M_LAMP (its colour by
## day, glowing at night; the tree's strands M_LAMP + 0.5, green by day and blue at night). The
## bulbs over the aisles are kept out of the roof grid. The cars that park there the rest of the
## year are cleared (`parked_free`), and the trees in the rides' swing.

const JM_O := Vector2(-1022.4, 100.15)
const JM_AXIS := Vector2(0.3445, 0.9388)

const JM_WHITE := Color("#f2f0ea")
const JM_TRIM := Color("#2a2b2f")
const JM_ROOF := Color("#323438")
const JM_ROOF_LIGHT := Color("#d6d3cc")
const JM_RED := Color("#b0232a")
const JM_YELLOW := Color("#e9b62c")
const JM_TIMBER := Color("#6b4a2e")
const JM_FIR := Color("#25603a")
const JM_BOW := Color("#d0222c")
const JM_GLOW := Color("#cf8d4c")
const JM_BULB := Color(1.0, 0.84, 0.55)
const JM_LED := Color(0.9, 0.94, 1.0)
const JM_GOLD := Color("#e3b34a")
const JM_BLUE := Color(0.32, 0.55, 1.0)
const JM_ASPHALT := Color("#56585c")
const JM_WIRE := Color("#2b2c2f")
const JM_RAINBOW := [Color("#e8333a"), Color("#f08a24"), Color("#f2d230"), Color("#4cc35a"), Color("#2fa8e0"),
		Color("#3a5be0"), Color("#9a4ad8")]

## Hut kinds: white with black trim, white half-timbered (black frame and cross braces), red, the
## small dark food stall with a yellow roof, the big white chalet.
enum Hut { WHITE, TIMBER, RED, FOOD, BIG }

## The rows: [u0, u1, v, quarter (front turned from -v: 0 faces -v, 2 faces +v, -1 alternates),
## kind (-1 mixed), step, skips ([u0, u1] where no hut stands: cross aisles, the metro pavilions)].
const JM_ROWS := [
	# The main market, Marszałkowska row first, then the rows back to back towards the Palace.
	[118.0, 197.0, -11.0, 2, -1, 3.5, [[128.0, 151.0], [161.0, 169.5], [172.0, 180.0]]],
	[146.0, 195.0, 22.0, 0, -1, 3.5, [[166.5, 172.5]]],
	[146.0, 195.0, 25.6, 2, -1, 3.5, [[166.5, 172.5]]],
	[119.0, 193.0, 33.0, -1, Hut.FOOD, 3.0, [[141.0, 147.0], [166.5, 172.5]]],
	[118.0, 195.0, 40.0, 0, -1, 3.5, [[141.0, 147.0], [166.5, 172.5]]],
	[118.0, 195.0, 43.6, 2, -1, 3.5, [[141.0, 147.0], [166.5, 172.5]]],
	[118.0, 195.0, 56.0, 0, -1, 3.5, [[141.0, 147.0], [166.5, 172.5]]],
	[118.0, 195.0, 59.6, 2, -1, 3.5, [[141.0, 147.0], [166.5, 172.5]]],
	[118.0, 141.0, 72.0, 0, -1, 3.5, []],
	[186.0, 196.0, 72.0, 0, Hut.BIG, 5.6, []],
	# The annex by the museum (F's photos, 2026-11-15): the white rows, the half-timbered pair.
	[41.0, 63.0, 29.0, 0, Hut.WHITE, 4.3, []],
	[95.0, 113.0, 29.0, 0, Hut.WHITE, 4.3, []],
	[69.0, 88.0, -11.0, 0, Hut.TIMBER, 3.7, []],
	[72.7, 88.0, 5.0, 2, Hut.TIMBER, 3.7, []],
	[92.0, 113.0, -3.0, -1, Hut.FOOD, 3.0, []],
]
## Huts not in a row: [u, v, quarter, kind]. The three turned to the annex's plaza.
const JM_HUTS := [[56.5, 10.0, 1, Hut.WHITE], [56.5, 13.7, 1, Hut.TIMBER], [56.5, 17.4, 1, Hut.RED]]

## The strings of bulbs zig-zagging over the aisles: [u0, u1, v_a, v_b, step along u].
const JM_STRINGS := [[146.0, 195.0, 25.6, 33.0, 5.0], [119.0, 193.0, 33.0, 40.0, 5.0],
		[118.0, 195.0, 43.6, 56.0, 6.0], [118.0, 195.0, 59.6, 72.0, 6.0], [150.0, 197.0, -8.0, 0.0, 6.0],
		[60.0, 92.0, 8.0, 27.0, 6.0], [93.0, 113.0, 0.0, 27.0, 6.0]]
## Straight strings along v down the cross aisles: [u, v0, v1].
const JM_LINES := [[144.0, 28.0, 72.0], [169.5, 15.0, 72.0], [92.0, -14.0, 28.0]]

const JM_TREE := Vector2(135.0, 5.0)
const JM_CAROUSEL := Vector2(170.0, 6.0)
const JM_TOWER := Vector2(56.0, 70.0)
const JM_TEACUPS := Vector2(79.0, 70.0)
const JM_TREE_RIDE := Vector2(79.0, 48.0)
const JM_SANTA := Vector2(56.0, 47.0)
const JM_HEXBAR := Vector2(128.0, 24.0)
const JM_STAGE := Vector2(155.0, 74.0)
const JM_GREENHOUSE := [199.5, 10.0, 29.0]
## The market's ground: the car park's asphalt under the main market, the annex's east end.
const JM_PAVED := [[115.0, 198.0, -15.0, 76.0], [89.0, 115.0, -15.0, 31.0]]
const JM_LIFT := 0.28
## The tower carousel's carrier at its top (metres over the ground); jarmark_rides.gd runs it down to the base.
const TOWER_TOP := 26.0
## How far the carrier comes down to load: the chairs (6 m under it) stop just over the base.
const TOWER_DROP := 18.9
## The riders' coats (the reels: dark winter coats, a few bright ones).
const JM_SHIRTS := [Color("#2c3440"), Color("#7a1f26"), Color("#e7e2d6"), Color("#344a2e"), Color("#1c1d22"),
		Color("#c25a2a"), Color("#4a5a8a"), Color("#8a7a62")]


func _jm_frame() -> void:
	_o = JM_O
	_a = JM_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)


func _jm_p(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, y, p.y)


func _jm_bar(u0: float, v0: float, y0: float, u1: float, v1: float, y1: float, w: float, col: Color, mode := M_STONE) -> void:
	_beam(_jm_p(u0, v0, y0), _jm_p(u1, v1, y1), w, col, true, mode)


func _jm_ground(u: float, v: float) -> float:
	var p := _w(u, v)
	return map.terrain_height(p.x, p.y)


## Turn the frame to a spot: origin at local (u, v) of the market, the front `quarter` turns from -v.
func _jm_at(u: float, v: float, quarter: int) -> float:
	_jm_frame()
	var pos := _w(u, v)
	_o = pos
	for q in posmod(quarter, 4):
		_a = Vector2(-_a.y, _a.x)
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(pos.x, pos.y)
	return _g


## Every hut: [u, v, quarter, kind, n], the rows laid out and the single huts.
static func _jm_huts() -> Array:
	var out: Array = []
	var n := 0
	for r: Array in JM_ROWS:
		var u: float = r[0]
		var k := 0
		while u <= float(r[1]) + 0.01:
			var skip := false
			for s: Array in r[6]:
				if u > float(s[0]) - 1.8 and u < float(s[1]) + 1.8:
					skip = true
			if not skip:
				var q: int = r[3]
				if q < 0:
					q = 0 if k % 2 == 0 else 2
				var kind: int = r[4]
				if kind < 0:
					kind = Hut.RED if n % 7 == 3 else (Hut.TIMBER if n % 3 == 0 else Hut.WHITE)
				out.append([u, float(r[2]), q, kind, n])
				n += 1
				k += 1
			u += float(r[5])
	for h: Array in JM_HUTS:
		out.append([h[0], h[1], h[2], h[3], n])
		n += 1
	return out


## A market point (u, v) in the world plan, without the instance frame (crowds.gd's plan).
static func _jm_world(u: float, v: float) -> Vector2:
	var a := JM_AXIS.normalized()
	return JM_O + a * u + Vector2(-a.y, a.x) * v


## How far over the terrain the market's ground is at a world point: the asphalt's JM_LIFT on the
## paved parts (over the lawns' own lift), 0 elsewhere (crowds.gd stands the shoppers on it).
static func jarmark_lift(p: Vector2) -> float:
	var a := JM_AXIS.normalized()
	var d := p - JM_O
	var u := d.dot(a)
	var v := d.dot(Vector2(-a.y, a.x))
	for r: Array in JM_PAVED:
		if u >= float(r[0]) and u <= float(r[1]) and v >= float(r[2]) and v <= float(r[3]):
			return JM_LIFT
	return 0.0


## Where the market's shoppers stand (crowds.gd, kind `jarmark`): [plan point, the way they face,
## part (0 the main market, 1 the annex and Plac Centralny)]. Two at most counters, looking at the
## goods; a ring round the tree; queues at the carousel, the tower and the teacups; a few in the
## aisles looking about. Deterministic, so both city paths and every run agree.
static func jarmark_plan() -> Array:
	var out: Array = []
	var a := JM_AXIS.normalized()
	var b := Vector2(-a.y, a.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for h: Array in _jm_huts():
		var au := a
		for q in int(h[2]):
			au = Vector2(-au.y, au.x)
		var bv := Vector2(-au.y, au.x)
		var hv := 1.0 if h[3] == Hut.FOOD else 1.15
		var c := _jm_world(h[0], h[1])
		var part := 0 if float(h[0]) > 114.0 else 1
		for k in [0, 1, 2, 3]:
			if k == 3 and int(h[4]) % 2 != 0:
				continue
			var off := rng.randf_range(-1.3, 1.3)
			var p: Vector2 = c - bv * (hv + rng.randf_range(0.75, 1.3)) + au * off
			out.append([p, bv.rotated(rng.randf_range(-0.4, 0.4)), part])
	for k in 26:
		var t := TAU * (float(k) + rng.randf()) / 26.0
		var d := (a * cos(t) + b * sin(t))
		out.append([_jm_world(JM_TREE.x, JM_TREE.y) + d * rng.randf_range(8.3, 11.0), -d, 0])
	for ride: Array in [[JM_CAROUSEL, 7.5, 18, 0], [JM_TOWER, 6.0, 16, 1], [JM_TEACUPS, 6.8, 10, 1], [JM_TREE_RIDE, 5.4, 9, 1]]:
		var rc: Vector2 = ride[0]
		for k in int(ride[2]):
			var t := -PI * 0.5 + rng.randf_range(-1.2, 1.2)
			var d := (a * cos(t) + b * sin(t))
			out.append([_jm_world(rc.x, rc.y) + d * (float(ride[1]) + rng.randf_range(0.0, 2.5)), -d, ride[3]])
	for s: Array in JM_STRINGS:
		var u := float(s[0]) + 2.0
		while u < float(s[1]) - 2.0:
			# To one side of the aisle (the strollers of jarmark_life.gd keep to its middle).
			var f := rng.randf_range(0.28, 0.36)
			var v := lerpf(float(s[2]), float(s[3]), f if rng.randf() < 0.5 else 1.0 - f)
			var t := rng.randf() * TAU
			var at := _jm_world(u, v)
			var part := 0 if u > 114.0 else 1
			out.append([at, Vector2(cos(t), sin(t)), part])
			# Half the time a friend: two who stopped to talk, face to face.
			if rng.randf() < 0.5:
				var d := Vector2(cos(t), sin(t))
				out.append([at + d * 0.8, -d, part])
			u += rng.randf_range(2.2, 4.5)
	return out


func _find_jarmark() -> void:
	_jm_frame()
	var zones: Array = []
	for h: Array in _jm_huts():
		var big := 2.8 if h[3] == Hut.BIG else 1.9
		zones.append(_rect(h[0], h[1], big, big))
	for c: Vector2 in [JM_TREE, JM_CAROUSEL, JM_TOWER, JM_TEACUPS, JM_TREE_RIDE, JM_SANTA, JM_HEXBAR, JM_STAGE]:
		zones.append(_rect(c.x, c.y, 4.0, 4.0))
	_add_site("jarmark", zones)
	# The cars that park on Plac Defilad the rest of the year, and the trees in the rides' way.
	for p: Array in JM_PAVED:
		var ring := _urect(p[0], p[1], p[2], p[3])
		parked_free.append([ring, _box_of([ring])])
		tree_free.append([ring, 0.0, _box_of([ring])])
	for c: Array in [[JM_TOWER, 12.5], [JM_TEACUPS, 7.0], [JM_TREE_RIDE, 6.0], [JM_SANTA, 5.0]]:
		tree_free.append([_w(c[0].x, c[0].y), c[1]])


func _build_jarmark(_site: Dictionary) -> void:
	_jm_frame()
	_mode = M_STONE
	for p: Array in JM_PAVED:
		_jm_drape(p[0], p[1], p[2], p[3])
	for h: Array in _jm_huts():
		_jm_hut(h[0], h[1], h[2], h[3], h[4])
	# The tree's plaza by Marszałkowska.
	_jm_tree(JM_TREE)
	for k in 14:
		var t := TAU * (float(k) + 0.5) / 14.0
		if absf(wrapf(t - PI * 1.5, -PI, PI)) < 0.5:
			continue  # the gap towards the metro pavilion
		_jm_bench(JM_TREE + Vector2(cos(t), sin(t)) * 9.6, t)
	_jm_snowman(144.0, 13.0)
	_jm_hat(152.5, -4.5)
	_jm_carousel(JM_CAROUSEL)
	_jm_redbar(186.5, 6.0, 3.2, 2.2, "KIEŁBASKI")
	_jm_greenhouse(JM_GREENHOUSE[0], JM_GREENHOUSE[1], JM_GREENHOUSE[2])
	_jm_hexbar(JM_HEXBAR)
	_jm_stage(JM_STAGE)
	_jm_redbar(178.0, 74.0, 4.2, 3.0, "GRZANIEC")
	# The red and green barrel tables in the plazas.
	var barrels := [[122.0, 15.0], [124.0, 18.5], [149.0, 18.0], [153.0, 15.5], [181.0, 15.5], [184.0, 16.5],
			[156.0, 64.0], [161.0, 66.0], [175.0, 66.5], [100.0, 12.0], [104.0, 15.0], [66.0, 15.0], [70.0, 21.0]]
	for i in barrels.size():
		_jm_barrel(barrels[i][0], barrels[i][1], JM_RED if i % 2 == 0 else Color("#2f7a3c"))
	# The light strings over the aisles.
	for s: Array in JM_STRINGS:
		_jm_zigzag(s[0], s[1], s[2], s[3], s[4])
	for l: Array in JM_LINES:
		_jm_line(l[0], l[1], l[2])
	# The fence along Marszałkowska with its white banners, the entrances open.
	_jm_fence(40.0, 198.0, -17.5, [[88.0, 97.0], [128.0, 151.0], [160.0, 166.0]])
	for bu: float in [60.0, 112.0, 182.0]:
		_jm_banner(bu, -17.6)
	# The gold sign and the light-up trees at the two entrances, a big star, more trees down the aisles.
	_jm_greeting(92.5, -15.5)
	_jm_greeting(147.0, -3.0)
	for t: Array in [[86.0, -15.5], [99.0, -15.5], [141.0, -3.5], [153.0, 0.5], [92.0, 20.0], [92.0, 24.0],
			[144.0, 31.0], [144.0, 49.5], [169.5, 49.5], [169.5, 64.5], [60.0, 76.0], [52.0, 56.0]]:
		_jm_ledtree(t[0], t[1], 3.4)
	_jm_bigstar(106.0, -14.5, 1.9)
	_jm_bigstar(196.0, -13.0, 1.6)
	# Plac Centralny: the tower, the teacups, the tree carousel, Santa's cabin.
	_jm_tower(JM_TOWER)
	_jm_teacups(JM_TEACUPS)
	_jm_tree_ride(JM_TREE_RIDE)
	_jm_santa(JM_SANTA)
	_jm_frame()


## The asphalt laid over the car park and the lawns between its aisles (the drone frames show the
## whole market on dark asphalt with faint white bay lines), draped on the terrain in 4 m cells.
func _jm_drape(u0: float, u1: float, v0: float, v1: float) -> void:
	_jm_frame()
	var cols := ceili((u1 - u0) / 4.0)
	var rows := ceili((v1 - v0) / 4.0)
	var pts: Array[Vector3] = []
	for j in rows + 1:
		for i in cols + 1:
			var w := _w(lerpf(u0, u1, float(i) / cols), lerpf(v0, v1, float(j) / rows))
			pts.append(Vector3(w.x, map.terrain_height(w.x, w.y) + JM_LIFT, w.y))
	_mode = M_STONE
	for j in rows:
		for i in cols:
			var k := j * (cols + 1) + i
			var col := JM_ASPHALT.lightened(0.03 * float((i * 7 + j * 3) % 3))
			_quad(pts[k], pts[k + 1], pts[k + cols + 2], pts[k + cols + 1], Vector3.UP, col,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The car park's old bay lines, white, across the aisles of the main market.
	if u0 > 110.0:
		for vl: float in [17.0, 49.0, 65.0]:
			var uu := u0 + 2.0
			while uu < u1 - 2.0:
				var g := _jm_ground(uu, vl)
				_ubox(uu - 0.06, uu + 0.06, vl - 2.4, vl + 2.4, g + JM_LIFT, g + JM_LIFT + 0.05, Color("#c9c9c4"), M_STONE)
				uu += 2.6


## One chalet, its front (the counter) to -v after `quarter` turns. 3.2 x 2.3 m (the food stall
## 2.6 x 2.0, the big chalet 5.2 x 3.0), gable roof along the front, the counter lit from inside,
## goods on the shelf, a fir garland with red bows and a string of bulbs on most.
func _jm_hut(u: float, v: float, quarter: int, kind: int, n: int) -> void:
	var g := _jm_at(u, v, quarter)
	var hu := 1.6
	var hv := 1.15
	var eave := 2.3
	var rise := 0.95
	var wall := JM_WHITE
	var roof := JM_ROOF
	var trim := JM_TRIM
	match kind:
		Hut.RED:
			wall = JM_RED
			trim = JM_WHITE
		Hut.FOOD:
			hu = 1.3
			hv = 1.0
			eave = 2.2
			rise = 0.75
			wall = Color("#3a3634")
			roof = JM_YELLOW
			trim = JM_YELLOW
		Hut.BIG:
			hu = 2.6
			hv = 1.5
			eave = 2.6
			rise = 1.25
	if kind == Hut.WHITE and n % 4 == 1:
		roof = JM_ROOF_LIGHT
	_mode = M_STONE
	_lbox(0.0, 0.0, hu, hv, g, g + eave, wall, M_STONE, wall.darkened(0.1))
	# The counter: the open front lit from inside (goods by day, a warm glow at night), the shelf.
	var top := g + eave - 0.3
	_ubox(-hu + 0.22, hu - 0.22, -hv - 0.03, -hv, g + 1.05, top, JM_GLOW, M_LAMP)
	_ubox(-hu, hu, -hv - 0.4, -hv, g + 0.93, g + 1.03, JM_TIMBER, M_STONE)
	var goods := [Color("#c23b2e"), Color("#e7c14a"), Color("#3d7a4a"), Color("#f3efe6"), Color("#7a4a8c")]
	for k in 2:
		var gu := -hu * 0.5 + float(k) * hu
		var col: Color = goods[(n + k) % goods.size()]
		_ubox(gu - 0.22, gu + 0.22, -hv - 0.32, -hv - 0.08, g + 1.03, g + 1.3 + 0.1 * float((n + k) % 3), col, M_STONE)
	# The roof, overhanging the counter.
	_gable(hu + 0.15, -hu - 0.15, 0.0, hv + 0.4, g + eave, rise, wall, roof, true)
	# Trim: corner posts, the eave beam, the plinth.
	for su: float in [-hu, hu - 0.12]:
		_ubox(su, su + 0.12, -hv - 0.03, hv + 0.03, g, g + eave - 0.05, trim, M_STONE)
	_ubox(-hu, hu, -hv - 0.05, -hv, g + eave - 0.14, g + eave, trim, M_STONE)
	_ubox(-hu, hu, -hv - 0.05, -hv, g, g + 0.18, trim, M_STONE)
	if kind == Hut.TIMBER or kind == Hut.BIG:
		# The half-timbered look: black braces below the counter, a black post in the middle.
		var parts := 3 if kind == Hut.TIMBER else 4
		var w := (2.0 * hu - 0.24) / parts
		for k in parts:
			var b0 := -hu + 0.12 + k * w
			_jm_bar(b0 + 0.05, -hv - 0.06, g + 0.2, b0 + w - 0.05, -hv - 0.06, g + 0.95, 0.07, JM_TRIM)
			_jm_bar(b0 + w - 0.05, -hv - 0.06, g + 0.2, b0 + 0.05, -hv - 0.06, g + 0.95, 0.07, JM_TRIM)
		for sv: float in [-1.0, 1.0]:
			var sx := sv * (hu + 0.04)
			_jm_bar(sx, -hv + 0.1, g + 0.2, sx, hv - 0.1, g + eave - 0.2, 0.07, JM_TRIM)
			_jm_bar(sx, hv - 0.1, g + 0.2, sx, -hv + 0.1, g + eave - 0.2, 0.07, JM_TRIM)
	# The fir garland with red bows along the front eave, and the bulbs under it.
	if kind != Hut.FOOD and n % 5 != 4:
		_jm_bar(-hu - 0.15, -hv - 0.42, g + eave - 0.05, hu + 0.15, -hv - 0.42, g + eave - 0.05, 0.22, JM_FIR)
		for bu: float in [-hu, hu]:
			_ubox(bu - 0.13, bu + 0.13, -hv - 0.58, -hv - 0.46, g + eave - 0.32, g + eave - 0.06, JM_BOW, M_STONE)
	if n % 5 != 2:
		_no_roof = true
		_jm_bar(-hu - 0.1, -hv - 0.36, g + eave - 0.2, hu + 0.1, -hv - 0.36, g + eave - 0.2, 0.06, JM_BULB, M_LAMP)
		_no_roof = false
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	_jm_frame()


## A string of bulbs from p to q (world), sagging, a bulb every ~1.3 m. Out of the roof grid.
func _jm_string(p: Vector3, q: Vector3, sag: float) -> void:
	_no_roof = true
	var sagged := func(t: float) -> Vector3:
		return p.lerp(q, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t)
	var prev := p
	for k in range(1, 5):
		var at: Vector3 = sagged.call(float(k) / 4.0)
		_beam(prev, at, 0.03, JM_WIRE, false)
		prev = at
	var n := maxi(3, ceili(p.distance_to(q) / 1.25))
	for k in range(1, n):
		var at: Vector3 = sagged.call(float(k) / n)
		_prism(_circle(Vector2(at.x, at.z), 0.15, 3), at.y - 0.26, at.y - 0.04, JM_BULB, JM_BULB, M_LAMP, M_LAMP)
	_no_roof = false


## A thin dark pole at local (u, v) up to `h` over the ground; its top.
func _jm_pole(u: float, v: float, h: float) -> Vector3:
	var g := _jm_ground(u, v)
	_jm_bar(u, v, g, u, v, g + h, 0.09, JM_WIRE)
	return _jm_p(u, v, g + h)


## Strings zig-zagging across an aisle between the lines v_a and v_b, from u0 to u1.
func _jm_zigzag(u0: float, u1: float, va: float, vb: float, step: float) -> void:
	_jm_frame()
	var u := u0
	var at_a := true
	var prev := _jm_pole(u, va, 4.2)
	while u + step * 0.5 <= u1:
		u += step * 0.5
		at_a = not at_a
		var nxt := _jm_pole(u, va if at_a else vb, 4.2)
		_jm_string(prev, nxt, 0.45)
		prev = nxt


## A straight string down a cross aisle, between poles every 8 m.
func _jm_line(u: float, v0: float, v1: float) -> void:
	_jm_frame()
	var n := maxi(1, ceili((v1 - v0) / 8.0))
	var prev := _jm_pole(u, v0, 4.6)
	for k in range(1, n + 1):
		var nxt := _jm_pole(u, lerpf(v0, v1, float(k) / n), 4.6)
		_jm_string(prev, nxt, 0.35)
		prev = nxt


## The big tree (nm-01, the drone frames): about 15 m, eight tiers of fir green with big red, gold
## and white baubles, LED strands round every tier and down the cone (blue at night, as the reels
## show it), white bulbs on the rims and the gold star; on a round platform with a red rail.
func _jm_tree(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_mode = M_STONE
	_prism(_circle(c, 7.5, 24), g, g + 0.35, Color("#7a5a3c"), Color("#cfc8bc"), M_STONE, M_STONE)
	_no_roof = true
	var ring := _circle(c, 7.35, 24)
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		_beam(Vector3(a.x, g + 0.36, a.y), Vector3(b.x, g + 0.36, b.y), 0.08, JM_LED, false, M_LAMP)
		_beam(Vector3(a.x, g + 1.1, a.y), Vector3(b.x, g + 1.1, b.y), 0.07, JM_BOW, false)
		_beam(Vector3(a.x, g + 0.36, a.y), Vector3(a.x, g + 1.1, a.y), 0.07, JM_BOW, false)
	_no_roof = false
	var g0 := g + 0.35
	var tiers := 8
	var apex := g0 + 0.5 + tiers * 1.75 + 0.6
	for k in tiers:
		var y0 := g0 + 0.5 + k * 1.75
		var r0 := 4.7 - 0.53 * k
		# The tiers themselves are the LED net: fir green by day, blue at night (the reels).
		var keep_mode := _mode
		_mode = M_LAMP + 0.5
		_frustum(_circle(c, r0, 12), y0, _circle(c, r0 * 0.32, 12), y0 + 2.5, JM_FIR, JM_FIR.darkened(0.2))
		_mode = keep_mode
		var rim := _circle(c, r0 + 0.05, 12)
		_no_roof = true
		for j in rim.size():
			var a := rim[j]
			var b := rim[(j + 1) % rim.size()]
			_beam(Vector3(a.x, y0 + 0.05, a.y), Vector3(b.x, y0 + 0.05, b.y), 0.09, JM_FIR.lightened(0.15), false, M_LAMP + 0.5)
			_prism(_circle(a, 0.14, 4), y0 - 0.12, y0 + 0.12, JM_LED, JM_LED, M_LAMP, M_LAMP)
		_no_roof = false
		for j in 6:
			var t := TAU * (float(j) + 0.5 * (k % 2)) / 6.0
			var p := c + Vector2(cos(t), sin(t)) * (r0 * 0.86)
			var col: Color = [Color("#c8232c"), Color("#d9a82b"), Color("#f2efe8")][(j + k) % 3]
			var br := 0.48 - 0.03 * k
			_frustum(_circle(p, br * 0.7, 8), y0 - br * 0.9, _circle(p, br, 8), y0 - br * 0.3, col)
			_frustum(_circle(p, br, 8), y0 - br * 0.3, _circle(p, br * 0.6, 8), y0 + br * 0.5, col, col)
	# The strands down the cone, blue at night.
	_no_roof = true
	for j in 16:
		var t := TAU * (float(j) + 0.25) / 16.0
		var foot := c + Vector2(cos(t), sin(t)) * 4.75
		_beam(Vector3(c.x, apex - 0.4, c.y), Vector3(foot.x, g0 + 0.55, foot.y), 0.07, JM_FIR.lightened(0.15), false, M_LAMP + 0.5)
	_no_roof = false
	_jm_star(Vector3(c.x, apex + 0.9, c.y), 1.1, Vector3(_a.x, 0.0, _a.y), JM_GOLD)
	_jm_star(Vector3(c.x, apex + 0.9, c.y), 1.1, Vector3(_b.x, 0.0, _b.y), JM_GOLD)
	_collide(_circle(c, 7.5, 12))


## A five-pointed star of radius r in the upright plane along `side`, lit, seen from both faces.
func _jm_star(c: Vector3, r: float, side: Vector3, col: Color) -> void:
	var keep := _mode
	_mode = M_LAMP
	var n := side.cross(Vector3.UP).normalized()
	var pts: Array[Vector3] = []
	for k in 10:
		var t := PI * 0.5 + TAU * float(k) / 10.0
		var rr := r if k % 2 == 0 else r * 0.42
		pts.append(c + (side.normalized() * cos(t) + Vector3.UP * sin(t)) * rr)
	for k in 10:
		var a := pts[k]
		var b := pts[(k + 1) % 10]
		var off := n * 0.06
		_tri(c + off, a + off, b + off, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
		_tri(c - off, b - off, a - off, -n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = keep


## A yellow bench at a local spot of the market (u, v), facing the tree (angle t round it).
func _jm_bench(at: Vector2, t: float) -> void:
	_jm_frame()
	var p := _w(at.x, at.y)
	var g: float = map.terrain_height(p.x, p.y)
	var out := (_a * cos(t) + _b * sin(t)).normalized()
	var d := Vector2(-out.y, out.x)
	_pow_box(p, d, 0.95, 0.24, g + 0.4, g + 0.5, JM_YELLOW, JM_YELLOW.lightened(0.1))
	_pow_box(p + out * 0.22, d, 0.95, 0.05, g + 0.5, g + 0.95, JM_YELLOW, JM_YELLOW)
	for s: float in [-0.8, 0.8]:
		_pow_box(p + d * s, d, 0.06, 0.2, g, g + 0.4, Color("#9a7a2a"), Color("#9a7a2a"))


## The snowman lit white: three balls, a black hat, a carrot nose.
func _jm_snowman(u: float, v: float) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	var balls := [[1.0, 0.0, 1.7], [0.75, 1.6, 2.8], [0.52, 2.75, 3.7]]
	for b: Array in balls:
		var r: float = b[0]
		var y0: float = g + float(b[1])
		var y1: float = g + float(b[2])
		var ym := (y0 + y1) * 0.5
		_frustum(_circle(c, r * 0.55, 10), y0, _circle(c, r, 10), ym, JM_LED)
		_frustum(_circle(c, r, 10), ym, _circle(c, r * 0.5, 10), y1, JM_LED, JM_LED)
	_prism(_circle(c, 0.6, 10), g + 3.68, g + 3.76, JM_TRIM, JM_TRIM)
	_prism(_circle(c, 0.36, 10), g + 3.76, g + 4.3, JM_TRIM, JM_TRIM)
	_jm_bar(u, v - 0.45, g + 3.2, u, v - 0.95, g + 3.15, 0.12, Color("#e87a24"))
	_collide(_circle(c, 1.0, 8))


## The Santa-hat photo spot (the drone frame): a 5 m teal LED hat with a white fur rim and pompom,
## a lit heart arch in front where people stand for the photo.
func _jm_hat(u: float, v: float) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	var teal := Color(0.14, 0.52, 0.66)
	_prism(_circle(c, 2.35, 14), g, g + 0.85, JM_LED, JM_LED, M_LAMP, M_LAMP)
	var tip := c + _a * 0.9
	_frustum(_circle(c, 2.0, 14), g + 0.85, _circle(tip, 0.35, 14), g + 4.6, teal)
	_frustum(_circle(tip, 0.35, 14), g + 4.6, _circle(tip + _a * 0.5, 0.15, 14), g + 4.9, teal)
	var pom := tip + _a * 0.75
	_prism(_circle(pom, 0.42, 8), g + 4.6, g + 5.4, JM_LED, JM_LED, M_LAMP, M_LAMP)
	# Re-draw the cone's skin as lit strands so it glows at night.
	_no_roof = true
	for k in 10:
		var t := TAU * float(k) / 10.0
		var f := c + Vector2(cos(t), sin(t)) * 2.02
		_beam(Vector3(f.x, g + 0.85, f.y), Vector3(tip.x, g + 4.6, tip.y), 0.08, teal.lightened(0.3), false, M_LAMP)
	# The heart in front.
	var hv := v - 3.0
	var pts: Array[Vector2] = []
	for k in 17:
		var t := TAU * float(k) / 16.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(Vector2(x, y) * 0.09)
	var hg := _jm_ground(u, hv)
	for k in 16:
		_jm_bar(u + pts[k].x, hv, hg + 1.6 + pts[k].y, u + pts[k + 1].x, hv, hg + 1.6 + pts[k + 1].y, 0.12,
				Color(1.0, 0.45, 0.62), M_LAMP)
	_jm_bar(u - 1.2, hv, hg, u - 1.2, hv, hg + 1.4, 0.1, JM_WIRE)
	_jm_bar(u + 1.2, hv, hg, u + 1.2, hv, hg + 1.4, 0.1, JM_WIRE)
	_no_roof = false
	_collide(_circle(c, 2.35, 8))


## The Venetian carousel (frame 004): a floor on a red plinth, a ring of gold posts, white horses on
## gold poles, the mirrored lit drum in the middle, the striped cream-and-red canopy with its lit
## valance and a gold finial, and light strings fanning from the top to poles round it.
func _jm_carousel(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 6.0, 16), g, g + 0.45, Color("#7a2228"), Color("#d8c9a6"), M_STONE, M_STONE)
	_prism(_circle(c, 1.3, 8), g + 0.45, g + 4.0, Color("#c99a48"), Color("#c99a48"), M_LAMP, M_STONE)
	_collide(_circle(c, 6.4, 12))
	# The strings fanning out from the top to poles 15 m round, skipping the side of the huts.
	for k in 12:
		var t := TAU * (float(k) + 0.5) / 12.0
		var p := at + Vector2(cos(t), sin(t)) * 15.0
		if p.y > 18.5 or p.y < -9.0:
			continue
		var top := _jm_pole(p.x, p.y, 4.0)
		_jm_string(Vector3(c.x, g + 6.9, c.y), top, 0.6)


## The Venetian carousel's turning part (jarmark_rides.gd turns it in its shader): `part` -1 the
## gold posts, the canopy with its lit valance and finial; 0-11 one horse on its pole, a rider on
## seven of them (the horses bob, so each is its own batch).
func _jm_carousel_spin(at: Vector2, part: int) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	if part < 0:
		for p: Vector2 in _circle(c, 5.5, 16):
			_beam(Vector3(p.x, g + 0.45, p.y), Vector3(p.x, g + 4.0, p.y), 0.16, JM_GOLD, false)
		var rim := _circle(c, 6.5, 16)
		_prism(rim, g + 3.9, g + 4.35, Color("#f3dfa8"), Color(0, 0, 0, 0), M_LAMP, M_STONE)
		var apex := Vector3(c.x, g + 6.8, c.y)
		_mode = M_STONE
		for k in rim.size():
			var a := rim[k]
			var b := rim[(k + 1) % rim.size()]
			var pa := Vector3(a.x, g + 4.35, a.y)
			var pb := Vector3(b.x, g + 4.35, b.y)
			var nrm := (pb - pa).cross(apex - pa).normalized()
			if Vector2(nrm.x, nrm.z).dot((a + b) * 0.5 - c) < 0.0:
				nrm = -nrm
			_tri(pa, pb, apex, nrm, Color("#efe6d2") if k % 2 == 0 else Color("#b3262d"), Vector2(-1, -1), Vector2(-1, -1),
					Vector2(-1, -1), -1.0, false)
		_frustum(_circle(c, 0.35, 8), g + 6.6, _circle(c, 0.12, 8), g + 7.6, JM_GOLD, JM_GOLD)
		_prism(_circle(c, 0.22, 6), g + 7.6, g + 7.95, JM_BULB, JM_BULB, M_LAMP, M_LAMP)
		return
	var k := part
	var t := TAU * float(k) / 12.0
	var r := 4.2 if k % 2 == 0 else 2.9
	var p := c + Vector2(cos(t), sin(t)) * r
	var d := Vector2(-sin(t), cos(t))
	var hy := g + 1.4 + 0.3 * float(k % 3)
	_beam(Vector3(p.x, g + 0.45, p.y), Vector3(p.x, g + 4.0, p.y), 0.06, JM_GOLD, false)
	var tail := p - d * 0.55
	var head := p + d * 0.55
	_beam(Vector3(tail.x, hy, tail.y), Vector3(head.x, hy, head.y), 0.42, Color("#f4f1ea"), false)
	_beam(Vector3(head.x, hy, head.y), Vector3(head.x + d.x * 0.25, hy + 0.55, head.y + d.y * 0.25), 0.22, Color("#f4f1ea"), false)
	_beam(Vector3(p.x, hy + 0.2, p.y), Vector3(p.x, hy + 0.3, p.y), 0.44, [JM_RED, JM_BLUE, JM_GOLD][k % 3], false)
	if k % 12 in [0, 1, 3, 4, 6, 8, 10]:
		_jm_rider(p - d * 0.1, d, hy + 0.3, k)

## A red stand (the sausage stand, the mulled-wine bar): a red box with white trim, counters lit on
## three sides, a dark red gable roof, and its word in white on a red board on two posts above.
func _jm_redbar(u: float, v: float, hu: float, hv: float, word: String) -> void:
	var g := _jm_at(u, v, 0)
	var h := 2.9
	_lbox(0.0, 0.0, hu, hv, g, g + h, JM_RED, M_STONE, JM_RED.darkened(0.1))
	_ubox(-hu + 0.3, hu - 0.3, -hv - 0.03, -hv, g + 1.05, g + 2.5, JM_GLOW, M_LAMP)
	_ubox(-hu - 0.03, -hu, -hv + 0.3, hv - 0.3, g + 1.05, g + 2.5, JM_GLOW, M_LAMP)
	_ubox(hu, hu + 0.03, -hv + 0.3, hv - 0.3, g + 1.05, g + 2.5, JM_GLOW, M_LAMP)
	_ubox(-hu, hu, -hv - 0.45, -hv, g + 0.93, g + 1.03, JM_WHITE, M_STONE)
	for su: float in [-hu, hu - 0.14]:
		_ubox(su, su + 0.14, -hv - 0.04, hv + 0.04, g, g + h - 0.05, JM_WHITE, M_STONE)
	_gable(hu + 0.25, -hu - 0.25, 0.0, hv + 0.45, g + h, 1.2, JM_RED, Color("#7a1c20"), true)
	_no_roof = true
	_jm_bar(-hu - 0.2, -hv - 0.42, g + h - 0.15, hu + 0.2, -hv - 0.42, g + h - 0.15, 0.07, JM_BULB, M_LAMP)
	_no_roof = false
	# The board.
	var by := g + h + 1.6
	var bw := _jm_word_w(word, 0.55) + 0.8
	for su: float in [-bw * 0.4, bw * 0.4]:
		_ubox(su - 0.06, su + 0.06, -0.06, 0.06, g + h + 0.6, by, JM_TRIM, M_STONE)
	_ubox(-bw * 0.5, bw * 0.5, -0.12, 0.12, by, by + 1.1, JM_RED.darkened(0.1), M_STONE)
	_jm_word(word, 0.0, -0.13, by + 0.3, 0.55, JM_WHITE, M_LAMP)
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	_jm_frame()


## A word in solid pixel blocks on the current local frame's -v face at v, centred on u, its body's
## bottom at y and `h` tall. The reader faces +v, so their left-to-right runs along -u.
func _jm_word_w(text: String, h: float) -> float:
	var w := 0.0
	for ch in text:
		w += (_pow_glyph_w(ch) + 1) * h / 7.0
	return w - h / 7.0


func _jm_word(text: String, u: float, v: float, y: float, h: float, col: Color, mode: float) -> void:
	var sx := h / 7.0
	var width := 0.0
	for ch in text:
		width += (_pow_glyph_w(ch) + 1) * sx
	width -= sx
	var at := u + width * 0.5
	for ch in text:
		if ch == " ":
			at -= (_pow_glyph_w(ch) + 1) * sx
			continue
		var lit := {}
		for q: Vector2i in _pow_glyph(ch):
			lit[q] = true
		for q: Vector2i in lit:
			if lit.has(q - Vector2i(1, 0)):
				continue
			var e := q
			while lit.has(e + Vector2i(1, 0)):
				e += Vector2i(1, 0)
			var row := PixelFont.BODY + 6 - q.y
			_ubox(at - (e.x + 1) * sx, at - q.x * sx, v - 0.08, v, y + row * sx, y + (row + 1) * sx, col, mode)
		at -= (_pow_glyph_w(ch) + 1) * sx


## The glass greenhouse tunnel at the south end (the drone frame): a half-round glass vault along v,
## lit warm from inside, white ribs every 1.5 m, glass ends.
func _jm_greenhouse(u: float, v0: float, v1: float) -> void:
	_jm_frame()
	var r := 2.6
	var g := _jm_ground(u, (v0 + v1) * 0.5)
	_g = g
	var segs := 8
	var keep := _mode
	_mode = M_PAVILION + 0.75
	var run := 0.0
	for k in segs:
		var t0 := PI * float(k) / segs
		var t1 := PI * float(k + 1) / segs
		var a0 := Vector2(u + r * cos(t0), g + r * sin(t0) + 0.4)
		var a1 := Vector2(u + r * cos(t1), g + r * sin(t1) + 0.4)
		var p0 := _jm_p(a0.x, v0, a0.y)
		var p1 := _jm_p(a1.x, v0, a1.y)
		var p2 := _jm_p(a1.x, v1, a1.y)
		var p3 := _jm_p(a0.x, v1, a0.y)
		var mid := (t0 + t1) * 0.5
		var nl := Vector2(cos(mid), sin(mid))
		var nrm := Vector3(_a.x * nl.x, nl.y, _a.y * nl.x).normalized()
		var l := a0.distance_to(a1)
		var len_v := v1 - v0
		_quad(p0, p3, p2, p1, nrm, Color("#b9d2c8"), Vector2(0.0, 0.4 + run), Vector2(len_v, 0.4 + run),
				Vector2(len_v, 0.4 + run + l), Vector2(0.0, 0.4 + run + l), 0.4 + PI * r)
		run += l
	_mode = keep
	# The ribs and the knee walls.
	var vv := v0
	while vv <= v1 + 0.01:
		for k in segs:
			var t0 := PI * float(k) / segs
			var t1 := PI * float(k + 1) / segs
			_jm_bar(u + r * cos(t0), vv, g + 0.4 + r * sin(t0), u + r * cos(t1), vv, g + 0.4 + r * sin(t1), 0.08, JM_WHITE)
		vv += 1.5
	_ubox(u - r, u - r + 0.15, v0, v1, g, g + 0.4, JM_WHITE, M_STONE)
	_ubox(u + r - 0.15, u + r, v0, v1, g, g + 0.4, JM_WHITE, M_STONE)
	_ubox(u - r, u + r, v0 - 0.1, v0, g, g + 2.2, Color("#cfe0d8"), M_PAVILION + 0.75)
	_ubox(u - r, u + r, v1, v1 + 0.1, g, g + 2.2, Color("#cfe0d8"), M_PAVILION + 0.75)
	_collide(_urect(u - r, u + r, v0, v1))


## The two-storey hexagonal bar (nm-75, nm-76): a red six-sided bar with a lit counter round it and
## a white band, a smaller red storey above with its own lights, a red pyramid roof and a gold star.
func _jm_hexbar(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 3.3, 6), g, g + 1.0, JM_RED, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_circle(c, 3.32, 6), g + 1.0, g + 1.12, JM_WHITE, JM_WHITE, M_STONE, M_STONE)
	_prism(_circle(c, 3.0, 6), g + 1.12, g + 2.5, JM_GLOW, Color(0, 0, 0, 0), M_LAMP, M_STONE)
	_prism(_circle(c, 3.4, 6), g + 2.5, g + 3.05, JM_WHITE, JM_WHITE, M_STONE, M_STONE)
	_prism(_circle(c, 2.1, 6), g + 3.05, g + 5.2, JM_RED, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_circle(c, 2.12, 6), g + 3.9, g + 4.7, JM_GLOW, Color(0, 0, 0, 0), M_LAMP, M_STONE)
	_pyramid(_circle(c, 2.7, 6), g + 5.2, g + 7.6, Color("#8e1c22"))
	_no_roof = true
	for ring: Array in [[3.45, g + 3.0], [2.75, g + 5.15]]:
		var pts := _circle(c, ring[0], 6)
		for k in 6:
			var a := pts[k]
			var b := pts[(k + 1) % 6]
			_beam(Vector3(a.x, ring[1], a.y), Vector3(b.x, ring[1], b.y), 0.08, JM_BULB, false, M_LAMP)
	_no_roof = false
	_jm_star(Vector3(c.x, g + 8.05, c.y), 0.6, Vector3(_a.x, 0.0, _a.y), JM_GOLD)
	_collide(_circle(c, 3.4, 6))


## The stage on the Palace side (the drone frame): a white pavilion open to the market, its back
## wall lit cool, a lit truss along the front, light-up trees on both sides, SCENA in gold above.
func _jm_stage(at: Vector2) -> void:
	var g := _jm_at(at.x, at.y, 0)
	var hu := 7.0
	var hv := 3.5
	_lbox(0.0, 0.4, hu, hv - 0.4, g, g + 0.9, Color("#3a3c40"), M_STONE, Color("#4a4c50"))
	_lbox(0.0, hv - 0.15, hu, 0.15, g + 0.9, g + 4.92, Color("#c8d4f0"), M_PAVILION + 0.5, Color("#e8e8e4"))
	for su: float in [-hu + 0.15, hu - 0.15]:
		_lbox(su, 0.0, 0.15, hv, g, g + 4.97, JM_WHITE, M_STONE, JM_WHITE)
	_lbox(0.0, 0.0, hu + 0.2, hv + 0.2, g + 5.0, g + 5.5, JM_WHITE, M_STONE, Color("#dcdad4"))
	_no_roof = true
	_jm_bar(-hu, -hv - 0.25, g + 4.8, hu, -hv - 0.25, g + 4.8, 0.22, JM_LED, M_LAMP)
	for su: float in [-hu, hu]:
		_jm_bar(su, -hv - 0.25, g + 0.9, su, -hv - 0.25, g + 4.8, 0.14, JM_LED, M_LAMP)
	_no_roof = false
	_jm_word("SCENA", 0.0, -hv - 0.2, g + 5.5, 1.1, JM_GOLD, M_LAMP)
	_collide(_rect(0.0, 0.0, hu + 0.2, hv + 0.2))
	_jm_frame()
	_jm_ledtree(at.x - 9.0, at.y - 3.0, 3.8)
	_jm_ledtree(at.x + 9.0, at.y - 3.0, 3.8)


## A red or green barrel standing table.
func _jm_barrel(u: float, v: float, col: Color) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_frustum(_circle(c, 0.32, 8), g, _circle(c, 0.38, 8), g + 0.55, col)
	_frustum(_circle(c, 0.38, 8), g + 0.55, _circle(c, 0.33, 8), g + 1.05, col, Color("#5a3a24"))
	_prism(_circle(c, 0.39, 8), g + 0.3, g + 0.36, JM_TRIM, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_circle(c, 0.39, 8), g + 0.8, g + 0.86, JM_TRIM, Color(0, 0, 0, 0), M_STONE, M_STONE)


## The low black mesh fence along Marszałkowska, posts every 2.5 m, two rails, open at the gates.
func _jm_fence(u0: float, u1: float, v: float, gaps: Array) -> void:
	_jm_frame()
	var u := u0
	while u < u1:
		var nu := minf(u + 2.5, u1)
		var open := false
		for gp: Array in gaps:
			if nu > float(gp[0]) and u < float(gp[1]):
				open = true
		if not open:
			var g0 := _jm_ground(u, v)
			var g1 := _jm_ground(nu, v)
			_jm_bar(u, v, g0, u, v, g0 + 1.2, 0.08, JM_WIRE)
			_jm_bar(u, v, g0 + 1.15, nu, v, g1 + 1.15, 0.1, JM_WIRE)
			_jm_bar(u, v, g0 + 0.15, nu, v, g1 + 0.15, 0.1, JM_WIRE)
			_ubox(u, nu, v - 0.02, v + 0.02, minf(g0, g1) + 0.15, minf(g0, g1) + 1.15, Color("#55595d"), M_STONE)
			_collide(_urect(u, nu, v - 0.1, v + 0.1))
		u = nu


## A white banner on the fence: JARMARK over WARSZAWSKI in dark red, facing the street.
func _jm_banner(u: float, v: float) -> void:
	_jm_frame()
	var g := _jm_ground(u, v)
	_ubox(u - 2.6, u + 2.6, v - 0.06, v, g + 0.3, g + 1.75, JM_WHITE, M_STONE)
	_ubox(u + 1.7, u + 2.5, v - 0.08, v - 0.06, g + 0.5, g + 1.55, JM_RED, M_STONE)
	_jm_word("JARMARK", u - 0.4, v - 0.06, g + 1.1, 0.45, JM_RED, M_STONE)
	_jm_word("WARSZAWSKI", u - 0.4, v - 0.06, g + 0.5, 0.42, JM_TRIM, M_STONE)


## The gold WESOŁYCH ŚWIĄT sign (the drone frames): the words on a gold arched frame on two posts,
## blue stars along the top, facing the street (-v).
func _jm_greeting(u: float, v: float) -> void:
	var g := _jm_at(u, v, 0)
	_no_roof = true
	_jm_word("WESOŁYCH", 0.0, 0.0, g + 3.3, 1.2, JM_GOLD, M_LAMP)
	_jm_word("ŚWIĄT", 0.0, 0.0, g + 1.0, 2.0, JM_GOLD, M_LAMP)
	var hw := 5.2
	for s: float in [-1.0, 1.0]:
		_ubox(s * hw - 0.06, s * hw + 0.06, 0.0, 0.12, g, g + 4.6, JM_WIRE, M_STONE)
	# The rails the letters stand on, post to post.
	_ubox(-hw, hw, -0.02, 0.1, g + 0.88, g + 1.0, JM_WIRE, M_STONE)
	_ubox(-hw, hw, -0.02, 0.1, g + 3.18, g + 3.3, JM_WIRE, M_STONE)
	var prev := Vector2(-hw, 4.5)
	for k in range(1, 15):
		var t := float(k) / 14.0
		var x := lerpf(-hw, hw, t)
		var y := 4.5 + 1.2 * sin(PI * t)
		_jm_bar(prev.x, 0.04, g + prev.y, x, 0.04, g + y, 0.14, JM_GOLD, M_LAMP)
		prev = Vector2(x, y)
	for k in 7:
		var t := (float(k) + 0.5) / 7.0
		var x := lerpf(-hw + 0.4, hw - 0.4, t)
		var sr := 0.5 if k % 2 == 0 else 0.34
		var y := 4.5 + 1.2 * sin(PI * t) + sr * 0.75
		_jm_star(_jm_p(x, 0.0, g + y), sr, Vector3(_a.x, 0.0, _a.y), JM_BLUE)
	_no_roof = false
	_collide(_rect(0.0, 0.0, hw + 0.1, 0.3))
	_jm_frame()


## A light-up tree on a short pole: three tiers of white LED, glowing at night, h metres tall.
func _jm_ledtree(u: float, v: float, h: float) -> void:
	_jm_frame()
	var c := _w(u, v)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	_beam(Vector3(c.x, g, c.y), Vector3(c.x, g + 0.8, c.y), 0.1, JM_WIRE)
	var r := h * 0.3
	var keep := _mode
	_mode = M_LAMP
	for k in 3:
		var y0 := g + 0.8 + h * 0.3 * k
		var r0 := r * (1.0 - 0.28 * k)
		_frustum(_circle(c, r0, 8), y0, _circle(c, r0 * 0.25, 8), y0 + h * 0.42, Color(0.78, 0.84, 0.92))
	_mode = keep
	_no_roof = false


## A big standing star of warm white tubes on a post (the drone frame by the entrance).
func _jm_bigstar(u: float, v: float, r: float) -> void:
	_jm_frame()
	var g := _jm_ground(u, v)
	_no_roof = true
	var cy := g + 1.2 + r
	_jm_bar(u, v + 0.08, g, u, v + 0.08, cy, 0.12, JM_WIRE)
	var prev := Vector2.ZERO
	for k in 11:
		var t := PI * 0.5 + TAU * float(k) / 10.0
		var rr := r if k % 2 == 0 else r * 0.42
		var p := Vector2(cos(t), sin(t)) * rr
		if k > 0:
			_jm_bar(u + prev.x, v, cy + prev.y, u + p.x, v, cy + p.y, 0.12, JM_BULB, M_LAMP)
		prev = p
	_no_roof = false


## The viewing tower carousel (nm-02, nm-12, the Palace's reel at night): a 38 m mast in rainbow LED
## bands on a round lit base, the gold carrier at 26 m with sixteen lit white spokes and chairs
## swinging out on chains, the orange crown on top.
func _jm_tower(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 5.0, 16), g, g + 0.6, Color("#d6d2ca"), Color("#c6c0b5"), M_STONE, M_STONE)
	_prism(_circle(c, 1.6, 8), g + 0.6, g + 2.2, Color("#3a3c40"), Color("#3a3c40"), M_STONE, M_STONE)
	_no_roof = true
	var ring := _circle(c, 4.75, 16)
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		_beam(Vector3(a.x, g + 0.66, a.y), Vector3(b.x, g + 0.66, b.y), 0.08, JM_RAINBOW[k % 7], false, M_LAMP)
		_beam(Vector3(a.x, g + 0.6, a.y), Vector3(a.x, g + 1.7, a.y), 0.06, JM_WIRE, false)
		_beam(Vector3(a.x, g + 1.7, a.y), Vector3(b.x, g + 1.7, b.y), 0.06, JM_WIRE, false)
	_no_roof = false
	# The mast in rainbow bands.
	var y := g + 2.2
	var top := g + 38.0
	var k := 0
	while y < top - 0.01:
		var y1 := minf(y + 1.8, top)
		_prism(_circle(c, 0.72, 8), y, y1, JM_RAINBOW[k % 7], Color(0, 0, 0, 0), M_LAMP, M_STONE)
		y = y1
		k += 1
	# The crown.
	_frustum(_circle(c, 0.8, 8), top, _circle(c, 1.7, 8), top + 1.3, Color("#f09a28"), Color("#f09a28"))
	_no_roof = true
	var crown := _circle(c, 1.7, 8)
	for p: Vector2 in crown:
		_beam(Vector3(p.x, top + 1.3, p.y), Vector3(p.x, top + 2.2, p.y), 0.16, JM_GOLD, false, M_LAMP)
	_no_roof = false
	_prism(_circle(c, 0.5, 8), top + 1.3, top + 2.4, JM_GOLD, JM_GOLD, M_LAMP, M_LAMP)
	_collide(_circle(c, 5.0, 12))
	# The ticket booth.
	_jm_hut(at.x + 7.5, at.y - 2.0, 3, Hut.RED, 0)


## The tower carousel's carrier (jarmark_rides.gd turns it and runs it up and down the mast): a
## gold bowl under a gold dome, bulbs round its belly, sixteen lit spokes, the chairs on their
## chains swung out to 10 m, a rider in twelve of them. Built at the top (26 m).
func _jm_tower_spin(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	var yc := g + TOWER_TOP
	_frustum(_circle(c, 1.0, 16), yc - 2.0, _circle(c, 3.4, 16), yc, JM_GOLD)
	_frustum(_circle(c, 3.4, 16), yc, _circle(c, 1.0, 16), yc + 1.4, JM_GOLD, JM_GOLD)
	for p: Vector2 in _circle(c, 3.0, 16):
		_prism(_circle(p, 0.1, 4), yc - 0.6, yc - 0.4, JM_LED, JM_LED, M_LAMP, M_LAMP)
	var chair_cols := [JM_YELLOW, JM_RED, JM_BLUE, Color("#3fb24f")]
	for j in 16:
		var t := TAU * (float(j) + 0.5) / 16.0
		var d := Vector2(cos(t), sin(t))
		var hub := c + d * 1.0
		var mid := c + d * 3.3
		var tip := c + d * 7.8
		_beam(Vector3(hub.x, yc + 1.4, hub.y), Vector3(tip.x, yc - 0.3, tip.y), 0.14, JM_LED, false, M_LAMP)
		_beam(Vector3(mid.x, yc, mid.y), Vector3(tip.x, yc - 0.3, tip.y), 0.08, JM_LED, false)
		var seat := c + d * 10.0
		var sy := yc - 6.0
		var side := Vector2(-d.y, d.x) * 0.3
		_beam(Vector3(tip.x + side.x, yc - 0.3, tip.y + side.y), Vector3(seat.x + side.x, sy + 0.6, seat.y + side.y), 0.03, JM_WIRE, false)
		_beam(Vector3(tip.x - side.x, yc - 0.3, tip.y - side.y), Vector3(seat.x - side.x, sy + 0.6, seat.y - side.y), 0.03, JM_WIRE, false)
		var col: Color = chair_cols[j % 4]
		_pow_box(seat, Vector2(-d.y, d.x), 0.3, 0.28, sy, sy + 0.12, col, col, M_LAMP)
		_pow_box(seat - d * 0.26, Vector2(-d.y, d.x), 0.3, 0.04, sy, sy + 0.6, col, col, M_LAMP)
		if j % 4 != 3:
			_jm_rider(seat - d * 0.08, Vector2(-d.y, d.x), sy + 0.12, j)


## The teacups (the PIK article's list): a blue platform with a lit rim, six white cups with blue
## bands on saucers, the big teapot in the middle.
func _jm_teacups(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 6.0, 16), g, g + 0.35, Color("#2e5fa8"), Color("#e6ecf4"), M_STONE, M_STONE)
	_prism(_circle(c, 6.03, 16), g + 0.2, g + 0.32, JM_LED, Color(0, 0, 0, 0), M_LAMP, M_STONE)
	_frustum(_circle(c, 1.0, 12), g + 0.35, _circle(c, 1.7, 12), g + 1.6, Color("#f4f2ee"))
	_frustum(_circle(c, 1.7, 12), g + 1.6, _circle(c, 0.9, 12), g + 2.8, Color("#f4f2ee"), Color("#f4f2ee"))
	_prism(_circle(c, 0.25, 8), g + 2.8, g + 3.2, Color("#3a6fc0"), Color("#3a6fc0"), M_STONE, M_STONE)
	_beam(_jm_p(at.x + 1.5, at.y, g + 1.6), _jm_p(at.x + 2.6, at.y, g + 2.6), 0.3, Color("#3a6fc0"))
	_beam(_jm_p(at.x - 1.6, at.y, g + 2.3), _jm_p(at.x - 2.2, at.y, g + 1.7), 0.18, Color("#3a6fc0"))
	_collide(_circle(c, 6.0, 12))


## The teacups' turning part (jarmark_rides.gd): six white cups with blue bands on their saucers,
## two riders in each, going round the teapot.
func _jm_teacups_spin(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	for k in 6:
		var t := TAU * float(k) / 6.0
		var p := c + Vector2(cos(t), sin(t)) * 3.9
		var col := Color("#f4f2ee")
		_prism(_circle(p, 1.3, 12), g + 0.35, g + 0.45, Color("#3a6fc0"), Color("#3a6fc0"), M_STONE, M_STONE)
		_frustum(_circle(p, 0.75, 12), g + 0.45, _circle(p, 1.15, 12), g + 1.35, col, Color("#7a4a30"))
		_prism(_circle(p, 1.17, 12), g + 1.05, g + 1.2, Color("#3a6fc0"), Color(0, 0, 0, 0), M_STONE, M_STONE)
		var d := Vector2(cos(t + 0.7 * k), sin(t + 0.7 * k))
		_jm_rider(p + d * 0.4, Vector2(-d.y, d.x), g + 0.75, k * 2)
		_jm_rider(p - d * 0.4, Vector2(-d.y, d.x), g + 0.75, k * 2 + 1)

## The Christmas-tree carousel: a red floor, little red sleighs hanging from a green tree-shaped
## canopy in three tiers with lit rims, a star on top.
func _jm_tree_ride(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_prism(_circle(c, 4.6, 16), g, g + 0.35, JM_RED, Color("#e2d6be"), M_STONE, M_STONE)
	_prism(_circle(c, 0.5, 8), g + 0.35, g + 3.2, JM_TIMBER, JM_TIMBER, M_STONE, M_STONE)
	_collide(_circle(c, 4.6, 12))


## The Christmas-tree carousel's turning part (jarmark_rides.gd): the tree-shaped canopy in three
## tiers with lit rims, the star, and eight little red sleighs on gold rods, a child in five.
func _jm_tree_ride_spin(at: Vector2) -> void:
	_jm_frame()
	var c := _w(at.x, at.y)
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_no_roof = true
	for k in 3:
		var y0 := g + 3.0 + k * 1.7
		var r0 := 4.8 - 1.3 * k
		_frustum(_circle(c, r0, 16), y0, _circle(c, r0 * 0.35, 16), y0 + 2.2, JM_FIR, JM_FIR)
		var rim := _circle(c, r0, 16)
		for j in rim.size():
			var a := rim[j]
			var b := rim[(j + 1) % rim.size()]
			_beam(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), 0.08, JM_BULB, false, M_LAMP)
	_jm_star(Vector3(c.x, g + 9.0, c.y), 0.6, Vector3(_a.x, 0.0, _a.y), JM_GOLD)
	for k in 8:
		var t := TAU * float(k) / 8.0
		var d := Vector2(cos(t), sin(t))
		var p := c + d * 3.5
		_beam(Vector3(p.x, g + 3.0, p.y), Vector3(p.x, g + 1.5, p.y), 0.04, JM_GOLD, false)
		_pow_box(p, Vector2(-d.y, d.x), 0.55, 0.35, g + 0.8, g + 1.5, JM_RED, Color("#7a1c20"))
		if k % 8 in [0, 2, 3, 5, 6]:
			_jm_rider(p, Vector2(-d.y, d.x), g + 1.0, k + 3, 0.7)


## A rider (jarmark_rides.gd's rides): a shirt and a head, `n` picks the colours, `s` scales a child.
func _jm_rider(p: Vector2, d: Vector2, y: float, n: int, s := 1.0) -> void:
	var shirt: Color = JM_SHIRTS[n % JM_SHIRTS.size()]
	var skin: Color = [Color("#e8c4a4"), Color("#d6a882"), Color("#b98463"), Color("#f0d2b8")][n % 4]
	var hair: Color = [Color("#2a2420"), Color("#6b4a2e"), Color("#c9a25a"), Color("#3a2a22"), Color("#d8d4cc")][n % 5]
	if n % 3 == 0:
		hair = [JM_RED, Color("#f4f2ee"), JM_BLUE][n % 9 / 3]  # a winter hat
	_pow_box(p, d, 0.19 * s, 0.12 * s, y, y + 0.52 * s, shirt, shirt)
	_pow_box(p, d, 0.1 * s, 0.1 * s, y + 0.52 * s, y + 0.74 * s, skin, hair)

## Santa's house: a log cabin with snow on the roof, a red door, warm windows, a brick chimney and
## DOM MIKOŁAJA in gold over the door, facing the field (-u... turned to face +v towards the rides).
func _jm_santa(at: Vector2) -> void:
	var g := _jm_at(at.x, at.y, 3)
	var hu := 3.0
	var hv := 2.4
	var logc := Color("#7a4a2a")
	_lbox(0.0, 0.0, hu, hv, g, g + 2.8, logc, M_STONE, logc.darkened(0.1))
	var y := g + 0.3
	while y < g + 2.8:
		_ubox(-hu - 0.06, hu + 0.06, -hv - 0.06, -hv, y, y + 0.1, logc.darkened(0.35), M_STONE)
		_ubox(-hu - 0.06, -hu, -hv, hv, y, y + 0.1, logc.darkened(0.35), M_STONE)
		_ubox(hu, hu + 0.06, -hv, hv, y, y + 0.1, logc.darkened(0.35), M_STONE)
		y += 0.36
	_gable(hu + 0.4, -hu - 0.4, 0.0, hv + 0.5, g + 2.8, 1.8, logc, JM_WHITE, true)
	_ubox(-0.55, 0.55, -hv - 0.1, -hv - 0.06, g, g + 2.0, JM_RED, M_STONE)
	for su: float in [-2.0, 2.0]:
		_ubox(su - 0.5, su + 0.5, -hv - 0.1, -hv - 0.06, g + 1.0, g + 2.0, JM_GLOW.lightened(0.15), M_LAMP)
	_ubox(1.4, 2.1, 0.5, 1.2, g + 3.5, g + 5.2, Color("#8a3a2c"), M_STONE, Color("#3a3a3a"))
	_jm_word("DOM MIKOŁAJA", 0.0, -hv - 0.6, g + 2.95, 0.45, JM_GOLD, M_LAMP)
	_collide(_rect(0.0, 0.0, hu + 0.1, hv + 0.1))
	_jm_frame()
