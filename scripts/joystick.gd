extends Control
## The stick appears under the pressing finger and follows that drag.
## It does not sit on the left edge, and it does not take the call buttons.


signal moved(axis: Vector2)

var axis: Vector2 = Vector2.ZERO

var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false


func release_stick() -> void:
	axis = Vector2.ZERO
	_knob = Vector2.ZERO
	visible = false
	queue_redraw()
	moved.emit(axis)


func show_under(center: Vector2) -> void:
	var span := size
	if span.x < 32.0 or span.y < 32.0:
		span = Vector2(180.0, 180.0)
		size = span
		custom_minimum_size = span
	position = center - span * 0.5
	_knob = Vector2.ZERO
	axis = Vector2.ZERO
	visible = true
	queue_redraw()
	moved.emit(axis)


func follow_finger(point: Vector2) -> void:
	if not visible:
		show_under(point)
		return
	var radius := minf(size.x, size.y) * 0.36
	if radius < 8.0:
		return
	var center := position + size * 0.5
	var offset := point - center
	if offset.length() > radius:
		position += offset - offset.normalized() * radius
	_place(point - position)


func _place(local_pos: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	if radius < 8.0:
		return
	var raw := (local_pos - center) / radius
	_knob = raw.limit_length(1.0)
	if _knob.length() < 0.18:
		axis = Vector2.ZERO
	else:
		var strength := (_knob.length() - 0.18) / 0.82
		axis = _knob.normalized() * strength
	queue_redraw()
	moved.emit(axis)


func _draw() -> void:
	if not visible:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	draw_circle(center, radius + 8.0, Color(0, 0, 0, 0.28))
	draw_circle(center, radius, Color(0.09, 0.07, 0.05, 0.72))
	draw_arc(center, radius, 0.0, TAU, 48, Color("e6c36a"), 4.0, true)
	draw_arc(center, radius * 0.48, 0.0, TAU, 32, Color(0.95, 0.9, 0.78, 0.28), 2.0, true)
	var knob_r := radius * 0.38
	var knob := center + _knob * radius * 0.56
	draw_circle(knob, knob_r, Color("f3e6c8"))
	draw_arc(knob, knob_r, 0.0, TAU, 28, Color("c44536"), 4.0, true)
