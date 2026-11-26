shader_type canvas_item;
// The drive after THE TAPCZAN (tipsy.gd): the city seen double and soft at the edges. Three taps
// of the city's own screen (a ghost that drifts and a fainter one opposite), a warm tint and a
// vignette, all scaled by `amount` (0: off; the node is hidden then, so it costs nothing).
// It sits in the city's SubViewport, so the HUD on top stays sharp.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
uniform float t = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = vec2(sin(t * 1.3), cos(t * 0.9)) * 0.012 * amount;
	vec3 a = texture(screen_tex, uv).rgb;
	vec3 b = texture(screen_tex, uv + off).rgb;
	vec3 c = texture(screen_tex, uv - off * 0.6).rgb;
	vec3 col = mix(a, (a + b + c) / 3.0, 0.8 * amount);
	float v = smoothstep(0.35, 0.95, distance(uv, vec2(0.5)));
	col *= 1.0 - v * 0.45 * amount;
	col = mix(col, col * vec3(1.06, 0.98, 0.9), amount * 0.5);
	COLOR = vec4(col, 1.0);
}
