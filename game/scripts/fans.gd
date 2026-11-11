extends Node3D
## Kibice (F's idea 7, 2026-11-02; docs/design/city-life-satire.md "7 Legia fans"): friendly football
## fans outside Stadion Leguminy (landmarks.gd `legia`, ul. Łazienkowska) on match evenings. Funny,
## never harmful: scarves, a drum, a banner with a soft joke, hand-held pink "smoke" (a puff, no fire,
## no weapons), a kid with a giant foam finger and a patrol car parked by the gate whose officer only
## drinks a coffee. No crest, no club name, no real chant, nothing about other fans: colours only.
##  - **When**: `match_on`: Wednesday 17:00-21:30, Saturday 15:00-21:30, Sunday 14:00-20:30 (the
##    game clock); --fans-now has them out at any hour.
##  - **Where**: three groups (`GROUPS`) on the footways round the stadium: the north gate and the
##    north-east corner on Łazienkowska, and the south side by the bridge approach (Trasa
##    Łazienkowska). Each group stands on the pavement nearest its anchor and on the open ground
##    on whichever side of it has more room (never on a road, never inside a building), a banner
##    on two poles at the back (its words on both faces), the drummer at the side, two smoke
##    holders and the kid at the front, everyone facing away from the banner.
##  - **The chant**: every CHANT_GAP s a group sings for CHANT_LEN s: everyone jumps on the drum's
##    beat and the scarves go up over the heads; between chants they sway, scarves round the neck.
##    The player's horn within HONK_R m starts a chant at once (and a `honk` line).
##  - **Lines** (`kibice` in data/dialogue.json, `police_kibice` for Sierżant Bogdan): a chant line
##    when a chant starts on screen, chat between, `car` for a slow car by a group, `kid` now and
##    then from the kid; a toast the first time the car meets the fans.
##  - **Sound**: city_sounds.gd's `chant` kind (the fan_chant loop, tools/make_sfx.py) at each group
##    while it is out.
##  - **Match day** (follow-up, 2026-11-02): kick-off is KICK_AFTER h into the evening (`phase_at`).
##    In the ARRIVE h before it fans walk (`ROUTES`) from the bus stops by the Trasa Łazienkowska
##    and along Łazienkowska and Czerniakowska to the groups, more as kick-off nears, the last few
##    running late; from FULL_TIME h after kick-off, for LEAVE h, they stream back the other way.
##    The result is a win or a draw (never a loss: the joke is warm), rolled at full time: a win
##    has the groups sing twice as often, scarves up on the way home and `win` lines; a draw has
##    "następnym razem" (`draw`). The routes are found once on the footways and zebras (AStar2D).
##  - **Making way** (follow-up, 2026-11-02): walkers and the groups' fans step out of the player's
##    car's path (`dodge_target`), hop aside with the scarves up when it is fast (a `dodge` line),
##    walk round it when it stands, and step back after. During the match most of each group goes
##    in (`group_share`): the drummer and a few stay out with a radio (`match` lines), no smoke.
## Drawing: the fans one MultiMesh (the pedestrians' person mesh), their props one (a four-shape
## family: a scarf held up, a scarf round the neck, the officer's coffee, the foam finger), the smoke
## puffs one, and the three groups' banners, drums and smoke sticks one mesh, the walkers one more
## (the person mesh with the walking legs; their scarves join the props): +5 draw calls while the
## view is within ACTIVE_R of the stadium on a match evening (+4 when nobody walks), nothing otherwise. No sun shadow, no
## collision (like the coffee raves). The logic ticks at 2 Hz, the figures move at 10 Hz while near.
## The rules are static functions (check_fans.gd runs them on synthetic clocks and the real map).

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Crowds := preload("res://scripts/crowds.gd")
const CityLife := preload("res://scripts/city_life.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const TICK := 0.5
## The figures move at 10 Hz (a walker steps 13 cm a move: about a pixel at the phone's zoom).
const MOVE_TICK := 0.1
## Stadion Leguminy's middle (landmarks.gd LEGIA_AT): the view within ACTIVE_R of it draws the fans.
const STADIUM := Vector2(1139.0, 1500.0)
const ACTIVE_R := 420.0
## Match evenings by weekday (1 Monday .. 7 Sunday): [from, to) hours.
const MATCHES := {3: [17.0, 21.5], 6: [15.0, 21.5], 7: [14.0, 20.5]}
## The groups: an anchor on the map (local metres; snapped to the nearest pavement within SNAP m),
## the most fans, the banner's two lines, and whether the patrol car parks by it.
const GROUPS := {
	"brama": {"at": Vector2(1150.0, 1392.0), "n": 24, "banner": ["ZAWSZE WIERNI", "CZASEM PUNKTUALNI"], "police": true},
	"naroznik": {"at": Vector2(1285.0, 1398.0), "n": 18, "banner": ["MAMO, JESTEM", "W TELEWIZJI!"], "police": false},
	"trasa": {"at": Vector2(1140.0, 1606.0), "n": 16, "banner": ["WYNIK NIEWAŻNY", "KIEŁBASA WAŻNA"], "police": false},
}
const SNAP := 45.0
const MIN_STRETCH := 12.0
## A group's room: along the pavement ±HALF_BASE + HALF_PER a fan (m), back from the kerb side of the
## pavement to the forecourt up to DEEP m behind its far edge; fans GAP m apart at least.
const HALF_BASE := 4.0
const HALF_PER := 0.14
const DEEP := 4.5
const GAP := 0.62
## Clear of a road's edge by ROAD_CLEAR m.
const ROAD_CLEAR := 0.8
## The chant: a gap between two (s), its length (s), the jump (m) and its beat (jumps a second).
const CHANT_GAP := Vector2(14.0, 26.0)
const CHANT_LEN := 7.0
const JUMP := 0.26
const JUMP_HZ := 2.2
## The horn within HONK_R m starts a chant (not more often than HONK_GAP s a group).
const HONK_R := 45.0
const HONK_GAP := 10.0
## Lines: a group within LINE_VIEW of the view and on screen talks every LINE_GAP s; a car slower
## than CAR_KMH within CAR_NEAR m gets the `car` lines; MEET_R for the toast.
const LINE_VIEW := 140.0
const LINE_GAP := Vector2(16.0, 30.0)
const CAR_NEAR := 22.0
const CAR_KMH := 20.0
const MEET_R := 35.0
## The smoke: puffs per stick, how long a puff lives (s), how high it rises (m), its biggest size,
## and each stick lit for SMOKE_ON of every SMOKE_CYCLE seconds.
const PUFFS := 8
const PUFF_LIFE := 3.2
const PUFF_RISE := 3.6
const PUFF_SIZE := 1.0
const SMOKE_ON := 45.0
const SMOKE_CYCLE := 75.0
const WIND := Vector3(0.7, 0.0, 0.35)
## Match day: kick-off KICK_AFTER h after a window in MATCHES opens; walkers come in the ARRIVE h
## before it (the last LATE of that running) and go home from FULL_TIME h after it for LEAVE h.
const KICK_AFTER := 1.5
const ARRIVE := 1.4
const LATE := 0.08
const FULL_TIME := 1.9
const LEAVE := 0.7
## The walkers' routes: from a start on the map (snapped to the nearest footway) to a group, the
## most walking it at once. The bus stops' platforms by the Trasa Łazienkowska (there is no tram
## near the stadium on the map), the west end of Łazienkowska (from Agrykola and Myśliwiecka) and
## Czerniakowska from the south.
const ROUTES := {
	"przystanek_brama": {"from": Vector2(1331.0, 1234.0), "to": "brama", "n": 40},
	"przystanek_naroznik": {"from": Vector2(1331.0, 1234.0), "to": "naroznik", "n": 32},
	"lazienkowska": {"from": Vector2(822.0, 1349.0), "to": "brama", "n": 32},
	"czerniakowska": {"from": Vector2(1470.0, 1700.0), "to": "trasa", "n": 30},
}
## Footway graph: points every NODE_STEP m along each footway and zebra, joined to any other
## within JOIN m (mapped footways often stop short of the next); a route at most ROUTE_MAX m.
const NODE_STEP := 6.0
const JOIN := 4.0
const ROUTE_MAX := 700.0
## Walking (m/s, ± WALK_VAR), running late, and how far off the footway's middle (m).
const WALK_V := 1.35
const WALK_VAR := 0.2
const RUN_V := 3.0
const SIDE := 0.75
## Walkers' lines: one on screen within LINE_VIEW every WALK_LINE_GAP s.
const WALK_LINE_GAP := Vector2(14.0, 26.0)
## Making way for the car (follow-up, 2026-11-02): a fan (walking or in a group) whose spot the car
## will pass within DODGE_MISS m in the next DODGE_T s steps out sideways to DODGE_MISS + 0.4 m off
## its path (at most DODGE_MAX m) at STEP_OUT_V m/s, and back at STEP_BACK_V once it has gone; a
## stopped car is walked round at CAR_CLEAR m. Above SCATTER_KMH they hop aside (HOP m) faster,
## scarves up, and someone says a `dodge` line (at most one every DODGE_LINE_GAP s). Friendly: a
## "whoa, easy", never a fall.
const DODGE_T := 1.4
const DODGE_MISS := 2.2
const DODGE_MAX := 3.2
const CAR_CLEAR := 2.6
const CAR_BACK := 2.5
const STEP_OUT_V := 3.5
const STEP_BACK_V := 1.0
const SCATTER_KMH := 30.0
const HOP := 0.3
const DODGE_LINE_GAP := 12.0
## The match itself: the groups file in through the gate over the first MATCH_IN of it until only
## MATCH_SHARE stay outside (the drummer and a few without tickets, a radio on), and come back out
## over the last MATCH_OUT before full time. No smoke while they are in.
const MATCH_SHARE := 0.15
const MATCH_IN := 0.06
const MATCH_OUT := 0.04
## Colours: the fans' shirts and jackets (white, red, green and dark), the smoke (from the stick's
## bright pink-red to a soft pink), the bubbles, Sierżant Bogdan's hi-vis.
const SHIRTS := ["#f2efe8", "#f2efe8", "#c4262e", "#c4262e", "#2b6e3f", "#2b6e3f", "#1c2230", "#2b2c2f", "#e8e4d8"]
const KID_SHIRT := Color("#c4262e")
## The smoke holders' dark jackets (their raised arm is in the kit mesh, in the same colour).
const HOLDER_SHIRT := Color("#1c2230")
const SMOKE_A := Color("#ff4f6d")
const SMOKE_B := Color("#ffc2cf")
const BUBBLE := Color("#ff7a8a")
const POLICE_BUBBLE := Color("#9ec9ff")
const OFFICER_SHIRT := Color("#e8f23a")
## Props' shapes (INSTANCE_CUSTOM.a).
const SCARF_UP := 0.0
const SCARF_NECK := 1.0
const CUP := 2.0
const FINGER := 3.0

## The view's focus, -> Vector3.
var focus: Callable
## The game clock, -> {hour, weekday}.
var clock: Callable
## The vehicle, -> [position, km/h, flying].
var vehicle: Callable
## Is a world point on screen (traffic.gd on_screen), -> bool; unset: always.
var on_screen: Callable
var map: Node3D
var dialogue: Node
var hud: CanvasLayer
## police.gd (club_park / club_leave) for the patrol car by the gate; may be null.
var police: Node
## city_sounds.gd (add_crowd) for the chant; may be null.
var sounds: Node
## --crowd= scale.
var amount := 1.0
## --fans-log: changes and lines.
var log_on := false
## --fans-now: out on whatever the clock says.
var force := false
var spent_usec := 0
var lines_said := 0
var chants := 0
var meets := 0
var on := false
var near := false
## Groups: {id, at (Vector2 the pavement point), face (Vector2 toward the street), yaw (the kit's),
## slots: [{p: Vector3, yaw, shirt, tr, role ("fan", "drum", "smoke", "kid"), ph}], tips (Vector3
## the smoke sticks' tops), n, chant (s left), next (s to the next chant), honk_t, line_t, police
## (bool), officer ({} or {p, yaw}), met}.
var groups: Array[Dictionary] = []
var t := 0.0
## Match day: "arrive", "match", "leave" or "" (`phase_at`), its progress 0..1, the result ("win"
## or "draw", rolled at full time), --fans-phase= / --fans-result= for shots and checks.
var phase := ""
var phase_p := 0.0
var result := ""
var force_phase := ""
var force_result := ""
## Routes: {id, to (group index), pts (PackedVector2Array), ys (PackedFloat32Array), cum, len}.
var routes: Array[Dictionary] = []
## Walkers, in parallel arrays (a move touches every one 10 times a second): the route, metres
## along it, speed, bunch and its trip number, out on this trip or not, metres off the footway's
## middle, shirt, trousers, prop (-1 none, SCARF_NECK, FINGER for a kid), a bob phase, heading
## and the route segment it was on last time.
var walker_count := 0
var w_route := PackedInt32Array()
var w_s := PackedFloat32Array()
var w_v := PackedFloat32Array()
var w_clump := PackedInt32Array()
var w_lap := PackedInt32Array()
var w_show := PackedByteArray()
var w_side := PackedFloat32Array()
var w_shirt := PackedColorArray()
var w_tr := PackedFloat32Array()
var w_prop := PackedFloat32Array()
var w_ph := PackedFloat32Array()
var w_yaw := PackedFloat32Array()
var w_seg := PackedInt32Array()
## Each walker's step aside from its route (m), easing towards `dodge_target`.
var w_off := PackedVector2Array()
## Steps aside so far (the check, the log) and the car as last seen by move() (its speed from that).
var dodges := 0
var _car_prev := Vector2.INF
var _dodge_line_at := -99.0
var walking := 0
var _walk_line_t := 6.0
var _clumps := 0
var _full_time_toast := false

var _rng := RandomNumberGenerator.new()
var _tick_t := 0.0
var _move_t := 0.0
var _hour := 14.0
var _weekday := 5
var _fan_mm: MultiMesh
var _fan_mmi: MultiMeshInstance3D
var _fan_buf := PackedFloat32Array()
var _prop_mm: MultiMesh
var _prop_mmi: MultiMeshInstance3D
var _prop_buf := PackedFloat32Array()
var _puff_mm: MultiMesh
var _puff_mmi: MultiMeshInstance3D
var _puff_buf := PackedFloat32Array()
var _kit: MeshInstance3D
var _walk_mm: MultiMesh
var _walk_mmi: MultiMeshInstance3D
var _walk_buf := PackedFloat32Array()


# --- the rules (static: check_fans.gd) -----------------------------------------------------

## Is it a match evening at `hour` on `weekday` (1 Monday .. 7 Sunday)?
static func match_on(hour: float, weekday: int) -> bool:
	if not MATCHES.has(weekday):
		return false
	var w: Array = MATCHES[weekday]
	return hour >= float(w[0]) and hour < float(w[1])


## How many stand in a group now (0 off a match evening; `k` the --crowd scale).
static func group_count(max_n: int, hour: float, weekday: int, k := 1.0, forced := false) -> int:
	if not forced and not match_on(hour, weekday):
		return 0
	return roundi(max_n * k)


## The jump of a fan `secs` into a chant (m): in unison on the beat, a little spread by `ph`.
static func jump_at(secs: float, ph: float) -> float:
	return absf(sin((secs * JUMP_HZ + ph * 0.08) * PI)) * JUMP


## Is smoke stick `k` of a group lit `secs` into the session (each lit SMOKE_ON of SMOKE_CYCLE s,
## the two a group has half a cycle apart)?
static func smoke_lit(secs: float, k: int, seed_ph: float) -> bool:
	return fposmod(secs + seed_ph + k * SMOKE_CYCLE * 0.5, SMOKE_CYCLE) < SMOKE_ON


## A puff `age` (0..1) of its life from a stick's top: [offset (Vector3), size].
static func puff_at(age: float, k: int) -> Array:
	var a := clampf(age, 0.0, 1.0)
	var wob := sin(a * 5.0 + k * 1.9) * 0.25
	var off := WIND * a * 2.2 + Vector3(wob, a * PUFF_RISE, wob * 0.6)
	return [off, (0.22 + PUFF_SIZE * pow(sin(a * PI), 0.7)) * (1.0 - a * 0.25)]


## Is a ground point clear for a fan: off every road (`roads`: [PackedVector2Array, half width]) by
## ROAD_CLEAR, outside every building (`blds`: PackedVector2Array outlines).
static func clear_at(p: Vector2, roads: Array, blds: Array) -> bool:
	for r: Array in roads:
		var pts: PackedVector2Array = r[0]
		var hw := float(r[1]) + ROAD_CLEAR
		for j in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1]).distance_to(p) < hw:
				return false
	for b: PackedVector2Array in blds:
		if Geometry2D.is_point_in_polygon(p, b):
			return false
	return true


## The roads and buildings within `reach` m of `c` from the map data: [roads, blds].
static func obstacles(data: Dictionary, c: Vector2, reach: float) -> Array:
	var roads: Array = []
	for r: Dictionary in data.get("roads", []):
		var flat: Array = r["p"]
		var pts := PackedVector2Array()
		var close := false
		for i in flat.size() / 2:
			var q := Vector2(float(flat[i * 2]), float(flat[i * 2 + 1]))
			pts.append(q)
			close = close or q.distance_to(c) < reach
		if close and pts.size() >= 2 and not bool(r.get("bridge", false)):
			roads.append([pts, float(r.get("w", 6.0)) * 0.5])
	var blds: Array = []
	for b: Dictionary in data.get("buildings", []):
		var flat: Array = b["p"]
		if flat.size() < 6:
			continue
		var q0 := Vector2(float(flat[0]), float(flat[1]))
		if q0.distance_to(c) > reach + 250.0:
			continue
		var pts := PackedVector2Array()
		for i in flat.size() / 2:
			pts.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
		blds.append(pts)
	return [roads, blds]


## The pavements (footways off decks) within `reach` m of `c`: [PackedVector2Array, width] each.
static func pavements(data: Dictionary, c: Vector2, reach: float) -> Array:
	var out: Array = []
	for p: Dictionary in data.get("paths", []):
		if str(p.get("k", "")) != "foot" or int(p.get("dk", -1)) >= 0:
			continue
		var flat: Array = p["p"]
		var pts := PackedVector2Array()
		var close := false
		for i in flat.size() / 2:
			var q := Vector2(float(flat[i * 2]), float(flat[i * 2 + 1]))
			pts.append(q)
			close = close or q.distance_to(c) < reach
		if close and pts.size() >= 2:
			out.append([pts, float(p.get("w", 2.2))])
	return out


## A group's layout (pure): the pavement point nearest `anchor`, the side with more room, and
## up to `n` slots on clear ground: {at, along, face, slots: [[Vector2, role]], banner (Vector2 the
## banner's middle), back (m behind the pavement's middle the banner stands)} or {}.
static func layout(anchor: Vector2, n: int, foot: Array, roads: Array, blds: Array, seed_value: int) -> Dictionary:
	var best: Array = []
	var bd := SNAP
	for f: Array in foot:
		var pts: PackedVector2Array = f[0]
		for j in pts.size() - 1:
			# A stretch long enough to line up along (not a crossing's short link).
			if pts[j].distance_to(pts[j + 1]) < MIN_STRETCH:
				continue
			var q := Geometry2D.get_closest_point_to_segment(anchor, pts[j], pts[j + 1])
			var d := q.distance_to(anchor)
			if d < bd and clear_at(q, roads, blds):
				bd = d
				best = [q, (pts[j + 1] - pts[j]).normalized(), float(f[1])]
	if best.is_empty():
		return {}
	var q: Vector2 = best[0]
	var along: Vector2 = best[1]
	var w := clampf(float(best[2]), 1.8, 5.0)
	var side := Vector2(-along.y, along.x)
	# `side` points to the side with more clear ground 2-5 m out (the group's back, the banner's).
	var room_a := 0
	var room_b := 0
	for k: float in [2.0, 3.5, 5.0]:
		room_a += 1 if clear_at(q + side * k, roads, blds) else 0
		room_b += 1 if clear_at(q - side * k, roads, blds) else 0
	if room_b > room_a:
		side = -side
	var half := HALF_BASE + HALF_PER * n
	# How deep the clear ground goes behind the pavement (sampled across the group's length).
	var back := w * 0.5
	var depth := w * 0.5
	while depth <= w * 0.5 + DEEP:
		var ok := true
		for a: float in [-half, -half * 0.5, 0.0, half * 0.5, half]:
			if not clear_at(q + along * a + side * depth, roads, blds):
				ok = false
				break
		if not ok:
			break
		back = depth
		depth += 0.5
	var front := -w * 0.5 + 0.3
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var slots: Array = []
	var at := func(a: float, b: float) -> Vector2: return q + along * a + side * b
	# The specials first: the drummer at the side, two smoke holders, the kid at the front.
	var mid := lerpf(front, back - 0.6, 0.5)
	for s: Array in [[-half + 1.2, mid, "drum"], [half * 0.45, lerpf(front, back - 0.6, 0.7), "smoke"],
			[-half * 0.35, lerpf(front, back - 0.6, 0.35), "smoke"], [half * 0.1, front + 0.2, "kid"]]:
		# The spot planned, else the nearest clear one round it.
		for k in 30:
			var p: Vector2 = at.call(float(s[0]) + (rng.randf_range(-2.0, 2.0) if k > 0 else 0.0),
					clampf(float(s[1]) + (rng.randf_range(-1.0, 1.0) if k > 0 else 0.0), front, maxf(back - 0.6, front)))
			var ok := clear_at(p, roads, blds)
			for o: Array in slots:
				ok = ok and (o[0] as Vector2).distance_to(p) >= GAP * 1.5
			if ok:
				slots.append([p, s[2]])
				break
	var tries := 0
	while slots.size() < n and tries < 900:
		tries += 1
		var p: Vector2 = at.call(rng.randf_range(-half, half), rng.randf_range(front, maxf(back - 0.6, front + 0.4)))
		var ok := clear_at(p, roads, blds)
		if ok:
			for s: Array in slots:
				if (s[0] as Vector2).distance_to(p) < GAP:
					ok = false
					break
		if ok:
			slots.append([p, "fan"])
	return {"at": q, "along": along, "face": -side, "slots": slots, "banner": q + side * (back + 0.2), "back": back + 0.2,
			"half": half}


# --- match day (static: check_fans.gd) -----------------------------------------------------

## The match day's phase at `hour` on `weekday`: ["arrive", 0..1] in the ARRIVE h before kick-off,
## ["match", 0..1] while the ball rolls, ["leave", 0..1] for LEAVE h from full time, ["", 0] else
## (also the rest of a match evening, when the groups still sing but nobody walks).
static func phase_at(hour: float, weekday: int) -> Array:
	if not MATCHES.has(weekday):
		return ["", 0.0]
	var kick := float(MATCHES[weekday][0]) + KICK_AFTER
	var a := kick - ARRIVE
	var f := kick + FULL_TIME
	if hour >= a and hour < kick:
		return ["arrive", (hour - a) / ARRIVE]
	if hour >= kick and hour < f:
		return ["match", (hour - kick) / FULL_TIME]
	if hour >= f and hour < f + LEAVE:
		return ["leave", (hour - f) / LEAVE]
	return ["", 0.0]


## How many of a route's walkers are out (0..1) `p` into a phase: on the way in a trickle that
## grows to a stream just before kick-off and a few running in the last LATE; on the way home
## everyone at the whistle, thinning out.
static func walk_density(ph: String, p: float) -> float:
	match ph:
		"arrive":
			if p >= 1.0 - LATE:
				return 0.18
			return lerpf(0.2, 1.0, smoothstep(0.0, 0.85, p))
		"leave":
			return lerpf(1.0, 0.0, smoothstep(0.0, 1.0, p))
	return 0.0


## A bunch's dice for one trip (0..1): the friends in it come (or don't) together.
static func clump_roll(clump: int, lap: int) -> float:
	return fposmod(sin(clump * 12.9898 + lap * 78.233) * 43758.5453, 1.0)


## Are the walkers running (late for kick-off)?
static func running(ph: String, p: float) -> bool:
	return ph == "arrive" and p >= 1.0 - LATE


## The share of a group outside (0..1) `p` into match-day phase `ph`: all of it but during the
## match, when most file in (MATCH_SHARE stay) and come back out just before full time.
static func group_share(ph: String, p: float) -> float:
	if ph != "match":
		return 1.0
	if p < MATCH_IN:
		return lerpf(1.0, MATCH_SHARE, p / MATCH_IN)
	if p > 1.0 - MATCH_OUT:
		return lerpf(MATCH_SHARE, 1.0, (p - (1.0 - MATCH_OUT)) / MATCH_OUT)
	return MATCH_SHARE


## Where a fan standing (or walking) at `p` wants to be, as an offset (m), with the car at `car`
## moving at `vel` (m/s): out of its path (DODGE_MISS + 0.4 m to the side it is already on) when the
## car will pass within DODGE_MISS in DODGE_T s, round it at CAR_CLEAR when it stands, else ZERO.
static func dodge_target(p: Vector2, car: Vector2, vel: Vector2) -> Vector2:
	var rel := p - car
	var sp := vel.length()
	if sp < 1.0:
		var d := rel.length()
		if d >= CAR_CLEAR:
			return Vector2.ZERO
		return (rel / d if d > 0.01 else Vector2.RIGHT) * (CAR_CLEAR - d)
	var dir := vel / sp
	var ahead := rel.dot(dir)
	if ahead < -CAR_BACK or ahead > sp * DODGE_T + CAR_BACK:
		return Vector2.ZERO
	var side := Vector2(-dir.y, dir.x)
	var lat := rel.dot(side)
	if absf(lat) >= DODGE_MISS:
		return Vector2.ZERO
	return side * (1.0 if lat >= 0.0 else -1.0) * minf(DODGE_MISS + 0.4 - absf(lat), DODGE_MAX)


## The walkways (footways and zebras off decks) within `reach` m of `c`: [PackedVector2Array,
## width, zebra] each.
static func walkways(data: Dictionary, c: Vector2, reach: float) -> Array:
	var out: Array = []
	for p: Dictionary in data.get("paths", []):
		var k := str(p.get("k", ""))
		if (k != "foot" and k != "zebra") or int(p.get("dk", -1)) >= 0:
			continue
		var flat: Array = p["p"]
		var pts := PackedVector2Array()
		var close := false
		for i in flat.size() / 2:
			var q := Vector2(float(flat[i * 2]), float(flat[i * 2 + 1]))
			pts.append(q)
			close = close or q.distance_to(c) < reach
		if close and pts.size() >= 2:
			out.append([pts, float(p.get("w", 2.2)), k == "zebra"])
	return out


## The walkways as a graph: a point every NODE_STEP m, linked along each walkway and to any other
## within JOIN m (zebras a little dearer, so a route crosses where it has to).
static func walk_graph(ways: Array) -> AStar2D:
	var g := AStar2D.new()
	var ids := {}
	var cells := {}
	var node := func(q: Vector2, zebra: bool) -> int:
		var key := Vector2i(roundi(q.x * 2.0), roundi(q.y * 2.0))
		if ids.has(key):
			return int(ids[key])
		var id := g.get_point_count()
		g.add_point(id, q, 1.3 if zebra else 1.0)
		ids[key] = id
		var cell := Vector2i(floori(q.x / JOIN), floori(q.y / JOIN))
		if not cells.has(cell):
			cells[cell] = []
		(cells[cell] as Array).append(id)
		return id
	for w: Array in ways:
		var pts: PackedVector2Array = w[0]
		var zebra := bool(w[2])
		var prev: int = node.call(pts[0], zebra)
		for j in pts.size() - 1:
			var a := pts[j]
			var b := pts[j + 1]
			var m := maxi(1, ceili(a.distance_to(b) / NODE_STEP))
			for i in range(1, m + 1):
				var id: int = node.call(a.lerp(b, float(i) / m), zebra)
				if id != prev:
					g.connect_points(prev, id)
				prev = id
	for cell: Vector2i in cells:
		for id: int in cells[cell]:
			var q := g.get_point_position(id)
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					var other := cell + Vector2i(dx, dy)
					if not cells.has(other):
						continue
					for o: int in cells[other]:
						if o > id and not g.are_points_connected(id, o) and g.get_point_position(o).distance_to(q) < JOIN:
							g.connect_points(id, o)
	return g


## A route on the graph from the walkway point nearest `from` to the one nearest `to` (empty when
## either is more than 30 m off, they don't connect, or it is longer than ROUTE_MAX).
static func walk_route(g: AStar2D, from: Vector2, to: Vector2) -> PackedVector2Array:
	if g.get_point_count() == 0:
		return PackedVector2Array()
	var a := g.get_closest_point(from)
	var b := g.get_closest_point(to)
	if g.get_point_position(a).distance_to(from) > 30.0 or g.get_point_position(b).distance_to(to) > 30.0:
		return PackedVector2Array()
	var pts := g.get_point_path(a, b)
	if pts.size() < 2 or path_length(pts) > ROUTE_MAX:
		return PackedVector2Array()
	return pts


static func path_length(pts: PackedVector2Array) -> float:
	var l := 0.0
	for j in pts.size() - 1:
		l += pts[j].distance_to(pts[j + 1])
	return l


## The point `s` m along a route (`cum` its cumulative lengths) and the way it heads there:
## [Vector2, Vector2 direction, segment index, fraction].
static func along_route(pts: PackedVector2Array, cum: PackedFloat32Array, s: float) -> Array:
	var n := pts.size()
	var x := clampf(s, 0.0, cum[n - 1])
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if cum[mid] <= x:
			lo = mid
		else:
			hi = mid
	var seg := cum[hi] - cum[lo]
	var f := (x - cum[lo]) / seg if seg > 0.0 else 0.0
	var d := (pts[hi] - pts[lo]).normalized() if seg > 0.0 else Vector2.UP
	return [pts[lo].lerp(pts[hi], f), d, lo, f]


# --- setup ---------------------------------------------------------------------------------

## The groups from the map data (roads, buildings, footways round the stadium).
func setup(data: Dictionary, seed_value := 1916) -> void:
	_rng.seed = seed_value
	var obs := obstacles(data, STADIUM, 330.0)
	var foot := pavements(data, STADIUM, 330.0)
	var cap_k := maxf(amount, 1.0)
	for id: String in GROUPS:
		var spec: Dictionary = GROUPS[id]
		var lay := layout(spec["at"], ceili(int(spec["n"]) * cap_k), foot, obs[0], obs[1], hash(id))
		if lay.is_empty():
			push_warning("fans: no pavement near the %s group's anchor" % id)
			continue
		var face: Vector2 = lay["face"]
		var slots: Array = []
		var tips: Array = []
		for s: Array in lay["slots"]:
			var p2: Vector2 = s[0]
			var role: String = s[1]
			var look := face.rotated(_rng.randf_range(-0.5, 0.5)) if role == "fan" else face
			var shirt := Color(SHIRTS[_rng.randi() % SHIRTS.size()])
			if role == "kid":
				shirt = KID_SHIRT
			elif role == "smoke":
				shirt = HOLDER_SHIRT
			var p := _ground(p2)
			# Who stays outside during the match (ord < the share): the drummer always, then the fans
			# in a random order; the kid and the smoke holders go in first.
			var ord := 0.0 if role == "drum" else (_rng.randf_range(0.02, 0.98) if role == "fan" else 0.99)
			slots.append({"p": p, "yaw": atan2(-look.x, -look.y), "shirt": shirt, "tr": _rng.randf() * 0.99, "role": role,
					"ph": _rng.randf_range(-1.0, 1.0), "scarf": role == "fan" and _rng.randf() < 0.75, "ord": ord,
					"off": Vector2.ZERO})
			if role == "smoke":
				# The stick's top in the raised right hand (the figure faces -z: its right is +x).
				var right := Vector2(-face.y, face.x)
				var hand := p2 + right * 0.32 + face * 0.1
				tips.append(Vector3(hand.x, p.y + 2.25, hand.y))
		groups.append({"id": id, "at": lay["at"], "along": lay["along"], "face": face, "yaw": atan2(face.x, face.y),
				"banner": lay["banner"], "back": float(lay["back"]), "half": float(lay["half"]), "text": spec["banner"],
				"slots": slots, "tips": tips, "max": int(spec["n"]), "n": 0, "chant": 0.0,
				"next": _rng.randf_range(2.0, 8.0), "honk_t": 0.0, "line_t": _rng.randf_range(3.0, 8.0),
				"police": bool(spec["police"]), "officer": {}, "met": false, "smoke_ph": _rng.randf_range(0.0, SMOKE_CYCLE),
				"share": 1.0, "dodging": false})
	_setup_routes(data)
	_build_drawing()
	if sounds != null and sounds.has_method("add_crowd"):
		for g in groups:
			var a: Vector2 = g["at"]
			sounds.add_crowd("kibice_%s" % g["id"], "chant", _ground(a),
					func() -> bool: return on and int(g["n"]) > 0)
	var sizes := PackedStringArray()
	for g in groups:
		sizes.append("%s %d" % [g["id"], (g["slots"] as Array).size()])
	print("fans: %d groups by Stadion Leguminy (%s), %d routes, %d walkers, amount %.2f" % [groups.size(), ", ".join(sizes),
			routes.size(), walker_count, amount])


## The walkers' routes (ROUTES) on the walkways round the stadium, each ending at its group's
## pavement point, and the walkers on them (× the --crowd scale).
func _setup_routes(data: Dictionary) -> void:
	var g := walk_graph(walkways(data, STADIUM, 650.0))
	var idx := {}
	for i in groups.size():
		idx[groups[i]["id"]] = i
	for id: String in ROUTES:
		var spec: Dictionary = ROUTES[id]
		if not idx.has(spec["to"]):
			continue
		var gi: int = idx[spec["to"]]
		var pts := walk_route(g, spec["from"], groups[gi]["at"])
		if pts.is_empty():
			push_warning("fans: no walkway from %s to the %s group" % [id, spec["to"]])
			continue
		var cum := PackedFloat32Array([0.0])
		var ys := PackedFloat32Array([_ground(pts[0]).y])
		for j in range(1, pts.size()):
			cum.append(cum[j - 1] + pts[j - 1].distance_to(pts[j]))
			ys.append(_ground(pts[j]).y)
		var ri := routes.size()
		# The way home: the same route backwards (so a walker's cursor only ever moves forward).
		var rpts := pts.duplicate()
		rpts.reverse()
		var rys := ys.duplicate()
		rys.reverse()
		var rcum := PackedFloat32Array([0.0])
		for j in range(1, rpts.size()):
			rcum.append(rcum[j - 1] + rpts[j - 1].distance_to(rpts[j]))
		routes.append({"id": id, "to": gi, "pts": pts, "ys": ys, "cum": cum, "len": cum[cum.size() - 1],
				"rpts": rpts, "rys": rys, "rcum": rcum})
		# In little bunches of friends (1-4, one with a kid now and then) walking together.
		var n := roundi(int(spec["n"]) * maxf(amount, 0.0))
		var made := 0
		while made < n:
			var size := mini(1 + _rng.randi() % 4, n - made)
			var base := _rng.randf() * cum[cum.size() - 1]
			var v := WALK_V + _rng.randf_range(-WALK_VAR, WALK_VAR)
			var clump := _clumps
			_clumps += 1
			for k in size:
				var kid := size >= 3 and k == size - 1 and _rng.randf() < 0.5
				w_route.append(ri)
				w_s.append(fposmod(base + k * 0.7 + _rng.randf_range(-0.3, 0.3), cum[cum.size() - 1]))
				w_v.append(v)
				w_clump.append(clump)
				w_lap.append(0)
				w_show.append(0)
				w_side.append(clampf((k - (size - 1) * 0.5) * 0.65 + _rng.randf_range(-0.2, 0.2), -SIDE - 0.3, SIDE + 0.3))
				w_shirt.append(KID_SHIRT if kid else Color(SHIRTS[_rng.randi() % SHIRTS.size()]))
				w_tr.append(_rng.randf() * 0.99)
				w_prop.append(FINGER if kid else (SCARF_NECK if _rng.randf() < 0.7 else -1.0))
				w_ph.append(_rng.randf_range(0.0, TAU))
				w_yaw.append(0.0)
				w_seg.append(0)
				w_off.append(Vector2.ZERO)
				walker_count += 1
			made += size


func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, map.deck_height(-1, p.x, p.y) if map != null else 0.0, p.y)


# --- drawing -------------------------------------------------------------------------------

## The fans' props, facing -z, a four-shape family (CityLife.family_mesh; the PAINT parts take the
## instance colour, the fan's shirt): 0 a scarf held up over the head in both hands (the arms
## raised), 1 a scarf round the neck, its two ends hanging in front, 2 a paper coffee cup in the
## right hand, 3 a giant green foam finger raised in the right hand. Stripes red, white, green.
static func props_mesh() -> ArrayMesh:
	var red := [Color("#c4262e"), Models.FIXED]
	var white := [Color("#f2efe8"), Models.FIXED]
	var green := [Color("#2b6e3f"), Models.FIXED]
	var skin := [Color("#e2b48c"), Models.FIXED]
	var sleeve := [Color.WHITE, Models.PAINT]
	var cup := [Color("#f2efe8"), Models.FIXED]
	var lid := [Color("#6b4a32"), Models.FIXED]
	var foam := [Color("#3fae5a"), Models.FIXED]
	var parts := [red, white, green, white, red, skin, skin, sleeve, sleeve, red, red, green, cup, lid, foam, foam, sleeve]
	var Z := [Vector3.ZERO, Vector3.ZERO]
	var stripe := func(k: int) -> Array: return [Vector3(-0.52 + k * 0.26, 2.12, -0.04), Vector3(0.26, 0.22, 0.03)]
	var up := [stripe.call(0), stripe.call(1), stripe.call(2), stripe.call(3), stripe.call(4),
			[Vector3(-0.62, 2.1, -0.04), Vector3(0.1, 0.12, 0.1)], [Vector3(0.62, 2.1, -0.04), Vector3(0.1, 0.12, 0.1)],
			[Vector3(-0.47, 1.74, -0.02), Vector3(0.11, 0.62, 0.13)], [Vector3(0.47, 1.74, -0.02), Vector3(0.11, 0.62, 0.13)],
			Z, Z, Z, Z, Z, Z, Z, Z]
	var neck := [Z, Z, Z, Z, Z, Z, Z, Z, Z,
			[Vector3(0, 1.45, 0), Vector3(0.36, 0.1, 0.32)], [Vector3(-0.08, 1.24, -0.155), Vector3(0.08, 0.36, 0.03)],
			[Vector3(0.08, 1.2, -0.155), Vector3(0.08, 0.36, 0.03)], Z, Z, Z, Z, Z]
	var coffee := [Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z,
			[Vector3(0.3, 1.18, -0.2), Vector3(0.09, 0.12, 0.09)], [Vector3(0.3, 1.25, -0.2), Vector3(0.1, 0.025, 0.1)],
			Z, Z, [Vector3(0.3, 1.12, -0.1), Vector3(0.11, 0.14, 0.2)]]
	var finger := [Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z,
			[Vector3(0.4, 2.05, -0.04), Vector3(0.3, 0.36, 0.14)], [Vector3(0.36, 2.48, -0.04), Vector3(0.1, 0.52, 0.1)],
			[Vector3(0.36, 1.68, -0.02), Vector3(0.11, 0.5, 0.13)]]
	return CityLife.family_mesh(parts, [up, neck, coffee, finger])


## A smoke puff: a rounded clump of four boxes (the instance colour), about a metre across at
## scale 1.
static func puff_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Color.WHITE
	Models.box(st, Vector3(0, 0, 0), Vector3(0.8, 0.6, 0.8), c, Models.PAINT)
	Models.box(st, Vector3(0, 0, 0), Vector3(0.55, 0.9, 0.55), c, Models.PAINT)
	Models.box(st, Vector3(0.22, 0.12, -0.15), Vector3(0.5, 0.5, 0.5), c, Models.PAINT)
	Models.box(st, Vector3(-0.2, -0.08, 0.2), Vector3(0.45, 0.45, 0.45), c, Models.PAINT)
	return st.commit()


## One group's kit in its own frame (+z toward the street, x along the pavement, the origin on the
## pavement's middle): the banner on two poles at the back (its two lines facing the street), the
## bass drum on a harness frame in front of the drummer, and the smoke sticks (a dark handle, a
## glowing pink-red top, LIT_SIGN) in the holders' hands. `items`: [[local Vector3, role]].
static func kit_mesh(st: SurfaceTool, banner_z: float, half: float, text: Array, items: Array) -> void:
	var grey := Color("#5a5d63")
	var px := 0.08
	var l0 := str(text[0])
	var l1 := str(text[1]) if text.size() > 1 else ""
	var tw := maxi(PixelFont.width(l0), PixelFont.width(l1))
	var bw := minf((tw + 8) * px, half * 2.0 + 1.0)
	var lines := 2 if l1 != "" else 1
	var bh := (PixelFont.LINE * lines + 3) * px
	var y0 := 2.5
	var bz := -banner_z
	# The cloth: white with a red band above and a green one below; the words in dark red.
	Models.box(st, Vector3(0, y0, bz), Vector3(bw, bh, 0.04), Color("#f2efe8"))
	Models.box(st, Vector3(0, y0 + bh * 0.5 + 0.06, bz), Vector3(bw, 0.12, 0.05), Color("#c4262e"))
	Models.box(st, Vector3(0, y0 - bh * 0.5 - 0.06, bz), Vector3(bw, 0.12, 0.05), Color("#2b6e3f"))
	var top := y0 + bh * 0.5 - 1.5 * px
	# The words on both faces (read from the street and from the stadium's side).
	for i in lines:
		var s := l0 if i == 0 else l1
		var lw := PixelFont.width(s) * px
		var y := top - i * PixelFont.LINE * px
		PixelFont.add_quads(st, s, Vector3(-lw * 0.5, y, bz + 0.025), Vector3.RIGHT, Vector3.DOWN, px, Color("#8e1b22"), Models.FIXED)
		PixelFont.add_quads(st, s, Vector3(lw * 0.5, y, bz - 0.025), Vector3.LEFT, Vector3.DOWN, px, Color("#8e1b22"), Models.FIXED)
	for x in [-bw * 0.5 - 0.05, bw * 0.5 + 0.05]:
		Models.box(st, Vector3(x, (y0 + bh * 0.5 + 0.15) * 0.5, bz), Vector3(0.06, y0 + bh * 0.5 + 0.15, 0.06), grey)
	for it: Array in items:
		var p: Vector3 = it[0]
		match str(it[1]):
			"drum":
				# A bass drum carried on the belly, its heads facing the sides: white shell, red hoops.
				var d := p + Vector3(0, 1.0, 0.42)
				Models.box(st, d, Vector3(0.36, 0.56, 0.56), Color("#f2efe8"))
				for sx in [-0.19, 0.19]:
					Models.box(st, d + Vector3(sx, 0, 0), Vector3(0.03, 0.6, 0.6), Color("#c4262e"))
				Models.box(st, d + Vector3(0, 0.33, 0), Vector3(0.1, 0.1, 0.1), Color("#2b2c2f"))
			"smoke":
				Models.box(st, p + Vector3(0, -0.65, 0), Vector3(0.11, 0.5, 0.13), HOLDER_SHIRT)
				Models.box(st, p + Vector3(0, -0.22, 0), Vector3(0.05, 0.36, 0.05), Color("#2b2c2f"))
				Models.box(st, p, Vector3(0.08, 0.12, 0.08), Color("#ff3d5a"), Models.LIT_SIGN)


func _build_drawing() -> void:
	var fan_cap := 1
	var tips := 0
	for g in groups:
		fan_cap += (g["slots"] as Array).size()
		tips += (g["tips"] as Array).size()
	var person := Models.person_mesh()
	var mat := Models.material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("walk", 0.0)
	_fan_mm = _new_mm(person, fan_cap)
	_fan_mmi = _new_mmi(_fan_mm, "Fans", mat)
	_fan_buf.resize(fan_cap * 16)
	_fan_buf.fill(0.0)
	var walk_cap := maxi(walker_count, 1)
	var walk_mat := Models.material().duplicate() as ShaderMaterial
	walk_mat.set_shader_parameter("walk", 0.16)
	_walk_mm = _new_mm(person, walk_cap)
	_walk_mmi = _new_mmi(_walk_mm, "FanWalkers", walk_mat)
	_walk_buf.resize(walk_cap * 16)
	_walk_buf.fill(0.0)
	_prop_mm = _new_mm(props_mesh(), fan_cap + walk_cap)
	_prop_mmi = _new_mmi(_prop_mm, "FanProps", Models.material())
	_prop_buf.resize((fan_cap + walk_cap) * 16)
	_prop_buf.fill(0.0)
	var pc := maxi(tips * PUFFS, 1)
	_puff_mm = _new_mm(puff_mesh(), pc)
	_puff_mmi = _new_mmi(_puff_mm, "FanSmoke", Models.material())
	_puff_buf.resize(pc * 16)
	_puff_buf.fill(0.0)
	# The kits: every group's banner, drum and sticks in one mesh in world space.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for g in groups:
		var one := SurfaceTool.new()
		one.begin(Mesh.PRIMITIVE_TRIANGLES)
		var face: Vector2 = g["face"]
		var right := Vector2(face.y, -face.x)  # the kit frame's +x in the world
		var o := _ground(g["at"])
		var items: Array = []
		for s: Dictionary in g["slots"]:
			if s["role"] == "drum":
				items.append([_to_local(s["p"], o, right, face), "drum"])
		for tip: Vector3 in g["tips"]:
			items.append([_to_local(tip, o, right, face), "smoke"])
		kit_mesh(one, float(g["back"]), float(g["half"]), g["text"], items)
		var basis := Basis(Vector3.UP, float(g["yaw"]))
		st.append_from(one.commit(), 0, Transform3D(basis, o))
		any = true
	_kit = MeshInstance3D.new()
	_kit.name = "FanKit"
	_kit.mesh = st.commit() if any else null
	_kit.material_override = Models.material()
	_kit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_kit.visible = false
	add_child(_kit)


## A world point in a kit's frame (origin `o`, +x `right`, +z `face`).
static func _to_local(p: Vector3, o: Vector3, right: Vector2, face: Vector2) -> Vector3:
	var d := Vector2(p.x - o.x, p.z - o.z)
	return Vector3(d.dot(right), p.y - o.y, d.dot(face))


func _new_mm(mesh: Mesh, cap: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = cap
	mm.visible_instance_count = 0
	return mm


func _new_mmi(mm: MultiMesh, n: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mmi.visible = false
	add_child(mmi)
	return mmi


# --- the logic -----------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or not clock.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	t += dt
	_tick_t += dt
	if _tick_t >= TICK:
		var step := _tick_t
		_tick_t = 0.0
		tick(step)
	_move_t += dt
	if _move_t >= MOVE_TICK:
		var step := _move_t
		_move_t = 0.0
		move(step)
	spent_usec += Time.get_ticks_usec() - t0


## One tick: out or not, near or not, the patrol car, the chants' timers, the lines and the toast.
func tick(step: float) -> void:
	var now: Dictionary = clock.call()
	_hour = float(now["hour"])
	_weekday = int(now["weekday"])
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var eye := Vector2(eye3.x, eye3.z)
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var vp: Vector3 = veh[0]
	var car2 := Vector2(vp.x, vp.z) if vp != Vector3.INF and not bool(veh[2]) else Vector2.INF
	var was := on
	on = force or match_on(_hour, _weekday)
	if on != was:
		if log_on:
			print("fans: %s" % ("out by Stadion Leguminy" if on else "gone home"))
		_police(on)
	for g in groups:
		g["n"] = mini(group_count(int(g["max"]), _hour, _weekday, amount, force), (g["slots"] as Array).size())
	_match_day()
	for g in groups:
		g["share"] = group_share(phase, phase_p)
	var nr := on and eye.distance_to(STADIUM) < ACTIVE_R
	if nr != near:
		near = nr
		_kit.visible = near
		if near:
			_place_walkers()
		else:
			_fan_mmi.visible = false
			_prop_mmi.visible = false
			_puff_mmi.visible = false
			_walk_mmi.visible = false
	if not near:
		return
	_walkers_talk(step, eye, car2, float(veh[1]))
	for g in groups:
		g["honk_t"] = maxf(float(g["honk_t"]) - step, 0.0)
		if float(g["chant"]) > 0.0:
			g["chant"] = maxf(float(g["chant"]) - step, 0.0)
		else:
			g["next"] = float(g["next"]) - step
			if float(g["next"]) <= 0.0:
				_start_chant(g, "")
		_talk(g, step, eye, car2, float(veh[1]))


## A group starts singing (`why`: "" its own timer, "honk" the player's horn).
func _start_chant(g: Dictionary, why: String) -> void:
	g["chant"] = CHANT_LEN
	g["next"] = _rng.randf_range(CHANT_GAP.x, CHANT_GAP.y) * (0.5 if celebrating() else 1.0)
	g["t0"] = t
	chants += 1
	if log_on:
		print("fans: %s sings%s" % [g["id"], " (the horn)" if why == "honk" else ""])
	if int(g["n"]) == 0:
		return
	var at: Vector3 = _ground(g["at"])
	if why == "honk" or _seen(at):
		g["line_t"] = maxf(float(g["line_t"]), 6.0)
		var tag := "chant"
		if why == "honk":
			tag = "honk"
		elif phase == "leave" and _rng.randf() < 0.6:
			tag = result
		_say(_anchor_of(g, -1), "", "kibice", tag, true)


## The player's horn at `at` (main.gd `_honk`: B, L3 on a pad): the nearest group within HONK_R sings.
func honk(at: Vector3) -> void:
	if not near:
		return
	var best := {}
	var bd := HONK_R
	for g in groups:
		var d := Vector2(at.x, at.z).distance_to(g["at"])
		if d < bd and float(g["honk_t"]) <= 0.0:
			bd = d
			best = g
	if not best.is_empty():
		best["honk_t"] = HONK_GAP
		_start_chant(best, "honk")


## The match day's phase from the clock (or --fans-phase= with --fans-now off a match evening), the
## result rolled at full time (or --fans-result=), and the full-time toast near the stadium.
func _match_day() -> void:
	var pa := phase_at(_hour, _weekday)
	var ph: String = pa[0]
	var pp: float = pa[1]
	if force_phase != "" or (force and not match_on(_hour, _weekday)):
		# Shots: the busy part of the phase (the stream just before kick-off, the crowd just after).
		ph = force_phase if force_phase != "" else "arrive"
		pp = {"arrive": 0.75, "match": 0.5, "leave": 0.15}.get(ph, 0.0)
	if ph == "leave" and phase != "leave":
		result = force_result if force_result != "" else ("draw" if _rng.randf() < 0.35 else "win")
		_full_time_toast = false
		if log_on:
			print("fans: full time, a %s" % result)
	elif ph != "leave" and ph != "" and phase == "leave":
		result = ""
	if log_on and ph != phase:
		print("fans: match day %s" % (ph if ph != "" else "quiet"))
	phase = ph
	phase_p = pp
	if phase == "leave" and near and not _full_time_toast and hud != null and hud.has_method("ambient_toast"):
		_full_time_toast = true
		if result == "win":
			hud.ambient_toast("Koniec meczu: wygrana! Kibice wracają do domu", "Full time: a win! The fans head home")
		else:
			hud.ambient_toast("Koniec meczu: remis. Następnym razem!", "Full time: a draw. Next time!")


## A win being sung home (the groups sing twice as often, the walkers lift their scarves).
func celebrating() -> bool:
	return phase == "leave" and result == "win"


## Walkers on the way: on arriving near, each where it is with the phase's density.
func _place_walkers() -> void:
	var dens := walk_density(phase, phase_p) if on else 0.0
	walking = 0
	for i in walker_count:
		w_lap[i] += 1
		w_show[i] = 1 if clump_roll(w_clump[i], w_lap[i]) < dens else 0
		walking += w_show[i]


## The walkers' lines: one on screen near the view now and then (`walk`, `late`, then `win` or
## `draw` on the way home; `car` for a slow car by them on the way in).
func _walkers_talk(step: float, eye: Vector2, car2: Vector2, kmh: float) -> void:
	_walk_line_t -= step
	if _walk_line_t > 0.0 or walking == 0 or phase == "":
		return
	var best := -1
	var bd := LINE_VIEW
	for i in walker_count:
		if w_show[i] == 0:
			continue
		var p := walker_at(i)
		var d := Vector2(p.x, p.z).distance_to(eye)
		if d < bd and _seen(p):
			bd = d
			best = i
	if best < 0:
		return
	_walk_line_t = _rng.randf_range(WALK_LINE_GAP.x, WALK_LINE_GAP.y)
	var p0 := walker_at(best)
	var tag := "walk"
	if phase == "leave":
		tag = result
	elif running(phase, phase_p) or phase == "match":
		tag = "late"
	elif car2 != Vector2.INF and car2.distance_to(Vector2(p0.x, p0.z)) < CAR_NEAR and kmh < CAR_KMH:
		tag = "car"
	var wk := best
	_say(func() -> Vector3: return walker_at(wk) + Vector3(0, 2.3, 0), "", "kibice", tag, true)


## Where walker `i` is now (on the way home it walks its route backwards); sets its heading (the
## figure faces -z). Its segment is the one it was on last time: walkers only move forward, so it
## is found by stepping on, not by a search.
func walker_at(i: int) -> Vector3:
	var r: Dictionary = routes[w_route[i]]
	var back := phase == "leave"
	var pts: PackedVector2Array = r["rpts"] if back else r["pts"]
	var cum: PackedFloat32Array = r["rcum"] if back else r["cum"]
	var ys: PackedFloat32Array = r["rys"] if back else r["ys"]
	return _walker_on(i, pts, cum, ys)


func _walker_on(i: int, pts: PackedVector2Array, cum: PackedFloat32Array, ys: PackedFloat32Array) -> Vector3:
	var n := pts.size()
	var s := clampf(w_s[i], 0.0, cum[n - 1])
	var j := w_seg[i]
	if j >= n - 1 or cum[j] > s:
		j = 0
	while j < n - 2 and cum[j + 1] <= s:
		j += 1
	w_seg[i] = j
	var seg := cum[j + 1] - cum[j]
	var f := (s - cum[j]) / seg if seg > 0.0 else 0.0
	var a := pts[j]
	var d := (pts[j + 1] - a) / seg if seg > 0.0 else Vector2.UP
	var q := a + d * (s - cum[j]) + Vector2(-d.y, d.x) * w_side[i]
	w_yaw[i] = atan2(-d.x, -d.y)
	return Vector3(q.x, lerpf(ys[j], ys[j + 1], f), q.y)


func _seen(at: Vector3) -> bool:
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	return Vector2(eye3.x, eye3.z).distance_to(Vector2(at.x, at.z)) < LINE_VIEW and (not on_screen.is_valid() or on_screen.call(at, 2.0))


## The patrol car by the gate comes with the fans and goes with them (police.gd club_park).
func _police(out: bool) -> void:
	if police == null or not police.has_method("club_park"):
		return
	for g in groups:
		if not bool(g["police"]):
			continue
		if out:
			var a: Vector2 = g["at"]
			var spot: Dictionary = police.club_park("kibice_%s" % g["id"], a + (g["along"] as Vector2) * (float(g["half"]) + 6.0))
			if not spot.is_empty():
				g["officer"] = {"p": spot["officer"], "yaw": float(spot.get("officer_yaw", 0.0))}
		else:
			police.club_leave("kibice_%s" % g["id"])
			g["officer"] = {}


## A group's lines: the car slow by it (`car`), else chat (or the kid's) while on screen near the
## view; the toast the first time the car meets the fans.
func _talk(g: Dictionary, step: float, eye: Vector2, car2: Vector2, kmh: float) -> void:
	if int(g["n"]) == 0:
		return
	var a2: Vector2 = g["at"]
	if car2 != Vector2.INF and not bool(g["met"]) and car2.distance_to(a2) < MEET_R:
		g["met"] = true
		meets += 1
		if meets == 1 and hud != null and hud.has_method("ambient_toast"):
			hud.ambient_toast("Kibice pod Stadionem Leguminy", "Football fans outside Stadion Leguminy")
	g["line_t"] = float(g["line_t"]) - step
	if float(g["line_t"]) > 0.0:
		return
	var at := _ground(a2)
	var slow := car2 != Vector2.INF and car2.distance_to(a2) < CAR_NEAR and kmh < CAR_KMH
	if not slow and not _seen(at):
		return
	g["line_t"] = _rng.randf_range(LINE_GAP.x, LINE_GAP.y)
	var off: Dictionary = g["officer"]
	var roll := _rng.randf()
	var inside := float(g["share"]) < 1.0
	if not off.is_empty() and roll < 0.25:
		var op: Vector3 = off["p"]
		_say(func() -> Vector3: return op + Vector3(0, 2.2, 0), "Sierżant Bogdan", "police_kibice", "", false, POLICE_BUBBLE)
	elif slow:
		_say(_anchor_of(g, -1), "", "kibice", "car", true)
	elif inside:
		# The few left outside during the match: the radio, the stands' roar.
		_say(_anchor_of(g, -1), "", "kibice", "match")
	elif roll < 0.45:
		_say(_anchor_of(g, _role_index(g, "kid")), "", "kibice", "kid")
	else:
		_say(_anchor_of(g, -1), "", "kibice", "")


func _role_index(g: Dictionary, role: String) -> int:
	var slots: Array = g["slots"]
	for i in mini(int(g["n"]), slots.size()):
		if slots[i]["role"] == role:
			return i
	return -1


## A bubble's anchor over slot `i` of a group (a random fan's near the front when -1).
func _anchor_of(g: Dictionary, i: int) -> Callable:
	var slots: Array = g["slots"]
	var n := mini(int(g["n"]), slots.size())
	var k := i if i >= 0 else _rng.randi() % maxi(n, 1)
	if i < 0 and float(g["share"]) < 1.0:
		# During the match: one of the few still outside.
		for j in n:
			if float(slots[j]["ord"]) < float(g["share"]):
				k = j
				break
	var p: Vector3 = slots[mini(k, slots.size() - 1)]["p"]
	return func() -> Vector3: return p + Vector3(0, 2.3, 0)


func _say(anchor: Callable, speaker: String, group: String, tag: String, prefer := false, accent := BUBBLE) -> void:
	if dialogue == null:
		return
	var l: Array = dialogue.say_ambient(anchor, speaker, group, tag, 4.0, accent, 2.3, prefer or tag != "")
	if not l.is_empty():
		lines_said += 1
		if log_on:
			print("fans: line %s/%s: %s" % [group, tag, l[0]])


## The figures, their props and the smoke, 10 times a second while near: the jump and the scarves
## up in a chant, a sway between; the drummer's beat; the puffs rising from the lit sticks.
func move(step: float) -> void:
	if not near:
		return
	# The car (not the heli) and its velocity from the last move (a jump of > 70 m/s is a respawn).
	var car2 := Vector2.INF
	var cv := Vector2.ZERO
	if vehicle.is_valid():
		var veh: Array = vehicle.call()
		var vp: Vector3 = veh[0]
		if vp != Vector3.INF and not bool(veh[2]):
			car2 = Vector2(vp.x, vp.z)
			if _car_prev != Vector2.INF and step > 0.0:
				cv = (car2 - _car_prev) / step
				if cv.length() > 70.0:
					cv = Vector2.ZERO
	_car_prev = car2
	var has_car := car2 != Vector2.INF
	var reach := DODGE_MISS + cv.length() * DODGE_T + CAR_BACK + 1.0
	var reach2 := reach * reach
	var scatter := cv.length() * 3.6 > SCATTER_KMH
	var out_v := STEP_OUT_V * (1.6 if scatter else 1.0) * step
	var back_v := STEP_BACK_V * step
	var nf := 0
	var np := 0
	var nu := 0
	var box := AABB(Vector3(STADIUM.x, 0, STADIUM.y), Vector3.ZERO)
	var pbox := box
	var first := true
	var pfirst := true
	for g in groups:
		var slots: Array = g["slots"]
		var singing := float(g["chant"]) > 0.0
		var secs := t - float(g.get("t0", 0.0))
		var share := float(g["share"])
		# The group makes way only while the car is by it (or someone is still stepping back).
		var by_car := has_car and car2.distance_to(g["at"]) < float(g["half"]) + reach + 6.0
		var dodging := false
		for i in mini(int(g["n"]), slots.size()):
			var s: Dictionary = slots[i]
			if share < 1.0 and float(s["ord"]) >= share:
				continue
			var p: Vector3 = s["p"]
			var hop := 0.0
			if by_car or bool(g["dodging"]):
				var o: Vector2 = s["off"]
				var want := dodge_target(Vector2(p.x, p.z), car2, cv) if by_car else Vector2.ZERO
				var fresh := o == Vector2.ZERO
				o = o.move_toward(want, out_v if want != Vector2.ZERO else back_v)
				s["off"] = o
				if o != Vector2.ZERO:
					dodging = true
					p += Vector3(o.x, 0.0, o.y)
					if want != Vector2.ZERO:
						hop = _made_way(fresh, o, want, scatter, p)
			var role: String = s["role"]
			var ph := float(s["ph"])
			var y := 0.0
			var yaw := float(s["yaw"])
			match role:
				"fan":
					y = jump_at(secs, ph) if singing else absf(sin(t * 1.6 + ph * 3.0)) * 0.02
					if not singing:
						yaw += sin(t * 0.8 + ph * 4.0) * 0.12
				"drum":
					y = absf(sin(t * JUMP_HZ * PI)) * 0.05
				"kid":
					y = jump_at(secs, ph) * 0.6 if singing else 0.0
			var at := p + Vector3(0, maxf(y, hop), 0)
			var scale := Vector3.ONE * (0.68 if role == "kid" else 1.0)
			CityLife.put(_fan_buf, nf, at, yaw, scale, s["shirt"], s["tr"])
			nf += 1
			box = AABB(at, Vector3.ZERO) if first else box.expand(at)
			first = false
			var shape := -1.0
			if role == "kid":
				shape = FINGER
			elif bool(s["scarf"]):
				shape = SCARF_UP if singing or hop > 0.0 else SCARF_NECK
			if shape >= 0.0:
				CityLife.put(_prop_buf, np, at, yaw, scale, s["shirt"], shape)
				np += 1
		var off: Dictionary = g["officer"]
		if not off.is_empty():
			var op: Vector3 = off["p"]
			var oyaw := float(off["yaw"]) + sin(t * 0.3) * 0.2
			CityLife.put(_fan_buf, nf, op, oyaw, Vector3.ONE, OFFICER_SHIRT, 0.1)
			CityLife.put(_prop_buf, np, op, oyaw, Vector3.ONE, OFFICER_SHIRT, CUP)
			nf += 1
			np += 1
			box = box.expand(op)
		g["dodging"] = dodging
		if int(g["n"]) == 0 or share < 1.0:
			continue
		var tips: Array = g["tips"]
		for k in tips.size():
			if not smoke_lit(t, k, float(g["smoke_ph"])):
				continue
			var tip: Vector3 = tips[k]
			for j in PUFFS:
				if nu >= _puff_mm.instance_count:
					break
				var age := fposmod(t / PUFF_LIFE + float(j) / PUFFS + k * 0.37, 1.0)
				var pf := puff_at(age, j)
				var q: Vector3 = tip + (pf[0] as Vector3)
				CityLife.put(_puff_buf, nu, q, j * 0.7 + t * 0.2, Vector3.ONE * float(pf[1]), SMOKE_A.lerp(SMOKE_B, age), 0.0)
				nu += 1
				pbox = AABB(q, Vector3.ZERO) if pfirst else pbox.expand(q)
				pfirst = false
	var nw := 0
	var wbox := box
	var wfirst := true
	if phase == "arrive" or phase == "leave" or (phase == "match" and walking > 0):
		# After kick-off nobody new sets off, but whoever is on the way still gets there, running.
		var dens := walk_density(phase, phase_p)
		var run := running(phase, phase_p) or phase == "match"
		var party := celebrating()
		var back := phase == "leave"
		var speed := 1.1 if party else 1.0
		var bob_hz := 9.0 if run else 5.5
		var bob := 0.06 if run else 0.025
		var kid_scale := Vector3.ONE * 0.68
		walking = 0
		var ri := -1
		var pts := PackedVector2Array()
		var cum := PackedFloat32Array()
		var ys := PackedFloat32Array()
		var len := 0.0
		for i in walker_count:
			if w_route[i] != ri:
				ri = w_route[i]
				var r: Dictionary = routes[ri]
				pts = r["rpts"] if back else r["pts"]
				cum = r["rcum"] if back else r["cum"]
				ys = r["rys"] if back else r["ys"]
				len = float(r["len"])
			var s := w_s[i] + (RUN_V if run else w_v[i] * speed) * step
			if s >= len:
				# The end of the way (the gate, or the stop): a new bunch sets off from the start.
				s = fposmod(s, len)
				w_lap[i] += 1
				w_show[i] = 1 if clump_roll(w_clump[i], w_lap[i]) < dens else 0
			w_s[i] = s
			if w_show[i] == 0:
				continue
			walking += 1
			var at := _walker_on(i, pts, cum, ys)
			var yaw := w_yaw[i]
			at.y += absf(sin(t * bob_hz + w_ph[i])) * bob
			var hop := 0.0
			var o := w_off[i]
			if has_car and (o != Vector2.ZERO or Vector2(at.x, at.z).distance_squared_to(car2) < reach2):
				var want := dodge_target(Vector2(at.x, at.z), car2, cv)
				var fresh := o == Vector2.ZERO
				o = o.move_toward(want, out_v if want != Vector2.ZERO else back_v)
				w_off[i] = o
				if want != Vector2.ZERO:
					hop = _made_way(fresh, o, want, scatter, at + Vector3(o.x, 0.0, o.y))
			elif o != Vector2.ZERO:
				o = o.move_toward(Vector2.ZERO, back_v)
				w_off[i] = o
			at += Vector3(o.x, hop, o.y)
			var shape := w_prop[i]
			var scale := kid_scale if shape == FINGER else Vector3.ONE
			CityLife.put(_walk_buf, nw, at, yaw, scale, w_shirt[i], w_tr[i])
			nw += 1
			wbox = AABB(at, Vector3.ZERO) if wfirst else wbox.expand(at)
			wfirst = false
			if shape == SCARF_NECK and ((party and sin(t * 0.9 + w_ph[i] * 3.0) > 0.55) or hop > 0.0):
				shape = SCARF_UP
			if shape >= 0.0:
				CityLife.put(_prop_buf, np, at, yaw, scale, w_shirt[i], shape)
				np += 1
				box = box.expand(at)
	else:
		walking = 0
	_send(_walk_mm, _walk_mmi, _walk_buf, nw, wbox, 2.8)
	_send(_fan_mm, _fan_mmi, _fan_buf, nf, box, 2.8)
	_send(_prop_mm, _prop_mmi, _prop_buf, np, box, 3.2)
	_send(_puff_mm, _puff_mmi, _puff_buf, nu, pbox, 1.2)


## A fan stepping aside (at `o` of its `want` offset, now at `at`; `first` its first step): the hop
## when the car is fast (m, 0 when only walking aside or once out), the count, a `dodge` line now
## and then.
func _made_way(first: bool, o: Vector2, want: Vector2, scatter: bool, at: Vector3) -> float:
	if first:
		dodges += 1
		if scatter and t - _dodge_line_at > DODGE_LINE_GAP and _seen(at):
			_dodge_line_at = t
			var a := at + Vector3(0, 2.3, 0)
			_say(func() -> Vector3: return a, "", "kibice", "dodge", true)
	if not scatter or o.distance_squared_to(want) < 0.0001:
		return 0.0
	return absf(sin(t * 11.0 + at.x)) * HOP


func _send(mm: MultiMesh, mmi: MultiMeshInstance3D, buf: PackedFloat32Array, n: int, box: AABB, up: float) -> void:
	mm.visible_instance_count = n
	if n > 0:
		InstanceBuffers.send(mm.get_rid(), buf)
		mm.custom_aabb = box.grow(1.5).expand(box.end + Vector3(0, up, 0))
	if mmi.visible != (n > 0):
		mmi.visible = n > 0


## "18:30 day 6 · out, near · brama 24, naroznik 18, trasa 16 · chants 3 · lines 5".
func summary() -> String:
	var gs := PackedStringArray()
	for g in groups:
		gs.append("%s %d%s" % [g["id"], g["n"], " (singing)" if float(g["chant"]) > 0.0 else ""])
	return "%02d:%02d day %d · %s%s · %s · %s%s, %d walking · chants %d · lines %d · meets %d · dodges %d" % [int(_hour),
			int(fmod(_hour, 1.0) * 60.0), _weekday, "out" if on else "home", ", near" if near else "", ", ".join(gs),
			phase if phase != "" else "quiet", (" (%s)" % result) if result != "" else "", walking, chants, lines_said, meets, dodges]
