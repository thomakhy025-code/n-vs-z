shader_type canvas_item;
render_mode blend_mix;

// Four streak drawings share one atlas, side by side.
// Particle hue picks the slice. Particle alpha fades the quad.
// HDR orange is tonemapped because this viewport has no bloom.

uniform sampler2D atlas : repeat_disable, filter_linear;

float hue_of(vec3 c) {
	float maxc = max(c.r, max(c.g, c.b));
	float minc = min(c.r, min(c.g, c.b));
	float delta = maxc - minc;
	if (delta < 0.001) {
		return 0.0;
	}
	float h = 0.0;
	if (maxc == c.r) {
		h = mod((c.g - c.b) / delta, 6.0);
	} else if (maxc == c.g) {
		h = (c.b - c.r) / delta + 2.0;
	} else {
		h = (c.r - c.g) / delta + 4.0;
	}
	return fract(h / 6.0);
}

void fragment() {
	float slice = clamp(floor(hue_of(COLOR.rgb) * 4.0), 0.0, 3.0);
	vec2 uv = vec2(clamp(UV.x, 0.001, 0.999) * 0.25 + slice * 0.25, UV.y);
	float mark = texture(atlas, uv).a;
	float fade = clamp(COLOR.a, 0.0, 1.0);
	vec3 hdr = vec3(4.0, 0.85, 0.22);
	vec3 hot = hdr / (1.0 + hdr);
	float core = pow(clamp(mark, 0.0, 1.0), 0.55);
	vec3 rgb = mix(hot, vec3(1.0, 0.97, 0.9), core);
	float alpha = mark * fade;
	if (alpha < 0.04) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
