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
## The turning hall's shut east end carries the car park's gates (BACKLOG "Dworzec Centralny's
## car park ramp": the real tunnel goes on to Złote Tarasy's car park): the wall is dressed as the
## entry, a dark opening with a hazard-striped header, two boom barriers standing raised, a ticket
## machine, the overhead "P" signs, a green exit door, the 2.1 m limit and a fire extinguisher.

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
## The hall's end wall (tools/centralny_ramp.py: the hall line's two ends, the wall across the
## last one, 11.3 m to each side).
const HALL_START := Vector2(-1572.1, 424.1)
const HALL_END := Vector2(-1552.6, 438.1)
const GATE_OPEN := 3.4          # the opening's width...
const GATE_H := 3.0             # ...and height
const GATE_AT := [-5.0, 5.0]    # each lane's gate: metres to the reader's right of the hall's middle
const DARK := Color("#17191d")
const STEEL := Color("#8d9298")
const YELLOW := Color("#e2b21c")
const GREEN := Color("#1e8a4c")
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
	_gates(st)
	_defilad_sign(st)
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


## The APCOA car park on Plac Defilad (F, 2026-11-09, Street View Aug 2025): over the top of its
## ramp (map_builder.gd SUNKEN `defilad_ramp`) a dark board on two steel posts, a white down arrow,
## "PARKING PODZIEMNY" and in a white box "24h 7dni", read from the street side (north-west, the way
## cars come), its foot 2.6 m over the ramp's top. Its back is plain dark steel.
const DEFILAD_TOP := Vector2(-1004.35, 222.0)
const DEFILAD_OUT := Vector2(-0.338, -0.941)
const DEFILAD_BOARD := Vector2(5.6, 1.5)
const BOARD_DARK := Color("#2a2f35")


func _defilad_sign(st: SurfaceTool) -> void:
	var y: float = map.ground_height(DEFILAD_TOP.x, DEFILAD_TOP.y)
	# The board's -z face looks along DEFILAD_OUT, away from the ramp.
	var b := Basis(Vector3.UP, atan2(-DEFILAD_OUT.x, -DEFILAD_OUT.y))
	var right: Vector3 = b * Vector3(-1, 0, 0)
	var out: Vector3 = b * Vector3(0, 0, -1)
	var centre := Vector3(DEFILAD_TOP.x, y + 2.6 + DEFILAD_BOARD.y * 0.5, DEFILAD_TOP.y)
	for sgn in [-1.0, 1.0]:
		var p: Vector3 = Vector3(DEFILAD_TOP.x, y, DEFILAD_TOP.y) + right * sgn * (DEFILAD_BOARD.x * 0.5 - 0.4)
		Props.obox(st, p + Vector3.UP * (2.6 + 0.6), b, Vector3(0.16, 3.8, 0.16), STEEL)
	Props.obox(st, centre, b, Vector3(DEFILAD_BOARD.x, DEFILAD_BOARD.y, 0.14), BOARD_DARK)
	Props.obox(st, centre + out * 0.075, b, Vector3(DEFILAD_BOARD.x - 0.16, DEFILAD_BOARD.y - 0.16, 0.02), Color("#3a4048"))
	var tl: Vector3 = centre + right * (-DEFILAD_BOARD.x * 0.5) + Vector3.UP * (DEFILAD_BOARD.y * 0.5) + out * 0.095
	# The down arrow on the left: a stem and a head of three bars.
	var ac: Vector3 = tl + right * 0.75 + Vector3.DOWN * 0.75
	Props.obox(st, ac + out * 0.01, b, Vector3(0.16, 0.7, 0.02), WHITE, Models.LIT_SIGN)
	for k in 3:
		var half := 0.34 - 0.11 * k
		Props.obox(st, ac + Vector3.DOWN * (0.28 + 0.1 * k) + out * 0.01, b, Vector3(half * 2.0, 0.1, 0.02), WHITE, Models.LIT_SIGN)
	PixelFont.add_quads(st, "PARKING", tl + right * 1.35 + Vector3.DOWN * 0.18, right, Vector3.DOWN, 0.04, WHITE, Models.LIT_SIGN)
	PixelFont.add_quads(st, "PODZIEMNY", tl + right * 1.35 + Vector3.DOWN * 0.74, right, Vector3.DOWN, 0.04, WHITE, Models.LIT_SIGN)
	# "24h 7dni" in a white box at the right end.
	var bc: Vector3 = tl + right * (DEFILAD_BOARD.x - 0.7) + Vector3.DOWN * 0.75
	Props.obox(st, bc + out * 0.01, b, Vector3(1.0, 0.95, 0.02), WHITE, Models.LIT_SIGN)
	PixelFont.add_quads(st, "24H", bc + right * -0.28 + Vector3.UP * 0.34 + out * 0.03, right, Vector3.DOWN, 0.03, BOARD_DARK, Models.FIXED)
	PixelFont.add_quads(st, "7DNI", bc + right * -0.32 + Vector3.UP * 0.02 + out * 0.03, right, Vector3.DOWN, 0.03, BOARD_DARK, Models.FIXED)
	count += 1


## A red and white bollard (the photos': white, two red bands, a dark foot), 0.85 m.
func _bollard(st: SurfaceTool, at: Vector3) -> void:
	var b := Basis()
	Props.obox(st, at + Vector3(0, 0.03, 0), b, Vector3(0.2, 0.06, 0.2), Color("#3a3d42"))
	Props.obox(st, at + Vector3(0, 0.43, 0), b, Vector3(0.13, 0.8, 0.13), WHITE)
	Props.obox(st, at + Vector3(0, 0.5, 0), b, Vector3(0.14, 0.14, 0.14), RED)
	Props.obox(st, at + Vector3(0, 0.76, 0), b, Vector3(0.14, 0.12, 0.14), RED)
	count += 1


## The car park's gates on the hall's end wall. `at(s, y, d)` is a point s metres to the reader's
## right of the wall's middle, y over the floor, d out from the wall into the hall.
func _gates(st: SurfaceTool) -> void:
	var u := (HALL_END - HALL_START).normalized()
	var b := Basis(Vector3.UP, atan2(u.x, u.y))
	var right: Vector3 = b * Vector3(-1, 0, 0)
	var origin := Vector3(HALL_END.x, FLOOR, HALL_END.y)
	var out: Vector3 = b * Vector3(0, 0, -1)
	for s: float in GATE_AT:
		_gate(st, origin + right * s, b, right, out)
	# The overhead sign between the two openings: white P on blue, the car park's name under it.
	var sign_c := origin + right * 0.0 + Vector3.UP * 4.1 + out * 0.12
	Props.obox(st, sign_c, b, Vector3(5.2, 1.3, 0.12), NAVY)
	var tl: Vector3 = sign_c + right * -2.4 + Vector3.UP * 0.55 + out * 0.07
	PixelFont.add_quads(st, "P", tl + right * 0.15, right, Vector3.DOWN, 0.07, WHITE, Models.LIT_SIGN)
	PixelFont.add_quads(st, "PARKING", tl + right * 1.0 + Vector3.DOWN * 0.1, right, Vector3.DOWN, 0.045, WHITE,
			Models.LIT_SIGN)
	PixelFont.add_quads(st, "ZŁOTE TARASY", tl + right * 1.0 + Vector3.DOWN * 0.65, right, Vector3.DOWN, 0.035, WHITE,
			Models.LIT_SIGN)
	# The green exit door and its lit sign, to the left of the gates; the 2.1 m limit on the right.
	var door := origin + right * -9.0 + Vector3.UP * 1.1 + out * 0.05
	Props.obox(st, door, b, Vector3(1.2, 2.2, 0.1), Color("#5b6168"))
	Props.obox(st, door + Vector3.UP * 1.45 + out * 0.03, b, Vector3(0.9, 0.3, 0.08), GREEN, Models.LIT_SIGN)
	PixelFont.add_quads(st, "WYJŚCIE", door + Vector3.UP * 1.54 + right * -0.38 + out * 0.08, right, Vector3.DOWN, 0.012,
			WHITE, Models.LIT_SIGN)
	var lim := origin + right * 9.0 + Vector3.UP * 3.3 + out * 0.08
	for turn in [0.0, PI * 0.25]:
		var tb := b * Basis(Vector3.BACK, turn)
		Props.obox(st, lim, tb, Vector3(0.7, 0.7, 0.06), RED)
		Props.obox(st, lim + out * 0.02, tb, Vector3(0.52, 0.52, 0.06), WHITE, Models.LIT_SIGN)
	var w := PixelFont.width("2,1M") * 0.022
	PixelFont.add_quads(st, "2,1M", lim + out * 0.06 - right * w * 0.5 + Vector3.UP * 0.1, right, Vector3.DOWN, 0.022,
			Color("#1b1b1b"), Models.FIXED)
	# A red fire extinguisher box on the wall by the door.
	Props.obox(st, origin + right * -7.6 + Vector3.UP * 1.3 + out * 0.08, b, Vector3(0.3, 0.5, 0.16), RED)
	count += 1


## One lane's gate at `c` (on the wall's foot): the dark opening, a hazard header, the steel
## jamb posts, a ticket machine on a kerb island and a boom barrier standing raised beside it.
func _gate(st: SurfaceTool, c: Vector3, b: Basis, right: Vector3, out: Vector3) -> void:
	Props.obox(st, c + Vector3.UP * GATE_H * 0.5 + out * 0.03, b, Vector3(GATE_OPEN, GATE_H, 0.06), DARK)
	for sgn in [-1.0, 1.0]:
		Props.obox(st, c + right * sgn * (GATE_OPEN * 0.5 + 0.15) + Vector3.UP * GATE_H * 0.5 + out * 0.08, b,
				Vector3(0.3, GATE_H, 0.18), STEEL)
	Props.obox(st, c + Vector3.UP * (GATE_H + 0.2) + out * 0.08, b, Vector3(GATE_OPEN + 0.9, 0.4, 0.18), STEEL)
	var n := 8
	for k in n:
		var x := (float(k) + 0.5) / n * (GATE_OPEN + 0.9) - (GATE_OPEN + 0.9) * 0.5
		if k % 2 == 0:
			Props.obox(st, c + right * x + Vector3.UP * (GATE_H + 0.2) + out * 0.18, b,
					Vector3((GATE_OPEN + 0.9) / n, 0.34, 0.02), YELLOW)
	# The island two metres out, the machine on it (grey post, blue head, a lit screen) and the
	# boom barrier beside it standing up: a white post with the arm raised, red bands on it.
	var isl := c + out * 2.2 + right * (GATE_OPEN * 0.5 + 0.7)
	Props.obox(st, isl + Vector3.UP * 0.08, b, Vector3(0.7, 0.16, 1.6), Color("#6e7278"))
	Props.obox(st, isl + Vector3.UP * 0.7, b, Vector3(0.34, 1.2, 0.3), Color("#3b4a63"))
	Props.obox(st, isl + Vector3.UP * 1.0 + out * 0.16, b, Vector3(0.22, 0.14, 0.02), Color("#a9e8ff"), Models.LIT_SIGN)
	var post := isl + right * 0.0 + out * -0.55
	Props.obox(st, post + Vector3.UP * 0.55, b, Vector3(0.22, 1.1, 0.22), WHITE)
	Props.obox(st, post + Vector3.UP * 0.75, b, Vector3(0.23, 0.18, 0.23), RED)
	for k in 5:
		var h := 1.2 + 0.28 * k
		Props.obox(st, post + Vector3.UP * (h + 0.14) + right * -0.1, b, Vector3(0.1, 0.28, 0.1),
				RED if k % 2 == 0 else WHITE)
	count += 1
