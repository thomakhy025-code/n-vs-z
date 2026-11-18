extends Control

signal done

var host_button: Button = null
var age: float = 0.0
var ended: bool = false
var opened_sound: bool = false
var turned_sound: bool = false

const GIFT := 0.7
const LID := 0.55
const FLY := 0.85
const TURN := 0.55
const CHEER := 1.05


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fill()


func _process(delta: float) -> void:
	if ended:
		return
	_fill()
	age += delta
	if age >= GIFT and not opened_sound:
		opened_sound = true
		Sfx.play("buff", 1.06, -5.0)
	if age >= GIFT + LID + FLY and not turned_sound:
		_turn()
	if age >= GIFT + LID + FLY + TURN + CHEER:
		_finish()
		return
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if ended:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_skip()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if ended:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		_skip()
		get_viewport().set_input_as_handled()


func _skip() -> void:
	_turn()
	_finish()


func _turn() -> void:
	if turned_sound:
		return
	turned_sound = true
	Sfx.play("click", 0.72, -3.0)
	Sfx.play("buff", 1.22, -7.0)
	_reveal()


func _reveal() -> void:
	if host_button != null and is_instance_valid(host_button):
		host_button.modulate = Color.WHITE
	var root := get_tree().current_scene
	if root != null and root.has_method("_reveal_duel_button"):
		root._reveal_duel_button(host_button)


func _finish() -> void:
	if ended:
		return
	ended = true
	done.emit()
	queue_free()


func _draw() -> void:
	var cheer := _phase(GIFT + LID + FLY + TURN, CHEER)
	var fade := 1.0
	if cheer > 0.62:
		fade = 1.0 - smoothstep(0.62, 1.0, cheer)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.02, 0.05, 0.46 * fade))
	var gift_u := _phase(0.0, GIFT)
	var lid_u := _phase(GIFT, LID)
	var fly_u := smoothstep(0.0, 1.0, _phase(GIFT + LID, FLY))
	var turn_u := _phase(GIFT + LID + FLY, TURN)
	var cradle := Vector2(size.x * 0.2, size.y * 0.34)
	var drop := lerpf(-140.0, 0.0, 1.0 - pow(1.0 - gift_u, 3.0))
	var bounce := sin(gift_u * PI) * 12.0
	var box_at := cradle + Vector2(0, drop - bounce)
	_glow(box_at, gift_u, lid_u, fade)
	_gift(box_at, lid_u, gift_u)
	var lock_at := _lock_point()
	_aim(lock_at, fly_u, turn_u, fade)
	var start := box_at + Vector2(0, -48.0 - lid_u * 22.0)
	var key_at := start.lerp(lock_at, fly_u)
	key_at.y += sin(fly_u * PI) * -42.0
	var spin := lerpf(-0.6, 0.2, fly_u) + turn_u * (PI * 0.5)
	if lid_u > 0.12 or fly_u > 0.0:
		_key(key_at, spin, lerpf(0.7, 1.85, clampf(lid_u * 0.45 + fly_u, 0.0, 1.0)))
	if turn_u > 0.02:
		_burst(lock_at, turn_u, cheer, fade)
	_words(box_at, gift_u, turn_u, cheer, fade)


func _fill() -> void:
	var want := get_viewport_rect().size
	var parent_control := get_parent() as Control
	if parent_control != null and parent_control.size.x > 20.0 and parent_control.size.y > 20.0:
		want = parent_control.size
	if want.x < 20.0 or want.y < 20.0:
		return
	if absf(size.x - want.x) < 2.0 and absf(size.y - want.y) < 2.0:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = want


func _phase(start: float, length: float) -> float:
	return clampf((age - start) / length, 0.0, 1.0)


func _into(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point


func _lock_point() -> Vector2:
	if host_button == null or not is_instance_valid(host_button):
		return Vector2(size.x * 0.72, size.y * 0.42)
	var rect := host_button.get_global_rect()
	return _into(rect.position + Vector2(rect.size.x - 36.0, rect.size.y * 0.5 + 3.0))


func _button_rect() -> Rect2:
	if host_button == null or not is_instance_valid(host_button):
		return Rect2()
	var rect := host_button.get_global_rect()
	return Rect2(_into(rect.position), rect.size)


func _glow(at: Vector2, gift_u: float, lid_u: float, fade: float) -> void:
	var radius := lerpf(10.0, 78.0, clampf(gift_u * 0.4 + lid_u, 0.0, 1.0))
	draw_circle(at + Vector2(0, -10), radius, Color(0.95, 0.78, 0.35, 0.16 * fade))
	draw_circle(at + Vector2(0, -24), radius * 0.45, Color(1.0, 0.94, 0.7, 0.18 * lid_u * fade))


func _gift(at: Vector2, lid_u: float, gift_u: float) -> void:
	draw_colored_polygon(_ellipse(at + Vector2(0, 42), 58, 12), Color(0, 0, 0, 0.32 * gift_u))
	var body := Rect2(at + Vector2(-50, -6), Vector2(100, 52))
	draw_rect(body, Color("6e1c1c"))
	draw_rect(body.grow(-4), Color("c44536"))
	draw_rect(Rect2(at + Vector2(-9, -6), Vector2(18, 52)), Color("e6c36a"))
	draw_rect(Rect2(at + Vector2(-50, 12), Vector2(100, 14)), Color("e6c36a"))
	var lid_at := at + Vector2(0, lerpf(-6.0, -40.0, lid_u))
	draw_set_transform(lid_at, lerpf(0.0, -0.42, lid_u), Vector2.ONE)
	draw_rect(Rect2(Vector2(-54, -18), Vector2(108, 22)), Color("7d1f1f"))
	draw_rect(Rect2(Vector2(-54, -18), Vector2(108, 8)), Color("f0d78c"))
	draw_rect(Rect2(Vector2(-9, -18), Vector2(18, 22)), Color("fff1c2"))
	draw_colored_polygon(_ellipse(Vector2(-16, -24), 16, 10), Color("f0d78c"))
	draw_colored_polygon(_ellipse(Vector2(16, -24), 16, 10), Color("e6c36a"))
	draw_circle(Vector2(0, -20), 7.0, Color("fff8ea"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _key(at: Vector2, spin: float, scale: float) -> void:
	draw_set_transform(at, spin, Vector2(scale, scale))
	draw_circle(Vector2(-12, 0), 11.0, Color(0, 0, 0, 0.28))
	draw_arc(Vector2(-12, 0), 8.0, 0.0, TAU, 18, Color("fff1c2"), 3.4, true)
	draw_line(Vector2(-4, 0), Vector2(18, 0), Color("e6c36a"), 3.6)
	draw_line(Vector2(10, 0), Vector2(10, 7), Color("f0d78c"), 3.2)
	draw_line(Vector2(18, 0), Vector2(18, 9), Color("fff1c2"), 3.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _aim(lock_at: Vector2, fly_u: float, turn_u: float, fade: float) -> void:
	var rect := _button_rect()
	if rect.size.x < 4.0:
		return
	var ink := Color("e6c36a")
	ink.a = lerpf(0.0, 0.95, clampf(fly_u, 0.0, 1.0)) * fade * (1.0 - turn_u * 0.4)
	draw_rect(rect.grow(6.0), ink, false, 3.0)


func _burst(at: Vector2, turn_u: float, cheer: float, fade: float) -> void:
	var lift := lerpf(0.0, -18.0, turn_u)
	draw_arc(at + Vector2(0, -9.0 + lift), 9.0, PI, TAU, 14, Color("f3e6c8"), 3.0, true)
	draw_rect(Rect2(at + Vector2(-10, -1), Vector2(20, 15)), Color("e6c36a"))
	draw_circle(at + Vector2(0, 6), 2.2, Color("1c140e"))
	var rays := 12
	for ray_i in rays:
		var ang := TAU * float(ray_i) / float(rays) + cheer
		var reach := lerpf(16.0, 52.0, clampf(turn_u * 0.7 + cheer * 0.5, 0.0, 1.0))
		var near := at + Vector2(cos(ang), sin(ang)) * 14.0
		var far := at + Vector2(cos(ang), sin(ang)) * reach
		var spark := Color("fff1c2")
		spark.a = fade
		draw_line(near, far, spark, 2.0)
		draw_circle(far, 2.6, spark)


func _words(_box_at: Vector2, gift_u: float, turn_u: float, cheer: float, fade: float) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var spot := Vector2(size.x * 0.2, size.y * 0.16)
	_plate(font, "Congratulations", spot, 36, gift_u * fade, Color("fff4d2"))
	if turn_u <= 0.15:
		return
	var gold := Color("f3e6c8").lerp(Color("e6c36a"), cheer)
	_plate(font, "1 vs 1 is open", Vector2(size.x * 0.46, size.y * 0.3), 28, clampf(turn_u, 0.0, 1.0) * fade, gold)


func _plate(font: Font, text: String, anchor: Vector2, px: int, alpha: float, ink: Color) -> void:
	if alpha <= 0.01:
		return
	var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px)
	var at := Vector2(anchor.x - measured.x * 0.5, anchor.y)
	var plate := Rect2(at + Vector2(-18, -px), Vector2(measured.x + 36, px + 16))
	draw_rect(plate, Color(0.08, 0.05, 0.04, 0.82 * alpha))
	draw_rect(plate, Color("e6c36a", 0.9 * alpha), false, 2.0)
	ink.a = alpha
	draw_string(font, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(0.12, 0.07, 0.04, alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)


func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var segs := 16
	for i in segs:
		var ang := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	return pts
