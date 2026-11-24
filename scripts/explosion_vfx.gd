extends Node2D

# The finished bomb at 45:30 in Le Lu's explosion tutorial, in 2D.
# One shared bank. A cast restarts the emitters. Nothing is painted.
# Timing from that playblast: the flash fills the blast in the first
# instant, the noisy fireball is up by a quarter second, streaks die
# inside a second, the fire collapses around two seconds, and darker
# smoke plus a few embers outlive it.

const CLOUD_SHADER = preload("res://shaders/explosion_cloud.gdshader")
const STREAK_SHADER = preload("res://shaders/explosion_streak.gdshader")
const FLARE_SHADER = preload("res://shaders/explosion_flare.gdshader")

const CORE_LIFE: float = 1.7
const BODY_LIFE: float = 2.25
const SMOKE_LIFE: float = 2.6
const STREAK_LIFE: float = 0.7
const EMBER_LIFE: float = 2.55
const FLARE_LIFE: float = 0.42
const CORE_COUNT: int = 14
const BODY_COUNT: int = 34
const SMOKE_COUNT: int = 16
const STREAK_COUNT: int = 18
const EMBER_COUNT: int = 20
const STREAK_H: float = 120.0

static var banked: bool = false
static var core_motion: ParticleProcessMaterial
static var body_motion: ParticleProcessMaterial
static var smoke_motion: ParticleProcessMaterial
static var streak_motion: ParticleProcessMaterial
static var ember_motion: ParticleProcessMaterial
static var flare_motion: ParticleProcessMaterial
static var core_draw: ShaderMaterial
static var body_draw: ShaderMaterial
static var smoke_draw: ShaderMaterial
static var streak_draw: ShaderMaterial
static var ember_draw: ShaderMaterial
static var flare_draw: ShaderMaterial
static var cloud_tex: Texture2D
static var streak_tex: Texture2D
static var streak_quad: Texture2D
static var flare_tex: Texture2D
static var ember_tex: Texture2D
static var live: Array = []

var age: float = 0.0
var core: GPUParticles2D
var body: GPUParticles2D
var smoke: GPUParticles2D
var streaks: GPUParticles2D
var embers: GPUParticles2D
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
	streaks = _emitter(streak_motion, streak_draw, streak_quad, STREAK_COUNT, STREAK_LIFE, 0.9, 0.14)
	smoke = _emitter(smoke_motion, smoke_draw, cloud_tex, SMOKE_COUNT, SMOKE_LIFE, 0.82, 0.12)
	body = _emitter(body_motion, body_draw, cloud_tex, BODY_COUNT, BODY_LIFE, 0.84, 0.1)
	core = _emitter(core_motion, core_draw, cloud_tex, CORE_COUNT, CORE_LIFE, 0.96, 0.06)
	embers = _emitter(ember_motion, ember_draw, ember_tex, EMBER_COUNT, EMBER_LIFE, 0.78, 0.16)
	flare = _emitter(flare_motion, flare_draw, flare_tex, 1, FLARE_LIFE, 1.0, 0.0)
	streaks.z_index = -4
	smoke.z_index = -1
	body.z_index = 1
	core.z_index = 2
	embers.z_index = 3
	flare.z_index = 4
	add_child(streaks)
	add_child(smoke)
	add_child(body)
	add_child(core)
	add_child(embers)
	add_child(flare)
	call_deferred("_ignite_all")


func _process(delta: float) -> void:
	age += delta
	if age > 3.15:
		queue_free()


func _exit_tree() -> void:
	_silence(streaks)
	_silence(smoke)
	_silence(body)
	_silence(core)
	_silence(embers)
	_silence(flare)
	live.erase(self)


func _silence(p: GPUParticles2D) -> void:
	if p != null:
		p.emitting = false


func _ignite_all() -> void:
	_ignite(streaks)
	_ignite(smoke)
	_ignite(body)
	_ignite(core)
	_ignite(embers)
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
	p.visibility_rect = Rect2(-900, -900, 1800, 1800)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return p


static func _bank() -> void:
	if banked:
		return
	banked = true
	cloud_tex = _white_tex(160, 160)
	flare_tex = _white_tex(256, 256)
	ember_tex = _white_tex(48, 48)
	streak_quad = _white_tex(52, int(STREAK_H))
	streak_tex = _streak_atlas()
	body_draw = ShaderMaterial.new()
	body_draw.shader = CLOUD_SHADER
	body_draw.set_shader_parameter("white_boost", 0.04)
	core_draw = body_draw.duplicate() as ShaderMaterial
	core_draw.set_shader_parameter("white_boost", 0.42)
	smoke_draw = body_draw.duplicate() as ShaderMaterial
	smoke_draw.set_shader_parameter("white_boost", 0.0)
	streak_draw = ShaderMaterial.new()
	streak_draw.shader = STREAK_SHADER
	streak_draw.set_shader_parameter("atlas", streak_tex)
	streak_draw.set_shader_parameter("base_shift", STREAK_H * 0.36)
	flare_draw = ShaderMaterial.new()
	flare_draw.shader = FLARE_SHADER
	flare_draw.set_shader_parameter("glow_pow", 1.7)
	ember_draw = ShaderMaterial.new()
	ember_draw.shader = FLARE_SHADER
	ember_draw.set_shader_parameter("glow_pow", 2.6)
	ember_draw.set_shader_parameter("core_k", 7.0)
	ember_draw.set_shader_parameter("flash_color", Vector3(2.6, 0.85, 0.16))
	core_motion = _core_motion()
	body_motion = _body_motion()
	smoke_motion = _smoke_motion()
	streak_motion = _streak_motion()
	ember_motion = _ember_motion()
	flare_motion = _flare_motion()


static func _burst_basis(mat: ParticleProcessMaterial, sphere: float) -> void:
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = sphere
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3.ZERO
	mat.angle_min = 0.0
	mat.angle_max = 360.0


static func _core_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	_burst_basis(mat, 8.0)
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 36.0
	mat.damping_min = 1.6
	mat.damping_max = 2.6
	mat.radial_velocity_min = 30.0
	mat.radial_velocity_max = 80.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.08, 0.35),
		Vector2(0.22, 0.0),
		Vector2(1.0, 0.0),
	]))
	mat.scale_min = 1.45
	mat.scale_max = 1.85
	mat.scale_curve = _pop_curve()
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _ramp(PackedFloat32Array([0.0, 0.62, 0.82, 1.0]), PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.7, 0.0, 0.0, 0.05),
		Color(1.0, 0.0, 0.0, 1.0),
	]))
	return mat


static func _body_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	_burst_basis(mat, 14.0)
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 36.0
	mat.damping_min = 1.4
	mat.damping_max = 2.2
	mat.radial_velocity_min = 150.0
	mat.radial_velocity_max = 280.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.06, 0.8),
		Vector2(0.14, 0.12),
		Vector2(0.34, 0.0),
		Vector2(1.0, 0.0),
	]))
	mat.scale_min = 1.25
	mat.scale_max = 1.65
	mat.scale_curve = _pop_curve()
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _ramp(PackedFloat32Array([0.0, 0.58, 0.76, 0.9, 1.0]), PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.45, 0.0, 0.0, 0.0),
		Color(1.0, 0.0, 0.0, 0.35),
		Color(1.0, 0.0, 0.0, 1.0),
	]))
	return mat


static func _smoke_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	_burst_basis(mat, 16.0)
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3(0, -28, 0)
	mat.damping_min = 0.7
	mat.damping_max = 1.3
	mat.radial_velocity_min = 220.0
	mat.radial_velocity_max = 400.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.07, 0.55),
		Vector2(0.18, 0.08),
		Vector2(0.4, 0.0),
		Vector2(1.0, 0.0),
	]))
	mat.scale_min = 1.05
	mat.scale_max = 1.45
	mat.scale_curve = _pop_curve()
	mat.color = Color(1, 1, 1, 1)
	mat.color_ramp = _ramp(PackedFloat32Array([0.0, 0.16, 0.38, 0.7, 1.0]), PackedColorArray([
		Color(0.06, 0.0, 0.0, 0.0),
		Color(0.4, 0.0, 0.0, 0.0),
		Color(1.0, 0.0, 0.0, 0.0),
		Color(1.0, 0.0, 0.0, 0.12),
		Color(1.0, 0.0, 0.0, 1.0),
	]))
	return mat


static func _streak_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.particle_flag_align_y = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 6.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 260.0
	mat.initial_velocity_max = 460.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 1.6
	mat.damping_max = 2.6
	mat.scale_min = 0.85
	mat.scale_max = 1.25
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.16),
		Vector2(0.16, 1.0),
		Vector2(0.7, 0.85),
		Vector2(1.0, 0.55),
	]))
	mat.color = Color(1, 0, 0, 1)
	mat.hue_variation_min = 0.0
	mat.hue_variation_max = 0.999
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.35, 0.95),
		Vector2(0.75, 0.35),
		Vector2(1.0, 0.0),
	]))
	return mat


static func _ember_motion() -> ParticleProcessMaterial:
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	_burst_basis(mat, 10.0)
	mat.initial_velocity_min = 90.0
	mat.initial_velocity_max = 240.0
	mat.gravity = Vector3(0, -48, 0)
	mat.damping_min = 0.45
	mat.damping_max = 0.9
	mat.radial_velocity_min = 60.0
	mat.radial_velocity_max = 160.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.2, 0.25),
		Vector2(1.0, 0.0),
	]))
	mat.scale_min = 0.45
	mat.scale_max = 1.15
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.35),
		Vector2(0.15, 1.0),
		Vector2(0.7, 0.7),
		Vector2(1.0, 0.15),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.45, 0.85),
		Vector2(0.8, 0.4),
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
	mat.scale_min = 3.05
	mat.scale_max = 3.05
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.22, 0.78),
		Vector2(0.5, 0.14),
		Vector2(1.0, 0.0),
	]))
	mat.color = Color(1, 1, 1, 1)
	return mat


static func _pop_curve() -> CurveTexture:
	return _curve(PackedVector2Array([
		Vector2(0.0, 0.04),
		Vector2(0.1, 1.0),
		Vector2(1.0, 1.0),
	]))


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


static func _white_tex(w: int, h: int) -> Texture2D:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _streak_atlas() -> Texture2D:
	var img: Image = Image.create(256, int(STREAK_H), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var slice: int = 0
	while slice < 4:
		_paint_slice(img, slice)
		slice += 1
	return ImageTexture.create_from_image(img)


static func _paint_slice(img: Image, slice: int) -> void:
	var left: int = slice * 64
	var tall: int = int(STREAK_H)
	var y: int = 0
	while y < tall:
		var along: float = float(y) / float(tall - 1)
		var wave: float = 0.0
		if slice == 1:
			wave = sin(along * 8.0) * 8.0
		elif slice == 2:
			wave = sin(along * 18.0) * 2.2
		elif slice == 3:
			wave = sin(along * 4.2) * along * 12.0
		var width: float = lerpf(24.0, 3.0, pow(along, 0.85))
		if slice == 2 and (int(along * 8.0) % 2) == 0:
			width = 0.0
		_dab(img, left, y, 32.0 + wave, width)
		if slice == 3 and along > 0.4:
			_dab(img, left, y, 32.0 - wave * 0.65, width * 0.7)
		y += 1


static func _dab(img: Image, left: int, y: int, center: float, width: float) -> void:
	if width <= 0.2:
		return
	var side: int = -18
	while side <= 18:
		var sx: int = left + int(center) + side
		if sx > left and sx < left + 63:
			var dist: float = absf(float(side)) / width
			if dist < 1.0:
				var a: float = pow(1.0 - dist, 1.7)
				var old: Color = img.get_pixel(sx, y)
				if a > old.a:
					img.set_pixel(sx, y, Color(1, 1, 1, a))
		side += 1
