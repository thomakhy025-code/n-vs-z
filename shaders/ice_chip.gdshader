shader_type canvas_item;
render_mode blend_mix;

// Cell-fracture chip from the earth tutorial, cut as a pale ice splinter.
// The particle quad is white. The shard shape lives in this shader.

void fragment() {
	vec2 p = UV;
	float left = mix(0.20, 0.05, p.y);
	float right = mix(0.58, 0.96, p.y);
	float in_shard = step(left, p.x) * step(p.x, right);
	in_shard *= step(0.05, p.y) * step(p.y, 0.97);
	float notch = step(0.58, p.y) * step(p.x, mix(0.16, 0.42, p.y));
	in_shard *= 1.0 - notch;
	if (in_shard < 0.5) {
		COLOR = vec4(0.0);
	} else {
		float edge = min(min(p.x - left, right - p.x), min(p.y - 0.05, 0.97 - p.y));
		float rim = 1.0 - smoothstep(0.0, 0.14, edge);
		vec3 cold = vec3(0.18, 0.50, 0.88);
		vec3 pale = vec3(0.84, 0.96, 1.0);
		vec3 ice = mix(cold, pale, smoothstep(0.0, 0.65, rim));
		ice = mix(ice, vec3(1.0), smoothstep(0.4, 1.0, rim));
		float hot = max(ice.r, max(ice.g, ice.b));
		ice = mix(ice, vec3(1.0), smoothstep(0.86, 1.0, hot));
		COLOR = vec4(ice, COLOR.a);
	}
}
