extends Node3D
## The base of every place script (pipeline review item 7, 2026-11-13): a spot in the city with
## its own dressing (furniture, signs, standing people, a small structure) that is not a
## landmark site. A place is one script that extends this and one row in `Places.TABLE`
## (places.gd); main.gd never wires one by hand.
##
## Static dressing in the actors' material (`Models.material()`) goes through `pour`: the place
## commits its mesh and hands it over, and places.gd merges every poured mesh into one
## MeshInstance3D per map sector, so the dressing costs one draw call per sector however many
## places stand in it. Anything else (a mesh with its own material, something that moves, a
## StaticBody3D) goes through `part`.
##
## Without an owner (a check builds the place alone) `pour` makes the MeshInstance3D the scripts
## made by hand before this base existed, so a place can still be looked at on its own.

const _Models := preload("res://scripts/models.gd")

## The city (ground heights, the sunk rings), as main.gd always gave it.
var map: Node3D
## What main.gd hands every place (places.gd sets it before `build`): "data" (the map's data),
## "dialogue", "clock" (TimeOfDay.local_clock), "focus", "vehicle" (callables) and "logs"
## ({"tamka": bool}, the `--tamka-log` flag).
var ctx := {}
## Pieces placed, for the log line (a place that counts keeps it).
var count := 0
## The place's own triangle count, for scripts that print it (the owner counts from `pour` and
## `part` itself and does not read this).
var tris := 0
## Triangles poured to the owner (or to the fallback instance) and the draw items added by `part`
## with their triangles: what places.gd and check_places.gd read.
var poured := 0
var own_parts := 0
var part_tris := 0
## The owner (places.gd) taking the poured meshes; null when the place is built alone.
var hub: Node


## Builds the place. Virtual: every place script overrides it and takes everything it needs from
## `map` and `ctx`.
func build() -> void:
	pass


## Hands over a committed mesh of static dressing, drawn in `Models.material()`. `label` names the
## stand-alone instance only (the name the script gave it before this base).
func pour(mesh: ArrayMesh, shadows := true, label := "") -> void:
	poured += mesh_triangles(mesh)
	if hub != null:
		if mesh.get_surface_count() > 0:
			hub.call("take", mesh, shadows)
		return
	var mi := MeshInstance3D.new()
	if label != "":
		mi.name = label
	mi.mesh = mesh
	mi.material_override = _Models.material()
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Adds a node that is not poured dressing: a mesh with its own material, something that moves, a
## StaticBody3D. It is `add_child` plus the count (and the triangles) of the draw item the owner
## budgets under `own`.
func part(node: Node3D) -> void:
	add_child(node)
	if node is MeshInstance3D:
		own_parts += 1
		part_tris += mesh_triangles((node as MeshInstance3D).mesh)


## The triangles of every surface of a mesh (indexed or not).
static func mesh_triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var n := 0
	for s in mesh.get_surface_count():
		var idx: int = mesh.surface_get_array_index_len(s)
		n += (idx if idx > 0 else mesh.surface_get_array_len(s)) / 3
	return n


## Everything the place made: poured and its own parts.
func total_triangles() -> int:
	return poured + part_tris
