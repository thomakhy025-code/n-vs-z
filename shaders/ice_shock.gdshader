shader_type canvas_item;
render_mode blend_add;

// Jagged frost ring at the shatter. Vertex color carries the ice bands.
// Nothing here is above 1, and the tonemap keeps it that way.

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
	if (v_col.a < 0.02) {
		discard;
	}
	COLOR = vec4(ice_tonemap(v_col.rgb), v_col.a);
}
