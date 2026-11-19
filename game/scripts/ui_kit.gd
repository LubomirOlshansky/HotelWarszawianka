extends RefCounted
## The UI kit (F 2026-11-19, docs/design/ui-kit.md): the one look of every interface surface, so
## the HUD, the full map, QUESTS, the garage, the notebook, calls, photo mode and the title read as
## one game. It holds the colours, the type scale, the corners and spacing, and makes the card,
## button, chip and label styles from them; `theme(pt)` turns the same tokens into a Godot Theme
## for the whole window, so a plain Button or PanelContainer already wears the kit.
##
## Rules (the design doc's section 2):
## - Gold means "you can press this" or "this is chosen": PRIMARY buttons, SELECTED tabs, toggles
##   and rows, screen titles and labels. Never a decoration.
## - ALERT, GO, POLICE and HEAT appear only when the colour says something (new / quit, won, police,
##   a timer). NEON_PINK and NEON_CYAN are the brand (title, radio, stars, portrait rings), never a
##   button.
## - Corners: R_SMALL for chips, tiles and rows, R_CARD for cards and buttons, a pill for round
##   things. Button words in capitals; card titles gold capitals at T_TITLE.
## - A UI script uses these constants and builders instead of its own Color literals; the ratchet
##   tools/check_ui_kit.py counts the literals each UI script still has and only lets them fall.
##
## Everything here is static and pure (no node, no state): a caller passes its `pt` (points to
## pixels, hud.gd `pt`).

# --- colours ---

## Surfaces. CARD is every card and panel: near-black violet, opaque enough that the street never
## tints it (loop 2e's recipe, hud.gd CARD_BG before the kit).
const CARD := Color(0.07, 0.06, 0.1, 0.94)
## The same, fully opaque (a page under a scrolling list).
const CARD_SOLID := Color(0.07, 0.06, 0.1, 1.0)
## Buttons, rows and tiles inside a card.
const RAISED := Color(0.118, 0.102, 0.157, 1.0)
## Only for controls over the road (pedals, the steering strip, map zoom): the city shows through.
const GLASS := Color(0.07, 0.06, 0.1, 0.34)
const GLASS_EDGE := Color(1, 1, 1, 0.42)
## A card's and a button's thin border; STRONG on hover and for a raised button.
const EDGE := Color(1, 1, 1, 0.16)
const EDGE_STRONG := Color(1, 1, 1, 0.30)
## A faint fill (an empty slot, a bar's track).
const DIM := Color(1, 1, 1, 0.07)

## Text.
const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const FAINT := Color("#8e879e")
## The outline under text drawn straight over the city.
const OUTLINE := Color("#1d1b19")

## Action. The one gold (replaces #f0b429, #ffe27a, #f2d34a).
const GOLD := Color("#ffd23f")
const GOLD_PRESS := Color("#d9b235")
## A chosen tab, toggle or row: gold at 22 % under a gold edge.
const GOLD_TINT := Color(1.0, 0.824, 0.247, 0.22)
## Text and marks on a gold fill.
const ON_GOLD := Color("#1a1622")

## Meaning, only when the colour says something.
const ALERT := Color("#ff4f6d")   # NEW badges, quit, wrong way, a rescue
const GO := Color("#5fd38a")      # won, delivered, safe, hidden
const POLICE := Color("#3d7bff")  # police and the chase
const HEAT := Color("#ffb020")    # timers and hot food

## The brand neon (the title's sunset, KEBAB FM, stars, portrait rings, photo mode's frame).
const NEON_PINK := Color("#ff4fd8")
const NEON_CYAN := Color("#5fd4ff")

# --- type, corners, spacing (points) ---

const T_BANNER := 44.0
const T_CLOCK := 22.0
const T_TITLE := 17.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0

const R_SMALL := 6.0
const R_CARD := 12.0
## A pill: big enough to round any HUD-sized box fully.
const R_PILL := 999.0

const PAD := 12.0
const GAP := 8.0
const TOUCH := 44.0
## The border's width (points); never under one pixel.
const EDGE_W := 0.5

## Button kinds.
enum Kind { SECONDARY, PRIMARY, SELECTED, DANGER }


static func px(points: float, pt: float) -> int:
	return maxi(1, roundi(points * pt))


## A rounded box: `bg` with an `edge` border `width` points wide (at least a pixel), `radius`
## points, `margin` points of content margin.
static func box(bg: Color, edge: Color, pt: float, radius := R_CARD, width := EDGE_W, margin := 4.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(roundi(radius * pt))
	s.border_color = edge
	s.set_border_width_all(maxi(1, roundi(width * pt)) if edge.a > 0.0 else 0)
	s.set_content_margin_all(margin * pt)
	s.anti_aliasing = true
	return s


## The card: every panel in the game.
static func card(pt: float, margin := PAD, radius := R_CARD) -> StyleBoxFlat:
	return box(CARD, EDGE, pt, radius, EDGE_W, margin)


## A row or tile inside a card; `chosen` gives it the SELECTED look.
static func row(pt: float, chosen := false, margin := GAP) -> StyleBoxFlat:
	if chosen:
		return box(GOLD_TINT, GOLD, pt, R_SMALL, 1.0, margin)
	return box(RAISED, Color(0, 0, 0, 0), pt, R_SMALL, 0.0, margin)


## A small pill with a coloured edge and words in the same colour (a status chip: NEW, rescue
## call, delivered).
static func chip(colour: Color, pt: float) -> StyleBoxFlat:
	var s := box(CARD, colour, pt, R_PILL, 1.0, 4.0)
	s.content_margin_left = 9.0 * pt
	s.content_margin_right = 9.0 * pt
	return s


## The HUD's round readouts (speed, the wallet, the radio).
static func pill(pt: float) -> StyleBoxFlat:
	var s := box(CARD, EDGE, pt, R_PILL, EDGE_W, 4.0)
	s.content_margin_left = 12.0 * pt
	s.content_margin_right = 12.0 * pt
	return s


## A control over the road.
static func glass(pt: float, radius := R_CARD) -> StyleBoxFlat:
	return box(GLASS, GLASS_EDGE, pt, radius, 0.75, 4.0)


## The text colour of a button of `kind`.
static func button_ink(kind: int) -> Color:
	match kind:
		Kind.PRIMARY:
			return ON_GOLD
		Kind.DANGER:
			return ALERT
	return INK


## The style boxes of a button of `kind`, by state (normal, hover, pressed, hover_pressed,
## disabled, focus). `radius` R_PILL makes a round button.
static func button_boxes(kind: int, pt: float, radius := R_CARD) -> Dictionary:
	var normal: StyleBoxFlat
	var pressed: StyleBoxFlat
	match kind:
		Kind.PRIMARY:
			normal = box(GOLD, GOLD, pt, radius, 1.0)
			pressed = box(GOLD_PRESS, GOLD_PRESS, pt, radius, 1.0)
		Kind.SELECTED:
			normal = box(GOLD_TINT, GOLD, pt, radius, 1.0)
			pressed = box(Color(GOLD, 0.32), GOLD, pt, radius, 1.0)
		Kind.DANGER:
			normal = box(RAISED, Color(ALERT, 0.6), pt, radius, 1.0)
			pressed = box(Color(ALERT, 0.22), ALERT, pt, radius, 1.0)
		_:
			normal = box(RAISED, EDGE, pt, radius, EDGE_W)
			pressed = box(GOLD_TINT, GOLD, pt, radius, 1.0)
	var hover := normal.duplicate() as StyleBoxFlat
	if kind == Kind.SECONDARY:
		hover.border_color = EDGE_STRONG
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(disabled.bg_color, disabled.bg_color.a * 0.5)
	disabled.border_color = Color(disabled.border_color, disabled.border_color.a * 0.5)
	var focus := box(Color(0, 0, 0, 0), GOLD, pt, radius, 1.5)
	focus.draw_center = false
	return {"normal": normal, "hover": hover, "pressed": pressed, "hover_pressed": pressed,
			"disabled": disabled, "focus": focus}


## Dresses a Button as a kit button of `kind`: its boxes, its word colours (capitals: the kit
## writes button words upper case) and its font size `font_pt`. `focus` false keeps the focus ring
## off (touch-only buttons).
static func style_button(b: Button, kind: int, pt: float, font_pt := T_SUB, radius := R_CARD, focus := false) -> void:
	var boxes := button_boxes(kind, pt, radius)
	for state in boxes:
		if state == "focus" and not focus:
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			continue
		b.add_theme_stylebox_override(state, boxes[state])
	var ink := button_ink(kind)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.45))
	b.add_theme_font_size_override("font_size", px(font_pt, pt))
	b.text = b.text.to_upper()


## A label's colours for the kit's text roles: "title" (gold, a card or screen title), "label"
## (gold, the small capitals over a group), "body" (ink), "sub" (sub), "faint".
static func role_colour(role: String) -> Color:
	match role:
		"title", "label":
			return GOLD
		"sub":
			return SUB
		"faint":
			return FAINT
	return INK


## The point size of a text role.
static func role_size(role: String) -> float:
	match role:
		"title":
			return T_TITLE
		"label":
			return T_LABEL
		"sub":
			return T_SUB
		"faint":
			return T_LABEL
	return T_BODY


## Dresses a Label in a text role (and upper-cases title and label words).
static func style_label(l: Label, role: String, pt: float, size_pt := -1.0) -> void:
	l.add_theme_color_override("font_color", role_colour(role))
	l.add_theme_font_size_override("font_size", px(role_size(role) if size_pt < 0.0 else size_pt, pt))
	if role == "title" or role == "label":
		l.uppercase = true


## The kit as a Godot Theme for the whole window (main.gd sets it on the root viewport): a plain
## Button is a SECONDARY kit button, a Label is ink body text, a PanelContainer or Panel is a card,
## a LineEdit, a slider and a scroll bar use the same surfaces. Scripts that override styles keep
## them; this is the default the overrides now agree with.
static func theme(pt: float) -> Theme:
	var t := Theme.new()
	t.default_font_size = px(T_BODY, pt)
	var boxes := button_boxes(Kind.SECONDARY, pt)
	for state in boxes:
		t.set_stylebox(state, "Button", boxes[state])
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.45))
	t.set_color("font_color", "Label", INK)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_stylebox("panel", "PanelContainer", card(pt))
	t.set_stylebox("panel", "Panel", card(pt))
	t.set_stylebox("normal", "LineEdit", box(RAISED, EDGE, pt, R_SMALL, EDGE_W, 6.0))
	t.set_stylebox("focus", "LineEdit", box(Color(0, 0, 0, 0), GOLD, pt, R_SMALL, 1.0, 6.0))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_color("selection_color", "LineEdit", GOLD_TINT)
	var track := box(DIM, Color(0, 0, 0, 0), pt, R_PILL, 0.0, 2.0)
	var grab := box(Color(1, 1, 1, 0.35), Color(0, 0, 0, 0), pt, R_PILL, 0.0, 2.0)
	var grab_on := box(GOLD, Color(0, 0, 0, 0), pt, R_PILL, 0.0, 2.0)
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, track)
		t.set_stylebox("grabber", bar, grab)
		t.set_stylebox("grabber_highlight", bar, grab_on)
		t.set_stylebox("grabber_pressed", bar, grab_on)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", box(GOLD, Color(0, 0, 0, 0), pt, R_PILL, 0.0, 2.0))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(GOLD, Color(0, 0, 0, 0), pt, R_PILL, 0.0, 2.0))
	t.set_stylebox("background", "ProgressBar", track)
	t.set_stylebox("fill", "ProgressBar", box(GOLD, Color(0, 0, 0, 0), pt, R_PILL, 0.0, 0.0))
	t.set_color("font_color", "ProgressBar", INK)
	return t
