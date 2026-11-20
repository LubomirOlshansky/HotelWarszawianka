extends RefCounted
## The city objects plan, step 1 (docs/design/city-objects-plan.md 3.2, the build plan's item 0 in
## docs/design/drivable-city-build.md): the classes of solid thing a collider face belongs to, and
## the answer the car gets from each. Pure and static: no node, no state but the table read once.
##
## The list lives in ONE place, `game/data/object_palette.json` ("classes": id, answer, note), so
## a class can later move to another answer as data, without code. This script reads it once
## (a static variable, filled when the script loads, on the main thread: the sector builds on the
## streamer's worker only read it) and answers questions about it. map_builder.gd files every
## collider face under a class (`_solid(cls, faces)`, one `StaticBody3D` per class per sector,
## named `Solid_<class>` with `set_meta("solid", cls)`); the dressing scripts' own bodies carry
## the same meta (game/tools/check_solids.gd).
## Step 2 (the wall builder) adds the palette's barrier types ("types": one row per wall, fence,
## hedge, rail and guard rail look; `types`, `type_row`), drawn by city_barriers.gd. W2 of the walls
## look (docs/design/walls-true-to-life.md 6.1) adds the `looks` rows (one per barrier line type
## `ty`; `looks`, `look_row`) and the key that picks between the two, `barrier_look` (classic, the
## `types` rows, by default; `set_barrier_look` for `--barriers=`).
##
## The answers: H hard (the car stops and slides, today's wall), S smash (it breaks, the car goes
## through for a share of its speed), P push (it gives way), R ride (the car drives over it),
## G ghost (no contact). **In step 1 every class answers H**: today's behaviour, nothing moves.
## Step 7: a collider face is always hard; the fences and hedges the bake classed S (`sc`) file no
## faces at all (city_barriers.gd `_is_soft`) and break through soft_things.gd at the costs below, so
## the faces left under `fence` and `hedge` are the hard ones (a hazard behind, a railing, `--no-soft`).
## The research's verdicts (docs/design/drivable-city.md 3, for later steps; nothing reads them):
## building H; lod2 H; small_building H (kiosk-size ones Smash candidates later); fence S (H where
## a drop, a railway or water is behind); hedge S; wall by height (under 0.6 m R, 0.6-1.2 m S,
## over 1.2 m H); stair_wall H; railing H; struct_wall H; tunnel H; portal H; guard_deck H;
## guard_ground H where a drop, water or opposing traffic is behind, else S; pier H; platform R
## (H for rail platforms of 0.9 m); parked P; shelter H; prop by type (stalls S, carts P,
## kiosks H, small monuments G); pocket H; garage_door H; landmark H; edge H.

const PALETTE := "res://data/object_palette.json"
## Hard, Smash, Push, Ride, Ghost.
const ANSWERS := ["H", "S", "P", "R", "G"]

## Step 7 (docs/design/drivable-city-build.md item 3): what a smash costs, read by soft_things.gd.
## The share of the speed a panel takes when the car crosses it, by soft class; at most SMASH_CAP of
## the speed within SMASH_CAP_TIME s however many panels go; grinding along a line (under
## GRIND_ANGLE deg between the car's way and the line) costs GRIND_COST of the speed a second and
## pushes the car out of the line at GRIND_NUDGE m/s. A class not listed costs DEFAULT_SMASH.
const SMASH_COST := {&"fence": 0.06, &"hedge": 0.10}
const DEFAULT_SMASH := 0.06
const SMASH_CAP := 0.15
const SMASH_CAP_TIME := 0.5
const GRIND_ANGLE := 15.0
const GRIND_COST := 0.03
const GRIND_NUDGE := 0.3
## Step 8a (drivable-city-build.md item 4): a parked car pushed, read by soft_things.gd. The player
## keeps 1 - PUSH_LOSS × |cos θ| of the speed going into it (θ between the car's way and the face's
## normal: a quarter lost head-on into its end or square into its side, almost nothing brushing it);
## the parked car takes PUSH_SHARE of the player's speed along that normal, turns PUSH_SPIN rad/s for
## each m/s of it at a corner (less toward the face's middle, at most PUSH_SPIN_MOST), slides with
## PUSH_FRICTION m/s² and stops. A car whose slide is clamped under PUSH_WEDGED m (a wall, a car that
## cannot move) does not give way: the player meets it as a wall.
const PUSH_LOSS := 0.25
const PUSH_SHARE := 0.6
const PUSH_FRICTION := 6.0
const PUSH_SPIN := 0.08
const PUSH_SPIN_MOST := 0.6
const PUSH_WEDGED := 0.5


## Step 7: the share of the speed one crossed panel of class `cls` takes.
static func smash_cost(cls: StringName) -> float:
	return float(SMASH_COST.get(cls, DEFAULT_SMASH))


## Step 8a: the share of its speed the player keeps pushing a parked car, `cos_in` the cosine of the
## angle between its way and the face's normal (1 square on, 0 brushing along it).
static func push_keep(cos_in: float) -> float:
	return 1.0 - PUSH_LOSS * clampf(absf(cos_in), 0.0, 1.0)


## Step 8a: how far a parked car pushed at `speed` m/s slides before it stops (m).
static func push_slide(speed: float) -> float:
	return speed * speed / (2.0 * PUSH_FRICTION)

## {"list": Array[StringName] in the file's order, "answer": {StringName: String},
## "planned": {StringName: String}}.
static var _table: Dictionary = _load()
## Step 2 (the wall builder): the palette's barrier types, {"list": Array[StringName] in the
## file's order, "row": {StringName: Dictionary}}, each row read-only. city_barriers.gd draws them;
## the palette is their one source (no copy of a look in code).
static var _types: Dictionary = _load_types()
## W2 of the walls look (docs/design/walls-true-to-life.md 6.1): the palette's `looks` rows, one
## per barrier line type (`ty`), {"list": Array[StringName], "row": {StringName: Dictionary}},
## each row read-only, and its `barrier_look` key. Read once when the script loads, on the main
## thread (the streamer's worker builds sectors and only reads them).
static var _looks: Dictionary = _load_looks()
## The looks the game knows. W4 (walls doc 6.4): `panels`, typed with the rows marked `panel`
## drawn as instanced 2 m panels (city_barriers.gd `panel_along`, panel.gdshader).
const BARRIER_LOOKS: Array[StringName] = [&"classic", &"typed", &"panels"]
## `set_barrier_look`'s override (`--barriers=`, dev_flags.gd, bake_city.gd, the checks): &"" for
## none, the palette's key then.
static var _look_override := &""


## Every class, in the palette's order (the order map_builder.gd adds its bodies in).
static func classes() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_table["list"])
	return out


## The answer a class gets ("H", "S", "P", "R" or "G"); "" for a class not in the palette.
static func answer(cls: StringName) -> String:
	return str((_table["answer"] as Dictionary).get(cls, ""))


## Step 4: the answer the research plans for a class (the palette's `planned`, drivable-city.md 3),
## for the collider view (collider_view.gd); its `answer` when the row has none.
static func planned(cls: StringName) -> String:
	return str((_table["planned"] as Dictionary).get(cls, answer(cls)))


static func is_known(cls: StringName) -> bool:
	return (_table["answer"] as Dictionary).has(cls)


## Every barrier type's id, in the palette's order (step 2).
static func types() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_types["list"])
	return out


## A barrier type's palette row (read-only: id, family, draw, colour, sizes, ...; the palette's
## "_types" says what each key means), or an empty Dictionary for an id not in the palette.
static func type_row(id: StringName) -> Dictionary:
	return (_types["row"] as Dictionary).get(id, {})


## W2: the look the city's barriers are drawn in: `set_barrier_look`'s override, else the palette's
## `barrier_look` (classic: the `types` rows, today's drawing; typed: the `looks` rows).
static func barrier_look() -> StringName:
	return _look_override if _look_override != &"" else StringName(_looks["key"])


## W2: overrides the palette's look for this run (called before the city is built: dev_flags.gd
## `--barriers=`, bake_city.gd, the checks). A look outside BARRIER_LOOKS is reported and the
## override set to classic.
static func set_barrier_look(look: StringName) -> void:
	if not look in BARRIER_LOOKS:
		push_error("solidity: unknown barrier look %s (one of %s): classic" % [look, BARRIER_LOOKS])
		look = &"classic"
	_look_override = look


## W2: `--barriers=classic|typed|panels` among `args` (a check's or a bake's user arguments) set as the
## override; nothing when it isn't given.
static func barrier_look_from(args: PackedStringArray) -> void:
	for a in args:
		if a.begins_with("--barriers="):
			set_barrier_look(StringName(a.trim_prefix("--barriers=")))


## W2: every `looks` row's id, in the palette's order.
static func looks() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_looks["list"])
	return out


## W2: the `looks` row of barrier line type `ty` (read-only; the palette's "_looks" says what each
## key means), or an empty Dictionary for a type with no row.
static func look_row(ty: StringName) -> Dictionary:
	return (_looks["row"] as Dictionary).get(ty, {})


## W6 of the walls look (walls doc 7): what a broken panel of type `ty` throws, its looks row's
## `debris` ("metal", "wood", "sheet", "leaf"), or "" for a type with no row or no `debris`.
static func debris_of(ty: StringName) -> String:
	return str(look_row(ty).get("debris", ""))


## W6: the colour of debris `kind` (the palette's "debris" table; an unknown kind is metal's).
static func debris_colour(kind: String) -> Color:
	var table: Dictionary = _looks["debris"]
	return Color(str(table.get(kind, table.get("metal", "#3b3f44"))))


## W9 of the walls look (walls doc 6.8): the palette's `marks` table (graffiti, stain, ivy, slogan,
## banner: shares by looks row, sizes and colours; the palette's "_marks" says what each key means).
## Read-only data for wall_marks.gd.
static func marks_table() -> Dictionary:
	return _looks["marks"]


## W2: the palette's looks and its `barrier_look`, checked as `_load_types` checks the types: a row
## without an id or a draw, or an id twice, is reported and left out; a key outside BARRIER_LOOKS
## is reported and read as classic.
static func _load_looks() -> Dictionary:
	var list: Array[StringName] = []
	var rows := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE)) if FileAccess.file_exists(PALETTE) else null
	if not parsed is Dictionary:
		return {"list": list, "row": rows, "key": "classic", "debris": {}, "marks": {}}
	var key := str((parsed as Dictionary).get("barrier_look", "classic"))
	if not StringName(key) in BARRIER_LOOKS:
		push_error("solidity: %s barrier_look %s is not one of %s: classic" % [PALETTE, key, BARRIER_LOOKS])
		key = "classic"
	for row: Variant in (parsed as Dictionary).get("looks", []):
		var id := StringName(str((row as Dictionary).get("id", ""))) if row is Dictionary else &""
		if id == &"" or rows.has(id) or str((row as Dictionary).get("draw", "")) == "":
			push_error("solidity: a bad look row in %s: %s" % [PALETTE, row])
			continue
		(row as Dictionary).make_read_only()
		list.append(id)
		rows[id] = row
	var debris: Variant = (parsed as Dictionary).get("debris", {})
	var marks: Variant = (parsed as Dictionary).get("marks", {})
	return {"list": list, "row": rows, "key": key, "debris": debris if debris is Dictionary else {},
			"marks": marks if marks is Dictionary else {}}


## The palette's types, checked: a row without an id or a draw, or an id twice, is reported
## (push_error) and left out.
static func _load_types() -> Dictionary:
	var list: Array[StringName] = []
	var rows := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE)) if FileAccess.file_exists(PALETTE) else null
	if not parsed is Dictionary or not (parsed as Dictionary).get("types") is Array:
		push_error("solidity: %s is missing or has no \"types\" list" % PALETTE)
		return {"list": list, "row": rows}
	for row: Variant in parsed["types"]:
		var id := StringName(str((row as Dictionary).get("id", ""))) if row is Dictionary else &""
		if id == &"" or rows.has(id) or str((row as Dictionary).get("draw", "")) == "":
			push_error("solidity: a bad type row in %s: %s" % [PALETTE, row])
			continue
		(row as Dictionary).make_read_only()
		list.append(id)
		rows[id] = row
	return {"list": list, "row": rows}


## The palette's classes, checked: a row without an id or with an answer outside ANSWERS, or an
## id twice, is reported (push_error) and left out.
static func _load() -> Dictionary:
	var list: Array[StringName] = []
	var answers := {}
	var plans := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE)) if FileAccess.file_exists(PALETTE) else null
	if not parsed is Dictionary or not (parsed as Dictionary).get("classes") is Array:
		push_error("solidity: %s is missing or has no \"classes\" list" % PALETTE)
		return {"list": list, "answer": answers, "planned": plans}
	for row: Variant in parsed["classes"]:
		var id := StringName(str((row as Dictionary).get("id", ""))) if row is Dictionary else &""
		var ans := str((row as Dictionary).get("answer", "")) if row is Dictionary else ""
		if id == &"" or not ans in ANSWERS or answers.has(id):
			push_error("solidity: a bad class row in %s: %s" % [PALETTE, row])
			continue
		list.append(id)
		answers[id] = ans
		var plan := str((row as Dictionary).get("planned", ans))
		plans[id] = plan if plan in ANSWERS else ans
	return {"list": list, "answer": answers, "planned": plans}
