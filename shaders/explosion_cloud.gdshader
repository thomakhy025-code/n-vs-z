shader_type canvas_item;
render_mode blend_mix;

// Le Lu's cloud, flattened for a 2D quad (the tutorial displaces a sphere).
// Red is the explosion amount: 0 keeps the fire, 1 leaves smoke.
// Alpha is the dissolve: 0 stays opaque, 1 eats the puff.
// Emission (1, 0.3, 0.1) * 20 is tonemapped. This viewport has no bloom,
// so the hottest part of each puff is pushed to white in the shader.
// white_boost is higher on the core bank so the heart stays white-hot.

uniform float white_boost = 0.12;

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
	for (int i = 0; i < 3; i++) {
		sum += amp * value_noise(p);
		p = p * 2.05 + vec2(1.7, 9.2);
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
}

void fragment() {
	float cut = clamp(COLOR.r, 0.0, 1.0);
	float dissolve = clamp(COLOR.a, 0.0, 1.0);
	vec2 uv = UV;
	vec2 from = uv - vec2(0.5);
	float dist = length(from);
	float ang = atan(from.y, from.x);
	float lobe = fbm(vec2(ang * 1.5 + puff * 8.0, dist * 2.2));
	float lump = fbm(vec2(ang * 3.2 - puff * 5.0, dist * 4.8 + 1.7));
	float rad = 0.22 + lobe * 0.14 + lump * 0.07;
	float body = 1.0 - smoothstep(rad - 0.01, rad + 0.07, dist);
	float cell = cellular(uv * 2.7 + vec2(TIME * 0.1, TIME * 0.03) + puff * 2.6);
	float flames = smoothstep(cut, cut + 0.16, mix(0.34, 1.0, 1.0 - cell));
	flames *= 1.0 - smoothstep(rad - 0.04, rad + 0.05, dist);
	float radial = 1.0 - smoothstep(0.0, rad * 0.9, dist);
	float heat = flames * radial;
	vec3 fire = vec3(1.0, 0.38, 0.04);
	fire = mix(fire, vec3(1.0, 0.58, 0.08), smoothstep(0.2, 0.75, radial));
	float hot_core = smoothstep(0.55, 0.95, heat + white_boost * 0.5);
	fire = mix(fire, vec3(1.0, 0.96, 0.86), hot_core);
	float shade = fbm(uv * 3.2 + vec2(puff * 3.0, TIME * 0.05));
	vec3 smoke = mix(vec3(0.05, 0.04, 0.035), vec3(0.22, 0.13, 0.08), shade);
	vec3 rgb = mix(smoke, fire, clamp(flames, 0.0, 1.0));
	float veil = fbm(uv * 2.2 + vec2(2.1, puff * 6.0));
	float remain = smoothstep(dissolve, dissolve + 0.18, veil);
	float alpha = body * remain;
	if (alpha < 0.035) {
		discard;
	}
	COLOR = vec4(rgb, alpha);
}
