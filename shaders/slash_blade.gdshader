shader_type canvas_item;
render_mode blend_add;

// One crescent. The cutting edge is a thin white skin. Yellow sits just
// behind it, then a wide orange smear on the trailing side. Thick at the
// foot, thin at the tip. Layers are combined with max so they stay
// yellow and orange instead of stacking into a white blob.
// Tonemapped because this viewport has no bloom.
// ASPECT and the curve match scripts/slash_vfx.gd. The sprite flip sends
// the opening toward the travel direction. +side is that opening.

uniform float fade = 1.0;
uniform float flash = 1.0;
uniform float rush = 1.0;

const float ASPECT = 360.0 / 420.0;
const vec2 TIP = vec2(0.72, 0.10);
const vec2 BELLY = vec2(0.40, 0.42);
const vec2 FOOT = vec2(0.80, 0.78);

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

void fragment() {
	vec2 p = plane(UV);
	float best = 9.0;
	float best_t = 0.55;
	float side = 0.0;
	for (int i = 0; i <= 48; i++) {
		float t = float(i) / 48.0;
		vec2 at = curve(t);
		vec2 rel = p - at;
		float d2 = dot(rel, rel);
		if (d2 < best) {
			best = d2;
			best_t = t;
			float t0 = max(t - 0.025, 0.0);
			float t1 = min(t + 0.025, 1.0);
			vec2 tang = curve(t1) - curve(t0);
			float len2 = max(dot(tang, tang), 0.00001);
			tang *= inversesqrt(len2);
			side = rel.x * tang.y - rel.y * tang.x;
		}
	}
	float dist = sqrt(best);
	float rush_amt = clamp(rush, 0.0, 1.0);
	float width = mix(0.22, 1.85, smoothstep(0.0, 0.62, best_t));
	float reach = mix(0.7, 1.0, rush_amt);
	float sd = side;
	float along = max(dist - abs(sd), 0.0);
	float cap = exp(-pow(along / (0.055 * max(width, 0.28)), 2.0));
	// Hard stop in front of the cutting edge. The tip narrows with width.
	float front = 1.0 - smoothstep(0.004 * width, 0.03 * width, sd);
	float rim = exp(-pow(sd / (0.011 * max(width, 0.2)), 2.0));
	rim *= 1.0 - smoothstep(0.0, 0.014 * width, sd);
	float yellow = exp(-pow((sd + 0.045 * width) / (0.075 * width), 2.0));
	float orange = exp(-pow((sd + 0.13 * width * reach) / (0.15 * width * reach), 2.0));
	orange *= 1.0 - smoothstep(-0.015 * width, 0.028 * width, sd);
	float haze = exp(-pow((sd + 0.22 * width * reach) / (0.24 * width * reach), 2.0));
	haze *= 1.0 - smoothstep(-0.03 * width, 0.02 * width, sd);
	rim *= cap * front;
	yellow *= cap * front;
	orange *= cap * front;
	haze *= cap * front;
	vec2 pf = p;
	float up = FOOT.y - pf.y;
	float foot = exp(-pow((pf.x - FOOT.x) / 0.05, 2.0));
	foot *= 1.0 - smoothstep(0.0, 0.18, up);
	foot *= smoothstep(-0.03, 0.012, up);
	foot *= rush_amt;
	vec3 hdr = vec3(2.9, 0.58, 0.04) * haze;
	hdr = max(hdr, vec3(3.8, 1.05, 0.07) * orange);
	hdr = max(hdr, vec3(5.4, 3.5, 0.32) * yellow);
	hdr = max(hdr, vec3(3.4, 1.6, 0.18) * foot);
	hdr = max(hdr, vec3(14.0, 13.0, 11.0) * rim);
	vec3 rgb = tonemap(hdr);
	float edge = clamp(rim * (0.85 + 0.35 * clamp(flash, 0.0, 1.8)), 0.0, 1.0);
	rgb = mix(rgb, vec3(1.0, 0.99, 0.96), edge);
	float alpha = max(max(haze * 0.82, orange * 0.94), max(yellow, max(rim, foot * 0.8)));
	alpha = clamp(alpha, 0.0, 1.0) * clamp(fade, 0.0, 1.0);
	float inset = smoothstep(0.0, 0.035, UV.x) * smoothstep(0.0, 0.035, UV.y);
	inset *= smoothstep(0.0, 0.035, 1.0 - UV.x) * smoothstep(0.0, 0.035, 1.0 - UV.y);
	alpha *= inset;
	if (alpha < 0.02) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
