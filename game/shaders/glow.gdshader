shader_type spatial;
// Additive light that only shows when the city's lights are on: headlight cones on
// the road, the helicopter's searchlight pool, halos round lamps and signal heads.
// Vertex colour = light colour, its alpha = brightness; a MultiMesh instance colour
// (if used) multiplies it, so a dark instance colour switches a halo off.
//
// It draws after the post-process quad (render_priority 1 on the material), like
// every see-through surface in this game; the post pass repaints the screen from a
// copy taken before the transparent pass and would wipe it out otherwise.

render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

global uniform float lights_on;

#include "res://shaders/tunnel_cut.gdshaderinc"

uniform float strength = 1.0;
// Metres the surface is pulled towards the camera (depth only): pools lie on the
// road, whose layers are already pulled up to 0.42 m (ground.gdshader).
uniform float lift = 0.9;
// Halos: turn the quad to face the camera, `radius` metres from the centre.
uniform bool billboard = false;
// Halos fade with the distance from the quad's centre (UV 0..1 across it).
uniform bool radial = false;
// Loop 1: blink in the roadwork lamps' beat (actor.gdshader, part 7).
uniform bool blink = false;

void vertex() {
	// The tunnel cutaway (tunnel_cut.gdshaderinc): a lamp's halo over the opened ground goes with it.
	VERTEX = tunnel_hide(VERTEX, MODEL_MATRIX[3].xyz);
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.z += lift;
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	float a = COLOR.a;
	if (radial) {
		float r = length(UV - 0.5) * 2.0;
		a *= pow(clamp(1.0 - r, 0.0, 1.0), 2.2);
	}
	if (!billboard && !radial) {
		// Loop 3i (art bible: light on the ground is pixel light, never a smooth gradient):
		// the light on the road (headlight fans, tail glows, the searchlight's pool) in three
		// hard bands like the lamp pools, with a one-pixel checker where two bands meet.
		float d = mod(floor(FRAGCOORD.x) + floor(FRAGCOORD.y), 2.0) * 0.024 - 0.012;
		float b = a + d;
		a = b > 0.22 ? 0.46 : (b > 0.11 ? 0.27 : (b > 0.035 ? 0.11 : 0.0));
	}
	if (blink) {
		a *= step(0.42, fract(TIME * 1.15));
	}
	ALBEDO = COLOR.rgb * a * strength * lights_on;
}
