extends Control

# First-time skill unlock. Holds the choice screen for a short reward, then finishes.
# Rank raises and coin upgrades never open this.

const Stamp = preload("res://scripts/stamp_bake.gd")

signal finished

var skill_id: String = ""
var skill_title: String = ""
var age: float = 0.0
var ended: bool = false
var chimed: bool = false

const SPAN := 1.95
const POP := 0.58
const SETTLE := 0.24


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fill()
	_chime()


func _process(delta: float) -> void:
	if ended:
		return
	_fill()
	var step: float = delta
	if step > 0.05:
		step = 0.05
	age += step
	if age >= SPAN:
		_end()
		return
	queue_redraw()


func _chime() -> void:
	if chimed:
		return
	chimed = true
	Sfx.play("skill_reward", 1.0, -5.0)


func _end() -> void:
	if ended:
		return
	ended = true
	finished.emit()
	queue_free()


func _fill() -> void:
	var want := get_viewport_rect().size
	var parent_control: Control = get_parent() as Control
	if parent_control != null and parent_control.size.x > 20.0 and parent_control.size.y > 20.0:
		want = parent_control.size
	if want.x < 20.0 or want.y < 20.0:
		return
	if absf(size.x - want.x) < 2.0 and absf(size.y - want.y) < 2.0 and absf(position.x) < 1.0 and absf(position.y) < 1.0:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = want


func _draw() -> void:
	Stamp.ensure()
	var box := _box()
	var fade := _fade()
	var mid := box * 0.5
	var emblem_at := mid + Vector2(0.0, -28.0)
	_flash(box, fade)
	_rings(emblem_at, fade)
	_emblem(emblem_at, _emblem_scale(), fade)
	_motes(emblem_at, fade)
	_title(Vector2(mid.x, mid.y + 78.0), fade)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _box() -> Vector2:
	if size.x >= 20.0 and size.y >= 20.0:
		return size
	return get_viewport_rect().size


func _fade() -> float:
	var tail := SPAN - 0.34
	if age <= tail:
		return 1.0
	return clampf(1.0 - (age - tail) / 0.34, 0.0, 1.0)


func _emblem_scale() -> float:
	var rise := POP
	var settle_at := POP + SETTLE
	if age < rise:
		var rise_u := clampf(age / rise, 0.0, 1.0)
		var rise_ease := 1.0 - pow(1.0 - rise_u, 3.0)
		return lerpf(0.08, 1.16, rise_ease)
	if age < settle_at:
		var settle_u := clampf((age - rise) / SETTLE, 0.0, 1.0)
		var settle_ease := settle_u * settle_u * (3.0 - 2.0 * settle_u)
		return lerpf(1.16, 1.0, settle_ease)
	return 1.0


func _hot() -> Color:
	match skill_id:
		"ls":
			return Color(1.0, 0.92, 0.62)
		"fz":
			return Color(0.62, 0.86, 1.0)
		"en":
			return Color(1.0, 0.38, 0.06)
		_:
			return Color(1.0, 0.46, 0.05)


func _core() -> Color:
	match skill_id:
		"ls":
			return Color(1.0, 0.98, 0.92)
		"fz":
			return Color(0.9, 0.97, 1.0)
		"en":
			return Color(1.0, 0.78, 0.28)
		_:
			return Color(1.0, 0.84, 0.38)


func _flash(box: Vector2, fade: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, box), Color(0.03, 0.015, 0.04, 0.62 * fade))
	var burst := 0.0
	if age < 0.26:
		burst = pow(1.0 - age / 0.26, 2.0)
	if burst > 0.01:
		draw_rect(Rect2(Vector2.ZERO, box), Color(1.0, 0.99, 0.96, burst * 0.92))
	var wash := _hot()
	wash.a = pow(1.0 - clampf(age / 0.72, 0.0, 1.0), 2.0) * 0.3 * fade
	if wash.a > 0.015:
		draw_rect(Rect2(Vector2.ZERO, box), wash)


func _rings(at: Vector2, fade: float) -> void:
	var hot := _hot()
	var band_i := 0
	while band_i < 3:
		var start := 0.02 + float(band_i) * 0.12
		var along := clampf((age - start) / 0.9, 0.0, 1.0)
		if age >= start:
			var radius := lerpf(20.0, 250.0 + float(band_i) * 36.0, along)
			var band := hot
			band.a = (1.0 - along) * 0.9 * fade
			Stamp.ring(self, at, radius, band)
		band_i += 1


func _motes(at: Vector2, fade: float) -> void:
	var hot := _hot()
	var core := _core()
	var n := 0
	while n < 10:
		var ang := TAU * float(n) / 10.0 - age * 0.4
		var travel := clampf((age - 0.04) / 1.1, 0.0, 1.0)
		var dist := lerpf(16.0, 150.0 + float(n % 4) * 26.0, 1.0 - pow(1.0 - travel, 2.0))
		var spot := at + Vector2(cos(ang) * dist, sin(ang) * dist * 0.76)
		var rad := lerpf(6.2, 1.6, travel)
		var tint: Color = hot
		if n % 2 == 0:
			tint = core
		tint.a = (1.0 - travel) * 0.95 * fade
		if travel > 0.0 and tint.a > 0.02:
			Stamp.disc(self, spot, rad, tint)
		n += 1


func _emblem(at: Vector2, emblem_scale: float, fade: float) -> void:
	var hot := _hot()
	var core := _core()
	core.a = fade
	var glow := hot
	glow.a = 0.22 * fade
	var fill := hot.darkened(0.18)
	fill.a = 0.96 * fade
	var rim := core
	rim.a = 0.92 * fade
	var body := hot
	body.a = fade
	draw_set_transform(at, 0.0, Vector2(emblem_scale, emblem_scale))
	Stamp.disc(self, Vector2.ZERO, 108.0, glow)
	Stamp.ring(self, Vector2.ZERO, 78.0, body)
	Stamp.disc(self, Vector2.ZERO, 62.0, fill)
	Stamp.ring(self, Vector2.ZERO, 52.0, rim)
	Stamp.disc(self, Vector2(-12.0, -14.0), 20.0, Color(core.r, core.g, core.b, 0.9 * fade))
	if skill_id == "ls":
		_arc(Stamp.arc_ls, 58.0, -0.5, core, at, emblem_scale)
		_arc(Stamp.arc_ls, 46.0, 2.2, rim, at, emblem_scale)
	elif skill_id == "fz":
		_arc(Stamp.arc_fz, 54.0, 0.4, core, at, emblem_scale)
		draw_set_transform(at, 0.0, Vector2(emblem_scale, emblem_scale))
		Stamp.disc(self, Vector2.ZERO, 16.0, Color(0.95, 0.99, 1.0, fade))
	elif skill_id == "en":
		var climb := lerpf(28.0, 112.0, 1.0 - pow(1.0 - clampf(age / 0.9, 0.0, 1.0), 3.0))
		Stamp.paint_flame(self, Vector2(0.0, 34.0), climb, false)
		Stamp.paint_flame(self, Vector2(-22.0, 40.0), climb * 0.72, true)
		Stamp.paint_flame(self, Vector2(22.0, 40.0), climb * 0.66, true)
	else:
		Stamp.paint_flame(self, Vector2(-18.0, 24.0), 52.0, true)
		Stamp.paint_flame(self, Vector2(18.0, 26.0), 46.0, true)
		Stamp.disc(self, Vector2.ZERO, 16.0, Color(1.0, 0.96, 0.82, fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _arc(tex: Texture2D, radius: float, spin: float, tint: Color, at: Vector2, emblem_scale: float) -> void:
	if tex == null:
		return
	var side := radius / 40.0 * float(tex.get_width())
	draw_set_transform(at, spin, Vector2(emblem_scale, emblem_scale))
	draw_texture_rect(tex, Rect2(-side * 0.5, -side * 0.5, side, side), false, tint)


func _title(anchor: Vector2, fade: float) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var shown := skill_title
	if shown == "":
		shown = "Skill"
	var arrive := clampf(age / 0.2, 0.0, 1.0) * fade
	if arrive <= 0.02:
		return
	var name_px := 68
	var wide := _box().x
	var name_size := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px)
	while name_size.x > wide - 72.0 and name_px > 36:
		name_px -= 2
		name_size = font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px)
	var caption := "Unlocked"
	var cap_px := 28
	var cap_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_px)
	var plate_w := maxf(name_size.x, cap_size.x) + 64.0
	var plate_h := float(cap_px + name_px) + 40.0
	var plate_at := Vector2(anchor.x - plate_w * 0.5, anchor.y)
	draw_rect(Rect2(plate_at, Vector2(plate_w, plate_h)), Color(0.07, 0.035, 0.025, 0.8 * arrive))
	var edge := _hot()
	edge.a = 0.95 * arrive
	draw_rect(Rect2(plate_at, Vector2(plate_w, plate_h)), edge, false, 3.0)
	var cap_ink := _core()
	cap_ink.a = arrive
	var cap_pos := Vector2(anchor.x - cap_size.x * 0.5, plate_at.y + float(cap_px) + 10.0)
	draw_string(font, cap_pos + Vector2(1.0, 2.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_px, Color(0.12, 0.05, 0.03, arrive))
	draw_string(font, cap_pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_px, cap_ink)
	var name_ink := Color(1.0, 0.98, 0.94, arrive)
	var name_pos := Vector2(anchor.x - name_size.x * 0.5, cap_pos.y + float(name_px) + 6.0)
	draw_string(font, name_pos + Vector2(2.0, 3.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px, Color(0.14, 0.05, 0.03, arrive))
	draw_string(font, name_pos, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px, name_ink)
