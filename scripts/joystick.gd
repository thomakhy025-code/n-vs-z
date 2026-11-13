extends Control
## Bottom-left movement stick. One finger owns it, so the other thumb can call ninjas.


signal moved(axis: Vector2)

var axis: Vector2 = Vector2.ZERO

var _finger: int = -1
var _mouse: bool = false
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func release_stick() -> void:
	_finger = -1
	_mouse = false
	axis = Vector2.ZERO
	_knob = Vector2.ZERO
	queue_redraw()
	moved.emit(axis)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger < 0:
			_finger = event.index
			_place(event.position)
			accept_event()
		elif not event.pressed and event.index == _finger:
			release_stick()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _finger:
		_place(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = event.pressed
		if event.pressed:
			_place(event.position)
		else:
			release_stick()
		accept_event()
	elif event is InputEventMouseMotion and _mouse:
		_place(event.position)
		accept_event()


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
