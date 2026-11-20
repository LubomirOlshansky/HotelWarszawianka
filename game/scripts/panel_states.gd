extends RefCounted
## W6 of the walls look (docs/design/walls-true-to-life.md 6.4 and 7): the broken panels shown. The
## only writer of a panel's state. soft_things.gd owns the events and the memory (`broke`,
## `repaired`, `is_broken`); this shows them on the sectors' `Panels` MultiMeshes (W4: under the
## `panels` look only; map_builder.gd `_build_panels`), in the instance custom data's third float,
## which panel.gdshader reads: 0 whole, 1 down, 2 torn, 3 stub, 4 gap, 5 boards (W5), by the line's
## looks row's `broken` (the row is the custom data's first float, its place in Solidity.looks()).
## W5: `flat` (hoarding) lies down as `down` does, the face the car saw (the banner's) up; `gap`
## draws nothing of the panel; a wood row's gap (`debris` wood) is its two boards on the ground, the
## box laid down as a fallen panel's.
##
## - `on_broke(id, panel, kind, at, direction, speed)` (main.gd connects soft_things.broke): the
##   line's pieces with that panel index, in the loaded `Panels` round `at` (the root's "panels"
##   meta: per line its id, first instance and pieces, every instance's panel index), get their
##   state; a `down` piece also its transform, the box laid flat on the ground on the far side of the
##   hit (the side `direction` points to), turned up to ASKEW_DEG by a hash of the line and panel.
## - `on_repaired(id, panel)` (soft_things.repaired: rule B, `repair_near`, `reset`, the soft switch
##   off): the pieces' baked transform and custom data back, float for float.
## - `add_sector(root)` (main.gd `_on_sector_ready`, and the whole city's map on --monolithic):
##   its `Panels` (or the whole city's `Panels_i_j`) noted; when something is broken, each line of
##   its meta with a broken panel here (one dictionary lookup a line) is asked of
##   soft_things.is_broken piece by piece and shown again, so a panel broken, driven away from and
##   back to is still down.
##
## The baked buffer: a tile's MultiMesh buffer is read once, on the first write there (a sector
## loaded fresh is whole), and kept until the tile leaves. On a RenderingDevice (Mobile, the phone)
## the read is asynchronous (`buffer_get_data_async` on the MultiMesh's own buffer: a synchronous
## read stalls the GPU, about 1 to 2 ms on the cloud's software renderer): the tile's writes wait for
## it, two frames, behind the debris; each write is then one instance's floats sent into that buffer
## (`buffer_update`, a few µs). Elsewhere (the Compatibility renderer, a headless run) the buffer is
## read at once and written through the MultiMesh (set_instance_transform, set_instance_custom_data).
## With nothing broken nothing is read or written; under `classic` and `typed` there is no `Panels`,
## so nothing at all happens. No node, no per-frame work.

const Solidity := preload("res://scripts/solidity.gd")
const PanelRule := preload("res://scripts/panel_rule.gd")

## The custom data's states (panel.gdshader).
const WHOLE := 0.0
const DOWN := 1.0
const TORN := 2.0
const STUB := 3.0
const GAP := 4.0
const BOARDS := 5.0
## A looks row's `broken` -> the state its panels take (walls doc 7: `flat` lies down like `down`;
## W5: `gap` its own state, BOARDS for a wood row's; `none` and `notch` are not panels' looks).
const STATE_OF := {"down": DOWN, "flat": DOWN, "torn": TORN, "stub": STUB, "gap": GAP}
## A fallen panel: at most this many degrees off square to its line, and this far over the ground
## at its foot (m), so it does not sink into a kerb.
const ASKEW_DEG := 7.0
const LIFT := 0.04
## The sector size (m): a hit's pieces are looked for in its tile and the eight round it (a piece
## belongs to the tile holding its middle; a corner piece can sit one tile over).
const SECTOR := 512.0

## soft_things.gd, for is_broken (main.gd sets it).
var soft: Node
## Tile key -> {"key": that key, "node": the Panels MultiMeshInstance3D, "meta": its "panels" meta, "baked": the
## buffer before any write (empty until read), "stride": floats an instance, "asked": an
## asynchronous read is on its way, "pending": the writes waiting for it ([instance, transform,
## custom]), "rid": the MultiMesh's RenderingDevice buffer (RD path)}.
var _tiles := {}
## Line id -> {panel index: the hit's direction (Vector3)}: every broken panel this has shown.
var _down := {}
## Per looks row (its index), the state its broken panels take.
var _row_state := PackedFloat32Array()
## The renderer's device (null: the Compatibility renderer or headless: the MultiMesh path).
var _rd: RenderingDevice = RenderingServer.get_rendering_device()
## Counters for the check and the soak: instances written, hits and sector loads handled, the
## script time they took (µs), the most one hit took leaving out a tile's first read, and the reads
## (one a tile) with the script time they took.
var writes := 0
var hits := 0
var loads := 0
var spent_usec := 0
var hit_most_usec := 0
var reads := 0
var read_usec := 0
## For check_panel_states.gd: every write also goes into the tile's "live" copy of the buffer, as the
## renderer has it (a headless run's renderer keeps no instance written one by one).
var keep_live := false


## main.gd: listens to soft_things.gd `soft`'s `broke` and `repaired`.
func attach(soft_things: Node) -> void:
	soft = soft_things
	soft_things.connect(&"broke", on_broke)
	soft_things.connect(&"repaired", on_repaired)


## A sector (or the whole city's map) is in: its panels noted, and the broken ones shown again.
func add_sector(root: Node3D) -> void:
	if root == null:
		return
	var t0 := Time.get_ticks_usec()
	var found := false
	var own := root.get_node_or_null(^"Panels") as MultiMeshInstance3D
	if own != null and root.has_meta(&"panels"):
		found = _add_tile(_key_of(String(root.name)), own, root.get_meta(&"panels"))
	else:
		for c in root.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi != null and String(mmi.name).begins_with("Panels_") and mmi.has_meta(&"panels"):
				found = _add_tile(_key_of(String(mmi.name)), mmi, mmi.get_meta(&"panels")) or found
	if found:
		loads += 1
		spent_usec += Time.get_ticks_usec() - t0


## Notes tile `key`; shows its broken panels again. True when it has panels.
func _add_tile(key: Vector2i, node: MultiMeshInstance3D, meta: Dictionary) -> bool:
	if node.multimesh == null or node.multimesh.instance_count == 0:
		return false
	var tile := {"key": key, "node": node, "meta": meta, "baked": PackedFloat32Array(), "stride": 0, "asked": false,
			"pending": []}
	_tiles[key] = tile
	if not node.tree_exiting.is_connected(_on_tile_gone):
		node.tree_exiting.connect(_on_tile_gone.bind(key, node), CONNECT_ONE_SHOT)
	if _down.is_empty():
		return true
	var ids: PackedStringArray = meta["ids"]
	var first: PackedInt32Array = meta["first"]
	var count: PackedInt32Array = meta["count"]
	var panel: PackedInt32Array = meta["panel"]
	for k in ids.size():
		var broken: Variant = _down.get(ids[k])
		if broken == null:
			continue
		for i in range(first[k], first[k] + count[k]):
			var p := panel[i]
			if (broken as Dictionary).has(p) and (soft == null or soft.is_broken(ids[k], p)):
				_show(tile, i, ids[k], p, broken[p])
	return true


func _on_tile_gone(key: Vector2i, node: MultiMeshInstance3D) -> void:
	if _tiles.has(key) and is_same(_tiles[key]["node"], node):
		_tiles.erase(key)


## soft_things.broke: the panel's pieces in the loaded tiles take its state.
func on_broke(id: String, panel: int, _kind: StringName, at: Vector3, direction: Vector3, _speed: float) -> void:
	if _tiles.is_empty():
		return  # classic or typed: no panels drawn
	var t0 := Time.get_ticks_usec()
	var read0 := read_usec
	if not _down.has(id):
		_down[id] = {}
	_down[id][panel] = direction
	var c := Vector2i(floori(at.x / SECTOR), floori(at.z / SECTOR))
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var tile: Variant = _tiles.get(c + Vector2i(dx, dz))
			if tile != null:
				for i in _pieces(tile, id, panel):
					_show(tile, i, id, panel, direction)
	hits += 1
	var took := Time.get_ticks_usec() - t0
	spent_usec += took
	hit_most_usec = maxi(hit_most_usec, took - (read_usec - read0))


## soft_things.repaired: the panel's pieces as baked.
func on_repaired(id: String, panel: int) -> void:
	var broken: Variant = _down.get(id)
	if broken == null or not (broken as Dictionary).has(panel):
		return
	(broken as Dictionary).erase(panel)
	if (broken as Dictionary).is_empty():
		_down.erase(id)
	var t0 := Time.get_ticks_usec()
	for key: Vector2i in _tiles:
		var tile: Dictionary = _tiles[key]
		if not tile["asked"]:
			continue  # never written: it is as baked
		for i in _pieces(tile, id, panel):
			_restore(tile, i)
	spent_usec += Time.get_ticks_usec() - t0


## How many panels are shown broken (the check).
func broken_count() -> int:
	var n := 0
	for id: String in _down:
		n += (_down[id] as Dictionary).size()
	return n


## Writes still waiting for a tile's read (the check waits for none).
func pending() -> int:
	var n := 0
	for key: Vector2i in _tiles:
		n += (_tiles[key]["pending"] as Array).size()
	return n


## The instances of line `id`'s panel `panel` in `tile`.
static func _pieces(tile: Dictionary, id: String, panel: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var meta: Dictionary = tile["meta"]
	var k := (meta["ids"] as PackedStringArray).find(id)
	if k < 0:
		return out
	var first: int = (meta["first"] as PackedInt32Array)[k]
	var panels: PackedInt32Array = meta["panel"]
	for i in range(first, first + (meta["count"] as PackedInt32Array)[k]):
		if panels[i] == panel:
			out.append(i)
	return out


## Instance `i` of `tile` (line `id`'s panel `panel`) in its row's broken state; `down`, laid flat.
func _show(tile: Dictionary, i: int, id: String, panel: int, direction: Vector3) -> void:
	_queue(tile, [i, id, panel, direction])


## Instance `i` of `tile` as baked.
func _restore(tile: Dictionary, i: int) -> void:
	_queue(tile, [i])


## One write: done now when the tile's buffer is read, else after its read.
func _queue(tile: Dictionary, op: Array) -> void:
	if not tile["asked"]:
		_read(tile)
	if (tile["baked"] as PackedFloat32Array).is_empty():
		(tile["pending"] as Array).append(op)
	else:
		_apply(tile, op)


## The tile's baked buffer: on a RenderingDevice asked for (its writes wait for `_on_read`), else
## read now.
func _read(tile: Dictionary) -> void:
	var t0 := Time.get_ticks_usec()
	tile["asked"] = true
	reads += 1
	var mm := (tile["node"] as MultiMeshInstance3D).multimesh
	var rid := RenderingServer.multimesh_get_buffer_rd_rid(mm.get_rid()) if _rd != null else RID()
	# The answer comes inside the device's frame sync, where a buffer_update is accepted and lost
	# (measured: Godot 4.7.2, Mobile): the writes are done after it, deferred.
	if rid.is_valid() and _rd.buffer_get_data_async(rid, func(data: PackedByteArray) -> void:
			_on_read.call_deferred(data, tile, mm.instance_count)) == OK:
		tile["rid"] = rid
	else:
		# One read of the buffer into the renderer's own copy (an instance read makes it), then the
		# buffer from that copy: the per-instance writes after it need no second read.
		mm.get_instance_custom_data(0)
		_baked(tile, mm.buffer, mm.instance_count)
	read_usec += Time.get_ticks_usec() - t0


## The asynchronous read is in: the tile's waiting writes done (none if the tile left meanwhile).
func _on_read(data: PackedByteArray, tile: Dictionary, count: int) -> void:
	var node: Variant = tile["node"]
	if not is_instance_valid(node) or not is_same(_tiles.get(tile["key"]), tile):
		return
	var buf := data.to_float32_array()
	if buf.size() != count * 16 and buf.size() != count * 20:
		# Not the layout this writes (a renderer keeping two frames' transforms): the MultiMesh path.
		tile.erase("rid")
		var mm := (node as MultiMeshInstance3D).multimesh
		mm.get_instance_custom_data(0)
		buf = mm.buffer
	_baked(tile, buf, count)
	var ops: Array = tile["pending"]
	tile["pending"] = []
	for op: Array in ops:
		_apply(tile, op)


func _baked(tile: Dictionary, buf: PackedFloat32Array, count: int) -> void:
	tile["baked"] = buf
	tile["stride"] = buf.size() / count
	if keep_live:
		tile["live"] = buf.duplicate()


## One write `op` ([i, id, panel, direction]: shown broken; [i]: as baked) into the tile's buffer.
func _apply(tile: Dictionary, op: Array) -> void:
	var b: PackedFloat32Array = tile["baked"]
	var stride: int = tile["stride"]
	var i: int = op[0]
	var o := i * stride
	var c := stride - 4  # the custom data: the last four floats (after the colour on Compatibility)
	var xf := _transform(b, o)
	var custom := Color(b[o + c], b[o + c + 1], b[o + c + 2], b[o + c + 3])
	if op.size() > 1:
		var state := _state_of_row(int(custom.r + 0.5))
		if state == WHOLE:
			return
		custom.b = state
		if state == DOWN or state == BOARDS:
			xf = down_transform(xf, op[3], op[1], op[2])
	if tile.has("rid"):
		var floats := b.slice(o, o + stride)
		_put(floats, 0, c, xf, custom)
		_rd.buffer_update(tile["rid"], o * 4, stride * 4, floats.to_byte_array())
	else:
		var mm := (tile["node"] as MultiMeshInstance3D).multimesh
		mm.set_instance_transform(i, xf)
		mm.set_instance_custom_data(i, custom)
	writes += 1
	if keep_live:
		var live: PackedFloat32Array = tile["live"]
		_put(live, o, c, xf, custom)
		tile["live"] = live


## Transform `xf` and custom data `custom` into buffer `buf` at instance offset `o` (custom at `o + c`).
static func _put(buf: PackedFloat32Array, o: int, c: int, xf: Transform3D, custom: Color) -> void:
	var x := xf.basis.x
	var y := xf.basis.y
	var z := xf.basis.z
	var v := [x.x, y.x, z.x, xf.origin.x, x.y, y.y, z.y, xf.origin.y, x.z, y.z, z.z, xf.origin.z]
	for k in 12:
		buf[o + k] = v[k]
	for k in 4:
		buf[o + c + k] = custom[k]


## The transform at `o` in a MultiMesh buffer (12 floats, the basis' rows with the origin).
static func _transform(b: PackedFloat32Array, o: int) -> Transform3D:
	return Transform3D(Vector3(b[o], b[o + 4], b[o + 8]), Vector3(b[o + 1], b[o + 5], b[o + 9]),
			Vector3(b[o + 2], b[o + 6], b[o + 10]), Vector3(b[o + 3], b[o + 7], b[o + 11]))


## A standing piece's transform `xf` (city_barriers.gd `_panel_piece`: x along the line with its
## slope, y up its height plus PanelRule.SINK, z across its thickness, the origin at its start,
## SINK under the ground) laid down: y along the ground on the side `direction` points to (either
## side when the hit ran along the line), turned by up to ASKEW_DEG about the piece's start by the
## line's and panel's hash, the thickness standing up, the box LIFT over the ground there.
static func down_transform(xf: Transform3D, direction: Vector3, id: String, panel: int) -> Transform3D:
	var x := xf.basis.x
	var tall := xf.basis.y.length()
	var thick := xf.basis.z.length()
	var across := Vector3(-x.z, 0.0, x.x).normalized()
	if Vector2(direction.x, direction.z).dot(Vector2(across.x, across.z)) < 0.0:
		across = -across
	var turn := (float(posmod(hash("%s#%d" % [id, panel]), 2001)) / 1000.0 - 1.0) * deg_to_rad(ASKEW_DEG)
	var y := across.rotated(Vector3.UP, turn) * tall
	var z := x.cross(y).normalized() * thick
	var ground := xf.origin.y + PanelRule.SINK
	return Transform3D(Basis(x, y, z), Vector3(xf.origin.x, ground + thick * 0.5 + LIFT, xf.origin.z))


## The state a broken panel of looks row `r` takes (WHOLE for a row that does not break).
func _state_of_row(r: int) -> float:
	if _row_state.is_empty():
		var looks := Solidity.looks()
		_row_state.resize(looks.size())
		for k in looks.size():
			var row := Solidity.look_row(looks[k])
			_row_state[k] = float(STATE_OF.get(str(row.get("broken", "")), WHOLE))
			if _row_state[k] == GAP and str(row.get("debris", "")) == "wood":
				_row_state[k] = BOARDS
	return _row_state[r] if r >= 0 and r < _row_state.size() else WHOLE


## A sector root's or a whole-city tile node's key ("s_i_j", "Panels_i_j").
static func _key_of(n: String) -> Vector2i:
	var parts := n.split("_")
	if parts.size() == 3:
		return Vector2i(int(parts[1]), int(parts[2]))
	return Vector2i(1 << 20, 1 << 20)
