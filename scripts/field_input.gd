extends Control

var battle = null


func _hand():
	if battle == null:
		return null
	if battle.controlled != null:
		return battle.controlled
	return battle.hero


func _gui_input(event: InputEvent) -> void:
	var hand = _hand()
	if hand == null or battle.finished:
		return
	if battle.stick_axis.length() > 0.12 and ((event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)):
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		hand.dragging = event.pressed
		if event.pressed:
			hand.set_target(event.position)
		accept_event()
	elif event is InputEventMouseMotion and hand.dragging:
		hand.set_target(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		hand.dragging = event.pressed
		if event.pressed:
			hand.set_target(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		hand.set_target(event.position)
		accept_event()
