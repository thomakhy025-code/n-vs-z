shader_type canvas_item;
render_mode blend_add;

// Flame tongue from the weapon-aura tutorial, drawn on the particle quad.
// Noise crawls toward the tip. No bloom in this viewport, so the core
// is tonemapped. COLOR is the particle ramp (yellow, then orange, then out).

uniform float heat = 2.2;
uniform float cap = 0.78;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	float v = UV.y;
	float n = value_noise(vec2(UV.x * 3.2, UV.y * 2.4 - TIME * 1.35));
	float n2 = value_noise(vec2(UV.x * 6.4 + 1.7, UV.y * 3.6 - TIME * 2.1));
	float sway = (n - 0.5) * 0.55 * (1.0 - v);
	float u = (UV.x - 0.5) * 2.0 - sway;
	float halfw = mix(1.2, 0.22, pow(v, 0.62));
	halfw *= mix(0.7, 1.05, sin(v * 3.14159));
	float edge = abs(u) / max(halfw, 0.05);
	edge += (n2 - 0.55) * 0.28;
	float mask = pow(clamp(1.0 - edge, 0.0, 1.0), 1.05);
	mask *= smoothstep(0.0, 0.07, v);
	mask *= 1.0 - smoothstep(0.92, 1.0, v);
	float core = pow(clamp(1.0 - edge * 1.35, 0.0, 1.0), 1.25);
	core *= pow(clamp(v, 0.0, 1.0), 0.28);
	mask *= COLOR.a * mix(0.72, 1.0, n2);
	if (mask < 0.03) {
		discard;
	}
	vec3 hdr = COLOR.rgb * (0.85 + heat * core);
	hdr += vec3(0.75, 0.48, 0.14) * core * core * heat;
	vec3 mapped = hdr / (vec3(1.0) + hdr);
	COLOR = vec4(mapped, clamp(mask, 0.0, cap));
}
