extends RefCounted

static var _tilt: float = 0.0


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


static func call_id(paint: String) -> String:
	match paint:
		"archer":
			return "call_bow"
		"shield":
			return "call_shield"
		"lancer":
			return "call_spear"
		"berserker", "brute":
			return "call_heavy"
		"horse":
			return "call_horse"
		"suicide", "bomber":
			return "call_bomb"
		"assassin":
			return "call_dagger"
		"heal", "level":
			return "call_magic"
		"walker", "runner", "spitter":
			return "call_dead"
		"oni":
			return "call_oni"
		"hero":
			return "call_hero"
		_:
			return "call_blade"


static func hit_id(weapon: String) -> String:
	match weapon:
		"bow":
			return "hit_bow"
		"shield", "axe", "club", "oni", "bomb":
			return "hit_blunt"
		"spear":
			return "hit_pierce"
		"staff", "scroll":
			return "hit_magic"
		"claws", "spit":
			return "hit_claw"
		_:
			return "hit_blade"


static func call_pitch(paint: String) -> float:
	match paint:
		"saber":
			return 0.9
		"runner":
			return 1.16
		"spitter":
			return 1.08
		"bomber":
			return 0.92
		"brute":
			return 0.86
		"walker":
			return 0.94
		_:
			return 1.0


static func _look(skin: Color, cloth: Color, trim: Color, weapon: String, mount: bool) -> Dictionary:
	return {"skin": skin, "cloth": cloth, "trim": trim, "weapon": weapon, "mount": mount}


static func paint_local(ci: CanvasItem, look: Dictionary, pose: Dictionary) -> void:
	var phase := str(pose.get("phase", "idle"))
	var t := float(pose.get("t", 0.0))
	var clock := float(pose.get("clock", 0.0))
	var flash := float(pose.get("flash", 0.0))
	var skin: Color = look["skin"]
	var cloth: Color = look["cloth"]
	var trim: Color = look["trim"]
	if flash > 0.0:
		var wash := clampf(flash * 4.0, 0.0, 0.72)
		skin = skin.lerp(Color.WHITE, wash)
		cloth = cloth.lerp(Color.WHITE, wash)
		trim = trim.lerp(Color.WHITE, wash)
	var motion := _motion(phase, t, clock)
	var lean := float(motion["lean"])
	var squat := float(motion["squat"])
	var arm := float(motion["arm"])
	var step := float(motion["step"])
	var breath := float(motion["breath"])
	var rise := float(motion["rise"])
	var mount: bool = look["mount"]
	var lift := -18.0 if mount else -2.0
	var drop := squat + rise
	var ground := 18.0 + rise * 0.35
	var chest := Vector2(lean + 1.0, lift + drop - breath)
	var weapon := str(look["weapon"])
	_tilt = 0.0
	_ellipse(ci, Vector2(lean * 0.2, 22.0), 16.0 + abs(step) * 3.0, 4.2, Color(0, 0, 0, 0.32))
	if phase == "strike":
		_ellipse(ci, Vector2(8.0 + t * 10.0, 21.0), 7.0, 2.2, Color(1, 0.94, 0.82, 0.28 * (1.0 - t)))
	_tilt = float(motion["tilt"])
	if mount:
		_horse(ci, cloth, trim, step, drop)
	_cape(ci, chest, weapon, cloth, arm)
	if not mount:
		_leg(ci, chest + Vector2(-3.5, 12.0), Vector2(-5.0 - step * 11.0, ground), cloth.darkened(0.34), 3.2)
	_torso(ci, chest, cloth, trim, weapon)
	if not mount:
		_leg(ci, chest + Vector2(3.0, 12.0), Vector2(6.0 + step * 12.0, ground), cloth.darkened(0.08), 3.5)
	_head(ci, chest + Vector2(1.6, -16.0), skin, cloth, trim, weapon, phase)
	var grip := _grip(chest, arm)
	_arm(ci, chest + Vector2(-4.0, -1.0), grip + Vector2(-8.0, 6.0), skin, cloth.darkened(0.22), 2.5)
	_arm(ci, chest + Vector2(5.0, -4.0), grip, skin, cloth, 2.9)
	_weapon_at(ci, weapon, grip, trim, cloth, arm, phase)
	if phase == "strike":
		var alpha := (1.0 - t) * 0.85
		var sweep := Color(trim.r, trim.g, trim.b, alpha)
		_arc(ci, grip, 18.0 + t * 22.0, -1.35, 1.05, 16, sweep, 3.4)
		_arc(ci, grip, 11.0 + t * 14.0, -1.05, 0.7, 12, Color(1, 0.97, 0.88, alpha), 1.7)
	_tilt = 0.0


static func _motion(phase: String, t: float, clock: float) -> Dictionary:
	var lean := 0.0
	var squat := 0.0
	var arm := 0.35
	var step := sin(clock * 1.7) * 0.15
	var breath := sin(clock * 2.1) * 0.8
	var rise := 0.0
	var tilt := 0.04 + sin(clock * 1.7) * 0.03
	match phase:
		"debut":
			rise = (1.0 - t) * 22.0
			squat = (1.0 - t) * 8.0
			arm = lerpf(-0.55, 0.4, t)
			step = lerpf(0.7, 0.0, t)
			tilt = lerpf(0.35, 0.0, t)
			breath = 0.0
		"march":
			step = sin(clock * 8.0)
			lean = 4.0
			squat = absf(step) * 2.2
			arm = 0.22 + step * 0.16
			breath = 0.25
			tilt = 0.2 + step * 0.05
		"windup":
			lean = lerpf(0.0, -6.0, t)
			squat = lerpf(0.0, 7.0, t)
			arm = lerpf(0.35, -0.85, t)
			step = lerpf(0.0, -1.05, t)
			tilt = lerpf(0.08, -0.55, t)
			breath = 0.0
		"strike":
			var snap := 1.0 - pow(1.0 - t, 2.6)
			lean = lerpf(-6.0, 9.0, snap)
			squat = lerpf(7.0, 0.2, snap)
			arm = lerpf(-0.85, 1.5, snap)
			step = lerpf(-1.05, 1.35, snap)
			tilt = lerpf(-0.55, 0.62, snap)
			breath = 0.0
		"recover":
			lean = lerpf(9.0, 1.0, t)
			squat = lerpf(0.2, 0.0, t)
			arm = lerpf(1.5, 0.35, t)
			step = lerpf(1.35, 0.0, t)
			tilt = lerpf(0.62, 0.06, t)
		"hurt":
			lean = lerpf(-2.0, 0.0, t)
			squat = lerpf(5.0, 0.0, t)
			arm = lerpf(-0.15, 0.3, t)
			step = lerpf(-0.7, 0.0, t)
			tilt = lerpf(-0.62, 0.0, t)
			breath = 0.0
		"cast":
			lean = -1.0
			arm = 0.85 + sin(clock * 4.5) * 0.22
			rise = sin(clock * 3.0) * 2.0
			step = sin(clock * 2.0) * 0.2
			tilt = -0.22 + sin(clock * 2.4) * 0.06
		"fall":
			squat = lerpf(2.0, 18.0, t)
			lean = lerpf(0.0, 10.0, t)
			arm = lerpf(0.35, 1.15, t)
			step = lerpf(0.0, 1.1, t)
			tilt = lerpf(0.0, 1.25, t)
			breath = 0.0
	return {
		"lean": lean,
		"squat": squat,
		"arm": arm,
		"step": step,
		"breath": breath,
		"rise": rise,
		"tilt": tilt,
	}


static func _cape(ci: CanvasItem, chest: Vector2, weapon: String, cloth: Color, arm: float) -> void:
	var trail := 10.0 + maxf(0.0, arm) * 8.0 + maxf(0.0, _tilt) * 14.0
	var hem := chest + Vector2(-16.0 - trail * 0.35, 22.0)
	var back := cloth.darkened(0.45)
	if weapon == "claws" or weapon == "spit":
		back = cloth.darkened(0.18)
		hem = chest + Vector2(-9.0, 15.0)
		trail = 4.0
	_poly(ci, PackedVector2Array([
		chest + Vector2(-6.0, -4.0),
		chest + Vector2(-14.0, 4.0),
		hem,
		chest + Vector2(-2.0, 15.0),
	]), back)
	_poly(ci, PackedVector2Array([
		chest + Vector2(-4.0, -6.0),
		chest + Vector2(-8.0 - trail * 0.15, 2.0),
		chest + Vector2(-6.0, 12.0),
	]), cloth.darkened(0.22))


static func _torso(ci: CanvasItem, chest: Vector2, cloth: Color, trim: Color, weapon: String) -> void:
	_ellipse(ci, chest + Vector2(-6.2, 3.2), 11.2, 14.2, cloth.darkened(0.46))
	_ellipse(ci, chest + Vector2(0.4, 1.0), 8.6, 12.4, cloth)
	_ellipse(ci, chest + Vector2(6.4, -1.4), 5.0, 8.4, cloth.lightened(0.24))
	_line(ci, chest + Vector2(-2.0, -7.0), chest + Vector2(7.0, 9.0), trim, 1.8)
	_line(ci, chest + Vector2(-1.0, 6.0), chest + Vector2(6.0, 6.5), trim, 1.5)
	if weapon == "shield" or weapon == "axe":
		_ellipse(ci, chest + Vector2(8.0, -5.0), 5.2, 3.6, trim)
	elif weapon == "nodachi":
		_line(ci, chest + Vector2(-3.0, -9.0), chest + Vector2(5.0, -9.0), trim, 2.6)


static func _head(ci: CanvasItem, at: Vector2, skin: Color, cloth: Color, trim: Color, weapon: String, phase: String) -> void:
	_ellipse(ci, at + Vector2(-5.4, 0.8), 7.4, 7.6, cloth.darkened(0.48))
	_ellipse(ci, at + Vector2(-1.0, 0.3), 6.6, 7.0, skin.darkened(0.16))
	_ellipse(ci, at + Vector2(3.6, -0.4), 4.6, 5.8, skin.lightened(0.06))
	_line(ci, at + Vector2(6.2, -0.6), at + Vector2(9.4, 1.2), skin.darkened(0.18), 2.0)
	var eye := Color(0.1, 0.07, 0.06)
	if weapon == "claws" or weapon == "spit" or weapon == "club" or weapon == "oni":
		eye = Color(0.85, 0.95, 0.55)
	if phase == "hurt" or phase == "fall":
		_line(ci, at + Vector2(3.2, -2.2), at + Vector2(5.4, -0.4), eye, 1.5)
		_line(ci, at + Vector2(3.2, -0.2), at + Vector2(5.4, -1.8), eye, 1.5)
	elif phase == "windup":
		_dot(ci, at + Vector2(3.8, -2.2), 1.25, eye)
	else:
		_dot(ci, at + Vector2(4.0, -1.8), 1.25, eye)
	_mark(ci, at, cloth, trim, weapon)


static func _mark(ci: CanvasItem, at: Vector2, cloth: Color, trim: Color, weapon: String) -> void:
	match weapon:
		"katana", "nodachi", "dagger":
			_line(ci, at + Vector2(-5.0, -6.2), at + Vector2(5.5, -6.4), trim, 2.4)
		"bow":
			_ellipse(ci, at + Vector2(-1.5, -1.2), 7.6, 8.0, cloth.darkened(0.25))
			_ellipse(ci, at + Vector2(3.2, -0.8), 3.8, 4.6, Color("f0c9a0"))
		"spear":
			_line(ci, at + Vector2(-1.0, -7.0), at + Vector2(-1.0, -14.0), trim, 2.2)
			draw_tip(ci, at + Vector2(-1.0, -14.0), trim)
		"axe":
			_line(ci, at + Vector2(-4.0, -5.5), at + Vector2(0.0, -12.0), trim, 2.4)
			_line(ci, at + Vector2(3.0, -5.5), at + Vector2(6.0, -11.0), trim, 2.4)
		"oni":
			_line(ci, at + Vector2(-3.0, -6.0), at + Vector2(-9.0, -16.0), trim, 2.6)
			_line(ci, at + Vector2(2.5, -6.0), at + Vector2(7.0, -15.0), trim, 2.6)
		"staff", "scroll":
			_dot(ci, at + Vector2(0.4, -7.2), 2.6, trim)
		"bomb":
			_ellipse(ci, at + Vector2(-1.2, -0.6), 7.2, 7.6, cloth.darkened(0.3))
		_:
			pass


static func _leg(ci: CanvasItem, hip: Vector2, foot: Vector2, color: Color, width: float) -> void:
	var knee := (hip + foot) * 0.5 + Vector2(-2.2, -1.2)
	var bend := clampf(hip.distance_to(foot), 8.0, 24.0)
	knee.y -= maxf(0.0, 16.0 - bend)
	_line(ci, hip, knee, color, width)
	_line(ci, knee, foot, color.darkened(0.14), width * 0.85)
	_ellipse(ci, foot + Vector2(2.0, 0.6), 5.0, 2.0, Color(0.08, 0.06, 0.05))


static func _arm(ci: CanvasItem, shoulder: Vector2, hand: Vector2, skin: Color, cloth: Color, width: float) -> void:
	var elbow := (shoulder + hand) * 0.5 + Vector2(-1.0, 4.0)
	_line(ci, shoulder, elbow, cloth, width)
	_line(ci, elbow, hand, skin.darkened(0.06), width * 0.78)
	_dot(ci, hand, 1.7, skin.darkened(0.04))


static func _grip(chest: Vector2, arm: float) -> Vector2:
	var along := clampf((arm + 0.85) / 2.35, 0.0, 1.0)
	return chest + Vector2(lerpf(-16.0, 24.0, along), lerpf(7.0, -16.0, along))


static func _weapon_at(ci: CanvasItem, weapon: String, hand: Vector2, trim: Color, cloth: Color, arm: float, phase: String) -> void:
	var reach := lerpf(12.0, 34.0, clampf((arm + 0.85) / 2.35, 0.0, 1.0))
	var tip := hand + Vector2(reach, lerpf(-18.0, 8.0, clampf((arm + 0.4) / 1.9, 0.0, 1.0)))
	var steel := trim.lightened(0.22)
	match weapon:
		"katana", "dagger":
			var length := 16.0 if weapon == "dagger" else 26.0
			tip = hand + (tip - hand).normalized() * length
			_blade(ci, hand, tip, steel, phase, 2.2 if weapon == "dagger" else 2.8)
			_line(ci, hand + Vector2(-3.5, 1.5), hand + Vector2(3.5, 1.2), cloth.darkened(0.4), 2.4)
		"nodachi":
			tip = hand + (tip - hand).normalized() * 34.0
			_blade(ci, hand, tip, steel, phase, 3.2)
			_line(ci, hand + Vector2(-4.5, 2.0), hand + Vector2(3.0, 2.0), cloth.darkened(0.35), 2.8)
		"bow":
			var pull := 0.0 if phase == "strike" else clampf(0.45 - arm, 0.0, 0.8) * 18.0
			_arc(ci, hand + Vector2(3, 0), 13.0, -1.25, 1.25, 14, trim, 2.4)
			_line(ci, hand + Vector2(3, -13), hand + Vector2(3, 13), Color("f3e6c8"), 1.3)
			_line(ci, hand + Vector2(3, -13), hand + Vector2(-pull, 0), Color("f3e6c8"), 1.1)
			_line(ci, hand + Vector2(-pull, 0), hand + Vector2(3, 13), Color("f3e6c8"), 1.1)
		"shield":
			var face := hand + Vector2(6.0 + maxf(arm, 0.0) * 8.0, -1.0)
			_box(ci, Rect2(face.x, face.y - 13.0, 16.0, 26.0), trim)
			_box(ci, Rect2(face.x + 3.0, face.y - 8.0, 10.0, 16.0), cloth.lightened(0.1))
		"spear":
			tip = hand + Vector2(32.0 + arm * 10.0, -18.0)
			_blade(ci, hand, tip, Color("c8b48a"), phase, 2.4)
			draw_tip(ci, tip, trim)
		"axe":
			tip = hand + Vector2(14.0 + arm * 8.0, -16.0)
			_blade(ci, hand, tip, Color("c8b48a"), phase, 3.2)
			_poly(ci, PackedVector2Array([
				tip + Vector2(-3, 3),
				tip + Vector2(11, -7),
				tip + Vector2(7, 2),
				tip + Vector2(-2, 9),
			]), trim)
		"bomb":
			_ellipse(ci, hand + Vector2(5, -2), 7.0, 7.0, Color(0.1, 0.08, 0.08))
			_dot(ci, hand + Vector2(5, -2), 2.8, trim)
			_line(ci, hand + Vector2(9, -7), hand + Vector2(15, -14), Color("e6c36a"), 1.6)
		"staff":
			_line(ci, hand + Vector2(0, 12), hand + Vector2(-2, -24), Color("c8b48a"), 2.6)
			_dot(ci, hand + Vector2(-2, -28), 4.6, trim)
		"scroll":
			_box(ci, Rect2(hand.x - 1.0, hand.y - 10.0, 16.0, 18.0), trim)
			_line(ci, hand + Vector2(3, -3), hand + Vector2(12, -3), cloth.darkened(0.4), 1.3)
			_line(ci, hand + Vector2(3, 1), hand + Vector2(11, 1), cloth.darkened(0.4), 1.3)
		"claws":
			_line(ci, hand, hand + Vector2(12, -8), trim, 1.8)
			_line(ci, hand + Vector2(0, 2), hand + Vector2(14, -1), trim, 1.8)
			_line(ci, hand + Vector2(0, 5), hand + Vector2(12, 7), trim, 1.8)
		"club", "oni":
			tip = hand + Vector2(16.0 + arm * 8.0, -14.0)
			_blade(ci, hand, tip, Color("6b4a32"), phase, 4.2)
			_ellipse(ci, tip, 7.2, 5.4, trim.darkened(0.08))
		"spit":
			_dot(ci, hand + Vector2(8, -2), 3.8, trim)
		_:
			_blade(ci, hand, tip, steel, phase, 2.6)


static func _blade(ci: CanvasItem, hand: Vector2, tip: Vector2, color: Color, phase: String, width: float) -> void:
	if phase == "strike":
		var ghost := Color(color.r, color.g, color.b, 0.38)
		var lag := hand + (tip - hand) * 0.72 + Vector2(-8.0, -6.0)
		_line(ci, hand, lag, ghost, width * 0.8)
	_line(ci, hand, tip, color, width)


static func draw_tip(ci: CanvasItem, at: Vector2, color: Color) -> void:
	_poly(ci, PackedVector2Array([
		at + Vector2(-2, 4),
		at + Vector2(10, -2),
		at + Vector2(-2, -6),
	]), color)


static func _horse(ci: CanvasItem, cloth: Color, trim: Color, step: float, drop: float) -> void:
	var body := Color("6b442c")
	var base := Vector2(0, drop)
	_ellipse(ci, base + Vector2(-4, 9), 19, 8.5, body.darkened(0.28))
	_ellipse(ci, base + Vector2(1, 7), 16, 7.2, body)
	_ellipse(ci, base + Vector2(15, 1), 7.4, 6.2, body.lightened(0.1))
	_ellipse(ci, base + Vector2(18, -1), 3.4, 2.6, body.lightened(0.18))
	var hoofs: Array = [-13.0, -3.0, 8.0, 15.0]
	for i in hoofs.size():
		var hx := float(hoofs[i])
		var gait := step if i % 2 == 0 else -step
		_leg(ci, base + Vector2(hx, 12), Vector2(hx + gait * 7.0, 22), body.darkened(0.22), 2.6)
	_ellipse(ci, base + Vector2(2, 4), 6.5, 3.2, cloth)
	_line(ci, base + Vector2(18, -2), base + Vector2(28, -8), trim, 2.2)
	_line(ci, base + Vector2(-16, 6), base + Vector2(-24, 12), body.darkened(0.12), 2.4)


static func _around(point: Vector2) -> Vector2:
	var pivot := Vector2(0.0, 21.0)
	return pivot + (point - pivot).rotated(_tilt)


static func _line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	ci.draw_line(_around(a), _around(b), color, width)


static func _dot(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	ci.draw_circle(_around(at), radius, color)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	var turned := PackedVector2Array()
	for point in pts:
		turned.append(_around(point))
	if turned.size() >= 3:
		ci.draw_colored_polygon(turned, color)


static func _box(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	_poly(ci, PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]), color)


static func _arc(ci: CanvasItem, center: Vector2, radius: float, a0: float, a1: float, segs: int, color: Color, width: float) -> void:
	ci.draw_arc(_around(center), radius, a0 + _tilt, a1 + _tilt, segs, color, width)


static func _ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 14
	for i in segs:
		var angle := TAU * float(i) / float(segs)
		pts.append(_around(center + Vector2(cos(angle) * rx, sin(angle) * ry)))
	if pts.size() >= 3:
		ci.draw_colored_polygon(pts, color)
