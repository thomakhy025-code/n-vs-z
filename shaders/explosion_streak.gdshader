shader_type canvas_item;
render_mode blend_add;

// Four motion-blurred strokes share one atlas. Hue picks the slice.
// The quad is shifted so the thick end sits on the particle and the
// tip points along velocity (align Y). HDR (4, 0.8, 0.2) is tonemapped
// because this viewport has no bloom. Additive so the strokes stay
// yellow on the dark road.

uniform sampler2D atlas : repeat_disable, filter_linear;
uniform float base_shift = 90.0;

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

void vertex() {
	VERTEX.y += base_shift;
}

void fragment() {
	float slice = clamp(floor(hue_of(COLOR.rgb) * 4.0), 0.0, 3.0);
	vec2 uv = vec2(clamp(UV.x, 0.001, 0.999) * 0.25 + slice * 0.25, UV.y);
	float mark = texture(atlas, uv).a;
	float fade = clamp(COLOR.a, 0.0, 1.0);
	float spine = pow(clamp(mark, 0.0, 1.0), 2.4);
	vec3 rgb = mix(vec3(1.0, 0.42, 0.05), vec3(1.0, 0.92, 0.55), spine);
	float alpha = mark * fade;
	if (alpha < 0.03) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
