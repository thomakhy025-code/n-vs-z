shader_type canvas_item;
render_mode blend_add;

// One additive billboard. The tutorial flare is (2, 0.6, 0.3), big at
// the first instant, then small. The same shader draws the late embers
// with a tighter falloff. Tonemapped: this viewport has no bloom.

uniform float glow_pow = 1.35;
uniform float core_k = 3.1;
uniform vec3 flash_color = vec3(2.0, 0.6, 0.3);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float dist = length(p);
	float glow = pow(clamp(1.0 - dist, 0.0, 1.0), glow_pow);
	float core = exp(-dist * dist * core_k);
	float round_end = 1.0 - smoothstep(0.55, 0.9, dist);
	float mask = clamp(glow * 0.8 + core, 0.0, 1.0) * round_end;
	mask *= clamp(COLOR.a, 0.0, 1.0);
	vec3 hdr = flash_color;
	vec3 tint = hdr / (vec3(1.0) + hdr);
	vec3 rgb = mix(tint, vec3(1.0, 0.98, 0.92), clamp(core * 1.2, 0.0, 1.0));
	if (mask < 0.02) {
		discard;
	}
	COLOR = vec4(rgb, mask);
}
