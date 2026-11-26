extends Control

signal finished

const Early = preload("res://scripts/early_roster.gd")
const Painter = preload("res://scripts/painter.gd")

var kind: String = "walker"
var clock: float = 0.0
var span: float = 5.6
var closed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var voice := Sfx.speak("demo_" + kind)
	span = maxf(5.6, voice + 0.45)
	if kind == "howler":
		span = maxf(6.8, voice + 0.45)


func _process(delta: float) -> void:
	if closed:
		return
	clock += delta
	if clock >= span:
		closed = true
		finished.emit()
		return
	queue_redraw()


func _span() -> Vector2:
	if size.x > 40.0 and size.y > 40.0:
		return size
	return get_viewport_rect().size


func _draw() -> void:
	var box := _span()
	var ground := box.y * 0.62
	draw_rect(Rect2(Vector2.ZERO, box), Color("161311"))
	draw_rect(Rect2(0, ground, box.x, box.y - ground), Color("2a241c"))
	draw_line(Vector2(36, ground), Vector2(box.x - 36, ground), Color("6b5344"), 4.0)
	var wall := box.x * 0.76
	draw_rect(Rect2(wall, ground - 168.0, 92.0, 168.0), Color("3a2c24"))
	draw_rect(Rect2(wall - 16.0, ground - 196.0, 124.0, 34.0), Color("2a211c"))
	var font := Tr.font()
	if font != null:
		draw_string(font, Vector2(40, 48), Tr.t(Early.name_of(kind)), HORIZONTAL_ALIGNMENT_LEFT, box.x - 80.0, 32, Color("f3e6c8"))
		if Tr.lang == "zh" or Tr.lang == "zh_cn":
			draw_multiline_string(font, Vector2(40, box.y - 148.0), Tr.t(Early.line(kind)), HORIZONTAL_ALIGNMENT_LEFT, box.x - 80.0, 20, 4, Color("f4efe4"))
		else:
			var y := box.y - 96.0
			for piece in Early.line(kind).split(". ", false):
				var shown := str(piece)
				if not shown.ends_with("."):
					shown += "."
				draw_string(font, Vector2(40, y), shown, HORIZONTAL_ALIGNMENT_LEFT, box.x - 80.0, 20, Color("f4efe4"))
				y += 26.0
	if kind == "howler":
		_draw_howler(box, ground, wall)
	else:
		_draw_hit(box, ground)


func _draw_howler(box: Vector2, ground: float, wall: float) -> void:
	var sword_x := box.x * 0.40
	if clock < 1.15:
		sword_x = lerpf(box.x * 0.26, box.x * 0.40, clock / 1.15)
	var hang_at := Vector2(wall + 24.0, ground - 86.0)
	var land := Vector2(sword_x + 42.0, ground)
	var howler_at := hang_at
	var howler_hang := 1.0
	var howler_phase := "idle"
	if clock >= 1.75 and clock < 2.75:
		var u := clampf((clock - 1.75) / 1.0, 0.0, 1.0)
		var crown := Vector2((hang_at.x + land.x) * 0.5, ground - 230.0)
		howler_at = _bez(hang_at, crown, land, u)
		howler_hang = 1.0 - u * 0.35
		howler_phase = "act"
	elif clock >= 2.75:
		howler_at = land
		howler_hang = 0.0
		howler_phase = "act" if clock < 3.15 else "idle"
	var sword_phase := "march"
	var sword_t := 0.4
	if clock >= 1.15 and clock < 1.9:
		sword_phase = "act"
		sword_t = clampf((clock - 1.15) / 0.75, 0.0, 1.0)
	elif clock >= 2.65 and clock < 4.5:
		sword_phase = "hurt"
		sword_t = 0.0
	elif clock >= 1.9:
		sword_phase = "idle"
	_actor(Painter.look("sword"), _pose(sword_phase, sword_t, clock), Vector2(sword_x, ground), 1.0, 2.7)
	_actor(Painter.look("howler"), _pose(howler_phase, 0.6, clock, howler_hang), howler_at, -1.0, 2.5)
	if clock >= 1.35 and clock < 2.05:
		var font := Tr.font()
		if font != null:
			draw_string(font, Vector2(sword_x - 20.0, ground - 150.0), Tr.t("miss"), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 22, Color("f0d2a0"))
	if clock >= 2.9:
		var archer_at := Vector2(box.x * 0.16, ground)
		var shot := "idle"
		var shot_t := 0.0
		if clock >= 3.35 and clock < 4.15:
			shot = "act"
			shot_t = clampf((clock - 3.35) / 0.8, 0.0, 1.0)
		_actor(Painter.look("archer"), _pose(shot, shot_t, clock), archer_at, 1.0, 2.7)
		var font2 := Tr.font()
		if font2 != null:
			draw_string(font2, Vector2(archer_at.x - 28.0, ground - 150.0), Tr.t("Archer"), HORIZONTAL_ALIGNMENT_LEFT, 140.0, 18, Color("d7ecd8"))
		if clock >= 3.7 and clock <= 4.45:
			var fly := clampf((clock - 3.7) / 0.55, 0.0, 1.0)
			var from := archer_at + Vector2(36.0, -48.0)
			var tip := from.lerp(howler_at + Vector2(0.0, -40.0), fly)
			draw_line(from, tip, Color("f2d38a"), 3.0)
			draw_circle(tip, 4.0, Color("fff6d2"))
			if fly > 0.92:
				draw_arc(howler_at + Vector2(0.0, -36.0), 18.0, 0.0, TAU, 16, Color("f3e6c8"), 3.0)


func _draw_hit(box: Vector2, ground: float) -> void:
	var sword_x := box.x * 0.36
	var foe_x := box.x * 0.70
	if clock < 1.45:
		foe_x = lerpf(box.x * 0.74, box.x * 0.50, clock / 1.45)
	else:
		foe_x = box.x * 0.50
	var foe_phase := "march"
	var foe_t := 0.3
	if clock >= 1.45 and clock < 2.25:
		foe_phase = "act"
		foe_t = clampf((clock - 1.45) / 0.8, 0.0, 1.0)
	elif clock >= 2.25:
		foe_phase = "idle"
	var sword_phase := "idle"
	var sword_t := 0.0
	if clock >= 2.15:
		if kind == "viper" or clock < 3.7:
			sword_phase = "hurt"
			sword_t = 0.0
	var foe_zoom := 2.7
	if kind == "oni" or kind == "shell" or kind == "boss" or kind == "glut":
		foe_zoom = 2.05
	elif kind == "ling":
		foe_zoom = 1.55
	var foe_y := ground
	if kind == "moth":
		foe_y = ground - 78.0
	_actor(Painter.look("sword"), _pose(sword_phase, sword_t, clock), Vector2(sword_x, ground), 1.0, 2.7)
	_actor(Painter.look(_face()), _pose(foe_phase, foe_t, clock), Vector2(foe_x, foe_y), -1.0, foe_zoom)
	if kind == "viper" and clock >= 2.2:
		draw_arc(Vector2(sword_x, ground - 48.0), 28.0, 0.4, TAU - 0.2, 18, Color(0.62, 0.9, 0.7, 0.55), 2.4)
	if kind == "storm" and clock >= 2.2 and clock < 4.2:
		var hop := clampf((clock - 2.2) / 1.6, 0.0, 1.0)
		var from := Vector2(foe_x - 10.0, ground - 90.0)
		var tip := from.lerp(Vector2(sword_x + 8.0, ground - 46.0), hop)
		var mid := from.lerp(tip, 0.5) + Vector2(0.0, -28.0)
		draw_line(from, mid, Color(0.62, 0.86, 1.0, 0.9), 3.0)
		draw_line(mid, tip, Color(1.0, 0.96, 0.78, 0.95), 2.2)
		draw_circle(tip, 5.0, Color("fff6d0"))


func _face() -> String:
	if kind == "boss":
		return "general"
	return kind


func _pose(phase: String, along: float, now: float, hang: float = 0.0) -> Dictionary:
	var beat := 0
	var t := along
	if phase == "act":
		beat = mini(3, int(along * 4.0))
		t = clampf(along * 4.0 - float(beat), 0.0, 1.0)
	return {
		"phase": phase,
		"t": t,
		"clock": now,
		"flash": 0.0,
		"beat": beat,
		"hang": hang,
	}


func _actor(look: Dictionary, pose: Dictionary, at: Vector2, face: float, zoom: float) -> void:
	draw_set_transform(at, 0.0, Vector2(face * zoom, zoom))
	Painter.paint_local(self, look, pose)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _bez(a: Vector2, b: Vector2, c: Vector2, u: float) -> Vector2:
	var omu := 1.0 - u
	return a * omu * omu + b * 2.0 * omu * u + c * u * u
