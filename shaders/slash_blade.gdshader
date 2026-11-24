shader_type canvas_item;
render_mode blend_add;

// Light-smash crescent from the Godot slash short: a thick arc that opens
// toward the swing, white on the inner edge, gold, then a soft orange
// smear on the trailing side. Tonemapped because this game has no bloom.
// ASPECT and the curve points match the quad in scripts/slash_vfx.gd.
// The sprite is flipped when the slash travels left, so this shader always
// draws the opening toward +UV.x.

uniform float fade = 1.0;
uniform float flash = 1.0;

const float ASPECT = 280.0 / 200.0;
const vec2 TIP = vec2(0.64, 0.24);
const vec2 BELLY = vec2(0.26, 0.66);
const vec2 FOOT = vec2(0.86, 1.18);

vec2 plane(vec2 uv) {
	return vec2(uv.x, uv.y * ASPECT);
}

vec2 curve(float t) {
	float u = 1.0 - t;
	return TIP * u * u + BELLY * 2.0 * u * t + FOOT * t * t;
}

vec3 tonemap(vec3 hdr) {
	return hdr / (vec3(1.0) + hdr);
}

vec3 stroke(vec2 uv, float edge) {
	vec2 p = plane(uv);
	float best = 9.0;
	float best_t = 0.5;
	float side = 0.0;
	for (int i = 0; i <= 28; i++) {
		float t = float(i) / 28.0;
		vec2 at = curve(t);
		vec2 rel = p - at;
		float d2 = dot(rel, rel);
		if (d2 < best) {
			best = d2;
			best_t = t;
			float t0 = max(t - 0.04, 0.0);
			float t1 = min(t + 0.04, 1.0);
			vec2 tang = curve(t1) - curve(t0);
			float len2 = max(dot(tang, tang), 0.00001);
			tang *= inversesqrt(len2);
			side = rel.x * tang.y - rel.y * tang.x;
		}
	}
	float dist = sqrt(best);
	float taper = smoothstep(0.0, 0.055, best_t);
	taper *= mix(1.0, 0.82, smoothstep(0.9, 1.0, best_t));
	float trail = 1.0 - smoothstep(-0.02, 0.012, side);
	float hot = mix(1.0, 1.25, smoothstep(0.45, 0.92, best_t));
	float rim = exp(-pow(dist / 0.07, 2.0)) * taper * hot * edge;
	float body = exp(-pow(max(dist - 0.02, 0.0) / 0.12, 2.0)) * trail * taper;
	float haze = exp(-pow(max(dist - 0.04, 0.0) / 0.2, 2.0)) * trail * taper;
	return vec3(haze, body, rim);
}

void fragment() {
	vec3 main_stroke = stroke(UV, 1.0);
	vec3 ghost = stroke(UV + vec2(0.055, -0.01), 0.35);
	float haze = main_stroke.x + ghost.x * 0.85;
	float body = main_stroke.y + ghost.y * 0.45;
	float rim = main_stroke.z + ghost.z * 0.25;
	float foot_d = distance(plane(UV), FOOT);
	float foot_glow = exp(-foot_d * foot_d * 14.0) * flash;
	vec3 hdr = vec3(1.45, 0.42, 0.06) * haze;
	hdr += vec3(1.9, 1.2, 0.28) * body;
	hdr += vec3(2.8, 2.45, 1.85) * rim;
	hdr += vec3(2.2, 1.15, 0.28) * foot_glow;
	vec3 rgb = tonemap(hdr);
	rgb = mix(rgb, vec3(1.0, 0.98, 0.92), clamp(rim * 0.55, 0.0, 1.0));
	float alpha = clamp(haze * 0.42 + body * 0.78 + rim * 0.95 + foot_glow * 0.55, 0.0, 1.0);
	alpha *= clamp(fade, 0.0, 1.0);
	if (alpha < 0.02) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
