extends SceneTree
## Beer pong's difficulty calibration (F's ask 2026-11-25, docs/design/tapczan-pub.md "Difficulty"):
## plays N seeded games of the pure sim (beer_pong_sim.gd) per cell, a player bot of a given skill
## against each rival of data/tapczan.json, and prints one table: the player's win rate, the throws
## per side, the turns, the cups the player sinks, how often the winning ball was a bounce shot (two
## cups) and how often a game ran into Pani Gienia's late switch. A study tool, not a check: it
## always exits 0 and joins nothing (check_tapczan.gd holds the bands).
##
## The player bots aim exactly at a random cup of the rival's rack, then scatter (lateral, power)
## by their level, plus the sim's own drink sway. "+1 drink" / "+3 drinks" start the game with that
## many drinks already in the hand (the game today starts every game at 0; this is the sway's
## sensitivity, e.g. for a later "pints before pong" rule).
##
##   godot --headless --path game --script res://tools/pong_calibrate.gd -- [--n=1000]
##       [--set=sommelier:0.8,office:0.4,first:0.3/0.6]   # try rival skills without editing the data
##       [--sweep]   # decent sober bot's win rate against a plain rival of skill 0.0..1.0
## About a second per 1000 games.

const Sim := preload("res://scripts/beer_pong_sim.gd")
const Room := preload("res://scripts/tapczan_room.gd")

## The player bots: name, scatter (lateral, power), drinks at the start.
const BOTS := [
	["poor", Vector2(0.20, 0.10), 0],
	["decent", Vector2(0.12, 0.06), 0],
	["good", Vector2(0.07, 0.035), 0],
	["decent +1 drink", Vector2(0.12, 0.06), 1],
	["decent +3 drinks", Vector2(0.12, 0.06), 3],
]
const MAX_THROWS := 600


func _initialize() -> void:
	var n := 1000
	var over := {}
	var sweep := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.substr(4))
		elif a.begins_with("--set="):
			for part: String in a.substr(6).split(","):
				var kv := part.split(":")
				var sk := kv[1].split("/")
				over[kv[0]] = Vector2(float(sk[0]), float(sk[1]) if sk.size() > 1 else -1.0)
		elif a == "--sweep":
			sweep = true
		elif a == "--rates":
			_rates(n)
			quit(0)
			return
	if sweep:
		_sweep(n)
	else:
		_table(n, over)
	quit(0)


func _table(n: int, over: Dictionary) -> void:
	print("pong_calibrate: %d games per cell, seeds 1..%d" % [n, n])
	print("| player | rival (skill/late) | player wins | throws/side (player, rival) | turns | player cups | won on a bounce | late switch |")
	print("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |")
	for bot: Array in BOTS:
		for id: String in Room.RIVALS:
			var r := Room.rival(id)
			var sk := Vector2(float(r.get("skill", 0.5)), float(r.get("late_skill", -1.0)))
			if over.has(id):
				sk = over[id]
			var st := _cell(n, bot[1], int(bot[2]), sk)
			var tag := "%.2f" % sk.x + ("/%.2f" % sk.y if sk.y >= 0.0 else "")
			print("| %s | %s %s | %d%% | %.1f, %.1f | %.1f | %.1f | %d%% | %s |" % [bot[0], id, tag,
					roundi(st["win"] * 100.0), st["pt"], st["rt"], st["turns"], st["cups"],
					roundi(st["bounce"] * 100.0), ("%d%%" % roundi(st["late"] * 100.0)) if sk.y >= 0.0 else "-"])


## The decent sober bot against a plain rival (no late switch) at skills 0.0..1.0.
func _sweep(n: int) -> void:
	var line := "pong_calibrate sweep (decent, %d games):" % n
	for i in 11:
		var k := i * 0.1
		line += " %.1f=%d%%" % [k, roundi(_cell(n, Vector2(0.12, 0.06), 0, Vector2(k, -1.0))["win"] * 100.0)]
	print(line)


## One throw's odds at a full rack (6) and a re-racked one (3): the share of throws that take a cup
## and of those that end on a rim, for the bots' scatters and the rivals' skills 0.3..0.9.
func _rates(n: int) -> void:
	var rows: Array = []
	for bot: Array in BOTS.slice(0, 3):
		rows.append([bot[0], bot[1]])
	for k: float in [0.3, 0.5, 0.6, 0.7, 0.75, 0.8, 0.9]:
		rows.append(["rival %.2f" % k, Sim.SCATTER_LO.lerp(Sim.SCATTER_HI, k)])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for row: Array in rows:
		var line := "pong_calibrate rates %s (scatter %.3f, %.3f):" % [row[0], row[1].x, row[1].y]
		for size: int in [6, 3]:
			var cups := Sim.rack(size)
			var hit := 0
			var rim := 0
			for i in n:
				var a := Sim.aim_at(cups[rng.randi() % cups.size()])
				var r := Sim.fly(Sim.launch(a.x + rng.randfn(0.0, row[1].x), a.y + rng.randfn(0.0, row[1].y)), cups, rng.randf())
				if str(r["result"]) in ["cup", "rim_in", "bounce"]:
					hit += 1
				if r["rim"]:
					rim += 1
			line += " rack %d: in %d%%, rim %d%%;" % [size, roundi(100.0 * hit / n), roundi(100.0 * rim / n)]
		print(line)


## `n` games of the bot (`scatter`, `start_drinks`) against a rival of `sk` (skill, late skill).
func _cell(n: int, scatter: Vector2, start_drinks: int, sk: Vector2) -> Dictionary:
	var won := 0
	var pt := 0
	var rt := 0
	var turns := 0
	var cups := 0
	var bounce_win := 0
	var late := 0
	for g in n:
		var s := Sim.new(g + 1)
		s.skill = sk.x
		s.late_skill = sk.y
		s.drinks = start_drinks
		var throws := 0
		var turn_n := 1
		var last := {}
		while s.winner < 0 and throws < MAX_THROWS:
			throws += 1
			if s.turn == 0:
				pt += 1
				var row: Array = s.cups[1]
				var a := Sim.aim_at(row[s.rng.randi() % row.size()])
				last = s.throw_player(a.x + s.rng.randfn(0.0, scatter.x), a.y + s.rng.randfn(0.0, scatter.y), throws * 0.7)
			else:
				rt += 1
				last = s.throw_rival()
			if "turn" in last.get("events", []):
				turn_n += 1
		turns += turn_n
		cups += Sim.CUPS - s.cups[1].size()
		if s.winner == 0:
			won += 1
		if s.winner >= 0 and str(last.get("result", "")) == "bounce":
			bounce_win += 1
		if s.late:
			late += 1
	return {"win": float(won) / n, "pt": float(pt) / n, "rt": float(rt) / n, "turns": float(turns) / n,
			"cups": float(cups) / n, "bounce": float(bounce_win) / n, "late": float(late) / n}
