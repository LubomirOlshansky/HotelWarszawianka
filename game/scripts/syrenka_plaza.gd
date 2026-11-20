extends "res://scripts/place.gd"
## The Syrenka's plaza on the upper Vistula boulevard (F, 2026-11-20: his screenshot of the bare
## plaza and three photos; the GUGiK orthophoto): the dark granite band that leads from the
## Copernicus Science Centre's side to the riverside Mermaid (site `syrenka_powisle`,
## landmarks/river.gd) is set with lights: a field of round lamps in the paving and, past it, short
## light strips, so after dark the band glows white in rows towards the statue (F's night photo,
## April 2024). Among the lamps small floor jets play, lit from below (the "glowing fountains" F
## asked for). Round the field: long rough granite boulders as benches, sandstone planters with
## clipped hedges and wooden benches on the metro's side.
## Built at runtime on both city paths as a place: one mesh poured in the actors' material, no draw
## call of its own; the lamps, strips and jets glow at night through LIT_SIGN (no lights). Nothing
## here is solid: drive-through, like the map's benches.
##
## Frame: the statue's (River.POWISLE_SYRENKA): `u` down the slope to the river (her facing), `v`
## along the edge (her right, towards the metro). The plaza is the upper level, u < -4.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const River := preload("res://scripts/landmarks/river.gd")

const LAMP := Color("#fff4d6")
const STRIP := Color("#fff8e8")
const JET := Color("#cdeffa")
const GRANITE := Color("#8a8279")
const GRANITE_HI := Color("#a39a8e")
const SAND := Color("#cdb48a")
const HEDGE := Color("#2f5a33")
const HEDGE_HI := Color("#3e6e3f")
const TIMBER := Color("#8a6a48")
const STEEL := Color("#3c3f44")

## The lamp field: rows along u, columns across v (metres in the frame).
const FIELD_U0 := -13.2
const FIELD_U1 := -5.8
const FIELD_STEP := 1.2
const FIELD_HALF_V := 3.6
## The strips' lines either side of the field and across its statue end.
const STRIP_V: Array[float] = [-6.2, -5.0, 5.0, 6.2]
## [u, v, yaw, length]: the boulders along the field's sides (the band ends at the cycle path, 14 m
## behind the basin).
const BOULDERS := [[-12.8, -7.6, 1.5, 2.3], [-9.2, -7.7, 1.35, 2.1], [-5.6, -7.5, 1.45, 2.0],
		[-4.4, 7.6, 1.6, 2.0]]
## The planters' centres (u) on the metro's side, at PLANTER_V.
const PLANTERS: Array[float] = [-12.4, -8.0]
const PLANTER_V := 8.8

var _st: SurfaceTool
var _o: Vector2
var _a: Vector2
var _b: Vector2


func build() -> void:
	_o = River.POWISLE_SYRENKA
	_a = River.POWISLE_SYRENKA_FWD
	_b = Vector2(-_a.y, _a.x)
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_field()
	_strips()
	for bd: Array in BOULDERS:
		_boulder(bd[0], bd[1], bd[2], bd[3])
	for u: float in PLANTERS:
		_planter(u, PLANTER_V)
	pour(_st.commit(), true, "SyrenkaPlaza")


## The world point of a frame (u, v) on the ground, `up` m over it.
func _at(u: float, v: float, up := 0.0) -> Vector3:
	var p := _o + _a * u + _b * v
	return Vector3(p.x, map.ground_height(p.x, p.y) + up, p.y)


## A box at frame (u, v), `yaw` turned from the frame's axes, `size` (x along u, y up, z along v),
## standing on the ground (its base `up` m over it).
func _box(u: float, v: float, yaw: float, size: Vector3, up: float, colour: Color, part := Props.FIXED) -> void:
	var fwd := Vector3(_a.x, 0.0, _a.y)
	var side := Vector3(_b.x, 0.0, _b.y)
	var x := fwd * cos(yaw) + side * sin(yaw)
	var z := side * cos(yaw) - fwd * sin(yaw)
	var basis := Basis(x, Vector3.UP, z)
	Props.obox(_st, _at(u, v, up + size.y * 0.5), basis, size, colour, part)
	count += 1


## The lamp field: round lamps (square at this scale) in staggered rows, and floor jets over every
## third one near the middle, taller in turn.
func _field() -> void:
	var rows := int(roundf((FIELD_U1 - FIELD_U0) / FIELD_STEP))
	for r in rows + 1:
		var u := FIELD_U0 + r * FIELD_STEP
		var off := 0.0 if r % 2 == 0 else FIELD_STEP * 0.5
		var v := -FIELD_HALF_V + off
		var c := 0
		while v <= FIELD_HALF_V + 0.01:
			_box(u, v, 0.0, Vector3(0.2, 0.03, 0.2), 0.0, LAMP, Models.LIT_SIGN)
			if absf(v) <= 2.5 and (r + c) % 3 == 0:
				var h := 0.45 + 0.3 * float((r * 7 + c) % 3)
				_box(u, v, 0.0, Vector3(0.07, h, 0.07), 0.03, JET, Models.LIT_SIGN)
				_box(u, v, 0.0, Vector3(0.18, 0.05, 0.18), 0.03 + h, JET, Models.LIT_SIGN)
			v += FIELD_STEP
			c += 1


## The light strips: dashes along u in two lines each side of the field, and a row across its
## statue end where the band meets the basin.
func _strips() -> void:
	for v: float in STRIP_V:
		var u := FIELD_U0 - 1.2 + (0.6 if absf(v) > 5.5 else 0.0)
		while u < FIELD_U1 + 0.5:
			_box(u, v, 0.0, Vector3(1.2, 0.03, 0.1), 0.0, STRIP, Models.LIT_SIGN)
			u += 2.6
	for k in 7:
		_box(FIELD_U1 + 1.4, -3.6 + k * 1.2, PI * 0.5, Vector3(0.9, 0.03, 0.1), 0.0, STRIP, Models.LIT_SIGN)


## A boulder bench: a long rough granite slab with a flatter, lighter top.
func _boulder(u: float, v: float, yaw: float, length: float) -> void:
	_box(u, v, yaw, Vector3(length, 0.42, 0.95), -0.05, GRANITE)
	_box(u + 0.05, v, yaw + 0.04, Vector3(length - 0.25, 0.14, 0.78), 0.33, GRANITE_HI)


## A sandstone planter with a clipped hedge, and a timber bench facing the lamp field.
func _planter(u: float, v: float) -> void:
	_box(u, v, 0.0, Vector3(4.4, 0.5, 1.5), 0.0, SAND)
	_box(u, v, 0.0, Vector3(4.1, 0.75, 1.2), 0.5, HEDGE)
	_box(u, v, 0.0, Vector3(3.9, 0.08, 1.0), 1.25, HEDGE_HI)
	var bv := v - 1.45
	for du: float in [-0.75, 0.75]:
		_box(u + du, bv, 0.0, Vector3(0.08, 0.42, 0.5), 0.0, STEEL)
	_box(u, bv, 0.0, Vector3(1.9, 0.07, 0.5), 0.42, TIMBER)
	_box(u, bv + 0.27, 0.0, Vector3(1.9, 0.4, 0.06), 0.45, TIMBER)
