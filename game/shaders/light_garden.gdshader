shader_type spatial;
// The ground projections of the light garden in Park Świętokrzyski (light_garden.gd; opened
// 15 October 2026): after dark, projectors on the steel pylons throw a carpet of flowers on the
// 50 m alley towards the Palace, and a ring of them round the fountain. From the photos: a purple
// wash with white dandelion clocks (a ring of dots round a yellow eye), yellow sunflowers, red and
// orange blooms and green leaves, the motifs drifting and changing. Additive like glow.gdshader,
// so it only adds light and shows only when the city's lights are on (nothing by day); it draws
// after the post-process quad for the same reason (render_priority 1 on the material).
//
// UV.x = metres along the strip, UV.y = metres across it from its middle line (the half width is
// `half_w`). The pattern is cells of `cell` metres, each with one motif picked by a hash that moves
// on every `season` seconds (the real show changes about every three minutes), and the cells
// drift slowly along the alley. Like the real one's motion sensors, it answers whoever walks on it:
// light_garden.gd hands the car's ground point in `visitor` (x, z, and w 1 while the car is close,
// 0 otherwise), and round it the motifs swap and swell, the light rises and a ring of light runs
// out from the wheels about once a second. Branch-free (tools/check_shader_budget.gd): step, mix and maths.

render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

global uniform float lights_on;

uniform float half_w = 1.6;
uniform float cell = 2.2;
uniform float season = 180.0;
uniform float drift = 0.25;
uniform float strength = 0.85;
// Metres the strip is pulled towards the camera (depth only), over the ground's layers.
uniform float lift = 0.9;
// The car on the projection: xz (in x, y), w 1 when it is near (light_garden.gd), else 0.
uniform vec4 visitor = vec4(0.0);
// How far round the car the motifs answer, metres.
uniform float reach = 6.0;

varying vec2 world_xz;

const vec3 PURPLE = vec3(0.32, 0.12, 0.75);
const vec3 WHITE = vec3(0.92, 0.92, 1.0);
const vec3 YELLOW = vec3(1.0, 0.82, 0.12);
const vec3 ORANGE = vec3(1.0, 0.36, 0.08);
const vec3 GREEN = vec3(0.45, 0.85, 0.15);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.z += lift;
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	// Pixel steps of 0.25 m, so the projection reads as the game's pixel light.
	vec2 uv = floor(vec2(UV.x - TIME * drift, UV.y) * 4.0) / 4.0;
	vec2 id = floor(uv / cell);
	vec2 f = fract(uv / cell) - 0.5;
	float era = floor(TIME / season);
	// The sensors: how near this point is to the car (1 under it, 0 past `reach`), in two steps.
	float d = length(world_xz - visitor.xy);
	float near = visitor.w * (step(d, reach) * 0.5 + step(d, reach * 0.5) * 0.5);
	// Under and round the car every cell turns to another motif (a new hash for the near cells).
	float h = hash(id + vec2(era * 7.0, era * 3.0) + near * 5.0);
	float h2 = hash(id.yx + vec2(13.0, era));
	// Near the car the motifs swell by a third.
	float r = length(f + (vec2(h, h2) - 0.5) * 0.25) / (1.0 + near * 0.33);
	float ang = atan(f.y, f.x);
	// The four motifs, each a mask 0..1.
	float eye = step(r, 0.09);
	float dots = step(0.5, sin(ang * 14.0 + h * 6.0)) * step(0.24, r) * step(r, 0.36);
	float clock = max(eye, dots);
	float petals = step(r, 0.2 + 0.12 * sin(ang * 12.0 + h * 9.0));
	float bloom = step(r, 0.16 + 0.1 * sin(ang * 5.0 + h2 * 4.0));
	float leaf = step(abs(f.y * 2.4 - sin(f.x * 3.0 + h * 5.0) * 0.4), 0.3 - abs(f.x) * 0.55);
	// Which motif this cell shows (a quarter each).
	float k0 = step(h, 0.25);
	float k1 = step(0.25, h) * step(h, 0.5);
	float k2 = step(0.5, h) * step(h, 0.75);
	float k3 = step(0.75, h);
	vec3 c = PURPLE * 0.55;
	c = mix(c, mix(WHITE, YELLOW, eye), clock * k0);
	c = mix(c, mix(YELLOW, ORANGE, step(r, 0.07)), petals * k1);
	c = mix(c, mix(ORANGE, vec3(1.0, 0.15, 0.25), step(0.5, h2)), bloom * k2);
	c = mix(c, GREEN, leaf * k3);
	// The beam's edge: the strip fades out over its last 0.3 m either side, in two steps.
	float edge = step(abs(UV.y), half_w - 0.3) * 0.6 + step(abs(UV.y), half_w) * 0.4;
	// A ring of light running out from the car, about once a second, out to `reach`.
	float wave = visitor.w * step(abs(d - fract(TIME * 0.9) * reach), 0.35) * step(d, reach);
	c = c * (1.0 + near * 0.8) + WHITE * wave * 0.45;
	ALBEDO = c * edge * strength * lights_on;
}
