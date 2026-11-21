// The time of day, shared by the city shaders. main.gd sets these globals
// (project.godot [shader_globals]); in the day they are lights_on 0 and
// daylight 1, which leaves every shader's daytime output untouched.

// How far the city's lights are on: 0 day, ~0.8 dusk, 1 night.
global uniform float lights_on;
// 1 in daylight, about 0.5 at dusk, 0 at night: cloud shadows, sky reflections.
global uniform float daylight;
// The sky the glass reflects (sRGB): pale blue by day, pink at dusk, navy at night.
global uniform vec3 sky_colour;

// Street-lamp pools baked by tools/bake_lights.py: red = sodium lamps, green = LED lamps,
// 160/255 = one lamp's full brightness. Loop 3d-2b: read per sector (city_maps.gdshaderinc).
#include "res://shaders/city_maps.gdshaderinc"

const vec3 SODIUM = vec3(1.0, 0.4, 0.08);
const vec3 LED = vec3(0.62, 0.74, 1.0);

// Lamp light falling on a point of the map (linear colour, ~1 under a lamp).
vec3 lamp_light(vec2 xz) {
	vec2 lm = city_light_at(xz) * (255.0 / 160.0);
	return lm.r * SODIUM + lm.g * LED;
}

// Rec. 709 luma of a linear colour.
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
// The look loop (2026-10-28): a lamp pool is pixel light, four hard bands with a one-pixel
// checker dither along each step, never a smooth radial gradient. The steps of the pool's
// strength (1 = one lamp's full brightness; a sodium pool reaches them about 12, 9, 6 and
// 3.5 m from the lamp) and the level each band shows (the outermost a faint skirt).
const vec4 POOL_STEPS = vec4(0.1, 0.3, 0.55, 0.8);
const vec4 POOL_LEVELS = vec4(0.07, 0.27, 0.52, 0.85);
// A sodium pool's colour on the ground: a little more amber than the lamp's own (dimmed
// under the cap, the full sodium red read pink on pale paving).
const vec3 SODIUM_POOL = vec3(1.0, 0.5, 0.15);
// The most a pool may add to a surface (linear luma of the emission, at the top band): with
// the moonlit surface under it, about 80 % of a lit window's luma on screen, pale paving
// included (the art bible's value ladder: lamps > lit windows > lit ground > the car).
const float POOL_CAP = 0.3;

// The lamps' light at a point in bands: rgb = its colour (sodium, LED or a mix, at full
// strength), a = the band's level (0 outside the pools). `frag` is FRAGCOORD.xy.
vec4 lamp_pool(vec2 xz, vec2 frag) {
	vec2 lm = city_light_at(xz) * (255.0 / 160.0);
	float s = lm.r + lm.g;
	// How much s changes across one pixel: the width of the dithered seam.
	float e = fwidth(s);
	float checker = mod(floor(frag.x) + floor(frag.y), 2.0);
	vec4 above = step(POOL_STEPS, vec4(s)) + checker * step(POOL_STEPS - e, vec4(s)) * step(vec4(s), POOL_STEPS);
	float band = min(dot(above, vec4(1.0)), 4.0);
	float level = band < 0.5 ? 0.0 : (band < 1.5 ? POOL_LEVELS.x : (band < 2.5 ? POOL_LEVELS.y : (band < 3.5 ? POOL_LEVELS.z : POOL_LEVELS.w)));
	return vec4((lm.r * SODIUM_POOL + lm.g * LED) / max(s, 1e-4), level);
}

// The Jarmark promo's pools (--promo-dress=jarmark, ground.gdshader `pool_soft`): a smooth falloff with
// no bands or dither, smaller (only a lamp's inner few metres), same colour.
vec4 lamp_pool_soft(vec2 xz) {
	vec2 lm = city_light_at(xz) * (255.0 / 160.0);
	float s = lm.r + lm.g;
	float level = smoothstep(0.25, 1.15, s);
	return vec4((lm.r * SODIUM_POOL + lm.g * LED) / max(s, 1e-4), level * level * 0.6);
}

// What a lamp pool adds to a surface of colour `surf` (linear) at the pool's band:
// lit like before (the surface's colour times the lamp's, a little light even on dark
// asphalt), capped so its top band stays under POOL_CAP. `multiply` (grass, cycle lanes,
// flowerbeds): the lamp only tints the surface's own colour, half desaturated, so sodium on
// grass reads warm olive rather than adding orange (it read chartreuse).
vec3 pool_glow(vec3 surf, vec4 pool, bool multiply) {
	if (pool.a <= 0.0) {
		return vec3(0.0);
	}
	vec3 lit = multiply ? surf * mix(vec3(dot(pool.rgb, LUMA)), pool.rgb, 0.45) * 2.4
			: (surf + 0.03) * pool.rgb * 2.2;
	float top = dot(lit, LUMA) * POOL_LEVELS.w;
	return lit * pool.a * min(1.0, POOL_CAP / max(top, 1e-4));
}
