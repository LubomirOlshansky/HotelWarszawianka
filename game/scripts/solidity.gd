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
##
## The answers: H hard (the car stops and slides, today's wall), S smash (it breaks, the car goes
## through for a share of its speed), P push (it gives way), R ride (the car drives over it),
## G ghost (no contact). **In step 1 every class answers H**: today's behaviour, nothing moves.
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

## {"list": Array[StringName] in the file's order, "answer": {StringName: String}}.
static var _table: Dictionary = _load()


## Every class, in the palette's order (the order map_builder.gd adds its bodies in).
static func classes() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_table["list"])
	return out


## The answer a class gets ("H", "S", "P", "R" or "G"); "" for a class not in the palette.
static func answer(cls: StringName) -> String:
	return str((_table["answer"] as Dictionary).get(cls, ""))


static func is_known(cls: StringName) -> bool:
	return (_table["answer"] as Dictionary).has(cls)


## The palette's classes, checked: a row without an id or with an answer outside ANSWERS, or an
## id twice, is reported (push_error) and left out.
static func _load() -> Dictionary:
	var list: Array[StringName] = []
	var answers := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE)) if FileAccess.file_exists(PALETTE) else null
	if not parsed is Dictionary or not (parsed as Dictionary).get("classes") is Array:
		push_error("solidity: %s is missing or has no \"classes\" list" % PALETTE)
		return {"list": list, "answer": answers}
	for row: Variant in parsed["classes"]:
		var id := StringName(str((row as Dictionary).get("id", ""))) if row is Dictionary else &""
		var ans := str((row as Dictionary).get("answer", "")) if row is Dictionary else ""
		if id == &"" or not ans in ANSWERS or answers.has(id):
			push_error("solidity: a bad class row in %s: %s" % [PALETTE, row])
			continue
		list.append(id)
		answers[id] = ans
	return {"list": list, "answer": answers}
