extends Node2D

var side: int = 0
var hp: float = 2000.0
var max_hp: float = 2000.0
var front_x: float = 0.0
var battle = null
var flicker: float = 0.0
var gusted: bool = false
var clan_gate: bool = false
var hit_shake: float = 0.0
var crack_flash: float = 0.0
var crack_marks: int = 0
var breaking: bool = false
var break_age: float = 0.0
var shattered: bool = false
var piece_count: int = 0
var spread_marks: int = 0


func setup(field, which_side: int, where: Vector2, front: float) -> void:
	battle = field
	side = which_side
	position = where
	front_x = front
	hp = max_hp
	z_index = 2


func take_damage(amount: float, _quiet: bool = false) -> void:
	if hp <= 0.0 or battle.finished:
		return
	hp = maxf(0.0, hp - amount)
	battle.register_damage()
	var text_y := position.y - 120.0
	if battle.lane_ys.size() > 0:
		text_y = float(battle.lane_ys[0]) - 36.0
	battle.float_text(Vector2(front_x, text_y), str(int(round(amount))), Color("ff8d7a"))
	battle.note_gate_hit(side)
	if not gusted and hp <= max_hp * 0.5 and hp > 0.0:
		gusted = true
		battle.gate_gust(side)
	if side == 1:
		battle.note_enemy_purse()
	_note_hit()
	Sfx.play("castle", randf_range(0.92, 1.05), -6.0)
	queue_redraw()
	if hp <= 0.0:
		battle.on_gate_fallen(side)


func begin_break() -> void:
	if breaking:
		return
	breaking = true
	break_age = 0.0
	hit_shake = 1.0
	queue_redraw()


func _note_hit() -> void:
	hit_shake = 1.0
	crack_flash = 1.0
	var hurt := clampf(1.0 - hp / maxf(1.0, max_hp), 0.0, 1.0)
	var marks := int(ceil(hurt * 6.0))
	if hp < max_hp and marks < 1:
		marks = 1
	crack_marks = marks


func _process(delta: float) -> void:
	flicker += delta
	var dirty := side == 1 and not shattered
	if hit_shake > 0.0:
		hit_shake = maxf(0.0, hit_shake - delta * 3.1)
		dirty = true
	if crack_flash > 0.0:
		crack_flash = maxf(0.0, crack_flash - delta * 2.2)
		dirty = true
	if breaking and not shattered:
		break_age += delta
		spread_marks = mini(6, int(floor(break_age / 0.07)) + 1)
		dirty = true
		if break_age >= 0.82:
			_spawn_pieces()
	if dirty:
		queue_redraw()


func _draw() -> void:
	if shattered:
		return
	var kick := 0.0
	if hit_shake > 0.0:
		kick = sin(hit_shake * 46.0) * 5.5 * hit_shake
	draw_set_transform(Vector2(kick, 0.0), 0.0, Vector2.ONE)
	for raw in _parts():
		var part: Dictionary = raw
		_paint(part)
	var span := _span()
	_draw_damage_cracks(span)
	if breaking:
		_draw_spread_cracks(span)
	_draw_meter(span)


func _spawn_pieces() -> void:
	if shattered:
		return
	shattered = true
	var chips := _chips()
	piece_count = chips.size()
	for raw in chips:
		var part: Dictionary = raw
		var chip := CastleChip.new()
		var origin := _part_center(part)
		chip.position = origin
		chip.load_part(part, origin)
		var away := origin
		if away.length() < 8.0:
			away = Vector2(randf_range(-1.0, 1.0), randf_range(-0.8, 0.15))
		chip.vel = away.normalized() * randf_range(90.0, 180.0) + Vector2(randf_range(-24.0, 24.0), randf_range(-110.0, -28.0))
		chip.spin = randf_range(-3.0, 3.0)
		chip.z_index = 4
		add_child(chip)
	Sfx.play("castle", 0.64, -3.0)
	queue_redraw()


func _parts() -> Array:
	var span := _span()
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	if side == 0 or clan_gate:
		return _player_parts(ratio, span)
	if _human_army():
		return _army_parts(ratio, span)
	return _enemy_parts(ratio, span)


func _chips() -> Array:
	var out: Array = []
	for raw in _parts():
		var part: Dictionary = raw
		var kind := str(part.get("kind", ""))
		if kind == "rect":
			var box: Rect2 = part["rect"]
			for slice in _split_rect(box):
				var bit: Dictionary = part.duplicate()
				bit["rect"] = slice
				out.append(bit)
		elif kind == "poly":
			var pts: PackedVector2Array = part["pts"]
			var halves := _split_poly(pts)
			if halves.is_empty():
				out.append(part)
			else:
				for half in halves:
					var bit_poly: Dictionary = part.duplicate()
					bit_poly["pts"] = half
					out.append(bit_poly)
		elif kind == "circle":
			if float(part.get("r", 0.0)) >= 3.0:
				out.append(part)
		else:
			out.append(part)
	return out


func _paint(part: Dictionary) -> void:
	var kind := str(part.get("kind", ""))
	var ink: Color = part["color"]
	if kind == "rect":
		var box: Rect2 = part["rect"]
		draw_rect(box, ink)
	elif kind == "poly":
		var pts: PackedVector2Array = part["pts"]
		if pts.size() >= 3:
			draw_colored_polygon(pts, ink)
	elif kind == "circle":
		var spot: Vector2 = part["at"]
		draw_circle(spot, float(part.get("r", 1.0)), ink)
	elif kind == "line":
		var line_a: Vector2 = part["a"]
		var line_b: Vector2 = part["b"]
		draw_line(line_a, line_b, ink, float(part.get("w", 2.0)))


func _rect(box: Rect2, ink: Color) -> Dictionary:
	return {"kind": "rect", "rect": box, "color": ink}


func _poly(pts: PackedVector2Array, ink: Color) -> Dictionary:
	return {"kind": "poly", "pts": pts, "color": ink}


func _circle(spot: Vector2, radius: float, ink: Color) -> Dictionary:
	return {"kind": "circle", "at": spot, "r": radius, "color": ink}


func _span() -> Vector2:
	if battle == null or battle.lane_ys.is_empty():
		return Vector2(-126.0, 12.0)
	var top := float(battle.lane_ys[0]) - position.y - 36.0
	var bottom := float(battle.lane_ys[battle.lane_ys.size() - 1]) - position.y + 16.0
	return Vector2(top, bottom)


func _player_parts(ratio: float, span: Vector2) -> Array:
	var top := span.x
	var bottom := span.y
	var wood := Color("6b3a32")
	var roof := Color("c44536")
	if ratio < 0.35:
		wood = wood.darkened(0.25)
		roof = roof.darkened(0.2)
	var post_top := top + 28.0
	var parts: Array = [
		_rect(Rect2(-48, bottom - 12, 96, 16), Color("5c564e")),
		_rect(Rect2(-28, post_top, 14, bottom - post_top), wood),
		_rect(Rect2(14, post_top, 14, bottom - post_top), wood),
	]
	if battle != null:
		for road_y in battle.lane_ys:
			var local_y := float(road_y) - position.y
			parts.append(_rect(Rect2(-30, local_y - 4.0, 60, 6), wood.lightened(0.08)))
	parts.append(_poly(PackedVector2Array([
		Vector2(-58, top + 18), Vector2(0, top - 16), Vector2(58, top + 18),
		Vector2(48, top + 26), Vector2(0, top - 4), Vector2(-48, top + 26),
	]), roof))
	parts.append(_rect(Rect2(-34, top + 24, 68, 8), Color("e6c36a")))
	parts.append(_rect(Rect2(-8, top + 36, 16, 22), Color("f3e6c8")))
	return parts


func _human_army() -> bool:
	if clan_gate or battle == null or not (battle.rules is Dictionary):
		return false
	return str(battle.rules.get("faction", "")) == "human"


func _army_parts(ratio: float, span: Vector2) -> Array:
	var top := span.x
	var bottom := span.y
	var stone := Color("3e4654")
	if ratio < 0.35:
		stone = stone.darkened(0.25)
	return [
		_rect(Rect2(-48, bottom - 8, 96, 18), Color("2a241c")),
		_rect(Rect2(-32, top + 18, 18, bottom - top - 26), stone),
		_rect(Rect2(14, top + 18, 18, bottom - top - 26), stone),
		_rect(Rect2(-36, top + 8, 72, 16), stone.lightened(0.08)),
		_poly(PackedVector2Array([
			Vector2(-6, top + 28),
			Vector2(28, top + 46),
			Vector2(-6, top + 78),
		]), Color("c44536")),
	]


func _enemy_parts(ratio: float, span: Vector2) -> Array:
	var top := span.x
	var bottom := span.y
	var stone := Color("243028")
	if ratio < 0.35:
		stone = stone.darkened(0.2)
	var flame := 0.65 + 0.35 * sin(flicker * 9.0)
	var flame_y := (top + bottom) * 0.5
	return [
		_rect(Rect2(-48, bottom - 8, 96, 18), Color("1a1c18")),
		_poly(PackedVector2Array([
			Vector2(-36, bottom), Vector2(-42, top + 8), Vector2(-16, top + 34),
			Vector2(0, top - 10), Vector2(18, top + 32), Vector2(42, top + 4), Vector2(36, bottom),
		]), stone),
		_circle(Vector2(0, flame_y), 10.0 + flame * 3.0, Color(0.65, 0.9, 0.35, 0.85)),
		_circle(Vector2(0, flame_y), 4.0, Color("e7f3c4")),
		_circle(Vector2(-6, flame_y - 2), 1.4, Color(0.1, 0.12, 0.08)),
		_circle(Vector2(6, flame_y - 2), 1.4, Color(0.1, 0.12, 0.08)),
	]


func _draw_meter(span: Vector2) -> void:
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var bar_y := span.x - 22.0
	draw_rect(Rect2(-34, bar_y, 68, 8), Color(0, 0, 0, 0.65))
	var fill := Color("7dce6a") if ratio > 0.35 else Color("e24b3b")
	draw_rect(Rect2(-34, bar_y, 68.0 * ratio, 8), fill)
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var title := "CLAN" if side == 0 or clan_gate else ("ARMY" if _human_army() else "CURSE")
		draw_string(font, Vector2(-22, bar_y - 6.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f3e6c8"))


func _draw_damage_cracks(span: Vector2) -> void:
	var lines := _damage_lines(span)
	var count := lines.size()
	for i in count:
		var line: Array = lines[i]
		var line_a: Vector2 = line[0]
		var line_b: Vector2 = line[1]
		var ink := Color(0.07, 0.05, 0.04, 0.84)
		var width := 2.2
		if i == count - 1 and crack_flash > 0.0:
			ink = Color(0.94, 0.86, 0.68, 0.5 + 0.45 * crack_flash)
			width = 2.8
		draw_line(line_a, line_b, ink, width)


func _damage_lines(span: Vector2) -> Array:
	var top := span.x
	var bottom := span.y
	var out: Array = []
	var total := maxi(crack_marks, 0)
	for i in total:
		var t := float(i) / 6.0
		var y0 := lerpf(top + 34.0, bottom - 20.0, t)
		var x0 := -26.0 + float((i * 19 + side * 11) % 40)
		var x1 := x0 + 16.0 + float(i % 3) * 9.0
		var y1 := y0 + 14.0 + float((i * 5) % 4) * 7.0
		if i % 2 == 0:
			x1 = x0 - 14.0 - float(i % 3) * 6.0
		out.append([Vector2(x0, y0), Vector2(x1, y1)])
	return out


func _draw_spread_cracks(span: Vector2) -> void:
	var seams := _break_seams(span)
	var count := seams.size()
	for i in count:
		var line: Array = seams[i]
		var line_a: Vector2 = line[0]
		var line_b: Vector2 = line[1]
		var u := clampf((break_age - float(i) * 0.07) / 0.28, 0.0, 1.0)
		if u <= 0.0:
			continue
		var tip := line_a.lerp(line_b, u)
		draw_line(line_a, tip, Color(0.06, 0.04, 0.03, 0.94), 2.7)
		draw_line(line_a, tip, Color(0.9, 0.82, 0.62, 0.38), 1.15)


func _break_seams(span: Vector2) -> Array:
	var top := span.x
	var bottom := span.y
	var mid_y := (top + bottom) * 0.5
	return [
		[Vector2(-46, top + 18), Vector2(8, mid_y)],
		[Vector2(40, top + 24), Vector2(-4, bottom - 8)],
		[Vector2(-6, top - 4), Vector2(-24, bottom - 4)],
		[Vector2(10, top + 30), Vector2(34, bottom - 16)],
		[Vector2(-50, mid_y - 8), Vector2(50, mid_y + 18)],
		[Vector2(2, top + 8), Vector2(-2, bottom)],
	]


func _split_rect(box: Rect2) -> Array:
	var out: Array = []
	var cols := 1
	var rows := 1
	if box.size.x >= 30.0:
		cols = 2
	if box.size.y >= 36.0:
		rows = 2
	if cols == 1 and rows == 1:
		out.append(box)
		return out
	var piece_w := box.size.x / float(cols)
	var piece_h := box.size.y / float(rows)
	for row in rows:
		for col in cols:
			out.append(Rect2(box.position + Vector2(piece_w * float(col), piece_h * float(row)), Vector2(piece_w, piece_h)))
	return out


func _split_poly(pts: PackedVector2Array) -> Array:
	if pts.size() < 3:
		return []
	var bounds := _poly_bounds(pts)
	var mid_x := bounds.position.x + bounds.size.x * 0.5
	var left := _clip_poly(pts, mid_x, true, true)
	var right := _clip_poly(pts, mid_x, false, true)
	var halves: Array = []
	if left.size() >= 3:
		halves.append(left)
	if right.size() >= 3:
		halves.append(right)
	if bounds.size.y < 48.0 or halves.is_empty():
		return halves
	var mid_y := bounds.position.y + bounds.size.y * 0.5
	var quads: Array = []
	for raw in halves:
		var half: PackedVector2Array = raw
		var upper := _clip_poly(half, mid_y, true, false)
		var lower := _clip_poly(half, mid_y, false, false)
		if upper.size() >= 3:
			quads.append(upper)
		if lower.size() >= 3:
			quads.append(lower)
	if quads.is_empty():
		return halves
	return quads


func _clip_poly(pts: PackedVector2Array, cut: float, keep_min: bool, along_x: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := pts.size()
	if count < 3:
		return result
	for i in count:
		var edge_a: Vector2 = pts[i]
		var edge_b: Vector2 = pts[(i + 1) % count]
		var a_in := _inside(edge_a, cut, keep_min, along_x)
		var b_in := _inside(edge_b, cut, keep_min, along_x)
		if a_in and b_in:
			result.append(edge_b)
		elif a_in and not b_in:
			result.append(_cross(edge_a, edge_b, cut, along_x))
		elif not a_in and b_in:
			result.append(_cross(edge_a, edge_b, cut, along_x))
			result.append(edge_b)
	return result


func _inside(point: Vector2, cut: float, keep_min: bool, along_x: bool) -> bool:
	var value := point.x if along_x else point.y
	if keep_min:
		return value <= cut
	return value >= cut


func _cross(edge_a: Vector2, edge_b: Vector2, cut: float, along_x: bool) -> Vector2:
	if along_x:
		var dx := edge_b.x - edge_a.x
		if absf(dx) < 0.001:
			return Vector2(cut, edge_a.y)
		var tx := (cut - edge_a.x) / dx
		return Vector2(cut, lerpf(edge_a.y, edge_b.y, tx))
	var dy := edge_b.y - edge_a.y
	if absf(dy) < 0.001:
		return Vector2(edge_a.x, cut)
	var ty := (cut - edge_a.y) / dy
	return Vector2(lerpf(edge_a.x, edge_b.x, ty), cut)


func _poly_bounds(pts: PackedVector2Array) -> Rect2:
	var min_x := pts[0].x
	var min_y := pts[0].y
	var max_x := min_x
	var max_y := min_y
	for i in range(1, pts.size()):
		var point: Vector2 = pts[i]
		min_x = minf(min_x, point.x)
		min_y = minf(min_y, point.y)
		max_x = maxf(max_x, point.x)
		max_y = maxf(max_y, point.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _part_center(part: Dictionary) -> Vector2:
	var kind := str(part.get("kind", ""))
	if kind == "rect":
		var box: Rect2 = part["rect"]
		return box.get_center()
	if kind == "poly":
		var pts: PackedVector2Array = part["pts"]
		if pts.is_empty():
			return Vector2.ZERO
		var acc := Vector2.ZERO
		for point in pts:
			acc += point
		return acc / float(pts.size())
	if kind == "circle":
		var spot: Vector2 = part["at"]
		return spot
	var line_a: Vector2 = part.get("a", Vector2.ZERO)
	var line_b: Vector2 = part.get("b", Vector2.ZERO)
	return (line_a + line_b) * 0.5


class CastleChip:
	extends Node2D

	var shape: String = "rect"
	var fill: Color = Color.WHITE
	var box: Rect2 = Rect2()
	var poly: PackedVector2Array = PackedVector2Array()
	var spot: Vector2 = Vector2.ZERO
	var rad: float = 1.0
	var vel: Vector2 = Vector2.ZERO
	var spin: float = 0.0
	var age: float = 0.0

	func load_part(part: Dictionary, origin: Vector2) -> void:
		shape = str(part.get("kind", "rect"))
		var ink: Color = part["color"]
		fill = ink
		var shift := -origin
		if shape == "rect":
			var src: Rect2 = part["rect"]
			src.position += shift
			box = src
		elif shape == "poly":
			var pts: PackedVector2Array = part["pts"]
			var moved := PackedVector2Array()
			for point in pts:
				moved.append(point + shift)
			poly = moved
		elif shape == "circle":
			var at: Vector2 = part["at"]
			spot = at + shift
			rad = float(part.get("r", 1.0))

	func _process(delta: float) -> void:
		age += delta
		position += vel * delta
		vel.y += 760.0 * delta
		rotation += spin * delta
		if age > 2.3:
			set_process(false)
		queue_redraw()

	func _draw() -> void:
		if shape == "rect":
			draw_rect(box, fill)
		elif shape == "poly":
			if poly.size() >= 3:
				draw_colored_polygon(poly, fill)
		elif shape == "circle":
			draw_circle(spot, rad, fill)
