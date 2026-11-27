extends RefCounted
## The phone's contents (F 2026-11-26, "the phone with jobs"; redesigned 2026-11-27: a compact portrait
## phone with four apps; ŁUBER and GŁODNO search and offer inside it, QUESTS opens the big screen).
## Pure, no nodes: phone.gd gathers the facts, phone_hub.gd draws what `model` returns, and
## game/tools/check_phone_hub.gd drives it with made-up facts.
##
## Every word is dialogue.json's group "phone_hub" (one line per key, TD-19): the apps' names
## (ŁUBER the ride app, GŁODNO the food-delivery app, COTAM the messenger) are only there, so a rename
## is a text change.
##
## Facts: {"can_ride": bool (rides.gd can_request), "busy": bool (something is on: a job, a call),
## "jobs_done": int}.
## Model: {"apps": [app]}, an app {"key", "title": [pl, en], "sub": [pl, en], "colour", "enabled": bool}.

const DIALOGUE_PATH := "res://data/dialogue.json"
const GROUP := "phone_hub"

## The apps in the order the phone shows them: [key, colour, kind]. "cotam" is the messenger parody
## (F 2026-11-27: it is the feedback form, a message to the author). kind: "offer" an app that searches
## and offers inside the phone, "screen" opens the big QUESTS screen, "form" opens the feedback card
## (feedback.gd), "soon" does nothing yet (no app is "soon" now; the kind stays for the next one).
const APPS := [["luber", Color("#5fd4ff"), "offer"], ["glodno", Color("#ff4fd8"), "offer"],
		["quests", Color("#ff7a2a"), "screen"], ["cotam", Color("#2fd36b"), "form"]]
## The food-delivery app's places: the side-job groups (main.gd `_quest_entries`) it offers.
const FOOD_GROUPS := ["kebab"]
## Seconds the "looking for…" screen is up before an offer (or nothing) shows.
const SEARCH_S := 1.4

static var _words := {}


## [Polish, English] for one key of the "phone_hub" group ([key, key] when missing).
static func words(key: String) -> Array:
	if _words.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_PATH)) if FileAccess.file_exists(DIALOGUE_PATH) else null
		var lines: Variant = d.get(GROUP, []) if d is Dictionary else []
		for l: Variant in lines:
			if l is Array and l.size() >= 3 and l[2] is Dictionary and l[2].has("only"):
				_words[str(l[2]["only"])] = [str(l[0]), str(l[1])]
	return _words.get(key, [key, key])


## Every key the model and the view ask for (check_phone_hub.gd checks them against the file).
static func keys() -> Array:
	var k: Array = ["title", "b_close", "b_back", "b_take", "b_skip", "soon", "busy", "no_ride", "searching",
			"none_luber", "none_glodno", "offer_glodno", "offer_glodno_sub"]
	for a: Array in APPS:
		k.append("app_" + str(a[0]))
		k.append("app_%s_sub" % a[0])
	return k


## What an app does when tapped: "offer", "screen", "form" or "soon" ("" for an unknown key).
static func kind(key: String) -> String:
	for a: Array in APPS:
		if str(a[0]) == key:
			return str(a[2])
	return ""


## The phone's home for these facts.
static func model(facts: Dictionary) -> Dictionary:
	var busy := bool(facts.get("busy", false))
	var apps: Array = []
	for a: Array in APPS:
		var key := str(a[0])
		var enabled := str(a[2]) != "soon"
		if key == "luber":
			enabled = bool(facts.get("can_ride", false))
		elif key == "glodno":
			enabled = not busy
		apps.append({"key": key, "title": words("app_" + key), "sub": _sub(key, facts, enabled),
				"colour": a[1], "enabled": enabled})
	return {"apps": apps}


static func _sub(key: String, facts: Dictionary, enabled: bool) -> Array:
	match key:
		"luber":
			return words("app_luber_sub") if enabled else words("no_ride")
		"glodno":
			return words("app_glodno_sub") if enabled else words("busy")
		"quests":
			var n := int(facts.get("jobs_done", 0))
			var w := words("app_quests_sub")
			return [str(w[0]) + (" · %d" % n if n > 0 else ""), str(w[1]) + (" · %d" % n if n > 0 else "")]
	return words("app_%s_sub" % key)


## The food app's offer from the side-job places (main.gd `_quest_entries` entries: id, group, pl, en,
## at, colour), the nearest to `from` of FOOD_GROUPS; {} when none. {"entry", "who": "", "title", "body"
## ([pl, en]), "colour"}; `far_text` is quest_lines.gd's distance ([pl, en]).
static func food_offer(entries: Array, from: Vector2, far_text: Array) -> Dictionary:
	var best := {}
	var best_d := INF
	for e: Dictionary in entries:
		if not FOOD_GROUPS.has(str(e.get("group", ""))):
			continue
		var at: Vector2 = e["at"]
		if at == Vector2.INF:
			continue
		var d := from.distance_to(at)
		if d < best_d:
			best_d = d
			best = e
	if best.is_empty():
		return {}
	var name_pl := str(best["pl"])
	var name_en := str(best["en"])
	var t := words("offer_glodno")
	var sub := words("offer_glodno_sub")
	return {"entry": best, "who": "", "colour": best["colour"], "title": t,
			"body": [name_pl + " · " + str(far_text[0]) + "\n" + str(sub[0]), name_en + " · " + str(far_text[1]) + "\n" + str(sub[1])]}
