shader_type canvas_item;
render_mode blend_mix;

// Low frost bank in place of the tutorial's brown dust.

void fragment() {
	vec2 p = UV - vec2(0.5);
	float dist = length(p) * 2.0;
	float body = smoothstep(1.0, 0.12, dist);
	vec3 mist = mix(vec3(0.58, 0.82, 0.98), vec3(0.96, 0.99, 1.0), smoothstep(0.65, 0.0, dist));
	float hot = max(mist.r, max(mist.g, mist.b));
	mist = mix(mist, vec3(1.0), smoothstep(0.90, 1.0, hot));
	COLOR = vec4(mist, body * COLOR.a * 0.40);
}
