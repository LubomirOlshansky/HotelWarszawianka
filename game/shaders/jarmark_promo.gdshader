shader_type spatial;
// The Jarmark promo dressing (jarmark_promo.gd, --promo-dress=jarmark; promo videos only, never a
// player's game). UV2.x the material code:
//   21 a softly lit surface (the striped awnings under their bulbs)
//   22 the tower's LED mast sleeve, UV2.y its height 0-1: cyan above, violet-magenta below, the
//      boundary cycling up and down, with a white chase
//   23 a cool-white glow (the glass barrels)        24 gold wire
//   26 lit paving, UV.x across the band -1..1: three hard warm bands
//   27 a warm-white counter                         0 plain
//   30 a bulb, 31 a tree bulb, 32 a pagoda bulb (COLOR.r their phase): camera-facing discs, UV the corner, UV2.y the
//      radius; never under ~1.3 px (a 5 cm bulb at a 100 m view is a third of a pixel), HDR core
// Everything glows only once the city's lights are on (the mast at a third by day).

render_mode cull_disabled;

#include "res://shaders/common.gdshaderinc"

global uniform float lights_on;
// The bulb's least radius in image pixels (1.3 x the --ss capture scale, jarmark_promo.gd).
uniform float px_floor = 1.3;

varying float mode;
varying float phase;
varying vec2 disc;

void vertex() {
	mode = UV2.x;
	phase = UV2.y;
	disc = UV;
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
	// F's drone photos (2026-11-21): cyan at the top, violet-magenta below, the boundary cycling up
	// and down the mast, with a white chase.
	float edge = 0.55 + 0.3 * sin(TIME * 0.5);
	vec3 c = mix(vec3(0.78, 0.16, 0.95), vec3(0.13, 0.85, 1.0), smoothstep(edge - 0.15, edge + 0.15, h));
	float chase = smoothstep(0.93, 1.0, sin((h * 14.0 - TIME * 1.6) * 3.14159) * 0.5 + 0.5);
	return mix(c, vec3(1.0), chase * 0.5);
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
		e = bc * mix(5.0, 2.0, d * d);  // was 9 to 3: blown, glossy halos (F 2026-11-21)
	} else if (mode > 20.5 && mode < 21.5) {
		e = col * 0.4;
	} else if (mode > 21.5 && mode < 22.5) {
		vec3 m = mast_colour(phase);
		ALBEDO = m * 0.6;
		e = m * 2.2;
		on = max(on, 0.35);
	} else if (mode > 22.5 && mode < 23.5) {
		e = col * 1.15;
	} else if (mode > 23.5 && mode < 24.5) {
		e = col * 1.8;
	} else if (mode > 25.5 && mode < 26.5) {
		float x = abs(disc.x);
		float band = x < 0.35 ? 1.0 : (x < 0.7 ? 0.62 : 0.3);
		ALBEDO = col * 0.6;
		e = vec3(1.0, 0.66, 0.4) * 0.28 * band;
	} else if (mode > 26.5 && mode < 27.5) {
		e = col * 1.1;
	}
	EMISSION = e * on;
}
