extends Control

var battle = null


func _gui_input(event: InputEvent) -> void:
	if battle == null or battle.hero == null or battle.finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		battle.hero.dragging = event.pressed
		if event.pressed:
			battle.hero.set_target(event.position)
		accept_event()
	elif event is InputEventMouseMotion and battle.hero.dragging:
		battle.hero.set_target(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		battle.hero.dragging = event.pressed
		if event.pressed:
			battle.hero.set_target(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		battle.hero.set_target(event.position)
		accept_event()
