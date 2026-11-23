extends RefCounted

# One baked sheet per skill. Every cast of that skill blits a frame from the
# same texture, so a second explosion does not bake another sheet.
const FRAMES := 8
const PAD := 4

static var sheets: Dictionary = {}
static var bakes: int = 0
static var pending: int = 0
static var pixels: int = 0


static func clear() -> void:
	sheets.clear()
	bakes = 0
	pending = 0
	pixels = 0


static func sheet_count() -> int:
	return sheets.size()


static func texture(kind: String) -> Texture2D:
	if not sheets.has(kind):
		return null
	var row: Dictionary = sheets[kind]
	if not bool(row.get("ready", false)):
		return null
	var tex: Texture2D = row["tex"]
	return tex


static func sheet_object(kind: String) -> int:
	var tex: Texture2D = texture(kind)
	if tex == null:
		return 0
	return tex.get_instance_id()


static func warm(host: Node) -> void:
	var kinds := PackedStringArray(["ex", "ls", "fz", "en"])
	for kind in kinds:
		_request(host, str(kind))


static func region(kind: String, frame: int) -> Rect2:
	var box: Vector2 = _cell(kind)
	var slot: int = clampi(frame, 0, FRAMES - 1)
	var step: int = int(box.x) + PAD
	return Rect2(float(slot * step), 0.0, box.x, box.y)


static func blit(ci: CanvasItem, kind: String, frame: int, rect: Rect2, flip_h: bool, tint: Color) -> void:
	var tex: Texture2D = texture(kind)
	if tex == null or rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	var src: Rect2 = region(kind, frame)
	if not flip_h:
		ci.draw_texture_rect_region(tex, rect, src, tint)
		return
	ci.draw_set_transform(rect.position + Vector2(rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	ci.draw_texture_rect_region(tex, Rect2(Vector2.ZERO, rect.size), src, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_ground(ci: CanvasItem, hazards: Array) -> void:
	for raw in hazards:
		var patch: Dictionary = raw
		var kind: String = str(patch.get("kind", ""))
		if kind == "fire":
			_draw_fire(ci, patch)
		elif kind == "ice":
			_draw_ice_sheet(ci, patch)


static func draw_glow(ci: CanvasItem, bursts: Array, slashes: Array, hazards: Array) -> void:
	for burst_raw in bursts:
		var burst: Dictionary = burst_raw
		_draw_burst(ci, burst, true)
	for slash_raw in slashes:
		var slash: Dictionary = slash_raw
		_draw_slash(ci, slash, true)
	for hazard_raw in hazards:
		var patch: Dictionary = hazard_raw
		if str(patch.get("kind", "")) == "ice":
			_draw_ice_head(ci, patch)


static func draw_world(ci: CanvasItem, bursts: Array, slashes: Array) -> void:
	for world_burst in bursts:
		var burst_row: Dictionary = world_burst
		_draw_burst(ci, burst_row, false)
	for world_slash in slashes:
		var slash_row: Dictionary = world_slash
		_draw_slash(ci, slash_row, false)


static func draw_marks(ci: CanvasItem, bodies: Array) -> void:
	for body in bodies:
		if body == null or not is_instance_valid(body):
			continue
		if not ("root_left" in body) or not ("alive" in body):
			continue
		if not bool(body.alive) or float(body.root_left) <= 0.0:
			continue
		var at: Vector2 = body.position
		var pulse: float = 1.0 + 0.1 * sin(float(Time.get_ticks_msec()) * 0.012)
		var wide: float = 40.0 * pulse
		var tall: float = 32.0 * pulse
		blit(ci, "fz", 7, Rect2(at.x - wide * 0.5, at.y - 112.0, wide, tall), false, Color(1, 1, 1, 0.96))


static func paint_sheet(ci: CanvasItem, kind: String) -> void:
	var box: Vector2 = _cell(kind)
	var step: int = int(box.x) + PAD
	var slot: int = 0
	while slot < FRAMES:
		ci.draw_set_transform(Vector2(float(slot * step), 0.0), 0.0, Vector2.ONE)
		if kind == "ex":
			_paint_blast(ci, slot, box)
		elif kind == "ls":
			_paint_slash(ci, slot, box)
		elif kind == "fz":
			_paint_frost(ci, slot, box)
		else:
			_paint_aura(ci, slot, box)
		slot += 1
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _request(host: Node, kind: String) -> void:
	if sheets.has(kind):
		return
	if not host.is_inside_tree():
		return
	sheets[kind] = {"ready": false}
	bakes += 1
	pending += 1
	var host_node := BakeHost.new()
	host_node.kind = kind
	host.add_child(host_node)


static func _cell(kind: String) -> Vector2:
	if kind == "ex":
		return Vector2(300, 300)
	if kind == "ls":
		return Vector2(280, 200)
	if kind == "fz":
		return Vector2(220, 132)
	return Vector2(240, 280)


static func _draw_fire(ci: CanvasItem, patch: Dictionary) -> void:
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y: float = float(patch.get("y", 0.0))
	var age: float = float(patch.get("age", 0.0))
	var span: float = x1 - x0
	if span < 4.0:
		return
	if span < 140.0:
		var frame_n: int = 4 + posmod(int(age * 10.0), 4)
		var side: float = clampf(span, 40.0, 92.0)
		blit(ci, "ex", frame_n, Rect2((x0 + x1) * 0.5 - side * 0.5, y - side * 0.78, side, side), false, Color(1, 1, 1, 0.95))
		return
	var cursor: float = x0 + 20.0
	var guard: int = 0
	while cursor < x1 - 12.0 and guard < 28:
		var puff: int = 4 + posmod(guard + int(age * 8.0), 4)
		var dot: float = 22.0 + 8.0 * _unit(guard * 9 + 3)
		blit(ci, "ex", puff, Rect2(cursor - dot * 0.5, y - dot * 0.72, dot, dot), false, Color(1, 1, 1, 0.88))
		cursor += 68.0
		guard += 1


static func _draw_ice_sheet(ci: CanvasItem, patch: Dictionary) -> void:
	var cover: Vector2 = _ice_cover(patch)
	var y: float = float(patch.get("y", 0.0))
	var age: float = float(patch.get("age", 0.0))
	if cover.y - cover.x < 4.0:
		return
	var frame: int = 3 + posmod(int(age * 8.0), 4)
	var tile_w: float = 176.0
	var tile_h: float = 106.0
	var cursor: float = cover.x
	var guard: int = 0
	while cursor < cover.y - 1.0 and guard < 80:
		var span: float = minf(tile_w, cover.y - cursor)
		blit(ci, "fz", frame, Rect2(cursor, y - tile_h * 0.62, span, tile_h), false, Color(1, 1, 1, 0.94))
		cursor += tile_w - 12.0
		guard += 1


static func _draw_ice_head(ci: CanvasItem, patch: Dictionary) -> void:
	var age: float = float(patch.get("age", 0.0))
	if age >= 0.95:
		return
	var cover: Vector2 = _ice_cover(patch)
	var from_x: float = float(patch.get("from_x", cover.x))
	var y: float = float(patch.get("y", 0.0))
	var frame: int = mini(2, int(age * 3.2))
	var wide: float = 170.0
	var tall: float = 102.0
	if from_x - cover.x > 14.0:
		blit(ci, "fz", frame, Rect2(cover.x - wide * 0.15, y - tall * 0.62, wide, tall), true, Color(1, 1, 1, 0.95))
	if cover.y - from_x > 14.0:
		blit(ci, "fz", frame, Rect2(cover.y - wide * 0.85, y - tall * 0.62, wide, tall), false, Color(1, 1, 1, 0.95))


static func _ice_cover(patch: Dictionary) -> Vector2:
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var from_x: float = float(patch.get("from_x", (x0 + x1) * 0.5))
	var age: float = float(patch.get("age", 0.0))
	var cover: float = clampf(age / 0.9, 0.0, 1.0)
	return Vector2(lerpf(from_x, x0, cover), lerpf(from_x, x1, cover))


static func _draw_burst(ci: CanvasItem, patch: Dictionary, bloom: bool) -> void:
	var age: float = float(patch.get("age", 0.0))
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y0: float = float(patch.get("y0", 0.0))
	var y1: float = float(patch.get("y1", 0.0))
	var full_w: float = maxf(8.0, x1 - x0)
	var full_h: float = maxf(8.0, y1 - y0)
	var cx: float = (x0 + x1) * 0.5
	var cy: float = (y0 + y1) * 0.5
	var diam: float = minf(full_w, full_h)
	if age < 0.62:
		var u: float = clampf(age / 0.62, 0.0, 1.0)
		var grow: float = 0.18 + 0.82 * (1.0 - (1.0 - u) * (1.0 - u))
		var frame: int = mini(3, int(u * 3.99))
		var body: float = diam * grow
		var ring: float = minf(diam, body + diam * 0.1)
		if bloom:
			_blit_square(ci, "ex", 3, cx, cy, ring, Color(1, 0.96, 0.82, 0.4))
			_blit_square(ci, "ex", frame, cx, cy, body * 0.72, Color(1, 0.9, 0.65, 0.6))
			return
		_blit_square(ci, "ex", 3, cx, cy, ring, Color(1, 1, 1, 0.92))
		_blit_square(ci, "ex", frame, cx, cy, body, Color(1, 1, 1, 1.0))
		if frame >= 1:
			_blit_square(ci, "ex", 0, cx, cy, body * 0.42, Color(1, 0.98, 0.9, 0.72))
		return
	var tail: float = clampf((age - 0.62) / 3.08, 0.0, 0.999)
	var ember: int = 4 + mini(3, int(tail * 3.99))
	var fade: float = 1.0
	if age > 3.25:
		fade = clampf((3.7 - age) / 0.45, 0.0, 1.0)
	var ember_d: float = diam * 0.94
	var ember_y: float = cy + diam * 0.03
	if bloom:
		_blit_square(ci, "ex", ember, cx, ember_y, ember_d * 0.48, Color(1.0, 0.62, 0.28, fade * 0.34))
		return
	_blit_square(ci, "ex", ember, cx, ember_y, ember_d, Color(1, 1, 1, fade))


static func _blit_square(ci: CanvasItem, kind: String, frame: int, cx: float, cy: float, diam: float, tint: Color) -> void:
	if diam < 2.0:
		return
	blit(ci, kind, frame, Rect2(cx - diam * 0.5, cy - diam * 0.5, diam, diam), false, tint)


static func _draw_slash(ci: CanvasItem, mark: Dictionary, bloom: bool) -> void:
	var life: float = float(mark.get("life", 1.05))
	var age: float = float(mark.get("age", 0.0))
	var near: float = float(mark.get("near", 0.0))
	var far: float = float(mark.get("far", 0.0))
	var y: float = float(mark.get("y", 0.0))
	var travel: float = life * 0.68
	var u: float = clampf(age / maxf(0.05, travel), 0.0, 1.0)
	var eased: float = 1.0 - (1.0 - u) * (1.0 - u)
	var flip: bool = far < near
	var at: float = lerpf(near, far, eased)
	if age >= travel:
		at = far
	if not bloom:
		var span: float = absf(at - near)
		var step_px: float = 84.0
		var walked: float = 0.0
		var dir_sign: float = 1.0
		if at < near:
			dir_sign = -1.0
		var stamp_i: int = 0
		while walked <= span and stamp_i < 48:
			var gx: float = near + dir_sign * walked
			var slot: int = 6
			if stamp_i % 2 == 1:
				slot = 7
			_place_ground(ci, gx, y, flip, slot, 0.95)
			walked += step_px
			stamp_i += 1
	var frame: int = 0
	var wide: float = 250.0
	var tall: float = 176.0
	var tint: Color = Color(1, 1, 1, 1)
	if age < travel:
		frame = mini(3, int(eased * 4.0))
		if bloom:
			tint = Color(1, 0.96, 0.78, 0.5)
		else:
			var ghost: int = 2
			while ghost >= 1:
				var gu: float = maxf(0.0, eased - 0.16 * float(ghost))
				var gx_g: float = lerpf(near, far, gu)
				var gframe: int = maxi(0, frame - 1)
				var galpha: float = 0.28
				if ghost == 1:
					galpha = 0.5
				_place_slash(ci, gx_g, y, flip, gframe, 214.0, 150.0, Color(1, 1, 1, galpha))
				ghost -= 1
	else:
		var tail: float = clampf((age - travel) / maxf(0.05, life - travel), 0.0, 0.999)
		frame = 4 + mini(3, int(tail * 4.0))
		wide = 286.0
		tall = 198.0
		if bloom:
			tint = Color(1, 0.95, 0.7, 0.45)
	if bloom and frame >= 6:
		return
	_place_slash(ci, at, y, flip, frame, wide, tall, tint)


static func _place_slash(ci: CanvasItem, tip_x: float, road_y: float, flip: bool, frame: int, wide: float, tall: float, tint: Color) -> void:
	var tip_bias: float = 0.92
	var left: float = tip_x - wide * tip_bias
	if flip:
		left = tip_x - wide * (1.0 - tip_bias)
	blit(ci, "ls", frame, Rect2(left, road_y - tall * 0.78, wide, tall), flip, tint)


static func _place_ground(ci: CanvasItem, at_x: float, road_y: float, flip: bool, frame: int, alpha: float) -> void:
	var wide: float = 136.0
	var tall: float = 112.0
	blit(ci, "ls", frame, Rect2(at_x - wide * 0.5, road_y - tall * 0.74, wide, tall), flip, Color(1, 1, 1, alpha))


static func _paint_blast(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	var center: Vector2 = Vector2(w * 0.5, h * 0.5)
	if frame >= 4:
		_paint_embers(ci, frame, center, w)
		return
	var spin: float = float(frame) * 0.7
	_disc(ci, center, w * 0.47, Color(1.0, 0.28, 0.04, 0.7))
	_disc(ci, center, w * 0.38, Color(0.62, 0.08, 0.01, 1.0))
	_disc(ci, center, w * 0.27, Color(1.0, 0.4, 0.05, 1.0))
	_disc(ci, center, w * 0.15, Color(1.0, 0.8, 0.28, 1.0))
	_disc(ci, center, w * 0.07, Color(1.0, 0.98, 0.9, 1.0))
	_ring_tongues(ci, center, w * 0.28, w * 0.18, 18 + frame * 2, spin, Color(1.0, 0.36, 0.04, 1.0), Color(1.0, 0.78, 0.28, 1.0))
	_ring_tongues(ci, center, w * 0.14, w * 0.12, 11 + frame, -spin * 1.4, Color(1.0, 0.62, 0.1, 1.0), Color(1.0, 0.96, 0.7, 1.0))
	_shock(ci, center, w * (0.33 + float(frame) * 0.035), 4.5 + float(frame) * 1.4, Color(1.0, 0.94, 0.75, 0.95))
	_shock(ci, center, w * (0.24 + float(frame) * 0.02), 2.2, Color(1.0, 0.7, 0.22, 0.65))
	var ray_i: int = 0
	var rays: int = 16 + frame * 2
	while ray_i < rays:
		var ang: float = TAU * float(ray_i) / float(rays) + spin
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var length: float = w * (0.12 + 0.22 * _unit(ray_i * 13 + frame * 5))
		var thick: float = 2.4 + 3.4 * _unit(ray_i * 3 + 9)
		_ray(ci, center + dir * (w * 0.08), dir, length, thick, Color(1.0, 0.92, 0.6, 0.9))
		ray_i += 1
	_sparks(ci, center, w * 0.44, 16 + frame * 5, spin * 2.0, 1.15 + float(frame) * 0.2)
	var chunk_i: int = 0
	while chunk_i < 8 + frame * 2:
		var ang_c: float = spin * 0.8 + float(chunk_i) * 0.85
		var dist: float = w * (0.3 + 0.14 * _unit(chunk_i * 11 + frame))
		var at: Vector2 = center + Vector2(cos(ang_c), sin(ang_c)) * dist
		_rock(ci, at, 4.5 + _unit(chunk_i) * 5.0, ang_c, Color(0.32, 0.14, 0.06, 0.95))
		_rock(ci, at + Vector2(4, -3), 2.2, ang_c + 0.8, Color(1.0, 0.72, 0.22, 0.9))
		chunk_i += 1
	var filament: int = 0
	while filament < 7:
		var a0: float = spin + float(filament) * 0.9
		ci.draw_arc(center, w * (0.12 + 0.02 * float(filament % 3)), a0, a0 + 1.15, 10, Color(1, 0.97, 0.86, 0.92), 2.6)
		filament += 1


static func _paint_embers(ci: CanvasItem, frame: int, center: Vector2, w: float) -> void:
	var spin: float = float(frame) * 0.9
	_disc(ci, center, w * 0.44, Color(0.85, 0.18, 0.03, 0.34))
	_disc(ci, center + Vector2(0, w * 0.03), w * 0.3, Color(0.55, 0.1, 0.02, 0.45))
	var i: int = 0
	while i < 26:
		var ang: float = TAU * float(i) / 26.0 + spin * 0.2
		var dist: float = w * (0.06 + 0.32 * _unit(i * 13 + frame * 7))
		var at: Vector2 = center + Vector2(cos(ang) * dist, sin(ang) * dist * 0.82 + w * 0.03)
		var tall: float = w * (0.045 + 0.055 * _unit(i * 5 + frame))
		var hot: Color = Color(1.0, 0.38, 0.05, 0.96)
		var core: Color = Color(1.0, 0.88, 0.42, 1.0)
		_flame(ci, at + Vector2(0, tall * 0.25), tall, tall * 0.32, hot, core)
		_disc(ci, at + Vector2(0, -tall * 0.15), 2.0 + _unit(i + frame) * 2.2, Color(1, 0.86, 0.4, 0.95))
		i += 1
	var spark: int = 0
	while spark < 18:
		var ang_s: float = spin + float(spark) * 1.7
		var dist_s: float = w * (0.1 + 0.32 * _unit(spark * 19 + frame))
		var at_s: Vector2 = center + Vector2(cos(ang_s) * dist_s, sin(ang_s) * dist_s * 0.78)
		_disc(ci, at_s, 1.7 + _unit(spark * 3) * 2.4, Color(1, 0.95, 0.7, 1))
		spark += 1
	var smoke_i: int = 0
	while smoke_i < 7:
		var ang_m: float = float(smoke_i) * 0.9 + spin
		var at_m: Vector2 = center + Vector2(cos(ang_m), sin(ang_m) * 0.72) * w * (0.16 + 0.04 * float(smoke_i % 3))
		_disc(ci, at_m, w * 0.055, Color(0.32, 0.18, 0.12, 0.32))
		smoke_i += 1


static func _paint_slash(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	if frame >= 6:
		_paint_fissure(ci, size, frame)
		return
	var reveal: float = 1.0
	if frame <= 0:
		reveal = 0.34
	elif frame == 1:
		reveal = 0.58
	elif frame == 2:
		reveal = 0.82
	var p0: Vector2 = Vector2(w * 0.05, h * 0.82)
	var p1: Vector2 = Vector2(w * 0.4, h * 0.05)
	var p2: Vector2 = Vector2(w * 0.92, h * 0.58)
	_paint_cut_ground(ci, size, reveal, frame)
	_curve(ci, p0, p1, p2, 28.0, Color(0.42, 0.1, 0.04, 0.96), 16, 0.0, reveal)
	_curve(ci, p0, p1, p2, 16.0, Color(0.98, 0.52, 0.1, 1.0), 16, 0.0, reveal)
	_curve(ci, p0, p1, p2, 8.0, Color(1.0, 0.86, 0.42, 1.0), 16, 0.0, reveal)
	_curve(ci, p0, p1, p2, 2.8, Color(1.0, 0.99, 0.94, 1.0), 16, 0.0, reveal)
	var spark: int = 0
	while spark < 11:
		var t: float = 0.06 + float(spark) * 0.08
		if t > reveal:
			spark += 1
			continue
		var at: Vector2 = _bez(p0, p1, p2, t)
		var jitter: Vector2 = Vector2(_unit(spark * 5 + frame) * 12.0 - 6.0, _unit(spark * 9) * 10.0 - 4.0)
		_disc(ci, at + jitter, 2.2 + _unit(spark + frame) * 2.4, Color(1, 0.95, 0.72, 0.95))
		spark += 1
	if frame < 4:
		return
	var flash_r: float = 24.0 + float(frame - 4) * 20.0
	_glow(ci, p2, flash_r * 1.35, Color(1.0, 0.72, 0.28, 0.95))
	_disc(ci, p2, flash_r, Color(1.0, 0.5, 0.08, 1.0))
	_disc(ci, p2, flash_r * 0.55, Color(1.0, 0.9, 0.55, 1.0))
	_disc(ci, p2, flash_r * 0.22, Color(1, 1, 1, 1))
	var ray_i: int = 0
	while ray_i < 14:
		var ang: float = TAU * float(ray_i) / 14.0 + float(frame) * 0.4
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		_ray(ci, p2, dir, flash_r * (1.05 + 0.45 * _unit(ray_i * 7 + frame)), 3.4, Color(1.0, 0.95, 0.75, 0.95))
		ray_i += 1
	_sparks(ci, p2, flash_r * 1.1, 14, float(frame), 1.3)
	var bit: int = 0
	while bit < 6:
		var ang_b: float = float(bit) + float(frame)
		var at_b: Vector2 = p2 + Vector2(cos(ang_b), sin(ang_b)) * (flash_r * 0.8)
		_rock(ci, at_b, 5.0 + _unit(bit * 4) * 4.0, ang_b, Color(0.34, 0.24, 0.16, 1.0))
		bit += 1


static func _paint_cut_ground(ci: CanvasItem, size: Vector2, reveal: float, frame: int) -> void:
	var w: float = size.x
	var h: float = size.y
	var y0: float = h * 0.74
	var x1: float = 12.0 + (w * 0.9 - 12.0) * reveal
	_fissure_poly(ci, 8.0, x1, y0, frame, 1.0)
	var rock_i: int = 0
	var rocks: int = 5 + int(reveal * 6.0)
	while rock_i < rocks:
		var t: float = (float(rock_i) + 0.5) / float(rocks)
		var x: float = lerpf(14.0, x1, t)
		var lift: float = _unit(rock_i * 11 + frame * 3) * 16.0
		var rad: float = 5.0 + _unit(rock_i * 7 + frame) * 7.0
		var side: float = -1.0
		if rock_i % 2 == 0:
			side = 1.0
		_rock(ci, Vector2(x, y0 + side * (7.0 + lift * 0.25)), rad, float(rock_i) + float(frame), Color(0.3, 0.22, 0.15, 1.0))
		_rock(ci, Vector2(x + 5.0, y0 + side * 3.0), rad * 0.45, float(rock_i) + 0.7, Color(0.52, 0.38, 0.26, 1.0))
		_disc(ci, Vector2(x, y0 - 12.0 - lift), 8.0 + lift * 0.35, Color(0.74, 0.62, 0.44, 0.5))
		_disc(ci, Vector2(x + 8.0, y0 - 6.0 - lift * 0.4), 4.5, Color(0.9, 0.82, 0.66, 0.35))
		rock_i += 1


static func _paint_fissure(ci: CanvasItem, size: Vector2, frame: int) -> void:
	var w: float = size.x
	var h: float = size.y
	var y0: float = h * 0.7
	_fissure_poly(ci, 6.0, w - 6.0, y0, frame, 1.0)
	var i: int = 0
	var count: int = 9
	if frame >= 7:
		count = 6
	while i < count:
		var t: float = (float(i) + 0.35) / float(count)
		var x: float = lerpf(18.0, w - 18.0, t)
		var lift: float = 10.0 + _unit(i * 13 + frame * 2) * 20.0
		var side: float = 1.0
		if i % 2 == 0:
			side = -1.0
		_rock(ci, Vector2(x, y0 + side * 14.0), 6.0 + _unit(i * 3 + frame) * 6.0, float(i) + float(frame), Color(0.28, 0.2, 0.14, 1))
		_disc(ci, Vector2(x, y0 - lift), 9.0 + lift * 0.28, Color(0.76, 0.64, 0.46, 0.52))
		_disc(ci, Vector2(x + 7.0, y0 - lift * 0.55), 4.5, Color(0.92, 0.84, 0.68, 0.34))
		i += 1
	if frame >= 7:
		_glow(ci, Vector2(w * 0.5, y0), w * 0.16, Color(1.0, 0.58, 0.16, 0.55))


static func _fissure_poly(ci: CanvasItem, x0: float, x1: float, y0: float, frame: int, alpha: float) -> void:
	if x1 - x0 < 6.0:
		return
	var steps: int = 8
	var top: PackedVector2Array = PackedVector2Array()
	var bot: PackedVector2Array = PackedVector2Array()
	var i: int = 0
	while i <= steps:
		var t: float = float(i) / float(steps)
		var x: float = lerpf(x0, x1, t)
		var jag: float = (_unit(i * 17 + frame * 5) - 0.5) * 11.0
		top.append(Vector2(x, y0 - 8.0 + jag))
		bot.append(Vector2(x, y0 + 15.0 + (_unit(i * 29 + frame) - 0.35) * 9.0))
		i += 1
	var pts: PackedVector2Array = PackedVector2Array()
	i = 0
	while i < top.size():
		pts.append(top[i])
		i += 1
	i = bot.size() - 1
	while i >= 0:
		pts.append(bot[i])
		i -= 1
	_poly(ci, pts, Color(0.1, 0.06, 0.04, alpha))
	var hot: PackedVector2Array = PackedVector2Array()
	var hot_bot: PackedVector2Array = PackedVector2Array()
	i = 0
	while i < top.size():
		hot.append(top[i] + Vector2(0, 5))
		hot_bot.append(top[i] + Vector2(0, 9))
		i += 1
	var seam: PackedVector2Array = PackedVector2Array()
	i = 0
	while i < hot.size():
		seam.append(hot[i])
		i += 1
	i = hot_bot.size() - 1
	while i >= 0:
		seam.append(hot_bot[i])
		i -= 1
	_poly(ci, seam, Color(1.0, 0.46, 0.08, 0.9 * alpha))
	i = 0
	while i < top.size() - 1:
		ci.draw_line(top[i] + Vector2(0, 7), top[i + 1] + Vector2(0, 7), Color(1.0, 0.93, 0.7, 0.95 * alpha), 1.6)
		i += 1


static func _paint_frost(ci: CanvasItem, frame: int, size: Vector2) -> void:
	if frame >= 7:
		_paint_lock(ci, size)
		return
	if frame >= 3:
		_paint_ice_sheet(ci, frame, size)
		return
	_paint_race(ci, frame, size)


static func _paint_race(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	var origin: Vector2 = Vector2(w * 0.06, h * 0.52)
	var mist: int = 0
	while mist < 6:
		var mx: float = w * (0.18 + float(mist) * 0.12)
		var my: float = h * (0.28 + float(mist % 3) * 0.16)
		_disc(ci, Vector2(mx, my), 14.0 + float(frame + mist) * 2.0, Color(0.72, 0.9, 1.0, 0.2))
		mist += 1
	var count: int = 12 + frame * 3
	var shard: int = 0
	while shard < count:
		var spread: float = (float(shard) / float(count) - 0.5) * 1.25
		var dir: Vector2 = Vector2(cos(spread), sin(spread))
		var length: float = w * (0.28 + 0.5 * _unit(shard * 11 + frame * 4))
		var thick: float = 3.2 + _unit(shard * 5 + frame) * 5.5
		_shard(ci, origin, dir, length, thick, Color(0.42, 0.76, 0.98, 1.0), Color(0.94, 0.99, 1.0, 1.0))
		shard += 1
	var gem_i: int = 0
	while gem_i < 9:
		var gx: float = w * (0.2 + _unit(gem_i * 17 + frame) * 0.68)
		var gy: float = h * (0.12 + _unit(gem_i * 9 + 2) * 0.74)
		_gem(ci, Vector2(gx, gy), 3.5 + _unit(gem_i + frame) * 5.5, Color(0.68, 0.9, 1.0, 0.95), Color(1, 1, 1, 1))
		gem_i += 1
	_disc(ci, Vector2(w * 0.9, h * 0.5), 14.0 + float(frame) * 4.0, Color(1, 1, 1, 0.95))
	_disc(ci, Vector2(w * 0.9, h * 0.5), 6.0, Color(0.72, 0.92, 1.0, 1.0))
	_shock(ci, Vector2(w * 0.7, h * 0.5), 16.0 + float(frame) * 10.0, 2.2, Color(0.88, 0.97, 1.0, 0.75))


static func _paint_ice_sheet(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	ci.draw_rect(Rect2(0, 0, w, h), Color(0.32, 0.66, 0.9, 0.9))
	ci.draw_rect(Rect2(0, 0, w, h * 0.24), Color(0.9, 0.98, 1.0, 0.96))
	ci.draw_rect(Rect2(0, h * 0.58, w, h * 0.42), Color(0.14, 0.4, 0.66, 0.94))
	ci.draw_rect(Rect2(0, h * 0.3, w, h * 0.16), Color(0.78, 0.93, 1.0, 0.38))
	var shine_x: float = w * (0.08 + 0.14 * float(frame % 4))
	_poly(ci, PackedVector2Array([
		Vector2(shine_x, 0),
		Vector2(shine_x + w * 0.16, 0),
		Vector2(shine_x + w * 0.05, h),
		Vector2(shine_x - w * 0.07, h),
	]), Color(1, 1, 1, 0.3))
	var crack: int = 0
	while crack < 8:
		var x: float = w * (0.05 + float((crack * 3 + frame) % 9) * 0.1)
		var bend: float = (_unit(crack * 19 + frame) - 0.5) * 30.0
		ci.draw_line(Vector2(x, h * 0.05), Vector2(x + bend, h * 0.52), Color(0.05, 0.18, 0.36, 0.92), 2.4)
		ci.draw_line(Vector2(x + bend, h * 0.52), Vector2(x + bend * 0.35, h * 0.97), Color(0.04, 0.14, 0.3, 0.88), 2.0)
		ci.draw_line(Vector2(x + bend, h * 0.46), Vector2(x + bend + 18.0, h * 0.74), Color(0.08, 0.22, 0.4, 0.75), 1.5)
		crack += 1
	var gem_i: int = 0
	while gem_i < 8:
		var gx: float = w * (float(gem_i) + 0.45) / 8.0
		var gy: float = h * (0.2 + _unit(gem_i * 8 + frame) * 0.55)
		_gem(ci, Vector2(gx, gy), 5.5 + _unit(gem_i * 4 + frame) * 5.0, Color(0.8, 0.95, 1.0, 0.96), Color(1, 1, 1, 1))
		gem_i += 1
	var icicle: int = 0
	while icicle < 11:
		var ix: float = w * (float(icicle) + 0.3) / 11.0
		var ih: float = 9.0 + float((icicle * 2 + frame) % 5) * 5.0
		_poly(ci, PackedVector2Array([
			Vector2(ix - 4.2, 1.0),
			Vector2(ix + 4.2, 1.0),
			Vector2(ix, 1.0 + ih),
		]), Color(0.86, 0.97, 1.0, 0.96))
		_poly(ci, PackedVector2Array([
			Vector2(ix - 1.5, 2.0),
			Vector2(ix + 1.1, 2.0),
			Vector2(ix - 0.3, ih * 0.72),
		]), Color(1, 1, 1, 0.88))
		icicle += 1
	var spark: int = 0
	while spark < 16:
		var sx: float = w * _unit(spark * 13 + frame * 3)
		var sy: float = h * (0.16 + _unit(spark * 29 + frame) * 0.72)
		_disc(ci, Vector2(sx, sy), 1.5 + _unit(spark + frame) * 1.8, Color(1, 1, 1, 0.95))
		spark += 1
	var needle: int = 0
	while needle < 8:
		var nx: float = w * (float(needle) + 0.4) / 8.0
		_shard(ci, Vector2(nx, h * 0.84), Vector2(0.2, -1.0).normalized(), 14.0 + _unit(needle * 6 + frame) * 16.0, 2.3, Color(0.78, 0.94, 1, 0.92), Color(1, 1, 1, 1))
		needle += 1


static func _paint_lock(ci: CanvasItem, size: Vector2) -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.58)
	ci.draw_arc(c + Vector2(0, -16.0), 26.0, PI + 0.15, TAU - 0.15, 14, Color(0.9, 0.98, 1.0, 1.0), 9.0)
	ci.draw_arc(c + Vector2(0, -16.0), 26.0, PI + 0.35, PI + 1.3, 6, Color(1, 1, 1, 0.9), 3.0)
	var body := Rect2(c.x - 34.0, c.y - 6.0, 68.0, 48.0)
	ci.draw_rect(body, Color(0.5, 0.82, 1.0, 1.0))
	ci.draw_rect(Rect2(body.position.x + 5.0, body.position.y + 5.0, body.size.x - 10.0, 10.0), Color(0.92, 0.98, 1.0, 1.0))
	_disc(ci, c + Vector2(0, 16.0), 7.0, Color(0.08, 0.2, 0.34, 1.0))
	ci.draw_rect(Rect2(c.x - 3.0, c.y + 16.0, 6.0, 12.0), Color(0.08, 0.2, 0.34, 1.0))


static func _paint_aura(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.58)
	var spin: float = TAU * float(frame) / 8.0
	_glow(ci, center, size.x * 0.46, Color(1.0, 0.32, 0.04, 0.9))
	_disc(ci, center, size.x * 0.18, Color(1.0, 0.42, 0.05, 0.28))
	var tongue: int = 0
	var tongues: int = 20
	while tongue < tongues:
		var ang: float = TAU * float(tongue) / float(tongues) + spin * 0.35
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var up: float = clampf(-dir.y, 0.0, 1.0)
		var wobble: float = 0.5 + 0.5 * sin(float(frame) * 1.35 + float(tongue) * 1.15)
		var inner: float = size.x * 0.15
		var outer: float = inner + size.y * (0.07 + 0.1 * wobble + 0.13 * up)
		var base: Vector2 = center + dir * inner
		var tip: Vector2 = center + dir * outer
		var side: Vector2 = Vector2(-dir.y, dir.x) * (4.5 + wobble * 7.0)
		_poly(ci, PackedVector2Array([base - side, tip, base + side]), Color(1.0, 0.26, 0.03, 0.97))
		_poly(ci, PackedVector2Array([
			base - side * 0.4,
			tip - dir * (outer - inner) * 0.22,
			base + side * 0.4,
		]), Color(1.0, 0.7, 0.2, 1.0))
		tongue += 1
	var mid_i: int = 0
	while mid_i < 12:
		var ang_m: float = spin + TAU * float(mid_i) / 12.0
		var dir_m: Vector2 = Vector2(cos(ang_m), sin(ang_m))
		var up_m: float = clampf(-dir_m.y, 0.0, 1.0)
		var a: Vector2 = center + dir_m * (size.x * 0.09)
		var b: Vector2 = center + dir_m * (size.x * (0.2 + 0.08 * up_m) + float((mid_i + frame) % 3) * 3.0)
		var nrm: Vector2 = Vector2(-dir_m.y, dir_m.x) * 5.5
		_poly(ci, PackedVector2Array([a - nrm, b, a + nrm]), Color(1.0, 0.55, 0.08, 1.0))
		_poly(ci, PackedVector2Array([a - nrm * 0.35, b - dir_m * 6.0, a + nrm * 0.35]), Color(1.0, 0.96, 0.72, 1.0))
		mid_i += 1
	_flame(ci, center + Vector2(0, size.y * 0.08), size.y * 0.36, size.x * 0.07, Color(1.0, 0.42, 0.05, 1), Color(1.0, 0.95, 0.7, 1))
	_flame(ci, center + Vector2(-12, size.y * 0.1), size.y * 0.24, size.x * 0.045, Color(1.0, 0.3, 0.03, 0.96), Color(1.0, 0.84, 0.38, 1))
	_flame(ci, center + Vector2(12, size.y * 0.11), size.y * 0.22, size.x * 0.042, Color(1.0, 0.3, 0.03, 0.96), Color(1.0, 0.84, 0.38, 1))
	_disc(ci, center + Vector2(0, -size.y * 0.02), size.x * 0.055, Color(1, 0.98, 0.9, 1))
	var ember: int = 0
	while ember < 12:
		var ang_e: float = spin * 1.7 + float(ember) * 0.8
		var lift: float = float((ember + frame * 2) % 5) * 8.0
		var at: Vector2 = center + Vector2(cos(ang_e) * size.x * 0.42, sin(ang_e) * size.y * 0.32 - lift)
		_disc(ci, at, 2.4 + _unit(ember * 3 + frame) * 2.6, Color(1.0, 0.94, 0.68, 1.0))
		_disc(ci, at + Vector2(0, -3), 1.2, Color(1, 1, 1, 0.9))
		ember += 1


static func _glow(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.4:
		return
	var outer: Color = color
	outer.a *= 0.2
	_disc(ci, at, radius, outer)
	var mid: Color = color
	mid.a *= 0.45
	_disc(ci, at, radius * 0.62, mid)
	_disc(ci, at, radius * 0.28, color)


static func _ring_tongues(ci: CanvasItem, center: Vector2, inner: float, reach: float, count: int, spin: float, hot: Color, core: Color) -> void:
	var tongue: int = 0
	while tongue < count:
		var ang: float = TAU * float(tongue) / float(maxi(count, 1)) + spin
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var wobble: float = 0.5 + 0.55 * _unit(tongue * 13 + int(spin * 17.0))
		var len: float = reach * wobble
		var base: Vector2 = center + dir * inner
		var tip: Vector2 = center + dir * (inner + len)
		var side: Vector2 = Vector2(-dir.y, dir.x) * (3.2 + len * 0.24)
		_poly(ci, PackedVector2Array([base - side, tip, base + side]), hot)
		_poly(ci, PackedVector2Array([
			base - side * 0.36,
			tip - dir * len * 0.22,
			base + side * 0.36,
		]), core)
		tongue += 1


static func _shock(ci: CanvasItem, center: Vector2, radius: float, width: float, color: Color) -> void:
	if radius < 1.0:
		return
	ci.draw_arc(center, radius, 0.0, TAU, 52, color, width)
	var soft: Color = color
	soft.a *= 0.4
	ci.draw_arc(center, radius, 0.0, TAU, 40, soft, width * 2.3)


static func _sparks(ci: CanvasItem, center: Vector2, radius: float, count: int, spin: float, scale: float) -> void:
	var spark: int = 0
	while spark < count:
		var ang: float = spin + float(spark) * 2.399
		var dist: float = radius * (0.7 + 0.4 * _unit(spark * 17 + int(absf(spin) * 8.0)))
		var at: Vector2 = center + Vector2(cos(ang), sin(ang)) * dist
		var rad: float = scale * (1.4 + _unit(spark * 7) * 2.3)
		_disc(ci, at, rad, Color(1.0, 0.9, 0.45, 1.0))
		_disc(ci, at, rad * 0.4, Color(1.0, 1.0, 0.95, 1.0))
		spark += 1


static func _rock(ci: CanvasItem, at: Vector2, radius: float, tilt: float, color: Color) -> void:
	var c: float = cos(tilt)
	var s: float = sin(tilt)
	var axis: Vector2 = Vector2(c, s) * radius
	var side: Vector2 = Vector2(-s, c) * (radius * 0.72)
	_poly(ci, PackedVector2Array([
		at - axis - side,
		at + side * 1.15,
		at + axis * 0.85 - side * 0.3,
	]), color)
	var lite: Color = Color(minf(color.r + 0.22, 1.0), minf(color.g + 0.16, 1.0), minf(color.b + 0.1, 1.0), color.a)
	_poly(ci, PackedVector2Array([
		at - axis * 0.15,
		at + side * 0.45,
		at + axis * 0.35,
	]), lite)


static func _shard(ci: CanvasItem, origin: Vector2, dir: Vector2, length: float, width: float, body: Color, edge: Color) -> void:
	var side: Vector2 = Vector2(-dir.y, dir.x) * width
	var tip: Vector2 = origin + dir * length
	var mid: Vector2 = origin + dir * length * 0.42
	_poly(ci, PackedVector2Array([
		origin - side * 0.25,
		mid - side,
		tip,
		mid + side,
		origin + side * 0.25,
	]), body)
	_poly(ci, PackedVector2Array([
		origin,
		tip,
		mid + side * 0.16,
	]), edge)


static func _gem(ci: CanvasItem, at: Vector2, radius: float, fill: Color, edge: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var k: int = 0
	while k < 6:
		var ang: float = TAU * float(k) / 6.0 - 0.4
		pts.append(at + Vector2(cos(ang), sin(ang)) * radius)
		k += 1
	_poly(ci, pts, fill)
	var inner: PackedVector2Array = PackedVector2Array()
	k = 0
	while k < 6:
		var ang_i: float = TAU * float(k) / 6.0 - 0.4
		inner.append(at + Vector2(cos(ang_i), sin(ang_i)) * radius * 0.38)
		k += 1
	_poly(ci, inner, edge)


static func _unit(seed: int) -> float:
	var n: int = seed % 2147483647
	if n < 0:
		n = -n
	n = (n * 1103515245 + 12345) % 2147483647
	return float(n % 10000) / 10000.0
static func _flame(ci: CanvasItem, base: Vector2, tall: float, half: float, hot: Color, core: Color) -> void:
	var lean: float = half * 0.28
	var tip: Vector2 = base + Vector2(lean, -tall)
	_poly(ci, PackedVector2Array([
		base + Vector2(-half, 0.0),
		base + Vector2(half, 0.0),
		tip,
	]), hot)
	_poly(ci, PackedVector2Array([
		base + Vector2(-half * 0.4, -tall * 0.16),
		base + Vector2(half * 0.4, -tall * 0.16),
		tip + Vector2(-lean * 0.2, tall * 0.3),
	]), core)


static func _curve(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, width: float, color: Color, segs: int, t0: float, t1: float) -> void:
	var prev: Vector2 = _bez(a, b, c, t0)
	var step: int = 0
	var point: Vector2 = prev
	while step < segs:
		var t: float = lerpf(t0, t1, float(step + 1) / float(segs))
		point = _bez(a, b, c, t)
		_band(ci, prev, point, width, color)
		prev = point
		step += 1


static func _bez(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return a * u * u + b * 2.0 * u * t + c * t * t


static func _band(ci: CanvasItem, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var delta: Vector2 = b - a
	var leng: float = delta.length()
	if leng < 0.6:
		return
	var dir: Vector2 = delta / leng
	var side: Vector2 = Vector2(-dir.y, dir.x) * width
	_poly(ci, PackedVector2Array([a - side, a + side, b + side, b - side]), color)


static func _ray(ci: CanvasItem, at: Vector2, dir: Vector2, length: float, width: float, color: Color) -> void:
	var side: Vector2 = Vector2(-dir.y, dir.x) * width
	_poly(ci, PackedVector2Array([at - side, at + dir * length, at + side]), color)


static func _disc(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.2:
		return
	ci.draw_circle(at, radius, color)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	if pts.size() >= 3:
		ci.draw_colored_polygon(pts, color)


static func _opaque(img: Image) -> int:
	var count: int = 0
	var w: int = img.get_width()
	var h: int = img.get_height()
	var y: int = 0
	while y < h:
		var x: int = 0
		while x < w:
			if img.get_pixel(x, y).a > 0.12:
				count += 1
			x += 4
		y += 4
	return count


class BakeHost extends Node:
	var kind: String = ""
	var vp: SubViewport = null
	var step: int = 0
	var tries: int = 0

	func _ready() -> void:
		var baker = load("res://scripts/skill_fx.gd")
		var box: Vector2 = baker.call("_cell", kind)
		var wide: int = (int(box.x) + int(baker.PAD)) * int(baker.FRAMES)
		vp = _viewport(Vector2i(wide, int(box.y)))
		var drawer := SheetDrawer.new()
		drawer.kind = kind
		add_child(vp)
		vp.add_child(drawer)

	func _process(_delta: float) -> void:
		if vp == null:
			queue_free()
			return
		step += 1
		if step == 1:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return
		var baker = load("res://scripts/skill_fx.gd")
		if step > 24:
			_store(baker, Image.create(maxi(vp.size.x, 1), maxi(vp.size.y, 1), false, Image.FORMAT_RGBA8), 0)
			queue_free()
			return
		if DisplayServer.get_name() == "headless":
			_store(baker, Image.create(maxi(vp.size.x, 1), maxi(vp.size.y, 1), false, Image.FORMAT_RGBA8), 0)
			queue_free()
			return
		var view_tex: ViewportTexture = vp.get_texture()
		var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		if view_tex != null:
			var grabbed: Image = view_tex.get_image()
			if grabbed != null:
				img = grabbed
		var seen: int = int(baker.call("_opaque", img))
		if seen == 0 and tries < 4:
			tries += 1
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return
		_store(baker, img, seen)
		img = null
		queue_free()

	func _store(baker, img: Image, seen: int) -> void:
		if seen == 0:
			pass
		else:
			img.fix_alpha_edges()
			if seen > int(baker.pixels):
				baker.pixels = seen
		var tex := ImageTexture.create_from_image(img)
		baker.sheets[kind] = {"ready": true, "tex": tex}
		baker.pending -= 1

	func _viewport(view_size: Vector2i) -> SubViewport:
		var made := SubViewport.new()
		made.disable_3d = true
		made.transparent_bg = true
		made.use_hdr_2d = false
		made.handle_input_locally = false
		made.gui_disable_input = true
		made.msaa_2d = Viewport.MSAA_DISABLED
		made.render_target_update_mode = SubViewport.UPDATE_DISABLED
		made.size = view_size
		return made


class SheetDrawer extends Node2D:
	var kind: String = ""

	func _draw() -> void:
		var baker = load("res://scripts/skill_fx.gd")
		baker.call("paint_sheet", self, kind)


class GlowLayer extends Node2D:
	var field: Node = null

	func _draw() -> void:
		if field == null:
			return
		var baker = load("res://scripts/skill_fx.gd")
		var burst_raw: Variant = field.get("bursts")
		var slash_raw: Variant = field.get("slash_fx")
		var hazard_raw: Variant = field.get("hazards")
		var burst_list: Array = []
		var slash_list: Array = []
		var hazard_list: Array = []
		if burst_raw is Array:
			burst_list = burst_raw
		if slash_raw is Array:
			slash_list = slash_raw
		if hazard_raw is Array:
			hazard_list = hazard_raw
		baker.call("draw_glow", self, burst_list, slash_list, hazard_list)


class MarkLayer extends Node2D:
	var field: Node = null

	func _draw() -> void:
		if field == null or not field.has_method("_bodies"):
			return
		var found: Variant = field.call("_bodies")
		if not (found is Array):
			return
		var bodies: Array = found
		var baker = load("res://scripts/skill_fx.gd")
		baker.call("draw_marks", self, bodies)

class BodyLayer extends Node2D:
	var field: Node = null

	func _draw() -> void:
		if field == null:
			return
		var baker = load("res://scripts/skill_fx.gd")
		var burst_raw: Variant = field.get("bursts")
		var slash_raw: Variant = field.get("slash_fx")
		var burst_list: Array = []
		var slash_list: Array = []
		if burst_raw is Array:
			burst_list = burst_raw
		if slash_raw is Array:
			slash_list = slash_raw
		baker.call("draw_world", self, burst_list, slash_list)
