extends Node2D

var age: float = 0.0
var text: String = ""
var color: Color = Color.WHITE


func setup(value: String, tint: Color) -> void:
	text = value
	color = tint
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	position.y -= 32.0 * delta
	modulate.a = 1.0 - clampf(age / 0.7, 0.0, 1.0)
	if age >= 0.7:
		queue_free()


func _draw() -> void:
	var font: Font = Tr.font()
	if font == null:
		return
	var shown := Tr.t(text)
	draw_string(font, Vector2(-16, 1), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(-17, 0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
