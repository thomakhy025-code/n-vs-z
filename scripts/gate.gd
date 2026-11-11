extends Node2D

var side: int = 0
var hp: float = 1000.0
var max_hp: float = 1000.0
var front_x: float = 0.0
var battle = null
var flicker: float = 0.0


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
	battle.float_text(Vector2(front_x, position.y - 120), str(int(round(amount))), Color("ff8d7a"))
	battle.note_gate_hit(side)
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
	if side == 0:
		_player_gate(ratio)
	else:
		_enemy_gate(ratio)
	var bar := Rect2(-34, -132, 68, 8)
	draw_rect(bar, Color(0, 0, 0, 0.65))
	var fill := Color("7dce6a") if ratio > 0.35 else Color("e24b3b")
	draw_rect(Rect2(-34, -132, 68.0 * ratio, 8), fill)
	var font: Font = ThemeDB.fallback_font
	if font != null:
		var title := "CLAN" if side == 0 else "CURSE"
		draw_string(font, Vector2(-22, -142), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f3e6c8"))


func _player_gate(ratio: float) -> void:
	var wood := Color("6b3a32")
	var roof := Color("c44536")
	if ratio < 0.35:
		wood = wood.darkened(0.25)
		roof = roof.darkened(0.2)
	draw_rect(Rect2(-46, -8, 92, 16), Color("5c564e"))
	draw_rect(Rect2(-28, -96, 14, 92), wood)
	draw_rect(Rect2(14, -96, 14, 92), wood)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-58, -90), Vector2(0, -126), Vector2(58, -90), Vector2(48, -84), Vector2(0, -114), Vector2(-48, -84)
	]), roof)
	draw_rect(Rect2(-34, -86, 68, 8), Color("e6c36a"))
	draw_rect(Rect2(-8, -78, 16, 28), Color("f3e6c8"))
	if ratio < 0.6:
		draw_line(Vector2(-20, -40), Vector2(6, -10), Color(0, 0, 0, 0.45), 2.0)
	if ratio < 0.3:
		draw_line(Vector2(18, -70), Vector2(8, -20), Color(0, 0, 0, 0.55), 2.0)


func _enemy_gate(ratio: float) -> void:
	var stone := Color("243028")
	if ratio < 0.35:
		stone = stone.darkened(0.2)
	draw_rect(Rect2(-48, -6, 96, 18), Color("1a1c18"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34, 0), Vector2(-40, -100), Vector2(-16, -78), Vector2(0, -112), Vector2(18, -76), Vector2(40, -104), Vector2(34, 0)
	]), stone)
	var flame := 0.65 + 0.35 * sin(flicker * 9.0)
	draw_circle(Vector2(0, -48), 10 + flame * 3.0, Color(0.65, 0.9, 0.35, 0.85))
	draw_circle(Vector2(0, -48), 4, Color("e7f3c4"))
	draw_circle(Vector2(-6, -50), 1.4, Color(0.1, 0.12, 0.08))
	draw_circle(Vector2(6, -50), 1.4, Color(0.1, 0.12, 0.08))
	if ratio < 0.55:
		draw_line(Vector2(-18, -20), Vector2(10, -60), Color(0, 0, 0, 0.45), 2.0)
