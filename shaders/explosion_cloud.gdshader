shader_type canvas_item;
render_mode blend_mix;

// Le Lu's cloud: a sphere pushed along its normals by scrolling noise,
// with smoothstep fire and dissolve driven by the particle color.
// Red is the explosion amount (0 keeps the fire, 1 cuts it).
// Alpha is the dissolve edge (0 stays opaque, 1 eats the smoke).
// The 20x emission is folded into a white-hot core because this
// compatibility viewport has no bloom buffer.

varying float puff;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		sum += amp * value_noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		amp *= 0.5;
	}
	return sum;
}

float cellular(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float dist = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = vec2(hash21(cell + neighbor), hash21(cell + neighbor + vec2(19.1, 7.7)));
			vec2 delta = neighbor + point - f;
			dist = min(dist, dot(delta, delta));
		}
	}
	return sqrt(dist);
}

void vertex() {
	vec2 origin = MODEL_MATRIX[3].xy;
	puff = fract(sin(dot(origin, vec2(127.1, 311.7))) * 43758.5453);
	float dist = length(VERTEX);
	if (dist > 0.5) {
		vec2 nrm = VERTEX / dist;
		float n = hash21(nrm * 2.4 + vec2(puff * 8.0, 1.7));
		VERTEX += nrm * (n - 0.35) * 26.0;
	}
}

void fragment() {
	float fire_edge = clamp(COLOR.r, 0.0, 1.0);
	float dissolve = clamp(COLOR.a, 0.0, 1.0);
	vec2 uv = UV;
	vec2 from = uv - vec2(0.5);
	float dist = length(from);
	vec2 scroll = uv * 3.4 + vec2(0.0, TIME * 0.22) + puff * 5.5;
	float n = fbm(scroll);
	float lump = fbm(vec2(atan(from.y, from.x) * 1.4 + puff * 6.0, dist * 5.0));
	float rad = 0.30 + n * 0.16 + lump * 0.08;
	float body = 1.0 - smoothstep(rad - 0.05, rad + 0.045, dist);
	float shade = fbm(uv * 5.0 + vec2(puff * 4.0, TIME * 0.08));
	vec3 smoke = mix(vec3(0.12, 0.09, 0.07), vec3(0.48, 0.28, 0.14), shade);
	float cell = cellular(uv * 5.5 + vec2(TIME * 0.16, TIME * 0.05) + puff * 3.0);
	float fire = smoothstep(fire_edge, fire_edge + 0.28, mix(0.2, 1.0, 1.0 - cell));
	float radial = 1.0 - smoothstep(rad * 0.15, rad * 0.95, dist);
	vec3 emission = vec3(1.0, 0.30, 0.10) * 20.0;
	vec3 hot = vec3(1.0, 0.46, 0.1);
	float core = radial * fire;
	vec3 rgb = mix(smoke, hot, fire * 0.92);
	rgb = mix(rgb, emission / (1.0 + emission), core);
	rgb = mix(rgb, vec3(1.0, 0.96, 0.82), core * radial);
	float veil = fbm(uv * 3.2 + vec2(2.2, puff * 6.0));
	float remain = smoothstep(dissolve, dissolve + 0.22, veil);
	float alpha = body * remain;
	if (alpha < 0.03) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
