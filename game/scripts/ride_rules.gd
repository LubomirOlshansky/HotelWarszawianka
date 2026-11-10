extends RefCounted
## Loop 2d-1: Podwózka's numbers as plain rules (docs/design/parodies.md 3.3 with the section 11
## defaults), apart from the scene so tools/check_rides.gd can feed them synthetic events.
##
## One of these lives for each ride (rides.gd): the live star rating starts at 5.0 and loses
## half a star for a hard bump, harsh braking or a fast corner (2 s apart, at most 2.0 in all),
## half a star for each 15 s past the ETA (at most 1.5) and one star for a police pull-over; it
## gains half a star for arriving within 0.8 of the ETA and, with a GPS believer, for driving the
## app's silly leg. The final rating is rounded to the nearest half, 1.0 to 5.0. The statics are
## the pay (15 zł + 9 zł a km, the MNOŻNIK: night ×1.5, rain ×1.2; the tip by stars; the 5-star
## streak), respect, the cancel rule, the player's rating (the last 20 rides, a new save counting
## as 4,87) and the cards' words (Polish over English), which tools/check_hud.gd lays out too.

const Lang := preload("res://scripts/lang.gd")

## The live rating's events (thresholds milder than the słoiki's 16 / 14 m/s²).
const START := 5.0
const DRIVE_STEP := 0.5
const DRIVE_GAP := 2.0
const DRIVE_CAP := 2.0
const BUMP_FREE := 4.0      # closing speed, m/s
const BRAKE_FREE := 18.0    # m/s²
const CORNER_FREE := 15.0   # lateral m/s²
const LATE_EVERY := 15.0
const LATE_STEP := 0.5
const LATE_CAP := 1.5
const POLICE := 1.0
const EARLY := 0.8
const BONUS := 0.5
## ETA = road distance / SPEED + EXTRA (an in-a-hurry passenger: × HURRY_ETA).
const SPEED := 9.0
const EXTRA := 20.0
const HURRY_ETA := 0.8
const HURRY_TIP := 1.2
## The passenger gives up after this many ETAs.
const CANCEL_AFTER := 3.0
## Pay, in złoty.
const BASE := 15.0
const PER_KM := 9.0
const NIGHT := 1.5
const RAIN := 1.2
const STREAK_STEP := 10
const STREAK_CAP := 50
## The player's rating: the last HISTORY rides; the ones a new save hasn't driven count as NEW.
const HISTORY := 20
const NEW := 4.87

var start := START
var clock := 0.0
var eta := 60.0
var drive := 0.0
var late := 0.0
var police := 0.0
var bonus := 0.0
var pulled_over := false
var followed := false
## Loop MW-2 (parodies.md 3.3): a `detour` passenger's Frogs stop (+0.5 once).
var detoured := false
## A story passenger's question answered the way they liked (taxi_stories.json `star`): +0.5 once.
var chatted := false
var early := false
var _drive_at := -INF


## A new ride: the ETA (seconds) and where the live rating starts (--stars=X).
func begin(eta_seconds: float, from := START) -> void:
	eta = maxf(eta_seconds, 1.0)
	start = clampf(from, 1.0, START)
	clock = 0.0
	drive = 0.0
	late = 0.0
	police = 0.0
	bonus = 0.0
	pulled_over = false
	followed = false
	detoured = false
	chatted = false
	early = false
	_drive_at = -INF


## The clock runs; true when lateness just cost another half star.
func tick(dt: float) -> bool:
	clock += dt
	var want := minf(LATE_CAP, LATE_STEP * floorf(maxf(0.0, clock - eta) / LATE_EVERY))
	if want > late:
		late = want
		return true
	return false


## A hard bump ("bump", closing speed m/s), harsh braking ("brake", m/s²) or a fast corner
## ("corner", lateral m/s²); true when it cost half a star (over the limit, 2 s after the last
## one, the 2.0 cap not reached).
func drive_event(kind: String, amount: float) -> bool:
	var limit: float = {"bump": BUMP_FREE, "brake": BRAKE_FREE, "corner": CORNER_FREE}.get(kind, INF)
	if amount <= limit or clock - _drive_at < DRIVE_GAP or drive >= DRIVE_CAP:
		return false
	drive = minf(DRIVE_CAP, drive + DRIVE_STEP)
	_drive_at = clock
	return true


## A police pull-over during the ride (police.md 8.3): one star. Escaping a chase costs nothing.
func pull_over() -> void:
	police += POLICE
	pulled_over = true


## A believer, and the player drove the app's silly leg: half a star, once.
func follow() -> bool:
	if followed:
		return false
	followed = true
	bonus += BONUS
	return true


## Loop MW-2: a `detour` passenger asked for a Frogs and the car stopped at one: half a star, once.
func detour() -> bool:
	if detoured:
		return false
	detoured = true
	bonus += BONUS
	return true


## A story passenger liked the answer (rides.gd, taxi_stories.json): half a star, once.
func chat() -> bool:
	if chatted:
		return false
	chatted = true
	bonus += BONUS
	return true


## At the door: half a star for being early (within EARLY of the ETA).
func arrive() -> bool:
	early = clock <= EARLY * eta
	if early:
		bonus += BONUS
	return early


## The live rating, 1.0 to 5.0 (not rounded).
func stars() -> float:
	return clampf(start - drive - late - police + bonus, 1.0, START)


## The final rating: the nearest half star.
func final() -> float:
	return half(stars())


## The passenger gives up: past CANCEL_AFTER × the ETA.
func overdue() -> bool:
	return clock > CANCEL_AFTER * eta


# --- the statics: pay, streak, respect, rating -------------------------------------------------

static func half(x: float) -> float:
	return clampf(roundf(x * 2.0) / 2.0, 1.0, START)


static func eta_for(road_m: float, hurry := false) -> float:
	return (road_m / SPEED + EXTRA) * (HURRY_ETA if hurry else 1.0)


## The MNOŻNIK: night ×1.5, rain ×1.2, both ×1.8.
static func multiplier(night: bool, rain: bool) -> float:
	return (NIGHT if night else 1.0) * (RAIN if rain else 1.0)


static func tip_share(stars_final: float) -> float:
	if stars_final >= 5.0:
		return 0.40
	if stars_final >= 4.5:
		return 0.25
	if stars_final >= 4.0:
		return 0.10
	return 0.0


static func respect(stars_final: float) -> int:
	if stars_final >= 5.0:
		return 25
	return 10 if stars_final >= 4.0 else 0


## The 5-star streak after a ride: a 5-star ride adds one, a ride below 4.5 or a cancel ends it,
## a 4.5 keeps it as it was.
static func next_streak(streak: int, stars_final: float, cancelled := false) -> int:
	if cancelled or stars_final < 4.5:
		return 0
	return streak + 1 if stars_final >= 5.0 else streak


## What a finished ride pays: {fare, mult, tip, streak (the bonus), total, respect, streak_after}.
## `streak` is the 5-star rides in a row before this one (the first pays no streak bonus).
static func pay(road_m: float, stars_final: float, night: bool, rain: bool, hurry: bool, streak: int, story_tip := 0) -> Dictionary:
	var mult := multiplier(night, rain)
	var fare := roundi((BASE + PER_KM * road_m / 1000.0) * mult)
	var tip := roundi(fare * tip_share(stars_final) * (HURRY_TIP if hurry else 1.0))
	var bonus_zl := mini(STREAK_STEP * streak, STREAK_CAP) if stars_final >= 5.0 else 0
	# A story passenger's extra (taxi_stories.json `tip`; the startup's "investment" is below zero):
	# it can take the tip and the streak away, never the fare.
	var story := maxi(story_tip, -tip - bonus_zl)
	return {"fare": fare, "mult": mult, "tip": tip, "streak": bonus_zl, "story": story, "total": fare + tip + bonus_zl + story,
			"respect": respect(stars_final), "streak_after": next_streak(streak, stars_final)}


## The player's rating: the average of the last HISTORY rides, the missing ones counted as NEW.
static func rating(history: Array) -> float:
	var n := mini(history.size(), HISTORY)
	var sum := NEW * (HISTORY - n)
	for i in range(history.size() - n, history.size()):
		sum += float(history[i])
	return sum / HISTORY


## The history with one more ride, the oldest dropped past HISTORY.
static func pushed(history: Array, stars_final: float) -> Array:
	var out := history.duplicate()
	out.append(stars_final)
	while out.size() > HISTORY:
		out.pop_front()
	return out


# --- words (Polish above English) --------------------------------------------------------------

## 4.5 -> "4,5" (Polish) or "4.5"; `places` decimals.
static func num(x: float, places := 1, polish := true) -> String:
	var text := ("%." + str(places) + "f") % x
	return text.replace(".", ",") if polish else text


## "★★★★½ 4,5": the stars in the HUD font (no ★ in the pixel font), rounded to the half.
static func stars_text(x: float, polish := true) -> String:
	var r := half(x)
	var full := floori(r)
	return "★".repeat(full) + ("½" if r - full >= 0.5 else "") + " " + num(r, 1, polish)


## "×1,5 · NOC" / "×1.5 · night": the MNOŻNIK line's tail, "" when there is none.
static func surge_text(night: bool, rain: bool, polish := true) -> String:
	if not night and not rain:
		return ""
	var why := PackedStringArray()
	if night:
		why.append("NOC" if polish else "night")
	if rain:
		why.append("DESZCZ" if polish else "rain")
	return "×%s · %s" % [num(multiplier(night, rain), 1, polish), " + ".join(why)]


static func km(metres: float, polish := true) -> String:
	return num(metres / 1000.0, 1, polish) + " km"


## The request card: [title, body, title_en, body_en]. `o`: name, away (m to the pin), road (m of
## ride), their (the passenger's stars), note ([pl, en] from podwozka_request), night, rain,
## rating (the player's; on the result card, not here). It stands beside the car (hud.gd
## show_side_card), so it is short: the MNOŻNIK in the title, the numbers once in the Polish,
## the English a gloss of the note.
static func offer_text(o: Dictionary) -> Array:
	var note: Array = o.get("note", [])
	var surge_pl := surge_text(o["night"], o["rain"], true)
	var surge_en := surge_text(o["night"], o["rain"], false)
	var mult := multiplier(o["night"], o["rain"])
	var body := "%s ★ %s · %d m · %s" % [o["name"], num(o["their"]), roundi(o["away"]), km(o["road"])]
	if not note.is_empty():
		body += "\n" + String(note[0])
	var body_en := "%s ★ %s · %d m · %s" % [o["name"], num(o["their"], 1, false), roundi(o["away"]), km(o["road"], false)]
	if not note.is_empty():
		body_en += "\n" + String(note[1])
	var title := ("PODWÓZKA · MNOŻNIK ×" + num(mult)) if surge_pl != "" else "PODWÓZKA · NOWY KURS"
	return [title, body, ("New ride · surge " + surge_en) if surge_en != "" else "New ride", body_en]


## The result card: [title, body, title_en, body_en]. `r`: stars, name, comment ([pl, en] from
## podwozka_rating), pay (from pay()), rating (the player's, after), why ([pl, en]: what moved the
## stars, may be empty). Short, beside the car; the wallet under the minimap shows the money and
## the English glosses the comment.
static func result_text(r: Dictionary) -> Array:
	var p: Dictionary = r["pay"]
	var comment: Array = r.get("comment", [])
	var why: Array = r.get("why", ["", ""])
	var mult := float(p["mult"])
	var money := "%d zł: kurs %d%s + napiwek %d%s" % [p["total"], p["fare"], (" (×%s)" % num(mult)) if mult > 1.0 else "",
			p["tip"], (" + seria %d" % p["streak"]) if int(p["streak"]) > 0 else ""]
	var story := int(p.get("story", 0))
	if story != 0:
		money += (" + rozmowa %d" % story) if story > 0 else (" − inwestycja %d" % -story)
	# "Marta: …" (the comments carry their own „quotes”, so none round them).
	var body := ("%s: %s\n" % [r.get("name", "Pasażer"), comment[0]] if not comment.is_empty() else "") + "%s\nOcena %s%s" % [money,
			num(r["rating"], 2), (" · " + String(why[0])) if String(why[0]) != "" else ""]
	var body_en := ("%s " % comment[1] if not comment.is_empty() else "") + "%d zł." % p["total"]
	return ["KURS · " + stars_text(r["stars"]), body, "Ride done", body_en]
