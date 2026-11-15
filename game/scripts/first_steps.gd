extends RefCounted
## First hour, step 3 (the spec "First hour for the beta", F 2026-11-15; the critique's points 2
## and 3): "Pierwsze kroki · First steps", seven things done in any order, the spine of the first
## hour. Each one ticks once, by itself, whenever the player first does it (first10.gd watches the
## facts five times a second and calls `tick_for`), and pays a small reward; the third tick is a
## small party (a car paint, and the friends' calls may start: "the city has noticed you"); all
## seven give a card, a second paint and RESPECT_ALL respect. The list hangs on one promise
## (PROMISE), shown on the guide's choice card and in the list's header.
##
## The ticks live in the save's [intro] section (wallet.gd `intro`) as "fs_<id>" -> the second of
## the session it was ticked (1 or more), so a tester's "copy my progress" (later) can say what came
## when. A save that already has a kebab, a ride, a race or a rescue behind it ticks those quietly
## at the start (`from_wallet`), with no reward. Pure (no nodes): check_first10.gd tests it.

## The steps, in the order the list shows them.
const IDS := ["kebab", "ride", "race", "rescue", "heli", "police", "garage"]
## Each step's line in the list, [Polish, English] (at most 40 characters).
const NAMES := {
	"kebab": ["Dowieź kebab", "Deliver a kebab"],
	"ride": ["Podwieź kogoś (Podwózka)", "Give a lift (Podwózka)"],
	"race": ["Ścigaj się z rywalem", "Race a rival"],
	"rescue": ["Odbierz wezwanie ratunkowe", "Answer a rescue call"],
	"heli": ["Polataj helikopterem", "Fly the helicopter"],
	"police": ["Spotkaj policję: stań albo uciekaj", "Meet the police: stop or get away"],
	"garage": ["Zajrzyj do warsztatu Mirka", "Visit Mirek's garage"],
}
const TITLE := ["PIERWSZE KROKI", "First steps"]
## The one promise (the critique's point 2, F's yes 2026-11-15 21:02 UTC): what all this is for.
const PROMISE := ["Sześciu rywali. Pokonaj wszystkich i wygraj Trzy mosty.", "Six rivals. Beat them all and win Trzy mosty."]
const KEY := "fs_"
## Every tick pays this much.
const STEP_ZL := 50
## The third tick: a paint, and the friends may start to call (first10.gd `friends_wait`).
const NOTICED_AT := 3
const NOTICED_PAINT := "green"
## All seven: a card, a second paint and this much respect.
const ALL_PAINT := "yellow"
const RESPECT_ALL := 100
const NOTICED_WORDS := ["Miasto cię zauważyło: znajomi zaczną dzwonić. Nowy lakier u Mirka.",
		"The city has noticed you: friends will call. New paint at Mirek's."]
const ALL_TITLE := ["PIERWSZE KROKI ZALICZONE", "First steps done"]
const ALL_BODY := ["Znasz już całe miasto. Lakier „Żółty jak tramwaj” czeka u Mirka, +100 respektu. Teraz szóstka rywali.",
		"You know the whole city now. Tram yellow paint waits at Mirek's, +100 respect. Now the six rivals."]
const ALL_BUTTON := "JEDZIEMY|LET'S GO"


## The steps ticked in the save's [intro] section, in the list's order.
static func done(intro: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in IDS:
		if intro.has(KEY + id):
			out.append(id)
	return out


static func count(intro: Dictionary) -> int:
	return done(intro).size()


## The steps the facts say were done (each fact a bool): kebab (a kebab delivered), ride (a
## Podwózka ride), race (a race with a rival run to its end, won or lost: the critique's point 4),
## rescue (a rescue call answered), heli (in the air once), police (a chase or a pull-over over:
## stopped or got away), garage (Mirek's garage opened).
static func from_facts(f: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in IDS:
		if bool(f.get(id, false)):
			out.append(id)
	return out


## The steps an existing save already shows (its jobs by kind, the ladder), for the quiet ticks at
## the start: `jobs` and `ladder` as wallet.gd keeps them.
static func from_wallet(jobs: Dictionary, ladder: Dictionary) -> Array[String]:
	return from_facts({
		"kebab": int(jobs.get("kebab", 0)) > 0,
		"ride": int(jobs.get("podwozka", 0)) > 0,
		"race": int(jobs.get("race", 0)) > 0 or not ladder.is_empty(),
		"rescue": int(jobs.get("rescue", 0)) > 0,
	})


## What the `n`-th tick (1 to 7) gives: {zl, respect, paint ("" for none), noticed (the third:
## the friends open), card (the seventh)}.
static func reward(n: int) -> Dictionary:
	var out := {"zl": STEP_ZL, "respect": 0, "paint": "", "noticed": false, "card": false}
	if n == NOTICED_AT:
		out["paint"] = NOTICED_PAINT
		out["noticed"] = true
	if n == IDS.size():
		out["paint"] = ALL_PAINT
		out["respect"] = RESPECT_ALL
		out["card"] = true
	return out


## The tick's toast: "✓ Pierwsze kroki 2/7: Podwózka" with the reward, [Polish, English].
static func tick_words(id: String, n: int) -> Array:
	var name: Array = NAMES.get(id, [id, id])
	return ["✓ Pierwsze kroki %d/%d: %s  +%d zł" % [n, IDS.size(), name[0], STEP_ZL],
			"✓ First steps %d/%d: %s  +%d zł" % [n, IDS.size(), name[1], STEP_ZL]]


## The list's header: "PIERWSZE KROKI 2/7" and "First steps 2/7".
static func header(intro: Dictionary) -> Array:
	var n := count(intro)
	return ["%s %d/%d" % [TITLE[0], n, IDS.size()], "%s %d/%d" % [TITLE[1], n, IDS.size()]]


## The list for the map (first hour, step 4 reads it): one row per step, in order, {id, pl, en,
## done, at (the second it was ticked, 0 when not)}.
static func rows(intro: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in IDS:
		var name: Array = NAMES[id]
		out.append({"id": id, "pl": name[0], "en": name[1], "done": intro.has(KEY + id),
				"at": int(intro.get(KEY + id, 0))})
	return out


## The steps not ticked yet, in the list's order.
static func left(intro: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in IDS:
		if not intro.has(KEY + id):
			out.append(id)
	return out
