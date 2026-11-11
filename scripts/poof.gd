extends Node2D

var age: float = 0.0
var tint: Color = Color("d7c4ff")


func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= 0.32:
		queue_free()


func _draw() -> void:
	var radius := 6.0 + age * 90.0
	var alpha := 1.0 - age / 0.32
	draw_arc(Vector2.ZERO, radius, 0, TAU, 18, Color(tint.r, tint.g, tint.b, alpha), 3.0)
