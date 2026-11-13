extends Node
## Loop 2d-1: Podwózka's "GPS moments" in traffic (docs/design/parodies.md 3.2). Every 45 to 90 s
## one app-taxi (traffic kind TAXI, shape podwozka: the phone on the roof, loop 2c) within 80 m of
## the view's centre, on screen and not behind a building does one of three things, never two
## at once:
## - "You have arrived": stops dead in its lane for 4 s, then goes; the cars behind wait (one may
##   shout a `traffic` line);
## - Recalculating: takes the way back at the next junction where a U-turn is possible;
## - The river: on a road along the Vistula (rides.gd's river spots), pulls up where the road
##   comes nearest the granite edge, waits 3 s, turns away.
## The driver says a `podwozka_driver` line. No new geometry: the cars are traffic's own.

## Seconds between moments, and between tries when no app-taxi is in view.
const GAP := Vector2(45.0, 90.0)
const RETRY := 1.0
## Only this close to the view's centre (and on screen), so it is seen.
const NEAR := 80.0
## traffic.gd Kind.TAXI and models.gd TRAFFIC[1]'s podwozka shape.
const APP_KIND := 1
const APP_SHAPE := 1
const ARRIVE_HOLD := 4.0
const RIVER_HOLD := 3.0
## The junction ahead must be this far (m) for a GPS U-turn to read as one.
const TURN_MIN := 15.0
const TURN_MAX := 140.0
const SPEAKER := "Podwózka"
const Chatter := preload("res://scripts/chatter.gd")
const COLOUR := Color("#e8f4ff")

var traffic: Node3D
var dialogue: Node
## --parody-log: print a `gps:` line for each moment.
var log_on := false
## --gps-in=S (testing, screenshots): the first moment is looked for S seconds in.
var first_in := -1.0
## A Podwózka card is up (rides.gd): no new moment, and a driver's bubble already up is hushed.
var held := false:
	set(v):
		if v and not held and _anchor.is_valid():
			dialogue.bubbles.hush(_anchor)
		held = v
var _anchor := Callable()
## How long the last update took, for --bench (µs).
var last_usec := 0
## Moments done this session.
var count := 0
## Edge -> [s, metres to the water]: where it passes nearest a river spot (rides.gd fills it
## when its spots are found).
var river_edges := {}

var _wait := 0.0
var _d = null
var _slot := -1
var _edge := -1
var _kind := ""
var _t := 0.0
var _stop_s := -1.0
var _stopped := false
var _turned := false
var _shouted := false
var _rng := RandomNumberGenerator.new()
var _clock := 0.0


func _ready() -> void:
	_rng.randomize()
	_wait = first_in if first_in >= 0.0 else _rng.randf_range(GAP.x, GAP.y) * 0.5


func _process(dt: float) -> void:
	if traffic == null or dt <= 0.0:
		return
	var t0 := Time.get_ticks_usec()
	_clock += dt
	if _d != null:
		_run(dt)
	elif held:
		_wait = maxf(_wait, RETRY)
	else:
		_wait -= dt
		if _wait <= 0.0:
			_wait = RETRY if not _try() else _rng.randf_range(GAP.x, GAP.y)
	last_usec = Time.get_ticks_usec() - t0


## Picks an app-taxi in view and starts a moment with it; false if there was none.
func _try() -> bool:
	var g = traffic.graph
	var centre: Vector2 = traffic.view_centre
	for d in traffic.drivers():
		if d.kind != APP_KIND or d.shape != APP_SHAPE or d.ghost or d.node != null or not d.visible \
				or d.in_conn or d.v < 3.0 or d.stun > 0.0:
			continue
		if Vector2(d.pos.x - centre.x, d.pos.z - centre.y).length() > NEAR or not _in_middle(d) or _hidden(d):
			continue
		var e: int = d.edge
		var rev: int = g.e_reverse[e]
		var ahead: float = g.e_s1[e] - d.s
		var can_turn: bool = rev >= 0 and rev in g.node_out[g.e_b[e]] and g.node_out[g.e_b[e]].size() >= 3 \
				and ahead > TURN_MIN and ahead < TURN_MAX
		if river_edges.has(e) and float(river_edges[e][0]) > d.s + 8.0:
			_begin(d, "river")
			_stop_s = river_edges[e][0]
		elif can_turn and _rng.randf() < 0.5:
			_begin(d, "reroute")
			traffic.turn_next(d, rev)
			_turned = true
			_say("reroute")
			_log("recalculating: a U-turn at the junction %d m ahead" % roundi(ahead))
		else:
			_begin(d, "arrive")
			_hold(ARRIVE_HOLD)
			_say("arrive")
			_log("\"you have arrived\": stops in its lane for %d s" % roundi(ARRIVE_HOLD))
		return true
	return false


## In the middle 70 % of the view (on screen isn't enough: a car at the edge is under the HUD,
## and its bubble would point off the screen).
func _in_middle(d) -> bool:
	var cam: Camera3D = traffic.cam
	if cam == null:
		return true
	var size: Vector2 = cam.get_viewport().get_visible_rect().size
	return Rect2(size * 0.15, size * 0.7).has_point(cam.unproject_position(d.pos))


## Behind a building as the camera sees it (the bubble would point at a roof): steps up the view
## line from the car towards the camera against the map's roof heights (the colliders are only
## 2 m walls).
func _hidden(d) -> bool:
	var cam: Camera3D = traffic.cam
	var map: Node3D = traffic.map
	if cam == null or map == null:
		return false
	var back: Vector3 = cam.global_basis.z
	if back.y < 0.1:
		return false
	var at: Vector3 = d.pos + Vector3(0, 1.0, 0)
	var t := 3.0
	while t < 400.0 and at.y + back.y * t < 260.0:
		var p := at + back * t
		if float(map.top_height(p.x, p.z)) > p.y:
			return true
		t += 4.0
	return false


func _begin(d, kind: String) -> void:
	_d = d
	_slot = d.slot
	_edge = d.edge
	_kind = kind
	_t = 0.0
	_stop_s = -1.0
	_stopped = false
	_turned = false
	_shouted = false


## The moment under way; it ends when its car has done it (or has gone: pooled for another).
func _run(dt: float) -> void:
	_t += dt
	var d = _d
	if not d.active or d.slot != _slot or d.kind != APP_KIND:
		_end()
		return
	var g = traffic.graph
	match _kind:
		"arrive":
			# The car behind waits; after a moment one driver loses patience.
			if not _shouted and _t > 2.0:
				_shouted = true
				var behind = _behind(d)
				if behind != null:
					dialogue.on_driver_blocked(behind)
			if _t > ARRIVE_HOLD + 3.0 and d.stun <= 0.0:
				_end()
		"reroute":
			if (d.edge == g.e_reverse[_edge] and not d.in_conn) or _t > 20.0:
				_end()
		"river":
			if not _stopped:
				if d.in_conn or not river_edges.has(d.edge) or _t > 25.0:
					_end()  # it turned off before the river: no moment after all
				elif d.s >= _stop_s - 2.0:
					_stopped = true
					_hold(RIVER_HOLD)
					_say("river")
					_log("the river: pulls up %d m from the water's edge, waits %d s, turns away" % [
							roundi(float(river_edges[d.edge][1])), roundi(RIVER_HOLD)])
			elif not _turned and d.stun <= 0.0:
				_turned = true
				var rev: int = g.e_reverse[d.edge]
				if rev >= 0:
					traffic.turn_next(d, rev)
			elif _turned and (d.in_conn or _t > 15.0):
				_end()


func _end() -> void:
	_d = null


## Stops the car where it is for `seconds` (traffic.gd holds a stunned car still).
func _hold(seconds: float) -> void:
	_d.stun = seconds + _d.v / 8.0


func _say(tag: String) -> void:
	if dialogue == null:
		return
	var d = _d
	var slot: int = d.slot
	var anchor := func() -> Vector3:
		if not d.active or d.slot != slot or d.kind != APP_KIND:
			return Vector3.INF
		return d.pos + Vector3(0, d.size.y + 0.6, 0)
	_anchor = anchor
	if not held:
		# Flavour (F 2026-11-11: it talked over a race): ambient in the chatter budget, so it keeps
		# quiet during a quest, a chase, fast driving and while a card is up.
		dialogue.say(anchor, SPEAKER, "podwozka_driver", tag, 3.2, COLOUR, 2.6, true, Chatter.AMBIENT)


## The nearest car behind d in its lane, within 25 m (or null).
func _behind(d):
	var best = null
	var best_gap := 25.0
	for o in traffic.drivers():
		if o == d or o.edge != d.edge or o.lane != d.lane or o.in_conn or o.ghost or o.node != null:
			continue
		var gap: float = d.s - o.s
		if gap > 0.0 and gap < best_gap:
			best_gap = gap
			best = o
	return best


func _log(what: String) -> void:
	count += 1
	if log_on:
		var p: Vector3 = _d.pos
		print("gps: moment %d at %.0f s, %d,%d: %s (one at a time)" % [count, _clock, roundi(p.x), roundi(p.z), what])
