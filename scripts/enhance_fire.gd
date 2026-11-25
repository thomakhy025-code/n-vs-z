extends Node2D

# Enhancement burn. The flame tongue and the spark are painted once into
# one shared sheet (sword row, body row, spark cell). During the burn the
# sheet is blitted on the sword and on the head, torso, arms, and legs.
# Frames advance, and the quads rise, scale, and flip. Nothing here
# allocates a texture per cast or per frame, and this skill does not run
# a particle simulation.

const FRAMES: int = 6
const CELL_W: int = 32
const CELL_H: int = 48
const PAD: int = 2
const STEP: int = CELL_W + PAD
const SPARK: int = 16

static var banked: bool = false
static var flame_tex: Texture2D
static var add_mat: CanvasItemMaterial

var _lit: bool = false
var _rig: Dictionary = {}
var _facing: float = 1.0
var _fit: float = 1.0
var _bob: float = 0.0


static func ensure() -> void:
	_bank()


static func frame_rect(row: int, frame: int) -> Rect2:
	var slot: int = clampi(frame, 0, FRAMES - 1)
	var line: int = 0
	if row > 0:
		line = 1
	return Rect2(float(slot * STEP), float(line * (CELL_H + PAD)), float(CELL_W), float(CELL_H))


static func spark_rect() -> Rect2:
	return Rect2(0.0, float(2 * (CELL_H + PAD)), float(SPARK), float(SPARK))


func _ready() -> void:
	_bank()
	material = add_mat
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visible = false


func sync(on: bool, rig: Dictionary, facing: float, scale: float, bob: float) -> void:
	var ended: bool = (not on) and _lit
	_lit = on
	if not on:
		if ended:
			visible = false
			_rig = {}
		return
	visible = true
	_rig = rig
	_facing = facing
	_fit = scale
	_bob = bob
	queue_redraw()


func _draw() -> void:
	if not _lit or flame_tex == null or _rig.is_empty():
		return
	var hand: Vector2 = _rig["hand"]
	var tip: Vector2 = _rig["tip"]
	var spots: PackedVector2Array = _rig["body"]
	var now: float = float(Time.get_ticks_msec()) * 0.001
	_draw_body(spots, now)
	var a: Vector2 = _map(hand)
	var b: Vector2 = _map(tip)
	var delta: Vector2 = b - a
	var leng: float = delta.length()
	if leng < 8.0:
		if leng < 0.01:
			delta = Vector2(_facing, -0.2)
			leng = delta.length()
		if leng < 0.01:
			delta = Vector2(1.0, -0.2)
			leng = delta.length()
		delta = delta / leng * 8.0
		b = a + delta
		leng = 8.0
	var across: Vector2 = Vector2(-delta.y, delta.x)
	if leng > 0.01:
		across = across / leng
	else:
		across = Vector2.UP
	var count: int = clampi(int(leng / 12.0), 6, 10)
	var i: int = 0
	while i < count:
		var along: float = (float(i) + 0.5) / float(count)
		var at: Vector2 = a.lerp(b, along)
		_blit(0, now / 0.55 + float(i) * 0.31, at, 52.0, 2.6, i % 2 == 1)
		i += 1
	var sparks: int = 5
	var s: int = 0
	while s < sparks:
		var spark_along: float = (float(s) + 0.5) / float(sparks)
		var spark_at: Vector2 = a.lerp(b, spark_along)
		spark_at += across * sin(float(s) * 2.1) * 5.0
		_blit_spark(now / 0.42 + float(s) * 0.37, spark_at)
		s += 1


func _draw_body(spots: PackedVector2Array, now: float) -> void:
	var n: int = mini(spots.size(), 6)
	var s: int = 0
	while s < n:
		var layers: int = 2
		if s <= 1:
			layers = 3
		var spot: Vector2 = _map(spots[s])
		var tall: float = _body_tall(s)
		var layer: int = 0
		while layer < layers:
			var jog: float = (float(layer) - 1.0) * 4.5
			var nest: Vector2 = spot + Vector2(jog, float(layer) * -2.0)
			var phase: float = now / 0.58 + float(s) * 0.27 + float(layer) * 0.41
			_blit(1, phase, nest, tall, 2.2, layer % 2 == 1)
			layer += 1
		s += 1


func _blit(row: int, phase: float, base: Vector2, tall: float, sway: float, flip: bool) -> void:
	var wrapped: float = fposmod(phase, 1.0)
	var frame: int = mini(int(wrapped * float(FRAMES)), FRAMES - 1)
	var grow: float = _grow_sword(wrapped)
	if row > 0:
		grow = _grow_body(wrapped)
	var dh: float = tall * grow
	if dh < 2.0:
		return
	var dw: float = dh * float(CELL_W) / float(CELL_H)
	var lift: float = lerpf(tall * 0.06, tall * 0.55, wrapped)
	var x: float = base.x + sin(wrapped * TAU) * sway
	var y: float = base.y - lift
	var rect: Rect2 = Rect2(x - dw * 0.5, y - dh, dw, dh)
	var src: Rect2 = frame_rect(row, frame)
	if flip:
		draw_set_transform(Vector2(rect.position.x + rect.size.x, rect.position.y), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(flame_tex, Rect2(Vector2.ZERO, rect.size), src, Color.WHITE, false, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_texture_rect_region(flame_tex, rect, src, Color.WHITE, false, true)


func _blit_spark(phase: float, base: Vector2) -> void:
	var wrapped: float = fposmod(phase, 1.0)
	var alpha: float = sin(wrapped * PI)
	if alpha < 0.05:
		return
	var side: float = lerpf(7.0, 14.0, alpha)
	var lift: float = lerpf(4.0, 36.0, wrapped)
	var x: float = base.x + sin(wrapped * TAU * 1.3) * 3.5
	var y: float = base.y - lift
	var rect: Rect2 = Rect2(x - side * 0.5, y - side * 0.5, side, side)
	draw_texture_rect_region(flame_tex, rect, spark_rect(), Color(1, 1, 1, alpha), false, true)


func _map(p: Vector2) -> Vector2:
	return Vector2(p.x * _facing * _fit, p.y * _fit + _bob)


static func _bank() -> void:
	if banked:
		return
	banked = true
	flame_tex = ImageTexture.create_from_image(_paint_sheet())
	add_mat = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


static func _paint_sheet() -> Image:
	var sheet_w: int = FRAMES * STEP
	var sheet_h: int = 2 * (CELL_H + PAD) + SPARK
	var data: PackedByteArray = PackedByteArray()
	data.resize(sheet_w * sheet_h * 4)
	var sword_stops: PackedFloat32Array = PackedFloat32Array([0.0, 0.14, 0.46, 1.0])
	var sword_cols: PackedColorArray = PackedColorArray([
		Color(1.0, 0.96, 0.75, 0.0),
		Color(1.0, 0.8, 0.34, 0.92),
		Color(1.0, 0.36, 0.06, 0.7),
		Color(0.32, 0.04, 0.01, 0.0),
	])
	var body_stops: PackedFloat32Array = PackedFloat32Array([0.0, 0.16, 0.5, 1.0])
	var body_cols: PackedColorArray = PackedColorArray([
		Color(1.0, 0.92, 0.6, 0.0),
		Color(1.0, 0.66, 0.18, 0.8),
		Color(0.95, 0.3, 0.05, 0.52),
		Color(0.28, 0.04, 0.01, 0.0),
	])
	_paint_flames(data, sheet_w, 0, 2.35, 0.82, sword_stops, sword_cols)
	_paint_flames(data, sheet_w, 1, 1.85, 0.7, body_stops, body_cols)
	_paint_spark(data, sheet_w, 2 * (CELL_H + PAD))
	return Image.create_from_data(sheet_w, sheet_h, false, Image.FORMAT_RGBA8, data)


static func _paint_flames(data: PackedByteArray, sheet_w: int, row: int, heat: float, cap: float, stops: PackedFloat32Array, cols: PackedColorArray) -> void:
	var frame: int = 0
	var y0: int = row * (CELL_H + PAD)
	while frame < FRAMES:
		var life: float = (float(frame) + 0.5) / float(FRAMES)
		var tint: Color = _ramp(life, stops, cols)
		var tick: float = float(frame) * 0.16
		var x0: int = frame * STEP
		var y: int = 0
		while y < CELL_H:
			var v: float = 1.0 - float(y) / float(CELL_H - 1)
			var x: int = 0
			while x < CELL_W:
				var col: Color = _flame_pixel(float(x), v, tick, heat, cap, tint)
				if col.a > 0.004:
					_put(data, sheet_w, x0 + x, y0 + y, col)
				x += 1
			y += 1
		frame += 1


static func _paint_spark(data: PackedByteArray, sheet_w: int, y0: int) -> void:
	var y: int = 0
	while y < SPARK:
		var x: int = 0
		while x < SPARK:
			var col: Color = _spark_pixel(float(x), float(y))
			if col.a > 0.004:
				_put(data, sheet_w, x, y0 + y, col)
			x += 1
		y += 1


static func _flame_pixel(px: float, v: float, tick: float, heat: float, cap: float, tint: Color) -> Color:
	if tint.a < 0.01 or v < 0.015 or v > 0.985:
		return Color(0, 0, 0, 0)
	var uvx: float = px / float(CELL_W - 1)
	var rough: float = lerpf(1.2, 0.22, pow(v, 0.62))
	rough *= lerpf(0.7, 1.05, sin(v * PI))
	var u_raw: float = (uvx - 0.5) * 2.0
	if absf(u_raw) > rough + 0.55:
		return Color(0, 0, 0, 0)
	var n: float = _noise(uvx * 3.2, v * 2.4 - tick * 1.35)
	var n2: float = _noise(uvx * 6.4 + 1.7, v * 3.6 - tick * 2.1)
	var sway: float = (n - 0.5) * 0.55 * (1.0 - v)
	var u: float = u_raw - sway
	var edge: float = absf(u) / maxf(rough, 0.05)
	edge += (n2 - 0.55) * 0.28
	var mask: float = pow(clampf(1.0 - edge, 0.0, 1.0), 1.05)
	mask *= _smooth(0.0, 0.07, v)
	mask *= 1.0 - _smooth(0.92, 1.0, v)
	var core: float = pow(clampf(1.0 - edge * 1.35, 0.0, 1.0), 1.25)
	core *= pow(clampf(v, 0.0, 1.0), 0.28)
	mask *= tint.a * lerpf(0.72, 1.0, n2)
	if mask < 0.03:
		return Color(0, 0, 0, 0)
	var gain: float = 0.85 + heat * core
	var hot: float = core * core * heat
	var hdr_r: float = tint.r * gain + 0.75 * hot
	var hdr_g: float = tint.g * gain + 0.48 * hot
	var hdr_b: float = tint.b * gain + 0.14 * hot
	return Color(hdr_r / (1.0 + hdr_r), hdr_g / (1.0 + hdr_g), hdr_b / (1.0 + hdr_b), clampf(mask, 0.0, cap))


static func _spark_pixel(px: float, py: float) -> Color:
	var u: float = (px / float(SPARK - 1) - 0.5) * 2.0
	var v: float = (py / float(SPARK - 1) - 0.5) * 2.0
	var dist: float = sqrt(u * u + v * v)
	var core: float = exp(-dist * dist * 5.5)
	var mask: float = pow(clampf(1.0 - dist, 0.0, 1.0), 1.7)
	if mask < 0.03:
		return Color(0, 0, 0, 0)
	var gain: float = 0.4 + core * 1.35
	var hdr_r: float = 2.5 * gain
	var hdr_g: float = 1.2 * gain
	var hdr_b: float = 0.32 * gain
	return Color(hdr_r / (1.0 + hdr_r), hdr_g / (1.0 + hdr_g), hdr_b / (1.0 + hdr_b), clampf(mask, 0.0, 0.9))


static func _put(data: PackedByteArray, sheet_w: int, x: int, y: int, col: Color) -> void:
	var i: int = (y * sheet_w + x) * 4
	data[i] = int(round(clampf(col.r, 0.0, 1.0) * 255.0))
	data[i + 1] = int(round(clampf(col.g, 0.0, 1.0) * 255.0))
	data[i + 2] = int(round(clampf(col.b, 0.0, 1.0) * 255.0))
	data[i + 3] = int(round(clampf(col.a, 0.0, 1.0) * 255.0))


static func _ramp(t: float, stops: PackedFloat32Array, cols: PackedColorArray) -> Color:
	var last: int = cols.size() - 1
	if last < 0:
		return Color.WHITE
	if t <= stops[0]:
		return cols[0]
	if t >= stops[last]:
		return cols[last]
	var i: int = 0
	while i < last:
		var edge: float = stops[i + 1]
		if t <= edge:
			var span: float = edge - stops[i]
			var u: float = 0.0
			if span > 0.0001:
				u = (t - stops[i]) / span
			return cols[i].lerp(cols[i + 1], u)
		i += 1
	return cols[last]


static func _body_tall(index: int) -> float:
	if index == 0:
		return 40.0
	if index == 1:
		return 50.0
	if index >= 4:
		return 34.0
	return 32.0


static func _grow_sword(t: float) -> float:
	if t < 0.28:
		return lerpf(0.35, 1.0, t / 0.28)
	if t < 0.72:
		return lerpf(1.0, 0.62, (t - 0.28) / 0.44)
	return lerpf(0.62, 0.12, (t - 0.72) / 0.28)


static func _grow_body(t: float) -> float:
	if t < 0.3:
		return lerpf(0.4, 1.0, t / 0.3)
	return lerpf(1.0, 0.16, (t - 0.3) / 0.7)


static func _smooth(e0: float, e1: float, x: float) -> float:
	var t: float = clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _noise(px: float, py: float) -> float:
	var cx: float = floor(px)
	var cy: float = floor(py)
	var fx: float = px - cx
	var fy: float = py - cy
	var ux: float = fx * fx * (3.0 - 2.0 * fx)
	var uy: float = fy * fy * (3.0 - 2.0 * fy)
	var a: float = _hash21(cx, cy)
	var b: float = _hash21(cx + 1.0, cy)
	var c: float = _hash21(cx, cy + 1.0)
	var d: float = _hash21(cx + 1.0, cy + 1.0)
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy)


static func _hash21(px: float, py: float) -> float:
	var s: float = sin(px * 127.1 + py * 311.7) * 43758.5453
	return s - floor(s)
