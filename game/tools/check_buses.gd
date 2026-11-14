extends SceneTree
## The night-buses loop (docs/design/vision.md 3.5, eggs E23-E25): scripts/buses.gd's rules,
## headless, from the committed map data (map/centrum.json: the lane graph and the shelters) and
## data/eggs.json; seeded, no clock of its own:
##   1. the N sign's window (22:30-05:00) and the bus with the sign (one surface, more vertices);
##   2. the hub's timing on a synthetic clock (a gathering every half hour from 22:30 to 04:30,
##      none by day) and its rings (5-8 buses, seeded, all standing together at ARRIVE + 1 s);
##   3. the hub's 8 bays on the real lane graph (two rows of 4 at the kerb by the station, within
##      60 m of the hub) and the bus stops from the real shelters (beside a bus road, the hub's own);
##   4. the stops' people: 1-2 by day, none at night away from the ring, at most
##      pedestrians.gd's STOPS figures in all (written through a stand-in);
##   5. the horn's rate limit (honk() on a synthetic clock; walkers startled through a stand-in);
##   6. E23 (the car at the ring with 5+ standing), E24 (a called bus pulling in) and E25 (the car
##      at the Palm first, no trap flash) on synthetic inputs, each found once with its respect.
## Prints "check_buses: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_buses.gd [-- --verbose]

const Buses := preload("res://scripts/buses.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Pedestrians := preload("res://scripts/pedestrians.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Fakes := preload("res://tools/fakes.gd")


var problems: Array[String] = []
var verbose := false
var veh: Array = [Vector3.ZERO, 0.0, false]


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_sign(digest)
	_check_hub_clock(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var g := LaneGraph.new(data["graph"], null)
	_check_places(g, data, digest)
	_check_people(digest)
	_check_service(digest)
	_check_horn(digest)
	_check_eggs(digest)
	if problems.is_empty():
		print("check_buses: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_buses: %d problems" % problems.size())
		quit(1)


func _check_sign(digest: PackedStringArray) -> void:
	var want := {14.0: false, 22.48: false, 22.5: true, 23.9: true, 0.0: true, 4.99: true, 5.0: false, 12.0: false}
	for h: float in want:
		if Buses.sign_on(h) != want[h]:
			problems.append("N sign at %.2f: %s, want %s" % [h, Buses.sign_on(h), want[h]])
	var day: ArrayMesh = Models.bus_mesh()
	var night: ArrayMesh = Traffic.night_bus_mesh()
	var dv := (day.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var nv := (night.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	if night.get_surface_count() != 1 or nv <= dv:
		problems.append("night bus: %d surfaces, %d vertices (the day bus %d)" % [night.get_surface_count(), nv, dv])
	if Traffic.night_bus_mesh() != night:
		problems.append("night bus: made again (not cached)")
	digest.append("N sign 22:30-05:00, bus +%d vertices" % (nv - dv))


func _check_hub_clock(digest: PackedStringArray) -> void:
	var cases := [[22.4, -1], [22.5, 0], [23.05, 1], [0.1, 3], [4.5, 12], [4.66, -1], [5.0, -1], [12.0, -1], [14.0, -1], [21.9, -1]]
	for c: Array in cases:
		var sl := Buses.slot_at(float(c[0]))
		if int(sl.x) != int(c[1]):
			problems.append("hub at %.2f: slot %d, want %d" % [c[0], int(sl.x), c[1]])
	var age := Buses.slot_at(23.05)
	if absf(age.y - 180.0) > 0.5:
		problems.append("hub at 23:03: %.0f s into the slot, want 180" % age.y)
	var sizes := {}
	var gatherings := 0
	for day in range(1, 8):
		for slot in Buses.SLOTS:
			var plan := Buses.ring_plan(day, slot)
			gatherings += 1
			if str(plan) != str(Buses.ring_plan(day, slot)):
				problems.append("ring %d/%d: not the same twice" % [day, slot])
			sizes[plan.size()] = int(sizes.get(plan.size(), 0)) + 1
			if plan.size() < Buses.RING.x or plan.size() > Buses.RING.y:
				problems.append("ring %d/%d: %d buses" % [day, slot, plan.size()])
			for b: Array in plan:
				if float(b[0]) > Buses.ARRIVE or float(b[1]) < Buses.WAIT.x or float(b[1]) > Buses.WAIT.y:
					problems.append("ring %d/%d: a bus %s" % [day, slot, b])
			if Buses.standing(plan, Buses.ARRIVE + 1.0) != plan.size():
				problems.append("ring %d/%d: %d of %d standing at %.0f s" % [day, slot, Buses.standing(plan, Buses.ARRIVE + 1.0), plan.size(), Buses.ARRIVE + 1.0])
			if Buses.standing(plan, Buses.ARRIVE + Buses.WAIT.y + 1.0) != 0:
				problems.append("ring %d/%d: buses still standing after the longest wait" % [day, slot])
	if sizes.size() < 3:
		problems.append("rings: sizes %s (want 5-8 spread)" % sizes)
	digest.append("%d gatherings a night, rings %s" % [Buses.SLOTS, sizes])


func _check_places(g: LaneGraph, data: Dictionary, digest: PackedStringArray) -> void:
	var bays := Buses.hub_bays(g)
	var east := 0
	for b: Dictionary in bays:
		var at: Vector3 = b["at"]
		east += int(b["east"])
		if Vector2(at.x, at.z).distance_to(Buses.HUB) > 85.0:  # the 18 m articulated buses stand 20 m apart
			problems.append("hub bay at %.0f, %.0f: %.0f m from the hub" % [at.x, at.z, Vector2(at.x, at.z).distance_to(Buses.HUB)])
		if g.e_class[int(b["e"])] > 1:
			problems.append("hub bay on a class %d edge" % g.e_class[int(b["e"])])
	for i in bays.size():
		for j in range(i + 1, bays.size()):
			var a: Vector3 = bays[i]["at"]
			var c: Vector3 = bays[j]["at"]
			if a.distance_to(c) < 12.5:
				problems.append("hub bays %d and %d %.1f m apart" % [i, j, a.distance_to(c)])
	if bays.size() != 8 or east != 4:
		problems.append("hub: %d bays (%d eastbound), want 8 (4)" % [bays.size(), east])
	var sh: Array = data["shelters"]
	var n := 0
	var hub_stop := false
	var off_kerb := 0
	for i in range(0, sh.size() - 2, 3):
		var st := Buses.stop_from(g, Vector2(float(sh[i]), float(sh[i + 1])))
		if st.is_empty():
			continue
		n += 1
		if float(st["out"]) > 3.5:
			off_kerb += 1  # G8: the shelter stands past the kerb lane's edge by more than the bake's furthest try
		var e: int = st["e"]
		if g.e_class[e] > 1:
			problems.append("stop at %s on a class %d edge" % [st["at"], g.e_class[e]])
		if (st["at"] as Vector2).distance_to(Buses.HUB) < 40.0:
			hub_stop = true
	if off_kerb * 8 > n:
		problems.append("bus stops: %d of %d shelters stand more than 3.5 m past the kerb lane (tools/snap_props.py)" % [off_kerb, n])
	if n < 100 or not hub_stop:
		problems.append("bus stops: %d of %d shelters (the hub's %s)" % [n, sh.size() / 3, hub_stop])
	var text := '{"a": [1], "shelters": [1.5, 2.5, 0.3, 4, 5, 6], "x": [7]}'
	if Buses.shelters_in(text) != [1.5, 2.5, 0.3, 4.0, 5.0, 6.0]:
		problems.append("shelters_in: %s" % [Buses.shelters_in(text)])
	digest.append("hub 8 bays, %d bus stops of %d shelters" % [n, sh.size() / 3])


func _check_people(digest: PackedStringArray) -> void:
	var most := 0
	for key in 400:
		for h in range(0, 24):
			var p := Buses.stop_people(key * 7919, float(h) + 0.5)
			var day := float(h) + 0.5 >= Buses.DAY_FROM and float(h) + 0.5 < Buses.DAY_TO
			if (day and (p < 2 or p > 5)) or (not day and p != 0):
				problems.append("stop %d at %d:30: %d people" % [key, h, p])
				return
			most = maxi(most, p)
	var b: Buses = Buses.new()
	var w := Fakes.Walkers.new()
	b.walkers = w
	root.add_child(b)
	root.add_child(w)
	for k in 6:
		b.stops.append({"at": Vector2(100.0 + k * 20.0, 0.0), "key": k * 977 + 5, "side": Vector2.UP, "e": 0, "s": 0.0})
	b._pick_stops(Vector2(120.0, 0.0))
	var by_day := 0
	for h in [7.5, 8.0, 12.0, 16.0, 17.0]:
		b._stop_figures(h)
		by_day = maxi(by_day, w.stops.size())
		if w.stops.size() > Buses.WAIT_SLOTS or w.stops.size() < b._near.size():
			problems.append("stop figures at %.1f: %d for %d stops (cap %d)" % [h, w.stops.size(), b._near.size(), Buses.WAIT_SLOTS])
	b._stop_figures(23.0)
	if not w.stops.is_empty():
		problems.append("stop figures at 23:00 with no ring: %d" % w.stops.size())
	b.free()
	w.free()
	digest.append("stops 2-5 people by day, ≤ %d waiting figures (%d seen)" % [Buses.WAIT_SLOTS, by_day])


func _check_horn(digest: PackedStringArray) -> void:
	var b: Buses = Buses.new()
	var w := Fakes.Walkers.new()
	b.walkers = w
	b.vehicle = func() -> Array: return veh
	root.add_child(b)
	root.add_child(w)
	var times := [0.0, 0.2, 0.59, 0.6, 0.65, 1.3, 5.0]
	var ok: Array = []
	for t: float in times:
		b._now = t
		ok.append(b.honk())
	if ok != [true, false, false, true, false, true, true] or b.honks != 4 or w.startled != 4:
		problems.append("horn: %s, %d honks, %d startles" % [ok, b.honks, w.startled])
	if not Buses.horn_ok(10.0, 9.375) or Buses.horn_ok(10.0, 9.5):
		problems.append("horn_ok: the gap is not %.1f s" % Buses.HORN_GAP)
	b.free()
	w.free()
	digest.append("horn once per %.1f s" % Buses.HORN_GAP)


func _check_eggs(digest: PackedStringArray) -> void:
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var book: EggBook = EggBook.new()
	book.wallet = wallet
	root.add_child(book)
	if not book.load_eggs():
		problems.append("no data/eggs.json")
		return
	for id in ["e23", "e24", "e25"]:
		var e: Dictionary = book.eggs[book.by_id[id]]
		if e.has("waits") or str(e["trigger"].get("kind", "")) != "event":
			problems.append("%s: not an event trigger (%s)" % [id, e["trigger"]])
	var s := {"pos": Vector3(Buses.HUB.x, 0.0, Buses.HUB.y), "hour": 1.5, "kmh": 0.0, "look": "Night"}
	# E23: the moment's rule, then the find.
	if not Buses.hub_moment(Buses.HUB, false, 5) or Buses.hub_moment(Buses.HUB, false, 4) \
			or Buses.hub_moment(Buses.HUB, true, 7) or Buses.hub_moment(Buses.HUB + Vector2(70, 0), false, 7):
		problems.append("E23: the hub moment's rule")
	var r0: int = wallet.respect
	var first := [book.fire("e23", s), book.fire("e23", s)]
	var r1: int = wallet.respect
	var e24 := [book.fire("e24", s), book.fire("e24", s)]
	var r2: int = wallet.respect
	if not Buses.race_won(true, 2, 2) or Buses.race_won(true, 2, 3) or Buses.race_won(false, 2, 2):
		problems.append("E25: the race's rule")
	var e25 := [book.fire("e25", s), book.fire("e25", s)]
	var r3: int = wallet.respect
	if first != [true, false] or r1 - r0 != 30:
		problems.append("E23: fired %s, +%d respect (want once, +30)" % [first, r1 - r0])
	if e24 != [true, false] or r2 - r1 != 15:
		problems.append("E24: fired %s, +%d respect (want once, +15)" % [e24, r2 - r1])
	if e25 != [true, false] or r3 - r2 != 30:
		problems.append("E25: fired %s, +%d respect (want once, +30)" % [e25, r3 - r2])
	book.free()
	wallet.free()
	digest.append("E23 E24 E25 once each (+%d respect)" % (r3 - r0))


## G8: the service rules (buses.gd): a stand lasts 8-12 s, a stop is only served from 14-90 m ahead by
## day and not twice within SERVE_GAP, 1-3 step off and at most 2 of the waiting board; the figure
## slots hold the waiting and the passengers apart.
func _check_service(digest: PackedStringArray) -> void:
	var lo := 1000.0
	var hi := 0.0
	for k in 300:
		var d := Buses.dwell_for(k * 7919, k % 8, k % 5)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	if lo < Buses.DWELL.x or hi > Buses.DWELL.y or hi - lo < 1.0:
		problems.append("dwell %.1f-%.1f s, want %.0f-%.0f s varying" % [lo, hi, Buses.DWELL.x, Buses.DWELL.y])
	if not Buses.serve_ok(40.0, 200.0, 12.0) or Buses.serve_ok(5.0, 200.0, 12.0) or Buses.serve_ok(120.0, 200.0, 12.0) \
			or Buses.serve_ok(40.0, 60.0, 12.0) or Buses.serve_ok(40.0, 200.0, 23.0) or Buses.serve_ok(40.0, 200.0, 3.0):
		problems.append("serve_ok: the window, the gap or the day's hours are wrong")
	for k in 200:
		var waiting := k % 6
		var pax := Buses.passengers(k * 977, k % 8, k % 4, waiting)
		if pax.x < Buses.ALIGHT.x or pax.x > Buses.ALIGHT.y or pax.y < 0 or pax.y > Buses.BOARD_MAX or pax.y > waiting:
			problems.append("passengers %s for %d waiting" % [pax, waiting])
			return
		if waiting <= 3 and waiting > 0 and pax.y >= waiting:
			problems.append("everyone boarded from %d waiting" % waiting)
			return
	if Buses.WAIT_SLOTS + Buses.ALIGHT.y > Pedestrians.STOPS:
		problems.append("stop slots: %d waiting + %d passengers > %d" % [Buses.WAIT_SLOTS, Buses.ALIGHT.y, Pedestrians.STOPS])
	digest.append("service: stands %.1f-%.1f s, %d-%d step off, ≤ %d board" % [lo, hi, Buses.ALIGHT.x, Buses.ALIGHT.y, Buses.BOARD_MAX])
