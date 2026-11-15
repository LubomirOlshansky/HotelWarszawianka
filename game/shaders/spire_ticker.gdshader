shader_type spatial;
// The Warsaw Spire's lights (spire_motion.gd), one mesh: the LED band round the top of the glass
// with the GeoBent advert and KOCHAM WARSZAWĘ running along it, and the night's lines of light
// (the slab edges, the fins, the rim, the drum). The vertex colour's alpha picks the part: 0 the LED
// band (UV in metres: x round the ring, y up the band; the text is one small texture,
// pixel_font.gd, one texel an LED, scrolled here by TIME, so nothing runs per frame in script),
// 0.5 a line (rgb its light, UV.y its brightness). Unshaded: past the bloom threshold at night.
// By day the unlit LEDs and the lines are not drawn: the glass shows through, as on the real tower.

render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

global uniform float lights_on;

uniform sampler2D words : filter_nearest, repeat_enable;
uniform vec2 words_px = vec2(512.0, 10.0);  // the text in LEDs
uniform vec2 px_m = vec2(1.2, 1.2);         // metres per LED, sideways and up
uniform float band = 17.5;                  // the band's height in metres
uniform float speed = 9.0;                  // metres a second

void fragment() {
	if (COLOR.a > 0.25) {
		// A line: lit at night only.
		if (lights_on < 0.05) {
			discard;
		}
		ALBEDO = COLOR.rgb * UV.y * (0.5 + 1.0 * lights_on);
	} else {
		// The rows: the text's ten LED rows centred in the band.
		float margin = (band - words_px.y * px_m.y) * 0.5;
		float row = (band - margin - UV.y) / px_m.y;
		float col = (UV.x + TIME * speed) / px_m.x;
		vec3 led = vec3(0.0);
		if (row >= 0.0 && row < words_px.y) {
			led = texture(words, vec2(fract(col / words_px.x), (floor(row) + 0.5) / words_px.y)).rgb;
		}
		// Each LED a round dot (the gaps only when an LED is over four pixels wide on screen, so
		// far off the letters don't shimmer). By day the dark LEDs and the gaps are not drawn: the
		// glass shows through. At night they are the dark glass behind the sign, so the letters
		// stand clear of the lit offices, as on the real tower.
		vec2 cell = vec2(fract(col), fract(row)) - 0.5;
		float lit = max(led.r, max(led.g, led.b));
		bool gap = length(cell) > 0.42 && fwidth(col) < 0.25;
		bool dark = lit < 0.05 || gap;
		if (dark && lights_on < 0.05) {
			discard;
		}
		vec3 glass = vec3(0.006, 0.012, 0.035);
		ALBEDO = dark ? glass : led * (0.55 + 0.5 * lights_on);
	}
}
