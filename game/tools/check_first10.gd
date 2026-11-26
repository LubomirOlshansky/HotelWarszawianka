extends SceneTree
## Loop 3h slice 4 and first hour step 3: the guided first minutes (first10.gd) and the First steps
## list (first_steps.gd), without the map. Checks that:
## - the beats a replay must see are the finger, the stand, the order, the choice card and the nine
##   intros, each window holds the first hour's time ("First hour for the beta", the hour as it
##   would play), and the windows are in order;
## - `guide_due` only on a fresh save (a job, złoty, a rung or a finished guide: never), or on one
##   where the guide began and has not finished (złoty earned since: still on); `first_launch` only
##   until the opening was seen; `restored` brings an earlier session's beats back (the kebab arrow
##   with no order counts as let go), so nothing is made twice;
## - players on a synthetic clock through `decide` and `met` (the director's rules) with a toy city
##   (a delivery takes 75 s, a race 60 s, a rescue 90 s, ...): an ordinary player (touches at once,
##   orders at 0:35, picks RACE, does what each intro offers) gets the choice card CHOICE_AFTER s
##   after the delivery, Halina at once, every intro by its window's end, and all seven First steps;
##   a wanderer (never touches or orders, picks JUST DRIVE, says no to Halina) gets the finger, the
##   arrow, the kebab let go at LURE_LATEST, the choice at LURE_LATEST + CHOICE_AFTER, then one
##   intro every NEXT_GAP s of free driving, Halina only once, no garage without earnings and the
##   guide's end at GUIDE_END; a player who already flew and gave a lift is never told about the
##   helicopter or the rides (met, not fired); FLY asks for the helicopter and the tape at once,
##   RIDES for the ride; a player busy with a job gets the next intro only NEXT_GAP s after it; a
##   player who takes every Łuber request still meets every intro (the hold, `due`), and without
##   the hold does not (the test means something); the replay's scripted order fires at ORDER_AT; a
##   helicopter-only call brings the helicopter's toast at once; `judge` flags a late, a missing and
##   an early-fired beat;
## - the friends' calls wait for FRIENDS_STEPS steps or FRIENDS_AFTER s (at most 5 minutes, and not
##   again in a later session once opened), then NEW_FRIEND_GAP s after a
##   new friend (`friends_held`); the First steps' rewards (money each, a paint and the friends at the
##   third, the card, a paint and the respect at the seventh), an old save's quiet ticks
##   (`from_wallet`), the rows and the header for the map's list;
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
## - the words (the director's, Halina's, the choice card's, the First steps', the end card's) in
##   Polish and English, each line at most 70 characters (a card's body at most 110), the repo's
##   name as README has it.
##   godot --headless --path game --script res://tools/check_first10.gd

const First10 := preload("res://scripts/first10.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")
const Rivals := preload("res://scripts/rivals.gd")
const RaceSession := preload("res://scripts/race_session.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Districts := preload("res://scripts/districts.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Rules := preload("res://scripts/ride_rules.gd")
const QuestBook := preload("res://scripts/quest_book.gd")
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
	_skipper()
	_picks()
	_busy()
	_rider()
	_scripted()
	_judge()
	_beta()
	_friends()
	_steps()
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
	var want := ["finger", "stand", "order", "beta", "choice", "race", "trap", "rescue", "heli", "tape", "ride", "powisle", "garage"]
	_expect(First10.BEATS == want, "the beats: %s" % [First10.BEATS])
	for id: String in First10.INTROS:
		_expect(id in First10.BEATS or id == "kebab", "intro %s is a beat (or the kebab, met by the first delivery)" % id)
	# The first hour as it would play (the spec's table): the choice about 1:45, the race 2:00 to
	# 4:00, the police about 4:00, the first rescue about 5:00, the helicopter about 7:00, the garage
	# about 9:30.
	var times := {"finger": 5.0, "stand": 15.0, "order": 30.0, "beta": 90.0, "choice": 105.0, "race": 150.0, "trap": 240.0,
			"rescue": 300.0, "heli": 420.0, "tape": 430.0, "ride": 480.0, "powisle": 500.0, "garage": 570.0}
	for id: String in First10.BEATS:
		var w: Vector2 = First10.WINDOWS[id]
		_expect(w.x <= times[id] and times[id] <= w.y, "%s's window %s holds the hour's %.0f s" % [id, w, times[id]])
		_expect(w.x < w.y and w.y < First10.REPLAY_DEADLINE, "%s's window %s ends before the replay's deadline" % [id, w])
	for id: String in First10.INTRO_STEP:
		_expect(str(First10.INTRO_STEP[id]) in FirstSteps.IDS, "intro %s's step %s is a First step" % [id, First10.INTRO_STEP[id]])
	_expect(First10.CHOICE_LOG.size() == 3 and First10.CHOICE_CLOSE == First10.CHOICE_LOG.size()
			and First10.CHOICE_PICKS.size() == First10.CHOICE_LOG.size() + 1 and (First10.CHOICE_PICKS[First10.CHOICE_CLOSE] as Array).is_empty(),
			"the choice card: RACE, RIDES, FLY, one pick each, and the ✕ is JUST DRIVE (none)")
	# F's playtest 2026-11-16: the card comes sooner and stays longer, the garage follows the race.
	_expect(First10.CHOICE_LIFE == 30.0, "the choice card lives 30 s: %.0f" % First10.CHOICE_LIFE)
	_expect(First10.CHOICE_AFTER == 20.0 and First10.CHOICE_LATEST == 150.0, "pacing.json: the card 20 s after the delivery, 150 s at the latest: %.0f %.0f" % [First10.CHOICE_AFTER, First10.CHOICE_LATEST])
	_expect(First10.INTROS.find("garage") == First10.INTROS.find("race") + 1, "the garage is the intro right after the race: %s" % [First10.INTROS])
	_expect(First10.REPLAY_DEADLINE * 60.0 < 48000.0, "the replay judges before verify.sh's 48000 frames")
	_summary.append("%d beats" % First10.BEATS.size())


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
	# 2026-11-22: a guide once begun carries on in later sessions, whatever was earned since.
	w.ladder.clear()
	w.intro.clear()
	_expect(First10.first_launch(w), "a fresh save: the first launch (the opening)")
	w.intro[First10.GUIDE_KEY] = 20261122
	w.intro[First10.OPENED_KEY] = 20261122
	_expect(not First10.first_launch(w), "the opening seen: no flyover, no Palace start again")
	w.zl = 50
	w.jobs["kebab"] = 1
	_expect(First10.guide_due(w), "a guide begun carries on with a kebab and 50 zł in the save")
	_expect(not First10.first_launch(w), "... but not as a first launch")
	w.intro["done"] = 20261122
	_expect(not First10.guide_due(w), "a begun guide ends at done")
	var r := First10.restored({"finger": 1, "stand": 1, "fs_heli": 1, "beta_pick": 2, "guide": 1})
	_expect(r.has("finger") and r.has("stand") and r.has("lure") and not r.has("order"),
			"restored: finger, stand, and the kebab let go with no order: %s" % [r])
	_expect(not r.has("fs_heli") and not r.has("beta_pick") and not r.has("guide"), "restored: beats only: %s" % [r])
	r = First10.restored({"finger": 1, "stand": 1, "order": 1, "beta": 1, "choice": 1, "race": 1})
	_expect(not r.has("lure") and r.has("choice") and r.has("race"), "restored: an order taken is not a kebab let go: %s" % [r])
	# The restored beats are not made again; the next intro comes after NEXT_GAP s of free driving.
	var f := {"free": true, "free_for": 0.0, "input": false, "delivered_t": -1.0, "want": [], "ways": {}}
	for id: String in r:
		f["ways"][id] = "saved"
	var now := First10.RESTORED_AT + 1.0
	var out := First10.decide(now, f, r)
	_expect(not "finger" in out and not "stand" in out and not "beta" in out and not "choice" in out,
			"a resumed session makes no beat again: %s" % [out])
	f["free_for"] = First10.NEXT_GAP
	out = First10.decide(now + First10.NEXT_GAP, f, r)
	_expect(out == ["trap"], "a resumed session (the race restored, nothing earned yet): the police next after NEXT_GAP s: %s" % [out])
	w.free()
	_summary.append("fresh saves, then resumed")


## A toy city for `decide` and `met`: the player's plan and how long things take.
class Toy:
	var t := 0.0
	var input_at := INF
	var order_at := INF       # pulls into the stand (or the director's scripted order)
	var deliver_s := 75.0
	var pick := 0             # the choice card's button (First10.CHOICE_BUTTONS); 3: the ✕, JUST DRIVE
	var says_no := false      # declines Halina
	var beta_read := 6.0      # how long the beta card stays up (s)
	var job_from := INF       # an extra job of the player's own
	var job_to := INF
	var tape_after := 50.0    # after the tape's arrow, the tape is played (INF: never)
	var scripted := false
	var heli_call_at := INF
	var rescue_ok := true
	var flies_at := INF       # flies the helicopter by themselves at this second
	var flies := true         # flies when the guide says so (the heli intro)
	var takes_rides := true   # takes the ride the guide's intro offers
	var visits := true        # drives into the garage after its intro
	var rider := false        # takes every Łuber request (rides.gd: the next after ride_gap s of free driving)
	var ride_s := 150.0
	var ride_gap := 75.0
	var honour_hold := true   # the rides honour the guide's hold (false: as before the hold)
	var held := false         # set by _play from First10.due (first10.gd `_hold_offers`)
	# the state
	var offer_in := 30.0
	var ride_until := -1.0
	var rides_taken := 0
	var rode := false
	var ride_done := -1.0
	var ride_starts: Array[float] = []
	var ordered := false
	var delivered_t := -1.0
	var busy_until := -1.0
	var calling_until := -1.0
	var raced := false
	var race_end := INF
	var trap := false
	var police_at := INF
	var police := false
	var rang := false
	var rang_at := INF
	var rescued := false
	var rescue_end := INF
	var tape := false
	var tape_at := INF
	var powisle := false
	var garage := false
	var garage_at := INF
	var garage_seen := false
	var earned := false
	var flown := false
	var want: Array[String] = []
	var free_for := 0.0
	var choice_seen := false
	var ways := {}
	var jobs_n := 0
	var jobs_at_intro := 0

	func steps() -> Array[String]:
		return FirstSteps.from_facts({"kebab": delivered_t >= 0.0, "ride": rode, "race": raced, "rescue": rang,
				"heli": flown, "police": police, "garage": garage_seen})

	func facts() -> Dictionary:
		var other := t < busy_until or (t >= job_from and t < job_to) or t < calling_until
		var busy := other or t < ride_until
		return {"input": t >= input_at, "free": not busy, "free_for": free_for,
				"ordered": ordered, "delivered_t": delivered_t,
				"raced": raced, "calling": t < calling_until, "trap": trap, "rang": rang,
				"rescued": rescued, "heli_call": t >= heli_call_at and not rescued, "tape": tape,
				"powisle": powisle, "garage": garage, "earned": earned, "scripted": scripted,
				"steps": steps(), "want": want, "retry_t": 0.0, "ways": ways,
				"jobs_since": jobs_n > jobs_at_intro}

	## The world moves on by itself.
	func step() -> void:
		var free_now: bool = facts()["free"]
		if free_now and choice_seen:
			offer_in -= 0.2
		if held and honour_hold:
			offer_in = maxf(offer_in, 30.0)  # rides.gd HOLD_GAP
		if rider and choice_seen and offer_in <= 0.0 and free_now and not (held and honour_hold):
			_ride()
		if ride_until >= 0.0 and t >= ride_until and ride_until > ride_done:
			ride_done = ride_until
			jobs_n += 1
			rode = true
			earned = true
		if not ordered and t >= order_at:
			ordered = true
			busy_until = t + deliver_s
		if ordered and delivered_t < 0.0 and t >= busy_until:
			delivered_t = t
			jobs_n += 1
			earned = true
		if race_end != INF and t >= race_end and not raced:
			raced = true
			earned = true
		if raced and not trap and t >= race_end + 6.0:
			trap = true  # police.gd arms it FIRST_DELAY s after the race
			police_at = t + 30.0
		if trap and not police and t >= police_at:
			police = true  # the first contact: a stop of 10 s
			busy_until = maxf(busy_until, t + 10.0)
		if not rang and t >= rang_at:
			rang = true
			busy_until = t + 90.0
			rescue_end = t + 90.0
		if rang and not rescued and t >= rescue_end and rescue_ok:
			rescued = true
			jobs_n += 1
			earned = true
		if not tape and t >= tape_at:
			tape = true
			powisle = true  # the boulevards are in Powiśle
		if not garage and t >= garage_at:
			garage = true
			garage_seen = visits
		if not flown and t >= flies_at:
			flown = true

	func _ride() -> void:
		ride_until = t + ride_s
		offer_in = ride_gap
		rides_taken += 1
		ride_starts.append(t)

	## The director fired `id`: what follows in the toy.
	func on_fire(id: String) -> void:
		match id:
			"order":
				order_at = t
			"beta":
				busy_until = maxf(busy_until, t + beta_read)
			"choice":
				choice_seen = true
				for p: String in First10.CHOICE_PICKS[pick]:
					want.append(p)
			"race":
				calling_until = t + (20.0 if says_no else 8.0)
				if not says_no:
					race_end = t + 8.0 + 60.0
					busy_until = race_end
			"trap":
				trap = true
				police_at = t + 30.0
			"rescue":
				rang_at = t + 12.0
			"heli":
				if flies:
					flies_at = minf(flies_at, t + 5.0)
			"tape":
				tape_at = t + tape_after
			"ride":
				if takes_rides:
					_ride()
			"garage":
				garage_at = t + 0.3


## Plays `toy` for `seconds` through the director's rules: [fired (id -> s), how (id -> way)].
func _play(toy: Toy, seconds: float) -> Array:
	var done := {}
	var ways := toy.ways
	while toy.t < seconds:
		toy.step()
		toy.free_for = toy.free_for + STEP if toy.facts()["free"] else 0.0
		var f := toy.facts()
		toy.held = not First10.due(toy.t, f, done).is_empty()
		if not done.has("done"):
			for id in First10.met(f):
				if not done.has(id):
					done[id] = toy.t
					ways[id] = "met"
					toy.want.erase(id)
			for id in First10.decide(toy.t, f, done):
				if not done.has(id):
					done[id] = toy.t
					ways[id] = "fired"
					toy.want.erase(id)
					if id in First10.INTROS or id == "choice":
						toy.jobs_at_intro = toy.jobs_n
					toy.on_fire(id)
		toy.t += STEP
	return [done, ways]


func _at(done: Dictionary, id: String) -> float:
	return float(done.get(id, -1.0))


## The intros fired, in the order they came: [id, second].
func _intro_times(done: Dictionary, ways: Dictionary) -> Array:
	var out: Array = []
	for id: String in First10.INTROS:
		if ways.get(id) == "fired":
			out.append([id, _at(done, id)])
	out.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))
	return out


func _ordinary() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	var r := _play(toy, 1300.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	var bad := First10.judge(done, ways)
	_expect(bad.is_empty(), "the ordinary player: %s" % [bad])
	_expect(ways.get("finger") == "met" and _at(done, "finger") < 2.0, "a touch at 1 s: no finger (%s)" % ways.get("finger"))
	_expect(ways.get("stand") == "fired" and absf(_at(done, "stand") - First10.STAND_AT) < 0.3, "the stand's arrow at 10 s: %.1f" % _at(done, "stand"))
	_expect(ways.get("order") == "met" and absf(_at(done, "order") - 35.0) < 0.3, "the order met at 35 s: %.1f" % _at(done, "order"))
	_expect(not done.has("lure"), "an order taken: the kebab is never let go (%.1f)" % _at(done, "lure"))
	var delivered := 35.0 + toy.deliver_s
	_expect(ways.get("choice") == "fired" and absf(_at(done, "choice") - (delivered + First10.CHOICE_AFTER)) < 0.5,
			"the choice card %.0f s after the delivery: %.1f" % [First10.CHOICE_AFTER, _at(done, "choice")])
	_expect(ways.get("race") == "fired" and _at(done, "race") - _at(done, "choice") < 0.5, "RACE: Halina at once: %.1f" % _at(done, "race"))
	_expect(ways.get("trap") == "met", "the trap armed by the race, not an intro: %s" % ways.get("trap"))
	_expect(ways.get("rescue") == "fired" and ways.get("heli") == "fired" and _at(done, "heli") > _at(done, "rescue") + 90.0,
			"the helicopter after the rescue: %.1f" % _at(done, "heli"))
	_expect(ways.get("powisle") == "met", "Powiśle discovered at the boulevards: %s" % ways.get("powisle"))
	_expect(ways.get("garage") == "fired" and ways.get("kebab") == "met", "the garage an intro, the kebab met: %s %s" % [ways.get("garage"), ways.get("kebab")])
	var seq := _intro_times(done, ways)
	var spaced := true
	for i in range(1, seq.size()):
		if str(seq[i][0]) != "heli":  # the helicopter's toast comes with the rescue, never waits
			spaced = spaced and float(seq[i][1]) - float(seq[i - 1][1]) >= First10.NEXT_GAP - 0.01
	_expect(spaced, "the intros NEXT_GAP s apart at least: %s" % [seq])
	_expect(done.has("done") and _at(done, "done") < 800.0, "the guide ends once every intro came: %.1f" % _at(done, "done"))
	_expect(toy.steps().size() == FirstSteps.IDS.size(), "all seven First steps: %s" % [toy.steps()])
	_summary.append("ordinary %s" % _line(done))


func _wanderer() -> void:
	var toy := Toy.new()
	toy.pick = 3
	toy.says_no = true
	toy.tape_after = INF
	toy.rescue_ok = false
	toy.flies = false
	toy.takes_rides = false
	var r := _play(toy, 1300.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("finger") == "fired" and absf(_at(done, "finger") - First10.FINGER_IDLE) < 0.3, "the finger at 4 s: %.1f" % _at(done, "finger"))
	_expect(ways.get("stand") == "fired" and absf(_at(done, "stand") - First10.STAND_AT) < 0.3, "the arrow at 10 s: %.1f" % _at(done, "stand"))
	_expect(not done.has("order"), "no order without the player (or the replay)")
	# First hour, step 1: the kebab is a lure; at LURE_LATEST its arrow goes, and the free minute
	# before the choice card starts there, as after a delivery.
	_expect(ways.get("lure") == "fired" and absf(_at(done, "lure") - First10.LURE_LATEST) < 0.3, "the kebab let go at 1:30: %.1f" % _at(done, "lure"))
	_expect(ways.get("choice") == "fired" and absf(_at(done, "choice") - (First10.LURE_LATEST + First10.CHOICE_AFTER)) < 0.3,
			"the choice card a free minute after the kebab was let go: %.1f" % _at(done, "choice"))
	_expect(ways.get("race") == "fired" and absf(_at(done, "race") - (_at(done, "choice") + First10.NEXT_GAP)) < 0.5,
			"JUST DRIVE: Halina NEXT_GAP s later, the first intro: %.1f" % _at(done, "race"))
	_expect(ways.get("trap") == "fired" and ways.get("rescue") == "fired" and ways.get("heli") == "fired" and ways.get("ride") == "fired",
			"the trap, the call, the helicopter and the ride all come as intros: %s" % [_intro_times(done, ways)])
	_expect(ways.get("kebab") == "fired", "the stand's arrow once more for a player who never delivered: %s" % ways.get("kebab"))
	_expect(not done.has("garage"), "no earnings: no garage (%.1f)" % _at(done, "garage"))
	_expect(absf(_at(done, "done") - First10.GUIDE_END) < 0.3, "the guide ends at GUIDE_END: %.1f" % _at(done, "done"))
	_summary.append("wanderer %s" % _line(done))


## A player who flew and gave a lift before the guide got there is not told about either.
func _skipper() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	toy.flies_at = 20.0
	toy.pick = 3
	var r := _play(toy, 1300.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("heli") == "met" and _at(done, "heli") < 21.0, "flown at 20 s: the helicopter's intro met, never told: %s %.1f" % [ways.get("heli"), _at(done, "heli")])
	_expect(ways.get("race") == "fired", "the race still comes: %s" % ways.get("race"))
	_summary.append("skipper: heli %s at %.0f" % [ways.get("heli"), _at(done, "heli")])


## The choice card's picks: FLY asks for the helicopter and the tape at once, RIDES for a ride.
func _picks() -> void:
	var fly := Toy.new()
	fly.input_at = 1.0
	fly.order_at = 35.0
	fly.pick = 2
	var r := _play(fly, 600.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	var c := _at(done, "choice")
	var fly_heli := _at(done, "heli")
	_expect(ways.get("heli") == "fired" and _at(done, "heli") - c < 0.5, "FLY: the helicopter at once: %.1f (card %.1f)" % [_at(done, "heli"), c])
	_expect(ways.get("tape") == "fired" and _at(done, "tape") - c < 1.0, "FLY: the tape's arrow right after: %.1f" % _at(done, "tape"))
	_expect(_at(done, "race") >= c + First10.NEXT_GAP, "FLY: Halina later, as an intro: %.1f" % _at(done, "race"))
	var ride := Toy.new()
	ride.input_at = 1.0
	ride.order_at = 35.0
	ride.pick = 1
	r = _play(ride, 600.0)
	done = r[0]
	ways = r[1]
	c = _at(done, "choice")
	_expect(ways.get("ride") == "fired" and _at(done, "ride") - c < 0.5, "RIDES: the first request at once: %.1f (card %.1f)" % [_at(done, "ride"), c])
	_expect(_at(done, "race") >= _at(done, "ride") + ride.ride_s, "RIDES: Halina after the ride: %.1f" % _at(done, "race"))
	# due: the choice holds the offers before it comes; then the intro waiting, once a job was done.
	var f := {"free": true, "free_for": 5.0, "earned": true}
	_expect(First10.due(50.0, f, {"finger": 1.0}) == ["choice"], "before the choice card the guide holds the offers")
	_expect(First10.due(160.0, f, {"choice": 150.0}).is_empty(), "no job since the card: the requests may come")
	f["jobs_since"] = true
	_expect(First10.due(160.0, f, {"choice": 150.0}) == ["race"], "a job done since the card: held for Halina: %s" % [First10.due(160.0, f, {"choice": 150.0})])
	_expect(First10.due(200.0, f, {"done": 900.0}).is_empty(), "nothing held once the guide is over")
	_summary.append("picks: FLY heli %.0f, RIDES ride %.0f" % [fly_heli, _at(done, "ride")])


func _busy() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	toy.pick = 3
	toy.job_from = 115.0  # the card is due 20 s after the first delivery (about 110 s): the job starts before it
	toy.job_to = 330.0
	var r := _play(toy, 1300.0)
	var done: Dictionary = r[0]
	# The beta card came before the job (114 s): the choice card waits BETA_GAP s of free driving after it.
	var due := 330.0 + First10.BETA_GAP
	_expect(_at(done, "beta") < 115.0 and _at(done, "choice") >= due - 0.01 and _at(done, "choice") < due + 1.0,
			"the choice card waits for the job (115-330 s) and BETA_GAP s more: %.1f (beta %.1f)" % [_at(done, "choice"), _at(done, "beta")])
	_expect(_at(done, "race") >= due + First10.NEXT_GAP - 0.01, "the first intro NEXT_GAP s after it: %.1f" % _at(done, "race"))
	_summary.append("busy: the card at %.0f s" % _at(done, "choice"))


## Run 12 (2026-11-03): a player who takes every Łuber request kept the first call waiting
## 83 s past its window. Once a job was done since the last intro the guide holds new requests
## (first10.gd `due`), so a rider meets every intro, with at most one ride between two of them;
## without the hold the rides crowd the intros out (the test means something).
func _rider() -> void:
	var make := func(hold: bool) -> Toy:
		var toy := Toy.new()
		toy.input_at = 1.0
		toy.order_at = 15.0
		toy.deliver_s = 20.0
		toy.rider = true
		toy.pick = 3
		toy.ride_gap = 30.0
		toy.honour_hold = hold
		return toy
	var toy: Toy = make.call(true)
	var r := _play(toy, 1300.0)
	var done: Dictionary = r[0]
	var most := _rides_between(toy, done, r[1])
	var all := true
	for id: String in First10.INTROS:
		all = all and done.has(id) and _at(done, id) < First10.GUIDE_END
	_expect(all, "the rider meets every intro before GUIDE_END: %s" % _line(done))
	_expect(most <= 1, "at most one ride between two intros: %d" % most)
	_expect(toy.rides_taken >= 3, "the rider still gets rides between the intros: %d" % toy.rides_taken)
	var old: Toy = make.call(false)
	var o := _play(old, 1300.0)
	var old_most := _rides_between(old, o[0], o[1])
	var missing := 0
	for id: String in First10.INTROS:
		if not (o[0] as Dictionary).has(id) or _at(o[0], id) >= First10.GUIDE_END:
			missing += 1
	_expect(old_most >= 2 or missing > 0, "without the hold the rides crowd the intros out (the test means something): %d rides between two, %d never" % [old_most, missing])
	_summary.append("rider: %d rides, %s (without the hold: %d rides between two, %d intros never)" % [toy.rides_taken, _line(done), old_most, missing])


## The most rides the toy started between two intros the director made in a row.
func _rides_between(toy: Toy, done: Dictionary, ways: Dictionary) -> int:
	var seq := _intro_times(done, ways)
	var most := 0
	for i in range(1, seq.size()):
		var n := 0
		for at: float in toy.ride_starts:
			if at >= float(seq[i - 1][1]) and at < float(seq[i][1]):
				n += 1
		most = maxi(most, n)
	return most


func _scripted() -> void:
	var toy := Toy.new()
	toy.scripted = true
	var r := _play(toy, 1300.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("order") == "fired" and absf(_at(done, "order") - First10.ORDER_AT) < 0.3, "the replay's order at 15 s: %.1f" % _at(done, "order"))
	var bad := First10.judge(done, ways)
	_expect(bad.is_empty(), "the replay toy (no touch, the order scripted, RACE): %s" % [bad])
	var heli := Toy.new()
	heli.input_at = 1.0
	heli.heli_call_at = 100.0
	var h: Dictionary = _play(heli, 200.0)[0]
	_expect(absf(_at(h, "heli") - 100.0) < 0.3, "a helicopter-only call brings the helicopter's toast at once: %.1f" % _at(h, "heli"))
	_summary.append("replay toy OK")


func _judge() -> void:
	var done := {}
	var ways := {}
	for id: String in First10.BEATS:
		var w: Vector2 = First10.WINDOWS[id]
		done[id] = (w.x + w.y) * 0.5
		ways[id] = "fired"
	_expect(First10.judge(done, ways).is_empty(), "every beat mid-window passes")
	done["race"] = 400.0
	done["tape"] = 50.0
	done.erase("garage")
	var bad := First10.judge(done, ways)
	_expect(bad.size() == 3, "late race, early tape, missing garage: %s" % [bad])
	ways["tape"] = "met"
	_expect(First10.judge(done, ways).size() == 2, "a tape met early is fine")


## The beta card (2026-11-17): BETA_AFTER s after the first delivery, before the choice card; a slow
## reader pushes the choice card to BETA_GAP s of free driving after it. Its words and tiles exist.
func _beta() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	var r := _play(toy, 300.0)
	var done: Dictionary = r[0]
	var delivered := 35.0 + toy.deliver_s
	_expect(absf(_at(done, "beta") - (delivered + First10.BETA_AFTER)) < 0.3, "the beta card %.0f s after the delivery: %.1f" % [First10.BETA_AFTER, _at(done, "beta")])
	_expect(_at(done, "beta") < _at(done, "choice"), "the beta card before the choice card: %.1f %.1f" % [_at(done, "beta"), _at(done, "choice")])
	var slow := Toy.new()
	slow.input_at = 1.0
	slow.order_at = 35.0
	slow.beta_read = 30.0
	r = _play(slow, 300.0)
	done = r[0]
	var shut := _at(done, "beta") + slow.beta_read
	_expect(absf(_at(done, "choice") - (shut + First10.BETA_GAP)) < 0.5, "a slow reader: the choice card BETA_GAP s after the beta card closed: %.1f (closed %.1f)" % [_at(done, "choice"), shut])
	_expect(First10.BETA_AFTER < First10.CHOICE_AFTER and First10.BETA_LATEST < First10.CHOICE_LATEST, "pacing.json: the beta card before the choice card (%.0f < %.0f, %.0f < %.0f)"
			% [First10.BETA_AFTER, First10.CHOICE_AFTER, First10.BETA_LATEST, First10.CHOICE_LATEST])
	var w := First10.beta_words()
	_expect(not "kebab" in str(w["body"][1]).to_lower(), "the beta card without a kebab delivered says nothing of one: %s" % [w["body"]])
	_expect("kebab" in str(First10.beta_words(true)["body"][1]).to_lower(), "... and with one: \"just a kebab\"")
	_expect((w["buttons"] as PackedStringArray).size() == 2, "the beta card: SEE QUESTS and DRIVE ON: %s" % [w["buttons"]])
	for k: String in ["title", "body"]:
		var pair: Array = w[k]
		_expect(str(pair[0]) != "" and str(pair[1]) != "" and str(pair[1]) != "show_" + k, "the beta card's %s has words: %s" % [k, pair])
	for pair: Array in QuestBook.SHOWCASE:
		var words := QuestBook.words(str(pair[1]))
		_expect(str(words[1]) != str(pair[1]), "the tile %s has words (%s)" % [pair[0], pair[1]])
		_expect(QuestBook.ICONS.has(str(pair[0])), "the tile %s has an icon name" % pair[0])
	var tiles := First10.beta_tiles(1.0)
	_expect(tiles.get_child_count() == QuestBook.SHOWCASE.size(), "six tiles under the words: %d" % tiles.get_child_count())
	tiles.free()
	_summary.append("beta card at +%.0f s, %d tiles" % [First10.BETA_AFTER, QuestBook.SHOWCASE.size()])


## The friends' calls during the guide (first10.gd `friends_held`, main.gd `_free_block`).
func _friends() -> void:
	var steps := int(First10.FRIENDS_STEPS)
	_expect(First10.friends_held(0, 60.0, -1.0), "no steps at 1:00: the friends wait")
	_expect(First10.friends_held(steps - 1, First10.FRIENDS_AFTER - 1.0, -1.0), "%d steps just before FRIENDS_AFTER: they wait" % (steps - 1))
	_expect(not First10.friends_held(steps, 200.0, -1.0), "%d steps: the friends may call" % steps)
	_expect(not First10.friends_held(0, First10.FRIENDS_AFTER, -1.0), "FRIENDS_AFTER s with no steps: they may call")
	_expect(First10.friends_held(steps, 400.0, 400.0 - First10.NEW_FRIEND_GAP + 1.0), "a new friend rang lately: the next waits")
	_expect(not First10.friends_held(steps, 400.0, 400.0 - First10.NEW_FRIEND_GAP), "NEW_FRIEND_GAP s after a new friend: the next may ring")
	_expect(First10.friends_held(steps, 400.0, -1.0, true), "an intro waits for its turn: it goes before a friend's call")
	_expect(not First10.friends_held(0, 10.0, -1.0, false, true), "opened in an earlier session: no steps, 10 s in, they may call")
	_expect(First10.FRIENDS_AFTER <= 300.0, "a player who skips the First steps gets calls within 5 minutes (FRIENDS_AFTER %.0f s, F 2026-11-22)" % First10.FRIENDS_AFTER)
	_expect(First10.FRIENDS_YIELD < First10.NEXT_GAP, "a call yields before the intro is due (%.0f < %.0f s)" % [First10.FRIENDS_YIELD, First10.NEXT_GAP])
	_expect(steps == FirstSteps.NOTICED_AT, "the friends open at the third step, the reward's party (%d, %d)" % [steps, FirstSteps.NOTICED_AT])
	_summary.append("friends after %d steps or %.0f s, one new every %.0f s" % [steps, First10.FRIENDS_AFTER, First10.NEW_FRIEND_GAP])


## first_steps.gd: the list, the rewards, an old save's quiet ticks, the rows for the map.
func _steps() -> void:
	_expect(FirstSteps.IDS == ["kebab", "ride", "race", "rescue", "heli", "police", "garage"], "the seven steps: %s" % [FirstSteps.IDS])
	var zl := 0
	var paints: Array = []
	var respect := 0
	for n in range(1, FirstSteps.IDS.size() + 1):
		var r := FirstSteps.reward(n)
		zl += int(r["zl"])
		respect += int(r["respect"])
		if str(r["paint"]) != "":
			paints.append(r["paint"])
		_expect(bool(r["noticed"]) == (n == FirstSteps.NOTICED_AT), "only the third tick opens the friends (%d)" % n)
		_expect(bool(r["card"]) == (n == FirstSteps.IDS.size()), "only the seventh brings the card (%d)" % n)
		_expect(int(r["zl"]) > 0, "every tick pays (%d)" % n)
	_expect(paints == [FirstSteps.NOTICED_PAINT, FirstSteps.ALL_PAINT] and respect == FirstSteps.RESPECT_ALL,
			"a paint at the third and the seventh, %d respect at the seventh: %s %d" % [FirstSteps.RESPECT_ALL, paints, respect])
	const Garage := preload("res://scripts/garage.gd")
	for p: String in paints:
		_expect(not Garage.find(p).is_empty(), "the gift paint %s is one of Mirek's" % p)
	var old := FirstSteps.from_wallet({"kebab": 3, "podwozka": 1, "sloik": 2}, {"halina": 20261101})
	_expect(old == ["kebab", "ride", "race"], "an old save ticks the kebab, the ride and the race quietly: %s" % [old])
	_expect(FirstSteps.from_wallet({}, {}).is_empty(), "a fresh save ticks nothing")
	var intro := {"fs_ride": 130, "fs_heli": 400, "done": 20261115}
	_expect(FirstSteps.done(intro) == ["ride", "heli"] and FirstSteps.count(intro) == 2, "the save's ticks in the list's order")
	_expect(FirstSteps.left(intro).size() == 5 and not "ride" in FirstSteps.left(intro), "the steps left")
	var rows := FirstSteps.rows(intro)
	_expect(rows.size() == 7 and bool(rows[1]["done"]) and int(rows[1]["at"]) == 130 and not bool(rows[0]["done"]), "the rows for the map: %s" % [rows[1]])
	var h := FirstSteps.header(intro)
	_expect(h[0] == "PIERWSZE KROKI 2/7" and h[1] == "First steps 2/7", "the header: %s" % [h])
	_summary.append("first steps: %d zł, paints %s, %d respect" % [zl, paints, respect])


## A stand-in for a traffic driver: the fields race_session.gd `arm_racer` and `pace_tick` set.
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
	var race_boost := 1.0
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
## behind on ladder.gd's gentle day (eased by `ease`) at the race session's effort (`arm_racer`, then
## `pace_tick` 5 times a second, as the game), pulling her race_accel towards her share of a main
## road's racing speed times her effort; `hold`: she waits at the line for the player to move
## (`first_start_step`, PT-11). Returns {lead: the player's lead at the finish in s (< 0: she
## won), time: her seconds from the moment she was let go, wait: her seconds at the line, lo and
## hi: her lowest and highest speed once up to it, as a share of her own straight-line pace}.
func _race(speed: float, stop := 0.0, road := 800.0, late := 0.0, hold := false, ease := 0.0) -> Dictionary:
	var toy := ToyRacer.new()
	var stats := RaceSession.arm_racer(toy, RaceSession.race_stats(0, true, ease), Ladder.pace(0), 30.0, {}, 1)
	var own: float = minf(toy.race_top, Traffic.RACE_CLASS_TOP[0]) * toy.race_share
	var pace := RaceSession.Pace.new()
	var held := false  # F 2026-11-16: she never waits at the line; `hold` is only kept for the callers
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
			RaceSession.pace_tick(pace, toy, float(stats["mistake"]), maxf(her, 0.0), maxf(me, 0.0) if speed > 0.0 else INF)
		var mine := speed if t >= late else 0.0
		if held:
			if Rivals.first_start_step(t, mine) == "release":
				held = false
				wait = t
		if her > 0.0:
			v = move_toward(v, 0.0 if held else own * toy.race_effort, toy.race_accel * dt)
			her -= v * dt
			if not held and v >= own * RaceSession.EFFORT_EASE - 0.01:
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
	var stats := RaceSession.arm_racer(toy, RaceSession.race_stats(0, true, 0.0), Ladder.pace(0), 30.0, {}, 1)
	var own: float = minf(toy.race_top, Traffic.RACE_CLASS_TOP[0]) * toy.race_share
	var pace := RaceSession.Pace.new()
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
			RaceSession.pace_tick(pace, toy, float(stats["mistake"]), her, maxf(me, 0.0) if speed > 0.0 else INF)
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
	_expect(RaceSession.effort_of(0.0) == 1.0 and RaceSession.effort_of(RaceSession.EASE_FROM) == 1.0 and RaceSession.effort_of(-RaceSession.PUSH_FROM) == 1.0,
			"level, just ahead or just behind: her own pace")
	_expect(is_equal_approx(RaceSession.effort_of(RaceSession.EASE_FULL), RaceSession.EFFORT_EASE) and is_equal_approx(RaceSession.effort_of(900.0), RaceSession.EFFORT_EASE),
			"far ahead she eases to EFFORT_EASE and no further: %.2f" % RaceSession.effort_of(900.0))
	_expect(is_equal_approx(RaceSession.effort_of(-RaceSession.PUSH_FULL), RaceSession.EFFORT_PUSH) and is_equal_approx(RaceSession.effort_of(-900.0), RaceSession.EFFORT_PUSH),
			"far behind she pushes to EFFORT_PUSH and no further: %.2f" % RaceSession.effort_of(-900.0))
	var falls := true
	for i in range(-40, 40):
		falls = falls and RaceSession.effort_of(i * 0.5 + 0.5) <= RaceSession.effort_of(i * 0.5) + 0.0001
	_expect(falls, "the further ahead, the less effort (never the other way)")
	_expect(RaceSession.EFFORT_EASE >= 0.85 and RaceSession.EFFORT_PUSH <= 1.1, "the effort stays within a tenth or so: %.2f-%.2f" % [RaceSession.EFFORT_EASE, RaceSession.EFFORT_PUSH])
	_expect(is_equal_approx(RaceSession.own_pace(30.0, 0.65), 30.0 * 0.65 * RaceSession.GAP_PACE) and RaceSession.own_pace(0.0, 0.65) == 5.0, "her seconds come from her own usual speed")
	# The gentle day and the easier rematch (ladder.gd).
	_expect(RaceSession.race_stats(0, true) == Ladder.FIRST_RACER and RaceSession.race_stats(0) == Ladder.racer(0), "the first race drives FIRST_RACER, her rung its own numbers")
	_expect(float(RaceSession.race_stats(0, true, 0.1)["share"]) < float(Ladder.FIRST_RACER["share"]), "an easier rematch is slower")
	# pace_tick: a pushing rival makes more mistakes, and the effort never takes a car past its top.
	var toy := ToyRacer.new()
	RaceSession.arm_racer(toy, RaceSession.race_stats(5, false, 0.0), Ladder.pace(5), 30.0, {}, 1)
	_expect(toy.race_rng != null and toy.race_top == 30.0 and is_equal_approx(toy.race_share, float(Ladder.racer(5)["share"])), "arm_racer: the player's top, the rung's share, its own dice")
	var pace := RaceSession.Pace.new()
	for i in 200:
		RaceSession.pace_tick(pace, toy, 0.1, 2000.0, 1000.0)
	# (Mike drives the road's full speed since step 4a: his push is all in the corners.)
	_expect(toy.race_effort * toy.race_share <= 1.0001 and is_equal_approx(toy.race_corner, RaceSession.EFFORT_PUSH),
			"far behind, Mike pushes through the corners but never past the car's top: %.3f of it, %.2f of his grip" % [toy.race_effort * toy.race_share, toy.race_corner])
	var room := ToyRacer.new()
	RaceSession.arm_racer(room, RaceSession.race_stats(4, false, 0.0), Ladder.pace(4), 30.0, {}, 1)
	var room_pace := RaceSession.Pace.new()
	for i in 200:
		RaceSession.pace_tick(room_pace, room, 0.1, 2000.0, 1000.0)
	_expect(is_equal_approx(room.race_effort, RaceSession.EFFORT_PUSH) and room.race_effort * room.race_share <= 1.0001 and is_equal_approx(room.race_corner, RaceSession.EFFORT_PUSH),
			"far behind, a rival with room under the car's top pushes on the straights too: %.3f of the car's top" % (room.race_effort * room.race_share))
	_expect(is_equal_approx(toy.race_mistake, 0.1 * RaceSession.PUSH_MISTAKES), "pushing: PUSH_MISTAKES times the mistakes: %.3f" % toy.race_mistake)
	# Catch-up (F 2026-11-19): far behind, past the car's top up to its `catch`; never by itself past.
	_expect(is_equal_approx(toy.race_boost, 1.0), "pace_tick with no catch-up asked: no boost (%.2f)" % toy.race_boost)
	var chase := ToyRacer.new()
	RaceSession.arm_racer(chase, RaceSession.race_stats(5, false, 0.0), Ladder.pace(5), 30.0, {}, 1)
	var chase_pace := RaceSession.Pace.new()
	for i in 200:
		RaceSession.pace_tick(chase_pace, chase, 0.1, 2000.0, 1000.0, RaceSession.catch_of(Ladder.racer(5)))
	_expect(is_equal_approx(chase.race_boost, RaceSession.CATCH_MAX) and is_equal_approx(chase.race_corner, RaceSession.EFFORT_PUSH * RaceSession.CATCH_MAX),
			"far behind, a rival speeds up to CATCH_MAX (%.2f) and pushes its grip with it (%.2f; traffic.gd caps it at GRIP_EFFORT_MOST)" % [chase.race_boost, chase.race_corner])
	_expect(is_equal_approx(Traffic.boosted(chase, 30.0), RaceSession.CATCH_TOP) and is_equal_approx(Traffic.boosted(chase, 20.0), 20.0 * RaceSession.CATCH_MAX) and Traffic.boosted(chase, 50.0) == 50.0,
			"the boost goes past the car's top up to CATCH_TOP only: %.1f, %.1f, %.1f" % [Traffic.boosted(chase, 30.0), Traffic.boosted(chase, 20.0), Traffic.boosted(chase, 50.0)])
	for i in 200:
		RaceSession.pace_tick(chase_pace, chase, 0.1, 1000.0 + RaceSession.own_pace(chase.race_top, chase.race_share) * RaceSession.CATCH_FROM * 0.9, 1000.0, RaceSession.catch_of(Ladder.racer(5)))
	_expect(is_equal_approx(chase.race_boost, 1.0), "on the player's tail (within CATCH_FROM s) the boost is gone: %.2f" % chase.race_boost)
	_expect(RaceSession.boost_of(0.0, RaceSession.CATCH_MAX) == 1.0 and RaceSession.boost_of(5.0, RaceSession.CATCH_MAX) == 1.0, "level or ahead: no boost")
	# F's playtest of 2026-11-22 ("Halina's race I did easily"): her gentle day chases as hard as any rival.
	_expect(is_equal_approx(RaceSession.catch_of(Ladder.FIRST_RACER), RaceSession.CATCH_MAX),
			"Halina's gentle day chases like the others: %.2f" % RaceSession.catch_of(Ladder.FIRST_RACER))
	_expect(RaceSession.catch_of(Ladder.racer(0), 0.1) < RaceSession.catch_of(Ladder.racer(0)), "an easier rematch chases less")
	pace = RaceSession.Pace.new()
	for i in 200:
		RaceSession.pace_tick(pace, toy, 0.1, 1000.0, 2000.0)
	_expect(is_equal_approx(toy.race_effort, RaceSession.EFFORT_EASE) and is_equal_approx(toy.race_mistake, 0.1), "far ahead: EFFORT_EASE, her usual mistakes")
	pace = RaceSession.Pace.new()
	RaceSession.pace_tick(pace, toy, 0.1, 1000.0, 2000.0)
	_expect(toy.race_effort >= 1.0 - RaceSession.EFFORT_RATE * 0.2 - 0.0001, "the effort moves slowly (EFFORT_RATE a second), no step")
	pace = RaceSession.Pace.new()
	RaceSession.pace_tick(pace, toy, 0.1, 1000.0, INF)
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
	var fast := _race(26.0)
	var slow := _race(6.0)
	var stops := _race(26.0, 60.0)
	_expect(float(fast["lead"]) > 0.0, "a player faster than her wins: %.1f s" % fast["lead"])
	_expect(float(ordinary["lead"]) < -10.0 and float(slow["lead"]) < float(ordinary["lead"]), "a player at town pace loses, a slower one by more (she does not wait): %.1f s, %.1f s" % [ordinary["lead"], slow["lead"]])
	_expect(float(stops["lead"]) < 0.0, "a fast player who stops for a minute loses: %.1f s" % stops["lead"])
	for r: Dictionary in [ordinary, fast, slow, stops]:
		_expect(float(r["lo"]) >= RaceSession.EFFORT_EASE - 0.011 and float(r["hi"]) <= RaceSession.EFFORT_PUSH + 0.001,
				"once up to speed she holds %.2f to %.2f of her own pace to the line (no crawl, no lift-off): %.2f-%.2f" % [RaceSession.EFFORT_EASE, RaceSession.EFFORT_PUSH, r["lo"], r["hi"]])
	var eased := _race(0.0, 0.0, 800.0, 0.0, false, Ladder.EASE_MAX)
	_expect(float(eased["time"]) > alone * 1.05, "after three losses in a row she is slower: %.1f s against %.1f s" % [eased["time"], alone])
	# PT-11: a new player who sits still after START! (the agent in run 20261102-175913 lost so).
	var late_new := _race(26.0, 0.0, 800.0, 8.0, true)
	var long_s := Rivals.FIRST_HOLD + 8.0
	var long_new := _race(26.0, 0.0, 800.0, long_s, true)
	_expect(float(late_new["wait"]) == 0.0 and float(late_new["lead"]) < float(fast["lead"]),
			"8 s still at the start, she does not wait (F 2026-11-16): waited %.1f s, the player pays for it: %.1f s against %.1f s" % [late_new["wait"], late_new["lead"], fast["lead"]])
	_expect(float(long_new["wait"]) == 0.0 and float(long_new["lead"]) < float(late_new["lead"]),
			"%.0f s still: she is long gone, the player pays for all of it: waited %.1f s, %.1f s" % [long_s, long_new["wait"], long_new["lead"]])
	_expect(Rivals.first_start_step(0.5, 0.0) == "wait", "START! + 0.5 s, still: wait")
	_expect(Rivals.first_start_step(Rivals.FIRST_IDLE + 0.1, 0.5) == "nudge", "still past FIRST_IDLE: the GO nudge")
	_expect(Rivals.first_start_step(1.0, Rivals.FIRST_MOVE + 0.1) == "release", "the player moves: she goes")
	_expect(Rivals.first_start_step(Rivals.FIRST_HOLD, 0.0) == "release", "FIRST_HOLD s: she goes anyway")
	_expect(Rivals.first_stall_due(Rivals.FIRST_STALL, 0, 500.0), "stopped mid-race: the stall nudge")
	_expect(not Rivals.first_stall_due(Rivals.FIRST_STALL - 0.5, 0, 500.0), "a short stop (a red light): no nudge")
	_expect(not Rivals.first_stall_due(Rivals.FIRST_STALL, Rivals.FIRST_STALLS, 500.0), "at most FIRST_STALLS nudges")
	_expect(not Rivals.first_stall_due(60.0, 0, Rivals.FIRST_EASE - 1.0), "the last stretch: no nudge")
	_expect(Rivals.FIRST_GO_BANNER.length() <= 24, "the GO banner fits: %s" % Rivals.FIRST_GO_BANNER)
	_summary.append("start: she never waits at the line: 8 s still, player %+.1f s; %.0f s still, %+.1f s" % [late_new["lead"], long_s, long_new["lead"]])
	_summary.append("first race: her 800 m alone %.1f s, with any player %+.0f to %+.0f %%, %.2f-%.2f of her own pace; a fast player %+.1f s, town pace %+.1f s, a stop %+.1f s" % [
			alone, lows * 100.0, worst * 100.0 if worst > 0.0 else 0.0, minf(float(slow["lo"]), float(stops["lo"])), float(fast["hi"]), fast["lead"], ordinary["lead"], stops["lead"]])


func _words() -> void:
	var lines: Array = []
	for k in First10.LINES:
		lines.append(First10.LINES[k])
	for k in Rivals.FIRST_LINES:
		lines.append(Rivals.FIRST_LINES[k])
	for k: String in ["intro_kebab", "intro_ride", "what_next"]:
		lines.append(FirstSteps.words(k))
	for l: Array in lines:
		_expect(l.size() == 2 and str(l[0]) != "" and str(l[1]) != "" and str(l[0]) != str(l[1]), "Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 70, "at most 70 characters: %s (%d)" % [x, str(x).length()])
	for id: String in FirstSteps.IDS:
		var n: Array = FirstSteps.name_of(id)
		_expect(n.size() == 2 and str(n[0]) != str(n[1]) and str(n[0]).length() <= 40 and str(n[1]).length() <= 40,
				"a First step's line in Polish and English, at most 40 characters: %s" % [n])
		var tw := FirstSteps.tick_words(id, 7)
		_expect(str(tw[0]).length() <= 70 and str(tw[1]).length() <= 70, "the tick's toast at most 70 characters: %s" % [tw])
	for l: Array in [FirstSteps.words("choice_title"), FirstSteps.TITLE, FirstSteps.words("promise"), FirstSteps.words("noticed"),
			FirstSteps.words("all_title")]:
		_expect(l.size() == 2 and str(l[0]) != str(l[1]), "Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 70, "at most 70 characters: %s (%d)" % [x, str(x).length()])
	for l: Array in [FirstSteps.words("all_body")]:
		_expect(l.size() == 2 and str(l[0]) != str(l[1]), "a card's body in Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 110, "a card's body at most 110 characters: %s (%d)" % [x, str(x).length()])
	# The choice card (F's playtest 2026-11-16): every key is in dialogue.json (a missing one reads as its own name),
	# the numbers in the words are the game's (ladder stake and gain, Łuber's base fare, the route's km).
	for k: String in ["choice_title", "choice_body", "choice_race", "choice_ride", "choice_fly", "next_rival", "next_waits", "tick_race"]:
		var w: Array = FirstSteps.words(k)
		_expect(w.size() == 2 and str(w[0]) != k and str(w[1]) != k and str(w[0]) != str(w[1]), "dialogue.json first_steps has %s in both languages: %s" % [k, w])
	var cw := First10.choice_words(0.8)
	var stake := int(Ladder.RUNGS[0]["stake"])
	_expect(cw["title"][0] == "PANI HALINA MRUGA" and cw["title"][1] == "Pani Halina is flashing you", "the choice card's title: %s" % [cw["title"]])
	_expect(cw["body"][0].begins_with("„Do Palmy, kto pierwszy?”") and "0,8 km" in cw["body"][0] and "%d zł" % stake in cw["body"][0]
			and "%d respektu" % Ladder.WIN_GAIN in cw["body"][0], "the Polish body has the route (0,8), the stake and the gain: %s" % cw["body"][0])
	_expect("0.8 km" in cw["body"][1] and "%d zł" % stake in cw["body"][1] and "%d respect." % Ladder.WIN_GAIN in cw["body"][1]
			and "First of six rivals" in cw["body"][1], "the English body: %s" % cw["body"][1])
	_expect(stake == 60 and Ladder.WIN_GAIN == 100, "the reward is 60 zł and 100 respect (the ladder's data)")
	var bs: PackedStringArray = cw["buttons"]
	_expect(bs.size() == 3 and bs[0] == "ŚCIGAJ SIĘ · +%d zł|START RACE · +%d zł" % [stake, stake], "START RACE button: %s" % [bs])
	_expect(bs[1] == "Łuber · od %d zł|Give a lift · from %d zł" % [int(Rules.BASE), int(Rules.BASE)] and int(Rules.BASE) == 15, "the ride chip is from Rules.BASE: %s" % [bs])
	_expect(bs[2] == "Lot · kaseta na dachu BUW|Fly · a mixtape on the BUW roof", "the fly chip names the BUW mixtape: %s" % [bs])
	_expect(First10.choice_words(-1.0)["body"][1].contains("? km"), "an unknown route reads as ? km, never an invented number")
	for l: Array in [cw["body"], cw["title"]]:
		for x in l:
			_expect(str(x).length() <= 110, "the choice card's text at most 110 characters: %s" % x)
	for b: String in [FirstSteps.ALL_BUTTON] + Array(bs):
		_expect(b.get_slice_count("|") == 2 and b.get_slice("|", 0).length() <= 30, "a button's two words: %s" % b)
	# The race's tick names the garage (the next intro); the others keep the plain toast.
	var tr := FirstSteps.tick_words("race", 3, true)
	_expect("garaż" in tr[0] and "garage" in tr[1] and str(tr[0]).length() <= 70 and str(tr[1]).length() <= 70, "the race tick names the garage: %s" % [tr])
	_expect(not "garaż" in FirstSteps.tick_words("race", 3)[0] and not "garaż" in FirstSteps.tick_words("kebab", 1, true)[0], "no other tick names it")
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
