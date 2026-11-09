extends SceneTree
## The Adreno 6xx shader budget (2026-11-08, gpu_quirks.gd): that GPU's Vulkan driver fails to link
## a pipeline once the fragment stage's control flow is too big, and the mesh then doesn't draw
## (the Nothing Phone 1 drew no ground, roads or buildings). Measured on the phone with a probe app,
## one change at a time: every `if`, loop, early `return`, short-circuit `&&` / `||` and function
## call adds to it (each call counts its callee's whole body again, as the driver inlines it); a
## plain ternary, all() / any(), step() / mix() and straight-line maths don't. Godot's own lighting
## code shares the limit, so a lit shader has less room than an unshaded one, and building.gdshader's
## lite copy (no specular lobe) more than ground.gdshader.
##
## This counts that cost for every spatial shader in res://shaders from the source (includes
## resolved, comments dropped; the macros in common.gdshaderinc cost nothing) and fails when one is
## over its budget. The budgets sit a little under the first count that failed on the phone:
## ground.gdshader passed at 275 and failed at 285 (lit), building's lite copy passed at 508 and
## failed at 518, led_screen.gdshader (unshaded) passes at 309.
## Prints each shader's cost and `check_shader_budget: OK`, else the shaders over and exit 1.
##   godot --headless --path game --script res://tools/check_shader_budget.gd

const DIR := "res://shaders/"
const LIT_BUDGET := 260
const UNSHADED_BUDGET := 320
## building.gdshader runs as its lite copy on these GPUs (gpu_quirks.gd).
const BUDGETS := {"building.gdshader": 505}

var _func := RegEx.create_from_string("(?m)^[a-z][A-Za-z0-9_]*\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\([^;{]*\\)\\s*\\{")
var _flow := RegEx.create_from_string("\\bif\\s*\\(|\\bfor\\s*\\(|\\bwhile\\s*\\(|\\breturn\\b|\\?|&&|\\|\\|")
var _call := RegEx.create_from_string("\\b([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")


func _init() -> void:
	var over: PackedStringArray = []
	var files := DirAccess.get_files_at(DIR)
	for f in files:
		if not f.ends_with(".gdshader"):
			continue
		var code := _strip(_resolve(DIR + f, {}))
		if not code.contains("shader_type spatial"):
			continue
		var unshaded := RegEx.create_from_string("render_mode[^;]*\\bunshaded\\b").search(code) != null
		var budget: int = BUDGETS.get(f, UNSHADED_BUDGET if unshaded else LIT_BUDGET)
		var cost := fragment_cost(code)
		print("%s: %d of %d%s" % [f, cost, budget, " (unshaded)" if unshaded else ""])
		if cost > budget:
			over.append("%s %d > %d" % [f, cost, budget])
	if GpuQuirks.lite_code("render_mode cull_disabled;") == "render_mode cull_disabled;" \
			or not (load(GpuQuirks.BUILDING) as Shader).code.contains(GpuQuirks.BUILDING_MODE):
		over.append("gpu_quirks.gd's lite anchor \"%s\" is not in building.gdshader" % GpuQuirks.BUILDING_MODE)
	if not GpuQuirks.is_old_adreno("Adreno (TM) 642L") or GpuQuirks.is_old_adreno("Adreno (TM) 740") \
			or GpuQuirks.is_old_adreno("Apple A13 GPU") or GpuQuirks.is_old_adreno("Mali-G78"):
		over.append("gpu_quirks.gd is_old_adreno picks the wrong GPUs")
	if over.is_empty():
		print("check_shader_budget: OK")
		quit(0)
	else:
		print("check_shader_budget: %d over: %s" % [over.size(), "; ".join(over)])
		quit(1)


## The control-flow cost of fragment() with every call inlined.
func fragment_cost(code: String) -> int:
	var bodies := {}
	for m in _func.search_all(code):
		var depth := 1
		var i := m.get_end()
		while depth > 0 and i < code.length():
			var c := code[i]
			if c == "{":
				depth += 1
			elif c == "}":
				depth -= 1
			i += 1
		bodies[m.get_string(1)] = code.substr(m.get_end(), i - m.get_end())
	if not bodies.has("fragment"):
		return 0
	return _cost("fragment", bodies, {})


func _cost(name: String, bodies: Dictionary, memo: Dictionary) -> int:
	if memo.has(name):
		return memo[name]
	memo[name] = 0  # no recursion in GLSL; this only guards a parse slip
	var body: String = bodies[name]
	var n := _flow.search_all(body).size()
	for m in _call.search_all(body):
		var callee := m.get_string(1)
		if bodies.has(callee):
			n += 1 + _cost(callee, bodies, memo)
	memo[name] = n
	return n


## The shader's text with its #includes in place (each file once, as the include guards do).
func _resolve(path: String, seen: Dictionary) -> String:
	if seen.has(path):
		return ""
	seen[path] = true
	var out := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var t := line.strip_edges()
		if t.begins_with("#include"):
			out += _resolve(t.get_slice("\"", 1), seen) + "\n"
		else:
			out += line + "\n"
	return out


func _strip(code: String) -> String:
	code = RegEx.create_from_string("(?s)/\\*.*?\\*/").sub(code, "", true)
	return RegEx.create_from_string("//[^\\n]*").sub(code, "", true)
