extends Node3D
## The car park ramp by Dworzec Centralny (F, 2026-11-08, Street View, August 2024): what the map
## data doesn't draw at the tunnel under Aleja Jana Pawła II (tools/centralny_ramp.py makes the
## drive: the tube, the turning hall, the way out). Over the portal the white direction board with
## the blue frame, "ZŁOTE TARASY ←" on the left and "DWORZEC CENTRALNY TAXI BUS →" on the right,
## hung so its foot is the 3.3 m clearance, the round height limit sign beside it; the red and white
## bollards between the two lanes, down the ramp and on into the mouth (the photos' long row).
## Built at runtime on both city paths (it isn't in the sector scenes), as skwer_zlota.gd: one
## mesh in the actors' material (models.gd), one draw call in view. Nothing here is solid: the
## bollards stand on the strip between the lanes, drive-through like the map's benches.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

## The portal (tools/centralny_ramp.py: the tube's west end, its heading into the tunnel, its floor).
const PORTAL := Vector2(-1644.6, 428.0)
const INTO := Vector2(0.8236, -0.5671)
const FLOOR := 8.5
const CLEARANCE := 3.4
## The board: this wide and tall, this far out in front of the mouth.
const BOARD := Vector2(8.0, 2.3)
const BOARD_OUT := 0.5
const NAVY := Color("#1f3f8f")
const WHITE := Color("#f2f2ee")
const RED := Color("#c8282a")
const TEXT_PX := 0.045
const ARROW_PX := 0.09
## [text, u, v, px]: u, v in metres from the board's top left as a driver reads it.
const LINES := [
	["ZŁOTE", 0.35, 0.18, TEXT_PX], ["TARASY", 0.35, 0.68, TEXT_PX], ["←", 0.7, 1.25, ARROW_PX],
	["DWORZEC", 4.3, 0.18, TEXT_PX], ["CENTRALNY", 4.3, 0.68, TEXT_PX], ["TAXI BUS", 4.3, 1.18, TEXT_PX],
	["→", 6.65, 1.25, ARROW_PX],
]
## The bollards: the middle line between the two lanes (tools/centralny_ramp.py's ramps; none
## where a retaining wall stands on that line), out of the avenue's slip down to the portal; the
## last ones inside the mouth stand on the tunnel's floor.
const BOLLARDS := [
	Vector2(-1636.2, 481.7), Vector2(-1638.4, 482.2), Vector2(-1640.8, 482.5), Vector2(-1643.3, 482.7),
	Vector2(-1645.7, 482.6), Vector2(-1648.2, 482.2), Vector2(-1651.9, 481.3), Vector2(-1654.1, 480.2),
	Vector2(-1656.3, 479.0), Vector2(-1658.4, 477.4), Vector2(-1660.1, 475.6), Vector2(-1661.7, 473.8),
	Vector2(-1662.9, 471.6), Vector2(-1663.9, 469.0), Vector2(-1664.4, 466.8), Vector2(-1663.0, 451.8),
	Vector2(-1661.8, 449.0), Vector2(-1660.8, 447.0), Vector2(-1659.5, 444.6), Vector2(-1658.1, 442.3),
	Vector2(-1656.7, 440.3), Vector2(-1655.1, 438.4), Vector2(-1653.3, 436.5), Vector2(-1651.7, 434.8),
	Vector2(-1649.9, 433.1), Vector2(-1648.2, 431.4), Vector2(-1646.4, 429.7),
]
## Inside the mouth: this many more on along the tube's middle, this far apart.
const MOUTH_BOLLARDS := 3
const BOLLARD_STEP := 2.2

var map: Node3D
var count := 0


## Builds the mesh; `map` gives the ground (map_builder.ground_height, tunnel_floor_under).
func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_board(st)
	for p: Vector2 in BOLLARDS:
		_bollard(st, Vector3(p.x, map.ground_height(p.x, p.y), p.y))
	for k in MOUTH_BOLLARDS:
		var p := PORTAL + INTO * BOLLARD_STEP * (k + 1)
		_bollard(st, Vector3(p.x, FLOOR, p.y))
	var mi := MeshInstance3D.new()
	mi.name = "CentralnyRampProps"
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	add_child(mi)


## The direction board over the mouth (its -z face looks out of the tunnel) and the height sign.
func _board(st: SurfaceTool) -> void:
	var at := PORTAL - INTO * BOARD_OUT
	var yaw := atan2(INTO.x, INTO.y)
	var b := Basis(Vector3.UP, yaw)
	var foot := FLOOR + CLEARANCE
	var centre := Vector3(at.x, foot + BOARD.y * 0.5, at.y)
	Props.obox(st, centre, b, Vector3(BOARD.x + 0.16, BOARD.y + 0.16, 0.1), NAVY)
	Props.obox(st, centre + b * Vector3(0, 0, -0.03), b, Vector3(BOARD.x, BOARD.y, 0.08), WHITE, Models.LIT_SIGN)
	# A driver outside reads the -z face: their right is -x, the board's top left is +x, top.
	var right: Vector3 = b * Vector3(-1, 0, 0)
	var top_left: Vector3 = centre + b * Vector3(BOARD.x * 0.5, BOARD.y * 0.5, -0.075)
	for line: Array in LINES:
		var o: Vector3 = top_left + right * float(line[1]) + Vector3.DOWN * float(line[2])
		PixelFont.add_quads(st, line[0], o, right, Vector3.DOWN, float(line[3]), NAVY, Models.FIXED)
	# The rule across under the names, above the arrows.
	Props.obox(st, top_left + right * BOARD.x * 0.5 + Vector3.DOWN * 1.2 + b * Vector3(0, 0, -0.005), b,
			Vector3(BOARD.x - 0.3, 0.05, 0.02), NAVY)
	# The 3.3 m sign: a red-rimmed white disc (an octagon) left of the board, "3,3M" on it.
	var sc: Vector3 = top_left - right * 0.75 + Vector3.DOWN * 0.7
	for turn in [0.0, PI * 0.25]:
		var tb := b * Basis(Vector3.BACK, turn)
		Props.obox(st, sc, tb, Vector3(0.9, 0.9, 0.06), RED)
		Props.obox(st, sc + b * Vector3(0, 0, -0.02), tb, Vector3(0.68, 0.68, 0.06), WHITE, Models.LIT_SIGN)
	var w := PixelFont.width("3,3M") * 0.03
	PixelFont.add_quads(st, "3,3M", sc + b * Vector3(0, 0, -0.06) - right * w * 0.5 + Vector3.UP * 0.15, right,
			Vector3.DOWN, 0.03, Color("#1b1b1b"), Models.FIXED)
	count += 1


## A red and white bollard (the photos': white, two red bands, a dark foot), 0.85 m.
func _bollard(st: SurfaceTool, at: Vector3) -> void:
	var b := Basis()
	Props.obox(st, at + Vector3(0, 0.03, 0), b, Vector3(0.2, 0.06, 0.2), Color("#3a3d42"))
	Props.obox(st, at + Vector3(0, 0.43, 0), b, Vector3(0.13, 0.8, 0.13), WHITE)
	Props.obox(st, at + Vector3(0, 0.5, 0), b, Vector3(0.14, 0.14, 0.14), RED)
	Props.obox(st, at + Vector3(0, 0.76, 0), b, Vector3(0.14, 0.12, 0.14), RED)
	count += 1
