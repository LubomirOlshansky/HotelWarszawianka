// Shared by the city shaders.

// Android (Adreno 6xx, e.g. the Nothing Phone 1's 642L): its Vulkan driver fails to link a
// pipeline ("Failed to link shaders", VkResult -13) once a lit shader's fragment control flow is
// too big, and the mesh then doesn't draw at all (scripts/gpu_quirks.gd). Every function call
// counts there (the driver inlines it), so the three helpers that building.gdshader and
// ground.gdshader call hundreds of times are macros, not functions: the same arithmetic in the
// same order, written out in one expression (the compiler folds the repeats).
// tools/check_shader_budget.gd keeps every shader under the limit. Readable forms:
//   srgb_to_linear(c): mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)))
//   hash12(p):         p3 = fract(p.xyx * 0.1031); p3 += dot(p3, p3.yzx + 33.33); fract((p3.x + p3.y) * p3.z)
//   value_noise(p):    i = floor(p), f = fract(p), u = f * f * (3 - 2f); the four corner hashes mixed by u
// Each macro is flat (no macro inside another's body but hash12 in value_noise): Godot's
// preprocessor gives up on a line whose nested expansions run too deep.

// Vertex colours are authored in sRGB; lighting needs them linear.
#define srgb_to_linear(c) mix(pow(((c) + 0.055) / 1.055, vec3(2.4)), (c) / 12.92, lessThan((c), vec3(0.04045)))

#define hash12(p) fract(((fract(vec3((p).xyx) * 0.1031).x + dot(fract(vec3((p).xyx) * 0.1031), fract(vec3((p).xyx) * 0.1031).yzx + 33.33)) + (fract(vec3((p).xyx) * 0.1031).y + dot(fract(vec3((p).xyx) * 0.1031), fract(vec3((p).xyx) * 0.1031).yzx + 33.33))) * (fract(vec3((p).xyx) * 0.1031).z + dot(fract(vec3((p).xyx) * 0.1031), fract(vec3((p).xyx) * 0.1031).yzx + 33.33)))

#define value_noise(p) mix(mix(hash12(floor(p)), hash12(floor(p) + vec2(1.0, 0.0)), (fract(p) * fract(p) * (3.0 - 2.0 * fract(p))).x), mix(hash12(floor(p) + vec2(0.0, 1.0)), hash12(floor(p) + vec2(1.0, 1.0)), (fract(p) * fract(p) * (3.0 - 2.0 * fract(p))).x), (fract(p) * fract(p) * (3.0 - 2.0 * fract(p))).y)

// Soft cloud shadows drifting slowly across the city: 0 in sun, up to 1 under a cloud.
float cloud_shadow(vec2 xz, float time) {
	vec2 p = xz / 220.0 + vec2(time * 0.010, time * 0.004);
	float n = value_noise(p) * 0.65 + value_noise(p * 2.7 + 7.3) * 0.35;
	return smoothstep(0.56, 0.74, n);
}
