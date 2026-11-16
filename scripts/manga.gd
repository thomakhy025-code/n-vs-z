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
		fig.position = Vector2(rect.position.x + rect.size.x * spot, rect.end.y - GROUND - feet)
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
	done.emit()


func _read_time() -> float:
	var row: Dictionary = panels[index]
	var full := str(row.get("caption", "")) + str(row.get("speech", ""))
	return maxf(0.35, float(full.length()) / 48.0)


func _show_panel() -> void:
	clock = 0.0
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
	_place(rect, str(row.get("place", "mountain")))
	if bool(row.get("impact", false)):
		_speed(rect)
	var reveal := clampf(clock * 2.4, 0.0, 1.0)
	if reveal < 1.0:
		var cover := rect.size.x * (1.0 - reveal)
		draw_rect(Rect2(rect.end.x - cover, rect.position.y, cover, rect.size.y), INK)
	_speech(rect, str(row.get("speech", "")))
	_caption(view, str(row.get("caption", "")))
	_hint(view)


func _place(rect: Rect2, place: String) -> void:
	var ground_y := rect.end.y - GROUND
	var sky := PAPER
	match place:
		"village":
			sky = Color("d7c4a3")
		"night":
			sky = Color("1a1c28")
		"cliff", "war":
			sky = Color("c5d0dc")
		"banners":
			sky = Color("e7d7c4")
		"climb":
			sky = Color("d5dde4")
		_:
			sky = Color("e7e1d4")
	draw_rect(rect, sky)
	draw_rect(Rect2(rect.position.x, ground_y, rect.size.x, rect.end.y - ground_y), Color("3a342c") if place != "night" else Color("12141c"))
	if place == "village":
		_house(rect.position + Vector2(rect.size.x * 0.62, ground_y), 70.0)
		_house(rect.position + Vector2(rect.size.x * 0.78, ground_y), 48.0)
	elif place == "climb" or place == "mountain" or place == "camp":
		_peak(rect, ground_y, 0.18, 150.0)
		_peak(rect, ground_y, 0.42, 210.0)
		_peak(rect, ground_y, 0.7, 170.0)
		if place == "camp":
			_house(rect.position + Vector2(rect.size.x * 0.3, ground_y), 54.0)
	elif place == "night":
		draw_circle(rect.position + Vector2(rect.size.x * 0.78, 48.0), 16.0, Color("f4efe4"))
		_peak(rect, ground_y, 0.2, 120.0)
		_peak(rect, ground_y, 0.55, 160.0)
	elif place == "cliff":
		draw_rect(Rect2(rect.position.x, ground_y - 90.0, rect.size.x * 0.42, rect.end.y - (ground_y - 90.0)), Color("4a453c"))
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.42, ground_y + 8.0, rect.size.x * 0.58, 40.0), Color("6d6048"))
	elif place == "war":
		draw_rect(Rect2(rect.position.x, ground_y - 20.0, rect.size.x * 0.46, 28.0), Color("3d4634"))
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.54, ground_y - 20.0, rect.size.x * 0.46, 28.0), Color("5c3a34"))
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 16.0), Vector2(rect.position.x + rect.size.x * 0.5, ground_y), INK, 2.0)
	elif place == "banners":
		_banner(rect.position + Vector2(rect.size.x * 0.68, ground_y), Color("c44536"))
		_banner(rect.position + Vector2(rect.size.x * 0.82, ground_y), Color("8d2f28"))
	else:
		draw_line(Vector2(rect.position.x + 20.0, ground_y - 8.0), Vector2(rect.end.x - 20.0, ground_y - 8.0), Color("6b5a48"), 3.0)
	draw_rect(rect, Color(0, 0, 0, 0))
	draw_rect(Rect2(rect.position, rect.size), Color(0, 0, 0, 0))
	_frame(rect)


func _frame(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), INK)
	draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), INK)
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - 3.0), Vector2(rect.size.x, 3.0)), INK)
	draw_rect(Rect2(Vector2(rect.end.x - 3.0, rect.position.y), Vector2(3.0, rect.size.y)), INK)


func _house(at: Vector2, wide: float) -> void:
	draw_rect(Rect2(at.x, at.y - wide * 0.7, wide, wide * 0.7), Color("6b3a32"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x - 8.0, at.y - wide * 0.62),
		Vector2(at.x + wide * 0.5, at.y - wide * 1.15),
		Vector2(at.x + wide + 8.0, at.y - wide * 0.62),
	]), Color("c44536"))


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


func _banner(at: Vector2, color: Color) -> void:
	draw_line(Vector2(at.x, at.y), Vector2(at.x, at.y - 92.0), INK, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x, at.y - 88.0),
		Vector2(at.x + 36.0, at.y - 74.0),
		Vector2(at.x, at.y - 58.0),
	]), color)


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
	var monster: bool = false
	var clock: float = 0.0
	var phase_draw: String = "idle"
	var look: Dictionary = {}

	func setup(item: Dictionary) -> void:
		paint_id = str(item.get("id", "sword"))
		phase = str(item.get("phase", "idle"))
		phase_draw = "march" if phase == "walk" else phase
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
		Painter.paint_local(self, look, {
			"phase": phase_draw,
			"t": fmod(clock, 1.0),
			"clock": clock,
			"beat": beat,
			"flash": 0.0,
		})
