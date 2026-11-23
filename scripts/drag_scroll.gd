extends ScrollContainer

# A vertical list can be dragged from anywhere on its content.
# A press counts only when the finger stays nearly still. Past STILL_LIMIT,
# in this control's space, the gesture is a scroll: buttons are told the
# scroll began, so Godot does not emit pressed when the finger lifts.
# The right-hand bar is left alone.

const STILL_LIMIT := 14.0

var _down: bool = false
var _dragged: bool = false
var _start_local: Vector2 = Vector2.ZERO
var _start_scroll: int = 0


func drag_scrolls() -> bool:
	return true


func scroll_ate_tap() -> bool:
	return _dragged


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	follow_focus = false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var finger := event as InputEventScreenTouch
		_pointer(finger.pressed, finger.position)
		return
	if event is InputEventScreenDrag and _down:
		_slide((event as InputEventScreenDrag).position)
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		_pointer(mouse_button.pressed, mouse_button.position)
		return
	if event is InputEventMouseMotion and _down:
		_slide((event as InputEventMouseMotion).position)


func _pointer(pressed: bool, point: Vector2) -> void:
	if pressed:
		if _down:
			return
		if not _inside(point) or _on_bar(point):
			return
		_down = true
		_dragged = false
		_start_local = _to_local(point)
		_start_scroll = scroll_vertical
		return
	if not _down:
		return
	_commit(point, false)
	_down = false


func _slide(point: Vector2) -> void:
	_commit(point, true)


func _commit(point: Vector2, hold: bool) -> void:
	var delta := _to_local(point) - _start_local
	if not _dragged and delta.length() < STILL_LIMIT:
		return
	if not _dragged:
		_dragged = true
		propagate_notification(NOTIFICATION_SCROLL_BEGIN)
	var next := int(round(float(_start_scroll) - delta.y))
	scroll_vertical = maxi(0, next)
	if hold:
		get_viewport().set_input_as_handled()


func _to_local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point


func _inside(point: Vector2) -> bool:
	return get_global_rect().has_point(point)


func _on_bar(point: Vector2) -> bool:
	var rect := get_global_rect()
	return point.x >= rect.end.x - 36.0
