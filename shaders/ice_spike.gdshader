shader_type canvas_item;
render_mode blend_mix;

// Faceted cone from the earth-spike tutorial, shaded as glass.
// UV.x is 0 on the left edge and 1 on the right. UV.y is 0 at the tip.
// Bright rims are pushed to white here. This viewport has no bloom.

uniform float core_mix = 0.55;
uniform float clip_local = 1000.0;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	float edge = abs(UV.x - 0.5) * 2.0;
	float up = 1.0 - UV.y;
	vec3 cold = vec3(0.10, 0.40, 0.82);
	vec3 pale = vec3(0.74, 0.93, 1.0);
	vec3 ice = mix(cold, pale, smoothstep(0.08, 0.72, edge));
	float core = (1.0 - smoothstep(0.0, 0.48, edge));
	core *= smoothstep(0.08, 0.34, UV.y) * smoothstep(0.92, 0.42, UV.y);
	ice = mix(ice, cold, core * core_mix);
	float rim = smoothstep(0.58, 0.96, edge);
	ice = mix(ice, vec3(0.95, 0.99, 1.0), rim);
	ice = mix(ice, vec3(1.0), smoothstep(0.58, 1.0, up) * 0.8);
	float hot = max(ice.r, max(ice.g, ice.b));
	ice = mix(ice, vec3(1.0), smoothstep(0.80, 0.99, hot));
	vec4 shard = vec4(ice, 0.94 * COLOR.a);
	if (local_y > clip_local) {
		shard = vec4(0.0);
	}
	COLOR = shard;
}
