extends Control

# One ink page at a time. Tap, click, or Enter moves on. The first tap finishes the line.

signal done

const Painter = preload("res://scripts/painter.gd")
const INK := Color("1c140e")
const PAPER := Color("f4efe4")
const GROUND := 36.0

var panels: Array = []
var index: int = 0
var clock: float = 0.0
var closing: bool = false


func open(rows: Array) -> void:
	panels = rows
	index = 0
	clock = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	if panels.is_empty():
		done.emit()
		return
	_show_panel()


func _process(delta: float) -> void:
	if panels.is_empty():
		return
	clock += delta
	var rect := _panel_rect()
	var cast: Array = panels[index].get("cast", [])
	var figs: Array = []
	for child in get_children():
		if child is Fig:
			figs.append(child)
	for i in figs.size():
		var fig: Fig = figs[i]
		var spot := 0.5
		if i < cast.size():
			spot = float(cast[i].get("x", 0.5))
		var feet := 20.0 * fig.scale.y
		var drift := 0.0
		if fig.tale == "pace" or fig.tale == "creep" or fig.tale == "parade" or fig.tale == "rush":
			var span := Painter.tale_span(fig.tale)
			drift = sin(clock / span * TAU) * 16.0
		var place := str(panels[index].get("place", ""))
		fig.position = Vector2(rect.position.x + rect.size.x * spot + drift, _ground_y(rect, place) - feet)
		fig.clock = clock
		fig.queue_redraw()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if panels.is_empty():
		return
	var click := false
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		click = true
	var key := false
	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var code := (event as InputEventKey).keycode
		key = code == KEY_ENTER or code == KEY_SPACE or code == KEY_ESCAPE or code == KEY_KP_ENTER
	if not click and not key:
		return
	_advance()
	get_viewport().set_input_as_handled()


func _advance() -> void:
	if closing or panels.is_empty():
		return
	if clock < _read_time():
		clock = _read_time()
		queue_redraw()
		return
	if index + 1 < panels.size():
		index += 1
		_show_panel()
		return
	closing = true
	Sfx.stop_mood()
	done.emit()


func _read_time() -> float:
	var row: Dictionary = panels[index]
	var full := _spoken(row)
	return maxf(maxf(0.35, float(full.length()) / 48.0), Sfx.narration_length())


func _spoken(row: Dictionary) -> String:
	var caption := str(row.get("caption", ""))
	var speech := str(row.get("speech", ""))
	if speech == "":
		return caption
	return caption + " " + speech


func _show_panel() -> void:
	clock = 0.0
	var place := str(panels[index].get("place", "mountain"))
	Sfx.mood(place)
	Sfx.narrate(_spoken(panels[index]))
	for child in get_children():
		child.queue_free()
	var cast: Array = panels[index].get("cast", [])
	for item in cast:
		if not item is Dictionary:
			continue
		var fig := Fig.new()
		fig.setup(item)
		add_child(fig)
	queue_redraw()


func _panel_rect() -> Rect2:
	var view := get_viewport_rect().size
	if size.x > 20.0 and size.y > 20.0:
		view = size
	var margin := 28.0
	var caption_h := 132.0
	return Rect2(margin, 22.0, maxf(80.0, view.x - margin * 2.0), maxf(120.0, view.y - caption_h - 36.0))


func _draw() -> void:
	if panels.is_empty():
		return
	var view := size
	if view.x < 20.0:
		view = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color("0c0a08"))
	var rect := _panel_rect()
	var row: Dictionary = panels[index]
	draw_rect(rect.grow(8.0), INK)
	draw_rect(rect, PAPER)
	_place(rect, str(row.get("place", "mountain")), clock)
	if bool(row.get("impact", false)):
		_speed(rect)
	var reveal := clampf(clock * 2.4, 0.0, 1.0)
	if reveal < 1.0:
		var cover := rect.size.x * (1.0 - reveal)
		draw_rect(Rect2(rect.end.x - cover, rect.position.y, cover, rect.size.y), INK)
	_speech(rect, str(row.get("speech", "")))
	_caption(view, str(row.get("caption", "")))
	_hint(view)


func _ground_y(rect: Rect2, place: String) -> float:
	if place == "cliff":
		return rect.position.y + rect.size.y * 0.62
	return rect.end.y - GROUND


func _place(rect: Rect2, place: String, time: float) -> void:
	var ground_y := _ground_y(rect, place)
	match place:
		"village":
			_scene_village(rect, ground_y, time)
		"climb":
			_scene_climb(rect, ground_y, time)
		"descent":
			_scene_descent(rect, ground_y)
		"mountain":
			_scene_mountain(rect, ground_y, time)
		"quiet":
			_scene_quiet(rect, ground_y, time)
		"mist":
			_scene_mist(rect, ground_y, time)
		"stone":
			_scene_stone(rect, ground_y)
		"lone":
			_scene_lone(rect, ground_y, time)
		"camp":
			_scene_camp(rect, ground_y, time)
		"council":
			_scene_council(rect, ground_y, time)
		"depart":
			_scene_depart(rect, ground_y)
		"night":
			_scene_night(rect, ground_y, time)
		"vow":
			_scene_vow(rect, ground_y)
		"omen":
			_scene_omen(rect, ground_y, time)
		"banners":
			_scene_banners(rect, ground_y, time)
		"ash":
			_scene_ash(rect, ground_y, time)
		"low":
			_scene_low(rect, ground_y, time)
		"bury":
			_scene_bury(rect, ground_y)
		"between":
			_scene_between(rect, ground_y, time)
		"cliff":
			_scene_cliff(rect, ground_y, time)
		"war":
			_scene_war(rect, ground_y, time)
		_:
			_scene_road(rect, ground_y, time)
	_dress(rect, ground_y, place, time)
	_vignette(rect)
	_frame(rect)


func _sky(rect: Rect2, ground_y: float, top: Color, low: Color, earth: Color) -> void:
	_bands(rect, top, low, ground_y)
	draw_rect(Rect2(rect.position.x, ground_y, rect.size.x, rect.end.y - ground_y), earth)


func _scene_village(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("b7c0c8"), Color("e4ddd2"), Color("6a645c"))
	_house(rect.position + Vector2(rect.size.x * 0.5, ground_y), 150.0, false)
	_house(rect.position + Vector2(rect.size.x * 0.72, ground_y), 118.0, false)
	var door := rect.position + Vector2(rect.size.x * 0.5 + 58.0, ground_y)
	draw_line(Vector2(door.x, door.y - 28.0), Vector2(door.x + 16.0, door.y), Color("1c140e"), 3.0)
	_fence(rect.position + Vector2(rect.size.x * 0.34, ground_y), rect.size.x * 0.22)
	var sway := sin(time * 0.8) * 4.0
	var hook := rect.position + Vector2(rect.size.x * 0.46, ground_y)
	draw_line(Vector2(hook.x, hook.y - 150.0), Vector2(hook.x + sway, hook.y - 112.0), INK, 2.0)
	draw_rect(Rect2(hook.x + sway - 8.0, hook.y - 112.0, 16.0, 20.0), Color("3a3228"))
	for i in 7:
		var x := rect.position.x + 30.0 + float(i) * (rect.size.x / 8.0)
		var drift := fmod(time * 30.0 + float(i) * 40.0, 80.0)
		draw_line(Vector2(x, rect.position.y + 20.0 + drift), Vector2(x + 10.0, rect.position.y + 48.0 + drift), Color(0.55, 0.6, 0.66, 0.28), 1.0)


func _scene_climb(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("c5d2dc"), Color("e7eef2"), Color("6d756c"))
	_peak(rect, ground_y, 0.22, 240.0)
	_peak(rect, ground_y, 0.7, 280.0)
	_steps(rect, ground_y)
	_pine(rect.position + Vector2(rect.size.x * 0.86, ground_y), 78.0)
	var bank := ground_y - 170.0 + sin(time * 0.3) * 6.0
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, bank - rect.position.y), Color(0.97, 0.98, 0.98, 0.94))
	draw_rect(Rect2(rect.position.x, bank, rect.size.x, 46.0), Color(0.94, 0.96, 0.97, 0.62))


func _scene_descent(rect: Rect2, ground_y: float) -> void:
	_sky(rect, ground_y, Color("d7e6f0"), Color("f7f1df"), Color("6a6258"))
	var back := rect.position + Vector2(rect.size.x * 0.18, ground_y)
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.position.x, ground_y),
		Vector2(back.x, ground_y - 220.0),
		Vector2(back.x + 180.0, ground_y),
	]), Color("6e7884"))
	var x := rect.position.x + rect.size.x * 0.34
	for i in 6:
		var y := ground_y - 8.0 - float(5 - i) * 16.0
		draw_rect(Rect2(x + float(i) * 48.0, y, 40.0, 6.0), Color("7a7268"))
	var far := rect.position + Vector2(rect.size.x * 0.82, ground_y - 18.0)
	draw_circle(far, 10.0, Color(0.95, 0.72, 0.35, 0.45))
	_far_village(far + Vector2(-20.0, 8.0))


func _scene_mountain(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("c5d5e2"), Color("f7f4ee"), Color("7a736a"))
	_peak(rect, ground_y, 0.58, 280.0)
	_cairn(rect.position + Vector2(rect.size.x * 0.28, ground_y))
	_wind(rect, ground_y, time)


func _scene_quiet(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("f6edd4"), Color("d7e4c8"), Color("6d7a58"))
	_peak(rect, ground_y, 0.72, 150.0)
	draw_circle(rect.position + Vector2(rect.size.x * 0.18, 64.0), 22.0, Color("f0c14a"))
	for i in 9:
		var x := rect.position.x + 24.0 + float(i) * (rect.size.x / 10.0)
		var lean := sin(time * 0.6 + float(i)) * 3.0
		draw_line(Vector2(x, ground_y), Vector2(x + lean, ground_y - 16.0), Color("3f5a3a"), 2.0)


func _scene_mist(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("e7eef2"), Color("f7f7f4"), Color("8a9188"))
	_peak(rect, ground_y, 0.3, 260.0)
	_peak(rect, ground_y, 0.62, 300.0)
	for i in 4:
		var y := ground_y - 20.0 - float(i) * 18.0
		draw_line(Vector2(rect.position.x + 20.0, y), Vector2(rect.end.x - 40.0, y), Color(0.35, 0.32, 0.28, 0.22), 2.0)
	var veil := rect.position.y + (ground_y - rect.position.y) * 0.28
	draw_rect(Rect2(rect.position.x, veil, rect.size.x, ground_y - veil + 4.0), Color(0.97, 0.98, 0.98, 0.86))


func _scene_stone(rect: Rect2, ground_y: float) -> void:
	_sky(rect, ground_y, Color("8e989e"), Color("c5c8c4"), Color("5c615e"))
	var slab := rect.position + Vector2(rect.size.x * 0.62, ground_y)
	draw_colored_polygon(PackedVector2Array([
		Vector2(slab.x - 80.0, ground_y),
		Vector2(slab.x - 20.0, ground_y - 160.0),
		Vector2(slab.x + 70.0, ground_y - 120.0),
		Vector2(slab.x + 40.0, ground_y),
	]), Color("6a706c"))
	draw_line(Vector2(slab.x - 30.0, ground_y - 40.0), Vector2(slab.x + 24.0, ground_y - 90.0), Color("3e4442"), 2.0)
	draw_line(Vector2(rect.position.x + 40.0, ground_y - 8.0), Vector2(rect.position.x + rect.size.x * 0.4, ground_y - 8.0), Color("3e4442"), 3.0)


func _scene_lone(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("5c6270"), Color("b7aea2"), Color("3a342e"))
	var at := rect.position + Vector2(rect.size.x * 0.24, ground_y)
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 70.0, at.y),
		Vector2(at.x + 8.0, at.y - 86.0),
		Vector2(at.x + 78.0, at.y),
	]), Color("4a4038"))
	draw_line(Vector2(at.x + 8.0, at.y - 86.0), Vector2(at.x + 8.0, at.y), Color("2a241c"), 2.0)
	var logs := at + Vector2(130.0, 0.0)
	draw_rect(Rect2(logs.x, logs.y - 8.0, 36.0, 8.0), Color("1c140e"))
	draw_rect(Rect2(logs.x + 8.0, logs.y - 14.0, 22.0, 6.0), Color("2a241c"))
	var smoke_y := fmod(time * 12.0, 36.0)
	draw_circle(logs + Vector2(18.0, -22.0 - smoke_y), 8.0, Color(0.55, 0.52, 0.48, 0.28))
	_wind(rect, ground_y, time)


func _scene_camp(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("f0c49a"), Color("c47a62"), Color("3e342c"))
	_peak(rect, ground_y, 0.84, 110.0)
	var tent_at := rect.position + Vector2(rect.size.x * 0.14, ground_y)
	draw_colored_polygon(PackedVector2Array([
		Vector2(tent_at.x - 78.0, tent_at.y),
		Vector2(tent_at.x, tent_at.y - 150.0),
		Vector2(tent_at.x + 78.0, tent_at.y),
	]), Color("6b3a32"))
	draw_line(Vector2(tent_at.x, tent_at.y - 150.0), Vector2(tent_at.x, tent_at.y), Color("c4a574"), 2.0)
	var rack := rect.position + Vector2(rect.size.x * 0.9, ground_y)
	draw_line(Vector2(rack.x, ground_y), Vector2(rack.x, ground_y - 70.0), Color("5c3d24"), 3.0)
	draw_line(Vector2(rack.x - 8.0, ground_y - 64.0), Vector2(rack.x + 6.0, ground_y - 8.0), Color("8a8176"), 3.0)
	_fire(rect.position + Vector2(rect.size.x * 0.7, ground_y), time)
	_stones(rect.position + Vector2(rect.size.x * 0.7, ground_y))
	draw_circle(rect.position + Vector2(rect.size.x * 0.7, ground_y - 8.0), 70.0, Color(1.0, 0.55, 0.22, 0.1))


func _scene_council(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("2c2838"), Color("8a5a48"), Color("3a322c"))
	var hearth := rect.position + Vector2(rect.size.x * 0.82, ground_y)
	_fire(hearth, time * 0.6)
	for i in 7:
		var x := rect.position.x + rect.size.x * (0.18 + float(i) * 0.1)
		draw_circle(Vector2(x, ground_y - 3.0), 5.0, Color("2a241c"))
	draw_circle(hearth + Vector2(0.0, -12.0), 48.0, Color(1.0, 0.4, 0.16, 0.1))


func _scene_depart(rect: Rect2, ground_y: float) -> void:
	_sky(rect, ground_y, Color("e7eef2"), Color("f4efe4"), Color("6a6258"))
	var at := rect.position + Vector2(rect.size.x * 0.22, ground_y)
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 50.0, at.y),
		Vector2(at.x - 10.0, at.y - 22.0),
		Vector2(at.x + 46.0, at.y),
	]), Color("6b3a32"))
	_peak(rect, ground_y, 0.08, 80.0)
	var x := rect.position.x + rect.size.x * 0.4
	for i in 5:
		draw_rect(Rect2(x + float(i) * 56.0, ground_y - 6.0, 22.0, 4.0), Color("8a8176"))


func _scene_night(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("0c0e16"), Color("1c2436"), Color("10141c"))
	_stars(rect, time)
	var moon := rect.position + Vector2(rect.size.x * 0.8, 48.0)
	draw_circle(moon, 12.0, Color("d7deea"))
	_pine(rect.position + Vector2(rect.size.x * 0.12, ground_y), 120.0)
	_pine(rect.position + Vector2(rect.size.x * 0.9, ground_y), 150.0)
	var mouth := rect.position + Vector2(rect.size.x * 0.5, rect.position.y + 80.0)
	draw_colored_polygon(PackedVector2Array([
		mouth + Vector2(-18.0, 0.0),
		mouth + Vector2(18.0, 0.0),
		Vector2(rect.end.x - 80.0, ground_y),
		Vector2(rect.position.x + 80.0, ground_y),
	]), Color("2a3144"))
	_mist(rect, ground_y, time, 0.55)


func _scene_vow(rect: Rect2, ground_y: float) -> void:
	_sky(rect, ground_y, Color("10182a"), Color("243044"), Color("161c28"))
	var beam_x := rect.position.x + rect.size.x * 0.42
	draw_rect(Rect2(beam_x, rect.position.y, 70.0, ground_y - rect.position.y), Color(0.9, 0.92, 1.0, 0.08))
	draw_circle(rect.position + Vector2(rect.size.x * 0.72, 42.0), 14.0, Color("f7f1df"))
	_peak(rect, ground_y, 0.78, 90.0)


func _scene_omen(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("140c10"), Color("4a2430"), Color("100e12"))
	var moon := rect.position + Vector2(rect.size.x * 0.76, 70.0)
	draw_circle(moon, 34.0, Color("8d3a32"))
	draw_circle(moon + Vector2(-8.0, -4.0), 28.0, Color("c45a48"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.position.x, ground_y),
		Vector2(rect.position.x + rect.size.x * 0.28, ground_y - 200.0),
		Vector2(rect.position.x + rect.size.x * 0.55, ground_y),
	]), Color("0c0a0c"))
	for i in 6:
		var x := rect.position.x + fmod(float(i) * 180.0 + time * 40.0, rect.size.x)
		var y := rect.position.y + fmod(float(i) * 70.0 + time * 55.0, ground_y - rect.position.y)
		draw_circle(Vector2(x, y), 1.8, Color(0.85, 0.25, 0.18, 0.7))


func _scene_banners(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("e7c9a4"), Color("c47a62"), Color("5a4636"))
	var far := rect.position + Vector2(rect.size.x * 0.5, ground_y - 64.0)
	draw_colored_polygon(PackedVector2Array([
		far + Vector2(-22.0, 0.0),
		far + Vector2(22.0, 0.0),
		Vector2(rect.end.x - 16.0, ground_y),
		Vector2(rect.position.x + 16.0, ground_y),
	]), Color("6a5344"))
	for i in 5:
		var t := float(i) / 4.0
		var y := lerpf(far.y, ground_y, t)
		var spread := lerpf(18.0, rect.size.x * 0.38, t)
		var cloth := Color("8d2f28") if i % 2 == 0 else Color("c44536")
		_banner(Vector2(far.x - spread, y), cloth, time + float(i))
		_banner(Vector2(far.x + spread, y), cloth.darkened(0.1), time + float(i) + 0.4)
	_dust(rect, ground_y, time)


func _scene_ash(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("8a8680"), Color("c4beb4"), Color("5c5852"))
	for i in 5:
		var x := rect.position.x + 40.0 + float(i) * 70.0
		draw_line(Vector2(x, ground_y - 2.0), Vector2(x + 16.0, ground_y - 2.0), Color("2a241c"), 2.0)
		draw_line(Vector2(x + 8.0, ground_y - 8.0), Vector2(x + 22.0, ground_y - 8.0), Color("2a241c"), 2.0)
	for i in 16:
		var x := rect.position.x + fmod(float(i) * 83.0 + time * 16.0, rect.size.x)
		var y := rect.position.y + fmod(float(i) * 47.0 + time * 26.0, ground_y - rect.position.y)
		draw_rect(Rect2(x, y, 3.0, 2.0), Color(0.78, 0.75, 0.7, 0.5))


func _scene_low(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("d5dde4"), Color("e7d8c4"), Color("6a6258"))
	var far_y := ground_y - 110.0
	draw_rect(Rect2(rect.position.x, far_y, rect.size.x, ground_y - far_y), Color("8a9a78"))
	var shop := Vector2(rect.position.x + rect.size.x * 0.68, far_y)
	draw_rect(Rect2(shop.x, shop.y - 52.0, 84.0, 52.0), Color("5c4034"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(shop.x - 8.0, shop.y - 48.0),
		Vector2(shop.x + 42.0, shop.y - 78.0),
		Vector2(shop.x + 92.0, shop.y - 48.0),
	]), Color("3a3228"))
	draw_rect(Rect2(shop.x + 62.0, shop.y - 110.0, 12.0, 40.0), Color("2a241c"))
	draw_rect(Rect2(shop.x + 22.0, shop.y - 28.0, 14.0, 12.0), Color("e24b3b"))
	var rise := fmod(time * 14.0, 48.0)
	draw_circle(shop + Vector2(68.0, -116.0 - rise), 12.0 + rise * 0.2, Color(0.25, 0.22, 0.2, 0.35))
	draw_line(Vector2(rect.position.x + 24.0, ground_y - 4.0), Vector2(shop.x, far_y), Color("5c564c"), 5.0)


func _scene_bury(rect: Rect2, ground_y: float) -> void:
	_sky(rect, ground_y, Color("6a6248"), Color("c4b49a"), Color("4a4034"))
	_house(rect.position + Vector2(rect.size.x * 0.08, ground_y), 70.0, false)
	for i in 3:
		var x := rect.position.x + rect.size.x * (0.48 + float(i) * 0.14)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 28.0, ground_y),
			Vector2(x, ground_y - 22.0),
			Vector2(x + 28.0, ground_y),
		]), Color("5c5348"))
		draw_line(Vector2(x, ground_y - 22.0), Vector2(x + 8.0, ground_y - 36.0), Color("8d5a4a"), 3.0)
		draw_line(Vector2(x + 8.0, ground_y - 36.0), Vector2(x + 16.0, ground_y - 24.0), Color("8d5a4a"), 3.0)


func _scene_between(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("3a3040"), Color("c4a090"), Color("3e3832"))
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x * 0.34, ground_y - rect.position.y), Color(0.08, 0.05, 0.1, 0.45))
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.66, rect.position.y, rect.size.x * 0.34, ground_y - rect.position.y), Color(0.7, 0.32, 0.22, 0.28))
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.38, ground_y - 12.0, rect.size.x * 0.24, 16.0), Color("8a8176"))
	_banner(rect.position + Vector2(rect.size.x * 0.86, ground_y), Color("c44536"), time)
	var horn := rect.position + Vector2(rect.size.x * 0.12, ground_y - 130.0)
	draw_colored_polygon(PackedVector2Array([
		horn + Vector2(-16.0, 28.0),
		horn + Vector2(-28.0, -6.0),
		horn + Vector2(0.0, 8.0),
		horn + Vector2(28.0, -6.0),
		horn + Vector2(16.0, 28.0),
	]), Color("141018"))
	draw_circle(horn + Vector2(-8.0, 10.0), 3.0, Color("8d2f28"))
	draw_circle(horn + Vector2(8.0, 10.0), 3.0, Color("8d2f28"))


func _scene_cliff(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("d5e4ef"), Color("f7f1df"), Color("5c564c"))
	var drop_x := rect.position.x + rect.size.x * 0.58
	var valley_y := ground_y + 64.0
	draw_rect(Rect2(drop_x, rect.position.y, rect.end.x - drop_x, valley_y - rect.position.y), Color("d5e4ef"))
	for i in 6:
		var stripe := Color("7d8f62") if i % 2 == 0 else Color("c4b48a")
		var y := valley_y + float(i) * ((rect.end.y - valley_y) / 6.0)
		draw_rect(Rect2(drop_x + 8.0, y, rect.end.x - drop_x - 16.0, (rect.end.y - valley_y) / 6.0 + 1.0), stripe)
	draw_line(Vector2(drop_x + 70.0, valley_y + 18.0), Vector2(rect.end.x - 30.0, valley_y + 46.0), Color("7aa0b8"), 5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(drop_x - 8.0, ground_y),
		Vector2(drop_x + 36.0, valley_y),
		Vector2(drop_x - 20.0, rect.end.y),
		Vector2(drop_x - 80.0, rect.end.y),
	]), Color("5c564c"))
	var face := int((valley_y - ground_y) / 14.0)
	for i in face:
		var y := ground_y + 12.0 + float(i) * 14.0
		draw_line(Vector2(drop_x - 36.0, y), Vector2(drop_x + 10.0, y + 6.0), Color("3e3832"), 2.0)
	_far_village(Vector2(drop_x + rect.size.x * 0.16, valley_y + 36.0))
	_wind(rect, ground_y, time)


func _scene_war(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("5c6060"), Color("c4a090"), Color("4a4038"))
	draw_rect(Rect2(rect.position.x, ground_y - 16.0, rect.size.x * 0.42, rect.end.y - ground_y + 16.0), Color("2a2428"))
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.58, ground_y - 16.0, rect.size.x * 0.42, rect.end.y - ground_y + 16.0), Color("6a4034"))
	_smoke(rect, ground_y, time)
	_banner(rect.position + Vector2(rect.size.x * 0.1, ground_y), Color("1c140e"), time)
	_banner(rect.position + Vector2(rect.size.x * 0.9, ground_y), Color("8d2f28"), time + 0.5)
	var mid := rect.position.x + rect.size.x * 0.5
	draw_line(Vector2(mid - 30.0, ground_y - 6.0), Vector2(mid + 10.0, ground_y - 28.0), Color("8a8176"), 3.0)
	for i in 6:
		var x := rect.position.x + 30.0 + float(i) * (rect.size.x / 7.0)
		draw_line(Vector2(x, ground_y - 2.0), Vector2(x + 18.0, ground_y - 2.0), Color("2a241c"), 2.0)


func _scene_road(rect: Rect2, ground_y: float, time: float) -> void:
	_sky(rect, ground_y, Color("d7cfc4"), Color("c4b4a4"), Color("4a4034"))
	_lane_marks(rect, ground_y)
	_gate_far(rect.position + Vector2(rect.size.x * 0.9, ground_y))
	var lintel := rect.position + Vector2(rect.size.x * 0.9, ground_y - 78.0)
	draw_line(Vector2(lintel.x + 8.0, lintel.y + 4.0), Vector2(lintel.x + 28.0, lintel.y + 16.0), Color("3a3228"), 4.0)
	_dust(rect, ground_y, time)


func _dress(rect: Rect2, ground_y: float, place: String, time: float) -> void:
	match place:
		"village":
			_ridge(rect, ground_y, 0.06, 64.0, Color("8b969f"))
			_well(rect.position + Vector2(rect.size.x * 0.08, ground_y))
			_barrel(rect.position + Vector2(rect.size.x * 0.43, ground_y))
			_barrel(rect.position + Vector2(rect.size.x * 0.46, ground_y))
			_crate(rect.position + Vector2(rect.size.x * 0.66, ground_y))
			_bare(rect.position + Vector2(rect.size.x * 0.93, ground_y), 120.0)
			_birds(rect, time, rect.position.y + 78.0, 4, Color("2a241c"))
		"climb":
			_rock(rect.position + Vector2(rect.size.x * 0.16, ground_y), 16.0)
			_rock(rect.position + Vector2(rect.size.x * 0.58, ground_y), 12.0)
			_stake(rect.position + Vector2(rect.size.x * 0.74, ground_y))
			_pine(rect.position + Vector2(rect.size.x * 0.04, ground_y), 96.0)
			_birds(rect, time, ground_y - 150.0, 3, Color("3a4450"))
		"descent":
			_pine(rect.position + Vector2(rect.size.x * 0.28, ground_y), 70.0)
			_tufts(rect, ground_y, time, Color("5c6a48"))
			_birds(rect, time, rect.position.y + 90.0, 3, Color("3a3228"))
			_far_village(rect.position + Vector2(rect.size.x * 0.74, ground_y - 8.0))
		"mountain":
			_ridge(rect, ground_y, 0.18, 90.0, Color("9aa3ae"))
			_cairn(rect.position + Vector2(rect.size.x * 0.46, ground_y))
			_pine(rect.position + Vector2(rect.size.x * 0.82, ground_y), 86.0)
			_tufts(rect, ground_y, time, Color("6a7464"))
			_birds(rect, time, rect.position.y + 64.0, 3, Color("2a241c"))
		"quiet":
			_bush(rect.position + Vector2(rect.size.x * 0.12, ground_y))
			_bush(rect.position + Vector2(rect.size.x * 0.88, ground_y))
			_house(rect.position + Vector2(rect.size.x * 0.9, ground_y), 48.0, false)
			_cloud_at(rect.position + Vector2(rect.size.x * 0.48, rect.position.y + 70.0), time)
			_birds(rect, time, rect.position.y + 110.0, 4, Color("3a3228"))
			_tufts(rect, ground_y, time, Color("3f5a3a"))
		"mist":
			_rock(rect.position + Vector2(rect.size.x * 0.16, ground_y), 18.0)
			_cairn(rect.position + Vector2(rect.size.x * 0.82, ground_y))
			_stake(rect.position + Vector2(rect.size.x * 0.9, ground_y))
		"stone":
			_rock(rect.position + Vector2(rect.size.x * 0.16, ground_y), 22.0)
			_rock(rect.position + Vector2(rect.size.x * 0.28, ground_y), 14.0)
			_rock(rect.position + Vector2(rect.size.x * 0.84, ground_y), 18.0)
			_bare(rect.position + Vector2(rect.size.x * 0.08, ground_y), 80.0)
			_tufts(rect, ground_y, time, Color("5c6158"))
		"lone":
			_ridge(rect, ground_y, 0.78, 48.0, Color("6a645c"))
			_bare(rect.position + Vector2(rect.size.x * 0.86, ground_y), 100.0)
			_pot(rect.position + Vector2(rect.size.x * 0.18, ground_y))
			_rock(rect.position + Vector2(rect.size.x * 0.62, ground_y), 12.0)
		"camp":
			_log(rect.position + Vector2(rect.size.x * 0.56, ground_y))
			_pot(rect.position + Vector2(rect.size.x * 0.64, ground_y))
			_stake(rect.position + Vector2(rect.size.x * 0.78, ground_y))
			_crate(rect.position + Vector2(rect.size.x * 0.28, ground_y))
			_cloud_at(rect.position + Vector2(rect.size.x * 0.4, rect.position.y + 56.0), time)
		"council":
			_tent(rect.position + Vector2(rect.size.x * 0.16, ground_y))
			_log(rect.position + Vector2(rect.size.x * 0.34, ground_y))
			_log(rect.position + Vector2(rect.size.x * 0.62, ground_y))
			_pot(rect.position + Vector2(rect.size.x * 0.74, ground_y))
			_stars(rect, time)
		"depart":
			_bundle(rect.position + Vector2(rect.size.x * 0.4, ground_y))
			_bundle(rect.position + Vector2(rect.size.x * 0.48, ground_y))
			_stake(rect.position + Vector2(rect.size.x * 0.7, ground_y))
			_birds(rect, time, rect.position.y + 80.0, 3, Color("3a3228"))
			_tufts(rect, ground_y, time, Color("6a745c"))
		"night":
			_pine(rect.position + Vector2(rect.size.x * 0.28, ground_y), 90.0)
			_rock(rect.position + Vector2(rect.size.x * 0.4, ground_y), 14.0)
			_cart(rect.position + Vector2(rect.size.x * 0.68, ground_y), true)
			for eye_i in 3:
				var eye := rect.position + Vector2(rect.size.x * (0.5 + float(eye_i) * 0.08), ground_y - 36.0 - float(eye_i) * 10.0)
				draw_circle(eye, 2.2, Color("c44536"))
		"vow":
			_stars(rect, time)
			_cairn(rect.position + Vector2(rect.size.x * 0.24, ground_y))
			_cairn(rect.position + Vector2(rect.size.x * 0.58, ground_y))
			_stake(rect.position + Vector2(rect.size.x * 0.22, ground_y))
		"omen":
			_bare(rect.position + Vector2(rect.size.x * 0.62, ground_y), 130.0)
			_bare(rect.position + Vector2(rect.size.x * 0.9, ground_y), 90.0)
			_rock(rect.position + Vector2(rect.size.x * 0.16, ground_y), 16.0)
		"banners":
			_ridge(rect, ground_y, 0.2, 40.0, Color("a07858"))
			_dust(rect, ground_y, time + 1.2)
			_stake(rect.position + Vector2(rect.size.x * 0.08, ground_y))
			_stake(rect.position + Vector2(rect.size.x * 0.94, ground_y))
		"ash":
			_bare(rect.position + Vector2(rect.size.x * 0.72, ground_y), 70.0)
			_wheel(rect.position + Vector2(rect.size.x * 0.84, ground_y))
			_cart(rect.position + Vector2(rect.size.x * 0.18, ground_y), true)
			_rock(rect.position + Vector2(rect.size.x * 0.5, ground_y), 10.0)
		"low":
			_fence(rect.position + Vector2(rect.size.x * 0.78, ground_y - 110.0), 90.0)
			_log(rect.position + Vector2(rect.size.x * 0.58, ground_y - 110.0))
			_crate(rect.position + Vector2(rect.size.x * 0.8, ground_y - 108.0))
			_bush(rect.position + Vector2(rect.size.x * 0.2, ground_y))
			_birds(rect, time, rect.position.y + 70.0, 3, Color("3a3228"))
		"bury":
			_bare(rect.position + Vector2(rect.size.x * 0.28, ground_y), 110.0)
			_bush(rect.position + Vector2(rect.size.x * 0.4, ground_y))
			_tufts(rect, ground_y, time, Color("5c5840"))
			for flower_i in 4:
				var flower_x := rect.position.x + rect.size.x * (0.5 + float(flower_i) * 0.1)
				draw_circle(Vector2(flower_x, ground_y - 28.0), 3.0, Color("8d5a4a"))
		"between":
			_pine(rect.position + Vector2(rect.size.x * 0.06, ground_y), 140.0)
			_pine(rect.position + Vector2(rect.size.x * 0.2, ground_y), 100.0)
			_banner(rect.position + Vector2(rect.size.x * 0.74, ground_y), Color("8d2f28"), time + 0.6)
			_stake(rect.position + Vector2(rect.size.x * 0.94, ground_y))
			_rock(rect.position + Vector2(rect.size.x * 0.3, ground_y), 12.0)
		"cliff":
			_bush(rect.position + Vector2(rect.size.x * 0.08, ground_y))
			_rock(rect.position + Vector2(rect.size.x * 0.18, ground_y), 14.0)
			_tufts(rect, ground_y, time, Color("6a7460"), 0.5)
			_birds(rect, time, rect.position.y + 80.0, 4, Color("3a4450"))
			var drop_x := rect.position.x + rect.size.x * 0.58
			var valley_y := ground_y + 64.0
			_bush(Vector2(drop_x + 80.0, valley_y + 20.0))
			_far_village(Vector2(drop_x + rect.size.x * 0.28, valley_y + 24.0))
		"war":
			_banner(rect.position + Vector2(rect.size.x * 0.28, ground_y), Color("1c140e"), time + 0.8)
			_banner(rect.position + Vector2(rect.size.x * 0.72, ground_y), Color("c44536"), time + 1.1)
			_stake(rect.position + Vector2(rect.size.x * 0.16, ground_y))
			_stake(rect.position + Vector2(rect.size.x * 0.84, ground_y))
			_wheel(rect.position + Vector2(rect.size.x * 0.46, ground_y))
			_rock(rect.position + Vector2(rect.size.x * 0.58, ground_y), 10.0)
		_:
			_barrel(rect.position + Vector2(rect.size.x * 0.12, ground_y))
			_cart(rect.position + Vector2(rect.size.x * 0.22, ground_y), true)
			_rock(rect.position + Vector2(rect.size.x * 0.4, ground_y), 12.0)
			_stake(rect.position + Vector2(rect.size.x * 0.55, ground_y))
			_birds(rect, time, rect.position.y + 70.0, 3, Color("2a241c"))
			for arrow_i in 4:
				var arrow_x := rect.position.x + rect.size.x * (0.3 + float(arrow_i) * 0.12)
				draw_line(Vector2(arrow_x, ground_y - 4.0), Vector2(arrow_x + 4.0, ground_y - 22.0), Color("5c4034"), 2.0)


func _frame(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), INK)
	draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), INK)
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - 3.0), Vector2(rect.size.x, 3.0)), INK)
	draw_rect(Rect2(Vector2(rect.end.x - 3.0, rect.position.y), Vector2(3.0, rect.size.y)), INK)


func _house(at: Vector2, wide: float, lit: bool) -> void:
	draw_rect(Rect2(at.x, at.y - wide * 0.72, wide, wide * 0.72), Color("6b3a32"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 10.0, at.y - wide * 0.64),
		Vector2(at.x + wide * 0.5, at.y - wide * 1.22),
		Vector2(at.x + wide + 10.0, at.y - wide * 0.64),
	]), Color("8d2f28"))
	var window := Color("f0c14a") if lit else Color("1c140e")
	draw_rect(Rect2(at.x + wide * 0.62, at.y - wide * 0.48, 12.0, 14.0), window)
	draw_rect(Rect2(at.x + wide * 0.38, at.y - wide * 0.22, 14.0, wide * 0.22), Color("2a1814"))


func _path(rect: Rect2, ground_y: float) -> void:
	for i in 6:
		var x := rect.position.x + 18.0 + float(i) * 28.0
		draw_rect(Rect2(x, ground_y - 7.0, 14.0, 4.0), Color("7a6a58"))


func _cairn(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 10.0, at.y - 8.0, 20.0, 8.0), Color("8a8176"))
	draw_rect(Rect2(at.x - 7.0, at.y - 16.0, 14.0, 8.0), Color("6e675e"))
	draw_rect(Rect2(at.x - 4.0, at.y - 22.0, 8.0, 6.0), Color("a39b90"))


func _cloud(rect: Rect2, time: float) -> void:
	var shift := fmod(time * 12.0, rect.size.x * 0.5)
	var origin := rect.position + Vector2(rect.size.x * 0.12 + shift, 48.0)
	draw_circle(origin, 16.0, Color(1, 1, 1, 0.45))
	draw_circle(origin + Vector2(18.0, 4.0), 12.0, Color(1, 1, 1, 0.4))
	draw_circle(origin + Vector2(-16.0, 6.0), 10.0, Color(1, 1, 1, 0.35))


func _stones(at: Vector2) -> void:
	for i in 5:
		var x := at.x - 22.0 + float(i) * 11.0
		draw_circle(Vector2(x, at.y - 2.0), 4.0, Color("4a4034"))


func _fence(at: Vector2, wide: float) -> void:
	draw_line(Vector2(at.x, at.y), Vector2(at.x + wide, at.y - 10.0), Color("5c3d24"), 3.0)
	var posts := 4
	for i in posts:
		var x := at.x + wide * float(i) / float(posts - 1)
		draw_line(Vector2(x, at.y - 4.0), Vector2(x, at.y - 46.0), Color("5c3d24"), 3.0)


func _lantern(at: Vector2, time: float) -> void:
	var sway := sin(time * 1.1) * 8.0
	draw_line(Vector2(at.x, at.y - 150.0), Vector2(at.x + sway, at.y - 108.0), INK, 2.0)
	draw_rect(Rect2(at.x + sway - 10.0, at.y - 108.0, 20.0, 26.0), Color("e2b034"))
	draw_circle(at + Vector2(sway, -96.0), 18.0, Color(0.95, 0.7, 0.25, 0.18))


func _pine(at: Vector2, tall: float) -> void:
	draw_rect(Rect2(at.x - 3.0, at.y - tall * 0.45, 6.0, tall * 0.45), Color("3a2a22"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x, at.y - tall),
		Vector2(at.x - 22.0, at.y - tall * 0.35),
		Vector2(at.x + 20.0, at.y - tall * 0.32),
	]), Color("2f4a38"))


func _tent(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 54.0, at.y),
		Vector2(at.x, at.y - 108.0),
		Vector2(at.x + 54.0, at.y),
	]), Color("6b3a32"))
	draw_line(Vector2(at.x, at.y - 108.0), Vector2(at.x, at.y), Color("c4a574"), 2.0)


func _fire(at: Vector2, time: float) -> void:
	var flick := 16.0 + sin(time * 9.0) * 6.0
	draw_circle(at + Vector2(0, -12), 28.0, Color(0.9, 0.45, 0.15, 0.18))
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 8.0, at.y),
		Vector2(at.x, at.y - flick - 18.0),
		Vector2(at.x + 8.0, at.y),
	]), Color("e24b3b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 4.0, at.y),
		Vector2(at.x, at.y - flick - 8.0),
		Vector2(at.x + 4.0, at.y),
	]), Color("f0c14a"))
	var smoke_y := fmod(time * 18.0, 70.0)
	draw_circle(at + Vector2(sin(time) * 6.0, -30.0 - smoke_y), 8.0 + smoke_y * 0.08, Color(0.2, 0.16, 0.14, 0.18))


func _stars(rect: Rect2, time: float) -> void:
	var spots := [0.12, 0.2, 0.33, 0.41, 0.55, 0.63, 0.88, 0.15, 0.72]
	for i in spots.size():
		var x := rect.position.x + rect.size.x * float(spots[i])
		var y := rect.position.y + 18.0 + float((i * 37) % 70)
		var twinkle := 0.45 + 0.55 * absf(sin(time * 1.7 + float(i)))
		draw_circle(Vector2(x, y), 1.6, Color(1, 1, 0.92, twinkle))


func _mist(rect: Rect2, ground_y: float, time: float, alpha: float) -> void:
	var shift := sin(time * 0.35) * 24.0
	draw_rect(Rect2(rect.position.x + shift, ground_y - 28.0, rect.size.x, 22.0), Color(1, 1, 1, alpha * 0.35))
	draw_rect(Rect2(rect.position.x - shift * 0.5, ground_y - 14.0, rect.size.x, 16.0), Color(1, 1, 1, alpha * 0.22))


func _steps(rect: Rect2, ground_y: float) -> void:
	var x := rect.position.x + rect.size.x * 0.08
	for i in 5:
		var y := ground_y - float(i) * 14.0
		draw_rect(Rect2(x + float(i) * 16.0, y - 4.0, 34.0, 6.0), Color("6d6458"))


func _wind(rect: Rect2, ground_y: float, time: float) -> void:
	for i in 4:
		var y := ground_y - 40.0 - float(i) * 28.0
		var shift := fmod(time * 40.0 + float(i) * 80.0, rect.size.x + 40.0) - 20.0
		draw_line(Vector2(rect.position.x + shift, y), Vector2(rect.position.x + shift + 36.0, y - 4.0), Color(1, 1, 1, 0.28), 2.0)


func _smoke(rect: Rect2, ground_y: float, time: float) -> void:
	for i in 5:
		var rise := fmod(time * 22.0 + float(i) * 30.0, 120.0)
		var x := rect.position.x + rect.size.x * (0.2 + float(i) * 0.14)
		draw_circle(Vector2(x, ground_y - 10.0 - rise), 14.0 + rise * 0.12, Color(0.25, 0.22, 0.2, 0.16))
		var ember := fmod(time * 36.0 + float(i) * 17.0, 90.0)
		draw_circle(Vector2(x + 8.0, ground_y - ember), 2.2, Color(0.95, 0.45, 0.18, 0.55))


func _dust(rect: Rect2, ground_y: float, time: float) -> void:
	var shift := fmod(time * 50.0, rect.size.x)
	draw_rect(Rect2(rect.position.x + shift * 0.3, ground_y - 8.0, rect.size.x * 0.4, 6.0), Color(0.72, 0.58, 0.4, 0.28))


func _lane_marks(rect: Rect2, ground_y: float) -> void:
	for i in 3:
		var y := ground_y - 18.0 - float(i) * 22.0
		draw_line(Vector2(rect.position.x + 16.0, y), Vector2(rect.end.x - 16.0, y), Color(0.35, 0.3, 0.24, 0.35), 2.0)


func _gate_far(at: Vector2) -> void:
	draw_rect(Rect2(at.x, at.y - 70.0, 10.0, 70.0), Color("2a241c"))
	draw_rect(Rect2(at.x + 36.0, at.y - 70.0, 10.0, 70.0), Color("2a241c"))
	draw_rect(Rect2(at.x, at.y - 78.0, 46.0, 10.0), Color("3a3228"))


func _far_village(at: Vector2) -> void:
	draw_rect(Rect2(at.x, at.y - 10.0, 18.0, 10.0), Color("8d5a4a"))
	draw_rect(Rect2(at.x + 22.0, at.y - 16.0, 14.0, 16.0), Color("6b3a32"))
	draw_rect(Rect2(at.x + 40.0, at.y - 8.0, 16.0, 8.0), Color("8d5a4a"))


func _bands(rect: Rect2, top: Color, low: Color, ground_y: float) -> void:
	var height := maxf(1.0, ground_y - rect.position.y)
	var strips := 8
	for i in strips:
		var t := float(i) / float(strips - 1)
		var y := rect.position.y + height * float(i) / float(strips)
		var h := height / float(strips) + 1.0
		draw_rect(Rect2(rect.position.x, y, rect.size.x, h), top.lerp(low, t))


func _vignette(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 18.0)), Color(0, 0, 0, 0.08))
	draw_rect(Rect2(rect.position.x, rect.end.y - 22.0, rect.size.x, 22.0), Color(0, 0, 0, 0.1))


func _mood_pitch(place: String) -> float:
	match place:
		"village", "lone", "vow", "bury":
			return 0.82
		"night", "banners", "omen", "ash", "low":
			return 0.7
		"war", "between":
			return 0.64
		"cliff", "mountain", "quiet", "mist", "stone", "climb":
			return 1.12
		"camp", "council":
			return 0.96
		_:
			return 0.9


func _peak(rect: Rect2, ground_y: float, spot: float, tall: float) -> void:
	var x := rect.position.x + rect.size.x * spot
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 70.0, ground_y),
		Vector2(x, ground_y - tall),
		Vector2(x + 78.0, ground_y),
	]), Color("8a93a0"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 16.0, ground_y - tall + 28.0),
		Vector2(x, ground_y - tall),
		Vector2(x + 18.0, ground_y - tall + 28.0),
	]), Color("f7f1df"))


func _ridge(rect: Rect2, ground_y: float, spot: float, tall: float, color: Color) -> void:
	var x := rect.position.x + rect.size.x * spot
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - tall, ground_y),
		Vector2(x, ground_y - tall * 0.55),
		Vector2(x + tall * 1.15, ground_y),
	]), color)


func _bare(at: Vector2, tall: float) -> void:
	draw_line(Vector2(at.x, at.y), Vector2(at.x + 8.0, at.y - tall), Color("3a3228"), 3.0)
	draw_line(Vector2(at.x + 8.0, at.y - tall * 0.72), Vector2(at.x - 22.0, at.y - tall * 0.86), Color("3a3228"), 2.0)
	draw_line(Vector2(at.x + 8.0, at.y - tall * 0.5), Vector2(at.x + 28.0, at.y - tall * 0.66), Color("3a3228"), 2.0)
	draw_line(Vector2(at.x + 8.0, at.y - tall * 0.84), Vector2(at.x + 20.0, at.y - tall), Color("3a3228"), 2.0)


func _well(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 18.0, at.y - 22.0, 36.0, 22.0), Color("6e675e"))
	draw_rect(Rect2(at.x - 10.0, at.y - 16.0, 20.0, 12.0), Color("1c2834"))
	draw_line(Vector2(at.x - 20.0, at.y - 22.0), Vector2(at.x, at.y - 48.0), Color("5c3d24"), 3.0)
	draw_line(Vector2(at.x + 20.0, at.y - 22.0), Vector2(at.x, at.y - 48.0), Color("5c3d24"), 3.0)


func _barrel(at: Vector2) -> void:
	draw_rect(Rect2(at.x, at.y - 26.0, 18.0, 26.0), Color("6b3a32"))
	draw_line(Vector2(at.x, at.y - 18.0), Vector2(at.x + 18.0, at.y - 18.0), Color("c4a574"), 2.0)
	draw_line(Vector2(at.x, at.y - 10.0), Vector2(at.x + 18.0, at.y - 10.0), Color("c4a574"), 2.0)


func _crate(at: Vector2) -> void:
	draw_rect(Rect2(at.x, at.y - 20.0, 24.0, 20.0), Color("8a6a44"))
	draw_line(Vector2(at.x, at.y - 20.0), Vector2(at.x + 24.0, at.y), Color("5c3d24"), 2.0)
	draw_line(Vector2(at.x + 24.0, at.y - 20.0), Vector2(at.x, at.y), Color("5c3d24"), 2.0)


func _rock(at: Vector2, wide: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - wide, at.y),
		Vector2(at.x - wide * 0.35, at.y - wide * 0.7),
		Vector2(at.x + wide * 0.55, at.y - wide * 0.42),
		Vector2(at.x + wide, at.y),
	]), Color("6e675e"))


func _tufts(rect: Rect2, ground_y: float, time: float, color: Color, span: float = 1.0) -> void:
	var width := rect.size.x * span
	for i in 16:
		var x := rect.position.x + 12.0 + float(i) * (width / 17.0)
		var lean := sin(time * 1.3 + float(i)) * 5.0
		draw_line(Vector2(x, ground_y), Vector2(x + lean, ground_y - 14.0 - float(i % 3) * 5.0), color, 2.0)


func _birds(rect: Rect2, time: float, y: float, count: int, ink: Color) -> void:
	for i in count:
		var x := rect.position.x + fmod(rect.size.x * (0.18 + 0.16 * float(i)) + time * 22.0, rect.size.x)
		var flap := sin(time * 7.0 + float(i)) * 5.0
		draw_line(Vector2(x - 7.0, y + flap), Vector2(x, y), ink, 2.0)
		draw_line(Vector2(x + 7.0, y + flap), Vector2(x, y), ink, 2.0)


func _bush(at: Vector2) -> void:
	draw_circle(at + Vector2(0.0, -10.0), 12.0, Color("3f5a3a"))
	draw_circle(at + Vector2(14.0, -6.0), 9.0, Color("2f4a38"))
	draw_circle(at + Vector2(-12.0, -4.0), 8.0, Color("4d6844"))


func _log(at: Vector2) -> void:
	draw_rect(Rect2(at.x, at.y - 10.0, 42.0, 10.0), Color("5c3d24"))
	draw_circle(at + Vector2(2.0, -5.0), 5.0, Color("8a6a44"))
	draw_circle(at + Vector2(40.0, -5.0), 5.0, Color("8a6a44"))


func _pot(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 10.0, at.y),
		Vector2(at.x - 12.0, at.y - 16.0),
		Vector2(at.x + 12.0, at.y - 16.0),
		Vector2(at.x + 10.0, at.y),
	]), Color("3a3228"))
	draw_line(Vector2(at.x - 14.0, at.y - 18.0), Vector2(at.x + 14.0, at.y - 18.0), Color("8a8176"), 2.0)


func _stake(at: Vector2) -> void:
	draw_line(Vector2(at.x, at.y), Vector2(at.x - 4.0, at.y - 58.0), Color("5c3d24"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 6.0, at.y - 58.0),
		Vector2(at.x - 2.0, at.y - 78.0),
		Vector2(at.x + 2.0, at.y - 54.0),
	]), Color("8a8176"))


func _bundle(at: Vector2) -> void:
	draw_rect(Rect2(at.x, at.y - 16.0, 28.0, 16.0), Color("6b3a32"))
	draw_line(Vector2(at.x + 4.0, at.y - 16.0), Vector2(at.x + 22.0, at.y), Color("c4a574"), 2.0)


func _cart(at: Vector2, broken: bool) -> void:
	draw_rect(Rect2(at.x, at.y - 22.0, 46.0, 16.0), Color("5c4034"))
	draw_circle(at + Vector2(8.0, -2.0), 7.0, Color("2a241c"))
	draw_circle(at + Vector2(36.0, -2.0), 7.0, Color("2a241c"))
	if broken:
		draw_line(Vector2(at.x + 30.0, at.y - 22.0), Vector2(at.x + 48.0, at.y - 8.0), Color("3a3228"), 3.0)


func _wheel(at: Vector2) -> void:
	draw_circle(at + Vector2(0.0, -8.0), 8.0, Color("5c4034"))
	draw_circle(at + Vector2(0.0, -8.0), 3.0, Color("2a241c"))


func _cloud_at(at: Vector2, time: float) -> void:
	var shift := sin(time * 0.4) * 10.0
	draw_circle(at + Vector2(shift, 0.0), 18.0, Color(1, 1, 1, 0.55))
	draw_circle(at + Vector2(20.0 + shift, 4.0), 14.0, Color(1, 1, 1, 0.45))
	draw_circle(at + Vector2(-16.0 + shift, 6.0), 12.0, Color(1, 1, 1, 0.4))


func _banner(at: Vector2, color: Color, time: float) -> void:
	var sway := sin(time * 1.4 + at.x * 0.01) * 10.0
	draw_line(Vector2(at.x, at.y), Vector2(at.x, at.y - 110.0), INK, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x, at.y - 104.0),
		Vector2(at.x + 28.0 + sway, at.y - 86.0),
		Vector2(at.x + 18.0 + sway * 0.6, at.y - 64.0),
		Vector2(at.x, at.y - 72.0),
	]), color)
	draw_line(Vector2(at.x, at.y - 104.0), Vector2(at.x + 28.0 + sway, at.y - 86.0), color.darkened(0.25), 2.0)


func _speed(rect: Rect2) -> void:
	var origin := rect.position + rect.size * 0.55
	for i in 9:
		var ang := -0.8 + float(i) * 0.18
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(origin + dir * 30.0, origin + dir * (90.0 + float(i % 3) * 24.0), Color(0.11, 0.08, 0.05, 0.45), 2.0)


func _speech(rect: Rect2, speech: String) -> void:
	if speech == "":
		return
	var shown := _typed(speech)
	var box := Rect2(rect.position.x + 24.0, rect.position.y + 18.0, minf(420.0, rect.size.x * 0.46), 72.0)
	draw_rect(box, Color("fff8ea"))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 3.0)), INK)
	draw_rect(Rect2(box.position, Vector2(3.0, box.size.y)), INK)
	draw_rect(Rect2(Vector2(box.position.x, box.end.y - 3.0), Vector2(box.size.x, 3.0)), INK)
	draw_rect(Rect2(Vector2(box.end.x - 3.0, box.position.y), Vector2(3.0, box.size.y)), INK)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, box.position + Vector2(14.0, 40.0), shown, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 28.0, 22, INK)


func _caption(view: Vector2, caption: String) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var shown := _typed(caption)
	var top := view.y - 118.0
	draw_multiline_string(font, Vector2(40.0, top), shown, HORIZONTAL_ALIGNMENT_LEFT, view.x - 80.0, 22, 28, Color("f3e6c8"))


func _hint(view: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var last := index + 1 >= panels.size()
	var word := "Continue" if last else "Tap"
	draw_string(font, Vector2(view.x - 180.0, view.y - 28.0), word, HORIZONTAL_ALIGNMENT_RIGHT, 150.0, 16, Color("e6c36a"))


func _typed(full: String) -> String:
	var count := mini(full.length(), int(clock * 48.0))
	return full.substr(0, count)


class Fig:
	extends Node2D

	const Painter = preload("res://scripts/painter.gd")

	var paint_id: String = "sword"
	var phase: String = "idle"
	var tale: String = ""
	var monster: bool = false
	var clock: float = 0.0
	var phase_draw: String = "idle"
	var look: Dictionary = {}

	func setup(item: Dictionary) -> void:
		paint_id = str(item.get("id", "sword"))
		phase = str(item.get("phase", "idle"))
		tale = ""
		phase_draw = "march" if phase == "walk" else phase
		if phase != "idle" and phase != "walk" and phase != "act" and phase != "hurt" and phase != "fall":
			tale = phase
			phase_draw = "tale"
		monster = bool(item.get("monster", false))
		look = Painter.look(paint_id)
		if monster:
			look = Painter.as_monster(look)
		elif bool(item.get("human", false)):
			look = Painter.as_human(look)
		scale = Vector2(2.2, 2.2)
		if bool(item.get("flip", false)):
			scale.x = -2.2
		z_index = 2

	func _draw() -> void:
		if look.is_empty():
			return
		var beat := int(clock * 2.0) % 4
		var along := fmod(clock, 1.0)
		if tale != "":
			var span := Painter.tale_span(tale)
			along = fmod(clock, span) / span
		Painter.paint_local(self, look, {
			"phase": phase_draw,
			"t": along,
			"clock": clock,
			"beat": beat,
			"flash": 0.0,
			"tale": tale,
		})
