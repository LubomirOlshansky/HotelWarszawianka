shader_type spatial;
// The Warsaw Spire's LED ticker (spire_motion.gd): a band of LEDs round the crown with the parody
// phone adverts running along it. UV is in metres: x round the ring, y up the band. The text is one
// small texture (pixel_font.gd, one texel an LED) scrolled here by TIME, so nothing runs per frame
// in script. Unshaded: lit by day, past the bloom threshold at night.

render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

global uniform float lights_on;

uniform sampler2D words : filter_nearest, repeat_enable;
uniform vec2 words_px = vec2(512.0, 10.0);  // the text in LEDs
uniform vec2 px_m = vec2(0.5, 0.5);         // metres per LED, sideways and up
uniform float band = 5.6;                   // the band's height in metres
uniform float speed = 7.0;                  // metres a second

void fragment() {
	// The rows: the text's ten LED rows centred in the band, a dark frame above and below.
	float margin = (band - words_px.y * px_m.y) * 0.5;
	float row = (band - margin - UV.y) / px_m.y;
	float col = (UV.x + TIME * speed) / px_m.x;
	vec3 led = vec3(0.0);
	if (row >= 0.0 && row < words_px.y) {
		led = texture(words, vec2(fract(col / words_px.x), (floor(row) + 0.5) / words_px.y)).rgb;
	}
	// Each LED a round dot on the black panel; unlit dots faintly grey.
	vec2 cell = vec2(fract(col), fract(row)) - 0.5;
	float dot = 1.0 - smoothstep(0.3, 0.45, length(cell));
	vec3 panel = vec3(0.025, 0.03, 0.04);
	vec3 off = vec3(0.04, 0.045, 0.05) * dot;
	float edge = step(UV.y, 0.12) + step(band - 0.12, UV.y);
	vec3 c = panel + off + led * dot * (1.2 + 1.6 * lights_on);
	c = mix(c, vec3(0.35, 0.38, 0.42), clamp(edge, 0.0, 1.0));
	ALBEDO = c;
}
