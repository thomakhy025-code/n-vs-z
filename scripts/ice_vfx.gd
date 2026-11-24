extends Node2D

# Pale cyan ice cones on every road, from the caster toward the enemy.
# Each cone starts small and grows as it rises. Distance from the caster
# picks the finished size, on the same curve every cast. The tip still
# rises, overshoots, holds, and sinks. Cracks, chips, and frost follow.
# Shards stay pale cyan with a cold blue core and a hard white rim.

const SPIKE_SHADER = preload("res://shaders/ice_spike.gdshader")
const CHIP_SHADER = preload("res://shaders/ice_chip.gdshader")
const MIST_SHADER = preload("res://shaders/ice_mist.gdshader")
const GLAZE_SHADER = preload("res://shaders/ice_glaze.gdshader")

const CONES := 14
const MARKS := 6
const CHIPS := 36
const MIST := 16
const POP := 0.30
const STAGGER := 0.80
const HOLD := 4.90
const LIFE := 6.05
const CHIP_LIFE := 1.25
const MIST_LIFE := 1.50
const EMIT_AT := 0.08
const CHIP_STOP := 0.92
const MIST_STOP := 1.05
const NEAR_TALL := 62.0
const FAR_TALL := 204.0
const NEAR_WIDE := 12.0
const FAR_WIDE := 40.0
const START_BULK := 0.22

static var banked: bool = false
static var chip_motion: ParticleProcessMaterial
static var mist_motion: ParticleProcessMaterial
static var chip_draw: ShaderMaterial
static var mist_draw: ShaderMaterial
static var white_tex: Texture2D
static var live: Array = []

var age: float = 0.0
var blow: float = 1.0
var span: float = 0.0
var full: float = 1.0
var cones: Array = []
var marks: Array = []
var drifts: Array = []


static func play(host: Node, from_x: float, road_ys: Array, blow_dir: float, reach: float, full_reach: float) -> void:
	if host == null:
		return
	_bank()
	var stale: Array = []
	for item in live:
		if not is_instance_valid(item):
			stale.append(item)
	for gone in stale:
		live.erase(gone)
	while live.size() >= 3:
		var old: Variant = live.pop_front()
		if old is Node and is_instance_valid(old):
			(old as Node).queue_free()
	var script: GDScript = load("res://scripts/ice_vfx.gd")
	var rig: Node2D = script.new() as Node2D
	if rig == null:
		return
	host.add_child(rig)
	rig.z_index = 470
	rig.position = Vector2(from_x, 0.0)
	rig.call("setup", blow_dir, reach, full_reach, road_ys)
	live.append(rig)


func setup(blow_dir: float, reach: float, full_reach: float, road_ys: Array) -> void:
	blow = 1.0
	if blow_dir < 0.0:
		blow = -1.0
	span = reach
	if span < 0.0:
		span = 0.0
	full = full_reach
	if full < span:
		full = span
	if full < 1.0:
		full = 1.0
	var r: int = 0
	while r < road_ys.size():
		var road_y: float = float(road_ys[r])
		_build_marks(r, road_y)
		_build_cones(r, road_y)
		_build_drift(r, road_y)
		r += 1


func _process(delta: float) -> void:
	age += delta
	var i: int = 0
	while i < cones.size():
		var row: Dictionary = cones[i]
		var node_v: Variant = row.get("node", null)
		if node_v is Polygon2D:
			var cone: Polygon2D = node_v
			var delay: float = float(row.get("delay", 0.0))
			var tall: float = float(row.get("tall", 160.0))
			var lift: float = _lift(age, delay)
			var bulk: float = _bulk(lift)
			var rest_v: Variant = row.get("rest", Vector2.ZERO)
			var rest := Vector2.ZERO
			if rest_v is Vector2:
				rest = rest_v
			var drop: float = _drop(lift, tall)
			cone.scale = Vector2(bulk, bulk)
			cone.position = rest + Vector2(0.0, drop + tall * (bulk - 1.0))
			var fade: float = 1.0
			if lift < 0.02:
				fade = 0.0
			cone.modulate = Color(1.0, 1.0, 1.0, fade)
			var mat_v: Variant = row.get("mat", null)
			if mat_v is ShaderMaterial:
				var ice_mat: ShaderMaterial = mat_v
				var floor_y: float = float(row.get("road_y", 0.0))
				var clip: float = floor_y + 8.0 - cone.position.y
				ice_mat.set_shader_parameter("clip_local", clip / bulk)
			var lean: float = float(row.get("lean", 0.0))
			var sink_at: float = HOLD + delay * 0.72
			if age > delay + POP and age < sink_at:
				cone.rotation = lean + sin(age * 17.0 + delay * 30.0) * 0.018
			else:
				cone.rotation = lean
		i += 1
	_sync_marks()
	_sync_emitters()
	if cones.is_empty() and age > 0.25:
		queue_free()
		return
	if age > LIFE:
		queue_free()


func _exit_tree() -> void:
	var d: int = 0
	while d < drifts.size():
		var drift: Dictionary = drifts[d]
		var chip_v: Variant = drift.get("chips", null)
		if chip_v is GPUParticles2D:
			(chip_v as GPUParticles2D).emitting = false
		var mist_v: Variant = drift.get("mist", null)
		if mist_v is GPUParticles2D:
			(mist_v as GPUParticles2D).emitting = false
		d += 1
	live.erase(self)


func _drop(lift: float, tall: float) -> float:
	var bury: float = tall * 1.08
	var extra: float = tall * 0.07
	if lift <= 1.0:
		return bury * (1.0 - lift)
	return -extra * ((lift - 1.0) / 0.16)


func _lift(now: float, delay: float) -> float:
	var local: float = now - delay
	if local <= 0.0:
		return 0.0
	var over: float = POP * 0.42
	if local < over:
		var rise: float = local / over
		var eased: float = 1.0 - pow(1.0 - rise, 3.0)
		return 1.16 * eased
	if local < POP:
		var settle: float = (local - over) / (POP - over)
		return lerpf(1.16, 1.0, settle * settle)
	var sink_at: float = HOLD + delay * 0.72
	if now < sink_at:
		return 1.0 + sin(now * 23.0 + delay * 40.0) * 0.02
	var sink_u: float = (now - sink_at) / 0.36
	if sink_u >= 1.0:
		return 0.0
	if sink_u < 0.28:
		return lerpf(1.0, 1.10, sink_u / 0.28)
	return lerpf(1.10, 0.0, (sink_u - 0.28) / 0.72)


func _bulk(lift: float) -> float:
	if lift <= 0.0:
		return START_BULK
	if lift <= 1.0:
		return lerpf(START_BULK, 1.0, lift)
	var over: float = (lift - 1.0) / 0.16
	if over > 1.0:
		over = 1.0
	return lerpf(1.0, 1.08, over)


func _swell(dist: float) -> float:
	var t: float = 0.0
	if full > 1.0:
		t = dist / full
	if t < 0.0:
		t = 0.0
	if t > 1.0:
		t = 1.0
	return pow(t, 1.25)


func _row_head() -> float:
	if span <= 16.0:
		return 0.0
	var lead: float = 8.0
	var cap: float = span * 0.06
	if lead > cap:
		lead = cap
	return lead


func _row_tail() -> float:
	if span <= 28.0:
		return span
	var inset: float = 12.0
	var cap: float = span * 0.08
	if inset > cap:
		inset = cap
	return span - inset


func _axis_dist(along: float) -> float:
	var head: float = _row_head()
	var tail: float = _row_tail()
	if tail < head:
		tail = head
	return lerpf(head, tail, along)


func _place_x(along: float, salt: int) -> float:
	var dist: float = _axis_dist(along) + lerpf(-6.0, 6.0, _hash(salt))
	if dist < 0.0:
		dist = 0.0
	if dist > span:
		dist = span
	return blow * dist


func _sync_marks() -> void:
	var m: int = 0
	while m < marks.size():
		var patch: Dictionary = marks[m]
		var mat_v: Variant = patch.get("mat", null)
		var node_v: Variant = patch.get("node", null)
		if (mat_v is ShaderMaterial) and (node_v is Polygon2D):
			var mat: ShaderMaterial = mat_v
			var mark: Polygon2D = node_v
			var delay: float = float(patch.get("delay", 0.0))
			var lift: float = _lift(age, delay)
			var bulk: float = _bulk(lift)
			mark.scale = Vector2(bulk, bulk)
			mat.set_shader_parameter("shown", _mark_shown(age, delay))
		m += 1


func _mark_shown(now: float, delay: float) -> float:
	var local: float = now - delay
	if local <= 0.0:
		return 0.0
	var fade_in: float = clampf(local / 0.16, 0.0, 1.0)
	var sink_at: float = HOLD + delay * 0.72
	if now < sink_at:
		return fade_in
	var fade_out: float = 1.0 - clampf((now - sink_at) / 0.42, 0.0, 1.0)
	return fade_in * fade_out


func _sync_emitters() -> void:
	var travel: float = clampf((age - EMIT_AT) / 0.78, 0.0, 1.0)
	var at: float = blow * _axis_dist(travel)
	var grown: float = _swell(_axis_dist(travel))
	var d: int = 0
	while d < drifts.size():
		var drift: Dictionary = drifts[d]
		var chip_v: Variant = drift.get("chips", null)
		var mist_v: Variant = drift.get("mist", null)
		var road_y: float = float(drift.get("y", 0.0))
		if chip_v is GPUParticles2D:
			var chips: GPUParticles2D = chip_v
			chips.position = Vector2(at, road_y - 6.0)
			var motion_v: Variant = chips.process_material
			if motion_v is ParticleProcessMaterial:
				var motion: ParticleProcessMaterial = motion_v
				motion.scale_min = lerpf(0.42, 1.15, grown)
				motion.scale_max = lerpf(0.95, 2.05, grown)
			var chips_on: bool = bool(drift.get("chips_on", false))
			if age >= EMIT_AT and age < CHIP_STOP:
				if not chips_on:
					chips.restart()
					chips.emitting = true
					drift["chips_on"] = true
			elif chips_on:
				chips.emitting = false
				drift["chips_on"] = false
		if mist_v is GPUParticles2D:
			var mist: GPUParticles2D = mist_v
			mist.position = Vector2(at, road_y - 2.0)
			var mist_on: bool = bool(drift.get("mist_on", false))
			if age >= EMIT_AT and age < MIST_STOP:
				if not mist_on:
					mist.restart()
					mist.emitting = true
					drift["mist_on"] = true
			elif mist_on:
				mist.emitting = false
				drift["mist_on"] = false
		d += 1


func _build_marks(road_i: int, road_y: float) -> void:
	var m: int = 0
	while m < MARKS:
		var along: float = 0.0
		if MARKS > 1:
			along = float(m) / float(MARKS - 1)
		var swell: float = _swell(_axis_dist(along))
		var wide: float = span / float(MARKS) * lerpf(0.85, 1.75, swell)
		if wide < 8.0:
			wide = 8.0
		var poly := Polygon2D.new()
		var half: float = wide * 0.5
		poly.polygon = PackedVector2Array([
			Vector2(-half, -10.0),
			Vector2(half, -10.0),
			Vector2(half, 18.0),
			Vector2(-half, 18.0),
		])
		poly.uv = PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(1.0, 0.0),
			Vector2(1.0, 1.0),
			Vector2(0.0, 1.0),
		])
		var mat := ShaderMaterial.new()
		mat.shader = GLAZE_SHADER
		mat.set_shader_parameter("seed", float(m) * 1.7 + float(road_i) * 0.35)
		mat.set_shader_parameter("shown", 0.0)
		poly.material = mat
		poly.position = Vector2(_place_x(along, m * 19 + road_i * 7), road_y)
		poly.scale = Vector2(START_BULK, START_BULK)
		poly.z_index = road_i * 40 - 3
		add_child(poly)
		marks.append({
			"node": poly,
			"mat": mat,
			"delay": along * STAGGER,
		})
		m += 1


func _build_cones(road_i: int, road_y: float) -> void:
	var i: int = 0
	while i < CONES:
		var along: float = 0.0
		if CONES > 1:
			along = float(i) / float(CONES - 1)
		var dist: float = _axis_dist(along)
		var swell: float = _swell(dist)
		var tall: float = lerpf(NEAR_TALL, FAR_TALL, swell)
		var wide: float = lerpf(NEAR_WIDE, FAR_WIDE, swell)
		var salt: int = i + road_i * 29
		var poly := Polygon2D.new()
		var pts: PackedVector2Array = _cone_points(wide, tall, salt)
		poly.polygon = pts
		poly.uv = _cone_uv(pts)
		poly.color = Color(0.82, 0.95, 1.0, 1.0)
		var mat := ShaderMaterial.new()
		mat.shader = SPIKE_SHADER
		mat.set_shader_parameter("core_mix", 0.35 + _hash(salt * 17 + 3) * 0.45)
		mat.set_shader_parameter("clip_local", 8.0)
		poly.material = mat
		var lean: float = blow * deg_to_rad(lerpf(-14.0, 18.0, _hash(salt * 5 + 8)) - 2.0)
		var home := Vector2(_place_x(along, salt * 13 + 2), road_y + 3.0)
		var start_drop: float = _drop(0.0, tall)
		poly.scale = Vector2(START_BULK, START_BULK)
		poly.position = home + Vector2(0.0, start_drop + tall * (START_BULK - 1.0))
		poly.rotation = lean
		poly.modulate = Color(1.0, 1.0, 1.0, 0.0)
		poly.z_index = road_i * 40 + i
		add_child(poly)
		cones.append({
			"node": poly,
			"mat": mat,
			"delay": along * STAGGER,
			"lean": lean,
			"tall": tall,
			"rest": home,
			"road_y": road_y,
		})
		i += 1


func _build_drift(road_i: int, road_y: float) -> void:
	var chips := GPUParticles2D.new()
	var motion: ParticleProcessMaterial = chip_motion.duplicate() as ParticleProcessMaterial
	motion.direction = Vector3(blow * 0.62, -1.0, 0.0)
	chips.process_material = motion
	chips.material = chip_draw
	chips.texture = white_tex
	chips.amount = CHIPS
	chips.lifetime = CHIP_LIFE
	chips.one_shot = false
	chips.explosiveness = 0.2
	chips.randomness = 0.4
	chips.emitting = false
	chips.local_coords = false
	chips.visibility_rect = Rect2(-800.0, -520.0, 1600.0, 980.0)
	chips.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	chips.z_index = road_i * 40 + 18
	chips.position = Vector2(blow * _row_head(), road_y - 6.0)
	add_child(chips)
	var mist := GPUParticles2D.new()
	var haze: ParticleProcessMaterial = mist_motion.duplicate() as ParticleProcessMaterial
	haze.direction = Vector3(blow * 0.22, -1.0, 0.0)
	mist.process_material = haze
	mist.material = mist_draw
	mist.texture = white_tex
	mist.amount = MIST
	mist.lifetime = MIST_LIFE
	mist.one_shot = false
	mist.explosiveness = 0.08
	mist.randomness = 0.45
	mist.emitting = false
	mist.local_coords = false
	mist.visibility_rect = Rect2(-800.0, -420.0, 1600.0, 860.0)
	mist.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mist.z_index = road_i * 40 - 1
	mist.position = Vector2(blow * _row_head(), road_y - 2.0)
	add_child(mist)
	drifts.append({
		"chips": chips,
		"mist": mist,
		"chips_on": false,
		"mist_on": false,
		"y": road_y,
	})


func _cone_points(wide: float, tall: float, salt: int) -> PackedVector2Array:
	var a: float = _hash(salt * 3 + 1)
	var b: float = _hash(salt * 3 + 2)
	var c: float = _hash(salt * 3 + 4)
	var pts := PackedVector2Array()
	pts.append(Vector2(-wide * 0.46, tall * 0.06))
	pts.append(Vector2(-wide * lerpf(0.82, 1.12, a), -tall * lerpf(0.18, 0.34, b)))
	pts.append(Vector2(-wide * lerpf(0.22, 0.5, c), -tall * lerpf(0.56, 0.74, a)))
	pts.append(Vector2(wide * lerpf(-0.08, 0.12, b), -tall))
	pts.append(Vector2(wide * lerpf(0.26, 0.55, a), -tall * lerpf(0.52, 0.72, c)))
	pts.append(Vector2(wide * lerpf(0.78, 1.08, b), -tall * lerpf(0.16, 0.32, c)))
	pts.append(Vector2(wide * 0.42, tall * 0.06))
	return pts


func _cone_uv(pts: PackedVector2Array) -> PackedVector2Array:
	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var min_y: float = pts[0].y
	var max_y: float = pts[0].y
	var n: int = 1
	while n < pts.size():
		var p: Vector2 = pts[n]
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
		n += 1
	var uv := PackedVector2Array()
	var k: int = 0
	var span_x: float = maxf(max_x - min_x, 0.001)
	var span_y: float = maxf(max_y - min_y, 0.001)
	while k < pts.size():
		var q: Vector2 = pts[k]
		uv.append(Vector2((q.x - min_x) / span_x, (q.y - min_y) / span_y))
		k += 1
	return uv


func _hash(salt: int) -> float:
	var n: int = salt * 1103515245 + 12345
	if n < 0:
		n = -n
	return float(n % 1000) / 999.0


static func _bank() -> void:
	if banked:
		return
	banked = true
	white_tex = _white_tex(32)
	chip_draw = ShaderMaterial.new()
	chip_draw.shader = CHIP_SHADER
	mist_draw = ShaderMaterial.new()
	mist_draw.shader = MIST_SHADER
	chip_motion = _chip_motion()
	mist_motion = _mist_motion()


static func _chip_motion() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0
	mat.direction = Vector3(0.5, -1.0, 0.0)
	mat.spread = 24.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 170.0
	mat.gravity = Vector3(0.0, 680.0, 0.0)
	mat.damping_min = 0.55
	mat.damping_max = 1.15
	mat.radial_velocity_min = 40.0
	mat.radial_velocity_max = 120.0
	mat.radial_velocity_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.12, 0.3),
		Vector2(0.32, 0.0),
		Vector2(1.0, 0.0),
	]))
	mat.angle_min = -180.0
	mat.angle_max = 180.0
	mat.angular_velocity_min = -160.0
	mat.angular_velocity_max = 160.0
	mat.scale_min = 0.55
	mat.scale_max = 1.35
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.55, 0.9),
		Vector2(1.0, 0.08),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(0.6, 0.85),
		Vector2(1.0, 0.0),
	]))
	return mat


static func _mist_motion() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 18.0
	mat.direction = Vector3(0.2, -1.0, 0.0)
	mat.spread = 36.0
	mat.initial_velocity_min = 16.0
	mat.initial_velocity_max = 42.0
	mat.gravity = Vector3(0.0, -16.0, 0.0)
	mat.damping_min = 0.35
	mat.damping_max = 0.7
	mat.scale_min = 1.15
	mat.scale_max = 2.05
	mat.scale_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.35),
		Vector2(0.3, 1.0),
		Vector2(1.0, 1.0),
	]))
	mat.color = Color(1, 1, 1, 1)
	mat.alpha_curve = _curve(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.16, 1.0),
		Vector2(0.7, 0.45),
		Vector2(1.0, 0.0),
	]))
	return mat


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
	tex.width = 64
	return tex


static func _white_tex(side: int) -> Texture2D:
	var img: Image = Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
