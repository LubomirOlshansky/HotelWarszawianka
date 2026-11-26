shader_type spatial;
// Neon shop signs (neon_signs.gd): one quad per sign from a MultiMesh. The words
// atlas holds the tubes (red) and a faded ring of glow round them (green); the
// instance colour is the tube's colour, INSTANCE_CUSTOM = (atlas row, word width
// as a share of the atlas, 1 = on a dark plate, flicker seed). Unshaded and bright
// enough for the night glow to bloom; the game hides the signs by day.

render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

// Sweep 2: ghosted with the wall it hangs on (ghost.gdshaderinc; main.gd _update_ghost sets
// the values): the art bible's "nothing glows" inside the ghost, so a sign there goes
// altogether in the core (none of it kept: kept tube pixels sparkled round the car) and is
// dithered over the rim like building.gdshader.
#include "res://shaders/ghost.gdshaderinc"
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

global uniform float lights_on;

uniform sampler2D words : filter_nearest, repeat_disable;
uniform float rows = 9.0;

varying vec4 info;
varying vec3 tube;

void vertex() {
	info = INSTANCE_CUSTOM;
	tube = COLOR.rgb;
}

void fragment() {
	// Sweep 2: the ghost (see the top).
	float fade = ghost_fade(VERTEX.xy, (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz);
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	if ((BAYER[p.y * 4 + p.x] + 0.5) / 16.0 < fade) {
		discard;
	}
	// Seen from behind (the quad is cull_disabled) the word would read mirrored: flip U on a back
	// face, so every sign reads correctly from both sides (the HOTEL MDM report, 2026-11-26).
	float u = FRONT_FACING ? UV.x : 1.0 - UV.x;
	vec4 t = texture(words, vec2(u * info.y, (info.x + UV.y) / rows));
	// A tired tube: every so often it drops out for a moment.
	// The landmarks loop: a landmark's sign (INSTANCE_CUSTOM.z = 2) is lit by day too, on no plate.
	float on = info.z > 1.5 ? max(lights_on, 0.7) : lights_on;
	if (info.w > 0.88) {
		float n = fract(sin(floor(TIME * 9.0) * 12.9898 + info.w * 78.233) * 43758.5453);
		on *= n < 0.2 ? 0.12 : 1.0;
	}
	vec3 plate = vec3(0.014, 0.011, 0.024);
	if (t.r > 0.5) {
		ALBEDO = mix(tube, vec3(1.0), 0.4) * 2.2 * on;
	} else if (t.g > 0.3) {
		ALBEDO = tube * t.g * 0.85 * on + plate * min(info.z, 1.0);
	} else if (info.z > 0.5 && info.z < 1.5) {
		ALBEDO = plate;
	} else {
		discard;
	}
}
