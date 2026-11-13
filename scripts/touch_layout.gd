extends RefCounted
## Places the fight controls under the three roads.
## The road block stays on the old formula so the berserker's span does not change.
## The stick, the six calls, and Sword / Shoot share the strip below that block.


static func view_of(node: Node) -> Vector2:
	var item := node as CanvasItem
	if item == null:
		return Vector2(1280, 720)
	var size := item.get_viewport_rect().size
	if size.x < 200.0:
		return Vector2(1280, 720)
	return size


static func insets_of(node: Node) -> Vector4:
	var view := view_of(node)
	var win := DisplayServer.window_get_size()
	if win.x < 2 or win.y < 2:
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x < 2 or safe.size.y < 2:
		return Vector4.ZERO
	var origin := DisplayServer.window_get_position()
	var scale_x := view.x / float(win.x)
	var scale_y := view.y / float(win.y)
	var left := (float(safe.position.x) - float(origin.x)) * scale_x
	var top := (float(safe.position.y) - float(origin.y)) * scale_y
	var right := (float(origin.x + win.x) - float(safe.position.x + safe.size.x)) * scale_x
	var bottom := (float(origin.y + win.y) - float(safe.position.y + safe.size.y)) * scale_y
	return Vector4(
		clampf(left, 0.0, view.x * 0.16),
		clampf(top, 0.0, view.y * 0.14),
		clampf(right, 0.0, view.x * 0.16),
		clampf(bottom, 0.0, view.y * 0.18)
	)


static func measure(view: Vector2, pad: Vector4) -> Dictionary:
	var field_bottom := view.y - 14.0 - sqrt(view.x * view.y / 20.0)
	var ceiling := field_bottom + 8.0
	var floor_y := view.y - (pad.w + 10.0)
	var avail := maxf(120.0, floor_y - ceiling)
	var short_side := minf(view.x, view.y)
	var action := clampf(minf(short_side * 0.175, avail), 112.0, 150.0)
	var stick := clampf(minf(short_side * 0.26, avail), 156.0, 210.0)
	var margin_l := pad.x + 12.0
	var margin_r := pad.z + 12.0
	var gap := 14.0
	var stick_pos := Vector2(margin_l, floor_y - stick)
	var sword_pos := Vector2(view.x - margin_r - action, floor_y - action)
	var shoot_pos := Vector2(sword_pos.x - gap - action, sword_pos.y)
	var slots_left := stick_pos.x + stick + 36.0
	var slots_right := shoot_pos.x - 32.0
	var slot_h := clampf(minf(action * 0.86, avail), 96.0, action)
	var slot_y := sword_pos.y + (action - slot_h)
	var span := maxf(80.0, slots_right - slots_left)
	var slot_gap := 10.0
	var slot_w := (span - slot_gap * 5.0) / 6.0
	if slot_w > 156.0:
		slot_w = 156.0
		var used := slot_w * 6.0 + slot_gap * 5.0
		slots_left += (span - used) * 0.5
	elif slot_w < 84.0:
		slot_gap = 6.0
		slot_w = maxf(72.0, (span - slot_gap * 5.0) / 6.0)
	return {
		"action": action,
		"stick": stick,
		"stick_pos": stick_pos,
		"sword_pos": sword_pos,
		"shoot_pos": shoot_pos,
		"slot_w": slot_w,
		"slot_h": slot_h,
		"slot_y": slot_y,
		"slots_left": slots_left,
		"slot_gap": slot_gap,
		"pad": pad,
		"floor_y": floor_y,
	}
