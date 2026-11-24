shader_type canvas_item;
render_mode blend_mix;

// Side-view crystal. Three cel bands, a hard rim, and diagonal streaks.
// Vertex color: r is the streak seed, g < 0.5 draws the ink outline,
// a is the coverage. The shatter flash is above 1, then pulled back
// into range. This viewport has no bloom.

uniform float ice_time = 0.0;
uniform float ice_flash = 0.0;
uniform float rim_gain = 1.15;

varying vec4 v_col;
varying vec2 v_uv;

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
	v_uv = UV;
}

void fragment() {
	if (v_col.g < 0.5) {
		COLOR = vec4(0.02353, 0.07059, 0.14902, v_col.a);
	} else {
		vec3 shadow_c = vec3(0.04706, 0.23137, 0.45882);
		vec3 mid_c = vec3(0.13333, 0.72157, 0.94118);
		vec3 lit_c = vec3(0.90980, 0.98039, 1.0);
		vec3 rim_c = vec3(0.64706, 0.95294, 0.98824);
		float across = clamp(v_uv.x, 0.0, 1.0);
		float up = clamp(v_uv.y, 0.0, 1.0);
		float cel = clamp(0.20 + across * 0.58 + up * 0.24, 0.0, 1.0);
		vec3 base = shadow_c;
		float band1 = smoothstep(0.42, 0.45, cel);
		float band2 = smoothstep(0.72, 0.75, cel);
		base = mix(base, mid_c, band1);
		base = mix(base, lit_c, band2);
		float diag = across * 2.4 + up * 3.8 + v_col.r * 6.28318;
		float streak1 = smoothstep(0.91, 0.94, sin(diag));
		float streak2 = smoothstep(0.95, 0.98, sin(diag * 2.1 + 1.3));
		float spec = clamp(streak1 * 0.65 + streak2 * 0.45, 0.0, 1.0) * step(0.48, cel);
		base = mix(base, vec3(1.0), spec * 0.72);
		float edge = min(across, 1.0 - across);
		float fres = smoothstep(0.16, 0.0, edge);
		vec3 col = base + rim_c * fres * rim_gain;
		float pulse = 0.06 * sin(ice_time * 4.5 + v_col.r * 5.0) * up;
		col += mid_c * pulse;
		float foot = smoothstep(0.18, 0.0, up);
		col = mix(col, shadow_c, 0.36 * foot);
		col = mix(col, vec3(1.45, 1.55, 1.65), ice_flash);
		COLOR = vec4(ice_tonemap(col), 0.96 * v_col.a);
	}
}
