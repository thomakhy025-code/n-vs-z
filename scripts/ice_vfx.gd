extends Node2D

# Freezing, ported from the Ice Pillar Skill (00GameDevs, MIT).
# A wedge of crystals runs forward, a rune and a frost trail sit on the
# road, mist and sparkles drift, then the pillars shatter into chips.
# Side view: forward is along the road, up is up, and the old lateral
# spread is a small overlap on that same road. No browser canvas.

# Copyright (c) 2026 00GameDevs (@00vchannel)
# Ported and adapted for this battle under the MIT License.

const CRYSTAL_SHADER: Shader = preload("res://shaders/ice_crystal.gdshader")
const SHEET_SHADER: Shader = preload("res://shaders/ice_sheet.gdshader")
const GLINT_SHADER: Shader = preload("res://shaders/ice_glint.gdshader")
const SHOCK_SHADER: Shader = preload("res://shaders/ice_shock.gdshader")

const SPIRES := 16
const MISTS := 6
const SPARKS := 6
const SHARD_CAP := 108
const MAX_LEN := 14.0
const MAX_H := 5.2
const SPIRE_PX := 204.0
const UNIT_PX := SPIRE_PX / MAX_H
const ERUPT_T := 0.44 / 1.2
const HOLD_T := 1.6
const SHATTER_T := 1.45
const STEP_T := 1.0 / 120.0
const MIST_DENSITY := 0.65
const SEED := 713

static var banked: bool = false
static var mesh_ready: bool = false
static var frost_tex: Texture2D
static var rune_tex: Texture2D
static var mist_tex: Texture2D
static var spark_tex: Texture2D
static var sheet_mat: ShaderMaterial
static var glint_mat: ShaderMaterial
static var shock_mat: ShaderMaterial
static var spike_pts: PackedVector2Array = PackedVector2Array()
static var spike_uv: PackedVector2Array = PackedVector2Array()
static var spike_out: PackedVector2Array = PackedVector2Array()
static var chip_pts: PackedVector2Array = PackedVector2Array()
static var chip_uv: PackedVector2Array = PackedVector2Array()
static var chip_out: PackedVector2Array = PackedVector2Array()
static var live: Array = []

var span: float = 1.0
var blow: float = 1.0
var rand_state: int = SEED
var acc: float = 0.0
var clock: float = 0.0
var phase: int = 1
var phase_t: float = 0.0
var frost_len: float = 0.01
var frost_alpha: float = 0.0
var rune_scale: float = 0.25
var rune_alpha: float = 1.0
var flash: float = 0.0
var shock_alpha: float = 0.0
var shock_radius: float = 0.0
var spark_cover: float = 0.0
var spark_op: float = 0.92
var show_spires: bool = true
var dying: bool = false
var roads: Array = []
var shards: Array = []
var crystal_mat: ShaderMaterial


class IceSheet extends Node2D:
	var rig: Node2D = null
	var road: int = 0
	var shock: bool = false

	func _draw() -> void:
		if rig == null or not is_instance_valid(rig):
			return
		if shock:
			rig.call("paint_shock", self, road)
		else:
			rig.call("paint_crystals", self, road)


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
	if span < 1.0:
		span = 1.0
	if full_reach > 1.0 and span > full_reach:
		span = full_reach
	rand_state = SEED
	crystal_mat = ShaderMaterial.new()
	crystal_mat.shader = CRYSTAL_SHADER
	crystal_mat.set_shader_parameter("rim_gain", 1.15)
	var road_i: int = 0
	while road_i < road_ys.size():
		_build_road(road_i, float(road_ys[road_i]))
		road_i += 1
	_present()


func _process(delta: float) -> void:
	if dying:
		queue_free()
		return
	var frame: float = delta
	if frame < 0.0:
		return
	if frame > 0.08:
		frame = 0.08
	acc += frame
	var guard: int = 0
	while acc >= STEP_T and guard < 8:
		_simulate(STEP_T)
		acc -= STEP_T
		guard += 1
	if acc > STEP_T * 4.0:
		acc = 0.0
	_present()
	if dying:
		queue_free()


func _exit_tree() -> void:
	live.erase(self)


func _simulate(dt: float) -> void:
	clock += dt
	if phase == 1:
		phase_t += dt
		_erupt(dt)
		if phase_t >= ERUPT_T:
			phase = 2
			phase_t = 0.0
		return
	if phase == 2:
		phase_t += dt
		_hold(dt)
		if phase_t >= HOLD_T:
			_begin_shatter()
		return
	phase_t += dt
	_shatter_motion(dt)
	if phase_t >= SHATTER_T:
		dying = true


func _erupt(dt: float) -> void:
	var progress: float = clampf(phase_t / ERUPT_T, 0.0, 1.0)
	var opened: float = clampf(progress * 2.4, 0.0, 1.0)
	var ease: float = 1.0 - pow(1.0 - opened, 3.0)
	rune_scale = 0.25 + ease * 0.85
	var rune_pulse: float = 0.84 + 0.16 * sin(clock * 11.0)
	rune_alpha = maxf(0.0, (1.0 - progress * 0.35) * rune_pulse)
	var frost_p: float = clampf(progress * 1.15, 0.0, 1.0)
	frost_len = maxf(0.01, span * frost_p)
	frost_alpha = minf(0.92, frost_p * 1.1)
	spark_cover = clampf(progress * 1.5, 0.0, 1.0)
	spark_op = 0.92
	var r: int = 0
	while r < roads.size():
		var road: Dictionary = roads[r]
		var spires: Array = road["spires"]
		var s: int = 0
		while s < spires.size():
			var sp: Dictionary = spires[s]
			var trigger: float = float(sp["trigger"])
			var local_t: float = (progress - trigger) / 0.28
			local_t = clampf(local_t, 0.0, 1.0)
			var grown: Vector2 = _grown(local_t)
			sp["sxz"] = grown.x
			sp["sy"] = grown.y
			spires[s] = sp
			s += 1
		_drift_mist(road["mists"], dt, progress, false, 0.0)
		_drift_sparks(road["sparks"], dt)
		r += 1


func _hold(dt: float) -> void:
	var ratio: float = clampf(phase_t / HOLD_T, 0.0, 1.0)
	var rune_pulse: float = 0.82 + 0.18 * sin(clock * 9.0)
	rune_alpha = maxf(0.0, 0.65 * (1.0 - ratio) * rune_pulse)
	spark_cover = 1.0
	spark_op = 0.92
	var r: int = 0
	while r < roads.size():
		var road: Dictionary = roads[r]
		_drift_mist(road["mists"], dt, 1.0, false, 0.0)
		_drift_sparks(road["sparks"], dt)
		r += 1


func _begin_shatter() -> void:
	phase = 3
	phase_t = 0.0
	show_spires = false
	flash = 1.0
	rune_alpha = 0.0
	shock_alpha = 0.95
	shock_radius = 0.55
	var force: float = 11.0 / 8.5
	shards.clear()
	var r: int = 0
	while r < roads.size():
		var road: Dictionary = roads[r]
		var spires: Array = road["spires"]
		var s: int = spires.size() - 1
		while s >= 0 and shards.size() < SHARD_CAP:
			var sp: Dictionary = spires[s]
			if float(sp["sy"]) > 0.05:
				_burst_spire(sp, force)
			s -= 1
		r += 1
	r = 0
	while r < roads.size():
		var road_b: Dictionary = roads[r]
		var mists: Array = road_b["mists"]
		var m: int = 0
		while m < mists.size():
			var puff: Dictionary = mists[m]
			puff["bx"] = (_unit() - 0.5) * 6.5 * force
			puff["by"] = 1.4 + _unit() * 2.2
			puff["bz"] = (_unit() - 0.3) * 5.0 * force
			mists[m] = puff
			m += 1
		var sparks: Array = road_b["sparks"]
		var k: int = 0
		while k < sparks.size():
			var bit: Dictionary = sparks[k]
			bit["vx"] = (_unit() - 0.5) * 9.0 * force
			bit["vy"] = 3.0 + _unit() * 5.0
			bit["vz"] = (_unit() - 0.2) * 8.0 * force
			sparks[k] = bit
			k += 1
		r += 1


func _shatter_motion(dt: float) -> void:
	var t_norm: float = clampf(phase_t / SHATTER_T, 0.0, 1.0)
	flash = maxf(0.0, 1.0 - phase_t / 0.08)
	var wave: float = clampf(phase_t / 0.48, 0.0, 1.0)
	var remain: float = 1.0 - wave
	shock_radius = 0.55 + 4.3 * (1.0 - remain * remain)
	shock_alpha = 0.95 * (1.0 - wave * wave)
	if wave >= 1.0:
		shock_alpha = 0.0
	frost_alpha = maxf(0.0, 0.92 * (1.0 - t_norm * 1.15))
	rune_alpha = 0.0
	spark_cover = maxf(0.0, 1.0 - t_norm * 1.3)
	spark_op = spark_cover
	var r: int = 0
	while r < roads.size():
		var road: Dictionary = roads[r]
		_drift_mist(road["mists"], dt, 1.0, true, t_norm)
		_drift_sparks(road["sparks"], dt)
		r += 1
	var gravity: float = 24.0 * UNIT_PX
	var n: int = 0
	while n < shards.size():
		var sh: Dictionary = shards[n]
		if not bool(sh["on"]):
			n += 1
			continue
		var life: float = float(sh["life"]) + dt
		var limit: float = float(sh["max"])
		sh["life"] = life
		if limit <= 0.001 or life / limit >= 1.0:
			sh["on"] = false
			shards[n] = sh
			n += 1
			continue
		var vx: float = float(sh["vx"])
		var vy: float = float(sh["vy"]) + gravity * dt
		var px: float = float(sh["x"]) + vx * dt
		var py: float = float(sh["y"]) + vy * dt
		var ground: float = float(sh["ground"])
		var spin: float = float(sh["spin"])
		if py >= ground:
			py = ground
			if vy > 0.0:
				vy = -vy * 0.36
				vx *= 0.72
				spin *= 0.65
		sh["vx"] = vx
		sh["vy"] = vy
		sh["x"] = px
		sh["y"] = py
		sh["spin"] = spin
		sh["rot"] = float(sh["rot"]) + spin * dt
		shards[n] = sh
		n += 1


func _drift_mist(mists: Array, dt: float, progress: float, shattering: bool, shatter_t: float) -> void:
	var m: int = 0
	while m < mists.size():
		var puff: Dictionary = mists[m]
		var spawn: float = float(puff["spawn"])
		if not shattering and progress < spawn:
			puff["show"] = false
			mists[m] = puff
			m += 1
			continue
		if shattering:
			puff["x"] = float(puff["x"]) + float(puff["bx"]) * dt
			puff["y"] = float(puff["y"]) + float(puff["by"]) * dt
			puff["z"] = float(puff["z"]) + float(puff["bz"]) * dt
			puff["now"] = float(puff["now"]) * (1.0 + dt * 0.65)
			puff["fade"] = maxf(0.0, (1.0 - shatter_t * 1.45) * 0.48 * MIST_DENSITY)
		else:
			puff["x"] = float(puff["x"]) + float(puff["dx"]) * dt * 0.45
			puff["y"] = float(puff["y"]) + float(puff["dy"]) * dt * 0.45
			puff["z"] = float(puff["z"]) + float(puff["dz"]) * dt * 0.45
			var age: float = clampf((progress - spawn) / 0.35, 0.0, 1.0)
			puff["now"] = float(puff["base"]) * (0.65 + age * 0.55)
			puff["fade"] = age * 0.52 * MIST_DENSITY
		puff["show"] = float(puff["fade"]) > 0.01
		mists[m] = puff
		m += 1


func _drift_sparks(sparks: Array, dt: float) -> void:
	var k: int = 0
	while k < sparks.size():
		var bit: Dictionary = sparks[k]
		bit["x"] = float(bit["x"]) + float(bit["vx"]) * dt
		bit["y"] = float(bit["y"]) + float(bit["vy"]) * dt
		bit["z"] = float(bit["z"]) + float(bit["vz"]) * dt
		sparks[k] = bit
		k += 1


func _burst_spire(sp: Dictionary, force: float) -> void:
	var tall: float = float(sp["height"])
	var pieces: int = 2
	if tall > 3.2:
		pieces = 3
	var room: int = SHARD_CAP - shards.size()
	if pieces > room:
		pieces = room
	if pieces < 1:
		return
	var xf: Transform2D = _pillar(sp)
	var spin_y: float = float(sp["spin"])
	var p: int = 0
	while p < pieces:
		var h_frac: float = (float(p) + 0.2) / float(pieces)
		var lx: float = (_unit() - 0.5) * 0.35
		var lz: float = (_unit() - 0.5) * 0.35
		var ang: float = _unit() * TAU
		var radial: float = (2.6 + _unit() * 5.8) * force
		var lat: float = float(sp["lat"])
		var side_n: float = 0.0
		if absf(lat) < 0.001:
			side_n = _unit() - 0.5
		else:
			side_n = lat
		if side_n < 0.0:
			side_n = -1.0
		elif side_n > 0.0:
			side_n = 1.0
		var vx_w: float = cos(ang) * radial + side_n * 1.2 * force
		var vy_w: float = (3.2 + h_frac * 4.8 + _unit() * 3.5) * force
		var vz_w: float = sin(ang) * radial + (1.8 + _unit() * 3.2) * force
		_unit()
		_unit()
		var rot_z: float = _unit() * 6.28
		_unit()
		_unit()
		var rv_z: float = (_unit() - 0.5) * 18.0
		var chip_s: float = (0.14 + _unit() * 0.22) * (0.7 + float(sp["radius"]) * 0.5)
		var stretch: float = 1.2 + _unit() * 0.9
		var max_life: float = 1.05 + _unit() * 0.45
		var turned: float = cos(spin_y)
		var turned_s: float = sin(spin_y)
		var rx: float = lx * turned + lz * turned_s
		var rz: float = -lx * turned_s + lz * turned
		var at: Vector2 = xf * Vector2(rx, -h_frac)
		at.x += blow * rz * UNIT_PX * float(sp["radius"]) * maxf(float(sp["sxz"]), 0.001)
		var road_y: float = float(sp["road_y"])
		var ceiling: float = road_y - 0.15 * UNIT_PX
		if at.y > ceiling:
			at.y = ceiling
		var px_s: float = chip_s * UNIT_PX
		shards.append({
			"on": true,
			"x": at.x,
			"y": at.y,
			"vx": (blow * vz_w + vx_w * 0.85) * UNIT_PX,
			"vy": -vy_w * UNIT_PX,
			"rot": rot_z,
			"spin": rv_z,
			"sx": px_s,
			"sy": px_s * stretch,
			"life": 0.0,
			"max": max_life,
			"road": int(sp["road"]),
			"ground": road_y - 0.08 * UNIT_PX,
			"seed": _hash(p * 19 + int(sp["road"]) * 7 + int(tall * 10.0)),
		})
		p += 1


func _present() -> void:
	if crystal_mat != null:
		crystal_mat.set_shader_parameter("ice_time", clock)
		crystal_mat.set_shader_parameter("ice_flash", flash)
	var r: int = 0
	while r < roads.size():
		var road: Dictionary = roads[r]
		var road_y: float = float(road["y"])
		_place_frost(road["frost"], road_y)
		_place_rune(road["rune"], road_y)
		_place_mists(road["mists"], road_y)
		_place_sparks(road["sparks"], road_y)
		var ink: Node = road["ink"]
		if ink != null and is_instance_valid(ink):
			ink.queue_redraw()
		var burst: Node = road["burst"]
		if burst != null and is_instance_valid(burst):
			burst.queue_redraw()
		r += 1


func _place_frost(node: Variant, road_y: float) -> void:
	if not (node is Sprite2D):
		return
	var sprite: Sprite2D = node
	var show: bool = frost_alpha > 0.012 and frost_len > 2.0
	sprite.visible = show
	if not show:
		return
	sprite.rotation = blow * PI * 0.5
	sprite.position = Vector2(blow * frost_len * 0.5, road_y)
	var tex_w: float = 160.0
	var tex_h: float = 320.0
	if frost_tex != null:
		tex_w = float(frost_tex.get_width())
		tex_h = float(frost_tex.get_height())
	sprite.scale = Vector2(46.0 / tex_w, frost_len / tex_h)
	sprite.modulate = Color(1.0, 1.0, 1.0, frost_alpha)


func _place_rune(node: Variant, road_y: float) -> void:
	if not (node is Sprite2D):
		return
	var sprite: Sprite2D = node
	var show: bool = rune_alpha > 0.02
	sprite.visible = show
	if not show:
		return
	sprite.rotation = 0.0
	sprite.position = Vector2(0.0, road_y + 1.0)
	var diam: float = span * (3.4 / MAX_LEN) * rune_scale
	var tex_w: float = 192.0
	var tex_h: float = 192.0
	if rune_tex != null:
		tex_w = float(rune_tex.get_width())
		tex_h = float(rune_tex.get_height())
	sprite.scale = Vector2(diam / tex_w, diam * 0.34 / tex_h)
	sprite.modulate = Color(1.0, 1.0, 1.0, rune_alpha)


func _place_mists(mists: Array, road_y: float) -> void:
	var tex_n: float = 96.0
	if mist_tex != null:
		tex_n = float(mist_tex.get_width())
	var m: int = 0
	while m < mists.size():
		var puff: Dictionary = mists[m]
		var node: Variant = puff["sprite"]
		if node is Sprite2D:
			var sprite: Sprite2D = node
			var fade: float = float(puff.get("fade", 0.0))
			var show: bool = bool(puff.get("show", false)) and fade > 0.01
			sprite.visible = show
			if show:
				sprite.position = _project(float(puff["x"]), float(puff["y"]), float(puff["z"]), road_y)
				var px: float = float(puff.get("now", 1.0)) * UNIT_PX
				sprite.scale = Vector2(px / tex_n, px * 0.72 / tex_n)
				sprite.modulate = Color(1.0, 1.0, 1.0, fade)
		m += 1


func _place_sparks(sparks: Array, road_y: float) -> void:
	var tex_n: float = 96.0
	if spark_tex != null:
		tex_n = float(spark_tex.get_width())
	var k: int = 0
	while k < sparks.size():
		var bit: Dictionary = sparks[k]
		var node: Variant = bit["sprite"]
		if node is Sprite2D:
			var sprite: Sprite2D = node
			var twinkle: float = 0.55 + 0.45 * sin(clock * 9.0 + float(bit["phase"]))
			var sc: float = float(bit["size"]) * twinkle * spark_cover
			var fade: float = spark_op * twinkle
			var show: bool = fade > 0.02 and sc > 0.01
			sprite.visible = show
			if show:
				sprite.position = _project(float(bit["x"]), float(bit["y"]), float(bit["z"]), road_y)
				var px: float = sc * UNIT_PX
				sprite.scale = Vector2(px / tex_n, px / tex_n)
				sprite.modulate = Color(1.0, 1.0, 1.0, fade)
		k += 1


func paint_crystals(sheet: CanvasItem, road_i: int) -> void:
	if road_i < 0 or road_i >= roads.size():
		return
	var road: Dictionary = roads[road_i]
	if show_spires:
		var spires: Array = road["spires"]
		var s: int = 0
		while s < spires.size():
			var sp: Dictionary = spires[s]
			if float(sp["sy"]) > 0.04 and float(sp["sxz"]) > 0.04:
				var xf: Transform2D = _pillar(sp)
				if absf(xf.y.y) < 6.0:
					s += 1
					continue
				var tint: Color = Color(float(sp["seed"]), 1.0, 1.0, 1.0)
				var ink: Color = Color(float(sp["seed"]), 0.0, 0.0, 1.0)
				_paint_poly(sheet, spike_out, spike_uv, xf, ink)
				_paint_poly(sheet, spike_pts, spike_uv, xf, tint)
			s += 1
	var n: int = 0
	while n < shards.size():
		var sh: Dictionary = shards[n]
		if bool(sh["on"]) and int(sh["road"]) == road_i:
			var life: float = float(sh["life"])
			var limit: float = maxf(float(sh["max"]), 0.001)
			var ratio: float = life / limit
			var shrink: float = 1.0
			if ratio > 0.65:
				shrink = maxf(0.001, 1.0 - (ratio - 0.65) / 0.35)
			if shrink > 0.02:
				var fit: Vector2 = Vector2(float(sh["sx"]) * shrink, float(sh["sy"]) * shrink)
				var xf_s: Transform2D = Transform2D(float(sh["rot"]), fit, 0.0, Vector2(float(sh["x"]), float(sh["y"])))
				var tint_s: Color = Color(float(sh["seed"]), 1.0, 1.0, 1.0)
				var ink_s: Color = Color(float(sh["seed"]), 0.0, 0.0, 1.0)
				_paint_poly(sheet, chip_out, chip_uv, xf_s, ink_s)
				_paint_poly(sheet, chip_pts, chip_uv, xf_s, tint_s)
		n += 1


func paint_shock(sheet: CanvasItem, road_i: int) -> void:
	if shock_alpha < 0.02 or road_i < 0 or road_i >= roads.size():
		return
	var road: Dictionary = roads[road_i]
	var center: Vector2 = Vector2(blow * 0.48 * span, float(road["y"]))
	var radius_px: float = shock_radius * (span / MAX_LEN)
	var blue: Color = Color(0.015, 0.22, 0.42, shock_alpha)
	var ice: Color = Color(0.30, 0.80, 1.0, shock_alpha)
	var edge: Color = Color(0.79, 0.98, 1.0, shock_alpha)
	var wedges: Array[Vector3] = [
		Vector3(0.02, 0.61, 1.02),
		Vector3(0.78, 0.36, 1.06),
		Vector3(1.32, 0.69, 0.97),
		Vector3(2.17, 0.28, 1.04),
		Vector3(2.62, 0.65, 1.0),
		Vector3(3.45, 0.34, 1.03),
		Vector3(4.05, 0.52, 0.95),
		Vector3(4.83, 0.77, 1.01),
		Vector3(5.84, 0.29, 0.97),
	]
	var w: int = 0
	while w < wedges.size():
		var wedge: Vector3 = wedges[w]
		_paint_wedge(sheet, center, radius_px, wedge.x, wedge.y, wedge.z, blue, ice, edge)
		w += 1


func _paint_wedge(sheet: CanvasItem, center: Vector2, radius_px: float, angle: float, span_a: float, rad: float, blue: Color, ice: Color, edge: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var j: int = 0
	while j <= 6:
		var t: float = float(j) / 6.0
		var taper: float = sin(PI * t)
		var a: float = angle + span_a * t
		var rr: float = rad + 0.1 * t * t - 0.035 * taper
		pts.append(_shock_pt(center, radius_px, a, rr - 0.075 * taper, 0.0))
		cols.append(blue)
		pts.append(_shock_pt(center, radius_px, a, rr - 0.02 * taper, 0.037 * taper))
		cols.append(ice)
		pts.append(_shock_pt(center, radius_px, a, rr, 0.012 * taper))
		cols.append(edge)
		if j > 0:
			var k: int = j * 3
			_tri(sheet, pts, cols, k - 3, k - 2, k)
			_tri(sheet, pts, cols, k, k - 2, k + 1)
			_tri(sheet, pts, cols, k - 2, k - 1, k + 1)
			_tri(sheet, pts, cols, k + 1, k - 1, k + 2)
		j += 1
	if span_a > 0.45:
		var tooth: float = angle + span_a * 0.67
		var extra: PackedVector2Array = PackedVector2Array()
		var tooth_cols: PackedColorArray = PackedColorArray()
		extra.append(_shock_pt(center, radius_px, tooth, rad + 0.05, 0.0))
		tooth_cols.append(blue)
		extra.append(_shock_pt(center, radius_px, tooth + 0.075, rad + 0.11, 0.016))
		tooth_cols.append(ice)
		extra.append(_shock_pt(center, radius_px, tooth + 0.16, rad + 0.23, 0.038))
		tooth_cols.append(edge)
		_tri(sheet, extra, tooth_cols, 0, 1, 2)


func _shock_pt(center: Vector2, radius_px: float, angle: float, geom_r: float, lift: float) -> Vector2:
	var reach: float = geom_r * radius_px
	var at: Vector2 = Vector2(cos(angle) * reach, sin(angle) * reach * 0.28)
	at.y -= lift * radius_px
	return center + at


func _tri(sheet: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray, a: int, b: int, c: int) -> void:
	if a < 0 or b < 0 or c < 0:
		return
	if a >= pts.size() or b >= pts.size() or c >= pts.size():
		return
	var pa: Vector2 = pts[a]
	var pb: Vector2 = pts[b]
	var pc: Vector2 = pts[c]
	if absf((pb - pa).cross(pc - pa)) < 0.08:
		return
	var poly: PackedVector2Array = PackedVector2Array([pa, pb, pc])
	var tint: PackedColorArray = PackedColorArray([cols[a], cols[b], cols[c]])
	sheet.draw_primitive(poly, tint, PackedVector2Array())


func _paint_poly(sheet: CanvasItem, pts: PackedVector2Array, uvs: PackedVector2Array, xf: Transform2D, tint: Color) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	var world: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var i: int = 0
	world.resize(n)
	cols.resize(n)
	while i < n:
		world[i] = xf * pts[i]
		cols[i] = tint
		i += 1
	var area: float = 0.0
	var e: int = 0
	while e < n:
		var nxt: int = 0
		if e + 1 < n:
			nxt = e + 1
		area += world[e].cross(world[nxt])
		e += 1
	if absf(area) < 2.0:
		return
	sheet.draw_polygon(world, cols, uvs)


func _pillar(sp: Dictionary) -> Transform2D:
	var sy: float = maxf(float(sp["sy"]), 0.0001)
	var sxz: float = maxf(float(sp["sxz"]), 0.0001)
	var height: float = float(sp["height"]) * sy * UNIT_PX
	var tilt: float = float(sp["tilt"])
	var side: float = float(sp["side"])
	var face: float = 0.72 + 0.28 * absf(cos(float(sp["spin"])))
	var wide: float = UNIT_PX * float(sp["radius"]) * sxz * face
	var x_axis: Vector2 = Vector2(wide, 0.0)
	var y_axis: Vector2 = Vector2(-blow * sin(tilt) * height, cos(tilt) * height)
	y_axis.x += -blow * sin(side) * height * 0.22
	var along: float = blow * (float(sp["z"]) / MAX_LEN) * span
	var origin: Vector2 = Vector2(along, float(sp["road_y"]) + float(sp["lat"]) * 5.0)
	origin.y += 0.012 * float(sp["radius"]) * sxz * UNIT_PX
	return Transform2D(x_axis, y_axis, origin)


func _project(x: float, y: float, z: float, road_y: float) -> Vector2:
	var sx: float = blow * (z / MAX_LEN) * span + x * 10.0
	var sy: float = road_y - y * UNIT_PX
	return Vector2(sx, sy)


func _grown(local_t: float) -> Vector2:
	if local_t <= 0.0:
		return Vector2.ZERO
	if local_t < 0.65:
		var rise: float = local_t / 0.65
		var ease: float = 1.0 - pow(1.0 - rise, 3.0)
		return Vector2(ease * 1.08, ease * 1.14)
	var settle: float = (local_t - 0.65) / 0.35
	return Vector2(1.08 - 0.08 * settle, 1.14 - 0.14 * settle)


func _build_road(road_i: int, road_y: float) -> void:
	var band: int = road_i * 40
	var frost: Sprite2D = _sprite(frost_tex, sheet_mat, band)
	var rune: Sprite2D = _sprite(rune_tex, glint_mat, band + 1)
	var ink: IceSheet = _sheet(road_i, band + 10, false)
	var burst: IceSheet = _sheet(road_i, band + 24, true)
	var spires: Array = []
	var i: int = 0
	while i < SPIRES:
		var u: float = 0.0
		if SPIRES > 1:
			u = float(i) / float(SPIRES - 1)
		var dist: float = pow(u, 0.92)
		var z: float = 0.65 + dist * (MAX_LEN - 0.65)
		var flank: bool = (i % 3) != 0 and u > 0.12
		var side_sign: float = 1.0
		if i % 2 != 0:
			side_sign = -1.0
		var spread: float = 0.22 + dist * 0.95
		var lat: float = 0.0
		if flank:
			lat = side_sign * (0.32 + _unit() * spread)
		else:
			lat = (_unit() - 0.5) * 0.36
		var wedge: float = 0.14 + 0.86 * pow(dist, 1.28)
		var jitter: float = 0.82 + _unit() * 0.36
		var tall: float = MAX_H * wedge * jitter
		if flank:
			tall *= 0.34 + _unit() * 0.28
		var radius: float = 0.0
		if flank:
			radius = 0.32 + _unit() * 0.24
		else:
			radius = 0.46 + dist * 0.42 + _unit() * 0.18
		var tilt: float = deg_to_rad(12.0 + dist * 14.0 + (_unit() - 0.5) * 6.0)
		var roll: float = 0.0
		if flank:
			roll = -side_sign * deg_to_rad(14.0 + _unit() * 18.0)
		else:
			roll = (_unit() - 0.5) * deg_to_rad(8.0)
		var spin: float = _unit() * TAU
		spires.append({
			"road": road_i,
			"road_y": road_y,
			"z": z,
			"lat": lat,
			"height": tall,
			"radius": radius,
			"tilt": tilt,
			"side": roll,
			"spin": spin,
			"trigger": dist * 0.72,
			"sy": 0.0,
			"sxz": 0.0,
			"seed": _hash(i * 13 + road_i * 9 + 3),
		})
		i += 1
	var mists: Array = []
	var m: int = 0
	while m < MISTS:
		var t: float = float(m) / float(MISTS)
		var mz: float = 0.5 + t * (MAX_LEN * 0.96)
		var mx: float = (_unit() - 0.5) * (0.9 + t * 1.6)
		var my: float = 0.45 + t * (MAX_H * 0.28) + _unit() * 0.6
		var dx: float = (_unit() - 0.5) * 0.35
		var dy: float = 0.25 + _unit() * 0.25
		var dz: float = 0.7 + _unit() * 0.6
		var base: float = 2.0 + t * 1.8 + _unit() * 0.9
		var puff: Sprite2D = _sprite(mist_tex, sheet_mat, band + 4)
		mists.append({
			"sprite": puff,
			"x": mx,
			"y": my,
			"z": mz,
			"dx": dx,
			"dy": dy,
			"dz": dz,
			"bx": 0.0,
			"by": 0.0,
			"bz": 0.0,
			"spawn": t * 0.75,
			"base": base,
			"now": base * 0.65,
			"fade": 0.0,
			"show": false,
		})
		m += 1
	var sparks: Array = []
	var k: int = 0
	while k < SPARKS:
		var st: float = _unit()
		var sz: float = 0.6 + st * MAX_LEN
		var sx: float = (_unit() - 0.5) * 2.4
		var sy: float = 0.3 + _unit() * (MAX_H * (0.25 + st * 0.85))
		var vx: float = (_unit() - 0.5) * 0.3
		var vy: float = 0.55 + _unit() * 0.75
		var vz: float = 0.2 + _unit() * 0.3
		var bit: Sprite2D = _sprite(spark_tex, glint_mat, band + 18)
		sparks.append({
			"sprite": bit,
			"x": sx,
			"y": sy,
			"z": sz,
			"vx": vx,
			"vy": vy,
			"vz": vz,
			"phase": float(k) * 1.37 + float(road_i) * 0.8,
			"size": 0.25 + _hash(k * 17 + road_i * 5) * 0.35,
		})
		k += 1
	roads.append({
		"y": road_y,
		"frost": frost,
		"rune": rune,
		"ink": ink,
		"burst": burst,
		"spires": spires,
		"mists": mists,
		"sparks": sparks,
	})


func _sprite(tex: Texture2D, mat: Material, z: int) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.material = mat
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = z
	sprite.visible = false
	add_child(sprite)
	return sprite


func _sheet(road_i: int, z: int, shock: bool) -> IceSheet:
	var sheet: IceSheet = IceSheet.new()
	sheet.rig = self
	sheet.road = road_i
	sheet.shock = shock
	sheet.z_index = z
	if shock:
		sheet.material = shock_mat
	else:
		sheet.material = crystal_mat
	add_child(sheet)
	return sheet


func _unit() -> float:
	var mixed: int = rand_state * 1664525 + 1013904223
	rand_state = mixed & 0xFFFFFFFF
	return float(rand_state) / 4294967296.0


func _hash(salt: int) -> float:
	var n: int = salt * 1103515245 + 12345
	if n < 0:
		n = -n
	return float(n % 1000) / 999.0


static func _bank() -> void:
	if banked:
		return
	banked = true
	_meshes()
	frost_tex = _tex(_make_frost(160, 320))
	rune_tex = _tex(_make_rune(192))
	mist_tex = _tex(_make_mist(96))
	spark_tex = _tex(_make_spark(96))
	sheet_mat = ShaderMaterial.new()
	sheet_mat.shader = SHEET_SHADER
	glint_mat = ShaderMaterial.new()
	glint_mat.shader = GLINT_SHADER
	shock_mat = ShaderMaterial.new()
	shock_mat.shader = SHOCK_SHADER


static func _meshes() -> void:
	if mesh_ready:
		return
	mesh_ready = true
	spike_pts = PackedVector2Array([
		Vector2(-0.50, 0.0),
		Vector2(-0.58, -0.14),
		Vector2(-0.46, -0.38),
		Vector2(-0.40, -0.64),
		Vector2(-0.14, -0.86),
		Vector2(0.05, -1.0),
		Vector2(0.20, -0.82),
		Vector2(0.44, -0.62),
		Vector2(0.54, -0.30),
		Vector2(0.48, 0.0),
	])
	spike_uv = _uvs_of(spike_pts)
	spike_out = _expand(spike_pts, 0.034, true)
	chip_pts = PackedVector2Array([
		Vector2(-0.40, 0.02),
		Vector2(-0.50, -0.28),
		Vector2(-0.16, -0.72),
		Vector2(0.06, -1.0),
		Vector2(0.36, -0.55),
		Vector2(0.42, 0.04),
	])
	chip_uv = _uvs_of(chip_pts)
	chip_out = _expand(chip_pts, 0.05, false)


static func _uvs_of(pts: PackedVector2Array) -> PackedVector2Array:
	var uvs: PackedVector2Array = PackedVector2Array()
	if pts.is_empty():
		return uvs
	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var i: int = 0
	while i < pts.size():
		min_x = minf(min_x, pts[i].x)
		max_x = maxf(max_x, pts[i].x)
		i += 1
	var span_x: float = maxf(max_x - min_x, 0.001)
	var k: int = 0
	while k < pts.size():
		var p: Vector2 = pts[k]
		uvs.append(Vector2((p.x - min_x) / span_x, clampf(-p.y, 0.0, 1.0)))
		k += 1
	return uvs


static func _expand(pts: PackedVector2Array, amount: float, pin_base: bool) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2(0.0, -0.45)
	var i: int = 0
	while i < pts.size():
		var cur: Vector2 = pts[i]
		var away: Vector2 = cur - center
		var len: float = away.length()
		var pushed: Vector2 = cur
		if len > 0.001:
			pushed = cur + away / len * amount
		if pin_base and cur.y >= -0.05:
			pushed.y = 0.0
		out.append(pushed)
		i += 1
	return out


static func _tex(img: Image) -> Texture2D:
	return ImageTexture.create_from_image(img)


static func _make_frost(w: int, h: int) -> Image:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx: float = float(w) * 0.5
	var cy: float = 540.0 / 1024.0 * float(h)
	var inner: float = 20.0 * float(w) / 512.0
	var outer: float = 240.0 * float(w) / 512.0
	var y: int = 0
	while y < h:
		var t: float = (0.96 - float(y) / float(h)) / 0.9
		var half_l: float = -1.0
		var half_r: float = -1.0
		var snow: Color = Color(0, 0, 0, 0)
		if t >= 0.0 and t <= 1.0:
			var env: float = sin(pow(maxf(t, 0.0), 0.65) * PI)
			var step_i: float = t * 42.0
			var jag_l: float = (sin(step_i * 7.3) * 0.25 + cos(step_i * 13.7) * 0.2) * 55.0
			var jag_r: float = (cos(step_i * 6.1) * 0.25 + sin(step_i * 11.9) * 0.2) * 55.0
			half_l = maxf(12.0, 28.0 + env * 135.0 + jag_l) * float(w) / 512.0
			half_r = maxf(12.0, 28.0 + env * 135.0 + jag_r) * float(w) / 512.0
			snow = _snow_color(t)
		var x: int = 0
		while x < w:
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			var glow: Color = _frost_glow(dist, inner, outer)
			var src: Color = glow
			if half_l >= 0.0 and float(x) >= cx - half_l and float(x) <= cx + half_r:
				src = _over_color(glow, snow)
			img.set_pixel(x, y, src)
			x += 1
		y += 1
	return img


static func _frost_glow(dist: float, inner: float, outer: float) -> Color:
	var core: Color = Color(186.0 / 255.0, 230.0 / 255.0, 253.0 / 255.0, 0.85)
	var mid: Color = Color(56.0 / 255.0, 189.0 / 255.0, 248.0 / 255.0, 0.35)
	var far: Color = Color(14.0 / 255.0, 165.0 / 255.0, 233.0 / 255.0, 0.0)
	if dist <= inner:
		return core
	var u: float = clampf((dist - inner) / maxf(outer - inner, 0.001), 0.0, 1.0)
	if u < 0.55:
		return core.lerp(mid, u / 0.55)
	return mid.lerp(far, (u - 0.55) / 0.45)


static func _snow_color(t: float) -> Color:
	var near: Color = Color(224.0 / 255.0, 242.0 / 255.0, 254.0 / 255.0, 0.92)
	var hot: Color = Color(1.0, 1.0, 1.0, 0.98)
	var pale: Color = Color(224.0 / 255.0, 242.0 / 255.0, 254.0 / 255.0, 0.90)
	var tip: Color = Color(186.0 / 255.0, 230.0 / 255.0, 253.0 / 255.0, 0.0)
	if t < 0.45:
		return near.lerp(hot, t / 0.45)
	if t < 0.88:
		return hot.lerp(pale, (t - 0.45) / 0.43)
	return pale.lerp(tip, (t - 0.88) / 0.12)


static func _over_color(dst: Color, src: Color) -> Color:
	var out_a: float = src.a + dst.a * (1.0 - src.a)
	if out_a <= 0.001:
		return Color(0, 0, 0, 0)
	var keep: float = dst.a * (1.0 - src.a)
	var r: float = (src.r * src.a + dst.r * keep) / out_a
	var g: float = (src.g * src.a + dst.g * keep) / out_a
	var b: float = (src.b * src.a + dst.b * keep) / out_a
	return Color(r, g, b, out_a)


static func _make_rune(side: int) -> Image:
	var img: Image = Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = float(side) * 0.5
	var cy: float = cx
	var fit: float = float(side) / 512.0
	var y: int = 0
	while y < side:
		var x: int = 0
		while x < side:
			var p: Vector2 = Vector2(float(x) - cx, float(y) - cy)
			var d: float = p.length()
			var col: Color = _rune_glow(d, fit)
			col = _ring(col, d, 210.0 * fit, 2.6 * fit)
			col = _ring(col, d, 182.0 * fit, 1.6 * fit)
			col = _tri_stroke(col, p, 180.0 * fit, 0.0, 2.0 * fit)
			col = _tri_stroke(col, p, 180.0 * fit, PI / 3.0, 2.0 * fit)
			col = _ticks(col, p, d, fit)
			img.set_pixel(x, y, col)
			x += 1
		y += 1
	return img


static func _rune_glow(d: float, fit: float) -> Color:
	var inner: float = 60.0 * fit
	var outer: float = 245.0 * fit
	var core: Color = Color(125.0 / 255.0, 211.0 / 255.0, 252.0 / 255.0, 0.25)
	var mid: Color = Color(56.0 / 255.0, 189.0 / 255.0, 248.0 / 255.0, 0.45)
	var far: Color = Color(56.0 / 255.0, 189.0 / 255.0, 248.0 / 255.0, 0.0)
	if d >= outer:
		return far
	if d <= inner:
		return core
	var u: float = (d - inner) / maxf(outer - inner, 0.001)
	if u < 0.75:
		return core.lerp(mid, u / 0.75)
	return mid.lerp(far, (u - 0.75) / 0.25)


static func _ring(col: Color, d: float, radius: float, width: float) -> Color:
	if absf(d - radius) > width:
		return col
	var ink: Color = Color(224.0 / 255.0, 242.0 / 255.0, 254.0 / 255.0, 0.95)
	return _over_color(col, ink)


static func _tri_stroke(col: Color, p: Vector2, radius: float, turn: float, width: float) -> Color:
	var a: Vector2 = Vector2(cos(turn - PI * 0.5), sin(turn - PI * 0.5)) * radius
	var b: Vector2 = Vector2(cos(turn + PI * 2.0 / 3.0 - PI * 0.5), sin(turn + PI * 2.0 / 3.0 - PI * 0.5)) * radius
	var c: Vector2 = Vector2(cos(turn + PI * 4.0 / 3.0 - PI * 0.5), sin(turn + PI * 4.0 / 3.0 - PI * 0.5)) * radius
	var hit: bool = _seg_dist(p, a, b) <= width or _seg_dist(p, b, c) <= width or _seg_dist(p, c, a) <= width
	if not hit:
		return col
	return _over_color(col, Color(224.0 / 255.0, 242.0 / 255.0, 254.0 / 255.0, 0.92))


static func _ticks(col: Color, p: Vector2, d: float, fit: float) -> Color:
	var inner: float = 186.0 * fit
	var outer: float = 206.0 * fit
	if d < inner or d > outer:
		return col
	var turns: float = atan2(p.y, p.x) / TAU
	turns = turns - floor(turns)
	var slot: float = turns * 24.0
	var nearest: float = round(slot)
	if nearest >= 24.0:
		nearest = 0.0
	var tick_a: float = nearest / 24.0 * TAU
	var dir: Vector2 = Vector2(cos(tick_a), sin(tick_a))
	var tang: float = absf(p.x * dir.y - p.y * dir.x)
	var even: bool = int(nearest) % 2 == 0
	var width: float = 1.7 * fit
	if even:
		width = 2.4 * fit
	if tang > width:
		return col
	return _over_color(col, Color(224.0 / 255.0, 242.0 / 255.0, 254.0 / 255.0, 0.9))


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var den: float = ab.length_squared()
	var t: float = 0.0
	if den > 0.0001:
		t = clampf((p - a).dot(ab) / den, 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _make_mist(side: int) -> Image:
	var img: Image = Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fit: float = float(side) / 256.0
	_blob(img, 128.0 * fit, 128.0 * fit, 92.0 * fit, 0.55)
	_blob(img, 96.0 * fit, 118.0 * fit, 66.0 * fit, 0.45)
	_blob(img, 162.0 * fit, 122.0 * fit, 64.0 * fit, 0.45)
	_blob(img, 115.0 * fit, 152.0 * fit, 58.0 * fit, 0.40)
	_blob(img, 148.0 * fit, 98.0 * fit, 56.0 * fit, 0.40)
	return img


static func _blob(img: Image, cx: float, cy: float, radius: float, alpha: float) -> void:
	var x0: int = int(floor(cx - radius)) - 1
	var y0: int = int(floor(cy - radius)) - 1
	var x1: int = int(ceil(cx + radius)) + 1
	var y1: int = int(ceil(cy + radius)) + 1
	var w: int = img.get_width()
	var h: int = img.get_height()
	if x0 < 0:
		x0 = 0
	if y0 < 0:
		y0 = 0
	if x1 > w:
		x1 = w
	if y1 > h:
		y1 = h
	var y: int = y0
	while y < y1:
		var x: int = x0
		while x < x1:
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= radius:
				var u: float = clampf((dist - radius * 0.12) / maxf(radius * 0.88, 0.001), 0.0, 1.0)
				var core: Color = Color(240.0 / 255.0, 249.0 / 255.0, 1.0, alpha)
				var mid: Color = Color(186.0 / 255.0, 230.0 / 255.0, 253.0 / 255.0, alpha * 0.65)
				var far: Color = Color(125.0 / 255.0, 211.0 / 255.0, 252.0 / 255.0, 0.0)
				var src: Color = core
				if u < 0.55:
					src = core.lerp(mid, u / 0.55)
				else:
					src = mid.lerp(far, (u - 0.55) / 0.45)
				img.set_pixel(x, y, _over_color(img.get_pixel(x, y), src))
			x += 1
		y += 1


static func _make_spark(side: int) -> Image:
	var img: Image = Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = float(side) * 0.5
	var cy: float = cx
	var fit: float = float(side) / 128.0
	var star: PackedVector2Array = PackedVector2Array()
	var i: int = 0
	while i < 8:
		var reach: float = 56.0 * fit
		if i % 2 != 0:
			reach = 11.0 * fit
		var ang: float = float(i) * PI / 4.0
		star.append(Vector2(cx, cy) + Vector2(cos(ang), sin(ang)) * reach)
		i += 1
	var y: int = 0
	while y < side:
		var x: int = 0
		while x < side:
			var p: Vector2 = Vector2(float(x) - cx, float(y) - cy)
			var dist: float = p.length()
			var glow_u: float = clampf((dist - 2.0 * fit) / maxf(52.0 * fit - 2.0 * fit, 0.001), 0.0, 1.0)
			var core: Color = Color(1, 1, 1, 1)
			var mid: Color = Color(125.0 / 255.0, 211.0 / 255.0, 252.0 / 255.0, 0.75)
			var far: Color = Color(56.0 / 255.0, 189.0 / 255.0, 248.0 / 255.0, 0.0)
			var col: Color = far
			if dist <= 2.0 * fit:
				col = core
			elif glow_u < 0.35:
				col = core.lerp(mid, glow_u / 0.35)
			else:
				col = mid.lerp(far, (glow_u - 0.35) / 0.65)
			if _inside(Vector2(float(x), float(y)), star):
				col = _over_color(col, Color(1, 1, 1, 1))
			img.set_pixel(x, y, col)
			x += 1
		y += 1
	return img


static func _inside(p: Vector2, poly: PackedVector2Array) -> bool:
	var n: int = poly.size()
	var inside: bool = false
	var j: int = n - 1
	var i: int = 0
	while i < n:
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[j]
		var cross: bool = (a.y > p.y) != (b.y > p.y)
		if cross:
			var x_at: float = (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x
			if p.x < x_at:
				inside = not inside
		j = i
		i += 1
	return inside
