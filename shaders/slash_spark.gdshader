shader_type canvas_item;
render_mode blend_add;

// Thin streak thrown off the crescent's foot. COLOR carries the life ramp
// (white, then yellow, then gone). Tonemapped viewport, no bloom.

void fragment() {
	vec2 p = UV - vec2(0.5);
	float across = abs(p.x) * 2.0;
	float along = abs(p.y) * 2.0;
	float body = exp(-across * across * 22.0) * (1.0 - smoothstep(0.04, 1.0, along));
	float core = exp(-across * across * 70.0) * (1.0 - smoothstep(0.0, 0.8, along));
	float mask = clamp(body * 0.7 + core, 0.0, 1.0) * clamp(COLOR.a, 0.0, 1.0);
	if (mask < 0.03) {
		discard;
	}
	vec3 rgb = mix(COLOR.rgb, vec3(1.0, 0.98, 0.94), clamp(core * 1.5, 0.0, 1.0));
	COLOR = vec4(rgb, mask);
}
