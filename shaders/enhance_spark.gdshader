shader_type canvas_item;
render_mode blend_add;

// The small trails beside the blade. Tonemapped: this viewport has no bloom.

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float dist = length(p);
	float core = exp(-dist * dist * 5.5);
	float mask = pow(clamp(1.0 - dist, 0.0, 1.0), 1.7) * COLOR.a;
	if (mask < 0.03) {
		discard;
	}
	vec3 hdr = vec3(2.5, 1.2, 0.32) * (0.4 + core * 1.35);
	vec3 mapped = hdr / (vec3(1.0) + hdr);
	COLOR = vec4(mapped, clamp(mask, 0.0, 0.9));
}
