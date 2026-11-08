extends Node3D
## Street details along the main line (docs/design/street-details.md, BACKLOG audit item 5): kiosks,
## flower stalls, café tables, planters, ad columns, bollards, an ice-cream cart and tram/bus stop
## kits on the pavements of the streets the main line sends the player down, from
## game/data/street_details.json (tools/bake_street_details.py). first_scene.gd keeps the start.
##
## Built at runtime on both city paths (not in the sector scenes), one mesh per CELL m square in the
## actors' material (models.gd): one draw call a cell in view, cast_shadow OFF for all of it (a
## contact pad on the paving under the tall props stands in for the shadow). Kiosks, stalls and the
## cart stop the car (one box each in one StaticBody); the rest are drive-through like the map's
## benches. A tram shelter stands on Rondo Dmowskiego's unsheltered east island (2026-11-02). PRASA = press, KWIATY = flowers, LODY = ice cream, BILETY = tickets.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

const FILE := "res://data/street_details.json"
## The cell size of one mesh (the map's sector size).
const CELL := 512.0
## Footprint halves (x, z) of the pad under a tall prop, and of the car's box for the solid ones.
const PAD := {"kiosk": Vector2(1.6, 1.2), "stall": Vector2(1.4, 1.0), "cafe": Vector2(1.4, 1.4),
		"cart": Vector2(1.0, 0.7), "column": Vector2(0.7, 0.7), "heater": Vector2(0.4, 0.4)}
const SOLID := {"kiosk": Vector2(1.45, 1.1), "stall": Vector2(1.2, 0.9), "cart": Vector2(0.9, 0.6)}
## Per-sector and total limits (the budget in the spec); check_street_details.gd holds the file to them.
const MAX_ITEMS := 900
const MAX_SECTOR := 100
## A stop kit item whose colour is this stands on a tram island (map `platforms`), on its top
## (map_builder.platform_top), not on the paving.
const ON_PLATFORM := "platform"

var map: Node3D
var count := 0
var meshes := 0


## The baked items: [kind, x, z, yaw, colour] arrays, [] when the file is missing.
static func load_items() -> Array:
	if not FileAccess.file_exists(FILE):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if parsed is Dictionary and (parsed as Dictionary).has("items"):
		return (parsed as Dictionary)["items"]
	return []


## Adds one item's pieces to `st` at `xf` (a pad first for the tall kinds).
static func add_item(st: SurfaceTool, kind: String, xf: Transform3D, colour: String) -> void:
	if PAD.has(kind):
		Props.add_contact_pad(st, xf, PAD[kind])
	match kind:
		"kiosk":
			Props.add_kiosk(st, xf)
		"stall":
			Props.add_flower_stall(st, xf)
		"cafe":
			Props.add_cafe_set(st, xf, Color(colour))
		"planter":
			Props.add_planter(st, xf, Color(colour))
		"column":
			Props.add_ad_column(st, xf, Color(colour))
		"bollards":
			Props.add_bollards(st, xf)
		"cart":
			Props.add_ice_cream_cart(st, xf, Color(colour))
		"post":
			Props.add_stop_post(st, xf)
		"ticket":
			Props.add_ticket_machine(st, xf)
		"bench":
			Props.add_stop_bench(st, xf)
		"heater":
			Props.add_patio_heater(st, xf)
		"shelter":
			Props.add_tram_shelter(st, xf)


## Builds the meshes and the colliders; `map` gives the ground (map_builder.ground_height).
func build() -> void:
	var cells := {}
	for item: Array in load_items():
		var key := Vector2i(int(floorf(float(item[1]) / CELL)), int(floorf(float(item[2]) / CELL)))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(item)
	var body := StaticBody3D.new()
	body.name = "StreetDetailSolids"
	for key: Vector2i in cells:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item: Array in cells[key]:
			var x := float(item[1])
			var z := float(item[2])
			var y: float = map.ground_height(x, z)
			if str(item[4]) == ON_PLATFORM:
				var top: float = map.platform_top(x, z)
				if not is_nan(top):
					y = maxf(y, top)
			var xf := Transform3D(Basis(Vector3.UP, float(item[3])), Vector3(x, y, z))
			var kind: String = item[0]
			add_item(st, kind, xf, str(item[4]))
			if SOLID.has(kind):
				var half: Vector2 = SOLID[kind]
				var shape := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(half.x * 2.0, 2.4, half.y * 2.0)
				shape.shape = box
				shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * 1.2)
				body.add_child(shape)
			count += 1
		var mi := MeshInstance3D.new()
		mi.name = "StreetDetails_%d_%d" % [key.x, key.y]
		mi.mesh = st.commit()
		mi.material_override = Models.material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		meshes += 1
	add_child(body)
