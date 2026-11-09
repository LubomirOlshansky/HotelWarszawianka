class_name GpuQuirks
## Workarounds for one GPU family's driver, decided once from the adapter's name.
##
## Adreno 6xx (the Nothing Phone 1's 642L, Vulkan driver 1.1.128 of 2024): the driver fails to link
## a pipeline ("Failed to link shaders", VkResult -13) once the fragment stage's control flow grows
## past a limit (each branch, short-circuit && / ||, function call and early return counts, Godot's
## own lighting code included), and the mesh then doesn't draw at all: on main b3297b1e the ground,
## roads and buildings were missing. common.gdshaderinc (macros) and the all()/any() conditions
## bring ground.gdshader under it everywhere; building.gdshader is still over, so on these GPUs it
## runs as a "lite" copy: Godot's specular lobe off (the walls are rough, roughness 0.95, so it is
## barely seen), which frees enough of the budget. Every other GPU keeps the shader as it is.
## tools/check_shader_budget.gd keeps both under the limit (docs/archive/DEVELOPMENT-full.md,
## "Adreno 6xx shader budget").

const BUILDING := "res://shaders/building.gdshader"
## The line the lite copy changes (building.gdshader's first render_mode); the check asserts it.
const BUILDING_MODE := "render_mode cull_disabled;"
const BUILDING_LITE_MODE := "render_mode cull_disabled, specular_disabled;\n#define BUILDING_LITE"

static var forced := false   ## --lite-shaders: the lite copies on any GPU (Mac shots of the look)
static var _lite := -1
static var _building: Shader


## Whether this GPU needs the lite shaders: an Adreno numbered below 700 (5xx and 6xx share the
## compiler generation), or `forced`.
static func lite() -> bool:
	if forced:
		return true
	if _lite < 0:
		_lite = 1 if is_old_adreno(RenderingServer.get_video_adapter_name()) else 0
	return _lite == 1


## "Adreno (TM) 642L" and the like, model 300 to 699.
static func is_old_adreno(adapter: String) -> bool:
	var m := RegEx.create_from_string("Adreno[^0-9]*([0-9])[0-9][0-9]").search(adapter)
	return m != null and int(m.get_string(1)) < 7


## The buildings' shader for this GPU: building.gdshader, or its lite copy (made once from the
## same code, so the two never drift apart).
static func building_shader() -> Shader:
	var full := load(BUILDING) as Shader
	if not lite():
		return full
	if _building == null:
		_building = Shader.new()
		_building.code = lite_code(full.code)
	return _building


## building.gdshader's code with the lite render mode (unchanged, with an error, when the anchor is gone).
static func lite_code(code: String) -> String:
	if not code.contains(BUILDING_MODE):
		push_error("gpu_quirks: no \"%s\" in %s" % [BUILDING_MODE, BUILDING])
		return code
	return code.replace(BUILDING_MODE, BUILDING_LITE_MODE)
