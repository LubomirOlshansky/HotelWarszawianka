extends Node
## Loop MW-1 (docs/design/vision.md 4.1): MOJA WARSZAWA, the city notebook. The 72 places of
## `data/places.json` (designer-owned: 9 chapters of 8), each found by passing it slowly, by
## stopping in it, or from the helicopter flying low, and kept in the save (wallet.gd `notes`).
##
## - **Where a place is.** No bake gives the places map metres yet (that is the map lane's
##   follow-up: `pois` kind `place` from the 3d bake, BACKLOG "From loop MW-1"), so each place
##   is resolved once at load (`resolve`): its `near` [lat, lon] hint (about ±150 m) projected
##   with the bake's own flat projection (tools/bake_osm.py `project`: the map's `origin`,
##   110 574 m a degree of latitude, 111 320 · cos(lat0) of longitude), then, preferred, a
##   point of the map that carries the place's address (the `address` pois: street and number)
##   or its name (a named square, park or landmark; never for a parody venue), or a map poi
##   of its own kind (the Mermaid, Patelnia, Plac Defilad, the stadium; the kebab stands),
##   within reach of the hint.
## - **Finding** (`finds`): within `radius` at ≤ 30 km/h, or stopped inside it for 1 s; in the
##   helicopter within `heli_radius` (60 m when the place has none) below 60 m over the ground.
##   Checked twice a second over a 100 m grid of the places (`CELL`): a tick looks at the one
##   cell the vehicle is in, so nothing runs per frame but a timer.
## - **Rewards**: +5 respect a card; a chapter complete +50 zł and +30 respect once (the
##   wallet's `pay`), recorded in the save; loop MW-5: `chapter_done` then opens the next
##   locked PÓŁNOC FM track (radio.gd `sync_chapters`, wired in main.gd).
## - **On the minimap**: the places not found yet within MINI_REACH m of the car as "?"
##   (the PLACE layer of map_markers.gd, read by hud.gd); never their names.
## The page in the settings card is notebook_page.gd.

## Loop MW-5: a chapter's last card was found (its id); main.gd opens a PÓŁNOC FM track.
signal chapter_done(chapter_id: String)

const MapMarkers := preload("res://scripts/map_markers.gd")
const Lang := preload("res://scripts/lang.gd")
const Access := preload("res://scripts/access.gd")
const PLACES_PATH := "res://data/places.json"
## The bake's flat projection (tools/bake_osm.py): metres a degree.
const M_PER_DEG_LAT := 110574.0
const M_PER_DEG_LON_EQUATOR := 111320.0
## Seconds between two finding checks (2 Hz).
const CHECK_EVERY := 0.5
## The finding grid's cell, metres.
const CELL := 100.0
## Finding: slow enough (km/h), stopped (km/h) and for how long (s).
const SLOW_KMH := 30.0
const STOP_KMH := 1.0
const STOP_S := 1.0
## The helicopter: the reach when a place has no `heli_radius`, and the highest it may fly (m
## over the ground).
const HELI_RADIUS := 60.0
const HELI_ALT := 60.0
## The minimap's "?": undiscovered places within this many metres of the car; loop 3h slice 1 adds
## the discovered districts' own "?" marks wherever they are (`extra_marks`, districts.gd).
const MINI_REACH := 400.0
const CARD_RESPECT := 5
const CHAPTER_ZL := 50
const CHAPTER_RESPECT := 30
## How far from the hint a matching address, name or poi may be (m).
const ADDRESS_REACH := 600.0
const NAME_REACH := 600.0
const KIND_REACH := 300.0
## A place whose own kind of poi the map has (the special pois eggs.gd uses).
const POI_KIND := {"syrenka": "syrenka", "patelnia": "patelnia", "plac_defilad": "defilad",
		"stadion_narodowy": "stadium"}
## The chapters' size since loop MW-0 (vision.md 4.1: 9 chapters of 8). Map north (2026-10-31):
## a chapter may hold up to MAX_PER_CHAPTER (Rondo Radosława, Arkadia and Forest went into three
## of them as a ninth card); the counts shown are the chapter's own size (chapter_places).
const PER_CHAPTER := 8
const MAX_PER_CHAPTER := 10

## The chapters in the notebook's order: {id, name_pl, name_en}.
var chapters: Array = []
## Every place: places.json's fields plus `at` (Vector2, map x, z), `source` ("address",
## "name", "poi" or "near"), `off` (metres from the hint) and `chapter_i`.
var places: Array[Dictionary] = []
var by_id := {}
## The wallet (wallet.gd): `notes` (id -> yyyymmdd) and `chapters_done` (chapter id -> yyyymmdd).
var wallet: Node
var hud: CanvasLayer
## Called at each check: [position Vector3, speed km/h, flying, metres over the ground, away
## (the title, the bench: nothing is found)].
var probe: Callable
## The UI sound (main.gd's blip) for a new entry.
var blip: Callable
## --notes-log: a `notes:` line per find.
var log_on := false
## Time spent in the checks since the bench last read it (µs).
var spent_usec := 0
## Loaded and placed.
var ready_ok := false

var _grid := {}
var _t := 0.0
var _still := {}
var _unknown := PackedVector2Array()
## Loop 3h slice 1: more "?" marks (map points) beyond MINI_REACH: districts.gd `marks`, the
## discovered districts' first three places not found yet.
var extra_marks: Callable


## Reads places.json (no map: the UI and the checks that need no positions). False if missing.
func load_places() -> bool:
	if not FileAccess.file_exists(PLACES_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_PATH))
	if not json is Dictionary:
		push_error("notebook: %s does not parse" % PLACES_PATH)
		return false
	chapters = json.get("chapters", [])
	var order := {}
	for i in chapters.size():
		order[str(chapters[i]["id"])] = i
	places.clear()
	by_id.clear()
	for p: Dictionary in json.get("places", []):
		var place := p.duplicate(true)
		place["chapter_i"] = int(order.get(str(p.get("chapter", "")), 0))
		place["at"] = Vector2.INF
		place["source"] = ""
		place["off"] = 0.0
		by_id[str(p["id"])] = places.size()
		places.append(place)
	return true


## Loads the places and puts each on the map (`data`: the map's data, index.json's or
## centrum.json's: origin, pois, landmarks); builds the finding grid. `say`: one line per place.
func setup(data: Dictionary, say := false) -> bool:
	var t0 := Time.get_ticks_usec()
	if not load_places():
		return false
	var index := build_index(data)
	var counts := {}
	var worst: Array = []
	for place in places:
		var r := resolve(place, data.get("origin", [52.234, 21.024]), index)
		place["at"] = r["at"]
		place["source"] = r["source"]
		place["off"] = r["off"]
		counts[r["source"]] = int(counts.get(r["source"], 0)) + 1
		if say:
			print("notes: place %s %s %.0f m from the hint (%.0f, %.0f)" % [place["id"], r["source"], r["off"], r["at"].x, r["at"].y])
		worst.append([float(r["off"]), str(place["id"])])
	worst.sort()
	worst.reverse()
	_build_grid()
	ready_ok = true
	var far := PackedStringArray()
	for w in worst.slice(0, 3):
		far.append("%s %.0f m" % [w[1], w[0]])
	print("notes: %d places (%s), furthest from the hint %s, in %.1f ms" % [places.size(), counts,
			", ".join(far), (Time.get_ticks_usec() - t0) / 1000.0])
	return true


# --- where a place is ----------------------------------------------------------------------

## The bake's flat projection: [lat, lon] to map x (east), z (south), from `origin` [lat0, lon0].
static func project(origin: Array, lat: float, lon: float) -> Vector2:
	var lat0 := float(origin[0])
	var lon0 := float(origin[1])
	return Vector2((lon - lon0) * M_PER_DEG_LON_EQUATOR * cos(deg_to_rad(lat0)), (lat0 - lat) * M_PER_DEG_LAT)


## Lower case, dots as spaces, single spaces ("Al. Jerozolimskie" -> "al jerozolimskie").
static func norm(s: String) -> String:
	var out := s.to_lower().replace(".", " ").replace(" ", " ")
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


## "Nowy Świat 22/28 (the gate)" -> ["nowy świat", "22/28"]; [] if it has no number.
static func split_address(s: String) -> Array:
	var cut := s
	var paren := cut.find("(")
	if paren >= 0:
		cut = cut.substr(0, paren)
	cut = cut.strip_edges()
	var space := cut.rfind(" ")
	if space <= 0:
		return []
	var num := cut.substr(space + 1).to_lower()
	if num.is_empty() or not num[0].is_valid_int():
		return []
	return [norm(cut.substr(0, space)), num]


## The map's points to match places against, once: {"addr": {number: [[street, Vector2]]},
## "named": {name: [Vector2]}, "kind": {poi kind: [Vector2]}}.
static func build_index(data: Dictionary) -> Dictionary:
	var addr := {}
	var named := {}
	var kind := {}
	for p: Dictionary in data.get("pois", []):
		var at := Vector2(float(p["x"]), float(p["z"]))
		var k := str(p.get("k", ""))
		var n: String = str(p["name"]) if p.get("name") != null else ""
		if k == "address":
			var sa := split_address(n)
			if sa.is_empty():
				continue
			var keys := PackedStringArray([sa[1]])
			keys.append_array(str(sa[1]).split("/"))
			for key in keys:
				if not addr.has(key):
					addr[key] = []
				addr[key].append([sa[0], at])
			continue
		if not kind.has(k):
			kind[k] = []
		kind[k].append(at)
		if n != "":
			_add_named(named, norm(n), at)
	for l: Dictionary in data.get("landmarks", []):
		var pts: Array = l.get("p", [])
		if pts.size() < 2 or str(l.get("name", "")) == "":
			continue
		var c := Vector2.ZERO
		for i in range(0, pts.size() - 1, 2):
			c += Vector2(float(pts[i]), float(pts[i + 1]))
		_add_named(named, norm(str(l["name"])), c / float(pts.size() / 2))
	return {"addr": addr, "named": named, "kind": kind}


static func _add_named(named: Dictionary, n: String, at: Vector2) -> void:
	if not named.has(n):
		named[n] = []
	named[n].append(at)


## Where `place` is: {at: Vector2, source, off (m from the hint)}. The address first (same
## number, the street's last word the same: "Al. Jerozolimskie 6" finds "Aleje Jerozolimskie
## 6"), then the name (exact, or a landmark's name that starts with it: "Pałac Kultury i
## Nauki"; never for a parody venue or a street), then a poi of the place's own kind, else the hint.
static func resolve(place: Dictionary, origin: Array, index: Dictionary) -> Dictionary:
	var near: Array = place.get("near", [0.0, 0.0])
	var hint := project(origin, float(near[0]), float(near[1]))
	var best := Vector2.INF
	var best_d := INF
	var source := "near"
	if place.has("address"):
		var sa := split_address(str(place["address"]))
		if not sa.is_empty():
			var last: String = str(sa[0]).get_slice(" ", str(sa[0]).get_slice_count(" ") - 1)
			var keys := PackedStringArray([sa[1]])
			keys.append_array(str(sa[1]).split("/"))
			for key in keys:
				for e: Array in index["addr"].get(key, []):
					var street: String = e[0]
					if street.get_slice(" ", street.get_slice_count(" ") - 1) != last:
						continue
					var d := hint.distance_to(e[1])
					if d < ADDRESS_REACH and d < best_d:
						best = e[1]
						best_d = d
						source = "address"
				if best != Vector2.INF:
					break
	var tags: Array = place.get("tags", [])
	# A street is a line, not a point: its name finds a building on it (Nowy Świat 568 m off).
	if best == Vector2.INF and not "venue" in tags and not "street" in tags:
		var want := norm(str(place.get("name_pl", "")))
		for n: String in index["named"]:
			if n != want and not (n.begins_with(want + " ") and want.length() >= 6):
				continue
			for at: Vector2 in index["named"][n]:
				var d := hint.distance_to(at)
				if d < NAME_REACH and d < best_d:
					best = at
					best_d = d
					source = "name"
	if best == Vector2.INF:
		var kinds: Array[String] = []
		if POI_KIND.has(str(place["id"])):
			kinds.append(POI_KIND[str(place["id"])])
		if "kebab" in tags:
			kinds.append("kebab")
		for k in kinds:
			for at: Vector2 in index["kind"].get(k, []):
				var d := hint.distance_to(at)
				if d < KIND_REACH and d < best_d:
					best = at
					best_d = d
					source = "poi"
	if best == Vector2.INF:
		return {"at": hint, "source": "near", "off": 0.0}
	return {"at": best, "source": source, "off": best_d}


# --- finding -------------------------------------------------------------------------------

## The finding rule (vision.md 4.1). Car: within `radius` at ≤ SLOW_KMH, or stopped inside for
## STOP_S. Helicopter: within `heli_radius` (HELI_RADIUS if 0) under HELI_ALT m over the ground.
static func finds(dist: float, kmh: float, still_s: float, flying: bool, altitude: float, radius: float,
		heli_radius: float) -> bool:
	if flying:
		return altitude < HELI_ALT and dist <= (heli_radius if heli_radius > 0.0 else HELI_RADIUS)
	return dist <= radius and (kmh <= SLOW_KMH or still_s >= STOP_S)


## The reach of a place for the grid: the larger of the car's and the helicopter's.
static func reach(place: Dictionary) -> float:
	return maxf(float(place.get("radius", 25.0)), float(place.get("heli_radius", HELI_RADIUS)))


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func _build_grid() -> void:
	_grid.clear()
	for i in places.size():
		var at: Vector2 = places[i]["at"]
		var r := reach(places[i])
		var a := _cell(at - Vector2(r, r))
		var b := _cell(at + Vector2(r, r))
		for x in range(a.x, b.x + 1):
			for z in range(a.y, b.y + 1):
				var key := Vector2i(x, z)
				if not _grid.has(key):
					_grid[key] = []
				_grid[key].append(i)


func _process(dt: float) -> void:
	if not ready_ok or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	var step := _t
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	var s: Array = probe.call()
	tick(s[0], float(s[1]), bool(s[2]), float(s[3]), bool(s[4]), step)
	spent_usec += Time.get_ticks_usec() - t0


## One check: `pos` the vehicle, `kmh` its speed, `step` seconds since the last check.
func tick(pos: Vector3, kmh: float, flying: bool, altitude: float, away: bool, step: float) -> void:
	if away:
		return
	var p := Vector2(pos.x, pos.z)
	var cell := _cell(p)
	if _grid.has(cell):
		for i: int in _grid[cell]:
			var place := places[i]
			var id := str(place["id"])
			if is_found(id):
				continue
			var d := p.distance_to(place["at"])
			var radius := float(place.get("radius", 25.0))
			if not flying and d <= radius and kmh < STOP_KMH:
				_still[id] = float(_still.get(id, 0.0)) + step
			else:
				_still.erase(id)
			if finds(d, kmh, float(_still.get(id, 0.0)), flying, altitude, radius, float(place.get("heli_radius", 0.0))):
				record(id)
	_update_minimap(p)


## The "?" marks: places not found yet within MINI_REACH m (72 distance checks, 2 Hz).
func _update_minimap(p: Vector2) -> void:
	if hud == null:
		return
	var marks := PackedVector2Array()
	for place in places:
		var at: Vector2 = place["at"]
		if at.distance_squared_to(p) < MINI_REACH * MINI_REACH and not is_found(str(place["id"])):
			marks.append(at)
	if extra_marks.is_valid():
		for at: Vector2 in extra_marks.call():
			if at.distance_squared_to(p) >= MINI_REACH * MINI_REACH:
				marks.append(at)
	if marks != _unknown:
		_unknown = marks
		# The "?" marks on the minimap (map_markers.gd, TD-13; the rule table keeps them off the
		# full map).
		var put: Array[Dictionary] = []
		for at: Vector2 in marks:
			put.append({"layer": MapMarkers.Layer.PLACE, "at": at})
		hud.markers.put_all("notebook", put)


# --- the record ----------------------------------------------------------------------------

func is_found(id: String) -> bool:
	return wallet != null and wallet.notes.has(id)


## Found places of chapter `ci` (its index).
func found_in(ci: int) -> int:
	var n := 0
	for place in places:
		if int(place["chapter_i"]) == ci and is_found(str(place["id"])):
			n += 1
	return n


func found_total() -> int:
	var n := 0
	for place in places:
		if is_found(str(place["id"])):
			n += 1
	return n


## The places of chapter `ci`, in the file's order.
func chapter_places(ci: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for place in places:
		if int(place["chapter_i"]) == ci:
			out.append(place)
	return out


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


## "30.10.2026" from yyyymmdd.
static func date_text(ymd: int) -> String:
	return "%02d.%02d.%04d" % [ymd % 100, (ymd / 100) % 100, ymd / 10000]


## A place found for the first time: the save, +5 respect, the toast, the sound, the buzz; a
## chapter complete pays +50 zł and +30 respect once. False if it was in the notebook already.
func record(id: String, date := 0) -> bool:
	if wallet == null or not by_id.has(id) or is_found(id):
		return false
	var place := places[by_id[id]]
	var ci := int(place["chapter_i"])
	wallet.notes[id] = date if date > 0 else today()
	wallet.pay(0, CARD_RESPECT)
	var k := found_in(ci)
	var chapter: Dictionary = chapters[ci] if ci < chapters.size() else {"id": "", "name_pl": "", "name_en": ""}
	if log_on:
		print("notes: found %s (chapter %d, %d/%d)" % [id, ci + 1, k, chapter_places(ci).size()])
	if hud != null:
		hud.toast("NOWY WPIS · %s" % place["name_pl"], "NEW ENTRY · %s · %d/%d" % [place["name_en"], k, chapter_places(ci).size()])
	if blip.is_valid():
		blip.call()
	Access.buzz(25, 0.3)
	var cid := str(chapter["id"])
	if k >= chapter_places(ci).size() and not wallet.chapters_done.has(cid):
		wallet.chapters_done[cid] = wallet.notes[id]
		wallet.pay(CHAPTER_ZL, CHAPTER_RESPECT)
		if log_on:
			print("notes: chapter %d (%s) complete: +%d zł, +%d respect" % [ci + 1, cid, CHAPTER_ZL, CHAPTER_RESPECT])
		if hud != null:
			hud.show_note(Lang.pick("ROZDZIAŁ GOTOWY", "CHAPTER DONE"), "%s: +%d zł, +%d ★" % [Lang.pick(chapter["name_pl"], chapter["name_en"]),
					CHAPTER_ZL, CHAPTER_RESPECT], Color("#f0b429"))
		chapter_done.emit(cid)
	if hud != null:
		hud.notebook_changed()
	return true


## --found=all|none|<chapter>[:k],...: the record for a test run, in memory (no rewards, nothing
## written by itself; use with --nosave). A chapter is its id or its number 1-9; `:k` its first
## k places.
func preset(spec: String) -> void:
	if wallet == null:
		return
	for part in spec.split(",", false):
		if part == "none":
			wallet.notes.clear()
			wallet.chapters_done.clear()
			continue
		var bits := part.split(":")
		var ci := -1
		var upto := 99
		if bits[0] != "all":
			for i in chapters.size():
				if str(chapters[i]["id"]) == bits[0] or str(i + 1) == bits[0]:
					ci = i
			if ci < 0:
				push_warning("notebook: --found=%s: no chapter %s" % [spec, bits[0]])
				continue
		if bits.size() > 1:
			upto = int(bits[1])
		for i in chapters.size():
			if ci >= 0 and i != ci:
				continue
			var list := chapter_places(i)
			for k in mini(upto, list.size()):
				wallet.notes[str(list[k]["id"])] = today()
			if found_in(i) >= list.size():
				wallet.chapters_done[str(chapters[i]["id"])] = today()
	print("notes: --found=%s: %d/%d in the notebook" % [spec, found_total(), places.size()])
