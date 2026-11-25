extends Control
## THE TAPCZAN's room UI in padel's pixel look (docs/design/tapczan-pong-v2.md 2.4 to 2.6): slim
## chips top left (THE TAPCZAN, RACHUNEK n ZŁ, the wallet), anyone's line as a bubble pinned to the
## speaker's head, three action tiles on the objects (PIWKO over the taps, GRAJ over the pong
## table, WYJDŹ at the door), the rival card, and the tap list as a chalkboard docked right.
##
## It lives on a CanvasLayer of the ROOT viewport (tapczan_room.gd parents it to the HUD's parent),
## not inside the city's SubViewport: drawn there it was scaled by the image's stretch_shrink (2 on
## the phone), so a 52 pt button came out 103 pt and soft (Fable's finding, 2026-11-25). The unit
## is `u = min(screen_h / 216, 2 * pt)` screen px a canvas px: padel's pixel on a phone, no balloon
## on an iPad or the Mac; every rect snapped to whole screen pixels (pixel_kit.gd).
##
## Touch: a hit area is never under 44 pt either way (the art's rect grown). A tap on the open tap
## list's row orders it, outside it closes it; on a rival card plays; a tile acts; a tap elsewhere
## falls through to the room (people and boards, tapczan_room.gd `pick`). Polish with English.
##
## Cost: one Control's _draw of untextured rects, redrawn only on a change (a line, the bill, open
## or close, a press); _process runs only while a bubble or the bill's flash is up. No Button,
## Label or StyleBox.

const Kit := preload("res://scripts/pixel_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")

## Canvas rows on any screen (padel's).
const H := 216.0
const BUBBLE_W := 142.0
const BUBBLE_S := 4.0
const FLASH_S := 0.4
const TOUCH_PT := 44.0
const BOARD := Vector2(202, 190)
const ROW_H := 25.0
const CARD := Vector2(96, 92)

## A tile was tapped: "beer", "play" or "leave".
signal tile(id: String)
## A beer off the board.
signal tap_picked(id: String)
## A rival's card.
signal rival_picked(id: String)

## (Vector3 world) -> Vector2 root-viewport px (the room's camera through the city image's scale).
var project := Callable()
## The tiles' world anchors {id: Vector3}.
var anchors: Dictionary = {}
## The words (tapczan_room.gd statics): Callable(key) -> [pl, en].
var words := Callable()
## The rivals' card data: [{id, short, stake, how, last}] in the card's order.
var rivals: Array = []
## The tap list: [{id, name, sub, price, colour}].
var taps: Array = []
var u := 2.0
var pt := 1.0
var safe := Rect2()
var bill := 0
var wallet := 0
var taps_open := false
var rivals_open := false
## The line up now ("" none).
var line_text := ""
var line_who := ""

var _line_at := Vector3.INF
var _line_c := Kit.AMBER
var _line_t := 0.0
var _flash_t := 0.0
var _press := ""
var _press_t := 0.0
var _rects: Dictionary = {}
var _pen: Kit


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pen = Kit.new(self)
	get_viewport().size_changed.connect(_measure)
	_measure()
	set_process(false)


func _measure() -> void:
	var s := get_viewport().get_visible_rect().size
	var m := ScreenPoints.measure(s)
	pt = float(m["pt"])
	safe = m["safe"]
	u = minf(s.y / H, 2.0 * pt)
	_pen.u = u
	queue_redraw()


func _w(key: String) -> String:
	var p: Array = words.call(key) if words.is_valid() else [key, key]
	return Lang.pick(str(p[0]), str(p[1]))


## The canvas size (canvas px).
func canvas() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	return s / u


# --- the API (tapczan_room.gd) -----------------------------------------------------------------

## Anyone's line, pinned over `at` (world; Vector3.INF: under the chips), gone after 4 s or a tap.
func show_line(who: String, text: String, at := Vector3.INF, colour := Kit.AMBER) -> void:
	line_who = who
	line_text = text
	_line_at = at
	_line_c = colour
	_line_t = BUBBLE_S
	set_process(true)
	queue_redraw()


func hide_line() -> void:
	line_text = ""
	queue_redraw()


## The bill and the wallet; the bill chip flashes gold for 0.4 s when it grows.
func set_bill(b: int, w: int) -> void:
	if b > bill:
		_flash_t = FLASH_S
		set_process(true)
	bill = b
	wallet = w
	queue_redraw()


func open_taps() -> void:
	taps_open = true
	rivals_open = false
	queue_redraw()


func open_rivals() -> void:
	rivals_open = true
	taps_open = false
	queue_redraw()


func close_all() -> void:
	taps_open = false
	rivals_open = false
	queue_redraw()


func _process(dt: float) -> void:
	var busy := false
	if line_text != "":
		_line_t -= dt
		if _line_t <= 0.0:
			line_text = ""
			queue_redraw()
		else:
			busy = true
	if _flash_t > 0.0:
		_flash_t -= dt
		busy = true
		if _flash_t <= 0.0:
			queue_redraw()
	if _press_t > 0.0:
		_press_t -= dt
		busy = true
		if _press_t <= 0.0:
			_press = ""
			queue_redraw()
	if not busy:
		set_process(false)


# --- drawing ------------------------------------------------------------------------------------

## A screen point in canvas px.
func _c(p: Vector2) -> Vector2:
	return p / u


## Grow a canvas rect to the 44 pt touch minimum, both ways.
func _hit(r: Rect2) -> Rect2:
	var m := ceilf(TOUCH_PT * pt / u)
	var g := r
	if g.size.x < m:
		g = g.grow_individual((m - g.size.x) * 0.5, 0, (m - g.size.x) * 0.5, 0)
	if g.size.y < m:
		g = g.grow_individual(0, (m - g.size.y) * 0.5, 0, (m - g.size.y) * 0.5)
	return g


func _draw() -> void:
	_rects.clear()
	var cv := canvas()
	var p := _pen
	var left := maxf(4.0, ceilf(safe.position.x / u) + 2.0)
	var right := cv.x - maxf(4.0, ceilf((get_viewport().get_visible_rect().size.x - safe.end.x) / u) + 2.0)
	# The chips: not buttons.
	var x := left
	x += p.chip(x, 4, "THE TAPCZAN", Kit.AMBER) + 3.0
	var bc := Kit.GOLD if _flash_t > 0.0 else Kit.LINE
	x += p.chip(x, 4, _w("bill_chip") % bill, bc, "bill", 0.0, Kit.GOLD if _flash_t > 0.0 else Kit.SLATE_L) + 3.0
	p.chip(x, 4, _w("wallet_chip") % wallet, Kit.GOLD, "wallet")
	# The tiles over their objects.
	if not taps_open and not rivals_open:
		for id: String in ["beer", "play", "leave"]:
			if not anchors.has(id) or not project.is_valid():
				continue
			var at := _c(project.call(anchors[id]))
			at.x = clampf(at.x, left + 14.0, right - 14.0)
			at.y = clampf(at.y, 34.0, cv.y - 50.0)
			var key := {"beer": "tile_beer", "play": "tile_play", "leave": "tile_leave"}[id] as String
			var icon := {"beer": "beer", "play": "pong", "leave": "door"}[id] as String
			p.tile(at.x, at.y, _w(key), icon, id != "leave", _press == "t:" + id)
			_rects["t:" + id] = _hit(Rect2(at.x - 12.0, at.y - 12.0, 25.0, 37.0))
	# The bubble.
	if line_text != "":
		var lines := Kit.wrap(line_text, int(BUBBLE_W - 10.0))
		var h := 6.0 + lines.size() * 10.0
		var anchor := Vector2(left + 40.0, 30.0 + h)
		var down := true
		if _line_at != Vector3.INF and project.is_valid():
			anchor = _c(project.call(_line_at))
		var bx := clampf(anchor.x - BUBBLE_W * 0.5, left, (right if not taps_open else cv.x - BOARD.x - 8.0) - BUBBLE_W)
		var by := anchor.y - h - 6.0
		if by < 26.0:
			by = anchor.y + 14.0
			down = false
		by = clampf(by, 26.0, cv.y - h - 4.0)
		var tail := clampf(anchor.x, bx + 6.0, bx + BUBBLE_W - 8.0)
		p.bubble(bx, by, BUBBLE_W, line_who, lines, tail, _line_c, down)
		_rects["bubble"] = Rect2(bx, by - 6.0, BUBBLE_W, h + 6.0)
	if taps_open:
		_draw_board(cv, right)
	if rivals_open:
		_draw_rivals(cv)


func _draw_board(cv: Vector2, right: float) -> void:
	var p := _pen
	var bx := minf(right, cv.x - 2.0) - BOARD.x
	var by := clampf((cv.y - BOARD.y) * 0.5 + 8.0, 22.0, cv.y - BOARD.y - 2.0)
	_rects["board"] = Rect2(bx, by, BOARD.x, BOARD.y)
	p.rect(bx - 3, by - 3, BOARD.x + 6, BOARD.y + 6, Kit.WOOD_D)
	p.rect(bx - 3, by - 3, BOARD.x + 6, 1, Kit.WOOD)
	p.rect(bx, by, BOARD.x, BOARD.y, Kit.BOARD)
	p.text(_w("taps_head"), bx + 8, by + 3, Kit.LINE)
	var hw := Kit.text_w(_w("taps_head"))
	p.text(_w("taps_sub"), bx + 14 + hw, by + 3, Kit.CHALK_D)
	for i in range(0, int(hw + 2.0), 3):
		p.rect(bx + 8 + i, by + 13, 2, 1, Kit.AMBER)
	# The close cross (art 9, hit 44 pt).
	var cx := bx + BOARD.x - 12.0
	var cy := by + 8.0
	for i in range(-3, 4):
		p.px(cx + i, cy + i, Kit.LINE)
		p.px(cx + i, cy - i, Kit.LINE)
	_rects["close"] = _hit(Rect2(cx - 6.0, cy - 6.0, 12.0, 12.0))
	for i in taps.size():
		var t: Dictionary = taps[i]
		var ry := by + 20.0 + i * (ROW_H + 2.0)
		var key := "r:" + str(t["id"])
		if _press == key:
			p.rect(bx + 2, ry, BOARD.x - 4, ROW_H, Color(Kit.GOLD, 0.18))
			p.rect(bx + 2, ry, 1, ROW_H, Kit.GOLD)
		p.mug(bx + 9, ry + 7, t["colour"])
		p.text(str(t["name"]), bx + 24, ry + 1, Kit.LINE)
		p.text(str(t["sub"]), bx + 24, ry + 12, Kit.CHALK_D)
		var price := _w("wallet_chip") % int(t["price"])
		p.text(price, bx + BOARD.x - 8 - Kit.text_w(price), ry + 1, Kit.AMBER)
		for k in range(0, int(BOARD.x - 12.0), 3):
			p.px(bx + 6 + k, ry + ROW_H + 1, Kit.BOARD_L)
		_rects[key] = _hit(Rect2(bx, ry, BOARD.x, ROW_H + 2.0))


func _draw_rivals(cv: Vector2) -> void:
	var p := _pen
	var n := rivals.size()
	var total := n * CARD.x + (n - 1) * 8.0
	var x0 := roundf((cv.x - total) * 0.5)
	var y0 := roundf((cv.y - CARD.y) * 0.5) + 4.0
	p.rect(0, 0, cv.x, cv.y, Color(0, 0, 0, 0.45))
	p.text(_w("pick"), cv.x * 0.5, y0 - 18.0, Kit.LINE, 1, true, true)
	for i in n:
		var r: Dictionary = rivals[i]
		var x := x0 + i * (CARD.x + 8.0)
		var key := "c:" + str(r["id"])
		p.card(x, y0, CARD.x, CARD.y, Color(Kit.INK, 0.96) if _press != key else Color(Kit.THEM_D, 0.6), Kit.THEM)
		p.bust(x + 4, y0 + 4, str(r["id"]), 1.0, Kit.THEM)
		p.text(str(r["short"]), x + 40, y0 + 4, Kit.THEM)
		p.text(_w("wallet_chip") % int(r["stake"]), x + 40, y0 + 15, Kit.GOLD)
		var last := str(r.get("last", ""))
		if last != "":
			for li in Kit.wrap(last, int(CARD.x - 44.0)).size():
				p.text(Kit.wrap(last, int(CARD.x - 44.0))[li], x + 40, y0 + 26 + li * 9, Kit.CHALK_D)
		var how := Kit.wrap(str(r["how"]), int(CARD.x - 8.0))
		for k in mini(4, how.size()):
			p.text(how[k], x + 4, y0 + 40 + k * 10, Kit.LINE)
		_rects[key] = Rect2(x, y0, CARD.x, CARD.y)
	var bw := 70.0
	p.button(cv.x * 0.5 - bw * 0.5, y0 + CARD.y + 8.0, bw, _w("back"), false, 20.0, _press == "back")
	_rects["back"] = _hit(Rect2(cv.x * 0.5 - bw * 0.5, y0 + CARD.y + 8.0, bw, 20.0))


# --- touch --------------------------------------------------------------------------------------

## The hit rects as the next draw will place them, drawing nothing (a dry pen).
func layout() -> void:
	_pen.ci = null
	_draw()
	_pen.ci = self


## A press at root-viewport px: true when the UI took it (the room's pick is skipped).
func press(at: Vector2) -> bool:
	if not shown():
		return false
	layout()
	var c := _c(at)
	if taps_open:
		for t: Dictionary in taps:
			var key := "r:" + str(t["id"])
			if (_rects.get(key, Rect2()) as Rect2).has_point(c):
				_flash(key)
				tap_picked.emit(str(t["id"]))
				return true
		if (_rects.get("close", Rect2()) as Rect2).has_point(c) or not (_rects.get("board", Rect2()) as Rect2).has_point(c):
			close_all()
			return true
		return true
	if rivals_open:
		for r: Dictionary in rivals:
			var key := "c:" + str(r["id"])
			if (_rects.get(key, Rect2()) as Rect2).has_point(c):
				_flash(key)
				rivals_open = false
				rival_picked.emit(str(r["id"]))
				return true
		close_all()
		return true
	for id: String in ["beer", "play", "leave"]:
		if (_rects.get("t:" + id, Rect2()) as Rect2).has_point(c):
			_flash("t:" + id)
			tile.emit(id)
			return true
	if line_text != "" and (_rects.get("bubble", Rect2()) as Rect2).has_point(c):
		hide_line()
		return true
	return false


func _flash(key: String) -> void:
	_press = key
	_press_t = 0.15
	set_process(true)
	queue_redraw()


## On screen: this Control and its CanvasLayer both visible (a hidden layer does not hide its
## children's `visible`, and they would still hear touches).
func shown() -> bool:
	var layer := get_parent() as CanvasLayer
	return visible and (layer == null or layer.visible)


func _input(event: InputEvent) -> void:
	if not shown():
		return
	# Touch only: the project emulates touch from the mouse (and iOS the mouse from touch), so
	# reading both would press twice (padel's rule).
	if event is InputEventScreenTouch and event.pressed and press(event.position):
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and _rects.size() > 0 and (taps_open or rivals_open):
		get_viewport().set_input_as_handled()


## The share of the screen the UI covers now (the brief's 9.6 % with a bubble): for the log.
func coverage() -> float:
	var cv := canvas()
	var area := 0.0
	for k: String in _rects:
		var r: Rect2 = _rects[k]
		area += r.size.x * r.size.y
	return area / maxf(1.0, cv.x * cv.y)
