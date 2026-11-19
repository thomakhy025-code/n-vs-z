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
		draw_circle(at + Vector2(0, -10), 42.0, Color(0.62, 0.66, 0.68, 0.55 * fade))
		draw_circle(at + Vector2(-16, -36), 30.0, Color(0.78, 0.8, 0.82, 0.42 * fade))
		draw_circle(at + Vector2(18, -28), 26.0, Color(0.9, 0.91, 0.9, 0.38 * fade))
		draw_circle(at + Vector2(0, -58), 22.0, Color(0.84, 0.86, 0.86, 0.34 * fade))
