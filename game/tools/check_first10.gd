extends SceneTree
## Loop 3h slice 4: the guided first 10 minutes (first10.gd), without the map. Checks that:
## - the beats are 6.2's ten in order, each window holds its 6.2 time and the windows follow on;
## - `guide_due` only on a fresh save (a job, złoty, a rung or a finished guide: never);
## - three players played on a synthetic clock through `decide` and `met` (the director's rules)
##   with a toy city (a delivery takes 75 s, a race 60 s, a rescue 90 s, ...): an ordinary player
##   (touches at once, orders at 0:35) gets every beat inside its window, the stand's arrow and the
##   race fired, the order met; a wanderer (never touches, never orders, says no to Halina) still
##   gets the finger at 4 s, the arrow at 10 s, Halina at RACE_LATEST, the trap armed at
##   TRAP_LATEST, the call at RESCUE_LATEST, the helicopter at HELI_LATEST, the tape and Powiśle
##   arrows, no garage without earnings and the guide's end at GUIDE_END; a player busy with a job
##   from 3:40 to 5:30 gets the call only after it (beats wait); a player on one long Podwózka
##   ride (4.5 minutes, taken after the tape's beat and before the hold for Powiśle) gets the
##   Powiśle line at POWISLE_LATEST, over the ride and inside its window (without that rule it came at the ride's end, late), and behind any other job it
##   still waits; the replay's scripted order fires
##   at ORDER_AT; a helicopter-only call unlocks the helicopter at once; `judge` flags a late, a
##   missing and an early-fired beat;
## - the first race's driver (the racer AI rebuild, step 2: rivals.gd `effort_of` and `pace_tick` on
##   ladder.gd's gentle day; the rubber band `first_speed` is gone): the effort follows the time gap
##   alone and stays between EFFORT_EASE and EFFORT_PUSH, a pushing rival makes more mistakes and
##   never passes the car's top, and in a 1-D race of 800 m her time moves at most 12 % whatever
##   the player does (nobody, 22 to 108 km/h, a stop of a minute, never moving), she holds her own
##   pace to the line, a faster player wins and one at town pace loses; PT-11: she waits at the
##   line for a player who sits still after START! (`first_start_step`: wait, the GO nudge,
##   release at FIRST_HOLD), and the stall nudge mid-race (`first_stall_due`) skips red-light
##   stops, the last stretch and comes at most FIRST_STALLS times;
## - PT-30: the Powiśle arrow's spot comes from the real districts data (it read "at" off an index);
## - the words (the director's, Halina's, the end card's) in Polish and English, each line at most
##   70 characters (the card's at most 100), the repo's name as README has it.
##   godot --headless --path game --script res://tools/check_first10.gd

const First10 := preload("res://scripts/first10.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Districts := preload("res://scripts/districts.gd")
const Traffic := preload("res://scripts/traffic.gd")
const STEP := 0.2

var _problems := 0
var _summary: Array[String] = []


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_data()
	_due()
	_ordinary()
	_wanderer()
	_busy()
	_rider()
	_long_ride()
	_quick()
	_scripted()
	_judge()
	_effort()
	_words()
	_powisle()
	if _problems == 0:
		print("first10: OK (%s)" % ", ".join(_summary))
		quit(0)
	else:
		print("check_first10: %d problem(s)" % _problems)
		quit(1)


func _data() -> void:
	var want := ["finger", "stand", "order", "race", "trap", "rescue", "heli", "tape", "powisle", "garage"]
	_expect(First10.BEATS == want, "the beats: %s" % [First10.BEATS])
	# DEMO.md 6.2's times (the helicopter comes with the rescue, about a minute after the call).
	var times := {"finger": 5.0, "stand": 15.0, "order": 30.0, "race": 90.0, "trap": 180.0, "rescue": 240.0,
			"heli": 300.0, "tape": 360.0, "powisle": 480.0, "garage": 600.0}
	var last := 0.0
	for id: String in First10.BEATS:
		var w: Vector2 = First10.WINDOWS[id]
		_expect(w.x <= times[id] and times[id] <= w.y, "%s's window %s holds 6.2's %.0f s" % [id, w, times[id]])
		_expect(w.x >= last - 120.0 and w.x < w.y, "%s's window %s follows on" % [id, w])
		last = w.x
	_summary.append("10 beats")


func _fresh() -> Wallet:
	var w := Wallet.new()
	w.persistent = false
	return w


func _due() -> void:
	var w := _fresh()
	_expect(First10.guide_due(w), "a fresh save gets the guide")
	w.intro["finger"] = 20261031
	_expect(First10.guide_due(w), "a save with only the finger seen gets the guide again")
	w.intro["done"] = 20261031
	_expect(not First10.guide_due(w), "a finished guide never comes back")
	w.intro.clear()
	w.jobs["kebab"] = 1
	_expect(not First10.guide_due(w), "a job done: no guide")
	w.jobs.clear()
	w.jobs["race"] = 1
	w.zl = 60
	_expect(not First10.guide_due(w), "złoty in hand: no guide")
	w.zl = 0
	w.jobs.clear()
	w.ladder["halina"] = 20261031
	_expect(not First10.guide_due(w), "a rung beaten: no guide")
	_expect(not First10.guide_due(null), "no wallet: no guide")
	w.free()
	_summary.append("fresh saves only")


## A toy city for `decide` and `met`: the player's plan and how long things take.
class Toy:
	var t := 0.0
	var input_at := INF
	var order_at := INF       # pulls into the stand (or the director's scripted order)
	var deliver_s := 75.0
	var says_no := false      # declines Halina
	var job_from := INF       # an extra job of the player's own
	var job_to := INF
	var tape_after := 50.0    # after the tape's arrow, the tape is played (INF: never)
	var scripted := false
	var heli_call_at := INF
	var rescue_ok := true
	var rider := false        # takes every Podwózka request (rides.gd: the first at 120 s, then a gap)
	var ride_s := 150.0
	var ride_gap := 90.0
	var honour_hold := true   # the rides honour the guide's hold (false: as before the hold)
	var tell_riding := true   # the director knows a ride is the only thing on (false: as before POWISLE_LATEST)
	var held := false         # set by _play from First10.due (first10.gd `_hold_offers`)
	# the state
	var next_ride := 120.0
	var ride_until := -1.0
	var rides_taken := 0
	var ordered := false
	var delivered_t := -1.0
	var busy_until := -1.0
	var calling_until := -1.0
	var raced := false
	var race_end := INF
	var trap := false
	var rang := false
	var rang_at := INF
	var rescued := false
	var rescue_end := INF
	var tape := false
	var tape_at := INF
	var powisle := false
	var garage := false
	var garage_at := INF
	var earned := false

	func facts() -> Dictionary:
		var other := t < busy_until or (t >= job_from and t < job_to) or t < calling_until
		var busy := other or t < ride_until
		return {"input": t >= input_at, "free": not busy, "riding": tell_riding and t < ride_until and not other,
				"ordered": ordered, "delivered_t": delivered_t,
				"raced": raced, "calling": t < calling_until, "race_next": 0.0, "trap": trap, "rang": rang,
				"rescued": rescued, "heli_call": t >= heli_call_at and not rescued, "tape": tape,
				"powisle": powisle, "garage": garage, "earned": earned, "scripted": scripted}

	## The world moves on by itself.
	func step() -> void:
		var free_now: bool = facts()["free"]
		if held and honour_hold:
			next_ride = maxf(next_ride, t + 30.0)  # rides.gd HOLD_GAP
		if rider and t >= next_ride and free_now and not (held and honour_hold):
			ride_until = t + ride_s
			next_ride = ride_until + ride_gap
			rides_taken += 1
		if not ordered and t >= order_at:
			ordered = true
			busy_until = t + deliver_s
		if ordered and delivered_t < 0.0 and t >= busy_until:
			delivered_t = t
			earned = true
		if race_end != INF and t >= race_end and not raced:
			raced = true
			earned = true
		if raced and not trap and t >= race_end + 6.0:
			trap = true  # police.gd arms it FIRST_DELAY s after the race
		if not rang and t >= rang_at:
			rang = true
			busy_until = t + 90.0
			rescue_end = t + 90.0
		if rang and not rescued and t >= rescue_end and rescue_ok:
			rescued = true
			earned = true
		if not tape and t >= tape_at:
			tape = true
			powisle = true  # the boulevards are in Powiśle
		if not garage and t >= garage_at:
			garage = true

	## The director fired `id`: what follows in the toy.
	func on_fire(id: String) -> void:
		match id:
			"order":
				order_at = t
			"race":
				calling_until = t + (20.0 if says_no else 8.0)
				if not says_no:
					race_end = t + 8.0 + 60.0
					busy_until = race_end
			"rescue":
				rang_at = t + 12.0
			"tape":
				tape_at = t + tape_after
			"garage":
				garage_at = t + 0.3


## Plays `toy` for `seconds` through the director's rules: [fired (id -> s), how (id -> way)].
func _play(toy: Toy, seconds: float) -> Array:
	var done := {}
	var ways := {}
	while toy.t < seconds:
		toy.step()
		var f := toy.facts()
		toy.held = not First10.due(toy.t, f, done).is_empty()
		if not done.has("done"):
			for id in First10.met(f):
				if not done.has(id):
					done[id] = toy.t
					ways[id] = "met"
			for id in First10.decide(toy.t, f, done):
				if not done.has(id):
					done[id] = toy.t
					ways[id] = "fired"
					toy.on_fire(id)
		toy.t += STEP
	return [done, ways]


func _at(done: Dictionary, id: String) -> float:
	return float(done.get(id, -1.0))


func _ordinary() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	var bad := First10.judge(done, ways)
	_expect(bad.is_empty(), "the ordinary player: %s" % [bad])
	_expect(ways.get("finger") == "met" and _at(done, "finger") < 2.0, "a touch at 1 s: no finger (%s)" % ways.get("finger"))
	_expect(ways.get("stand") == "fired" and absf(_at(done, "stand") - First10.STAND_AT) < 0.3, "the stand's arrow at 10 s: %.1f" % _at(done, "stand"))
	_expect(ways.get("order") == "met" and absf(_at(done, "order") - 35.0) < 0.3, "the order met at 35 s: %.1f" % _at(done, "order"))
	_expect(ways.get("race") == "fired" and absf(_at(done, "race") - (110.0 + First10.RACE_AFTER)) < 0.5,
			"Halina %.0f s after the delivery: %.1f" % [First10.RACE_AFTER, _at(done, "race")])
	_expect(ways.get("trap") == "met", "the trap armed by the race, not the fallback: %s" % ways.get("trap"))
	_expect(ways.get("rescue") == "fired" and absf(_at(done, "rescue") - First10.RESCUE_AT) < 0.3, "the call let through at 3:45: %.1f" % _at(done, "rescue"))
	_expect(ways.get("heli") == "fired" and _at(done, "heli") > _at(done, "rescue") + 90.0, "the helicopter after the rescue: %.1f" % _at(done, "heli"))
	_expect(ways.get("powisle") == "met", "Powiśle discovered at the boulevards: %s" % ways.get("powisle"))
	_expect(ways.get("garage") == "fired" and absf(_at(done, "garage") - First10.GARAGE_AT) < 0.3, "the garage at 9:30: %.1f" % _at(done, "garage"))
	_expect(done.has("done") and _at(done, "done") < First10.GARAGE_AT + 2.0, "the guide ends at the garage: %.1f" % _at(done, "done"))
	_summary.append("ordinary %s" % _line(done))


func _wanderer() -> void:
	var toy := Toy.new()
	toy.says_no = true
	toy.tape_after = INF
	toy.rescue_ok = false
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("finger") == "fired" and absf(_at(done, "finger") - First10.FINGER_IDLE) < 0.3, "the finger at 4 s: %.1f" % _at(done, "finger"))
	_expect(ways.get("stand") == "fired" and absf(_at(done, "stand") - First10.STAND_AT) < 0.3, "the arrow at 10 s: %.1f" % _at(done, "stand"))
	_expect(not done.has("order"), "no order without the player (or the replay)")
	_expect(ways.get("race") == "fired" and absf(_at(done, "race") - First10.RACE_LATEST) < 0.3, "Halina at the fallback: %.1f" % _at(done, "race"))
	_expect(ways.get("trap") == "fired" and absf(_at(done, "trap") - First10.TRAP_LATEST) < 0.3, "the trap armed at its fallback: %.1f" % _at(done, "trap"))
	_expect(ways.get("rescue") == "fired" and absf(_at(done, "rescue") - First10.RESCUE_LATEST) < 0.3, "the call at its fallback: %.1f" % _at(done, "rescue"))
	_expect(ways.get("heli") == "fired" and absf(_at(done, "heli") - First10.HELI_LATEST) < 0.3, "the helicopter at its fallback: %.1f" % _at(done, "heli"))
	_expect(ways.get("tape") == "fired" and _at(done, "tape") >= First10.HELI_LATEST, "the tape's arrow after the helicopter: %.1f" % _at(done, "tape"))
	_expect(ways.get("powisle") == "fired" and _at(done, "powisle") >= First10.POWISLE_AT, "the Powiśle arrow: %.1f" % _at(done, "powisle"))
	_expect(not done.has("garage"), "no earnings: no garage (%.1f)" % _at(done, "garage"))
	_expect(absf(_at(done, "done") - First10.GUIDE_END) < 0.3, "the guide ends at GUIDE_END: %.1f" % _at(done, "done"))
	_summary.append("wanderer %s" % _line(done))


func _busy() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	toy.job_from = 220.0
	toy.job_to = 330.0
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	_expect(_at(done, "rescue") >= 330.0 - 0.01 and _at(done, "rescue") < 331.0, "the call waits for the job (220-330 s): %.1f" % _at(done, "rescue"))
	_summary.append("busy: the call at %.0f s" % _at(done, "rescue"))


## Run 12 (2026-11-03): a player who takes every Podwózka request kept the first call waiting
## 83 s past its window. The guide holds new requests while a beat is due (first10.gd `due`), so
## the race and the call land in their windows and the rides come between the beats.
func _rider() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 15.0
	toy.deliver_s = 20.0
	toy.rider = true
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var bad := First10.judge(done, r[1])
	_expect(bad.is_empty(), "the rider's beats in their windows: %s" % [bad])
	_expect(toy.rides_taken >= 2, "the rider still gets rides between the beats: %d" % toy.rides_taken)
	var old := Toy.new()
	old.input_at = 1.0
	old.order_at = 15.0
	old.deliver_s = 20.0
	old.rider = true
	old.honour_hold = false
	var o := _play(old, 1000.0)
	_expect(not First10.judge(o[0], o[1]).is_empty(), "without the hold the rider meets a beat late (the test means something)")
	# due: what the director waits to fire, and nothing once the guide is over.
	var f := {"free": false, "ordered": true, "delivered_t": 40.0, "race_next": 0.0, "earned": true}
	_expect(First10.due(100.0, f, {"finger": 1.0, "stand": 10.0, "order": 15.0}) == ["race"], "Halina due at 100 s while busy: %s" % [First10.due(100.0, f, {"finger": 1.0, "stand": 10.0, "order": 15.0})])
	_expect(First10.due(100.0, f, {"done": 900.0}).is_empty(), "nothing due once the guide is over")
	_expect(First10.due(20.0, f, {"finger": 1.0, "stand": 10.0, "order": 15.0}).is_empty(), "nothing due at 20 s (Halina not before %.0f s)" % First10.RACE_EARLIEST)
	_summary.append("rider: %d rides, the call at %.0f s (%s without the hold)" % [toy.rides_taken, _at(done, "rescue"), ", ".join(First10.judge(o[0], o[1]))])


## The replay of 2026-11-10: a Podwózka request taken at 331 s, in the free gap between the tape's
## beat and the hold for Powiśle (45 s before a beat), ran to 600 s with the drive to the pin, and
## Powiśle came 20 s past its window. The Powiśle line now shows at POWISLE_LATEST over a ride
## (first10.gd `decide`; the ride's pin keeps the arrow until it is done), and only over a ride.
func _long_ride() -> void:
	var make := func(riding: bool, as_job: bool) -> Toy:
		var toy := Toy.new()
		toy.input_at = 1.0
		toy.order_at = 15.0
		toy.deliver_s = 20.0
		toy.tape_after = INF  # the tape is not fetched: Powiśle is not met by the way
		toy.tell_riding = riding
		if as_job:
			toy.job_from = 335.0
			toy.job_to = 600.0
		else:
			toy.rider = true
			toy.next_ride = 335.0
			toy.ride_s = 265.0
			toy.ride_gap = 1000.0
		return toy
	var toy: Toy = make.call(true, false)
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	var bad := First10.judge(done, ways)
	var from := toy.ride_until - toy.ride_s
	_expect(toy.rides_taken == 1 and from > _at(done, "tape") and from < First10.POWISLE_AT - First10.HOLD_AHEAD
			and toy.ride_until > First10.WINDOWS["powisle"].y,
			"one ride, taken between the tape's beat and the hold for Powiśle, past Powiśle's window: %d, %.1f to %.1f s" % [toy.rides_taken, from, toy.ride_until])
	_expect(bad.is_empty(), "a 4.5-minute ride across Powiśle's window: every beat in its window: %s" % [bad])
	_expect(ways.get("powisle") == "fired" and absf(_at(done, "powisle") - First10.POWISLE_LATEST) < 0.3,
			"the Powiśle line over the ride at POWISLE_LATEST: %.1f" % _at(done, "powisle"))
	var old: Toy = make.call(false, false)
	var o := _play(old, 1000.0)
	var late := First10.judge(o[0], o[1])
	_expect(late.size() == 1 and late[0].begins_with("powisle late"), "without the rule the same ride makes Powiśle late (the test means something): %s" % [late])
	# Any other job of that length: the line still waits for its end.
	var job: Toy = make.call(true, true)
	var j: Dictionary = _play(job, 1000.0)[0]
	_expect(_at(j, "powisle") >= 600.0 - 0.01 and _at(j, "powisle") < 601.0, "behind another job the Powiśle line waits: %.1f" % _at(j, "powisle"))
	# The rule itself: not before POWISLE_LATEST, and never when something else is on.
	var seen := {"finger": 1.0, "stand": 10.0, "order": 15.0, "race": 75.0, "trap": 150.0, "rescue": 225.0, "heli": 327.0, "tape": 330.0}
	var f := {"free": false, "riding": true, "ordered": true, "raced": true, "trap": true, "rang": false, "rescued": true}
	_expect(not ("powisle" in First10.decide(First10.POWISLE_LATEST - 1.0, f, seen)), "a ride before POWISLE_LATEST: the line waits")
	_expect("powisle" in First10.decide(First10.POWISLE_LATEST, f, seen), "a ride at POWISLE_LATEST: the line shows")
	f["riding"] = false
	_expect(not ("powisle" in First10.decide(First10.POWISLE_LATEST + 60.0, f, seen)), "a race, a call, the police or a card at POWISLE_LATEST: the line waits")
	_expect(First10.POWISLE_AT < First10.POWISLE_LATEST and First10.POWISLE_LATEST < First10.WINDOWS["powisle"].y,
			"POWISLE_LATEST %.0f s is after POWISLE_AT and inside the window" % First10.POWISLE_LATEST)
	_summary.append("a ride from %.0f to %.0f s: Powiśle at %.0f s (%s without the rule)" % [from, toy.ride_until, _at(done, "powisle"), ", ".join(late)])


## The first-10 polish: the short first order is done in ~20 s; Halina still waits for
## RACE_EARLIEST, inside the race's window.
func _quick() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 15.0
	toy.deliver_s = 20.0
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var race := _at(done, "race")
	_expect(race >= First10.RACE_EARLIEST - 0.01 and race <= First10.RACE_EARLIEST + 1.0, "a quick first delivery (35 s): Halina at %.1f s, not before %.0f" % [race, First10.RACE_EARLIEST])
	_expect(First10.judge(done, r[1]).is_empty(), "the quick player's beats in their windows: %s" % [First10.judge(done, r[1])])
	_summary.append("quick: the race at %.0f s" % race)


func _scripted() -> void:
	var toy := Toy.new()
	toy.scripted = true
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("order") == "fired" and absf(_at(done, "order") - First10.ORDER_AT) < 0.3, "the replay's order at 15 s: %.1f" % _at(done, "order"))
	var bad := First10.judge(done, ways)
	_expect(bad.is_empty(), "the replay toy (no touch, the order scripted): %s" % [bad])
	var heli := Toy.new()
	heli.input_at = 1.0
	heli.heli_call_at = 100.0
	var h: Dictionary = _play(heli, 200.0)[0]
	_expect(absf(_at(h, "heli") - 100.0) < 0.3, "a helicopter-only call unlocks it at once: %.1f" % _at(h, "heli"))
	_summary.append("replay toy OK")


func _judge() -> void:
	var done := {}
	var ways := {}
	for id: String in First10.BEATS:
		var w: Vector2 = First10.WINDOWS[id]
		done[id] = (w.x + w.y) * 0.5
		ways[id] = "fired"
	_expect(First10.judge(done, ways).is_empty(), "every beat mid-window passes")
	done["race"] = 260.0
	done["tape"] = 100.0
	done.erase("garage")
	var bad := First10.judge(done, ways)
	_expect(bad.size() == 3, "late race, early tape, missing garage: %s" % [bad])
	ways["tape"] = "met"
	_expect(First10.judge(done, ways).size() == 2, "a tape met early is fine")


## A stand-in for a traffic driver: the fields rivals.gd `arm_racer` and `pace_tick` set.
class ToyRacer:
	var speed_factor := 1.0
	var accel_factor := 1.0
	var race_top := 0.0
	var race_share := 1.0
	var race_accel := 0.0
	var race_brake := 0.0
	var race_lat := 0.0
	var race_effort := 1.0
	var race_corner := 1.0
	var race_still := 0.0
	var race_passes := 0
	var cuts := {}
	var race_mistake := 0.0
	var race_wrong := 0
	var race_block := 0.0
	var race_dare := 1.0
	var race_rng: RandomNumberGenerator
	var cuts_taken := 0
	var links_taken := 0
	var hop_go := false
	var hops_taken := 0
	var hops_refused := 0
	var mistakes := 0
	var wrong_turns := 0
	var blocks := 0


## A 1-D race of `road` m, the guided first race in small: the player at `speed` m/s (0: no
## player at all; stopping `stop` s at half way; starting `late` s after START!), Halina from 12 m
## behind on ladder.gd's gentle day (eased by `ease`) at rivals.gd's effort (`arm_racer`, then
## `pace_tick` 5 times a second, as the game), pulling her race_accel towards her share of a main
## road's racing speed times her effort; `hold`: she waits at the line for the player to move
## (`first_start_step`, PT-11). Returns {lead: the player's lead at the finish in s (< 0: she
## won), time: her seconds from the moment she was let go, wait: her seconds at the line, lo and
## hi: her lowest and highest speed once up to it, as a share of her own straight-line pace}.
func _race(speed: float, stop := 0.0, road := 800.0, late := 0.0, hold := false, ease := 0.0) -> Dictionary:
	var toy := ToyRacer.new()
	var stats := Rivals.arm_racer(toy, 0, 30.0, {}, true, ease, 1)
	var own: float = minf(toy.race_top, Traffic.RACE_CLASS_TOP[0]) * toy.race_share
	var pace := Rivals.Pace.new()
	var held := hold
	var me := road
	var her := road + 12.0
	var v := 0.0
	var dt := 0.05
	var t := 0.0
	var k := 0.0
	var wait := 0.0
	var stopped := 0.0
	var lo := INF
	var hi := 0.0
	var up := false
	var her_time := -1.0
	while (me > 0.0 or her > 0.0) and t < 900.0:
		k += dt
		if k >= 0.2:
			k = 0.0
			Rivals.pace_tick(pace, toy, float(stats["mistake"]), maxf(her, 0.0), maxf(me, 0.0) if speed > 0.0 else INF)
		var mine := speed if t >= late else 0.0
		if held:
			if Rivals.first_start_step(t, mine) == "release":
				held = false
				wait = t
		if her > 0.0:
			v = move_toward(v, 0.0 if held else own * toy.race_effort, toy.race_accel * dt)
			her -= v * dt
			if not held and v >= own * Rivals.EFFORT_EASE - 0.01:
				up = true
			if up:
				lo = minf(lo, v / own)
				hi = maxf(hi, v / own)
			if her <= 0.0:
				her_time = t + dt - wait
		if me > 0.0 and speed > 0.0:
			if t < late:
				pass
			elif stop > 0.0 and me < road * 0.5 and stopped < stop:
				stopped += dt
			else:
				me -= speed * dt
				if me <= 0.0 and her > 0.0:
					# The player is home first: by how long, at her speed now.
					return {"lead": her / maxf(v, 0.1), "time": -1.0, "wait": wait, "lo": lo, "hi": hi}
		elif speed <= 0.0:
			me = 0.0 if her <= 0.0 else me
		t += dt
		if her <= 0.0 and speed > 0.0 and me > 0.0:
			# She is home first: the player's seconds still to drive.
			return {"lead": -me / speed, "time": her_time, "wait": wait, "lo": lo, "hi": hi}
	return {"lead": 0.0, "time": her_time, "wait": wait, "lo": lo, "hi": hi}


## Her time over the same 800 m whatever the player does (the race is driven on past the player's
## finish): the player at `speed`, stopping `stop` s at half way.
func _her_time(speed: float, stop := 0.0) -> float:
	var toy := ToyRacer.new()
	var stats := Rivals.arm_racer(toy, 0, 30.0, {}, true, 0.0, 1)
	var own: float = minf(toy.race_top, Traffic.RACE_CLASS_TOP[0]) * toy.race_share
	var pace := Rivals.Pace.new()
	var me := 800.0
	var her := 812.0
	var v := 0.0
	var dt := 0.05
	var t := 0.0
	var k := 0.0
	var stopped := 0.0
	while her > 0.0 and t < 900.0:
		k += dt
		if k >= 0.2:
			k = 0.0
			Rivals.pace_tick(pace, toy, float(stats["mistake"]), her, maxf(me, 0.0) if speed > 0.0 else INF)
		v = move_toward(v, own * toy.race_effort, toy.race_accel * dt)
		her -= v * dt
		if stop > 0.0 and me < 400.0 and stopped < stop:
			stopped += dt
		else:
			me -= speed * dt
		t += dt
	return t


## The racer AI rebuild, step 2 (docs/design/race-ai.md 6): the first race's driver is ladder.gd's
## gentle day at rivals.gd's effort, and nothing in it is the player's speed.
func _effort() -> void:
	# The effort: the time gap alone, bounded both ways.
	_expect(Rivals.effort_of(0.0) == 1.0 and Rivals.effort_of(Rivals.EASE_FROM) == 1.0 and Rivals.effort_of(-Rivals.PUSH_FROM) == 1.0,
			"level, just ahead or just behind: her own pace")
	_expect(is_equal_approx(Rivals.effort_of(Rivals.EASE_FULL), Rivals.EFFORT_EASE) and is_equal_approx(Rivals.effort_of(900.0), Rivals.EFFORT_EASE),
			"far ahead she eases to EFFORT_EASE and no further: %.2f" % Rivals.effort_of(900.0))
	_expect(is_equal_approx(Rivals.effort_of(-Rivals.PUSH_FULL), Rivals.EFFORT_PUSH) and is_equal_approx(Rivals.effort_of(-900.0), Rivals.EFFORT_PUSH),
			"far behind she pushes to EFFORT_PUSH and no further: %.2f" % Rivals.effort_of(-900.0))
	var falls := true
	for i in range(-40, 40):
		falls = falls and Rivals.effort_of(i * 0.5 + 0.5) <= Rivals.effort_of(i * 0.5) + 0.0001
	_expect(falls, "the further ahead, the less effort (never the other way)")
	_expect(Rivals.EFFORT_EASE >= 0.85 and Rivals.EFFORT_PUSH <= 1.1, "the effort stays within a tenth or so: %.2f-%.2f" % [Rivals.EFFORT_EASE, Rivals.EFFORT_PUSH])
	_expect(is_equal_approx(Rivals.own_pace(30.0, 0.65), 30.0 * 0.65 * Rivals.GAP_PACE) and Rivals.own_pace(0.0, 0.65) == 5.0, "her seconds come from her own usual speed")
	# The gentle day and the easier rematch (ladder.gd).
	_expect(Rivals.race_stats(0, true) == Ladder.FIRST_RACER and Rivals.race_stats(0) == Ladder.racer(0), "the first race drives FIRST_RACER, her rung its own numbers")
	_expect(float(Rivals.race_stats(0, true, 0.1)["share"]) < float(Ladder.FIRST_RACER["share"]), "an easier rematch is slower")
	# pace_tick: a pushing rival makes more mistakes, and the effort never takes a car past its top.
	var toy := ToyRacer.new()
	Rivals.arm_racer(toy, 5, 30.0, {}, false, 0.0, 1)
	_expect(toy.race_rng != null and toy.race_top == 30.0 and is_equal_approx(toy.race_share, float(Ladder.racer(5)["share"])), "arm_racer: the player's top, the rung's share, its own dice")
	var pace := Rivals.Pace.new()
	for i in 200:
		Rivals.pace_tick(pace, toy, 0.1, 2000.0, 1000.0)
	# (Mike drives the road's full speed since step 4a: his push is all in the corners.)
	_expect(toy.race_effort * toy.race_share <= 1.0001 and is_equal_approx(toy.race_corner, Rivals.EFFORT_PUSH),
			"far behind, Mike pushes through the corners but never past the car's top: %.3f of it, %.2f of his grip" % [toy.race_effort * toy.race_share, toy.race_corner])
	var room := ToyRacer.new()
	Rivals.arm_racer(room, 4, 30.0, {}, false, 0.0, 1)
	var room_pace := Rivals.Pace.new()
	for i in 200:
		Rivals.pace_tick(room_pace, room, 0.1, 2000.0, 1000.0)
	_expect(is_equal_approx(room.race_effort, Rivals.EFFORT_PUSH) and room.race_effort * room.race_share <= 1.0001 and is_equal_approx(room.race_corner, Rivals.EFFORT_PUSH),
			"far behind, a rival with room under the car's top pushes on the straights too: %.3f of the car's top" % (room.race_effort * room.race_share))
	_expect(is_equal_approx(toy.race_mistake, 0.1 * Rivals.PUSH_MISTAKES), "pushing: PUSH_MISTAKES times the mistakes: %.3f" % toy.race_mistake)
	pace = Rivals.Pace.new()
	for i in 200:
		Rivals.pace_tick(pace, toy, 0.1, 1000.0, 2000.0)
	_expect(is_equal_approx(toy.race_effort, Rivals.EFFORT_EASE) and is_equal_approx(toy.race_mistake, 0.1), "far ahead: EFFORT_EASE, her usual mistakes")
	pace = Rivals.Pace.new()
	Rivals.pace_tick(pace, toy, 0.1, 1000.0, 2000.0)
	_expect(toy.race_effort >= 1.0 - Rivals.EFFORT_RATE * 0.2 - 0.0001, "the effort moves slowly (EFFORT_RATE a second), no step")
	pace = Rivals.Pace.new()
	Rivals.pace_tick(pace, toy, 0.1, 1000.0, INF)
	_expect(toy.race_effort == 1.0, "no player: her own pace")
	# Her time is her own: 800 m against nobody, a slow, an ordinary and a fast player, one who
	# stops for a minute and one who never moves.
	var alone := _her_time(0.0)
	var worst := 0.0
	var lows := INF
	for case: Array in [[6.0, 0.0], [9.5, 0.0], [14.0, 0.0], [21.0, 0.0], [30.0, 0.0], [9.5, 60.0], [0.01, 0.0]]:
		var with := _her_time(case[0], case[1])
		var x := with / alone - 1.0
		if absf(x) > absf(worst):
			worst = x
		lows = minf(lows, x)
	_expect(absf(worst) <= 0.12, "her time moves at most 12 %% whatever the player does: %+.0f %%" % (worst * 100.0))
	var ordinary := _race(9.5)
	var fast := _race(21.0)
	var slow := _race(6.0)
	var stops := _race(21.0, 60.0)
	_expect(float(fast["lead"]) > 0.0, "a player faster than her wins: %.1f s" % fast["lead"])
	_expect(float(ordinary["lead"]) < -10.0 and float(slow["lead"]) < float(ordinary["lead"]), "a player at town pace loses, a slower one by more (she does not wait): %.1f s, %.1f s" % [ordinary["lead"], slow["lead"]])
	_expect(float(stops["lead"]) < 0.0, "a fast player who stops for a minute loses: %.1f s" % stops["lead"])
	for r: Dictionary in [ordinary, fast, slow, stops]:
		_expect(float(r["lo"]) >= Rivals.EFFORT_EASE - 0.011 and float(r["hi"]) <= Rivals.EFFORT_PUSH + 0.001,
				"once up to speed she holds %.2f to %.2f of her own pace to the line (no crawl, no lift-off): %.2f-%.2f" % [Rivals.EFFORT_EASE, Rivals.EFFORT_PUSH, r["lo"], r["hi"]])
	var eased := _race(0.0, 0.0, 800.0, 0.0, false, Ladder.EASE_MAX)
	_expect(float(eased["time"]) > alone * 1.05, "after three losses in a row she is slower: %.1f s against %.1f s" % [eased["time"], alone])
	# PT-11: a new player who sits still after START! (the agent in run 20261102-175913 lost so).
	var late_new := _race(21.0, 0.0, 800.0, 8.0, true)
	var long_s := Rivals.FIRST_HOLD + 8.0
	var long_new := _race(21.0, 0.0, 800.0, long_s, true)
	_expect(float(late_new["wait"]) >= 8.0 and float(late_new["wait"]) < 9.0 and absf(float(late_new["lead"]) - float(fast["lead"])) < 1.0,
			"8 s still at the start, she waits: the race is the same: waited %.1f s, %.1f s against %.1f s" % [late_new["wait"], late_new["lead"], fast["lead"]])
	_expect(absf(float(long_new["wait"]) - Rivals.FIRST_HOLD) < 0.11 and float(long_new["lead"]) < float(fast["lead"]),
			"%.0f s still: she goes after FIRST_HOLD s and the player pays for the rest: waited %.1f s, %.1f s" % [long_s, long_new["wait"], long_new["lead"]])
	_expect(Rivals.first_start_step(0.5, 0.0) == "wait", "START! + 0.5 s, still: wait")
	_expect(Rivals.first_start_step(Rivals.FIRST_IDLE + 0.1, 0.5) == "nudge", "still past FIRST_IDLE: the GO nudge")
	_expect(Rivals.first_start_step(1.0, Rivals.FIRST_MOVE + 0.1) == "release", "the player moves: she goes")
	_expect(Rivals.first_start_step(Rivals.FIRST_HOLD, 0.0) == "release", "FIRST_HOLD s: she goes anyway")
	_expect(Rivals.first_stall_due(Rivals.FIRST_STALL, 0, 500.0), "stopped mid-race: the stall nudge")
	_expect(not Rivals.first_stall_due(Rivals.FIRST_STALL - 0.5, 0, 500.0), "a short stop (a red light): no nudge")
	_expect(not Rivals.first_stall_due(Rivals.FIRST_STALL, Rivals.FIRST_STALLS, 500.0), "at most FIRST_STALLS nudges")
	_expect(not Rivals.first_stall_due(60.0, 0, Rivals.FIRST_EASE - 1.0), "the last stretch: no nudge")
	_expect(Rivals.FIRST_GO_BANNER.length() <= 24, "the GO banner fits: %s" % Rivals.FIRST_GO_BANNER)
	_summary.append("start: 8 s still, she waits %.1f s; %.0f s still, she goes at %.0f s" % [late_new["wait"], long_s, long_new["wait"]])
	_summary.append("first race: her 800 m alone %.1f s, with any player %+.0f to %+.0f %%, %.2f-%.2f of her own pace; a fast player %+.1f s, town pace %+.1f s, a stop %+.1f s" % [
			alone, lows * 100.0, worst * 100.0 if worst > 0.0 else 0.0, minf(float(slow["lo"]), float(stops["lo"])), float(fast["hi"]), fast["lead"], ordinary["lead"], stops["lead"]])


func _words() -> void:
	var lines: Array = []
	for k in First10.LINES:
		lines.append(First10.LINES[k])
	for k in Rivals.FIRST_LINES:
		lines.append(Rivals.FIRST_LINES[k])
	for l: Array in lines:
		_expect(l.size() == 2 and str(l[0]) != "" and str(l[1]) != "" and str(l[0]) != str(l[1]), "Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 70, "at most 70 characters: %s (%d)" % [x, str(x).length()])
	for l: Array in [First10.END_TITLE, First10.END_BODY, First10.END_FREE]:
		_expect(l.size() == 2 and str(l[0]) != str(l[1]), "the end card in Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 100, "an end card line at most 100 characters: %s" % x)
	var w := First10.end_words()
	_expect(w.size() == 4 and First10.REPO in w[1], "the repo's name on the card (the shared line under the Polish)")
	_expect("OpenStreetMap" in w[1] and "GUGiK" in w[1], "the credits on the card (the shared line)")
	var readme := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../README.md").simplify_path())
	if readme != "":
		_expect(("https://" + First10.REPO) in readme, "README names %s" % First10.REPO)
	_expect(First10.END_BUTTON.get_slice("|", 0) == "JEDŹ DALEJ" and First10.END_BUTTON.get_slice("|", 1) == "FREE ROAM", "the button: %s" % First10.END_BUTTON)
	_summary.append("words")


func _line(done: Dictionary) -> String:
	var parts := PackedStringArray()
	for id: String in First10.BEATS:
		parts.append("%s %s" % [id.substr(0, 2), str(roundi(_at(done, id))) if done.has(id) else "-"])
	return " ".join(parts)


## PT-30: the Powiśle beat's arrow, from the real districts data.
func _powisle() -> void:
	var d := Districts.new()
	var f := First10.new()
	_expect(f.powisle_at() == Vector3.INF, "no districts: no Powiśle arrow")
	if not d.load_data():
		_expect(false, "districts data loads")
	else:
		f.districts = d
		var at := f.powisle_at()
		var want: Vector2 = d.districts[int(d.by_id["powisle"])]["at"]
		_expect(at != Vector3.INF and Vector2(at.x, at.z).distance_to(want) < 0.01, "the Powiśle arrow at the district's label: %s" % at)
		_summary.append("Powiśle arrow at %.0f, %.0f" % [at.x, at.z])
	f.free()
	d.free()
