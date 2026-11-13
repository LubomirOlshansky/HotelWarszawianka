extends SceneTree
## Racer AI step 6a (docs/design/race-ai.md 6.1): a rival's lights (race_signals.gd) and the
## numbers that make a rival its own (ladder.gd `dare`, `indicate`, `flash`, `home`). A toy driver
## with the traffic Driver's fields on a toy lane graph (a street north, with a road east, a road
## west, a road straight on and its own way back), so every case is one line of state. Checks that:
## - brake lights come on when it brakes and while it stands, stay a moment, and stay off when it
##   only lifts off or backs up;
## - the indicator comes on `indicate` seconds before a turn at its speed (never under TURN_LEAST
##   m), on the turn's side, in the junction's curve too; not for a way straight on; to the left
##   for a U-turn; for a shortcut by where its curve leads; a rival that never indicates never does;
## - it blinks from the moment it comes on, and never left and right at once but as hazards;
## - a pass is indicated out and back in, a block and a slide are not;
## - the hazards blink while it backs out of a street and after a wrong turn, whoever drives;
## - the headlights flash twice once it has been held up for its `flash` seconds, not again for
##   FLASH_AGAIN s, and never for a rival that never flashes;
## - a mistake swings the body and the swing dies out; a phone call's weave is smaller;
## - the lamps: four hidden meshes, each on its own end and side of the car and near its body,
##   each one draw with its glow on the road at least 2 m across;
## - every racer profile has the four numbers inside their ranges, Seba dares most and never
##   indicates, Halina wants the widest gap and indicates earliest, every home district exists.
##   godot --headless --path game --script res://tools/check_race_signals.gd

const RaceSignals := preload("res://scripts/race_signals.gd")
const Ladder := preload("res://scripts/ladder.gd")
const DT := 1.0 / 60.0


class ToyGraph:
	## Edge 0 runs north (0, -1) for 200 m; from its end: 1 east, 2 west, 3 straight on, 4 back.
	var e_reverse := PackedInt32Array([4, -1, -1, -1, 0])
	var e_s0 := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])
	var e_s1 := PackedFloat32Array([200.0, 100.0, 100.0, 100.0, 200.0])
	var dirs := [Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(0.1, -1).normalized(), Vector2(0, 1)]

	func direction(e: int, _s: float) -> Vector2:
		return dirs[e]


class ToyDriver:
	var v := 20.0
	var accel_now := 0.0
	var back := 0
	var wrong_t := 0.0
	var held_up := 0.0
	var in_conn := false
	var block_t := 0.0
	var daze := 0.0
	var pass_t := 0.0
	var pass_back := false
	var pass_off := 0.0
	var off_target := 0.0
	var off := 0.0
	var edge := 0
	var s := 0.0
	var next_edge := 3
	var on_cut := false
	var conn := PackedVector2Array([Vector2.ZERO, Vector2(0, -3), Vector2(0, -6), Vector2(0, -9)])
	var mistakes := 0


var _problems := 0
var _graph := ToyGraph.new()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  FAIL: " + what)


func _initialize() -> void:
	_brakes()
	_turns()
	_blink()
	_passes()
	_hazards()
	_flashes()
	_body()
	_lamps()
	_traits()
	if _problems > 0:
		print("race_signals: %d problems" % _problems)
		quit(1)
	else:
		print("race_signals: OK (brake lights, indicators, hazards, headlight flash, wobble, lamps, the racers' own numbers)")
		quit(0)


## `seconds` of frames of driver d's lights with `traits`.
func _run(st: RaceSignals.State, d: ToyDriver, traits: Dictionary, seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		RaceSignals.tick(st, d, _graph, traits, DT)
		t += DT


func _brakes() -> void:
	var st := RaceSignals.State.new()
	var d := ToyDriver.new()
	var traits := {"indicate": 2.0, "flash": 0.0}
	_run(st, d, traits, 0.5)
	_expect(not st.brake, "brake lights on a car that holds its speed")
	d.accel_now = -1.0
	_run(st, d, traits, 0.5)
	_expect(not st.brake, "brake lights for lifting off (-1 m/s²)")
	d.accel_now = -5.0
	_run(st, d, traits, DT)
	_expect(st.brake and st.brakes == 1, "no brake lights in the first frame of braking")
	d.accel_now = 0.0
	_run(st, d, traits, RaceSignals.BRAKE_HOLD * 0.5)
	_expect(st.brake, "the brake lights go out the moment it lets go (no hold)")
	_run(st, d, traits, RaceSignals.BRAKE_HOLD)
	_expect(not st.brake, "the brake lights stay on after the hold")
	d.v = 0.0
	_run(st, d, traits, DT)
	_expect(st.brake, "no brake lights on a car that stands")
	d.back = 3
	_run(st, d, traits, 1.0)
	_expect(not st.brake, "brake lights on a car that backs up")
	_expect(st.brakes == 2, "brake lights came on %d times, 2 expected" % st.brakes)


func _turns() -> void:
	# The side of each way on.
	var d := ToyDriver.new()
	d.next_edge = 1
	_expect(RaceSignals.turn_side(d, _graph) == 1, "a road to the east off a street north is not a right turn")
	d.next_edge = 2
	_expect(RaceSignals.turn_side(d, _graph) == -1, "a road to the west off a street north is not a left turn")
	d.next_edge = 3
	_expect(RaceSignals.turn_side(d, _graph) == 0, "a road 6° off its own is a turn")
	d.next_edge = 4
	_expect(RaceSignals.turn_side(d, _graph) == -1, "a U-turn is not indicated to the left")
	d.next_edge = -1
	_expect(RaceSignals.turn_side(d, _graph) == 0, "a turn with no way on")
	# A shortcut: by where its curve leads, from a smaller angle.
	d.next_edge = 3
	d.on_cut = true
	d.conn = PackedVector2Array([Vector2.ZERO, Vector2(0, -3), Vector2(2, -7), Vector2(4, -9)])
	_expect(RaceSignals.turn_side(d, _graph) == 1, "a shortcut that leads off to the right is not indicated right")
	d.conn = PackedVector2Array([Vector2.ZERO, Vector2(0, -3), Vector2(-2, -7), Vector2(-4, -9)])
	_expect(RaceSignals.turn_side(d, _graph) == -1, "a shortcut that leads off to the left is not indicated left")
	# When it comes on: `indicate` seconds before the junction at its speed.
	for row: Array in [[3.0, 20.0, 60.0], [0.7, 20.0, 14.0], [2.0, 2.0, RaceSignals.TURN_LEAST]]:
		var st := RaceSignals.State.new()
		d = ToyDriver.new()
		d.next_edge = 1
		d.v = row[1]
		var traits := {"indicate": row[0], "flash": 0.0}
		d.s = 200.0 - float(row[2]) - 2.0
		_run(st, d, traits, 0.2)
		_expect(not st.indicating(), "indicating %.0f m before a turn at %.0f m/s with %.1f s of warning" % [float(row[2]) + 2.0, d.v, row[0]])
		d.s = 200.0 - float(row[2]) + 1.0
		_run(st, d, traits, DT)
		_expect(st.indicating() and st.right and not st.left, "not indicating right %.0f m before a right turn at %.0f m/s with %.1f s of warning" % [float(row[2]) - 1.0, d.v, row[0]])
		d.in_conn = true
		d.s = 200.0
		_run(st, d, traits, RaceSignals.BLINK)
		_expect(st.indicating(), "the indicator goes out in the junction's curve")
		_expect(st.indications == 1, "one turn counted as %d indications" % st.indications)
	# The rival that never indicates.
	var seba := RaceSignals.State.new()
	d = ToyDriver.new()
	d.next_edge = 1
	d.s = 195.0
	_run(seba, d, {"indicate": 0.0, "flash": 0.8}, 1.0)
	_expect(not seba.indicating() and seba.indications == 0, "a rival with no warning indicates a turn")


func _blink() -> void:
	var st := RaceSignals.State.new()
	var d := ToyDriver.new()
	d.next_edge = 2
	d.s = 195.0
	var traits := {"indicate": 2.0, "flash": 0.0}
	var lit := 0
	var dark := 0
	var both := 0
	var first := false
	for k in roundi(RaceSignals.BLINK * 3.0 / DT):
		RaceSignals.tick(st, d, _graph, traits, DT)
		if k == 0:
			first = st.left
		if st.left:
			lit += 1
		else:
			dark += 1
		if st.right:
			both += 1
	_expect(first, "the indicator's first frame is dark")
	_expect(lit > 0 and dark > 0 and absf(float(lit) / (lit + dark) - RaceSignals.BLINK_ON) < 0.05, "the indicator is lit %d of %d frames, not %.0f %%" % [lit, lit + dark, RaceSignals.BLINK_ON * 100.0])
	_expect(both == 0, "the right indicator lit for a left turn")


func _passes() -> void:
	var traits := {"indicate": 1.5, "flash": 0.0}
	var st := RaceSignals.State.new()
	var d := ToyDriver.new()
	d.s = 50.0
	# Out for a pass over the centre line (to the left).
	d.pass_t = 3.0
	d.pass_off = -3.2
	_run(st, d, traits, DT)
	_expect(st.left and not st.right, "going out to the left for a pass is not indicated left")
	d.off = -3.2
	_run(st, d, traits, RaceSignals.SIDE_HOLD * 0.5)
	_expect(st.indicating(), "the indicator goes out the moment it is over (no hold)")
	_run(st, d, traits, RaceSignals.SIDE_HOLD)
	_expect(not st.indicating(), "the indicator stays on beside the car it passes")
	# Back in.
	d.pass_t = 0.0
	_run(st, d, traits, DT)
	_expect(st.right and not st.left, "coming back in to the right is not indicated right")
	d.off = 0.0
	_run(st, d, traits, RaceSignals.SIDE_HOLD + 0.1)
	_expect(not st.indicating(), "the indicator stays on after the pass")
	_expect(st.indications == 2, "a pass counted as %d indications, not out and back in" % st.indications)
	# A lane change.
	d.off_target = 3.5
	_run(st, d, traits, DT)
	_expect(st.right, "a lane change to the right is not indicated")
	# A block and a slide are not.
	st = RaceSignals.State.new()
	d = ToyDriver.new()
	d.s = 50.0
	d.off_target = 3.0
	d.block_t = 2.0
	_run(st, d, traits, 0.3)
	_expect(not st.indicating(), "a block across the player's line is indicated")
	d.block_t = 0.0
	d.daze = 0.5
	_run(st, d, traits, 0.3)
	_expect(not st.indicating(), "a slide is indicated")
	# Seba passes without.
	st = RaceSignals.State.new()
	d = ToyDriver.new()
	d.s = 50.0
	d.pass_t = 3.0
	d.pass_off = -3.2
	_run(st, d, {"indicate": 0.0, "flash": 0.8}, 0.5)
	_expect(not st.indicating(), "a rival with no warning indicates a pass")


func _hazards() -> void:
	for warn: float in [2.0, 0.0]:
		var traits := {"indicate": warn, "flash": 0.0}
		var st := RaceSignals.State.new()
		var d := ToyDriver.new()
		d.s = 50.0
		d.wrong_t = 2.4
		_run(st, d, traits, DT)
		_expect(st.left and st.right, "no hazard lights after a wrong turn (warning %.0f s)" % warn)
		_expect(st.hazards == 1, "one wrong turn counted as %d hazards" % st.hazards)
		_run(st, d, traits, RaceSignals.BLINK * RaceSignals.BLINK_ON + 0.05)
		_expect(not st.left and not st.right and st.indicating(), "the hazard lights do not blink")
		d.wrong_t = 0.0
		_run(st, d, traits, DT)
		_expect(not st.indicating(), "the hazard lights stay on")
		d.back = 3
		d.v = 0.0
		_run(st, d, traits, DT)
		_expect(st.left and st.right and st.hazards == 2, "no hazard lights while it backs out of a street")


func _flashes() -> void:
	var st := RaceSignals.State.new()
	var d := ToyDriver.new()
	d.s = 50.0
	var traits := {"indicate": 0.0, "flash": 0.8}
	d.held_up = 0.5
	_run(st, d, traits, 0.5)
	_expect(not st.flash and st.flashes == 0, "a flash before it has been held up long enough")
	d.held_up = 0.9
	var pattern := ""
	for k in roundi(1.0 / DT):
		RaceSignals.tick(st, d, _graph, traits, DT)
		var c := "1" if st.flash else "0"
		if pattern == "" or pattern[pattern.length() - 1] != c:
			pattern += c
	_expect(pattern == "1010", "the flash's pattern is %s, not on-off-on-off" % pattern)
	_expect(st.flashes == 1, "one flash counted as %d" % st.flashes)
	_run(st, d, traits, RaceSignals.FLASH_AGAIN - 1.5)
	_expect(st.flashes == 1, "it flashes again within FLASH_AGAIN s")
	_run(st, d, traits, 1.5)
	_expect(st.flashes == 2, "still held up after FLASH_AGAIN s, it does not flash again")
	# Halina never does.
	st = RaceSignals.State.new()
	d.held_up = 30.0
	_run(st, d, {"indicate": 3.0, "flash": 0.0}, 5.0)
	_expect(st.flashes == 0 and not st.flash, "a rival that never flashes its headlights did")


func _body() -> void:
	var traits := {"indicate": 2.0, "flash": 0.0}
	var st := RaceSignals.State.new()
	var d := ToyDriver.new()
	_run(st, d, traits, 0.2)
	_expect(st.yaw == 0.0, "the body swings with nothing wrong")
	d.mistakes = 1
	var most := 0.0
	var left := false
	var right := false
	for k in roundi(RaceSignals.WOBBLE_S / DT) - 1:
		RaceSignals.tick(st, d, _graph, traits, DT)
		most = maxf(most, absf(st.yaw))
		left = left or st.yaw > 0.02
		right = right or st.yaw < -0.02
	_expect(most > 0.05 and most <= RaceSignals.WOBBLE_RAD, "a mistake's wobble swings %.2f rad at most (over 0.05, %.2f at most)" % [most, RaceSignals.WOBBLE_RAD])
	_expect(left and right, "a mistake's wobble swings one way only")
	_run(st, d, traits, 0.2)
	_expect(st.yaw == 0.0, "the wobble does not die out")
	st.weave(1.2)
	most = 0.0
	for k in roundi(1.2 / DT) - 1:
		RaceSignals.tick(st, d, _graph, traits, DT)
		most = maxf(most, absf(st.yaw))
	_expect(most > 0.02 and most <= RaceSignals.WEAVE_RAD, "a phone call's weave swings %.2f rad at most (over 0.02, %.2f at most)" % [most, RaceSignals.WEAVE_RAD])
	_run(st, d, traits, 0.2)
	_expect(st.yaw == 0.0, "the weave does not end")
	d.accel_now = -5.0
	d.wrong_t = 1.0
	_run(st, d, traits, DT)
	st.clear()
	_expect(not st.brake and not st.left and not st.right and not st.flash and st.yaw == 0.0 and not st.indicating(), "clear() leaves a light on")


func _lamps() -> void:
	for size: Vector3 in [Vector3(1.6, 1.9, 3.4), Vector3(2.0, 3.0, 5.2), Vector3(1.9, 1.3, 4.4)]:
		var node := RaceSignals.build(size)
		var names := PackedStringArray()
		for c in node.get_children():
			names.append(c.name)
			_expect(not (c as MeshInstance3D).visible, "the %s lamp is lit from the start" % c.name)
			var box: AABB = (c as MeshInstance3D).mesh.get_aabb()
			# Its glow on the road reaches past the car by the largest pool, and lies on the road.
			var reach := RaceSignals.FLASH_POOL * 1.6 + 0.3
			_expect(box.position.x >= -size.x * 0.5 - reach and box.end.x <= size.x * 0.5 + reach and box.position.z >= -size.z * 0.5 - reach and box.end.z <= size.z * 0.5 + reach
					and box.position.y >= 0.0 and box.position.y <= RaceSignals.POOL_Y + 0.01 and box.end.y <= size.y, "the %s lamp is off a car of %s: %s" % [c.name, size, box])
			_expect((c as MeshInstance3D).mesh.get_surface_count() == 1, "the %s lamp is %d draws, not one" % [c.name, (c as MeshInstance3D).mesh.get_surface_count()])
			# Big enough to read from the game's height: its glow at least 2 m across.
			_expect(minf(box.size.x, box.size.z) >= 2.0, "the %s lamp's glow is %.1f m across" % [c.name, minf(box.size.x, box.size.z)])
			match String(c.name):
				"brake":
					_expect(box.position.z > 0.0, "the brake lights are not at the rear")
				"flash":
					_expect(box.end.z < 0.0, "the headlights' flash is not at the front")
				"left":
					_expect(box.end.x < 0.0, "the left indicator is not on the left")
				"right":
					_expect(box.position.x > 0.0, "the right indicator is not on the right")
		_expect(names == PackedStringArray(["brake", "left", "right", "flash"]), "the lamps are %s" % ", ".join(names))
		var st := RaceSignals.State.new()
		st.brake = true
		st.right = true
		RaceSignals.show(node, st)
		_expect(node.get_node("brake").visible and node.get_node("right").visible and not node.get_node("left").visible and not node.get_node("flash").visible, "show() lights the wrong lamps")
		RaceSignals.show(node, null)
		for c in node.get_children():
			_expect(not c.visible, "show(null) leaves the %s lamp lit" % c.name)
		node.free()


func _traits() -> void:
	var ids := {}
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/districts.json"))
	for d: Dictionary in (doc as Dictionary).get("districts", []):
		ids[str(d["id"])] = true
	var profiles := {"the final": Ladder.FINAL_RACER, "the default": Ladder.DEFAULT_RACER, "the gentle day": Ladder.FIRST_RACER}
	for i in Ladder.RUNGS.size():
		profiles[Ladder.RUNGS[i]["rival"]] = Ladder.racer(i)
	for who: String in profiles:
		var p: Dictionary = profiles[who]
		for key: String in ["dare", "indicate", "flash", "home"]:
			_expect(p.has(key), "%s has no `%s`" % [who, key])
		if not (p.has("dare") and p.has("indicate") and p.has("flash") and p.has("home")):
			continue
		_expect(float(p["dare"]) >= 0.4 and float(p["dare"]) <= 3.0, "%s: dare %.2f outside 0.4 to 3" % [who, p["dare"]])
		_expect(float(p["indicate"]) >= 0.0 and float(p["indicate"]) <= 4.0, "%s: indicate %.1f outside 0 to 4 s" % [who, p["indicate"]])
		_expect(float(p["flash"]) == 0.0 or (float(p["flash"]) >= 0.5 and float(p["flash"]) <= 5.0), "%s: flash %.1f is neither 0 nor 0.5 to 5 s" % [who, p["flash"]])
		for id: String in p["home"]:
			_expect(ids.has(id), "%s: home district `%s` is not in data/districts.json" % [who, id])
	var halina := Ladder.racer(0)
	var seba := Ladder.racer(Ladder.rung_of("Seba z Pragi"))
	for i in Ladder.RUNGS.size():
		var p := Ladder.racer(i)
		_expect(float(p["dare"]) <= float(halina["dare"]), "%s wants a wider gap than Pani Halina" % Ladder.RUNGS[i]["rival"])
		_expect(float(p["dare"]) >= float(seba["dare"]), "%s dares a narrower gap than Seba" % Ladder.RUNGS[i]["rival"])
		_expect(float(p["indicate"]) <= float(halina["indicate"]), "%s indicates earlier than Pani Halina" % Ladder.RUNGS[i]["rival"])
		_expect(float(p["indicate"]) > 0.0 or Ladder.RUNGS[i]["rival"] == "Seba z Pragi", "%s never indicates (only Seba does not)" % Ladder.RUNGS[i]["rival"])
	_expect(float(seba["indicate"]) == 0.0, "Seba indicates")
	_expect(float(halina["flash"]) == 0.0, "Pani Halina flashes her headlights")
	_expect(float(seba["flash"]) > 0.0 and float(seba["flash"]) <= 1.0, "Seba does not flash at once")
	_expect(Ladder.FIRST_RACER["home"] == halina["home"] and Ladder.FIRST_RACER["dare"] == halina["dare"] and Ladder.FIRST_RACER["indicate"] == halina["indicate"],
			"Pani Halina's gentle day is another driver (home, dare, indicate)")
