extends "res://scripts/place.gd"
## The Syrenka's plaza on the upper Vistula boulevard (F, 2026-11-20: his screenshot of the bare
## plaza, then Google Maps photos of the "Fontanna", 2019 and 2024): behind the riverside Mermaid
## (site `syrenka_powisle`, landmarks/river.gd), on her axis 22-74 m back towards the Copernicus
## Science Centre, lies the water mirror: a flush field of dark wet granite (OSM's `fountain`
## surface, drawn dark by map_builder's DRY_FOUNTAINS, not as a pool) where mist jets play from
## nozzles in the slabs and slanted light strips glow in rows after dark. Between it and the
## statue: rough red-granite boulders as seats, sandstone planters with clipped hedges and wooden
## benches on the metro's side.
## Built at runtime on both city paths as a place: one mesh poured in the actors' material, no draw
## call of its own; the strips, nozzles and jets glow at night through LIT_SIGN (no lights).
## Nothing here is solid: drive-through, like the map's benches, and the mirror is dry ground.
##
## Frame: the statue's (River.POWISLE_SYRENKA): `u` down the slope to the river (her facing), `v`
## along the edge (her right, towards the metro). The plaza is the upper level, u < -4.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const River := preload("res://scripts/landmarks/river.gd")

const STRIP := Color("#ffe8bf")
const NOZZLE := Color("#fff2d8")
const JET := Color("#e9f1ef")
const MIST := Color("#cfd8d8")
const BOULDER := Color("#8e5a4b")
const BOULDER_HI := Color("#a66f5d")
const SAND := Color("#cdb48a")
const HEDGE := Color("#2f5a33")
const HEDGE_HI := Color("#3e6e3f")
const TIMBER := Color("#8a6a48")
const STEEL := Color("#3c3f44")

## The water mirror in the frame (OSM's fountain ring (492,-647) (499,-640) (538,-674) (531,-681)):
## u MIRROR_U0..MIRROR_U1 along her axis, v within MIRROR_V0..MIRROR_V1.
const MIRROR_U0 := -73.2
const MIRROR_U1 := -22.2
const MIRROR_V0 := -4.4
const MIRROR_V1 := 5.0
## Rows of light strips and of nozzles take turns every ROW m; the strips lean STRIP_YAW off the
## axis (the photos' slanted dashes); the mist plays over the middle rows.
const ROW := 1.2
const STRIP_YAW := 0.42
const MIST_U0 := -66.0
const MIST_U1 := -30.0
## [u, v, yaw, length]: the red-granite boulders between the mirror's end and the statue.
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
	_mirror()
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


## The water mirror's lights (laid 0.13 m up: map_builder drapes its surfaces 0.08 m over the
## ground and the mirror's slabs over that, so flush boxes vanished under them): rows across it, every other one a row of four slanted light strips
## (staggered), the rows between them five round nozzles; over the middle rows every other nozzle
## throws a low lit plume of mist (a wide puff at its foot, a column over it), taller in turn.
func _mirror() -> void:
	var width := MIRROR_V1 - MIRROR_V0
	var rows := int(floorf((MIRROR_U1 - MIRROR_U0 - 1.0) / ROW))
	for r in rows:
		var u := MIRROR_U0 + 0.6 + r * ROW
		if r % 2 == 0:
			var off := 0.25 if (r / 2) % 2 == 0 else 0.75
			for k in 4:
				var v := MIRROR_V0 + width * (k + off) / 4.0
				_box(u, v, STRIP_YAW, Vector3(1.6, 0.04, 0.16), 0.13, STRIP, Models.LIT_SIGN)
		else:
			for k in 5:
				var v := MIRROR_V0 + width * (k + 0.5) / 5.0
				_box(u, v, 0.0, Vector3(0.14, 0.04, 0.14), 0.13, NOZZLE, Models.LIT_SIGN)
				if u > MIST_U0 and u < MIST_U1 and (r / 2 + k) % 2 == 0:
					var h := 0.5 + 0.3 * float((r + k * 2) % 3)
					_box(u, v, 0.0, Vector3(0.5, 0.3, 0.5), 0.07, MIST, Models.LIT_SIGN)
					_box(u, v, 0.6, Vector3(0.32, h, 0.32), 0.1, JET, Models.LIT_SIGN)


## A boulder seat: a long rough red-granite block with a flatter, lighter top.
func _boulder(u: float, v: float, yaw: float, length: float) -> void:
	_box(u, v, yaw, Vector3(length, 0.42, 0.95), -0.05, BOULDER)
	_box(u + 0.05, v, yaw + 0.04, Vector3(length - 0.25, 0.14, 0.78), 0.33, BOULDER_HI)


## A sandstone planter with a clipped hedge, and a timber bench facing the plaza.
func _planter(u: float, v: float) -> void:
	_box(u, v, 0.0, Vector3(4.4, 0.5, 1.5), 0.0, SAND)
	_box(u, v, 0.0, Vector3(4.1, 0.75, 1.2), 0.5, HEDGE)
	_box(u, v, 0.0, Vector3(3.9, 0.08, 1.0), 1.25, HEDGE_HI)
	var bv := v - 1.45
	for du: float in [-0.75, 0.75]:
		_box(u + du, bv, 0.0, Vector3(0.08, 0.42, 0.5), 0.0, STEEL)
	_box(u, bv, 0.0, Vector3(1.9, 0.07, 0.5), 0.42, TIMBER)
	_box(u, bv + 0.27, 0.0, Vector3(1.9, 0.4, 0.06), 0.45, TIMBER)
