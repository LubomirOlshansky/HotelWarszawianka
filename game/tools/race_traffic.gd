extends SceneTree
## Measures what the town's traffic costs a racer, street by street, for the planner's traffic
## delay (traffic.gd RACE_STUCK*, `race_delay`; docs/design/race-ai.md 5). Three rivals (the
## slowest, a middle one, the fastest of the ladder) drive ten courses through the centre on the
## race bench (tools/race_bench.gd: the real traffic and the game's own race code, headless, no
## city), each once on clear roads and then at Low, Normal and Busy traffic with `seeds` draws of
## the town's cars, every race on the shortest way in metres (`no_plan`, so the streets are the
## same with and without traffic and the planner under fit does not pick them). A race that left
## the clear run's streets (a street boxed in, a turn back) gives no samples. Each street of each
## race is one line of the CSV: the street (class, lanes, an oncoming road, length, lights), the
## racer's own speed there, its seconds on clear roads and in that traffic.
##   godot --headless --path game --script res://tools/race_traffic.gd -- --out=FILE [--part=K/N] [--seeds=3]
## `--part=K/N` runs every Nth rival-course from the Kth (tools/race_traffic.sh runs the parts side
## by side and then the fit, tools/race_traffic.py). Not a check: it prints what it ran, exit 0;
## exit 1 without the map (map/centrum.json).

const RaceBench := preload("res://tools/race_bench.gd")
const Settings := preload("res://scripts/settings.gd")
const Traffic := preload("res://scripts/traffic.gd")

## The courses: [name, the start (a point, or a finish's name to start at), the finish, the
## points to drive by]. The prototype race's three ways and seven more across the centre:
## one-lane streets in Powiśle, the wide ones round the Palace, two crossings of the centre.
var _courses: Array = [
	["tamka", RaceBench.STARTS["tamka"], "Plac Trzech Krzyży", []],
	["leszcz", RaceBench.STARTS["leszczynska"], "Plac Trzech Krzyży", []],
	["leszcz-dobra", RaceBench.STARTS["leszczynska"], "Plac Trzech Krzyży", RaceBench.ROUTES["dobra"]],
	["leszcz-solec", RaceBench.STARTS["leszczynska"], "Plac Trzech Krzyży", RaceBench.ROUTES["solec"]],
	["krzyzy-onz", "Plac Trzech Krzyży", "Rondo ONZ", []],
	["onz-palm", "Rondo ONZ", "Rondo de Gaulle'a (the Palm)", []],
	["powisle-pkin", "Dworzec Powiśle", "Pałac Kultury i Nauki", []],
	["varso-kopernik", "Varso Tower", "Centrum Nauki Kopernik", []],
	["dmowski-krzyzy", "Rondo Dmowskiego", "Plac Trzech Krzyży", []],
	["kopernik-onz", "Centrum Nauki Kopernik", "Rondo ONZ", []],
]
const RIVALS := ["Pani Halina", "Bulwar Bartek", "Mordor Mike"]
## The traffic levels driven (Settings.TRAFFIC: Low, Normal, Busy).
const LEVELS := [1, 2, 3]
const HEADER := "course,rival,level,density,seed,k,edge,cls,lanes,twoway,len,lights,v,clear_s,traffic_s,finished"


func _initialize() -> void:
	_run()


func _run() -> void:
	# The bench's nodes join the tree a frame after the script starts.
	await process_frame
	var part := 0
	var parts := 1
	var seeds := 3
	var out_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):
			part = int(a.get_slice("=", 1).get_slice("/", 0))
			parts = maxi(int(a.get_slice("/", 1)), 1)
		elif a.begins_with("--seeds="):
			seeds = maxi(int(a.get_slice("=", 1)), 1)
		elif a.begins_with("--out="):
			out_path = a.get_slice("=", 1)
	if out_path == "":
		print("race_traffic: --out=FILE is missing")
		quit(2)
		return
	var bench := RaceBench.new()
	if not bench.open(root):
		print("race_traffic: %s" % bench.error)
		quit(1)
		return
	var g := bench.graph
	var lines := PackedStringArray([HEADER])
	var index := 0
	for c: Array in _courses:
		var start: Vector2 = c[1] if c[1] is Vector2 else bench.finish(String(c[1]))["at"]
		for rival: String in RIVALS:
			index += 1
			if index % parts != part % parts:
				continue
			var spec := {"rival": rival, "tuning": "ladder", "start": start, "start_name": c[0], "finish": c[2],
					"situation": "clear", "player": "none", "no_plan": true}
			if not (c[3] as Array).is_empty():
				spec["via"] = c[3]
				spec["via_name"] = "v"
			var base: Dictionary = bench.race(spec)
			if base.has("error") or not base["finished"]:
				print("race_traffic: %s, %s skipped (%s)" % [c[0], rival, base.get("error", "not finished on clear roads")])
				continue
			var clear: Array = base["edges"]
			print("race_traffic: %s, %s: clear roads %.1f s, %d streets, %.0f m" % [c[0], rival, base["time"], clear.size(), base["driven_m"]])
			for level: int in LEVELS:
				for draw in range(1, seeds + 1):
					var busy := spec.duplicate()
					busy["situation"] = "heavy"
					busy["traffic"] = level
					busy["seed"] = draw
					var r: Dictionary = bench.race(busy)
					var driven: Array = r.get("edges", [])
					var same := driven.size() <= clear.size()
					for k in driven.size():
						if k >= clear.size() or int(driven[k]) != int(clear[k]):
							same = false
							break
					print("   %s, draw %d: %.1f s%s%s" % [Settings.TRAFFIC_NAMES[level], draw, r["time"], "" if r["finished"] else " (not finished)", "" if same else " (left the clear run's streets: no samples)"])
					if not same:
						continue
					# The street an unfinished race stopped on is not a whole sample.
					var whole: int = driven.size() if r["finished"] else driven.size() - 1
					for k in whole:
						var e := int(driven[k])
						lines.append("%s,%s,%d,%.3f,%d,%d,%d,%d,%d,%d,%.1f,%d,%.2f,%.2f,%.2f,%d" % [c[0], rival, level, float(Settings.TRAFFIC[level]), draw, k, e,
								g.e_class[e], g.e_lanes[e], 1 if g.e_reverse[e] >= 0 else 0, g.e_s1[e] - g.e_s0[e], g.e_stops[e].size() / 3,
								minf(RaceBench.PLAYER_TOP, Traffic.RACE_CLASS_TOP[g.e_class[e]]) * float(base["share"]),
								float(base["edge_s"][k]), float(r["edge_s"][k]), 1 if r["finished"] else 0])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		print("race_traffic: cannot write %s" % out_path)
		bench.close()
		quit(1)
		return
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("race_traffic: %d street samples in %s" % [lines.size() - 1, out_path])
	bench.close()
	quit(0)
