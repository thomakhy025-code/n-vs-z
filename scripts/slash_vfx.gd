extends Node2D

# Light smashing, matched to the crescent in the Godot slash short.
# One shared crescent shader, a hard edge on top of it, a short streak
# burst at the leading foot, and a jagged fissure that stays on the road.
# The hero sprite is not replaced. Nothing here is allocated per cast
# except the rig that restarts the shared materials.

const BLADE_SHADER = preload("res://shaders/slash_blade.gdshader")
const EDGE_SHADER = preload("res://shaders/slash_edge.gdshader")
const SPARK_SHADER = preload("res://shaders/slash_spark.gdshader")

const TRAVEL := 0.42
const LIFE := 1.95
const SPARK_LIFE := 0.16
const SPARK_COUNT := 42
const BLADE_W := 420.0
const BLADE_H := 360.0
const TEX := 8.0
const TIP_PLANE := Vector2(0.72, 0.10)
const BELLY_PLANE := Vector2(0.40, 0.42)
const FOOT_PLANE := Vector2(0.80, 0.78)

static var banked: bool = false
static var spark_motion: ParticleProcessMaterial
static var spark_draw: ShaderMaterial
static var edge_draw: ShaderMaterial
static var spark_tex: Texture2D
static var blade_tex: Texture2D
static var crescent: Texture2D
static var crescent_ready: bool = false
static var crescent_failed: bool = false
static var sheet_mat: ShaderMaterial
static var live: Array = []

var age: float = 0.0
var origin_x: float = 0.0
var dest_x: float = 0.0
var road_y: float = 0.0
var blow: float = 1.0
var mote_at: float = -1.0
var settle: Vector3 = Vector3(0, 0, -1)
var crack_pts: PackedVector2Array = PackedVector2Array()
var forks: Array = []
var motes: Array = []
var blade: Sprite2D
var blade_mat: ShaderMaterial
var edge: SlashEdge
var sparks: GPUParticles2D
var using_sheet: bool = false


static func warm(host: Node) -> void:
	if host == null:
		return
	_bank()
	if crescent_ready or crescent_failed:
		return
	if host.get_node_or_null("CrescentBake") != null:
		return
	var node := CrescentBake.new()
	node.name = "CrescentBake"
	host.add_child(node)


static func play(host: Node, near_x: float, far_x: float, y: float) -> void:
	if host == null:
		return
	warm(host)
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
	_build_crack()
	_build_blade()
	_build_edge()
	_build_sparks()
	_place(0.0)
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	var travel: float = _eased()
	_place(travel)
	_drop_dust(travel)
	if settle.z < 0.0 and age >= 0.5:
		settle = Vector3(_head_x(1.0) - blow * 12.0, road_y + 2.0, age)
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
	return t * (1.08 - 0.08 * t)


func _head_x(travel: float) -> float:
	return lerpf(origin_x, dest_x, travel)


func _blade_fade() -> float:
	if age < 0.03:
		return clampf(age / 0.03, 0.0, 1.0)
	if age < 0.36:
		return 1.0
	if age >= 1.0:
		return 0.0
	return clampf(1.0 - (age - 0.36) / 0.64, 0.0, 1.0)


func _flash() -> float:
	if age < 0.07:
		return 1.75
	if age < TRAVEL:
		return lerpf(1.5, 1.08, age / TRAVEL)
	return 1.0


func _rush() -> float:
	if age <= TRAVEL:
		return 1.0
	return clampf(1.0 - (age - TRAVEL) / 0.48, 0.18, 1.0)


func _place(travel: float) -> void:
	var head: float = _head_x(travel)
	var fade: float = _blade_fade()
	var grow: float = clampf(0.92 + 0.08 * minf(age / 0.05, 1.0), 0.92, 1.0)
	if not using_sheet and crescent != null:
		_use_sheet()
	if blade != null:
		blade.visible = fade > 0.012
		var sx: float = blow * grow * BLADE_W / TEX
		var sy: float = grow * BLADE_H / TEX
		if using_sheet and blade.texture != null:
			sx = blow * grow * BLADE_W / float(blade.texture.get_width())
			sy = grow * BLADE_H / float(blade.texture.get_height())
		blade.scale = Vector2(sx, sy)
		var foot_u: float = FOOT_PLANE.x
		var foot_v: float = FOOT_PLANE.y * BLADE_W / BLADE_H
		var foot_x: float = (foot_u - 0.5) * BLADE_W * grow * blow
		var foot_y: float = (foot_v - 0.5) * BLADE_H * grow
		blade.position = Vector2(head - foot_x, road_y - foot_y)
		if using_sheet:
			blade.modulate = Color(1, 1, 1, fade)
		elif blade_mat != null:
			blade_mat.set_shader_parameter("fade", fade)
			blade_mat.set_shader_parameter("flash", _flash())
			blade_mat.set_shader_parameter("rush", _rush())
	if edge != null:
		if using_sheet:
			edge.visible = false
		else:
			edge.visible = fade > 0.012
			edge.pts = _edge_points(head, grow)
			edge.fade = fade
			edge.queue_redraw()
	if sparks != null:
		sparks.position = Vector2(head, road_y - 2.0)


func _draw() -> void:
	var travel: float = _eased()
	if travel < 0.02 and age < 0.02:
		return
	var head: float = _head_x(travel)
	_draw_crack(head)
	_draw_dust()


func _core_alpha() -> float:
	if age < 0.04:
		return clampf(age / 0.04, 0.0, 1.0)
	if age < 1.25:
		return 1.0
	var span: float = LIFE - 1.25
	if span <= 0.001:
		return 0.0
	return clampf(lerpf(0.9, 0.07, (age - 1.25) / span), 0.0, 1.0)


func _split_alpha() -> float:
	if age < 0.05:
		return clampf(age / 0.05, 0.0, 1.0)
	if age < 1.2:
		return 1.0
	if age > 1.55:
		return 0.0
	return clampf(1.0 - (age - 1.2) / 0.35, 0.0, 1.0)


func _draw_crack(head: float) -> void:
	var hot: float = _core_alpha()
	var split_a: float = _split_alpha()
	if hot <= 0.02 and split_a <= 0.02:
		return
	var shown: PackedVector2Array = _until(crack_pts, head)
	if shown.size() < 2:
		return
	var pulse: float = 0.9 + 0.1 * sin(age * 10.0)
	var glow: float = hot * pulse
	var Stamp = preload("res://scripts/stamp_bake.gd")
	Stamp.ensure()
	if glow > 0.03:
		Stamp.stroke(self, shown, 34.0, Color(1.0, 0.42, 0.04, 0.5 * glow))
	if split_a > 0.04:
		Stamp.stroke(self, shown, 18.0, Color(0.01, 0.004, 0.002, 0.94 * split_a))
	if glow > 0.03:
		Stamp.stroke(self, shown, 8.0, Color(1.0, 0.45, 0.04, glow))
		Stamp.stroke(self, shown, 3.8, Color(1.0, 0.86, 0.28, glow))
		Stamp.stroke(self, shown, 1.6, Color(1.0, 0.98, 0.9, glow))
	if glow < 0.45:
		return
	var index: int = 0
	while index < forks.size():
		var fork: PackedVector2Array = forks[index]
		if fork.size() >= 2 and _passed(fork[0], head):
			Stamp.stroke(self, fork, 9.0, Color(1.0, 0.48, 0.06, 0.48 * glow))
			if split_a > 0.05:
				Stamp.stroke(self, fork, 6.8, Color(0.012, 0.005, 0.002, 0.9 * split_a))
			Stamp.stroke(self, fork, 2.8, Color(1.0, 0.78, 0.18, glow))
			Stamp.stroke(self, fork, 1.15, Color(1.0, 0.97, 0.88, glow))
		index += 1


func _draw_dust() -> void:
	var index: int = 0
	while index < motes.size():
		var mote: Vector3 = motes[index]
		_puff(Vector2(mote.x, mote.y), age - mote.z, 0.8, 7.0, 22.0)
		index += 1
	if settle.z >= 0.0:
		_puff(Vector2(settle.x, settle.y), age - settle.z, 0.7, 9.0, 28.0)


func _puff(at: Vector2, lived: float, life: float, r0: float, r1: float) -> void:
	if lived < 0.0 or lived > life:
		return
	var u: float = lived / life
	var fade: float = (1.0 - u) * (1.0 - u)
	var rad: float = lerpf(r0, r1, u)
	var center := Vector2(at.x, at.y - lived * 10.0)
	var Stamp = preload("res://scripts/stamp_bake.gd")
	Stamp.ensure()
	Stamp.disc(self, center, rad, Color(0.55, 0.48, 0.38, 0.5 * fade))
	Stamp.disc(self, center + Vector2(0.0, -1.5), rad * 0.48, Color(0.82, 0.76, 0.66, 0.42 * fade))


func _drop_dust(travel: float) -> void:
	if travel <= 0.04 or age > TRAVEL:
		return
	if mote_at >= 0.0 and age - mote_at < 0.06:
		return
	if motes.size() >= 8:
		return
	mote_at = age
	var head: float = _head_x(travel)
	motes.append(Vector3(head - blow * 18.0, road_y + 4.0, age))


func _passed(at: Vector2, head: float) -> bool:
	var along: float = (at.x - origin_x) * blow
	var limit: float = (head - origin_x) * blow
	return along <= limit + 4.0


func _until(pts: PackedVector2Array, head: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var limit: float = (head - origin_x) * blow
	var count: int = pts.size()
	var index: int = 0
	while index < count:
		var at: Vector2 = pts[index]
		var along: float = (at.x - origin_x) * blow
		if along <= limit + 0.01:
			out.append(at)
		else:
			if index > 0:
				var prev: Vector2 = pts[index - 1]
				var prev_along: float = (prev.x - origin_x) * blow
				var span: float = along - prev_along
				var u: float = 0.0
				if span > 0.001:
					u = clampf((limit - prev_along) / span, 0.0, 1.0)
				out.append(prev.lerp(at, u))
			break
		index += 1
	return out


func _ribbon(pts: PackedVector2Array, half: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var count: int = pts.size()
	if count < 2:
		return poly
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var index: int = 0
	while index < count:
		var prev: Vector2 = pts[maxi(index - 1, 0)]
		var nxt: Vector2 = pts[mini(index + 1, count - 1)]
		var dir: Vector2 = nxt - prev
		if dir.length_squared() < 0.0001:
			dir = Vector2(blow, 0.0)
		dir = dir.normalized()
		var normal := Vector2(-dir.y, dir.x)
		left.append(pts[index] + normal * half)
		right.append(pts[index] - normal * half)
		index += 1
	index = 0
	while index < count:
		poly.append(left[index])
		index += 1
	index = count - 1
	while index >= 0:
		poly.append(right[index])
		index -= 1
	return poly


func _fill(poly: PackedVector2Array, tint: Color) -> void:
	if poly.size() < 3 or tint.a <= 0.01:
		return
	var cols := PackedColorArray()
	var index: int = 0
	while index < poly.size():
		cols.append(tint)
		index += 1
	draw_polygon(poly, cols)


func _build_crack() -> void:
	crack_pts = _crack_points(origin_x, dest_x, 22.0)
	forks.clear()
	var index: int = 4
	var made: int = 0
	while index < crack_pts.size() - 2 and made < 7:
		forks.append(_branch_at(crack_pts[index], index))
		index += 4
		made += 1


func _seed() -> int:
	var sx: int = int(absf(origin_x)) + int(absf(road_y) * 3.0)
	return sx % 97 + 1


func _jag_at(index: int, seed: int) -> float:
	var n: int = index * 19 + seed * 7 + 11
	n = (n * 1103515245 + 12345) & 2147483647
	var slot: int = n % 9
	var table := PackedFloat32Array([0.15, -1.0, 0.7, -0.32, 1.0, -0.8, 0.38, -0.12, 0.88])
	var pick: float = table[slot]
	var fine: float = float((n / 9) % 100) / 100.0 - 0.5
	return pick * 0.86 + fine * 0.18


func _crack_points(x_from: float, x_to: float, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps: int = 26
	var seed: int = _seed()
	var index: int = 0
	while index <= steps:
		var t: float = float(index) / float(steps)
		var x: float = lerpf(x_from, x_to, t)
		var jag: float = 0.0
		if index != 0 and index != steps:
			jag = _jag_at(index, seed) * amp
		pts.append(Vector2(x, road_y + jag))
		index += 1
	return pts


func _branch_at(at: Vector2, index: int) -> PackedVector2Array:
	var seed: int = _seed() + index * 3
	var n: int = (index * 31 + seed * 5) & 255
	var lift: float = 18.0 + float(n % 22)
	if n % 2 == 0:
		lift = -lift
	var fwd: float = blow * (6.0 + float((n / 3) % 12))
	var kink: float = _jag_at(index, seed) * 7.0
	var pts := PackedVector2Array()
	pts.append(at)
	pts.append(Vector2(at.x + fwd * 0.45, at.y + lift * 0.5 + kink * 0.4))
	pts.append(Vector2(at.x + fwd, at.y + lift + kink))
	return pts


func _paint_line(pts: PackedVector2Array, width: float, color: Color) -> void:
	if pts.size() < 2 or color.a <= 0.01:
		return
	draw_polyline(pts, color, width, true)


func _edge_points(head: float, grow: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps: int = 32
	var index: int = 0
	while index <= steps:
		var t: float = float(index) / float(steps)
		var u: float = 1.0 - t
		var p: Vector2 = TIP_PLANE * u * u + BELLY_PLANE * 2.0 * u * t + FOOT_PLANE * t * t
		var x: float = head + (p.x - FOOT_PLANE.x) * BLADE_W * grow * blow
		var y: float = road_y + (p.y - FOOT_PLANE.y) * BLADE_W * grow
		pts.append(Vector2(x, y))
		index += 1
	return pts


func _build_edge() -> void:
	edge = SlashEdge.new()
	edge.z_index = 3
	edge.material = edge_draw
	add_child(edge)


func _build_blade() -> void:
	blade = Sprite2D.new()
	blade.centered = true
	blade.z_index = 2
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	blade.texture = blade_tex
	_use_sheet()
	add_child(blade)


func _use_sheet() -> void:
	if blade == null or crescent == null or sheet_mat == null:
		if blade != null and blade.material == null:
			blade_mat = ShaderMaterial.new()
			blade_mat.shader = BLADE_SHADER
			blade_mat.set_shader_parameter("fade", 1.0)
			blade_mat.set_shader_parameter("flash", 1.0)
			blade_mat.set_shader_parameter("rush", 1.0)
			blade.material = blade_mat
			blade.texture = blade_tex
		return
	blade.texture = crescent
	blade.material = sheet_mat
	blade_mat = null
	using_sheet = true
	if edge != null:
		edge.visible = false


func _build_sparks() -> void:
	sparks = GPUParticles2D.new()
	var copied: ParticleProcessMaterial = spark_motion.duplicate() as ParticleProcessMaterial
	copied.direction = Vector3(-blow * 0.3, -1.0, 0.0)
	copied.spread = 100.0
	sparks.process_material = copied
	sparks.material = spark_draw
	sparks.texture = spark_tex
	sparks.amount = SPARK_COUNT
	sparks.lifetime = SPARK_LIFE
	sparks.one_shot = false
	sparks.explosiveness = 0.0
	sparks.randomness = 0.45
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
	spark_tex = _white_tex(8, 72)
	spark_draw = ShaderMaterial.new()
	spark_draw.shader = SPARK_SHADER
	edge_draw = ShaderMaterial.new()
	edge_draw.shader = EDGE_SHADER
	spark_motion = ParticleProcessMaterial.new()
	spark_motion.particle_flag_disable_z = true
	spark_motion.particle_flag_align_y = true
	spark_motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_motion.emission_sphere_radius = 5.0
	spark_motion.direction = Vector3(0, -1, 0)
	spark_motion.spread = 100.0
	spark_motion.gravity = Vector3(0, 80, 0)
	spark_motion.initial_velocity_min = 240.0
	spark_motion.initial_velocity_max = 760.0
	spark_motion.damping_min = 1.1
	spark_motion.damping_max = 2.6
	spark_motion.scale_min = 0.85
	spark_motion.scale_max = 1.7
	spark_motion.color = Color(1, 1, 1, 1)
	spark_motion.color_ramp = _spark_ramp()
	var sheet_shader := Shader.new()
	sheet_shader.code = "shader_type canvas_item;\nrender_mode blend_add;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tif (dot(tex.rgb, vec3(1.0)) < 0.004) {\n\t\tdiscard;\n\t}\n\tCOLOR = vec4(tex.rgb * COLOR.a, 1.0);\n}\n"
	sheet_mat = ShaderMaterial.new()
	sheet_mat.shader = sheet_shader


static func _spark_ramp() -> GradientTexture1D:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.add_point(0.18, Color(1, 0.96, 0.72, 1))
	grad.add_point(0.55, Color(1, 0.58, 0.1, 0.55))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(1, 0.4, 0.05, 0))
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
		draw_polyline(pts, Color(1.0, 0.72, 0.14, fade), 13.0, true)
		draw_polyline(pts, Color(1.0, 1.0, 0.97, fade), 4.2, true)


class CrescentBake extends Node:
	var vp: SubViewport
	var step: int = 0
	var tries: int = 0

	func _ready() -> void:
		var baker = load("res://scripts/slash_vfx.gd")
		vp = SubViewport.new()
		vp.disable_3d = true
		vp.transparent_bg = true
		vp.use_hdr_2d = false
		vp.handle_input_locally = false
		vp.gui_disable_input = true
		vp.msaa_2d = Viewport.MSAA_DISABLED
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.size = Vector2i(420, 360)
		add_child(vp)
		var root := Node2D.new()
		vp.add_child(root)
		var blade := Sprite2D.new()
		blade.texture = baker.blade_tex
		blade.centered = true
		blade.position = Vector2(210.0, 180.0)
		blade.scale = Vector2(420.0 / 8.0, 360.0 / 8.0)
		blade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var blade_mat := ShaderMaterial.new()
		blade_mat.shader = load("res://shaders/slash_blade.gdshader")
		blade_mat.set_shader_parameter("fade", 1.0)
		blade_mat.set_shader_parameter("flash", 1.4)
		blade_mat.set_shader_parameter("rush", 1.0)
		blade.material = blade_mat
		root.add_child(blade)
		var edge := SlashEdge.new()
		edge.fade = 1.0
		edge.pts = _edge_pts()
		edge.material = baker.edge_draw
		edge.z_index = 2
		root.add_child(edge)

	func _process(_delta: float) -> void:
		if vp == null:
			return
		step += 1
		if step == 1:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return
		var baker = load("res://scripts/slash_vfx.gd")
		if DisplayServer.get_name() == "headless":
			_store(baker, Image.create(420, 360, false, Image.FORMAT_RGBA8), 0)
			queue_free()
			return
		var view_tex := vp.get_texture()
		var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		if view_tex != null:
			var grabbed := view_tex.get_image()
			if grabbed != null:
				img = grabbed
		var seen := _opaque(img)
		if seen == 0 and tries < 4:
			tries += 1
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return
		_store(baker, img, seen)
		queue_free()

	func _store(baker, img: Image, seen: int) -> void:
		if seen == 0 and DisplayServer.get_name() != "headless":
			baker.crescent_failed = true
			baker.crescent = null
			baker.crescent_ready = false
			return
		if seen > 0:
			img.fix_alpha_edges()
		baker.crescent = ImageTexture.create_from_image(img)
		baker.crescent_ready = true
		baker.crescent_failed = false

	func _edge_pts() -> PackedVector2Array:
		var tip := Vector2(0.72, 0.10)
		var belly := Vector2(0.40, 0.42)
		var foot := Vector2(0.80, 0.78)
		var foot_u: float = foot.x
		var foot_v: float = foot.y * 420.0 / 360.0
		var foot_px := Vector2(210.0 + (foot_u - 0.5) * 420.0, 180.0 + (foot_v - 0.5) * 360.0)
		var pts := PackedVector2Array()
		var steps: int = 32
		var index: int = 0
		while index <= steps:
			var t: float = float(index) / float(steps)
			var u: float = 1.0 - t
			var p: Vector2 = tip * u * u + belly * 2.0 * u * t + foot * t * t
			pts.append(foot_px + Vector2((p.x - foot.x) * 420.0, (p.y - foot.y) * 420.0))
			index += 1
		return pts

	func _opaque(img: Image) -> int:
		var count: int = 0
		var w: int = img.get_width()
		var h: int = img.get_height()
		var y: int = 0
		while y < h:
			var x: int = 0
			while x < w:
				if img.get_pixel(x, y).a > 0.04 or img.get_pixel(x, y).r > 0.04:
					count += 1
				x += 6
			y += 6
		return count
