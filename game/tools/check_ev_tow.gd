extends SceneTree
## Dead electric cars (scripts/ev_tow.gd, F's ask 2026-11-06): their rules headless, from the
## committed map data (map/centrum.json: the lane graph) and data/dialogue.json; seeded:
##   1. the meshes: the TESŁO, its hazards, the rope and the charger one surface each (one draw
##      call apiece), the car within its SIZE box;
##   2. the lines: Bartek's `ev_tow` tags (hello, hook, carry 12+, swing, drop, stranger), the
##      stranded drivers' `ev_stranded` (8+), KEBAB FM's `ev` lines naming {street} in both
##      languages; Polish and English, bubbles under 90 characters, no real brand (the denylist
##      holds "tesla" and friends);
##   3. the rope: a car let go beside a still hook swings and settles straight under it at the
##      rope's length, never further; the loaded helicopter speeding up drags it behind and it hangs back
##      down when the hook stops; a floor under the hook holds the car up (resting);
##   4. a roof above the hook is a wall, not a floor (Autopilot run 2026-11-06); the hooking and the pay: within reach, low and slow hooks; too far, too high, inside the
##      roof or too fast doesn't; a quick carry adds the bonus, a stranger tips less;
##   5. the real lane graph: every charger found by its place (bay within 200 m, totem off the
##      carriageway); pick_charger gives one at least 600 m away when there is one; Bartek's car
##      found from 40 seeded places at 450-1050 m on edges the traffic can go round;
##   6. the play, on the activity kit (activity.gd) with stand-ins for the HUD, the dialogue, the
##      wallet, the rescue calls, the traffic and the helicopter (the script's own `_process`, a
##      frame at a time; the cards are pressed through the stand-in HUD, which sends a press to
##      the card's owner as hud.gd does): Bartek's clock (it stands while something else is on,
##      and asks the tow's own test, not the director's `world_free`: the tow may start from the
##      air); a call missed, declined, answered; an offer missed, declined, and none when no road
##      has room; LECĘ! on the ground (the take-off) and in the air; the pickup ring and the
##      bay's; the hook's rules in flight; the carry, the set-down, the pay and the result card;
##      the car's ten seconds on the bay, ended early by flying off; the ✕ before the hook and
##      with the car on the rope; a stranded car hooked on with no call, its tip, and Bartek's
##      clock left alone; the rescue calls held (the stand-in joined to the director) and left as main.gd had them; the director.
## Prints "check_ev_tow: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_ev_tow.gd [-- --verbose]

const EvTow := preload("res://scripts/ev_tow.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Heli := preload("res://scripts/heli.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Fakes := preload("res://tools/fakes.gd")
const BUBBLE := 90
const DT := 1.0 / 60.0


## The helicopter as the tow reads it: where it is, how fast, and the load on its sling.
class Sling extends Node3D:
	var sling := 0.0
	var vel := Vector3.ZERO
	var vy := 0.0
	var v := 0.0
	func speed() -> float:
		return v


## A lane held in the traffic (traffic.gd's parked Driver).
class Held extends RefCounted:
	var ghost := false
	var visible := true


## The traffic as the tow uses it: lanes held by an unseen parked car, and given back.
class Lanes extends Node3D:
	var held: Array[Held] = []
	var seen := false
	var free := true
	func on_screen(_p: Vector3, _h: float) -> bool:
		return seen
	func lane_free(_e: int, _lane: int, _s0: float, _s1: float, _room: float) -> bool:
		return free
	func add_parked_car(_e: int, _s: float, _at: Vector3, _yaw: float, _lane: int, _shape: int, _paint: Color) -> Held:
		var d := Held.new()
		held.append(d)
		return d
	func drop_parked(d: Held) -> void:
		held.erase(d)


var problems: Array[String] = []
var verbose := false

# The play's stand-ins and inputs.
var _tow: EvTow
var _hud: Fakes.Hud
var _talk: Fakes.Dialogue
var _wallet: Fakes.Wallet
var _calls: Fakes.Calls
var _lanes: Lanes
var _heli: Sling
var _director: Activities
var _other: Activity
var _pos := Vector3.ZERO
var _flying := false
var _free := true
var _took_off := 0
var _checks := 0


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_meshes(digest)
	_check_lines(digest)
	_check_rope(digest)
	_check_rules(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	_check_map(g, map, digest)
	var sp: Dictionary = data.get("spawn", {})
	_check_play(g, map, Vector3(float(sp.get("x", 0.0)), 0.0, float(sp.get("z", 0.0))), digest)
	if problems.is_empty():
		print("check_ev_tow: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_ev_tow: %d problems" % problems.size())
		quit(1)


func _check_meshes(digest: PackedStringArray) -> void:
	var tris := 0
	for row: Array in [["car", EvTow.car_mesh()], ["hazards", EvTow.hazard_mesh()], ["rope", EvTow.rope_mesh()], ["charger", EvTow.charger_mesh()]]:
		var m: ArrayMesh = row[1]
		if m.get_surface_count() != 1:
			problems.append("%s: %d surfaces (want 1)" % [row[0], m.get_surface_count()])
		tris += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	var box := EvTow.car_mesh().get_aabb()
	var want := EvTow.SIZE
	if box.size.x > want.x + 0.05 or box.size.z > want.z + 0.1 or box.size.y > want.y + 0.05 or box.position.y < -0.01:
		problems.append("car mesh %s is outside its SIZE %s" % [box.size, want])
	digest.append("4 meshes, %d triangles, car %.2f×%.2f×%.2f m" % [tris, box.size.x, box.size.y, box.size.z])


func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	if not "tesla" in banned:
		problems.append("brand_denylist: 'tesla' missing")
	var by_tag := {}
	for l: Array in all.get("ev_tow", []):
		var only: String = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
		by_tag[only] = int(by_tag.get(only, 0)) + 1
		_line_ok("ev_tow", l, banned)
	for tag: String in ["hello", "hook", "carry", "swing", "drop", "stranger"]:
		var want := 12 if tag == "carry" else 1
		if int(by_tag.get(tag, 0)) < want:
			problems.append("ev_tow: %d lines tagged %s (want %d+)" % [int(by_tag.get(tag, 0)), tag, want])
	if by_tag.has(""):
		problems.append("ev_tow: %d lines without a tag" % by_tag[""])
	var stranded: Array = all.get("ev_stranded", [])
	for l: Array in stranded:
		_line_ok("ev_stranded", l, banned)
	if stranded.size() < 8:
		problems.append("ev_stranded: %d lines (want 8+)" % stranded.size())
	var radio := 0
	for l: Array in all.get("radio_host", []):
		if l.size() > 2 and (l[2] as Dictionary).get("only", "") == "ev":
			radio += 1
			if not String(l[0]).contains("{street}") or not String(l[1]).contains("{street}"):
				problems.append("radio ev line without {street}: %s" % l[0])
			_line_ok("radio_host", l, banned, 200)
	if radio < 2:
		problems.append("radio_host: %d ev lines (want 2+)" % radio)
	# The name on the cards, too.
	for text: String in [EvTow.NAME, EvTow.MODEL, EvTow.CALLER]:
		_line_ok("names", [text, text], banned)
	digest.append("lines %s, stranded %d, radio %d" % [by_tag, stranded.size(), radio])


func _line_ok(group: String, l: Array, banned: Array, most := BUBBLE) -> void:
	if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
		problems.append("%s: a line without its Polish or English: %s" % [group, l])
		return
	if String(l[0]).length() >= most:
		problems.append("%s: %d characters (under %d): %s" % [group, String(l[0]).length(), most, l[0]])
	for text: String in [String(l[0]).to_lower(), String(l[1]).to_lower()]:
		for b in banned:
			var rx := RegEx.create_from_string("(^|[^\\p{L}])" + _escape(String(b)) + "($|[^\\p{L}])")
			if rx.search(text) != null:
				problems.append("%s: a real brand (%s): %s" % [group, b, l[0]])


static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += "\\" + c if c in ".+*?^$()[]{}|\\" else c
	return out


func _check_rope(digest: PackedStringArray) -> void:
	var dt := 1.0 / 60.0
	var anchor := Vector3(0, 50, 0)
	# Let go 6 m to the side, level with the hook minus 8 m: it swings and settles under it.
	var p := Vector3(6, 42, 0)
	var v := Vector3.ZERO
	var longest := 0.0
	for i in 60 * 30:
		var r := EvTow.swing_step(p, v, anchor, Vector3.ZERO, EvTow.ROPE, dt, -100.0)
		p = r[0]
		v = r[1]
		longest = maxf(longest, p.distance_to(anchor))
	if longest > EvTow.ROPE + 0.01:
		problems.append("rope stretched to %.2f m (rope %.1f)" % [longest, EvTow.ROPE])
	if Vector2(p.x, p.z).length() > 0.3 or absf(p.y - (anchor.y - EvTow.ROPE)) > 0.1:
		problems.append("after 30 s the car hangs at %s, not under the hook at %.1f m" % [p, EvTow.ROPE])
	# The helicopter speeding up to its loaded top speed for 8 s: the car trails behind (swings back), then hangs down again.
	var trail := 0.0
	var a := anchor
	var sp := 0.0
	var top := Heli.MAX_SPEED * (1.0 - Heli.LOAD_SLOW)
	for i in 60 * 8:
		# heli.gd's easing with the sling on.
		sp = lerpf(sp, top, 1.0 - exp(-1.3 * (1.0 - Heli.LOAD_EASE) * dt))
		a += Vector3(sp * dt, 0, 0)
		var r := EvTow.swing_step(p, v, a, Vector3(sp, 0, 0), EvTow.ROPE, dt, -100.0)
		p = r[0]
		v = r[1]
		trail = maxf(trail, EvTow.swing_angle(p, a))
	if trail < 0.15 or trail > 0.9:
		problems.append("the loaded helicopter swings the car %.2f rad (want 0.15-0.9: it trails, it doesn't fly level)" % trail)
	for i in 60 * 40:
		var r := EvTow.swing_step(p, v, a, Vector3.ZERO, EvTow.ROPE, dt, -100.0)
		p = r[0]
		v = r[1]
	if EvTow.swing_angle(p, a) > 0.05:
		problems.append("40 s after the hook stops the car still swings %.2f rad" % EvTow.swing_angle(p, a))
	# A floor 4 m under the hook: the car rests on it, its roof SIZE.y above.
	var floor_y := a.y - 4.0 - EvTow.SIZE.y
	var resting := false
	for i in 60 * 3:
		var r := EvTow.swing_step(p, v, a, Vector3.ZERO, EvTow.ROPE, dt, floor_y)
		p = r[0]
		v = r[1]
		resting = r[2]
	if not resting or p.y < floor_y + EvTow.SIZE.y - 0.01:
		problems.append("the car went through the floor (%.2f, floor %.2f) or isn't resting" % [p.y - EvTow.SIZE.y, floor_y])
	digest.append("rope ≤ %.2f m, swings %.2f rad at full speed, settles, rests on a floor" % [longest, trail])


func _check_rules(digest: PackedStringArray) -> void:
	# A roof higher than the hook is a wall, one under it a floor (Autopilot run 2026-11-06).
	if not EvTow.is_wall(108.0, 59.0) or EvTow.is_wall(20.0, 59.0) or not EvTow.is_wall(58.0, 59.0):
		problems.append("is_wall: a 108 m roof under a 59 m hook must be a wall, a 20 m one a floor")
	if not EvTow.can_hook(3.0, 6.0, 2.0):
		problems.append("can_hook: 3 m off, 6 m above, 2 m/s doesn't hook")
	for row: Array in [[EvTow.HOOK_R + 1.0, 6.0, 2.0, "too far"], [3.0, EvTow.ROPE + 3.0, 2.0, "too high"],
			[3.0, 0.0, 2.0, "inside the roof"], [3.0, 6.0, EvTow.HOOK_SPEED + 2.0, "too fast"]]:
		if EvTow.can_hook(row[0], row[1], row[2]):
			problems.append("can_hook: hooks when %s" % row[3])
	var quick: Array = EvTow.pay(false, 60.0)
	var slow: Array = EvTow.pay(false, EvTow.QUICK + 30.0)
	var tip: Array = EvTow.pay(true, 60.0)
	if int(quick[0]) != EvTow.PAY + EvTow.BONUS or int(slow[0]) != EvTow.PAY or int(slow[2]) != 0:
		problems.append("pay: quick %s, slow %s" % [quick, slow])
	if int(tip[0]) >= int(slow[0]) or int(tip[1]) >= int(slow[1]):
		problems.append("a stranger's tip %s is not less than Bartek's %s" % [tip, slow])
	var list := [{"at": Vector3(100, 0, 0)}, {"at": Vector3(900, 0, 0)}, {"at": Vector3(2000, 0, 0)}]
	if EvTow.pick_charger(list, Vector2.ZERO, 600.0) != 1 or EvTow.pick_charger(list, Vector2.ZERO, 600.0, true) != 0 \
			or EvTow.pick_charger(list, Vector2.ZERO, 5000.0) != 2:
		problems.append("pick_charger: wrong choices")
	digest.append("hook and pay rules, Bartek %d-%d zł, tip %d zł" % [slow[0], quick[0], tip[0]])


func _check_map(g: LaneGraph, map: Node3D, digest: PackedStringArray) -> void:
	var found := EvTow.find_chargers(g, map)
	if found.size() != EvTow.CHARGERS.size():
		problems.append("chargers: %d of %d found" % [found.size(), EvTow.CHARGERS.size()])
	for c: Dictionary in found:
		var place: Vector2 = Vector2.INF
		for d: Dictionary in EvTow.CHARGERS:
			if d["id"] == c["id"]:
				place = d["at"]
		var bay := Vector2(c["at"].x, c["at"].z)
		if bay.distance_to(place) > 200.0:
			problems.append("charger %s: bay %.0f m from its place" % [c["id"], bay.distance_to(place)])
		var side := Vector2(c["side"].x, c["side"].z)
		var e: int = c["e"]
		var half := absf(g.lane_offset(e, int(c["lane"]))) + g.e_lw[e] * 0.5
		if side.distance_to(g.point_at(e, float(c["s"]))) < half:
			problems.append("charger %s: its totem stands on the carriageway" % c["id"])
		if verbose:
			print("  charger %s at %d,%d (%s)" % [c["id"], roundi(bay.x), roundi(bay.y), g.e_name[e]])
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var ok := 0
	var far := 0
	for i in 40:
		var from := Vector2(rng.randf_range(-2400.0, 900.0), rng.randf_range(-1500.0, 1500.0))
		var spot := EvTow.pick_car_spot(g, from, EvTow.CAR_FROM, EvTow.CAR_TO, rng)
		if spot.is_empty():
			continue
		ok += 1
		var e: int = spot["e"]
		if not EvTow.fits(g, e) or int(spot["lane"]) != g.e_lanes[e] - 1:
			problems.append("car spot on edge %d lane %d doesn't fit" % [e, spot["lane"]])
		var p: Array = EvTow.pose(g, spot)
		var d := from.distance_to(Vector2(p[0].x, p[0].z))
		if d < EvTow.CAR_FROM - 80.0 or d > EvTow.CAR_TO + 80.0:
			problems.append("car spot %.0f m away (want %.0f-%.0f)" % [d, EvTow.CAR_FROM, EvTow.CAR_TO])
		if not found.is_empty():
			var k := EvTow.pick_charger(found, Vector2(p[0].x, p[0].z), 600.0)
			if Vector2(p[0].x, p[0].z).distance_to(Vector2(found[k]["at"].x, found[k]["at"].z)) >= 600.0:
				far += 1
	if ok < 34:
		problems.append("Bartek's car placed from only %d of 40 places" % ok)
	digest.append("%d chargers, car spots %d/40 (charger 600 m+ away for %d)" % [found.size(), ok, far])


# --- the play ---------------------------------------------------------------------------------------

func _ok(good: bool, what: String) -> void:
	_checks += 1
	if not good:
		problems.append("the play: " + what)


func _frames(seconds: float) -> void:
	for i in roundi(seconds / DT):
		_tow._process(DT)


func _is(stage: int) -> bool:
	return _tow.phase == Activity.Phase.RUN and _tow.stage == stage


## The last toast has `text` in it.
func _toasted(text: String) -> bool:
	return not _hud.toasts.is_empty() and text in _hud.toasts[-1]


## How many lines of "group:tag" (or of the whole group, "group:") were asked for so far.
func _said(key: String) -> int:
	var n := 0
	for line in _talk.said:
		if line == key or (key.ends_with(":") and line.begins_with(key)):
			n += 1
	return n


func _solid(b: StaticBody3D) -> bool:
	return b.process_mode == Node.PROCESS_MODE_INHERIT and b.collision_layer == 1


## The helicopter hovering at `p` (or passing it at `speed` m/s).
func _hover(p: Vector3, speed := 0.0) -> void:
	_flying = true
	_heli.global_position = p
	_heli.vel = Vector3.ZERO
	_heli.vy = 0.0
	_heli.v = speed


## Flies there in a straight line at `speed` m/s, a frame at a time.
func _fly_to(dest: Vector3, speed: float) -> void:
	_flying = true
	var p := _heli.global_position
	while p.distance_to(dest) > speed * DT:
		var dir := (dest - p).normalized()
		p += dir * speed * DT
		_heli.global_position = p
		_heli.vel = Vector3(dir.x, 0.0, dir.z) * speed
		_heli.vy = dir.y * speed
		_heli.v = _heli.vel.length()
		if _heli.v > 0.5:
			_heli.rotation.y = atan2(-dir.x, -dir.z)
		_tow._process(DT)
	_hover(dest)
	_tow._process(DT)


## Bartek rings, the call is answered, LECĘ! pressed.
func _take() -> void:
	_tow.ring()
	_hud.press(0)
	_hud.press(0)


## Low and slow over the car until the sling hooks on.
func _hook_on() -> void:
	var car: Vector3 = _tow.job["at"]
	_hover(car + Vector3(2.0, 8.0, 1.0))
	_frames(1.3)


## Up with the car, across to the bay, down until it rests there.
func _carry_home() -> void:
	var p := _heli.global_position
	_fly_to(Vector3(p.x, 45.0, p.z), 7.0)
	var bay: Vector3 = _tow.chargers[_tow.target]["at"]
	_fly_to(Vector3(bay.x, 45.0, bay.z), 30.0)
	_frames(2.0)
	_fly_to(bay + Vector3(0.0, 10.4, 0.0), 6.0)
	_frames(3.0)


func _check_play(g: LaneGraph, map: Node3D, spawn: Vector3, digest: PackedStringArray) -> void:
	var world := Node3D.new()
	root.add_child(world)
	_hud = Fakes.Hud.new()
	_talk = Fakes.Dialogue.new()
	_wallet = Fakes.Wallet.new()
	_calls = Fakes.Calls.new()
	_lanes = Lanes.new()
	_heli = Sling.new()
	_other = Activity.new()   # another activity of the kit, to be "on"
	for node: Node in [_hud, _talk, _wallet, _calls, _lanes, _heli, _other]:
		world.add_child(node)
	_other.set_process(false)
	var t := EvTow.new()
	_tow = t
	t.hud = _hud
	t.dialogue = _talk
	t.wallet = _wallet
	t.map = map
	t.graph = g
	t.traffic = _lanes
	t.heli = _heli
	t.vehicle = func() -> Array: return [_heli.global_position if _flying else _pos, 0.0, _flying]
	t.take_off = func() -> void:
		_took_off += 1
		_hover(_pos + Vector3(0.0, 30.0, 0.0))
	world.add_child(t)
	t.setup(world, 7)
	t.set_process(false)
	# The director's `world_free` refuses here (it refuses the air); the tow brings its own test.
	_director = Activities.new()
	_director.world_free = func() -> bool: return false
	_director.add(_other)
	_director.add(t, func() -> bool: return _free)
	_director.add(_calls)
	_pos = spawn
	var b: Node3D = t._beacon
	var fly := EvTow.Stage.FLY
	var carry := EvTow.Stage.CARRY
	var result := EvTow.Stage.RESULT

	# Bartek's clock.
	_ok(t.flown and t.tag == "ev" and not _other.flown, "the tow is the kit's flown activity")
	_ok(t.chargers.size() == EvTow.CHARGERS.size(), "every charger is on the map")
	var first: float = t.call_in
	_ok(first >= EvTow.FIRST_CALL.x and first <= EvTow.FIRST_CALL.y, "the first call is 5 to 8 minutes of free play away")
	_frames(2.0)
	_ok(absf(t.call_in - (first - 2.0)) < 0.3, "Bartek's clock counts in free play (the tow's own test is asked, not `world_free`)")
	var left: float = t.call_in
	_free = false
	_frames(2.0)
	_ok(t.call_in == left, "his clock stands while something outside the kit is on")
	_free = true
	_other.phase = Activity.Phase.RUN
	_frames(2.0)
	_ok(t.call_in == left, "and while another activity of the kit is on")
	_other.phase = Activity.Phase.IDLE
	t.auto = false
	_frames(2.0)
	_ok(t.call_in == left, "and in a test run (no timers)")
	t.auto = true

	# The call.
	t.call_in = 0.4
	_frames(0.8)
	_ok(t.phase == Activity.Phase.RING and "BARTEK" in _hud.card and _hud.buttons == 2, "the phone rings by his clock")
	_ok(not t.busy() and not _director.busy() and not t.ring(), "a ringing phone is not busy, and can't ring twice")
	_hud.abort_pressed.emit()
	_ok(t.phase == Activity.Phase.RING, "the ✕ does nothing on a call")
	_frames(EvTow.RING_LIFE - 1.5)
	_ok(t.phase == Activity.Phase.RING, "the call waits 25 s")
	_frames(2.0)
	_ok(t.idle() and _hud.card == "" and _toasted("Nieodebrane"), "nobody answers: the card goes, a missed call")
	_ok(t.call_in >= EvTow.NEXT_CALL.x and t.call_in <= EvTow.NEXT_CALL.y, "the next call is 12 to 18 minutes away")
	_ok(t.ring(), "he rings when asked (the STORIES tab, --ev-call)")
	_hud.press(1)
	_ok(t.idle() and _hud.card == "" and _toasted("Odrzucono"), "declined: his long text message is promised")

	# The offer.
	t.ring()
	_hud.press(0)
	_ok(t.phase == Activity.Phase.OFFER and "BARTEK" in _hud.card and _hud.buttons == 2, "answered: the offer card, LECĘ! / NIE TERAZ")
	_ok(not t.job.is_empty() and t.target >= 0 and str(t.chargers[t.target]["place"]) in _hud.body and EvTow.NAME in _hud.body,
			"the offer names his car and the charger's place")
	if t.job.is_empty():
		digest.append("the play stopped: no offer")
		return
	var away := Vector2(spawn.x, spawn.z).distance_to(Vector2(t.job["at"].x, t.job["at"].z))
	_ok(away >= EvTow.CAR_FROM - 80.0 and away <= EvTow.CAR_TO + 80.0, "his car stands 450 to 1050 m away (%.0f m)" % away)
	_ok(t.busy() and _director.busy() and _director.busy_tag() == "ev" and _director.current() == t,
			"from the offer card on the tow is busy (the kit's one meaning)")
	_ok(not t._car.visible and _lanes.held.is_empty() and not _calls._held() and not t.has_target(), "nothing is on the road yet")
	_hud.abort_pressed.emit()
	_ok(t.phase == Activity.Phase.OFFER, "the ✕ does nothing on an offer")
	_frames(EvTow.RING_LIFE + 0.5)
	_ok(t.idle() and t.job.is_empty() and _hud.card == "" and _toasted("Nieodebrane"), "an offer nobody answers goes after 25 s")
	t.ring()
	_hud.press(0)
	_hud.press(1)
	_ok(t.idle() and t.job.is_empty() and _toasted("Spoko, poczekam"), "the offer declined: he will wait")
	_pos = Vector3(90000.0, 0.0, 90000.0)
	t.ring()
	_hud.press(0)
	_ok(t.idle() and _hud.card == "" and t.job.is_empty(), "no road has room for his car: no offer, back to idle")
	_pos = spawn

	# The first tow, taken on the ground.
	_take()
	_ok(_is(fly) and _took_off == 1 and _flying and t.calls == 1, "LECĘ! on the ground: up in the helicopter")
	var car: Vector3 = t.job["at"]
	_ok(_calls._held(), "the rescue calls are held")
	_ok(t._car.visible and t._car.global_position.is_equal_approx(car) and _solid(t._body), "his car stands on the road, solid")
	_ok(_lanes.held.size() == 1 and _lanes.held[0].ghost and not _lanes.held[0].visible, "its lane is held in the traffic by an unseen parked car")
	_ok(b.visible and b.pattern == Beacon.Pattern.DASHED and b.waving and b._person.visible and b._colour == EvTow.PICK_COLOUR
			and is_equal_approx(b._ring_radius, EvTow.HOOK_R) and b.position.distance_to(car) < 3.0,
			"the pickup ring: dashed, amber, Bartek waving beside his car")
	_ok(t.has_target() and _director.targeted() == t and t.target_position() == car and t.target_colour() == EvTow.PICK_COLOUR
			and t.stop_spot() == Vector3.INF, "the arrow leads to the car; no stop assist for a ring that is flown to")
	_ok(_toasted("Do śmigłowca"), "the toast sends the player up")
	_flying = false
	_frames(0.5)
	_ok("Do śmigłowca" in _hud.status and _hud.tint == EvTow.PICK_COLOUR, "landed again: the status line says take the helicopter")
	_hover(car + Vector3(30.0, 40.0, 0.0))
	_frames(1.0)
	_ok("Zniż się" in _hud.status and _said("ev_tow:hello") == 1, "30 m off: come down over it; Bartek says hello")
	_frames(2.0)
	_ok(_said("ev_tow:hello") == 1, "he says it once")
	_hover(car + Vector3(0.0, 30.0, 0.0))
	_frames(1.5)
	_hover(car + Vector3(1.0, 8.0, 0.0), EvTow.HOOK_SPEED + 4.0)
	_frames(1.5)
	_ok(_is(fly) and not t.carrying(), "too high, then too fast: no hook")
	_hook_on()
	_ok(_is(carry) and t.carrying(), "low and slow over it for a moment: hooked on")
	var c: Dictionary = t.chargers[t.target]
	var bay: Vector3 = c["at"]
	_ok(_lanes.held.is_empty() and not _solid(t._body) and t._rope.visible and _heli.sling == 1.0,
			"the lane is given back, the car is on the rope, the helicopter loaded")
	_ok(t._totem.visible and t._totem.global_position.is_equal_approx(c["side"]), "the charger's totem stands by its bay")
	_ok(b.visible and b.pattern == Beacon.Pattern.SOLID and not b.waving and not b._person.visible and b._colour == EvTow.COLOUR
			and is_equal_approx(b._ring_radius, EvTow.DROP_R) and b.position.is_equal_approx(bay), "the bay's ring: solid, green, nobody in it")
	_ok(t.target_position() == bay and t.target_colour() == EvTow.COLOUR and _director.targeted() == t, "the arrow leads to the bay")
	_ok(_said("ev_tow:hook") + _said("ev_tow:elektrownia") == 1, "Bartek has a word as it hooks on")
	var p := _heli.global_position
	_fly_to(Vector3(p.x, 45.0, p.z), 7.0)
	_fly_to(Vector3(p.x, 45.0, p.z).lerp(Vector3(bay.x, 45.0, bay.z), 0.5), 30.0)
	_frames(0.5)
	_ok(t.hang.distance_to(_heli.global_position + Vector3(0.0, 0.2, 0.0)) <= EvTow.ROPE + 0.01 and t._car.global_position.y > 20.0,
			"the car hangs on the rope under the helicopter")
	_ok(":" in _hud.count and "Ładowarka przy" in _hud.status and _hud.tint == EvTow.COLOUR, "the status line: the carry's clock and the charger")
	_fly_to(Vector3(bay.x, 45.0, bay.z), 30.0)
	_frames(2.0)
	_ok(_said("ev_tow:carry") >= 1, "Bartek talks on the way")
	_ok("Opuść" in _hud.status, "over the bay: lower it")
	_fly_to(bay + Vector3(0.0, 10.4, 0.0), 6.0)
	_frames(3.0)
	_ok(_is(result), "lowered onto the bay and resting there: set down")
	var want: Array = EvTow.pay(false, float(t.last_pay.get("secs", 0.0)))
	_ok(_wallet.money == int(want[0]) and _wallet.respect == int(want[1]) and _wallet.kinds == ["ev_tow"] and int(want[0]) == EvTow.PAY + EvTow.BONUS,
			"Bartek pays, with the bonus for a quick flight (%d zł)" % _wallet.money)
	_ok(_hud.card == "NAŁADOWANE: 3 %" and _hud.buttons == 1 and str(want[0]) in _hud.body, "the result card names the pay")
	_ok(t.carried == 1 and not t._rope.visible and _heli.sling == 0.0 and not t.has_target() and not b.visible and _hud.status == ""
			and not t.carrying(), "the rope, the load, the ring and the status line are gone")
	_ok(t._car.visible and t._car.global_position.is_equal_approx(bay) and not t._hazards.visible and _solid(t._body)
			and _lanes.held.size() == 1, "the car stands on the bay, its hazards off, its lane held")
	_ok(t.busy() and _director.busy() and _calls._held(), "the tow is still on, the rescue calls still held")
	_hud.abort_pressed.emit()
	_ok(_is(result) and _hud.card != "", "the ✕ does nothing over the result card")
	_hud.hide_card()   # something else takes the card down
	_frames(0.1)
	_ok(_hud.card == "NAŁADOWANE: 3 %", "a result card something else took down goes back up")
	_hud.press(0)
	_ok(_hud.card == "" and _is(result) and t._car.visible, "OK closes the card; the car stays on the bay for a moment")
	_frames(EvTow.RESULT_LIFE - t._result_t - 0.5)
	_ok(_is(result) and t._car.visible, "it stays for ten seconds from the set-down")
	_frames(1.0)
	_ok(t.idle() and not _director.busy() and not t._car.visible and not t._totem.visible and _lanes.held.is_empty() and not _calls._held(),
			"ten seconds after the set-down the car goes; the lane and the rescue calls are given back")
	_ok(t.call_in >= EvTow.NEXT_CALL.x and t.call_in <= EvTow.NEXT_CALL.y and t.job.is_empty() and t.target == -1, "Bartek's next call is drawn")

	# Taken in the air, the rescue calls already held, the card left alone.
	_calls.paused = true
	_hover(spawn + Vector3(100.0, 40.0, 0.0))
	_take()
	_ok(_is(fly) and _took_off == 1, "LECĘ! in the air: no take-off")
	_hook_on()
	_carry_home()
	_ok(_is(result) and _hud.card != "", "the second tow set down")
	_frames(EvTow.RESULT_LIFE + 0.5)
	_ok(t.idle() and _hud.card == "" and not t._car.visible, "a result card nobody presses goes with the car")
	_ok(_calls.paused, "rescue calls that were held before the tow stay held after it")
	_ok(_calls._held(), "rescue calls that were held before the tow stay held after it (the countdown's hold)")
	_calls.paused = false

	# The result ends early when the player flies off.
	_take()
	_hook_on()
	_carry_home()
	_hud.press(0)
	_fly_to(_heli.global_position + Vector3(260.0, 20.0, 0.0), 90.0)
	_ok(t.idle() and t._result_t < EvTow.RESULT_LIFE and not t._car.visible, "flying 220 m off ends the result early")
	_ok(t.carried == 3 and t.calls == 3, "three calls answered, three cars carried")

	# Given up.
	var money := _wallet.money
	_take()
	_frames(1.0)
	_hud.abort_pressed.emit()
	_ok(t.idle() and not t._car.visible and _lanes.held.is_empty() and not _calls._held() and _hud.status == "" and not b.visible
			and _wallet.money == money and _said("ev_tow:drop") == 0, "the ✕ on the way to the car: everything gone, no pay")
	_take()
	_hook_on()
	p = _heli.global_position
	_fly_to(Vector3(p.x, 40.0, p.z), 7.0)
	_hud.abort_pressed.emit()
	_ok(t.idle() and not t._rope.visible and _heli.sling == 0.0 and not t._car.visible and not t._totem.visible and not b.visible
			and _said("ev_tow:drop") == 1 and _wallet.money == money and not _calls._held(), "the ✕ with the car on the rope: Bartek sighs, no pay")

	# The test flags' way in (main.gd `_ev_start`): the kit's presses, then the hook at once.
	t.ring()
	t.card_pressed(0)
	t.card_pressed(0)
	_ok(_is(fly), "--ev-tow: the call and the offer taken at once")
	t._hook()
	_ok(_is(carry) and t._rope.visible, "--ev-tow=carry: the car on the rope at once")
	_hud.abort_pressed.emit()

	# A stranded stranger.
	_flying = false
	_pos = spawn
	t.auto = false
	var placed: bool = t.place_stranded(Vector2(spawn.x, spawn.z), Vector2(0.0, -1.0), true)
	_ok(placed and t._strand_car.visible and _solid(t._strand_body) and _lanes.held.size() == 1 and bool(t.strand.get("stranger", false)),
			"a stranded car stands ahead, its lane held")
	if not placed:
		digest.append("the play stopped: no stranded car")
		return
	var m: Vector3 = t.strand["at"]
	_pos = m + Vector3(20.0, 0.0, 5.0)
	_frames(2.0)
	_ok(_said("ev_stranded:") >= 1, "its driver complains to a player on the ground nearby")
	var bartek: float = t.call_in
	_hover(m + Vector3(50.0, 30.0, 0.0))
	_frames(0.5)
	_ok(_toasted("Rozładowane"), "from the air: the hint to hook it on")
	_free = false
	_hover(m + Vector3(2.0, 8.0, 0.0))
	_frames(1.5)
	_ok(t.idle() and not t.strand.is_empty(), "something else on: it does not hook on")
	_free = true
	_frames(1.3)
	_ok(_is(carry) and bool(t.job.get("stranger", false)) and t.strand.is_empty() and not t._strand_car.visible and t._car.visible,
			"nothing else on: the stranger's car hooks on, with no call")
	_ok(_calls._held() and t.calls == 6 and _took_off == 1 and t.busy() and _director.current() == t,
			"it is a tow like Bartek's (busy, the rescue calls held), but no call of his and no take-off")
	_ok(t.target == EvTow.pick_charger(t.chargers, Vector2(m.x, m.z), 0.0, true), "to the nearest charger")
	_ok(t.strand_in >= EvTow.GAP_STRAND.x and t.strand_in <= EvTow.GAP_STRAND.y, "the next stranded car is 3 to 5 minutes away")
	_ok(_said("ev_tow:stranger") == 1, "the stranger has a word")
	money = _wallet.money
	_carry_home()
	want = EvTow.pay(true, float(t.last_pay.get("secs", 0.0)))
	_ok(_is(result) and _wallet.money - money == int(want[0]) and int(want[0]) < EvTow.PAY and "obcego" in _hud.body, "set down: the stranger's tip (%d zł)" % (_wallet.money - money))
	_hud.press(0)
	_frames(EvTow.RESULT_LIFE)
	_ok(t.idle() and not _calls._held() and t.call_in == bartek, "over; a stranger's tow does not move Bartek's next call")

	# No chargers on the map: no call.
	var kept: Array[Dictionary] = t.chargers
	var none: Array[Dictionary] = []
	t.chargers = none
	_ok(not t.ring() and t.idle(), "no chargers on the map: Bartek does not ring")
	t.chargers = kept
	digest.append("the play: %d tows, %d checks" % [t.carried, _checks])
