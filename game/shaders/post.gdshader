shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled;
// Full-screen pass on the low-resolution image: dark outlines where depth
// jumps, optional colour posterize, and a saturation tweak. At dusk and at night
// (main.gd sets the uniforms per time of day) it also paints a dithered sky
// gradient, with stars at night, behind the diorama, and split-tones the image:
// shadows towards one colour, highlights towards another (the vaporwave grade).
//
// v0.9: reflections and rain. Where the pixel is a level surface (its normal, from the
// neighbours' depths, points up) that the surface map (tools/bake_water.py) calls water
// or (when wet) road or paving, it marches the mirrored view ray up the screen through
// the depth buffer (an orthographic camera: a straight line) and mixes in what it hits:
// the bridges' dark undersides by day, every lamp, neon sign, signal and car light at
// night, smeared a little along the ray (rough water, wet asphalt). Steps per pixel
// are the quality setting's (0 switches it off). Then the rain: three layers of
// one-pixel streaks falling at a slant, drifting with the view a little.
//
// Promo snow (weather.gd set_snow, --snow=COVER,FALL, Promo Mode's SNOW): a light cover on
// everything that faces up (roofs, stall tops, tree crowns, ledges, hats, lawns) from the same
// neighbour normal, in patches anchored to the world and dithered to the pixel grid; trodden
// plazas and pavements keep less, ploughed roads little, water none. It takes its light from the
// pixel it covers (warm under the string lights, blue-grey in the dark). Then flakes: three
// layers of one- and two-pixel dots drifting down and sideways, catching the light behind them.
// Both are off (one branch each) unless the flag or the promo button turns them on.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/ghost.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float outline_strength = 0.55;
// --ss: image pixels per video pixel (tiers.gd capture_scale), so outlines, rain and flakes keep
// their size in a supersampled trailer frame. 1 in a player's game.
uniform float px_scale = 1.0;
uniform float depth_threshold = 1.5;
uniform float levels = 0.0;
uniform float saturation = 1.05;
// How much of the style's saturation boost applies (time_of_day.gd): the look loop
// (2026-10-28) keeps 1.0 by day (the boost made the lime grass, the coral cycle lanes and
// the azure river louder than the car) and the style's own at dusk and night.
uniform float saturation_share = 1.0;
uniform float vignette = 0.14;
uniform vec3 grade = vec3(1.025, 1.0, 0.97); // a touch warm
// Split tone (linear multipliers): 0 leaves the image alone (daytime).
uniform float tone_amount = 0.0;
uniform vec3 tone_shadow = vec3(1.0);
uniform vec3 tone_light = vec3(1.0);
// The grading look (grades.gd, research prototype): white balance and exposure, contrast
// round a pivot, lifted blacks, vibrance, a highlight shoulder. The defaults change nothing.
uniform vec3 g_gain = vec3(1.0);
uniform float g_contrast = 1.0;
uniform float g_pivot = 0.18;
uniform vec3 g_lift = vec3(0.0);
uniform float g_vibrance = 0.0;
uniform float g_shoulder = 0.0;
// Sky behind the slab: top and bottom of the screen (linear), how much of it
// replaces the plain background (0 = the day's flat colour), and stars.
uniform float sky_amount = 0.0;
uniform vec3 sky_top = vec3(0.0);
uniform vec3 sky_bottom = vec3(0.0);
uniform float stars = 0.0;
// Reflections (main.gd sets the map; quality sets the steps) and the rain (weather.gd).
#include "res://shaders/city_maps.gdshaderinc"
uniform int reflect_steps = 10;
uniform float rain = 0.0;
uniform vec2 rain_shift = vec2(0.0);
global uniform float wetness;
global uniform float snow_cover;
uniform float snowfall = 0.0;
global uniform float daylight;
global uniform float lights_on;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// The sky: a gradient in a few dithered bands (it reads as pixel art), and
// sparse twinkling stars in the upper part.
vec3 sky(vec2 uv, vec2 frag) {
	float t = clamp(uv.y, 0.0, 1.0);
	ivec2 p = ivec2(frag) % 4;
	float dither = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0 - 0.5;
	float bands = 10.0;
	t = clamp(floor(t * bands + dither + 0.5) / bands, 0.0, 1.0);
	vec3 col = mix(sky_top, sky_bottom, t);
	if (stars > 0.0) {
		vec2 cell = floor(frag);
		float h = hash(cell);
		if (h > 0.9992 - 0.0008 * (1.0 - uv.y)) {
			float tw = 0.55 + 0.45 * sin(TIME * (1.5 + hash(cell + 3.0) * 3.0) + h * 40.0);
			col += vec3(0.9, 0.85, 1.0) * tw * stars * (1.0 - uv.y);
		}
	}
	return col;
}

vec3 view_pos(vec2 uv, mat4 inv_projection) {
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, texture(depth_tex, uv).r, 1.0);
	return v.xyz / v.w;
}

// Rain streaks of one layer: a streak `len` pixels long in some of the cells, falling.
float rain_layer(vec2 frag, vec2 cell_size, float speed, float len, float slant, float density, float seed) {
	vec2 p = frag;
	p.x += p.y * slant;
	p.y -= TIME * speed;
	vec2 cell = floor(p / cell_size);
	if (hash(cell + seed) > density) {
		return 0.0;
	}
	float x0 = (cell.x + 0.15 + 0.7 * hash(cell + seed + 1.7)) * cell_size.x;
	float y0 = (cell.y + hash(cell + seed + 3.1) * (1.0 - len / cell_size.y)) * cell_size.y;
	float on = step(abs(p.x - x0), 0.5) * step(y0, p.y) * step(p.y, y0 + len);
	return on * (0.45 + 0.55 * (p.y - y0) / len);
}

// Snowflakes of one layer: in some cells a `size`-pixel dot, falling at `speed` px/s and
// swaying sideways by up to `sway` px, each row on its own phase.
float snow_layer(vec2 frag, float cell, float speed, float sway, float density, float size, float seed) {
	vec2 p = frag;
	p.y -= TIME * speed;
	float row = floor(p.y / cell);
	p.x += sin(TIME * (0.6 + 0.5 * hash(vec2(row, seed))) + hash(vec2(seed, row)) * 6.283) * sway + TIME * speed * 0.12;
	vec2 c = floor(p / cell);
	if (hash(c + seed) > density) {
		return 0.0;
	}
	vec2 o = (c + 0.2 + 0.6 * vec2(hash(c + seed + 1.7), hash(c + seed + 3.1))) * cell;
	vec2 d = abs(p - o);
	return step(d.x, size * 0.5) * step(d.y, size * 0.5) * (0.55 + 0.45 * hash(c + seed + 5.3));
}

void fragment() {
	vec2 px = px_scale / VIEWPORT_SIZE;
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	vec3 vc = view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 vr = view_pos(SCREEN_UV + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 vl = view_pos(SCREEN_UV - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 vd = view_pos(SCREEN_UV + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	vec3 vu = view_pos(SCREEN_UV - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float c = -vc.z;
	float jump = 0.0;
	jump = max(jump, -vr.z - c);
	jump = max(jump, -vl.z - c);
	jump = max(jump, -vd.z - c);
	jump = max(jump, -vu.z - c);
	float edge = step(depth_threshold, jump);
	if (edge > 0.0 && occlusion_radius > 0.0) {
		// No outlines on the occlusion ghost's pixels (loop 1): every pixel it keeps stands
		// in front of the street showing through beside it, and outlining each one turned
		// the ghost into a dark stipple.
		vec3 wc = (INV_VIEW_MATRIX * vec4(vc, 1.0)).xyz;
		edge *= 1.0 - step(0.02, ghost_fade(vc.xy, wc.xz));
	}

	if (reflect_steps > 0 && texture(depth_tex, SCREEN_UV).r > 0.0 && jump < 0.6) {
		// A level surface? Its normal from the neighbours (view space, then world).
		vec3 n_view = normalize(cross(vr - vl, vu - vd));
		vec3 n = (INV_VIEW_MATRIX * vec4(n_view, 0.0)).xyz;
		vec3 world = (INV_VIEW_MATRIX * vec4(vc, 1.0)).xyz;
		vec4 surf = city_surface_at(world.xz);  // loop 3d-2b: per sector
		// Water mirrors always; roads and paving once they're wet (puddles most).
		float water = smoothstep(0.66, 0.8, surf.b);
		float road = smoothstep(0.3, 0.45, surf.b) * (1.0 - water);
		float paving = smoothstep(0.12, 0.22, surf.b) * (1.0 - smoothstep(0.3, 0.45, surf.b));
		float puddle = 0.0;
		if (wetness > 0.0 && road + paving > 0.0) {
			// The same puddles as ground.gdshader.
			float pm = value_noise(world.xz * 0.16 + 11.3) * 0.6 + value_noise(world.xz * 0.53 + 2.1) * 0.4;
			puddle = smoothstep(0.64, 0.69, pm) * smoothstep(0.35, 0.9, wetness);
		}
		// By day the water's mirror is half as strong as in loop 1 (the look loop: the deck's
		// shade on the water, tinted to it, halved); at night as before.
		float strength = water * mix(0.19, 0.85, lights_on)
				+ wetness * (road * 0.3 + paving * 0.18) + puddle * (road + paving) * 0.4;
		if (abs(n.y) > 0.92 && strength > 0.01) {
			// The mirrored view ray: into the screen and up. In view space it climbs the
			// screen in a straight line; march it against the depth buffer.
			vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
			vec3 r = vec3(fwd.x, -fwd.y, fwd.z);
			vec3 r_view = (VIEW_MATRIX * vec4(r, 0.0)).xyz;
			vec2 duv = (PROJECTION_MATRIX * vec4(r_view, 0.0)).xy * 0.5;
			float span = 30.0;
			float step_t = span / float(reflect_steps);
			ivec2 bp = ivec2(FRAGCOORD.xy) % 4;
			float jitter = (BAYER[bp.y * 4 + bp.x] + 0.5) / 16.0;
			// Ripples bend the water's reflection sideways.
			float wobble = water * (sin(world.z * 1.7 + TIME * 2.3) + sin(world.x * 2.3 - TIME * 1.7)) * 0.5 * px.x * 1.5;
			for (int k = 0; k < 24; k++) {
				if (k >= reflect_steps) {
					break;
				}
				float t = step_t * (float(k) + jitter);
				vec2 uv = SCREEN_UV + duv * t + vec2(wobble, 0.0);
				if (uv.y < 0.0 || uv.y > 1.0 || uv.x < 0.0 || uv.x > 1.0) {
					break;
				}
				float ray = c - r_view.z * t;
				float scene = linear_depth(uv, INV_PROJECTION_MATRIX);
				if (scene < ray - 0.2 && ray - scene < step_t * 0.6 + 2.0) {
					// A hit: smear it a little along the ray (rough water, wet asphalt).
					vec3 hit = texture(screen_tex, uv).rgb * 0.5
							+ texture(screen_tex, uv - duv * step_t * 0.35).rgb * 0.25
							+ texture(screen_tex, uv + duv * step_t * 0.35).rgb * 0.25;
					// By day the water shows what stands over it as a darker band (its shade),
					// not a pale copy of a concrete deck reading as a wake (loop 1).
					hit = mix(hit, col * 0.62, water * (1.0 - lights_on));
					// Fade towards the end of the march.
					float fade = 1.0 - smoothstep(0.6, 1.0, t / span);
					col = mix(col, hit, strength * fade);
					break;
				}
			}
		}
	}
	if (snow_cover > 0.0 && texture(depth_tex, SCREEN_UV).r > 0.0 && jump < 4.0) {
		// Promo snow: up-facing pixels whiten in world-anchored patches.
		vec3 sn_view = normalize(cross(vr - vl, vu - vd));
		vec3 sn = (INV_VIEW_MATRIX * vec4(sn_view, 0.0)).xyz;
		float up = abs(sn.y);
		vec3 sw = (INV_VIEW_MATRIX * vec4(vc, 1.0)).xyz;
		vec4 ssurf = city_surface_at(sw.xz);
		float flat_ground = smoothstep(0.96, 0.99, up);
		float s_water = smoothstep(0.66, 0.8, ssurf.b);
		float s_road = smoothstep(0.3, 0.45, ssurf.b) * (1.0 - s_water);
		float s_paving = smoothstep(0.12, 0.22, ssurf.b) * (1.0 - smoothstep(0.3, 0.45, ssurf.b));
		// How much of this surface keeps snow: lawns, roofs, crowns all; trodden paving a share
		// (white rims and lanes of slush); roads only broken patches; water nothing. Only flat
		// ground counts as a road: a pitched stall roof over the plaza keeps its white.
		float keep = 1.0 - flat_ground * (s_road * 0.82 + s_paving * 0.45 + s_water);
		// Fresh light snow lies whole on roofs and lawns and in patches where people walk:
		// a threshold on world noise (solid shapes with a one-pixel dithered rim), lowered by
		// the cover and by how well the surface keeps it.
		float patch = value_noise(sw.xz * 0.45 + 3.7) * 0.65 + value_noise(sw.xz * 1.7 + 9.1) * 0.35;
		ivec2 sbp = ivec2(FRAGCOORD.xy) % 4;
		float sd = (BAYER[sbp.y * 4 + sbp.x] + 0.5) / 16.0 - 0.5;
		float face = smoothstep(0.42, 0.75, up);
		float hold = snow_cover * keep * face;
		float cover = step(1.0 - hold * 1.7, patch + sd * 0.05);
		if (cover > 0.0) {
			float sl = dot(col, vec3(0.299, 0.587, 0.114));
			// The light on this spot, from what is drawn there: snow is brighter than the roof
			// or asphalt it hides, and keeps the colour of the light (sodium, LEDs, neon).
			// Grey, not the grass's green or the asphalt's blue under it; the street lamps' map
			// adds their own colour (sodium warm, LED cold).
			vec2 lamp = city_light_at(sw.xz) * (255.0 / 160.0) * lights_on;
			vec3 lit = mix(vec3(sl), col, 0.06) * mix(3.0, 1.9, daylight)
					+ (vec3(1.0, 0.62, 0.3) * lamp.r + vec3(0.75, 0.82, 1.0) * lamp.g) * 0.35;
			vec3 day_snow = vec3(0.80, 0.83, 0.88) * mix(0.62, 1.0, smoothstep(0.04, 0.3, sl));
			vec3 night_snow = vec3(0.085, 0.095, 0.13);
			vec3 snow_col = max(mix(night_snow, day_snow, daylight), lit);
			snow_col = min(snow_col, vec3(1.15));
			col = mix(col, snow_col, 0.92);
		}
	}
	if (sky_amount > 0.0 && texture(depth_tex, SCREEN_UV).r <= 0.0) {
		// Nothing drawn here (reversed depth: the far plane is 0): the sky.
		col = mix(col, sky(SCREEN_UV, FRAGCOORD.xy / px_scale), sky_amount);
	}
	col = mix(col, col * 0.32, edge * outline_strength);

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(luma), col, mix(1.0, saturation, saturation_share)), vec3(0.0)) * grade;
	if (tone_amount > 0.0) {
		vec3 tint = mix(tone_shadow, tone_light, smoothstep(0.015, 0.45, luma));
		col = mix(col, col * tint, tone_amount);
	}
	col *= g_gain;
	if (g_contrast != 1.0) {
		col = g_pivot * pow(col / g_pivot, vec3(g_contrast));
	}
	if (g_vibrance != 0.0) {
		float hi = max(col.r, max(col.g, col.b));
		float lo = min(col.r, min(col.g, col.b));
		float sat = (hi - lo) / max(hi, 1e-4);
		float l2 = dot(col, vec3(0.299, 0.587, 0.114));
		col = max(mix(vec3(l2), col, 1.0 + g_vibrance * (1.0 - sat)), vec3(0.0));
	}
	col += g_lift * (1.0 - min(col, vec3(1.0)));
	if (g_shoulder > 0.0) {
		// Rolls the highlights off and leaves the pivot where it was.
		col = col * (1.0 + g_shoulder * g_pivot) / (1.0 + g_shoulder * col);
	}
	float edge_dist = length((SCREEN_UV - 0.5) * vec2(1.0, 0.8));
	col *= 1.0 - vignette * smoothstep(0.3, 0.75, edge_dist);

	if (rain > 0.0) {
		// Rain: a grey veil by day, and three layers of falling streaks (far: short,
		// slow, many; near: long, fast, few), drifting with the view.
		col = mix(col, vec3(luma) * 0.92 + 0.02, 0.18 * rain * daylight);
		vec2 f = FRAGCOORD.xy / px_scale;
		float s = rain_layer(f + rain_shift * 0.35, vec2(5.0, 34.0), 220.0, 5.0, 0.18, 0.55 * rain, 1.0) * 0.45
				+ rain_layer(f + rain_shift * 0.6, vec2(7.0, 48.0), 320.0, 8.0, 0.2, 0.5 * rain, 7.0) * 0.7
				+ rain_layer(f + rain_shift, vec2(11.0, 70.0), 460.0, 13.0, 0.22, 0.4 * rain, 13.0);
		vec3 drop = mix(vec3(0.42, 0.46, 0.62), vec3(0.78, 0.82, 0.88), daylight);
		col = mix(col, drop, clamp(s, 0.0, 1.0) * 0.55);
	}

	if (snowfall > 0.0) {
		// Snowfall: a faint veil by day, and three layers of flakes (far: small, slow, many;
		// near: two-pixel, faster, few), drifting with the view; they take the light behind them.
		col = mix(col, vec3(0.62, 0.64, 0.7), 0.06 * snowfall * daylight);
		vec2 f = FRAGCOORD.xy / px_scale;
		float far = snow_layer(f + rain_shift * 0.3, 8.0, 14.0, 2.5, 0.45 * snowfall, 1.0, 2.0);
		float mid = snow_layer(f + rain_shift * 0.6, 14.0, 24.0, 4.0, 0.4 * snowfall, 2.0, 8.0);
		float near = snow_layer(f + rain_shift, 30.0, 40.0, 8.0, 0.3 * snowfall, 3.0, 14.0);
		float fl = clamp(far * 0.5 + mid * 0.75 + near, 0.0, 1.0);
		float bl = dot(col, vec3(0.299, 0.587, 0.114));
		vec3 flake = mix(vec3(0.5, 0.53, 0.62), vec3(0.95, 0.97, 1.0), daylight) + col * 0.5 + vec3(bl * 0.35);
		col = mix(col, flake, fl * 0.9);
	}

	if (levels > 0.5) {
		vec3 s = pow(col, vec3(1.0 / 2.2));
		s = floor(s * levels + 0.5) / levels;
		col = pow(s, vec3(2.2));
	}
	ALBEDO = col;
}
