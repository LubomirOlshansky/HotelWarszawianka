extends SceneTree
## Racer AI step 5 (docs/design/race-ai.md 5.4): the race links, ways through yards, car parks and
## alleys (game/data/race_links.json, tools/race_links.py). Checks, without the city:
## - the file parses, holds at least MIN_LINKS proven links, and every link has a proof that
##   matches its points (the player's car drove it: tools/race_links.sh) or says why the car could
##   not (`refused`); every proven link snaps to the committed map's lane graph and is loaded
##   (race_cuts.gd), and no other is;
## - a link's curve (race_cuts.gd `curve`, a chain of cubic pieces) starts and ends where the
##   streets' lanes do, passes within ON_LINE m of every point of the link, and is no more than
##   LONGER longer than they are; a cut's curve is still one piece (LaneGraph `bezier` and
##   `bezier_length` are the same as before for it);
## - its speeds stay at or under RaceCuts.LINK_TOP and its bends' pull at the racer's grip;
## - knowledge (ladder.gd `yards`, `narrow`): Słoik knows none, Halina only the wide ones (none
##   under her `narrow`), Zbyszek every one he dares, and a link is never in a racer's table under
##   its width;
## - the wrong-way hops (step 5b, kind "wrong"; ladder.gd `hops`): each drives against a one-way
##   street between its own two junctions (`RaceCuts.hop`) and no other link does; only Seba and
##   Mike (and Seba in the final) have them, every one; a plan never enters a hop from the street
##   it drives against, and a hop refused (`Plan.refuse`) is not chosen again;
## - the routing with every link never makes a junction further from a finish, and for every link
##   it is shorter than the road between its two junctions as a racer counts it (RaceCuts.cost).
##   godot --headless --path game --script res://tools/check_race_links.gd

const LaneGraph := preload("res://scripts/lane_graph.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Ladder := preload("res://scripts/ladder.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")

const MIN_LINKS := 20
const ON_LINE := 1.5
const LONGER := 0.08
## Step 5b: proven wrong-way hops at least, a hop's metres at most (junction to junction: the
## street's 150 m, tools/race_links.py HOP_MAX, and the two junctions' boxes), and the hops whose
## plans are tried.
const MIN_HOPS := 30
const HOP_MOST := 175.0
const HOP_PLANS := 12


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func roof_height(_x: float, _z: float) -> float:
		return -1000.0
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0


var _problems := 0
var _summary := {}


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_curves()
	_knowledge()
	if FileAccess.file_exists("res://map/centrum.json"):
		_map()
	else:
		_summary["map"] = "no map data: links skipped"
	if _problems == 0:
		print("race_links: OK (%s)" % ", ".join(PackedStringArray(_summary.values())))
		quit(0)
	else:
		print("check_race_links: %d problem(s)" % _problems)
		quit(1)


## A cut's one piece is driven as before; a chain's pieces join up and run with their metres.
func _curves() -> void:
	var c := PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(8, 2), Vector2(10, 6)])
	var u := 0.3
	var w := 1.0 - u
	var by_hand := c[0] * (w * w * w) + c[1] * (3.0 * w * w * u) + c[2] * (3.0 * w * u * u) + c[3] * (u * u * u)
	_expect(LaneGraph.bezier(c, u).is_equal_approx(by_hand), "a cut's curve is not the one cubic piece any more")
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 40)])
	var ch := RaceCuts.chain(pts, Vector2(1, 0), Vector2(0, 1))
	_expect(ch.size() > 4 and (ch.size() - 1) % 3 == 0, "a chain has %d points (3n + 1)" % ch.size())
	_expect(LaneGraph.bezier(ch, 0.0).is_equal_approx(pts[0]) and LaneGraph.bezier(ch, 1.0).is_equal_approx(pts[2]), "a chain does not start and end at its points")
	var length := LaneGraph.bezier_length(ch)
	_expect(length > 66.0 and length < 72.0, "a chain round a 70 m corner is %.1f m" % length)
	# Its parameter runs with its metres (pieces of one length): halfway is about 35 m along.
	var half := LaneGraph.bezier(ch, 0.5)
	_expect(half.distance_to(Vector2(30, 5)) < 3.0, "halfway along the chain is at %s, not near (30, 5)" % half)
	var v := RaceCuts.speeds(ch, 10.0, RaceCuts.LINK_TOP, 40)
	var top := 0.0
	for x in v:
		top = maxf(top, x)
	_expect(top <= RaceCuts.LINK_TOP + 0.001, "a link's speed reaches %.1f m/s" % top)
	_expect(RaceCuts.bend_speed(ch, 10.0, RaceCuts.LINK_TOP) < 9.0, "the corner of a chain is taken at %.1f m/s" % RaceCuts.bend_speed(ch, 10.0, RaceCuts.LINK_TOP))
	_summary["curves"] = "chain %d pieces, %.1f m" % [(ch.size() - 1) / 3, length]


func _knowledge() -> void:
	var by := {}
	for i in Ladder.RUNGS.size():
		by[Ladder.RUNGS[i]["id"]] = Ladder.racer(i)
	_expect(float(by["sloik"]["yards"]) == 0.0, "Słoik knows yards (he follows his satnav)")
	_expect(float(by["halina"]["yards"]) == 1.0, "Halina doesn't know every yard")
	_expect(float(by["halina"]["narrow"]) >= 3.5, "Halina dares the narrow links")
	_expect(float(by["zbyszek"]["yards"]) == 1.0, "Zbyszek doesn't know every yard")
	_expect(float(by["seba"]["narrow"]) < float(by["halina"]["narrow"]), "Seba dares no narrower links than Halina")
	_expect(float(Ladder.FIRST_RACER["yards"]) == float(by["halina"]["yards"]), "Halina's gentle day knows other yards than Halina")
	# Step 5b: the wrong way down a one-way street only for the two who dare (parked question 3).
	for id: String in by:
		_expect((float(by[id]["hops"]) == 1.0) == (id == "seba" or id == "mike"), "%s's wrong-way hops are %.1f (Seba and Mike only)" % [id, float(by[id]["hops"])])
	_expect(float(Ladder.FINAL_RACER["hops"]) == 1.0, "Seba in the final takes no wrong-way hop")
	_expect(float(Ladder.FIRST_RACER["hops"]) == 0.0 and float(Ladder.DEFAULT_RACER["hops"]) == 0.0, "Halina's gentle day or a race off the ladder takes wrong-way hops")
	_summary["knowledge"] = "Halina %.0f %% over %.1f m, Seba %.0f %% over %.1f m" % [
			float(by["halina"]["yards"]) * 100.0, float(by["halina"]["narrow"]), float(by["seba"]["yards"]) * 100.0, float(by["seba"]["narrow"])]


func _map() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RaceCuts.LINKS_PATH))
	if not parsed is Dictionary:
		_expect(false, "%s does not parse" % RaceCuts.LINKS_PATH)
		return
	var listed: Array = parsed.get("links", [])
	var unproven: Array[String] = []
	var refused := 0
	for l: Dictionary in listed:
		if String(l.get("refused", "")) != "":
			refused += 1
			_expect(String(l.get("proof", "")) == "", "link %s is proven and refused" % l["id"])
		elif String(l.get("proof", "")) != String(l["id"]):
			unproven.append(String(l["id"]))
	_expect(listed.size() - refused >= MIN_LINKS, "only %d proven race links (at least %d)" % [listed.size() - refused, MIN_LINKS])
	_expect(unproven.is_empty(), "%d links were never driven or have no proof that matches their points (%s): run tools/race_links.sh" % [
			unproven.size(), ", ".join(unproven.slice(0, 5))])
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	var cuts := RaceCuts.new()
	cuts.load_cuts(g)
	var n_links := cuts.a.size() - cuts.first_link
	_expect(cuts.links_missed == 0, "%d proven links find no junction: re-run tools/race_links.sh" % cuts.links_missed)
	_expect(n_links == listed.size() - refused - unproven.size() - cuts.links_missed, "%d links loaded of %d proven" % [n_links, listed.size() - refused - unproven.size()])
	# Each link's curve, from the street into it that meets it straightest to its first way on.
	var worst_off := 0.0
	var worst_long := 0.0
	var by_kind := {}
	for i in range(cuts.first_link, cuts.a.size()):
		var pts: PackedVector2Array = cuts.shape[i]
		by_kind[cuts.kind[i]] = int(by_kind.get(cuts.kind[i], 0)) + 1
		_expect(not cuts.exits_ab[i].is_empty(), "link %d has no way on from its far junction" % i)
		_expect(cuts.exits_ba[i].is_empty(), "link %d is driven backwards" % i)
		var e_in := -1
		var best := -2.0
		for e: int in g.node_in[cuts.a[i]]:
			var dot := g.direction(e, g.e_s1[e]).dot((pts[1] - pts[0]).normalized())
			if dot > best and RaceCuts.hop(cuts.a[i], cuts.b[i]) != e:
				best = dot
				e_in = e
		if e_in < 0 or cuts.exits_ab[i].is_empty():
			_expect(false, "link %d has no street into it" % i)
			continue
		var c := RaceCuts.curve(g, e_in, 0, cuts.exits_ab[i][0])
		_expect(RaceCuts.is_link(c), "link %d is driven as a straight cut" % i)
		var samples := PackedVector2Array()
		var n := maxi(ceili(LaneGraph.bezier_length(c) / 0.5), 8)
		for k in n + 1:
			samples.append(LaneGraph.bezier(c, float(k) / n))
		var off := 0.0
		for q in pts:
			var near := INF
			for k in samples.size() - 1:
				near = minf(near, Geometry2D.get_closest_point_to_segment(q, samples[k], samples[k + 1]).distance_to(q))
			off = maxf(off, near)
		worst_off = maxf(worst_off, off)
		_expect(off <= ON_LINE, "link %d: its curve passes %.1f m from one of its points" % [i, off])
		var along := 0.0
		for k in range(1, pts.size()):
			along += pts[k].distance_to(pts[k - 1])
		var long := LaneGraph.bezier_length(c) / maxf(along + c[0].distance_to(pts[0]) + pts[pts.size() - 1].distance_to(c[c.size() - 1]), 1.0) - 1.0
		worst_long = maxf(worst_long, long)
		_expect(long <= LONGER, "link %d: its curve is %.0f %% longer than its points" % [i, long * 100.0])
	# Step 5b: a wrong-way hop drives against a one-way street between its own two junctions; no
	# other link does.
	var hops := 0
	for i in range(cuts.first_link, cuts.a.size()):
		var h := RaceCuts.hop(cuts.a[i], cuts.b[i])
		if cuts.kind[i] != "wrong":
			_expect(h < 0, "link %d (%s) counts as a wrong-way hop" % [i, cuts.kind[i]])
			continue
		hops += 1
		_expect(h >= 0 and g.e_a[h] == cuts.b[i] and g.e_b[h] == cuts.a[i] and g.e_reverse[h] < 0,
				"hop %d does not drive against a one-way street between its junctions" % i)
		_expect(cuts.length[i] <= HOP_MOST, "hop %d is %.0f m long (at most %.0f)" % [i, cuts.length[i], HOP_MOST])
	_expect(hops >= MIN_HOPS, "only %d proven wrong-way hops (at least %d)" % [hops, MIN_HOPS])
	# Who knows which: a racer never has a link under its `narrow` (a hop is a street: by `hops`).
	for rung in Ladder.RUNGS.size():
		var stats := Ladder.racer(rung)
		var both := cuts.links(float(stats["cuts"]), hash(String(Ladder.RUNGS[rung]["rival"])), float(stats["yards"]), float(stats["narrow"]), float(stats.get("hops", 0.0)))
		var table: Dictionary = both[0]
		var known := 0
		for i in range(cuts.first_link, cuts.a.size()):
			var has := false
			if table.has(cuts.a[i]):
				var list: PackedFloat32Array = table[cuts.a[i]]
				for k in range(0, list.size(), 2):
					if int(list[k]) in cuts.exits_ab[i] and is_equal_approx(list[k + 1], cuts.length[i]):
						has = true
			if cuts.kind[i] == "wrong":
				_expect(has == (float(stats["hops"]) >= 1.0), "%s %s hop %d" % [Ladder.RUNGS[rung]["id"], "has" if has else "lacks", i])
			elif has:
				known += 1
				_expect(cuts.width[i] >= float(stats["narrow"]), "%s knows link %d of %.1f m, under its %.1f m" % [Ladder.RUNGS[rung]["id"], i, cuts.width[i], float(stats["narrow"])])
		if float(stats["yards"]) == 0.0:
			_expect(known == 0, "%s knows %d links" % [Ladder.RUNGS[rung]["id"], known])
	# Every link is worth taking: from its near junction to its far one, a racer that knows it counts
	# it (RaceCuts.cost) shorter than the best road, and it makes no junction further from a finish.
	var all := cuts.links(0.0, 0, 1.0, 0.0, 1.0)
	# Step 5b: a plan with every hop never enters one from the street it drives against, takes it
	# from another street into the junction, and does not choose a hop it has refused.
	var planner := RacePlanner.new(g)
	var hop_plans := 0
	for i in range(cuts.first_link, cuts.a.size()):
		if cuts.kind[i] != "wrong" or hop_plans >= HOP_PLANS:
			continue
		var h := RaceCuts.hop(cuts.a[i], cuts.b[i])
		var exit: int = cuts.exits_ab[i][0]
		var plan: RacePlanner.Plan = planner.plan(g.e_b[exit], Ladder.racer(Ladder.rung_of("Seba z Pragi")), 30.0, all[0])
		_expect(plan._cut_state(h, exit) < 0, "hop %d can be entered from the street it drives against" % i)
		for e: int in g.node_in[cuts.a[i]]:
			if e == h or g.e_tn[e] >= 0 or g.e_reverse[e] == exit:
				continue
			var way: int = plan.choose(e, g.e_s0[e], 10.0)
			if not (plan.chosen_cut and way == exit):
				continue
			hop_plans += 1
			plan.refuse(e, exit)
			_expect(plan.searches == 2, "hop %d refused: the plan was not searched again" % i)
			var other: int = plan.choose(e, g.e_s0[e], 10.0, exit, true)
			_expect(not (plan.chosen_cut and other == exit), "hop %d is chosen again after it was refused" % i)
			_expect(other >= 0, "hop %d refused: the plan knows no other way from that street" % i)
			break
	_expect(hop_plans >= 3, "only %d hops were a plan's way to the junction just beyond them" % hop_plans)
	var taken := 0
	for i in range(cuts.first_link, cuts.a.size()):
		var pts: PackedVector2Array = cuts.shape[i]
		var far: int = cuts.b[i]
		var plain := g.distances_to(far, INF, false)
		var dist := g.distances_to(far, INF, false, all[1])
		var worse := 0
		for n in dist.size():
			if dist[n] > plain[n] + 0.01:
				worse += 1
		_expect(worse == 0, "link %d makes %d junctions further from a finish" % [i, worse])
		var road := INF
		for f in g.node_out[cuts.a[i]]:
			road = minf(road, g.e_len[f] + plain[g.e_b[f]])
		var by_link := cuts.length[i] * RaceCuts.COST + RaceCuts.GAIN
		if by_link < road:
			taken += 1
		elif OS.is_stdout_verbose():
			print("  not worth it: link %d (%.0f, %.0f) %.0f m, road %.0f m, counted %.0f m" % [i, pts[0].x, pts[0].y, cuts.length[i], road, by_link])
	_expect(taken == n_links, "only %d of %d links are shorter than the road as a racer counts them" % [taken, n_links])
	var kinds := PackedStringArray()
	for k: String in by_kind:
		kinds.append("%d %s" % [by_kind[k], k])
	_summary["map"] = "%d links (%s; %d refused by the car), %d worth taking, curve within %.2f m of the points, at most %.1f %% longer" % [
			n_links, ", ".join(kinds), refused, taken, worst_off, worst_long * 100.0]
	map.free()
