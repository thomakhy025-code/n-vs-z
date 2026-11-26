extends RefCounted

static var _tilt: float = 0.0
static var saber_navy: bool = false
static var sheet_on: Dictionary = {}
static var school_on: Dictionary = {}
static var hero_dress: String = ""
static var paints: int = 0


static func as_monster(look: Dictionary) -> Dictionary:
	var row := look.duplicate()
	row["skin"] = Color("8d9a7a")
	row["cloth"] = Color("141816")
	row["trim"] = Color("5d7a48")
	row["faction"] = "cursed"
	row["horns"] = true
	row["sash"] = false
	return row


static func as_human(look: Dictionary) -> Dictionary:
	var row := look.duplicate()
	row["skin"] = Color("cbb8a6")
	row["cloth"] = Color("241418")
	row["trim"] = Color("8e2430")
	row["faction"] = "clan"
	row["sash"] = true
	row["horns"] = false
	return row


static func wears_own(kind: String) -> bool:
	return kind == "sword" or kind == "archer" or kind == "shield" or kind == "saber" or kind == "lancer" or kind == "berserker" or kind == "horse" or kind == "suicide" or kind == "assassin" or kind == "heal" or kind == "level" or kind == "hero"


static func dress_foe(look: Dictionary) -> Dictionary:
	if is_human_body(str(look.get("paint", ""))):
		return as_human(look)
	return as_monster(look)


static func look(kind: String) -> Dictionary:
	var dress := ""
	if bool(school_on.get(kind, false)):
		dress = "school"
	elif kind == "hero" and hero_dress == "school":
		dress = "school"
	var sheet := false
	if dress == "" and sheet_on.has(kind):
		sheet = bool(sheet_on[kind])
	return look_as(kind, sheet, kind == "saber" and saber_navy, dress)


static func look_as(kind: String, sheet: bool, navy: bool, dress: String = "") -> Dictionary:
	var row := _painted(kind)
	row["paint"] = kind
	if dress == "school" and wears_own(kind):
		row["dress"] = "school"
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
			return _look(Color("e7c2a4"), Color("241418"), Color("e24b3b"), "bomb", false, "court")
		"oni":
			return _look(Color("e0c2a0"), Color("3d3428"), Color("e6c36a"), "polearm", false, "soldier")
		"howler":
			return _look(Color("c4a882"), Color("6a4a32"), Color("e6c36a"), "hammer", false, "beast")
		"viper":
			return _look(Color("d7e2a8"), Color("3d6a45"), Color("c44536"), "spear", false, "beast")
		"storm":
			return _look(Color("d5e8f6"), Color("1c2438"), Color("7ec8ff"), "staff", false, "beast")
		"herald":
			return _look(Color("e6c36a"), Color("4a3048"), Color("e6c36a"), "staff", false, "beast")
		"shell":
			return _look(Color("8a9a78"), Color("7a8490"), Color("d7dde6"), "hammer", false, "beast")
		"reaver":
			return _look(Color("e0c2a0"), Color("3a1818"), Color("e24b3b"), "axe", false, "beast")
		"boss":
			return _look(Color("e0c2a0"), Color("241c16"), Color("e6c36a"), "polearm", false, "soldier")
		"spear":
			return _soldier(Color("3e4c62"), Color("c44536"), "spear", "cap", true)
		"scout":
			return _soldier(Color("6d7a52"), Color("e7c07a"), "dagger", "hood", false)
		"guard":
			return _soldier(Color("2a3140"), Color("9aa4b0"), "hammer", "heavy", true)
		"crossbow":
			return _soldier(Color("4a4034"), Color("6b7c4a"), "crossbow", "kettle", true)
		"satchel":
			return _soldier(Color("5c4034"), Color("e24b3b"), "bomb", "bare", false)
		"captain":
			return _soldier(Color("241c18"), Color("e6c36a"), "polearm", "crest", true)
		"general":
			return _soldier(Color("1a1612"), Color("f0d78c"), "polearm", "crest", true)
		"knives":
			return _look(Color("e7c2a4"), Color("9a3030"), Color("e6c36a"), "dagger", false, "court")
		"firebow":
			return _look(Color("e7c2a4"), Color("2a2420"), Color("e24b3b"), "bow", false, "court")
		"fan":
			return _look(Color("e7c2a4"), Color("efe2c4"), Color("5d8a48"), "staff", false, "court")
		"ward":
			return _look(Color("e7c2a4"), Color("243044"), Color("d7b56a"), "shield", false, "court")
		"javelin":
			return _look(Color("e7c2a4"), Color("243048"), Color("c4a574"), "spear", false, "court")
		"drum":
			return _look(Color("e7c2a4"), Color("6a3a55"), Color("e6c36a"), "staff", false, "court")
		"crow":
			return _look(Color("1c1e24"), Color("16181e"), Color("e6c36a"), "spear", false, "court")
		"cow":
			return _look(Color("8a5a32"), Color("f0e2c8"), Color("f4efe4"), "spear", false, "court")
		"smog":
			return _look(Color("e7c2a4"), Color("c9a227"), Color("f4efe4"), "staff", false, "court")
		"buck":
			return _look(Color("e7c2a4"), Color("3a4654"), Color("d7b56a"), "crossbow", false, "court")
		"scope":
			return _look(Color("e7c2a4"), Color("3d4a38"), Color("8d97a3"), "bow", false, "court")
		"aria":
			return _look(Color("e7c2a4"), Color("6a3a55"), Color("f4efe4"), "staff", false, "court")
		"moth":
			return _look(Color("d7c4a2"), Color("5c4a38"), Color("e6c36a"), "spear", false, "beast")
		"elder":
			return _look(Color("e6d3c0"), Color("4a4038"), Color("c9c3b2"), "hammer", false, "beast")
		"glut":
			return _look(Color("c4a070"), Color("6a4030"), Color("e24b3b"), "hammer", false, "beast")
		"brood":
			return _look(Color("2a2428"), Color("3a3038"), Color("c44536"), "dagger", false, "beast")
		"ling":
			return _look(Color("2a2428"), Color("4a3840"), Color("e24b3b"), "dagger", false, "beast")
		_:
			return _look(Color("f0c9a0"), Color("1a1e28"), Color("c5ccd6"), "katana", false, "ninja")


static func call_id(paint: String) -> String:
	match paint:
		"sword":
			return "call_say_sword"
		"archer":
			return "call_say_archer"
		"shield":
			return "call_say_shield"
		"saber":
			return "call_say_saber"
		"lancer":
			return "call_say_lancer"
		"berserker":
			return "call_say_berserker"
		"brute":
			return "call_heavy"
		"horse":
			return "call_say_rider"
		"suicide":
			return "call_say_bomb"
		"bomber":
			return "call_bomb"
		"assassin":
			return "call_say_assassin"
		"heal":
			return "call_say_heal"
		"level":
			return "call_say_level"
		"walker", "runner", "spitter":
			return "call_dead"
		"spear":
			return "call_spear"
		"scout":
			return "call_blade"
		"guard":
			return "call_heavy"
		"crossbow":
			return "call_bow"
		"satchel":
			return "call_bomb"
		"howler", "shell":
			return "call_heavy"
		"viper", "herald":
			return "call_dead"
		"storm":
			return "call_magic"
		"reaver":
			return "call_oni"
		"oni", "boss", "captain", "general":
			return "call_oni"
		"knives":
			return "call_blade"
		"firebow":
			return "call_bow"
		"fan", "drum":
			return "call_magic"
		"ward":
			return "call_heavy"
		"javelin":
			return "call_spear"
		"crow":
			return "call_horse"
		"cow":
			return "call_heavy"
		"smog", "aria":
			return "call_magic"
		"buck":
			return "call_bow"
		"scope":
			return "call_spear"
		"moth", "ling":
			return "call_blade"
		"elder":
			return "call_dead"
		"glut", "brood":
			return "call_heavy"
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
	if paint == "runner" or paint == "scout":
		return 0.62
	return 0.92


static func call_pitch(paint: String) -> float:
	match paint:
		"sword", "archer", "shield", "saber", "lancer", "berserker", "horse", "suicide", "assassin", "heal", "level":
			return 1.0
		"runner":
			return 1.16
		"spitter":
			return 1.08
		"bomber":
			return 0.92
		"brute":
			return 0.86
		"howler":
			return 0.78
		"viper":
			return 1.24
		"storm":
			return 1.04
		"herald":
			return 0.82
		"shell":
			return 0.7
		"reaver":
			return 0.9
		"walker", "spear":
			return 0.94
		"scout":
			return 1.16
		"guard":
			return 0.86
		"crossbow":
			return 1.08
		"satchel":
			return 0.92
		"captain", "general":
			return 0.88
		"knives":
			return 1.05
		"firebow":
			return 1.12
		"fan":
			return 0.96
		"ward":
			return 0.74
		"javelin":
			return 0.9
		"drum":
			return 1.08
		"crow":
			return 1.18
		"cow":
			return 0.82
		"smog":
			return 0.9
		"buck":
			return 0.86
		"scope":
			return 0.78
		"aria":
			return 1.14
		"moth":
			return 1.2
		"elder":
			return 0.84
		"glut":
			return 0.7
		"brood":
			return 0.92
		"ling":
			return 1.28
		_:
			return 1.0


static func is_human_body(paint: String) -> bool:
	if _is_court(paint):
		return true
	return paint == "spear" or paint == "scout" or paint == "guard" or paint == "crossbow" or paint == "satchel" or paint == "captain" or paint == "general"


static func _soldier(cloth: Color, trim: Color, weapon: String, helm: String, pack: bool) -> Dictionary:
	var row := _look(Color("e7c2a4"), cloth, trim, weapon, false, "soldier", pack)
	row["sash"] = true
	row["helm"] = helm
	return row


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
	if flash > 0.0:
		var wash := clampf(flash * 4.0, 0.0, 0.72)
		skin = skin.lerp(Color.WHITE, wash)
		cloth = cloth.lerp(Color.WHITE, wash)
		trim = trim.lerp(Color.WHITE, wash)
		eye = eye.lerp(Color.WHITE, wash)
		blade = blade.lerp(Color.WHITE, wash)
	var paint := str(look.get("paint", ""))
	if mount:
		_part_horse(ci, trim, step, drop)
	if scarf.a > 0.2:
		_part_scarf(ci, chest, snap, scarf, false)
	if paint == "archer":
		_part_quiver(ci, chest, trim)
	var pants := cloth.darkened(0.28)
	if cloth.get_luminance() > 0.55:
		pants = Color("2c261e")
	var wraps := 2 if paint == "heal" else 1
	if mount:
		_part_leg(ci, chest + Vector2(-4.0, 9.0), chest + Vector2(-5.0 - step * 3.0, 17.0), pants, trim, wraps)
	else:
		_part_leg(ci, chest + Vector2(-4.0, 11.0), Vector2(-5.0 - step * 11.0, ground), pants, trim, wraps)
	_part_cloth(ci, chest, cloth, trim, bare, paint)
	if mount:
		_part_leg(ci, chest + Vector2(3.0, 9.0), chest + Vector2(7.0 + step * 3.0, 17.0), pants.lightened(0.06), trim, wraps)
	else:
		_part_leg(ci, chest + Vector2(3.0, 11.0), Vector2(6.0 + step * 12.0, ground), pants.lightened(0.06), trim, wraps)
	if paint == "shield":
		_part_hip_sword(ci, chest, trim)
	var head := chest + Vector2(1.6, -16.0)
	_part_hood(ci, head, cloth, trim, eye, mask, phase, paint)
	if scarf.a > 0.2:
		_part_scarf(ci, chest, snap, scarf, true)
	var sleeve := cloth.darkened(0.1)
	var glove := sleeve.lightened(0.24)
	if bare:
		sleeve = skin
		glove = skin.lightened(0.08)
	elif cloth.get_luminance() > 0.55:
		glove = skin
	_part_arm(ci, chest + Vector2(-4.0, -1.0), rear, sleeve, glove, trim, bare)
	_part_arm(ci, chest + Vector2(5.0, -4.0), front, sleeve.lightened(0.05), glove, trim, bare)
	_part_weapon(ci, cycle, phase, beat, t, chest, rear, front, tip, ground, trim, cloth, blade)


static func _part_hood(ci: CanvasItem, at: Vector2, cloth: Color, trim: Color, eye: Color, mask: Color, phase: String, paint: String) -> void:
	_ellipse(ci, at + Vector2(-4.6, 2.4), 9.4, 10.0, cloth.darkened(0.4))
	_ellipse(ci, at + Vector2(1.4, 0.6), 8.0, 8.8, cloth)
	_ellipse(ci, at + Vector2(4.0, -2.2), 3.6, 4.4, cloth.lightened(0.14))
	_poly(ci, PackedVector2Array([
		at + Vector2(0.2, -6.2),
		at + Vector2(3.6, -11.0),
		at + Vector2(7.2, -4.2),
	]), cloth.darkened(0.08))
	_line(ci, at + Vector2(1.4, -8.6), at + Vector2(5.4, -5.2), trim, 1.6)
	_poly(ci, PackedVector2Array([
		at + Vector2(-0.4, -4.2),
		at + Vector2(2.4, -5.4),
		at + Vector2(7.6, -1.6),
		at + Vector2(8.0, 3.8),
		at + Vector2(5.0, 5.0),
		at + Vector2(1.0, 0.6),
	]), trim)
	_ellipse(ci, at + Vector2(4.2, 1.4), 4.6, 3.5, mask)
	_ellipse(ci, at + Vector2(3.6, 0.2), 3.2, 1.5, mask.darkened(0.18))
	_part_mark(ci, at, paint, trim, eye)
	if phase == "hurt" or phase == "fall":
		_line(ci, at + Vector2(2.2, 0.6), at + Vector2(6.4, 1.4), Color("f4f4f0"), 1.4)
		return
	_dot(ci, at + Vector2(5.0, 0.2), 2.5, Color(eye.r, eye.g, eye.b, 0.38))
	_dot(ci, at + Vector2(5.0, 0.4), 1.45, eye)
	_dot(ci, at + Vector2(5.5, 0.0), 0.5, Color("f7f7f4"))


static func _part_mark(ci: CanvasItem, at: Vector2, paint: String, trim: Color, eye: Color) -> void:
	var o := at + Vector2(-6.5, -1.0)
	match paint:
		"hero":
			_line(ci, o + Vector2(0.0, -3.0), o + Vector2(1.4, -0.6), trim, 1.5)
			_line(ci, o + Vector2(1.4, -0.6), o + Vector2(0.2, 1.6), trim, 1.5)
		"sword":
			_poly(ci, PackedVector2Array([
				o + Vector2(1.2, -2.2),
				o + Vector2(2.8, 0.0),
				o + Vector2(1.2, 2.2),
				o + Vector2(-0.4, 0.0),
			]), trim)
		"saber", "suicide", "level":
			_poly(ci, PackedVector2Array([
				o + Vector2(1.2, -3.2),
				o + Vector2(2.6, -0.4),
				o + Vector2(1.2, 0.6),
				o + Vector2(0.0, -0.6),
			]), trim.lightened(0.12))
		"lancer":
			_line(ci, o + Vector2(1.2, -2.8), o + Vector2(1.2, 0.4), eye, 1.6)
			_line(ci, o + Vector2(-0.4, -0.8), o + Vector2(2.8, -0.8), trim, 1.5)
		"berserker":
			_line(ci, o + Vector2(-0.6, -0.4), o + Vector2(0.4, -2.8), trim, 1.6)
			_line(ci, o + Vector2(0.4, -2.8), o + Vector2(1.4, -0.4), trim, 1.6)
			_line(ci, o + Vector2(1.4, -0.4), o + Vector2(2.6, -2.6), trim.lightened(0.15), 1.5)
		"horse":
			_line(ci, o + Vector2(1.2, -2.4), o + Vector2(1.2, 1.6), trim, 1.4)
			_line(ci, o + Vector2(-0.6, -0.4), o + Vector2(3.0, -0.4), trim, 1.4)
		"assassin":
			_dot(ci, o + Vector2(0.2, -1.2), 1.1, eye)
			_dot(ci, o + Vector2(2.4, -1.2), 1.1, eye)
			_poly(ci, PackedVector2Array([
				o + Vector2(1.3, 0.2),
				o + Vector2(2.2, 2.0),
				o + Vector2(0.4, 2.0),
			]), trim)
		"heal":
			_line(ci, o + Vector2(1.2, -2.2), o + Vector2(1.2, 1.8), trim, 1.7)
			_line(ci, o + Vector2(-0.6, -0.2), o + Vector2(3.0, -0.2), trim, 1.7)
		"shield":
			_poly(ci, PackedVector2Array([
				o + Vector2(1.2, -2.6),
				o + Vector2(3.0, 0.2),
				o + Vector2(1.2, 1.4),
				o + Vector2(-0.6, 0.2),
			]), trim)
		_:
			pass


static func _part_cloth(ci: CanvasItem, chest: Vector2, cloth: Color, trim: Color, bare: bool, _paint: String) -> void:
	var wide := 9.4 if bare else 7.6
	_poly(ci, PackedVector2Array([
		chest + Vector2(-wide - 1.4, -5.0),
		chest + Vector2(wide - 2.0, -4.0),
		chest + Vector2(wide - 1.0, 10.0),
		chest + Vector2(-wide + 0.4, 11.0),
	]), cloth.darkened(0.32))
	_poly(ci, PackedVector2Array([
		chest + Vector2(-wide, -7.2),
		chest + Vector2(wide, -5.6),
		chest + Vector2(wide + 0.8, 8.6),
		chest + Vector2(2.2, 13.4),
		chest + Vector2(-wide + 1.2, 11.6),
	]), cloth)
	_poly(ci, PackedVector2Array([
		chest + Vector2(1.2, -6.2),
		chest + Vector2(wide - 0.4, -5.2),
		chest + Vector2(wide + 0.2, 7.4),
		chest + Vector2(2.6, 11.0),
	]), cloth.lightened(0.12))
	_ellipse(ci, chest + Vector2(1.0, 1.4), 4.6, 6.0, trim.darkened(0.06))
	_ellipse(ci, chest + Vector2(0.0, -0.2), 2.0, 2.2, trim.lightened(0.26))


static func _part_leg(ci: CanvasItem, hip: Vector2, foot: Vector2, pants: Color, _trim: Color, _wraps: int) -> void:
	_oval_leg(ci, hip, foot, pants)


static func _part_arm(ci: CanvasItem, shoulder: Vector2, hand: Vector2, sleeve: Color, glove: Color, trim: Color, bare: bool) -> void:
	var delta := hand - shoulder
	var mid := (shoulder + hand) * 0.5
	var elbow := mid + Vector2(-2.0, 3.0)
	if delta.length() > 3.0:
		var perp := Vector2(-delta.y, delta.x).normalized()
		if perp.y < 0.0:
			perp = -perp
		if perp.x > 0.15:
			perp = -perp
		elbow = mid + perp * clampf(delta.length() * 0.16, 2.4, 6.0)
	var upper := 4.0 if bare else 3.2
	var fore := 3.6 if bare else 2.8
	_line(ci, shoulder, elbow, sleeve.darkened(0.08), upper)
	_ellipse(ci, elbow, 2.1, 1.8, sleeve.lightened(0.08))
	_line(ci, elbow, hand, sleeve.lightened(0.06), fore)
	_line(ci, shoulder + Vector2(0.6, -0.4), elbow, sleeve.lightened(0.18), 1.1)
	var wrist := hand.lerp(elbow, 0.22)
	_line(ci, wrist + Vector2(-1.6, 1.2), wrist + Vector2(1.8, -0.8), trim, 1.6)
	_ellipse(ci, hand, 2.5, 2.1, glove)
	_ellipse(ci, hand + Vector2(0.8, -0.6), 1.1, 0.8, glove.lightened(0.2))
	if bare:
		_ellipse(ci, wrist, 2.2, 1.5, trim)
		_line(ci, wrist + Vector2(-1.8, 0.4), wrist + Vector2(1.8, -0.2), trim.lightened(0.25), 1.1)


static func _part_scarf(ci: CanvasItem, chest: Vector2, snap: float, color: Color, knot: bool) -> void:
	var neck := chest + Vector2(0.4, -8.0)
	if knot:
		_ellipse(ci, neck, 5.2, 2.4, color)
		_ellipse(ci, neck + Vector2(1.2, 0.4), 2.2, 1.2, color.darkened(0.12))
		return
	var end := chest + Vector2(-16.0, 6.0)
	var flap := end + Vector2(-3.0, 8.0)
	if snap > 12.0:
		end = chest + Vector2(12.0 + snap * 0.28, 4.0)
		flap = end + Vector2(5.0, 8.0)
	_line(ci, neck, end, color.darkened(0.18), 4.6)
	_line(ci, neck, end, color, 2.8)
	_line(ci, end, flap, color.darkened(0.1), 3.4)
	_line(ci, neck + Vector2(0.6, -0.8), end + Vector2(0.4, -1.0), color.lightened(0.18), 1.2)


static func _part_quiver(ci: CanvasItem, chest: Vector2, trim: Color) -> void:
	var wood := Color("6b4a32")
	_box(ci, Rect2(chest.x - 16.0, chest.y - 9.0, 7.0, 15.0), wood.darkened(0.2))
	_box(ci, Rect2(chest.x - 15.0, chest.y - 8.0, 5.0, 13.0), wood)
	_line(ci, chest + Vector2(-14.5, -8.0), chest + Vector2(-11.0, 4.0), wood.lightened(0.18), 1.2)
	_line(ci, chest + Vector2(-13.0, -8.0), chest + Vector2(-6.0, -2.0), trim.darkened(0.25), 1.4)
	_line(ci, chest + Vector2(-13.5, -12.0), chest + Vector2(-11.0, -7.0), trim, 1.6)
	_line(ci, chest + Vector2(-15.0, -11.0), chest + Vector2(-12.4, -7.4), trim.lightened(0.2), 1.3)
	_line(ci, chest + Vector2(-12.2, -12.4), chest + Vector2(-10.2, -7.2), Color("c8b48a"), 1.2)


static func _part_hip_sword(ci: CanvasItem, chest: Vector2, trim: Color) -> void:
	var hilt := chest + Vector2(1.0, 8.0)
	var end := chest + Vector2(9.0, 16.0)
	_line(ci, hilt, end, Color("1a140e"), 2.4)
	_line(ci, hilt + Vector2(0.6, 0.4), end, Color("c8b48a"), 1.1)
	_dot(ci, hilt, 1.6, trim)
	_dot(ci, end, 1.3, trim.lightened(0.2))


static func _part_weapon(ci: CanvasItem, cycle: String, phase: String, beat: int, t: float, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, ground: float, trim: Color, cloth: Color, blade: Color) -> void:
	var steel := blade
	if steel.a < 0.01:
		steel = trim.lightened(0.28)
	match cycle:
		"bow":
			_part_bow(ci, beat, t, front, rear, trim)
		"shield":
			_part_shield(ci, front, trim)
		"spear", "polearm":
			_part_spear(ci, rear, tip, steel, trim)
		"axe":
			_part_axe(ci, rear, tip, steel)
		"bomb_dive", "bomb_throw":
			_part_bomb(ci, tip, trim, beat, t)
		"staff":
			_part_staff(ci, beat, t, front, tip, ground, steel)
		"scroll":
			_part_scroll(ci, beat, rear, front, steel, trim, cloth)
		"nodachi":
			_part_blade(ci, front, tip, steel, trim, 3.4, true)
		"assassin":
			_part_blade(ci, front, tip, steel, trim, 1.2, false)
		"horse":
			_part_blade(ci, front, tip, steel, trim, 2.6, false)
		_:
			_part_blade(ci, rear, tip, steel, trim, 2.4, false)


static func _part_blade(ci: CanvasItem, hand: Vector2, tip: Vector2, steel: Color, trim: Color, curve: float, dark: bool) -> void:
	var dir := tip - hand
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	if side.y > 0.0:
		side = -side
	var mid := hand.lerp(tip, 0.48) + side * curve
	var pommel := hand - n * 6.0
	_line(ci, pommel, hand, Color("2c261e"), 3.3)
	_line(ci, pommel + n * 1.6, hand - n * 1.4, trim, 2.0)
	_dot(ci, pommel, 1.8, trim.lightened(0.16))
	var guard := Vector2(-n.y, n.x) * 4.4
	_line(ci, hand + guard, hand - guard, trim.lightened(0.08), 2.3)
	var edge := steel
	if dark:
		edge = trim
	_line(ci, hand, mid, steel.darkened(0.16), 3.8)
	_line(ci, mid, tip, steel, 3.2)
	_line(ci, hand + side * 1.1, mid + side * 0.7, edge.lightened(0.22), 1.3)
	_line(ci, mid + side * 0.7, tip, edge.lightened(0.28), 1.15)
	_dot(ci, tip, 1.25, steel.lightened(0.4))


static func _part_bow(ci: CanvasItem, beat: int, t: float, front: Vector2, rear: Vector2, trim: Color) -> void:
	var wood := Color("6b4a32")
	_arc(ci, front + Vector2(-0.6, 0.0), 14.4, -1.25, 1.25, 16, wood.darkened(0.25), 3.4)
	_arc(ci, front, 14.0, -1.2, 1.2, 16, wood, 2.4)
	var top := front + Vector2(1.0, -14.0)
	var bot := front + Vector2(1.0, 14.0)
	_dot(ci, top, 1.7, trim)
	_dot(ci, bot, 1.7, trim)
	_dot(ci, front, 1.8, trim.darkened(0.08))
	var released := beat >= 3
	var string_at := front + Vector2(-2.0, 0.0)
	if beat >= 1 and not released:
		string_at = rear
	var cord := Color("f3e6c8")
	_line(ci, top, string_at, cord, 1.2)
	_line(ci, string_at, bot, cord, 1.2)
	if released:
		var fly := front + Vector2(lerpf(8.0, 30.0, t), -1.0)
		_line(ci, front + Vector2(5.0, 0.0), fly, cord, 1.3)
		_point(ci, fly, front, trim)
		return
	var aim := front - rear
	if aim.length() < 1.0:
		aim = Vector2(10.0, 0.0)
	aim = aim.normalized() * (12.0 if beat >= 1 else 8.0)
	_line(ci, rear - aim.normalized() * 2.0, rear + aim, cord, 1.3)
	_point(ci, rear + aim, rear, trim)
	var nock := rear - aim.normalized() * 2.0
	_line(ci, nock + Vector2(-1.4, -1.6), nock, trim, 1.2)
	_line(ci, nock + Vector2(-1.2, 1.6), nock, trim.lightened(0.15), 1.1)


static func _part_shield(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	var at := hand + Vector2(7.0, 1.0)
	var wood := Color("6b4a32")
	_ellipse(ci, at + Vector2(1.2, 1.4), 12.2, 14.2, trim.darkened(0.35))
	_ellipse(ci, at, 12.0, 14.0, trim)
	_ellipse(ci, at + Vector2(-0.4, -0.4), 9.2, 11.0, wood)
	_ellipse(ci, at + Vector2(-2.2, -2.0), 4.0, 5.0, wood.lightened(0.12))
	_line(ci, at + Vector2(-3.2, -8.4), at + Vector2(-3.2, 8.4), wood.darkened(0.18), 1.3)
	_line(ci, at + Vector2(2.4, -8.0), at + Vector2(2.4, 8.0), wood.lightened(0.16), 1.2)
	_ellipse(ci, at, 3.4, 3.4, trim)
	_ellipse(ci, at + Vector2(-0.6, -0.6), 1.5, 1.5, trim.lightened(0.32))
	_dot(ci, at + Vector2(0.0, -8.6), 1.1, trim.lightened(0.25))
	_dot(ci, at + Vector2(0.0, 8.6), 1.1, trim.darkened(0.1))
	_dot(ci, at + Vector2(-7.4, 0.0), 1.0, trim.lightened(0.12))
	_dot(ci, at + Vector2(7.4, 0.0), 1.0, trim.lightened(0.12))


static func _part_spear(ci: CanvasItem, rear: Vector2, tip: Vector2, steel: Color, trim: Color) -> void:
	var dir := tip - rear
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	var butt := rear - n * 12.0
	var neck := tip - n * 7.0
	_line(ci, butt, neck, Color("8a6a42"), 3.4)
	_line(ci, butt, neck, Color("c8b48a"), 1.5)
	_dot(ci, butt, 1.8, trim)
	_line(ci, neck + side * 2.2, neck - side * 2.2, trim, 2.0)
	_poly(ci, PackedVector2Array([
		neck + side * 2.4,
		tip + n * 1.5,
		neck - side * 2.4,
	]), steel)
	_line(ci, neck, tip, steel.lightened(0.32), 1.1)


static func _part_axe(ci: CanvasItem, rear: Vector2, tip: Vector2, steel: Color) -> void:
	var dir := tip - rear
	if dir.length() < 1.0:
		dir = Vector2(0.0, -1.0)
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x)
	_line(ci, rear, tip - dir * 2.0, Color("5c4030"), 3.6)
	_line(ci, rear, tip - dir * 2.0, Color("c8b48a"), 1.4)
	_dot(ci, rear, 1.7, steel.darkened(0.2))
	_poly(ci, PackedVector2Array([
		tip - dir * 4.0,
		tip + side * 12.0,
		tip + dir * 8.0 + side * 3.0,
		tip + dir * 2.0 - side * 2.0,
	]), steel.darkened(0.22))
	_poly(ci, PackedVector2Array([
		tip - dir * 2.4,
		tip + side * 9.5,
		tip + dir * 6.2 + side * 2.2,
		tip + dir * 1.2 - side * 1.2,
	]), steel)
	_poly(ci, PackedVector2Array([
		tip + side * 2.0,
		tip + side * 5.2,
		tip + side * 3.6 + dir * 1.4,
	]), Color("3a2a14"))
	_line(ci, tip + side * 7.0, tip + side * 2.0, steel.lightened(0.3), 1.2)


static func _part_bomb(ci: CanvasItem, tip: Vector2, trim: Color, beat: int, t: float) -> void:
	var body := Color("1a1214")
	_ellipse(ci, tip + Vector2(1.0, 1.2), 7.2, 7.2, body.darkened(0.2))
	_ellipse(ci, tip, 6.6, 6.6, body)
	_ellipse(ci, tip + Vector2(-1.8, -1.8), 2.4, 2.0, body.lightened(0.22))
	_line(ci, tip + Vector2(-5.0, 0.4), tip + Vector2(5.0, -0.2), trim, 2.2)
	var fuse := tip + Vector2(2.2, -6.2)
	_line(ci, tip + Vector2(1.0, -4.4), fuse, Color("c8b48a"), 1.4)
	var spark := fuse + Vector2(1.2, -2.2 - float(beat) * 0.4)
	if beat >= 3:
		spark += Vector2(t * 2.0, -t * 2.0)
	_dot(ci, spark, 2.2, Color("f2d38a"))
	_dot(ci, spark + Vector2(0.6, -0.4), 1.0, Color("fff6d8"))


static func _part_staff(ci: CanvasItem, beat: int, t: float, front: Vector2, tip: Vector2, ground: float, gem: Color) -> void:
	var foot := Vector2(front.x, ground)
	_line(ci, foot, tip, Color("5c4030"), 3.2)
	_line(ci, foot + Vector2(1.1, 0.0), tip + Vector2(-0.6, 0.0), Color("8a6244"), 1.5)
	var side := Vector2(3.2, 0.0)
	_poly(ci, PackedVector2Array([
		tip + Vector2(0.0, -6.2),
		tip + side + Vector2(0.4, -0.4),
		tip + Vector2(0.0, 3.6),
		tip - side,
	]), gem.darkened(0.12))
	_poly(ci, PackedVector2Array([
		tip + Vector2(-0.4, -4.6),
		tip + Vector2(1.6, -0.6),
		tip + Vector2(-0.2, 2.2),
		tip + Vector2(-2.0, -0.8),
	]), gem.lightened(0.18))
	_dot(ci, tip + Vector2(-0.6, -1.6), 1.2, Color("f7fffe"))
	_dot(ci, tip, 5.2, Color(gem.r, gem.g, gem.b, 0.22))
	if beat == 2:
		var fly := tip.lerp(tip + Vector2(34.0, 6.0), t)
		_dot(ci, fly, 3.4, Color(gem.r, gem.g, gem.b, 0.7))
		_dot(ci, fly, 1.4, Color(1, 1, 1, 0.85))


static func _part_scroll(ci: CanvasItem, beat: int, rear: Vector2, front: Vector2, paper: Color, trim: Color, cloth: Color) -> void:
	var mid := (front + rear) * 0.5
	var span := front.distance_to(rear)
	if span < 11.0:
		_box(ci, Rect2(mid.x - 3.4, mid.y - 8.4, 6.8, 16.8), trim.darkened(0.2))
		_box(ci, Rect2(mid.x - 2.4, mid.y - 6.6, 4.8, 13.2), paper)
		_line(ci, mid + Vector2(0.0, -6.6), mid + Vector2(0.0, 6.6), trim, 1.3)
		return
	var left := minf(front.x, rear.x)
	var top := mid.y - 7.2
	_box(ci, Rect2(left - 1.4, top - 1.2, span + 2.8, 16.8), trim.darkened(0.15))
	_box(ci, Rect2(left, top, span, 14.4), paper)
	_box(ci, Rect2(left, top, 3.2, 14.4), trim)
	_box(ci, Rect2(left + span - 3.2, top, 3.2, 14.4), trim.darkened(0.08))
	var ink := cloth.darkened(0.45)
	_line(ci, Vector2(left + 5.0, mid.y - 2.2), Vector2(left + span - 5.0, mid.y - 2.2), ink, 1.1)
	_line(ci, Vector2(left + 5.0, mid.y + 1.4), Vector2(left + span - 5.0, mid.y + 1.4), ink, 1.1)
	if beat == 2:
		_dot(ci, mid + Vector2(0.0, -12.0), 2.4, trim.lightened(0.25))
		_dot(ci, mid + Vector2(0.6, -11.2), 1.0, Color("fff6d8"))


static func _part_horse(ci: CanvasItem, trim: Color, step: float, drop: float) -> void:
	var base := Vector2(0.0, drop)
	var body := Color("5a3d2e")
	var dark := Color("3a281c")
	var mane := Color("1a120e")
	_line(ci, base + Vector2(-14.0, 7.0), base + Vector2(-24.0, 14.0), mane, 3.2)
	_line(ci, base + Vector2(-15.0, 9.0), base + Vector2(-21.0, 17.0), dark, 2.2)
	_ellipse(ci, base + Vector2(-3.0, 10.0), 17.0, 8.0, dark)
	_ellipse(ci, base + Vector2(1.0, 8.0), 15.0, 6.6, body)
	_ellipse(ci, base + Vector2(4.0, 10.0), 8.0, 3.2, body.lightened(0.1))
	_ellipse(ci, base + Vector2(16.0, 2.0), 6.6, 5.4, dark)
	_ellipse(ci, base + Vector2(17.0, 2.2), 5.4, 4.4, body)
	_line(ci, base + Vector2(14.0, -1.0), base + Vector2(12.0, -7.0), mane, 2.4)
	_line(ci, base + Vector2(16.5, -0.6), base + Vector2(18.5, -6.0), mane, 1.8)
	_ellipse(ci, base + Vector2(21.0, 4.4), 2.6, 1.8, body.lightened(0.08))
	_dot(ci, base + Vector2(19.0, 1.2), 1.1, Color("1a120e"))
	_dot(ci, base + Vector2(19.4, 0.9), 0.45, Color("f4f1ea"))
	_line(ci, base + Vector2(12.0, 3.0), base + Vector2(21.0, 5.0), trim, 1.5)
	_dot(ci, base + Vector2(20.4, 5.2), 1.2, trim.lightened(0.2))
	var hoofs: Array[float] = [-13.0, -3.0, 8.0, 15.0]
	for i in hoofs.size():
		var hx := hoofs[i]
		var gait := step if i % 2 == 0 else -step
		var hip := base + Vector2(hx, 12.0)
		var hoof := Vector2(hx + gait * 7.0, base.y + 22.0)
		_line(ci, hip, hoof, dark, 2.8)
		_ellipse(ci, hoof + Vector2(1.0, 0.4), 2.4, 1.3, Color("12100e"))
	_ellipse(ci, base + Vector2(2.0, 5.0), 7.4, 3.2, Color("8e2430"))
	_ellipse(ci, base + Vector2(2.4, 4.4), 4.2, 1.5, Color("a33a3a"))
	_line(ci, base + Vector2(-5.0, 3.2), base + Vector2(9.0, 3.2), trim, 1.5)
	_line(ci, base + Vector2(-5.0, 7.2), base + Vector2(9.0, 7.2), trim, 1.4)


static func _paint_school(ci: CanvasItem, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, step: float, ground: float, phase: String, beat: int, t: float, cycle: String, flash: float, weapon: String, mount: bool, trim: Color) -> void:
	var wash: float = 0.0
	if flash > 0.0:
		wash = clampf(flash * 4.0, 0.0, 0.72)
	var cream: Color = Color("f6f1e6").lerp(Color.WHITE, wash)
	var hood_shade: Color = Color("e4d8c4").lerp(Color.WHITE, wash)
	var hood_red: Color = Color("d23b32").lerp(Color.WHITE, wash)
	var red: Color = Color("cb322a").lerp(Color.WHITE, wash)
	var red_dark: Color = Color("9c2922").lerp(Color.WHITE, wash)
	var navy: Color = Color("25252d").lerp(Color.WHITE, wash)
	var pants: Color = Color("151724").lerp(Color.WHITE, wash)
	var collar: Color = Color("1a1823").lerp(Color.WHITE, wash)
	var gold: Color = Color("d6ad44").lerp(Color.WHITE, wash)
	var ink: Color = Color("1b1612").lerp(Color.WHITE, wash)
	var shoe: Color = Color("12110f").lerp(Color.WHITE, wash)
	var steel: Color = Color("d7dbe4").lerp(Color.WHITE, wash)
	var light: Color = Color("f2f4ef").lerp(Color.WHITE, wash)
	var back_foot := Vector2(-5.0 - step * 11.0, ground)
	var fore_foot := Vector2(6.0 + step * 12.0, ground)
	if mount:
		back_foot = chest + Vector2(-5.0 - step * 3.0, 17.0)
		fore_foot = chest + Vector2(7.0 + step * 3.0, 17.0)
	_school_scarf(ci, chest, step, red, red_dark)
	_school_rod(ci, chest + Vector2(-3.2, 8.4), back_foot, 4.3, pants)
	_ellipse(ci, back_foot + Vector2(1.2, 0.3), 5.2, 2.3, shoe)
	_school_rod(ci, chest + Vector2(3.4, 8.2), fore_foot, 4.6, pants.lightened(0.05))
	_ellipse(ci, fore_foot + Vector2(1.8, 0.2), 5.6, 2.4, shoe)
	_school_jacket(ci, chest, navy, collar, red)
	_hero_hood(ci, chest + Vector2(2.0, -17.2), cream, hood_shade, hood_red, ink, phase)
	var apart: float = front.distance_to(rear)
	_school_rod(ci, chest + Vector2(7.6, 0.4), rear, 3.1, navy)
	if apart > 11.0:
		_school_rod(ci, chest + Vector2(-5.2, -1.4), front, 2.8, navy)
	_school_buttons(ci, chest, gold)
	if weapon == "katana":
		_school_sword(ci, rear, tip, ink, red, steel, light)
	else:
		_tool(ci, cycle, phase, beat, t, chest, rear, front, tip, ground, trim, navy)


static func _school_scarf(ci: CanvasItem, chest: Vector2, step: float, red: Color, red_dark: Color) -> void:
	var wag: float = step * 2.6
	var neck: Vector2 = chest + Vector2(-1.6, -5.8)
	_poly(ci, PackedVector2Array([
		neck + Vector2(2.0, -2.2),
		neck + Vector2(-8.0, -6.6),
		neck + Vector2(-22.0 + wag, -3.4),
		neck + Vector2(-27.0 + wag, 1.8),
		neck + Vector2(-16.0 + wag * 0.3, 0.2),
		neck + Vector2(-6.0, 1.4),
	]), red)
	_poly(ci, PackedVector2Array([
		neck + Vector2(-7.0, -1.2),
		neck + Vector2(-18.0 + wag * 0.65, 2.0),
		neck + Vector2(-25.0 + wag, 10.0),
		neck + Vector2(-16.0 + wag * 0.3, 11.2),
		neck + Vector2(-7.0, 4.6),
	]), red_dark)


static func _school_jacket(ci: CanvasItem, chest: Vector2, navy: Color, collar: Color, red: Color) -> void:
	_poly(ci, PackedVector2Array([
		chest + Vector2(-8.8, -4.2),
		chest + Vector2(8.2, -5.2),
		chest + Vector2(9.6, 5.6),
		chest + Vector2(2.6, 8.4),
		chest + Vector2(-7.6, 7.8),
	]), navy)
	_poly(ci, PackedVector2Array([
		chest + Vector2(-5.2, -7.8),
		chest + Vector2(6.2, -8.8),
		chest + Vector2(6.6, -2.4),
		chest + Vector2(-4.6, -1.6),
	]), collar)
	_poly(ci, PackedVector2Array([
		chest + Vector2(-8.4, 5.6),
		chest + Vector2(9.4, 4.8),
		chest + Vector2(9.8, 8.8),
		chest + Vector2(-7.8, 9.4),
	]), red)


static func _school_buttons(ci: CanvasItem, chest: Vector2, gold: Color) -> void:
	_ellipse(ci, chest + Vector2(-0.4, 7.2), 1.9, 1.45, gold)
	_ellipse(ci, chest + Vector2(2.4, -2.4), 1.55, 1.55, gold)
	_ellipse(ci, chest + Vector2(2.6, 1.8), 1.55, 1.55, gold)


static func _school_rod(ci: CanvasItem, a: Vector2, b: Vector2, radius: float, color: Color) -> void:
	var delta: Vector2 = b - a
	var span: float = delta.length()
	if span < 0.8:
		_ellipse(ci, a, radius, radius, color)
		return
	var n: Vector2 = delta / span
	var side: Vector2 = Vector2(-n.y, n.x) * radius
	_poly(ci, PackedVector2Array([a + side, b + side, b - side, a - side]), color)
	_ellipse(ci, a, radius, radius, color)
	_ellipse(ci, b, radius, radius, color)


static func _school_sword(ci: CanvasItem, hand: Vector2, tip: Vector2, ink: Color, red: Color, steel: Color, light: Color) -> void:
	var dir: Vector2 = tip - hand
	if dir.length() < 1.0:
		return
	var n: Vector2 = dir.normalized()
	var side: Vector2 = Vector2(-n.y, n.x)
	var reach: float = maxf(dir.length(), 16.0)
	var end: Vector2 = hand + n * reach
	var pommel: Vector2 = hand - n * 7.4
	var guard: Vector2 = hand + n * 2.2
	_school_rod(ci, pommel, guard, 2.45, ink)
	_school_rod(ci, pommel + n * 1.6, pommel + n * 3.3, 2.15, red)
	_school_rod(ci, hand - n * 2.0, hand - n * 0.4, 2.15, red)
	_school_rod(ci, guard + side * 4.2, guard - side * 4.2, 1.15, ink)
	_ellipse(ci, guard + n * 0.4, 1.35, 1.35, red)
	_poly(ci, PackedVector2Array([
		guard + side * 2.7,
		end + side * 0.85,
		end - side * 0.55,
		guard - side * 2.3,
	]), steel)
	_poly(ci, PackedVector2Array([
		guard + side * 1.15,
		end + side * 0.35,
		end,
		guard + side * 0.15,
	]), light)


static func _paint_hero(ci: CanvasItem, chest: Vector2, rear: Vector2, front: Vector2, tip: Vector2, step: float, ground: float, phase: String, beat: int, t: float, cycle: String, snap: float, flash: float) -> void:
	var wash := 0.0
	if flash > 0.0:
		wash = clampf(flash * 4.0, 0.0, 0.72)
	var cream := Color("f6f1e6").lerp(Color.WHITE, wash)
	var shade := Color("e4d8c4").lerp(Color.WHITE, wash)
	var red := Color("d23b32").lerp(Color.WHITE, wash)
	var red_dark := Color("a32e28").lerp(Color.WHITE, wash)
	var ink := Color("1c1614").lerp(Color.WHITE, wash)
	var steel := Color("d8dee6").lerp(Color.WHITE, wash)
	var gold := Color("e2b034").lerp(Color.WHITE, wash)
	var wood := Color("8b5a32").lerp(Color.WHITE, wash)
	_hero_scarf(ci, chest, snap, red, red_dark, false)
	if cycle == "bow":
		_hero_sheath(ci, chest, ink, red, gold)
	_hero_leg(ci, chest + Vector2(-4.0, 11.0), Vector2(-5.0 - step * 11.0, ground), ink, red)
	_hero_torso(ci, chest, cream, shade, red, red_dark)
	_hero_leg(ci, chest + Vector2(3.2, 11.0), Vector2(6.0 + step * 12.0, ground), ink.lightened(0.04), red)
	_hero_hood(ci, chest + Vector2(2.0, -17.2), cream, shade, red, ink, phase)
	_hero_scarf(ci, chest, snap, red, red_dark, true)
	_hero_arm(ci, chest + Vector2(-3.5, -1.0), rear, ink, red)
	_hero_arm(ci, chest + Vector2(5.2, -4.2), front, ink.lightened(0.05), red)
	if cycle == "bow":
		_hero_bow(ci, beat, t, front, rear, wood, red, steel, ink)
	else:
		_hero_katana(ci, rear, tip, steel, ink, red, gold)


static func _hero_hood(ci: CanvasItem, at: Vector2, cream: Color, shade: Color, red: Color, ink: Color, phase: String) -> void:
	_ellipse(ci, at + Vector2(-3.6, 2.6), 10.2, 11.0, shade.darkened(0.08))
	_ellipse(ci, at + Vector2(1.8, 0.8), 8.8, 9.6, cream)
	_ellipse(ci, at + Vector2(4.4, -2.4), 4.0, 4.8, cream.lightened(0.08))
	_poly(ci, PackedVector2Array([
		at + Vector2(0.6, -7.4),
		at + Vector2(4.2, -12.4),
		at + Vector2(8.0, -5.0),
	]), cream)
	_line(ci, at + Vector2(1.6, -9.6), at + Vector2(6.2, -6.0), red, 2.2)
	_poly(ci, PackedVector2Array([
		at + Vector2(0.2, -4.6),
		at + Vector2(3.0, -6.2),
		at + Vector2(8.6, -1.2),
		at + Vector2(8.8, 4.4),
		at + Vector2(5.4, 5.6),
		at + Vector2(1.6, 0.8),
	]), red)
	_ellipse(ci, at + Vector2(5.0, 2.0), 4.4, 3.4, ink)
	if phase == "hurt" or phase == "fall":
		_line(ci, at + Vector2(2.8, 0.2), at + Vector2(7.0, 1.0), Color("f4f4f0"), 1.6)
		return
	_line(ci, at + Vector2(3.2, -0.6), at + Vector2(6.8, 0.4), red, 2.4)
	_dot(ci, at + Vector2(5.6, -0.2), 0.7, ink)


static func _hero_torso(ci: CanvasItem, chest: Vector2, cream: Color, shade: Color, red: Color, red_dark: Color) -> void:
	_poly(ci, PackedVector2Array([
		chest + Vector2(-8.6, -6.0),
		chest + Vector2(6.4, -5.0),
		chest + Vector2(7.2, 10.0),
		chest + Vector2(-7.4, 11.0),
	]), shade)
	_poly(ci, PackedVector2Array([
		chest + Vector2(-7.4, -8.0),
		chest + Vector2(8.2, -6.2),
		chest + Vector2(8.8, 8.4),
		chest + Vector2(2.4, 14.2),
		chest + Vector2(-6.6, 12.2),
	]), cream)
	_poly(ci, PackedVector2Array([
		chest + Vector2(1.4, -6.6),
		chest + Vector2(7.6, -5.6),
		chest + Vector2(8.2, 7.6),
		chest + Vector2(2.8, 12.4),
	]), cream.lightened(0.06))
	_line(ci, chest + Vector2(-1.0, -7.2), chest + Vector2(7.4, 7.2), red, 1.8)
	_line(ci, chest + Vector2(-6.2, 11.6), chest + Vector2(2.6, 14.0), red, 2.4)
	_line(ci, chest + Vector2(6.6, -5.4), chest + Vector2(8.4, 8.0), red, 1.6)
	_box(ci, Rect2(chest.x - 6.4, chest.y + 4.2, 13.5, 4.2), red_dark)
	_line(ci, chest + Vector2(-5.2, 4.8), chest + Vector2(6.0, 4.8), red.lightened(0.16), 1.2)
	_poly(ci, PackedVector2Array([
		chest + Vector2(1.6, 8.2),
		chest + Vector2(4.2, 8.2),
		chest + Vector2(2.9, 13.6),
	]), red)
	var mark := chest + Vector2(3.4, 7.6)
	_line(ci, mark + Vector2(-1.2, -2.2), mark + Vector2(1.6, -0.6), red, 1.7)
	_line(ci, mark + Vector2(1.6, -0.6), mark + Vector2(-0.8, 1.0), red, 1.7)
	_line(ci, mark + Vector2(-0.8, 1.0), mark + Vector2(1.8, 2.6), red, 1.7)


static func _hero_scarf(ci: CanvasItem, chest: Vector2, snap: float, red: Color, red_dark: Color, knot: bool) -> void:
	var neck := chest + Vector2(1.0, -8.4)
	if knot:
		_ellipse(ci, neck, 6.2, 2.8, red)
		_ellipse(ci, neck + Vector2(1.4, 0.5), 2.6, 1.4, red_dark)
		return
	var end := chest + Vector2(-18.0, 2.0)
	var flap := end + Vector2(-2.0, 10.0)
	var lower := end + Vector2(3.0, 8.0)
	if snap > 12.0:
		end = chest + Vector2(14.0 + snap * 0.22, 1.0)
		flap = end + Vector2(6.0, 9.0)
		lower = end + Vector2(2.0, 7.0)
	_line(ci, neck, end, red_dark, 6.4)
	_line(ci, neck + Vector2(0.0, -1.2), end + Vector2(0.0, -2.0), red, 3.6)
	_line(ci, end, flap, red, 4.4)
	_line(ci, end + Vector2(1.0, 1.0), lower, red_dark, 3.6)


static func _hero_leg(ci: CanvasItem, hip: Vector2, foot: Vector2, ink: Color, red: Color) -> void:
	var knee := (hip + foot) * 0.5 + Vector2(-2.0, -1.6)
	var bend := clampf(hip.distance_to(foot), 8.0, 24.0)
	knee.y -= maxf(0.0, 16.0 - bend)
	var ankle := foot + Vector2(0.6, -4.0)
	_line(ci, hip, knee, ink, 4.8)
	_ellipse(ci, knee, 2.2, 1.9, ink.lightened(0.08))
	_line(ci, knee, ankle, ink.lightened(0.04), 4.0)
	_line(ci, hip + Vector2(1.0, 1.0), knee, red, 1.3)
	_ellipse(ci, foot + Vector2(1.8, -1.6), 5.2, 3.0, ink)
	_ellipse(ci, foot + Vector2(2.6, 0.8), 5.6, 1.7, Color("12100e"))
	_line(ci, ankle + Vector2(-2.4, 0.6), ankle + Vector2(3.0, 0.0), red, 1.9)


static func _hero_arm(ci: CanvasItem, shoulder: Vector2, hand: Vector2, ink: Color, red: Color) -> void:
	var delta := hand - shoulder
	var mid := (shoulder + hand) * 0.5
	var elbow := mid + Vector2(-2.0, 3.0)
	if delta.length() > 3.0:
		var perp := Vector2(-delta.y, delta.x).normalized()
		if perp.y < 0.0:
			perp = -perp
		if perp.x > 0.15:
			perp = -perp
		elbow = mid + perp * clampf(delta.length() * 0.16, 2.4, 6.0)
	_line(ci, shoulder, elbow, ink, 3.8)
	_ellipse(ci, elbow, 2.0, 1.7, ink.lightened(0.08))
	_line(ci, elbow, hand, ink.lightened(0.05), 3.2)
	var wrist := hand.lerp(elbow, 0.24)
	_line(ci, wrist + Vector2(-1.8, 1.2), wrist + Vector2(2.0, -0.8), red, 1.8)
	_ellipse(ci, hand, 2.6, 2.2, ink)
	_ellipse(ci, hand + Vector2(0.8, -0.5), 1.0, 0.8, ink.lightened(0.18))


static func _hero_sheath(ci: CanvasItem, chest: Vector2, ink: Color, red: Color, gold: Color) -> void:
	var top := chest + Vector2(-7.0, -1.0)
	var bot := chest + Vector2(-2.0, 14.0)
	_line(ci, top, bot, ink, 3.4)
	_line(ci, top + Vector2(0.8, 0.4), bot, Color("3a342c"), 1.2)
	_dot(ci, top, 2.0, gold)
	_line(ci, top + Vector2(-0.4, 2.4), top + Vector2(1.2, 4.6), red, 1.6)


static func _hero_katana(ci: CanvasItem, hand: Vector2, tip: Vector2, steel: Color, ink: Color, red: Color, gold: Color) -> void:
	var dir := tip - hand
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	if side.y > 0.0:
		side = -side
	var mid := hand.lerp(tip, 0.5) + side * 3.2
	var pommel := hand - n * 7.0
	_line(ci, pommel, hand, ink, 3.2)
	_line(ci, pommel + n * 1.8, hand - n * 2.2, red, 2.2)
	_line(ci, pommel + n * 3.4, pommel + n * 4.6, red, 2.0)
	_dot(ci, pommel, 2.0, gold)
	_ellipse(ci, hand, 2.3, 1.6, ink)
	_line(ci, hand + Vector2(-n.y, n.x) * 4.6, hand - Vector2(-n.y, n.x) * 4.6, ink, 2.6)
	_line(ci, hand, mid, steel.darkened(0.22), 4.0)
	_line(ci, mid, tip, steel, 3.2)
	_line(ci, hand + side * 1.3, mid + side * 0.8, steel.lightened(0.28), 1.4)
	_line(ci, mid + side * 0.8, tip, Color("f7f7f4"), 1.15)
	_dot(ci, tip, 1.2, steel.lightened(0.35))
	_dot(ci, hand + n * 1.4, 1.1, red)


static func _hero_bow(ci: CanvasItem, beat: int, t: float, front: Vector2, rear: Vector2, wood: Color, red: Color, steel: Color, ink: Color) -> void:
	_arc(ci, front + Vector2(-0.8, 0.0), 15.0, -1.25, 1.25, 16, wood.darkened(0.28), 4.0)
	_arc(ci, front, 14.4, -1.2, 1.2, 16, wood, 2.6)
	var top := front + Vector2(1.2, -14.4)
	var bot := front + Vector2(1.2, 14.4)
	_dot(ci, top, 2.0, red)
	_dot(ci, bot, 2.0, red)
	_ellipse(ci, front, 2.2, 2.6, red)
	var released := beat >= 3
	var string_at := front + Vector2(-2.0, 0.0)
	if beat >= 1 and not released:
		string_at = rear
	var cord := Color("f4efe4")
	_line(ci, top, string_at, cord, 1.2)
	_line(ci, string_at, bot, cord, 1.2)
	if released:
		var fly := front + Vector2(lerpf(8.0, 32.0, t), -1.0)
		_hero_arrow(ci, front + Vector2(4.0, 0.0), fly, steel, red, ink)
		return
	var aim := front - rear
	if aim.length() < 1.0:
		aim = Vector2(12.0, 0.0)
	aim = aim.normalized() * (13.0 if beat >= 1 else 9.0)
	var nock := rear - aim.normalized() * 3.0
	_hero_arrow(ci, nock, rear + aim, steel, red, ink)


static func _hero_arrow(ci: CanvasItem, nock: Vector2, head: Vector2, steel: Color, red: Color, ink: Color) -> void:
	var dir := head - nock
	if dir.length() < 1.0:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	_line(ci, nock, head, Color("c8b48a"), 1.5)
	_poly(ci, PackedVector2Array([
		head - n * 6.0 + side * 2.4,
		head + n * 1.6,
		head - n * 6.0 - side * 2.4,
	]), steel)
	_poly(ci, PackedVector2Array([
		nock,
		nock + n * 4.0 + side * 2.2,
		nock + n * 2.4,
	]), red)
	_poly(ci, PackedVector2Array([
		nock,
		nock + n * 4.0 - side * 2.2,
		nock + n * 2.4,
	]), red.darkened(0.08))
	_dot(ci, nock, 1.0, ink)


# Paint-local sword segment and body points for the enhancement overlay.
# Same chest, hands, and blade the current skin already draws.
static func blaze_rig(look: Dictionary, pose: Dictionary) -> Dictionary:
	var phase: String = str(pose.get("phase", "idle"))
	var along: float = float(pose.get("t", 0.0))
	var clock: float = float(pose.get("clock", 0.0))
	var beat: int = int(pose.get("beat", 0))
	var weapon: String = str(pose.get("tool", look.get("weapon", "katana")))
	var paint: String = str(look.get("paint", "hero"))
	var cycle: String = _cycle_id(paint, weapon)
	var motion: Dictionary = _motion(phase, along, clock, cycle, beat, "")
	var lean: float = float(motion["lean"])
	var squat: float = float(motion["squat"])
	var step: float = float(motion["step"])
	var breath: float = float(motion["breath"])
	var rise: float = float(motion["rise"])
	var rear_off: Vector2 = motion["rear"]
	var front_off: Vector2 = motion["front"]
	var tip_off: Vector2 = motion["tip"]
	var mount: bool = bool(look.get("mount", false))
	var lift: float = -2.0
	if mount:
		lift = -18.0
	var drop: float = squat + rise
	var ground: float = 18.0 + rise * 0.35
	var chest: Vector2 = Vector2(lean + 1.0, lift + drop - breath)
	var rear: Vector2 = chest + rear_off
	var front: Vector2 = chest + front_off
	var tip: Vector2 = chest + tip_off
	var sheet: bool = bool(look.get("sheet", false))
	var hand: Vector2 = rear
	var blade_tip: Vector2 = tip
	var drawn: bool = cycle != "bow" and cycle != "crossbow"
	if not drawn:
		hand = chest + Vector2(-7.0, -1.0)
		blade_tip = chest + Vector2(-2.0, 14.0)
	elif blade_tip.distance_to(hand) > 1.0:
		var along_blade: Vector2 = (blade_tip - hand).normalized()
		hand = hand - along_blade * 4.0
	return {
		"hand": hand,
		"tip": blade_tip,
		"body": _blaze_body(chest, rear, front, step, ground, sheet),
	}


static func _blaze_body(chest: Vector2, rear: Vector2, front: Vector2, step: float, ground: float, sheet: bool) -> PackedVector2Array:
	var head: Vector2 = chest + Vector2(1.6, -16.0)
	var torso: Vector2 = chest + Vector2(0.4, 1.0)
	var shoulder_r: Vector2 = chest + Vector2(-4.0, -1.0)
	var shoulder_f: Vector2 = chest + Vector2(5.0, -4.0)
	var hip_r: Vector2 = chest + Vector2(-3.5, 11.0)
	var hip_f: Vector2 = chest + Vector2(3.0, 11.0)
	if sheet:
		head = chest + Vector2(2.0, -17.2)
		torso = chest + Vector2(1.0, 2.0)
		shoulder_r = chest + Vector2(-3.5, -1.0)
		shoulder_f = chest + Vector2(5.2, -4.2)
		hip_r = chest + Vector2(-4.0, 11.0)
		hip_f = chest + Vector2(3.2, 11.0)
	var foot_r: Vector2 = Vector2(-5.0 - step * 11.0, ground)
	var foot_f: Vector2 = Vector2(6.0 + step * 12.0, ground)
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(head)
	pts.append(torso)
	pts.append(shoulder_r.lerp(rear, 0.62))
	pts.append(shoulder_f.lerp(front, 0.62))
	pts.append(hip_r.lerp(foot_r, 0.55))
	pts.append(hip_f.lerp(foot_f, 0.55))
	return pts


static func paint_local(ci: CanvasItem, look: Dictionary, pose: Dictionary) -> void:
	paints += 1
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
	var beast := str(look.get("paint", ""))
	if _is_beast(beast):
		_paint_beast(ci, beast, phase, beat, t, clock, pose)
		return
	if _is_court(beast):
		_paint_court(ci, beast, phase, beat, t, clock, pose)
		return
	var weapon := str(pose.get("tool", look["weapon"]))
	var paint := str(look.get("paint", ""))
	var faction := str(look.get("faction", "ninja"))
	var cycle := _cycle_id(paint, weapon)
	var motion := _motion(phase, t, clock, cycle, beat, str(pose.get("tale", "")))
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
	if str(look.get("dress", "")) == "school":
		_paint_school(ci, chest, rear, front, tip, step, ground, phase, beat, t, cycle, flash, weapon, mount, trim)
		if phase == "act" and beat == contact_beat(weapon) and t > 0.35 and not _is_quiet(cycle):
			_arc(ci, front, 16.0 + t * 12.0, -1.15, 0.95, 14, Color(0.77, 0.27, 0.21, (1.0 - t) * 0.85), 3.0)
		_tilt = 0.0
		return
	if paint == "hero" and bool(look.get("sheet", false)):
		_paint_hero(ci, chest, rear, front, tip, step, ground, phase, beat, t, cycle, snap, flash)
		if phase == "act" and beat == contact_beat(weapon) and t > 0.35 and not _is_quiet(cycle):
			_arc(ci, front, 16.0 + t * 12.0, -1.15, 0.95, 14, Color(0.82, 0.23, 0.2, (1.0 - t) * 0.85), 3.0)
		_tilt = 0.0
		return
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
		if faction == "ninja":
			_oval_leg(ci, chest + Vector2(-3.5, 11.0), Vector2(-5.0 - step * 11.0, ground), cloth.darkened(0.28))
		else:
			_leg(ci, chest + Vector2(-3.5, 12.0), Vector2(-5.0 - step * 11.0, ground), cloth.darkened(0.34), 3.2)
	_torso(ci, chest, cloth, trim, faction)
	if not mount:
		if faction == "ninja":
			_oval_leg(ci, chest + Vector2(3.0, 11.0), Vector2(6.0 + step * 12.0, ground), cloth.darkened(0.08))
		else:
			_leg(ci, chest + Vector2(3.0, 12.0), Vector2(6.0 + step * 12.0, ground), cloth.darkened(0.08), 3.5)
	_head(ci, chest + Vector2(1.6, -16.0), skin, cloth, trim, faction, weapon, phase, str(look.get("helm", "")))
	if bool(look.get("horns", false)):
		_horns(ci, chest + Vector2(1.6, -24.0), trim)
	if bool(look.get("sash", false)):
		_line(ci, chest + Vector2(-9.0, 1.0), chest + Vector2(10.0, 3.0), Color("c44536"), 3.0)
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
	match paint:
		"horse":
			return "horse"
		"assassin":
			return "assassin"
		"runner", "scout":
			return "runner"
		"suicide":
			return "bomb_dive"
		"bomber", "satchel":
			return "bomb_throw"
		_:
			return weapon


static func tale_span(name: String) -> float:
	match name:
		"small", "loom", "edge":
			return 6.4
		"vow", "draw", "weigh", "read", "cost", "mend", "yield":
			return 5.6
		"rein", "creep", "pace", "parade", "rush":
			return 4.6
		_:
			return 4.8


static func _motion(phase: String, t: float, clock: float, cycle: String, beat: int, tale: String = "") -> Dictionary:
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
		"tale":
			return _tale(tale, t, clock)
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
		"model":
			lean = -0.5
			squat = 0.0
			step = 0.18
			breath = 0.0
			rise = 0.0
			tilt = -0.06
			rear = Vector2(3.0, 10.0)
			front = Vector2(8.0, 3.0)
			tip = Vector2(8.0, 20.0)
			if cycle == "bow" or cycle == "crossbow":
				rear = Vector2(6.0, 2.0)
				front = Vector2(10.0, 1.0)
				tip = Vector2(10.0, 1.0)
			elif cycle == "staff" or cycle == "polearm":
				rear = Vector2(2.0, 8.0)
				front = Vector2(5.0, 2.0)
				tip = Vector2(4.0, -22.0)
			elif cycle == "spear":
				rear = Vector2(2.0, 6.0)
				front = Vector2(8.0, 4.0)
				tip = Vector2(6.0, -24.0)
			elif cycle == "axe" or cycle == "hammer":
				rear = Vector2(2.0, 8.0)
				front = Vector2(8.0, 3.0)
				tip = Vector2(4.0, -20.0)
			elif cycle == "shield":
				rear = Vector2(2.0, 10.0)
				front = Vector2(6.0, 2.0)
				tip = Vector2(6.0, 2.0)
			elif cycle == "scroll":
				rear = Vector2(4.0, 2.0)
				front = Vector2(8.0, 1.0)
				tip = Vector2(8.0, 1.0)
			elif cycle == "bomb_dive" or cycle == "bomb_throw":
				rear = Vector2(3.0, 8.0)
				front = Vector2(8.0, 4.0)
				tip = Vector2(10.0, 2.0)
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


static func _tale(name: String, along: float, clock: float) -> Dictionary:
	var keys := _tale_keys(name)
	var count := keys.size()
	if count < 2:
		return _motion("idle", 0.0, clock, "katana", 0)
	var wrapped := clampf(along, 0.0, 0.999) * float(count)
	var index := int(wrapped) % count
	var next := (index + 1) % count
	var blend := wrapped - float(int(wrapped))
	blend = blend * blend * (3.0 - 2.0 * blend)
	var left: Array = keys[index]
	var right: Array = keys[next]
	return {
		"lean": lerpf(float(left[0]), float(right[0]), blend),
		"squat": lerpf(float(left[1]), float(right[1]), blend),
		"step": lerpf(float(left[2]), float(right[2]), blend),
		"breath": sin(clock * 1.5) * float(left[3]),
		"rise": lerpf(float(left[4]), float(right[4]), blend),
		"tilt": lerpf(float(left[5]), float(right[5]), blend),
		"rear": Vector2(float(left[6]), float(left[7])).lerp(Vector2(float(right[6]), float(right[7])), blend),
		"front": Vector2(float(left[8]), float(left[9])).lerp(Vector2(float(right[8]), float(right[9])), blend),
		"tip": Vector2(float(left[10]), float(left[11])).lerp(Vector2(float(right[10]), float(right[11])), blend),
	}


static func _tk(lean: float, squat: float, step: float, breath: float, rise: float, tilt: float, rx: float, ry: float, fx: float, fy: float, tx: float, ty: float) -> Array:
	return [lean, squat, step, breath, rise, tilt, rx, ry, fx, fy, tx, ty]


static func _tale_keys(name: String) -> Array:
	match name:
		"small":
			return [
				_tk(-6, 8, 0.1, 0.35, 1, -0.42, -2, 8, 2, 7, 3, 10),
				_tk(-8, 11, -0.15, 0.2, 2, -0.55, -1, 9, 1, 8, 2, 11),
				_tk(-12, 10, -0.7, 0.15, 2, -0.48, -4, 10, 0, 9, 1, 12),
				_tk(-7, 9, -0.2, 0.3, 1, -0.4, -2, 8, 2, 7, 3, 10),
			]
		"pace":
			return [
				_tk(3, 1, -0.9, 0.25, 0, 0.08, -8, 8, 6, 4, 10, 16),
				_tk(4, 2, 0.1, 0.2, 0, 0.1, -2, 6, 9, 3, 14, 12),
				_tk(3, 1, 0.95, 0.25, 0, 0.06, 4, 7, 11, 5, 16, 18),
				_tk(4, 2, -0.1, 0.2, 0, 0.1, -3, 6, 8, 3, 12, 14),
			]
		"still":
			return [
				_tk(0, 0, 0.08, 0.7, 0, 0.12, -4, 8, 7, 3, 9, 18),
				_tk(-1, 0, 0.16, 0.85, 0, -0.08, -3, 7, 8, 2, 8, 8),
				_tk(1, 0, 0.05, 0.7, 0, -0.18, -4, 8, 7, 2, 8, 4),
				_tk(0, 0, 0.1, 0.75, 0, 0.04, -4, 8, 7, 3, 9, 14),
			]
		"vow":
			return [
				_tk(0, 1, 0.1, 0.4, 0, 0.05, -2, 8, 6, 6, 8, 16),
				_tk(-2, 2, 0.0, 0.3, 0, -0.2, -6, 2, 4, -2, 2, -28),
				_tk(-1, 0, 0.05, 0.55, 0, -0.28, -4, -2, 5, -6, 1, -36),
				_tk(-1, 0, 0.05, 0.6, 0, -0.22, -4, 0, 5, -4, 2, -30),
				_tk(1, 1, 0.12, 0.4, 0, 0.02, -2, 6, 8, 2, 12, 8),
			]
		"guard":
			return [
				_tk(1, 1, 0.15, 0.45, 0, 0.04, -3, 6, 8, 2, 14, 6),
				_tk(2, 2, 0.2, 0.4, 0, -0.06, -2, 4, 10, -1, 18, -6),
				_tk(2, 2, 0.12, 0.55, 0, -0.04, -2, 4, 10, -1, 18, -4),
				_tk(1, 1, 0.16, 0.45, 0, 0.02, -3, 6, 8, 2, 14, 4),
			]
		"ask":
			return [
				_tk(0, 0, 0.1, 0.5, 0, 0.02, -4, 8, 6, 4, 8, 12),
				_tk(2, 0, 0.2, 0.4, 0, -0.08, -3, 6, 16, 1, 28, 2),
				_tk(3, 0, 0.15, 0.55, 0, -0.12, -3, 6, 18, 0, 32, 1),
				_tk(1, 0, 0.1, 0.5, 0, 0.0, -4, 7, 8, 3, 12, 8),
			]
		"edge":
			return [
				_tk(0, 0, 0.1, 0.6, 0, 0.16, -4, 8, 7, 4, 9, 16),
				_tk(6, 1, 0.35, 0.4, 0, 0.28, -2, 6, 12, 2, 16, 10),
				_tk(2, 2, -0.2, 0.35, 1, 0.1, -6, 8, 4, 6, 6, 14),
				_tk(1, 0, 0.08, 0.7, 0, 0.2, -4, 8, 7, 3, 8, 16),
			]
		"low":
			return [
				_tk(1, 1, 0.05, 0.45, 0, 0.06, -5, 10, 6, 8, 8, 20),
				_tk(0, 0, 0.12, 0.55, 0, 0.02, -4, 9, 7, 7, 9, 18),
				_tk(1, 1, -0.05, 0.45, 0, 0.08, -5, 10, 6, 8, 7, 22),
				_tk(0, 0, 0.08, 0.5, 0, 0.04, -4, 9, 7, 7, 9, 19),
			]
		"offer":
			return [
				_tk(0, 2, 0.1, 0.4, 0, 0.1, -2, 8, 6, 6, 8, 10),
				_tk(1, 1, 0.15, 0.35, 0, -0.05, 2, 4, 14, 2, 26, 4),
				_tk(2, 3, 0.1, 0.4, 1, 0.18, 2, 6, 14, 4, 24, 8),
				_tk(1, 1, 0.12, 0.4, 0, 0.02, 0, 5, 10, 3, 16, 6),
			]
		"draw":
			return [
				_tk(0, 0, 0.1, 0.4, 0, 0.04, 2, 6, 8, 4, 10, 4),
				_tk(-1, 1, 0.05, 0.3, 0, -0.06, -2, 2, 12, 1, 16, 0),
				_tk(-3, 1, -0.05, 0.25, 0, -0.1, -8, 1, 14, 0, 18, -1),
				_tk(-3, 1, -0.05, 0.45, 0, -0.08, -8, 1, 14, 0, 18, -1),
				_tk(0, 0, 0.1, 0.4, 0, 0.02, 2, 5, 8, 3, 10, 3),
			]
		"plant":
			return [
				_tk(2, 1, 0.4, 0.35, 0, 0.08, -6, 4, 8, 2, 22, -8),
				_tk(4, 2, 0.15, 0.3, 0, 0.04, -2, 6, 12, 3, 30, 2),
				_tk(3, 3, 0.05, 0.5, 0, 0.02, -2, 8, 10, 4, 28, 6),
				_tk(3, 2, 0.08, 0.45, 0, 0.04, -3, 7, 10, 3, 26, 4),
			]
		"brace":
			return [
				_tk(1, 2, 0.2, 0.4, 0, 0.02, -4, 8, 8, 2, 8, 2),
				_tk(-2, 5, 0.45, 0.25, 1, -0.08, -3, 8, 10, 1, 10, 1),
				_tk(-1, 4, 0.35, 0.45, 0, -0.02, -3, 7, 10, 1, 10, 1),
				_tk(1, 2, 0.15, 0.4, 0, 0.04, -4, 8, 8, 2, 8, 2),
			]
		"rein":
			return [
				_tk(4, 1, -1.0, 0.2, 0, 0.12, -4, 6, 8, 2, 12, 8),
				_tk(3, 2, 0.2, 0.25, 0, 0.08, -2, 5, 7, 2, 10, 6),
				_tk(1, 0, 0.15, 0.45, 0, -0.04, -2, 6, 6, 2, 8, 4),
				_tk(0, 0, 0.08, 0.6, 0, -0.1, -3, 7, 6, 3, 7, 6),
			]
		"slip":
			return [
				_tk(0, 1, 0.1, 0.3, 0, 0.02, -4, 6, 8, 3, 12, 8),
				_tk(-10, 3, -0.8, 0.15, 0, -0.35, -10, 8, 0, 6, 2, 10),
				_tk(-8, 2, -0.4, 0.2, 1, -0.2, -8, 6, 2, 4, 4, 6),
				_tk(2, 1, 0.3, 0.3, 0, 0.12, -2, 5, 10, 2, 16, 4),
			]
		"weigh":
			return [
				_tk(1, 1, 0.1, 0.4, 0, 0.06, -4, 10, 6, 8, 8, 22),
				_tk(-2, 3, 0.05, 0.25, 0, -0.25, -8, 2, 2, -4, -2, -30),
				_tk(-4, 4, 0.0, 0.35, 1, -0.18, -6, 4, 1, 2, 4, -8),
				_tk(-1, 2, 0.08, 0.45, 0, 0.04, -3, 8, 5, 6, 8, 16),
			]
		"rush":
			return [
				_tk(6, 2, -1.15, 0.1, 0, 0.2, -6, 6, 10, 2, 14, 2),
				_tk(7, 3, 1.05, 0.1, 0, 0.22, -4, 5, 12, 2, 16, 1),
				_tk(2, 4, 0.2, 0.2, 1, 0.05, -2, 6, 8, 4, 10, 2),
				_tk(1, 2, 0.05, 0.35, 0, 0.0, -2, 7, 7, 5, 9, 3),
			]
		"cost":
			return [
				_tk(4, 1, 0.7, 0.2, 0, 0.1, -4, 6, 9, 3, 12, 2),
				_tk(1, 3, 0.1, 0.25, 0, 0.2, -2, 8, 8, 6, 10, 6),
				_tk(2, 10, 0.2, 0.2, 4, 0.45, -2, 12, 6, 10, 8, 12),
				_tk(1, 12, 0.1, 0.25, 5, 0.4, -1, 12, 5, 11, 7, 13),
			]
		"mend":
			return [
				_tk(0, 0, 0.08, 0.55, 0, 0.02, -2, 6, 6, 4, 6, -8),
				_tk(1, 0, 0.1, 0.4, 0, -0.06, -1, 2, 12, 0, 8, -22),
				_tk(2, 1, 0.12, 0.6, 0, -0.04, 0, 3, 16, 1, 22, -6),
				_tk(1, 0, 0.08, 0.55, 0, 0.0, -2, 5, 8, 3, 8, -4),
			]
		"read":
			return [
				_tk(1, 1, 0.05, 0.4, 0, 0.16, 2, 6, 8, 4, 10, 2),
				_tk(2, 1, 0.08, 0.35, 0, 0.22, 4, 4, 12, 3, 16, 1),
				_tk(0, 0, 0.05, 0.3, 0, -0.16, 1, 2, 8, -2, 6, -18),
				_tk(0, 0, 0.05, 0.45, 0, -0.1, 2, 3, 8, 0, 7, -10),
			]
		"wide":
			return [
				_tk(0, 2, 0.55, 0.35, 0, 0.04, -6, 8, 8, 6, 4, 16),
				_tk(0, 3, 0.85, 0.5, 0, 0.0, -4, 6, 6, 2, 2, -6),
				_tk(1, 2, 0.7, 0.7, 0, -0.04, -2, 4, 8, 1, 6, -16),
				_tk(0, 2, 0.6, 0.45, 0, 0.02, -5, 8, 7, 5, 4, 10),
			]
		"shun":
			return [
				_tk(1, 0, 0.1, 0.3, 0, -0.02, -4, 7, 8, 3, 10, 8),
				_tk(3, 0, 0.25, 0.25, 0, -0.08, -3, 6, 16, 1, 30, 2),
				_tk(3, 0, 0.2, 0.35, 0, -0.06, -3, 6, 16, 1, 30, 2),
				_tk(1, 0, 0.1, 0.3, 0, 0.0, -4, 7, 8, 3, 12, 8),
			]
		"away":
			return [
				_tk(2, 1, 0.3, 0.3, 0, 0.2, -8, 6, 4, 6, 2, 12),
				_tk(4, 1, 0.8, 0.2, 0, 0.28, -10, 7, 2, 8, 0, 14),
				_tk(3, 1, 0.4, 0.25, 0, 0.22, -8, 6, 3, 7, 1, 12),
				_tk(2, 1, 0.2, 0.3, 0, 0.16, -6, 6, 4, 6, 2, 10),
			]
		"creep":
			return [
				_tk(5, 4, -0.7, 0.2, 1, 0.22, -6, 8, 8, 5, 12, 10),
				_tk(6, 5, 0.15, 0.15, 1, 0.26, -4, 8, 10, 4, 14, 8),
				_tk(5, 4, 0.75, 0.2, 1, 0.2, -2, 7, 11, 5, 16, 12),
				_tk(6, 5, -0.1, 0.15, 1, 0.24, -5, 8, 9, 5, 13, 10),
			]
		"parade":
			return [
				_tk(2, 1, -0.65, 0.3, 0, 0.06, -6, 6, 8, 2, 14, -4),
				_tk(2, 2, 0.05, 0.25, 0, 0.04, -4, 6, 9, 2, 16, -2),
				_tk(2, 1, 0.7, 0.3, 0, 0.06, -2, 6, 10, 2, 18, -4),
				_tk(2, 2, 0.0, 0.25, 0, 0.04, -4, 6, 9, 2, 15, -2),
			]
		"loom":
			return [
				_tk(0, 1, 0.05, 0.9, 0, 0.02, -3, 6, 6, 2, 4, -34),
				_tk(1, 0, 0.08, 1.1, 0, -0.04, -2, 4, 7, 1, 5, -38),
				_tk(0, 1, 0.04, 0.95, 0, 0.06, -3, 6, 6, 2, 4, -32),
				_tk(-1, 1, 0.06, 0.8, 0, 0.1, -4, 7, 5, 3, 3, -28),
			]
		"yield":
			return [
				_tk(1, 1, 0.1, 0.3, 0, 0.05, -4, 6, 8, 3, 12, 8),
				_tk(-4, 6, -0.4, 0.15, 2, -0.35, -6, 10, 3, 8, 6, 14),
				_tk(-2, 12, 0.15, 0.2, 6, 0.55, -2, 14, 4, 12, 6, 16),
				_tk(-1, 13, 0.1, 0.25, 6, 0.48, -2, 14, 4, 12, 6, 16),
			]
		"ordered":
			return [
				_tk(1, 0, 0.05, 0.15, 0, 0.02, -4, 6, 8, 2, 14, 2),
				_tk(1, 0, 0.05, 0.15, 0, 0.02, -4, 6, 8, 2, 14, 2),
				_tk(1, 1, 0.2, 0.2, 0, -0.04, -3, 5, 9, 1, 16, -2),
				_tk(1, 0, 0.05, 0.15, 0, 0.02, -4, 6, 8, 2, 14, 2),
			]
		_:
			return [
				_tk(0, 0, 0.08, 0.6, 0, 0.04, -4, 8, 7, 3, 9, 14),
				_tk(0, 0, 0.12, 0.7, 0, -0.04, -3, 7, 8, 2, 8, 10),
				_tk(0, 0, 0.08, 0.6, 0, 0.02, -4, 8, 7, 3, 9, 14),
			]


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
	if faction == "ninja":
		var hem_n := chest + Vector2(-8.0, 10.0)
		if snap > 10.0:
			hem_n = chest + Vector2(6.0, 6.0)
		_poly(ci, PackedVector2Array([
			chest + Vector2(-2.0, -4.0),
			chest + Vector2(2.0, -2.0),
			hem_n,
		]), trim.darkened(0.2))
		if weapon == "bow":
			_box(ci, Rect2(chest.x - 13.0, chest.y - 4.0, 7.0, 13.0), cloth.lightened(0.08))
			_line(ci, chest + Vector2(-11.0, -6.0), chest + Vector2(-9.0, -1.0), trim, 1.3)
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
	if faction == "ninja":
		_ellipse(ci, chest + Vector2(1.2, 2.2), 4.8, 6.4, trim.darkened(0.08))
		_ellipse(ci, chest + Vector2(0.2, 0.6), 2.2, 2.4, trim.lightened(0.28))
		return
	_line(ci, chest + Vector2(-2.0, -7.0), chest + Vector2(7.0, 9.0), trim, 1.6)


static func _horns(ci: CanvasItem, at: Vector2, trim: Color) -> void:
	_line(ci, at + Vector2(-4.0, -2.0), at + Vector2(-9.0, -12.0), trim.darkened(0.15), 2.4)
	_line(ci, at + Vector2(3.0, -3.0), at + Vector2(9.0, -13.0), trim.darkened(0.15), 2.4)


static func _head(ci: CanvasItem, at: Vector2, skin: Color, cloth: Color, trim: Color, faction: String, weapon: String, phase: String, helm: String = "") -> void:
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
	if faction == "clan" or faction == "cursed":
		var mask := Color("161214") if faction == "clan" else Color("121614")
		var slit := Color("8e2430") if faction == "clan" else Color("3d5a32")
		var eye := Color("e23b3b") if faction == "clan" else Color("d6f5a8")
		_ellipse(ci, at + Vector2(-4.0, 1.0), 8.2, 8.4, cloth.darkened(0.28))
		_ellipse(ci, at + Vector2(2.4, 0.2), 6.4, 7.0, mask)
		_line(ci, at + Vector2(0.4, -1.2), at + Vector2(6.2, -1.0), slit, 2.2)
		if phase == "hurt" or phase == "fall":
			_line(ci, at + Vector2(1.2, -1.6), at + Vector2(5.4, -0.4), Color(0.9, 0.9, 0.85), 1.4)
		else:
			_dot(ci, at + Vector2(4.2, -1.6), 1.15, eye)
		if helm == "crest" or weapon == "polearm":
			_line(ci, at + Vector2(0.0, -6.0), at + Vector2(1.0, -16.0), trim, 2.4)
			_ellipse(ci, at + Vector2(1.0, -16.0), 3.2, 2.2, trim)
		return
	if helm == "bare":
		_ellipse(ci, at + Vector2(-1.0, -2.0), 7.6, 4.2, cloth.darkened(0.2))
		_ellipse(ci, at + Vector2(1.4, 1.6), 6.4, 6.2, skin)
		_dot(ci, at + Vector2(4.0, 0.4), 1.05, Color(0.12, 0.1, 0.08))
		return
	if helm == "hood":
		_ellipse(ci, at + Vector2(-1.2, -0.4), 8.2, 8.0, cloth.darkened(0.18))
		_ellipse(ci, at + Vector2(2.6, 2.2), 4.8, 4.4, skin)
		_dot(ci, at + Vector2(4.2, 1.2), 1.0, Color(0.12, 0.1, 0.08))
		return
	var helm_w := 8.4 if helm == "heavy" else 7.4
	var helm_h := 7.4 if helm == "heavy" else 6.6
	_ellipse(ci, at + Vector2(-1.0, -1.0), helm_w, helm_h, cloth.darkened(0.28))
	if helm == "kettle":
		_line(ci, at + Vector2(-8.0, 1.2), at + Vector2(9.0, 1.6), cloth.darkened(0.35), 2.2)
	_ellipse(ci, at + Vector2(2.2, 2.4), 4.2, 3.2, skin)
	_line(ci, at + Vector2(-1.0, -0.2), at + Vector2(6.4, 0.4), Color(0.1, 0.1, 0.08), 2.4)
	if helm == "crest" or weapon == "polearm":
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
	var spin := t * TAU + float(beat)
	_dot(ci, tip + Vector2(cos(spin) * 8.0, sin(spin) * 5.0), 1.6, trim.lightened(0.35))
	_dot(ci, tip + Vector2(cos(spin + 2.1) * 6.0, sin(spin + 2.1) * 4.0), 1.3, Color(1, 1, 1, 0.7))


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
	if beat >= 1:
		_arc(ci, mid + Vector2(0.0, -10.0), 5.0 + float(beat), 0.4, 2.4, 8, Color(trim.r, trim.g, trim.b, 0.55), 1.4)
		_dot(ci, mid + Vector2(6.0, -14.0), 1.5, Color("fff6d0"))


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


static func _oval_leg(ci: CanvasItem, hip: Vector2, foot: Vector2, color: Color) -> void:
	var delta := foot - hip
	var length := maxf(delta.length(), 8.0)
	var angle := delta.angle()
	var mid := (hip + foot) * 0.5
	var pts := PackedVector2Array()
	var segs := 12
	for i in segs:
		var a := TAU * float(i) / float(segs)
		var local := Vector2(cos(a) * length * 0.5, sin(a) * 3.4).rotated(angle)
		pts.append(mid + local)
	_poly(ci, pts, color)
	_ellipse(ci, foot + Vector2(1.4, 0.4), 4.2, 1.8, Color(0.08, 0.06, 0.05))


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


static func _is_beast(paint: String) -> bool:
	return paint == "howler" or paint == "viper" or paint == "storm" or paint == "herald" or paint == "shell" or paint == "reaver" or paint == "moth" or paint == "elder" or paint == "glut" or paint == "brood" or paint == "ling" or paint == "walker" or paint == "runner" or paint == "oni"


static func paint_ailment(ci: CanvasItem, bone: float, still: float, clock: float) -> void:
	if still > 0.0:
		var ring := 0.28 + 0.22 * sin(clock * 6.0)
		_arc(ci, Vector2(0, -18), 24.0, 0.4, TAU - 0.2, 18, Color(0.62, 0.9, 0.7, ring), 2.2)
	if bone <= 0.0:
		return
	var blink := 0.2 + 0.8 * absf(sin(clock * 16.0))
	var chalk := Color(0.96, 0.94, 0.88, clampf(bone / 0.9, 0.0, 1.0) * blink)
	_line(ci, Vector2(-12, -36), Vector2(-3, -18), chalk, 2.4)
	_line(ci, Vector2(10, -38), Vector2(2, -16), chalk, 2.4)
	_line(ci, Vector2(-8, -6), Vector2(11, 0), chalk, 2.4)
	_dot(ci, Vector2(0, -46), 3.4, chalk)
	_line(ci, Vector2(-5, -48), Vector2(5, -43), chalk, 1.8)


static func _paint_beast(ci: CanvasItem, paint: String, phase: String, beat: int, t: float, clock: float, pose: Dictionary) -> void:
	var hang := float(pose.get("hang", 0.0))
	var calling := bool(pose.get("calling", false))
	var step := 0.0
	if phase == "march":
		step = sin(clock * 8.0)
	var chop := 0.0
	if phase == "act":
		if beat < 2:
			chop = -0.85
		elif beat == 2:
			chop = lerpf(-0.15, 1.0, t)
		else:
			chop = lerpf(1.0, 0.05, t)
	_tilt = 0.0
	match paint:
		"howler":
			_beast_howler(ci, phase, chop, step, hang)
		"viper":
			_beast_viper(ci, phase, chop, step, clock)
		"storm":
			_beast_storm(ci, phase, chop, clock)
		"herald":
			_beast_herald(ci, phase, chop, calling, clock)
		"shell":
			_beast_shell(ci, phase, chop, step)
		"reaver":
			_beast_reaver(ci, phase, chop, step)
		"moth":
			_beast_moth(ci, phase, chop, step)
		"elder":
			_beast_elder(ci, phase, chop, step)
		"glut":
			_beast_glut(ci, phase, chop, step, pose)
		"brood":
			_beast_brood(ci, phase, chop, step, false)
		"ling":
			_beast_brood(ci, phase, chop, step, true)
		"walker":
			_beast_walker(ci, phase, chop, step)
		"runner":
			_beast_runner(ci, phase, chop, step)
		"oni":
			_beast_oni(ci, phase, chop, step)
	if paint == "howler" or paint == "viper" or paint == "storm" or paint == "herald" or paint == "shell" or paint == "reaver":
		_dire_stripe(ci)
	_tilt = 0.0


static func _beast_howler(ci: CanvasItem, phase: String, chop: float, step: float, hang: float) -> void:
	var fur := Color("4a3428")
	var belly := Color("6a5344")
	var face := Color("5c4a3c")
	_ellipse(ci, Vector2(2, 20), 18, 4.4, Color(0, 0, 0, 0.3))
	var hold := Vector2(-4, -22)
	var swing := Vector2(16, 4)
	if phase == "act":
		var along := clampf(chop * 0.5 + 0.5, 0.0, 1.0)
		swing = Vector2(lerpf(-6.0, 26.0, along), lerpf(-16.0, 10.0, along))
	elif hang > 0.4:
		swing = Vector2(10, 6)
	if hang > 0.25:
		_line(ci, Vector2(-26, -70), Vector2(18, -76), Color("2c261e"), 5.0)
		_line(ci, Vector2(-6, -72), hold, Color("4a3b30"), 2.4)
	var foot := 17.0 if hang < 0.45 else 10.0
	_line(ci, Vector2(-5, 8), Vector2(-8.0 - step * 5.0, foot), fur.darkened(0.25), 4.4)
	_line(ci, Vector2(4, 8), Vector2(8.0 + step * 5.0, foot), fur, 4.6)
	_ellipse(ci, Vector2(1, 3), 14, 12, fur)
	_ellipse(ci, Vector2(4, 5), 8, 7, belly)
	_line(ci, Vector2(-2, -4), hold, fur.darkened(0.1), 4.8)
	_dot(ci, hold, 3.4, face)
	_line(ci, Vector2(4, -2), swing, fur, 5.2)
	_dot(ci, swing, 3.6, face)
	if phase == "act" and chop > 0.35:
		_arc(ci, swing, 11.0, -1.1, 0.7, 10, Color(0.93, 0.78, 0.42, 0.75), 2.6)
	_ellipse(ci, Vector2(8, -12), 10, 9, fur)
	_ellipse(ci, Vector2(14, -11), 6.2, 4.6, face)
	_dot(ci, Vector2(16.5, -12), 1.4, Color("d6f5a8"))
	_poly(ci, PackedVector2Array([Vector2(2, -18), Vector2(-1, -28), Vector2(6, -16)]), fur)
	_poly(ci, PackedVector2Array([Vector2(10, -18), Vector2(14, -27), Vector2(16, -14)]), fur.darkened(0.12))
	_line(ci, Vector2(-10, 6), Vector2(-18, 12), fur.darkened(0.15), 3.4)


static func _beast_viper(ci: CanvasItem, phase: String, chop: float, step: float, clock: float) -> void:
	var scale_c := Color("2f6a45")
	var belly := Color("8a9a62")
	var lunge := 0.0
	if phase == "act":
		lunge = maxf(chop, 0.0) * 7.0
	_ellipse(ci, Vector2(2, 14), 24, 3.4, Color(0, 0, 0, 0.24))
	for coil in 5:
		var cx := -20.0 + float(coil) * 7.2
		var cy := 6.0 + sin(clock * 6.0 + float(coil) + step) * 2.2
		var rx := 5.2 + float(coil) * 0.35
		_ellipse(ci, Vector2(cx, cy), rx, 4.2, scale_c if coil % 2 == 0 else scale_c.darkened(0.15))
		_ellipse(ci, Vector2(cx + 0.6, cy + 1.0), rx * 0.45, 1.5, belly)
	var neck := Vector2(12.0, 4.0)
	var head := Vector2(18.0 + lunge, 1.0)
	_ellipse(ci, neck, 5.0, 3.6, scale_c)
	_poly(ci, PackedVector2Array([
		head + Vector2(-4, 0),
		head + Vector2(-1, -11),
		head + Vector2(5, -1),
	]), scale_c.darkened(0.2))
	_ellipse(ci, head, 6.4, 4.2, scale_c.lightened(0.05))
	_dot(ci, head + Vector2(2.4, -1.0), 1.45, Color("e24b3b"))
	_line(ci, head + Vector2(5.2, 0.6), head + Vector2(10.0, 3.2), Color("f4f4f0"), 1.5)
	_line(ci, head + Vector2(5.0, 2.2), head + Vector2(9.4, 5.4), Color("f4f4f0"), 1.5)
	if phase == "act" and chop > 0.25:
		_arc(ci, head + Vector2(6, 2), 7.0, -0.5, 0.85, 8, Color(0.72, 0.9, 0.45, 0.7), 2.0)


static func _beast_storm(ci: CanvasItem, phase: String, chop: float, clock: float) -> void:
	var robe := Color("1b2740")
	var cloud := Color("e8f2fb")
	var bolt := Color("d6f4ff")
	_ellipse(ci, Vector2(0, 20), 16, 4.0, Color(0, 0, 0, 0.28))
	_line(ci, Vector2(-5, 10), Vector2(-7, 18), robe.darkened(0.2), 3.6)
	_line(ci, Vector2(5, 10), Vector2(7, 18), robe, 3.6)
	_poly(ci, PackedVector2Array([
		Vector2(-7, -10),
		Vector2(7, -10),
		Vector2(13, 14),
		Vector2(-13, 14),
	]), robe)
	_line(ci, Vector2(-8, 6), Vector2(8, 8), Color("7ec8ff"), 2.0)
	_ellipse(ci, Vector2(0, -16), 6.5, 6.2, Color("d5e6f4"))
	_dot(ci, Vector2(-2.2, -16), 1.35, Color("e6c36a"))
	_dot(ci, Vector2(2.4, -16), 1.35, Color("e6c36a"))
	var puff := Vector2(sin(clock * 3.0) * 4.0, cos(clock * 2.4) * 2.0)
	_ellipse(ci, Vector2(-9, -12) + puff, 7, 4.2, cloud)
	_ellipse(ci, Vector2(8, -13) - puff * 0.6, 8, 4.6, cloud)
	var tip := Vector2(4, -32)
	if phase == "act":
		var lift := clampf(chop + 0.45, 0.0, 1.0)
		tip = Vector2(lerpf(2.0, 14.0, lift), lerpf(-20.0, -36.0, lift))
	_line(ci, Vector2(3, 0), tip, Color("8a7048"), 2.8)
	_dot(ci, tip, 2.6, bolt)
	var flick := sin(clock * 24.0) * 3.0
	_line(ci, tip, tip + Vector2(6.0 + flick, 7.0), bolt, 2.2)
	_line(ci, tip + Vector2(-2.0, 2.0), tip + Vector2(-8.0 + flick * 0.3, 9.0), Color(0.75, 0.9, 1.0, 0.85), 1.6)
	_line(ci, tip + Vector2(5.0, 5.0), tip + Vector2(12.0, 13.0), Color("fff6c8"), 1.7)
	_dot(ci, tip + Vector2(sin(clock * 8.0) * 7.0, 6.0), 1.5, Color(1, 1, 1, 0.75))
	if phase == "act" and chop > 0.3:
		_line(ci, tip + Vector2(8, 8), tip + Vector2(4, 16), bolt, 1.8)


static func _beast_herald(ci: CanvasItem, phase: String, chop: float, calling: bool, clock: float) -> void:
	var hide := Color("4a3050")
	var mouth := Color("1a1018")
	var gold := Color("e6c36a")
	var open := calling or (phase == "act" and beat_open(chop))
	_ellipse(ci, Vector2(0, 18), 13, 3.6, Color(0, 0, 0, 0.26))
	_line(ci, Vector2(-4, 8), Vector2(-6, 17), hide.darkened(0.25), 3.6)
	_line(ci, Vector2(3, 8), Vector2(6, 17), hide, 3.6)
	_poly(ci, PackedVector2Array([
		Vector2(-10, -2),
		Vector2(9, -4),
		Vector2(8, 12),
		Vector2(-8, 12),
	]), hide)
	_ellipse(ci, Vector2(3, -12), 7, 6.5, hide.lightened(0.06))
	_dot(ci, Vector2(1, -13), 1.15, gold)
	_dot(ci, Vector2(5, -13), 1.15, gold)
	var jaw := 3.6 if open else 1.8
	_ellipse(ci, Vector2(8, -9), 3.4, jaw, mouth)
	var horn := Vector2(12, -20)
	if open:
		horn = Vector2(14, -24)
	_line(ci, Vector2(4, -6), horn, Color("d7c49a"), 3.2)
	_poly(ci, PackedVector2Array([
		horn + Vector2(-3, 1),
		horn + Vector2(5, -2),
		horn + Vector2(1, 4),
	]), gold)
	if open:
		var mote := sin(clock * 7.0) * 2.5
		_dot(ci, horn + Vector2(8, 2 + mote), 2.3, gold)
		_dot(ci, horn + Vector2(13, 7 - mote), 1.7, Color("f3e6c8"))


static func _beast_shell(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var plate := Color("6e7886")
	var rim := Color("e7eef6")
	var skin := Color("7f9474")
	var shove := 0.0
	if phase == "act":
		shove = maxf(chop, 0.0) * 5.0
	_ellipse(ci, Vector2(shove, 16), 22, 4.2, Color(0, 0, 0, 0.28))
	_line(ci, Vector2(-12, 8), Vector2(-14.0 - step * 2.0, 16), skin, 3.4)
	_line(ci, Vector2(-4, 10), Vector2(-3.0 + step * 2.0, 16), skin, 3.4)
	_line(ci, Vector2(5, 10), Vector2(6.0 - step, 16), skin, 3.4)
	_line(ci, Vector2(12, 8), Vector2(14.0 + step, 16), skin, 3.2)
	_ellipse(ci, Vector2(shove, 1), 20, 13, plate)
	_ellipse(ci, Vector2(shove - 3, -2), 13, 8, plate.lightened(0.1))
	_line(ci, Vector2(shove - 14, 2), Vector2(shove + 12, 4), plate.darkened(0.18), 1.6)
	_arc(ci, Vector2(shove, 1), 17.5, 3.4, 6.0, 14, rim, 2.6)
	_ellipse(ci, Vector2(16 + shove, 3), 5.2, 4.2, skin)
	_dot(ci, Vector2(18 + shove, 2.2), 1.15, Color("1a140c"))
	if phase == "act" and chop > 0.35:
		_arc(ci, Vector2(18 + shove, 5), 9.0, -0.7, 0.7, 8, Color(0.92, 0.94, 0.96, 0.75), 2.4)


static func _beast_reaver(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var cloth := Color("3a1818")
	var skin := Color("6a5c50")
	var horn := Color("e6c36a")
	var steel := Color("d5dde6")
	_ellipse(ci, Vector2(0, 20), 15, 4.0, Color(0, 0, 0, 0.28))
	_line(ci, Vector2(-4, 8), Vector2(-7.0 - step * 6.0, 18), cloth.darkened(0.25), 4.2)
	_line(ci, Vector2(3, 8), Vector2(8.0 + step * 6.0, 18), cloth, 4.4)
	_poly(ci, PackedVector2Array([
		Vector2(-13, -6),
		Vector2(12, -8),
		Vector2(11, 12),
		Vector2(-11, 12),
	]), cloth)
	_line(ci, Vector2(-12, 1), Vector2(12, 3), Color("c44536"), 3.0)
	_ellipse(ci, Vector2(3, -16), 8, 8, Color("2a1412"))
	_ellipse(ci, Vector2(4, -15), 5.5, 5.2, skin.darkened(0.08))
	_line(ci, Vector2(-1, -22), Vector2(-6, -32), horn, 2.8)
	_line(ci, Vector2(6, -22), Vector2(11, -32), horn, 2.8)
	_dot(ci, Vector2(2, -15), 1.25, Color("d6f5a8"))
	_dot(ci, Vector2(6.5, -15), 1.25, Color("d6f5a8"))
	var along := 0.35
	if phase == "act":
		along = clampf(chop * 0.5 + 0.55, 0.0, 1.0)
	var grip := Vector2(lerpf(2.0, 12.0, along), lerpf(-2.0, 2.0, along))
	var tip := Vector2(lerpf(-2.0, 22.0, along), lerpf(-24.0, 6.0, along))
	_line(ci, Vector2(6, -4), grip, skin, 3.6)
	_line(ci, grip, tip, Color("6b4a32"), 3.0)
	var dir := tip - grip
	var side := Vector2(-dir.y, dir.x)
	if side.length() > 1.0:
		side = side.normalized()
	_poly(ci, PackedVector2Array([
		grip + side * 5.0,
		grip - side * 2.0,
		tip,
	]), steel)
	if phase == "act" and chop > 0.4:
		_arc(ci, tip, 12.0, -1.3, 0.55, 10, Color(0.9, 0.32, 0.22, 0.8), 2.8)


static func beat_open(chop: float) -> bool:
	return chop > -0.2


static func _is_court(paint: String) -> bool:
	return paint == "bomber" or paint == "knives" or paint == "firebow" or paint == "fan" or paint == "ward" or paint == "javelin" or paint == "drum" or paint == "crow" or paint == "cow" or paint == "smog" or paint == "buck" or paint == "scope" or paint == "aria"


static func _paint_court(ci: CanvasItem, paint: String, phase: String, beat: int, t: float, clock: float, pose: Dictionary) -> void:
	var step := 0.0
	if phase == "march":
		step = sin(clock * 8.0)
	var chop := 0.0
	if phase == "act":
		if beat < 2:
			chop = -0.85
		elif beat == 2:
			chop = lerpf(-0.15, 1.0, t)
		else:
			chop = lerpf(1.0, 0.2, t)
	var roost := float(pose.get("roost", 0.0))
	var spears := int(pose.get("spears", 0))
	_tilt = 0.0
	match paint:
		"bomber":
			_court_bomber(ci, step, chop, beat, t)
		"knives":
			_court_knives(ci, step, chop)
		"firebow":
			_court_firebow(ci, step, beat, chop)
		"fan":
			_court_fan(ci, step, chop, clock)
		"ward":
			_court_ward(ci, step, chop)
		"javelin":
			_court_javelin(ci, step, chop, phase, spears)
		"drum":
			_court_drum(ci, step, chop, phase, clock)
		"crow":
			_court_crow(ci, phase, chop, step, roost, clock)
		"cow":
			_court_cow(ci, phase, chop, step, roost, clock)
		"smog":
			_court_smog(ci, step, chop, phase, clock)
		"buck":
			_court_buck(ci, step, chop, phase, pose)
		"scope":
			_court_scope(ci, step, chop, phase, pose)
		"aria":
			_court_aria(ci, step, chop, phase, clock)
	_tilt = 0.0


static func _court_bomber(ci: CanvasItem, step: float, chop: float, beat: int, t: float) -> void:
	var chest := _court_person(ci, Color("241418"), Color("e24b3b"), step)
	var wind := clampf(chop, -0.2, 1.0)
	var hand := chest + Vector2(8.0 + wind * 6.0, -4.0 - wind * 8.0)
	_part_bomb(ci, hand, Color("e24b3b"), beat, t)


static func _court_person(ci: CanvasItem, cloth: Color, trim: Color, step: float) -> Vector2:
	var boot := Color("1c1e22")
	var hood := cloth.darkened(0.42)
	_ellipse(ci, Vector2(0, 18), 16, 4.2, Color(0, 0, 0, 0.28))
	_line(ci, Vector2(-5, 4), Vector2(-7 + step * 4.0, 16), boot, 4.2)
	_line(ci, Vector2(5, 4), Vector2(7 - step * 4.0, 16), boot, 4.2)
	_poly(ci, PackedVector2Array([
		Vector2(-6, 2),
		Vector2(-1, 2),
		Vector2(-2 + step * 3.0, 15),
		Vector2(-8 + step * 3.0, 15),
	]), Color("2c3440"))
	_poly(ci, PackedVector2Array([
		Vector2(1, 2),
		Vector2(6, 2),
		Vector2(8 - step * 3.0, 15),
		Vector2(2 - step * 3.0, 15),
	]), Color("2c3440"))
	_poly(ci, PackedVector2Array([
		Vector2(-12, -22),
		Vector2(12, -22),
		Vector2(13, 6),
		Vector2(-13, 6),
	]), cloth)
	_poly(ci, PackedVector2Array([
		Vector2(-9, -20),
		Vector2(9, -20),
		Vector2(8, 2),
		Vector2(-8, 2),
	]), cloth.darkened(0.18))
	_line(ci, Vector2(-8, -8), Vector2(8, 2), trim, 2.0)
	_box(ci, Rect2(-14, -6, 5, 8), Color("1a1e22"))
	_ellipse(ci, Vector2(-1.4, -33.0), 8.6, 8.8, hood)
	_ellipse(ci, Vector2(2.6, -31.4), 6.2, 6.8, Color("161214"))
	_line(ci, Vector2(-0.2, -32.6), Vector2(6.6, -31.4), Color("8e2430"), 2.2)
	_dot(ci, Vector2(5.2, -33.2), 1.15, Color("e23b3b"))
	_poly(ci, PackedVector2Array([
		Vector2(-5, -26),
		Vector2(2, -27),
		Vector2(0, -18),
		Vector2(-9, -16),
	]), trim.darkened(0.12))
	return Vector2(1, -14)


static func _court_blade(ci: CanvasItem, grip: Vector2, tip: Vector2) -> void:
	var steel := Color("d5dde6")
	var edge := Color("8d98a6")
	_line(ci, grip, tip, Color("6a5438"), 2.2)
	var dir := tip - grip
	if dir.length() < 1.0:
		dir = Vector2(1, 0)
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x)
	var haft := grip + dir * 4.0
	_poly(ci, PackedVector2Array([
		haft + side * 2.2,
		haft - side * 2.2,
		tip,
	]), steel)
	_line(ci, haft, tip, edge, 1.1)


static func _court_knives(ci: CanvasItem, step: float, chop: float) -> void:
	var chest := _court_person(ci, Color("9a3030"), Color("e6c36a"), step)
	var thrust := clampf(chop, -0.3, 1.0)
	var high := chest + Vector2(-4, -2)
	var low := chest + Vector2(2, 8)
	var high_tip := high + Vector2(14.0 + thrust * 14.0, -16.0 + thrust * 8.0)
	var low_tip := low + Vector2(16.0 + thrust * 12.0, 8.0 + thrust * 2.0)
	if chop < 0.0:
		high_tip = high + Vector2(-8, -16)
		low_tip = low + Vector2(-6, -8)
	_court_blade(ci, high, high_tip)
	_court_blade(ci, low, low_tip)


static func _court_firebow(ci: CanvasItem, step: float, beat: int, chop: float) -> void:
	var chest := _court_person(ci, Color("2a2420"), Color("e24b3b"), step)
	var grip := chest + Vector2(4, 2)
	var pull := 0.0
	if beat == 2:
		pull = 0.35 + chop * 0.2
	elif beat >= 3:
		pull = 1.0
	var tube := grip + Vector2(6.0 + pull * 4.0, -2)
	_box(ci, Rect2(tube.x, tube.y - 4.0, 22.0, 8.0), Color("3a4048"))
	_box(ci, Rect2(tube.x + 18.0, tube.y - 5.5, 8.0, 11.0), Color("5a3030"))
	_line(ci, grip + Vector2(-2, 6), tube + Vector2(4, 2), Color("6a5438"), 2.2)
	var flame := Color("ff7a2a")
	var hot := Color("ffe08a")
	if pull > 0.2:
		_poly(ci, PackedVector2Array([
			tube + Vector2(26, 4),
			tube + Vector2(26, -4),
			tube + Vector2(34 + pull * 10.0, 0),
		]), flame)
		_dot(ci, tube + Vector2(28, 0), 2.4, hot)


static func _court_fan(ci: CanvasItem, step: float, chop: float, clock: float) -> void:
	var chest := _court_person(ci, Color("3a4650"), Color("5d8a48"), step)
	var hand := chest + Vector2(4, 6)
	var open := 0.35 + clampf(chop, 0.0, 1.0) * 0.85
	var pivot := hand + Vector2(8, -2)
	_box(ci, Rect2(hand.x - 6.0, hand.y - 6.0, 14.0, 12.0), Color("2c343c"))
	_box(ci, Rect2(pivot.x, pivot.y - 3.5, 16.0 + open * 8.0, 7.0), Color("5a646e"))
	_ellipse(ci, hand + Vector2(-8, 2), 5.0, 6.0, Color("3a4650"))
	if open > 0.7:
		var gust := 0.35 + 0.25 * sin(clock * 10.0)
		_arc(ci, pivot + Vector2(18, -6), 14.0, -0.8, 0.7, 8, Color(0.75, 0.9, 0.86, gust), 2.0)
		_arc(ci, pivot + Vector2(28, 2), 18.0, -0.6, 0.5, 8, Color(0.75, 0.9, 0.86, gust * 0.7), 1.6)


static func _court_ward(ci: CanvasItem, step: float, chop: float) -> void:
	var chest := _court_person(ci, Color("243044"), Color("d7b56a"), step)
	var shove := clampf(chop, 0.0, 1.0) * 8.0
	var shield := chest + Vector2(10.0 + shove, 2)
	_poly(ci, PackedVector2Array([
		shield + Vector2(-2, -16),
		shield + Vector2(16, -14),
		shield + Vector2(16, 16),
		shield + Vector2(-2, 18),
	]), Color("c4a574"))
	_poly(ci, PackedVector2Array([
		shield + Vector2(1, -12),
		shield + Vector2(13, -11),
		shield + Vector2(13, 12),
		shield + Vector2(1, 14),
	]), Color("e6d3a1"))
	_box(ci, Rect2(shield.x + 4.0, shield.y - 4.0, 6.0, 8.0), Color("2a3038"))
	_poly(ci, PackedVector2Array([
		Vector2(-8, -34),
		Vector2(9, -34),
		Vector2(8, -44),
		Vector2(-7, -46),
	]), Color("2a3038"))
	_dot(ci, Vector2(5.4, -33), 1.1, Color("d7e6f2"))


static func _court_javelin(ci: CanvasItem, step: float, chop: float, phase: String, spears: int) -> void:
	var chest := _court_person(ci, Color("243048"), Color("c4a574"), step)
	var wood := Color("8a6844")
	var steel := Color("d5dde6")
	if spears <= 0:
		var hand := chest + Vector2(4, 6)
		var tip := hand + Vector2(8.0 + clampf(chop, 0.0, 1.0) * 14.0, -6.0)
		_court_blade(ci, hand, tip)
		return
	var carried := mini(spears, 3)
	for lance_i in carried:
		var base := chest + Vector2(-12.0 - float(lance_i) * 4.0, 8.0)
		var top := base + Vector2(-2.0 + float(lance_i) * 5.0, -28.0)
		_line(ci, base, top, wood, 2.6)
		_poly(ci, PackedVector2Array([
			top + Vector2(-3.0, 1.0),
			top + Vector2(3.0, 1.0),
			top + Vector2(0.0, -8.0),
		]), steel)
	if phase == "act":
		var hand := chest + Vector2(2, -2)
		var reach := 14.0 + clampf(chop, 0.0, 1.0) * 22.0
		var tip := hand + Vector2(reach, -2)
		_line(ci, hand, tip, wood, 2.6)
		_poly(ci, PackedVector2Array([
			tip + Vector2(-2, 3),
			tip + Vector2(-2, -3),
			tip + Vector2(8, 0),
		]), steel)


static func _court_drum(ci: CanvasItem, step: float, chop: float, phase: String, clock: float) -> void:
	var chest := _court_person(ci, Color("6a3a55"), Color("e6c36a"), step)
	var drum := chest + Vector2(-2, 10)
	_ellipse(ci, drum, 11, 7.5, Color("8e2f2a"))
	_ellipse(ci, drum + Vector2(0, -3), 9, 3.2, Color("e6c36a"))
	_line(ci, drum + Vector2(-9, -1), drum + Vector2(9, -1), Color("5a241c"), 1.4)
	var stick_hand := chest + Vector2(6, 2)
	var hit := drum + Vector2(4, -6)
	if phase != "act":
		hit = chest + Vector2(10, -8)
	elif chop < 0.2:
		hit = chest + Vector2(12, -14)
	_line(ci, stick_hand, hit, Color("6a5438"), 2.0)
	_dot(ci, hit, 2.0, Color("d7c4a2"))
	var mic_hand := chest + Vector2(-6, -2)
	var mic := chest + Vector2(4, -18)
	_line(ci, mic_hand, mic, Color("8d98a6"), 1.8)
	_ellipse(ci, mic + Vector2(3, -2), 4.2, 5.0, Color("c5ccd6"))
	_dot(ci, mic + Vector2(3, -2), 1.5, Color("4a5560"))
	if phase == "act":
		var bob := sin(clock * 8.0) * 2.0
		_court_note(ci, chest + Vector2(16, -28 + bob))
		_court_note(ci, chest + Vector2(26, -18 - bob))


static func _court_note(ci: CanvasItem, at: Vector2) -> void:
	var ink := Color("f4efe4")
	_ellipse(ci, at, 3.2, 2.4, ink)
	_line(ci, at + Vector2(3, 0), at + Vector2(3, -12), ink, 1.3)


static func _court_crow(ci: CanvasItem, phase: String, chop: float, step: float, roost: float, clock: float) -> void:
	var ink := Color("1c2228")
	var arm := Color("8d97a3")
	_ellipse(ci, Vector2(0, 16), 14, 3.2, Color(0, 0, 0, 0.28))
	var body := Vector2(0, -6)
	if phase == "march":
		body.y += step * 2.0
	if phase == "act":
		body.x += clampf(chop, 0.0, 1.0) * 8.0
		body.y += 4.0
	if roost > 0.0:
		body.y = 2.0
	_box(ci, Rect2(body.x - 10.0, body.y - 6.0, 20.0, 12.0), ink)
	_ellipse(ci, body + Vector2(8, 0), 3.2, 3.2, Color("7ec8ff"))
	var spin := clock * (4.0 if roost <= 0.0 else 0.6)
	var hubs: Array = [Vector2(-16, -10), Vector2(16, -10), Vector2(-16, 8), Vector2(16, 8)]
	for hub_i in hubs.size():
		var hub: Vector2 = body + (hubs[hub_i] as Vector2)
		_line(ci, body, hub, arm, 1.6)
		var blade := Vector2(cos(spin + float(hub_i)), sin(spin + float(hub_i))) * 7.0
		_line(ci, hub - blade, hub + blade, Color("d7dde6"), 1.8)
		_dot(ci, hub, 1.6, Color("e6c36a"))
	if phase == "act" and chop > 0.4:
		_line(ci, body + Vector2(10, 0), body + Vector2(24, 2), Color("ff7a2a"), 2.2)


static func _court_cow(ci: CanvasItem, phase: String, chop: float, step: float, roost: float, clock: float) -> void:
	var hide := Color("8a5a32")
	var belly := Color("f0e2c8")
	var hoof := Color("2a2420")
	var lunge := 0.0
	if phase == "act":
		lunge = clampf(chop, 0.0, 1.0) * 14.0
	var bob := 0.0
	if phase == "march":
		bob = step * 2.2
	var dip := 6.0 if roost > 0.0 else 0.0
	var lift := 0.0
	if phase == "march":
		lift = step * 5.0
	elif roost > 0.0:
		lift = maxf(0.0, sin(clock * 7.0)) * 5.0
	_ellipse(ci, Vector2(4, 18), 18, 3.4, Color(0, 0, 0, 0.28))
	var body := Vector2(lunge * 0.3, -2.0 + bob)
	_line(ci, body + Vector2(-12, 6), body + Vector2(-14, 16 - lift), hoof, 3.0)
	_line(ci, body + Vector2(-6, 6), body + Vector2(-5, 16 + lift), hoof, 3.0)
	_line(ci, body + Vector2(8, 6), body + Vector2(10, 16 - lift), hoof, 3.0)
	_line(ci, body + Vector2(14, 6), body + Vector2(16, 16 + lift), hoof, 3.0)
	_ellipse(ci, body + Vector2(2, 1), 18, 9.0, hide)
	_ellipse(ci, body + Vector2(3, 5.6), 8.5, 3.2, belly)
	var flick := sin(clock * 5.0) * 2.2
	_line(ci, body + Vector2(-15, -2), body + Vector2(-22, 4 + flick), hide, 1.8)
	_ellipse(ci, body + Vector2(-22, 6 + flick), 2.4, 2.8, hoof)
	var head := body + Vector2(17 + lunge * 0.45, -6 + dip)
	if phase == "act" and chop > 0.28:
		head.y += 5.0
	_ellipse(ci, head, 6.6, 5.4, hide)
	_ellipse(ci, head + Vector2(5.2, 1.2), 3.6, 2.5, Color("c47a6a"))
	_dot(ci, head + Vector2(2.2, -1.1), 0.95, Color("1c140e"))
	_ellipse(ci, head + Vector2(-1.6, -4.2), 2.4, 1.5, hide)
	_line(ci, head + Vector2(-1, -4), head + Vector2(-5, -13), Color("f4efe4"), 1.9)
	_line(ci, head + Vector2(2.2, -4.2), head + Vector2(7, -12), Color("f4efe4"), 1.9)
	if phase == "act" and chop > 0.45:
		_line(ci, head + Vector2(7, 1), head + Vector2(16, 3), Color("ffd9a0"), 1.6)


static func _dire_stripe(ci: CanvasItem) -> void:
	_line(ci, Vector2(-8, -18), Vector2(10, -8), Color("c44536"), 2.2)
	_poly(ci, PackedVector2Array([
		Vector2(8, -28),
		Vector2(14, -24),
		Vector2(6, -20),
	]), Color("2a3038"))


static func _court_smog(ci: CanvasItem, step: float, chop: float, phase: String, clock: float) -> void:
	var chest := _court_person(ci, Color("c9a227"), Color("f4efe4"), step)
	_box(ci, Rect2(chest.x - 16.0, chest.y - 4.0, 8.0, 14.0), Color("b23a2f"))
	_ellipse(ci, chest + Vector2(-12, -8), 4.0, 3.0, Color("d7dde6"))
	var hose := chest + Vector2(-8, 2)
	var nozzle := chest + Vector2(16.0 + clampf(chop, 0.0, 1.0) * 6.0, -4.0)
	_line(ci, hose, nozzle, Color("2a3038"), 3.2)
	_box(ci, Rect2(nozzle.x, nozzle.y - 3.0, 8.0, 6.0), Color("d7dde6"))
	if phase == "march" or phase == "act":
		var puff := 0.45 + 0.25 * sin(clock * 9.0)
		_ellipse(ci, nozzle + Vector2(14, -6), 7.0, 5.0, Color(0.9, 0.91, 0.9, puff))
		_ellipse(ci, nozzle + Vector2(22, -14), 5.0, 4.0, Color(0.82, 0.84, 0.84, puff * 0.8))


static func _court_buck(ci: CanvasItem, step: float, chop: float, phase: String, pose: Dictionary) -> void:
	var chest := _court_person(ci, Color("3a4654"), Color("d7b56a"), step)
	var pump := 0.0
	if phase == "act":
		pump = clampf(chop, 0.0, 1.0) * 6.0
	if float(pose.get("loading", 0.0)) > 0.05:
		pump = 8.0
	var stock := chest + Vector2(-8, 6)
	var muzzle := chest + Vector2(18, -4)
	_line(ci, stock + Vector2(0, 4), stock, Color("4a4034"), 4.0)
	_line(ci, stock, muzzle, Color("2a3038"), 5.0)
	_line(ci, stock + Vector2(6, 1), stock + Vector2(6 + pump, 7), Color("6a5438"), 3.2)
	_box(ci, Rect2(muzzle.x - 1.0, muzzle.y - 4.0, 14.0, 8.0), Color("1c1e22"))
	if phase == "act" and chop > 0.55:
		_poly(ci, PackedVector2Array([
			muzzle + Vector2(10, 2),
			muzzle + Vector2(10, -2),
			muzzle + Vector2(20, 0),
		]), Color("ffe08a"))


static func _court_scope(ci: CanvasItem, step: float, chop: float, phase: String, pose: Dictionary) -> void:
	var chest := _court_person(ci, Color("3d4a38"), Color("8d97a3"), step)
	var stock := chest + Vector2(-12, 4)
	var muzzle := chest + Vector2(26, -8)
	if float(pose.get("loading", 0.0)) > 0.05 or (phase != "act" and float(pose.get("bolt", 0.0)) > 0.4):
		muzzle.y += 3.0
	_line(ci, stock + Vector2(-2, 6), stock, Color("3a4034"), 3.4)
	_line(ci, stock, muzzle, Color("1c1e22"), 3.6)
	_box(ci, Rect2(chest.x + 2.0, chest.y - 14.0, 16.0, 4.0), Color("2a3038"))
	_line(ci, chest + Vector2(8, -10), chest + Vector2(8, -16), Color("8d97a3"), 1.8)
	_box(ci, Rect2(muzzle.x, muzzle.y - 2.5, 12.0, 5.0), Color("3a4048"))
	if phase == "act" and chop > 0.45:
		_line(ci, muzzle, muzzle + Vector2(16, -1), Color("ffe08a"), 2.0)
		_dot(ci, muzzle + Vector2(6, 0), 2.2, Color("ff7a2a"))


static func _court_aria(ci: CanvasItem, step: float, chop: float, phase: String, clock: float) -> void:
	var chest := _court_person(ci, Color("6a3a55"), Color("f4efe4"), step)
	_ellipse(ci, Vector2(1, -30), 8.0, 6.0, Color("3a2418"))
	_line(ci, Vector2(-6, -36), Vector2(-10, -28), Color("3a2418"), 2.4)
	var hand := chest + Vector2(4, 2)
	var mic := hand + Vector2(6.0, -16.0 - clampf(chop, 0.0, 1.0) * 4.0)
	_line(ci, hand, mic, Color("8d98a6"), 2.0)
	_ellipse(ci, mic, 3.4, 5.2, Color("d7dde6"))
	_dot(ci, mic + Vector2(0, -1), 1.3, Color("2a3038"))
	if phase == "act" or phase == "march":
		var bob := sin(clock * 7.0) * 3.0
		_court_note(ci, chest + Vector2(16, -24 + bob))
		_court_note(ci, chest + Vector2(24, -12 - bob))


static func _beast_walker(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var hide := Color("4e5a3a")
	var plate := Color("2a3038")
	_ellipse(ci, Vector2(0, 18), 16, 4.0, Color(0, 0, 0, 0.3))
	_line(ci, Vector2(-4, 0), Vector2(-8 + step * 6.0, 16), plate, 4.0)
	_line(ci, Vector2(4, 0), Vector2(8 - step * 6.0, 16), plate, 4.0)
	_ellipse(ci, Vector2(0, -8), 9, 12, hide)
	_line(ci, Vector2(-8, -10), Vector2(-14, 2), hide, 3.4)
	_ellipse(ci, Vector2(0.6, -23.2), 7.2, 7.0, Color("1a1614"))
	_ellipse(ci, Vector2(2.4, -21.6), 5.2, 5.4, Color("121614"))
	_line(ci, Vector2(0.4, -22.4), Vector2(5.6, -21.4), Color("3d5a32"), 1.8)
	_dot(ci, Vector2(4.6, -22.8), 1.1, Color("d6f5a8"))
	var hand := Vector2(8, -6)
	var tip := hand + Vector2(8, 8)
	if phase == "act":
		tip = hand + Vector2(12.0 + clampf(chop, 0.0, 1.0) * 10.0, -8.0 + clampf(chop, 0.0, 1.0) * 14.0)
	_line(ci, Vector2(6, -12), hand, hide, 3.2)
	_court_blade(ci, hand, tip)


static func _beast_runner(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var hide := Color("5c6844")
	var lean := 8.0 if phase == "march" else 2.0
	_ellipse(ci, Vector2(4, 18), 18, 3.6, Color(0, 0, 0, 0.28))
	_line(ci, Vector2(-2, 0), Vector2(-10 + step * 6.0, 16), Color("1c1e22"), 3.2)
	_line(ci, Vector2(6, -2), Vector2(14 - step * 4.0, 14), Color("1c1e22"), 3.2)
	_ellipse(ci, Vector2(lean, -8), 12, 7, hide)
	_ellipse(ci, Vector2(lean + 8.2, -17.2), 6.4, 6.0, Color("1a1614"))
	_ellipse(ci, Vector2(lean + 10.4, -15.6), 4.6, 4.4, Color("121614"))
	_line(ci, Vector2(lean + 8.4, -16.2), Vector2(lean + 13.2, -15.2), Color("3d5a32"), 1.6)
	_dot(ci, Vector2(lean + 12.4, -16.6), 1.0, Color("d6f5a8"))
	var tip := Vector2(lean + 18.0 + clampf(chop, 0.0, 1.0) * 8.0, -4)
	_court_blade(ci, Vector2(lean + 8, -6), tip)


static func _beast_oni(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var hide := Color("6a3030")
	var iron := Color("3a4048")
	_ellipse(ci, Vector2(0, 20), 22, 5, Color(0, 0, 0, 0.32))
	_line(ci, Vector2(-8, 4), Vector2(-10 + step * 3.0, 18), iron, 5.0)
	_line(ci, Vector2(8, 4), Vector2(10 - step * 3.0, 18), iron, 5.0)
	_ellipse(ci, Vector2(0, -6), 18, 16, hide)
	_poly(ci, PackedVector2Array([
		Vector2(-16, -8),
		Vector2(-22, -20),
		Vector2(-8, -14),
	]), iron)
	_poly(ci, PackedVector2Array([
		Vector2(16, -8),
		Vector2(24, -22),
		Vector2(8, -14),
	]), iron)
	_ellipse(ci, Vector2(0.4, -25.2), 9.2, 8.8, Color("1a1214"))
	_ellipse(ci, Vector2(2.6, -23.4), 6.4, 6.2, Color("2a1418"))
	_line(ci, Vector2(0.2, -24.2), Vector2(6.4, -23.0), Color("8e2430"), 2.0)
	_dot(ci, Vector2(5.2, -24.6), 1.25, Color("e23b3b"))
	_poly(ci, PackedVector2Array([
		Vector2(-4, -30),
		Vector2(-12, -42),
		Vector2(0, -32),
	]), Color("e6c36a"))
	_poly(ci, PackedVector2Array([
		Vector2(6, -30),
		Vector2(14, -42),
		Vector2(2, -32),
	]), Color("e6c36a"))
	var grip := Vector2(10, -4)
	var tip := grip + Vector2(8.0, -22.0 + clampf(chop, 0.0, 1.0) * 28.0)
	if phase != "act":
		tip = grip + Vector2(6, -18)
	_line(ci, grip, tip, Color("6a5438"), 3.4)
	_poly(ci, PackedVector2Array([
		tip + Vector2(-5, 2),
		tip + Vector2(5, 2),
		tip + Vector2(0, -10),
	]), Color("d7dde6"))


static func _beast_moth(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var wing := Color("c4a574")
	var membrane := Color("e6d3a1")
	var body := Color("5c4030")
	var flap := step * 8.0
	if phase == "act":
		flap = 2.0 + clampf(chop, 0.0, 1.0) * 14.0
	_ellipse(ci, Vector2(4, 14), 8, 2.2, Color(0, 0, 0, 0.18))
	_ellipse(ci, Vector2(-6, -16 - flap * 0.3), 10, 6, wing)
	_ellipse(ci, Vector2(-14, -6 + flap * 0.2), 8, 4.5, membrane)
	_ellipse(ci, Vector2(16, -14 - flap * 0.3), 10, 6, wing)
	_ellipse(ci, Vector2(22, -4 + flap * 0.2), 7, 4, membrane)
	_ellipse(ci, Vector2(2, -2), 5.5, 11, body)
	_ellipse(ci, Vector2(6.6, -13.0), 5.0, 4.6, Color("2a221c"))
	_ellipse(ci, Vector2(8.2, -11.6), 3.4, 3.2, Color("1a1614"))
	_dot(ci, Vector2(9.4, -12.2), 1.0, Color("d6f5a8"))
	_line(ci, Vector2(6, -14), Vector2(12, -18), Color("2a2420"), 1.3)
	_line(ci, Vector2(7, -13), Vector2(13, -15), Color("2a2420"), 1.3)
	var sting := Vector2(2, 12)
	if phase == "act":
		sting = Vector2(14.0 + clampf(chop, 0.0, 1.0) * 10.0, 4.0)
	_line(ci, Vector2(2, 8), sting, Color("2a2420"), 2.2)
	_dot(ci, sting, 1.8, Color("c44536"))


static func _beast_elder(ci: CanvasItem, phase: String, chop: float, step: float) -> void:
	var coat := Color("4a4038")
	var hair := Color("f4efe4")
	_ellipse(ci, Vector2(0, 18), 14, 3.6, Color(0, 0, 0, 0.28))
	var limp := step * 3.0
	_line(ci, Vector2(-4, 2), Vector2(-8 + limp, 16), Color("1c1e22"), 3.0)
	_line(ci, Vector2(3, 4), Vector2(2, 16), Color("1c1e22"), 3.0)
	_poly(ci, PackedVector2Array([
		Vector2(-8, -8),
		Vector2(6, -18),
		Vector2(8, 6),
		Vector2(-10, 8),
	]), coat)
	_ellipse(ci, Vector2(2.4, -25.2), 7.4, 6.8, Color("1a1614"))
	_ellipse(ci, Vector2(4.2, -23.6), 5.0, 4.6, Color("3a342e"))
	_line(ci, Vector2(2.2, -24.2), Vector2(7.0, -23.4), Color("9a8c80"), 1.6)
	_dot(ci, Vector2(6.2, -24.6), 1.1, Color("f4efe4"))
	_ellipse(ci, Vector2(4, -30), 7.0, 3.4, hair)
	var grip := Vector2(-6, 0)
	var tip := grip + Vector2(-4, 14)
	if phase == "act":
		tip = grip + Vector2(16.0 * clampf(chop, 0.0, 1.0), -8.0 + clampf(chop, 0.0, 1.0) * 16.0)
	_line(ci, grip, tip, Color("6a5438"), 3.0)
	_ellipse(ci, tip, 4.2, 3.4, Color("8a9098"))


static func _beast_glut(ci: CanvasItem, phase: String, chop: float, step: float, pose: Dictionary) -> void:
	var hide := Color("6a4030")
	var belly := Color("8a705c")
	var sit := float(pose.get("sit", 0.0))
	var drop := 10.0 if sit > 0.05 else 0.0
	_ellipse(ci, Vector2(2, 20), 24, 5, Color(0, 0, 0, 0.32))
	if sit <= 0.05:
		_line(ci, Vector2(-10, 6), Vector2(-16 + step * 3.0, 18), hide, 6.0)
		_line(ci, Vector2(8, 8), Vector2(16 - step * 3.0, 18), hide, 6.0)
	else:
		_ellipse(ci, Vector2(-12, 14), 8, 4, hide)
		_ellipse(ci, Vector2(14, 14), 8, 4, hide)
	_ellipse(ci, Vector2(0, 2 + drop), 20, 13, hide)
	_ellipse(ci, Vector2(2, 4 + drop), 14, 10, belly)
	_line(ci, Vector2(-16, -2 + drop), Vector2(-24, 6 + drop), hide, 4.0)
	_ellipse(ci, Vector2(4.4, -15.2 + drop), 10.0, 8.6, Color("1a1614"))
	_ellipse(ci, Vector2(6.6, -13.6 + drop), 6.8, 6.0, Color("2a221c"))
	_dot(ci, Vector2(9.2, -14.6 + drop), 1.15, Color("d6f5a8"))
	var open := sit > 0.05 or (phase == "act" and chop > 0.15)
	if open:
		_ellipse(ci, Vector2(16, -8 + drop), 8, 7, Color("6a2030"))
		_poly(ci, PackedVector2Array([
			Vector2(10, -14 + drop),
			Vector2(18, -15 + drop),
			Vector2(14, -8 + drop),
		]), Color("f4efe4"))
		_poly(ci, PackedVector2Array([
			Vector2(12, -2 + drop),
			Vector2(20, -3 + drop),
			Vector2(16, -9 + drop),
		]), Color("f4efe4"))
	else:
		_line(ci, Vector2(12, -10 + drop), Vector2(18, -8 + drop), Color("6a2030"), 2.0)


static func _beast_brood(ci: CanvasItem, phase: String, chop: float, step: float, small: bool) -> void:
	var scale := 0.62 if small else 1.0
	var ink := Color("2a2428")
	var leg := Color("4a3840")
	_ellipse(ci, Vector2(0, 16 * scale), 12 * scale, 3 * scale, Color(0, 0, 0, 0.28))
	var body := Vector2(0, -2 * scale)
	_ellipse(ci, body + Vector2(-6 * scale, 4 * scale), 9 * scale, 7 * scale, ink)
	_ellipse(ci, body + Vector2(7 * scale, -2 * scale), 7 * scale, 6 * scale, ink.lightened(0.08))
	for leg_i in 8:
		var side := -1.0 if leg_i < 4 else 1.0
		var slot := float(leg_i % 4)
		var sway := step * 5.0 * side * (1.0 if int(slot) % 2 == 0 else -1.0)
		if phase == "act":
			sway = clampf(chop, 0.0, 1.0) * 7.0 * side
		var hip := body + Vector2(side * 4.0 * scale, (-8.0 + slot * 5.0) * scale)
		var knee := hip + Vector2(side * 8.0 * scale, -4.0 * scale)
		var foot := hip + Vector2(side * (14.0 * scale + sway), 10.0 * scale)
		_line(ci, hip, knee, leg, 1.8 if small else 2.4)
		_line(ci, knee, foot, leg, 1.8 if small else 2.4)
	var bite := body + Vector2(12 * scale, 0)
	if phase == "act":
		bite.x += clampf(chop, 0.0, 1.0) * 6.0 * scale
	_line(ci, body + Vector2(4 * scale, -2 * scale), bite + Vector2(0, -3 * scale), Color("e7d2b0"), 1.6)
	_line(ci, body + Vector2(4 * scale, 2 * scale), bite + Vector2(0, 3 * scale), Color("e7d2b0"), 1.6)
	_dot(ci, body + Vector2(6 * scale, -3 * scale), 1.1, Color("c44536"))
