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
## - **Racing** (docs/design/street-races.md R1/R2/R4, 2026-11-04): in a race the rival drives in
##   traffic.gd's racer mode, not at `pace` × the speed limit: `share` of the player's car top
##   speed (capped by road class; F 2026-11-09, "Halina is far too slow, I drive much faster":
##   every rival's car now reaches the player's top, it was 0.8 for Halina up to 1.0 for Mike),
##   `race_accel` m/s², corners at `lat` m/s² sideways (Halina 8.5, was a timid 6), and a rubber band of strength `band` (rivals.gd
##   `band_mult`; strong at the bottom of the ladder, small at the top) that aims her `aim` m
##   behind the player (> 0: an even drive beats her; < 0: she aims to be in front). `pace` stays as the
##   cruise-time liveliness and the old tests' order.
## - **Human rivals** (F, 2026-11-05: "not competitive, very slow, only by roads, never cut me off"):
##   every rival from Słoik up now aims to LEAD (`aim` < 0: Słoik 5 m in front ... Mike 50 m; Halina
##   15 m behind after her launch: the first rung stays a win for a new player), so the player
##   chases and has to outdrive them, and each has a personality: `cuts` the share of the city's
##   shortcuts it knows (race_cuts.gd: Słoik none, he follows his satnav; Zbyszek all of them),
##   `mistake` the chance of running wide out of a corner near the player (Halina, Bartek),
##   `wrong` wrong turns a race (Słoik), `block` the chance of moving across the player's line
##   when chased (Seba most), `phone` a one-second brake for a call (Mike). Halina's and Słoik's
##   strong band still lets a new player win in the last stretch.
## - **The record** is the wallet's `ladder` (rung id -> the day it was first beaten, yyyymmdd;
##   the save's [ladder] section, wallet.gd). The final's win is `ladder["trzy_mosty"]`
##   (`final_won`), for the end card of the next slice.

const Lang := preload("res://scripts/lang.gd")

## The rungs: id (the save's key), the rival's name as rivals.gd RIVALS has it, the short name for
## the locked prompt, the stake (zł, as RIVALS), the respect it needs, and the race pace.
const RUNGS := [
	{"id": "halina", "rival": "Pani Halina", "short": "HALINA", "stake": 60, "respect": 0, "pace": 1.25, "accel": 1.5,
		"share": 1.0, "race_accel": 9.5, "lat": 8.5, "band": 0.8, "aim": 15.0,
		"cuts": 0.3, "mistake": 0.2, "wrong": 0, "block": 0.0, "phone": false},
	{"id": "sloik", "rival": "Słoik z Radomia", "short": "SŁOIK", "stake": 90, "respect": 100, "pace": 1.3, "accel": 1.55,
		"share": 1.0, "race_accel": 9.0, "lat": 7.0, "band": 0.65, "aim": -5.0,
		"cuts": 0.0, "mistake": 0.12, "wrong": 1, "block": 0.0, "phone": false},
	{"id": "bartek", "rival": "Bulwar Bartek", "short": "BARTEK", "stake": 120, "respect": 220, "pace": 1.35, "accel": 1.6,
		"share": 1.0, "race_accel": 9.5, "lat": 8.5, "band": 0.45, "aim": -25.0,
		"cuts": 0.4, "mistake": 0.2, "wrong": 0, "block": 0.3, "phone": false},
	{"id": "seba", "rival": "Seba z Pragi", "short": "SEBA", "stake": 150, "respect": 340, "pace": 1.4, "accel": 1.65,
		"share": 1.0, "race_accel": 10.5, "lat": 9.0, "band": 0.35, "aim": -35.0,
		"cuts": 0.6, "mistake": 0.08, "wrong": 0, "block": 0.9, "phone": false},
	{"id": "zbyszek", "rival": "Taksiarz Zbyszek", "short": "ZBYSZEK", "stake": 200, "respect": 480, "pace": 1.45, "accel": 1.7,
		"share": 1.0, "race_accel": 11.0, "lat": 9.5, "band": 0.3, "aim": -40.0,
		"cuts": 1.0, "mistake": 0.03, "wrong": 0, "block": 0.4, "phone": false},
	{"id": "mike", "rival": "Mordor Mike", "short": "MIKE", "stake": 300, "respect": 640, "pace": 1.5, "accel": 1.75,
		"share": 1.0, "race_accel": 12.0, "lat": 10.0, "band": 0.25, "aim": -50.0,
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
## Seba's racing in the final (`racer`): near Mike's top, every corner, a small band.
const FINAL_RACER := {"share": 1.0, "race_accel": 12.0, "lat": 10.0, "band": 0.15, "aim": -50.0,
		"cuts": 1.0, "mistake": 0.05, "wrong": 0, "block": 1.0, "phone": false}
## Racing outside the ladder.
const DEFAULT_RACER := {"share": 1.0, "race_accel": 9.0, "lat": 8.0, "band": 0.4, "aim": -20.0,
		"cuts": 0.5, "mistake": 0.1, "wrong": 0, "block": 0.3, "phone": false}
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


## The racer stats of rung `i` (FINAL: the final's; -1: the default): share, race_accel, lat, band,
## aim, and the personality (2026-11-05): cuts, mistake, wrong, block, phone.
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
