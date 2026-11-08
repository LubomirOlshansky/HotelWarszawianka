shader_type spatial;
// Ground, parks, paths, roads, markings and rails. UV.x carries each layer's
// depth bias: the vertex is pulled that many metres towards the camera in
// depth only (with an orthographic camera it doesn't move on screen), so a
// layer always draws over the one beneath it even where both follow the terrain.
// UV.y is the layer id (map_builder.gd L_*), UV2 is metres along/across the
// street so paving runs with it. A baked occlusion map darkens the ground next
// to walls, under parked cars and beneath trees. At night the baked street-lamp
// pools (night.gdshaderinc) light it up, and the river glints.
//
// v0.9: the surface map (tools/bake_water.py: shore distance, flow, what reflects,
// bridge decks) gives the river and ponds depth colour from the shore inwards, a
// current drifting north along the river, shore foam and sun sparkles; at night the
// lamps' light becomes broken columns of reflection on the water instead of pools,
// and nothing under a bridge deck gets the deck lamps' pools. In the rain (`wetness`,
// weather.gd) asphalt and paving go darker with a sheen of the sky, puddles (a noise
// mask, on roads and paving only, never kerbs) lie darker still with rings where the
// drops land, and the lamps reflect in long streaks. post.gdshader adds the mirror
// reflections of what stands on screen above the water and the wet streets.
//
// Loop 1: where the occlusion ghost (ghost.gdshaderinc) shows a building's footprint
// through its dither, the buildings' baked shade is lifted (ao_map red; the parked cars'
// and trees' shade in green stays) and, inside the footprint, which its own building
// always shades, the sunlight it would get is given back (ghost_sun), so the street
// round the car reads as bright as the street outside the ghost.
//
// Loop 3b-2: layers 16 (sand), 17 (a natural bank's wet bands, a sandbar's rim), 18 (the
// foam line on a natural waterline) and 19 (the tram bed's slabs), map_builder.gd L_SAND,
// L_WET, L_FOAM, L_TRAMBED.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"
#include "res://shaders/ghost.gdshaderinc"

uniform float clouds = 0.18;
uniform bool debug_ao = false;
uniform float ao_strength = 1.0;
// The sun's light (linear colour x energy x how much of it to give back) and the way
// to it (world space), for ghosted footprints (main.gd).
uniform vec3 ghost_sun = vec3(0.0);
uniform vec3 ghost_sun_dir = vec3(0.0, 1.0, 0.0);
// F's ask (2026-11-07): the car's ground height (main.gd _update_ghost; -1e4: off). A bridge or
// viaduct deck's own surface more than DECK_GHOST_OVER m over it is cut by the occlusion ghost
// like a building, so the car and the traffic under the Trasa show through it.
uniform float ghost_car_y = -10000.0;
global uniform float wetness;
global uniform float rain;
varying vec3 world_pos;
varying vec2 street;
varying float layer;

// The look loop (2026-10-28), calmer day colours (the overcast rain-day look as the guide):
// grass less yellow (a multiplier on its linear colour) and with less chroma (the share
// kept), cycle lanes in brick red (sRGB), the river by day a grey-green-blue lowland river
// (sRGB, the colour its depth shading starts from; at night it keeps the old one).
const vec3 GRASS_TINT = vec3(0.86, 1.0, 1.2);
const float GRASS_CHROMA = 0.88;
const vec3 BRICK = vec3(0.6, 0.31, 0.28);
const vec3 DAY_WATER = vec3(0.41, 0.6, 0.6);
// The deck ghost: a deck's surface this far over the car's ground or more is cut (a car on the
// deck itself, or on a ramp beside it, keeps its road), keeping building.gdshader's ghost_keep.
const float DECK_GHOST_OVER = 2.5;
const float DECK_GHOST_KEEP = 0.19;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	street = UV2;
	layer = UV.y;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.z += max(UV.x, 0.0);
	POSITION = PROJECTION_MATRIX * view;
}

// Lamp light seen in wet ground or water: the light map sampled further from the
// viewer (a lamp head about 6-12 m up reflects that far towards the camera), peaked
// so a lamp gives a narrow column, broken into short dashes across it.
vec3 lamp_reflection(vec2 wp, vec2 away, float dashes, float speed) {
	vec3 col = vec3(0.0);
	for (int k = 0; k < 4; k++) {
		vec3 l = lamp_light(wp + away * (9.0 + 4.0 * float(k)));
		// Peaked on brightness (not per channel: that would turn sodium red).
		float b = clamp(dot(l, vec3(0.45, 0.45, 0.1)), 0.0, 1.5);
		float b2 = b * b;
		col = max(col, l * b2 * b2);
	}
	vec2 side = vec2(-away.y, away.x);
	float dash = smoothstep(0.42, 0.72, value_noise(vec2(dot(wp, side) * 0.5, dot(wp, away) * dashes + TIME * speed)));
	return col * (0.25 + 1.5 * dash);
}

// 1 on the joint lines of a square grid of the given size (metres), else 0.
float joints(vec2 p, float size, float width) {
	vec2 d = abs(fract(p / size + 0.5) - 0.5) * size;
	return 1.0 - step(width, min(d.x, d.y));
}

// R2 of docs/design/start-area-real.md (2026-11-01): Plac Centralny, the square laid in 2024-25
// south and west of the Museum of Modern Art, paves the lost pre-war quarter into the ground:
// the tenements' outlines in red and grey slabs, their courtyards in reused granite setts, and
// its walks (the mapped footways, which follow the 1939 streets) in granite setts. Drawn inside
// the square, in Marszałkowska's frame (first_scene.gd FRAME_O / FRAME_S / FRAME_T: s metres
// north along the street, t metres east of it). The plots follow the old grid's direction and
// rhythm, not a surveyed plan (the orthophoto check on the Mac sets them exactly).
const vec2 CENTRALNY_O = vec2(-937.0, 210.1);
const vec2 CENTRALNY_S = vec2(-0.34917, -0.93706);
const vec2 CENTRALNY_T = vec2(0.93706, -0.34917);
const vec4 CENTRALNY_BOX = vec4(-45.0, 92.0, -245.0, -23.0);   // s0, s1, t0, t1
const float PLOT_WIDE = 19.0;    // a tenement's frontage (along s)
const float PLOT_DEEP = 24.0;    // a plot's depth (along t): the house and its courtyard
const float HOUSE_DEEP = 15.0;   // the house's own depth from the plot's front

// Plac Centralny's stones at the point wp on a plaza (walk = false) or a footway (walk = true):
// the colour (sRGB), or alpha 0 outside the square.
vec4 centralny(vec2 wp, bool walk) {
	vec2 r = wp - CENTRALNY_O;
	float s = dot(r, CENTRALNY_S);
	float t = dot(r, CENTRALNY_T);
	if (s < CENTRALNY_BOX.x || s > CENTRALNY_BOX.y || t < CENTRALNY_BOX.z || t > CENTRALNY_BOX.w) {
		return vec4(0.0);
	}
	vec2 p = vec2(s, t);
	if (walk) {
		// The walks: granite setts in rows.
		vec2 cell = floor(p / vec2(0.2, 0.15));
		float j = joints(p, 0.18, 0.02);
		return vec4(vec3(0.62, 0.6, 0.57) * (0.92 + 0.14 * hash12(cell)) * (1.0 - 0.15 * j), 1.0);
	}
	float ks = fract(s / PLOT_WIDE) * PLOT_WIDE;
	float kt = fract(t / PLOT_DEEP) * PLOT_DEEP;
	float edge = min(min(ks, PLOT_WIDE - ks), min(kt, PLOT_DEEP - kt));
	bool house = kt < HOUSE_DEEP;
	if (edge < 0.6 || (abs(kt - HOUSE_DEEP) < 0.3)) {
		// The outline: red slabs, every other plot's grey.
		bool red = mod(floor(s / PLOT_WIDE) + floor(t / PLOT_DEEP), 2.0) < 1.0;
		vec3 c = red ? vec3(0.66, 0.38, 0.32) : vec3(0.52, 0.52, 0.51);
		return vec4(c * (0.95 + 0.08 * hash12(floor(wp * 2.0))), 1.0);
	}
	if (house) {
		// Where a house stood: large pale grey slabs.
		float j = joints(p, 1.2, 0.04);
		return vec4(vec3(0.78, 0.77, 0.74) * (0.96 + 0.06 * hash12(floor(p / 1.2))) * (1.0 - 0.1 * j), 1.0);
	}
	// Its courtyard: reused setts, warmer.
	float j = joints(p, 0.24, 0.03);
	return vec4(vec3(0.7, 0.65, 0.58) * (0.92 + 0.12 * hash12(floor(p / 0.24))) * (1.0 - 0.15 * j), 1.0);
}

// First-scene item 4 (2026-11-02): around the start (Marszałkowska from Rondo Dmowskiego to
// the tram stop north of the museum: both pavements, the paving round the museum, Pasaż Wiecha
// behind the stores; the frame above) the wide pavements, drawn as plazas, `paving` surfaces or
// bare ground, are Warsaw's grey concrete and granite, not the warm beige and sand the rest of
// the map keeps (the city-wide choice is parked in QUESTIONS.md), a touch cooler than R3's
// footways so they still read grey in the warm day light. Plac Centralny keeps its own stones.
// START_BOX is s0, s1, t0, t1; the grey fades out over START_FADE metres at its edge.
const vec4 START_BOX = vec4(-265.0, 365.0, -80.0, 95.0);
const float START_FADE = 12.0;
const vec3 START_PLAZA = vec3(0.8, 0.8, 0.785);
const vec3 START_PAVING = vec3(0.835, 0.835, 0.82);

// The start's frame at wp: x = s, y = t, z = how much of its grey applies (0 outside the box,
// 1 inside its faded edge).
vec3 start_frame(vec2 wp) {
	vec2 r = wp - CENTRALNY_O;
	float s = dot(r, CENTRALNY_S);
	float t = dot(r, CENTRALNY_T);
	float k = min(min(s - START_BOX.x, START_BOX.y - s), min(t - START_BOX.z, START_BOX.w - t));
	return vec3(s, t, clamp(k / START_FADE, 0.0, 1.0));
}

// K6 (2026-11-01): the carriageway of Krakowskie Przedmieście (and the top of Nowy Świat) is
// granite setts, not asphalt. KP_LINE is the street's centreline from the map (a 15-point
// simplification of the mapped ways, from the Castle Square end to Nowy Świat); the setts show
// where an asphalt fragment lies within KP_HALF of it. The box test keeps the cost off every
// other road.
const vec4 KP_BOX = vec4(-740.0, -440.0, -1350.0, -450.0);   // x0, x1, z0, z1
const float KP_HALF = 7.0;
const vec2 KP_LINE[15] = vec2[15](
	vec2(-717.0, -1333.0), vec2(-696.0, -1279.0), vec2(-680.0, -1206.0), vec2(-666.0, -1095.0),
	vec2(-650.0, -1041.0), vec2(-621.0, -973.0), vec2(-600.0, -922.0), vec2(-577.0, -867.0),
	vec2(-555.0, -812.0), vec2(-530.0, -752.0), vec2(-500.0, -673.0), vec2(-471.0, -600.0),
	vec2(-446.0, -534.0), vec2(-436.0, -493.0), vec2(-434.0, -465.0));

// 1 where wp lies on Krakowskie Przedmieście's carriageway, else 0.
float kp_setts_at(vec2 wp) {
	if (wp.x < KP_BOX.x || wp.x > KP_BOX.y || wp.y < KP_BOX.z || wp.y > KP_BOX.w) {
		return 0.0;
	}
	float best = 1e4;
	for (int i = 0; i < 14; i++) {
		vec2 a = KP_LINE[i];
		vec2 ab = KP_LINE[i + 1] - a;
		float t = clamp(dot(wp - a, ab) / dot(ab, ab), 0.0, 1.0);
		best = min(best, length(wp - a - ab * t));
	}
	return 1.0 - smoothstep(KP_HALF - 0.4, KP_HALF, best);
}

// Plac Piłsudskiego (photos, 2026-11-02; docs/landmarks/photo-reports/pilsudskiego.md): the paved
// field is grey granite slabs in ~6 m squares, a chequer of lighter and darker panels outlined by
// darker grey bands (the drone photo). The map has it as bare ground crossed by footpaths; inside
// PLAC_BOX those (and any plaza) take the pattern. Box test first, so no other place pays for it.
const vec4 PLAC_BOX = vec4(-840.0, -718.0, -868.0, -735.0);   // x0, x1, z0, z1
// The chequer is real but subtle on the ground; from the 30° camera a strong step read as a chess
// board (playtest, docs/GAMEPLAY_PLAN.md 3.4). So the panels differ by half as much, the thin dark
// bands carry the pattern, and the panel step fades out in wide views (bands only).
const vec3 PLAC_LIGHT = vec3(0.69, 0.69, 0.675);    // #b0b0ac
const vec3 PLAC_DARK = vec3(0.639, 0.639, 0.624);   // #a3a39f
const vec3 PLAC_BAND = vec3(0.533, 0.537, 0.525);   // #888986
const float PLAC_BAND_EDGE = 0.475;                 // 0.15 m each side of a joint: 0.3 m bands

// 1 inside the square's paved field, fading over its last metre.
float plac_at(vec2 wp) {
	vec2 lo = vec2(PLAC_BOX.x, PLAC_BOX.z);
	vec2 hi = vec2(PLAC_BOX.y, PLAC_BOX.w);
	vec2 d = min(wp - lo, hi - wp);
	return clamp(min(d.x, d.y), 0.0, 1.0);
}

void fragment() {
	vec3 base = srgb_to_linear(COLOR.rgb);
	vec2 wp = world_pos.xz;
	float n1 = value_noise(wp * 0.9);
	float n2 = value_noise(wp * 3.1);
	float shade = 0.95 + 0.1 * (n1 * 0.6 + n2 * 0.4);
	float ripple = 0.0;
	int id = int(round(layer));
	vec4 surf = city_surface_at(wp);  // loop 3d-2b: per sector (city_maps.gdshaderinc)
	// A bridge deck over this point, and whether this fragment lies under it.
	float deck_y = surf.a > 0.0 ? surf.a * 255.0 / 4.0 - 32.0 : -1e4;
	bool under_deck = world_pos.y < deck_y - 1.5;
	// The deck ghost (F, 2026-11-07): a deck's road, walks and markings between the car under it
	// and the camera keep only the ghost's thin dither, as a building's walls do; the ground under
	// the deck (under_deck) and everything near the car's own height stay whole.
	if (surf.a > 0.0 && !under_deck && world_pos.y > ghost_car_y + DECK_GHOST_OVER) {
		float cut = ghost_fade(VERTEX.xy, wp);
		ivec2 bp = ivec2(FRAGCOORD.xy) % 4;
		if ((BAYER[bp.y * 4 + bp.x] + 0.5) / 16.0 < cut * (1.0 - DECK_GHOST_KEEP)) {
			discard;
		}
	}
	vec3 emit = vec3(0.0);
	float puddle = 0.0;
	float sheen = 0.0;
	if (id == 4 || id == 2) {
		// Paving slabs: small along footpaths, large granite on plazas.
		float size = id == 4 ? 1.2 : 2.4;
		vec2 cell = floor(street / size);
		shade = 0.96 + 0.07 * hash12(cell) - 0.08 * joints(street, size, 0.09);
		if (id == 4) {
			// R3: a footway is Warsaw's grey concrete pavers in running bond (0.6 x 0.3 m).
			vec2 q = street / vec2(0.6, 0.3);
			q.x += 0.5 * mod(floor(q.y), 2.0);
			vec2 f = abs(fract(q) - 0.5);
			float joint = step(0.44, f.x) + step(0.4, f.y);
			shade = 0.95 + 0.07 * hash12(floor(q)) - 0.07 * min(joint, 1.0);
		}
		vec4 stones = centralny(wp, id == 4);
		if (stones.a > 0.0) {
			base = srgb_to_linear(stones.rgb);
			shade = 1.0;
		} else {
			float grey = start_frame(wp).z;
			if (grey > 0.0) {
				base = mix(base, srgb_to_linear(id == 2 ? START_PLAZA : START_PAVING), grey);
			}
		}
	} else if (id == 6) {
		// Asphalt: fine grain, a little lighter wear, darker repair patches.
		float grain = hash12(floor(wp * 6.0));
		float patch = smoothstep(0.63, 0.7, value_noise(wp * 0.11 + 3.7));
		shade = 0.95 + 0.07 * grain - 0.06 * patch + 0.04 * n1;
		if (kp_setts_at(wp) > 0.5) {
			// Granite setts, 0.12 x 0.1 m in rows broken like bricks; each stone its own grey
			// or warm pink; dark joints.
			vec2 q = wp / vec2(0.12, 0.1);
			q.x += 0.5 * mod(floor(q.y), 2.0);
			vec2 f = abs(fract(q) - 0.5);
			float joint = step(0.42, f.x) + step(0.4, f.y);
			float pick = hash12(floor(q));
			vec3 stone = mix(vec3(0.6, 0.59, 0.57), vec3(0.7, 0.62, 0.58), step(0.7, pick));
			base = srgb_to_linear(stone);
			shade = 0.9 + 0.2 * hash12(floor(q) + 7.3) - 0.22 * min(joint, 1.0);
		}
	} else if (id == 1) {
		// Grass: soft lighter and darker patches with a slight hue drift. The look loop:
		// calmer, the lime read louder than the car: less yellow, and less chroma.
		float g = value_noise(wp * 0.35) * 0.6 + value_noise(wp * 1.7) * 0.4;
		base *= mix(vec3(0.88, 0.94, 0.84), vec3(1.08, 1.05, 0.9), g);
		base *= GRASS_TINT;
		base = mix(vec3(dot(base, LUMA)), base, GRASS_CHROMA);
		shade = 0.97 + 0.06 * hash12(floor(wp * 4.0));
	} else if (id == 5) {
		// Cycle lanes and crossings: Warsaw brick red (the look loop; the mapped coral read
		// louder than the player's red car).
		base = srgb_to_linear(BRICK);
		shade = 0.94 + 0.08 * hash12(floor(wp * 5.0));
	} else if (id == 7) {
		shade = 0.88 + 0.12 * value_noise(wp * 1.3); // worn paint
	} else if (id == 9 || id == 15) {
		// Ballast gravel; along a track, concrete sleepers across it every 0.65 m.
		shade = 0.86 + 0.24 * hash12(floor(wp * 7.0));
		if (id == 9) {
			float sl = fract(street.x / 0.65);
			if (sl > 0.18 && sl < 0.62) {
				// A concrete sleeper (0.28 m wide), each a little different.
				base = srgb_to_linear(vec3(0.66, 0.64, 0.6));
				shade = 0.9 + 0.14 * hash12(vec2(floor(street.x / 0.65), 3.0));
			}
		}
	} else if (id == 10) {
		// Steps: a darker edge line on every tread.
		shade = fract(street.x / 0.34) < 0.22 ? 0.8 : 1.0;
	} else if (id == 11) {
		// Flowerbeds: leaves with dots of flowers.
		vec2 cell = floor(wp * 2.5);
		float pick = hash12(cell);
		if (pick > 0.62) {
			vec3 bloom[4] = vec3[4](vec3(0.85, 0.25, 0.3), vec3(0.95, 0.75, 0.2), vec3(0.65, 0.4, 0.8), vec3(0.95, 0.95, 0.9));
			base = srgb_to_linear(bloom[int(pick * 40.0) % 4]);
		}
		shade = 0.9 + 0.15 * hash12(cell + 3.1);
	} else if (id == 12) {
		shade = 0.85 + 0.2 * value_noise(wp * 0.8) + 0.06 * hash12(floor(wp * 5.0)); // dirt
	} else if (id == 13) {
		// Playground rubber in muted tiles.
		vec2 tile = floor(street / 2.0);
		vec3 rubber[3] = vec3[3](vec3(0.78, 0.45, 0.35), vec3(0.45, 0.6, 0.75), vec3(0.55, 0.7, 0.45));
		base = srgb_to_linear(rubber[int(hash12(tile) * 30.0) % 3]);
	} else if (id <= 0) {
		// Bare ground: in the start box it is pavement, grey concrete slabs (0.5 m, laid along
		// Marszałkowska) like the footways.
		vec3 f = start_frame(wp);
		if (f.z > 0.0) {
			vec2 q = f.xy / 0.5;
			vec2 e = abs(fract(q) - 0.5);
			float joint = step(0.43, max(e.x, e.y));
			base = mix(base, srgb_to_linear(START_PAVING), f.z);
			shade = mix(shade, 0.95 + 0.06 * hash12(floor(q)) - 0.07 * joint, f.z);
		}
	} else if (id == 20) {
		// First-scene item 5: a tactile pad at a crossing: rows of studs 0.1 m apart.
		vec2 q = fract(wp / 0.1) - 0.5;
		shade = 0.9 + 0.12 * step(length(q), 0.28);
	} else if (id == 14) {
		shade = 0.95 + 0.06 * hash12(floor(wp * 4.0)); // traffic island concrete
	} else if (id == 21) {
		// Smooth roads loop 7: a tram track on its own bed: gravel, and a darker timber-brown
		// sleeper (0.24 m wide) across it every 0.6 m, each a little different.
		shade = 0.9 + 0.18 * hash12(floor(wp * 7.0));
		float sl = fract(street.x / 0.6);
		if (sl > 0.3 && sl < 0.7) {
			base = srgb_to_linear(vec3(0.43, 0.4, 0.37));
			shade = 0.92 + 0.12 * hash12(vec2(floor(street.x / 0.6), 5.0));
		}
	} else if (id == 19) {
		// Loop 3b-2: the tram bed: concrete track slabs, a joint across it every 3 m.
		vec2 slab = floor(street / vec2(3.0, 2.0));
		shade = 0.95 + 0.06 * hash12(slab) - 0.1 * step(fract(street.x / 3.0), 0.05);
	} else if (id == 16 || id == 17) {
		// Loop 3b-2: sand (beaches, sandbars) and the wet bands of a natural bank or a
		// sandbar's rim (their colour, sand or earth, from the vertex): a fine grain, soft
		// drifts on the dry sand; darker after dark (the beach read as a pale lavender plane).
		shade = 0.95 + 0.06 * hash12(floor(wp * 4.5));
		if (id == 16) {
			shade += 0.06 * (value_noise(wp * 0.45) - 0.5);
		}
		base *= mix(0.6, 1.0, daylight);
	} else if (id == 18) {
		// Loop 3b-2: the foam line on a natural waterline: a 1-px line that breathes a little,
		// dim after dark (night water stays calm and dark).
		shade = 0.9 + 0.1 * value_noise(wp * 0.8 + vec2(TIME * 0.15, 0.0));
		base *= mix(0.32, 1.0, daylight);
	} else if (id == 3) {
		// Water. The river (B = 1 in the surface map) flows along its baked direction;
		// ponds and fountains are still.
		float d = surf.r * 64.0;
		bool flowing = surf.b > 0.9;
		float ang = (surf.g * 255.0 - 128.0) / 127.0 * PI;
		vec2 flow = flowing ? vec2(sin(ang), -cos(ang)) * 0.75 : vec2(0.0);
		// A flow map: the pattern slides downstream in two phases that take turns
		// (offsets stay under 10 m, so the current can turn with the banks without
		// tearing the pattern), stretched along the river's general line (NNW).
		float ph0 = fract(TIME * 0.075);
		float ph1 = fract(TIME * 0.075 + 0.5);
		float k0 = 1.0 - abs(2.0 * ph0 - 1.0);
		const vec2 AX = vec2(-0.34, -0.94);
		const vec2 AY = vec2(0.94, -0.34);
		vec2 p0 = wp - flow * ph0 * 13.3;
		vec2 p1 = wp - flow * ph1 * 13.3 + vec2(3.7, 1.9);
		vec2 s0 = vec2(dot(p0, AX) * 0.2, dot(p0, AY) * 0.85);
		vec2 s1 = vec2(dot(p1, AX) * 0.2, dot(p1, AY) * 0.85);
		float r1 = mix(value_noise(s1), value_noise(s0), k0);
		float r2 = mix(value_noise(s1 * vec2(3.6, 1.7) + vec2(0.0, TIME * 0.07)), value_noise(s0 * vec2(3.6, 1.7) + vec2(0.0, TIME * 0.07)), k0);
		ripple = r1 * 0.55 + r2 * 0.45;
		// Depth from the shore inwards: light and a little green at the edge, deep blue
		// mid-river. Loop 1: a slow lowland river, not the open sea: a touch deeper and
		// greyer, the flow a low-contrast drift (calmer still after dark), few glints.
		float deep = smoothstep(1.5, flowing ? 42.0 : 14.0, d);
		// The look loop: by day the depth shading starts from a grey-green-blue (the mapped
		// azure read as an open sea); at night from the old colour, so night is unchanged.
		base = mix(base, srgb_to_linear(DAY_WATER), daylight);
		base = mix(base * vec3(1.02, 1.1, 0.98) + vec3(0.0, 0.02, 0.012), base * vec3(0.38, 0.56, 0.86), deep);
		base = mix(vec3(dot(base, vec3(0.3, 0.59, 0.11))), base, mix(0.75, 0.9, daylight));
		float calm = mix(0.5, 1.0, daylight);
		base *= 1.0 + (smoothstep(0.3, 0.75, ripple) - 0.5) * 0.16 * calm;
		vec3 glint = mix(srgb_to_linear(sky_colour) * 0.7, srgb_to_linear(vec3(0.74, 0.86, 0.93)), daylight);
		// The pale crests: a third as strong by day (they read as white streaks), as before at night.
		base = mix(base, glint, smoothstep(0.68, 0.86, ripple) * 0.24 * calm * mix(1.0, 0.33, daylight));
		// Shore foam: a broken band that laps in and out (thin round ponds and fountains).
		float lap = 0.5 + 0.5 * sin(TIME * 1.2 + value_noise(wp * 0.25) * 6.0);
		float band = flowing ? 1.4 + 1.0 * lap : 0.5 + 0.3 * lap;
		float foam = (1.0 - smoothstep(0.3, band, d)) * step(0.42, value_noise(wp * 1.7 + vec2(TIME * 0.25, 0.0)));
		base = mix(base, vec3(0.8, 0.86, 0.88), foam * (surf.b > 0.5 ? 0.6 : 0.0));
		// Sun sparkles: a rare pixel on the highest crests flickers (day only). The look loop:
		// a quarter as many (1 cell in 1,600 was 1 in 400), each a 0.3 m cell, 1-2 px.
		float spark = step(0.999375, hash12(floor(wp * 3.4) + floor(TIME * 3.0) * 17.0)) * smoothstep(0.66, 0.82, ripple);
		base += vec3(1.0, 0.96, 0.85) * spark * daylight * (1.0 - 0.8 * rain) * 0.7;
		if (under_deck) {
			base *= 0.6; // in the bridge's shade
		}
		// After dark the river goes deep and inky.
		base *= mix(vec3(0.22, 0.2, 0.3), vec3(1.0), daylight);
		// Loop 3i (BACKLOG "night water too plain at the widest zoom"): after dark a faint
		// sheen of the night sky comes back as light, strongest on the slow crests, and the
		// city's glow warms the water near the banks. Low contrast, so the lamps' reflections
		// still carry the river; only below dusk's daylight (0.45), so dusk keeps its own colour.
		float night = smoothstep(0.35, 0.0, daylight) * (under_deck ? 0.3 : 1.0) * (1.0 - 0.6 * rain);
		// Broad slow patches (40-80 m) so the sheen still reads at the widest zoom, where the
		// ripple is finer than a pixel.
		float crest = smoothstep(0.5, 0.85, ripple);
		float broad = smoothstep(0.3, 0.8, value_noise(vec2(dot(wp, AX) * 0.012, dot(wp, AY) * 0.03) + vec2(TIME * 0.004, 0.0)));
		emit += srgb_to_linear(sky_colour) * night * (0.05 + 0.16 * broad + 0.1 * crest) * mix(1.0, 0.75, deep);
		emit += srgb_to_linear(vec3(0.55, 0.32, 0.42)) * night * 0.1 * (1.0 - smoothstep(2.0, 40.0, d));
	}
	if (id <= 0 || id == 2 || id == 4) {
		float plac = plac_at(wp);
		if (plac > 0.0) {
			vec2 q = (wp - vec2(PLAC_BOX.x, PLAC_BOX.z)) / 6.0;
			vec2 e = abs(fract(q) - 0.5);
			float em = max(e.x, e.y);
			float aa = max(fwidth(em), 0.002);              // soft edge one pixel wide: no crawl
			float band = smoothstep(PLAC_BAND_EDGE - aa, PLAC_BAND_EDGE + aa, em);
			// Orthographic view height in metres (2 / P[1][1]): the panel step is gone by 110 m.
			float view_m = 2.0 / max(PROJECTION_MATRIX[1][1], 1e-4);
			float panel = mod(floor(q.x) + floor(q.y), 2.0) * (1.0 - smoothstep(65.0, 110.0, view_m));
			vec3 col = mix(mix(PLAC_LIGHT, PLAC_DARK, panel), PLAC_BAND, band);
			vec2 slab = wp / 1.5;                           // the slabs inside a panel
			vec2 j = abs(fract(slab) - 0.5);
			float speckle = value_noise(wp * 5.0) - 0.5;    // fine granite grain (~20 cm)
			base = mix(base, srgb_to_linear(col), plac);
			shade = mix(shade, 0.97 + 0.04 * hash12(floor(slab)) + 0.05 * speckle - 0.035 * step(0.46, max(j.x, j.y)), plac);
		}
	}
	// Rain: wet asphalt and paving darken, puddles lie darker still and mirror the sky.
	if (wetness > 0.001 && (id == 6 || id == 2 || id == 4 || id == 5 || id == 7 || id == 14 || id == 19)) {
		base *= mix(1.0, id == 6 ? 0.62 : (id == 7 ? 0.82 : 0.74), wetness);
		// Loop 3i: the markings (7) lie in the same puddles as the asphalt under them, so a
		// painted line goes dark and mirrors the sky where it crosses one, not over it.
		if (id == 6 || id == 2 || id == 4 || id == 7) {
			float pm = value_noise(wp * 0.16 + 11.3) * 0.6 + value_noise(wp * 0.53 + 2.1) * 0.4;
			puddle = smoothstep(0.64, 0.69, pm) * smoothstep(0.35, 0.9, wetness);
		}
		base *= 1.0 - 0.5 * puddle;
		sheen = wetness * (id == 6 ? 0.14 : 0.09) + puddle * 0.32;
		if (puddle > 0.0 && rain > 0.0) {
			// Rings where the drops land: one per 0.9 m cell, growing and fading.
			vec2 cell = floor(wp / 0.9);
			vec2 c = (cell + 0.2 + 0.6 * vec2(hash12(cell), hash12(cell + 7.1))) * 0.9;
			float ph = fract(TIME * 1.3 + hash12(cell + 3.3));
			float ring = 1.0 - smoothstep(0.0, 0.06, abs(length(wp - c) - ph * 0.42));
			sheen += ring * (1.0 - ph) * puddle * rain * 0.6;
		}
	}
	vec2 shade_map = city_ao_at(wp);
	float ghost = ghost_fade(VERTEX.xy, wp);
	float ao = mix(1.0, mix(shade_map.r, 1.0, ghost) * shade_map.g, ao_strength);
	ALBEDO = base * shade * ao * (1.0 - clouds * daylight * (1.0 - rain) * cloud_shadow(wp, TIME));
	if (ghost > 0.0) {
		// Inside a ghosted footprint (deep in the buildings' shade): its sunlight back.
		float inside = smoothstep(0.5, 0.8, (1.0 - shade_map.r) / 0.72);
		vec3 n = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		emit += ALBEDO * ghost_sun * max(dot(n, ghost_sun_dir), 0.0) * inside * ghost;
	}
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	vec2 away = normalize(fwd.xz + vec2(1e-5));
	if (sheen > 0.0) {
		// The wet surface mirrors the (overcast) sky.
		emit += mix(srgb_to_linear(sky_colour) * 0.35, srgb_to_linear(vec3(0.72, 0.76, 0.8)), daylight) * sheen * (0.25 + 0.5 * daylight);
	}
	if (lights_on > 0.001) {
		// Lamp pools, softened a little by the contact shadows; none under a bridge deck
		// (its lamps stand on top). (A little light even on dark asphalt: sodium-lit roads
		// read orange.) On the water, the lamps reflect instead: broken columns of light
		// towards the viewer, shimmering, on dark, calm water (loop 1: the pink and cyan
		// glints that washed over half the river went; the mirror carries the neon).
		// The look loop: the pools are banded pixel light, capped under the lit windows'
		// brightness, and tint grass, cycle lanes and flowerbeds instead of adding to them.
		vec3 glow;
		if (id == 3) {
			glow = lamp_reflection(wp, away, 2.6, 1.6) * 0.7 * (under_deck ? 0.3 : 1.0);
		} else {
			vec4 pool = lamp_pool(wp, FRAGCOORD.xy);
			glow = pool_glow(base * shade * mix(1.0, ao, 0.6), pool, id == 1 || id == 5 || id == 11) * (under_deck ? 0.05 : 1.0);
			if (sheen > 0.0) {
				glow += lamp_reflection(wp, away, 1.4, 0.4) * min(sheen * 2.2, 1.0) * 0.8;
			}
		}
		emit += glow * lights_on;
	}
	EMISSION = emit;
	if (debug_ao) {
		ALBEDO = vec3(ao) * 0.45; // dim, so the sunlight doesn't push it to white
	}
	ROUGHNESS = 1.0 - 0.45 * min(sheen * 3.0, 1.0);
	SPECULAR = 0.1 + 0.3 * min(sheen * 3.0, 1.0);
}
