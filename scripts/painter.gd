extends RefCounted


static func look(kind: String) -> Dictionary:
	match kind:
		"sword":
			return _look(Color("f0c9a0"), Color("7f95ad"), Color("e8eef5"), "katana", false)
		"archer":
			return _look(Color("f0c9a0"), Color("3f6b45"), Color("d7e6c8"), "bow", false)
		"shield":
			return _look(Color("f0c9a0"), Color("8d5a32"), Color("e6c36a"), "shield", false)
		"saber":
			return _look(Color("f0c9a0"), Color("8d2430"), Color("f2d2d2"), "nodachi", false)
		"lancer":
			return _look(Color("f0c9a0"), Color("343e78"), Color("d5daf5"), "spear", false)
		"berserker":
			return _look(Color("e7b090"), Color("a34422"), Color("f0c36a"), "axe", false)
		"horse":
			return _look(Color("f0c9a0"), Color("7a2e2e"), Color("e6c36a"), "katana", true)
		"suicide":
			return _look(Color("e7c2a4"), Color("2a2428"), Color("e24b3b"), "bomb", false)
		"assassin":
			return _look(Color("c9b8d4"), Color("4c3560"), Color("d7c4ff"), "dagger", false)
		"heal":
			return _look(Color("f0c9a0"), Color("e7f3ee"), Color("7ec8b3"), "staff", false)
		"level":
			return _look(Color("f0c9a0"), Color("f4e2b0"), Color("a56b2b"), "scroll", false)
		"hero":
			return _look(Color("f3d2b0"), Color("f7f1df"), Color("c44536"), "katana", false)
		"walker":
			return _look(Color("8ea86a"), Color("4d5a42"), Color("d7e0b0"), "claws", false)
		"runner":
			return _look(Color("c5d39a"), Color("5d6848"), Color("f0f0c8"), "claws", false)
		"brute":
			return _look(Color("6f8a58"), Color("2d382c"), Color("9aa888"), "club", false)
		"spitter":
			return _look(Color("b7c96a"), Color("556338"), Color("d6ef78"), "spit", false)
		"bomber":
			return _look(Color("9aaa72"), Color("3a4034"), Color("e24b3b"), "bomb", false)
		"oni":
			return _look(Color("7f9a68"), Color("3a2748"), Color("e6c36a"), "oni", false)
		_:
			return _look(Color("f0c9a0"), Color("666666"), Color("ffffff"), "katana", false)


static func _look(skin: Color, cloth: Color, trim: Color, weapon: String, mount: bool) -> Dictionary:
	return {"skin": skin, "cloth": cloth, "trim": trim, "weapon": weapon, "mount": mount}


static func paint_local(ci: CanvasItem, look: Dictionary, attacking: bool, flash: float) -> void:
	var skin: Color = look["skin"]
	var cloth: Color = look["cloth"]
	var trim: Color = look["trim"]
	if flash > 0.0:
		skin = skin.lerp(Color.WHITE, 0.72)
		cloth = cloth.lerp(Color.WHITE, 0.72)
		trim = trim.lerp(Color.WHITE, 0.72)
	var mount: bool = look["mount"]
	var lift := -16.0 if mount else 0.0
	_ellipse(ci, Vector2(0, 22), 16, 5, Color(0, 0, 0, 0.35))
	if mount:
		_horse(ci, cloth, trim)
	if not mount:
		ci.draw_line(Vector2(-5, 8), Vector2(-7, 20), cloth.darkened(0.2), 3.0)
		ci.draw_line(Vector2(4, 8), Vector2(6, 20), cloth.darkened(0.2), 3.0)
	_ellipse(ci, Vector2(0, lift), 11, 14, Color(0.05, 0.04, 0.04))
	_ellipse(ci, Vector2(0, lift), 9, 12, cloth)
	_ellipse(ci, Vector2(0, lift - 16), 8, 8, Color(0.05, 0.04, 0.04))
	_ellipse(ci, Vector2(0, lift - 16), 6.5, 6.5, skin)
	ci.draw_circle(Vector2(3.1, lift - 17), 1.15, Color(0.12, 0.08, 0.08))
	_weapon(ci, str(look["weapon"]), trim, cloth, attacking, lift)
	if str(look["weapon"]) == "oni":
		ci.draw_line(Vector2(-3, lift - 22), Vector2(-7, lift - 30), trim, 2.2)
		ci.draw_line(Vector2(3, lift - 22), Vector2(7, lift - 30), trim, 2.2)


static func _weapon(ci: CanvasItem, weapon: String, trim: Color, cloth: Color, attacking: bool, lift: float) -> void:
	var reach := 18.0 if attacking else 12.0
	match weapon:
		"katana", "dagger":
			var length := 16.0 if weapon == "dagger" else 24.0
			ci.draw_line(Vector2(6, lift - 2), Vector2(6 + length, lift - reach), trim.lightened(0.2), 2.4)
			ci.draw_line(Vector2(5, lift - 1), Vector2(9, lift - 1), cloth.darkened(0.3), 2.0)
		"nodachi":
			ci.draw_line(Vector2(6, lift), Vector2(30, lift - reach - 4), trim, 3.0)
		"bow":
			ci.draw_arc(Vector2(10, lift - 2), 13, -1.15, 1.15, 10, trim, 2.2)
			ci.draw_line(Vector2(10, lift - 14), Vector2(10, lift + 10), Color("f3e6c8"), 1.2)
		"shield":
			_round_rect(ci, Rect2(8, lift - 14, 16, 26), trim)
			_round_rect(ci, Rect2(11, lift - 10, 10, 18), cloth.lightened(0.08))
			ci.draw_line(Vector2(4, lift + 2), Vector2(18, lift - 12), Color("f4f1ea"), 2.2)
		"spear":
			ci.draw_line(Vector2(2, lift + 6), Vector2(34, lift - 14), Color("c8b48a"), 2.4)
			draw_tip(ci, Vector2(34, lift - 14), trim)
		"axe":
			ci.draw_line(Vector2(4, lift + 8), Vector2(16, lift - 16), Color("c8b48a"), 3.0)
			_ellipse(ci, Vector2(18, lift - 16), 8, 7, trim)
		"bomb":
			_ellipse(ci, Vector2(12, lift - 2), 7, 7, Color(0.1, 0.08, 0.08))
			ci.draw_circle(Vector2(12, lift - 2), 3.0, trim)
			ci.draw_line(Vector2(16, lift - 8), Vector2(20, lift - 14), Color("e6c36a"), 1.6)
		"staff":
			ci.draw_line(Vector2(8, lift + 12), Vector2(8, lift - 24), Color("c8b48a"), 2.4)
			ci.draw_circle(Vector2(8, lift - 26), 4.0, trim)
		"scroll":
			_round_rect(ci, Rect2(6, lift - 10, 14, 16), trim)
			ci.draw_line(Vector2(9, lift - 4), Vector2(17, lift - 4), cloth.darkened(0.35), 1.2)
			ci.draw_line(Vector2(9, lift + 1), Vector2(16, lift + 1), cloth.darkened(0.35), 1.2)
		"claws":
			ci.draw_line(Vector2(8, lift - 2), Vector2(16, lift - 8), trim, 1.8)
			ci.draw_line(Vector2(8, lift + 1), Vector2(17, lift - 1), trim, 1.8)
			ci.draw_line(Vector2(8, lift + 4), Vector2(16, lift + 6), trim, 1.8)
		"club":
			ci.draw_line(Vector2(6, lift + 6), Vector2(18, lift - 12), Color("6b4a32"), 4.0)
			_ellipse(ci, Vector2(20, lift - 14), 6, 5, trim.darkened(0.1))
		"spit":
			ci.draw_circle(Vector2(12, lift - 4), 4.0, trim)
		"oni":
			ci.draw_line(Vector2(4, lift + 4), Vector2(20, lift - 10), Color("6b4a32"), 4.0)
			_ellipse(ci, Vector2(22, lift - 8), 7, 6, trim)


static func draw_tip(ci: CanvasItem, at: Vector2, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-2, 3),
		at + Vector2(8, -2),
		at + Vector2(-2, -5),
	]), color)


static func _horse(ci: CanvasItem, cloth: Color, trim: Color) -> void:
	var body := Color("6b442c")
	_ellipse(ci, Vector2(-2, 10), 18, 8, body)
	_ellipse(ci, Vector2(14, 4), 7, 6, body.lightened(0.08))
	ci.draw_line(Vector2(-12, 14), Vector2(-14, 22), body.darkened(0.15), 2.5)
	ci.draw_line(Vector2(-4, 16), Vector2(-3, 22), body.darkened(0.15), 2.5)
	ci.draw_line(Vector2(6, 16), Vector2(8, 22), body.darkened(0.15), 2.5)
	ci.draw_line(Vector2(12, 12), Vector2(16, 22), body.darkened(0.15), 2.5)
	ci.draw_line(Vector2(18, 2), Vector2(24, -2), trim, 2.0)


static func _ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 12
	for i in segs:
		var angle := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	ci.draw_colored_polygon(pts, color)


static func _round_rect(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	ci.draw_rect(rect, color)
