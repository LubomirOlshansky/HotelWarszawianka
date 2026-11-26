extends RefCounted
## The pub's pixel kit (docs/design/tapczan-pong-v2.md 2.1, 5.1 step 2): padel's palette and the
## pub's, and the sprites of THE TAPCZAN's pixel UI and beer pong drawn as flat rects through one
## pen (`ci` the CanvasItem drawn on, `u` screen px a canvas px, `o` the origin). Owner of the pub's
## pixel UI (tapczan_ui.gd at the room's unit, pong_match.gd at 1 in its 216-row canvas).
##
## Every rect is rounded to whole screen pixels on the canvas grid, so a non-integer unit (5.42 on a
## 2532x1170 phone) still draws even pixels. The 5x7 font is pixel_font.gd's, its glyphs cached
## here; capitals only (text is upper-cased, a plain " drawn as ”).
##
## Cost: draw_rect calls only (Godot batches untextured rects); nothing allocated but the glyph
## cache, once per character.

const PixelFont := preload("res://scripts/pixel_font.gd")

# --- padel's nine ---
const US := Color("#ff7a2a")
const US_D := Color("#d4501c")
const THEM := Color("#27c4dc")
const THEM_D := Color("#1784a8")
const BALL := Color("#e4f23a")
const GOLD := Color("#ffd23a")
const LINE := Color("#f2f2ea")
const FRAME := Color("#16191d")
const COURT := Color("#2d3135")
# --- the pub's ---
const BRICK := Color("#7a3324")
const BRICK_L := Color("#93432e")
const BRICK_D := Color("#5c2419")
const MORTAR := Color("#431a12")
const WOOD := Color("#7a5232")
const WOOD_L := Color("#9a6b40")
const WOOD_D := Color("#4a3220")
const COPPER := Color("#c8743a")
const COPPER_L := Color("#e89a58")
const AMBER := Color("#ffb020")
const AMBER_L := Color("#ffd98a")
const BEER := Color("#f2a51e")
const FOAM := Color("#fbf1d0")
const CUP := Color("#d4282e")
const CUP_D := Color("#9a1c22")
const CUP_L := Color("#ee5a5a")
const BOARD := Color("#1b2224")
const BOARD_L := Color("#243033")
const CHALK_D := Color("#9aa6a0")
const SLATE_L := Color("#383d42")
const SLATE_D := Color("#1f2327")
const CONCRETE := Color("#7c8088")
const CONCRETE_D := Color("#5f636b")
const CHROME := Color("#c9d2d8")
const INK := Color("#16191d")
const VOID := Color("#0a0a0c")
const PAPER_D := Color("#d9cba0")
const JEANS := Color("#262a36")
const PURPLE := Color("#7a5ac8")
const PEARL := Color("#fff6e6")
const ALERT := Color("#ff4f6d")
const GO := Color("#5fd38a")
const NIGHT1 := Color("#16264a")
const NIGHT2 := Color("#26365c")
const SKIN := [Color("#f1c8a4"), Color("#e2b08a"), Color("#d9a984"), Color("#c48d68")]
const HAIR_BR := Color("#4a2e1a")
const HAIR_BL := Color("#e2c060")
const HAIR_GR := Color("#bcbcbc")
const HAIR_BK := Color("#2a2a2a")

## The pen: what is drawn on (null: a dry run, nothing drawn), screen px per canvas px, the canvas
## origin on screen.
var ci: CanvasItem
var u := 1.0
var o := Vector2.ZERO
## Rects drawn (or, with no `ci`, that would be) since the owner last zeroed it: the Za deckami view's
## per-frame budget (check_decks.gd reads it from a dry pen).
var rects := 0

static var _glyphs: Dictionary = {}


func _init(item: CanvasItem = null, unit := 1.0, origin := Vector2.ZERO) -> void:
	ci = item
	u = unit
	o = origin


# --- primitives ---------------------------------------------------------------------------------

## A canvas-px rect, snapped to whole screen pixels on the grid.
func rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	if w <= 0.0 or h <= 0.0:
		return
	rects += 1
	if ci == null:
		return
	var x0 := roundf(o.x + roundf(x) * u)
	var y0 := roundf(o.y + roundf(y) * u)
	var x1 := roundf(o.x + roundf(x + w) * u)
	var y1 := roundf(o.y + roundf(y + h) * u)
	ci.draw_rect(Rect2(x0, y0, maxf(1.0, x1 - x0), maxf(1.0, y1 - y0)), c)


func px(x: float, y: float, c: Color) -> void:
	rect(x, y, 1, 1, c)


## A filled ellipse as rows of rects (rx, ry in canvas px), for glows and the porthole.
func disc(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var n := maxi(1, int(ceil(ry)))
	for k in range(-n, n + 1):
		var t := float(k) / maxf(ry, 0.5)
		if absf(t) > 1.0:
			continue
		var hw := rx * sqrt(1.0 - t * t)
		rect(cx - hw, cy + k, hw * 2.0, 1, c)


## A 1 px outline of a rect with its corners cut (padel's cards).
func frame(x: float, y: float, w: float, h: float, c: Color) -> void:
	rect(x + 1, y, w - 2, 1, c)
	rect(x + 1, y + h - 1, w - 2, 1, c)
	rect(x, y + 1, 1, h - 2, c)
	rect(x + w - 1, y + 1, 1, h - 2, c)


## A card: a dark body with its corners cut and a 1 px edge.
func card(x: float, y: float, w: float, h: float, body: Color, edge: Color) -> void:
	rect(x + 1, y, w - 2, h, body)
	rect(x, y + 1, w, h - 2, body)
	frame(x, y, w, h, edge)


# --- text ---------------------------------------------------------------------------------------

static func glyph(ch: String) -> Array[Vector2i]:
	if not _glyphs.has(ch):
		_glyphs[ch] = PixelFont.pixels(ch)
	return _glyphs[ch]


static func text_w(s: String, scale := 1) -> int:
	return PixelFont.width(s.to_upper().replace("\"", "”")) * scale


## Pixel text, the cell's top left at (x, y) (the letter itself starts 2 rows down); `scale` canvas
## px a font pixel; centred on x when `centre`; a dark drop shadow when `shadow`.
func text(s: String, x: float, y: float, c: Color, scale := 1, centre := false, shadow := false) -> void:
	s = s.to_upper().replace("\"", "”")
	var x0 := roundf(x - text_w(s, scale) * 0.5) if centre else roundf(x)
	if shadow:
		_text_at(s, x0 + scale, roundf(y) + scale, Color(0, 0, 0, 0.7), scale)
	_text_at(s, x0, roundf(y), c, scale)


func _text_at(s: String, x0: float, y0: float, c: Color, scale: int) -> void:
	var x := x0
	var first := true
	for ch in s:
		var cw := PixelFont.char_width(ch)
		if cw == 0:
			continue
		if not first:
			x += PixelFont.GAP * scale
		first = false
		var g := glyph(ch)
		# Runs along a row merged into one rect (fewer primitives than one per pixel).
		var i := 0
		while i < g.size():
			var p: Vector2i = g[i]
			var j := i
			while j + 1 < g.size() and g[j + 1].y == p.y and g[j + 1].x == g[j].x + 1:
				j += 1
			rect(x + p.x * scale, y0 + p.y * scale, (j - i + 1) * scale, scale, c)
			i = j + 1
		x += cw * scale


## Text wrapped to `max_w` canvas px (pixel_font.gd's rule), upper-cased.
static func wrap(s: String, max_w: int) -> PackedStringArray:
	return PixelFont.wrap_lines(s.to_upper().replace("\"", "”"), max_w)


# --- UI pieces ----------------------------------------------------------------------------------

## A slim chip (13 high): padel's black bar, a 1 px top edge, an optional icon, the words. Its width.
func chip(x: float, y: float, label: String, c := LINE, icon := "", w := 0.0, edge := SLATE_L) -> float:
	var iw := 11.0 if icon != "" else 0.0
	var ww := w if w > 0.0 else text_w(label) + iw + 9.0
	rect(x, y, ww, 13, Color(INK, 0.86))
	rect(x, y, ww, 1, edge)
	rect(x, y + 12, ww, 1, Color(VOID, 0.6))
	match icon:
		"bill":
			icon_bill(x + 3, y + 2)
		"wallet":
			icon_wallet(x + 2, y + 2)
	text(label, x + 4 + iw, y + 1, c)
	return ww


## A speech bubble (lines already wrapped): a dark card with a chalk edge, the speaker's name on a
## coloured tab, a tail at `tail_x` (canvas px, absolute) pointing down. Its height.
func bubble(x: float, y: float, w: float, name: String, lines: PackedStringArray, tail_x: float, name_c := AMBER, tail_down := true) -> float:
	var h := 6.0 + lines.size() * 10.0
	card(x, y, w, h, Color(INK, 0.94), CHALK_D)
	for i in 4:
		var ty := y + h - 1 + i if tail_down else y - i
		rect(tail_x - 2 + i * 0.5, ty, 4 - i, 1, Color(INK, 0.94))
	if name != "":
		var nw := text_w(name) + 6.0
		rect(x + 5, y - 6, nw, 9, name_c)
		text(name, x + 8, y - 7, INK)
	for i in lines.size():
		text(lines[i], x + 5, y + 2 + i * 10, LINE)
	return h


## An action tile (25x25) centred at (cx, cy) with its icon and the word under it.
func tile(cx: float, cy: float, label: String, icon: String, primary := true, pressed := false) -> void:
	var x := cx - 12.0
	var y := cy - 12.0
	var edge := GOLD if primary else CHALK_D
	card(x, y, 25, 25, Color(INK, 0.94) if not pressed else Color(edge, 0.35), edge)
	match icon:
		"beer":
			mug(x + 8, y + 8)
		"pong":
			cup(x + 9, y + 9)
			ball(x + 17, y + 6)
			px(x + 14, y + 4, GOLD)
			px(x + 12, y + 5, GOLD)
		"door":
			icon_door(x, y)
	var tw := text_w(label)
	rect(cx - tw * 0.5 - 3, y + 26, tw + 6, 10, Color(INK, 0.86))
	text(label, cx, y + 25, edge, 1, true)


## A button (gold primary, slate secondary) `w` x `h`.
func button(x: float, y: float, w: float, label: String, primary := true, h := 25.0, pressed := false) -> void:
	var bg := GOLD if primary else SLATE_L
	if pressed:
		bg = bg.darkened(0.2)
	var fg := INK if primary else LINE
	rect(x + 1, y, w - 2, h, bg)
	rect(x, y + 1, w, h - 2, bg)
	rect(x + 1, y + h - 3, w - 2, 2, bg.darkened(0.22))
	rect(x + 1, y + 1, w - 2, 1, bg.lightened(0.15))
	text(label, x + w * 0.5, y + h * 0.5 - 6, fg, 1, true)


func icon_bill(x: float, y: float) -> void:
	rect(x, y, 7, 9, FOAM)
	for i in range(0, 7, 2):
		px(x + i, y + 9, FOAM)
	rect(x + 1, y + 2, 5, 1, PAPER_D)
	rect(x + 1, y + 4, 3, 1, PAPER_D)
	rect(x + 1, y + 6, 5, 1, WOOD_D)


func icon_wallet(x: float, y: float) -> void:
	rect(x, y + 1, 9, 7, WOOD)
	rect(x, y + 1, 9, 2, WOOD_L)
	rect(x + 5, y + 4, 4, 3, WOOD_D)
	px(x + 6, y + 5, GOLD)


func icon_door(x: float, y: float) -> void:
	rect(x + 6, y + 5, 9, 15, WOOD)
	rect(x + 6, y + 5, 9, 1, WOOD_L)
	rect(x + 7, y + 7, 7, 5, WOOD_D)
	px(x + 13, y + 14, GOLD)
	for i in 3:
		rect(x + 17 + i, y + 12 - i, 1, 1 + i * 2, LINE)
	rect(x + 15, y + 12, 3, 1, LINE)


## A 9x11 pint with a handle and a head (top left at x, y + 0); `beer` its colour.
func mug(x: float, y: float, beer := BEER) -> void:
	rect(x, y + 2, 7, 9, beer)
	rect(x, y + 2, 2, 9, beer.lightened(0.18))
	rect(x - 1, y, 9, 3, FOAM)
	rect(x + 1, y - 1, 3, 1, FOAM)
	rect(x + 7, y + 4, 2, 1, LINE)
	rect(x + 8, y + 5, 1, 3, LINE)
	rect(x + 7, y + 8, 2, 1, LINE)
	rect(x, y + 10, 7, 1, beer.darkened(0.3))


## A red party cup, 9 wide at the rim, 13 tall, from the side; `cx` its centre, `top` its rim row.
func cup(cx: float, top: float, a := 1.0, rim := LINE) -> void:
	rect(cx - 4, top, 9, 2, Color(rim, a))
	rect(cx - 4, top + 2, 9, 5, Color(CUP, a))
	rect(cx - 3, top + 7, 7, 6, Color(CUP, a))
	rect(cx - 4, top + 2, 1, 5, Color(CUP_L, a))
	rect(cx - 3, top + 7, 1, 6, Color(CUP_L, a))
	rect(cx + 3, top + 2, 2, 5, Color(CUP_D, a))
	rect(cx + 2, top + 7, 2, 6, Color(CUP_D, a))
	rect(cx - 3, top + 4, 6, 1, Color(CUP_D, a * 0.6))


## Pan Hubert's tasting glass: a 7 px bowl (a 5 px mouth), a stem and a foot, 13 tall.
func tulip(cx: float, top: float, a := 1.0, rim := LINE) -> void:
	rect(cx - 2, top, 5, 1, Color(rim, a))
	rect(cx - 3, top + 1, 7, 6, Color(BEER, a))
	rect(cx - 2, top + 1, 5, 2, Color(FOAM, a))
	rect(cx - 3, top + 1, 1, 6, Color(AMBER_L, a))
	rect(cx - 2, top + 7, 5, 1, Color(BEER, a))
	rect(cx, top + 8, 1, 4, Color(LINE, a))
	rect(cx - 2, top + 12, 5, 1, Color(LINE, a))


## The 3x3 ball centred at (x, y); `squash` draws it 3x2 for the frame of a tock.
func ball(x: float, y: float, squash := false) -> void:
	if squash:
		rect(x - 1, y, 3, 2, BALL)
		return
	rect(x - 1, y - 1, 3, 3, BALL)
	px(x - 1, y - 1, Color.WHITE)
	px(x + 1, y + 1, BALL.darkened(0.35))


## A soft lamp glow: three stacked translucent discs.
func glow(cx: float, cy: float, r: float, c: Color, a := 0.10) -> void:
	for k in 3:
		var rr := r * (1.0 - k * 0.28)
		disc(cx, cy, rr, rr, Color(c, a))


# --- people -------------------------------------------------------------------------------------

## A table-side figure, about 58 px tall: padel's chibi built larger. `kind` you | gienia | hubert |
## crew | kuba; `face` +1 looks right; `arm` the throwing arm's angle (rad, 0 straight forward,
## negative up); `pose` "" | "cheer" | "slump" | "away" | "reach" | "drink" | "hold". Returns the
## hand's canvas position.
func figure(cx: float, foot: float, face: int, kind: String, arm := 0.5, pose := "", sway := 0.0) -> Vector2:
	var shirt := THEM
	var shirt_d := THEM_D
	var skin: Color = SKIN[0]
	var hair := HAIR_BL
	match kind:
		"you":
			shirt = US
			shirt_d = US_D
			hair = HAIR_BR
		"gienia":
			skin = SKIN[1]
			hair = HAIR_GR
		"hubert":
			skin = SKIN[2]
			hair = HAIR_BK
		"kuba":
			shirt = INK
			shirt_d = SLATE_D
			skin = SKIN[3]
			hair = HAIR_BK
	var short := 4.0 if kind == "gienia" else 0.0
	var x := roundf(cx + sway)
	var y := roundf(foot)
	var slump := 3.0 if pose == "slump" else 0.0
	disc(cx, foot, 12, 2, Color(0, 0, 0, 0.35))
	var legs := PURPLE if kind == "gienia" else JEANS
	rect(x - 7, y - 16, 6, 14, legs)
	rect(x + 1, y - 16, 6, 14, legs)
	rect(x - 8 + (1 if face > 0 else 0), y - 3, 8, 3, LINE)
	rect(x + (1 if face > 0 else 0), y - 3, 8, 3, LINE)
	var top := y - 38 + short + slump
	rect(x - 9, top, 18, 23 - short - slump, shirt)
	rect(x - 9 if face > 0 else x + 4, top, 5, 23 - short - slump, shirt_d)
	match kind:
		"you":
			rect(x - 4, top + 13, 9, 5, shirt_d)
			rect(x + 2 * face, top + 1, 1, 6, LINE)
		"gienia":
			rect(x - 2 + 3 * face, top, 5, 19, PEARL)
			for i in 3:
				px(x - 1 + 3 * face + i * 2, top + 2 + (i % 2), CHALK_D)
		"hubert":
			rect(x - 3 + 3 * face, top, 7, 23, INK)
			rect(x - 1 + 3 * face, top + 2, 3, 2, ALERT)
		"crew":
			rect(x - 4, top + 1, 1, 12, GOLD)
			rect(x - 5, top + 13, 4, 5, LINE)
		"kuba":
			rect(x - 7, top + 4, 14, 18, WOOD_D)
	var hy := top - 20 + (2.0 if pose == "slump" else 0.0)
	rect(x - 9, hy + 1, 18, 18, skin)
	rect(x - 8, hy, 16, 20, skin)
	rect(x - 9 if face > 0 else x + 6, hy + 2, 3, 16, skin.darkened(0.12))
	var ex := x + 4 * face
	var look := 1.0 if pose == "away" else 0.0
	if pose == "away" and kind == "gienia":
		rect(ex, hy + 11, 2, 1, INK)
		rect(ex - 5 * face, hy + 11, 2, 1, INK)
	else:
		rect(ex, hy + 9 + look, 2, 3 - look, INK)
		rect(ex - 5 * face, hy + 9 + look, 2, 3 - look, INK)
	var mouth := skin.darkened(0.3)
	if pose == "cheer":
		rect(x + 2 * face - 2, hy + 14, 5, 2, INK)
	else:
		rect(x + 2 * face - 1, hy + 15, 4, 1, mouth)
	match kind:
		"you":
			rect(x - 9, hy - 2, 18, 6, hair)
			rect(x - 10 if face > 0 else x + 7, hy, 3, 10, hair)
			rect(x + 3 * face - 1, hy + 3, 6, 2, hair)
		"gienia":
			rect(x - 9, hy - 2, 18, 6, hair)
			rect(x - 10, hy + 1, 3, 9, hair)
			rect(x + 7, hy + 1, 3, 9, hair)
			disc(x - 7 * face, hy - 4, 4, 4, hair)
			rect(x - 9 * face - 1, hy - 5, 2, 1, ALERT)
			var gy := hy + 7 if pose != "away" else hy - 1
			for gx in [ex - 1, ex - 5 * face - 1]:
				rect(gx - 1, gy, 6, 1, LINE)
				rect(gx - 1, gy + 6, 6, 1, LINE)
				rect(gx - 1, gy, 1, 7, LINE)
				rect(gx + 4, gy, 1, 7, LINE)
		"hubert":
			rect(x - 9, hy - 1, 18, 4, hair)
			rect(x - 10 if face > 0 else x + 7, hy, 3, 12, hair)
			rect(x + face - 2, hy + 13, 8, 2, hair)
			rect(x + 2 * face - 1, hy + 17, 4, 3, hair)
		"kuba":
			rect(x - 9, hy - 2, 18, 5, hair)
			rect(x - 8, hy + 13, 16, 7, hair)
		_:
			rect(x - 9, hy - 2, 18, 5, hair)
	# The arms: the throwing arm by `arm`; cheer: both up; drink: the hand at the mouth.
	var sx := x + 7 * face
	var sy := top + 4
	var a := arm
	match pose:
		"cheer":
			a = -1.25
		"slump":
			a = 1.3
		"drink":
			a = -0.9
		"reach":
			a = 0.9
	var hand := Vector2(sx + cos(a) * 15.0 * face, sy + sin(a) * 15.0)
	_limb(Vector2(sx, sy), hand, shirt)
	rect(hand.x - 2, hand.y - 2, 5, 5, skin)
	if pose == "drink":
		rect(hand.x - 1 - face * 2, hand.y - 6, 4, 6, BEER)
		rect(hand.x - 1 - face * 2, hand.y - 7, 4, 1, FOAM)
	if pose == "cheer":
		var ox := x - 7 * face
		var oh := Vector2(ox - cos(-1.25) * 15.0 * face, sy + sin(-1.25) * 15.0)
		_limb(Vector2(ox, sy), oh, shirt_d)
		rect(oh.x - 2, oh.y - 2, 5, 5, skin)
	if kind == "hubert" and pose != "cheer":
		# The tasting glass he never puts down, in the other hand (at his nose when `away`).
		var gx := x - 9 * face if pose != "away" else x + 9 * face
		var gy := top + 12 if pose != "away" else hy + 12
		tulip(gx, gy - 2, 1.0)
	if kind == "crew" and pose == "away":
		rect(x + 5 * face - 2, top + 6, 5, 7, INK)
		rect(x + 5 * face - 1, top + 7, 3, 5, THEM.lightened(0.4))
	return Vector2(roundf(hand.x + 2 * face), roundf(hand.y - 3))


func _limb(a: Vector2, b: Vector2, c: Color) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxf(1.0, n))
		rect(p.x, p.y - 1, 1, 3, c)


## Padel's own 18 px chibi (the regulars at the back table), seated or standing.
func mini(x: float, y: float, shirt: Color, hair: Color, skin: Color, sit := true, up := 0.0) -> void:
	var s := 3.0 if sit else 0.0
	if not sit:
		rect(x - 3, y - 5, 2, 5, JEANS)
		rect(x + 1, y - 5, 2, 5, JEANS)
	rect(x - 3, y - 12 + s - up, 6, 7 - (1.0 if sit else 0.0), shirt)
	rect(x - 3, y - 12 + s - up, 2, 6, shirt.darkened(0.2))
	var hy := y - 18 + s - up
	rect(x - 3, hy, 6, 6, skin)
	rect(x - 3, hy - 1, 6, 2, hair)
	px(x + 1, hy + 3, INK)
	if up > 0.0:
		rect(x - 5, hy - 3, 1, 5, shirt)
		rect(x + 4, hy - 3, 1, 5, shirt)


## A 32x32 portrait tile at (x, y), `s` canvas px a portrait px; `ring` its 1 px ring (alpha 0: none).
func bust(x: float, y: float, who: String, s := 1.0, ring := Color(0, 0, 0, 0)) -> void:
	var shirt := LINE
	var shirt_d := CHALK_D
	var skin: Color = SKIN[0]
	var hair := HAIR_BL
	var bg := SLATE_D
	match who:
		"you":
			shirt = US
			shirt_d = US_D
			hair = HAIR_BR
			bg = NIGHT1
		"gienia", "first":
			shirt = THEM
			shirt_d = THEM_D
			skin = SKIN[1]
			hair = HAIR_GR
			bg = BRICK_D
		"hubert", "sommelier":
			shirt = INK
			shirt_d = SLATE_D
			skin = SKIN[2]
			hair = HAIR_BK
			bg = WOOD_D
		"kuba", "barman":
			shirt = INK
			shirt_d = SLATE_D
			skin = SKIN[3]
			hair = HAIR_BK
			bg = WOOD_D
	var b := func(ax: float, ay: float, aw: float, ah: float, c: Color) -> void:
		rect(x + ax * s, y + ay * s, aw * s, ah * s, c)
	b.call(0, 0, 32, 32, bg)
	b.call(0, 22, 32, 10, bg.darkened(0.25))
	b.call(5, 24, 22, 8, shirt)
	b.call(5, 24, 5, 8, shirt_d)
	b.call(13, 21, 6, 4, skin.darkened(0.15))
	b.call(9, 7, 14, 15, skin)
	b.call(8, 9, 16, 11, skin)
	b.call(8, 9, 2, 11, skin.darkened(0.12))
	b.call(12, 13, 2, 3, INK)
	b.call(18, 13, 2, 3, INK)
	b.call(14, 18, 5, 1, skin.darkened(0.35))
	match who:
		"you":
			b.call(8, 4, 16, 6, hair)
			b.call(7, 7, 3, 7, hair)
			b.call(17, 9, 6, 2, hair)
			b.call(14, 25, 1, 5, LINE)
			b.call(17, 25, 1, 5, LINE)
		"gienia", "first":
			b.call(8, 4, 16, 6, hair)
			b.call(7, 6, 3, 9, hair)
			b.call(22, 6, 3, 9, hair)
			b.call(13, 0, 7, 5, hair)
			b.call(19, 1, 2, 1, ALERT)
			for gx in [10, 17]:
				b.call(gx, 12, 6, 1, LINE)
				b.call(gx, 16, 6, 1, LINE)
				b.call(gx, 12, 1, 5, LINE)
				b.call(gx + 5, 12, 1, 5, LINE)
			b.call(16, 13, 1, 1, LINE)
			b.call(13, 24, 6, 8, PEARL)
			for i in 4:
				b.call(11 + i * 3, 24 + (i % 2), 1, 1, PEARL)
			b.call(14, 18, 5, 1, ALERT)
		"hubert", "sommelier":
			b.call(8, 5, 16, 4, hair)
			b.call(7, 7, 3, 9, hair)
			b.call(22, 7, 3, 9, hair)
			b.call(11, 17, 10, 2, hair)
			b.call(14, 20, 4, 3, hair)
			b.call(13, 24, 6, 8, LINE)
			b.call(14, 25, 4, 2, ALERT)
			b.call(24, 16, 5, 1, LINE)
			b.call(24, 17, 5, 5, BEER)
			b.call(26, 22, 1, 4, LINE)
		"crew", "office":
			b.call(8, 5, 16, 5, hair)
			b.call(13, 24, 1, 8, GOLD)
			b.call(18, 24, 1, 8, GOLD)
			b.call(0, 14, 5, 10, SKIN[2])
			b.call(0, 12, 5, 3, HAIR_BK)
			b.call(27, 15, 5, 9, SKIN[1])
			b.call(27, 13, 5, 3, HAIR_BR)
		"kuba", "barman":
			b.call(8, 4, 16, 5, hair)
			b.call(8, 17, 16, 5, hair)
			b.call(14, 18, 5, 1, skin)
			b.call(5, 24, 22, 8, WOOD_D)
			b.call(13, 24, 6, 8, LINE)
	if ring.a > 0.0:
		rect(x - s, y - s, 32 * s + 2 * s, s, ring)
		rect(x - s, y + 32 * s, 32 * s + 2 * s, s, ring)
		rect(x - s, y - s, s, 32 * s + 2 * s, ring)
		rect(x + 32 * s, y - s, s, 32 * s + 2 * s, ring)


## A brick wall (w x h canvas px) with mortar courses and a few light and dark bricks.
func bricks(x: float, y: float, w: float, h: float, seed_value := 1) -> void:
	rect(x, y, w, h, BRICK)
	var r := seed_value
	var row := 0
	while row < h:
		rect(x, y + row + 4, w, 1, MORTAR)
		var off := 0 if (row / 5) % 2 == 0 else 6
		var bx := -off
		while bx < w:
			rect(x + bx + 11, y + row, 1, 4, MORTAR)
			r = (r * 1103515245 + 12345) & 0x7FFFFFFF
			if r % 7 == 0:
				rect(x + maxf(bx, 0), y + row, minf(11, w - bx), 4, BRICK_L)
			elif r % 5 == 0:
				rect(x + maxf(bx, 0), y + row, minf(11, w - bx), 4, BRICK_D)
			bx += 12
		row += 5
