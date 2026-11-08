shader_type spatial;
// Moving things built from coloured boxes: traffic, trams, rivals, pedestrians.
// UV.x says how a vertex is coloured (models.gd): 0 = its colour times the instance
// paint (INSTANCE_CUSTOM.rgb, MultiMesh only), 1 = its own colour, 2 = trousers from a
// small palette picked by INSTANCE_CUSTOM.a, and its own colour that glows when the
// city's lights are on: 3 = headlamp, 4 = tail lamp, 5 = a lit window (bus, tram),
// 6 = a lit sign (taxi), 7 = an amber lamp that blinks (roadworks, loop 1; all in one
// beat with their halos, glow.gdshader); 8 = the player's car (car.gd, the look loop): its own
// colour, lit from within at night by UV.y (a hero material: never darker than the road
// under it), a little brighter on the faces that look up. UV.y = +1 / -1 marks the left /
// right leg of a pedestrian, which swing as they walk (not when INSTANCE_CUSTOM.a >= 2: standing). Under the street lamps (night.gdshaderinc; main.gd
// hands this material the baked light map) they catch the light at night.
//
// Loop 2c (car models): a traffic family's mesh (models.gd family()) holds up to four shapes of
// the same parts, a hatch, a saloon, an estate and an SUV in one MultiMesh: its vertices have
// UV.x + 16, CUSTOM0..2 hold their position (xyz) and packed normal (w) in shapes 1..3, and
// INSTANCE_CUSTOM.a picks the shape (0: the mesh's own). For a BLINK lamp (7) UV.y shifts the
// beat by that share of a blink (the police light bar's two lamps take turns; 0 for roadworks).
//
// Loop 3g-1 (police, docs/design/police.md section 9): SIREN. On a family mesh INSTANCE_CUSTOM.a
// is the shape plus 4 x a mode (traffic.gd POLICE): 0 the old BLINK lamps, 1 a police light bar
// switched off (its lenses dim, still two-tone), 2 flashing: the patrol car's blue and red lenses
// in turns, 0.2 s each (2.5 Hz, UV.y shifts the beat), the guards' amber pair together at 1.5 Hz;
// a lit lens glows by day too, more at night.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"

uniform float clouds = 0.18;
// Pedestrians swing their legs; vehicles leave this at 0.
uniform float walk = 0.0;
varying vec3 world_pos;
varying vec3 tint;
varying vec3 glow;
varying float blink;
// Loop 3g-1 SIREN: x 0 none, 1 off, 2 flashing; y the beat's shift; z flashes a second.
varying vec3 siren;

const vec3 TROUSERS[4] = vec3[](vec3(0.18, 0.22, 0.33), vec3(0.12, 0.12, 0.13), vec3(0.42, 0.40, 0.37), vec3(0.55, 0.45, 0.32));

// A unit normal packed by models.gd _pack_normal(): octahedral, 12 bits a coordinate.
vec3 unpack_normal(float f) {
	float hi = floor(f / 4096.0);
	vec2 e = vec2(hi, f - hi * 4096.0) / 4095.0 * 2.0 - 1.0;
	vec3 n = vec3(e, 1.0 - abs(e.x) - abs(e.y));
	if (n.z < 0.0) {
		n.xy = (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
	}
	return normalize(n);
}

void vertex() {
	float code = UV.x;
	float siren_mode = 0.0;
	int shape = 0;
	if (code > 15.5) {
		code -= 16.0;
		siren_mode = floor((INSTANCE_CUSTOM.a + 0.5) / 4.0);
		shape = int(INSTANCE_CUSTOM.a - siren_mode * 4.0 + 0.5);
		if (shape > 0) {
			vec4 m = shape == 1 ? CUSTOM0 : (shape == 2 ? CUSTOM1 : CUSTOM2);
			VERTEX = m.xyz;
			NORMAL = unpack_normal(m.w);
		}
	}
	vec3 c = srgb_to_linear(COLOR.rgb);
	int part = int(code + 0.5);
	glow = vec3(0.0);
	blink = 0.0;
	siren = vec3(0.0);
	if (part == 0) {
		c *= srgb_to_linear(INSTANCE_CUSTOM.rgb);
	} else if (part == 2) {
		c = srgb_to_linear(TROUSERS[int(clamp(fract(INSTANCE_CUSTOM.a) * 4.0, 0.0, 3.0))]);
	} else if (part == 3) {
		glow = vec3(1.0, 0.9, 0.7) * 3.0;
	} else if (part == 4) {
		glow = vec3(1.0, 0.06, 0.04) * 2.2;
	} else if (part == 5) {
		glow = vec3(1.0, 0.82, 0.55) * 0.75;
	} else if (part == 6) {
		glow = c * 1.6;
	} else if (part == 7 && siren_mode > 0.5) {
		siren = vec3(siren_mode, UV.y, shape == 1 ? 1.5 : 2.5);
	} else if (part == 7) {
		glow = c * 4.0;
		blink = 1.0 + UV.y;
	} else if (part == 8) {
		// A touch more orange than the paint: a saturated red tops out at a low luma, so
		// the glow needs some green to climb clear of the road (kept red-orange, hue ~13
		// degrees: the jobs' beacon is orange, 24).
		glow = (c + vec3(0.0, 0.028, 0.008)) * UV.y * (0.75 + 0.25 * max(NORMAL.y, 0.0));
	}
	tint = c;
	// A pedestrian's alpha of 2 or more (trains.gd STAND_A): one waiting on a platform, standing still.
	if (walk > 0.0 && abs(UV.y) > 0.5 && INSTANCE_CUSTOM.a < 2.0) {
		float phase = TIME * 9.0 + float(INSTANCE_ID) * 1.7;
		VERTEX.z += UV.y * sin(phase) * walk * clamp(1.0 - VERTEX.y / 0.9, 0.0, 1.0);
	}
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = tint * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
	vec3 em = vec3(0.0);
	if (lights_on > 0.001) {
		vec3 g = glow;
		if (blink > 0.5) {
			// On a little over half the time, about once a second.
			g *= step(0.42, fract(TIME * 1.15 + blink - 1.0));
		}
		em = (g + tint * lamp_light(world_pos.xz) * 1.4) * lights_on;
	}
	if (siren.x > 0.5) {
		// Loop 3g-1 SIREN: a lit lens glows (by day too); an unlit one is dim but keeps its hue.
		float lit = siren.x > 1.5 ? step(0.5, fract(TIME * siren.z + siren.y)) : 0.0;
		ALBEDO = tint * mix(0.3, 1.0, lit);
		em += tint * lit * (1.2 + 2.8 * lights_on);
	}
	EMISSION = em;
}
