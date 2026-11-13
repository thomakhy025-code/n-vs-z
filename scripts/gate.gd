extends Node2D

var side: int = 0
var hp: float = 2000.0
var max_hp: float = 2000.0
var front_x: float = 0.0
var battle = null
var flicker: float = 0.0
var gusted: bool = false
var clan_gate: bool = false


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
	Sfx.play("castle", randf_range(0.92, 1.05), -6.0)
	queue_redraw()
	if hp <= 0.0:
		battle.on_gate_fallen(side)


func _process(delta: float) -> void:
	flicker += delta
	if side == 1:
		queue_redraw()


func _draw() -> void:
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	var span := _span()
	if side == 0 or clan_gate:
		_player_gate(ratio, span)
	else:
		_enemy_gate(ratio, span)
	var bar_y := span.x - 22.0
	draw_rect(Rect2(-34, bar_y, 68, 8), Color(0, 0, 0, 0.65))
	var fill := Color("7dce6a") if ratio > 0.35 else Color("e24b3b")
	draw_rect(Rect2(-34, bar_y, 68.0 * ratio, 8), fill)
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var title := "CLAN" if side == 0 or clan_gate else "CURSE"
		draw_string(font, Vector2(-22, bar_y - 6.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f3e6c8"))


func _span() -> Vector2:
	if battle == null or battle.lane_ys.is_empty():
		return Vector2(-126.0, 12.0)
	var top := float(battle.lane_ys[0]) - position.y - 36.0
	var bottom := float(battle.lane_ys[battle.lane_ys.size() - 1]) - position.y + 16.0
	return Vector2(top, bottom)


func _player_gate(ratio: float, span: Vector2) -> void:
	var top := span.x
	var bottom := span.y
	var wood := Color("6b3a32")
	var roof := Color("c44536")
	if ratio < 0.35:
		wood = wood.darkened(0.25)
		roof = roof.darkened(0.2)
	draw_rect(Rect2(-48, bottom - 12, 96, 16), Color("5c564e"))
	var post_top := top + 28.0
	draw_rect(Rect2(-28, post_top, 14, bottom - post_top), wood)
	draw_rect(Rect2(14, post_top, 14, bottom - post_top), wood)
	if battle != null:
		for road_y in battle.lane_ys:
			var local_y := float(road_y) - position.y
			draw_rect(Rect2(-30, local_y - 4.0, 60, 6), wood.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-58, top + 18), Vector2(0, top - 16), Vector2(58, top + 18),
		Vector2(48, top + 26), Vector2(0, top - 4), Vector2(-48, top + 26),
	]), roof)
	draw_rect(Rect2(-34, top + 24, 68, 8), Color("e6c36a"))
	draw_rect(Rect2(-8, top + 36, 16, 22), Color("f3e6c8"))
	if ratio < 0.6:
		draw_line(Vector2(-20, bottom - 46), Vector2(6, bottom - 12), Color(0, 0, 0, 0.45), 2.0)
	if ratio < 0.3:
		draw_line(Vector2(18, top + 46), Vector2(8, (top + bottom) * 0.5), Color(0, 0, 0, 0.55), 2.0)


func _enemy_gate(ratio: float, span: Vector2) -> void:
	var top := span.x
	var bottom := span.y
	var stone := Color("243028")
	if ratio < 0.35:
		stone = stone.darkened(0.2)
	draw_rect(Rect2(-48, bottom - 8, 96, 18), Color("1a1c18"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-36, bottom), Vector2(-42, top + 8), Vector2(-16, top + 34),
		Vector2(0, top - 10), Vector2(18, top + 32), Vector2(42, top + 4), Vector2(36, bottom),
	]), stone)
	var flame := 0.65 + 0.35 * sin(flicker * 9.0)
	var flame_y := (top + bottom) * 0.5
	draw_circle(Vector2(0, flame_y), 10 + flame * 3.0, Color(0.65, 0.9, 0.35, 0.85))
	draw_circle(Vector2(0, flame_y), 4, Color("e7f3c4"))
	draw_circle(Vector2(-6, flame_y - 2), 1.4, Color(0.1, 0.12, 0.08))
	draw_circle(Vector2(6, flame_y - 2), 1.4, Color(0.1, 0.12, 0.08))
	if ratio < 0.55:
		draw_line(Vector2(-18, bottom - 30), Vector2(10, top + 40), Color(0, 0, 0, 0.45), 2.0)
