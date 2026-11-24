shader_type canvas_item;
render_mode blend_mix;

// Floor cracks from the earth tutorial, drawn as a pale ice sheet.
// shown fades the mark in with its spikes and out when they sink.

uniform float shown = 0.0;
uniform float seed = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float x = UV.x;
	float y = UV.y;
	float sheet = smoothstep(0.0, 0.14, y) * smoothstep(1.0, 0.42, y);
	float cracks = 0.0;
	for (int i = 0; i < 5; i++) {
		float fx = hash21(vec2(seed, float(i) * 3.1));
		float jag = hash21(vec2(float(i), seed)) - 0.5;
		float d = abs(x - (fx + jag * y * 0.38));
		cracks = max(cracks, smoothstep(0.03, 0.0, d));
		float branch = abs(y - (0.32 + hash21(vec2(seed + 2.0, float(i))) * 0.45));
		float along = smoothstep(0.14, 0.0, abs(x - fx));
		cracks = max(cracks, smoothstep(0.045, 0.0, branch) * along);
	}
	vec3 frost = vec3(0.52, 0.82, 0.98);
	vec3 line = vec3(0.94, 0.99, 1.0);
	vec3 ice = mix(frost, line, cracks);
	float hot = max(ice.r, max(ice.g, ice.b));
	ice = mix(ice, vec3(1.0), smoothstep(0.84, 0.99, hot) * cracks);
	float alpha = shown * (sheet * 0.32 + cracks * 0.78);
	COLOR = vec4(ice, alpha);
}
