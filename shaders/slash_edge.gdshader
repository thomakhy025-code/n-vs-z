shader_type canvas_item;
render_mode blend_add;

// Crisp cutting edge over the crescent. White stays white, gold stays gold.
// Tonemapped because the viewport has no bloom.

void fragment() {
	float white = smoothstep(0.82, 0.97, min(COLOR.r, COLOR.g));
	vec3 warm = vec3(3.4, 1.35, 0.12);
	vec3 hot = vec3(8.0, 7.4, 6.2);
	vec3 hdr = mix(warm, hot, white);
	vec3 rgb = hdr / (vec3(1.0) + hdr);
	rgb = mix(rgb, vec3(1.0, 0.99, 0.97), white);
	COLOR = vec4(rgb, COLOR.a);
}
