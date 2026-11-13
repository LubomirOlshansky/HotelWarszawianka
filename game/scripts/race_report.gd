extends RefCounted
## Racer AI step 6a (docs/design/race-ai.md 6.1, "After the race the result card shows the rival's
## route against the player's and where the time went"): what a street race's result card says
## beyond who won. While the race runs it keeps both cars' ways (`tick`); at the end it works out
## what decided the race (`close`): the route (one car's way was shorter: a shortcut, a yard, a
## wrong turn), the standing (seconds under WALK m/s: a queue, a crash, a block), or the pace (the
## rest: who was quicker on the move), and gives the card its two lines (`lines`) and its picture
## (`Sketch`: both ways over the streets round them, the player's solid, the rival's dashed).
## Pure but for the Sketch: check_race_report.gd plays races into it without a scene.

## A point of a car's way every STEP m (and its last place at the end).
const STEP := 6.0
## Under this speed (m/s) a car stands.
const WALK := 1.0
## A cause must be worth this many seconds to be named; under it the race was even.
const NAMED := 1.0
## What decided the race.
enum Cause { EVEN, ROUTE, STILL, PACE }

var player := PackedVector2Array()
var rival := PackedVector2Array()
## Metres driven and seconds stood by each, the race's seconds, and the player's top speed (m/s).
var player_m := 0.0
var rival_m := 0.0
var player_still := 0.0
var rival_still := 0.0
var time := 0.0
var player_top := 0.0
## After `close`: who won, the cause and its seconds (how much of the gap it explains), each
## car's whole way in metres (the loser's with what it had left), the three shares of the gap
## (seconds the player lost to the rival by each, under 0 gained), and the rival's moments.
var won := false
var cause := Cause.EVEN
var cause_s := 0.0
var player_way := 0.0
var rival_way := 0.0
var route_s := 0.0
var still_s := 0.0
var pace_s := 0.0
var moments := {}
var closed := false


## A frame of the race: where each car is (map metres) and how fast (m/s).
func tick(dt: float, player_at: Vector2, player_v: float, rival_at: Vector2, rival_v: float) -> void:
	time += dt
	player_top = maxf(player_top, player_v)
	if player_v < WALK:
		player_still += dt
	if rival_v < WALK:
		rival_still += dt
	player_m += _add(player, player_at)
	rival_m += _add(rival, rival_at)


## Point `p` joins way `pts` when it is STEP m from its last; returns the metres added.
static func _add(pts: PackedVector2Array, p: Vector2) -> float:
	if pts.is_empty():
		pts.append(p)
		return 0.0
	var step := pts[pts.size() - 1].distance_to(p)
	if step < STEP:
		return 0.0
	pts.append(p)
	return step


## The race is over: the player `has_won` by `margin` s (the loser's seconds still to go), the
## loser had `left` m of its way to go, and `counts` is what the rival did ({"cuts", "yards",
## "hops", "wrong", "mistakes", "passes", "blocks"}: traffic.gd's counts).
func close(has_won: bool, margin: float, left: float, counts: Dictionary) -> void:
	closed = true
	won = has_won
	moments = counts
	left = left if left < INF else 0.0
	player_way = player_m + (0.0 if won else left)
	rival_way = rival_m + (left if won else 0.0)
	# The player's seconds over the rival's (under 0: the player won), shared out.
	var gap := -margin if won else margin
	var moving := maxf(time - player_still, 1.0)
	var pace := maxf(player_m / moving, 3.0)
	route_s = (player_way - rival_way) / pace
	still_s = player_still - rival_still
	pace_s = gap - route_s - still_s
	# The cause: the share that goes the result's way furthest.
	var way := -1.0 if won else 1.0
	cause = Cause.EVEN
	cause_s = NAMED
	for c: Array in [[Cause.ROUTE, route_s], [Cause.STILL, still_s], [Cause.PACE, pace_s]]:
		if float(c[1]) * way >= cause_s:
			cause = c[0]
			cause_s = float(c[1]) * way
	if cause == Cause.EVEN:
		cause_s = 0.0


static func _km(metres: float, comma: bool) -> String:
	var s := "%.2f" % (metres / 1000.0)
	return s.replace(".", ",") if comma else s


## The card's lines after `close`, in Polish and in English: [[pl, en], ...]: what decided the
## race, both ways' lengths, and the rival's moments (left out when there were none).
func lines(who: String) -> Array:
	var out := []
	var m := roundi(absf(player_way - rival_way) / 10.0) * 10
	var s := maxi(roundi(cause_s), 1)
	var short_pl := "skrót przez podwórko" if int(moments.get("yards", 0)) > 0 else ("jazda pod prąd" if int(moments.get("hops", 0)) > 0 else "skrót")
	var short_en := "a yard shortcut" if int(moments.get("yards", 0)) > 0 else ("a wrong-way hop" if int(moments.get("hops", 0)) > 0 else "a shortcut")
	var cut := int(moments.get("cuts", 0)) + int(moments.get("yards", 0)) + int(moments.get("hops", 0)) > 0
	match cause:
		Cause.ROUTE:
			if won:
				var lost := int(moments.get("wrong", 0)) > 0
				out.append(["Zdecydowała trasa: twoja krótsza o %d m, ok. %d s%s." % [m, s, " (rywal zabłądził)" if lost else ""],
						"The route decided it: yours was %d m shorter, about %d s%s." % [m, s, " (the rival got lost)" if lost else ""]])
			elif cut:
				out.append(["Zdecydował %s: trasa rywala krótsza o %d m, ok. %d s." % [short_pl, m, s],
						"%s decided it: the rival's route was %d m shorter, about %d s." % [short_en.substr(0, 1).to_upper() + short_en.substr(1), m, s]])
			else:
				out.append(["Zdecydowała trasa: rywal miał o %d m bliżej, ok. %d s." % [m, s],
						"The route decided it: the rival's was %d m shorter, about %d s." % [m, s]])
		Cause.STILL:
			out.append(["Zdecydowały postoje: ty %d s w miejscu, rywal %d s." % [roundi(player_still), roundi(rival_still)],
					"Standing still decided it: you %d s, the rival %d s." % [roundi(player_still), roundi(rival_still)]])
		Cause.PACE:
			if won:
				out.append(["Zdecydowało tempo: ok. %d s szybciej w ruchu." % s, "Pace decided it: about %d s quicker on the move." % s])
			else:
				out.append(["Zdecydowało tempo: rywal ok. %d s szybszy w ruchu." % s, "Pace decided it: the rival was about %d s quicker on the move." % s])
		_:
			out.append(["Równy wyścig: zdecydowały detale.", "An even race: the details decided it."])
	out.append(["Trasy: ty %s km, %s %s km." % [_km(player_way, true), who, _km(rival_way, true)],
			"Routes: you %s km, %s %s km." % [_km(player_way, false), who, _km(rival_way, false)]])
	var pl := PackedStringArray()
	var en := PackedStringArray()
	for row: Array in [["cuts", "skróty", "shortcuts"], ["yards", "podwórka", "yards"], ["hops", "pod prąd", "wrong-way hops"],
			["wrong", "złe skręty", "wrong turns"], ["mistakes", "błędy", "mistakes"], ["passes", "wyprzedzenia", "passes"], ["blocks", "blokady", "blocks"]]:
		var n := int(moments.get(row[0], 0))
		if n > 0:
			pl.append("%s %d" % [row[1], n])
			en.append("%s %d" % [row[2], n])
	if not pl.is_empty():
		out.append(["Rywal: %s." % " · ".join(pl), "The rival: %s." % " · ".join(en)])
	return out


## The lines as the card's two texts, a line each: [Polish, English].
func texts(who: String) -> Array:
	var pl := PackedStringArray()
	var en := PackedStringArray()
	for l: Array in lines(who):
		pl.append(l[0])
		en.append(l[1])
	return ["\n".join(pl), "\n".join(en)]


## The picture on the card: both ways over the streets round them, north up. The player's way is
## a solid line in `ink`, the rival's a dashed one in its own colour on top (a line and a pattern:
## colour-safe), a dot where they started and a chequered square at the finish.
class Sketch extends Control:
	const PAD := 8.0
	const DASH := 5.0
	var report
	var graph
	var finish := Vector2.INF
	var ink := Color("#fff8e8")
	var rival_colour := Color("#ff4fd8")
	var back := Color(1.0, 1.0, 1.0, 0.06)
	var street := Color(1.0, 1.0, 1.0, 0.16)
	var you := "TY"
	var them := ""
	var points := 1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	## The map's rectangle shown (both ways and the finish, with room round them), fitted to the
	## control's shape.
	func bounds() -> Rect2:
		var box := Rect2()
		var first := true
		for pts: PackedVector2Array in [report.player, report.rival, PackedVector2Array([finish] if finish != Vector2.INF else [])]:
			for p in pts:
				if first:
					box = Rect2(p, Vector2.ZERO)
					first = false
				else:
					box = box.expand(p)
		box = box.grow(maxf(box.size.x, box.size.y) * 0.08 + 20.0)
		var inner := size - Vector2.ONE * PAD * 2.0 * points
		if inner.x > 1.0 and inner.y > 1.0:
			var want := inner.x / inner.y
			if box.size.x / box.size.y < want:
				box = box.grow_individual((box.size.y * want - box.size.x) * 0.5, 0.0, (box.size.y * want - box.size.x) * 0.5, 0.0)
			else:
				box = box.grow_individual(0.0, (box.size.x / want - box.size.y) * 0.5, 0.0, (box.size.x / want - box.size.y) * 0.5)
		return box

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), back)
		if report == null or (report.player.size() < 2 and report.rival.size() < 2):
			return
		var box := bounds()
		var pad := Vector2.ONE * PAD * points
		var zoom := (size.x - pad.x * 2.0) / maxf(box.size.x, 1.0)
		var to := func(p: Vector2) -> Vector2: return pad + (p - box.position) * zoom
		if graph != null:
			# The streets round the two ways (junction to junction: a sketch, not the minimap).
			for e in graph.e_a.size():
				var a: Vector2 = graph.node_pos[graph.e_a[e]]
				var b: Vector2 = graph.node_pos[graph.e_b[e]]
				if box.has_point(a) or box.has_point(b):
					draw_line(to.call(a), to.call(b), street, maxf(1.0, points))
		var wide := 2.4 * points
		if report.player.size() >= 2:
			var line := PackedVector2Array()
			for p in report.player:
				line.append(to.call(p))
			draw_polyline(line, ink, wide, true)
		if report.rival.size() >= 2:
			var gone := 0.0
			var dash := DASH * points
			for i in report.rival.size() - 1:
				var a: Vector2 = to.call(report.rival[i])
				var b: Vector2 = to.call(report.rival[i + 1])
				var length := a.distance_to(b)
				var at := 0.0
				while at < length:
					var phase := fmod(gone + at, dash * 2.0)
					var run := minf((dash if phase < dash else dash * 2.0) - phase, length - at)
					if phase < dash:
						draw_line(a.lerp(b, at / length), a.lerp(b, (at + run) / length), rival_colour, wide)
					at += maxf(run, 0.01)
				gone += length
		var start: Vector2 = to.call(report.player[0] if not report.player.is_empty() else report.rival[0])
		draw_circle(start, 3.5 * points, ink)
		if finish != Vector2.INF:
			var f: Vector2 = to.call(finish)
			var q := 3.0 * points
			for k in 4:
				var o := Vector2((k % 2) - 1.0, (k / 2) - 1.0) * q
				draw_rect(Rect2(f + o, Vector2.ONE * q), ink if (k % 2 + k / 2) % 2 == 0 else Color("#2b2c2f"))
		# Who is who: a solid sample and a dashed one, with the names.
		var font := get_theme_default_font()
		var fs := roundi(10.0 * points)
		var y := size.y - 5.0 * points
		var x := 6.0 * points
		draw_line(Vector2(x, y - 4.0 * points), Vector2(x + 14.0 * points, y - 4.0 * points), ink, wide)
		x += 18.0 * points
		draw_string(font, Vector2(x, y), you, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, ink)
		x += font.get_string_size(you, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x + 10.0 * points
		draw_line(Vector2(x, y - 4.0 * points), Vector2(x + 5.0 * points, y - 4.0 * points), rival_colour, wide)
		draw_line(Vector2(x + 9.0 * points, y - 4.0 * points), Vector2(x + 14.0 * points, y - 4.0 * points), rival_colour, wide)
		x += 18.0 * points
		draw_string(font, Vector2(x, y), them, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, rival_colour)
