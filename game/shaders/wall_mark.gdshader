shader_type spatial;
// W9 of the walls look (docs/design/walls-true-to-life.md 6.8): the words painted on walls and the
// hoardings' developer banners (wall_marks.gd draws them into one atlas; map_builder.gd `_build_marks`,
// one `Slogans` mesh a sector). By day poster.gdshader's look: the atlas crisp (nearest filtering),
// shaded like the city with the cloud shadows. But it is paint on the wall, not a lit billboard: no
// emission, so at night it darkens with the wall it is on (6.6 row 13: nothing glows) and only the
// lights that light the wall (the car's own lamp) bring it out.
// Holed and ghosted with its wall: the see-through hole round the car and the occlusion ghost
// (ghost.gdshaderinc) are building.gdshader's, with the same dither, so a word goes where the wall
// round it goes and never floats in front of the car. main.gd sets the values (`fade_radius`,
// `car_view`, the ghost's) on this material as on the building material.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"
#include "res://shaders/ghost.gdshaderinc"

uniform sampler2D poster : source_color, filter_nearest, repeat_disable;
uniform float clouds = 0.18;
// The see-through hole round the car (building.gdshader's `fade_radius`; 0: off).
uniform float fade_radius = 7.5;
// The share of the ghost's pixels that stay (building.gdshader's `ghost_keep`).
uniform float ghost_keep = 0.19;
varying vec3 world_pos;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = texture(poster, UV).rgb;
	ALBEDO = c * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	// building.gdshader's two cuts, as one test: the hole (nearer the camera than the car by a metre,
	// inside fade_radius on screen) and the ghost, on the same 4x4 Bayer threshold.
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	float d = length(VERTEX.xy - car_view.xy);
	float hole = smoothstep(fade_radius, fade_radius * 0.5 - 0.001, d) * step(d, fade_radius) * step(car_view.z + 1.0, VERTEX.z);
	float ghost = ghost_fade(VERTEX.xy, world_pos.xz) * (1.0 - ghost_keep);
	if (threshold < max(hole * 0.92, ghost)) {
		discard;
	}
}
