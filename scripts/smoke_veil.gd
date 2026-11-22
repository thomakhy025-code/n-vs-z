extends Node2D

var battle = null
var _was_drawing: bool = false


func _process(_delta: float) -> void:
	var active := false
	if battle != null and battle.smokes.size() > 0:
		active = true
	if active or _was_drawing:
		queue_redraw()
	_was_drawing = active


func _draw() -> void:
	if battle == null:
		return
	for puff in battle.smokes:
		var left := float(puff.get("left", 0.0))
		var fade := clampf(left / 2.5, 0.0, 1.0)
		var at := Vector2(float(puff.get("x", 0.0)), float(puff.get("y", 0.0)))
		var wobble := 0.0
		if battle != null:
			wobble = battle.battle_time
		var drift := sin(wobble * 1.4 + at.x * 0.02) * 8.0
		var rise := cos(wobble * 0.8 + at.y * 0.015) * 5.0
		draw_circle(at + Vector2(drift, -10.0 + rise), 42.0, Color(0.62, 0.66, 0.68, 0.55 * fade))
		draw_circle(at + Vector2(-16.0 - drift * 0.6, -36.0 + rise), 30.0, Color(0.78, 0.8, 0.82, 0.42 * fade))
		draw_circle(at + Vector2(18.0 + drift * 0.4, -28.0 - rise * 0.5), 26.0, Color(0.9, 0.91, 0.9, 0.38 * fade))
		draw_circle(at + Vector2(drift * 0.3, -58.0 - rise), 22.0, Color(0.84, 0.86, 0.86, 0.34 * fade))
