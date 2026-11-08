shader_type spatial;
// 11 listopada (event_day.gd): the standing smoke. Soft round blobs that turn to face the camera,
// see-through (blend_mix), by day grey-pink and at night lit red-pink from inside by the flares
// (the `glow` uniform, set by event_day.gd). Like glow.gdshader it draws after the post pass
// (render_priority 1 on the material) and is pulled towards the camera by `lift` for depth only.

render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.86, 0.80, 0.82);
uniform vec3 lit_tint : source_color = vec3(1.0, 0.55, 0.52);
// 0 = daylight smoke, 1 = smoke lit by flares.
uniform float glow = 0.0;
uniform float density = 0.16;
uniform float lift = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	// The billboard matrix keeps only the instance's position: put its scale back.
	vec2 sc = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX.xy * sc, VERTEX.z, 1.0);
	view.z += lift;
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float a = pow(clamp(1.0 - r, 0.0, 1.0), 1.6) * density;
	ALBEDO = mix(tint, lit_tint, glow);
	ALPHA = a;
}
