extends RefCounted
## Podwózka story rides (F, 2026-11-07): the passengers who tell a story on the way and ask one
## question (game/data/taxi_stories.json). Pure: the list, which one is next, and when each beat
## is due; rides.gd says the lines, shows the question card and pays the tip; check_rides.gd
## checks this and the data without the city.
##
## A story's beats: its three `lines`, then the `ask` (a side card with two answers), then the
## chosen answer's `reply`. Each beat waits for a share of the way (by straight-line distance,
## so a detour doesn't rush it) or, failing that, for enough seconds, and at least GAP seconds
## after the one before, so a short ride still hears the question and a long one isn't silent.

const PATH := "res://data/taxi_stories.json"
## Of the rides that can have one (not a club, a date or a late Hyrax competitor), how many get a
## story passenger. Most: the stories are the point of the job now; the rest keep the old chat.
const SHARE := 0.8
## The share of the way each beat waits for: lines 1-3, then the question.
const AT := [0.0, 0.16, 0.32, 0.45]
## Or this many seconds into the ride (whichever comes first).
const AT_SECONDS := [3.0, 13.0, 23.0, 32.0]
## The first line waits at least FIRST seconds after boarding; later beats GAP after the last.
const FIRST := 3.0
const GAP := 7.5
## The question card waits this long for an answer; the autopilot answers after AUTO.
const ASK_LIFE := 10.0
const AUTO := 2.0
## No answer: the passenger lets it go.
const SILENT := ["Dobra, patrz na drogę. Ja też popatrzę.", "Fine, eyes on the road. I'll watch it too."]


## The stories from the data file ([] when it is missing or broken).
static func load_all() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return []
	return d.get("stories", [])


## The next story: one not heard yet (`seen`: ids, oldest first), a night-only one only at night;
## when every one has been heard, any but the last few. `forced` (an id) wins. {} when none fits.
static func pick(stories: Array, seen: Array, rng: RandomNumberGenerator, night: bool, forced := "") -> Dictionary:
	if forced != "":
		for s in stories:
			if s["id"] == forced:
				return s
		return {}
	var fits := stories.filter(func(s: Dictionary) -> bool: return night or String(s.get("when", "")) != "night")
	if fits.is_empty():
		return {}
	var fresh := fits.filter(func(s: Dictionary) -> bool: return not seen.has(s["id"]))
	if fresh.is_empty():
		# All heard: not the ones from the last few rides.
		var recent := seen.slice(maxi(0, seen.size() - mini(4, fits.size() - 1)))
		fresh = fits.filter(func(s: Dictionary) -> bool: return not recent.has(s["id"]))
		if fresh.is_empty():
			fresh = fits
	return fresh[rng.randi() % fresh.size()]


## `seen` with `id` heard now (moved to the end), at most `keep` long.
static func heard(seen: Array, id: String, keep := 40) -> Array:
	var out := seen.duplicate()
	out.erase(id)
	out.append(id)
	while out.size() > keep:
		out.pop_front()
	return out


## Is beat `beat` (0-2 the lines, 3 the question) due? `done`: the share of the way driven (0..1),
## `t`: seconds since boarding, `since`: seconds since the last beat was said.
static func due(beat: int, done: float, t: float, since: float) -> bool:
	if beat < 0 or beat >= AT.size():
		return false
	if t < FIRST:
		return false
	if beat > 0 and since < GAP:
		return false
	return done >= float(AT[beat]) or t >= float(AT_SECONDS[beat])
