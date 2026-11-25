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
// The Jarmark coloured uplights (map_builder `_jarmark_uplight`): 0 none, 0.4 green, 0.9 red.
varying float uplight;
// Trees thread (2026-11-15): the leaves left on this crown (1 full, 0 bare), worked out in vertex()
// from the season and the kind; parked cars and trunks keep 1. And 1 on the crown's limbs (UV 1, 1
// in map_builder.gd _broadleaf_mesh): bark, no lumps, dapple or holes.
varying float leaves;
varying float bark;
// How bare the crown is (0 full, 1 bare); softens the dapple. No holes or twig patches: cut-out
// cells read as a crown whose texture did not load, patches as camouflage (F, 2026-11-15).
varying float holes;
// The limbs' colour and the bare crown's fine twigs, a grey-violet haze from above (sRGB).
const vec3 BARK = vec3(0.30, 0.24, 0.20);
const vec3 TWIG = vec3(0.47, 0.37, 0.30);
// The season the trees show (trees thread, step T-fix): x the turn from summer to autumn colour
// (0-1), y how far the fall of leaves has gone (0 none, 1 the last leaf of the latest kind), z the
// blossom, w the snow. A shader global, so the prebuilt sectors hold nothing seasonal: the season
// module (step S1) writes it from the game's date; until then it stands at mid-November.
global uniform vec4 tree_season;
// Per kind (map_builder.gd TreeKind is the column), from map_builder.gd TREE_LOOK: row 0 the summer
// colour, row 1 the autumn colour, row 2 (when its leaves start to fall on tree_season.y, how long
// they take, the share kept through winter, -), row 3 the blossom (for step T4).
uniform sampler2D tree_look : filter_nearest;
// Graphics tiers (tiers.gd `tree_limbs`): 0 hides the limbs (a bare tree is its haze and trunk).
uniform float limbs = 1.0;

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

// The crown's half sizes in its model space (map_builder.gd _broadleaf_mesh's stretch).
const vec3 CROWN_HALF = vec3(2.4, 2.6, 2.4);
// The limbs' foot in the crown's model space (map_builder.gd _broadleaf_mesh).
const vec3 LIMB_FOOT = vec3(0.0, 1.7, 0.0);

// Trees thread (F, 2026-11-15): each broadleaf kind's silhouette from the one round crown, indexed by
// map_builder.gd TreeKind (lime, maple, chestnut, plane, robinia, oak, birch, poplar, willow): the
// lower half kept (a flat-bottomed dome keeps little), the upper half kept (a parasol's flat top),
// the taper towards the top (an egg, a column's point), the width, the droop of the outer lower
// leaves (a willow's curtain) and how lumpy it is.
const float S_LOW[9] = float[9](0.85, 0.7, 0.3, 0.55, 0.3, 0.5, 0.9, 1.0, 1.0);
const float S_HIGH[9] = float[9](1.0, 1.0, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0);
const float S_TAPER[9] = float[9](0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.65, 0.0);
const float S_WIDE[9] = float[9](1.0, 1.05, 1.08, 1.04, 1.1, 1.08, 0.9, 0.95, 1.1);
const float S_DROOP[9] = float[9](0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 1.0);
const float S_LUMPY[9] = float[9](1.0, 1.0, 1.2, 1.5, 1.4, 1.5, 1.0, 0.6, 0.8);

// A point of the round crown (offset from CROWN_MIDDLE) moved into the kind's silhouette; the crown
// keeps its foot and top (the scan's crown base and height). The limbs' centre lines go through it
// too, so they stay inside the crown's shape.
vec3 crown_shape(vec3 d, int kind, float seed) {
	vec3 n = d / CROWN_HALF;
	float u = clamp(n.y, -1.0, 1.0);
	float low = S_LOW[kind];
	float high = S_HIGH[kind];
	// Squash the halves, then stretch back so the foot and the top stay where the scan puts them.
	float y = u < 0.0 ? u * low : u * high;
	y = (y + low) / (low + high) * 2.0 - 1.0;
	float r = S_WIDE[kind] * (1.0 - S_TAPER[kind] * pow(max(u, 0.0), 1.5));
	// A little lopsided, each its own way (no two crowns of a row the same).
	r *= 1.0 + 0.08 * sin(atan(n.z, n.x) + seed * 6.283);
	float hang = S_DROOP[kind] * length(n.xz) * smoothstep(0.5, -0.6, u);
	y = mix(y, -1.0, hang * 0.85);
	r *= 1.0 + 0.12 * hang;
	return vec3(n.x * r, y, n.z * r) * CROWN_HALF;
}

// The conifer mesh (map_builder.gd _conifer_mesh, y 1.6-7.4): a spruce stays the three-tier spire;
// a pine's crown is a flat-topped head wider than its lower tiers.
vec3 conifer_shape(vec3 v, int kind) {
	if (kind != 10) {
		return v;
	}
	float t = clamp((v.y - 1.6) / 5.8, 0.0, 1.0);
	v.xz *= 0.6 + 0.8 * t;
	v.y = 1.6 + 5.8 * (1.0 - pow(1.0 - t, 1.6)) * 0.9;
	return v;
}

// The leaves left on a tree of `kind` (0-1) at the season's fall `fall`, a tree's own `seed` moving
// it a little earlier or later (neighbours of one kind are not all at the same step).
float leaves_left(int kind, float fall, float seed) {
	vec4 f = texelFetch(tree_look, ivec2(kind, 2), 0);
	float gone = clamp((fall + (seed - 0.5) * 0.2 - f.x) / max(f.y, 0.05), 0.0, 1.0);
	return 1.0 - gone * (1.0 - f.z);
}

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
	if (hue < 12.0 || hue > 38.0) {
		return c;
	}
	// Red-orange towards rust, golden towards olive, ochre-brown between, scaled a little
	// by the crown's brightness.
	return mix(RUST, OLIVE, smoothstep(16.0, 36.0, hue)) * (0.8 + 0.25 * hi);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	lift_h = VERTEX.y;
	paint = COLOR.rgb * tint;
	uplight = INSTANCE_CUSTOM.b;
	leaves = 1.0;
	bark = 0.0;
	holes = 0.0;
	if (sway > 0.0) {
		int kind = clamp(int(INSTANCE_CUSTOM.r * 16.0 + 0.5), 0, 15);
		float seed = INSTANCE_CUSTOM.g;
		bool needle = kind >= 9;
		leaves = needle ? 1.0 : leaves_left(kind, tree_season.y, seed);
		// Three states (Fable's review): full (the whole crown), thin (the whole crown with holes
		// in world cells, so it does not shimmer) and bare (a 30-35 % haze of twigs round the limbs).
		float thin = needle ? 0.0 : 1.0 - smoothstep(0.5, 0.6, leaves);
		float bare = needle ? 0.0 : 1.0 - smoothstep(0.15, 0.25, leaves);
		if (UV.x > 0.5) {
			// A limb: its centre line (CUSTOM0.xyz) into the crown's shape, its half width
			// (CUSTOM0.w) in world metres whatever the tree's size; hidden in a full crown, half
			// way out in a thin one, out to the crown's edge on a bare one.
			bark = 1.0;
			vec3 c = CUSTOM0.xyz;
			vec3 shaped = CROWN_MIDDLE + crown_shape(c - CROWN_MIDDLE, kind, seed);
			c = LIMB_FOOT + (shaped - LIMB_FOOT) * 0.95;
			vec3 side = VERTEX - CUSTOM0.xyz;
			vec3 side_dir = normalize(side + vec3(1e-5));
			float world_len = length(mat3(MODEL_MATRIX) * side_dir);
			VERTEX = c + side_dir * CUSTOM0.w * 1.8 / max(world_len, 1e-3);
			// Out of sight in a full crown, and on the lowest tier: collapsed to the foot.
			float shown = bare * limbs;
			VERTEX = mix(LIMB_FOOT, VERTEX, shown);
			paint = BARK;
		} else if (needle) {
			VERTEX = conifer_shape(VERTEX, kind);
			paint = COLOR.rgb * texelFetch(tree_look, ivec2(kind, 0), 0).rgb;
		} else {
			// Lumps: the crown pushed out and in along its own directions, three soft lobes
			// seeded by the tree's position, so no two crowns are the same gumdrop; capped at 0.3
			// of the radius whatever the kind.
			vec3 at = MODEL_MATRIX[3].xyz;
			vec3 d = crown_shape(VERTEX - CROWN_MIDDLE, kind, seed);
			vec3 dir = normalize(d / CROWN_HALF + vec3(1e-4));
			float lump = sin(dot(dir, vec3(2.1, 1.3, -1.7)) * 2.2 + at.x * 0.71)
					+ sin(dot(dir, vec3(-1.4, 2.4, 1.9)) * 1.9 + at.z * 0.53)
					+ 0.6 * sin(dot(dir, vec3(1.8, -0.9, 2.6)) * 2.6 + (at.x + at.z) * 0.37);
			// A bare tree's twig mass sits well inside where the crown was, so the limb tips
			// stick out past it and the silhouette reads as branches.
			VERTEX = CROWN_MIDDLE + d * (1.0 + min(LUMPS * S_LUMPY[kind], 0.3) * lump / 2.6) * mix(1.0, 0.92, thin) * mix(1.0, 0.85, bare);
			vec3 summer = texelFetch(tree_look, ivec2(kind, 0), 0).rgb;
			vec3 fall_col = texelFetch(tree_look, ivec2(kind, 1), 0).rgb;
			vec3 leaf = mix(summer, fall_col, clamp(tree_season.x + (seed - 0.5) * 0.3, 0.0, 1.0));
			vec3 leaf_col = COLOR.rgb * autumn(leaf);
			// Thin: the whole crown fades evenly towards twig brown (no patches); bare keeps
			// 18 % of its leaf tint, so a bare lime and a bare chestnut differ.
			float worn = mix(thin * clamp((0.6 - leaves) / 0.4, 0.0, 1.0) * 0.45, 0.82, bare);
			paint = mix(leaf_col, TWIG * (0.9 + 0.2 * seed), worn);
			holes = bare;
		}
		world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
	if (sway > 0.0 && bark < 0.5) {
		// The facets as they are after the lumps (the mesh's normals were the gumdrop's).
		vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		NORMAL = n.z < 0.0 ? -n : n; // towards the camera (orthographic: +z in view space)
		// Two-tone pixel dapple: darker leaves in clusters of 0.45 m cells (2-3 pixels).
		vec3 cell = floor(world_pos / 0.45);
		float pick = hash12(cell.xz + cell.y * vec2(17.3, 31.7));
		float clump = value_noise(world_pos.xz * 0.9 + world_pos.y * 0.7);
		col *= (pick * 0.6 + clump * 0.4) < 0.42 ? mix(0.80, 0.90, holes) : 1.0;
		// Volume without noise: the underside darker, the top lighter.
		col *= mix(0.88, 1.06, smoothstep(2.0, 6.5, lift_h));
	}
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
	if (lights_on > 0.001) {
		EMISSION = col * lamp_light(world_pos.xz) * (1.0 - smoothstep(1.5, 8.5, lift_h)) * 2.0 * lights_on;
		if (uplight > 0.1) {
			// Lit from below (look check 3: flat neon lollipops): deeper hues, bright at the underside,
			// falling off to almost nothing at the top.
			vec3 hue = uplight > 0.65 ? vec3(0.75, 0.05, 0.12) : vec3(0.22, 0.85, 0.12);
			float under = 1.0 - smoothstep(1.5, 6.5, lift_h);
			EMISSION += hue * (0.06 + 0.6 * under * under) * 0.45 * lights_on;
		}
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
