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
	if bloom:
		return
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
		var grow: float = 0.28 + 0.72 * (1.0 - (1.0 - u) * (1.0 - u))
		var frame: int = mini(3, int(u * 3.99))
		_blit_square(ci, "ex", frame, cx, cy, diam * grow, Color(1, 1, 1, 1))
		return
	var tail: float = clampf((age - 0.62) / 3.08, 0.0, 0.999)
	var ember: int = 4 + mini(3, int(tail * 3.99))
	var fade: float = 1.0
	if age > 3.25:
		fade = clampf((3.7 - age) / 0.45, 0.0, 1.0)
	_blit_square(ci, "ex", ember, cx, cy + diam * 0.04, diam * 0.9, Color(1, 1, 1, fade))


static func _blit_square(ci: CanvasItem, kind: String, frame: int, cx: float, cy: float, diam: float, tint: Color) -> void:
	if diam < 2.0:
		return
	blit(ci, kind, frame, Rect2(cx - diam * 0.5, cy - diam * 0.5, diam, diam), false, tint)


static func _draw_slash(ci: CanvasItem, mark: Dictionary, bloom: bool) -> void:
	if bloom:
		return
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
	var spin: float = float(frame) * 0.62
	var shock_r: float = w * (0.34 + float(frame) * 0.012)
	var fire_r: float = shock_r * 0.62
	_hoop(ci, center, shock_r, 18.0, Color("f3e6c8"))
	_hoop(ci, center, fire_r, 12.0, Color("e07a28"))
	var tongue: int = 0
	var tongues: int = 8
	while tongue < tongues:
		var ang: float = TAU * float(tongue) / float(tongues) + spin
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var tall: float = w * (0.085 + 0.03 * _unit(tongue * 5 + frame * 3))
		var base: Vector2 = center + dir * (fire_r * 0.72)
		_flame_out(ci, base, dir, tall, tall * 0.48, Color("c44536"), Color("e6c36a"))
		tongue += 1
	_coin(ci, center, w * 0.125, Color("c44536"))
	_coin(ci, center, w * 0.074, Color("e6c36a"))
	_coin(ci, center, w * 0.036, Color("fff6c8"))
	var spark: int = 0
	while spark < 7:
		var ang_s: float = spin * 1.35 + float(spark) * 0.9
		var dist_s: float = shock_r * (0.98 + 0.07 * _unit(spark * 11 + frame))
		var at_s: Vector2 = center + Vector2(cos(ang_s), sin(ang_s)) * dist_s
		_coin(ci, at_s, 5.2 + _unit(spark * 3 + frame) * 3.2, Color("fff6c8"))
		spark += 1


static func _paint_embers(ci: CanvasItem, frame: int, center: Vector2, w: float) -> void:
	var ground: float = center.y + w * 0.16
	var coal: int = 0
	while coal < 6:
		var x: float = center.x + (float(coal) - 2.5) * w * 0.13
		var bob: float = (_unit(coal * 9 + frame * 4) - 0.5) * w * 0.05
		var tall: float = w * (0.07 + 0.045 * _unit(coal * 5 + frame))
		var hot: Color = Color("c44536")
		if coal % 2 == 1:
			hot = Color("e07a28")
		_flame(ci, Vector2(x, ground + bob), tall, tall * 0.42, hot, Color("e6c36a"))
		_coin(ci, Vector2(x, ground + bob - tall * 0.7), 4.0, Color("fff6c8"))
		coal += 1
	var spark: int = 0
	while spark < 4:
		var ang_s: float = float(spark) * 1.4 + float(frame) * 0.35
		var at_s: Vector2 = center + Vector2(cos(ang_s) * w * 0.14, -w * 0.02 + sin(ang_s) * w * 0.05)
		_coin(ci, at_s, 4.5, Color("e6c36a"))
		spark += 1


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
	_curve(ci, p0, p1, p2, 30.0, Color("1c140e"), 14, 0.0, reveal)
	_curve(ci, p0, p1, p2, 18.0, Color("c44536"), 14, 0.0, reveal)
	_curve(ci, p0, p1, p2, 10.0, Color("e6c36a"), 14, 0.0, reveal)
	_curve(ci, p0, p1, p2, 3.2, Color("fff6c8"), 14, 0.0, reveal)
	var spark: int = 0
	while spark < 5:
		var t: float = 0.14 + float(spark) * 0.16
		if t <= reveal:
			var at: Vector2 = _bez(p0, p1, p2, t)
			_coin(ci, at, 4.6, Color("fff6c8"))
		spark += 1
	if frame < 4:
		return
	_coin(ci, p2, 14.0, Color("e07a28"))
	_coin(ci, p2, 7.0, Color("fff6c8"))
	var bit: int = 0
	while bit < 5:
		var ang_b: float = TAU * float(bit) / 5.0 + float(frame) * 0.2
		var dir_b: Vector2 = Vector2(cos(ang_b), sin(ang_b))
		_flame_out(ci, p2 + dir_b * 12.0, dir_b, 16.0, 6.0, Color("c44536"), Color("e6c36a"))
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
		_rock(ci, Vector2(x, y0 + side * (7.0 + lift * 0.25)), rad, float(rock_i) + float(frame), Color("5c4636"))
		_rock(ci, Vector2(x + 5.0, y0 + side * 3.0), rad * 0.45, float(rock_i) + 0.7, Color("6b5340"))
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
		var side: float = 1.0
		if i % 2 == 0:
			side = -1.0
		_rock(ci, Vector2(x, y0 + side * 14.0), 6.0 + _unit(i * 3 + frame) * 6.0, float(i) + float(frame), Color("5c4636"))
		i += 1


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
		top.append(Vector2(x, y0 - 14.0 + jag))
		bot.append(Vector2(x, y0 + 22.0 + (_unit(i * 29 + frame) - 0.35) * 8.0))
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
	var crack: Color = Color("1c140e")
	crack.a = alpha
	_poly(ci, pts, crack)
	var hot: PackedVector2Array = PackedVector2Array()
	var hot_bot: PackedVector2Array = PackedVector2Array()
	i = 0
	while i < top.size():
		hot.append(top[i] + Vector2(0, 8))
		hot_bot.append(top[i] + Vector2(0, 16))
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
	var seam_c: Color = Color("e07a28")
	seam_c.a = alpha
	_poly(ci, seam, seam_c)
	var cream: Color = Color("fff6c8")
	cream.a = alpha
	i = 0
	while i < top.size() - 1:
		ci.draw_line(top[i] + Vector2(0, 12), top[i + 1] + Vector2(0, 12), cream, 3.2)
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
	var origin: Vector2 = Vector2(w * 0.08, h * 0.55)
	var shard: int = 0
	while shard < 6:
		var spread: float = (float(shard) / 5.0 - 0.5) * 0.95
		var dir: Vector2 = Vector2(cos(spread), sin(spread))
		var length: float = w * (0.4 + 0.28 * _unit(shard * 7 + frame * 3))
		var thick: float = 7.0 + _unit(shard * 4 + frame) * 4.0
		_shard(ci, origin, dir, length, thick, Color("7eb6e0"), Color("e7f6ff"))
		shard += 1
	var lead: Vector2 = Vector2(w * 0.84, h * 0.5)
	_coin(ci, lead, 16.0 + float(frame) * 2.5, Color("e7f6ff"))
	_coin(ci, lead, 7.0, Color("7eb6e0"))


static func _paint_ice_sheet(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	ci.draw_rect(Rect2(0, 0, w, h), Color("7eb6e0"))
	ci.draw_rect(Rect2(0, 0, w, h * 0.2), Color("e7f6ff"))
	ci.draw_rect(Rect2(0, h * 0.72, w, h * 0.28), Color("3d6f99"))
	ci.draw_line(Vector2(0, 3), Vector2(w, 3), Color("1c140e"), 5.0)
	ci.draw_line(Vector2(0, h - 3), Vector2(w, h - 3), Color("1c140e"), 5.0)
	var crack: int = 0
	while crack < 4:
		var x: float = w * (0.16 + float(crack) * 0.2)
		var bend: float = 16.0
		if crack % 2 == 0:
			bend = -16.0
		var knee: Vector2 = Vector2(x + bend, h * 0.48)
		ci.draw_line(Vector2(x, h * 0.1), knee, Color("1c140e"), 5.0)
		ci.draw_line(knee, Vector2(x + bend * 0.4, h * 0.9), Color("1c140e"), 5.0)
		ci.draw_line(knee, Vector2(knee.x + bend, h * 0.74), Color("1c140e"), 4.0)
		ci.draw_line(Vector2(x, h * 0.1), knee, Color("e7f6ff"), 1.8)
		crack += 1
	var tooth: int = 0
	while tooth < 6:
		var tx: float = w * (float(tooth) + 0.5) / 6.0
		var th: float = 14.0 + float((tooth + frame) % 3) * 6.0
		_fill_ink(ci, PackedVector2Array([
			Vector2(tx - 7.0, 5.0),
			Vector2(tx + 7.0, 5.0),
			Vector2(tx, 5.0 + th),
		]), Color("e7f6ff"))
		tooth += 1
	var gem_i: int = 0
	while gem_i < 4:
		var gx: float = w * (0.18 + float(gem_i) * 0.2)
		var gy: float = h * (0.36 + float((gem_i + frame) % 2) * 0.16)
		_gem(ci, Vector2(gx, gy), 7.5, Color("d7eef8"), Color("fffefe"))
		gem_i += 1


static func _paint_lock(ci: CanvasItem, size: Vector2) -> void:
	var c: Vector2 = Vector2(size.x * 0.5, size.y * 0.58)
	var shackle: float = size.x * 0.22
	var hinge: Vector2 = c + Vector2(0, -shackle * 0.2)
	ci.draw_arc(hinge, shackle, PI + 0.15, TAU - 0.15, 18, Color("1c140e"), shackle * 0.55, false)
	ci.draw_arc(hinge, shackle, PI + 0.15, TAU - 0.15, 18, Color("e7f6ff"), shackle * 0.28, false)
	var body: Rect2 = Rect2(c.x - size.x * 0.28, c.y, size.x * 0.56, size.y * 0.38)
	ci.draw_rect(body.grow(6.0), Color("1c140e"))
	ci.draw_rect(body, Color("7eb6e0"))
	ci.draw_rect(Rect2(body.position.x + 8.0, body.position.y + 8.0, body.size.x - 16.0, body.size.y * 0.22), Color("e7f6ff"))
	_coin(ci, c + Vector2(0, body.size.y * 0.42), 9.0, Color("1c140e"))


static func _paint_aura(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.56)
	var spin: float = TAU * float(frame) / 8.0
	var tongue: int = 0
	while tongue < 8:
		var ang: float = TAU * float(tongue) / 8.0 + spin
		var dir: Vector2 = Vector2(cos(ang), sin(ang) * 0.9)
		if dir.length() < 0.01:
			dir = Vector2(0.0, -1.0)
		else:
			dir = dir.normalized()
		var wobble: float = 0.78 + 0.22 * sin(float(frame) * 1.3 + float(tongue) * 1.15)
		var base: Vector2 = center + dir * (size.x * 0.2)
		var length: float = size.y * (0.09 + 0.07 * wobble)
		_flame_out(ci, base, dir, length, 8.0 + wobble * 5.0, Color("c44536"), Color("e6c36a"))
		tongue += 1
	var mid_i: int = 0
	while mid_i < 5:
		var ang_m: float = spin * 1.5 + TAU * float(mid_i) / 5.0
		var dir_m: Vector2 = Vector2(cos(ang_m), sin(ang_m))
		var inner_at: Vector2 = center + dir_m * (size.x * 0.08)
		_flame_out(ci, inner_at, dir_m, size.y * 0.08, 6.0, Color("e07a28"), Color("fff6c8"))
		mid_i += 1
	var ember: int = 0
	while ember < 5:
		var ang_e: float = spin * 2.0 + float(ember) * 1.25
		var at: Vector2 = center + Vector2(cos(ang_e) * size.x * 0.38, sin(ang_e) * size.y * 0.28)
		_coin(ci, at, 4.2 + _unit(ember * 3 + frame) * 2.4, Color("fff6c8"))
		ember += 1


static func _fill_ink(ci: CanvasItem, pts: PackedVector2Array, fill: Color) -> void:
	var count: int = pts.size()
	if count < 3:
		return
	var mid: Vector2 = Vector2.ZERO
	var i: int = 0
	while i < count:
		mid += pts[i]
		i += 1
	mid /= float(count)
	var grown: PackedVector2Array = PackedVector2Array()
	i = 0
	while i < count:
		var spoke: Vector2 = pts[i] - mid
		var reach: float = spoke.length()
		if reach < 0.2:
			grown.append(pts[i])
		else:
			grown.append(mid + spoke * ((reach + 4.0) / reach))
		i += 1
	ci.draw_colored_polygon(grown, Color("1c140e"))
	ci.draw_colored_polygon(pts, fill)


static func _coin(ci: CanvasItem, at: Vector2, radius: float, fill: Color) -> void:
	if radius < 1.0:
		return
	ci.draw_circle(at, radius + 3.4, Color("1c140e"))
	ci.draw_circle(at, radius, fill)


static func _hoop(ci: CanvasItem, at: Vector2, radius: float, width: float, fill: Color) -> void:
	if radius < 2.0 or width < 1.0:
		return
	ci.draw_arc(at, radius, 0.0, TAU, 64, Color("1c140e"), width + 8.0, false)
	ci.draw_arc(at, radius, 0.0, TAU, 64, fill, width, false)


static func _flame_out(ci: CanvasItem, base: Vector2, dir: Vector2, length: float, half: float, hot: Color, core: Color) -> void:
	var side: Vector2 = Vector2(-dir.y, dir.x)
	if side.length() < 0.01:
		side = Vector2(0.0, 1.0)
	else:
		side = side.normalized()
	var tip: Vector2 = base + dir * length
	_fill_ink(ci, PackedVector2Array([
		base - side * half,
		base + side * half,
		tip,
	]), hot)
	_poly(ci, PackedVector2Array([
		base - side * half * 0.36 + dir * length * 0.24,
		base + side * half * 0.36 + dir * length * 0.24,
		base + dir * length * 0.62,
	]), core)


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
	_fill_ink(ci, PackedVector2Array([
		at - axis - side,
		at + side * 1.15,
		at + axis * 0.85 - side * 0.3,
	]), color)
	var lite: Color = Color(minf(color.r + 0.16, 1.0), minf(color.g + 0.12, 1.0), minf(color.b + 0.08, 1.0), 1.0)
	_poly(ci, PackedVector2Array([
		at - axis * 0.12,
		at + side * 0.4,
		at + axis * 0.28,
	]), lite)


static func _shard(ci: CanvasItem, origin: Vector2, dir: Vector2, length: float, width: float, body: Color, edge: Color) -> void:
	var side: Vector2 = Vector2(-dir.y, dir.x) * width
	var tip: Vector2 = origin + dir * length
	var mid: Vector2 = origin + dir * length * 0.42
	_fill_ink(ci, PackedVector2Array([
		origin - side * 0.25,
		mid - side,
		tip,
		mid + side,
		origin + side * 0.25,
	]), body)
	_poly(ci, PackedVector2Array([
		origin + dir * (length * 0.16),
		tip - dir * (length * 0.22),
		mid + side * 0.22,
	]), edge)


static func _gem(ci: CanvasItem, at: Vector2, radius: float, fill: Color, edge: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var k: int = 0
	while k < 6:
		var ang: float = TAU * float(k) / 6.0 - 0.4
		pts.append(at + Vector2(cos(ang), sin(ang)) * radius)
		k += 1
	_fill_ink(ci, pts, fill)
	var inner: PackedVector2Array = PackedVector2Array()
	k = 0
	while k < 6:
		var ang_i: float = TAU * float(k) / 6.0 - 0.4
		inner.append(at + Vector2(cos(ang_i), sin(ang_i)) * radius * 0.4)
		k += 1
	_poly(ci, inner, edge)


static func _unit(seed: int) -> float:
	var n: int = seed % 2147483647
	if n < 0:
		n = -n
	n = (n * 1103515245 + 12345) % 2147483647
	return float(n % 10000) / 10000.0
static func _flame(ci: CanvasItem, base: Vector2, tall: float, half: float, hot: Color, core: Color) -> void:
	var tip: Vector2 = base + Vector2(half * 0.15, -tall)
	_fill_ink(ci, PackedVector2Array([
		base + Vector2(-half, 0.0),
		base + Vector2(half, 0.0),
		tip,
	]), hot)
	_poly(ci, PackedVector2Array([
		base + Vector2(-half * 0.34, -tall * 0.22),
		base + Vector2(half * 0.28, -tall * 0.22),
		tip + Vector2(0.0, tall * 0.4),
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
