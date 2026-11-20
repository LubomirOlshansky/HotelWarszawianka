extends RefCounted
## W9 of the walls look (docs/design/walls-true-to-life.md 6.6 rows 10 to 13, 6.8): the marks on the
## city's walls, under barrier_look typed and panels (city_barriers.gd calls `draw` for each line it
## draws with a heavy slab row or a hoarding; classic never does).
##   graffiti, stain, ivy: colour quads in the city mesh, 1.5 to 2.5 cm off the wall face (vertex
##     colour, the building shader's prop path, no new draw call);
##   slogans (a row's `poster` mark) and banners (`banner`): quads of one MeshInstance3D per sector
##     (`Slogans`, map_builder.gd `_build_marks`), poster.gdshader and one shared atlas drawn here
##     with pixel_font.gd from game/data/wall_marks.json: one draw call a sector with any in view.
## A place is a hash of the line's stable id and its metres (`hv`), so both city paths and every run
## draw the same marks; none on a line inside a landmark's guard (graffiti and slogans), none across
## a gap (tools/barrier_gates.py `g`), none within MARGIN m of a corner or an end (the kit's mitres,
## piers and posts stand there). The numbers are the palette's `marks` table (solidity.gd
## marks_table); the words are game/data/wall_marks.json.

const Solidity := preload("res://scripts/solidity.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const TEXTS := "res://data/wall_marks.json"
## The atlas is this many pixels wide; cells are packed in shelves.
const ATLAS_W := 512
## A mark keeps this far (m) from a line's corners and ends, and from a gap's edges.
const MARGIN := 0.3
## A wall shorter than this (m) carries no mark; a slogan's segment needs the quad plus SLOGAN_ROOM.
const MIN_RUN := 0.8
const SLOGAN_ROOM := 0.8
## The metres a segment of a line shorter than a patch is no good for.
const MIN_PATCH := 0.8

static var _texts: Dictionary = _load_texts()
static var _atlas: Dictionary = {}


## One sector's slogan and banner quads (a tile of the last build_barriers).
class Tile:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var box := AABB()
	var started := false
	var quads := 0

	func add(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uv: Rect2) -> void:
		# a bottom left, b bottom right, c top right, d top left as the viewer reads; a clockwise
		# front face in Godot: (a, c, b) and (a, d, c).
		var ua := Vector2(uv.position.x, uv.end.y)
		var ub := Vector2(uv.end.x, uv.end.y)
		var uc := Vector2(uv.end.x, uv.position.y)
		var ud := Vector2(uv.position.x, uv.position.y)
		for p: Array in [[a, ua], [c, uc], [b, ub], [a, ua], [d, ud], [c, uc]]:
			verts.append(p[0])
			norms.append(n)
			uvs.append(p[1])
		for v: Vector3 in [a, b, c, d]:
			if not started:
				started = true
				box = AABB(v, Vector3.ZERO)
			else:
				box = box.expand(v)
		quads += 1


## game/data/wall_marks.json, read once: {"slogans": [...], "banners": [...]}.
static func _load_texts() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXTS)) if FileAccess.file_exists(TEXTS) else null
	if not parsed is Dictionary:
		push_error("wall_marks: %s is missing or not an object" % TEXTS)
		return {"slogans": [], "banners": []}
	return parsed


static func texts() -> Dictionary:
	return _texts


## A hash of (seed, a, b) to [0, 1), the same on every platform (32-bit integer mixing).
static func hv(seed: int, a: int, b: int = 0) -> float:
	var x := (seed & 0xFFFFFFFF) ^ ((a * 0x9E3779B1) & 0xFFFFFFFF) ^ ((b * 0x85EBCA6B) & 0xFFFFFFFF)
	x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	x = x ^ (x >> 16)
	return float(x & 0xFFFFFF) / 16777216.0


static func _range(r: Array, t: float) -> float:
	return lerpf(float(r[0]), float(r[1]), t)


# --- the atlas -----------------------------------------------------------------------------

## The atlas: {"image": Image (RGBA8, ATLAS_W wide), "slogans": {"<id>|<row>": Rect2i of pixels},
## "banners": {"<id>": Rect2i}}. A slogan's cell is its words in an ink on the repainted patch of its
## row's wall (the row's colour as the kit's faces shade it, `bg_lift` lighter), the ink by the text's
## and the row's number; a banner's cell is its lines centred between two bands in a scheme's ink on its
## sheet, the scheme by the banner's number. Made once.
static func atlas() -> Dictionary:
	if not _atlas.is_empty():
		return _atlas
	var tab := Solidity.marks_table()
	var cells: Array = []
	var sl: Dictionary = tab.get("slogan", {})
	var pad := int(sl.get("pad", 2))
	var inks: Array = sl.get("inks", ["#f2f0e8"])
	var rows: Array = (sl.get("share", {}) as Dictionary).keys()
	rows.sort()
	var si := 0
	for t: Dictionary in _texts.get("slogans", []):
		for r: String in rows:
			if not r in t.get("on", []):
				continue
			var bg := Color(str(Solidity.look_row(StringName(r)).get("colour", "#a9a69f"))).darkened(0.08).lightened(float(sl.get("bg_lift", 0.1)))
			cells.append({"key": "%s|%s" % [t["id"], r], "kind": "slogans", "w": PixelFont.width(str(t["pl"])) + pad * 2,
					"h": PixelFont.ROWS + pad * 2, "bg": bg, "ink": Color(str(inks[(si + rows.find(r)) % inks.size()])),
					"lines": [str(t["pl"])], "pad": pad, "band": 0})
		si += 1
	var bn: Dictionary = tab.get("banner", {})
	var schemes: Array = bn.get("schemes", [{"bg": "#f1efe6", "ink": "#1f4b8f"}])
	var bpad := int(bn.get("pad", 3))
	var bi := 0
	for t: Dictionary in _texts.get("banners", []):
		var lines: Array = t["lines"]
		var w := 0
		for ln: Variant in lines:
			w = maxi(w, PixelFont.width(str(ln)))
		var sch: Dictionary = schemes[bi % schemes.size()]
		cells.append({"key": str(t["id"]), "kind": "banners", "w": w + bpad * 2, "h": 4 + bpad * 2 + lines.size() * PixelFont.LINE - 1,
				"bg": Color(str(sch["bg"])), "ink": Color(str(sch["ink"])), "lines": lines, "pad": bpad, "band": 2})
		bi += 1
	# Shelf packing, in the order made.
	var x := 0
	var y := 0
	var shelf := 0
	for c: Dictionary in cells:
		if x + int(c["w"]) > ATLAS_W:
			x = 0
			y += shelf
			shelf = 0
		c["rect"] = Rect2i(x, y, int(c["w"]), int(c["h"]))
		x += int(c["w"])
		shelf = maxi(shelf, int(c["h"]))
	var height := maxi(16, ((y + shelf + 15) / 16) * 16)
	var img := Image.create(ATLAS_W, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5, 1.0))
	var out := {"image": img, "slogans": {}, "banners": {}}
	for c: Dictionary in cells:
		var r: Rect2i = c["rect"]
		img.fill_rect(r, c["bg"])
		var band := int(c["band"])
		if band > 0:
			img.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, band), c["ink"])
			img.fill_rect(Rect2i(r.position.x, r.end.y - band, r.size.x, band), c["ink"])
		var lines: Array = c["lines"]
		for i in lines.size():
			var text := str(lines[i])
			var tx := r.position.x + (r.size.x - PixelFont.width(text)) / 2
			PixelFont.draw(img, text, tx, r.position.y + band + int(c["pad"]) + i * PixelFont.LINE, c["ink"])
		(out[c["kind"]] as Dictionary)[c["key"]] = r
	_atlas = out
	return out


## The atlas as a texture for poster.gdshader's `poster` uniform.
static func atlas_texture() -> ImageTexture:
	return ImageTexture.create_from_image(atlas()["image"])


static func _uv(r: Rect2i, img: Image) -> Rect2:
	var w := float(img.get_width())
	var h := float(img.get_height())
	return Rect2(r.position.x / w, r.position.y / h, r.size.x / w, r.size.y / h)


# --- one line ------------------------------------------------------------------------------

## The marks of line `l` drawn by `look` (city_barriers.gd `_typed`: a heavy `slab` row, or the
## hoarding), its points `pts`: colour quads into the city mesh `st`, slogan and banner quads into
## `cb.mark_tiles`; what was made counted in `cb.mark_counts`. `cb` is the CityBarriers.
static func draw(cb, st, l: Dictionary, pts: PackedVector2Array, look: Dictionary) -> void:
	var row: Dictionary = look["row"]
	var marks: Array = row.get("marks", [])
	if marks.is_empty() or pts.size() < 2:
		return
	var tab := Solidity.marks_table()
	var ty := str(row["id"])
	var seed := hash(cb.barrier_id(l["k"], l["p"])) & 0x7FFFFFFF
	var height := float(look["h"])
	var k: Dictionary = cb._kit_spec(row, height, look["colour"], int(look["alt"])) if cb.kit_row(row) else {}
	var hw: float = k.get("hw", float(row.get("thick", 0.1)) * 0.5)
	var body_hi: float = height
	var foot_h := 0.0
	var cap_over := 0.0
	var cap_h := 0.0
	var face_col: Color = look["colour"]
	if not k.is_empty():
		cap_h = k["cap_h"]
		cap_over = k["cap_over"]
		body_hi = k["upstand"] if k["cap"] == "upstand" else height - cap_h
		foot_h = k["foot_h"]
		face_col = (k["col"] as Color).darkened(0.08)
	var segs: Array = _segments(cb, pts)
	if segs.is_empty():
		return
	var total: float = segs[segs.size() - 1]["e"]
	var gaps: Array = l.get("g", [])
	var guarded := false
	if "graffiti" in marks or "poster" in marks:
		guarded = cb.near_landmark(l["p"])
	var ctx := {"cb": cb, "st": st, "seg": segs, "total": total, "gaps": gaps, "hw": hw, "seed": seed, "ty": ty,
			"body_hi": body_hi, "foot_h": foot_h, "cap_over": cap_over, "cap_h": cap_h, "h": height, "face": face_col,
			"tab": tab, "cap": k.get("cap", ""), "id": cb.barrier_id(l["k"], l["p"]), "thick": float(row.get("thick", 0.1))}
	if "stain" in marks:
		_stains(ctx)
	if "graffiti" in marks and not guarded:
		_graffiti(ctx)
	if "ivy" in marks:
		_ivy(ctx)
	if "poster" in marks and not guarded:
		_slogans(ctx)
	if "banner" in marks:
		_banners(ctx)


## The line's segments: [{"s": metres at its start, "e": at its end, "a", "b": points, "ga", "gb": ground,
## "d": unit direction}], the ones under 0.05 m left out (as the kit's).
static func _segments(cb, pts: PackedVector2Array) -> Array:
	var out: Array = []
	var run := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var len := a.distance_to(b)
		if len < 0.05:
			continue
		out.append({"s": run, "e": run + len, "a": a, "b": b, "ga": cb.map.terrain_height(a.x, a.y),
				"gb": cb.map.terrain_height(b.x, b.y), "d": (b - a) / len})
		run += len
	return out


## The segment holding metre `s`, or an empty Dictionary.
static func _seg_at(ctx: Dictionary, s: float) -> Dictionary:
	for sg: Dictionary in ctx["seg"]:
		if s <= float(sg["e"]):
			return sg
	return {}


## Whether [s0, s1] metres of the line touch a gap (padded by MARGIN).
static func _in_gap(ctx: Dictionary, s0: float, s1: float) -> bool:
	for g: Array in ctx["gaps"]:
		if s1 > float(g[0]) - MARGIN and s0 < float(g[0]) + float(g[1]) + MARGIN:
			return true
	return false


## The ground at metre `s` of segment `sg`.
static func _ground(sg: Dictionary, s: float) -> float:
	return lerpf(float(sg["ga"]), float(sg["gb"]), clampf((s - float(sg["s"])) / (float(sg["e"]) - float(sg["s"])), 0.0, 1.0))


## An upright quad on face `side` (+1 left of the line's direction, -1 right) of segment `sg` from metre
## s0 to s1 and y0 to y1 over the ground, `off` m out of the line's middle, `col`.
static func _face(ctx: Dictionary, sg: Dictionary, s0: float, s1: float, y0: float, y1: float, side: float, off: float, col: Color) -> void:
	var cb = ctx["cb"]
	var d: Vector2 = sg["d"]
	var n2 := Vector2(-d.y, d.x) * side
	var p0: Vector2 = (sg["a"] as Vector2) + d * (s0 - float(sg["s"])) + n2 * off
	var p1: Vector2 = (sg["a"] as Vector2) + d * (s1 - float(sg["s"])) + n2 * off
	var g0 := _ground(sg, s0)
	var g1 := _ground(sg, s1)
	cb.map._quad(ctx["st"], Vector3(p0.x, g0 + y0, p0.y), Vector3(p1.x, g1 + y0, p1.y), Vector3(p1.x, g1 + y1, p1.y),
			Vector3(p0.x, g0 + y1, p0.y), Vector3(n2.x, 0.0, n2.y), col)
	var counts: Dictionary = cb.mark_counts
	counts["tris"] = int(counts.get("tris", 0)) + 2


## Where a mark of length `len` wanted at metre `s0` fits inside one segment (MARGIN from its ends, clear
## of the gaps): [segment, s0, s1], or an empty Array.
static func _fit(ctx: Dictionary, s0: float, len: float, least := MIN_PATCH) -> Array:
	var sg := _seg_at(ctx, s0 + len * 0.5)
	if sg.is_empty():
		return []
	var a := maxf(s0, float(sg["s"]) + MARGIN)
	var b := minf(s0 + len, float(sg["e"]) - MARGIN)
	if b - a < least or _in_gap(ctx, a, b):
		return []
	return [sg, a, b]


static func _count(ctx: Dictionary, what: String) -> void:
	var counts: Dictionary = ctx["cb"].mark_counts
	counts[what] = int(counts.get(what, 0)) + 1


## Graffiti: a low colour patch (a muted spray colour, sometimes with a bright inner block and a dark tag
## bar) per face, one chance per `cell` metres.
static func _graffiti(ctx: Dictionary) -> void:
	var tab: Dictionary = ctx["tab"].get("graffiti", {})
	var share := float((tab.get("share", {}) as Dictionary).get(ctx["ty"], 0.0))
	if share <= 0.0:
		return
	var cell := float(tab["cell"])
	var muted: Array = tab["muted"]
	var accent: Array = tab["accent"]
	var seed: int = ctx["seed"]
	var lift := float(tab["lift"]) + float(ctx["hw"])
	var avail: float = float(ctx["body_hi"]) - float(ctx["foot_h"]) - 0.25
	if avail < 0.4:
		return
	for c in ceili(float(ctx["total"]) / cell):
		for fi in 2:
			var key := c * 2 + fi
			if hv(seed, key, 1) >= share:
				continue
			var len := _range(tab["len"], hv(seed, key, 2))
			var hgt := minf(_range(tab["h"], hv(seed, key, 3)), avail)
			var fit := _fit(ctx, c * cell + hv(seed, key, 4) * (cell - len), len)
			if fit.is_empty():
				continue
			var sg: Dictionary = fit[0]
			var s0: float = fit[1]
			var s1: float = fit[2]
			var side := 1.0 if fi == 0 else -1.0
			var y0 := float(ctx["foot_h"]) + 0.12 + hv(seed, key, 5) * (avail - hgt)
			var base := Color(str(muted[int(hv(seed, key, 6) * muted.size()) % muted.size()]))
			_face(ctx, sg, s0, s1, y0, y0 + hgt, side, lift, base)
			var w := s1 - s0
			if hv(seed, key, 7) < float(tab["accent_share"]):
				var ac := Color(str(accent[int(hv(seed, key, 8) * accent.size()) % accent.size()]))
				_face(ctx, sg, s0 + w * 0.2, s0 + w * 0.8, y0 + hgt * 0.25, y0 + hgt * 0.75, side, lift + 0.003, ac)
			else:
				_face(ctx, sg, s0 + w * 0.1, s1 - w * 0.1, y0 + hgt * 0.42, y0 + hgt * 0.56, side, lift + 0.003, Color(str(tab["tag"])))
			_count(ctx, "graffiti")


## Stains: dark drip stripes hanging from under the coping, per face, one chance per `cell` metres.
static func _stains(ctx: Dictionary) -> void:
	var tab: Dictionary = ctx["tab"].get("stain", {})
	var share := float((tab.get("share", {}) as Dictionary).get(ctx["ty"], 0.0))
	if share <= 0.0:
		return
	var cell := float(tab["cell"])
	var seed: int = ctx["seed"] ^ 0x5A5A5A
	var lift := float(tab["lift"]) + float(ctx["hw"])
	var col: Color = (ctx["face"] as Color).darkened(float(tab["darken"]))
	var top: float = ctx["body_hi"]
	var room: float = top - float(ctx["foot_h"]) - 0.1
	if room < 0.3:
		return
	for c in ceili(float(ctx["total"]) / cell):
		for fi in 2:
			var key := c * 2 + fi
			if hv(seed, key, 1) >= share:
				continue
			var n := 1 + int(hv(seed, key, 2) * 3.0)
			var at := c * cell + hv(seed, key, 3) * (cell - 0.8)
			for i in n:
				var w := _range(tab["width"], hv(seed, key, 10 + i))
				var len := minf(_range(tab["len"], hv(seed, key, 20 + i)), room)
				var s0 := at + i * (0.25 + hv(seed, key, 30 + i) * 0.4)
				var fit := _fit(ctx, s0, w, w * 0.9)
				if fit.is_empty():
					continue
				_face(ctx, fit[0], fit[1], fit[2], top - len, top, 1.0 if fi == 0 else -1.0, lift, col)
				_count(ctx, "stain")


## Ivy: a green clump over the wall top (the cap's face and a mantle on the top) and a stepped skirt down
## the face, per face, one chance per `cell` metres.
static func _ivy(ctx: Dictionary) -> void:
	var tab: Dictionary = ctx["tab"].get("ivy", {})
	var share := float((tab.get("share", {}) as Dictionary).get(ctx["ty"], 0.0))
	if share <= 0.0:
		return
	var cell := float(tab["cell"])
	var seed: int = ctx["seed"] ^ 0x2F2F2F
	var hw: float = ctx["hw"]
	var lift := float(tab["lift"])
	var colours: Array = tab["colours"]
	var top: float = ctx["body_hi"]
	var h: float = ctx["h"]
	var over: float = ctx["cap_over"]
	for c in ceili(float(ctx["total"]) / cell):
		for fi in 2:
			var key := c * 2 + fi
			if hv(seed, key, 1) >= share:
				continue
			var len := _range(tab["width"], hv(seed, key, 2))
			var fit := _fit(ctx, c * cell + hv(seed, key, 3) * (cell - len), len)
			if fit.is_empty():
				continue
			var sg: Dictionary = fit[0]
			var s0: float = fit[1]
			var s1: float = fit[2]
			var w := s1 - s0
			var side := 1.0 if fi == 0 else -1.0
			var drop := minf(_range(tab["drop"], hv(seed, key, 4)), top - float(ctx["foot_h"]) - 0.1)
			var col := Color(str(colours[int(hv(seed, key, 5) * colours.size()) % colours.size()]))
			# The mantle on the top, across the cap's width (each face its own height).
			var across := hw + over + lift
			var d: Vector2 = sg["d"]
			var nrm := Vector2(-d.y, d.x)
			var pa: Vector2 = (sg["a"] as Vector2) + d * (s0 - float(sg["s"]))
			var pb: Vector2 = (sg["a"] as Vector2) + d * (s1 - float(sg["s"]))
			var ya := _ground(sg, s0) + h + lift + (0.0 if fi == 0 else 0.006)
			var yb := _ground(sg, s1) + h + lift + (0.0 if fi == 0 else 0.006)
			ctx["cb"].map._quad(ctx["st"], Vector3(pa.x + nrm.x * across, ya, pa.y + nrm.y * across), Vector3(pb.x + nrm.x * across, yb, pb.y + nrm.y * across),
					Vector3(pb.x - nrm.x * across, yb, pb.y - nrm.y * across), Vector3(pa.x - nrm.x * across, ya, pa.y - nrm.y * across), Vector3.UP, col)
			var counts: Dictionary = ctx["cb"].mark_counts
			counts["tris"] = int(counts.get("tris", 0)) + 2
			# The cap's face, then the skirt: wide and short, then narrower and longer, darker.
			if h - top > 0.01:
				_face(ctx, sg, s0, s1, top, h + lift, side, hw + over + lift, col)
			_face(ctx, sg, s0, s1, top - drop * 0.55, top, side, hw + lift, col)
			_face(ctx, sg, s0 + w * 0.2, s1 - w * 0.25, top - drop, top - drop * 0.55, side, hw + lift, col.darkened(0.15))
			_count(ctx, "ivy")


## Slogans: at most one per `window` metres of a line (a line shorter than that has the chance scaled by
## its length), on the longest wall segment of its window, a painted word on a repainted patch, a quad of
## the sector's `Slogans` mesh. Not where the wall is too low or too short for the words.
static func _slogans(ctx: Dictionary) -> void:
	var tab: Dictionary = ctx["tab"].get("slogan", {})
	var share := float((tab.get("share", {}) as Dictionary).get(ctx["ty"], 0.0))
	if share <= 0.0:
		return
	var win := float(tab["window"])
	var texel := float(tab["texel"])
	var seed: int = ctx["seed"] ^ 0x1B1B1B
	var at := atlas()
	var img: Image = at["image"]
	var total: float = ctx["total"]
	var cb = ctx["cb"]
	var last := -INF
	for w in ceili(total / win):
		var ws := w * win
		var we := minf(total, ws + win)
		var chance := share * minf(1.0, (we - ws) / win)
		if hv(seed, w, 1) >= chance:
			continue
		# The longest piece of a segment inside the window.
		var best: Dictionary = {}
		var best_len := 0.0
		for sg: Dictionary in ctx["seg"]:
			var len := minf(float(sg["e"]), we) - maxf(float(sg["s"]), ws)
			if len > best_len:
				best_len = len
				best = sg
		if best.is_empty():
			continue
		var lo := maxf(float(best["s"]), ws) + MARGIN
		var hi := minf(float(best["e"]), we) - MARGIN
		var fits: Array = []
		for t: Dictionary in _texts.get("slogans", []):
			var cell_key := "%s|%s" % [t["id"], ctx["ty"]]
			if not (at["slogans"] as Dictionary).has(cell_key):
				continue
			var cr: Rect2i = at["slogans"][cell_key]
			if cr.size.x * texel + SLOGAN_ROOM <= hi - lo and cr.size.y * texel + float(tab["bottom"]) + 0.15 <= float(ctx["body_hi"]):
				fits.append([cell_key, cr, str(t["id"])])
		if fits.is_empty():
			continue
		var pick: Array = fits[int(hv(seed, w, 2) * fits.size()) % fits.size()]
		var r: Rect2i = pick[1]
		var qw := r.size.x * texel
		var qh := r.size.y * texel
		var s0 := lo + (hi - lo - qw) * (0.25 + 0.5 * hv(seed, w, 3))
		if _in_gap(ctx, s0, s0 + qw):
			continue
		var side := 1.0 if hv(seed, w, 4) < 0.5 else -1.0
		var y0 := float(tab["bottom"]) + hv(seed, w, 5) * 0.2
		if y0 + qh + 0.12 > float(ctx["body_hi"]):
			y0 = float(ctx["body_hi"]) - 0.12 - qh
		# Never two slogans of a line closer than a window.
		if s0 + qw * 0.5 - last < win:
			continue
		var mid := _point(best, s0 + qw * 0.5)
		if not _put(cb, best, s0, s0 + qw, y0, y0 + qh, side, float(ctx["hw"]) + float(tab["lift"]), _uv(r, img)):
			continue
		last = s0 + qw * 0.5
		cb.mark_counts["slogan"] = int(cb.mark_counts.get("slogan", 0)) + 1
		cb.slogan_log.append([str(ctx["id"]), s0 + qw * 0.5, total, str(pick[2]), mid])


## Banners: on a hoarding, a developer's banner per face (the largest texel of the palette's list that
## fits), centred on its segment and its height.
static func _banners(ctx: Dictionary) -> void:
	var tab: Dictionary = ctx["tab"].get("banner", {})
	var share := float((tab.get("share", {}) as Dictionary).get(ctx["ty"], 0.0))
	if share <= 0.0:
		return
	var seed: int = ctx["seed"] ^ 0x3C3C3C
	var at := atlas()
	var img: Image = at["image"]
	var cb = ctx["cb"]
	var banners: Array = _texts.get("banners", [])
	if banners.is_empty():
		return
	for fi in 2:
		if hv(seed, fi, 1) >= share:
			continue
		var side := 1.0 if fi == 0 else -1.0
		# The longest segment holds the banner.
		var best: Dictionary = {}
		for sg: Dictionary in ctx["seg"]:
			if best.is_empty() or float(sg["e"]) - float(sg["s"]) > float(best["e"]) - float(best["s"]):
				best = sg
		var lo := float(best["s"]) + MARGIN
		var hi := float(best["e"]) - MARGIN
		var order := int(hv(seed, fi, 2) * banners.size()) % banners.size()
		for tries in banners.size():
			var t: Dictionary = banners[(order + tries) % banners.size()]
			var r: Rect2i = (at["banners"] as Dictionary)[str(t["id"])]
			var done := false
			for texel: Variant in tab["texel"]:
				var qw := r.size.x * float(texel)
				var qh := r.size.y * float(texel)
				if qw > hi - lo or qh > float(ctx["h"]) - 0.3:
					continue
				var s0 := lo + (hi - lo - qw) * 0.5
				if _in_gap(ctx, s0, s0 + qw):
					continue
				var y0 := (float(ctx["h"]) - qh) * 0.5
				if _put(cb, best, s0, s0 + qw, y0, y0 + qh, side, float(ctx["thick"]) * 0.5 + float(tab["lift"]), _uv(r, img)):
					cb.mark_counts["banner"] = int(cb.mark_counts.get("banner", 0)) + 1
					done = true
				break
			if done:
				break


static func _point(sg: Dictionary, s: float) -> Vector2:
	return (sg["a"] as Vector2) + (sg["d"] as Vector2) * (s - float(sg["s"]))


## One poster quad on face `side` of segment `sg` from metre s0 to s1 and y0 to y1 over the ground, `off`
## m out of the line, reading left to right as seen from outside (the right-hand side of a viewer
## facing the wall is `dir * side`), into the sector tile holding its middle. False when the middle is
## in another sector of a sector build.
static func _put(cb, sg: Dictionary, s0: float, s1: float, y0: float, y1: float, side: float, off: float, uv: Rect2) -> bool:
	var mid := _point(sg, (s0 + s1) * 0.5)
	var key := Vector2i(floori(mid.x / cb.map.SECTOR), floori(mid.y / cb.map.SECTOR))
	if cb.map._in_sector and key != cb.map._sector:
		return false
	var d: Vector2 = sg["d"]
	var n2 := Vector2(-d.y, d.x) * side
	var pl := _point(sg, s0 if side > 0.0 else s1) + n2 * off
	var pr := _point(sg, s1 if side > 0.0 else s0) + n2 * off
	var gl := _ground(sg, s0 if side > 0.0 else s1)
	var gr := _ground(sg, s1 if side > 0.0 else s0)
	var tile: Tile = cb.mark_tiles.get(key)
	if tile == null:
		tile = Tile.new()
		cb.mark_tiles[key] = tile
	tile.add(Vector3(pl.x, gl + y0, pl.y), Vector3(pr.x, gr + y0, pr.y), Vector3(pr.x, gr + y1, pr.y),
			Vector3(pl.x, gl + y1, pl.y), Vector3(n2.x, 0.0, n2.y), uv)
	return true
