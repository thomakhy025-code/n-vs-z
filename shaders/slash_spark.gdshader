shader_type canvas_item;
render_mode blend_add;

// Short yellow-white streak. Tonemapped: the fight viewport has no bloom.

uniform vec3 flash_color = vec3(2.5, 1.65, 0.42);

void fragment() {
	vec2 p = UV - vec2(0.5);
	float across = abs(p.x) * 2.0;
	float along = abs(p.y) * 2.0;
	float body = exp(-across * across * 7.0) * (1.0 - smoothstep(0.12, 1.0, along));
	float core = exp(-across * across * 24.0) * exp(-along * along * 2.6);
	float mask = clamp(body * 0.8 + core, 0.0, 1.0) * clamp(COLOR.a, 0.0, 1.0);
	if (mask < 0.03) {
		discard;
	}
	vec3 tint = flash_color / (vec3(1.0) + flash_color);
	vec3 rgb = mix(tint, vec3(1.0, 0.98, 0.9), clamp(core * 1.35, 0.0, 1.0));
	COLOR = vec4(rgb, mask);
}
