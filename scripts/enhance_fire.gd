extends Node2D

# Enhancement burn. The tutorial's finished look is GPU-particle fire
# clinging to a weapon (a flame pass plus a thinner spark trail) and the
# same fire sitting on a body so the metal or skin still reads. Adapted
# here as GPUParticles2D on the hero: one rectangle along the sword, and
# small spheres on the head, torso, and limbs. Textures are shared.
# Nothing is allocated per frame. gl_compatibility has no bloom, so the
# shaders tonemap the bright core.

const FLAME_SHADER = preload("res://shaders/enhance_flame.gdshader")
const SPARK_SHADER = preload("res://shaders/enhance_spark.gdshader")

const SWORD_COUNT: int = 26
const SPARK_COUNT: int = 10
const SWORD_LIFE: float = 0.55
const SPARK_LIFE: float = 0.7
const BODY_LIFE: float = 0.58

static var banked: bool = false
static var flame_tex: Texture2D
static var spark_tex: Texture2D
static var sword_draw: ShaderMaterial
static var body_draw: ShaderMaterial
static var spark_draw: ShaderMaterial
static var sword_motion: ParticleProcessMaterial
static var spark_motion: ParticleProcessMaterial
static var body_motion: ParticleProcessMaterial

var _lit: bool = false
var _sword: GPUParticles2D
var _sparks: GPUParticles2D
var _body: Array[GPUParticles2D] = []
var _sword_mat: ParticleProcessMaterial
var _spark_mat: ParticleProcessMaterial


static func ensure() -> void:
	_bank()


func _ready() -> void:
	_bank()
	_sword_mat = sword_motion.duplicate() as ParticleProcessMaterial
	_spark_mat = spark_motion.duplicate() as ParticleProcessMaterial
	_sword = _emitter(_sword_mat, sword_draw, flame_tex, SWORD_COUNT, SWORD_LIFE)
	_sword.z_index = 1
	_sparks = _emitter(_spark_mat, spark_draw, spark_tex, SPARK_COUNT, SPARK_LIFE)
	_sparks.z_index = 1
	add_child(_sword)
	_sword.add_child(_sparks)
	var counts: PackedInt32Array = PackedInt32Array([7, 10, 5, 5, 5, 5])
	var scales: PackedFloat32Array = PackedFloat32Array([1.12, 1.38, 0.86, 0.86, 0.9, 0.9])
	var i: int = 0
	while i < counts.size():
		var motion: ParticleProcessMaterial = body_motion.duplicate() as ParticleProcessMaterial
		var bit: GPUParticles2D = _emitter(motion, body_draw, flame_tex, counts[i], BODY_LIFE)
		bit.scale = Vector2(scales[i], scales[i])
		bit.z_index = 0
		add_child(bit)
		_body.append(bit)
		i += 1
	visible = false


func sync(on: bool, rig: Dictionary, facing: float, scale: float, bob: float) -> void:
	var became: bool = on and not _lit
	var ended: bool = (not on) and _lit
	_lit = on
	if ended or not on:
		if ended:
			visible = false
			_emit(false)
		return
	visible = true
	_place(rig, facing, scale, bob)
	if became:
		_emit(true)


func _emit(on: bool) -> void:
	_set_emit(_sword, on)
	_set_emit(_sparks, on)
	var i: int = 0
	while i < _body.size():
		_set_emit(_body[i], on)
		i += 1


func _set_emit(p: GPUParticles2D, on: bool) -> void:
	if p == null:
		return
	if on:
		p.emitting = true
		p.restart()
	else:
		p.emitting = false


func _place(rig: Dictionary, facing: float, scale: float, bob: float) -> void:
	if rig.is_empty() or _sword == null:
		return
	var hand: Vector2 = rig["hand"]
	var tip: Vector2 = rig["tip"]
	var a: Vector2 = _map(hand, facing, scale, bob)
	var b: Vector2 = _map(tip, facing, scale, bob)
	var delta: Vector2 = b - a
	var leng: float = delta.length()
	if leng < 8.0:
		leng = 8.0
		if delta.length() < 0.01:
			delta = Vector2(facing, -0.2)
		delta = delta.normalized() * leng
		b = a + delta
	var mid: Vector2 = (a + b) * 0.5
	_sword.position = mid
	_sword.rotation = delta.angle() - PI * 0.5
	if _sword_mat != null:
		_sword_mat.emission_box_extents = Vector3(6.5, leng * 0.5, 0.0)
	if _spark_mat != null:
		_spark_mat.emission_box_extents = Vector3(9.0, leng * 0.48, 0.0)
	var up_local: Vector2 = Vector2(0.0, -1.0).rotated(-_sword.rotation)
	var up3: Vector3 = Vector3(up_local.x, up_local.y, 0.0)
	if _sword_mat != null:
		_sword_mat.direction = up3
		_sword_mat.gravity = up3 * 28.0
	if _spark_mat != null:
		_spark_mat.direction = up3
		_spark_mat.gravity = up3 * 70.0
	var spots: PackedVector2Array = rig["body"]
	var n: int = mini(spots.size(), _body.size())
	var i: int = 0
	while i < n:
		_body[i].position = _map(spots[i], facing, scale, bob)
		i += 1


func _map(p: Vector2, facing: float, scale: float, bob: float) -> Vector2:
	return Vector2(p.x * facing * scale, p.y * scale + bob)


func _emitter(motion: ParticleProcessMaterial, draw: ShaderMaterial, tex: Texture2D, count: int, span: float) -> GPUParticles2D:
	var p: GPUParticles2D = GPUParticles2D.new()
	p.process_material = motion
	p.material = draw
	p.texture = tex
	p.amount = count
	p.lifetime = span
	p.one_shot = false
	p.explosiveness = 0.0
	p.randomness = 0.42
	p.preprocess = 0.3
	p.emitting = false
	p.local_coords = true
	p.interpolate = true
	p.visibility_rect = Rect2(-150.0, -170.0, 300.0, 320.0)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return p


static func _bank() -> void:
	if banked:
		return
	banked = true
	flame_tex = ImageTexture.create_from_image(_flame_image())
	spark_tex = ImageTexture.create_from_image(_dot_image())
	body_draw = ShaderMaterial.new()
	body_draw.shader = FLAME_SHADER
	body_draw.set_shader_parameter("heat", 1.85)
	body_draw.set_shader_parameter("cap", 0.7)
	sword_draw = body_draw.duplicate() as ShaderMaterial
	sword_draw.set_shader_parameter("heat", 2.35)
	sword_draw.set_shader_parameter("cap", 0.82)
	spark_draw = ShaderMaterial.new()
	spark_draw.shader = SPARK_SHADER
	sword_motion = _sword_motion()
	spark_motion = _spark_motion()
	body_motion = _body_motion()


static func _sword_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.particle_flag_align_y = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(4.0, 16.0, 0.0)
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 32.0
	mat.initial_velocity_min = 16.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3(0.0, -28.0, 0.0)
	mat.damping_min = 0.7
	mat.damping_max = 1.5
	mat.angle_min = -8.0
	mat.angle_max = 8.0
	mat.scale_min = 0.42
	mat.scale_max = 0.92
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.35),
		Vector2(0.28, 1.0),
		Vector2(0.72, 0.62),
		Vector2(1.0, 0.12),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _ramp(PackedFloat32Array([0.0, 0.14, 0.46, 1.0]), PackedColorArray([
		Color(1.0, 0.96, 0.75, 0.0),
		Color(1.0, 0.8, 0.34, 0.92),
		Color(1.0, 0.36, 0.06, 0.7),
		Color(0.32, 0.04, 0.01, 0.0),
	]))
	_wobble(mat, 0.06)
	return mat


static func _spark_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(7.0, 16.0, 0.0)
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 55.0
	mat.initial_velocity_min = 28.0
	mat.initial_velocity_max = 64.0
	mat.gravity = Vector3(0.0, -70.0, 0.0)
	mat.damping_min = 0.45
	mat.damping_max = 1.0
	mat.scale_min = 0.55
	mat.scale_max = 1.15
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.4),
		Vector2(0.2, 1.0),
		Vector2(1.0, 0.15),
	]))
	mat.color = Color(1.0, 0.92, 0.55, 1.0)
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.12, 1.0),
		Vector2(0.55, 0.7),
		Vector2(1.0, 0.0),
	]))
	return mat


static func _body_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.particle_flag_align_y = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 38.0
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 30.0
	mat.gravity = Vector3(0.0, -22.0, 0.0)
	mat.damping_min = 0.8
	mat.damping_max = 1.6
	mat.angle_min = -10.0
	mat.angle_max = 10.0
	mat.scale_min = 0.38
	mat.scale_max = 0.78
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.4),
		Vector2(0.3, 1.0),
		Vector2(1.0, 0.16),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _ramp(PackedFloat32Array([0.0, 0.16, 0.5, 1.0]), PackedColorArray([
		Color(1.0, 0.92, 0.6, 0.0),
		Color(1.0, 0.66, 0.18, 0.8),
		Color(0.95, 0.3, 0.05, 0.52),
		Color(0.28, 0.04, 0.01, 0.0),
	]))
	_wobble(mat, 0.05)
	return mat


static func _wobble(mat: ParticleProcessMaterial, influence: float) -> void:
	mat.turbulence_enabled = true
	mat.turbulence_noise_strength = 1.2
	mat.turbulence_noise_scale = 3.2
	mat.turbulence_noise_speed = Vector3(0.0, 0.55, 0.15)
	mat.turbulence_noise_speed_random = 0.35
	mat.turbulence_influence_min = influence * 0.4
	mat.turbulence_influence_max = influence


static func _ramp(offsets: PackedFloat32Array, colors: PackedColorArray) -> GradientTexture1D:
	var grad: Gradient = Gradient.new()
	grad.offsets = offsets
	grad.colors = colors
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
	tex.width = 64
	return tex


static func _flame_image() -> Image:
	var w: int = 48
	var h: int = 64
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var y: int = 0
	while y < h:
		var v: float = float(y) / float(h - 1)
		var x: int = 0
		while x < w:
			var sway: float = sin(v * 8.5) * 0.14 * (1.0 - v)
			var u: float = (float(x) / float(w - 1) - 0.5) * 2.0 - sway
			var half: float = lerpf(0.78, 0.07, pow(v, 0.82))
			half *= lerpf(0.62, 1.0, sin(v * PI))
			var jag: float = sin(v * 26.0 + float(x) * 0.17) * 0.07
			var edge: float = absf(u) / maxf(half, 0.04) + jag
			if edge < 1.0:
				var alpha: float = pow(1.0 - edge, 1.28)
				alpha *= smoothstep(0.0, 0.06, v)
				alpha *= smoothstep(0.0, 0.08, 1.0 - v)
				var core: float = pow(clampf(1.0 - edge * 1.45, 0.0, 1.0), 1.55) * pow(clampf(v, 0.0, 1.0), 0.35)
				if alpha > 0.015:
					img.set_pixel(x, y, Color(core, core * 0.55, core * 0.12, alpha))
			x += 1
		y += 1
	return img


static func _dot_image() -> Image:
	var img: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return img
