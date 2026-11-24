extends Node2D

# Light smashing, matched to the crescent in the Godot slash short.
# One quad shader for the blade, one small streak burst, and a fissure
# drawn under them. The hero sprite is not replaced.

const BLADE_SHADER = preload("res://shaders/slash_blade.gdshader")
const EDGE_SHADER = preload("res://shaders/slash_edge.gdshader")
const SPARK_SHADER = preload("res://shaders/slash_spark.gdshader")

const TRAVEL := 0.50
const LIFE := 1.42
const SPARK_COUNT := 48
const BLADE_W := 200.0
const BLADE_H := 280.0
const TEX := 8.0
const TIP_PLANE := Vector2(0.64, 0.24)
const BELLY_PLANE := Vector2(0.26, 0.66)
const FOOT_PLANE := Vector2(0.86, 1.18)

static var banked: bool = false
static var spark_motion: ParticleProcessMaterial
static var spark_draw: ShaderMaterial
static var spark_tex: Texture2D
static var blade_tex: Texture2D
static var live: Array = []

var age: float = 0.0
var origin_x: float = 0.0
var dest_x: float = 0.0
var road_y: float = 0.0
var blow: float = 1.0
var blade: Sprite2D
var blade_mat: ShaderMaterial
var edge: SlashEdge
var sparks: GPUParticles2D


static func play(host: Node, near_x: float, far_x: float, y: float) -> void:
	if host == null:
		return
	_bank()
	var stale: Array = []
	for listed in live:
		if not is_instance_valid(listed):
			stale.append(listed)
	for gone in stale:
		live.erase(gone)
	while live.size() >= 4:
		var old: Variant = live.pop_front()
		if old is Node and is_instance_valid(old):
			(old as Node).queue_free()
	var script: GDScript = load("res://scripts/slash_vfx.gd")
	var rig: Node = script.new()
	if rig == null:
		return
	rig.call("setup", near_x, far_x, y)
	host.add_child(rig)
	live.append(rig)


func setup(near_x: float, far_x: float, y: float) -> void:
	origin_x = near_x
	dest_x = far_x
	road_y = y
	var span: float = far_x - near_x
	if span < 0.0:
		blow = -1.0
	else:
		blow = 1.0
	if absf(span) < 8.0:
		dest_x = near_x + blow * 8.0


func _ready() -> void:
	z_index = 496
	_build_blade()
	_build_edge()
	_build_sparks()
	_place(0.0)
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	var travel: float = _eased()
	_place(travel)
	if sparks != null and age >= TRAVEL and sparks.emitting:
		sparks.emitting = false
	queue_redraw()
	if age > LIFE:
		queue_free()


func _exit_tree() -> void:
	if sparks != null:
		sparks.emitting = false
	live.erase(self)


func _eased() -> float:
	var t: float = clampf(age / TRAVEL, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 1.65)


func _head_x(travel: float) -> float:
	return lerpf(origin_x, dest_x, travel)


func _blade_fade() -> float:
	if age < 0.04:
		return clampf(age / 0.04, 0.0, 1.0)
	if age < 0.40:
		return 1.0
	if age > 0.92:
		return 0.0
	return clampf(1.0 - (age - 0.40) / 0.52, 0.0, 1.0)


func _flash() -> float:
	if age >= 0.55:
		return 0.32
	return lerpf(1.15, 0.45, clampf(age / 0.55, 0.0, 1.0))


func _place(travel: float) -> void:
	var head: float = _head_x(travel)
	var fade: float = _blade_fade()
	var grow: float = clampf(0.64 + 0.36 * minf(age / 0.12, 1.0), 0.64, 1.0)
	if blade != null:
		blade.visible = fade > 0.01
		var sx: float = blow * grow * BLADE_W / TEX
		var sy: float = grow * BLADE_H / TEX
		blade.scale = Vector2(sx, sy)
		var foot_u: float = FOOT_PLANE.x
		var foot_v: float = FOOT_PLANE.y * BLADE_W / BLADE_H
		var foot_x: float = (foot_u - 0.5) * BLADE_W * grow * blow
		var foot_y: float = (foot_v - 0.5) * BLADE_H * grow
		blade.position = Vector2(head - foot_x, road_y - foot_y)
		if blade_mat != null:
			blade_mat.set_shader_parameter("fade", fade)
			blade_mat.set_shader_parameter("flash", _flash())
	if edge != null:
		edge.pts = _edge_points(head, grow)
		edge.fade = fade
		edge.queue_redraw()
	if sparks != null:
		sparks.position = Vector2(head, road_y - 4.0)


func _draw() -> void:
	var travel: float = _eased()
	var head: float = _head_x(travel)
	var puff: float = clampf(1.0 - age / 0.34, 0.0, 1.0)
	if puff > 0.02:
		var puff_at := Vector2(head - blow * 10.0, road_y)
		draw_circle(puff_at, 16.0 + age * 46.0, Color(1.0, 0.48, 0.1, 0.18 * puff))
		draw_circle(puff_at + Vector2(0.0, -6.0), 7.0 + age * 14.0, Color(1.0, 0.94, 0.78, 0.28 * puff))
	if travel < 0.025:
		return
	var crack_a: float = _crack_alpha()
	if crack_a <= 0.02:
		return
	var main_pts: PackedVector2Array = _crack_points(origin_x, head, 3, 15.0)
	_paint_line(main_pts, 11.0, Color(0.04, 0.025, 0.015, 0.72 * crack_a))
	_paint_line(main_pts, 6.4, Color(0.95, 0.38, 0.06, 0.9 * crack_a))
	_paint_line(main_pts, 3.1, Color(1.0, 0.82, 0.28, crack_a))
	_paint_line(main_pts, 1.35, Color(1.0, 0.97, 0.88, crack_a))
	if main_pts.size() > 8:
		var fork: PackedVector2Array = _crack_points(origin_x, head, 8, 11.0)
		var fork_pts := PackedVector2Array()
		var cut: int = 3
		while cut <= 15 and cut < fork.size():
			fork_pts.append(fork[cut] + Vector2(0.0, -7.0))
			cut += 1
		_paint_line(fork_pts, 2.4, Color(1.0, 0.62, 0.12, 0.85 * crack_a))
		_paint_line(fork_pts, 1.05, Color(1.0, 0.95, 0.8, 0.9 * crack_a))
	var branch: int = 4
	while branch < main_pts.size() - 1:
		var at: Vector2 = main_pts[branch]
		var lift: float = -20.0
		if branch % 2 == 0:
			lift = 12.0
		var tip: Vector2 = at + Vector2(blow * 14.0, lift)
		draw_line(at, tip, Color(1.0, 0.55, 0.1, 0.85 * crack_a), 2.0, true)
		draw_line(at, tip, Color(1.0, 0.96, 0.84, crack_a), 0.9, true)
		branch += 5
	var speck: int = 0
	while speck < 12:
		var along: float = float(speck) / 11.0
		var sx: float = lerpf(origin_x, head, along)
		var flick: float = 0.4 + 0.6 * absf(sin(age * 16.0 + float(speck) * 1.7))
		var hop: float = 5.0 + float(speck % 4) * 6.0
		draw_circle(Vector2(sx, road_y - hop), 1.6 + float(speck % 3) * 0.7, Color(1.0, 0.94, 0.72, crack_a * flick))
		speck += 1


func _crack_alpha() -> float:
	if age < 0.06:
		return clampf(age / 0.06, 0.0, 1.0)
	if age < 0.72:
		return 1.0
	return clampf(1.0 - (age - 0.72) / (LIFE - 0.72), 0.0, 1.0)


func _crack_points(x_from: float, x_to: float, seed: int, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var table := PackedFloat32Array([0.0, 0.42, -0.18, 0.95, 0.12, -0.62, 0.28, -1.0, 0.08, 0.7, -0.36, 0.22, 0.0])
	var steps: int = 12
	var i: int = 0
	while i <= steps:
		var t: float = float(i) / float(steps)
		var x: float = lerpf(x_from, x_to, t)
		var n: int = (i + 3) * seed + 11
		n = (n * 1103515245 + 12345) % 997
		if n < 0:
			n = -n
		var slot: int = (i + seed) % table.size()
		var jag: float = table[slot] * amp
		jag += (float(n % 100) / 100.0 - 0.5) * amp * 0.22
		if i == 0 or i == steps:
			jag = 0.0
		pts.append(Vector2(x, road_y + jag))
		i += 1
	return pts


func _paint_line(pts: PackedVector2Array, width: float, color: Color) -> void:
	if pts.size() < 2 or color.a <= 0.01:
		return
	draw_polyline(pts, color, width, true)


func _edge_points(head: float, grow: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps: int = 32
	var i: int = 0
	while i <= steps:
		var t: float = float(i) / float(steps)
		var u: float = 1.0 - t
		var p: Vector2 = TIP_PLANE * u * u + BELLY_PLANE * 2.0 * u * t + FOOT_PLANE * t * t
		var x: float = head + (p.x - FOOT_PLANE.x) * BLADE_W * grow * blow
		var y: float = road_y + (p.y - FOOT_PLANE.y) * BLADE_W * grow
		pts.append(Vector2(x, y))
		i += 1
	return pts


func _build_edge() -> void:
	edge = SlashEdge.new()
	edge.z_index = 3
	var mat := ShaderMaterial.new()
	mat.shader = EDGE_SHADER
	edge.material = mat
	add_child(edge)


func _build_blade() -> void:
	blade = Sprite2D.new()
	blade.texture = blade_tex
	blade.centered = true
	blade.z_index = 2
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	blade_mat = ShaderMaterial.new()
	blade_mat.shader = BLADE_SHADER
	blade_mat.set_shader_parameter("fade", 1.0)
	blade_mat.set_shader_parameter("flash", 1.0)
	blade.material = blade_mat
	add_child(blade)


func _build_sparks() -> void:
	sparks = GPUParticles2D.new()
	var copied: ParticleProcessMaterial = spark_motion.duplicate() as ParticleProcessMaterial
	copied.direction = Vector3(-blow * 0.45, -1.0, 0.0)
	copied.spread = 64.0
	sparks.process_material = copied
	sparks.material = spark_draw
	sparks.texture = spark_tex
	sparks.amount = SPARK_COUNT
	sparks.lifetime = TRAVEL
	sparks.one_shot = true
	sparks.explosiveness = 0.2
	sparks.randomness = 0.35
	sparks.emitting = false
	sparks.local_coords = false
	sparks.visibility_rect = Rect2(-2500, -700, 5000, 1400)
	sparks.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sparks.z_index = 4
	add_child(sparks)
	sparks.restart()
	sparks.emitting = true


static func _bank() -> void:
	if banked:
		return
	banked = true
	blade_tex = _white_tex(int(TEX), int(TEX))
	spark_tex = _white_tex(12, 36)
	spark_draw = ShaderMaterial.new()
	spark_draw.shader = SPARK_SHADER
	spark_motion = ParticleProcessMaterial.new()
	spark_motion.particle_flag_disable_z = true
	spark_motion.particle_flag_align_y = true
	spark_motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_motion.emission_sphere_radius = 8.0
	spark_motion.direction = Vector3(0, -1, 0)
	spark_motion.spread = 64.0
	spark_motion.gravity = Vector3(0, 340, 0)
	spark_motion.initial_velocity_min = 80.0
	spark_motion.initial_velocity_max = 230.0
	spark_motion.damping_min = 1.6
	spark_motion.damping_max = 3.0
	spark_motion.scale_min = 0.55
	spark_motion.scale_max = 1.15
	spark_motion.color = Color(1, 1, 1, 1)
	spark_motion.color_ramp = _spark_ramp()


static func _spark_ramp() -> GradientTexture1D:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(1, 0.45, 0.08, 0))
	grad.add_point(0.4, Color(1, 0.92, 0.62, 1))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 48
	return tex


static func _white_tex(w: int, h: int) -> Texture2D:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


class SlashEdge extends Node2D:
	var pts: PackedVector2Array = PackedVector2Array()
	var fade: float = 1.0

	func _draw() -> void:
		if fade <= 0.02 or pts.size() < 2:
			return
		var gold := Color(1.0, 0.62, 0.16, fade)
		var white := Color(1.0, 0.98, 0.9, fade)
		draw_polyline(pts, gold, 10.0, true)
		draw_polyline(pts, white, 3.4, true)
