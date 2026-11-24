shader_type canvas_item;
render_mode blend_add;

// Rune and four-point sparkles. Additive, then tonemapped so the
// white core stays pale instead of clipping. No bloom on this viewport.

varying vec4 v_col;

vec3 ice_tonemap(vec3 c) {
	float peak = max(c.r, max(c.g, c.b));
	if (peak > 1.0) {
		c /= peak;
		c = mix(c, vec3(1.0), 0.82);
	}
	return clamp(c, vec3(0.0), vec3(1.0));
}

void vertex() {
	v_col = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float mask = tex.a * v_col.a;
	if (mask < 0.02) {
		discard;
	}
	vec3 col = ice_tonemap(tex.rgb * v_col.rgb);
	COLOR = vec4(col, mask);
}
