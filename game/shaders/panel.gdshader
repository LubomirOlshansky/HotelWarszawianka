shader_type spatial;
// W4 of the walls look (docs/design/walls-true-to-life.md 3 and 6.4): the light fences and low
// hedges as instanced 2 m panels (map_builder.gd _build_panels, one MultiMesh a sector). Each
// instance is one piece of one panel: the unit box of map_builder.gd panel_box stretched along
// the line, PanelRule.SINK under its foot to its height over it; INSTANCE_CUSTOM is (the row in
// `rows`, the metres along the line at the piece's start, the state, the line's colour seed).
// The row's numbers come from the `rows` texture (scripts/panel_rule.gd rows_image, from the
// palette's looks), read in vertex(). In the fragment, with u the metres along the line, v the
// metres up and px the metres one image pixel covers, by the pixel rule (panel_rule.gd, held by
// tools/check_panel_rule.gd): posts and rails solid and never under a pixel; bars at the row's
// spacing doubled until they stand BAR_GAP_PX pixels apart, one pixel wide, fixed to the fence;
// a tint fill (bars 0) a stipple of cells the pixel size rounded up to a power of two times CELL,
// a cell kept when its hash is under 1 - open. What is not solid is a hole (`holes`, tiers.gd
// panel_holes), or, without holes, the row's colour blended toward the ground by `open`.
// Lit, diffuse only, no shadow cast. The see-through hole round the car as the trees have it
// (map_builder.gd fade_materials). The time of day and the rain are the shared globals.
// Everything is step, mix and max: one `if` holds the discard (Adreno 6xx's budget, gpu_quirks.gd,
// tools/check_shader_budget.gd).
// W6 (walls doc 7): INSTANCE_CUSTOM.z is the panel's state, written by scripts/panel_states.gd when
// a panel breaks: 0 whole; 1 down (the transform lays the box on the ground, here it is a shade
// darker; its height is the y axis' length, as it no longer points up); 2 torn (the fill gone,
// posts and rails standing, a hole whatever `holes` says); 3 stub (the box squashed to STUB of its
// height in vertex(), a closed top, in STUB_COLOUR).
render_mode cull_disabled, specular_disabled;

#include "res://shaders/common.gdshaderinc"

global uniform float lights_on;
global uniform float daylight;
global uniform float wetness;

uniform sampler2D rows : filter_nearest, repeat_disable;
// 1: the gaps are holes; 0: the row's colour blends toward the ground by `open` (tiers.gd).
uniform float holes = 1.0;
uniform vec3 ground_tone : source_color = vec3(0.47, 0.47, 0.45);
uniform float clouds = 0.18;
uniform vec3 car_view = vec3(0.0, 0.0, -100000.0);
uniform float fade_radius = 6.0;

// panel_rule.gd's numbers (check_panel_rule.gd holds the two to each other).
const float BAR_GAP_PX = 2.5;
const float MIN_PX = 1.0;
const float CELL = 0.08;
const float RAIL = 0.06;
const float LOW_RAIL = 0.35;
const float SINK = 0.3;
// At night a row's colours are lifted this far toward grey, so black bars do not vanish on the
// dark ground (walls doc 6.4).
const float NIGHT_LIFT = 0.15;
// W6: a fallen panel's shade, and a hedge's stub: its share of the height and its colour (sRGB).
const float DOWN_SHADE = 0.7;
const float STUB = 0.25;
const vec3 STUB_COLOUR = vec3(0.36, 0.27, 0.17);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

varying vec3 world_pos;
// Metres along the line, metres up from the foot.
varying vec2 uvm;
// The row: its colour (the line's alt picked by the seed, linear) and open; the posts' colour and
// the ribs' spacing; the foot's colour and height; post every, post width, rails, bar spacing.
varying flat vec4 colour;
varying flat vec4 post_col;
varying flat vec4 foot;
varying flat vec4 shape;
// The panel's height over its foot, and the line's seed.
varying flat vec2 h_seed;
// W6: the state as flags, down, torn and stub (1 or 0).
varying flat vec3 broken;

void vertex() {
	int r = int(INSTANCE_CUSTOM.x + 0.5);
	vec4 t0 = texelFetch(rows, ivec2(0, r), 0);
	vec4 t1 = texelFetch(rows, ivec2(1, r), 0);
	vec4 t2 = texelFetch(rows, ivec2(2, r), 0);
	vec4 t3 = texelFetch(rows, ivec2(3, r), 0);
	vec4 t5 = texelFetch(rows, ivec2(5, r), 0);
	float seed = INSTANCE_CUSTOM.w;
	float state = INSTANCE_CUSTOM.z;
	broken = vec3(step(abs(state - 1.0), 0.5), step(abs(state - 2.0), 0.5), step(2.5, state));
	// The box's height: its y axis' length (a fallen panel's y lies along the ground).
	float tall = length(MODEL_MATRIX[1].xyz);
	// A stub: the box squashed so its top stands STUB of the panel's height over the foot.
	VERTEX.y *= mix(1.0, (STUB * (tall - SINK) + SINK) / max(tall, 1e-3), broken.z);
	// The alt colours by the seed, as city_barriers.gd _typed picks them.
	vec3 c = mix(t0.rgb, t2.rgb, step(seed, t2.a));
	c = mix(c, t1.rgb, step(seed, t1.a));
	float lift = NIGHT_LIFT * lights_on;
	colour = vec4(srgb_to_linear(mix(c, vec3(0.5), lift)), t0.a);
	post_col = vec4(srgb_to_linear(mix(t5.rgb, vec3(0.5), lift)), t5.a);
	foot = vec4(srgb_to_linear(mix(t3.rgb, vec3(0.5), lift)), t3.a);
	shape = texelFetch(rows, ivec2(4, r), 0);
	h_seed = vec2(tall - SINK, seed);
	uvm = vec2(INSTANCE_CUSTOM.y + VERTEX.x * length(MODEL_MATRIX[0].xz), VERTEX.y * tall - SINK);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float u = uvm.x;
	float v = uvm.y;
	float px = max(fwidth(u), 1e-4);
	float pxv = max(fwidth(v), 1e-4);
	float every = max(shape.x, 1e-3);
	// The foot; the posts every `every` m along the line, at least a pixel wide.
	float at_foot = step(v, foot.a);
	float post = step(0.001, shape.x) * step(0.001, shape.y)
			* step(abs(fract(u / every + 0.5) - 0.5) * every, max(shape.y, MIN_PX * px) * 0.5);
	// The rails: one under the top, a second LOW_RAIL over the foot, at least a pixel tall.
	float rail = max(RAIL, MIN_PX * pxv);
	float top = step(0.5, shape.z) * step(h_seed.x - rail, v);
	float low = step(1.5, shape.z) * step(abs(v - (foot.a + LOW_RAIL + RAIL * 0.5)), rail * 0.5);
	// The bars, BAR_GAP_PX pixels apart at least, one pixel wide.
	float spacing = max(shape.w, 1e-3);
	float sp = spacing * exp2(max(ceil(log2(max(BAR_GAP_PX * px / spacing, 1e-6))), 0.0));
	float bar = step(abs(fract(u / sp + 0.5) - 0.5) * sp, MIN_PX * px * 0.5);
	// The tint fill: a stipple fixed to the fence, and the ribs across it.
	float cell = CELL * exp2(max(ceil(log2(max(max(px, pxv) / CELL, 1e-6))), 0.0));
	vec2 grid = floor(vec2(u, v) / cell);
	float keep = step(hash12(grid + vec2(h_seed.y * 17.0, 0.0)), 1.0 - colour.a);
	float ribs = max(post_col.a, 1e-3);
	float rib = step(0.001, post_col.a) * step(abs(fract(v / ribs + 0.5) - 0.5) * ribs, MIN_PX * pxv * 0.5);
	float fill = mix(max(keep, rib), bar, step(0.001, shape.w)) * (1.0 - broken.y);
	float solid = max(max(at_foot, post), max(max(top, low), fill));

	vec3 col = mix(colour.rgb, post_col.rgb, post * (1.0 - at_foot));
	col = mix(col, foot.rgb, at_foot);
	// A closed row (a hedge): its leaves a speckle of the same cells.
	col *= mix(1.0, 0.88 + 0.22 * hash12(grid + vec2(5.3, 1.7)), step(colour.a, 0.001) * (1.0 - at_foot));
	// The rain: a darker foot and a wet top.
	col *= 1.0 - wetness * (0.3 * step(v, foot.a + 0.15) + 0.15 * top);
	// No holes: what would be a gap takes the ground's tone by the row's openness.
	col = mix(col, mix(col, ground_tone, colour.a), (1.0 - solid) * (1.0 - holes));
	// W6: fallen a shade darker; a stub brown.
	col *= mix(1.0, DOWN_SHADE, broken.x);
	col = mix(col, srgb_to_linear(STUB_COLOUR), broken.z);

	// The see-through hole round the car (foliage.gdshader's).
	float d = length(VERTEX.xy - car_view.xy);
	float fade = smoothstep(fade_radius, fade_radius * 0.5 - 0.001, d) * step(car_view.z + 0.5, VERTEX.z);
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	float gone = max(step(threshold, fade * 0.92), (1.0 - solid) * max(step(0.5, holes), broken.y));
	if (gone > 0.5) {
		discard;
	}
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 1.0;
}
