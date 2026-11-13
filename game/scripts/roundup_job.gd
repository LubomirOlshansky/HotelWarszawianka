extends "res://scripts/activity.gd"
## Loop jobs-2 (docs/design/parodies.md 5.3, DEMO 6.3): the Leżak round-up, a night side job. A few
## of storefronts.gd's empty parking zones are **Leżak depots** (a teal ring and a teal square on
## the minimap at night: one per DEPOT_SPACING m of the hero districts, the egg's standing zone
## left alone). Pull into one at night with nothing else on: the card ZBIERZ 10 LEŻAKÓW and the
## `lezak` `start` line. GO: the 10 nearest lying Leżaks within 600 m get violet pins on the
## minimap. Drive within 4 m of one under 15 km/h: the clatter and +1 in the boot, which holds 5;
## back at the depot (in its ring, slow) they are unloaded; then the other 5. Pay 8 zł a Leżak,
## +40 zł if all 10 are back within 6 minutes, +40 respect, the `done` line. ✕ gives up (the ones
## unloaded are paid, no bonus). Collected Leżaks are gone from the pavement until the next
## morning (storefronts.gd `restore_collected`, by day). One activity at a time, as every job.
##
## It is an activity of the kit (activity.gd): the kit has its cards, the ✕, the ring and "busy",
## and the director (activities.gd) says when it may offer itself and answers for it (`job_on`,
## the target, the M and K keys) since jobs.gd joined the kit too; jobs.gd keeps `round_busy()`
## for its own minimap squares and its pointer to the next stand. Cost: idle,
## a 2 Hz look at the depots (a handful of distances); while it runs, ≤ 10 distances a frame and
## the HUD's status. Nothing new is drawn but the depots' dashed rings (one mesh each, shown at
## night only while no job runs) and the shared beacon: +0-1 draw calls near a depot.

const MapIcons := preload("res://scripts/map_icons.gd")
const Missions := preload("res://scripts/missions.gd")

## Teal (the passengers' and goods' job colour, as the słoiki); the pins in Leżak's violet.
const COLOUR := Color("#4fd8c4")
const PIN_COLOUR := Color("#8e44d9")
const FAIL_COLOUR := Color("#e2574c")
const DEPOT_SPACING := 1200.0
const DEPOT_R := 7.0
const DEPOT_SPEED := 8.0
## Unloading at the depot is a quest stop (stop_assist.gd): its ring and its "stopped".
const UNLOAD_R := StopAssist.RING
const UNLOAD_SPEED := StopAssist.STOP_SPEED
const WANT := 10
## Fewer than this within reach: no job at that depot tonight.
const AT_LEAST := 4
const REACH := 600.0
const PICK_R := 4.0
const PICK_KMH := 15.0
const BOOT := 5
const PER := 8
const BONUS := 40
const RESPECT := 40
const LIMIT := 360.0
const LOOK_EVERY := 0.5
const RESULT_LIFE := 12.0
## The offer's card goes after this long (s) with no answer.
const OFFER_LIFE := 12.0

## The run's stages (the kit's `phase` is IDLE or RUN here; this activity never rings).
enum Stage { NONE, OFFER, COLLECT, RESULT }

var missions: Node
var tod: Node
## jobs.gd (its _free, _night, _marker and flying).
var jobs: Node
## storefronts.gd: the zones and the Leżaks.
var store: Node
var stage := Stage.NONE
## --roundup: the offer at the depot nearest the car, day or night.
var force := false
## The depots: {at: Vector3, zone: int, marker: Node3D, cool: bool}.
var depots: Array[Dictionary] = []
## The job: its depot, the Leżaks to round up (storefronts indices), those in the boot, unloaded.
var depot := -1
var targets: Array[int] = []
var boot := 0
var unloaded := 0
var secs := 0.0
## Round-ups finished (the check, the log).
var done := 0
## What the last finish paid: {zl, bonus, respect, all}.
var last_pay := {}

var _look_t := 0.0
var _shown := false
var _was_night := false
## The ✕'s words for this run ([Polish, English]): `drop` writes them, `_quit_words` gives them.
var _quit: Array = []


## The pay for `n` Leżaks unloaded of `want`, in `secs` (static: check_side_jobs.gd runs it): 8 zł
## each, +40 zł when all came back within LIMIT s, +40 respect when all came back.
static func pay(n: int, want: int, secs: float) -> Dictionary:
	var all := n >= want and want > 0
	var bonus := BONUS if all and secs <= LIMIT else 0
	return {"zl": n * PER + bonus, "bonus": bonus, "respect": RESPECT if all else 0, "all": all}


## A Leżak goes into the boot: within PICK_R m, under PICK_KMH, a free place in the boot.
static func can_pick(d: float, kmh: float, in_boot: int) -> bool:
	return d <= PICK_R and kmh < PICK_KMH and in_boot < BOOT


## The depots: zones at least `spacing` m apart, in the zones' order, the standing one left out.
static func pick_depots(zone_list: Array, spacing: float) -> Array[int]:
	var out: Array[int] = []
	for i in zone_list.size():
		var z: Dictionary = zone_list[i]
		if bool(z.get("standing", false)):
			continue
		var p := Vector2(z["at"].x, z["at"].z)
		var far := true
		for j in out:
			var q: Dictionary = zone_list[j]
			if Vector2(q["at"].x, q["at"].z).distance_to(p) < spacing:
				far = false
				break
		if far:
			out.append(i)
	return out


func setup(world: Node3D) -> void:
	tag = "roundup"
	colour = COLOUR
	dark = Color("#2f6fb5")
	is_job = true
	cards_low = true
	super.setup(world)
	if store == null:
		return
	for i in pick_depots(store.zones, DEPOT_SPACING):
		var at: Vector3 = store.zones[i]["at"]
		var marker: Node3D = jobs._marker(COLOUR, DEPOT_R - 1.0)
		world.add_child(marker)
		marker.global_position = at
		marker.visible = false
		depots.append({"at": at, "zone": i, "marker": marker, "cool": false})
	var where := PackedStringArray()
	for d in depots:
		where.append("%d,%d" % [roundi(d["at"].x), roundi(d["at"].z)])
	print("roundup: %d Leżak depots (%s)" % [depots.size(), " ".join(where)])


func has_target() -> bool:
	return phase == Phase.RUN and stage == Stage.COLLECT


## The nearest Leżak still out, or the depot when the boot is full or none are left.
func target_position() -> Vector3:
	var i := _next()
	if i >= 0:
		return store.scooters[i]["at"]
	return depots[depot]["at"]


## Where the car should stop now (stop_assist.gd): the depot, once the way leads back to unload
## (the Leżaks themselves are a slow drive-by, not a stop).
func stop_spot() -> Vector3:
	if not has_target() or boot <= 0 or _next() >= 0:
		return Vector3.INF
	return depots[depot]["at"]


func target_colour() -> Color:
	return PIN_COLOUR if _next() >= 0 else COLOUR


func primary() -> bool:
	if phase == Phase.RUN and (stage == Stage.OFFER or stage == Stage.RESULT):
		card_pressed(0)
		return true
	return false


func secondary() -> bool:
	if phase == Phase.RUN and stage == Stage.OFFER:
		card_pressed(1)
		return true
	return false


func _night() -> bool:
	return tod != null and tod.mode == 2


func _process(dt: float) -> void:
	super._process(dt)
	# The offer goes when the car drives off (the kit knows only a card's life): as NOT NOW, or
	# as GO! for the autopilot. After the kit's frame, so nothing else of this frame runs once
	# it is down.
	if phase == Phase.RUN and stage == Stage.OFFER and _flat(car.global_position, depots[depot]["at"]) > DEPOT_R + 7.0:
		card_pressed(0 if autopilot else 1)


## Twice a second while idle: the depots' rings by night, the morning's Leżaks, a pull-in. (No
## call: the kit's call clock is not used.)
func _idle_tick(dt: float) -> void:
	if depots.is_empty():
		return
	_look_t -= dt
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		_look()


func _run_tick(dt: float) -> void:
	if stage == Stage.COLLECT:
		_collect_tick(dt)


## Twice a second while idle: the depots' rings by night, the morning's Leżaks, a pull-in.
func _look() -> void:
	var night := _night()
	if night != _was_night:
		_was_night = night
		if not night and store != null:
			var n: int = store.restore_collected()
			if n > 0 and log_on:
				print("roundup: morning: %d Leżaks lie about again" % n)
	var open: bool = (night or force) and bool(free_now.call())
	_show_depots(open)
	if not open:
		return
	var p := car.global_position
	var slow: bool = car.vel.length() < DEPOT_SPEED
	for i in depots.size():
		var dp := depots[i]
		var d := _flat(p, dp["at"])
		if dp["cool"]:
			dp["cool"] = d < 25.0
		elif d < DEPOT_R and slow:
			offer(i)
			return


func _show_depots(on: bool) -> void:
	if on == _shown:
		return
	_shown = on
	for dp in depots:
		(dp["marker"] as Node3D).visible = on
	jobs.depots_shown(on)


## The minimap squares of the depots (jobs.gd adds them to its own while nothing runs).
func depot_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for dp in depots:
		pts.append(Vector2(dp["at"].x, dp["at"].z))
	return pts


## The card at depot i (--roundup too). False if too few Leżaks lie within reach.
func offer(i: int) -> bool:
	if phase != Phase.IDLE:
		return false
	var at: Vector3 = depots[i]["at"]
	var near: Array[int] = store.lying_near(Vector2(at.x, at.z), REACH, WANT)
	if near.size() < AT_LEAST:
		depots[i]["cool"] = true
		hud.toast("Tu już posprzątane. Na dziś", "Already tidy round here. For tonight")
		if log_on:
			print("roundup: depot %d: only %d Leżaks within %d m" % [i, near.size(), roundi(REACH)])
		return false
	depot = i
	targets = near
	boot = 0
	unloaded = 0
	start()
	return true


## The run begins with the offer: the card at the depot (a card of the run, so its buttons come
## here only).
func _begin() -> void:
	if depot < 0 or targets.is_empty():
		finish()  # started with nothing to collect (nobody does): over at once
		return
	stage = Stage.OFFER
	_show_depots(false)
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()
	var at: Vector3 = depots[depot]["at"]
	var n := targets.size()
	show_card(["ZBIERZ %d LEŻAKÓW" % n, "Round up %d Leżaks" % n],
			["Bagażnik mieści %d. %d zł za sztukę, +%d zł za komplet w 6 min." % [BOOT, PER, BONUS],
			"The boot holds %d. %d zł each, +%d zł for all of them within 6 min." % [BOOT, PER, BONUS]],
			PackedStringArray(["GO!", "NOT NOW"]), OFFER_LIFE)
	if dialogue != null:
		dialogue.say(func() -> Vector3: return at, "Leżak", "lezak", "start", 4.5, PIN_COLOUR, 1.6, true)
	print("roundup: offer at depot %d (%d,%d): %d Leżaks within %d m" % [depot, roundi(at.x), roundi(at.z), n, roundi(REACH)])


func _card_pressed(index: int) -> void:
	match stage:
		Stage.OFFER:
			if index == 0:
				_go()
			else:
				finish()
		Stage.RESULT:
			finish()


## A card nobody answered: the offer as NOT NOW, the result as OK.
func _card_expired() -> void:
	finish()


func _go() -> void:
	stage = Stage.COLLECT
	secs = 0.0
	_pins()
	_beacon.recolour(COLOUR)
	_beacon.waving = false
	hud.toast("Zbieraj Leżaki: podjedź powoli", "Collect the Leżaks: drive up slowly")
	print("roundup: go: %d Leżaks, the boot holds %d" % [targets.size(), BOOT])


func _collect_tick(dt: float) -> void:
	secs += dt
	var p := car.global_position
	var kmh: float = car.vel.length() * 3.6
	var flying: bool = jobs.flying
	if not flying:
		for k in range(targets.size() - 1, -1, -1):
			var i := targets[k]
			if can_pick(_flat(p, store.scooters[i]["at"]), kmh, boot):
				store.collect(i)
				targets.remove_at(k)
				boot += 1
				hud.toast("+1 LEŻAK · BAGAŻNIK %d/%d" % [boot, BOOT], "+1 Leżak in the boot (%d of %d)" % [boot, BOOT])
				print("roundup: picked up Leżak %d (boot %d/%d, %d left out) at %.0f s" % [i, boot, BOOT, targets.size(), secs])
				_pins()
				break
	var at: Vector3 = depots[depot]["at"]
	var dd := _flat(p, at)
	if boot > 0 and dd < UNLOAD_R and car.vel.length() < UNLOAD_SPEED and not flying:
		unloaded += boot
		print("roundup: unloaded %d at the depot (%d back) at %.0f s" % [boot, unloaded, secs])
		hud.toast("WYŁADOWANO %d · RAZEM %d/%d" % [boot, unloaded, unloaded + targets.size()],
				"Unloaded %d · %d of %d back" % [boot, unloaded, unloaded + targets.size()])
		boot = 0
		if targets.is_empty():
			_result()
			return
	var back := boot >= BOOT or targets.is_empty()
	if back:
		_beacon.place(at, DEPOT_R - 0.5, true, false)
	else:
		_beacon.visible = false
	var want := unloaded + boot + targets.size()
	var left := LIMIT - secs
	var clk := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var hint := ["Podjedź powoli do fioletowej pinezki", "Drive up slowly to a violet pin"]
	var dist := dd
	if back:
		hint = ["Bagażnik pełny: wracaj do strefy", "The boot is full: back to the zone"] if boot >= BOOT \
				else ["Wracaj do strefy i wyładuj", "Back to the zone to unload"]
		if dd < DEPOT_R:
			hint = ["Stań w strefie", "Stop in the zone"]
	else:
		var i := _next()
		dist = _flat(p, store.scooters[i]["at"])
		if dist < PICK_R + 6.0 and kmh >= PICK_KMH:
			hint = ["Wolniej! Poniżej 15 km/h", "Slower! Under 15 km/h"]
	if flying:
		hint = ["Wyląduj: Leżaki jadą w bagażniku", "Land: the Leżaks ride in the boot"]
	status("LEŻAKI %d/%d · BAGAŻNIK %d/%d" % [unloaded, want, boot, BOOT], clk, "%d m" % roundi(dist), hint,
			clampf(secs / LIMIT, 0.0, 1.0), COLOUR if left > 0.0 else FAIL_COLOUR)


## The nearest Leżak still out, while the boot has room (-1: none, or the boot is full).
func _next() -> int:
	if boot >= BOOT or targets.is_empty() or store == null:
		return -1
	var p := car.global_position
	var best := -1
	var bd := INF
	for i in targets:
		var d := _flat(p, store.scooters[i]["at"])
		if d < bd:
			bd = d
			best = i
	return best


## The violet pins (and the depot) on the minimap.
func _pins() -> void:
	var pts := PackedVector2Array()
	var colours := PackedColorArray()
	var shapes := PackedInt32Array()
	for i in targets:
		var a: Vector3 = store.scooters[i]["at"]
		pts.append(Vector2(a.x, a.z))
		colours.append(PIN_COLOUR)
		shapes.append(MapIcons.POI_SCOOTER)
	var at: Vector3 = depots[depot]["at"]
	pts.append(Vector2(at.x, at.z))
	colours.append(COLOUR)
	shapes.append(MapIcons.POI_DEPOT)
	hud.set_minimap_pois(pts, colours, shapes)


func _result() -> void:
	stage = Stage.RESULT
	hide_status()
	_beacon.visible = false
	var want := unloaded
	var r := pay(unloaded, want, secs)
	last_pay = r
	wallet.pay(int(r["zl"]), int(r["respect"]), "roundup")
	done += 1
	var l: Array = dialogue.line("lezak", "done", true) if dialogue != null else []
	var quote := "„%s”\n" % l[0] if not l.is_empty() else ""
	var quote_en := "\"%s\"\n" % l[1] if not l.is_empty() else ""
	var mm := "%d:%02d" % [int(secs) / 60, int(secs) % 60]
	show_card(["ZEBRANE · %d LEŻAKÓW · +%d zł" % [unloaded, int(r["zl"])], "Rounded up · %d Leżaks · +%d zł" % [unloaded, int(r["zl"])]],
			["%s%d × %d zł%s, +%d szacunku · czas %s" % [quote, unloaded, PER,
			(" + %d zł premii" % int(r["bonus"])) if int(r["bonus"]) > 0 else "", int(r["respect"]), mm],
			"%s%d × %d zł%s, +%d respect · time %s" % [quote_en, unloaded, PER,
			(" + %d zł bonus" % int(r["bonus"])) if int(r["bonus"]) > 0 else "", int(r["respect"]), mm]],
			PackedStringArray(["OK"]), RESULT_LIFE)
	_pins_off()
	print("roundup: done: %d Leżaks back in %.0f s: +%d zł (%d × %d%s), +%d respect (wallet %d zł)" % [unloaded, secs,
			int(r["zl"]), unloaded, PER, (" + %d bonus" % int(r["bonus"])) if int(r["bonus"]) > 0 else "", int(r["respect"]), wallet.zl])


## ✕: the ones unloaded are paid (no bonus, no respect); the ones in the boot go back out.
func drop(by_player: bool) -> void:
	var r := pay(unloaded, unloaded + boot + targets.size(), INF)
	if int(r["zl"]) > 0:
		wallet.pay(int(r["zl"]), 0, "roundup")
	_quit = ["Koniec zbierania · +%d zł" % int(r["zl"]), "Round-up given up · +%d zł" % int(r["zl"])]
	print("roundup: given up with %d back, %d in the boot: +%d zł" % [unloaded, boot, int(r["zl"])])
	super.drop(by_player)


func _quit_words() -> Array:
	return _quit


func _pins_off() -> void:
	hud.set_minimap_pois(PackedVector2Array(), PackedColorArray())


## Back to idle (the old `_release`): the depot offers again once the car has left it (25 m).
func _ended() -> void:
	if depot >= 0 and depot < depots.size():
		depots[depot]["cool"] = true
	stage = Stage.NONE
	missions.paused = false
	missions.close()
	_pins_off()
	targets = []
	boot = 0
	# jobs.gd shows its places again (and the depots with them) at its next look.
	jobs.places_dirty()


## --roundup: the car in the ring of the depot nearest it, the card up.
func start_at_nearest() -> bool:
	if depots.is_empty():
		return false
	var p := car.global_position
	var best := 0
	for i in depots.size():
		if _flat(p, depots[i]["at"]) < _flat(p, depots[best]["at"]):
			best = i
	var at: Vector3 = depots[best]["at"]
	car.global_position = at + Vector3(0, 0.1, 0)
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	return offer(best)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
