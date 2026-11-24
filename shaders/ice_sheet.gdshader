shader_type canvas_item;
render_mode blend_mix;

// Frost trail and cold mist. Shared texture, straight alpha.
// Values above 1 are pulled back. This viewport has no bloom.

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
	vec3 col = ice_tonemap(tex.rgb * v_col.rgb);
	COLOR = vec4(col, tex.a * v_col.a);
}
