extends Node3D
## Park details (BACKLOG "Parks", 2026-11-01): the pieces that make Ogród Saski, Ogród Krasińskich,
## Park Ujazdowski and the Łazienki end of the map read as parks: statues, fountains, a carousel,
## a playground, gazebos, a sundial, footbridges, ducks and swans, peacocks and squirrels, people on
## the benches, picnics and a yoga class. From game/data/park_details.json
## (tools/bake_park_details.py), same shape as street_details.json: `items` = [kind, x, z, yaw,
## colour]. Built at runtime on both city paths, one mesh per CELL m square in the actors' material:
## one draw call a cell in view, no sun shadow (a contact pad stands in under the tall pieces). The
## solid pieces (statues, fountains, the carousel, the playground, gazebos) stop the car with one
## box each; everything else drives through like the map's benches. Fronts face -Z.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const Water := preload("res://scripts/park_props_water.gd")
const Play := preload("res://scripts/park_props_play.gd")
const Life := preload("res://scripts/park_props_life.gd")
## The city's OSM monuments and plaques share these per-cell meshes (monuments.gd).
const Monuments := preload("res://scripts/monuments.gd")

const FILE := "res://data/park_details.json"
## The cell size of one mesh (the map's sector size).
const CELL := 512.0
## Footprint halves (x, z) of the contact pad under a tall piece (shadows are off for the mesh).
const PAD := {"statue": Vector2(0.9, 0.9), "fountain": Vector2(3.2, 3.2), "carousel": Vector2(2.7, 2.7),
		"playground": Vector2(3.4, 3.0), "gazebo": Vector2(2.4, 2.4), "sundial": Vector2(0.7, 0.7),
		"pergola": Vector2(3.2, 1.6), "ropecourse": Vector2(7.0, 4.5)}
## Half sizes (x, z) of the car's box for the solid pieces.
const SOLID := {"statue": Vector2(0.8, 0.8), "fountain": Vector2(3.0, 3.0), "carousel": Vector2(2.5, 2.5),
		"playground": Vector2(3.2, 2.8), "gazebo": Vector2(2.2, 2.2), "sundial": Vector2(0.55, 0.55), "ropecourse": Vector2(6.0, 4.0)}
## Which file builds which kind (all `add_<kind>(st, xf, colour)`).
const WATER_KINDS := ["duck", "swan", "footbridge", "fountain", "rowboat"]
const PLAY_KINDS := ["carousel", "playground", "gazebo", "sundial", "pergola", "ropecourse"]
const LIFE_KINDS := ["seated", "picnic", "peacock", "squirrel", "statue", "yoga"]
## Per-sector and total limits; check_park_details.gd holds the file to them.
const MAX_ITEMS := 700
const MAX_SECTOR := 400

var map: Node3D
var count := 0
var meshes := 0
## How many of `count` are monuments and plaques (monuments.gd).
var monuments := 0


## The baked items: [kind, x, z, yaw, colour] arrays, [] when the file is missing.
static func load_items() -> Array:
	if not FileAccess.file_exists(FILE):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if parsed is Dictionary and (parsed as Dictionary).has("items"):
		return (parsed as Dictionary)["items"]
	return []


## Whether `kind` is one this file builds.
static func known(kind: String) -> bool:
	return WATER_KINDS.has(kind) or PLAY_KINDS.has(kind) or LIFE_KINDS.has(kind)


## Adds one item's pieces to `st` at `xf` (a pad first for the tall kinds).
static func add_item(st: SurfaceTool, kind: String, xf: Transform3D, colour: String) -> void:
	if PAD.has(kind):
		Props.add_contact_pad(st, xf, PAD[kind])
	var c := Color(colour)
	match kind:
		"duck": Water.add_duck(st, xf, c)
		"swan": Water.add_swan(st, xf, c)
		"footbridge": Water.add_footbridge(st, xf, c)
		"fountain": Water.add_fountain(st, xf, c)
		"rowboat": Water.add_rowboat(st, xf, c)
		"carousel": Play.add_carousel(st, xf, c)
		"playground": Play.add_playground(st, xf, c)
		"gazebo": Play.add_gazebo(st, xf, c)
		"sundial": Play.add_sundial(st, xf, c)
		"ropecourse": Play.add_ropecourse(st, xf, c)
		"pergola": Play.add_pergola(st, xf, c)
		"seated": Life.add_seated(st, xf, c)
		"picnic": Life.add_picnic(st, xf, c)
		"peacock": Life.add_peacock(st, xf, c)
		"squirrel": Life.add_squirrel(st, xf, c)
		"statue": Life.add_statue(st, xf, c)
		"yoga": Life.add_yoga(st, xf, c)


## Builds the meshes and the colliders; `map` gives the ground (map_builder.ground_height).
func build() -> void:
	var cells := {}
	var all := load_items()
	all.append_array(Monuments.load_items())
	for item: Array in all:
		var key := Vector2i(int(floorf(float(item[1]) / CELL)), int(floorf(float(item[2]) / CELL)))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(item)
	var body := StaticBody3D.new()
	body.name = "ParkDetailSolids"
	body.set_meta(&"solid", &"prop")  # park pieces and monuments.gd's: the solid class (solidity.gd)
	for key: Vector2i in cells:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item: Array in cells[key]:
			var x := float(item[1])
			var z := float(item[2])
			var xf := Transform3D(Basis(Vector3.UP, float(item[3])), Vector3(x, map.ground_height(x, z), z))
			var kind: String = item[0]
			var solid := SOLID
			if item.size() > 5 and Monuments.known(kind):
				Monuments.add_item(st, kind, xf, str(item[4]))
				solid = Monuments.SOLID
				monuments += 1
			else:
				add_item(st, kind, xf, str(item[4]))
			if solid.has(kind):
				var half: Vector2 = solid[kind]
				var shape := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(half.x * 2.0, 2.4, half.y * 2.0)
				shape.shape = box
				shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * 1.2)
				body.add_child(shape)
			count += 1
		var mi := MeshInstance3D.new()
		mi.name = "ParkDetails_%d_%d" % [key.x, key.y]
		mi.mesh = st.commit()
		mi.material_override = Models.material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		meshes += 1
	add_child(body)
