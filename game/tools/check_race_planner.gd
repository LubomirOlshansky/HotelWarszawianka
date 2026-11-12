extends SceneTree
## The route planner's check (race_planner.gd, and traffic.gd's turning back, traffic delay and
## racers out of the town's cars; docs/design/race-ai.md 5, step 3 of the racer AI rebuild; the
## friend's point 3, "choose routes by expected arrival time: route score = driving time + traffic
## delay + risk penalty", and F's test list: "a blocked shortcut ... choose sensible
## alternatives"). Headless, from the committed map (map/centrum.json; skipped without it), with
## the race bench (tools/race_bench.gd: the real traffic and the game's own race code). Checks that:
## - the traffic's delay (Traffic.race_delay): none without traffic, in proportion to the density,
##   more a metre with no way past than with lanes or an oncoming road, more for a faster racer and
##   none along the street for one slower than the town, and a careful racer's extra on a street
##   with no way past only;
## - a plan: it knows a way from the prototype race's start to the finish and Mike's is quicker
##   than Halina's; one that knows nothing of the town's traffic (`knows` 0) is the clear roads'
##   plan, one that knows it gives the race more seconds, at most what its clear way costs in that
##   traffic, and caution never makes it quicker; `block` shuts a street once, and the new way goes
##   round it and is no quicker; a search in slices (`step`) and one of the whole map (`work`) come
##   to the same way and time as a search at once;
## - a wrong turn (Słoik's): every road the plan offers for one costs WRONG_LEAST to WRONG_MOST s
##   over its best way and is never the way back; a curve tighter than a car turns counts as the
##   arc, and a hairpin is taken at Traffic.UTURN_SPEED (no U-turn in a third of a second);
## - in races on the bench: the plan's clock is within CLOCK of the race as driven on clear roads
##   (Halina, Mike); at a wall across a one-way street the rival backs out to the junction behind,
##   and across a two-way street it turns round in the street (the oncoming road next), each time
##   home by another way through no car; behind the player's car stopped in its only lane in the
##   first race it turns back too and comes home;
## - out of the town's cars: with the view held away from the race in Busy traffic the rival is
##   slower than on clear roads by the delay its streets owe (AWAY), with no step in its speed;
## - a lane held (Traffic.RACE_LANE_HOLD): behind the slow test player on a road with two lanes
##   she moves over and is past, her time within the bench's Independence limit of her time
##   alone (she changed lane and back every frame behind the player's car, and never got by);
## - a finish's circle (RacePlanner.ends; rivals.gd FINISH_RADIUS): at Plac Trzech Krzyży no other
##   road runs through it and the plan to the circle is the plan to the junction, state for state;
##   at the Palace the other carriageway of Emilii Plater does, on the finish's own level only, the
##   plan to the circle ends there, is never the slower one from any street, and from Marszałkowska
##   is the quicker by a quarter of a minute; on that road the plan has the metres to the circle
##   left and past it the way round; a road through the circle that is shut is no finish; the
##   metres (RacePlanner.links) and the minimap's line (route_line.gd) end where the road enters;
##   a racer on the lane furthest from the finish is home there, outside the circle, and with the
##   plan to the junction alone or past the circle she is not; and the guided first race from
##   Marszałkowska as the whole game ran it comes home on that road, by its plan's clock, in Low
##   traffic with a player about too (101 s by the plan to the junction, 2026-11-12).
##   godot --headless --path game --script res://tools/check_race_planner.gd
## Prints "check_race_planner: OK (...)" or the problems (exit 1).

const RaceBench := preload("res://tools/race_bench.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Rivals := preload("res://scripts/rivals.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const RouteLine := preload("res://scripts/route_line.gd")

const HALINA := "Pani Halina"
const SLOIK := "Słoik z Radomia"
const MIKE := "Mordor Mike"
## The plan's clock against the race as driven on clear roads (a share of the race).
const CLOCK := 0.06
## Out of the town's cars: the seconds lost against the delay owed (a share of it), and the
## seconds that may still be owed at the finish.
const AWAY := 0.15
const AWAY_REST := 3.0
## A two-way street to wall for the U-turn: at least this long (m).
const UTURN_STREET := 100.0
## The view held here is far from every road: the rival is out of the town's cars all the race.
const FAR_VIEW := Vector2(-9000.0, -9000.0)
## The finish's circle: the plan to it from Marszałkowska beats the plan to the junction by at
## least this (s), and in Low traffic with a player about the race may take this share more than
## on clear roads.
const CIRCLE_GAIN := 15.0
## The player's car beside a road through the circle: this far from its outer lane's middle (m:
## the pavement, two lanes' width out) it is not on the road.
const OFF_ROAD := 7.0
## Trzy mosty's finish: the metres the circle saves Seba from the last bridge, at least.
const FINAL_GAIN := 300.0
const CIRCLE_TRAFFIC := 1.25

var _bench: RaceBench
var _graph: LaneGraph
var _problems := 0
var _notes := PackedStringArray()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_bench = RaceBench.new()
	if not _bench.open(root):
		# A clone without the map data: nothing to plan on (the same rule as check_race_bench.gd).
		print("check_race_planner: OK (skipped: %s)" % _bench.error)
		quit(0)
		return
	_graph = _bench.graph
	_delay()
	_plans()
	_wrong_and_tight()
	_races()
	_circle()
	_bench.close()
	if _problems == 0:
		print("check_race_planner: OK (%s)" % " · ".join(_notes))
		quit(0)
	else:
		print("check_race_planner: %d problem(s)" % _problems)
		quit(1)


## The racer stats of `name` on its rung (rivals.gd `race_stats`), with `over` on top.
func _stats(name: String, over := {}) -> Dictionary:
	var out := Rivals.race_stats(Ladder.rung_of(name)).duplicate()
	out.merge(over, true)
	return out


## [edge, lane, s] where `name` starts the prototype race from Tamka, and the finish's node.
func _start(name: String) -> Array:
	var fin: Dictionary = _bench.finish(RaceBench.FINISH)
	var places: Dictionary = _bench.grid(RaceBench.STARTS["tamka"], _bench.racer_to(name, fin["node"]), false)
	return [places["rival"][0], places["rival"][1], places["rival"][2], fin["node"]]


func _plan(name: String, density := 0.0, over := {}) -> RacePlanner.Plan:
	var at := _start(name)
	return _bench.planner.plan(at[3], _stats(name, over), RaceBench.PLAYER_TOP, _bench.links_of(name)[0], density)


## The first edge of the kind asked for: one lane or several, with an oncoming road or without,
## at least `least` m long, with no lights (the street's own delay alone).
func _street(lanes_one: bool, oncoming: bool, least: float) -> int:
	for e in _graph.e_a.size():
		if (_graph.e_lanes[e] == 1) == lanes_one and (_graph.e_reverse[e] >= 0) == oncoming \
				and _graph.e_s1[e] - _graph.e_s0[e] >= least and _graph.e_stops[e].is_empty():
			return e
	return -1


func _delay() -> void:
	var alone := _street(true, false, 80.0)
	var oncoming := _street(true, true, 80.0)
	var lanes := _street(false, false, 80.0)
	_expect(alone >= 0 and oncoming >= 0 and lanes >= 0, "the map has a one-lane one-way street, a one-lane two-way street and a street with several lanes of 80 m with no lights")
	if alone < 0 or oncoming < 0 or lanes < 0:
		return
	var v := 20.0
	for e: int in [alone, oncoming, lanes]:
		var full := Traffic.race_delay(_graph, e, v, 1.0)
		_expect(Traffic.race_delay(_graph, e, v, 0.0) == 0.0, "no traffic, no delay (edge %d)" % e)
		_expect(full > Traffic.RACE_STUCK_END, "Busy traffic costs more than the street's end alone (edge %d: %.2f s)" % [e, full])
		_expect(absf(Traffic.race_delay(_graph, e, v, 0.5) - full * 0.5) < 0.001, "half the traffic, half the delay (edge %d)" % e)
		_expect(Traffic.race_delay(_graph, e, 28.0, 1.0) > full, "a faster racer loses more (edge %d)" % e)
		_expect(absf(Traffic.race_delay(_graph, e, Traffic.RACE_STUCK_SPEED - 2.0, 1.0) - Traffic.RACE_STUCK_END) < 0.001,
				"a racer slower than the town's cars loses nothing along the street (edge %d)" % e)
	# By the metre: no way past costs the most, an oncoming road to pass on the least.
	var per := PackedFloat32Array()
	for e: int in [alone, lanes, oncoming]:
		per.append((Traffic.race_delay(_graph, e, v, 1.0) - Traffic.RACE_STUCK_END) / (_graph.e_s1[e] - _graph.e_s0[e]))
	_expect(per[0] > per[1] and per[1] > per[2], "a metre with no way past costs more than one with lanes, and that more than one with an oncoming road (%.4f, %.4f, %.4f s)" % [per[0], per[1], per[2]])
	# Caution: the street with no way past, and only that one.
	_expect(Traffic.race_delay(_graph, alone, v, 1.0, 1.0) > Traffic.race_delay(_graph, alone, v, 1.0) * 1.3, "a careful racer counts a street with no way past for more")
	_expect(Traffic.race_delay(_graph, oncoming, v, 1.0, 1.0) == Traffic.race_delay(_graph, oncoming, v, 1.0)
			and Traffic.race_delay(_graph, lanes, v, 1.0, 1.0) == Traffic.race_delay(_graph, lanes, v, 1.0), "caution changes nothing where there is a way past")
	# Every racer has the two numbers a plan reads.
	for i in range(-1, Ladder.FINAL + 1):
		var stats := Ladder.racer(i)
		_expect(stats.has("knows") and stats.has("caution") and float(stats["knows"]) >= 0.0 and float(stats["knows"]) <= 1.0 and float(stats["caution"]) >= 0.0,
				"racer %d has `knows` (0 to 1) and `caution`" % i)
	_expect(Ladder.FIRST_RACER.has("knows") and Ladder.FIRST_RACER.has("caution"), "Halina's gentle day has `knows` and `caution`")
	_notes.append("traffic delay %.1f s on %d m with no way past in Busy traffic" % [Traffic.race_delay(_graph, alone, v, 1.0), roundi(_graph.e_s1[alone] - _graph.e_s0[alone])])


func _plans() -> void:
	var at := _start(HALINA)
	var e: int = at[0]
	var s: float = at[2]
	var plan := _plan(HALINA)
	var clock := plan.left(e, s, 0.0)
	_expect(clock < INF and clock > 30.0, "Halina's plan knows a way from Tamka (%.1f s)" % clock)
	var route := plan.route(e, s)
	_expect(_graph.e_b[route[route.size() - 1]] == at[3], "the plan's way ends at the finish")
	var mike := _plan(MIKE)
	var mike_at := _start(MIKE)
	_expect(mike.left(mike_at[0], mike_at[2], 0.0) < clock * 0.85, "Mike's plan is quicker than Halina's (%.1f s, %.1f s)" % [mike.left(mike_at[0], mike_at[2], 0.0), clock])

	# The town's traffic in the plan.
	var blind := _plan(HALINA, 1.0, {"knows": 0.0})
	_expect(absf(blind.left(e, s, 0.0) - clock) < 0.001, "a racer that knows nothing of the traffic plans as on clear roads (%.2f s, %.2f s)" % [blind.left(e, s, 0.0), clock])
	var busy := _plan(HALINA, 1.0, {"knows": 1.0, "caution": 0.0})
	var busy_clock := busy.left(e, s, 0.0)
	# Its clear way's cost in that traffic: the clock on clear roads and each street's delay.
	var same_way := clock
	for k in route.size():
		same_way += Traffic.race_delay(_graph, route[k], plan.speed(route[k]), 1.0)
	_expect(busy_clock > clock + 5.0, "a racer that knows the traffic gives the race more seconds in Busy traffic (%.1f s, clear %.1f s)" % [busy_clock, clock])
	_expect(busy_clock <= same_way + 0.5, "... and never more than its clear way costs in that traffic (%.1f s, %.1f s)" % [busy_clock, same_way])
	var careful := _plan(HALINA, 1.0, {"knows": 1.0, "caution": 1.0})
	_expect(careful.left(e, s, 0.0) >= busy_clock - 0.001, "caution never makes a plan quicker (%.1f s, %.1f s)" % [careful.left(e, s, 0.0), busy_clock])
	var low := _plan(HALINA, 0.22, {"knows": 1.0, "caution": 0.0})
	_expect(low.left(e, s, 0.0) > clock and low.left(e, s, 0.0) < busy_clock, "Low traffic costs the plan less than Busy (%.1f s)" % low.left(e, s, 0.0))

	# A street shut: news once, the new way round it, no quicker.
	var shut := -1
	for k in range(2, route.size() - 2):
		if _graph.e_s1[route[k]] - _graph.e_s0[route[k]] > 60.0:
			shut = route[k]
			break
	_expect(shut >= 0, "the way has a street to shut")
	if shut >= 0:
		var other := _plan(HALINA)
		_expect(other.block(PackedInt32Array([shut])), "shutting a street is news to the plan")
		_expect(not other.block(PackedInt32Array([shut])), "... once")
		var round := other.route(e, s)
		_expect(not shut in round, "the new way goes round the shut street")
		_expect(_graph.e_b[round[round.size() - 1]] == at[3], "... to the finish")
		_expect(other.left(e, s, 0.0) >= clock - 0.001, "... and is no quicker (%.1f s, %.1f s)" % [other.left(e, s, 0.0), clock])
		_expect(other.searches == 2, "one more search for the shut street (%d)" % other.searches)

	# In slices, and the whole map: the same way and time as at once.
	var sliced := _plan(HALINA)
	var slices := 0
	while not sliced.step(e, Traffic.PLAN_SLICE) and slices < 100000:
		slices += 1
	_expect(slices > 0 and slices < 100000, "a plan is searched in slices (%d of %d states)" % [slices, Traffic.PLAN_SLICE])
	_expect(sliced.choose(e, s, 0.0) == plan.choose(e, s, 0.0) and absf(sliced.chosen_time - plan.chosen_time) < 0.001, "the search in slices chooses the same way and time")
	var whole := _plan(HALINA)
	var works := 0
	while not whole.work(5000) and works < 10000:
		works += 1
	_expect(whole.work(1), "the search of the whole map ends")
	_expect(whole.choose(e, s, 0.0) == plan.choose(e, s, 0.0) and absf(whole.chosen_time - plan.chosen_time) < 0.001, "... on the same way and time")
	_notes.append("Halina's plan %.0f s on clear roads, %.0f s in Busy traffic, in %d slices" % [clock, busy_clock, slices + 1])


func _wrong_and_tight() -> void:
	# Słoik's wrong turns: along his way, every road the plan offers for one.
	var at := _start(SLOIK)
	var plan := _plan(SLOIK)
	var route := plan.route(at[0], at[2])
	var offered := 0
	for k in route.size() - 1:
		var e := route[k]
		var best := plan.choose(e, _graph.e_s0[e], plan.speed(e))
		if plan.wrong < 0:
			continue
		offered += 1
		var over := plan.wrong_time - plan.chosen_time
		_expect(over >= RacePlanner.WRONG_LEAST - 0.001 and over <= RacePlanner.WRONG_MOST + 0.001, "a wrong turn off edge %d costs %.1f s (%.0f to %.0f)" % [e, over, RacePlanner.WRONG_LEAST, RacePlanner.WRONG_MOST])
		_expect(plan.wrong != _graph.e_reverse[e] and plan.wrong != best, "a wrong turn off edge %d is neither the way back nor the best way" % e)
	_expect(offered > 0, "Słoik's way has a junction with a wrong turn to take")

	# A curve tighter than a car turns is the arc; a longer one is itself.
	_expect(absf(Traffic.race_turn_length(2.0, 2.9) - Traffic.RACE_TURN_RADIUS * 2.9) < 0.001, "a 2 m curve through 166 degrees is driven as the arc")
	_expect(Traffic.race_turn_length(30.0, 1.0) == 30.0, "a wide curve is driven as it is")
	# A hairpin onto another road: the U-turn's speed, and the arc's seconds.
	var planner: RacePlanner = _bench.planner
	var hairpins := 0
	for y in planner.states:
		var e := planner.state_edge[y]
		if planner.state_next[y] == _graph.e_reverse[e]:
			continue
		var bend := planner.curve(y)
		if bend.y <= Traffic.RACE_HAIRPIN:
			continue
		hairpins += 1
		var through: float = plan._through(y)
		_expect(through <= Traffic.UTURN_SPEED + 0.001, "a hairpin (edge %d to %d, %.0f degrees) is taken at the U-turn's speed (%.1f m/s)" % [e, planner.state_next[y], rad_to_deg(bend.y), through])
		_expect(plan._cross[y] >= Traffic.RACE_TURN_RADIUS * Traffic.RACE_HAIRPIN / Traffic.UTURN_SPEED - 0.001, "... and takes the arc's seconds (%.1f s)" % plan._cross[y])
		if hairpins >= 40:
			break
	_expect(hairpins > 0, "the map has a hairpin onto another road")
	_notes.append("%d wrong turns on offer, %d hairpins" % [offered, hairpins])


## A race of `name` from Tamka on the bench, with `over` on top of the spec.
func _race(name: String, over := {}) -> Dictionary:
	var spec := {"rival": name, "tuning": "ladder", "start": RaceBench.STARTS["tamka"], "start_name": "tamka", "situation": "clear", "player": "none"}
	spec.merge(over, true)
	var r: Dictionary = _bench.race(spec)
	_expect(not r.has("error"), "the race %s runs (%s)" % [r["id"], r.get("error", "")])
	return r


func _races() -> void:
	# The plan's clock against the race as driven.
	var clear := _race(HALINA)
	if clear.has("error"):
		return
	_expect(clear["finished"], "Halina finishes on clear roads")
	_expect(absf(float(clear["plan_s"]) / float(clear["time"]) - 1.0) <= CLOCK, "Halina's plan gives the race %.1f s, she drives it in %.1f s (within %d %%)" % [clear["plan_s"], clear["time"], roundi(CLOCK * 100.0)])
	var fast := _race(MIKE)
	_expect(fast["finished"] and absf(float(fast["plan_s"]) / float(fast["time"]) - 1.0) <= CLOCK, "Mike's plan gives the race %.1f s, he drives it in %.1f s (within %d %%)" % [fast["plan_s"], fast["time"], roundi(CLOCK * 100.0)])
	var edges := PackedInt32Array(clear["edges"])

	# A wall across a one-way street (the bench's own): backwards out to the junction behind.
	var spec := {"rival": HALINA, "tuning": "ladder", "start": RaceBench.STARTS["tamka"], "start_name": "tamka", "situation": "blocked", "player": "none"}
	var wall: Dictionary = _bench.plan_wall(spec, edges)
	_expect(not wall.is_empty() and _graph.e_reverse[int(wall.get("edge", 0))] < 0, "the bench's wall stands in a one-way street")
	if not wall.is_empty():
		var r := _race(HALINA, {"situation": "blocked", "wall": wall})
		_turned(r, int(wall["edge"]), "a wall in a one-way street (%s)" % wall["street"])
		_expect((3 in r["back"] or 4 in r["back"]) and not 5 in r["back"], "... she backs out to the junction behind (states %s)" % [r["back"]])

	# A wall across a two-way street: round in the street, the oncoming road next.
	var two := -1
	for k in range(1, edges.size()):
		var e := edges[k]
		if _graph.e_reverse[e] >= 0 and _graph.e_lanes[e] == 1 and _graph.e_s1[e] - _graph.e_s0[e] >= UTURN_STREET \
				and _graph.e_bridge[e] == 0 and _graph.e_tn[e] < 0:
			two = e
			break
	_expect(two >= 0, "her way has a two-way street of %d m to wall" % roundi(UTURN_STREET))
	if two >= 0:
		var rev := _graph.e_reverse[two]
		var here := {"edge": two, "s": (_graph.e_s0[two] + _graph.e_s1[two]) * 0.5, "street": _graph.e_name[two],
				"base_m": float(clear["route_m"]), "alt_m": float(clear["route_m"]), "turn_m": float(clear["route_m"])}
		var r := _race(HALINA, {"situation": "blocked", "wall": here})
		_turned(r, two, "a wall in a two-way street (%s)" % _graph.e_name[two])
		_expect(5 in r["back"] and not 3 in r["back"], "... she turns round in the street (states %s)" % [r["back"]])
		var driven := PackedInt32Array(r["edges"])
		var k := driven.find(two)
		_expect(k >= 0 and k + 1 < driven.size() and driven[k + 1] == rev, "... onto the oncoming road")
		_notes.append("a U-turn on %s, home in %.0f s" % [_graph.e_name[two], r["time"]])

	# The player's car stopped in her only lane, the first race: she turns back and comes home.
	var boxed := _race(HALINA, {"tuning": "first", "player": "stopped"})
	_expect(boxed["finished"], "behind the player's stopped car in the first race she comes home (%.0f s)" % boxed["time"])
	_expect(int(boxed["turned_back"]) >= 1 and int(boxed["overlaps"]) == 0 and int(boxed["jumps_seen"]) == 0,
			"... by turning back, through no car (turned back %d, through %d cars, put elsewhere %d times)" % [boxed["turned_back"], boxed["overlaps"], boxed["jumps_seen"]])

	# Out of the town's cars: the view far from the race, no cars on the road, and Busy traffic
	# owed street by street.
	var alone := _race(HALINA, {"view": FAR_VIEW})
	var away := _race(HALINA, {"view": FAR_VIEW, "traffic": 3})
	if alone["finished"] and away["finished"]:
		var owed := 0.0
		var share := float(Rivals.race_stats(Ladder.rung_of(HALINA))["share"])
		var driven := PackedInt32Array(away["edges"])
		for k in range(1, driven.size()):
			owed += Traffic.race_delay(_graph, driven[k], minf(RaceBench.PLAYER_TOP, Traffic.RACE_CLASS_TOP[_graph.e_class[driven[k]]]) * share, 1.0)
		var lost := float(away["time"]) - float(alone["time"])
		_expect(owed > 15.0, "Busy traffic owes her way a delay (%.1f s)" % owed)
		_expect(lost >= owed * (1.0 - AWAY) - AWAY_REST and lost <= owed * (1.0 + AWAY), "out of the town's cars she loses %.1f s of the %.1f s her streets owe (within %d %%, %.0f s still owed at the finish at most)" % [
				lost, owed, roundi(AWAY * 100.0), AWAY_REST])
		_expect(float(away["away_paid_s"]) > owed * 0.6 and float(alone["away_paid_s"]) == 0.0, "... paid as she drives (%.1f s), and nothing on clear roads" % away["away_paid_s"])
		_expect(int(away["hard_stops"]) == 0 and int(away["jumps_seen"]) == 0, "... with no step in her speed (%d hard stops)" % away["hard_stops"])
		_notes.append("out of sight in Busy traffic %.0f s against %.0f s on clear roads (%.0f s owed)" % [away["time"], alone["time"], owed])
	else:
		_expect(false, "she finishes with the view far away (clear %s, Busy %s)" % [alone["finished"], away["finished"]])

	# A lane held: the first race from Leszczyńska, where the slow test player starts in front
	# and the road has two lanes after 100 m.
	var lanes := {"tuning": "first", "start": RaceBench.STARTS["leszczynska"], "start_name": "leszczynska"}
	var free := _race(HALINA, lanes)
	lanes["player"] = "slow"
	var slow := _race(HALINA, lanes)
	if free["finished"] and slow["finished"]:
		var moved := (float(slow["time"]) - float(slow["hold_s"])) / maxf(float(free["time"]) - float(free["hold_s"]), 1.0) - 1.0
		_expect(moved <= RaceBench.INDEPENDENCE, "behind the slow player on two lanes she moves over and is past: %.1f s against %.1f s alone (%+.0f %%, at most %d %%)" % [
				slow["time"], free["time"], moved * 100.0, roundi(RaceBench.INDEPENDENCE * 100.0)])
		_notes.append("past the slow player on two lanes, %+.0f %%" % (moved * 100.0))
	else:
		_expect(false, "she finishes the first race from Leszczyńska (alone %s, with the slow player %s)" % [free["finished"], slow["finished"]])
	_notes.append("clock %+.0f %% (Halina), %+.0f %% (Mike)" % [(float(clear["plan_s"]) / float(clear["time"]) - 1.0) * 100.0, (float(fast["plan_s"]) / float(fast["time"]) - 1.0) * 100.0])


## A race `r` with a wall on edge `wall`: home by another way, having turned back, through no car.
func _turned(r: Dictionary, wall: int, what: String) -> void:
	_expect(r["finished"], "%s: she comes home" % what)
	_expect(int(r["turned_back"]) >= 1, "%s: she turns back" % what)
	_expect(int(r["overlaps"]) == 0 and int(r["jumps_seen"]) == 0 and int(r["slips"]) == 0, "%s: through no car and put nowhere by the game (through %d, put elsewhere %d, slips %d)" % [
			what, r["overlaps"], r["jumps_seen"], r["slips"]])
	var driven := PackedInt32Array(r["edges"])
	var k := driven.find(wall)
	_expect(k >= 0, "%s: she drives up to it" % what)
	if k >= 0:
		# Past the wall she would come onto the street after it; her way from the wall on never
		# takes the walled street again.
		_expect(driven.slice(k + 1).find(wall) < 0, "%s: she does not come back to it" % what)


## The metres from the finish's point `at` to the nearest (or with `far` the furthest) lane of edge
## e at s, and which lane that is: [metres, lane].
func _lane_gap(e: int, s: float, at: Vector2, far := false) -> Array:
	var best := -INF if far else INF
	var lane := -1
	for k in _graph.e_lanes[e]:
		var gap := _graph.point_at(e, s, _graph.lane_offset(e, k)).distance_to(at)
		if (gap > best) if far else (gap < best):
			best = gap
			lane = k
	return [best, lane]


## A racer alone on the road: Halina on lane `lane` of edge e at s with `plan` (and its metres
## `dist`) to finish `fin`, driven until she is home, leaves the street or `most` s pass:
## [home, the s she is at, her metres from the finish's point].
func _drive(fin: Dictionary, plan: RacePlanner.Plan, dist: PackedFloat32Array, e: int, lane: int, s: float, most: float) -> Array:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(cam)
	var traffic: Node3D = Traffic.new()
	root.add_child(traffic)
	traffic.setup(_graph, _bench._map, cam, {})
	traffic.set_process(false)
	traffic.set_physics_process(false)
	traffic.spawning = false
	var body := Node3D.new()
	traffic.add_child(body)
	var d = traffic.add_node_driver(body, Rivals.RIVALS[RaceBench.rival_index(HALINA)]["size"], e, lane, s)
	Rivals.arm_racer(d, Ladder.rung_of(HALINA), RaceBench.PLAYER_TOP, {}, false, 0.0, 1)
	traffic.race_to(d, fin["node"], dist, plan)
	var t := 0.0
	while t < most and not d.arrived and d.edge == e and not d.in_conn:
		traffic.player_on_road = false
		traffic.player_pos = d.pos + Vector3(5000.0, 0.0, 0.0)
		traffic.player_vel = Vector3.ZERO
		_bench._look(cam, d.pos)
		traffic._process(RaceBench.DT)
		t += RaceBench.DT
	var out := [d.arrived, d.s, Vector2(d.pos.x, d.pos.z).distance_to(fin["at"])]
	traffic.free()
	cam.free()
	return out


## A finish's circle (RacePlanner.ends: the roads through it; rivals.gd FINISH_RADIUS).
func _circle() -> void:
	var planner: RacePlanner = _bench.planner
	var radius := Rivals.FINISH_RADIUS
	var top := RaceBench.PLAYER_TOP
	# The prototype race's finish: no road but its own junction's runs through the circle, and the
	# plan made for the circle is the plan to the junction, state for state.
	var home: Dictionary = _bench.finish(RaceBench.FINISH)
	_expect(home["ends"].is_empty(), "no other road runs through the circle at %s (%d)" % [RaceBench.FINISH, home["ends"].size()])
	var at := _start(HALINA)
	var plain := _plan(HALINA)
	var same: RacePlanner.Plan = planner.plan(at[3], _stats(HALINA), top, _bench.links_of(HALINA)[0], 0.0, PackedInt32Array(), home["at"], radius)
	_expect(same.left(at[0], at[2], 0.0) == plain.left(at[0], at[2], 0.0) and same.settled == plain.settled,
			"... so the plan to its circle is the plan to its junction (%.3f s in %d states, %.3f s in %d)" % [same.left(at[0], at[2], 0.0), same.settled, plain.left(at[0], at[2], 0.0), plain.settled])

	# The Palace: its junction is on one carriageway of Emilii Plater, the other runs through.
	var fin: Dictionary = _bench.finish(RaceBench.PALACE)
	_expect(not fin.is_empty() and not fin.get("ends", {}).is_empty(), "a road runs through the circle at the Palace")
	if fin.is_empty() or fin["ends"].is_empty():
		return
	var ends: Dictionary = fin["ends"]
	var node: int = fin["node"]
	# The road with the longest way up to the circle, and one that goes on past it.
	var f := -1
	var g := -1
	for e: int in ends:
		var end: Vector2 = ends[e]
		_expect(_graph.e_b[e] != node and _graph.e_a[e] != node, "edge %d is not a road of the finish's own junction" % e)
		_expect(end.x >= _graph.e_s0[e] - 0.001 and end.y <= _graph.e_s1[e] + 0.001 and end.x <= end.y and end.y - end.x <= 2.0 * (radius + RacePlanner.END_REACH),
				"edge %d's stretch in the circle lies on it (%.1f to %.1f of %.1f to %.1f)" % [e, end.x, end.y, _graph.e_s0[e], _graph.e_s1[e]])
		var near := INF
		var s := end.x
		while s <= end.y + 0.001:
			near = minf(near, float(_lane_gap(e, minf(s, end.y), fin["at"])[0]))
			s += RacePlanner.END_STEP
		_expect(float(_lane_gap(e, end.x, fin["at"])[0]) < radius and near < radius - RacePlanner.END_MARGIN,
				"edge %d has a lane in the circle where it enters, and one %d m inside it (%.1f m, %.1f m)" % [e, roundi(RacePlanner.END_MARGIN), _lane_gap(e, end.x, fin["at"])[0], near])
		if f < 0 or end.x - _graph.e_s0[e] > ends[f].x - _graph.e_s0[f]:
			f = e
		if _graph.e_s1[e] - end.y > 3.0 and (g < 0 or _graph.e_s1[e] - end.y > _graph.e_s1[g] - ends[g].y):
			g = e
	var end_f: Vector2 = ends[f]
	_expect(end_f.x - _graph.e_s0[f] > 30.0 and g >= 0, "one of them comes up to the circle over 30 m, and one goes on past it")
	# On the finish's own level only: the road under a bridge, or over the street, is not the finish.
	_expect(planner._inside(f, fin["at"], radius, 0.0) == end_f, "on the finish's level the road is in")
	_expect(planner._inside(f, fin["at"], radius, RacePlanner.END_LEVEL - 0.1) == end_f and planner._inside(f, fin["at"], radius, -RacePlanner.END_LEVEL + 0.1) == end_f,
			"... and a little above or below it too")
	_expect(planner._inside(f, fin["at"], radius, RacePlanner.END_LEVEL + 0.1).x == INF and planner._inside(f, fin["at"], radius, -RacePlanner.END_LEVEL - 0.1).x == INF,
			"%.0f m above or below the finish it is another level's road, out of the circle" % RacePlanner.END_LEVEL)

	# The plan to the circle against the plan to the junction, from the first race's start.
	var dist_j: PackedFloat32Array = _bench.roads_to(node)
	var dist_c: PackedFloat32Array = _graph.distances_to(node, INF, true, planner.links(node, ends))
	var places: Dictionary = _bench.grid(RaceBench.STARTS[RaceBench.PALACE_START], dist_c, true)
	_expect(not places.is_empty(), "the map has a lane at the Palace race's start")
	if places.is_empty():
		return
	var e0: int = places["rival"][0]
	var s0: float = places["rival"][2]
	var circle: RacePlanner.Plan = planner.plan(node, _stats(HALINA), top, {}, 0.0, PackedInt32Array(), fin["at"], radius)
	var junction: RacePlanner.Plan = planner.plan(node, _stats(HALINA), top)
	var t_c := circle.left(e0, s0, 0.0)
	var t_j := junction.left(e0, s0, 0.0)
	_expect(t_c < t_j - CIRCLE_GAIN, "from Marszałkowska the plan to the Palace's circle is the quicker by %d s or more (%.1f s, %.1f s to the junction)" % [roundi(CIRCLE_GAIN), t_c, t_j])
	var way := circle.route(e0, s0)
	_expect(ends.has(way[way.size() - 1]), "... and ends on a road through the circle (edge %d)" % way[way.size() - 1])
	var way_j := junction.route(e0, s0)
	_expect(_graph.e_b[way_j[way_j.size() - 1]] == node, "the plan to the junction ends at the junction")
	while not circle.work(100000):
		pass
	while not junction.work(100000):
		pass
	var slower := 0
	var tried := 0
	for e in range(0, _graph.e_a.size(), 3):
		var to_junction := junction.left(e, _graph.e_s0[e], 0.0)
		if to_junction == INF:
			continue
		tried += 1
		if circle.left(e, _graph.e_s0[e], 0.0) > to_junction + 0.001:
			slower += 1
	_expect(tried > 1000 and slower == 0, "from no street is the plan to the circle the slower one (%d of %d)" % [slower, tried])

	# On the road through the circle: the metres to it, and past it the way round.
	var v := circle.speed(f)
	var before := end_f.x - 10.0
	_expect(circle.ends_on(f, before) and absf(circle.left(f, before, v) - 10.0 / v) < 0.01, "10 m short of the circle on %s the plan has %.2f s left (10 m at %.1f m/s)" % [_graph.e_name[f], circle.left(f, before, v), v])
	_expect(absf(circle.metres(dist_c, f, before) - 10.0) < 0.001 and circle.metres(dist_c, f, end_f.x + 0.2) == 0.0, "... and 10 m, and none inside it (%.1f m)" % circle.metres(dist_c, f, before))
	_expect(circle.end_of(f) == end_f and junction.end_of(f).x == INF, "the plan to the circle has the road's stretch, the plan to the junction none")
	var past: float = ends[g].y + 2.0
	_expect(not circle.ends_on(g, past) and circle.left(g, past, circle.speed(g)) > 5.0 and circle.metres(dist_c, g, past) > 50.0,
			"past the circle on %s the finish is behind: %.1f s and %.0f m round" % [_graph.e_name[g], circle.left(g, past, circle.speed(g)), circle.metres(dist_c, g, past)])
	# The search's seed: a way into the road costs its curve and the road up to the circle only.
	var seeds := 0
	for p: int in _graph.node_in[_graph.e_a[f]]:
		var y: int = planner.first[p] + planner.slot[f]
		var part := end_f.x - _graph.e_s0[f]
		var want: float = circle._cross[y] + circle._street(part, circle._through(y), v, v) + circle._extra[f] * part / (_graph.e_s1[f] - _graph.e_s0[f])
		seeds += 1
		_expect(absf(circle._time[y] - want) < 0.01, "the way from edge %d into %s is its curve and %.0f m of the road (%.2f s, %.2f s)" % [p, _graph.e_name[f], part, circle._time[y], want])
	_expect(seeds > 0, "a road leads into %s" % _graph.e_name[f])

	# The metres, and the links the routing gets for them.
	_expect(dist_c[_graph.e_a[f]] <= end_f.x + 0.001 and dist_j[_graph.e_a[f]] > end_f.x + 100.0,
			"from the start of %s it is %.0f m to the circle, %.0f m to the junction" % [_graph.e_name[f], dist_c[_graph.e_a[f]], dist_j[_graph.e_a[f]]])
	var longer := 0
	for k in dist_c.size():
		if dist_c[k] > dist_j[k] + 0.001:
			longer += 1
	_expect(longer == 0, "from no junction is it further to the circle than to the finish's junction (%d)" % longer)
	var own := {node: PackedFloat32Array([8.0, 9.0])}
	_expect(is_same(planner.links(node, {}, own), own), "no road through the circle: the links are the racer's own")
	var merged: Dictionary = planner.links(node, ends, own)
	_expect(merged[node].size() == 2 + 2 * ends.size() and merged[node][0] == 8.0 and own[node].size() == 2, "the circle's links come after the racer's own, which stay as they were")

	# A road through the circle shut to the racer: no finish, and no link for its metres.
	var shut: RacePlanner.Plan = planner.plan(node, _stats(HALINA), top, {}, 0.0, PackedInt32Array(), fin["at"], radius)
	_expect(shut.block(PackedInt32Array([f])), "shutting the road through the circle is news to the plan")
	_expect(not shut.ends_on(f, before) and shut.end_of(f).x == INF, "... and it is no finish for that racer")
	_expect(shut.left(e0, s0, 0.0) >= t_c - 0.001, "... whose plan is no quicker for it (%.1f s, %.1f s)" % [shut.left(e0, s0, 0.0), t_c])
	_expect(planner.links(node, ends, {}, shut.shut).get(node, PackedFloat32Array()).size() == 2 * ends.size() - 2, "... and whose metres go round it")

	# The minimap's line: to where its road enters the circle, shorter than the line to the junction.
	var line := RouteLine.new(_graph)
	line.to_node(node, fin["at"], _graph.distances_to(node, INF, false, planner.links(node, ends)), ends)
	var pts := PackedVector2Array()
	line.walk(e0, s0, pts)
	var at_end := false
	for e: int in ends:
		if pts[pts.size() - 1].distance_to(_graph.point_at(e, ends[e].x)) < 0.01:
			at_end = true
	var plain_line := RouteLine.new(_graph)
	plain_line.to_node(node, fin["at"])
	var plain_pts := PackedVector2Array()
	plain_line.walk(e0, s0, plain_pts)
	_expect(at_end and _length(pts) < _length(plain_pts) - 100.0, "the minimap's line ends where its road enters the circle (%.0f m; %.0f m to the junction)" % [_length(pts), _length(plain_pts)])

	# In whichever lane: on the lane furthest from the finish she is home where the road enters the
	# circle, outside it; with the plan to the junction alone, or past the circle, she is not.
	var far := _lane_gap(f, (end_f.x + end_f.y) * 0.5, fin["at"], true)
	_expect(float(far[0]) > radius + 1.0, "the furthest lane of %s runs outside the circle (%.1f m from the finish)" % [_graph.e_name[f], far[0]])
	var came := _drive(fin, circle, dist_c, f, far[1], end_f.x - 25.0, 10.0)
	_expect(came[0] and float(came[1]) >= end_f.x - 0.001 and float(came[1]) <= end_f.x + 1.5, "on it she is home where the road enters the circle (at %.1f m of the street; it enters at %.1f m)" % [came[1], end_f.x])
	_expect(float(came[2]) > radius, "... %.1f m from the finish's point: the line runs across the carriageway" % came[2])
	var drove_on := _drive(fin, junction, dist_j, f, far[1], end_f.x - 25.0, 10.0)
	_expect(not drove_on[0], "with the plan to the junction alone she drives on")
	var behind := _drive(fin, circle, dist_c, g, _lane_gap(g, past, fin["at"], true)[1], past + 1.0, 4.0)
	_expect(not behind[0], "past the circle on %s she is not home" % _graph.e_name[g])

	# The player's car has the same line (rivals.gd `home_at`): home inside the circle; on a road
	# through it level with the circle in whichever lane; not short of it, past it, beside the
	# road, on another level, or without such a road.
	var goal := Vector3(fin["at"].x, 0.0, fin["at"].y)
	var mid := (end_f.x + end_f.y) * 0.5
	var on_far: Vector2 = _graph.point_at(f, mid, _graph.lane_offset(f, far[1]))
	var up: float = _graph.height(f, mid)
	_expect(on_far.distance_to(fin["at"]) > radius + 1.0 and Rivals.home_at(_graph, Vector3(on_far.x, up, on_far.y), goal, ends),
			"the player's car in the furthest lane of %s, level with the circle, is home (%.1f m from the finish's point)" % [_graph.e_name[f], on_far.distance_to(fin["at"])])
	_expect(not Rivals.home_at(_graph, Vector3(on_far.x, up, on_far.y), goal, {}), "... by that road alone: at a finish with no road through its circle it is not")
	_expect(Rivals.home_at(_graph, Vector3(fin["at"].x + radius - 1.0, up + 40.0, fin["at"].y), goal, {}), "inside the circle a car is home, whatever its road (PT-22)")
	var short: Vector2 = _graph.point_at(f, end_f.x - 3.0, _graph.lane_offset(f, far[1]))
	_expect(short.distance_to(fin["at"]) > radius and not Rivals.home_at(_graph, Vector3(short.x, up, short.y), goal, ends), "3 m short of the circle in that lane it is not home")
	var far_g := _lane_gap(g, past, fin["at"], true)
	var gone: Vector2 = _graph.point_at(g, past, _graph.lane_offset(g, far_g[1]))
	_expect(gone.distance_to(fin["at"]) > radius and not Rivals.home_at(_graph, Vector3(gone.x, up, gone.y), goal, ends), "past the circle on %s it is not home" % _graph.e_name[g])
	var centre: Vector2 = fin["at"]
	var away := (on_far - centre).normalized()
	var kerb := on_far + away * 2.0
	var beside := on_far + away * OFF_ROAD
	_expect(Rivals.home_at(_graph, Vector3(kerb.x, up, kerb.y), goal, ends), "at the kerb of that lane it is home")
	_expect(beside.distance_to(fin["at"]) < radius + RacePlanner.END_REACH and not Rivals.home_at(_graph, Vector3(beside.x, up, beside.y), goal, ends),
			"%.0f m off the road it is not (%.1f m from the finish's point)" % [OFF_ROAD, beside.distance_to(fin["at"])])
	_expect(not Rivals.home_at(_graph, Vector3(on_far.x, up + RacePlanner.END_LEVEL + 1.0, on_far.y), goal, ends) and not Rivals.home_at(_graph, Vector3(on_far.x, up - RacePlanner.END_LEVEL - 1.0, on_far.y), goal, ends),
			"%.0f m over or under that road it is not" % (RacePlanner.END_LEVEL + 1.0))

	# Trzy mosty's finish by the stadium: the avenue's other carriageway runs through its circle,
	# so Seba's last leg is planned to the circle too (rivals.gd `start_final`).
	var last: Dictionary = _bench.final_finish()
	_expect(not last.is_empty() and not last.get("ends", {}).is_empty(), "a road runs through the circle at Trzy mosty's finish")
	if not last.is_empty() and not last["ends"].is_empty():
		var to_circle: PackedFloat32Array = _graph.distances_to(last["node"], INF, true, planner.links(last["node"], last["ends"]))
		var to_junction: PackedFloat32Array = _bench.roads_to(last["node"])
		_expect(to_circle[last["from"]] < to_junction[last["from"]] - FINAL_GAIN,
				"from the last bridge it is %.0f m to the circle and %.0f m to the finish's junction" % [to_circle[last["from"]], to_junction[last["from"]]])
		var seba := Rivals.race_stats(Ladder.FINAL)
		var leg_c: RacePlanner.Plan = planner.plan(last["node"], seba, top, {}, 0.0, PackedInt32Array(), last["at"], radius)
		var leg_j: RacePlanner.Plan = planner.plan(last["node"], seba, top)
		var best_c := INF
		var best_j := INF
		for e: int in _graph.node_in[last["from"]]:
			best_c = minf(best_c, leg_c.left(e, _graph.e_s1[e], 15.0))
			best_j = minf(best_j, leg_j.left(e, _graph.e_s1[e], 15.0))
		_expect(best_c < best_j - 10.0, "Seba's last leg is %.1f s to the circle, %.1f s to the junction" % [best_c, best_j])
		_notes.append("Trzy mosty's finish: %.0f m and %.0f s from the last bridge to its circle (%.0f m, %.0f s to its junction)" % [
				to_circle[last["from"]], best_c, to_junction[last["from"]], best_j])

	# The race itself, as the whole game ran it: the guided first race from Marszałkowska.
	var spec := {"rival": HALINA, "tuning": "first", "start": RaceBench.STARTS[RaceBench.PALACE_START], "start_name": RaceBench.PALACE_START,
			"finish": RaceBench.PALACE, "situation": "clear", "player": "none"}
	var clear: Dictionary = _bench.race(spec)
	_expect(not clear.has("error") and clear["finished"], "the first race to the Palace runs and she comes home (%s)" % clear.get("error", ""))
	if clear.has("error") or not clear["finished"]:
		return
	_expect(absf(float(clear["plan_s"]) / float(clear["time"]) - 1.0) <= CLOCK, "her plan gives the race to the Palace %.1f s, she drives it in %.1f s (within %d %%)" % [clear["plan_s"], clear["time"], roundi(CLOCK * 100.0)])
	_expect(ends.has(int(clear["edges"][clear["edges"].size() - 1])) and float(clear["driven_m"]) <= float(clear["route_m"]) + 15.0,
			"... home on a road through the circle, having driven her %.0f m and no more (%.0f m)" % [clear["route_m"], clear["driven_m"]])
	spec["situation"] = "heavy"
	spec["traffic"] = 1
	spec["player"] = "average"
	var low: Dictionary = _bench.race(spec)
	_expect(not low.has("error") and low["finished"] and float(low["time"]) <= float(clear["time"]) * CIRCLE_TRAFFIC and ends.has(int(low["edges"][low["edges"].size() - 1])),
			"in Low traffic with a player about she is home on that road in %.1f s (%.1f s on clear roads, at most %d %% more)" % [low["time"], clear["time"], roundi((CIRCLE_TRAFFIC - 1.0) * 100.0)])
	_notes.append("the Palace's circle: %d roads through, the plan %.0f s against %.0f s to the junction, the first race %.0f s (%.0f s in Low traffic with a player)" % [
			ends.size(), t_c, t_j, clear["time"], low["time"]])


## The length of a polyline (m).
func _length(pts: PackedVector2Array) -> float:
	var out := 0.0
	for k in range(1, pts.size()):
		out += pts[k - 1].distance_to(pts[k])
	return out
