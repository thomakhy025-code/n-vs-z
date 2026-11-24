extends RefCounted

# One baked sheet per skill. Every cast of that skill blits a frame from the
# same texture, so a second explosion does not bake another sheet.
const FRAMES := 8
const PAD := 4
const SLASH_WIND := 0.42
const SLASH_STRIKE := 0.32
const SLASH_SPLIT := 1.0
const FROST_WIND := 0.68
const FROST_SHOW := 2.25

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
	if hazards.is_empty():
		return


static func draw_aim(ci: CanvasItem, at: Vector2, radius: float) -> void:
	if radius < 4.0:
		return
	var wash := Color("c44536")
	wash.a = 0.34
	ci.draw_circle(at, radius, wash)
	ci.draw_arc(at, radius, 0.0, TAU, 72, Color("1c140e"), 11.0, true)
	ci.draw_arc(at, maxf(4.0, radius - 9.0), 0.0, TAU, 72, Color("e6c36a"), 5.0, true)
	ci.draw_circle(at, 7.0, Color("1c140e"))
	ci.draw_circle(at, 3.2, Color("fff6c8"))


static func draw_world(ci: CanvasItem, bursts: Array, slashes: Array) -> void:
	for world_burst in bursts:
		var burst_row: Dictionary = world_burst
		_draw_burst(ci, burst_row, false)
	for world_slash in slashes:
		var slash_row: Dictionary = world_slash
		_draw_slash(ci, slash_row, false)


static func draw_marks(_ci: CanvasItem, _bodies: Array) -> void:
	pass


static func draw_frost(ci: CanvasItem, casts: Array) -> void:
	for raw in casts:
		var cast: Dictionary = raw
		var age: float = float(cast.get("age", 0.0))
		if age < FROST_WIND:
			var shown: float = clampf(age / FROST_WIND, 0.0, 1.0)
			_draw_ice_wind(ci, cast, shown)
		else:
			_draw_locked_bodies(ci, cast)
		_draw_snow(ci, cast)


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
		return Vector2(340, 340)
	if kind == "ls":
		return Vector2(240, 420)
	if kind == "fz":
		return Vector2(220, 132)
	return Vector2(240, 280)


static func _draw_fire(ci: CanvasItem, patch: Dictionary) -> void:
	if bool(patch.get("round", false)):
		_draw_round_fire(ci, patch)
		return
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y: float = float(patch.get("y", 0.0))
	var age: float = float(patch.get("age", 0.0))
	var span: float = x1 - x0
	if span < 4.0:
		return
	var cursor: float = x0 + 14.0
	var guard: int = 0
	while cursor < x1 - 8.0 and guard < 40:
		var tall: float = 16.0 + 14.0 * _unit(guard * 9 + int(age * 8.0))
		var hot := Color("c44536")
		if guard % 2 == 1:
			hot = Color("e07a28")
		_flame(ci, Vector2(cursor, y + 2.0), tall, tall * 0.36, hot, Color("e6c36a"))
		cursor += 26.0
		guard += 1


static func _draw_round_fire(ci: CanvasItem, patch: Dictionary) -> void:
	var cx: float = float(patch.get("cx", 0.0))
	var cy: float = float(patch.get("cy", 0.0))
	var radius: float = float(patch.get("radius", 40.0))
	var age: float = float(patch.get("age", 0.0))
	if radius < 6.0:
		return
	var n: int = 0
	var count: int = 12
	while n < count:
		var ang: float = TAU * float(n) / float(count) + age * 0.7
		var dist: float = radius * (0.16 + 0.62 * _unit(n * 13 + int(age * 5.0)))
		var at := Vector2(cx + cos(ang) * dist, cy + sin(ang) * dist * 0.72)
		var tall: float = radius * (0.09 + 0.1 * _unit(n * 7 + int(age * 9.0)))
		var hot := Color("c44536")
		if n % 2 == 1:
			hot = Color("e07a28")
		_flame(ci, at, tall, tall * 0.4, hot, Color("e6c36a"))
		n += 1


static func _draw_ice_sheet(ci: CanvasItem, patch: Dictionary) -> void:
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y: float = float(patch.get("y", 0.0))
	var age: float = float(patch.get("age", 0.0))
	var from_x: float = float(patch.get("from_x", (x0 + x1) * 0.5))
	var blow: float = float(patch.get("blow", 1.0))
	if x1 - x0 < 4.0:
		return
	var left: float = x0
	var right: float = x1
	var strength: float = 1.0
	if age < FROST_WIND:
		var shown: float = clampf(age / FROST_WIND, 0.0, 1.0)
		var reach: float = absf(x1 - x0) * shown
		strength = 0.55
		if blow >= 0.0:
			left = from_x
			right = minf(x1, from_x + reach)
		else:
			right = from_x
			left = maxf(x0, from_x - reach)
	if right - left < 8.0:
		return
	_paint_ground_ice(ci, left, right, y, strength)


static func _draw_burst(ci: CanvasItem, patch: Dictionary, bloom: bool) -> void:
	if bloom:
		return
	var age: float = float(patch.get("age", 0.0))
	var x0: float = float(patch.get("x0", 0.0))
	var x1: float = float(patch.get("x1", 0.0))
	var y0: float = float(patch.get("y0", 0.0))
	var y1: float = float(patch.get("y1", 0.0))
	var cx: float = (x0 + x1) * 0.5
	var cy: float = (y0 + y1) * 0.5
	var diam: float = minf(maxf(8.0, x1 - x0), maxf(8.0, y1 - y0))
	var frame: int = 5
	var fade: float = 1.0
	if age < 0.62:
		var fall: float = clampf(age / 0.62, 0.0, 0.999)
		frame = mini(2, int(fall * 3.0))
	elif age < 1.08:
		var boom: float = clampf((age - 0.62) / 0.46, 0.0, 0.999)
		frame = 3
		if boom >= 0.42:
			frame = 4
	else:
		var tail: float = clampf((age - 1.08) / 2.5, 0.0, 0.999)
		frame = 5 + mini(2, int(tail * 3.0))
		if age > 3.25:
			fade = clampf((3.7 - age) / 0.45, 0.0, 1.0)
	_blit_square(ci, "ex", frame, cx, cy, diam, Color(1, 1, 1, fade))


static func _blit_square(ci: CanvasItem, kind: String, frame: int, cx: float, cy: float, diam: float, tint: Color) -> void:
	if diam < 2.0:
		return
	blit(ci, kind, frame, Rect2(cx - diam * 0.5, cy - diam * 0.5, diam, diam), false, tint)


static func _draw_slash(ci: CanvasItem, mark: Dictionary, bloom: bool) -> void:
	if bloom:
		return
	var age: float = float(mark.get("age", 0.0))
	var y: float = float(mark.get("y", 0.0))
	var hx: float = float(mark.get("hx", 0.0))
	var hy: float = float(mark.get("hy", y))
	var x0: float = float(mark.get("x0", hx))
	var x1: float = float(mark.get("x1", hx))
	var box: Vector2 = _cell("ls")
	var aspect: float = box.x / maxf(1.0, box.y)
	if age < SLASH_WIND:
		var posed: float = clampf(age / SLASH_WIND, 0.0, 0.999)
		var sword_frame: int = 0
		if posed >= 0.5:
			sword_frame = 1
		var sword_h: float = 280.0
		var sword_w: float = sword_h * aspect
		var hilt_y: float = hy - 116.0
		blit(ci, "ls", sword_frame, Rect2(hx - sword_w * 0.5, hilt_y - sword_h * 0.56, sword_w, sword_h), false, Color(1, 1, 1, 1))
		return
	if age < SLASH_WIND + SLASH_STRIKE:
		var cut: float = clampf((age - SLASH_WIND) / SLASH_STRIKE, 0.0, 0.999)
		var bolt_frame: int = 2 + mini(2, int(cut * 2.99))
		var bolt_h: float = 330.0
		var bolt_w: float = bolt_h * aspect
		blit(ci, "ls", bolt_frame, Rect2(hx - bolt_w * 0.5, hy - bolt_h + 20.0, bolt_w, bolt_h), false, Color(1, 1, 1, 1))
		return
	var held: float = clampf((age - SLASH_WIND - SLASH_STRIKE) / SLASH_SPLIT, 0.0, 0.999)
	var split_frame: int = 5 + mini(2, int(held * 2.4))
	var tile_h: float = 120.0
	var tile_w: float = tile_h * aspect
	var left_x: float = minf(x0, x1)
	var right_x: float = maxf(x0, x1)
	if right_x - left_x < tile_w:
		right_x = left_x + tile_w
	var cursor: float = left_x
	var guard: int = 0
	while cursor < right_x - 1.0 and guard < 28:
		var span: float = minf(tile_w, right_x - cursor)
		blit(ci, "ls", split_frame, Rect2(cursor, y - tile_h * 0.55, span, tile_h), false, Color(1, 1, 1, 1))
		cursor += maxf(12.0, tile_w - 6.0)
		guard += 1


static func _paint_blast(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var ground := Vector2(size.x * 0.5, size.y * 0.62)
	if frame <= 2:
		_paint_meteor(ci, frame, ground, size)
		return
	if frame <= 4:
		_paint_boom(ci, frame, ground, size)
		return
	_paint_smoke_column(ci, frame, ground, size)


static func _paint_meteor(ci: CanvasItem, frame: int, ground: Vector2, size: Vector2) -> void:
	var w: float = size.x
	var drop: float = 0.12
	if frame == 1:
		drop = 0.3
	elif frame == 2:
		drop = 0.5
	var at := Vector2(ground.x, size.y * drop)
	var radius: float = w * (0.11 + float(frame) * 0.025)
	var shadow_w: float = radius * (1.1 + float(frame) * 0.55)
	_oval(ci, ground + Vector2(0.0, radius * 0.15), shadow_w, radius * 0.28, Color(0.04, 0.02, 0.02, 0.72))
	var trail: int = 0
	while trail < 6:
		var back: float = float(trail + 1) * radius * 0.72
		var sway: float = (float(trail) - 2.5) * radius * 0.22
		var puff_at := Vector2(at.x + sway, at.y - back)
		var puff_r: float = radius * (0.55 - float(trail) * 0.06)
		ci.draw_circle(puff_at + Vector2(2.0, 4.0), puff_r, Color("3a120c"))
		ci.draw_circle(puff_at, puff_r * 0.82, Color("c44536"))
		ci.draw_circle(puff_at + Vector2(-puff_r * 0.15, -puff_r * 0.2), puff_r * 0.38, Color("fff6c8"))
		trail += 1
	var wrap: int = 0
	while wrap < 10:
		var ang: float = TAU * float(wrap) / 10.0 + float(frame) * 0.6
		var dir := Vector2(cos(ang), sin(ang))
		var lick := at + dir * radius * 0.85
		var lick_r: float = radius * (0.28 + 0.12 * _unit(wrap * 5 + frame))
		var lick_c := Color("e07a28")
		if dir.y > 0.4:
			lick_c = Color("6b2418")
		elif dir.y < -0.35:
			lick_c = Color("fff6c8")
		ci.draw_circle(lick, lick_r + 3.0, Color("1c140e"))
		ci.draw_circle(lick, lick_r, lick_c)
		ci.draw_circle(lick + Vector2(-lick_r * 0.2, -lick_r * 0.25), lick_r * 0.35, Color("fff6c8"))
		wrap += 1
	_shaded_chunk(ci, at, radius * 0.72, float(frame) * 0.8)
	ci.draw_circle(at + Vector2(-radius * 0.12, -radius * 0.16), radius * 0.22, Color("e6c36a"))
	var star_i: int = 0
	while star_i < 5:
		var sx: float = at.x + (_unit(star_i * 9 + frame) - 0.5) * radius * 2.4
		var sy: float = at.y - radius * (1.2 + float(star_i) * 0.35)
		_star(ci, Vector2(sx, sy), 4.0 + float(star_i % 2) * 2.0, Color("fff6c8"))
		star_i += 1


static func _paint_boom(ci: CanvasItem, frame: int, ground: Vector2, size: Vector2) -> void:
	var w: float = size.x
	var heart := Vector2(w * 0.5, size.y * 0.44)
	var grow: float = 0.78
	if frame >= 4:
		grow = 1.0
	var radius: float = w * 0.34 * grow
	_oval(ci, ground + Vector2(0.0, radius * 0.08), radius * 1.45, radius * 0.34, Color(0.03, 0.02, 0.015, 0.82))
	_oval(ci, ground, radius * 1.05, radius * 0.16, Color(0.22, 0.12, 0.06, 0.55))
	_shock_ring(ci, heart, radius * 1.22)
	_fire_mass(ci, heart, radius, frame)
	_flying_bits(ci, heart, radius, frame)
	_blast_sparks(ci, heart, radius * 1.15, frame)


static func _paint_smoke_column(ci: CanvasItem, frame: int, ground: Vector2, size: Vector2) -> void:
	var w: float = size.x
	var rise: float = float(frame - 5)
	_oval(ci, ground + Vector2(0.0, w * 0.04), w * 0.42, w * 0.07, Color(0.04, 0.03, 0.02, 0.75))
	var coal: int = 0
	while coal < 7:
		var fx: float = ground.x + (float(coal) - 3.0) * w * 0.055
		var fr: float = w * (0.035 + 0.008 * float(coal % 3))
		ci.draw_circle(Vector2(fx, ground.y), fr + 2.5, Color("1c140e"))
		ci.draw_circle(Vector2(fx, ground.y + fr * 0.2), fr, Color("6b2418"))
		ci.draw_circle(Vector2(fx, ground.y - fr * 0.35), fr * 0.55, Color("e07a28"))
		ci.draw_circle(Vector2(fx - fr * 0.1, ground.y - fr * 0.55), fr * 0.22, Color("fff6c8"))
		coal += 1
	var puff: int = 0
	while puff < 16:
		var col: float = float(puff % 4)
		var row: float = float(puff / 4)
		var spread: float = (col - 1.5) * w * (0.1 + row * 0.02)
		var px: float = ground.x + spread
		var py: float = ground.y - w * (0.1 + row * 0.11 + rise * 0.045) 
		var rad: float = w * (0.07 + row * 0.02 + rise * 0.012)
		_smoke_ball(ci, Vector2(px, py), rad)
		puff += 1


static func _stone(ci: CanvasItem, at: Vector2, radius: float, tilt: float) -> void:
	var pts := PackedVector2Array()
	var k: int = 0
	while k < 7:
		var ang: float = TAU * float(k) / 7.0 + tilt
		var jag: float = 0.7 + 0.34 * _unit(k * 19 + int(tilt * 8.0))
		pts.append(at + Vector2(cos(ang), sin(ang)) * radius * jag)
		k += 1
	_fill_ink(ci, pts, Color("5c6770"))
	var facet := PackedVector2Array()
	facet.append(at + Vector2(-radius * 0.12, -radius * 0.46))
	facet.append(at + Vector2(radius * 0.5, -radius * 0.04))
	facet.append(at + Vector2(0.0, radius * 0.3))
	_poly(ci, facet, Color("c5ced6"))
	_coin(ci, at + Vector2(-radius * 0.16, -radius * 0.1), radius * 0.16, Color("f3e6c8"))


static func _star(ci: CanvasItem, at: Vector2, radius: float, fill: Color) -> void:
	if radius < 1.2:
		return
	var pts := PackedVector2Array()
	var k: int = 0
	while k < 8:
		var ang: float = TAU * float(k) / 8.0 - 0.7
		var rad: float = radius
		if k % 2 == 1:
			rad = radius * 0.36
		pts.append(at + Vector2(cos(ang), sin(ang)) * rad)
		k += 1
	_fill_ink(ci, pts, fill)


static func _paint_slash(ci: CanvasItem, frame: int, size: Vector2) -> void:
	if frame <= 1:
		_paint_raised_sword(ci, frame, size)
		return
	if frame <= 4:
		_paint_bolt(ci, frame, size)
		return
	_paint_ground_split(ci, frame, size)


static func _paint_raised_sword(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	var hilt := Vector2(w * 0.5, h * 0.58)
	var tip := Vector2(w * 0.5, h * 0.03)
	var axis: Vector2 = tip - hilt
	var leng: float = maxf(1.0, axis.length())
	var dir: Vector2 = axis / leng
	var side: Vector2 = Vector2(-dir.y, dir.x)
	var shadow: Vector2 = Vector2(16.0, 22.0)
	_poly(ci, PackedVector2Array([
		hilt + shadow + side * 22.0,
		hilt + shadow - side * 22.0,
		tip + shadow,
	]), Color(0.05, 0.03, 0.02, 0.72))
	var glow: int = 0
	while glow < 5:
		var along_g: float = 0.15 + float(glow) * 0.16
		ci.draw_circle(hilt + dir * (leng * along_g), 18.0 - float(glow), Color(1.0, 0.94, 0.7, 0.18))
		glow += 1
	_fill_ink(ci, PackedVector2Array([
		hilt + side * 9.0,
		hilt - side * 9.0,
		hilt - side * 9.0 - dir * 30.0,
		hilt + side * 9.0 - dir * 30.0,
	]), Color("3a2418"))
	_fill_ink(ci, PackedVector2Array([
		hilt + side * 36.0 + dir * 10.0,
		hilt - side * 36.0 + dir * 10.0,
		hilt - side * 28.0 - dir * 10.0,
		hilt + side * 28.0 - dir * 10.0,
	]), Color("e6c36a"))
	_poly(ci, PackedVector2Array([
		hilt + side * 36.0 + dir * 10.0 + Vector2(3.0, 5.0),
		hilt - side * 8.0 + dir * 4.0,
		hilt + side * 8.0 - dir * 6.0,
	]), Color(0.15, 0.1, 0.05, 0.45))
	var blade_base: Vector2 = hilt + dir * 14.0
	_fill_ink(ci, PackedVector2Array([
		blade_base + side * 22.0,
		blade_base - side * 22.0,
		tip,
	]), Color("f4e7b0"))
	_poly(ci, PackedVector2Array([
		blade_base + side * 4.0,
		blade_base - side * 16.0,
		tip - dir * 8.0,
	]), Color("8a7340"))
	_poly(ci, PackedVector2Array([
		blade_base + side * 16.0,
		blade_base + side * 2.0,
		tip - dir * 6.0,
	]), Color("fffef6"))
	_band(ci, blade_base + side * 18.0, tip - side * 1.5, 3.2, Color("ffffff"))
	var spark: int = 0
	var sparks: int = 12
	if frame >= 1:
		sparks = 20
	while spark < sparks:
		var along: float = 0.05 + 0.9 * _unit(spark * 17 + frame * 5)
		var off: float = (_unit(spark * 9 + frame * 3) - 0.5) * w * 0.85
		var at: Vector2 = blade_base + dir * (leng * along) + side * off
		_star(ci, at, 4.5 + _unit(spark * 4 + frame) * 8.0, Color("fff6c8"))
		if spark % 3 == 0:
			_star(ci, at + side * 10.0, 3.6, Color("7ecbff"))
		spark += 1


static func _paint_bolt(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	var reach: float = 0.5
	if frame == 3:
		reach = 0.76
	elif frame >= 4:
		reach = 0.97
	var x: float = w * 0.5
	var y0: float = h * 0.02
	var y1: float = h * reach
	_bolt_path(ci, x, y0, y1, w, frame, 0.0, 34.0, 18.0, 7.0)
	_bolt_path(ci, x, y0, y1 * 0.72, w * 0.62, frame + 3, -w * 0.18, 14.0, 7.0, 2.6)
	_bolt_path(ci, x, y0, y1 * 0.64, w * 0.55, frame + 5, w * 0.16, 12.0, 6.0, 2.4)
	if frame < 4:
		return
	_oval(ci, Vector2(x, y1 + 8.0), 46.0, 14.0, Color(0.04, 0.03, 0.02, 0.8))
	ci.draw_circle(Vector2(x, y1), 28.0, Color("1c140e"))
	ci.draw_circle(Vector2(x, y1), 20.0, Color("e6c36a"))
	ci.draw_circle(Vector2(x, y1 - 4.0), 9.0, Color("ffffff"))
	var bit: int = 0
	while bit < 10:
		var ang_b: float = TAU * float(bit) / 10.0
		var dist_b: float = 36.0 + float(bit % 3) * 10.0
		_star(ci, Vector2(x, y1) + Vector2(cos(ang_b), sin(ang_b)) * dist_b, 5.5 + float(bit % 2) * 3.0, Color("fff6c8"))
		bit += 1


static func _paint_ground_split(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var w: float = size.x
	var h: float = size.y
	var mid: float = h * 0.5
	var open: float = 48.0 + float(frame - 5) * 14.0
	var steps: int = 8
	var top_lip: PackedVector2Array = PackedVector2Array()
	var bot_lip: PackedVector2Array = PackedVector2Array()
	var i: int = 0
	while i <= steps:
		var t: float = float(i) / float(steps)
		var x: float = t * w
		var jag: float = (_unit(i * 13 + frame * 5) - 0.5) * 34.0
		var jag_b: float = (_unit(i * 29 + frame * 3) - 0.5) * 26.0
		top_lip.append(Vector2(x, mid - open + jag))
		bot_lip.append(Vector2(x, mid + open * 0.85 + jag_b))
		i += 1
	var upper: PackedVector2Array = PackedVector2Array()
	upper.append(Vector2(0.0, 0.0))
	upper.append(Vector2(w, 0.0))
	var rev: int = top_lip.size() - 1
	while rev >= 0:
		upper.append(top_lip[rev])
		rev -= 1
	_fill_ink(ci, upper, Color("6b5340"))
	var lower: PackedVector2Array = PackedVector2Array()
	var fwd: int = 0
	while fwd < bot_lip.size():
		lower.append(bot_lip[fwd])
		fwd += 1
	lower.append(Vector2(w, h))
	lower.append(Vector2(0.0, h))
	_fill_ink(ci, lower, Color("4a382c"))
	var void_pts: PackedVector2Array = PackedVector2Array()
	var up_i: int = 0
	while up_i < top_lip.size():
		void_pts.append(top_lip[up_i])
		up_i += 1
	var down_i: int = bot_lip.size() - 1
	while down_i >= 0:
		void_pts.append(bot_lip[down_i])
		down_i -= 1
	_poly(ci, void_pts, Color("120e0c"))
	var cave: PackedVector2Array = PackedVector2Array()
	var cave_i: int = 1
	while cave_i < top_lip.size() - 1:
		cave.append(top_lip[cave_i] + Vector2(0.0, 16.0))
		cave_i += 1
	var cave_j: int = bot_lip.size() - 2
	while cave_j >= 1:
		cave.append(bot_lip[cave_j] + Vector2(0.0, -14.0))
		cave_j -= 1
	_poly(ci, cave, Color("050403"))
	var lip: int = 0
	while lip < top_lip.size() - 1:
		_band(ci, top_lip[lip], top_lip[lip + 1], 7.0, Color("e6c36a"))
		_band(ci, top_lip[lip] + Vector2(0.0, -5.0), top_lip[lip + 1] + Vector2(0.0, -5.0), 3.0, Color("fff6c8"))
		_band(ci, bot_lip[lip], bot_lip[lip + 1], 7.0, Color("e07a28"))
		_band(ci, bot_lip[lip] + Vector2(0.0, 5.0), bot_lip[lip + 1] + Vector2(0.0, 5.0), 3.0, Color("fff6c8"))
		lip += 1
	var rock_i: int = 0
	while rock_i < 6:
		var rx: float = w * (0.08 + float(rock_i) * 0.16)
		var ry: float = top_lip[mini(rock_i + 1, top_lip.size() - 1)].y - 16.0
		if rock_i % 2 == 0:
			ry = bot_lip[mini(rock_i + 1, bot_lip.size() - 1)].y + 18.0
		_shaded_chunk(ci, Vector2(rx, ry), 11.0 + float(rock_i), float(rock_i) + float(frame))
		rock_i += 1


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
	ci.draw_line(Vector2(0, 3), Vector2(w, 3), Color("1c140e"), 6.0)
	ci.draw_line(Vector2(0, h - 3), Vector2(w, h - 3), Color("1c140e"), 6.0)
	ci.draw_line(Vector2(3, 0), Vector2(3, h), Color("1c140e"), 6.0)
	ci.draw_line(Vector2(w - 3, 0), Vector2(w - 3, h), Color("1c140e"), 6.0)
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


static func _oval(ci: CanvasItem, center: Vector2, wide: float, tall: float, color: Color) -> void:
	if wide < 2.0 or tall < 1.0:
		return
	var step: int = 0
	var steps: int = 16
	while step < steps:
		var t: float = float(step) / float(steps - 1)
		var x: float = lerpf(center.x - wide, center.x + wide, t)
		var hump: float = sin(t * PI)
		ci.draw_circle(Vector2(x, center.y), tall * (0.28 + 0.72 * hump), color)
		step += 1


static func _shock_ring(ci: CanvasItem, heart: Vector2, radius: float) -> void:
	ci.draw_arc(heart + Vector2(0.0, 10.0), radius, 0.0, TAU, 88, Color(0.05, 0.03, 0.02, 0.9), 26.0, true)
	ci.draw_arc(heart, radius, 0.0, TAU, 96, Color("fff6c8"), 16.0, true)
	ci.draw_arc(heart, radius * 0.86, 0.0, TAU, 80, Color("e07a28"), 8.0, true)
	ci.draw_arc(heart + Vector2(-radius * 0.04, -radius * 0.06), radius * 0.9, -2.7, -0.45, 32, Color("ffffff"), 6.0, true)


static func _fire_mass(ci: CanvasItem, heart: Vector2, radius: float, frame: int) -> void:
	ci.draw_circle(heart + Vector2(6.0, radius * 0.22), radius * 1.05, Color("1c140e"))
	ci.draw_circle(heart + Vector2(4.0, radius * 0.24), radius * 0.98, Color("140806"))
	ci.draw_circle(heart + Vector2(0.0, radius * 0.1), radius * 0.9, Color("6b2418"))
	ci.draw_circle(heart, radius * 0.78, Color("c44536"))
	ci.draw_circle(heart + Vector2(-radius * 0.06, -radius * 0.1), radius * 0.56, Color("e07a28"))
	ci.draw_circle(heart + Vector2(-radius * 0.08, -radius * 0.16), radius * 0.4, Color("e6c36a"))
	ci.draw_circle(heart + Vector2(-radius * 0.04, -radius * 0.08), radius * 0.24, Color("fff6c8"))
	ci.draw_circle(heart + Vector2(-radius * 0.02, -radius * 0.04), radius * 0.13, Color("ffffff"))
	var lobe: int = 0
	while lobe < 14:
		var ang: float = TAU * float(lobe) / 14.0 + float(frame) * 0.4
		var dir := Vector2(cos(ang), sin(ang))
		var dist: float = radius * (0.78 + 0.2 * _unit(lobe * 9 + frame * 4))
		var at: Vector2 = heart + dir * dist
		var rad: float = radius * (0.14 + 0.1 * _unit(lobe * 5 + frame))
		var shade := Color("e07a28")
		if dir.y > 0.35:
			shade = Color("4a140e")
		elif dir.y < -0.28:
			shade = Color("fff6c8")
		elif lobe % 2 == 0:
			shade = Color("c44536")
		ci.draw_circle(at, rad + 3.5, Color("1c140e"))
		ci.draw_circle(at, rad, shade)
		if dir.y < 0.15:
			ci.draw_circle(at + Vector2(-rad * 0.18, -rad * 0.28), rad * 0.36, Color("fffef2"))
		lobe += 1


static func _flying_bits(ci: CanvasItem, heart: Vector2, radius: float, frame: int) -> void:
	var bit: int = 0
	while bit < 11:
		var ang: float = -2.6 + _unit(bit * 19 + frame * 3) * 3.4
		var dir := Vector2(cos(ang), sin(ang))
		var dist: float = radius * (1.05 + 0.55 * _unit(bit * 7 + frame))
		var at: Vector2 = heart + dir * dist + Vector2(0.0, -radius * 0.08)
		_shaded_chunk(ci, at, 7.0 + _unit(bit * 4 + frame) * 8.0, ang + float(frame))
		bit += 1


static func _blast_sparks(ci: CanvasItem, heart: Vector2, radius: float, frame: int) -> void:
	var spark: int = 0
	while spark < 18:
		var ang: float = float(spark) * 0.9 + float(frame)
		var dist: float = radius * (0.7 + 0.45 * _unit(spark * 11 + frame))
		var at: Vector2 = heart + Vector2(cos(ang), sin(ang)) * dist
		_star(ci, at, 4.0 + _unit(spark * 3 + frame) * 6.0, Color("fff6c8"))
		if spark % 4 == 0:
			_star(ci, at + Vector2(8.0, 6.0), 3.2, Color("7ecbff"))
		spark += 1


static func _smoke_ball(ci: CanvasItem, at: Vector2, rad: float) -> void:
	if rad < 2.0:
		return
	ci.draw_circle(at + Vector2(3.0, rad * 0.2), rad + 4.0, Color("1c140e"))
	ci.draw_circle(at + Vector2(0.0, rad * 0.22), rad, Color("2a2622"))
	ci.draw_circle(at, rad * 0.9, Color("6a645c"))
	ci.draw_circle(at + Vector2(-rad * 0.16, -rad * 0.24), rad * 0.52, Color("d4cdc2"))
	ci.draw_circle(at + Vector2(-rad * 0.22, -rad * 0.34), rad * 0.22, Color("f7f3ea"))


static func _shaded_chunk(ci: CanvasItem, at: Vector2, radius: float, tilt: float) -> void:
	if radius < 1.5:
		return
	var pts := PackedVector2Array()
	var k: int = 0
	while k < 6:
		var ang: float = tilt + TAU * float(k) / 6.0
		var jag: float = 0.7 + 0.4 * _unit(k * 17 + int(tilt * 8.0))
		pts.append(at + Vector2(cos(ang), sin(ang)) * radius * jag)
		k += 1
	_fill_ink(ci, pts, Color("6b5340"))
	_poly(ci, PackedVector2Array([
		at + Vector2(-radius * 0.2, -radius * 0.42),
		at + Vector2(radius * 0.28, -radius * 0.08),
		at + Vector2(-radius * 0.02, radius * 0.08),
	]), Color("e6d3b0"))
	_poly(ci, PackedVector2Array([
		at + Vector2(radius * 0.05, radius * 0.12),
		at + Vector2(radius * 0.42, radius * 0.02),
		at + Vector2(radius * 0.12, radius * 0.46),
	]), Color("2a2118"))


static func _bolt_path(ci: CanvasItem, x: float, y0: float, y1: float, w: float, frame: int, lean: float, dark: float, mid: float, core: float) -> void:
	var steps: int = 9
	var prev := Vector2(x + lean * 0.2, y0)
	var i: int = 1
	while i <= steps:
		var t: float = float(i) / float(steps)
		var jag: float = 0.0
		if i < steps:
			jag = (_unit(i * 19 + frame * 7) - 0.5) * w * 0.42
		var at := Vector2(x + lean * (1.0 - t) + jag, lerpf(y0, y1, t))
		_band(ci, prev + Vector2(6.0, 8.0), at + Vector2(6.0, 8.0), dark * 0.7, Color(0.05, 0.04, 0.03, 0.55))
		_band(ci, prev, at, dark, Color("1c140e"))
		_band(ci, prev, at, mid, Color("e6c36a"))
		_band(ci, prev, at, core, Color("ffffff"))
		if i % 2 == 0:
			var kick: float = 28.0
			if i % 4 == 0:
				kick = -32.0
			var branch := at + Vector2(kick, 8.0)
			_band(ci, at, branch, dark * 0.45, Color("1c140e"))
			_band(ci, at, branch, core, Color("fff6c8"))
			_star(ci, branch, 6.0, Color("fff6c8"))
		prev = at
		i += 1


static func _paint_ground_ice(ci: CanvasItem, x0: float, x1: float, y: float, strength: float) -> void:
	var span: float = x1 - x0
	if span < 6.0:
		return
	var steps: int = clampi(int(span / 36.0), 3, 28)
	var top: PackedVector2Array = PackedVector2Array()
	var i: int = 0
	while i <= steps:
		var t: float = float(i) / float(steps)
		var x: float = lerpf(x0, x1, t)
		var jag: float = (_unit(i * 11) - 0.35) * 14.0 * strength
		top.append(Vector2(x, y - 10.0 - 16.0 * strength + jag))
		i += 1
	var plate: PackedVector2Array = PackedVector2Array()
	var a: int = 0
	while a < top.size():
		plate.append(top[a])
		a += 1
	plate.append(Vector2(x1, y + 8.0))
	plate.append(Vector2(x0, y + 8.0))
	_fill_ink(ci, plate, Color("7eb6e0"))
	var shade: PackedVector2Array = PackedVector2Array()
	var b: int = 0
	while b < top.size():
		shade.append(top[b] + Vector2(0.0, 8.0))
		b += 1
	shade.append(Vector2(x1, y + 8.0))
	shade.append(Vector2(x0, y + 8.0))
	_poly(ci, shade, Color("3d6f99"))
	var crack: int = 0
	while crack < steps:
		_band(ci, top[crack], top[crack + 1], 2.4, Color("e7f6ff"))
		if crack % 2 == 0:
			var foot: Vector2 = top[crack]
			_band(ci, foot, foot + Vector2(6.0, 14.0), 2.0, Color("e7f6ff"))
		crack += 1


static func _draw_ice_wind(ci: CanvasItem, cast: Dictionary, shown: float) -> void:
	var from_x: float = float(cast.get("from_x", 0.0))
	var y: float = float(cast.get("y", 0.0))
	var blow: float = float(cast.get("dir", 1.0))
	var reach: float = 70.0 + 380.0 * shown
	var blade: int = 0
	while blade < 7:
		var lift: float = (float(blade) - 3.0) * 18.0
		var origin := Vector2(from_x, y - 52.0 + lift * 0.35)
		var dir := Vector2(blow, lift * 0.0035)
		if dir.length() < 0.01:
			dir = Vector2(1.0, 0.0)
		else:
			dir = dir.normalized()
		var length: float = reach * (0.48 + 0.08 * float(blade))
		var thick: float = 5.5 + float(blade % 3) * 2.2
		_shard(ci, origin, dir, length, thick, Color("7eb6e0"), Color("e7f6ff"))
		blade += 1


static func _draw_snow(ci: CanvasItem, cast: Dictionary) -> void:
	var view := Vector2(1280.0, 720.0)
	var raw_vp: Variant = cast.get("vp")
	if raw_vp is Vector2:
		view = raw_vp
	var age: float = float(cast.get("age", 0.0))
	var flake: int = 0
	while flake < 40:
		var sway: float = sin(age * 1.5 + float(flake)) * (10.0 + _unit(flake * 7) * 28.0)
		var sx: float = fposmod(_unit(flake * 19 + 4) * view.x + sway, view.x)
		var fall: float = age * (20.0 + _unit(flake * 3) * 46.0)
		var sy: float = fposmod(_unit(flake * 23 + 8) * view.y + fall, view.y)
		var rad: float = 2.8 + _unit(flake * 11) * 3.6
		_snowflake(ci, Vector2(sx, sy), rad, age * 1.7 + float(flake))
		flake += 1


static func _snowflake(ci: CanvasItem, at: Vector2, radius: float, spin: float) -> void:
	var arm: int = 0
	while arm < 6:
		var ang: float = spin + TAU * float(arm) / 6.0
		var tip: Vector2 = at + Vector2(cos(ang), sin(ang)) * radius
		_band(ci, at, tip, 2.4, Color("1c140e"))
		_band(ci, at, tip, 1.1, Color("e7f6ff"))
		arm += 1


static func _draw_locked_bodies(ci: CanvasItem, cast: Dictionary) -> void:
	var bodies: Array = []
	var raw_bodies: Variant = cast.get("bodies")
	if raw_bodies is Array:
		bodies = raw_bodies
	for body in bodies:
		if body == null or not is_instance_valid(body):
			continue
		if not ("alive" in body) or not bool(body.alive):
			continue
		if not ("position" in body):
			continue
		var at: Vector2 = body.position
		_ice_block(ci, at)


static func _ice_block(ci: CanvasItem, feet: Vector2) -> void:
	var left: float = feet.x - 30.0
	var right: float = feet.x + 30.0
	var bottom: float = feet.y + 8.0
	var shoulder: float = feet.y - 86.0
	var peak := Vector2(feet.x, feet.y - 108.0)
	var shell := PackedVector2Array([
		Vector2(left, bottom),
		Vector2(left + 4.0, shoulder + 16.0),
		peak,
		Vector2(right - 4.0, shoulder + 16.0),
		Vector2(right, bottom),
	])
	_fill_ink(ci, shell, Color(0.49, 0.71, 0.88, 0.9))
	_poly(ci, PackedVector2Array([
		Vector2(left + 10.0, bottom - 10.0),
		Vector2(left + 12.0, shoulder + 22.0),
		Vector2(feet.x - 2.0, shoulder + 6.0),
		Vector2(feet.x + 4.0, bottom - 12.0),
	]), Color(0.91, 0.97, 1.0, 0.85))
	_band(ci, Vector2(feet.x - 6.0, shoulder + 8.0), Vector2(feet.x + 10.0, bottom - 16.0), 2.4, Color("1c140e"))
	_band(ci, Vector2(feet.x + 8.0, shoulder + 20.0), Vector2(left + 8.0, feet.y - 20.0), 2.0, Color("1c140e"))
	_band(ci, peak + Vector2(-8.0, 18.0), peak + Vector2(10.0, 28.0), 1.6, Color("ffffff"))


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
		var frost_raw: Variant = field.get("frost_casts")
		var frost_list: Array = []
		if frost_raw is Array:
			frost_list = frost_raw
		baker.call("draw_frost", self, frost_list)

class BodyLayer extends Node2D:
	var field: Node = null

	func _draw() -> void:
		if field == null:
			return
		var baker = load("res://scripts/skill_fx.gd")
		if bool(field.get("ex_aiming")):
			var aim_raw: Variant = field.get("ex_aim")
			var aim_at := Vector2.ZERO
			if aim_raw is Vector2:
				aim_at = aim_raw
			var reach := 0.0
			if field.has_method("_blast_radius"):
				reach = float(field.call("_blast_radius"))
			baker.call("draw_aim", self, aim_at, reach)
		var burst_raw: Variant = field.get("bursts")
		var slash_raw: Variant = field.get("slash_fx")
		var burst_list: Array = []
		var slash_list: Array = []
		if burst_raw is Array:
			burst_list = burst_raw
		if slash_raw is Array:
			slash_list = slash_raw
		baker.call("draw_world", self, burst_list, slash_list)
