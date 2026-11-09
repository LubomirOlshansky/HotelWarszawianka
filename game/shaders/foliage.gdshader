shader_type spatial;
// Tree crowns: per-tree colour from the MultiMesh, and the same dithered
// see-through hole as buildings wherever a crown covers the car. At night the
// street-lamp pools (night.gdshaderinc) light the crowns from below.
//
// The look loop (2026-10-28), trees only (sway > 0; the map side owns their sizes): each
// crown is pushed out and in by a few lumps of its own (seeded by where it stands), with
// its facets' normals taken from the pixels so the light follows the new shape; a
// two-tone pixel dapple of darker leaves; autumn crowns towards rust and olive (pure
// orange is the jobs' colour). Parked cars (sway 0) keep their paint as it is: loop 3b-2
// re-baked city.scn with models.gd PARKED_PAINT (no red: red is the player's), so the
// look loop's repaint of the old red parked cars here is gone.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"
#include "res://shaders/tunnel_cut.gdshaderinc"

uniform float clouds = 0.18;
// Crowns lean a little in the wind; parked cars use the same shader with sway = 0.
uniform float sway = 1.0;
// The paint's multiplier: the tree trunks (map_builder.gd `trunk_material`, sway 0, no instance
// colours) take their bark colour from it (sRGB); crowns and parked cars keep 1.
uniform vec3 tint = vec3(1.0);
// Rotor wash from a low helicopter: x, z of the rotor and a strength (0 = none).
uniform vec3 wash = vec3(0.0);
varying vec3 world_pos;
// Height of the vertex above the tree's (or parked car's) foot, for the lamp light.
varying float lift_h;
varying vec3 paint;

uniform vec3 car_view = vec3(0.0, 0.0, -100000.0);
uniform float fade_radius = 6.0;

// The broadleaf crown's middle in its model space (map_builder.gd _broadleaf_mesh) and how
// far the lumps push it out and in (share of the radius).
const vec3 CROWN_MIDDLE = vec3(0.0, 4.3, 0.0);
const float LUMPS = 0.2;
// Autumn: an orange crown (hue 12-50 degrees, saturated) turns rust (reddish brown), ochre
// or olive (yellow-green) depending on its hue, and loses some of its strength.
const vec3 RUST = vec3(0.58, 0.31, 0.2);
const vec3 OLIVE = vec3(0.56, 0.55, 0.24);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// A crown's colour (sRGB) with the jobs' orange taken out.
vec3 autumn(vec3 c) {
	float hi = max(c.r, max(c.g, c.b));
	float lo = min(c.r, min(c.g, c.b));
	float sat = (hi - lo) / max(hi, 1e-4);
	if (c.r < hi || c.b > c.g || sat < 0.5) {
		return c; // greens and anything already muted stay as they are
	}
	float hue = 60.0 * (c.g - c.b) / max(hi - lo, 1e-4);
	if (hue < 12.0 || hue > 50.0) {
		return c;
	}
	// Red-orange towards rust, golden towards olive, ochre-brown between, scaled a little
	// by the crown's brightness.
	return mix(RUST, OLIVE, smoothstep(18.0, 42.0, hue)) * (0.8 + 0.25 * hi);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	lift_h = VERTEX.y;
	paint = COLOR.rgb * tint;
	if (sway > 0.0) {
		// Lumps: the crown pushed out and in along its own directions, three soft lobes
		// seeded by the tree's position, so no two crowns are the same gumdrop.
		vec3 seed = MODEL_MATRIX[3].xyz;
		vec3 d = VERTEX - CROWN_MIDDLE;
		vec3 dir = normalize(d + vec3(1e-4));
		float lump = sin(dot(dir, vec3(2.1, 1.3, -1.7)) * 2.2 + seed.x * 0.71)
				+ sin(dot(dir, vec3(-1.4, 2.4, 1.9)) * 1.9 + seed.z * 0.53)
				+ 0.6 * sin(dot(dir, vec3(1.8, -0.9, 2.6)) * 2.6 + (seed.x + seed.z) * 0.37);
		VERTEX = CROWN_MIDDLE + d * (1.0 + LUMPS * lump / 2.6);
		world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		paint = autumn(COLOR.rgb);
	}
	float lift = clamp((VERTEX.y - 2.0) / 5.0, 0.0, 1.0);
	float gust = sin(TIME * 1.3 + world_pos.x * 0.07 + world_pos.z * 0.05);
	VERTEX.x += sway * gust * 0.12 * lift;
	VERTEX.z += sway * cos(TIME * 1.1 + world_pos.z * 0.06) * 0.08 * lift;
	// Downwash: a fast flutter that fades out about 25 m from the rotor.
	float w = sway * wash.z * smoothstep(26.0, 6.0, distance(world_pos.xz, wash.xy)) * lift;
	VERTEX.x += w * 0.45 * sin(TIME * 17.0 + world_pos.x * 1.7);
	VERTEX.z += w * 0.45 * cos(TIME * 15.0 + world_pos.z * 1.3);
	// The tunnel cutaway (tunnel_cut.gdshaderinc): a tree standing over the opened ground goes.
	VERTEX = tunnel_hide(VERTEX, MODEL_MATRIX[3].xyz);
}

void fragment() {
	vec3 col = srgb_to_linear(paint);
	if (sway > 0.0) {
		// The facets as they are after the lumps (the mesh's normals were the gumdrop's).
		vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		NORMAL = n.z < 0.0 ? -n : n; // towards the camera (orthographic: +z in view space)
		// Two-tone pixel dapple: darker leaves in clusters of 0.45 m cells (2-3 pixels).
		vec3 cell = floor(world_pos / 0.45);
		float pick = hash12(cell.xz + cell.y * vec2(17.3, 31.7));
		float clump = value_noise(world_pos.xz * 0.9 + world_pos.y * 0.7);
		col *= (pick * 0.6 + clump * 0.4) < 0.42 ? 0.78 : 1.0;
	}
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
	if (lights_on > 0.001) {
		EMISSION = col * lamp_light(world_pos.xz) * (1.0 - smoothstep(1.5, 8.5, lift_h)) * 2.0 * lights_on;
	}

	float d = length(VERTEX.xy - car_view.xy);
	if (VERTEX.z > car_view.z + 0.5 && d < fade_radius) {
		float fade = smoothstep(fade_radius, fade_radius * 0.5, d);
		ivec2 p = ivec2(FRAGCOORD.xy) % 4;
		float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
		if (threshold < fade * 0.92) {
			discard;
		}
	}
}
