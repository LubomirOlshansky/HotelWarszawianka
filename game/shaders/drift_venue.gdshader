// Bokiem na Narodowym, PR 2 (2026-11-27, docs/design/drift-narodowy.md 0b.4 and 6; critique-drift.md
// change 14): the stadium's bowl, boards, spire and crowd (drift_venue.gd builds them). Unshaded, so the
// venue costs no light: the shading is baked into the vertex colours, and the time of day comes from the
// city's globals (night.gdshaderinc's lights_on and daylight), dimming the stands to a blue night with the
// LED boards and the phones lit.
//
// UV2.x is the part:
//   0 plain (the concrete, the roof, the seats' risers): the colour, dimmed at night;
//   1 a lamp or LED strip: the colour, brighter at night;
//   2 an LED board: the atlas's row UV2.y, UV.x across the atlas (0..1, cropped to the board's word by
//     drift_venue.gd, one texel TEXEL m so iso has two render pixels a texel), lit as a screen, an LED grid;
//   3 a tread full of people: 0.55 m cells of the crowd's colours over the seats' red and white, a few
//     phones lit at night; where a cell is under about two pixels it fades to the cells' mean colour;
//   4 printed: the atlas's row like 2, not lit (the track wall's banners).
// `crowd` (the crowd's own material): a MultiMesh of figures. INSTANCE_CUSTOM.rgb is the shirt, .a a seed;
// UV2.x 5 is the head (a skin tone), 6 the phone (only for one figure in PHONE_SHARE, only at night).
// The bob is idle; `wave_age` (s since a bank or a zone, set by drift_stadium.gd) sends a wave both ways
// round the bowl from the angle `wave_from` (rad about the floor's centre).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

#include "res://shaders/common.gdshaderinc"

global uniform float lights_on;
global uniform float daylight;

uniform sampler2D atlas : source_color, filter_nearest;
uniform float rows = 6.0;
uniform float atlas_px = 128.0;
uniform float row_px = 12.0;
uniform float crowd = 0.0;
uniform float wave_age = 99.0;
uniform float wave_from = 0.0;

const float WAVE_SPEED = 1.7;
const float WAVE_WIDTH = 0.32;
const float WAVE_LIFE = 2.4;
const float PHONE_SHARE = 0.22;
const vec3 NIGHT = vec3(0.16, 0.18, 0.3);

varying vec3 tint;
varying flat float part;
varying flat float forced;
varying vec3 local;
varying flat float phone;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	part = UV2.x;
	forced = UV2.y;
	tint = srgb_to_linear(COLOR.rgb);
	local = VERTEX;
	phone = 0.0;
	if (crowd > 0.5) {
		float seed = INSTANCE_CUSTOM.a;
		if (part > 5.5) {
			// The phone: one figure in PHONE_SHARE holds one up at night; the others fold it away.
			phone = step(seed, PHONE_SHARE) * step(0.3, lights_on);
			if (phone < 0.5) {
				VERTEX = vec3(0.0, 0.6, 0.0);
			}
		} else if (part > 4.5) {
			tint = mix(vec3(0.62, 0.42, 0.3), vec3(0.32, 0.2, 0.13), fract(seed * 7.0));
		} else {
			tint = srgb_to_linear(INSTANCE_CUSTOM.rgb);
		}
		vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		vec3 o = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		// The idle bob, and the wave: a front running both ways round the bowl from wave_from.
		float lift = 0.035 * sin(TIME * (2.0 + seed * 2.0) + seed * 40.0);
		if (wave_age < WAVE_LIFE) {
			float a = atan(w.z - NODE_POSITION_WORLD.z, w.x - NODE_POSITION_WORLD.x);
			float d = abs(mod(a - wave_from + 3.14159265, 6.2831853) - 3.14159265);
			float front = wave_age * WAVE_SPEED;
			float k = exp(-pow((d - front) / WAVE_WIDTH, 2.0)) * (1.0 - wave_age / WAVE_LIFE);
			lift += 0.5 * k;
		}
		VERTEX.y += lift;
		local = o;
	}
}

void fragment() {
	vec3 c = tint;
	float night = 1.0 - daylight;
	vec3 dim = mix(vec3(1.0), NIGHT, night);
	if (part > 5.5) {
		c = vec3(0.75, 0.88, 1.0) * (1.6 + 0.6 * sin(TIME * 3.0 + local.x));
	} else if (part < 0.5 || (part > 4.5 && part < 5.5)) {
		c *= dim;
	} else if (part < 1.5) {
		c *= 1.0 + 0.8 * lights_on;
	} else if (part < 2.5 || part > 3.5) {
		float row = max(forced, 0.0);
		vec2 px = vec2(UV.x * atlas_px, (1.0 - UV.y) * row_px);
		c = texture(atlas, vec2(UV.x, (row * row_px + px.y) / (rows * row_px))).rgb;
		if (part < 2.5) {
			// An LED board: a grid between the pixels, brighter at night.
			// The grid fades out where a texel is under about three screen pixels (it ate the letters).
			vec2 f = fract(px);
			float grid = mix(0.55, 1.0, step(0.14, f.x) * step(0.14, f.y));
			float room = clamp(1.6 - max(fwidth(px.x), fwidth(px.y)) * 3.5, 0.0, 1.0);
			c *= mix(1.0, grid, room) * (1.05 + 0.55 * lights_on);
		} else {
			c *= mix(vec3(1.0), vec3(0.55, 0.55, 0.62), night);
		}
	} else {
		// People in their seats, seen from above: a 0.55 m cell is a seat (the tint), or a person: the
		// head (hair) in the middle, the shirt round it, the seat's colour in the gaps.
		vec2 g = vec2(local.x + local.y * 0.37, local.z - local.y * 0.61) / 0.55;
		vec2 cell = floor(g);
		float r = length(fract(g) - vec2(0.5));
		float h = hash(cell);
		vec3 shirt = h < 0.22 ? vec3(0.02, 0.02, 0.025) : (h < 0.34 ? vec3(0.62, 0.62, 0.6) : (h < 0.5 ? vec3(0.45, 0.04, 0.05)
				: (h < 0.68 ? vec3(0.04, 0.06, 0.14) : (h < 0.82 ? vec3(0.18, 0.18, 0.2) : vec3(0.3, 0.2, 0.12)))));
		float h2 = hash(cell + 31.0);
		vec3 hair = h2 < 0.55 ? vec3(0.02, 0.015, 0.01) : (h2 < 0.85 ? vec3(0.1, 0.055, 0.03) : vec3(0.45, 0.33, 0.16));
		vec3 who = r < 0.19 ? hair : (r < 0.43 ? shirt : c * 0.7);
		float seat = step(0.86, hash(cell + 17.0));
		// The cells' mean (hair 0.113 of a cell, shirt 0.468, the gap 0.419; one seat in seven empty), for
		// wide and far views where a cell is under about two pixels and the hash would sparkle.
		vec3 mean = 0.86 * (0.113 * vec3(0.06, 0.04, 0.025) + 0.468 * vec3(0.237, 0.157, 0.16) + 0.293 * c) + 0.14 * c;
		float far = smoothstep(0.3, 0.6, max(fwidth(g.x), fwidth(g.y)));
		c = mix(mix(who, c, seat), mean, far) * dim;
		// At night a few phones: a cell lights for a while, then another (a faint glow when far).
		vec3 glow = vec3(0.75, 0.88, 1.0) * 1.4;
		float on = step(0.985, hash(cell + floor(TIME * 0.4 + h * 7.0))) * (1.0 - far);
		c = mix(c, glow, (on + 0.015 * far) * step(0.3, lights_on));
	}
	ALBEDO = c;
}
