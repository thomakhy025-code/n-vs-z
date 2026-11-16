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
	var full := str(row.get("caption", "")) + str(row.get("speech", ""))
	return maxf(0.35, float(full.length()) / 48.0)


func _show_panel() -> void:
	clock = 0.0
	var place := str(panels[index].get("place", "mountain"))
	Sfx.mood(place)
	Sfx.play("story_breath", _mood_pitch(place), -16.0)
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
	var sky_top := Color("efe6d4")
	var sky_low := Color("d9cbb4")
	var earth := Color("4a4034")
	match place:
		"village":
			sky_top = Color("f0d7b0")
			sky_low = Color("e2b7a0")
			earth = Color("6a5340")
		"night":
			sky_top = Color("12141f")
			sky_low = Color("2a3148")
			earth = Color("12141c")
		"cliff":
			sky_top = Color("d5e4ef")
			sky_low = Color("f7f1df")
			earth = Color("5c564c")
		"war":
			sky_top = Color("8e9a9a")
			sky_low = Color("c4b4a4")
			earth = Color("3d3832")
		"banners":
			sky_top = Color("f3e2c8")
			sky_low = Color("e4c4a4")
			earth = Color("5a4636")
		"climb":
			sky_top = Color("e7eef2")
			sky_low = Color("c5d0d4")
			earth = Color("5d675c")
		"camp":
			sky_top = Color("f0c49a")
			sky_low = Color("c47a62")
			earth = Color("3e342c")
		"mountain":
			sky_top = Color("d7e4ee")
			sky_low = Color("f4efe4")
			earth = Color("6a6258")
		_:
			sky_top = Color("efe6d4")
			sky_low = Color("d7cbb6")
	_bands(rect, sky_top, sky_low, ground_y)
	draw_rect(Rect2(rect.position.x, ground_y, rect.size.x, rect.end.y - ground_y), earth)
	if place == "village":
		_house(rect.position + Vector2(rect.size.x * 0.46, ground_y), 168.0, true)
		_house(rect.position + Vector2(rect.size.x * 0.7, ground_y), 128.0, false)
		_fence(rect.position + Vector2(rect.size.x * 0.18, ground_y), rect.size.x * 0.28)
		_lantern(rect.position + Vector2(rect.size.x * 0.5, ground_y), time)
		_path(rect, ground_y)
		draw_rect(Rect2(rect.position.x, ground_y - 10.0, rect.size.x * 0.42, 16.0), Color(0.55, 0.62, 0.72, 0.16))
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.52, ground_y - 8.0, rect.size.x * 0.46, 14.0), Color(0.95, 0.55, 0.22, 0.14))
	elif place == "climb":
		_peak(rect, ground_y, 0.16, 130.0)
		_peak(rect, ground_y, 0.4, 190.0)
		_peak(rect, ground_y, 0.72, 150.0)
		_pine(rect.position + Vector2(rect.size.x * 0.22, ground_y), 70.0)
		_pine(rect.position + Vector2(rect.size.x * 0.84, ground_y), 92.0)
		_mist(rect, ground_y, time, 0.28)
		_steps(rect, ground_y)
	elif place == "mountain":
		_peak(rect, ground_y, 0.18, 170.0)
		_peak(rect, ground_y, 0.46, 240.0)
		_peak(rect, ground_y, 0.74, 180.0)
		_cairn(rect.position + Vector2(rect.size.x * 0.62, ground_y))
		_cloud(rect, time)
		_wind(rect, ground_y, time)
	elif place == "camp":
		_peak(rect, ground_y, 0.2, 120.0)
		_peak(rect, ground_y, 0.78, 140.0)
		_tent(rect.position + Vector2(rect.size.x * 0.22, ground_y))
		_fire(rect.position + Vector2(rect.size.x * 0.62, ground_y), time)
		_stones(rect.position + Vector2(rect.size.x * 0.62, ground_y))
		draw_circle(rect.position + Vector2(rect.size.x * 0.62, ground_y - 6.0), 54.0, Color(1.0, 0.55, 0.22, 0.08))
	elif place == "night":
		_stars(rect, time)
		draw_circle(rect.position + Vector2(rect.size.x * 0.78, 54.0), 18.0, Color("f7f1df"))
		draw_circle(rect.position + Vector2(rect.size.x * 0.78, 54.0), 28.0, Color(1, 1, 0.9, 0.08))
		_peak(rect, ground_y, 0.18, 110.0)
		_peak(rect, ground_y, 0.58, 150.0)
		draw_rect(Rect2(rect.position.x + 12.0, ground_y - 8.0, rect.size.x - 24.0, 7.0), Color(0.75, 0.8, 0.92, 0.1))
		_mist(rect, ground_y, time, 0.45)
	elif place == "cliff":
		var drop_x := rect.position.x + rect.size.x * 0.6
		draw_rect(Rect2(drop_x, rect.position.y, rect.end.x - drop_x, rect.end.y - rect.position.y), Color("d5e4ef"))
		var valley_y := rect.end.y - 36.0
		draw_rect(Rect2(drop_x + 28.0, valley_y, rect.end.x - drop_x - 28.0, rect.end.y - valley_y), Color("8a9a78"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(drop_x - 8.0, ground_y),
			Vector2(drop_x + 36.0, valley_y),
			Vector2(drop_x - 20.0, rect.end.y),
			Vector2(drop_x - 70.0, rect.end.y),
		]), Color("5c564c"))
		var face := int((valley_y - ground_y) / 14.0)
		for i in face:
			var y := ground_y + 12.0 + float(i) * 14.0
			draw_line(Vector2(drop_x - 36.0, y), Vector2(drop_x + 10.0, y + 6.0), Color("3e3832"), 2.0)
		_far_village(Vector2(drop_x + rect.size.x * 0.12, valley_y))
		_wind(rect, ground_y, time)
	elif place == "war":
		_smoke(rect, ground_y, time)
		_banner(rect.position + Vector2(rect.size.x * 0.18, ground_y), Color("3d4634"), time)
		_banner(rect.position + Vector2(rect.size.x * 0.78, ground_y), Color("8d2f28"), time + 0.6)
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 20.0), Vector2(rect.position.x + rect.size.x * 0.5, ground_y), Color(0.1, 0.08, 0.06, 0.35), 2.0)
	elif place == "banners":
		_banner(rect.position + Vector2(rect.size.x * 0.62, ground_y), Color("c44536"), time)
		_banner(rect.position + Vector2(rect.size.x * 0.78, ground_y), Color("8d2f28"), time + 0.4)
		_banner(rect.position + Vector2(rect.size.x * 0.9, ground_y), Color("c4a574"), time + 0.9)
		_dust(rect, ground_y, time)
	else:
		_lane_marks(rect, ground_y)
		_gate_far(rect.position + Vector2(rect.size.x * 0.86, ground_y))
	_vignette(rect)
	_frame(rect)


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
		"village":
			return 0.82
		"night", "banners":
			return 0.7
		"war":
			return 0.64
		"cliff", "mountain":
			return 1.12
		"camp":
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
