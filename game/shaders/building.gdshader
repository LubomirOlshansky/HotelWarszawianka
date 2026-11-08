shader_type spatial;
// Double-sided: a few LoD2 walls are wound inside out, and Godot flips the normal for back faces.
render_mode cull_disabled;
// Buildings. Walls carry UV = (metres along the wall, metres above the ground)
// and UV2 = (per-building style seed 0..1, wall top above the ground); roofs
// have UV.x < 0. From those the shader draws each building's own window rhythm,
// shop fronts on the ground floor, a cornice, and curtain walls on glass towers.
// It also opens a dithered hole wherever a building stands between camera and car,
// and (v0.8, reworked in loop 1) turns everything on the camera's side of the car that
// covers the car's surroundings on screen into a thin dithered ghost (ghost.gdshaderinc).
//
// v0.8 landmarks (landmarks.gd) carry a material code in UV2.x (2 and up; ordinary
// buildings keep their 0..1 style seed there): the Palace of Culture's stone with tall
// windows, plain stone, crenellated attics, gold, clock dials, Stadion Narodowy's
// woven red-and-white skin and roof membrane, Złote Tarasy's glass wave, the Rotunda's
// glass drum, lamps. Its fraction is a parameter (an attic's height in tens of metres).
//
// When the lights come on (night.gdshaderinc): a seeded share of the windows
// glows (warm flats, cool offices, the odd blue TV), whole floors of the glass
// towers, lit shop fronts with neon tubes over some of them, street-lamp light on
// the lower facades, and the Palace of Culture floodlit.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"
#include "res://shaders/ghost.gdshaderinc"

uniform float clouds = 0.18;
uniform float fade_radius = 7.5;
// The share of the ghost's pixels that stay in its core (a thin ghost keeps the tower's
// shape; the rim is a soft dither out to the whole wall).
uniform float ghost_keep = 0.19;
// --ghost-debug (main.gd): 1 paints the ghost magenta and the other buildings green,
// 2 cuts the ghost fully.
uniform int ghost_debug = 0;
// The Palace of Culture's clock (loop 1, main.gd, once a minute): the hour and minute
// hands' angles in radians, clockwise from twelve, for the time in Warsaw.
uniform vec2 clock_hands = vec2(5.32, 1.05);
uniform float windows = 1.0;
// The floodlit landmark: x, z of its centre and a radius (map_builder.gd, from the
// Palace of Culture's outline); only its sandstone walls light up.
uniform vec4 floodlit = vec4(0.0, 0.0, -1.0, 0.0);
// Its event lighting by date (palace_lights.gd, main.gd): 0 the nightly gold, 1 one colour,
// 2 colour a on the base and pavilions and b up the tower, 3 a rainbow across the facades
// (drifting `flood_cycle` turns a minute).
uniform int flood_mode = 0;
uniform vec3 flood_a : source_color = vec3(1.0, 0.7, 0.3);
uniform vec3 flood_b : source_color = vec3(1.0, 0.7, 0.3);
uniform float flood_cycle = 0.0;
varying vec3 world_pos;
varying vec2 style;
// The roofs lane: the plane's world normal (a roof's slope and which way it falls).
varying vec3 world_n;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// Linear colours of the lit windows.
const vec3 WARM = vec3(1.0, 0.52, 0.2);
const vec3 WARM_PALE = vec3(1.0, 0.72, 0.42);
const vec3 COOL = vec3(0.62, 0.78, 1.0);
const vec3 TV = vec3(0.22, 0.36, 1.0);
const vec3 NEON[3] = vec3[3](vec3(1.0, 0.08, 0.5), vec3(0.05, 0.85, 1.0), vec3(0.55, 0.16, 1.0));
// The inner faces of a building the ghost cuts (sRGB, unlit): a step darker than the
// street seen beside them, by day and at night (the look loop).
const vec3 INNER_DAY = vec3(0.3, 0.31, 0.34);
const vec3 INNER_NIGHT = vec3(0.15, 0.15, 0.24);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	style = UV2;
}

// A lit room's colour: warm most often, cool white in offices, sometimes a TV.
vec3 room(float pick, bool office, vec2 cell) {
	if (office) {
		return pick < 0.7 ? COOL : WARM_PALE;
	}
	if (pick < 0.62) {
		return WARM;
	} else if (pick < 0.76) {
		return WARM_PALE;
	} else if (pick < 0.86) {
		return COOL;
	}
	// A television: blue, flickering.
	float flick = 0.65 + 0.35 * value_noise(vec2(TIME * 3.1 + cell.x * 7.0, cell.y * 3.0));
	return TV * flick;
}

// The wall's colour at (u along, h up); `glow` gets what it gives off at night.
vec3 facade(vec3 col, float u, float h, float seed, float top, bool glass, out vec3 glow) {
	glow = vec3(0.0);
	bool night = lights_on > 0.001;
	// Some buildings are mostly dark, some nearly all lit.
	float busy = 0.35 + 1.3 * fract(seed * 17.31);
	if (glass) {
		// Curtain wall: mullions, floor bands, and a sky reflection that brightens upwards.
		vec3 sky = srgb_to_linear(sky_colour);
		vec3 deep = srgb_to_linear(vec3(0.18, 0.27, 0.37)) * mix(0.3, 1.0, daylight);
		float refl = clamp(h / max(top, 1.0), 0.0, 1.0) * 0.55 + 0.3 * value_noise(vec2(u * 0.04, h * 0.02) + seed * 17.0);
		col = mix(col * mix(0.35, 0.7, daylight), mix(deep, sky, refl), 0.6);
		float mullion = abs(fract(u / 1.6) - 0.5) * 1.6;
		bool frame = fract(h / 3.7) < 0.07 || mullion > 0.72;
		if (frame) {
			col *= 0.7;
		} else if (night && h > 3.0) {
			// Whole office floors left on, and single bays here and there.
			float level = floor(h / 3.7);
			float whole = hash12(vec2(level, seed * 91.0));
			// Bays light in runs of three, like one office's worth of desks.
			float bay = hash12(vec2(floor(u / 4.8), level) + seed * 53.0);
			if (whole < 0.18 * busy * lights_on || bay < 0.12 * busy * lights_on) {
				float tone = hash12(vec2(level, 3.3) + seed);
				glow = (tone < 0.75 ? COOL : WARM_PALE) * (0.95 + 0.3 * bay);
				col *= 0.45;
			}
		}
		return col;
	}
	float fh = 3.0 + 0.7 * fract(seed * 7.13);   // floor height
	float sp = 2.2 + 1.4 * fract(seed * 3.71);   // window spacing
	float ww = 0.32 + 0.22 * fract(seed * 5.37); // window width (share of spacing)
	float wh = 0.42 + 0.18 * fract(seed * 9.11); // window height (share of floor)
	float fy = fract(h / fh);
	float fx = fract(u / sp);
	if (top > 4.0 && h > top - 0.7) {
		return col * 1.12; // cornice / parapet
	}
	if (h < fh) {
		// Ground floor: wide shop windows under a darker fascia band.
		bool shop = fy > 0.12 && fy < 0.78 && abs(fx - 0.5) < 0.38;
		vec3 window_col = mix(col * 0.45, srgb_to_linear(vec3(0.23, 0.27, 0.31)), 0.72);
		if (night) {
			vec2 unit = vec2(floor(u / sp), seed * 77.0);
			// Neon tubes along the fascia over some buildings' shops.
			if (fract(seed * 23.17) > 0.7 && fy > 0.83 && fy < 0.93 && abs(fx - 0.5) < 0.42) {
				vec3 tube = NEON[int(fract(seed * 41.3) * 3.0)];
				glow = tube * 2.6;
				return tube * 0.25;
			}
			if (shop && hash12(unit) < 0.72 * lights_on) {
				float tone = hash12(unit + 5.1);
				glow = (tone < 0.65 ? WARM_PALE : vec3(0.9, 0.92, 1.0)) * 1.35;
				return window_col * 0.6;
			}
		}
		if (shop) {
			return window_col;
		}
		return fy > 0.82 ? col * 0.84 : col;
	}
	if (abs(fx - 0.5) < ww * 0.5 && abs(fy - 0.55) < wh * 0.5) {
		// Each pane catches the light a little differently.
		vec2 cell = vec2(floor(u / sp), floor(h / fh));
		float pane = hash12(cell + seed * 31.0);
		vec3 glass_col = mix(srgb_to_linear(vec3(0.24, 0.29, 0.36)), srgb_to_linear(vec3(0.56, 0.67, 0.78)), pane * pane);
		if (night) {
			bool office = top > 35.0;
			float share = (office ? 0.42 : 0.34) * busy;
			if (hash12(cell * 1.37 + seed * 59.0 + 7.7) < share * lights_on) {
				glow = room(hash12(cell + seed * 13.0), office, cell) * (1.05 + 0.5 * hash12(cell + 2.2));
				return mix(col * 0.5, glass_col, 0.66) * 0.35;
			}
			// Dark panes at night reflect a little less sky.
			glass_col *= mix(0.45, 1.0, daylight);
		}
		return mix(col * 0.5, glass_col, 0.66);
	}
	if (fract(seed * 13.7) > 0.5 && fy < 0.05) {
		return col * 0.9; // floor line
	}
	return col;
}

// R4 of docs/design/start-area-real.md (2026-11-01): ordinary buildings drawn by their type,
// not only their seed. map_builder.gd (_building_type) tags a wall's UV2.x in [1, 2): the type
// in quarters (1 a pre-war tenement, 2 a 1960s-80s slab or point block, 3 a post-war office
// with ribbon windows) and the seed in the rest of the quarter. Untyped walls keep [0, 1).
const int T_TENEMENT = 1;
const int T_SLAB = 2;
const int T_OFFICE = 3;

// A pane's colour by day, and a lit room at night: the same rules as facade()'s windows.
vec3 typed_pane(vec3 col, vec2 cell, float seed, bool office, out vec3 glow) {
	glow = vec3(0.0);
	float pane = hash12(cell + seed * 31.0);
	vec3 glass_col = mix(srgb_to_linear(vec3(0.22, 0.27, 0.34)), srgb_to_linear(vec3(0.55, 0.66, 0.77)), pane * pane);
	if (lights_on > 0.001) {
		float busy = 0.35 + 1.3 * fract(seed * 17.31);
		float share = (office ? 0.42 : 0.34) * busy;
		if (hash12(cell * 1.37 + seed * 59.0 + 7.7) < share * lights_on) {
			glow = room(hash12(cell + seed * 13.0), office, cell) * (1.05 + 0.5 * hash12(cell + 2.2));
			return mix(col * 0.5, glass_col, 0.66) * 0.35;
		}
		glass_col *= mix(0.45, 1.0, daylight);
	}
	return mix(col * 0.45, glass_col, 0.7);
}

vec3 typed_facade(int kind, vec3 col, float u, float h, float seed, float top, out vec3 glow) {
	glow = vec3(0.0);
	bool night = lights_on > 0.001;
	if (kind == T_TENEMENT) {
		// A pre-war tenement (kamienica): a tall rusticated shop floor, a string course, tall
		// windows with light plaster surrounds and sills, a heavy cornice with its shadow.
		float g = 4.4 + 0.5 * fract(seed * 7.13);    // the ground floor
		float fh = 3.6 + 0.6 * fract(seed * 3.31);   // upper floors
		float sp = 2.7 + 0.7 * fract(seed * 5.71);   // window axes
		if (top > 6.0 && h > top - 0.9) {
			return col * 1.16;                          // the cornice
		}
		if (top > 6.0 && h > top - 1.15) {
			return col * 0.62;                          // its shadow
		}
		float fx = fract(u / sp);
		if (h < g) {
			float fy = h / g;
			bool shop = fy > 0.08 && fy < 0.74 && abs(fx - 0.5) < 0.36;
			vec3 window_col = mix(col * 0.45, srgb_to_linear(vec3(0.2, 0.24, 0.28)), 0.75);
			if (night && shop) {
				vec2 unit = vec2(floor(u / sp), seed * 77.0);
				if (hash12(unit) < 0.72 * lights_on) {
					glow = (hash12(unit + 5.1) < 0.65 ? WARM_PALE : vec3(0.9, 0.92, 1.0)) * 1.35;
					return window_col * 0.6;
				}
			}
			if (shop) {
				return window_col;
			}
			if (fy > 0.8) {
				return col * 0.8;                       // the fascia
			}
			return fract(h / 0.42) < 0.12 ? col * 0.84 : col * 0.97;   // rustication
		}
		if (h < g + 0.32) {
			return col * 1.12;                          // the string course
		}
		float y = h - g;
		float fy = fract(y / fh);
		vec2 cell = vec2(floor(u / sp), floor(y / fh));
		float wx = abs(fx - 0.5);
		float wy = abs(fy - 0.5);
		bool win = wx < 0.17 && wy < 0.3;
		if (win) {
			return typed_pane(col, cell, seed, false, glow);
		}
		if (wx < 0.23 && wy < 0.36) {
			return col * 1.14;                          // the surround
		}
		if (wx < 0.25 && fy > 0.08 && fy < 0.13) {
			return col * 0.78;                          // the sill's shadow
		}
		return col;
	}
	if (kind == T_SLAB) {
		// A large-panel slab or point block: pale panels with dark joints, wide windows,
		// stacks of loggias in some bays.
		col = mix(col, srgb_to_linear(vec3(0.82, 0.81, 0.77)), 0.35);
		float fh = 2.8;
		float sp = 3.0 + 0.6 * fract(seed * 5.37);
		float fy = fract(h / fh);
		float fx = fract(u / sp);
		vec2 cell = vec2(floor(u / sp), floor(h / fh));
		if (top > 6.0 && h > top - 0.6) {
			return col * 0.92;                          // the attic band
		}
		if (h < fh) {
			// The ground floor: dark service doors and windows, set back a little.
			bool door = abs(fx - 0.5) < 0.3 && fy < 0.75;
			return door ? col * 0.42 : col * 0.86;
		}
		bool loggia = hash12(vec2(floor(u / sp), seed * 19.0)) < 0.28 + 0.2 * fract(seed * 3.7);
		if (loggia) {
			// The loggia: a deep shadowed recess over a parapet with the window at its back.
			if (fy < 0.36) {
				return col * (abs(fx - 0.5) < 0.47 ? 0.9 : 1.0);   // the parapet
			}
			if (abs(fx - 0.5) < 0.46) {
				if (abs(fx - 0.5) < 0.3 && fy < 0.88) {
					return typed_pane(col * 0.6, cell, seed, false, glow) * 0.8;
				}
				return col * 0.5;
			}
		}
		if (fy < 0.04 || abs(fx - 0.5) > 0.49) {
			return col * 0.72;                          // the panel joints
		}
		if (abs(fx - 0.5) < 0.3 && fy > 0.32 && fy < 0.82) {
			return typed_pane(col, cell, seed, false, glow);
		}
		return col;
	}
	// T_OFFICE: a post-war office: continuous ribbon windows between spandrel bands.
	float fh = 3.6 + 0.3 * fract(seed * 7.1);
	float fy = fract(h / fh);
	vec2 cell = vec2(floor(u / 1.5), floor(h / fh));
	if (top > 6.0 && h > top - 0.8) {
		return col * 1.08;
	}
	if (h < fh) {
		bool glazed = fy > 0.05 && fy < 0.8 && fract(u / 1.5) > 0.06;
		if (glazed) {
			if (night && hash12(vec2(floor(u / 6.0), seed * 77.0)) < 0.7 * lights_on) {
				glow = vec3(0.9, 0.92, 1.0) * 1.2;
				return col * 0.3;
			}
			return mix(col * 0.4, srgb_to_linear(vec3(0.2, 0.24, 0.29)), 0.8);
		}
		return col * 0.75;
	}
	if (fy > 0.36 && fy < 0.92) {
		if (fract(u / 1.5) < 0.06) {
			return col * 0.6;                           // the mullions
		}
		return typed_pane(col, vec2(floor(u / 4.5), cell.y), seed, true, glow);
	}
	return col;
}

// Landmark materials (landmarks.gd). Codes match landmarks.gd's M_* constants.
const int M_MONUMENT = 2;
const int M_STONE = 3;
const int M_GOLD = 4;
const int M_DIAL = 5;
const int M_WEAVE = 6;
const int M_GLASS_ROOF = 7;
const int M_PAVILION = 8;
const int M_ATTIC = 9;
const int M_LAMP = 10;
const int M_MEMBRANE = 11;
const int M_GLASS = 12;
const int M_SKIN = 13;
const int M_GOTHIC = 14;
const int M_PANE = 15;

// The towers' own skins (landmarks.gd TOWERS, the landmarks loop): M_SKIN's fraction picks the
// pattern (style / 16), the vertex colour is the glass. Each reads as its tower from the
// street and the air: Złota 44's white banded cladding, Warsaw Spire's diamonds, Q22's silver
// floor bands, Rondo 1's fins, the hotel's white grid, Cosmopolitan's balcony slabs, dark
// glass, gold glass, and an open frame (Rondo 1's crown: the panes are cut away).
const int S_SAIL = 0;
const int S_DIAMOND = 1;
const int S_BANDS = 2;
const int S_FINS = 3;
const int S_GRID = 4;
const int S_RIBBON = 5;
const int S_DARK = 6;
const int S_GOLD = 7;
const int S_FRAME = 8;
const int S_TILE = 9;
const int S_EASTWALL = 10;
const int S_PUNCHED = 11;
const int S_SLAB = 12;
const int S_ESTATE = 14;
const int S_MIRROR = 13;
const int S_KEYS = 15;

vec3 skin(int s, vec3 col, float u, float h, float top, out vec3 glow, out bool cut) {
	glow = vec3(0.0);
	cut = false;
	vec3 sky = srgb_to_linear(sky_colour);
	vec3 white = srgb_to_linear(vec3(0.93, 0.94, 0.95)) * mix(0.3, 1.0, daylight);
	vec3 silver = srgb_to_linear(vec3(0.74, 0.77, 0.8)) * mix(0.3, 1.0, daylight);
	float fh = 3.8;
	// The glass: its own tint, a little sky towards the top (less than the plain curtain walls,
	// so the tint carries), a slow ripple of reflections.
	float refl = clamp(h / max(top, 1.0), 0.0, 1.0) * 0.18 + 0.12 * value_noise(vec2(u * 0.05, h * 0.03));
	vec3 c = mix(col * mix(0.35, 1.0, daylight), sky * mix(0.4, 1.0, daylight), refl);
	float level = floor(h / fh);
	bool frame = false;
	vec3 frame_col = silver;
	float lit = 0.3;
	if (s == S_SAIL) {
		// Złota 44 (rebuilt 2026-11-02 from F's photos): silver-white aluminium cassettes, about
		// 60 % of the face, in a band at every floor (3.55 m) with glass between. Each 4.5 m
		// panel picks its own window, a tall pane, the usual slot or none, so the stripes break
		// and stagger across the face like the real cladding; thin white mullions every 1.5 m.
		fh = 3.55;
		level = floor(h / fh);
		float fy = fract(h / fh);
		float r = hash12(vec2(floor(u / 4.5) + 17.0, level));
		float lo = r < 0.25 ? 0.22 : 0.5;
		float hi = r > 0.86 ? 0.0 : 0.9;
		frame = fy < lo || fy > hi || fract(u / 1.5) < 0.05;
		frame_col = white * (0.97 + 0.06 * hash12(vec2(floor(u / 1.5), level)));
	} else if (s == S_DIAMOND) {
		float d1 = fract((u + h) / 5.2);
		float d2 = fract((u - h) / 5.2);
		frame = d1 < 0.08 || d2 < 0.08;
		frame_col = mix(silver, white, 0.5);
		c *= 1.0 + 0.12 * (hash12(vec2(floor((u + h) / 5.2), floor((u - h) / 5.2))) - 0.5);
	} else if (s == S_BANDS) {
		frame = fract(h / fh) < 0.3 || fract(u / 1.5) < 0.1;
		frame_col = silver;
	} else if (s == S_FINS) {
		frame = fract(u / 2.4) < 0.22 || fract(h / fh) < 0.06;
		frame_col = mix(silver, white, 0.4);
	} else if (s == S_GRID) {
		frame = fract(u / 1.6) < 0.16 || fract(h / fh) < 0.16;
		frame_col = white;
	} else if (s == S_RIBBON) {
		frame = fract(h / 3.2) < 0.3 || fract(u / 3.0) < 0.05;
		frame_col = white;
		lit = 0.45;
	} else if (s == S_DARK) {
		frame = fract(u / 1.5) < 0.08 || fract(h / fh) < 0.05;
		c *= 0.7;
		frame_col = c * 1.6;
	} else if (s == S_GOLD) {
		frame = fract(u / 1.5) < 0.1 || fract(h / fh) < 0.08;
		frame_col = srgb_to_linear(vec3(0.42, 0.33, 0.2)) * mix(0.3, 1.0, daylight);
		c = mix(c, col * mix(0.35, 1.0, daylight) * 1.15, 0.6);
	} else if (s == S_MIRROR) {
		// The Blue Skyscraper's reflective float glass (1991): plain blue mirror panes, the sky
		// shining in them in slow streaks, a fine pale-silver spandrel at every floor and a
		// hairline mullion every 2.4 m (not the gold of its first, copper-tinted cladding).
		frame = fract(h / fh) < 0.07 || fract(u / 2.4) < 0.04;
		frame_col = mix(silver, white, 0.3) * 0.92;
		c = mix(c, sky * mix(0.4, 1.0, daylight), 0.28);
		c *= 0.9 + 0.2 * value_noise(vec2(u * 0.11, h * 0.025));
	} else if (s == S_TILE) {
		// White tiled panels, floodlit at night. The wall colour picks the face:
		// warm (red over blue: the HUB's hotel, the Rondo photos' first Novotel, 2026-10-31): a
		// hairline grid every 3.4 m by one floor, a window slit lit now and then;
		// cool or neutral: the Novotel from F's five photos (2026-11-07), seams every 1.55 m and at
		// every floor (2.95 m), the faces cooler white under the floodlights; a cool one (blue over
		// red: the long faces) adds the punched windows, small dark squares 1.25 x 1.1 m in pairs
		// in every 6.2 m bay, a share of them warm at night; a neutral one (the blank narrow ends
		// and the lift core's strip) stays plain.
		float flood = mix(0.3, 1.0, daylight);
		if (col.r > col.b + 0.004) {
			float gx = fract(u / 3.4);
			float gy = fract(h / fh);
			bool seam = gx < 0.035 || gy < 0.03;
			vec3 tile = white * (seam ? 0.72 : 1.0) * flood;
			if (lights_on > 0.001) {
				glow = srgb_to_linear(vec3(0.62, 0.66, 0.74)) * (seam ? 0.3 : 0.62) * lights_on;
				if (gx > 0.3 && gx < 0.62 && gy > 0.35 && gy < 0.62 && hash12(vec2(floor(u / 3.4), level) + 7.7) < 0.12 * lights_on) {
					glow = WARM_PALE * 0.9;
				}
			}
			return tile;
		}
		float pf = 2.95;
		float lvl = floor(h / pf);
		float gx = fract(u / 1.55);
		float gy = fract(h / pf);
		bool seam = gx < 0.02 || gy < 0.025;
		vec3 tile = white * (seam ? 0.8 : 1.0) * flood;
		if (col.b > col.r + 0.004) {
			float bay = fract(u / 6.2) * 6.2;
			float fy = gy * pf;
			float x = bay - (bay < 3.1 ? 1.9 : 4.3);
			if (abs(x) < 0.625 && fy > 0.95 && fy < 2.05) {
				if (lights_on > 0.001 && hash12(vec2(floor(u / 3.1), lvl) + 5.3) < 0.3 * lights_on) {
					glow = WARM_PALE * (0.8 + 0.3 * hash12(vec2(floor(u / 3.1), lvl) + 1.1));
					return c * 0.3;
				}
				return mix(srgb_to_linear(vec3(0.13, 0.15, 0.18)), sky * 0.45, refl) * mix(0.35, 1.0, daylight);
			}
			if (abs(x) < 0.7 && fy > 0.88 && fy < 2.12) {
				return tile * 0.86;
			}
		}
		if (lights_on > 0.001) {
			glow = srgb_to_linear(vec3(0.6, 0.68, 0.82)) * (seam ? 0.3 : 0.6) * lights_on;
		}
		return tile;
	} else if (s == S_EASTWALL) {
		// The Eastern Wall's stores (the Mac photo check, 2026-11-01): a vertical-led grid, strong
		// dark grey mullions every 1.5 m, only a thin dark spandrel line at each floor.
		frame = fract(u / 1.5) < 0.13 || fract(h / fh) < 0.035;
		frame_col = srgb_to_linear(vec3(0.247, 0.278, 0.298)) * mix(0.3, 1.0, daylight);
	} else if (s == S_PUNCHED) {
		// A re-clad 1970s point block (the start area's 75 m tower, 2026-11-01): light horizontal
		// metal cladding, punched windows in bands (2 x 1.4 m every 3.2 m, white frames, dark
		// glass), warm at night.
		float pf = 2.95;
		float wx = fract(u / 3.2);
		float wy = fract(h / pf);
		float lvl = floor(h / pf);
		vec3 clad = col * mix(0.3, 1.0, daylight) * (fract(h / 0.74) < 0.06 ? 0.9 : 1.0);
		bool win = abs(wx - 0.5) < 0.3125 && wy > 0.3 && wy < 0.775;
		bool rim = abs(wx - 0.5) < 0.345 && wy > 0.27 && wy < 0.805;
		if (win) {
			if (lights_on > 0.001 && hash12(vec2(floor(u / 3.2), lvl) + 2.9) < 0.42 * lights_on) {
				glow = WARM_PALE * 0.95;
				return c * 0.3;
			}
			return mix(srgb_to_linear(vec3(0.16, 0.19, 0.23)), sky * 0.5, refl) * mix(0.35, 1.0, daylight);
		}
		return rim ? white : clad;
	} else if (s == S_SLAB) {
		// A 1960s residential slab's long face (2026-11-01): pale plaster, a continuous loggia
		// band on every floor (a light balustrade, a dark recess with windows between thin
		// piers); warm windows and some lit balconies at night.
		float pf = 2.85;
		float wy = fract(h / pf);
		float lvl = floor(h / pf);
		float bay = floor(u / 3.6);
		float wx = fract(u / 3.6);
		vec3 plaster = col * mix(0.3, 1.0, daylight);
		if (h < pf || h > top - 0.6) {
			return plaster * (h < pf ? 0.86 : 1.06);
		}
		if (wy < 0.33) {
			return srgb_to_linear(vec3(0.9, 0.88, 0.83)) * mix(0.3, 1.0, daylight);
		}
		if (wy > 0.9 || wx < 0.07) {
			return plaster * 0.92;
		}
		vec3 deep = col * 0.55 * mix(0.35, 1.0, daylight);
		if (abs(wx - 0.55) < 0.18 && wy > 0.45 && wy < 0.84) {
			deep = mix(srgb_to_linear(vec3(0.17, 0.19, 0.22)), sky * 0.4, 0.3) * mix(0.35, 1.0, daylight);
			if (lights_on > 0.001 && hash12(vec2(bay, lvl) + 4.1) < 0.45 * lights_on) {
				glow = WARM_PALE * 0.9;
				return deep * 0.3;
			}
		} else if (lights_on > 0.001 && hash12(vec2(bay, lvl) + 8.3) < 0.1 * lights_on) {
			glow = WARM * 0.5;
		}
		return deep;
	} else if (s == S_ESTATE) {
		// Osiedle Za Żelazną Bramą (2026-11-01, spec zelazna.md): a large-panel slab of the
		// 1960s-70s, pale concrete panels in 3 m bays, a wide ribbon window in each, and in
		// every fourth bay a loggia stack with a coloured parapet (blue, ochre or brick, by
		// stack), dark inside; warm windows and a few lit loggias at night.
		float pf = 2.8;
		float wy = fract(h / pf);
		float lvl = floor(h / pf);
		float bay = floor(u / 3.0);
		float wx = fract(u / 3.0);
		vec3 panel = col * mix(0.3, 1.0, daylight);
		if (h < pf || h > top - 0.7) {
			return panel * (h < pf ? 0.82 : 1.05);
		}
		if (wy < 0.035 || wx < 0.025) {
			return panel * 0.8;                         // the panel joints
		}
		if (mod(bay, 4.0) > 2.5) {
			float hue = hash12(vec2(floor(bay / 4.0), 1.7));
			vec3 accent = hue < 0.33 ? vec3(0.27, 0.43, 0.62) : (hue < 0.66 ? vec3(0.78, 0.6, 0.27) : vec3(0.62, 0.3, 0.24));
			if (wy < 0.4) {
				return srgb_to_linear(accent) * mix(0.3, 1.0, daylight);   // the coloured parapet
			}
			vec3 deep = col * 0.4 * mix(0.35, 1.0, daylight);
			if (lights_on > 0.001 && hash12(vec2(bay, lvl) + 5.9) < 0.18 * lights_on) {
				glow = WARM * 0.55;
			}
			return deep;
		}
		if (wy > 0.3 && wy < 0.78 && wx > 0.12 && wx < 0.88) {
			vec3 pane = mix(srgb_to_linear(vec3(0.17, 0.2, 0.24)), sky * 0.4, 0.3) * mix(0.35, 1.0, daylight);
			if (lights_on > 0.001 && hash12(vec2(bay, lvl) + 3.3) < 0.4 * lights_on) {
				glow = WARM_PALE * 0.9;
				return pane * 0.3;
			}
			return pane;
		}
		return panel;
	} else if (s == S_KEYS) {
		// Piano House on Zajęcza (2026-11-02, spec piano_house.md): white plaster with full-height
		// dark window strips in a keyboard's rhythm, white keys 1.25 m wide and a black one over
		// the joints after the 1st, 2nd, 4th, 5th and 6th of every seven (2 and 3, like an
		// octave). A glazed ground floor, a plain band under the top; warm strips at night.
		float kw = 1.25;
		float x = mod(u, kw * 7.0) / kw;
		float n = floor(x + 0.5);
		float lvl = floor(h / 3.1);
		vec3 plaster = col * mix(0.3, 1.0, daylight);
		if (h < 3.6) {
			if (lights_on > 0.001) {
				glow = WARM_PALE * 0.8;
				return c * 0.4;
			}
			return mix(srgb_to_linear(vec3(0.18, 0.2, 0.23)), sky * 0.4, 0.25) * mix(0.35, 1.0, daylight);
		}
		if (h > top - 0.7) {
			return plaster * 1.04;
		}
		bool black = abs(x - n) < 0.3 && (n == 1.0 || n == 2.0 || n == 4.0 || n == 5.0 || n == 6.0);
		if (black) {
			vec3 key = mix(srgb_to_linear(vec3(0.07, 0.075, 0.085)), sky * 0.3, refl) * mix(0.35, 1.0, daylight);
			if (fract(h / 3.1) < 0.06) {
				return key * 0.6;
			}
			if (lights_on > 0.001 && hash12(vec2(floor(u / kw), lvl) + 6.7) < 0.4 * lights_on) {
				glow = WARM_PALE * 0.9;
				return key * 0.4;
			}
			return key;
		}
		return fract(x) < 0.025 || fract(x) > 0.975 ? plaster * 0.86 : plaster;
	} else if (s == S_FRAME) {
		frame = fract(u / 3.2) < 0.14 || fract(h / 4.4) < 0.1 || h > top - 0.9;
		frame_col = mix(silver, white, 0.5);
		cut = !frame;
		return frame_col;
	}
	if (frame) {
		return frame_col;
	}
	if (h < 4.5) {
		// The lobby: tall clear glass, lit warm at night.
		if (lights_on > 0.001) {
			glow = WARM_PALE * 0.9;
			return c * 0.5;
		}
		return mix(c, srgb_to_linear(vec3(0.2, 0.24, 0.28)), 0.5);
	}
	if (lights_on > 0.001) {
		float whole = hash12(vec2(level, float(s) * 9.1 + top));
		float bay = hash12(vec2(floor(u / 4.8), level) + float(s) * 5.3);
		if (whole < lit * 0.6 * lights_on || bay < lit * 0.4 * lights_on) {
			glow = (hash12(vec2(level, 3.3)) < 0.75 ? COOL : WARM_PALE) * 1.05;
			return c * 0.45;
		}
	}
	return c;
}

// The Palace of Culture's walls: tall windows between stone piers, a pilaster every
// fourth bay, a plinth and a cornice; a few rooms lit at night.
vec3 monument(vec3 col, float u, float h, float top, out vec3 glow) {
	glow = vec3(0.0);
	float fh = 3.6;
	float sp = 2.3;
	float bay = floor(u / sp);
	float fx = fract(u / sp);
	float fy = fract(h / fh);
	if (h < 1.1) {
		return col * 0.78; // plinth
	}
	if (top > 3.0 && h > top - 1.1) {
		return col * (h > top - 0.45 ? 1.16 : 0.9); // cornice and its shadow line
	}
	if (mod(bay, 4.0) < 1.0) {
		return col * 1.07; // pilaster
	}
	if (abs(fx - 0.5) < 0.19 && fy > 0.22 && fy < 0.86) {
		vec2 cell = vec2(bay, floor(h / fh));
		float pane = hash12(cell * 1.7 + 3.1);
		vec3 dark = mix(srgb_to_linear(vec3(0.2, 0.22, 0.27)), srgb_to_linear(vec3(0.42, 0.47, 0.55)), pane * pane);
		if (lights_on > 0.001 && hash12(cell * 0.73 + 11.3) < 0.2 * lights_on) {
			glow = (pane < 0.7 ? WARM_PALE : WARM) * 0.9;
			return dark * 0.4;
		}
		return mix(dark, dark * mix(0.5, 1.0, daylight), 1.0 - daylight);
	}
	if (fy < 0.06) {
		return col * 0.92; // floor band
	}
	return col;
}

// Glass with mullions every `sp` metres and a transom band every `fh`; `lit` is the
// share of the bays glowing at night, `warmth` their tone.
vec3 glass_wall(vec3 col, float u, float h, float top, float sp, float fh, float lit, out vec3 glow) {
	glow = vec3(0.0);
	vec3 sky = srgb_to_linear(sky_colour);
	vec3 deep = srgb_to_linear(vec3(0.16, 0.24, 0.33)) * mix(0.35, 1.0, daylight);
	float refl = clamp(h / max(top, 1.0), 0.0, 1.0) * 0.5 + 0.25 * value_noise(vec2(u * 0.05, h * 0.03));
	vec3 c = mix(col * mix(0.35, 0.75, daylight), mix(deep, sky, refl), 0.62);
	float mullion = abs(fract(u / sp) - 0.5) * sp;
	if (mullion > sp * 0.5 - 0.12 || fract(h / fh) < 0.05) {
		return c * 0.6 + srgb_to_linear(vec3(0.75, 0.77, 0.8)) * 0.25 * daylight;
	}
	if (lights_on > 0.001 && h > 0.6) {
		float level = floor(h / fh);
		float b = hash12(vec2(floor(u / (sp * 3.0)), level) + 41.0);
		if (b < lit * lights_on) {
			glow = mix(COOL, WARM_PALE, step(0.6, hash12(vec2(level, 7.0)))) * 1.05;
			c *= 0.45;
		}
	}
	return c;
}

// Stadion Narodowy's skin: panels of mesh in staggered rows (3.2 x 1.6 m, each row shifted
// by half a panel), thin dark joints between them. Each panel is red or light silver, silver
// more often the higher it is (the Mac photo check, 2026-11-01: about 17 % at the foot, half
// at 60 % of the height, 88 % at the top, never all of one colour), so the flag's colours
// blend up the basket. `top` is the skin's top over the street.
vec3 weave(float u, float h, float top, out vec3 glow) {
	glow = vec3(0.0);
	float pw = 3.2;
	float ph = 1.6;
	float row = floor(h / ph);
	float x = u / pw + 0.5 * mod(row, 2.0);
	float col_i = floor(x);
	float fx = fract(x);
	float fy = fract(h / ph);
	vec3 red = srgb_to_linear(vec3(0.78, 0.12, 0.16));
	vec3 silver = srgb_to_linear(vec3(0.81, 0.82, 0.816));
	vec3 gap = srgb_to_linear(vec3(0.16, 0.15, 0.17));
	float f = clamp(((row + 0.5) * ph / max(top, 1.0) - 0.15) / 0.85, 0.0, 1.0);
	float p_silver = mix(0.17, 0.88, f);
	float n = hash12(vec2(col_i, row) + 0.37);
	vec3 c = n < p_silver ? silver : red;
	// The mesh catches the light unevenly: panel by panel, and darker at its lower edge.
	c *= (0.88 + 0.16 * hash12(vec2(col_i, row) + 5.11)) * (0.9 + 0.1 * fy);
	if (fx < 0.04 || fy < 0.07) {
		c = gap;
	}
	if (lights_on > 0.001) {
		// Lit from inside at night: the red panels glow, the silver ones catch the light.
		glow = (c == gap ? vec3(0.0) : c * (c.r > c.g * 2.0 ? 1.6 : 0.9)) * 0.75;
	}
	return c;
}

// The glass wave (Złote Tarasy): a lattice of diamonds over the roof, the sky in it by
// day, the mall glowing through it at night.
vec3 glass_roof(vec3 col, vec2 xz, out vec3 glow) {
	glow = vec3(0.0);
	vec2 d = vec2(xz.x + xz.y, xz.x - xz.y) / 3.4;
	vec2 f = abs(fract(d) - 0.5);
	bool bar = f.x > 0.43 || f.y > 0.43;
	vec3 sky = srgb_to_linear(sky_colour);
	float n = value_noise(xz * 0.035);
	// The landmarks loop: a golden tint with only a little sky in it (it read as ice before).
	vec3 c = mix(col * mix(0.4, 0.95, daylight), sky, 0.12 + 0.2 * n);
	if (bar) {
		c = mix(c, srgb_to_linear(vec3(0.93, 0.93, 0.9)), 0.7 * daylight + 0.1);
	} else if (lights_on > 0.001) {
		glow = mix(WARM_PALE, vec3(1.0, 0.85, 0.55), n) * (0.55 + 0.35 * hash12(floor(d))) ;
		c *= 0.5;
	}
	return c;
}

// A clock hand at angle `a` (clockwise from twelve), `len` long and `w` wide (dial radii),
// with a short tail: 1 on it, 0 off.
float clock_hand(vec2 q, float a, float len, float w) {
	vec2 d = vec2(sin(a), cos(a));
	float t = clamp(dot(q, d), -0.12, len);
	return step(length(q - d * t), w);
}

// Brick Gothic (the landmarks loop, Old Town): the Cathedral's and the Barbican's walls. Brick
// in slow patches, a stone plinth, a buttress every bay, and tall pointed lancets on walls
// over 9 m (stained glass, faintly lit at night).
vec3 gothic(vec3 col, float u, float h, float top, vec3 wp, out vec3 glow) {
	glow = vec3(0.0);
	vec3 c = col * (0.9 + 0.16 * value_noise(vec2(u * 0.7, h * 1.6) + wp.xz * 0.05));
	if (h < 1.0) {
		return srgb_to_linear(vec3(0.62, 0.6, 0.56)) * mix(0.35, 1.0, daylight);
	}
	float bay = 6.5;
	float fx = fract(u / bay);
	if (fx < 0.14) {
		return c * (h > top - 0.6 ? 1.0 : 0.84); // the buttress's shadowed face
	}
	if (top > 9.0) {
		float hw = 0.75;
		float top_w = top - 2.8;
		float dx = abs(fx - 0.57) * bay;
		float y = h - (top_w - hw * 1.6);
		// A lancet: straight sides, then two arcs meeting in a point.
		bool in_arch = y < 0.0 || dx < hw * (1.0 - (y / (hw * 1.6)) * (y / (hw * 1.6)));
		if (h > 2.6 && h < top_w && dx < hw && in_arch) {
			vec3 pane = mix(srgb_to_linear(vec3(0.16, 0.17, 0.22)), srgb_to_linear(vec3(0.3, 0.33, 0.42)), fract(h * 0.71));
			if (lights_on > 0.001) {
				glow = mix(WARM, srgb_to_linear(vec3(0.5, 0.35, 0.8)), step(0.5, fract(h * 0.37))) * 0.35 * lights_on;
			}
			return pane * mix(0.4, 1.0, daylight);
		}
	}
	return c;
}

vec3 landmark(int mode, float param, vec3 col, vec2 uv, float top, bool wall, vec3 wp, out vec3 glow, out bool cut) {
	glow = vec3(0.0);
	cut = false;
	if (mode == M_MONUMENT) {
		return wall ? monument(col, uv.x, uv.y, top, glow) : col * (0.94 + 0.08 * value_noise(wp.xz * 1.7));
	} else if (mode == M_STONE) {
		float grain = 0.95 + 0.07 * value_noise(wp.xz * 2.1 + wp.y * 1.3);
		if (wall && top > 2.0 && uv.y > top - 0.5) {
			return col * 1.12;
		}
		return col * grain;
	} else if (mode == M_ATTIC) {
		// A parapet: the top part cut into merlons (param = its height / 10 m).
		float height = max(param * 10.0, 0.6);
		if (wall && uv.y > top - height * 0.5 && fract(uv.x / 1.5) > 0.56) {
			cut = true;
		}
		return col * (wall && uv.y > top - 0.2 ? 1.12 : 1.0);
	} else if (mode == M_GOLD) {
		if (param > 0.25) {
			// Polished steel (M_GOLD + 0.5: the Warsaw Spire's columns and mirrored canopy): streaks
			// of sky and ground slide over it, no warm glow at night.
			float streak = value_noise(vec2(wp.y * 0.9 + (wp.x + wp.z) * 0.35, (wp.x - wp.z) * 0.15));
			vec3 mirror = mix(col, srgb_to_linear(sky_colour) * 1.15, 0.4 * smoothstep(0.3, 0.9, streak));
			return mirror * (0.8 + 0.45 * streak) * mix(0.35, 1.0, daylight);
		}
		float sheen = 0.75 + 0.5 * smoothstep(0.2, 1.0, value_noise(vec2(wp.y * 0.6, wp.x + wp.z)));
		if (lights_on > 0.001) {
			glow = col * vec3(1.0, 0.8, 0.45) * 1.25;
		}
		return col * sheen;
	} else if (mode == M_DIAL) {
		// The hands, from the point on the dial (landmarks.gd: x right, y up, in radii, -10).
		vec2 q = uv + 10.0;
		float ink = max(clock_hand(q, clock_hands.x, 0.55, 0.075), clock_hand(q, clock_hands.y, 0.84, 0.05));
		ink = max(ink, step(length(q), 0.09));
		col = mix(col, srgb_to_linear(vec3(0.15, 0.14, 0.16)), ink);
		if (lights_on > 0.001) {
			glow = col * vec3(1.0, 0.92, 0.75) * 1.4 * (1.0 - ink);
		}
		return col;
	} else if (mode == M_WEAVE) {
		return wall ? weave(uv.x, uv.y, top, glow) : col;
	} else if (mode == M_GLASS_ROOF) {
		return glass_roof(col, wp.xz, glow);
	} else if (mode == M_PAVILION) {
		// A glass drum lit from inside: busy at night, nearly every bay.
		if (!wall) {
			return col;
		}
		if (param > 0.6) {
			// param 0.75: the Rotunda (the Mac photo check, 2026-11-01): green-grey panes floor
			// to eave (its silver mullions are geometry), one transom near the top, a little sky
			// in the glass; lit warm from inside at night, nearly every pane.
			float refl = clamp(uv.y / max(top, 1.0), 0.0, 1.0) * 0.22 + 0.14 * value_noise(vec2(uv.x * 0.06, uv.y * 0.05));
			vec3 g = mix(col * mix(0.4, 1.0, daylight), srgb_to_linear(sky_colour) * mix(0.4, 1.0, daylight), refl);
			if (top > 3.0 && uv.y > top - 1.55 && uv.y < top - 1.3) {
				return srgb_to_linear(vec3(0.76, 0.78, 0.8)) * mix(0.3, 1.0, daylight);
			}
			if (lights_on > 0.001) {
				glow = vec3(1.0, 0.86, 0.62) * (0.8 + 0.3 * hash12(vec2(floor(uv.x / 2.07), floor(uv.y / 5.0))));
				g *= 0.4;
			}
			return g;
		}
		vec3 c = glass_wall(col, uv.x, uv.y, top, 1.6, 4.2, 0.0, glow);
		if (lights_on > 0.001 && fract(uv.x / 1.6) > 0.1 && fract(uv.x / 1.6) < 0.9 && fract(uv.y / 4.2) > 0.06) {
			// param 0: warm (the Rotunda), 0.5: cool white (Varso's crown), 0.375: the neon club's
			// pink (SOWA CLUB's glass box, landmarks.gd SOWA_LIT).
			vec3 tone = param > 0.3 && param < 0.45 ? vec3(1.0, 0.58, 0.86) : (param > 0.25 ? vec3(0.78, 0.88, 1.0) : vec3(1.0, 0.86, 0.62));
			glow = tone * (0.9 + 0.35 * hash12(vec2(floor(uv.x / 1.6), floor(uv.y / 4.2))));
			c *= 0.4;
		}
		return c;
	} else if (mode == M_PANE) {
		// One pane of a modelled block: param is the pane's own number, so a pane is lit whole.
		return typed_pane(col, vec2(floor(param * 97.0), floor(param * 311.0)), param, false, glow);
	} else if (mode == M_GLASS) {
		return wall ? glass_wall(col, uv.x, uv.y, top, 1.5, 4.0, 0.34, glow) : col;
	} else if (mode == M_GOTHIC) {
		return wall ? gothic(col, uv.x, uv.y, top, wp, glow) : col * (0.92 + 0.1 * value_noise(wp.xz * 1.3));
	} else if (mode == M_SKIN) {
		if (!wall) {
			return col * (0.94 + 0.08 * value_noise(wp.xz * 1.7));
		}
		return skin(int(param * 16.0 + 0.5), col, uv.x, uv.y, top, glow, cut);
	} else if (mode == M_LAMP) {
		if (lights_on > 0.001) {
			// param 0.5: a neon tube on a metal piece (Cedet's loop): its own colour by day, blue at night.
			glow = (param > 0.25 ? vec3(0.17, 0.34, 1.0) : col) * 2.4;
		}
		return col;
	} else if (mode == M_MEMBRANE) {
		if (lights_on > 0.001) {
			glow = col * vec3(1.0, 0.95, 0.9) * 0.18;
		}
		return col * (0.96 + 0.06 * value_noise(wp.xz * 0.5));
	}
	return col;
}

// Floodlights on the landmark: the dusk loop (2026-10-31, the user's photos) lights it gold
// all the way up (was violet up the tower), a little brighter on the high terraces, with a
// bright edge at the top of every wall, where the next terrace's lamps stand.
vec3 floodlight(vec3 col, float h, float top) {
	vec3 gold = vec3(1.0, 0.7, 0.3);
	float shape = 0.62 + 0.5 * exp(-h / 18.0) + 0.3 * smoothstep(30.0, 140.0, h);
	float edge = smoothstep(top - 9.0, top - 0.5, h) * 0.5;
	if (flood_mode == 0) {
		return col * (gold * shape + vec3(1.0, 0.88, 0.62) * edge) * 1.3;
	}
	// Event colours (F's photos): LED washes read as the light's own colour on the pale stone,
	// so the sandstone's warmth is mostly taken out before tinting.
	vec3 tint = flood_a;
	if (flood_mode == 2) {
		tint = mix(flood_a, flood_b, smoothstep(40.0, 52.0, h));
	} else if (flood_mode == 3) {
		vec2 d = world_pos.xz - floodlit.xy;
		float across = dot(d, vec2(0.9403, -0.3404)) + dot(d, vec2(0.3404, 0.9403)) * 0.35;
		float hue = fract(across / 150.0 + 0.5 + TIME * flood_cycle / 60.0);
		tint = clamp(abs(fract(hue + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		tint = mix(tint, vec3(1.0), 0.22);
	}
	float l = dot(col, vec3(0.3, 0.59, 0.11));
	vec3 stone = mix(col, vec3(l), 0.75);
	return stone * tint * (shape * 1.25 + edge) * 1.45;
}

// The roofs lane (docs/design/roofs.md, RF1): a thin line every `period` metres along x,
// `w` wide, as coverage 0..1. A line thinner than a pixel fades to its average share instead
// of shimmering (the phone's distance views).
float roof_lines(float x, float period, float w) {
	float aa = max(fwidth(x), 0.0001);
	float d = abs(fract(x / period + 0.5) - 0.5) * period;
	float ww = max(w, aa);
	return (1.0 - smoothstep(ww * 0.5, ww * 0.5 + aa, d)) * (w / ww);
}

// RF1: a roof plane's material from its slope (`n`, world), the building's R4 type and seed
// (style.x) and its aerial-photo colour (`srgb`, as the bake gave it): red or orange pitches
// are ceramic tile courses, other pitches sheet metal with standing seams down the slope,
// steep faces zinc; flat roofs are tar-paper strips on the slabs and dark roofs, a light
// membrane with welded seams and gravel on offices and pale roofs, sedum where the photo is
// green. Detail fades out where a pixel is wider than it (fwidth).
vec3 roof_surface(vec3 col, vec3 srgb, vec3 n, float sx) {
	vec2 xz = world_pos.xz;
	col *= 0.94 + 0.08 * value_noise(xz * 1.7) + 0.04 * hash12(floor(xz * 5.0));
	if (n.y < 0.3) {
		return col; // a plant box's side, a parapet, a dormer, a chimney
	}
	int kind = (sx >= 1.0 && sx < 2.0) ? int((sx - 1.0) * 4.0) + 1 : 0;
	float seed = sx >= 1.0 ? fract((sx - 1.0) * 4.0) : fract(sx);
	float red = srgb.r - max(srgb.g, srgb.b);
	float green = srgb.g - max(srgb.r, srgb.b);
	float lum = dot(srgb, vec3(0.3, 0.59, 0.11));
	if (n.y < 0.97) {
		vec2 fall = normalize(n.xz);
		float s = dot(xz, fall) / n.y;              // metres down the slope
		float a = dot(xz, vec2(-fall.y, fall.x));    // metres along the eaves
		float px = fwidth(s);
		if (red > 0.05 && n.y > 0.5) {
			// Ceramic tiles: courses across the slope, each tile's foot casting a shadow on the
			// course below it, staggered joints, a little colour from tile to tile.
			float row = s / 0.36;
			float fr = fract(row);
			float off = mod(floor(row), 2.0) * 0.5;
			float tile = floor(a / 0.26 + off);
			float shade = mix(0.62, 1.04, smoothstep(0.0, 0.3, fr)) * (1.0 - 0.18 * roof_lines(a + off * 0.26, 0.26, 0.03));
			shade *= 0.94 + 0.12 * hash12(vec2(floor(row), tile));
			col *= mix(0.9, shade, 1.0 - smoothstep(0.1, 0.24, px));
		} else {
			// Sheet metal (blacha), or zinc on a steep mansard face: standing seams down the
			// slope, each sheet its own shade of paint or patina, rain streaks below the ridge.
			bool steep = n.y < 0.62;
			float sheet = steep ? 0.45 : 0.6;
			float seam = roof_lines(a, sheet, 0.05);
			float streak = value_noise(vec2(a * 2.3, s * 0.22) + seed * 17.0);
			float shade = (0.92 + 0.14 * hash12(vec2(floor(a / sheet), seed * 97.0))) * (0.93 + 0.1 * streak);
			shade += seam * 0.4 - roof_lines(a + 0.07, sheet, 0.06) * 0.25;
			col *= mix(1.0, shade, 1.0 - smoothstep(0.15, 0.35, px));
			if (steep && red < 0.05) {
				col = mix(col, srgb_to_linear(vec3(0.5, 0.52, 0.54)) * (0.9 + 0.1 * streak), 0.15);
			}
		}
		return col;
	}
	float px = fwidth(xz.x) + fwidth(xz.y);
	float detail = 1.0 - smoothstep(0.2, 0.45, px);
	// Flat roofs lie along one of the map's axes, picked by the building's seed.
	vec2 q = seed < 0.5 ? xz : xz.yx;
	if (green > 0.025) {
		// Sedum and grass: clumps of green with a few rust-red patches and bare gravel.
		float clump = value_noise(xz * 1.3 + seed * 11.0) * 0.6 + value_noise(xz * 4.1) * 0.4;
		vec3 leaf = mix(col * vec3(0.8, 1.05, 0.7), col * vec3(1.15, 1.2, 0.85), clump);
		leaf = mix(leaf, col * vec3(1.25, 0.75, 0.6), smoothstep(0.78, 0.9, value_noise(xz * 0.7 + 3.1)) * 0.6);
		return mix(col, leaf, 0.5 + 0.5 * detail);
	}
	if (kind == T_SLAB || (kind != T_OFFICE && lum < 0.3)) {
		// Tar paper (papa): one-metre strips with a dark lapped edge, patched here and there,
		// darker where the water stands.
		float lap = roof_lines(q.x, 1.0, 0.08);
		float patch = step(0.86, hash12(vec2(floor(q.x), floor(q.y / 3.0)) + seed * 41.0));
		float shade = (1.0 - 0.3 * lap) * (1.0 - 0.12 * patch) * (1.0 - 0.1 * smoothstep(0.55, 0.8, value_noise(xz * 0.3)));
		return col * mix(0.95, shade, detail);
	}
	if (kind == T_OFFICE || lum > 0.42) {
		// A membrane: two-metre sheets with welded seams, the odd pond stain, gravel ballast.
		float weld = roof_lines(q.x, 2.0, 0.06);
		float stain = smoothstep(0.6, 0.85, value_noise(xz * 0.22 + seed * 5.0));
		float stones = hash12(floor(xz * 9.0));
		float shade = (1.0 + 0.2 * weld) * (1.0 - 0.1 * stain) * (0.94 + 0.1 * stones);
		return col * mix(1.0, shade, detail);
	}
	// Gravel over concrete slabs: a grid of pavers, a fine speckle.
	float joints = max(roof_lines(q.x, 1.2, 0.04), roof_lines(q.y, 1.2, 0.04));
	return col * mix(0.97, (1.0 - 0.18 * joints) * (0.93 + 0.12 * hash12(floor(xz * 7.0))), detail);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	vec3 glow = vec3(0.0);
	// Roofs and windowless solids carry UV (-1, -1). The look loop (2026-10-28): a LoD2 wall's
	// UV.x is its position along the wall's tangent in map metres (tools/bake_gugik.py), which
	// is negative for about half of them, so `UV.x >= 0` alone drew those walls as blank
	// roofs (no windows, no shop band, solid navy at night); their UV.y (metres up) never is.
	bool walls = UV.x >= 0.0 || UV.y > -0.5;
	int mode = style.x >= 2.0 ? int(style.x) : 0;
	if (mode > 0) {
		bool cut;
		col = landmark(mode, fract(style.x), col, UV, style.y, walls, world_pos, glow, cut);
		if (cut) {
			discard;
		}
	} else if (!walls) {
		// Roofs: their material (RF1, docs/design/roofs.md).
		col = roof_surface(col, COLOR.rgb, normalize(world_n), style.x);
	} else if (windows > 0.5 && style.x >= 1.0 && COLOR.a >= 0.75) {
		float f = (style.x - 1.0) * 4.0;
		col = typed_facade(int(f) + 1, col, UV.x, UV.y, fract(f), style.y, glow);
	} else if (windows > 0.5) {
		col = facade(col, UV.x, UV.y, style.x, style.y, COLOR.a < 0.75, glow);
	}
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
	if (mode == M_GOLD) {
		ROUGHNESS = 0.35;
		METALLIC = 0.55;
		SPECULAR = 0.6;
	}

	if (lights_on > 0.001 && (walls || mode > 0)) {
		if (walls) {
			// Street lamps light the lower floors facing them: sample the pools a step
			// out from the wall, so a wall only catches the lamps on its own side.
			vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
			vec2 out_dir = wn.xz / max(length(wn.xz), 0.001);
			vec3 lamp = lamp_light(world_pos.xz + out_dir * 1.2);
			glow += col * lamp * (1.0 - smoothstep(0.5, 12.0, UV.y)) * 1.6;
		}
		// The Palace of Culture, floodlit: its sandstone near its centre.
		vec3 c = COLOR.rgb / max(COLOR.r, 0.001);
		bool stone = mode == M_MONUMENT || mode == M_STONE || mode == M_ATTIC
				|| (mode == 0 && COLOR.r > 0.6 && abs(c.g - 0.905) < 0.05 && abs(c.b - 0.72) < 0.07);
		if (floodlit.z > 0.0 && stone && walls && distance(world_pos.xz, floodlit.xy) < floodlit.z) {
			glow += floodlight(col, UV.y, style.y);
		}
		EMISSION = glow * lights_on;
	}

	if (!IN_SHADOW_PASS) {
		if (ghost_debug == 1) {
			ALBEDO = vec3(0.0);
			EMISSION = vec3(0.0, 0.6, 0.0);
		}
		float d = length(VERTEX.xy - car_view.xy);
		ivec2 p = ivec2(FRAGCOORD.xy) % 4;
		float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
		if (VERTEX.z > car_view.z + 1.0 && d < fade_radius) {
			float fade = smoothstep(fade_radius, fade_radius * 0.5, d);
			if (ghost_debug == 1 && fade > 0.5) {
				EMISSION = vec3(0.6, 0.0, 0.6);
			} else if (ghost_debug != 1 && threshold < fade * 0.92) {
				discard;
			}
		}
		// Occlusion ghost (ghost.gdshaderinc): whatever stands on the camera's side of the
		// car and covers its surroundings on screen keeps only a thin dither of its pixels
		// (ghost_keep) in the core, more towards a soft rim, so the street shows through,
		// a tower keeps its shape and nothing above the cut floats. Every fragment goes,
		// near walls, far walls and roofs alike; looking into a cut building, its inner
		// faces go too (a little past the car, where the building runs on beyond it).
		float fade = ghost_fade(VERTEX.xy, world_pos.xz);
		if (!FRONT_FACING) {
			fade = ghost_fade(VERTEX.xy, world_pos.xz - occluder.zw * 8.0);
		}
		if (ghost_debug == 1) {
			if (fade > 0.5) {
				ALBEDO = vec3(0.0);
				EMISSION = vec3(0.6, 0.0, 0.6);
			}
		} else if (ghost_debug == 2) {
			if (fade > 0.01) {
				discard;
			}
		} else if (threshold < fade * (1.0 - ghost_keep)) {
			discard;
		}
		// Nothing glows inside the ghost (the look loop; loop 1 kept 30 % of it): the lit
		// windows, shop fronts and neon tubes of the pixels it keeps sparkled round the car.
		EMISSION *= 1.0 - fade;
		if (!FRONT_FACING && ghost_debug == 0 && ghost_region(VERTEX.xy) > 0.01) {
			// Looking into a cut building: its inner faces are unlit, flat, a step darker than
			// the street (they were lit with flipped normals, windows and floodlights: the
			// Palace's cut tower glowed gold inside at night).
			ALBEDO = vec3(0.0);
			SPECULAR = 0.0;
			EMISSION = srgb_to_linear(mix(INNER_NIGHT, INNER_DAY, daylight));
		}
	}
}
