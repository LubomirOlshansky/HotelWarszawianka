extends RefCounted
## Loop 3h slice 3 (docs/DEMO.md 6.3 "Rival ladder", "Progression"): the rival ladder. Six rungs in
## order of stake, then the final race "Trzy mosty" (rivals.gd races them; this script only keeps
## the order, the gating and the record, so check_ladder.gd tests it without the map).
##
## - A rung is **open** when the rung before it is beaten AND the respect is at least its
##   threshold (`RUNGS[i].respect`; the first needs neither). A beaten rung stays open (beaten
##   rivals are re-raced as before, the stake paid again). The final (`FINAL`, index 6) needs the
##   sixth rung beaten and FINAL_RESPECT.
## - A rung's first race win gives +100 respect (WIN_GAIN; a rematch +20), so the thresholds (0, 100, 220, 340, 480, 640, 850; the main line
##   retune of 2026-10-31, docs/design/main-line.md: about 250 respect from side quests in all, the
##   final within the first hour; it was 0/100/250/400/600/850/1100, ~500) pull the
##   jobs, the districts and the Syrenki in between the rungs.
## - **Pace**: each rung's rival races at its own speed (`pace`: the traffic driver's
##   speed_factor, `accel`: its accel_factor), rising up the ladder from Halina's 1.25 to Mike's
##   1.5 (the races were a flat 1.45 before loop 3h).
## - **Racing: difficulty from skill** (docs/design/race-ai.md 6, 2026-11-10; F 2026-11-09: "she
##   was still going very slow, and like the mob, not behave like real racer and competitive").
##   In a race the rival drives in traffic.gd's racer mode, not at `pace` × the speed limit. Every
##   rival has the player's own car (its top speed); what differs is how much of it the rival
##   uses, and that is fixed for the race: `share` of the road's racing speed on a straight
##   (traffic.gd RACE_CLASS_TOP under the car's top), `race_accel` m/s² off the line and out of a
##   corner, `brake` m/s² into one (a low number brakes early), `lat` m/s² sideways through it.
##   `lat` is the pull the racer's own line asks of the car (race_line.gd, step 4a, 2026-11-12:
##   the turn of every 8 m of the line it drives; the player's car holds 19 m/s², race_bench.gd
##   PLAYER_GRIP). Before the line a corner's speed came from the lane graph's own curve, the
##   same number was worth about twice the pull and nothing held a bend in the middle of a
##   street (77 m/s² measured on Książęca); the numbers were set again with the line so that
##   each rival keeps its time.
##   Halina is steady and slow in the corners, Słoik quick on the straights and lost once a race
##   (his wrong turn is in his time), Mike uses nearly all of the car, and the six run from about
##   100 s to 72 s over the bench's 1.75 km (tools/race_bench.sh; its Skill ladder mark holds the
##   order of the times, not of any one number). Nothing here reads the player's speed or place:
##   the rubber band that did (`band`, `aim`: a rival's speed as a mix of its own and the
##   player's) made Halina crawl at 0.3 of her pace in front of a waiting player, and is gone.
##   What is left of "closeness" is rivals.gd `effort_of`: a rival far in front eases to
##   EFFORT_EASE of its own pace, one behind pushes a little, by the time gap alone. `pace` stays
##   as the cruise-time liveliness and the old tests' order.
## - **Racing: the streets it takes** (docs/design/race-ai.md 5, 2026-11-10; the friend's point 5:
##   "Pani Halina could be surprisingly competitive because she knows the city extremely well").
##   A rival plans its way by the seconds each street costs it (race_planner.gd), and two numbers
##   say what it counts: `knows`, the share of the town's traffic it reckons with (Halina and
##   Zbyszek the taxi driver all of it; Słoik none, he plans as if the roads were empty), and
##   `caution`, how much more a one-lane one-way street with no way past a slow car costs it in
##   traffic (Halina goes round, Seba goes in). On clear roads neither changes anything.
## - **Halina's gentle day** (FIRST_RACER, `gentle`): the guided first race, and every race
##   against her until the player has beaten her once. The easiest drive in the game, but a real
##   one: she holds her own pace whatever the player does (parked question 1 in docs/QUESTIONS.md:
##   a player who stops loses and races her again). On her rung's own numbers she drives only
##   once she has been beaten: the rematches.
## - **An easier rematch** (`ease_of`, parked question 2): a rival the player has just lost to
##   drives EASE_STEP slower for each loss in a row, EASE_MAX at most, and a win puts it back. It
##   changes between races, never during one (`lost_streak`, the save's [keep]).
## - **Human rivals** (F, 2026-11-05: "not competitive, very slow, only by roads, never cut me off"):
##   each has a personality: `cuts` the share of the city's shortcuts it knows (race_cuts.gd: Słoik
##   none, he follows his satnav; Zbyszek all of them), `mistake` the chance of running wide out
##   of a corner near the player (Halina, Bartek; more when it pushes), `wrong` wrong turns a race
##   (Słoik), `block` the chance of moving across the player's line when chased (Seba most),
##   `phone` a one-second brake for a call (Mike).
## - **The record** is the wallet's `ladder` (rung id -> the day it was first beaten, yyyymmdd;
##   the save's [ladder] section, wallet.gd). The final's win is `ladder["trzy_mosty"]`
##   (`final_won`), for the end card of the next slice.

const Lang := preload("res://scripts/lang.gd")

## The rungs: id (the save's key), the rival's name as rivals.gd RIVALS has it, the short name for
## the locked prompt, the stake (zł, as RIVALS), the respect it needs, and the race pace.
const RUNGS := [
	{"id": "halina", "rival": "Pani Halina", "short": "HALINA", "stake": 60, "respect": 0, "pace": 1.25, "accel": 1.5,
		"share": 0.70, "race_accel": 8.0, "brake": 4.5, "lat": 10.0, "knows": 1.0, "caution": 0.8,
		"cuts": 0.3, "mistake": 0.2, "wrong": 0, "block": 0.0, "phone": false},
	{"id": "sloik", "rival": "Słoik z Radomia", "short": "SŁOIK", "stake": 90, "respect": 100, "pace": 1.3, "accel": 1.55,
		"share": 0.92, "race_accel": 9.5, "brake": 8.0, "lat": 11.0, "knows": 0.0, "caution": 0.5,
		"cuts": 0.0, "mistake": 0.12, "wrong": 1, "block": 0.0, "phone": false},
	{"id": "bartek", "rival": "Bulwar Bartek", "short": "BARTEK", "stake": 120, "respect": 220, "pace": 1.35, "accel": 1.6,
		"share": 0.80, "race_accel": 10.5, "brake": 9.0, "lat": 12.0, "knows": 0.5, "caution": 0.3,
		"cuts": 0.4, "mistake": 0.2, "wrong": 0, "block": 0.3, "phone": false},
	{"id": "seba", "rival": "Seba z Pragi", "short": "SEBA", "stake": 150, "respect": 340, "pace": 1.4, "accel": 1.65,
		"share": 0.86, "race_accel": 12.0, "brake": 13.0, "lat": 15.0, "knows": 0.7, "caution": 0.0,
		"cuts": 0.6, "mistake": 0.08, "wrong": 0, "block": 0.9, "phone": false},
	{"id": "zbyszek", "rival": "Taksiarz Zbyszek", "short": "ZBYSZEK", "stake": 200, "respect": 480, "pace": 1.45, "accel": 1.7,
		"share": 0.93, "race_accel": 12.5, "brake": 12.0, "lat": 15.5, "knows": 1.0, "caution": 0.2,
		"cuts": 1.0, "mistake": 0.03, "wrong": 0, "block": 0.4, "phone": false},
	{"id": "mike", "rival": "Mordor Mike", "short": "MIKE", "stake": 300, "respect": 640, "pace": 1.5, "accel": 1.75,
		"share": 1.0, "race_accel": 13.5, "brake": 13.0, "lat": 16.5, "knows": 0.4, "caution": 0.1,
		"cuts": 0.5, "mistake": 0.05, "wrong": 0, "block": 0.3, "phone": true},
]
## The final race: index RUNGS.size() (6) everywhere a rung index is asked for.
const FINAL := 6
const FINAL_ID := "trzy_mosty"
const FINAL_RESPECT := 850
## The final's pay: złoty and respect (the first win and every rematch alike).
const FINAL_ZL := 500
const FINAL_GAIN := 250
## Race respect (the designer pass, 2026-11-01, docs/design/pay-tables.md): a rung's first win
## gives WIN_GAIN, a rematch of a beaten rival (or a race the ladder doesn't count) REMATCH_GAIN, so
## re-racing Halina (+100 in about four minutes) is no shortcut past the gates; the stake is paid
## every time. The final's rematches give REMATCH_GAIN too.
const WIN_GAIN := 100
const REMATCH_GAIN := 20
## Seba's pace in the final (a long race: the same as Zbyszek's, a bit under Mike's).
const FINAL_PACE := 1.45
const FINAL_ACCEL := 1.7
## Seba's racing in the final (`racer`): his own late brakes and grip with nearly Mike's
## straights, every shortcut, always blocking.
const FINAL_RACER := {"share": 0.98, "race_accel": 13.0, "brake": 12.5, "lat": 16.0, "knows": 1.0, "caution": 0.0,
		"cuts": 1.0, "mistake": 0.05, "wrong": 0, "block": 1.0, "phone": false}
## Racing outside the ladder: a middling driver (between Bartek and Seba).
const DEFAULT_RACER := {"share": 0.82, "race_accel": 10.5, "brake": 9.0, "lat": 12.5, "knows": 0.6, "caution": 0.3,
		"cuts": 0.5, "mistake": 0.1, "wrong": 0, "block": 0.3, "phone": false}
## Halina on a gentle day: the guided first race (rivals.gd `call_first`) and every race against
## her until she has been beaten once (`gentle`). Gentler than on her rung, and as steady.
const FIRST_RACER := {"share": 0.65, "race_accel": 7.0, "brake": 4.0, "lat": 9.5, "knows": 1.0, "caution": 1.0,
		"cuts": 0.3, "mistake": 0.2, "wrong": 0, "block": 0.0, "phone": false}
## An easier rematch: each race lost in a row to a rival makes it this much slower the next time
## (the straights and the corners), up to EASE_MAX; the streak's key in the save's [keep].
const EASE_STEP := 0.05
const EASE_MAX := 0.15
const LOST_KEY := "race_lost_"
## No racer, eased or not, holds less than this share of the road's racing speed on a straight:
## times the least effort (rivals.gd EFFORT_EASE) it stays over half the road's speed, the race
## bench's crawl line (race_bench.gd CRAWL_SHARE; check_ladder.gd holds the three together).
const SHARE_MIN := 0.58
## The pace of a race outside the ladder (no wallet, an unknown rival): the old flat one.
const DEFAULT_PACE := 1.45
const DEFAULT_ACCEL := 1.7

## wallet.gd (its `ladder` and `respect`); null: nothing is beaten, respect 0.
var wallet: Node


## The rung of rival `name` (RIVALS' name), or -1.
static func rung_of(name: String) -> int:
	for i in RUNGS.size():
		if RUNGS[i]["rival"] == name:
			return i
	return -1


## The respect rung `i` needs (FINAL: FINAL_RESPECT).
static func threshold(i: int) -> int:
	return FINAL_RESPECT if i == FINAL else int(RUNGS[i]["respect"])


## The respect a won race on rung `i` gives: WIN_GAIN (FINAL_GAIN for the final) when `first` (the
## rung's first win, or a race outside the ladder), REMATCH_GAIN for a rematch.
static func race_gain(i: int, first: bool) -> int:
	if not first:
		return REMATCH_GAIN
	return FINAL_GAIN if i == FINAL else WIN_GAIN


## The save's key of rung `i`.
static func id_of(i: int) -> String:
	return FINAL_ID if i == FINAL else str(RUNGS[i]["id"])


## The racer stats of rung `i` (FINAL: the final's; -1: the default): the skill (share,
## race_accel, brake, lat), the streets it takes (knows, caution) and the personality
## (2026-11-05): cuts, mistake, wrong, block, phone.
static func racer(i: int) -> Dictionary:
	if i == FINAL:
		return FINAL_RACER
	if i < 0 or i >= RUNGS.size():
		return DEFAULT_RACER
	var r: Dictionary = RUNGS[i]
	var out := {}
	for k in DEFAULT_RACER:
		out[k] = r[k]
	return out


## How much slower a rival drives after `losses` races lost to it in a row (0 .. EASE_MAX).
static func ease_of(losses: int) -> float:
	return minf(maxi(losses, 0) * EASE_STEP, EASE_MAX)


## Racer stats `stats` eased by `ease` (`ease_of`): that much slower on the straights and through
## the corners (a corner's speed goes with the root of the grip). The pull and the braking stay.
static func eased(stats: Dictionary, ease: float) -> Dictionary:
	if ease <= 0.0:
		return stats
	var out := stats.duplicate()
	out["share"] = maxf(float(stats["share"]) * (1.0 - ease), minf(float(stats["share"]), SHARE_MIN))
	out["lat"] = float(stats["lat"]) * (1.0 - ease) * (1.0 - ease)
	return out


## [speed_factor, accel_factor] for rung `i` (FINAL: the final's; -1: the default).
static func pace(i: int) -> Vector2:
	if i == FINAL:
		return Vector2(FINAL_PACE, FINAL_ACCEL)
	if i < 0 or i >= RUNGS.size():
		return Vector2(DEFAULT_PACE, DEFAULT_ACCEL)
	return Vector2(float(RUNGS[i]["pace"]), float(RUNGS[i]["accel"]))


func respect() -> int:
	return int(wallet.respect) if wallet != null else 0


func beaten(i: int) -> bool:
	return wallet != null and i >= 0 and i <= FINAL and wallet.ladder.has(id_of(i))


func final_won() -> bool:
	return beaten(FINAL)


## Rung `i`'s rival drives its gentle day (FIRST_RACER): Pani Halina, the first rung, until the
## player has beaten her once. So a new player who loses the guided first race meets the same
## gentle driver again (and an easier one, `ease_of`), never a faster one.
func gentle(i: int) -> bool:
	return i == 0 and not beaten(0)


## The races lost in a row to rung `i` (FINAL: the final), for the easier rematch (`ease_of`).
func lost_streak(i: int) -> int:
	if wallet == null or i < 0 or i > FINAL:
		return 0
	return int(wallet.keep.get(LOST_KEY + id_of(i), 0))


## A race against rung `i` was driven to its end: a loss adds to the streak, a win ends it.
func note_result(i: int, won: bool) -> void:
	if wallet == null or i < 0 or i > FINAL:
		return
	var key := LOST_KEY + id_of(i)
	if won:
		if not wallet.keep.has(key):
			return
		wallet.keep.erase(key)
	else:
		wallet.keep[key] = lost_streak(i) + 1
	wallet.save()


## Rung `i` (0..FINAL) can be raced now.
func is_open(i: int) -> bool:
	if i < 0 or i > FINAL:
		return false
	if beaten(i):
		return true
	if i > 0 and not beaten(i - 1):
		return false
	return respect() >= threshold(i)


## What rung `i` is waiting for, [Polish, English] ("NAJPIERW HALINA" / "beat Pani Halina first",
## "SZACUNEK 220" / "respect 220"), or ["", ""] when it is open.
func missing(i: int) -> PackedStringArray:
	if is_open(i):
		return PackedStringArray(["", ""])
	if i > 0 and not beaten(i - 1):
		return PackedStringArray(["NAJPIERW %s" % RUNGS[i - 1]["short"], "beat %s first" % RUNGS[i - 1]["rival"]])
	return PackedStringArray(["SZACUNEK %d" % threshold(i), "respect %d" % threshold(i)])


## The first rung not beaten yet (FINAL when only the final is left; FINAL + 1 when it is won).
func next_rung() -> int:
	for i in FINAL + 1:
		if not beaten(i):
			return i
	return FINAL + 1


## How many rungs are open, the final included (it only grows: respect and wins never go away).
func open_count() -> int:
	var n := 0
	for i in FINAL + 1:
		if is_open(i):
			n += 1
	return n


## Marks rung `i` beaten on day `date` (yyyymmdd) and saves; true the first time. A locked rung
## (a race started by --race=N) is not counted: the ladder keeps its order.
func win(i: int, date := 1) -> bool:
	if wallet == null or i < 0 or i > FINAL or beaten(i) or not is_open(i):
		return false
	wallet.ladder[id_of(i)] = maxi(1, date)
	wallet.save()
	return true


## --ladder=N: the first N rungs beaten (N = 7: the final too), the respect raised to open the
## next one, in memory (use with --nosave).
func preset(n: int, date := 1) -> void:
	if wallet == null:
		return
	wallet.ladder.clear()
	for i in clampi(n, 0, FINAL + 1):
		wallet.ladder[id_of(i)] = maxi(1, date)
	var need := threshold(mini(n, FINAL))
	if wallet.respect < need:
		wallet.respect = need


## The ladder as rows for the full map's card: [text, state] where state is "won", "next" or
## "locked" (`night`: it is night now, for the final's "w nocy · at night").
func rows(night: bool) -> Array:
	var out: Array = []
	var nxt := next_rung()
	for i in RUNGS.size():
		var r: Dictionary = RUNGS[i]
		var text := "%s · %d zł" % [r["rival"], r["stake"]]
		if beaten(i):
			out.append(["★ " + text, "won"])
		elif i == nxt:
			out.append(["→ %s · %s" % [text, Lang.pick("otwarty", "open") if is_open(i) else "%s %d" % [Lang.pick("szacunek", "respect"), threshold(i)]], "next"])
		else:
			out.append(["· " + text, "locked"])
	var fin := Lang.pick("Finał · Trzy mosty · %d zł", "Final · Three Bridges · %d zł") % FINAL_ZL
	if final_won():
		out.append(["★ " + fin, "won"])
	elif nxt == FINAL:
		if not is_open(FINAL):
			out.append(["→ %s · %s %d" % [fin, Lang.pick("szacunek", "respect"), FINAL_RESPECT], "next"])
		elif night:
			out.append(["→ %s · Rondo Daszyńskiego" % fin, "next"])
		else:
			out.append(["→ %s · %s" % [fin, Lang.pick("w nocy", "at night")], "next"])
	else:
		out.append(["· " + fin + " · " + Lang.pick("w nocy", "at night"), "locked"])
	return out
