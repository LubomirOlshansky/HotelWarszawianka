extends RefCounted
## The phone's contents (F 2026-11-26, "the phone with jobs": a TELEFON chip that stays hidden until
## the first quest is done; it holds the ride app, the side jobs, the quests and the three featured
## quests). Pure, no nodes: main.gd gathers the facts, phone_hub.gd draws what `model` returns, and
## game/tools/check_phone_hub.gd drives it with made-up facts.
##
## Every word is dialogue.json's group "phone_hub" (one line per key, TD-19): the apps' names
## (ŁUBER the ride app, COTAM the messenger) are only there, so a rename is a text change.
##
## Facts: {"can_ride": bool (rides.gd can_request), "busy": bool (something is on: a job, a call),
## "stories": Array of the questline ids that exist, "done": Array of the ones played to the end,
## "jobs_done": int}.
## Model: {"apps": [app], "featured": [row]}, an app {"key", "title": [pl, en], "sub": [pl, en],
## "colour", "enabled": bool}, a row {"id", "title", "sub", "colour", "done": bool, "enabled": bool}.

const DIALOGUE_PATH := "res://data/dialogue.json"
const GROUP := "phone_hub"

## The apps in the order the phone shows them: [key, colour]. "cotam" is the messenger parody's
## inbox, not built yet (parked): its tile shows and says SOON.
const APPS := [["luber", Color("#5fd4ff")], ["jobs", Color("#ffd23f")], ["quests", Color("#ff7a2a")], ["cotam", Color("#8e879e")]]
## The featured quests, in F's order (2026-11-26 11:52): the night meet, Rave na Smolnej, TESŁO.
## [questline id (main.gd `stories.add`), the word key stem, colour].
const FEATURED := [["meet", "f_meet", Color("#5fd4ff")], ["rave", "f_rave", Color("#ff4fd8")], ["tesla", "f_tesla", Color("#5fd38a")]]

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
	var k: Array = ["title", "featured_head", "b_start", "b_open", "b_close", "done", "soon", "busy", "no_ride"]
	for a: Array in APPS:
		k.append("app_" + str(a[0]))
		k.append("app_%s_sub" % a[0])
	for f: Array in FEATURED:
		k.append(str(f[1]))
		k.append("%s_sub" % f[1])
	return k


## The phone for these facts.
static func model(facts: Dictionary) -> Dictionary:
	var busy := bool(facts.get("busy", false))
	var apps: Array = []
	for a: Array in APPS:
		var key := str(a[0])
		var enabled := key != "cotam"
		if key == "luber":
			enabled = bool(facts.get("can_ride", false))
		apps.append({"key": key, "title": words("app_" + key), "sub": _sub(key, facts, enabled),
				"colour": a[1], "enabled": enabled})
	var stories: Array = facts.get("stories", [])
	var done: Array = facts.get("done", [])
	var rows: Array = []
	for f: Array in FEATURED:
		var id := str(f[0])
		if not stories.has(id):
			continue
		var played := done.has(id)
		rows.append({"id": id, "title": words(str(f[1])), "sub": words("%s_sub" % f[1]), "colour": f[2],
				"done": played, "enabled": not busy})
	return {"apps": apps, "featured": rows}


static func _sub(key: String, facts: Dictionary, enabled: bool) -> Array:
	match key:
		"cotam":
			return words("soon")
		"luber":
			return words("app_luber_sub") if enabled else words("no_ride")
		"jobs":
			var n := int(facts.get("jobs_done", 0))
			return [words("app_jobs_sub")[0] + (" · %d" % n if n > 0 else ""), words("app_jobs_sub")[1] + (" · %d" % n if n > 0 else "")]
	return words("app_%s_sub" % key)
