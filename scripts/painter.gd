extends RefCounted

static var _tilt: float = 0.0


static func look(kind: String) -> Dictionary:
	match kind:
		"sword":
			return _look(Color("f0c9a0"), Color("1a1e28"), Color("c5ccd6"), "katana", false, "ninja")
		"archer":
			return _look(Color("f0c9a0"), Color("141820"), Color("7dcea0"), "bow", false, "ninja")
		"shield":
			return _look(Color("f0c9a0"), Color("1c1814"), Color("c4a574"), "shield", false, "ninja")
		"saber":
			return _look(Color("f0c9a0"), Color("1a1216"), Color("c44536"), "nodachi", false, "ninja")
		"lancer":
			return _look(Color("f0c9a0"), Color("161820"), Color("9aa4d4"), "spear", false, "ninja")
		"berserker":
			return _look(Color("e7b090"), Color("2a1210"), Color("e6c36a"), "axe", false, "ninja")
		"horse":
			return _look(Color("f0c9a0"), Color("1a1214"), Color("e6c36a"), "katana", true, "ninja")
		"suicide":
			return _look(Color("e7c2a4"), Color("16141a"), Color("e24b3b"), "bomb", false, "ninja")
		"assassin":
			return _look(Color("c9b8d4"), Color("1a1422"), Color("b794f6"), "dagger", false, "ninja")
		"heal":
			return _look(Color("f0c9a0"), Color("d7ddd8"), Color("7ec8b3"), "staff", false, "ninja")
		"level":
			return _look(Color("f0c9a0"), Color("e6d7b0"), Color("a56b2b"), "scroll", false, "ninja")
		"hero":
			return _look(Color("f3d2b0"), Color("f4efe4"), Color("c44536"), "katana", false, "ninja")
		"walker":
			return _look(Color("e0c2a0"), Color("4e5a3a"), Color("8d97a3"), "shortsword", false, "soldier")
		"runner":
			return _look(Color("e0c2a0"), Color("5c6844"), Color("c9c3b2"), "dagger", false, "soldier", false)
		"brute":
			return _look(Color("e0c2a0"), Color("3a4034"), Color("8a9098"), "hammer", false, "soldier")
		"spitter":
			return _look(Color("e0c2a0"), Color("46503a"), Color("6b7c4a"), "crossbow", false, "soldier")
		"bomber":
			return _look(Color("e0c2a0"), Color("4a4634"), Color("e24b3b"), "bomb", false, "soldier")
		"oni":
			return _look(Color("e0c2a0"), Color("3d3428"), Color("e6c36a"), "polearm", false, "soldier")
		_:
			return _look(Color("f0c9a0"), Color("1a1e28"), Color("c5ccd6"), "katana", false, "ninja")


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
		"bow", "crossbow":
			return "hit_bow"
		"shield", "axe", "hammer", "club", "bomb":
			return "hit_blunt"
		"spear", "polearm":
			return "hit_pierce"
		"staff", "scroll":
			return "hit_magic"
		_:
			return "hit_blade"


static func contact_beat(weapon: String) -> int:
	match weapon:
		"bow", "crossbow":
			return 3
		_:
			return 2


static func cycle_time(paint: String) -> float:
	if paint == "runner":
		return 0.62
	return 0.92


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


static func _look(skin: Color, cloth: Color, trim: Color, weapon: String, mount: bool, faction: String, pack: bool = true) -> Dictionary:
	return {
		"skin": skin,
		"cloth": cloth,
		"trim": trim,
		"weapon": weapon,
		"mount": mount,
		"faction": faction,
		"pack": pack,
	}


static func paint_local(ci: CanvasItem, look: Dictionary, pose: Dictionary) -> void:
	var phase := str(pose.get("phase", "idle"))
	var t := float(pose.get("t", 0.0))
	var clock := float(pose.get("clock", 0.0))
	var flash := float(pose.get("flash", 0.0))
	var beat := int(pose.get("beat", 0))
	var skin: Color = look["skin"]
	var cloth: Color = look["cloth"]
	var trim: Color = look["trim"]
	if flash > 0.0:
		var wash := clampf(flash * 4.0, 0.0, 0.72)
		skin = skin.lerp(Color.WHITE, wash)
		cloth = cloth.lerp(Color.WHITE, wash)
		trim = trim.lerp(Color.WHITE, wash)
	var weapon := str(pose.get("tool", look["weapon"]))
	var faction := str(look.get("faction", "ninja"))
	var motion := _motion(phase, t, clock, weapon, beat)
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
	_tilt = 0.0
	_ellipse(ci, Vector2(lean * 0.2, 22.0), 16.0 + abs(step) * 3.0, 4.2, Color(0, 0, 0, 0.32))
	if phase == "act" and beat == contact_beat(weapon):
		_ellipse(ci, Vector2(8.0 + t * 10.0, 21.0), 7.0, 2.2, Color(1, 0.94, 0.82, 0.28 * (1.0 - t)))
	_tilt = float(motion["tilt"])
	if mount:
		_horse(ci, cloth, trim, step, drop)
	_back(ci, chest, faction, weapon, cloth, trim, bool(look.get("pack", true)), arm)
	if not mount:
		_leg(ci, chest + Vector2(-3.5, 12.0), Vector2(-5.0 - step * 11.0, ground), cloth.darkened(0.34), 3.2)
	_torso(ci, chest, cloth, trim, faction)
	if not mount:
		_leg(ci, chest + Vector2(3.0, 12.0), Vector2(6.0 + step * 12.0, ground), cloth.darkened(0.08), 3.5)
	_head(ci, chest + Vector2(1.6, -16.0), skin, cloth, trim, faction, weapon, phase)
	var grip := _grip(chest, arm)
	if weapon == "bow" or weapon == "crossbow":
		var bow_hand := chest + Vector2(14.0, -2.0)
		var rear := _arrow_hand(chest, bow_hand, beat, t)
		_arm(ci, chest + Vector2(-4.0, -1.0), rear, skin, cloth.darkened(0.22), 2.5)
		_arm(ci, chest + Vector2(5.0, -4.0), bow_hand, skin, cloth, 2.9)
		_ranged(ci, weapon, bow_hand, rear, beat, trim, cloth)
	else:
		_arm(ci, chest + Vector2(-4.0, -1.0), grip + Vector2(-8.0, 6.0), skin, cloth.darkened(0.22), 2.5)
		_arm(ci, chest + Vector2(5.0, -4.0), grip, skin, cloth, 2.9)
		_weapon_at(ci, weapon, grip, trim, cloth, arm, phase, beat)
	if phase == "act" and beat == contact_beat(weapon) and weapon != "staff" and weapon != "scroll":
		var alpha := (1.0 - t) * 0.85
		_arc(ci, grip, 18.0 + t * 16.0, -1.35, 1.05, 16, Color(trim.r, trim.g, trim.b, alpha), 3.2)
	_tilt = 0.0


static func _motion(phase: String, t: float, clock: float, weapon: String, beat: int) -> Dictionary:
	var keys := _keys(weapon)
	var rest: Dictionary = keys[0]
	var lean := float(rest["lean"])
	var squat := float(rest["squat"])
	var arm := float(rest["arm"])
	var step := sin(clock * 1.7) * 0.15
	var breath := sin(clock * 2.1) * 0.8
	var rise := float(rest["rise"])
	var tilt := float(rest["tilt"]) + sin(clock * 1.7) * 0.03
	match phase:
		"debut":
			rise = (1.0 - t) * 22.0
			squat = (1.0 - t) * 8.0
			arm = lerpf(-0.55, arm, t)
			step = lerpf(0.7, 0.0, t)
			tilt = lerpf(0.35, tilt, t)
			breath = 0.0
		"march":
			step = sin(clock * 8.0)
			lean = 4.0
			squat = absf(step) * 2.2
			arm = arm + step * 0.1
			breath = 0.25
			tilt = 0.18 + step * 0.04
		"act":
			var a: Dictionary = keys[clampi(beat, 0, 3)]
			var b: Dictionary = keys[clampi(beat + 1, 0, 4)]
			lean = lerpf(float(a["lean"]), float(b["lean"]), t)
			squat = lerpf(float(a["squat"]), float(b["squat"]), t)
			arm = lerpf(float(a["arm"]), float(b["arm"]), t)
			step = lerpf(float(a["step"]), float(b["step"]), t)
			tilt = lerpf(float(a["tilt"]), float(b["tilt"]), t)
			rise = lerpf(float(a["rise"]), float(b["rise"]), t)
			breath = 0.0
		"hurt":
			lean = lerpf(-2.0, 0.0, t)
			squat = lerpf(5.0, 0.0, t)
			arm = lerpf(-0.15, arm, t)
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
			arm = lerpf(arm, 1.15, t)
			step = lerpf(0.0, 1.1, t)
			tilt = lerpf(0.0, 1.25, t)
			breath = 0.0
			rise = 0.0
	return {
		"lean": lean,
		"squat": squat,
		"arm": arm,
		"step": step,
		"breath": breath,
		"rise": rise,
		"tilt": tilt,
	}


static func _k(arm: float, tilt: float, squat: float, step: float, lean: float, rise: float = 0.0) -> Dictionary:
	return {"arm": arm, "tilt": tilt, "squat": squat, "step": step, "lean": lean, "rise": rise}


static func _keys(weapon: String) -> Array:
	match weapon:
		"nodachi":
			return [_k(-0.1, 0.05, 0.0, 0.1, 1.0), _k(-0.45, -0.1, 1.0, -0.2, -2.0), _k(-0.95, -0.62, 3.0, -0.7, -6.0), _k(1.45, 0.7, 0.4, 1.25, 9.0), _k(0.35, 0.12, 1.0, 0.2, 2.0)]
		"dagger":
			return [_k(0.15, 0.08, 1.0, 0.3, 2.0), _k(-0.35, 0.05, 4.0, -0.2, -1.0), _k(-0.15, -0.05, 3.0, 0.1, 0.0), _k(1.15, 0.38, 1.0, 0.9, 6.0), _k(0.2, 0.08, 1.2, 0.4, 2.0)]
		"shortsword":
			return [_k(-0.15, 0.05, 0.0, 0.15, 1.0), _k(-0.4, -0.05, 1.0, -0.2, -1.0), _k(-0.15, -0.28, 1.5, -0.3, -3.0), _k(1.15, 0.4, 0.3, 0.9, 6.0), _k(-0.1, 0.05, 0.0, 0.1, 1.0)]
		"bow":
			return [_k(0.25, 0.06, 0.0, 0.1, 1.0), _k(-0.9, -0.18, 1.5, -0.35, -3.0), _k(0.45, 0.08, 0.4, 0.25, 2.0), _k(-0.7, -0.42, 1.6, -0.45, -5.0), _k(1.2, 0.28, 0.0, 0.7, 7.0)]
		"crossbow":
			return [_k(0.15, 0.05, 0.0, 0.1, 1.0), _k(-0.45, 0.02, 2.0, -0.2, -1.0), _k(0.35, 0.04, 0.4, 0.15, 1.0), _k(0.6, -0.12, 0.6, 0.1, -1.0), _k(1.1, 0.22, 0.0, 0.45, 4.0)]
		"shield":
			return [_k(0.45, 0.04, 0.2, 0.1, 1.0), _k(0.15, -0.28, 1.5, -0.1, -2.0), _k(0.05, -0.12, 4.0, -0.3, -1.0), _k(1.3, 0.48, 0.4, 1.05, 7.0), _k(0.45, 0.05, 0.3, 0.1, 1.0)]
		"spear":
			return [_k(0.55, 0.06, 0.0, 0.2, 2.0), _k(-0.35, -0.16, 0.8, -0.85, -3.0), _k(0.7, 0.04, 0.2, 0.3, 2.0), _k(1.5, 0.36, 0.2, 1.3, 8.0), _k(0.6, 0.06, 0.0, 0.2, 2.0)]
		"polearm":
			return [_k(0.5, 0.08, 0.0, 0.15, 1.0), _k(-0.4, -0.38, 1.0, -0.7, -4.0), _k(0.65, 0.02, 0.3, 0.2, 1.0), _k(1.5, 0.4, 0.2, 1.25, 8.0), _k(0.45, 0.1, 0.0, 0.1, 1.0)]
		"axe":
			return [_k(0.3, 0.08, 0.4, 0.1, 1.0), _k(-0.95, 0.12, 3.2, -0.5, -2.0), _k(-0.2, -0.68, 2.0, -0.2, -5.0), _k(1.4, 0.72, 5.0, 1.2, 8.0), _k(0.35, 0.1, 0.6, 0.15, 1.0)]
		"hammer":
			return [_k(0.2, 0.06, 0.6, 0.05, 1.0), _k(-0.3, 0.02, 1.2, -0.2, 0.0), _k(-0.15, -0.45, 3.5, -0.4, -3.0), _k(1.25, 0.55, 2.0, 1.0, 6.0), _k(0.25, 0.08, 0.8, 0.1, 1.0)]
		"bomb":
			return [_k(-0.1, 0.04, 0.2, 0.1, 1.0), _k(-0.55, 0.05, 1.4, -0.2, -1.0), _k(0.25, -0.08, 1.0, 0.2, 1.0), _k(1.25, 0.62, 2.2, 1.25, 8.0), _k(0.8, 0.2, 1.0, 0.4, 3.0)]
		"staff":
			return [_k(0.5, -0.05, 0.0, 0.05, 0.0, 0.0), _k(0.2, 0.02, 1.2, 0.0, 0.0, 0.0), _k(0.9, -0.22, 0.2, 0.05, -1.0, 3.0), _k(0.7, -0.1, 0.0, 0.1, 0.0, 1.0), _k(0.5, -0.05, 0.0, 0.05, 0.0, 0.0)]
		"scroll":
			return [_k(-0.2, 0.04, 0.2, 0.05, 0.0), _k(0.15, -0.05, 0.4, 0.0, 0.0, 0.5), _k(0.45, -0.12, 0.2, 0.05, -1.0, 1.5), _k(0.7, -0.08, 0.0, 0.1, 0.0, 2.0), _k(-0.15, 0.04, 0.2, 0.05, 0.0)]
		_:
			return [_k(-0.2, 0.05, 0.0, 0.1, 1.0), _k(-0.55, -0.08, 1.0, -0.3, -2.0), _k(-0.2, -0.48, 2.0, -0.6, -5.0), _k(1.35, 0.55, 0.2, 1.1, 8.0), _k(0.15, 0.06, 0.0, 0.1, 1.0)]


static func _arrow_hand(chest: Vector2, bow_hand: Vector2, beat: int, t: float) -> Vector2:
	var behind := chest + Vector2(-16.0, 6.0)
	var nock := bow_hand + Vector2(-4.0, 1.0)
	var draw := bow_hand + Vector2(-16.0, 1.0)
	var released := bow_hand + Vector2(-3.0, 2.0)
	var points: Array[Vector2] = [behind, nock, draw, released, bow_hand + Vector2(2.0, 4.0)]
	var a: Vector2 = points[clampi(beat, 0, 3)]
	var b: Vector2 = points[clampi(beat + 1, 0, 4)]
	return a.lerp(b, t)


static func _back(ci: CanvasItem, chest: Vector2, faction: String, weapon: String, cloth: Color, trim: Color, pack: bool, arm: float) -> void:
	if faction == "soldier":
		if pack:
			_box(ci, Rect2(chest.x - 16.0, chest.y - 2.0, 10.0, 14.0), cloth.darkened(0.35))
			_line(ci, chest + Vector2(-14.0, -2.0), chest + Vector2(-6.0, -8.0), cloth.darkened(0.2), 2.0)
		return
	var trail := 12.0 + maxf(0.0, arm) * 8.0 + maxf(0.0, _tilt) * 14.0
	var hem := chest + Vector2(-18.0 - trail * 0.35, 24.0)
	_poly(ci, PackedVector2Array([
		chest + Vector2(-4.0, -8.0),
		chest + Vector2(-10.0, 2.0),
		hem,
		chest + Vector2(2.0, 8.0),
	]), trim.darkened(0.15))
	if weapon == "bow" or weapon == "crossbow":
		_box(ci, Rect2(chest.x - 12.0, chest.y - 6.0, 6.0, 12.0), cloth.lightened(0.08))


static func _torso(ci: CanvasItem, chest: Vector2, cloth: Color, trim: Color, faction: String) -> void:
	_ellipse(ci, chest + Vector2(-6.2, 3.2), 11.2, 14.2, cloth.darkened(0.46))
	_ellipse(ci, chest + Vector2(0.4, 1.0), 8.6, 12.4, cloth)
	var front := cloth.lightened(0.22)
	if faction == "soldier":
		front = trim.darkened(0.05)
	_ellipse(ci, chest + Vector2(6.4, -1.4), 5.0, 8.4, front)
	_line(ci, chest + Vector2(-2.0, -7.0), chest + Vector2(7.0, 9.0), trim, 1.6)


static func _head(ci: CanvasItem, at: Vector2, skin: Color, cloth: Color, trim: Color, faction: String, weapon: String, phase: String) -> void:
	if faction == "ninja":
		_ellipse(ci, at + Vector2(-4.0, 1.0), 8.2, 8.4, cloth.darkened(0.15))
		_ellipse(ci, at + Vector2(2.4, 0.2), 6.4, 7.0, cloth)
		_line(ci, at + Vector2(0.4, -1.2), at + Vector2(6.2, -1.0), trim, 2.2)
		if phase == "hurt" or phase == "fall":
			_line(ci, at + Vector2(1.2, -1.6), at + Vector2(5.4, -0.4), Color(0.9, 0.9, 0.85), 1.4)
		else:
			_dot(ci, at + Vector2(4.2, -1.6), 1.15, Color(0.95, 0.95, 0.9))
		if weapon == "axe":
			_line(ci, at + Vector2(-2.0, -6.0), at + Vector2(2.0, -2.0), cloth.lightened(0.1), 1.6)
		return
	_ellipse(ci, at + Vector2(-1.0, -1.0), 7.4, 6.6, cloth.darkened(0.28))
	_ellipse(ci, at + Vector2(2.2, 2.4), 4.2, 3.2, skin)
	_line(ci, at + Vector2(-1.0, -0.2), at + Vector2(6.4, 0.4), Color(0.1, 0.1, 0.08), 2.4)
	if weapon == "polearm":
		_line(ci, at + Vector2(0.0, -6.0), at + Vector2(1.0, -16.0), trim, 2.4)
		_ellipse(ci, at + Vector2(1.0, -16.0), 3.2, 2.2, trim)


static func _ranged(ci: CanvasItem, weapon: String, bow_hand: Vector2, rear: Vector2, beat: int, trim: Color, cloth: Color) -> void:
	if weapon == "crossbow":
		_line(ci, bow_hand + Vector2(-2, 3), bow_hand + Vector2(16, -1), Color("6b4a32"), 3.4)
		_line(ci, bow_hand + Vector2(10, -6), bow_hand + Vector2(10, 6), trim, 2.2)
		if beat < 3:
			_line(ci, rear, bow_hand + Vector2(8, 0), trim.lightened(0.2), 1.6)
		else:
			_line(ci, bow_hand + Vector2(12, 0), bow_hand + Vector2(28, -1), Color(1, 0.96, 0.86, 0.7), 1.6)
		return
	_arc(ci, bow_hand, 13.0, -1.25, 1.25, 14, trim, 2.4)
	var pull := bow_hand.x - rear.x
	if beat >= 3:
		pull = 0.0
	_line(ci, bow_hand + Vector2(2, -13), bow_hand + Vector2(2 - pull, 0), Color("f3e6c8"), 1.2)
	_line(ci, bow_hand + Vector2(2 - pull, 0), bow_hand + Vector2(2, 13), Color("f3e6c8"), 1.2)
	if beat < 3:
		_line(ci, rear + Vector2(-6, 0), rear + Vector2(4, 0), cloth.lightened(0.3), 1.5)
		draw_tip(ci, rear + Vector2(6, 0), trim)
	else:
		_line(ci, bow_hand + Vector2(8, -1), bow_hand + Vector2(26, -2), Color(1, 0.97, 0.88, 0.75), 1.6)


static func _weapon_at(ci: CanvasItem, weapon: String, hand: Vector2, trim: Color, cloth: Color, arm: float, phase: String, beat: int) -> void:
	var steel := trim.lightened(0.22)
	match weapon:
		"katana", "shortsword", "dagger":
			var length := 26.0
			if weapon == "dagger":
				length = 14.0
			elif weapon == "shortsword":
				length = 18.0
			if beat == 0:
				_line(ci, hand + Vector2(-2, 8), hand + Vector2(6, 2), steel, 2.2)
			else:
				var tip := hand + Vector2(length, lerpf(-16.0, 4.0, clampf((arm + 0.4) / 1.8, 0.0, 1.0)))
				_blade(ci, hand, tip, steel, phase, beat, 2.4)
				_line(ci, hand + Vector2(-3, 1), hand + Vector2(3, 1), cloth.darkened(0.4), 2.2)
		"nodachi":
			var tip := hand + Vector2(34.0, lerpf(-20.0, 8.0, clampf((arm + 0.4) / 1.8, 0.0, 1.0)))
			_blade(ci, hand, tip, steel, phase, beat, 3.2)
		"shield":
			var face := hand + Vector2(4.0, -2.0)
			_box(ci, Rect2(face.x, face.y - 13.0, 16.0, 26.0), trim)
			_box(ci, Rect2(face.x + 3.0, face.y - 8.0, 10.0, 16.0), cloth.lightened(0.08))
		"spear", "polearm":
			var reach := 18.0 if beat < 2 else 36.0
			var tip := hand + Vector2(reach, -8.0 if weapon == "polearm" else -4.0)
			_blade(ci, hand, tip, Color("c8b48a"), phase, beat, 2.4)
			draw_tip(ci, tip, trim)
		"axe":
			var tip := hand + Vector2(10.0 + maxf(arm, 0.0) * 8.0, -18.0)
			_blade(ci, hand, tip, Color("c8b48a"), phase, beat, 3.2)
			_poly(ci, PackedVector2Array([
				tip + Vector2(-3, 3),
				tip + Vector2(11, -7),
				tip + Vector2(7, 2),
				tip + Vector2(-2, 9),
			]), trim)
		"hammer":
			var tip := hand + Vector2(8.0, -16.0)
			_blade(ci, hand, tip, Color("6b4a32"), phase, beat, 4.0)
			_box(ci, Rect2(tip.x - 4.0, tip.y - 8.0, 14.0, 12.0), trim.darkened(0.1))
		"bomb":
			var hold := hand + Vector2(4, -4)
			if beat >= 2:
				hold = hand + Vector2(10, -8)
			_ellipse(ci, hold, 6.5, 6.5, Color(0.12, 0.1, 0.1))
			_dot(ci, hold, 2.4, trim)
		"staff":
			_line(ci, hand + Vector2(0, 14), hand + Vector2(-1, -26), Color("c8b48a"), 2.6)
			_dot(ci, hand + Vector2(-1, -28), 4.2, trim)
		"scroll":
			var wide := 16.0 if beat == 2 or beat == 3 else 8.0
			_box(ci, Rect2(hand.x, hand.y - 8.0, wide, 16.0), trim)
			if beat == 2 or beat == 3:
				_line(ci, hand + Vector2(3, -2), hand + Vector2(wide - 3.0, -2), cloth.darkened(0.35), 1.2)
		_:
			_line(ci, hand, hand + Vector2(16, -10), steel, 2.4)


static func _blade(ci: CanvasItem, hand: Vector2, tip: Vector2, color: Color, phase: String, beat: int, width: float) -> void:
	if phase == "act" and beat >= 2:
		var ghost := Color(color.r, color.g, color.b, 0.35)
		_line(ci, hand, hand + (tip - hand) * 0.7 + Vector2(-6.0, -4.0), ghost, width * 0.75)
	_line(ci, hand, tip, color, width)


static func draw_tip(ci: CanvasItem, at: Vector2, color: Color) -> void:
	_poly(ci, PackedVector2Array([
		at + Vector2(-2, 4),
		at + Vector2(10, -2),
		at + Vector2(-2, -6),
	]), color)


static func _horse(ci: CanvasItem, cloth: Color, trim: Color, step: float, drop: float) -> void:
	var body := Color("2a211c")
	var base := Vector2(0, drop)
	_ellipse(ci, base + Vector2(-4, 9), 19, 8.5, body.darkened(0.2))
	_ellipse(ci, base + Vector2(1, 7), 16, 7.2, body)
	_ellipse(ci, base + Vector2(15, 1), 7.4, 6.2, body.lightened(0.08))
	var hoofs: Array = [-13.0, -3.0, 8.0, 15.0]
	for i in hoofs.size():
		var hx := float(hoofs[i])
		var gait := step if i % 2 == 0 else -step
		_leg(ci, base + Vector2(hx, 12), Vector2(hx + gait * 7.0, 22), body.darkened(0.15), 2.6)
	_ellipse(ci, base + Vector2(2, 4), 6.5, 3.2, cloth)
	_line(ci, base + Vector2(18, -2), base + Vector2(28, -8), trim, 2.2)


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


static func _grip(chest: Vector2, arm: float) -> Vector2:
	var along := clampf((arm + 0.85) / 2.35, 0.0, 1.0)
	return chest + Vector2(lerpf(-16.0, 24.0, along), lerpf(7.0, -16.0, along))


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
