extends Control
## Loop MW-1 (docs/design/vision.md 4.1): the MOJA WARSZAWA page, the settings card's fifth tab
## (settings_panel.gd). A row of the 9 chapters (a number for the chapter's icon until the
## PixelLab icons come, and its count k/8), the chapter's name, then its 8 cards in a grid of
## 4 x 2: a found card shows its name (Polish over English), one not found yet only "?" and the
## chapter. Tapping a card opens it: name, fact and joke (Polish over English), the address,
## the hours for a night venue and the day it was found; WRÓĆ goes back to the grid. Map north
## (2026-10-31): a chapter of 9 or 10 cards draws them 5 x 2.
##
## Loop MW-6: three more chips after the chapters, each with a small pixel icon drawn in the
## boxes' triangles (no texture): SEKRETY · eggs (egg_book.gd, 45 cards), KASETA · tape (tape.gd,
## the 20 then cards) and KADR · photo spots (fotka.gd, 15). Their grids are 5 x 3, a page at a
## time (‹ › in the title row); a card found shows its name, one not found "?" and its number.
## Opened: an egg's line and reward, a then card's year and line, a Kadr spot's look and the
## player's own photo of it (a small texture loaded only while that card is open: +1 2D draw call).
##
## Drawn by hand, not as Buttons and Labels: every box is one triangle array (one draw call)
## and the words go after it grouped by size (a font size is a texture of its own), so the
## open page costs a handful of 2D draw calls whatever it shows (the HUD's rule 6, DEVELOPMENT
## "Performance budgets"); nothing is drawn while the panel is closed. Sized in points like
## the panel; every target at least 44 pt.

const UiKit := preload("res://scripts/ui_kit.gd")  # the one look (docs/design/ui-kit.md)
const Lang := preload("res://scripts/lang.gd")  # one language at a time
const INK := UiKit.INK
const SUB := UiKit.SUB
const ACCENT := UiKit.GOLD
## Collectibles' gold (the art bible): a complete chapter's number.
const GOLD := UiKit.GOLD  # the one gold (was #f0b429)
const DIM := UiKit.DIM
const EDGE := UiKit.EDGE
const SHUT := Color(UiKit.INK, 0.03)
const ON := UiKit.GOLD_TINT
## The card under a box's fill (settings_panel.gd CARD_BG, opaque): a box is its edge colour,
## then this inset, then its fill.
const UNDER := UiKit.CARD_SOLID
const T_BIG := 22.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0
## The page in points (at least; it takes the card's width when that is more): the chapters'
## row, a gap, the area (the grid or one card).
const MIN_W := 476.0
const ROW := 44.0
const GAP := 6.0
const AREA := 204.0
const CHIP_GAP := 4.0
const TITLE_H := 20.0
const BACK_W := 76.0
## Loop MW-6: the extra sections' grid (columns x rows a page) and their icons (7 x 5 pixels).
const XCOLS := 5
const XROWS := 3
const PAGE_W := 52.0
const ICON_PX := 2.2
const ICONS := {
	"eggs": ["..###..", ".#####.", "#######", "#######", ".#####."],
	"tape": ["#######", "#.###.#", "#######", "##...##", "#######"],
	"kadr": ["..##...", "#######", "###.###", "##...##", "#######"],
}
const SECTIONS := [["eggs", "SEKRETY", "EASTER EGGS"], ["tape", "KASETA", "TAPE"], ["kadr", "KADR", "PHOTO SPOTS"]]
## Polish day names to English ones, for the hours' gloss.
const DAYS := {"PN": "Mon", "WT": "Tue", "ŚR": "Wed", "CZ": "Thu", "PT": "Fri", "SB": "Sat", "ND": "Sun"}

var pt := 1.0
## The notebook (notebook.gd): chapters, places, the record.
var book: Node
## The chapter shown (its index; loop MW-6: past the chapters, the extra sections) and the card
## open ("" for the grid).
var chapter := 0
var card := ""
## Loop MW-6: the extra sections' sources (null: that chip is left out): egg_book.gd, tape.gd and
## fotka.gd (its `spots`, `photo_of`), and the page of the section's grid.
var eggs: Node
var tape: Node
var kadr: Node
var page := 0
var _photo: ImageTexture
var _photo_id := ""
var _photo_rect := Rect2()
## The page's width in points (settings_panel.gd sets it to the card's inner width).
var W := MIN_W
## What a tap hits: [Rect2, "chapter" | "card" | "back", value], rebuilt by each draw.
var _hits: Array = []
var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()
## Words to draw after the boxes, by size: size -> [[pos, text, colour, width, align, lines]].
var _words := {}
## The gamepad follow-ups: the pad's cursor over the drawn targets ("kind:value" of a hit) while
## the page has focus (settings_panel.gd `pad_focus` gives it FOCUS_ALL), and the cursor to come
## back to when an open card is left.
var cursor := ""
var _cursor_back := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(MIN_W, ROW + GAP + AREA) * pt
	gui_input.connect(_on_input)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


## Shows a chapter (index, id or number "1"-"9") or a place's card (its id): --notebook=.
func show_target(target: String) -> void:
	card = ""
	if book == null or target == "":
		queue_redraw()
		return
	page = 0
	if book.by_id.has(target):
		var place: Dictionary = book.places[book.by_id[target]]
		chapter = int(place["chapter_i"])
		card = target
	elif _section_target(target):
		pass
	else:
		for i in book.chapters.size():
			if str(book.chapters[i]["id"]) == target or str(i + 1) == target:
				chapter = i
	queue_redraw()


## Loop MW-6: "eggs" / "tape" / "kadr" (a section), or one of their cards' ids.
func _section_target(target: String) -> bool:
	var names := _sections()
	for k in names.size():
		var src := _source(names[k])
		if names[k] == target:
			chapter = book.chapters.size() + k
			return true
		if src != null:
			var list := _items(names[k])
			for j in list.size():
				if str(list[j]["id"]) == target:
					chapter = book.chapters.size() + k
					page = j / (XCOLS * XROWS)
					card = "%s:%s" % [names[k], target]
					return true
	return false


## The extra sections shown (those whose source is set).
func _sections() -> Array[String]:
	var out: Array[String] = []
	for sec: Array in SECTIONS:
		if _source(sec[0]) != null:
			out.append(sec[0])
	return out


func _source(name: String) -> Node:
	match name:
		"eggs":
			return eggs
		"tape":
			return tape
		"kadr":
			return kadr
	return null


## A section's cards: egg_book `eggs`, tape `spots`, fotka `spots`.
func _items(name: String) -> Array:
	var src := _source(name)
	if src == null:
		return []
	return src.get("eggs") if name == "eggs" else src.get("spots")


func _item_found(name: String, item: Dictionary) -> int:
	var w: Node = book.wallet
	if w == null:
		return 0
	var id := str(item["id"])
	match name:
		"eggs":
			return int(w.eggs.get(id, 0))
		"tape":
			return int(w.tapes.get(id, 0))
		"kadr":
			return int(w.kadr.get(id, 0))
	return 0


func _found_count(name: String) -> int:
	var n := 0
	for it: Dictionary in _items(name):
		n += int(_item_found(name, it) > 0)
	return n


## The touch targets in global pixels, by name (tools/check_hud.gd: 44 pt each way).
func hit_rects() -> Dictionary:
	var out := {}
	for h: Array in _hits:
		var r: Rect2 = h[0]
		out["notebook_%s_%s" % [h[1], h[2]]] = Rect2(get_global_transform() * r.position, r.size * get_global_transform().get_scale())
	return out


func _on_input(e: InputEvent) -> void:
	if has_focus() and _pad_input(e):
		accept_event()
		queue_redraw()
		return
	var mb := e as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for h: Array in _hits:
		if (h[0] as Rect2).has_point(mb.position):
			activate(h)
			accept_event()
			queue_redraw()
			return


## A tap or the pad's A on a target: [Rect2, kind, value].
func activate(h: Array) -> void:
	match str(h[1]):
		"chapter":
			chapter = int(h[2])
			card = ""
			page = 0
		"card":
			_cursor_back = cursor
			card = str(h[2])
		"back":
			card = ""
			cursor = _cursor_back
		"page":
			page += int(h[2])


## The gamepad follow-ups: the D-pad / stick moves the cursor to the nearest target that way, A
## opens it, B leaves an open card. False (not taken) when nothing lies that way, so the focus
## moves on to the tabs, or for B on the grid, so the card closes.
func _pad_input(e: InputEvent) -> bool:
	for d: Array in [["ui_left", Vector2.LEFT], ["ui_right", Vector2.RIGHT], ["ui_up", Vector2.UP], ["ui_down", Vector2.DOWN]]:
		if e.is_action_pressed(d[0], true):
			return move_cursor(d[1])
	if e.is_action_pressed("ui_accept"):
		var h := cursor_hit()
		if not h.is_empty():
			activate(h)
		return not h.is_empty()
	if e.is_action_pressed("ui_cancel") and card != "":
		activate([Rect2(), "back", ""])
		return true
	return false


static func hit_key(h: Array) -> String:
	return "%s:%s" % [h[1], h[2]]


## The target under the cursor: its own, else an open card's WRÓĆ, else the first.
func cursor_hit() -> Array:
	var back: Array = []
	for h: Array in _hits:
		if hit_key(h) == cursor:
			return h
		if str(h[1]) == "back":
			back = h
	if not back.is_empty():
		return back
	return _hits[0] if not _hits.is_empty() else []


## Moves the cursor to the closest target whose centre lies `dir` of the cursor's (across counts
## double); false when there is none.
func move_cursor(dir: Vector2) -> bool:
	var at := cursor_hit()
	if at.is_empty():
		return false
	var c := (at[0] as Rect2).get_center()
	var best: Array = []
	var best_score := INF
	for h: Array in _hits:
		var d := (h[0] as Rect2).get_center() - c
		var along := d.dot(dir)
		if along <= 1.0:
			continue
		var score := along + absf(d.cross(dir)) * 2.0
		if score < best_score:
			best_score = score
			best = h
	if best.is_empty():
		return false
	cursor = hit_key(best)
	return true


# --- drawing -------------------------------------------------------------------------------

func _draw() -> void:
	W = maxf(MIN_W, size.x / pt)
	_hits.clear()
	_pts.clear()
	_cols.clear()
	_words.clear()
	if book == null or book.chapters.is_empty():
		_word(Vector2.ZERO, "Zeszyt pusty", T_BODY, SUB)
		_flush()
		return
	var extra := _sections()
	chapter = clampi(chapter, 0, book.chapters.size() + extra.size() - 1)
	_chapters_row()
	if chapter >= book.chapters.size():
		var sec: String = extra[chapter - book.chapters.size()]
		if card.begins_with(sec + ":"):
			_extra_card(sec, card.trim_prefix(sec + ":"))
		else:
			_extra_grid(sec)
	elif card != "" and book.by_id.has(card):
		_card_view(book.places[book.by_id[card]])
	else:
		_grid_view()
	if not card.begins_with("kadr:") and _photo != null:
		_photo = null
		_photo_id = ""
	_flush()
	if has_focus():
		# The gamepad follow-ups: the cursor's ring (only while the pad has the page: +1 draw call).
		var h := cursor_hit()
		if not h.is_empty():
			draw_rect((h[0] as Rect2).grow(2.0 * pt), ACCENT, false, maxf(2.0, 2.0 * pt))


## A [Polish, English] pair in the chosen language (lang.gd): the page shows one language.
static func _l(pair: Array) -> String:
	return Lang.pick(str(pair[0]), str(pair[1]) if pair.size() > 1 else "")


func _chapters_row() -> void:
	var extra := _sections()
	var n: int = book.chapters.size() + extra.size()
	var w := (W - CHIP_GAP * (n - 1)) / n
	for i in n:
		if i >= book.chapters.size():
			_section_chip(Rect2(Vector2(i * (w + CHIP_GAP), 0.0) * pt, Vector2(w, ROW) * pt), i, extra[i - book.chapters.size()])
			continue
		var r := Rect2(Vector2(i * (w + CHIP_GAP), 0.0) * pt, Vector2(w, ROW) * pt)
		var k: int = book.found_in(i)
		var total: int = book.chapter_places(i).size()
		_box(r, ON if i == chapter else DIM, ACCENT if i == chapter else EDGE, 1.0 if i == chapter else 0.5)
		var done := total > 0 and k >= total
		_word(r.position + Vector2(0, 4.0 * pt), str(i + 1), T_BODY, GOLD if done else INK, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_word(r.position + Vector2(0, 24.0 * pt), "%d/%d" % [k, total], T_LABEL, GOLD if done else SUB, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_hits.append([r, "chapter", i])


func _grid_view() -> void:
	var c: Dictionary = book.chapters[chapter]
	var top := (ROW + GAP) * pt
	var title := Lang.pick(str(c["name_pl"]), str(c["name_en"])).to_upper()
	_word(Vector2(0, top), title, T_SUB, ACCENT)
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB)).x
	var list: Array = book.chapter_places(chapter)
	_word(Vector2(tw + 8.0 * pt, top + 2.0 * pt), "%d/%d" % [book.found_in(chapter), list.size()], T_LABEL, SUB)
	# Map north: a chapter of 9 or 10 (Notebook.MAX_PER_CHAPTER) takes 5 columns, still 2 rows.
	var cols := 4 if list.size() <= 8 else 5
	var cw := (W - GAP * (cols - 1)) / cols
	var ch := (AREA - TITLE_H - GAP) / 2.0
	for k in list.size():
		var place: Dictionary = list[k]
		var at := Vector2((k % cols) * (cw + GAP), ROW + GAP + TITLE_H + (k / cols) * (ch + GAP))
		var r := Rect2(at * pt, Vector2(cw, ch - GAP * 0.5) * pt)
		var id := str(place["id"])
		_hits.append([r, "card", id])
		var inner := r.size.x - 12.0 * pt
		if book.is_found(id):
			_box(r, DIM, EDGE, 0.5)
			var y := r.position.y + 8.0 * pt
			var pl := Lang.pick(str(place["name_pl"]), str(place["name_en"]))
			var lines := _lines(pl, T_SUB, inner, 3)
			_word(Vector2(r.position.x + 6.0 * pt, y), pl, T_SUB, INK, inner, HORIZONTAL_ALIGNMENT_LEFT, 3)
			y += lines * _line_h(T_SUB)
			# The foot: the night venue's hours over the day it was found.
			var foot := PackedStringArray()
			if place.has("hours"):
				foot.append(str(place["hours"]))
			var day := int(book.wallet.notes.get(id, 0)) if book.wallet != null else 0
			if day > 0:
				foot.append("%02d.%02d.%04d" % [day % 100, (day / 100) % 100, day / 10000])
			var foot_y := r.end.y - 5.0 * pt - foot.size() * _line_h(T_LABEL)
			for f in foot.size():
				_word(Vector2(r.position.x + 6.0 * pt, foot_y + f * _line_h(T_LABEL)), foot[f], T_LABEL,
						ACCENT if f == 0 and place.has("hours") else SUB, inner)
			var en := pl  # one language: no second name line
			if en != pl and y + _line_h(T_LABEL) < foot_y:
				_word(Vector2(r.position.x + 6.0 * pt, y), en, T_LABEL, SUB, inner, HORIZONTAL_ALIGNMENT_LEFT,
						maxi(1, int((foot_y - y) / _line_h(T_LABEL))))
		else:
			_box(r, SHUT, EDGE, 0.5)
			_word(Vector2(r.position.x, r.position.y + r.size.y * 0.5 - _line_h(T_BIG) * 0.75), "?", T_BIG, SUB,
					r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			_word(Vector2(r.position.x, r.end.y - _line_h(T_LABEL) - 5.0 * pt), Lang.pick("rozdz. %d", "ch. %d") % (chapter + 1),
					T_LABEL, SUB, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _card_view(place: Dictionary) -> void:
	var c: Dictionary = book.chapters[chapter]
	var top := (ROW + GAP) * pt
	var back := Rect2(Vector2(0, top), Vector2(BACK_W, ROW) * pt)
	_box(back, DIM, EDGE, 0.5)
	_word(back.position + Vector2(0, 14.0 * pt), Lang.pick("WRÓĆ", "BACK"), T_BODY, INK, back.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_hits.append([back, "back", 0])
	var x := (BACK_W + 10.0) * pt
	var wide := W * pt - x
	var id := str(place["id"])
	var list: Array = book.chapter_places(chapter)
	var where := "%d/%d · %s" % [list.find(place) + 1, list.size(), Lang.pick(c["name_pl"], c["name_en"])]
	if not book.is_found(id):
		_word(Vector2(x, top + 2.0 * pt), "?", T_BIG, ACCENT, wide)
		_word(Vector2(x, top + 28.0 * pt), where, T_LABEL, SUB, wide)
		var y := top + (ROW + 14.0) * pt
		_word(Vector2(0, y), Lang.pick("Jeszcze nie w zeszycie. Szukaj „?” na minimapie.", "Not in the notebook yet. Look for the ? on the minimap."), T_SUB, INK, W * pt)
		return
	_word(Vector2(x, top + 2.0 * pt), Lang.pick(str(place["name_pl"]), str(place["name_en"])), T_BODY, ACCENT, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
	_word(Vector2(x, top + 24.0 * pt), where, T_LABEL, SUB, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
	var y := top + (ROW + 12.0) * pt
	var full := W * pt
	for pair in [place.get("fact", ["", ""]), place.get("joke", ["", ""])]:
		var a: Array = pair
		var fact := _l(a)
		_word(Vector2(0, y), fact, T_SUB, INK, full, HORIZONTAL_ALIGNMENT_LEFT, 2)
		y += _lines(fact, T_SUB, full, 2) * _line_h(T_SUB) + 8.0 * pt
	var meta := meta_lines(place, int(book.wallet.notes.get(id, 0)) if book.wallet != null else 0)
	_word(Vector2(0, y), _l(meta), T_LABEL, ACCENT, full, HORIZONTAL_ALIGNMENT_LEFT, 1)


## A card's last two lines, Polish over English: the address of a place that is not a venue
## (without the anchor's notes in brackets), the hours of a night venue, the day it was found.
static func meta_lines(place: Dictionary, found: int) -> Array[String]:
	var pl := PackedStringArray()
	var en := PackedStringArray()
	# Never a venue's address: it can name the real business there ("Jasna 1": brand_denylist.json).
	if place.has("address") and not "venue" in place.get("tags", []):
		var a := str(place["address"])
		if a.contains("("):
			a = a.substr(0, a.find("(")).strip_edges()
		pl.append(a)
	if place.has("hours"):
		var h := str(place["hours"])
		pl.append("otwarte %s" % h)
		var g := h
		for d: String in DAYS:
			g = g.replace(d, DAYS[d])
		en.append("open %s" % g)
	if found > 0:
		var date := "%02d.%02d.%04d" % [found % 100, (found / 100) % 100, found / 10000]
		pl.append("wpis z %s" % date)
		en.append("found %s" % date)
	return [" · ".join(pl), " · ".join(en)]


# --- loop MW-6: the eggs, the tape and the photo spots ---------------------------------------

func _section_chip(r: Rect2, i: int, name: String) -> void:
	var k := _found_count(name)
	var total := _items(name).size()
	var done := total > 0 and k >= total
	_box(r, ON if i == chapter else DIM, ACCENT if i == chapter else EDGE, 1.0 if i == chapter else 0.5)
	_icon(r.position + Vector2(r.size.x * 0.5, 13.0 * pt), ICONS[name], GOLD if done else INK)
	_word(r.position + Vector2(0, 24.0 * pt), "%d/%d" % [k, total], T_LABEL, GOLD if done else SUB, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_hits.append([r, "chapter", i])


## A 7 x 5 pixel icon centred on `c`.
func _icon(c: Vector2, rows: Array, col: Color) -> void:
	var px := ICON_PX * pt
	var origin := c - Vector2(3.5, 2.5) * px
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			if line[x] == "#":
				_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px, px)), col)


func _section_title(name: String) -> Array:
	for sec: Array in SECTIONS:
		if sec[0] == name:
			return [sec[1], sec[2]]
	return [name, ""]


func _extra_grid(name: String) -> void:
	var list := _items(name)
	var per := XCOLS * XROWS
	var pages := maxi(1, ceili(list.size() / float(per)))
	page = clampi(page, 0, pages - 1)
	var top := (ROW + GAP) * pt
	var t := _section_title(name)
	var font := ThemeDB.fallback_font
	var head := _l(t)
	_word(Vector2(0, top), head, T_SUB, ACCENT)
	var tw := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB)).x
	var sub := "%d/%d" % [_found_count(name), list.size()]
	if pages > 1:
		sub += Lang.pick(" · str. %d/%d", " · page %d/%d") % [page + 1, pages]
	_word(Vector2(tw + 8.0 * pt, top + 2.0 * pt), sub, T_LABEL, SUB)
	var area_top := ROW + GAP + TITLE_H
	var grid_w := W
	var ch := (AREA - TITLE_H - GAP) / XROWS
	if pages > 1:
		# ‹ over › in a column at the grid's right (each half the grid's height, 52 pt wide).
		grid_w = W - PAGE_W - GAP
		var bh := (AREA - TITLE_H - GAP) * 0.5 - GAP * 0.5
		for k in 2:
			var pr := Rect2(Vector2(grid_w + GAP, area_top + k * (bh + GAP)) * pt, Vector2(PAGE_W, bh) * pt)
			var live := (k == 0 and page > 0) or (k == 1 and page < pages - 1)
			_box(pr, DIM if live else SHUT, EDGE, 0.5)
			_word(pr.position + Vector2(0, pr.size.y * 0.5 - _line_h(T_BIG) * 0.6), "‹" if k == 0 else "›", T_BIG,
					INK if live else SUB, pr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			if live:
				_hits.append([pr, "page", -1 if k == 0 else 1])
	var cw := (grid_w - GAP * (XCOLS - 1)) / XCOLS
	for j in range(page * per, mini(list.size(), (page + 1) * per)):
		var k := j - page * per
		var it: Dictionary = list[j]
		var at := Vector2((k % XCOLS) * (cw + GAP), area_top + (k / XCOLS) * (ch + GAP * 0.5))
		var w := cw
		var r := Rect2(at * pt, Vector2(w, ch - GAP * 0.5) * pt)
		var id := str(it["id"])
		_hits.append([r, "card", "%s:%s" % [name, id]])
		var inner := r.size.x - 10.0 * pt
		var num := _number(name, it)
		if _item_found(name, it) > 0:
			_box(r, DIM, EDGE, 0.5)
			_word(Vector2(r.position.x + 5.0 * pt, r.position.y + 5.0 * pt), _fit(_l(_item_name(name, it)), T_LABEL, inner, 2),
					T_LABEL, INK, inner, HORIZONTAL_ALIGNMENT_LEFT, 2)
			_word(Vector2(r.position.x + 5.0 * pt, r.end.y - _line_h(T_LABEL) - 3.0 * pt), num, T_LABEL, GOLD, inner)
		else:
			_box(r, SHUT, EDGE, 0.5)
			_word(Vector2(r.position.x, r.position.y + r.size.y * 0.5 - _line_h(T_BODY) * 0.62), "?", T_BODY, SUB,
					r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			_word(Vector2(r.position.x + 5.0 * pt, r.end.y - _line_h(T_LABEL) - 3.0 * pt), num, T_LABEL, SUB, inner)


## A card's number label: "E07", "1/40" for the old eggs' cards, a then card's year, "K03".
func _number(name: String, it: Dictionary) -> String:
	var id := str(it["id"])
	match name:
		"eggs":
			return id.to_upper() if id.begins_with("e") and id.length() == 3 else "v0.65"
		"tape":
			return str(int(it.get("year", 0)))
		"kadr":
			return id.to_upper()
	return id


func _item_name(name: String, it: Dictionary) -> Array:
	match name:
		"eggs", "kadr":
			return it["name"]
		"tape":
			var pid := str(it.get("place", ""))
			if book.by_id.has(pid):
				var p: Dictionary = book.places[book.by_id[pid]]
				return [str(p["name_pl"]), str(p["name_en"])]
			return [pid, pid]
	return ["", ""]


func _extra_card(name: String, id: String) -> void:
	var list := _items(name)
	var it: Dictionary = {}
	for x: Dictionary in list:
		if str(x["id"]) == id:
			it = x
	if it.is_empty():
		card = ""
		_extra_grid(name)
		return
	var top := (ROW + GAP) * pt
	var back := Rect2(Vector2(0, top), Vector2(BACK_W, ROW) * pt)
	_box(back, DIM, EDGE, 0.5)
	_word(back.position + Vector2(0, 14.0 * pt), Lang.pick("WRÓĆ", "BACK"), T_BODY, INK, back.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_hits.append([back, "back", 0])
	var x := (BACK_W + 10.0) * pt
	var wide := W * pt - x
	var t := _section_title(name)
	var found := _item_found(name, it)
	var nm := _item_name(name, it)
	var where := "%s · %s · %d/%d" % [_number(name, it), _l(t), list.find(it) + 1, list.size()]
	var full := W * pt
	var y := top + (ROW + 12.0) * pt
	if found <= 0:
		_word(Vector2(x, top + 2.0 * pt), "?" if name == "eggs" else _l(nm), T_BODY, ACCENT, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
		_word(Vector2(x, top + 24.0 * pt), where, T_LABEL, SUB, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
		var hint := _hint(name, it)
		_word(Vector2(0, y), _l(hint), T_SUB, INK, full, HORIZONTAL_ALIGNMENT_LEFT, 2)
		return
	_word(Vector2(x, top + 2.0 * pt), _l(nm), T_BODY, ACCENT, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
	_word(Vector2(x, top + 24.0 * pt), where, T_LABEL, SUB, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
	var line: Array = ["", ""]
	var meta := ["wpis z %s" % date_of(found), "found %s" % date_of(found)]
	match name:
		"eggs":
			line = eggs.line_of(it)
			var rw: Array = eggs.reward_text(it)
			meta = ["%s · %s" % [rw[0], meta[0]], "%s · %s" % [rw[1], meta[1]]]
		"tape":
			line = it["line"]
			meta = ["kaseta z %d · %s" % [int(it["year"]), meta[0]], "the tape of %d · %s" % [int(it["year"]), meta[1]]]
		"kadr":
			line = [kadr.look_text(it)[0], kadr.look_text(it)[1]]
	var text_w := full
	if name == "kadr":
		var tex := _photo_for(id)
		if tex != null:
			# The player's own photo, at the card's right (16:9, 90 pt high at most).
			var ph := 90.0 * pt
			var pw := ph * tex.get_width() / maxf(1.0, tex.get_height())
			var pr := Rect2(Vector2(full - pw, y), Vector2(pw, ph))
			_rect(pr.grow(maxf(1.0, pt)), EDGE)
			_photo_rect = pr
			text_w = full - pw - 10.0 * pt
	var shown := _l(line)
	_word(Vector2(0, y), shown, T_SUB, INK, text_w, HORIZONTAL_ALIGNMENT_LEFT, 2)
	y += _lines(shown, T_SUB, text_w, 2) * _line_h(T_SUB) + 8.0 * pt
	_word(Vector2(0, y), _l(meta), T_LABEL, ACCENT, text_w, HORIZONTAL_ALIGNMENT_LEFT, 1)


## What an unfound card says, Polish and English.
func _hint(name: String, it: Dictionary) -> Array:
	match name:
		"eggs":
			if it.has("waits"):
				return ["Ten sekret jeszcze śpi. Obudzi się w nowej wersji.", "This secret is still asleep. It wakes up in an update."]
			return ["Jeszcze nie znaleziony. Miasto ma swoje sekrety.", "Not found yet. The city keeps its secrets."]
		"tape":
			var nm := _item_name(name, it)
			return ["Stań przy: %s i włącz KASETĘ." % nm[0], "Stop by %s and play the TAPE." % nm[1]]
		"kadr":
			var lt: Array = kadr.look_text(it)
			return ["Zrób tu zdjęcie w Fotce. %s" % lt[0], "Take a photo here in Fotka. %s" % lt[1]]
	return ["", ""]


static func date_of(ymd: int) -> String:
	if ymd <= 1:
		return "?"
	return "%02d.%02d.%04d" % [ymd % 100, (ymd / 100) % 100, ymd / 10000]


## The Kadr spot's photo, loaded only while its card is open (and dropped with it).
func _photo_for(id: String) -> ImageTexture:
	if _photo_id == id:
		return _photo
	_photo_id = id
	_photo = null
	var path := str(book.wallet.kadr_photos.get(id, "")) if book.wallet != null else ""
	if path != "" and FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			img.resize(maxi(1, img.get_width() * 120 / maxi(1, img.get_height())), 120, Image.INTERPOLATE_BILINEAR)
			_photo = ImageTexture.create_from_image(img)
	return _photo


# --- pieces --------------------------------------------------------------------------------

func _line_h(points: float) -> float:
	return ThemeDB.fallback_font.get_height(_px(points))


## How many lines `text` takes at `width` pixels (at most `most`).
func _lines(text: String, points: float, width: float, most: int) -> int:
	if text == "":
		return 0
	var font := ThemeDB.fallback_font
	var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, _px(points), most).y
	return clampi(roundi(h / font.get_height(_px(points))), 1, most)


## `text` cut at a word with "…" so it fits `most` lines `width` px wide (a long name on a small
## card: "Palma na rondzie…").
func _fit(text: String, points: float, width: float, most: int) -> String:
	var font := ThemeDB.fallback_font
	var line := font.get_height(_px(points))
	var t := text
	var words := text.split(" ", false)
	while words.size() > 1 and font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, width, _px(points)).y > line * most + 0.5:
		words.remove_at(words.size() - 1)
		t = " ".join(words) + "…"
	return t


## Queues words: `at` is the top left of their first line.
func _word(at: Vector2, text: String, points: float, colour: Color, width := -1.0,
		align := HORIZONTAL_ALIGNMENT_LEFT, lines := 1) -> void:
	if text == "":
		return
	if not _words.has(points):
		_words[points] = []
	_words[points].append([at, text, colour, width, align, lines])


## A box: its edge (`ew` pt), the card's colour inside it, then its fill; round corners.
func _box(r: Rect2, fill: Color, edge: Color, ew: float) -> void:
	var e := maxf(1.0, ew * pt)
	_round(r, 8.0 * pt, edge)
	_round(r.grow(-e), 8.0 * pt - e, UNDER)
	_round(r.grow(-e), 8.0 * pt - e, fill)


func _rect(r: Rect2, col: Color) -> void:
	var b := Vector2(r.end.x, r.position.y)
	var d := Vector2(r.position.x, r.end.y)
	_pts.append_array(PackedVector2Array([r.position, b, r.end, r.position, r.end, d]))
	for i in 6:
		_cols.append(col)


func _round(r: Rect2, radius: float, col: Color) -> void:
	var k := clampf(radius, 0.0, minf(r.size.x, r.size.y) * 0.5)
	_rect(r.grow_individual(0.0, -k, 0.0, -k), col)
	_rect(Rect2(r.position + Vector2(k, 0.0), Vector2(r.size.x - 2.0 * k, k)), col)
	_rect(Rect2(Vector2(r.position.x + k, r.end.y - k), Vector2(r.size.x - 2.0 * k, k)), col)
	var corners := [[r.position + Vector2(k, k), PI], [Vector2(r.end.x - k, r.position.y + k), PI * 1.5],
			[r.end - Vector2(k, k), 0.0], [Vector2(r.position.x + k, r.end.y - k), PI * 0.5]]
	for cn: Array in corners:
		var c: Vector2 = cn[0]
		var a0: float = cn[1]
		for s in 4:
			var u := a0 + PI * 0.5 * s / 4.0
			var v := a0 + PI * 0.5 * (s + 1) / 4.0
			_pts.append_array(PackedVector2Array([c, c + Vector2(cos(u), sin(u)) * k, c + Vector2(cos(v), sin(v)) * k]))
			for i in 3:
				_cols.append(col)


## The boxes in one call, then the words size by size.
func _flush() -> void:
	var n := _pts.size()
	if n > 0:
		if _idx.size() < n:
			for i in range(_idx.size(), n):
				_idx.append(i)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _idx.slice(0, n), _pts, _cols)
	if _photo != null and card.begins_with("kadr:"):
		draw_texture_rect(_photo, _photo_rect, false)
	var font := ThemeDB.fallback_font
	for points: float in [T_BIG, T_BODY, T_SUB, T_LABEL]:
		var fs := _px(points)
		var ascent := font.get_ascent(fs)
		for w: Array in _words.get(points, []):
			var at: Vector2 = w[0] + Vector2(0, ascent)
			if int(w[5]) > 1:
				draw_multiline_string(font, at, w[1], w[4], w[3], fs, int(w[5]), w[2])
			else:
				draw_string(font, at, w[1], w[4], w[3], fs, w[2])
