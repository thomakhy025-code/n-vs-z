extends Node2D

# Le Lu's explosion (youtu.be/miQ7DO1QUVE) in 2D.
# One shared bank: smoke clouds, velocity-aligned streak quads, one flare.
# A cast only restarts those emitters. Nothing is painted in _draw.

const CLOUD_SHADER = preload("res://shaders/explosion_cloud.gdshader")
const STREAK_SHADER = preload("res://shaders/explosion_streak.gdshader")
const FLARE_SHADER = preload("res://shaders/explosion_flare.gdshader")

const CLOUD_LIFE: float = 1.15
const STREAK_LIFE: float = 0.48
const FLARE_LIFE: float = 0.5
const CLOUD_COUNT: int = 12
const STREAK_COUNT: int = 10

static var banked: bool = false
static var cloud_motion: ParticleProcessMaterial
static var streak_motion: ParticleProcessMaterial
static var flare_motion: ParticleProcessMaterial
static var cloud_draw: ShaderMaterial
static var streak_draw: ShaderMaterial
static var flare_draw: ShaderMaterial
static var cloud_tex: Texture2D
static var streak_tex: Texture2D
static var streak_quad: Texture2D
static var flare_tex: Texture2D
static var live: Array = []

var age: float = 0.0
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
	rig.z_index = 480
	var fit: float = clampf(radius / 150.0, 0.75, 2.2)
	rig.scale = Vector2(fit, fit)
	live.append(rig)


func _ready() -> void:
	clouds = _emitter(cloud_motion, cloud_draw, cloud_tex, CLOUD_COUNT, CLOUD_LIFE, 0.96, 0.08)
	streaks = _emitter(streak_motion, streak_draw, streak_quad, STREAK_COUNT, STREAK_LIFE, 1.0, 0.12)
	flare = _emitter(flare_motion, flare_draw, flare_tex, 1, FLARE_LIFE, 1.0, 0.0)
	clouds.name = "clouds"
	streaks.name = "streaks"
	flare.name = "flare"
	streaks.z_index = -2
	clouds.z_index = 0
	flare.z_index = 2
	add_child(streaks)
	add_child(clouds)
	add_child(flare)
	call_deferred("_ignite_all")


func _process(delta: float) -> void:
	age += delta
	if age > 1.45:
		queue_free()


func _exit_tree() -> void:
	if clouds != null:
		clouds.emitting = false
	if streaks != null:
		streaks.emitting = false
	if flare != null:
		flare.emitting = false
	live.erase(self)


func _ignite_all() -> void:
	_ignite(streaks)
	_ignite(clouds)
	_ignite(flare)


func _ignite(p: GPUParticles2D) -> void:
	p.emitting = false
	p.restart()
	p.emitting = true


func _emitter(motion: ParticleProcessMaterial, draw: ShaderMaterial, tex: Texture2D, count: int, span: float, burst: float, jitter: float) -> GPUParticles2D:
	var p: GPUParticles2D = GPUParticles2D.new()
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
	cloud_tex = _white_tex(168, 168)
	flare_tex = _white_tex(240, 240)
	streak_quad = _white_tex(22, 156)
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
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 14.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 24.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 0.8
	mat.damping_max = 1.5
	mat.radial_velocity_min = 280.0
	mat.radial_velocity_max = 460.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.16, 0.22),
		Vector2(1.0, 0.0),
	]))
	mat.scale_min = 0.78
	mat.scale_max = 1.08
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.42),
		Vector2(0.1, 1.0),
		Vector2(1.0, 1.08),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _cloud_ramp()
	return mat


static func _streak_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.particle_flag_align_y = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 240.0
	mat.initial_velocity_max = 420.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 1.2
	mat.damping_max = 2.0
	mat.scale_min = 1.15
	mat.scale_max = 1.85
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.35),
		Vector2(0.16, 1.0),
		Vector2(1.0, 0.7),
	]))
	mat.color = Color(1, 0, 0, 1)
	mat.hue_variation_min = 0.0
	mat.hue_variation_max = 0.999
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.42, 0.9),
		Vector2(1.0, 0.0),
	]))
	return mat


static func _flare_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 0.0
	mat.initial_velocity_min = 0.0
	mat.initial_velocity_max = 0.0
	mat.scale_min = 1.7
	mat.scale_max = 1.7
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.18, 0.7),
		Vector2(0.5, 0.22),
		Vector2(1.0, 0.0),
	]))
	mat.color = Color(1, 1, 1, 1)
	return mat


static func _cloud_ramp() -> GradientTexture1D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.28, 0.48, 0.7, 0.88, 1.0])
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.25, 0.0, 0.0, 0.08),
		Color(0.85, 0.0, 0.0, 0.45),
		Color(1.0, 0.0, 0.0, 0.85),
		Color(1.0, 0.0, 0.0, 1.0),
	])
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = grad
	ramp.width = 64
	return ramp


static func _curve(points: PackedVector2Array) -> CurveTexture:
	var curve: Curve = Curve.new()
	curve.min_value = 0.0
	curve.max_value = 1.0
	var i: int = 0
	while i < points.size():
		curve.add_point(points[i])
		i += 1
	var tex: CurveTexture = CurveTexture.new()
	tex.curve = curve
	return tex


static func _white_tex(w: int, h: int) -> Texture2D:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _streak_atlas() -> Texture2D:
	var img: Image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var slice: int = 0
	while slice < 4:
		_paint_slice(img, slice)
		slice += 1
	return ImageTexture.create_from_image(img)


static func _paint_slice(img: Image, slice: int) -> void:
	var left: int = slice * 64
	var y: int = 0
	while y < 256:
		var along: float = float(y) / 255.0
		var wave: float = 0.0
		if slice == 1:
			wave = sin(along * 9.0) * 7.0
		elif slice == 2:
			wave = sin(along * 16.0) * 2.5
		elif slice == 3:
			wave = sin(along * 5.0) * along * 10.0
		var width: float = lerpf(11.0, 1.4, along)
		if slice == 2 and (int(along * 7.0) % 2) == 0:
			width = 0.0
		_dab(img, left, y, 32.0 + wave, width)
		if slice == 3 and along > 0.35:
			_dab(img, left, y, 32.0 - wave, width * 0.8)
		y += 1


static func _dab(img: Image, left: int, y: int, center: float, width: float) -> void:
	if width <= 0.2:
		return
	var side: int = -16
	while side <= 16:
		var sx: int = left + int(center) + side
		if sx > left and sx < left + 63:
			var dist: float = absf(float(side)) / width
			if dist < 1.0:
				var a: float = pow(1.0 - dist, 1.35)
				var old: Color = img.get_pixel(sx, y)
				if a > old.a:
					img.set_pixel(sx, y, Color(1, 1, 1, a))
		side += 1
