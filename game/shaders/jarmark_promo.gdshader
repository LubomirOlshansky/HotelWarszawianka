shader_type spatial;
// The Jarmark promo dressing (jarmark_promo.gd, --promo-dress=jarmark; promo videos only, never a
// player's game). UV2.x the material code:
//   21 a softly lit surface (the striped awnings under their bulbs)
//   22 the tower's LED mast sleeve, UV2.y its height 0-1: cyan above, violet-magenta below, the
//      boundary cycling up and down, with a white chase
//   23 a cool-white glow (the glass barrels)        24 gold wire
//   26 lit paving, UV.x across the band -1..1, UV.y along it: a soft warm pool
//   27 a warm-white counter                         0 plain
//   3 the kit's plain surfaces (jarmark_kit.gd M_STONE), 10 its lit ones (M_LAMP, 10.5 blue at night),
//      at `lamp_gain` (the kit's rides, the kurant, the tower's mast, the dimmed LED figures)
//   30 a bulb, 31 a tree bulb, 32 a pagoda bulb (COLOR.r their phase): camera-facing discs, UV the corner, UV2.y the
//      radius; never under ~1.3 px (a 5 cm bulb at a 100 m view is a third of a pixel), HDR core
// Everything glows only once the city's lights are on (the mast at a third by day).

render_mode cull_disabled;

#include "res://shaders/common.gdshaderinc"

global uniform float lights_on;
// The bulb's least radius in image pixels (1.3 x the --ss capture scale, jarmark_promo.gd).
uniform float px_floor = 1.3;
// F's look check 1 (2026-11-21): the aisles read nearly white; every bulb about 40 % down, the kit's lit
// surfaces under the city's 2.4 (grade D: soft highlights, matte).
uniform float bulb_gain = 1.15;  // F 2026-11-22 photos: the strings are the brightest thing  // was 0.6: too dark (F 2026-11-22)
uniform float lamp_gain = 1.1;
// --promo-mast=stripes (F's video 2026-11-22, the ride against the Palace): red and blue bands with white chasers.
uniform float mast_stripes = 0.0;

varying float mode;
varying float phase;
varying vec2 disc;
// 1 on a wide view (110 m tall or more), down to 0 under 60 m: close-ups glow less (F 2026-11-21).
varying float wide;

void vertex() {
	mode = UV2.x;
	phase = UV2.y;
	disc = UV;
	wide = smoothstep(60.0, 110.0, 2.0 / PROJECTION_MATRIX[1][1]);
	if (PROJECTION_MATRIX[3][3] < 0.5) {
		wide = 0.6;
	}
	if (mode > 29.5) {
		// Ortho: the view's height in metres is 2 / P[1][1]; a pixel is that over the viewport's height.
		float px = 2.0 / PROJECTION_MATRIX[1][1] / VIEWPORT_SIZE.y;
		if (PROJECTION_MATRIX[3][3] < 0.5) {
			// A perspective camera: the pixel at this bulb's depth.
			float depth = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
			px = 2.0 * depth / PROJECTION_MATRIX[1][1] / VIEWPORT_SIZE.y;
		}
		float r = max(UV2.y, px_floor * px);
		vec3 right = INV_VIEW_MATRIX[0].xyz;
		vec3 up = INV_VIEW_MATRIX[1].xyz;
		VERTEX += (right * UV.x + up * UV.y) * r;
		NORMAL = INV_VIEW_MATRIX[2].xyz;
	}
}

vec3 mast_colour(float h) {
	// F's look check 1 (2026-11-21, his photo of the ride): a cobalt column (#2a46ff), never cyan,
	// with white and pink chasers running up it.
	vec3 c = vec3(0.023, 0.06, 1.0);
	float run = h * 14.0 - TIME * 1.6;
	float chase = smoothstep(0.9, 1.0, sin(run * 3.14159) * 0.5 + 0.5);
	vec3 tip = mod(floor(run), 2.0) < 0.5 ? vec3(1.0) : vec3(1.0, 0.35, 0.62);
	if (mast_stripes > 0.5) {
		// Nine bands up the mast, red and blue in turn (F's video: red at the top), white dots chasing up.
		c = mod(floor((1.0 - h) * 9.0), 2.0) < 0.5 ? vec3(1.0, 0.06, 0.05) : vec3(0.05, 0.12, 1.0);
		tip = vec3(1.0);
	}
	return mix(c, tip, chase * 0.75);
}

vec3 tree_colour(float p) {
	// blue-white to violet and back (F's photos: blue-white at the opening, violet later), 10 s a
	// way, rippling down the tree by the bulb's phase
	float f = smoothstep(0.2, 0.8, 0.5 + 0.5 * sin((TIME / 10.0 - p) * 3.14159));
	return mix(vec3(0.72, 0.82, 1.0), vec3(0.45, 0.25, 1.0), f);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	ALBEDO = col;
	ROUGHNESS = 0.8;
	SPECULAR = 0.2;
	float on = lights_on;
	vec3 e = vec3(0.0);
	if (mode > 29.5) {
		float d = length(disc);
		if (d > 1.0) {
			discard;
		}
		vec3 bc = col;
		if (mode > 31.5) {
			// The pagoda's edges: green and red, swapping every 3 s, rippling up the tiers.
			bc = mix(vec3(0.22, 1.0, 0.48), vec3(1.0, 0.12, 0.12), step(0.5, fract(TIME / 6.0 - COLOR.r)));
		} else if (mode > 30.5) {
			bc = tree_colour(COLOR.r);
		}
		ALBEDO = bc * 0.5;
		// Close up a tight bright core, the rim dark: a small distinct dot with a small halo.
		e = bc * mix(5.0, mix(0.6, 2.0, wide), smoothstep(0.0, 1.0, d * d)) * bulb_gain * mix(0.72, 1.0, wide);  // was 9 to 3: blown, glossy halos (F 2026-11-21)
	} else if (mode > 20.5 && mode < 21.5) {
		e = col * 0.4;
	} else if (mode > 21.5 && mode < 22.5) {
		vec3 m = mast_colour(phase);
		ALBEDO = m * 0.6;
		e = m * 2.2;
		on = max(on, 0.35);
	} else if (mode > 22.5 && mode < 23.5) {
		e = col * 0.85;  // F 2026-11-22: lit like the reels; was 0.4, before that 1.15: the metro tubes washed white over the tree (look check 1)
	} else if (mode > 23.5 && mode < 24.5) {
		e = col * 1.8;
	} else if (mode > 25.5 && mode < 26.5) {
		// A soft pool (look check 1: no hard bands): bright under the crown, fading across the aisle
		// and towards both ends (UV.y along it).
		float band = (1.0 - 0.85 * smoothstep(0.1, 1.0, abs(disc.x))) * (1.0 - smoothstep(0.35, 1.0, abs(disc.y)));
		ALBEDO = col * 0.6;
		e = vec3(1.0, 0.7, 0.45) * 0.6 * band;
	} else if (mode > 26.5 && mode < 27.5) {
		// A warm lit interior, not a light box (F 2026-11-21): under the glow threshold, darker up top.
		ALBEDO = col * 0.35;
		e = col * 0.8 * mix(0.85, 1.0, wide);  // was 0.42: too dark (F 2026-11-22)
	} else if (mode > 9.5 && mode < 11.0) {
		e = (fract(mode) > 0.25 ? vec3(0.17, 0.34, 1.0) : col) * lamp_gain * mix(0.8, 1.0, wide);
	}
	EMISSION = e * on;
}
