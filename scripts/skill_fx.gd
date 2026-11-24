extends RefCounted

# Baked sheet for Enhancement. Explosion, Light smashing, and Freezing
# are not painted: the bomb is explosion_vfx.gd, the slash is slash_vfx.gd,
# the ice pillars are ice_vfx.gd. FROST_WIND still times the lock sound.
const FRAMES := 12
const PAD := 4
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
	var kinds := PackedStringArray(["en"])
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


static func draw_glow(ci: CanvasItem, bursts: Array, _slashes: Array, hazards: Array) -> void:
	for burst_raw in bursts:
		var burst: Dictionary = burst_raw
		_draw_burst(ci, burst, true)
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


static func draw_world(ci: CanvasItem, bursts: Array, _slashes: Array) -> void:
	for world_burst in bursts:
		var burst_row: Dictionary = world_burst
		_draw_burst(ci, burst_row, false)


static func draw_marks(_ci: CanvasItem, _bodies: Array) -> void:
	pass


static func draw_frost(_ci: CanvasItem, _casts: Array) -> void:
	pass


static func paint_sheet(ci: CanvasItem, kind: String) -> void:
	if kind == "ex" or kind == "fz":
		return
	var box: Vector2 = _cell(kind)
	var step: int = int(box.x) + PAD
	var slot: int = 0
	while slot < FRAMES:
		ci.draw_set_transform(Vector2(float(slot * step), 0.0), 0.0, Vector2.ONE)
		_paint_aura(ci, slot, box)
		slot += 1
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _request(host: Node, kind: String) -> void:
	if kind == "ex" or sheets.has(kind):
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

static func _draw_burst(_ci: CanvasItem, _patch: Dictionary, _bloom: bool) -> void:
	return

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

static func _paint_aura(ci: CanvasItem, frame: int, size: Vector2) -> void:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
	var spin: float = TAU * float(frame) / float(FRAMES)
	var shade_r: float = size.x * 0.2
	ci.draw_circle(center + Vector2(6.0, 10.0), shade_r * 1.15, Color(0.05, 0.02, 0.015, 0.82))
	ci.draw_circle(center, shade_r, Color(0.12, 0.04, 0.02, 0.9))
	ci.draw_circle(center + Vector2(-4.0, -6.0), shade_r * 0.55, Color(0.28, 0.08, 0.04, 0.75))
	var tongue: int = 0
	while tongue < 18:
		var ang: float = TAU * float(tongue) / 18.0 + spin
		var dir: Vector2 = Vector2(cos(ang), sin(ang) * 0.92)
		if dir.length() < 0.01:
			dir = Vector2(0.0, -1.0)
		else:
			dir = dir.normalized()
		var wobble: float = 0.62 + 0.48 * _unit(tongue * 11 + frame * 3)
		var base: Vector2 = center + dir * (size.x * 0.16)
		var length: float = size.y * (0.16 + 0.16 * wobble)
		var half: float = 14.0 + wobble * 10.0
		_flame_out(ci, base + Vector2(4.0, 6.0), dir, length, half, Color(0.08, 0.03, 0.02, 0.9), Color("3a100c"))
		var hot := Color("c44536")
		var core := Color("e6c36a")
		if dir.y < -0.35:
			hot = Color("e07a28")
			core = Color("fff6c8")
		elif dir.y > 0.45:
			hot = Color("6b2418")
			core = Color("c44536")
		_flame_out(ci, base, dir, length, half, hot, core)
		_star(ci, base + dir * length, 4.5 + wobble * 4.0, Color("ffffff"))
		tongue += 1
	var mid_i: int = 0
	while mid_i < 12:
		var ang_m: float = spin * -1.3 + TAU * float(mid_i) / 12.0
		var dir_m: Vector2 = Vector2(cos(ang_m), sin(ang_m))
		var inner_at: Vector2 = center + dir_m * (size.x * 0.1)
		var mid_len: float = size.y * (0.1 + 0.06 * _unit(mid_i * 7 + frame))
		_flame_out(ci, inner_at, dir_m, mid_len, 8.0, Color("e07a28"), Color("fff6c8"))
		mid_i += 1
	var ember: int = 0
	while ember < 14:
		var ang_e: float = spin * 1.7 + float(ember) * 0.85
		var dist: float = size.x * (0.28 + 0.16 * _unit(ember * 5 + frame))
		var at: Vector2 = center + Vector2(cos(ang_e) * dist, sin(ang_e) * dist * 0.86)
		_coin(ci, at, 3.6 + _unit(ember * 3 + frame) * 4.2, Color("fff6c8"))
		if ember % 2 == 0:
			_star(ci, at, 5.0, Color("ffffff"))
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

static func _belly(ci: CanvasItem, heart: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(heart)
	var step: int = 0
	var steps: int = 16
	while step <= steps:
		var ang: float = lerpf(0.12, PI - 0.12, float(step) / float(steps))
		pts.append(heart + Vector2(cos(ang), sin(ang)) * radius)
		step += 1
	_poly(ci, pts, color)


static func _core_burst(ci: CanvasItem, at: Vector2, radius: float, frame: int) -> void:
	var pts := PackedVector2Array()
	var k: int = 0
	while k < 16:
		var ang: float = TAU * float(k) / 16.0 + float(frame) * 0.2
		var rad: float = radius
		if k % 2 == 1:
			rad = radius * (0.35 + 0.2 * _unit(k + frame))
		pts.append(at + Vector2(cos(ang), sin(ang)) * rad)
		k += 1
	_fill_ink(ci, pts, Color("fffef6"))
	_star(ci, at, radius * 0.45, Color("ffffff"))


static func draw_casts(ci: CanvasItem, winds: Array) -> void:
	for raw in winds:
		var wind: Dictionary = raw
		var who_v: Variant = wind.get("who", null)
		if who_v == null or not (who_v is Node2D):
			continue
		var caster: Node2D = who_v
		if not is_instance_valid(caster) or not caster.visible:
			continue
		var id := str(wind.get("id", ""))
		var span := maxf(0.001, float(wind.get("span", 1.0)))
		var age := float(wind.get("age", 0.0))
		var along := clampf(age / span, 0.0, 1.0)
		var pulse := 0.62 + 0.38 * sin(age * TAU * 4.0)
		var feet: Vector2 = caster.position
		if id == "en":
			_draw_cast_flames(ci, feet, along, pulse)
		else:
			_draw_cast_gather(ci, feet + Vector2(0.0, -46.0), id, along, pulse)


static func _draw_cast_gather(ci: CanvasItem, at: Vector2, id: String, along: float, pulse: float) -> void:
	var wash := Color(1.0, 0.42, 0.08, 0.16)
	var ring := Color(1.0, 0.48, 0.08, 0.88)
	var mote := Color(1.0, 0.74, 0.22, 0.95)
	var count := 8
	var wide := 3.4
	if id == "ls":
		wash = Color(1.0, 0.94, 0.72, 0.14)
		ring = Color(1.0, 0.9, 0.48, 0.92)
		mote = Color(1.0, 0.98, 0.9, 0.96)
		count = 6
		wide = 2.2
	elif id == "fz":
		wash = Color(0.62, 0.84, 1.0, 0.16)
		ring = Color(0.7, 0.88, 1.0, 0.9)
		mote = Color(0.92, 0.98, 1.0, 0.96)
		wide = 2.6
	var radius := lerpf(62.0, 12.0, along) * (0.9 + 0.1 * pulse)
	var disc := wash
	disc.a = wash.a * (0.75 + 0.45 * pulse)
	if disc.a > 0.28:
		disc.a = 0.28
	ci.draw_circle(at, radius * 0.55, disc)
	var band := ring
	band.a = 0.4 + 0.45 * pulse
	ci.draw_arc(at, radius, 0.0, TAU, 28, band, wide, true)
	if id == "ls":
		ci.draw_arc(at, radius * 0.72, 0.5, TAU - 0.4, 22, mote, 1.5, true)
	elif id == "fz":
		ci.draw_arc(at, radius * 0.64, 0.8, TAU - 0.6, 20, mote, 1.3, true)
	var n := 0
	while n < count:
		var ang := TAU * float(n) / float(count) - along * 3.4
		var dist := lerpf(radius, 8.0, along * 0.9)
		var spot := at + Vector2(cos(ang) * dist, sin(ang) * dist * 0.72)
		var rad := wide * (0.7 + 0.45 * pulse)
		ci.draw_circle(spot, rad, mote)
		n += 1
	var core := mote
	core.a = 0.18 + 0.55 * along * pulse
	ci.draw_circle(at, lerpf(11.0, 4.0, along), core)


static func _draw_cast_flames(ci: CanvasItem, feet: Vector2, along: float, pulse: float) -> void:
	var glow := Color(1.0, 0.42, 0.08, 0.1 + 0.1 * pulse)
	ci.draw_circle(feet + Vector2(0.0, -36.0), 26.0 + along * 10.0, glow)
	var n := 0
	while n < 5:
		var spread := float(n) - 2.0
		var sway := sin(along * TAU + float(n) * 1.3) * 3.0
		var x := feet.x + spread * 13.0 + sway
		var climb := (8.0 + along * 64.0) * (0.72 + 0.28 * pulse)
		var base := Vector2(x, feet.y - 6.0 - along * 10.0)
		var hot := Color(1.0, 0.36, 0.06, 0.78)
		var tip := Color(1.0, 0.86, 0.38, 0.92)
		ci.draw_circle(base, 6.5, Color(hot.r, hot.g, hot.b, 0.45))
		ci.draw_circle(base + Vector2(0.0, -climb * 0.45), 4.6, hot)
		ci.draw_circle(base + Vector2(0.0, -climb), 2.8, tip)
		n += 1


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
		var wind_raw: Variant = field.get("skill_winds")
		var wind_list: Array = []
		if wind_raw is Array:
			wind_list = wind_raw
		baker.call("draw_casts", self, wind_list)

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
