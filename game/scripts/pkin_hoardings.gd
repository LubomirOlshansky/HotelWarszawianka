extends "res://scripts/place.gd"
## The Sala Kongresowa building site on the Palace's west flank (F, 2026-11-15, his photos of the
## hall's renovation): the rotunda's front stands behind a run of site hoardings along the service
## road, with the street's black bollards along the kerb in front of them. From the photos:
##  - white printed hoardings with the contractor's name in navy, one dark navy panel with the
##    developer's mark, green information boards ("we are changing the Congress Hall for you");
##  - a stretch of white corrugated palisade fencing between them, on dark posts;
##  - a barrier gate with a red-and-white arm, its box beside it;
##  - thin black bollards with a ball cap, a few with a yellow one, in a row along the kerb.
## Names are parodies (the real contractor and developer are not shown): ADAMAJZER WARSZAWA and
## EKSEM GRUPA POLSKA. The Palace's own frame (u east along the long axis, v south) is the Palace
## site's (landmarks/centre.gd PKIN_O/A/B); the run stands between the hall's south front (v 33)
## and the service road (v 48). Built at runtime on both city paths as a place: one mesh poured in
## the actors' material, no draw call of its own. Nothing here is solid (drive-through like the
## map's benches).

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const Pixel := preload("res://scripts/pixel_font.gd")
const Centre := preload("res://scripts/landmarks/centre.gd")

## The hoarding's line: from u RUN_U0 along u in 3 m panels at v RUN_V (the panels' street face).
const RUN_U0 := -99.0
const RUN_V := 41.0
const PANEL := 3.0
const PANEL_H := 2.3
## The run, one letter per panel: w white printed, n navy, g green information board, p palisade,
## b the barrier gate's gap.
const RUN := "wwngppppbwwwg"
## The bollards' row: along the kerb in front of the run.
const BOLLARD_V := 44.4
const BOLLARD_U := [-99.0, -60.0]
const BOLLARDS := 14

const WHITE := Color("#eceae4")
const NAVY := Color("#1b2848")
const INK := Color("#1d3a78")
const GREEN := Color("#2c6e4a")
const POST := Color("#30343a")
const RIB_A := Color("#dedcd6")
const RIB_B := Color("#c4c3bd")
const ARM_RED := Color("#c9302c")
const BOLLARD := Color("#23262c")
const YELLOW := Color("#e8c43a")
const GREY_BOX := Color("#b5b7b8")

var _st: SurfaceTool
var _basis: Basis
var _ax: Vector3
var _bz: Vector3


func build() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ax = Vector3(Centre.PKIN_A.x, 0, Centre.PKIN_A.y)
	_bz = Vector3(Centre.PKIN_B.x, 0, Centre.PKIN_B.y)
	_basis = Basis(_ax, Vector3.UP, _bz)
	var named := 0
	for i in RUN.length():
		var u := RUN_U0 + (i + 0.5) * PANEL
		var kind := RUN[i]
		var c := _at(u, RUN_V)
		# A dark post at the panel's left edge.
		Props.obox(_st, _at(RUN_U0 + i * PANEL, RUN_V) + Vector3.UP * (PANEL_H * 0.5), _basis, Vector3(0.1, PANEL_H + 0.1, 0.14), POST)
		match kind:
			"w":
				Props.obox(_st, c + Vector3.UP * (PANEL_H * 0.5 + 0.05), _basis, Vector3(PANEL - 0.12, PANEL_H, 0.1), WHITE)
				if named % 2 == 0:
					_text(["ADAMAJZER"], u, 0.052, INK, PANEL_H * 0.62)
				named += 1
			"n":
				Props.obox(_st, c + Vector3.UP * (PANEL_H * 0.5 + 0.05), _basis, Vector3(PANEL - 0.12, PANEL_H, 0.1), NAVY)
				_text(["EKSEM"], u, 0.06, WHITE, PANEL_H * 0.62)
			"g":
				# The green information board, smaller, with a pale rim.
				Props.obox(_st, c + Vector3.UP * (PANEL_H * 0.5 + 0.05), _basis, Vector3(PANEL - 0.12, PANEL_H, 0.1), WHITE)
				Props.obox(_st, c + Vector3.UP * 1.35 + _bz * 0.06, _basis, Vector3(2.3, 1.7, 0.05), GREEN)
				_text(["ODŚWIEŻAMY", "KONGRESOWĄ", "DLA CIEBIE"], u, 0.034, WHITE, 1.95)
			"p":
				_palisade(u, c)
			"b":
				_gate(u)
	# The last post.
	Props.obox(_st, _at(RUN_U0 + RUN.length() * PANEL, RUN_V) + Vector3.UP * (PANEL_H * 0.5), _basis, Vector3(0.1, PANEL_H + 0.1, 0.14), POST)
	_bollards()
	pour(_st.commit(), true, "PkinHoardings")


## The ground at a point of the Palace's frame (flat 0 without a map).
func _at(u: float, v: float) -> Vector3:
	var p := Centre.PKIN_O + Centre.PKIN_A * u + Centre.PKIN_B * v
	return Vector3(p.x, map.ground_height(p.x, p.y) if map != null else 0.0, p.y)


## Lines of print, centred on u, the first line's top `top` m up, on the street face (+v) of the panel.
func _text(lines: Array, u: float, px: float, colour: Color, top: float) -> void:
	var y := top
	for l: String in lines:
		var w := Pixel.width(l) * px
		var origin := _at(u, RUN_V) - _ax * (w * 0.5) + _bz * 0.11
		origin.y = _at(u, RUN_V).y + y
		Pixel.add_quads(_st, l, origin, _ax, Vector3.DOWN, px, colour, Models.FIXED)
		y -= px * Pixel.LINE


## Corrugated white palisade: a flat panel with vertical ribs in two greys.
func _palisade(u: float, c: Vector3) -> void:
	var h := PANEL_H - 0.3
	Props.obox(_st, c + Vector3.UP * (h * 0.5 + 0.05), _basis, Vector3(PANEL - 0.12, h, 0.05), RIB_B)
	for k in 8:
		var du := -PANEL * 0.5 + 0.22 + k * 0.36
		Props.obox(_st, c + _ax * du + _bz * 0.045 + Vector3.UP * (h * 0.5 + 0.05), _basis, Vector3(0.16, h, 0.04), RIB_A)


## The barrier gate: a gap, a grey box on the left, the arm across it in red and white stripes.
func _gate(u: float) -> void:
	var left := _at(u - PANEL * 0.5 + 0.35, RUN_V + 0.3)
	Props.obox(_st, left + Vector3.UP * 0.6, _basis, Vector3(0.45, 1.2, 0.4), GREY_BOX)
	Props.obox(_st, left + Vector3.UP * 1.25, _basis, Vector3(0.5, 0.1, 0.45), POST)
	var stripes := 8
	var reach := 4.6
	for k in stripes:
		var a := left + _ax * (0.25 + k * reach / stripes) + Vector3.UP * 1.1
		Props.obox(_st, a + _ax * (reach / stripes * 0.5), _basis, Vector3(reach / stripes, 0.1, 0.06),
				ARM_RED if k % 2 == 0 else WHITE)


## The row of thin black bollards with a ball cap along the kerb, a yellow cap on every fifth.
func _bollards() -> void:
	for k in BOLLARDS:
		var u := lerpf(BOLLARD_U[0], BOLLARD_U[1], float(k) / (BOLLARDS - 1))
		var c := _at(u, BOLLARD_V)
		Props.obox(_st, c + Vector3.UP * 0.45, _basis, Vector3(0.13, 0.9, 0.13), BOLLARD)
		Props.obox(_st, c + Vector3.UP * 0.96, _basis, Vector3(0.18, 0.1, 0.18), YELLOW if k % 5 == 2 else BOLLARD)
