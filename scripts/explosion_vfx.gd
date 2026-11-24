extends Node2D

# Le Lu's explosion (youtu.be/miQ7DO1QUVE) in 2D.
# Clouds are noise-lumpy spheres on GPUParticles2D. Particle red drives the
# smoothstep that cuts the fire, particle alpha drives the smoothstep that
# dissolves the smoke. Streaks are one shared 4-slice atlas, chosen from
# particle hue and aligned to velocity. One additive flare shrinks away.
# Materials and the atlas are built once. A cast only restarts emitters.

const CLOUD_SHADER = preload("res://shaders/explosion_cloud.gdshader")
const STREAK_SHADER = preload("res://shaders/explosion_streak.gdshader")
const FLARE_SHADER = preload("res://shaders/explosion_flare.gdshader")

const LEAD := 0.62
const CLOUD_LIFE := 0.95
const STREAK_LIFE := 0.42
const FLARE_LIFE := 0.5
const CLOUD_COUNT := 10
const STREAK_COUNT := 8

static var banked: bool = false
static var cloud_motion: ParticleProcessMaterial
static var streak_motion: ParticleProcessMaterial
static var flare_motion: ParticleProcessMaterial
static var cloud_draw: ShaderMaterial
static var streak_draw: ShaderMaterial
static var flare_draw: ShaderMaterial
static var cloud_tex: Texture2D
static var streak_tex: Texture2D
static var spike_tex: Texture2D
static var flare_tex: Texture2D
static var live: Array = []

var wait: float = LEAD
var age: float = 0.0
var started: bool = false
var clouds: GPUParticles2D
var streaks: GPUParticles2D
var flare: GPUParticles2D


static func play(host: Node, at: Vector2, radius: float) -> void:
	if host == null:
		return
	_bank()
	var stale: Array = []
	for item in live:
		if not is_instance_valid(item):
			stale.append(item)
	for item in stale:
		live.erase(item)
	while live.size() >= 4:
		var old: Variant = live.pop_front()
		if old is Node and is_instance_valid(old):
			(old as Node).queue_free()
	var script: GDScript = load("res://scripts/explosion_vfx.gd")
	var rig: Node2D = script.new() as Node2D
	if rig == null:
		return
	host.add_child(rig)
	rig.position = at
	rig.z_index = 475
	var fit: float = clampf(radius / 150.0, 0.7, 2.4)
	rig.scale = Vector2(fit, fit)
	live.append(rig)


func _ready() -> void:
	clouds = _emitter(cloud_motion, cloud_draw, cloud_tex, CLOUD_COUNT, CLOUD_LIFE, 0.8, 0.12)
	streaks = _emitter(streak_motion, streak_draw, spike_tex, STREAK_COUNT, STREAK_LIFE, 0.9, 0.35)
	flare = _emitter(flare_motion, flare_draw, flare_tex, 1, FLARE_LIFE, 1.0, 0.0)
	streaks.z_index = -2
	clouds.z_index = 0
	flare.z_index = 2
	add_child(streaks)
	add_child(clouds)
	add_child(flare)


func _process(delta: float) -> void:
	if not started:
		wait -= delta
		if wait > 0.0:
			return
		_ignite(clouds)
		_ignite(streaks)
		_ignite(flare)
		started = true
		return
	age += delta
	if age > 2.05:
		queue_free()


func _exit_tree() -> void:
	if clouds != null:
		clouds.emitting = false
	if streaks != null:
		streaks.emitting = false
	if flare != null:
		flare.emitting = false
	live.erase(self)


func _ignite(p: GPUParticles2D) -> void:
	p.emitting = false
	p.restart()
	p.emitting = true


func _emitter(motion: ParticleProcessMaterial, draw: ShaderMaterial, tex: Texture2D, count: int, span: float, burst: float, jitter: float) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	var copied: Material = motion.duplicate() as Material
	p.process_material = copied
	p.material = draw
	p.texture = tex
	p.amount = count
	p.lifetime = span
	p.one_shot = true
	p.explosiveness = burst
	p.randomness = jitter
	p.emitting = false
	p.local_coords = true
	p.visibility_rect = Rect2(-520, -520, 1040, 1040)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return p


static func _bank() -> void:
	if banked:
		return
	banked = true
	cloud_tex = _white_tex(150, 150)
	flare_tex = _white_tex(220, 220)
	spike_tex = _white_tex(36, 168)
	streak_tex = _streak_atlas()
	cloud_draw = ShaderMaterial.new()
	cloud_draw.shader = CLOUD_SHADER
	streak_draw = ShaderMaterial.new()
	streak_draw.shader = STREAK_SHADER
	streak_draw.set_shader_parameter("atlas", streak_tex)
	flare_draw = ShaderMaterial.new()
	flare_draw.shader = FLARE_SHADER
	cloud_motion = _cloud_motion()
	streak_motion = _streak_motion()
	flare_motion = _flare_motion()


static func _cloud_motion() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 16.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 0.8
	mat.damping_max = 1.4
	mat.radial_velocity_min = 340.0
	mat.radial_velocity_max = 520.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.22, 0.18),
		Vector2(1.0, 0.0),
	]))
	mat.scale_min = 0.72
	mat.scale_max = 1.02
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.08),
		Vector2(0.1, 1.0),
		Vector2(1.0, 1.0),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _cloud_ramp()
	return mat


static func _streak_motion() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.particle_flag_align_y = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 220.0
	mat.initial_velocity_max = 380.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 1.1
	mat.damping_max = 1.8
	mat.scale_min = 1.25
	mat.scale_max = 1.75
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.12),
		Vector2(0.14, 1.0),
		Vector2(1.0, 0.72),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.hue_variation_min = 0.0
	mat.hue_variation_max = 1.0
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.18, 0.04),
		Vector2(0.55, 0.55),
		Vector2(1.0, 1.0),
	]))
	return mat


static func _flare_motion() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 0.0
	mat.initial_velocity_min = 0.0
	mat.initial_velocity_max = 0.0
	mat.scale_min = 1.35
	mat.scale_max = 1.35
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.2, 0.85),
		Vector2(0.45, 0.22),
		Vector2(1.0, 0.0),
	]))
	mat.color = Color(1, 1, 1, 1)
	return mat


static func _cloud_ramp() -> GradientTexture1D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.38, 0.55, 0.78, 1.0])
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.2, 0.0, 0.0, 0.02),
		Color(1.0, 0.0, 0.0, 0.08),
		Color(1.0, 0.0, 0.0, 0.55),
		Color(1.0, 0.0, 0.0, 1.0),
	])
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	ramp.width = 64
	return ramp


static func _curve(points: PackedVector2Array) -> CurveTexture:
	var curve := Curve.new()
	curve.min_value = 0.0
	curve.max_value = 1.0
	var i: int = 0
	while i < points.size():
		curve.add_point(points[i])
		i += 1
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex


static func _white_tex(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _streak_atlas() -> Texture2D:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var slice: int = 0
	while slice < 4:
		_stroke(img, slice, slice - 1, 1.0)
		slice += 1
	return ImageTexture.create_from_image(img)


static func _stroke(img: Image, slice: int, shift: int, weight: float) -> void:
	var left: int = slice * 64
	var y: int = 8
	while y < 250:
		var along: float = float(y) / 250.0
		var wave: float = sin(along * 9.0 + float(slice) * 1.7) * (2.0 + float(slice))
		var px: int = left + 32 + shift + int(wave)
		var reach: int = 2 + int((1.0 - along) * 8.0)
		var side: int = -reach
		while side <= reach:
			var sx: int = px + side
			var falloff: float = 1.0 - float(abs(side)) / float(reach + 1)
			var fade: float = falloff * weight * (0.35 + 0.65 * (1.0 - along))
			if sx > left + 1 and sx < left + 62:
				var old: Color = img.get_pixel(sx, y)
				var next: Color = Color(1, 1, 1, minf(1.0, old.a + fade))
				img.set_pixel(sx, y, next)
			side += 1
		y += 1
