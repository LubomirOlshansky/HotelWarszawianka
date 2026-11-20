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
// W5 (walls doc 6.4 and 7): every light row. The tops (texel 6's code): sag lowers the top rail and
// the fill under it by up to SAG between posts (4 t (1 - t)); leafy cuts the leaves' top by a value
// noise of the seed (at most LEAFY, cells of LEAF_CELL) and darkens the lowest LEAFY_FOOT; a hedge's
// top face sits LEAFY lower, so its sides' leafy edge stands over it. A closed row (open CLOSED or
// less: wood, hoarding, the hedges) has no holes, its bars are joints JOINT_SHADE darker. A row with
// leaves (texel 7: green_fence) has them on 1 - open of its fill's cells, in front of its bars. The
// states 4 gap (the box squashed to nothing in vertex(): no fragment, no discard) and 5 boards (a
// wood panel's gap: laid down by panel_states.gd like a fallen panel, only two boards of it kept,
// BOARDS m along the panel). panel_rule.gd `sample`, `sag_drop`, `leaf_edge` are this in GDScript.
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
// W5: panel_rule.gd's tops, closed rows and joints; a panel's length (city_barriers.gd PANEL) and
// where in it a wood gap's two boards lie.
const float SAG = 0.08;
const float LEAFY = 0.15;
const float LEAF_CELL = 0.3;
const float LEAFY_FOOT = 0.2;
const float LEAFY_SHADE = 0.75;
const float CLOSED = 0.1;
const float JOINT_SHADE = 0.72;
const float PANEL = 2.0;
const vec2 BOARDS = vec2(0.6, 1.35);
// W5: the pixel floors' cap, in widths of the pixel's narrow side on the panel (panel_rule.gd GRAZE).
const float GRAZE = 2.0;

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
// The panel's height over its foot, the line's seed, the top's code and closed (1 or 0).
varying flat vec4 h_seed;
// W5: the leaves' colour (linear) and whether the row has leaves.
varying flat vec4 leaf;
// W6: the state as flags, down (and W5's boards, laid down too), torn, stub and boards (1 or 0).
varying flat vec4 broken;

void vertex() {
	int r = int(INSTANCE_CUSTOM.x + 0.5);
	vec4 t0 = texelFetch(rows, ivec2(0, r), 0);
	vec4 t1 = texelFetch(rows, ivec2(1, r), 0);
	vec4 t2 = texelFetch(rows, ivec2(2, r), 0);
	vec4 t3 = texelFetch(rows, ivec2(3, r), 0);
	vec4 t5 = texelFetch(rows, ivec2(5, r), 0);
	vec4 t6 = texelFetch(rows, ivec2(6, r), 0);
	vec4 t7 = texelFetch(rows, ivec2(7, r), 0);
	float seed = INSTANCE_CUSTOM.w;
	float state = INSTANCE_CUSTOM.z;
	float boards = step(4.5, state);
	broken = vec4(max(step(abs(state - 1.0), 0.5), boards), step(abs(state - 2.0), 0.5), step(abs(state - 3.0), 0.5), boards);
	// The box's height: its y axis' length (a fallen panel's y lies along the ground).
	float tall = length(MODEL_MATRIX[1].xyz);
	float closed = step(t0.a, CLOSED);
	// W5: a hedge's (a closed leafy row without a leaf colour) top face LEAFY lower; not a stub's.
	float hedge_top = closed * step(1.5, t6.r) * (1.0 - t7.a) * step(0.5, NORMAL.y) * (1.0 - broken.z);
	VERTEX.y -= hedge_top * LEAFY / max(tall, 1e-3);
	// A stub: the box squashed so its top stands STUB of the panel's height over the foot.
	VERTEX.y *= mix(1.0, (STUB * (tall - SINK) + SINK) / max(tall, 1e-3), broken.z);
	// W5: a gap: the box squashed to a point, nothing drawn.
	VERTEX *= 1.0 - step(abs(state - 4.0), 0.5);
	// The alt colours by the seed, as city_barriers.gd _typed picks them.
	vec3 c = mix(t0.rgb, t2.rgb, step(seed, t2.a));
	c = mix(c, t1.rgb, step(seed, t1.a));
	float lift = NIGHT_LIFT * lights_on;
	colour = vec4(srgb_to_linear(mix(c, vec3(0.5), lift)), t0.a);
	post_col = vec4(srgb_to_linear(mix(t5.rgb, vec3(0.5), lift)), t5.a);
	foot = vec4(srgb_to_linear(mix(t3.rgb, vec3(0.5), lift)), t3.a);
	leaf = vec4(srgb_to_linear(mix(t7.rgb, vec3(0.5), lift)), t7.a);
	shape = texelFetch(rows, ivec2(4, r), 0);
	h_seed = vec4(tall - SINK, seed, t6.r, closed);
	uvm = vec2(INSTANCE_CUSTOM.y + VERTEX.x * length(MODEL_MATRIX[0].xz), VERTEX.y * tall - SINK);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float u = uvm.x;
	float v = uvm.y;
	float px = max(fwidth(u), 1e-4);
	float pxv = max(fwidth(v), 1e-4);
	// W5: the floors' pixel (posts, rails, bars, ribs, boards; spacings and cells keep px): px and
	// pxv, never over GRAZE times the narrow side of the pixel's footprint on the panel, so a panel
	// seen nearly edge-on (a pixel spanning metres across it) is not filled by pixel-wide bands.
	// A face along u or v (the top, the ends) has no area: its floors stay px and pxv.
	vec2 ex = vec2(dFdx(u), dFdx(v));
	vec2 ey = vec2(dFdy(u), dFdy(v));
	float area = abs(ex.x * ey.y - ex.y * ey.x);
	float major = max(max(length(ex), length(ey)), 1e-6);
	float narrow = GRAZE * mix(area / major, major, step(area, 1e-9));
	float fpx = min(px, narrow);
	float fpxv = min(pxv, narrow);
	float every = max(shape.x, 1e-3);
	float has_posts = step(0.001, shape.x);
	float leafy = step(1.5, h_seed.z);
	float closed = h_seed.w;
	// W5: the top line, sagging between the posts; the leaves' noisy top edge.
	float f = fract(u / every);
	float line = h_seed.x - SAG * 4.0 * f * (1.0 - f) * has_posts * step(abs(h_seed.z - 1.0), 0.5);
	float lx = u / LEAF_CELL;
	float li = floor(lx);
	float ls = smoothstep(0.0, 1.0, lx - li);
	float edge = h_seed.x - LEAFY * leafy * mix(hash12(vec2(li, h_seed.y * 31.0)), hash12(vec2(li + 1.0, h_seed.y * 31.0)), ls);
	float under = step(v, line + 0.001);
	// The foot; the posts every `every` m along the line, at least a pixel wide.
	float at_foot = step(v, foot.a);
	float post = has_posts * step(0.001, shape.y)
			* step(abs(fract(u / every + 0.5) - 0.5) * every, max(shape.y, MIN_PX * fpx) * 0.5);
	// The rails: one under the top line, a second LOW_RAIL over the foot, at least a pixel tall.
	float rail = max(RAIL, MIN_PX * fpxv);
	float top = step(0.5, shape.z) * step(line - rail, v) * under;
	float low = step(1.5, shape.z) * step(abs(v - (foot.a + LOW_RAIL + RAIL * 0.5)), rail * 0.5);
	// The bars, BAR_GAP_PX pixels apart at least, one pixel wide (a closed row's joints).
	float has_bars = step(0.001, shape.w);
	float spacing = max(shape.w, 1e-3);
	float sp = spacing * exp2(max(ceil(log2(max(BAR_GAP_PX * px / spacing, 1e-6))), 0.0));
	float bar = step(abs(fract(u / sp + 0.5) - 0.5) * sp, MIN_PX * fpx * 0.5);
	// The tint fill: a stipple fixed to the fence, and the ribs across it.
	float cell = CELL * exp2(max(ceil(log2(max(max(px, pxv) / CELL, 1e-6))), 0.0));
	vec2 grid = floor(vec2(u, v) / cell);
	float keep = step(hash12(grid + vec2(h_seed.y * 17.0, 0.0)), 1.0 - colour.a);
	float ribs = max(post_col.a, 1e-3);
	float rib = step(0.001, post_col.a) * step(abs(fract(v / ribs + 0.5) - 0.5) * ribs, MIN_PX * fpxv * 0.5);
	// W5: the leaves (a row with a leaf colour) on the stipple's cells under the leafy edge; a closed
	// row whole under its top line (a hedge under its leafy edge). Torn: the fill and leaves gone.
	float leaves = leaf.a * keep * step(v, edge + 0.001) * (1.0 - broken.y);
	float fill = max(mix(max(keep * (1.0 - leaf.a), rib), bar, has_bars), closed) * under
			* mix(1.0, step(v, edge + 0.001), closed * leafy * (1.0 - leaf.a));
	fill = max(fill * (1.0 - broken.y), leaves);
	float solid = max(max(max(at_foot, post), max(max(top, low), fill)), broken.z);

	vec3 col = mix(colour.rgb, post_col.rgb, post * (1.0 - at_foot));
	col = mix(col, leaf.rgb, leaves * (1.0 - post) * (1.0 - at_foot));
	col = mix(col, foot.rgb, at_foot);
	// W5: a closed row's joints a shade darker.
	col *= mix(1.0, JOINT_SHADE, bar * has_bars * closed * (1.0 - at_foot) * (1.0 - post));
	// Leaves (a hedge, a green fence's): a speckle of the same cells, the lowest LEAFY_FOOT darker.
	float leafed = leafy * max(closed, leaves) * (1.0 - at_foot);
	col *= mix(1.0, 0.88 + 0.22 * hash12(grid + vec2(5.3, 1.7)), leafed);
	col *= mix(1.0, LEAFY_SHADE, leafed * step(v, LEAFY_FOOT));
	// The rain: a darker foot and a wet top.
	col *= 1.0 - wetness * (0.3 * step(v, foot.a + 0.15) + 0.15 * top);
	// No holes: what would be a gap takes the ground's tone by the row's openness.
	col = mix(col, mix(col, ground_tone, colour.a), (1.0 - solid) * (1.0 - holes));
	// W6: fallen a shade darker; a stub brown.
	col *= mix(1.0, DOWN_SHADE, broken.x);
	col = mix(col, srgb_to_linear(STUB_COLOUR), broken.z);
	// W5: a wood gap's two boards, each the row's joint spacing wide (a pixel at least), the rest gone.
	float pu = fract(u / PANEL) * PANEL;
	float bw = max(shape.w, MIN_PX * fpx) * 0.5;
	float kept = max(step(abs(pu - BOARDS.x), bw), step(abs(pu - BOARDS.y), bw));

	// The see-through hole round the car (foliage.gdshader's).
	float d = length(VERTEX.xy - car_view.xy);
	float fade = smoothstep(fade_radius, fade_radius * 0.5 - 0.001, d) * step(car_view.z + 0.5, VERTEX.z);
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	float gone = max(max(step(threshold, fade * 0.92), (1.0 - solid) * max(step(0.5, holes), broken.y)), (1.0 - kept) * broken.w);
	if (gone > 0.5) {
		discard;
	}
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 1.0;
}
