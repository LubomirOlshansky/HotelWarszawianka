extends Node3D
## Loop 3b: the player's car seen through the ground while it drives inside a tunnel. Since
## 2026-11-08 (F) the ground over the tunnel opens round the car instead (the tunnel cutaway,
## main.gd `_update_tunnel_cut`); the silhouette stays for --no-ghost, the top-down view and
## Fotka's photo, and for decks with --no-ghost. The car shows as a warm silhouette through it: copies of its meshes with one unshaded material that ignores depth, drawn
## after the post pass, shown only while map_builder.gd `in_tunnel` says the car is down in a
## tunnel (one extra draw call per mesh then, none otherwise).

const COLOUR := Color(1.0, 0.82, 0.45, 0.6)

var _parts: Array[MeshInstance3D] = []
var _on := false


## Copies the car's solid meshes (those that cast a shadow) as children of the originals.
func setup(car: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.albedo_color = COLOUR
	mat.render_priority = Material.RENDER_PRIORITY_MAX
	for node in car.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.visible or mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue  # the body and its solid parts only (not the lamps' glow or the beams)
		var copy := MeshInstance3D.new()
		copy.mesh = mi.mesh
		copy.material_override = mat
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		copy.visible = false
		mi.add_child(copy)
		_parts.append(copy)


## Shows or hides the silhouette (called every frame; changes nothing when it stays the same).
func show_through(on: bool) -> void:
	if on == _on:
		return
	_on = on
	for p in _parts:
		p.visible = on
