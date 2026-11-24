shader_type canvas_item;
render_mode blend_add;

// Sharp inner edge of the crescent. The polyline color is already the
// gold or white stroke. Tonemapped because the viewport has no bloom.

void fragment() {
	vec3 hdr = COLOR.rgb * vec3(2.15, 1.55, 0.55);
	float hot = clamp((COLOR.g - 0.85) * 8.0, 0.0, 1.0);
	hdr = mix(hdr, vec3(2.7, 2.45, 1.9), hot);
	vec3 rgb = hdr / (vec3(1.0) + hdr);
	float alpha = COLOR.a;
	if (alpha < 0.02) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
