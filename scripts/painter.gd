extends RefCounted

static var _tilt: float = 0.0
static var saber_navy: bool = false
static var sheet_on: Dictionary = {}


static func look(kind: String) -> Dictionary:
	var sheet := false
	if sheet_on.has(kind):
		sheet = bool(sheet_on[kind])
	return look_as(kind, sheet, kind == "saber" and saber_navy)


static func look_as(kind: String, sheet: bool, navy: bool) -> Dictionary:
	var row := _painted(kind)
	row["paint"] = kind
	if kind == "saber" and navy:
		row["skin"] = Color("f0c14a")
		row["cloth"] = Color("1e3f8f")
		row["trim"] = Color("e2b034")
		return row
	if sheet:
		var pal := _sheet_row(kind)
		if not pal.is_empty():
			row["skin"] = pal["skin"]
			row["cloth"] = pal["cloth"]
			row["trim"] = pal["trim"]
			row["sheet"] = true
			row["eye"] = pal["eye"]
			row["mask"] = pal["mask"]
			row["bare"] = pal["bare"]
			row["scarf"] = pal["scarf"]
			row["blade"] = pal["blade"]
	return row


static func _painted(kind: String) -> Dictionary:
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
		"boss":
			return _look(Color("e0c2a0"), Color("241c16"), Color("e6c36a"), "polearm", false, "soldier")
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
		"oni", "boss":
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


# The picture eases into the contact pose. Ranged shots leave as the string
# opens. Every other hit lands once the weapon has arrived.
static func strike_due(weapon: String, beat: int, along: float) -> bool:
	var contact := contact_beat(weapon)
	if beat > contact:
		return true
	if beat < contact:
		return false
	if weapon == "bow" or weapon == "crossbow":
		return along >= 0.08
	return along >= 0.55


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


static func _palette(skin: Color, cloth: Color, trim: Color, eye: Color, mask: Color, bare: bool, scarf: Color, blade: Color) -> Dictionary:
	return {
		"skin": skin,
		"cloth": cloth,
		"trim": trim,
		"eye": eye,
		"mask": mask,
		"bare": bare,
		"scarf": scarf,
		"blade": blade,
	}


static func _sheet_row(kind: String) -> Dictionary:
	var none := Color(0, 0, 0, 0)
	match kind:
		"sword":
			return _palette(Color("d8dbe2"), Color("1c1e24"), Color("c5ccd6"), Color("f4f6f8"), Color("16181c"), false, none, Color("d5dbe3"))
		"archer":
			return _palette(Color("d8dbe2"), Color("1a1e24"), Color("2f9e44"), Color("7dff6a"), Color("14161a"), false, Color("2f9e44"), Color("c8b48a"))
		"shield":
			return _palette(Color("e7c2a4"), Color("5c3d24"), Color("e2b034"), Color("f0c14a"), Color("1a140e"), false, none, Color("e2b034"))
		"saber":
			return _palette(Color("1a1214"), Color("1a1216"), Color("c44536"), Color("e23b3b"), Color("141214"), false, Color("c44536"), Color("2c2c32"))
		"lancer":
			return _palette(Color("d8dbe2"), Color("1a2744"), Color("3d7ec9"), Color("7ecbff"), Color("101820"), false, none, Color("d5dbe3"))
		"berserker":
			return _palette(Color("e7b090"), Color("7a1f2b"), Color("e2b034"), Color("f0c14a"), Color("1a1214"), true, Color("8e2430"), Color("e2b034"))
		"horse":
			return _palette(Color("1a1c22"), Color("1a1c22"), Color("e2b034"), Color("f0c14a"), Color("14161a"), false, none, Color("e2b034"))
		"suicide":
			return _palette(Color("1a1214"), Color("1a1216"), Color("c44536"), Color("e23b3b"), Color("141214"), false, Color("c44536"), Color("1a1214"))
		"assassin":
			return _palette(Color("c9b8d4"), Color("4a2d78"), Color("c9a0ff"), Color("d7b4ff"), Color("1a1224"), false, none, Color("c9a0ff"))
		"heal":
			return _palette(Color("f4f1ea"), Color("f4f7f8"), Color("1aa6a6"), Color("3ee0e0"), Color("f7f7f4"), false, none, Color("3ee0e0"))
		"level":
			return _palette(Color("e6c9a0"), Color("e6d3a8"), Color("a56b2b"), Color("f0c14a"), Color("1a140e"), false, none, Color("f3e6c4"))
		"hero":
			return _palette(Color("f3d2b0"), Color("f4efe4"), Color("c44536"), Color("e23b3b"), Color("1a1214"), false, Color("c44536"), Color("d5dbe3"))
		_:
			return {}


static func _paint_sheet(ci: CanvasItem, look: Dictionary, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, step: float, ground: float, phase: String, beat: int, t: float, cycle: String, snap: float, mount: bool, flash: float, drop: float) -> void:
	var cloth: Color = look["cloth"] as Color
	var trim: Color = look["trim"] as Color
	var skin: Color = look["skin"] as Color
	var eye: Color = look["eye"] as Color
	var mask: Color = look["mask"] as Color
	var blade: Color = look["blade"] as Color
	var scarf: Color = look["scarf"] as Color
	var bare: bool = bool(look["bare"])
	var wash := 0.0
	if flash > 0.0:
		wash = clampf(flash * 4.0, 0.0, 0.72)
		skin = skin.lerp(Color.WHITE, wash)
		cloth = cloth.lerp(Color.WHITE, wash)
		trim = trim.lerp(Color.WHITE, wash)
		eye = eye.lerp(Color.WHITE, wash)
		blade = blade.lerp(Color.WHITE, wash)
	var ink := Color("141210").lerp(Color.WHITE, wash)
	var paint := str(look.get("paint", ""))
	if mount:
		_px_horse(ci, trim, step, drop, ink)
	if scarf.a > 0.2:
		_px_scarf(ci, chest, snap, scarf, ink)
	if paint == "archer":
		_px_quiver(ci, chest, trim, ink)
	var pants := cloth.darkened(0.28)
	if cloth.get_luminance() > 0.55:
		pants = Color("2c261e")
	var wraps := 2 if paint == "heal" else 1
	if mount:
		_px_leg(ci, chest + Vector2(-4.0, 8.0), chest + Vector2(-6.0 - step * 3.0, 16.0), pants, trim, ink, wraps)
	else:
		_px_leg(ci, chest + Vector2(-4.0, 8.0), Vector2(-5.0 - step * 11.0, ground), pants, trim, ink, wraps)
	_px_tunic(ci, chest, cloth, trim, ink, bare, paint)
	if mount:
		_px_leg(ci, chest + Vector2(3.0, 8.0), chest + Vector2(7.0 + step * 3.0, 16.0), pants.lightened(0.06), trim, ink, wraps)
	else:
		_px_leg(ci, chest + Vector2(3.0, 8.0), Vector2(6.0 + step * 12.0, ground), pants.lightened(0.06), trim, ink, wraps)
	if paint == "shield":
		_px_hip_sword(ci, chest, trim, ink)
	var head := chest + Vector2(1.6, -16.0)
	var neck_x := int(round(head.x)) + 1
	var neck_top := int(round(head.y)) + 5
	var neck_bot := int(round(chest.y)) - 5
	for y in range(neck_top, neck_bot):
		_px_put(ci, Vector2(float(neck_x) - 1.0, float(y)), ink)
		_px_run_x(ci, neck_x, neck_x + 2, y, cloth)
	_px_hood(ci, head, cloth, trim, eye, mask, ink, phase, paint)
	if scarf.a > 0.2:
		var neck := Vector2(round(head.x), round(head.y) + 6.0)
		_px_run_x(ci, int(neck.x) - 2, int(neck.x) + 5, int(neck.y), scarf)
		_px_run_x(ci, int(neck.x) - 1, int(neck.x) + 4, int(neck.y) + 1, scarf.darkened(0.14))
	var sleeve := cloth.darkened(0.08)
	var glove := sleeve.lightened(0.22)
	if bare:
		sleeve = skin
		glove = skin.lightened(0.08)
	elif cloth.get_luminance() > 0.55:
		glove = skin
	_px_arm(ci, chest + Vector2(-4.0, -1.0), rear, sleeve, glove, ink, bare)
	_px_arm(ci, chest + Vector2(5.0, -4.0), front, sleeve.lightened(0.05), glove, ink, bare)
	if bare:
		_px_bracer(ci, front, trim)
		_px_bracer(ci, rear, trim.darkened(0.08))
	_px_weapon(ci, cycle, phase, beat, t, chest, rear, front, tip, ground, trim, cloth, blade, ink)


static func _px_tunic(ci: CanvasItem, chest: Vector2, cloth: Color, trim: Color, ink: Color, bare: bool, paint: String) -> void:
	var rows: Array[String] = [
		"..oooooooooo..",
		".ohhhhhhhhhl..",
		".ohhhttttthl..",
		".ohhhhhtthhl..",
		".ohhhhhhhhhl..",
		".ottttttttttl.",
		".ohhhhbhhhhlo.",
		".ohhhhhhhhhl..",
		".otttttttttl..",
		"..oooooooooo..",
	]
	var colors := {
		"o": ink,
		"h": cloth,
		"l": cloth.lightened(0.16),
		"t": trim,
		"b": trim.lightened(0.28),
	}
	var origin := Vector2(round(chest.x) - 6.0, round(chest.y) - 6.0)
	_px_map(ci, origin, rows, colors)
	if bare:
		for y in range(1, 8):
			_px_put(ci, origin + Vector2(12.0, float(y)), cloth)
			_px_put(ci, origin + Vector2(13.0, float(y)), trim)
		_px_run_x(ci, int(origin.x) + 8, int(origin.x) + 12, int(origin.y) + 1, trim)
		_px_run_x(ci, int(origin.x) + 9, int(origin.x) + 11, int(origin.y) + 2, trim.lightened(0.2))
	if paint == "heal":
		_px_put(ci, chest + Vector2(2.0, 2.0), trim)
		_px_run_x(ci, int(round(chest.x)) + 1, int(round(chest.x)) + 3, int(round(chest.y)) + 3, trim)
		_px_put(ci, chest + Vector2(2.0, 4.0), trim)


static func _px_hood(ci: CanvasItem, at: Vector2, cloth: Color, trim: Color, eye: Color, mask: Color, ink: Color, phase: String, paint: String) -> void:
	var rows: Array[String] = [
		"....pppp........",
		"...phhhhp.......",
		"..odhhhhlo......",
		".odddhhhlo......",
		"ooddddhhlo......",
		".otmmmtlo.......",
		".odmmmmeo.......",
		".odmmmmewo......",
		".odmmmmewo......",
		".ohhhhhhlo......",
		"..ohhhhlo.......",
		"...oooooo.......",
	]
	var eye_px := eye
	var core := Color("f7f7f4")
	if phase == "hurt" or phase == "fall":
		eye_px = Color("f4f4f0")
		core = Color("f4f4f0")
	var colors := {
		"o": ink,
		"p": cloth.darkened(0.06),
		"h": cloth,
		"d": cloth.darkened(0.34),
		"l": cloth.lightened(0.14),
		"t": trim,
		"m": mask,
		"e": eye_px,
		"w": core,
	}
	var origin := Vector2(round(at.x) - 4.0, round(at.y) - 8.0)
	_px_map(ci, origin, rows, colors)
	_px_put(ci, at + Vector2(1.0, -9.0), trim)
	_px_put(ci, at + Vector2(2.0, -10.0), trim.lightened(0.2))
	_px_put(ci, at + Vector2(3.0, -9.0), trim)
	_px_mark(ci, at, paint, trim, eye)
	_px_face(ci, at, mask, trim, eye, ink, phase)


static func _px_face(ci: CanvasItem, at: Vector2, mask: Color, trim: Color, eye: Color, ink: Color, phase: String) -> void:
	var fx := int(round(at.x)) + 2
	var fy := int(round(at.y)) - 3
	_px_run_x(ci, fx - 1, fx + 4, fy, trim)
	_px_run_x(ci, fx - 1, fx + 4, fy + 5, trim.darkened(0.15))
	for y in range(1, 5):
		_px_put(ci, Vector2(float(fx) - 1.0, float(fy + y)), trim)
		_px_run_x(ci, fx, fx + 3, fy + y, mask)
		_px_put(ci, Vector2(float(fx) + 4.0, float(fy + y)), ink)
	if phase == "hurt" or phase == "fall":
		_px_run_x(ci, fx + 1, fx + 3, fy + 2, Color("f4f4f0"))
		return
	_px_put(ci, Vector2(float(fx) + 2.0, float(fy) + 2.0), eye)
	_px_put(ci, Vector2(float(fx) + 3.0, float(fy) + 2.0), eye)
	_px_put(ci, Vector2(float(fx) + 3.0, float(fy) + 1.0), Color("f7f7f4"))


static func _px_mark(ci: CanvasItem, at: Vector2, paint: String, trim: Color, eye: Color) -> void:
	var o := at + Vector2(-6.0, -1.0)
	match paint:
		"hero":
			_px_put(ci, o + Vector2(0.0, -2.0), trim)
			_px_put(ci, o + Vector2(1.0, -1.0), trim)
			_px_put(ci, o + Vector2(0.0, -1.0), trim.lightened(0.2))
			_px_put(ci, o + Vector2(1.0, 0.0), trim)
			_px_put(ci, o + Vector2(2.0, 1.0), trim)
		"sword":
			_px_put(ci, o + Vector2(1.0, -1.0), trim)
			_px_put(ci, o + Vector2(0.0, 0.0), trim)
			_px_put(ci, o + Vector2(2.0, 0.0), trim)
			_px_put(ci, o + Vector2(1.0, 1.0), trim)
		"saber", "suicide":
			_px_put(ci, o + Vector2(1.0, -2.0), trim.lightened(0.25))
			_px_put(ci, o + Vector2(0.0, -1.0), trim)
			_px_put(ci, o + Vector2(1.0, -1.0), trim.lightened(0.15))
			_px_put(ci, o + Vector2(2.0, 0.0), trim)
			_px_put(ci, o + Vector2(1.0, 1.0), trim.darkened(0.15))
		"lancer":
			_px_put(ci, o + Vector2(1.0, -2.0), eye)
			_px_put(ci, o + Vector2(0.0, -1.0), trim)
			_px_put(ci, o + Vector2(1.0, -1.0), eye)
			_px_put(ci, o + Vector2(2.0, -1.0), trim)
		"berserker":
			_px_run_x(ci, int(round(o.x)), int(round(o.x)) + 3, int(round(o.y)) - 2, trim)
			_px_put(ci, o + Vector2(0.0, -3.0), trim.lightened(0.2))
			_px_put(ci, o + Vector2(2.0, -3.0), trim.lightened(0.2))
		"horse":
			_px_put(ci, o + Vector2(1.0, -1.0), trim)
			_px_put(ci, o + Vector2(0.0, 0.0), trim.lightened(0.2))
			_px_put(ci, o + Vector2(2.0, 0.0), trim.lightened(0.2))
			_px_put(ci, o + Vector2(1.0, 0.0), trim)
			_px_put(ci, o + Vector2(1.0, 1.0), trim)
		"assassin":
			_px_put(ci, o + Vector2(0.0, -1.0), eye)
			_px_put(ci, o + Vector2(2.0, -1.0), eye)
			_px_put(ci, o + Vector2(1.0, 1.0), trim)
		"heal":
			_px_put(ci, o + Vector2(1.0, -1.0), trim)
			_px_run_x(ci, int(round(o.x)), int(round(o.x)) + 2, int(round(o.y)), trim)
			_px_put(ci, o + Vector2(1.0, 1.0), trim)
		"level":
			_px_put(ci, o + Vector2(1.0, -2.0), trim.lightened(0.3))
			_px_put(ci, o + Vector2(0.0, -1.0), trim)
			_px_put(ci, o + Vector2(1.0, -1.0), trim.lightened(0.15))
			_px_put(ci, o + Vector2(1.0, 0.0), trim)
		"shield":
			_px_put(ci, o + Vector2(1.0, -2.0), trim.lightened(0.25))
			_px_run_x(ci, int(round(o.x)), int(round(o.x)) + 2, int(round(o.y)) - 1, trim)
			_px_put(ci, o + Vector2(1.0, 0.0), trim.darkened(0.1))
		_:
			pass


static func _px_scarf(ci: CanvasItem, chest: Vector2, snap: float, color: Color, ink: Color) -> void:
	var neck := chest + Vector2(-1.0, -8.0)
	var end := chest + Vector2(-16.0, 4.0)
	var tip := end + Vector2(-4.0, 7.0)
	if snap > 12.0:
		end = chest + Vector2(11.0 + snap * 0.22, 3.0)
		tip = end + Vector2(5.0, 7.0)
	_px_line(ci, neck, end, ink, 3)
	_px_line(ci, neck, end, color, 2)
	_px_line(ci, end, tip, color.darkened(0.12), 2)
	_px_put(ci, end + Vector2(0.0, 1.0), color.lightened(0.12))
	_px_put(ci, tip, color.lightened(0.18))


static func _px_quiver(ci: CanvasItem, chest: Vector2, trim: Color, ink: Color) -> void:
	var wood := Color("6b4a32")
	var left := int(round(chest.x)) - 14
	var top := int(round(chest.y)) - 8
	for y in range(0, 12):
		_px_run_x(ci, left - 1, left + 5, top + y, ink)
		_px_run_x(ci, left, left + 4, top + y, wood)
	_px_run_x(ci, left, left + 4, top, wood.lightened(0.15))
	_px_line(ci, chest + Vector2(-12.0, -8.0), chest + Vector2(-6.0, -4.0), trim.darkened(0.2), 1)
	_px_put(ci, chest + Vector2(-12.0, -11.0), trim)
	_px_put(ci, chest + Vector2(-11.0, -12.0), trim.lightened(0.25))
	_px_put(ci, chest + Vector2(-10.0, -11.0), trim)
	_px_put(ci, chest + Vector2(-13.0, -10.0), Color("c8b48a"))


static func _px_hip_sword(ci: CanvasItem, chest: Vector2, trim: Color, ink: Color) -> void:
	var hilt := chest + Vector2(2.0, 7.0)
	var end := chest + Vector2(10.0, 16.0)
	_px_line(ci, hilt, end, ink, 2)
	_px_line(ci, hilt + Vector2(1.0, 1.0), end, Color("2a241c"), 1)
	_px_put(ci, hilt, trim)
	_px_put(ci, end, trim.lightened(0.2))


static func _px_leg(ci: CanvasItem, hip: Vector2, foot: Vector2, pants: Color, trim: Color, ink: Color, wraps: int) -> void:
	var knee := (hip + foot) * 0.5 + Vector2(-2.0, -1.0)
	var bend := clampf(hip.distance_to(foot), 8.0, 24.0)
	knee.y -= maxf(0.0, 16.0 - bend)
	var ankle := foot + Vector2(0.0, -3.0)
	_px_line(ci, hip, knee, ink, 3)
	_px_line(ci, knee, ankle, ink, 3)
	_px_line(ci, hip, knee, pants, 2)
	_px_line(ci, knee, ankle, pants.lightened(0.05), 2)
	_px_boot(ci, foot, trim, ink, wraps)


static func _px_boot(ci: CanvasItem, foot: Vector2, trim: Color, ink: Color, wraps: int) -> void:
	var upper := Color("2a241c")
	var fx := int(round(foot.x))
	var fy := int(round(foot.y))
	_px_run_x(ci, fx - 3, fx + 4, fy, ink)
	_px_run_x(ci, fx - 2, fx + 3, fy - 1, upper)
	_px_run_x(ci, fx - 2, fx + 3, fy - 2, upper.lightened(0.1))
	_px_put(ci, Vector2(float(fx) + 3.0, float(fy) - 2.0), upper.lightened(0.22))
	for i in wraps:
		_px_run_x(ci, fx - 2, fx + 2, fy - 3 - i * 2, trim)
		_px_run_x(ci, fx - 2, fx + 2, fy - 4 - i * 2, trim.lightened(0.12))
		if i > 0:
			_px_run_x(ci, fx - 2, fx + 2, fy - 2 - i * 2, upper)


static func _px_arm(ci: CanvasItem, shoulder: Vector2, hand: Vector2, sleeve: Color, glove: Color, ink: Color, bare: bool) -> void:
	var delta := hand - shoulder
	var mid := (shoulder + hand) * 0.5
	var elbow := mid + Vector2(-2.0, 3.0)
	if delta.length() > 3.0:
		var perp := Vector2(-delta.y, delta.x).normalized()
		if perp.y < 0.0:
			perp = -perp
		if perp.x > 0.15:
			perp = -perp
		elbow = mid + perp * clampf(delta.length() * 0.16, 2.0, 6.0)
	var thick := 3 if bare else 2
	_px_line(ci, shoulder, elbow, ink, thick + 1)
	_px_line(ci, elbow, hand, ink, thick + 1)
	_px_line(ci, shoulder, elbow, sleeve, thick)
	_px_line(ci, elbow, hand, sleeve.lightened(0.06), thick)
	_px_put(ci, hand, glove)
	_px_put(ci, hand + Vector2(1.0, 0.0), glove.lightened(0.12))
	_px_put(ci, hand + Vector2(0.0, 1.0), glove.darkened(0.12))


static func _px_bracer(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	var dir := Vector2(-1.0, 1.0)
	_px_put(ci, hand + dir, trim)
	_px_put(ci, hand + dir + Vector2(0.0, 1.0), trim.darkened(0.1))
	_px_put(ci, hand + dir + Vector2(1.0, 0.0), trim.lightened(0.2))


static func _px_weapon(ci: CanvasItem, cycle: String, phase: String, beat: int, t: float, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, ground: float, trim: Color, cloth: Color, blade: Color, ink: Color) -> void:
	var steel := blade
	if steel.a < 0.01:
		steel = trim.lightened(0.28)
	match cycle:
		"bow":
			_px_bow(ci, beat, t, front, rear, trim, ink)
		"shield":
			_px_shield(ci, front, trim, ink)
		"spear", "polearm":
			_px_spear(ci, rear, tip, steel, trim, ink)
		"axe":
			_px_axe(ci, rear, tip, steel, ink)
		"bomb_dive", "bomb_throw":
			_px_bomb(ci, tip, trim, beat, t, ink)
		"staff":
			_px_staff(ci, beat, t, front, tip, ground, steel, ink)
		"scroll":
			_px_scroll(ci, beat, rear, front, steel, trim, cloth, ink)
		"nodachi":
			_px_blade(ci, front, tip, steel, trim, ink, 3.2, true)
		"assassin":
			_px_blade(ci, front, tip, steel, trim, ink, 1.4, false)
		"horse":
			_px_blade(ci, front, tip, steel, trim, ink, 2.4, true)
		_:
			_px_blade(ci, rear, tip, steel, trim, ink, 2.2, true)


static func _px_blade(ci: CanvasItem, hand: Vector2, tip: Vector2, steel: Color, trim: Color, ink: Color, curve: float, hilt: bool) -> void:
	var dir := tip - hand
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	if side.y > 0.0:
		side = -side
	var mid := hand.lerp(tip, 0.5) + side * curve
	if hilt:
		var pommel := hand - n * 5.0
		_px_line(ci, pommel, hand, ink, 3)
		_px_line(ci, pommel, hand, Color("3a342c"), 2)
		_px_put(ci, pommel, trim)
		_px_put(ci, hand - n * 2.5, trim)
		_px_line(ci, hand + side * 3.0, hand - side * 3.0, trim.lightened(0.12), 1)
	_px_line(ci, hand, mid, ink, 3)
	_px_line(ci, mid, tip, ink, 3)
	_px_line(ci, hand, mid, steel, 2)
	_px_line(ci, mid, tip, steel, 2)
	_px_line(ci, hand + side, mid + side, steel.lightened(0.28), 1)
	_px_line(ci, mid + side, tip, steel.lightened(0.28), 1)
	_px_put(ci, tip, steel.lightened(0.4))


static func _px_bow(ci: CanvasItem, beat: int, t: float, front: Vector2, rear: Vector2, trim: Color, ink: Color) -> void:
	var wood := Color("6b4a32")
	var top := front + Vector2(1.0, -14.0)
	var bot := front + Vector2(1.0, 14.0)
	for i in 15:
		var ang := lerpf(-1.2, 1.2, float(i) / 14.0)
		var p := front + Vector2(cos(ang), sin(ang)) * 14.0
		_px_put(ci, p, ink)
		_px_put(ci, p + Vector2(-1.0, 0.0), wood)
	_px_put(ci, top, trim)
	_px_put(ci, bot, trim)
	_px_put(ci, front, trim.darkened(0.1))
	var released := beat >= 3
	var string_at := front + Vector2(-2.0, 0.0)
	if beat >= 1 and not released:
		string_at = rear
	var cord := Color("f3e6c8")
	_px_line(ci, top, string_at, cord, 1)
	_px_line(ci, string_at, bot, cord, 1)
	if released:
		var fly := front + Vector2(lerpf(8.0, 30.0, t), -1.0)
		_px_line(ci, front + Vector2(4.0, 0.0), fly, cord, 1)
		_px_put(ci, fly, trim)
		return
	var aim := front - rear
	if aim.length() < 1.0:
		aim = Vector2(10.0, 0.0)
	aim = aim.normalized() * (11.0 if beat >= 1 else 8.0)
	_px_line(ci, rear, rear + aim, cord, 1)
	_px_put(ci, rear + aim, trim)


static func _px_shield(ci: CanvasItem, hand: Vector2, trim: Color, ink: Color) -> void:
	var at := hand + Vector2(7.0, 1.0)
	var wood := Color("6b4a32")
	var plank := Color("8a6240")
	_px_ell(ci, at, 12.0, 14.0, ink)
	_px_ell(ci, at, 11.0, 13.0, trim)
	_px_ell(ci, at, 8.0, 10.0, wood)
	var cx := int(round(at.x))
	var top := int(round(at.y)) - 8
	for y in range(0, 17):
		_px_put(ci, Vector2(float(cx) - 3.0, float(top + y)), plank)
		_px_put(ci, Vector2(float(cx) + 2.0, float(top + y)), wood.darkened(0.12))
	_px_ell(ci, at, 3.0, 3.0, trim)
	_px_put(ci, at + Vector2(-1.0, -1.0), trim.lightened(0.35))
	for i in range(-10, 11):
		_px_put(ci, at + Vector2(float(i), -11.0), trim.lightened(0.18))


static func _px_spear(ci: CanvasItem, rear: Vector2, tip: Vector2, steel: Color, trim: Color, ink: Color) -> void:
	var dir := tip - rear
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var butt := rear - n * 10.0
	var neck := tip - n * 6.0
	_px_line(ci, butt, neck, ink, 3)
	_px_line(ci, butt, neck, Color("c8b48a"), 2)
	_px_put(ci, butt, trim)
	var side := Vector2(-n.y, n.x)
	_px_fill(ci, PackedVector2Array([
		neck + side * 2.5,
		tip,
		neck - side * 2.5,
	]), steel)
	_px_line(ci, neck, tip, steel.lightened(0.35), 1)


static func _px_axe(ci: CanvasItem, rear: Vector2, tip: Vector2, steel: Color, ink: Color) -> void:
	var dir := tip - rear
	if dir.length() < 1.0:
		dir = Vector2(0.0, -1.0)
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x)
	_px_line(ci, rear, tip - dir * 2.0, ink, 3)
	_px_line(ci, rear, tip - dir * 2.0, Color("6b4a32"), 2)
	var head := PackedVector2Array([
		tip - dir * 3.0,
		tip + side * 11.0,
		tip + dir * 7.0 + side * 3.0,
		tip + dir * 2.0 - side * 2.0,
	])
	_px_fill(ci, head, ink)
	_px_fill(ci, PackedVector2Array([
		tip - dir * 2.0,
		tip + side * 9.0,
		tip + dir * 6.0 + side * 2.0,
		tip + dir * 1.0 - side * 1.0,
	]), steel)
	_px_put(ci, tip + side * 2.0, Color("3a2a14"))
	_px_put(ci, tip + side * 3.0, Color("3a2a14"))
	_px_put(ci, tip + side * 4.0, steel.lightened(0.3))


static func _px_bomb(ci: CanvasItem, tip: Vector2, trim: Color, beat: int, t: float, ink: Color) -> void:
	var body := Color("1a1214")
	_px_ell(ci, tip, 7.0, 7.0, ink)
	_px_ell(ci, tip, 6.0, 6.0, body)
	_px_ell(ci, tip + Vector2(-1.0, -1.0), 2.0, 2.0, body.lightened(0.18))
	var cy := int(round(tip.y))
	_px_run_x(ci, int(round(tip.x)) - 4, int(round(tip.x)) + 4, cy, trim)
	var fuse := tip + Vector2(2.0, -6.0)
	_px_line(ci, tip + Vector2(1.0, -4.0), fuse, Color("c8b48a"), 1)
	var spark := fuse + Vector2(1.0, -2.0 - float(beat))
	if beat >= 3:
		spark += Vector2(t * 2.0, -t * 2.0)
	_px_put(ci, spark, Color("f2d38a"))
	_px_put(ci, spark + Vector2(1.0, 0.0), Color("fff4d2"))
	_px_put(ci, spark + Vector2(0.0, 1.0), trim)


static func _px_staff(ci: CanvasItem, beat: int, t: float, front: Vector2, tip: Vector2, ground: float, gem: Color, ink: Color) -> void:
	var foot := Vector2(front.x, ground)
	var wood := Color("6b4a32")
	var delta := tip - foot
	var steps := int(ceil(delta.length()))
	if steps < 1:
		steps = 1
	for i in steps + 1:
		var p := foot.lerp(tip, float(i) / float(steps))
		var twist := 0.0
		if i % 2 == 0:
			twist = 1.0
		_px_put(ci, p + Vector2(twist, 0.0), ink)
		_px_put(ci, p + Vector2(twist - 1.0, 0.0), wood)
	var side := Vector2(3.0, 0.0)
	_px_fill(ci, PackedVector2Array([
		tip + Vector2(0.0, -5.0),
		tip + side,
		tip + Vector2(0.0, 4.0),
		tip - side,
	]), gem)
	_px_put(ci, tip + Vector2(0.0, -4.0), gem.lightened(0.35))
	_px_put(ci, tip + Vector2(-1.0, -1.0), Color("f7fffe"))
	if beat == 2:
		var fly := tip.lerp(tip + Vector2(34.0, 6.0), t)
		_px_put(ci, fly, Color(gem.r, gem.g, gem.b, 0.85))
		_px_put(ci, fly + Vector2(1.0, 0.0), Color(1, 1, 1, 0.8))
		_px_put(ci, fly + Vector2(-1.0, 1.0), Color(gem.r, gem.g, gem.b, 0.45))


static func _px_scroll(ci: CanvasItem, beat: int, rear: Vector2, front: Vector2, paper: Color, trim: Color, cloth: Color, ink: Color) -> void:
	var mid := (front + rear) * 0.5
	var span := front.distance_to(rear)
	if span < 11.0:
		var left := int(round(mid.x)) - 2
		var top := int(round(mid.y)) - 7
		for y in range(0, 14):
			_px_run_x(ci, left - 1, left + 4, top + y, ink)
			_px_run_x(ci, left, left + 3, top + y, paper)
		_px_run_x(ci, left, left + 3, top, trim)
		_px_run_x(ci, left, left + 3, top + 13, trim)
		return
	var x0 := int(floor(minf(front.x, rear.x)))
	var x1 := int(ceil(maxf(front.x, rear.x)))
	var y0 := int(round(mid.y)) - 6
	for y in range(0, 13):
		_px_run_x(ci, x0, x1, y0 + y, paper)
	_px_run_x(ci, x0, x0 + 2, y0, trim)
	_px_run_x(ci, x1 - 2, x1, y0, trim)
	_px_run_x(ci, x0, x0 + 2, y0 + 12, trim)
	_px_run_x(ci, x1 - 2, x1, y0 + 12, trim)
	var ink_line := cloth.darkened(0.45)
	_px_run_x(ci, x0 + 4, x1 - 4, y0 + 4, ink_line)
	_px_run_x(ci, x0 + 4, x1 - 4, y0 + 7, ink_line)
	if beat == 2:
		_px_put(ci, mid + Vector2(0.0, -10.0), trim.lightened(0.3))
		_px_put(ci, mid + Vector2(1.0, -9.0), Color("f2d38a"))


static func _px_horse(ci: CanvasItem, trim: Color, step: float, drop: float, ink: Color) -> void:
	var base := Vector2(0.0, drop)
	var body := Color("5a3d2e")
	var dark := Color("3a281c")
	var mane := Color("1a120e")
	_px_line(ci, base + Vector2(-14.0, 6.0), base + Vector2(-24.0, 12.0), mane, 2)
	_px_line(ci, base + Vector2(-15.0, 8.0), base + Vector2(-22.0, 16.0), dark, 2)
	_px_ell(ci, base + Vector2(-2.0, 9.0), 16.0, 7.0, ink)
	_px_ell(ci, base + Vector2(0.0, 8.0), 14.0, 6.0, dark)
	_px_ell(ci, base + Vector2(1.0, 7.0), 12.0, 5.0, body)
	_px_run_x(ci, int(round(base.x)) - 6, int(round(base.x)) + 8, int(round(base.y)) + 10, body.lightened(0.12))
	_px_ell(ci, base + Vector2(15.0, 2.0), 6.0, 5.0, ink)
	_px_ell(ci, base + Vector2(16.0, 2.0), 5.0, 4.0, body)
	_px_line(ci, base + Vector2(13.0, -1.0), base + Vector2(12.0, -6.0), mane, 2)
	_px_line(ci, base + Vector2(16.0, -1.0), base + Vector2(18.0, -5.0), mane, 1)
	_px_put(ci, base + Vector2(18.0, 1.0), ink)
	_px_put(ci, base + Vector2(19.0, 1.0), Color("f4f1ea"))
	_px_line(ci, base + Vector2(12.0, 3.0), base + Vector2(21.0, 4.0), trim, 1)
	_px_put(ci, base + Vector2(20.0, 5.0), trim.lightened(0.2))
	var hoofs: Array[float] = [-13.0, -3.0, 8.0, 15.0]
	for i in hoofs.size():
		var hx := hoofs[i]
		var gait := step if i % 2 == 0 else -step
		var hip := base + Vector2(hx, 12.0)
		var hoof := Vector2(hx + gait * 7.0, base.y + 22.0)
		_px_line(ci, hip, hoof, ink, 2)
		_px_line(ci, hip, hoof, dark, 1)
		_px_run_x(ci, int(round(hoof.x)) - 1, int(round(hoof.x)) + 2, int(round(hoof.y)), ink)
	_px_ell(ci, base + Vector2(2.0, 5.0), 7.0, 3.0, Color("8e2430"))
	_px_run_x(ci, int(round(base.x)) - 5, int(round(base.x)) + 8, int(round(base.y)) + 3, trim)
	_px_run_x(ci, int(round(base.x)) - 5, int(round(base.x)) + 8, int(round(base.y)) + 7, trim)


static func _px_put(ci: CanvasItem, at: Vector2, color: Color) -> void:
	if color.a < 0.01:
		return
	var p := _around(at)
	ci.draw_rect(Rect2(floor(p.x), floor(p.y), 1.0, 1.0), color, true)


static func _px_run_x(ci: CanvasItem, x0: int, x1: int, y: int, color: Color) -> void:
	if color.a < 0.01:
		return
	if x1 < x0:
		var swap := x0
		x0 = x1
		x1 = swap
	if absf(_tilt) < 0.001:
		var left := _around(Vector2(float(x0), float(y)))
		ci.draw_rect(Rect2(floor(left.x), floor(left.y), float(x1 - x0 + 1), 1.0), color, true)
		return
	for x in range(x0, x1 + 1):
		_px_put(ci, Vector2(float(x), float(y)), color)


static func _px_line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, thick: int) -> void:
	var delta := b - a
	var steps := int(ceil(delta.length()))
	if steps < 1:
		steps = 1
	var n := Vector2(0.0, 1.0)
	if absf(delta.x) <= absf(delta.y):
		n = Vector2(1.0, 0.0)
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		_px_put(ci, p, color)
		if thick >= 2:
			_px_put(ci, p + n, color)
		if thick >= 3:
			_px_put(ci, p - n, color.darkened(0.22))


static func _px_ell(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var iy := int(ceil(ry))
	for y in range(-iy, iy + 1):
		var ny := float(y) / maxf(ry, 0.5)
		if absf(ny) > 1.0:
			continue
		var hx := rx * sqrt(maxf(0.0, 1.0 - ny * ny))
		var y0 := int(round(center.y)) + y
		_px_run_x(ci, int(floor(center.x - hx)), int(ceil(center.x + hx)), y0, color)


static func _px_fill(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	if pts.size() < 3:
		return
	var min_y := int(floor(pts[0].y))
	var max_y := min_y
	for point in pts:
		min_y = mini(min_y, int(floor(point.y)))
		max_y = maxi(max_y, int(ceil(point.y)))
	var count := pts.size()
	for y in range(min_y, max_y + 1):
		var xs: Array[float] = []
		for i in count:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % count]
			var ay := a.y
			var by := b.y
			if (ay <= float(y) and by > float(y)) or (by <= float(y) and ay > float(y)):
				var den := by - ay
				if absf(den) < 0.0001:
					continue
				var along := (float(y) - ay) / den
				xs.append(lerpf(a.x, b.x, along))
		xs.sort()
		var pair := 0
		while pair + 1 < xs.size():
			_px_run_x(ci, int(floor(xs[pair])), int(ceil(xs[pair + 1])), y, color)
			pair += 2


static func _px_map(ci: CanvasItem, origin: Vector2, rows: Array[String], colors: Dictionary) -> void:
	var ox := int(round(origin.x))
	var oy := int(round(origin.y))
	for y in rows.size():
		var row: String = rows[y]
		var run_x := -1
		var run_c := Color(0, 0, 0, 0)
		for x in row.length():
			var ch := row.substr(x, 1)
			var col := Color(0, 0, 0, 0)
			if colors.has(ch):
				col = colors[ch] as Color
			if col.a < 0.01:
				if run_x >= 0:
					_px_run_x(ci, ox + run_x, ox + x - 1, oy + y, run_c)
					run_x = -1
				continue
			if run_x < 0:
				run_x = x
				run_c = col
			elif col != run_c:
				_px_run_x(ci, ox + run_x, ox + x - 1, oy + y, run_c)
				run_x = x
				run_c = col
		if run_x >= 0:
			_px_run_x(ci, ox + run_x, ox + row.length() - 1, oy + y, run_c)


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
	var paint := str(look.get("paint", ""))
	var faction := str(look.get("faction", "ninja"))
	var cycle := _cycle_id(paint, weapon)
	var motion := _motion(phase, t, clock, cycle, beat)
	var lean := float(motion["lean"])
	var squat := float(motion["squat"])
	var step := float(motion["step"])
	var breath := float(motion["breath"])
	var rise := float(motion["rise"])
	var rear_off: Vector2 = motion["rear"]
	var front_off: Vector2 = motion["front"]
	var tip_off: Vector2 = motion["tip"]
	var mount: bool = look["mount"]
	var lift := -18.0 if mount else -2.0
	var drop := squat + rise
	var ground := 18.0 + rise * 0.35
	var chest := Vector2(lean + 1.0, lift + drop - breath)
	var rear := chest + rear_off
	var front := chest + front_off
	var tip := chest + tip_off
	_tilt = 0.0
	_ellipse(ci, Vector2(lean * 0.2, 22.0), 16.0 + absf(step) * 3.0, 4.2, Color(0, 0, 0, 0.32))
	if phase == "act" and beat == contact_beat(weapon) and t > 0.4:
		_ellipse(ci, Vector2(10.0 + t * 12.0, 21.0), 8.0, 2.4, Color(1, 0.94, 0.82, 0.32 * (1.0 - t)))
	_tilt = float(motion["tilt"])
	if mount and not bool(look.get("sheet", false)):
		_horse(ci, cloth, trim, step, drop)
	var snap := 0.0
	if phase == "act":
		snap = tip.x - chest.x
	if cycle == "saber_navy":
		_paint_saber(ci, chest, rear, front, tip, step, ground, phase, snap)
		if phase == "act" and beat == contact_beat(weapon) and t > 0.35:
			_arc(ci, front, 18.0 + t * 14.0, -1.2, 1.0, 14, Color(0.89, 0.69, 0.2, (1.0 - t) * 0.75), 3.0)
		_tilt = 0.0
		return
	if bool(look.get("sheet", false)):
		_paint_sheet(ci, look, chest, rear, front, tip, step, ground, phase, beat, t, cycle, snap, mount, flash, drop)
		if phase == "act" and beat == contact_beat(weapon) and t > 0.35 and not _is_quiet(cycle):
			_arc(ci, front, 16.0 + t * 12.0, -1.15, 0.95, 14, Color(trim.r, trim.g, trim.b, (1.0 - t) * 0.8), 3.0)
		_tilt = 0.0
		return
	_back(ci, chest, faction, weapon, cloth, trim, bool(look.get("pack", true)), snap)
	if not mount:
		_leg(ci, chest + Vector2(-3.5, 12.0), Vector2(-5.0 - step * 11.0, ground), cloth.darkened(0.34), 3.2)
	_torso(ci, chest, cloth, trim, faction)
	if not mount:
		_leg(ci, chest + Vector2(3.0, 12.0), Vector2(6.0 + step * 12.0, ground), cloth.darkened(0.08), 3.5)
	_head(ci, chest + Vector2(1.6, -16.0), skin, cloth, trim, faction, weapon, phase)
	var sleeve := cloth.darkened(0.12)
	var rear_tone := skin if faction == "soldier" else cloth.darkened(0.05)
	_arm(ci, chest + Vector2(-4.0, -1.0), rear, rear_tone, sleeve, 2.6)
	_arm(ci, chest + Vector2(5.0, -4.0), front, skin, sleeve, 2.9)
	_dot(ci, front, 2.2, skin)
	_tool(ci, cycle, phase, beat, t, chest, rear, front, tip, ground, trim, cloth)
	if phase == "act" and beat == contact_beat(weapon) and t > 0.35 and not _is_quiet(cycle):
		var alpha := (1.0 - t) * 0.8
		_arc(ci, front, 16.0 + t * 12.0, -1.15, 0.95, 14, Color(trim.r, trim.g, trim.b, alpha), 3.0)
	_tilt = 0.0


static func paint_saber_front(ci: CanvasItem, navy_skin: bool = true) -> void:
	_tilt = 0.0
	var cloth := Color("1e3f8f") if navy_skin else Color("1a1216")
	var cloth_dark := Color("142c68") if navy_skin else Color("0c0a0e")
	var trim := Color("e2b034") if navy_skin else Color("c44536")
	var scarf := Color("c73636") if navy_skin else Color("c44536")
	var wrap := Color("d2c2a4") if navy_skin else Color("f0c9a0")
	var eye := Color("f0c14a") if navy_skin else Color("f0c9a0")
	var face := Color("0c1a3a") if navy_skin else Color("2a211c")
	_ellipse(ci, Vector2(0.0, 32.0), 20.0, 4.4, Color(0, 0, 0, 0.28))
	_line(ci, Vector2(-7.0, 12.0), Vector2(-8.0, 28.0), cloth_dark, 6.4)
	_line(ci, Vector2(7.0, 12.0), Vector2(8.0, 28.0), cloth, 6.4)
	_line(ci, Vector2(-13.0, 27.0), Vector2(-3.0, 29.0), trim, 2.8)
	_line(ci, Vector2(3.0, 27.0), Vector2(13.0, 29.0), trim, 2.8)
	_poly(ci, PackedVector2Array([
		Vector2(-14.0, -8.0),
		Vector2(14.0, -8.0),
		Vector2(12.0, 16.0),
		Vector2(-12.0, 16.0),
	]), cloth)
	_line(ci, Vector2(-12.0, 15.0), Vector2(12.0, 15.0), trim, 2.2)
	_line(ci, Vector2(-13.0, -6.0), Vector2(-11.0, 14.0), trim, 1.6)
	_line(ci, Vector2(13.0, -6.0), Vector2(11.0, 14.0), trim, 1.6)
	_line(ci, Vector2(0.0, -4.0), Vector2(0.0, 8.0), trim, 1.5)
	_box(ci, Rect2(-12.0, 5.0, 24.0, 5.2), scarf)
	_poly(ci, PackedVector2Array([
		Vector2(-2.4, 10.0),
		Vector2(2.4, 10.0),
		Vector2(0.0, 18.0),
	]), scarf.darkened(0.08))
	_poly(ci, PackedVector2Array([
		Vector2(-6.0, -6.0),
		Vector2(-18.0, 4.0),
		Vector2(-12.0, 16.0),
	]), scarf)
	_poly(ci, PackedVector2Array([
		Vector2(6.0, -6.0),
		Vector2(18.0, 6.0),
		Vector2(12.0, 18.0),
	]), scarf.darkened(0.08))
	_box(ci, Rect2(-10.0, -8.0, 20.0, 4.0), scarf)
	_line(ci, Vector2(-12.0, -4.0), Vector2(-20.0, 8.0), cloth_dark, 5.2)
	_line(ci, Vector2(-20.0, 8.0), Vector2(-18.0, 16.0), wrap, 4.6)
	_dot(ci, Vector2(-18.0, 17.0), 2.6, wrap)
	_saber_sword(ci, Vector2(16.0, 2.0), Vector2(18.0, -2.0), Vector2(24.0, -34.0))
	_line(ci, Vector2(12.0, -4.0), Vector2(18.0, 4.0), cloth, 5.2)
	_line(ci, Vector2(18.0, 4.0), Vector2(17.0, 10.0), wrap, 4.4)
	_dot(ci, Vector2(17.2, 11.0), 2.5, wrap)
	_ellipse(ci, Vector2(0.0, -22.0), 13.5, 14.0, cloth_dark)
	_ellipse(ci, Vector2(0.0, -21.0), 12.0, 12.6, cloth)
	_poly(ci, PackedVector2Array([
		Vector2(-5.0, -30.0),
		Vector2(0.0, -38.0),
		Vector2(5.0, -30.0),
	]), cloth)
	if navy_skin:
		_poly(ci, PackedVector2Array([
			Vector2(0.0, -33.0),
			Vector2(2.2, -30.6),
			Vector2(0.0, -28.2),
			Vector2(-2.2, -30.6),
		]), trim)
	_ellipse(ci, Vector2(0.0, -20.0), 7.2, 7.6, face)
	_dot(ci, Vector2(-3.1, -20.4), 2.35, eye)
	_dot(ci, Vector2(3.1, -20.4), 2.35, eye)
	_dot(ci, Vector2(-3.1, -20.4), 1.0, Color("1a1408"))
	_dot(ci, Vector2(3.1, -20.4), 1.0, Color("1a1408"))
	_tilt = 0.0


static func _paint_saber(ci: CanvasItem, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, step: float, ground: float, phase: String, snap: float) -> void:
	var navy := Color("1e3f8f")
	var navy_dark := Color("142c68")
	var gold := Color("e2b034")
	var red := Color("c73636")
	var wrap := Color("d2c2a4")
	var behind := tip.x < chest.x - 4.0
	if behind:
		_saber_sword(ci, rear, front, tip)
	_saber_scarf(ci, chest, snap, red)
	var back_foot := Vector2(-5.0 - step * 11.0, ground)
	var front_foot := Vector2(6.0 + step * 12.0, ground)
	_leg(ci, chest + Vector2(-3.5, 12.0), back_foot, navy_dark, 3.6)
	_saber_tunic(ci, chest, navy, gold, red)
	_leg(ci, chest + Vector2(3.0, 12.0), front_foot, navy, 3.8)
	_line(ci, back_foot + Vector2(-3.0, -2.0), back_foot + Vector2(4.0, -1.0), gold, 2.2)
	_line(ci, front_foot + Vector2(-2.0, -2.0), front_foot + Vector2(5.0, -1.0), gold, 2.2)
	_saber_hood(ci, chest + Vector2(1.4, -16.0), navy, navy_dark, gold, phase)
	_arm(ci, chest + Vector2(-4.0, -1.0), rear, wrap, navy_dark, 3.3)
	_arm(ci, chest + Vector2(5.0, -4.0), front, wrap, navy, 3.5)
	if not behind:
		_saber_sword(ci, rear, front, tip)


static func _saber_scarf(ci: CanvasItem, chest: Vector2, snap: float, red: Color) -> void:
	var neck := chest + Vector2(0.0, -3.0)
	var end := chest + Vector2(-18.0, 9.0)
	var flap := end + Vector2(-4.0, 8.0)
	if snap > 12.0:
		end = chest + Vector2(12.0 + snap * 0.3, 5.0)
		flap = end + Vector2(5.0, 8.0)
	_poly(ci, PackedVector2Array([neck, end, flap]), red)
	_poly(ci, PackedVector2Array([
		neck,
		neck + Vector2(6.0, 3.0),
		flap,
	]), red.darkened(0.1))


static func _saber_tunic(ci: CanvasItem, chest: Vector2, navy: Color, gold: Color, red: Color) -> void:
	_poly(ci, PackedVector2Array([
		chest + Vector2(-7.0, -6.0),
		chest + Vector2(7.0, -5.0),
		chest + Vector2(8.0, 8.0),
		chest + Vector2(3.0, 14.0),
		chest + Vector2(-5.0, 12.0),
	]), navy)
	_line(ci, chest + Vector2(-5.0, 12.0), chest + Vector2(3.0, 14.0), gold, 2.0)
	_line(ci, chest + Vector2(6.0, -4.0), chest + Vector2(8.0, 8.0), gold, 1.6)
	_box(ci, Rect2(chest.x - 6.0, chest.y + 6.0, 14.0, 4.5), red)
	_poly(ci, PackedVector2Array([
		chest + Vector2(2.0, 10.0),
		chest + Vector2(5.0, 10.0),
		chest + Vector2(3.5, 16.0),
	]), red.darkened(0.08))


static func _saber_hood(ci: CanvasItem, at: Vector2, navy: Color, navy_dark: Color, gold: Color, phase: String) -> void:
	_ellipse(ci, at + Vector2(-3.0, 2.0), 8.4, 9.0, navy_dark)
	_ellipse(ci, at + Vector2(2.2, 0.4), 7.2, 8.2, navy)
	_poly(ci, PackedVector2Array([
		at + Vector2(0.5, -4.0),
		at + Vector2(3.2, -8.0),
		at + Vector2(6.0, -3.0),
	]), navy)
	_poly(ci, PackedVector2Array([
		at + Vector2(2.2, -5.2),
		at + Vector2(3.4, -6.6),
		at + Vector2(4.6, -5.0),
		at + Vector2(3.4, -4.2),
	]), gold)
	if phase == "hurt" or phase == "fall":
		_line(ci, at + Vector2(1.4, -1.2), at + Vector2(5.6, -0.2), Color("f4f4f0"), 1.3)
		return
	_dot(ci, at + Vector2(3.2, -1.0), 1.35, Color("f0c14a"))
	_dot(ci, at + Vector2(5.4, -0.7), 1.15, Color("f0c14a"))


static func _saber_sword(ci: CanvasItem, rear: Vector2, front: Vector2, tip: Vector2) -> void:
	var dir := tip - front
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	var two_hands := front.distance_to(rear) < 16.0
	var grip := front
	if two_hands:
		grip = (front + rear) * 0.5
		_line(ci, rear - n * 5.0, front + n * 2.0, Color("6b4a32"), 3.4)
	else:
		_line(ci, front - n * 7.0, front + n * 2.0, Color("6b4a32"), 3.4)
	_dot(ci, grip - n * 7.0, 2.6, Color("e2b034"))
	var guard := front + n * 2.0
	_poly(ci, PackedVector2Array([
		guard + side * 8.0,
		guard + n * 5.5,
		guard - side * 8.0,
		guard - n * 4.5,
	]), Color("e2b034"))
	var base := guard + n * 4.0
	_poly(ci, PackedVector2Array([
		base + side * 4.6,
		base - side * 4.6,
		tip,
	]), Color("9aa3b0"))
	_line(ci, base + side * 4.2, tip, Color("e8edf2"), 1.2)
	_line(ci, base, tip - n * 2.0, Color("d24545"), 2.3)


static func _is_quiet(cycle: String) -> bool:
	return cycle == "bow" or cycle == "crossbow" or cycle == "staff" or cycle == "scroll" or cycle == "bomb_dive" or cycle == "bomb_throw"


static func _cycle_id(paint: String, weapon: String) -> String:
	if weapon == "bow" or weapon == "crossbow":
		return weapon
	if paint == "saber" and saber_navy:
		return "saber_navy"
	match paint:
		"horse":
			return "horse"
		"assassin":
			return "assassin"
		"runner":
			return "runner"
		"suicide":
			return "bomb_dive"
		"bomber":
			return "bomb_throw"
		_:
			return weapon


static func _motion(phase: String, t: float, clock: float, cycle: String, beat: int) -> Dictionary:
	var pose := _sample(cycle, 0, 0.0)
	var lean := _num(pose, "lean")
	var squat := _num(pose, "squat")
	var step := sin(clock * 1.7) * 0.12
	var breath := sin(clock * 2.1) * 0.8
	var rise := _num(pose, "rise")
	var tilt := _num(pose, "tilt")
	var rear := _vec(pose, "rear")
	var front := _vec(pose, "front")
	var tip := _vec(pose, "tip")
	match phase:
		"debut":
			rise = (1.0 - t) * 22.0
			squat = (1.0 - t) * 8.0
			step = lerpf(0.7, 0.0, t)
			tilt = lerpf(0.35, tilt, t)
			breath = 0.0
			rear = Vector2(-8.0, 12.0).lerp(rear, t)
			front = Vector2(4.0, 12.0).lerp(front, t)
			tip = Vector2(6.0, 16.0).lerp(tip, t)
		"march":
			step = sin(clock * 8.0)
			if cycle == "runner":
				step = sin(clock * 11.0) * 1.2
			lean += 3.5
			squat += absf(step) * 2.0
			breath = 0.2
			tilt += 0.12 + step * 0.04
			var bob := Vector2(step * 1.6, absf(step) * 1.1)
			rear += bob
			front += bob
			tip += bob
		"act":
			pose = _sample(cycle, beat, t)
			lean = _num(pose, "lean")
			squat = _num(pose, "squat")
			step = _num(pose, "step")
			tilt = _num(pose, "tilt")
			rise = _num(pose, "rise")
			breath = 0.0
			rear = _vec(pose, "rear")
			front = _vec(pose, "front")
			tip = _vec(pose, "tip")
			if cycle == "runner":
				step = sin(clock * 11.0) * 1.15
			elif cycle == "horse":
				step = sin(clock * 8.0)
		"hurt":
			lean = lerpf(-2.0, lean, t)
			squat = lerpf(5.0, squat, t)
			step = lerpf(-0.7, 0.0, t)
			tilt = lerpf(-0.62, tilt, t)
			breath = 0.0
			rear = Vector2(-8.0, 8.0).lerp(rear, t)
			front = Vector2(2.0, 8.0).lerp(front, t)
			tip = Vector2(4.0, 12.0).lerp(tip, t)
		"fall":
			squat = lerpf(2.0, 18.0, t)
			lean = lerpf(0.0, 10.0, t)
			step = lerpf(0.0, 1.1, t)
			tilt = lerpf(0.0, 1.25, t)
			breath = 0.0
			rise = 0.0
			rear = rear.lerp(Vector2(-4.0, 14.0), t)
			front = front.lerp(Vector2(10.0, 12.0), t)
			tip = tip.lerp(Vector2(16.0, 14.0), t)
	return {
		"lean": lean,
		"squat": squat,
		"step": step,
		"breath": breath,
		"rise": rise,
		"tilt": tilt,
		"rear": rear,
		"front": front,
		"tip": tip,
	}


static func _num(row: Dictionary, key: String) -> float:
	return float(row[key])


static func _vec(row: Dictionary, key: String) -> Vector2:
	return row[key] as Vector2


static func _sample(cycle: String, beat: int, along: float) -> Dictionary:
	var frames := _frames(cycle)
	var i := clampi(beat, 0, 3)
	var a := frames[i] as Dictionary
	var b := frames[i + 1] as Dictionary
	var stay := clampf(along, 0.0, 1.0)
	var eased := 1.0 - (1.0 - stay) * (1.0 - stay)
	return _mix(a, b, eased)


static func _mix(a: Dictionary, b: Dictionary, amount: float) -> Dictionary:
	return {
		"rear": _vec(a, "rear").lerp(_vec(b, "rear"), amount),
		"front": _vec(a, "front").lerp(_vec(b, "front"), amount),
		"tip": _vec(a, "tip").lerp(_vec(b, "tip"), amount),
		"lean": lerpf(_num(a, "lean"), _num(b, "lean"), amount),
		"squat": lerpf(_num(a, "squat"), _num(b, "squat"), amount),
		"step": lerpf(_num(a, "step"), _num(b, "step"), amount),
		"tilt": lerpf(_num(a, "tilt"), _num(b, "tilt"), amount),
		"rise": lerpf(_num(a, "rise"), _num(b, "rise"), amount),
	}


static func _f(rx: float, ry: float, fx: float, fy: float, tx: float, ty: float, lean: float, squat: float, step: float, tilt: float, rise: float = 0.0) -> Dictionary:
	return {
		"rear": Vector2(rx, ry),
		"front": Vector2(fx, fy),
		"tip": Vector2(tx, ty),
		"lean": lean,
		"squat": squat,
		"step": step,
		"tilt": tilt,
		"rise": rise,
	}


static func _k(arm: float, tilt: float, squat: float, step: float, lean: float, rise: float = 0.0) -> Dictionary:
	return {"arm": arm, "tilt": tilt, "squat": squat, "step": step, "lean": lean, "rise": rise}


# Frame 0 is the carry. Beat i eases from frame i to frame i + 1.
# Hands and the weapon tip are offsets from the chest: +x is forward, +y is down.
static func _frames(cycle: String) -> Array:
	match cycle:
		"bow":
			return [
				_f(8, 6, 14, -2, 14, -2, 1, 0, 0.1, 0.04),
				_f(-16, 8, 14, -2, -16, 2, -1, 0.4, -0.2, -0.08),
				_f(10, -1, 16, -4, 12, -2, 1, 0.2, 0.1, 0.04),
				_f(1, -13, 20, -6, 2, -12, -2, 0.6, -0.15, -0.16),
				_f(8, 5, 14, -1, 32, -2, 2, 0, 0.2, 0.08),
			]
		"crossbow":
			return [
				_f(2, 6, 12, 8, 20, 6, 1, 0, 0.1, 0.04),
				_f(-12, 14, 10, 8, -4, 12, 0, 1.2, -0.15, 0.02),
				_f(4, 6, 14, 5, 22, 4, 1, 0.3, 0.1, 0.02),
				_f(0, -8, 16, -10, 24, -10, -1, 0.4, 0.05, -0.1),
				_f(4, 4, 12, 4, 36, 2, 2, 0, 0.2, 0.1),
			]
		"nodachi":
			return [
				_f(-2, -4, 6, -10, 8, -32, 1, 0, 0.1, 0.06),
				_f(0, 8, 8, 4, 16, 16, 0, 0.4, 0.05, 0.02),
				_f(-14, -8, -6, -18, -24, -4, -5, 1, -0.5, -0.42),
				_f(6, 6, 14, 0, 38, 18, 8, 0.3, 1.1, 0.4),
				_f(0, -2, 6, -8, 10, -26, 1, 0.2, 0.1, 0.08),
			]
		"saber_navy":
			return [
				_f(-9, 0, 6, 2, 16, 26, 2, 0, 0.25, 0.04),
				_f(2, 8, 8, 4, 6, -36, 0, 0.2, 0.4, 0.02),
				_f(-2, 0, 4, -6, -16, -34, -1, 0.3, 0.7, -0.16),
				_f(4, 6, 12, 2, 38, 14, 6, 0.2, 1.0, 0.22),
				_f(-7, 2, 6, 6, 14, 24, 2, 0.1, 0.25, 0.04),
			]
		"shield":
			return [
				_f(0, 6, 11, 1, 11, 1, 1, 0.2, 0.1, 0.04),
				_f(-2, 2, 7, -16, 7, -16, -1, 1, -0.1, -0.2),
				_f(-4, 6, 6, -14, 6, -14, -2, 6.5, -0.25, -0.08),
				_f(-10, 4, 24, -1, 24, -1, 6, 0.4, 1.1, 0.32),
				_f(0, 6, 11, 1, 11, 1, 1, 0.2, 0.1, 0.04),
			]
		"spear":
			return [
				_f(-4, 3, 12, 0, 26, -2, 2, 0, 0.15, 0.05),
				_f(-18, 7, 8, 1, 22, -1, -2, 0.4, -0.7, -0.12),
				_f(-10, 3, 14, -1, 32, -2, 1, 0.2, 0.15, 0.02),
				_f(4, 2, 22, -2, 48, -2, 7, 0.2, 1.25, 0.22),
				_f(-4, 3, 12, 0, 26, -2, 2, 0, 0.15, 0.05),
			]
		"polearm":
			return [
				_f(1, 12, 3, -2, 4, -40, 1, 0, 0.1, 0.06),
				_f(-6, -8, 0, -18, -18, -30, -3, 0.6, -0.4, -0.28),
				_f(-14, 8, 10, -2, 28, -8, 1, 0.2, 0.1, 0.02),
				_f(2, 4, 20, -4, 50, -6, 7, 0.2, 1.15, 0.24),
				_f(1, 12, 3, -2, 4, -40, 1, 0, 0.1, 0.06),
			]
		"axe":
			return [
				_f(-2, 0, 6, -10, 12, -28, 1, 0.3, 0.1, 0.06),
				_f(-6, 12, 2, 8, -18, 20, -1, 1.6, -0.3, 0.1),
				_f(-2, -16, 4, -24, 2, -42, -4, 1.2, -0.15, -0.45),
				_f(4, 6, 14, 10, 26, 18, 6, 6, 0.9, 0.48),
				_f(0, -4, 6, -12, 10, -24, 1, 0.4, 0.1, 0.08),
			]
		"hammer":
			return [
				_f(-2, 10, 6, 8, 10, 4, 1, 0.5, 0.05, 0.04),
				_f(0, 9, 6, 7, 9, 3, 0, 0.8, -0.1, 0.02),
				_f(-2, -6, 5, -14, 12, -28, -2, 4.5, -0.3, -0.28),
				_f(6, 8, 14, 12, 22, 20, 5, 1.4, 1.0, 0.4),
				_f(2, 2, 8, -2, 12, -10, 1, 0.6, 0.1, 0.06),
			]
		"shortsword":
			return [
				_f(2, 12, 8, 5, 11, 22, 1, 0, 0.1, 0.04),
				_f(6, 2, 8, 3, 8, -8, 0, 0.4, -0.15, -0.04),
				_f(-3, -13, 5, 1, 1, -30, -2, 1, -0.2, -0.18),
				_f(12, 4, 8, 3, 14, 20, 4, 0.2, 0.75, 0.38),
				_f(2, 12, 8, 5, 11, 22, 1, 0, 0.1, 0.04),
			]
		"runner":
			return [
				_f(-6, 6, 16, 1, 28, 0, 2, 0.2, 0.4, 0.08),
				_f(-4, 8, 14, 7, 26, 6, 1, 2.6, 0.5, 0.18),
				_f(-4, 6, 18, 5, 30, 3, 2, 1.4, 0.6, 0.1),
				_f(-2, 4, 28, 0, 42, -1, 3, 0.4, 0.7, 0.08),
				_f(-6, 5, 12, 1, 22, 0, 2, 0.2, 0.5, 0.06),
			]
		"assassin":
			return [
				_f(-4, 10, 8, 8, -2, 18, 1, 3.2, 0.25, 0.06),
				_f(-2, 12, 6, 12, -4, 20, 0, 7.5, -0.1, 0.08),
				_f(-2, 10, 5, 11, 2, 16, 1, 6.5, 0.1, 0.04),
				_f(2, 2, 20, -4, 34, -8, 6, 0.8, 0.6, 0.3),
				_f(-4, 10, 8, 8, -2, 18, 1, 3.2, 0.3, 0.06),
			]
		"horse":
			return [
				_f(10, 4, 4, 10, 8, 18, 0, 0, 0.2, 0.02),
				_f(8, 2, 2, -6, 2, -28, 1, 0, 0.3, -0.06),
				_f(6, 4, 14, 2, 30, 8, 11, 0, 0.4, 0.12),
				_f(4, 6, 20, 6, 40, 12, 13, 0, 0.5, 0.16),
				_f(8, 3, 4, 2, 14, -6, 1, 0, 0.2, 0.02),
			]
		"bomb_dive":
			return [
				_f(-4, 8, 3, 12, 4, 14, 1, 0.2, 0.1, 0.04),
				_f(0, 6, 6, 4, 6, 2, 0, 0.6, 0, 0.02),
				_f(1, 3, 9, 1, 5, -1, 1, 0.8, 0.15, -0.04),
				_f(6, 10, 14, 12, 20, 14, 10, 5, 1.0, 0.7),
				_f(8, 12, 16, 14, 26, 16, 12, 6, 0.8, 0.85),
			]
		"bomb_throw":
			return [
				_f(-6, 8, 2, 12, 0, 14, 1, 0.2, 0.1, 0.04),
				_f(-2, 4, 8, 2, 10, 0, 0, 0.4, 0, 0.02),
				_f(-4, 4, -14, -10, -18, -14, -1, 0.6, -0.2, -0.25),
				_f(2, 2, 22, -12, 38, -18, 5, 0.2, 0.4, 0.28),
				_f(0, 4, 14, -2, 22, -6, 2, 0.2, 0.15, 0.08),
			]
		"staff":
			return [
				_f(1, 8, 6, 4, 5, -30, 0, 0, 0.05, -0.04),
				_f(0, 10, 4, 8, 3, -28, 0, 0.8, 0, 0.02),
				_f(-2, -14, 4, 6, 3, -32, -1, 0.2, 0.05, -0.12, -2),
				_f(2, -4, 6, 2, 4, -30, 0, 0, 0.1, -0.06, -1),
				_f(1, 8, 6, 4, 5, -30, 0, 0, 0.05, -0.04),
			]
		"scroll":
			return [
				_f(2, 12, 6, 12, 4, 12, 0, 0.2, 0.05, 0.02),
				_f(4, 2, 8, 2, 6, 2, 0, 0.3, 0, -0.04, 0.4),
				_f(-6, 0, 16, -2, 5, -1, -1, 0.2, 0.05, -0.1, -1),
				_f(-5, 2, 15, 1, 5, 1, 0, 0, 0.05, -0.06, -1.5),
				_f(2, 12, 6, 12, 4, 12, 0, 0.2, 0.05, 0.02),
			]
		"katana", "dagger":
			return [
				_f(3, 12, 10, 5, 12, 22, 1, 0, 0.1, 0.04),
				_f(4, 2, 8, 3, 2, -12, 0, 0.4, -0.2, -0.06),
				_f(-2, -16, 6, 0, -4, -38, -5, 1.2, -0.75, -0.4),
				_f(16, -1, 18, 3, 42, 1, 8, 0.2, 1.15, 0.28),
				_f(3, 11, 9, 5, 13, 21, 1, 0, 0.15, 0.05),
			]
		_:
			return [
				_f(3, 12, 10, 5, 12, 22, 1, 0, 0.1, 0.04),
				_f(4, 2, 8, 3, 2, -12, 0, 0.4, -0.2, -0.06),
				_f(-2, -16, 6, 0, -4, -38, -5, 1.2, -0.75, -0.4),
				_f(16, -1, 18, 3, 42, 1, 8, 0.2, 1.15, 0.28),
				_f(3, 11, 9, 5, 13, 21, 1, 0, 0.15, 0.05),
			]


static func _back(ci: CanvasItem, chest: Vector2, faction: String, weapon: String, cloth: Color, trim: Color, pack: bool, snap: float) -> void:
	if faction == "soldier":
		if pack:
			_box(ci, Rect2(chest.x - 16.0, chest.y - 2.0, 10.0, 14.0), cloth.darkened(0.35))
			_line(ci, chest + Vector2(-14.0, -2.0), chest + Vector2(-6.0, -8.0), cloth.darkened(0.2), 2.0)
		return
	var hem := chest + Vector2(-18.0, 24.0)
	if snap > 10.0:
		hem = chest + Vector2(8.0 + snap * 0.42, 8.0)
		_poly(ci, PackedVector2Array([
			chest + Vector2(-2.0, -8.0),
			chest + Vector2(5.0, -1.0),
			hem,
			chest + Vector2(-8.0, 6.0),
		]), trim.darkened(0.1))
	else:
		var trail := 14.0 + maxf(0.0, -snap) * 0.2
		hem = chest + Vector2(-16.0 - trail * 0.28, 22.0)
		_poly(ci, PackedVector2Array([
			chest + Vector2(-4.0, -8.0),
			chest + Vector2(-10.0, 2.0),
			hem,
			chest + Vector2(2.0, 8.0),
		]), trim.darkened(0.15))
	if weapon == "bow":
		_box(ci, Rect2(chest.x - 13.0, chest.y - 4.0, 7.0, 13.0), cloth.lightened(0.08))
		_line(ci, chest + Vector2(-11.0, -6.0), chest + Vector2(-9.0, -1.0), trim, 1.3)


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


static func _tool(ci: CanvasItem, cycle: String, phase: String, beat: int, t: float, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, ground: float, trim: Color, cloth: Color, blade: Color = Color(0, 0, 0, 0)) -> void:
	var steel := trim.lightened(0.28)
	if blade.a > 0.01:
		steel = blade
	match cycle:
		"bow":
			_bow(ci, beat, t, front, rear, trim, cloth)
		"crossbow":
			_crossbow(ci, beat, t, chest, front, rear, trim)
		"shield":
			_buckler(ci, front, trim, cloth)
		"spear", "polearm":
			_shaft(ci, rear, tip, trim)
		"axe":
			_haft(ci, rear, tip, Color("c8b48a"), 3.2)
			_axe_head(ci, rear, tip, trim)
		"hammer":
			_haft(ci, rear, tip, Color("6b4a32"), 4.0)
			_box(ci, Rect2(tip.x - 8.0, tip.y - 6.0, 16.0, 12.0), trim.darkened(0.08))
		"bomb_dive", "bomb_throw":
			_ellipse(ci, tip, 6.6, 6.6, Color(0.1, 0.08, 0.08))
			_dot(ci, tip + Vector2(1.0, -2.0), 2.2, trim)
			_line(ci, tip + Vector2(2.0, -5.0), tip + Vector2(5.0, -10.0), Color("e7c07a"), 1.4)
		"staff":
			var gem := trim
			if blade.a > 0.01:
				gem = blade
			_staff(ci, beat, t, front, tip, ground, gem)
		"scroll":
			var paper := trim
			if blade.a > 0.01:
				paper = blade
			_scroll(ci, beat, rear, front, paper, cloth)
		"nodachi":
			_line(ci, rear, front, cloth.darkened(0.35), 3.6)
			_blade_to(ci, front, tip, steel, phase, beat, 3.4)
		"runner", "assassin", "horse":
			_blade_to(ci, front, tip, steel, phase, beat, 2.4 if cycle != "horse" else 3.0)
			if cycle == "horse" or cycle == "assassin":
				_line(ci, chest + Vector2(2.0, 10.0), chest + Vector2(12.0, 20.0), cloth.darkened(0.45), 2.6)
		"katana", "shortsword", "dagger":
			_line(ci, chest + Vector2(2.0, 10.0), chest + Vector2(12.0, 22.0), cloth.darkened(0.45), 3.0)
			_blade_to(ci, rear, tip, steel, phase, beat, 3.0 if cycle != "shortsword" else 2.5)
			_guard(ci, rear, tip, cloth.darkened(0.3))
		_:
			_blade_to(ci, rear, tip, steel, phase, beat, 3.0)


static func _bow(ci: CanvasItem, beat: int, t: float, front: Vector2, rear: Vector2, trim: Color, cloth: Color) -> void:
	_arc(ci, front, 14.0, -1.2, 1.2, 14, trim, 2.6)
	var top := front + Vector2(1.0, -14.0)
	var bot := front + Vector2(1.0, 14.0)
	var released := beat >= 3
	var string_at := front + Vector2(-2.0, 0.0)
	if beat >= 1 and not released:
		string_at = rear
	_line(ci, top, string_at, Color("f3e6c8"), 1.3)
	_line(ci, string_at, bot, Color("f3e6c8"), 1.3)
	if released:
		var fly := front + Vector2(lerpf(8.0, 32.0, t), -1.0)
		_line(ci, front + Vector2(6.0, -1.0), fly, Color(1, 0.97, 0.88, 0.85), 1.8)
		_point(ci, fly, front, trim)
		return
	var dir := Vector2(-8.0, -9.0)
	if beat == 1:
		dir = front - rear
	elif beat >= 2:
		dir = front - rear
	if dir.length() < 1.0:
		dir = Vector2(10.0, 0.0)
	dir = dir.normalized() * (12.0 if beat >= 1 else 9.0)
	_line(ci, rear - dir.normalized() * 3.0, rear + dir, cloth.lightened(0.35), 1.6)
	_point(ci, rear + dir, rear, trim)


static func _crossbow(ci: CanvasItem, beat: int, t: float, chest: Vector2, front: Vector2, rear: Vector2, trim: Color) -> void:
	_box(ci, Rect2(chest.x - 8.0, chest.y + 8.0, 8.0, 10.0), trim.darkened(0.35))
	var stock_back := front + Vector2(-16.0, 3.0)
	var stock_fore := front + Vector2(14.0, -2.0)
	_line(ci, stock_back, stock_fore, Color("6b4a32"), 4.2)
	var along := stock_fore - stock_back
	if along.length() < 1.0:
		along = Vector2(1.0, 0.0)
	var prod := Vector2(-along.normalized().y, along.normalized().x)
	_line(ci, stock_fore + prod * 7.0, stock_fore - prod * 7.0, trim, 2.4)
	if beat >= 3:
		var fly := stock_fore + Vector2(lerpf(6.0, 28.0, t), -1.0)
		_line(ci, stock_fore, fly, Color(1, 0.97, 0.88, 0.85), 1.8)
		_point(ci, fly, stock_fore, trim)
		return
	var bolt := Vector2(11.0, -1.0)
	if beat >= 1:
		bolt = stock_fore - rear
		if bolt.length() > 14.0:
			bolt = bolt.normalized() * 14.0
		if bolt.length() < 1.0:
			bolt = Vector2(11.0, 0.0)
	_line(ci, rear, rear + bolt, trim.lightened(0.25), 1.7)
	_point(ci, rear + bolt, rear, trim)


static func _buckler(ci: CanvasItem, hand: Vector2, trim: Color, cloth: Color) -> void:
	_box(ci, Rect2(hand.x - 1.0, hand.y - 14.0, 18.0, 28.0), trim)
	_box(ci, Rect2(hand.x + 3.0, hand.y - 8.0, 10.0, 16.0), cloth.lightened(0.08))
	_dot(ci, hand + Vector2(8.0, 0.0), 2.0, trim.lightened(0.35))


static func _shaft(ci: CanvasItem, rear: Vector2, tip: Vector2, trim: Color) -> void:
	var dir := tip - rear
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	_line(ci, rear - n * 12.0, tip, Color("c8b48a"), 2.8)
	_point(ci, tip, rear, trim)


static func _haft(ci: CanvasItem, rear: Vector2, tip: Vector2, color: Color, width: float) -> void:
	_line(ci, rear, tip, color, width)


static func _axe_head(ci: CanvasItem, rear: Vector2, tip: Vector2, trim: Color) -> void:
	var dir := tip - rear
	if dir.length() < 1.0:
		dir = Vector2(0.0, -1.0)
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x)
	_poly(ci, PackedVector2Array([
		tip - dir * 3.0,
		tip + side * 12.0,
		tip + dir * 8.0 + side * 3.0,
		tip + dir * 2.0 - side * 2.0,
	]), trim)


static func _staff(ci: CanvasItem, beat: int, t: float, front: Vector2, tip: Vector2, ground: float, trim: Color) -> void:
	var foot := Vector2(front.x, ground)
	_line(ci, foot, tip, Color("c8b48a"), 2.8)
	_dot(ci, tip, 4.4, trim)
	if beat == 1:
		_arc(ci, tip, lerpf(2.5, 6.5, t), 0.0, TAU, 16, trim, 1.6)
	elif beat == 2:
		var fly := tip.lerp(tip + Vector2(34.0, 6.0), t)
		_arc(ci, fly, 6.5, 0.0, TAU, 18, trim, 2.1)
		_dot(ci, fly, 2.2, Color(1, 1, 1, 0.85))
	elif beat >= 3:
		_arc(ci, tip + Vector2(10.0, 2.0), 3.2, 0.0, TAU, 12, Color(trim.r, trim.g, trim.b, 0.45), 1.4)


static func _scroll(ci: CanvasItem, beat: int, rear: Vector2, front: Vector2, trim: Color, cloth: Color) -> void:
	var mid := (front + rear) * 0.5
	var span := front.distance_to(rear)
	if span < 11.0:
		_box(ci, Rect2(mid.x - 4.0, mid.y - 8.0, 8.0, 16.0), trim)
		return
	var left := minf(front.x, rear.x)
	_box(ci, Rect2(left, mid.y - 8.0, span, 16.0), trim.lightened(0.12))
	_line(ci, Vector2(left + 3.0, mid.y - 2.0), Vector2(left + span - 3.0, mid.y - 2.0), cloth.darkened(0.35), 1.2)
	if beat == 2:
		_dot(ci, mid + Vector2(0.0, -12.0), 2.6, Color("f2d38a"))


static func _blade_to(ci: CanvasItem, hand: Vector2, tip: Vector2, color: Color, phase: String, beat: int, width: float) -> void:
	var dir := tip - hand
	if dir.length() < 1.0:
		return
	if phase == "act" and beat >= 2:
		var ghost := Color(color.r, color.g, color.b, 0.28)
		_line(ci, hand, hand + dir * 0.65 + Vector2(-6.0, -4.0), ghost, width * 0.7)
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x) * width
	_poly(ci, PackedVector2Array([hand + side, hand - side, tip]), color)
	_line(ci, hand, tip, color.lightened(0.35), 1.1)


static func _guard(ci: CanvasItem, hand: Vector2, tip: Vector2, color: Color) -> void:
	var dir := tip - hand
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x) * 5.0
	var at := hand + n * 4.0
	_line(ci, at + side, at - side, color, 2.2)


static func _point(ci: CanvasItem, tip: Vector2, origin: Vector2, color: Color) -> void:
	var dir := tip - origin
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x) * 3.6
	var base := tip - dir * 8.0
	_poly(ci, PackedVector2Array([base + side, tip + dir * 2.0, base - side]), color)


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
	var delta := hand - shoulder
	var mid := (shoulder + hand) * 0.5
	var elbow := mid + Vector2(-3.0, 4.0)
	if delta.length() > 3.0:
		var perp := Vector2(-delta.y, delta.x).normalized()
		if perp.y < 0.0:
			perp = -perp
		if perp.x > 0.15:
			perp = -perp
		elbow = mid + perp * clampf(delta.length() * 0.18, 3.0, 7.0)
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
