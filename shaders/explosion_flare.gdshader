shader_type canvas_item;
render_mode blend_add;

// One additive billboard. Color is the tutorial's flash (2, 0.6, 0.3),
// folded so the core reads white-hot without a glow post process.

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float dist = length(p);
	float glow = pow(clamp(1.0 - dist, 0.0, 1.0), 1.55);
	float core = exp(-dist * dist * 4.5);
	float mask = clamp(glow * 0.85 + core, 0.0, 1.0);
	vec3 hdr = vec3(2.0, 0.6, 0.3);
	vec3 tint = hdr / (1.0 + hdr);
	vec3 rgb = mix(tint, vec3(1.0, 0.97, 0.9), core);
	COLOR = vec4(rgb, mask);
}
