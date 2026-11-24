shader_type canvas_item;
render_mode blend_mix;

// Four painted spikes share one atlas. Particle hue picks a slice
// (UV.x * 0.25 + offset). Alpha smoothsteps the spike away.
uniform sampler2D atlas : repeat_disable, filter_linear;

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
	float pick = fract(COLOR.r * 12.989 + COLOR.g * 78.233 + COLOR.b * 37.719);
	float slice = floor(clamp(pick, 0.0, 0.999) * 4.0) * 0.25;
	vec2 uv = vec2(clamp(UV.x, 0.0, 1.0) * 0.25 + slice, UV.y);
	float painted = texture(atlas, uv).a;
	float across = abs(UV.x - 0.5) * 2.0;
	float taper = mix(1.05, 0.22, UV.y);
	float cone = 1.0 - smoothstep(taper * 0.45, taper, across);
	float tip = 1.0 - smoothstep(0.72, 1.0, UV.y);
	float grain = mix(0.45, 1.0, painted);
	float mark = grain * cone * tip;
	float veil = value_noise(UV * 5.0 + vec2(TIME * 0.35, 0.2));
	float dissolve = clamp(COLOR.a, 0.0, 1.0);
	float remain = smoothstep(dissolve, dissolve + 0.2, veil);
	vec3 hdr = vec3(4.0, 0.8, 0.2);
	vec3 tint = hdr / (1.0 + hdr);
	float heat = pow(clamp(mark, 0.0, 1.0), 0.55);
	vec3 rgb = mix(vec3(1.0, 0.62, 0.16), vec3(1.0, 0.98, 0.9), heat);
	float alpha = mark * remain;
	if (alpha < 0.04) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
