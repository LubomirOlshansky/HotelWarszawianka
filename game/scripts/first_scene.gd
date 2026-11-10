extends Node3D
## First scene (docs/design/first-scene.md items 4 and 5, 2026-11-01): the street furniture the
## map data doesn't have, on Marszałkowska's east pavement in the first frame of play (by the
## Eastern Wall's stores, from Junior to the pavilions under the towers): a newspaper kiosk, a
## flower stall, café tables under parasols, an advertising column and concrete planters.
## Built at runtime on both city paths (it isn't in the sector scenes) as one mesh in the actors'
## material (models.gd), with R7's street plates, tram stop, bike dock and bollards, items 4-5's
## tram platform edge lines and Pasaż Wiecha's Y masts, cafés and bollards behind the stores: one draw call in view, no sun shadow below a metre (the planters). The
## kiosk and the stall stop the car; the rest are drive-through like the map's benches.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

## Marszałkowska's frame here: `s` metres north along the street from FRAME_O, `t` metres east
## of it (the east carriageway's middle is t 17, its kerb 21.6, the cycle path 26-28, the stores'
## overhang 32). Fronts face the street (west).
const FRAME_O := Vector2(-937.0, 210.1)
const FRAME_S := Vector2(-0.34917, -0.93706)
const FRAME_T := Vector2(0.93706, -0.34917)
## [kind, s, t, extra]: extra is a colour for planters, parasols and the column. Each faces the
## street's middle (t 8, the tram tracks). Only where the first frame sees them: the stores'
## own fronts hide behind their 17 m boxes from the game's camera, so the first frame's furniture
## stands on the west pavement in front of the museum (between the tree row at t -14 and the
## museum's edge at t -21.7), and more on the way to Świętokrzyska: in front of the low pavilions
## north of Junior and on the paving north of the museum (clear of the map's lamps and trees).
const ITEMS := [
	# west, in front of the museum (the first frame)
	["planter", 88.5, -20.4, "#e63946"],
	["cafe", 97.5, -20.2, "#2f6b4f"], ["cafe", 104.5, -20.2, "#f4f1de"], ["cafe", 111.5, -20.2, "#2f6b4f"],
	["planter", 127.0, -20.4, "#ffd23f"],
	["kiosk", 140.0, -19.9, ""],
	["stall", 149.5, -20.0, ""],
	["column", 158.0, -19.9, "#e07a5f"],
	["planter", 168.0, -20.4, "#9b5de5"],
	# east, in front of the pavilions under the towers
	["planter", 182.0, 33.6, "#e63946"],
	["cafe", 188.0, 34.2, "#24324a"], ["cafe", 194.5, 34.2, "#c8282a"], ["cafe", 201.0, 34.2, "#24324a"],
	["planter", 208.0, 33.6, "#ffd23f"],
	["column", 215.0, 33.4, "#e8d36a"],
	["planter", 233.0, 33.6, "#9b5de5"],
	# west, the paving north of the museum
	["planter", 188.0, -19.6, "#f4a261"],
	["kiosk", 196.5, -24.0, ""],
	["stall", 208.5, -24.6, ""],
	["column", 199.0, -30.5, "#9db4d8"],
	["planter", 221.0, -19.6, "#e8a6b8"],
	["cafe", 192.0, -31.0, "#2f6b4f"], ["cafe", 186.0, -27.0, "#e07a5f"],
	# The park strip in front of the museum (first-scene item 4, 2026-11-02): larch benches facing
	# the street between the tree row and the museum, and slim park lamps on the same line. The
	# strip's trees, grass and paths are the map's.
	["bench", 82.0, -17.2, ""], ["bench", 118.0, -17.2, ""], ["bench", 133.5, -17.0, ""],
	["bench", 176.0, -17.2, ""],
	["lamp", 92.0, -16.2, ""], ["lamp", 122.0, -16.2, ""], ["lamp", 163.0, -16.2, ""],
	# The start area as real Warsaw (R7, docs/design/start-area-real.md, 2026-11-01): the street
	# name plates at the crossings (Widok by Wars, Sienkiewicza by Junior, Fangora by the museum),
	# the tram stop on Marszałkowska's island north of the museum (the map has its platform but no
	# shelter), a city bike dock and bollard rows on Plac Centralny's edge.
	["plates", -171.0, 23.4, "MARSZAŁKOWSKA|WIDOK"],
	["plates", 168.5, 23.4, "MARSZAŁKOWSKA|SIENKIEWICZA"],
	["plates", 192.0, -16.6, "MARSZAŁKOWSKA|FANGORA"],
	["shelter", 272.0, 13.6, ""], ["shelter", 306.0, 13.6, ""],
	["stop", 254.0, 12.3, ""], ["ticket", 288.0, 14.4, ""],
	["bikes", 66.0, -17.6, ""],
	["bollards", 32.0, -7.2, ""], ["bollards", 47.0, -7.2, ""], ["bollards", 75.5, -7.2, ""],
	# Krajobraz K2 (docs/design/krajobraz-places.md, 2026-11-02): Chmielna meets Pasaż Wiecha
	# behind the Eastern Wall, at the square named after August Agbola Browne ("Ali", jazz
	# musician and Uprising fighter, 1 Aug 2024), with his memorial stone (2019) by its bed; the
	# plates at the corner. Both stand on the new granite, clear of the square's tree.
	["plates", -67.5, 68.2, "PASAŻ WIECHA|CHMIELNA"],
	["plates", -60.4, 73.5, "SKWER BROWNE'A"],
	["stone", -63.2, 74.1, ""],
	# Pasaż Wiecha behind the stores (items 4-5, 2026-11-02, the Mac photo report dt_pawilony):
	# café gardens under white parasols in front of the pavilions (landmarks.gd `wiecha`), planters
	# and black bollards across both ends. The pasaż runs between the stores' backs (t 62) and the
	# pavilions' fronts (t 72-77; 93 by the square at Chmielna). Its white Y masts are PASAZ below.
	["planter", 80.5, 70.2, "#e8a6b8"],
	["cafe", 84.0, 69.6, "#f4f2ec"], ["cafe", 90.0, 69.6, "#f4f2ec"], ["cafe", 96.0, 69.6, "#f4f2ec"],
	["planter", 101.0, 70.2, "#ffd23f"],
	["planter", -1.0, 74.6, "#f4a261"],
	["cafe", 3.0, 74.0, "#f4f2ec"], ["cafe", 9.0, 74.0, "#f4f2ec"], ["cafe", 15.0, 74.0, "#f4f2ec"],
	["planter", 20.0, 74.6, "#e63946"],
	["cafe", -57.0, 89.5, "#f4f2ec"], ["cafe", -51.0, 89.5, "#f4f2ec"], ["cafe", -45.5, 89.5, "#f4f2ec"],
	["planter", -48.0, 85.0, "#9b5de5"],
	["bollards_x", -167.0, 67.5, ""], ["bollards_x", 113.0, 67.5, ""],
]
## Pasaż Wiecha in the frame above, [s0, s1, t0, t1]: from Aleje Jerozolimskie to the north end
## behind Junior, between the stores' backs and the pavilions. The map's lamps in it (OSM, on the
## pasaż's axis) become the photos' white Y masts: a single pole splitting into two arms with long
## lamp blades (map_builder.gd skips those lamps). PASAZ_MASTS fills the 74 m gap the map leaves
## under the slab, so they stand about every 25 m.
const PASAZ := [-172.0, 116.0, 63.0, 74.0]
const PASAZ_MASTS := [[-15.0, 68.0], [10.0, 68.0], [100.0, 67.5]]
## First scene item 6 (2026-11-02): Marszałkowska's two pavements from Widok to the tram stop north
## of the museum, [s0, s1, t0, t1] in the frame above: the west one between the museum's edge and the
## tree row, the east one from the kerb to the stores' arcades. Walkers there are denser while the
## view is on the start (pedestrians.gd set_busy).
const BUSY_BANDS := [[-200.0, 330.0, -30.0, -13.0], [-200.0, 330.0, 22.0, 37.0]]
## The kinds that stand on a tram island (centrum.json `platforms`): on its top
## (map_builder.platform_top; 0.3 m since the tram-stops pass, 2026-11-07).
const ON_PLATFORM := ["shelter", "stop", "ticket"]
## The middle of the street (the tram tracks), which every item faces.
const STREET_T := 8.0
## First-scene item 5's platform edges (the light band and the tactile strip) are drawn by
## map_builder.gd on every tram island since the tram-stops pass (2026-11-07, `te`).
## The kiosk's and the stall's footprints for the car (half sizes).
const SOLID := {"kiosk": Vector2(1.45, 1.1), "stall": Vector2(1.2, 0.9), "shelter": Vector2(2.15, 0.98),
		"stone": Vector2(0.6, 0.4)}

var map: Node3D
var count := 0


## Builds the mesh and the colliders; `map` gives the ground (map_builder.ground_height).
func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "FirstSceneSolids"
	for item: Array in ITEMS:
		var p := FRAME_O + FRAME_S * float(item[1]) + FRAME_T * float(item[2])
		# +z of a prop points away from the street, so its -z front faces it.
		var face := FRAME_T * signf(float(item[2]) - STREET_T)
		var yaw := atan2(face.x, face.y)
		var kind: String = item[0]
		var y: float = map.ground_height(p.x, p.y)
		if kind in ON_PLATFORM:
			var top: float = map.platform_top(p.x, p.y)
			if not is_nan(top):
				y = maxf(y, top)
		var xf := Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, y, p.y))
		match kind:
			"kiosk":
				Props.add_kiosk(st, xf)
			"stall":
				Props.add_flower_stall(st, xf)
			"cafe":
				Props.add_cafe_set(st, xf, Color(item[3]))
			"planter":
				Props.add_planter(st, xf, Color(item[3]))
			"column":
				Props.add_ad_column(st, xf, Color(item[3]))
			"plates":
				var names: PackedStringArray = String(item[3]).split("|")
				Props.add_street_plates(st, xf, names[0], names[1] if names.size() > 1 else "")
			"shelter":
				Props.add_tram_shelter(st, xf)
			"stop":
				Props.add_stop_post(st, xf)
			"ticket":
				Props.add_ticket_machine(st, xf)
			"bikes":
				# The row runs along the street: the dock turned a quarter.
				Props.add_bike_dock(st, Transform3D(xf.basis * Basis(Vector3.UP, PI * 0.5), xf.origin))
			"bollards":
				Props.add_bollards(st, xf, 5)
			"bollards_x":
				# Across the pasaż: the row turned a quarter.
				Props.add_bollards(st, Transform3D(xf.basis * Basis(Vector3.UP, PI * 0.5), xf.origin), 5)
			"stone":
				Props.add_memorial_stone(st, xf)
			"bench":
				Props.add_long_bench(st, xf, 2.4)
			"lamp":
				Props.add_park_lamp(st, xf)
		if SOLID.has(kind):
			var half: Vector2 = SOLID[kind]
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(half.x * 2.0, 2.4, half.y * 2.0)
			shape.shape = box
			shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * 1.2)
			body.add_child(shape)
		count += 1
	_pasaz_masts(st)
	var mi := MeshInstance3D.new()
	mi.name = "FirstSceneProps"
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	add_child(mi)
	add_child(body)


## Whether a point (plan x, z) lies on Pasaż Wiecha (PASAZ). map_builder.gd asks it for each lamp.
static func on_pasaz(p: Vector2) -> bool:
	var d := p - FRAME_O
	var s := d.dot(FRAME_S)
	var t := d.dot(FRAME_T)
	return s > PASAZ[0] and s < PASAZ[1] and t > PASAZ[2] and t < PASAZ[3]


## Pasaż Wiecha's Y masts: one at each of the map's lamps on it, and PASAZ_MASTS; the arms span
## the pasaż (they face the street like the rest).
func _pasaz_masts(st: SurfaceTool) -> void:
	var at: Array[Vector2] = []
	var lamps: Array = map.data.get("lamps", [])
	for i in range(0, lamps.size() - 1, 2):
		var p := Vector2(float(lamps[i]), float(lamps[i + 1]))
		if on_pasaz(p):
			at.append(p)
	for m: Array in PASAZ_MASTS:
		at.append(FRAME_O + FRAME_S * float(m[0]) + FRAME_T * float(m[1]))
	var yaw := atan2(FRAME_T.x, FRAME_T.y)
	for p in at:
		Props.add_y_mast(st, Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, map.ground_height(p.x, p.y), p.y)))
		count += 1
