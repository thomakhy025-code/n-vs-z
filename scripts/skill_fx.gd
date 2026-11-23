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
		_draw_burst(ci, burst)
	for slash_raw in slashes:
		var slash: Dictionary = slash_raw
		_draw_slash(ci, slash)
	for hazard_raw in hazards:
		var patch: Dictionary = hazard_raw
		if str(patch.get("kind", "")) == "ice":
			_draw_ice_head(ci, patch)


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
		return Vector2(256, 176)
	if kind == "ls":
		return Vector2(220, 160)
	if kind == "fz":
		return Vector2(160, 112)
	return Vector2(200, 240)


static func _draw_fire(ci: CanvasItem, patch: Dictionary) -> void:
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y: float = float(patch.get("y", 0.0))
	var age: float = float(patch.get("age", 0.0))
	if x1 - x0 < 4.0:
		return
	var base: int = posmod(int(age * 10.0), 4)
	var tile_w: float = 132.0
	var tile_h: float = 84.0
	var cursor: float = x0
	var guard: int = 0
	while cursor < x1 - 1.0 and guard < 80:
		var span: float = minf(tile_w, x1 - cursor)
		var frame: int = 4 + posmod(base + guard, 4)
		blit(ci, "ex", frame, Rect2(cursor, y - 68.0, span, tile_h), false, Color(1, 1, 1, 0.96))
		cursor += tile_w - 10.0
		guard += 1


static func _draw_ice_sheet(ci: CanvasItem, patch: Dictionary) -> void:
	var cover: Vector2 = _ice_cover(patch)
	var y: float = float(patch.get("y", 0.0))
	var age: float = float(patch.get("age", 0.0))
	if cover.y - cover.x < 4.0:
		return
	var frame: int = 3 + posmod(int(age * 8.0), 4)
	var tile_w: float = 150.0
	var tile_h: float = 52.0
	var cursor: float = cover.x
	var guard: int = 0
	while cursor < cover.y - 1.0 and guard < 80:
		var span: float = minf(tile_w, cover.y - cursor)
		blit(ci, "fz", frame, Rect2(cursor, y - tile_h * 0.55, span, tile_h), false, Color(1, 1, 1, 0.92))
		cursor += tile_w - 8.0
		guard += 1


static func _draw_ice_head(ci: CanvasItem, patch: Dictionary) -> void:
	var age: float = float(patch.get("age", 0.0))
	if age >= 0.95:
		return
	var cover: Vector2 = _ice_cover(patch)
	var from_x: float = float(patch.get("from_x", cover.x))
	var y: float = float(patch.get("y", 0.0))
	var frame: int = mini(2, int(age * 3.2))
	var wide: float = 118.0
	var tall: float = 78.0
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


static func _draw_burst(ci: CanvasItem, patch: Dictionary) -> void:
	var age: float = float(patch.get("age", 0.0))
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y0: float = float(patch.get("y0", 0.0))
	var y1: float = float(patch.get("y1", 0.0))
	var full_w: float = maxf(8.0, x1 - x0)
	var full_h: float = maxf(8.0, y1 - y0)
	var cx: float = (x0 + x1) * 0.5
	var cy: float = (y0 + y1) * 0.5
	if age < 0.12:
		blit(ci, "ex", 0, Rect2(x0, y0, full_w, full_h), false, Color(1, 1, 1, 1.0))
		return
	var u: float = clampf((age - 0.12) / 0.40, 0.0, 1.0)
	var grow: float = 0.4 + 0.6 * (1.0 - (1.0 - u) * (1.0 - u))
	var frame: int = 1
	if u > 0.33:
		frame = 2
	if u > 0.66:
		frame = 3
	var fade: float = 1.0
	if age > 0.50:
		fade = clampf(1.0 - (age - 0.50) / 0.16, 0.0, 1.0)
	var bw: float = full_w * grow
	var bh: float = full_h * grow
	blit(ci, "ex", frame, Rect2(cx - bw * 0.5, cy - bh * 0.5, bw, bh), false, Color(1, 1, 1, fade))
	if frame >= 2:
		var inner: float = grow * 0.62
		blit(ci, "ex", 1, Rect2(cx - full_w * inner * 0.5, cy - full_h * inner * 0.5, full_w * inner, full_h * inner), false, Color(1, 0.96, 0.82, fade * 0.7))


static func _draw_slash(ci: CanvasItem, mark: Dictionary) -> void:
	var life: float = float(mark.get("life", 1.05))
	var age: float = float(mark.get("age", 0.0))
	var near: float = float(mark.get("near", 0.0))
	var far: float = float(mark.get("far", 0.0))
	var y: float = float(mark.get("y", 0.0))
	var travel: float = life * 0.68
	var u: float = clampf(age / maxf(0.05, travel), 0.0, 1.0)
	var eased: float = 1.0 - (1.0 - u) * (1.0 - u)
	var flip: bool = far < near
	var frame: int = 0
	var at: float = lerpf(near, far, eased)
	if age < travel:
		frame = mini(3, int(eased * 4.0))
		var ghost: int = 2
		while ghost >= 1:
			var gu: float = maxf(0.0, eased - 0.15 * float(ghost))
			var gx: float = lerpf(near, far, gu)
			var gframe: int = maxi(0, frame - 1)
			var galpha: float = 0.26
			if ghost == 1:
				galpha = 0.5
			_place_slash(ci, gx, y, flip, gframe, 196.0, 132.0, Color(1, 1, 1, galpha))
			ghost -= 1
	else:
		var tail: float = clampf((age - travel) / maxf(0.05, life - travel), 0.0, 0.999)
		frame = 4 + mini(3, int(tail * 4.0))
		at = far
	var wide: float = 236.0
	var tall: float = 158.0
	if frame >= 4:
		wide = 270.0
		tall = 180.0
	_place_slash(ci, at, y, flip, frame, wide, tall, Color(1, 1, 1, 1.0))


static func _place_slash(ci: CanvasItem, tip_x: float, road_y: float, flip: bool, frame: int, wide: float, tall: float, tint: Color) -> void:
	var tip_bias: float = 0.92
	var left: float = tip_x - wide * tip_bias
	if flip:
		left = tip_x - wide * (1.0 - tip_bias)
	blit(ci, "ls", frame, Rect2(left, road_y - tall * 0.78, wide, tall), flip, tint)


static func _paint_blast(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	var center := Vector2(w * 0.5, h * 0.48)
	if frame <= 0:
		_flash(ci, center, w, h)
		return
	if frame >= 4:
		_fire_bed(ci, frame, size)
		return
	if frame >= 3:
		_fire_bed(ci, frame, size)
	_burst_ball(ci, frame, center, w)


static func _flash(ci: CanvasItem, center: Vector2, w: float, h: float) -> void:
	_disc(ci, center, w * 0.28, Color(1.0, 0.46, 0.08, 0.55))
	_disc(ci, center, w * 0.16, Color(1.0, 0.82, 0.28, 0.95))
	_disc(ci, center, w * 0.07, Color(1.0, 0.98, 0.9, 1.0))
	var ray_i: int = 0
	while ray_i < 12:
		var ang: float = TAU * float(ray_i) / 12.0
		var dir := Vector2(cos(ang), sin(ang))
		var length: float = h * 0.42
		var width: float = 5.0
		if ray_i % 2 == 0:
			length = h * 0.62
			width = 3.2
		_ray(ci, center, dir, length, width, Color(1.0, 0.94, 0.72, 0.95))
		ray_i += 1
	ci.draw_arc(center, w * 0.2, 0.0, TAU, 28, Color(1.0, 0.96, 0.82, 0.95), 7.0)
	ci.draw_line(Vector2(8.0, center.y), Vector2(w - 8.0, center.y), Color(1, 1, 0.9, 0.85), 4.0)
	ci.draw_line(Vector2(center.x, 6.0), Vector2(center.x, h - 6.0), Color(1, 0.95, 0.75, 0.7), 3.0)


static func _burst_ball(ci: CanvasItem, frame: int, center: Vector2, w: float) -> void:
	var reach: float = w * (0.18 + float(frame) * 0.08)
	_disc(ci, center, reach, Color(0.85, 0.16, 0.03, 1.0))
	_disc(ci, center, reach * 0.72, Color(1.0, 0.48, 0.08, 1.0))
	_disc(ci, center, reach * 0.4, Color(1.0, 0.86, 0.4, 1.0))
	_disc(ci, center, reach * 0.16, Color(1.0, 0.98, 0.88, 1.0))
	var spikes: int = 7 + frame * 2
	var spike: int = 0
	while spike < spikes:
		var ang: float = TAU * float(spike) / float(spikes) + float(frame) * 0.31
		var dir := Vector2(cos(ang), sin(ang))
		var len: float = reach * (0.45 + 0.22 * float((spike + frame) % 3))
		var base: Vector2 = center + dir * (reach * 0.62)
		var tip: Vector2 = center + dir * (reach + len)
		var side: Vector2 = Vector2(-dir.y, dir.x) * (7.0 + float(frame) * 2.0)
		_poly(ci, PackedVector2Array([base - side, tip, base + side]), Color(1.0, 0.5, 0.08, 1.0))
		_poly(ci, PackedVector2Array([base - side * 0.38, tip - dir * len * 0.2, base + side * 0.38]), Color(1.0, 0.93, 0.55, 1.0))
		if spike % 2 == 0:
			_disc(ci, tip, 3.5, Color(1.0, 0.97, 0.8, 1.0))
		spike += 1
	ci.draw_arc(center, reach * 1.05, 0.2, TAU - 0.2, 24, Color(1.0, 0.9, 0.55, 0.8), 3.0)


static func _fire_bed(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	ci.draw_rect(Rect2(0, h * 0.34, w, h * 0.66), Color(0.62, 0.1, 0.02, 0.94))
	ci.draw_rect(Rect2(0, h * 0.58, w, h * 0.42), Color(0.95, 0.32, 0.05, 0.96))
	var tongues: int = 8
	var n: int = 0
	while n < tongues:
		var x: float = w * (float(n) + 0.5) / float(tongues)
		var hop: float = float((n * 3 + frame * 2) % 5)
		var tall: float = h * (0.42 + hop * 0.08)
		var half: float = w * 0.07
		var hot := Color(1.0, 0.45, 0.07, 1.0)
		var core := Color(1.0, 0.92, 0.5, 1.0)
		_flame(ci, Vector2(x, h * 0.96), tall, half, hot, core)
		if (n + frame) % 2 == 0:
			_disc(ci, Vector2(x + sin(float(n + frame)) * 4.0, h * 0.96 - tall - 4.0), 3.6, Color(1.0, 0.96, 0.72, 1.0))
		n += 1


static func _paint_slash(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var p0 := Vector2(size.x * 0.05, size.y * 0.88)
	var p1 := Vector2(size.x * 0.46, size.y * 0.02)
	var p2 := Vector2(size.x * 0.94, size.y * 0.4)
	var reveal: float = 1.0
	if frame <= 0:
		reveal = 0.3
	elif frame == 1:
		reveal = 0.55
	elif frame == 2:
		reveal = 0.82
	var fade: float = 1.0
	if frame >= 4:
		fade = 0.45
	if frame >= 6:
		fade = 0.16
	var streak: int = 0
	while streak < 4 and frame < 4:
		var sy: float = size.y * (0.2 + float(streak) * 0.16)
		ci.draw_line(Vector2(8.0, sy + 10.0), Vector2(size.x * reveal * 0.7, sy), Color(1.0, 0.9, 0.55, 0.45), 2.0)
		streak += 1
	_curve(ci, p0, p1, p2, 18.0, Color(1.0, 0.32, 0.08, 0.95 * fade), 12, 0.0, reveal)
	_curve(ci, p0, p1, p2, 9.0, Color(1.0, 0.78, 0.28, fade), 12, 0.0, reveal)
	if frame >= 2:
		_curve(ci, p0, p1, p2, 3.4, Color(1.0, 0.98, 0.92, fade), 12, 0.0, reveal)
	var spark: int = 0
	while spark < 6 and frame >= 2 and frame < 5:
		var t: float = 0.25 + float(spark) * 0.12
		if t > reveal:
			spark += 1
			continue
		var at: Vector2 = _bez(p0, p1, p2, t)
		_disc(ci, at + Vector2(-8.0, 6.0), 3.2, Color(1.0, 0.95, 0.7, 0.9))
		spark += 1
	if frame < 4:
		return
	var flash_r: float = 16.0 + float(frame - 4) * 16.0
	_disc(ci, p2, flash_r, Color(1.0, 0.72, 0.22, 0.95))
	_disc(ci, p2, flash_r * 0.55, Color(1.0, 0.95, 0.75, 1.0))
	_disc(ci, p2, flash_r * 0.22, Color(1, 1, 1, 1))
	var ray_i: int = 0
	while ray_i < 8:
		var ang: float = TAU * float(ray_i) / 8.0 + float(frame)
		var dir := Vector2(cos(ang), sin(ang))
		_ray(ci, p2, dir, flash_r * 1.35, 3.0, Color(1.0, 0.95, 0.7, 0.9))
		ray_i += 1


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
	var line_i: int = 0
	while line_i < 6:
		var y: float = h * (0.16 + float(line_i) * 0.12)
		ci.draw_line(Vector2(2.0, y), Vector2(w * 0.62, y - 3.0), Color(0.8, 0.95, 1.0, 0.75), 2.4)
		line_i += 1
	var count: int = 4 + frame * 2
	var shard: int = 0
	while shard < count:
		var y0: float = h * (0.12 + float(shard) * 0.76 / float(count))
		var len: float = w * (0.34 + float((shard + frame) % 3) * 0.1)
		var tip := Vector2(w * 0.94, y0)
		var base := Vector2(w * 0.94 - len, h * 0.5)
		_poly(ci, PackedVector2Array([base + Vector2(0, -8), tip, base + Vector2(0, 8)]), Color(0.45, 0.82, 1.0, 1.0))
		_poly(ci, PackedVector2Array([base + Vector2(len * 0.35, -3), tip + Vector2(-10, 0), base + Vector2(len * 0.35, 3)]), Color(0.94, 0.99, 1.0, 1.0))
		shard += 1
	_disc(ci, Vector2(w * 0.9, h * 0.5), 11.0, Color(1, 1, 1, 1.0))
	_disc(ci, Vector2(w * 0.9, h * 0.5), 5.0, Color(0.75, 0.94, 1.0, 1.0))


static func _paint_ice_sheet(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	ci.draw_rect(Rect2(0, 0, w, h), Color(0.58, 0.86, 1.0, 0.82))
	ci.draw_rect(Rect2(0, 0, w, h * 0.28), Color(0.92, 0.98, 1.0, 0.95))
	ci.draw_rect(Rect2(0, h * 0.7, w, h * 0.3), Color(0.28, 0.58, 0.82, 0.9))
	var crack: int = 0
	while crack < 5:
		var x: float = w * (0.08 + float((crack * 2 + frame) % 6) * 0.14)
		var bend: float = 10.0 - float(frame) * 2.0
		ci.draw_line(Vector2(x, h * 0.08), Vector2(x + bend, h * 0.92), Color(0.1, 0.32, 0.52, 0.85), 2.2)
		ci.draw_line(Vector2(x + bend, h * 0.5), Vector2(x + bend + 12.0, h * 0.78), Color(0.12, 0.34, 0.55, 0.7), 1.6)
		crack += 1
	var icicle: int = 0
	while icicle < 7:
		var ix: float = w * (float(icicle) + 0.5) / 7.0
		var ih: float = 8.0 + float((icicle + frame) % 4) * 4.0
		_poly(ci, PackedVector2Array([
			Vector2(ix - 5.0, 2.0),
			Vector2(ix + 5.0, 2.0),
			Vector2(ix, 2.0 + ih),
		]), Color(0.85, 0.96, 1.0, 0.95))
		icicle += 1
	var spark: int = 0
	while spark < 6:
		var sx: float = w * (0.12 + float((spark * 3 + frame) % 7) * 0.11)
		var sy: float = h * (0.28 + float((spark + frame) % 4) * 0.14)
		_disc(ci, Vector2(sx, sy), 2.8, Color(1, 1, 1, 0.95))
		spark += 1


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
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	var spin: float = TAU * float(frame) / 8.0
	var tongue: int = 0
	while tongue < 16:
		var ang: float = TAU * float(tongue) / 16.0 + spin * 0.2
		var dir := Vector2(cos(ang), sin(ang))
		var wobble: float = 0.5 + 0.5 * sin(float(frame) * 1.2 + float(tongue) * 1.3)
		var up: float = clampf(-dir.y, 0.0, 1.0)
		var inner: float = size.x * 0.2
		var outer: float = inner + size.y * (0.1 + 0.09 * wobble + 0.07 * up)
		var base: Vector2 = center + dir * inner
		var tip: Vector2 = center + dir * outer
		var side: Vector2 = Vector2(-dir.y, dir.x) * (6.0 + wobble * 5.0)
		_poly(ci, PackedVector2Array([base - side, tip, base + side]), Color(1.0, 0.3, 0.05, 0.96))
		_poly(ci, PackedVector2Array([
			base - side * 0.4,
			tip - dir * (outer - inner) * 0.18,
			base + side * 0.4,
		]), Color(1.0, 0.84, 0.38, 1.0))
		tongue += 1
	var inner_i: int = 0
	while inner_i < 10:
		var ang_i: float = spin + TAU * float(inner_i) / 10.0
		var dir_i := Vector2(cos(ang_i), sin(ang_i))
		var a: Vector2 = center + dir_i * (size.x * 0.16)
		var b: Vector2 = center + dir_i * (size.x * 0.28 + float((inner_i + frame) % 3) * 4.0)
		var n: Vector2 = Vector2(-dir_i.y, dir_i.x) * 4.0
		_poly(ci, PackedVector2Array([a - n, b, a + n]), Color(1.0, 0.95, 0.7, 0.95))
		inner_i += 1
	var ember: int = 0
	while ember < 7:
		var ang_e: float = spin * 1.4 + float(ember) * 0.9
		var lift: float = float((ember + frame) % 4) * 6.0
		var at: Vector2 = center + Vector2(cos(ang_e) * size.x * 0.42, sin(ang_e) * size.y * 0.34 - lift)
		_disc(ci, at, 3.8, Color(1.0, 0.95, 0.72, 1.0))
		ember += 1


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
