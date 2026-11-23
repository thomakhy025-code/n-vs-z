extends ScrollContainer

# A vertical list can be dragged from anywhere on its content.
# A short press still reaches the buttons. The right bar still works.

var _down: bool = false
var _dragged: bool = false
var _start_y: float = 0.0
var _start_scroll: int = 0


func drag_scrolls() -> bool:
	return true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	follow_focus = false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _down:
		_mouse_move(event as InputEventMouseMotion)


func _mouse_button(press: InputEventMouseButton) -> void:
	if press.pressed:
		if not _inside(press.position) or _on_bar(press.position):
			_down = false
			return
		_down = true
		_dragged = false
		_start_y = press.position.y
		_start_scroll = scroll_vertical
		return
	if not _down:
		return
	_down = false
	if not _dragged:
		return
	_lift_buttons(self)
	get_viewport().set_input_as_handled()


func _mouse_move(motion: InputEventMouseMotion) -> void:
	var delta_y := _start_y - motion.position.y
	if absf(delta_y) < 10.0 and not _dragged:
		return
	_dragged = true
	scroll_vertical = maxi(0, int(round(_start_scroll + delta_y)))
	get_viewport().set_input_as_handled()


func _inside(point: Vector2) -> bool:
	return get_global_rect().has_point(point)


func _on_bar(point: Vector2) -> bool:
	var rect := get_global_rect()
	return point.x >= rect.end.x - 36.0


func _lift_buttons(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).button_pressed = false
	for child in node.get_children():
		_lift_buttons(child)
