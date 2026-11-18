extends RefCounted

static var saber_navy: bool = false
static var sheet_on: Dictionary = {}

const GROUND_Y := 20.0
const HEAD_R := 16.0
const BODY_W := 22.0
const BODY_H := 16.0
const LIMB_T := 6.0
const UPPER_L := 10.0
const LOWER_L := 9.0
const LEG_L := 12.0


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
	var sheet := false
	if sheet_on.has(kind):
		sheet = bool(sheet_on[kind])
	return look_as(kind, sheet, kind == "saber" and saber_navy)


static func look_as(kind: String, sheet: bool, navy: bool) -> Dictionary:
	var row := _painted(kind)
	row["paint"] = kind
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
	if paint == "knives" or paint == "firebow" or paint == "fan" or paint == "ward" or paint == "javelin" or paint == "drum" or paint == "crow" or paint == "cow" or paint == "smog" or paint == "buck" or paint == "scope" or paint == "aria":
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


# The roster shares one small body so a crowded fight stays light.
# The sword soldier is the sample in the chunky icon style. Everyone else stays here.

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


static func paint_local(ci: CanvasItem, look: Dictionary, pose: Dictionary) -> void:
	var phase := str(pose.get("phase", "idle"))
	var along := float(pose.get("t", 0.0))
	var clock := float(pose.get("clock", 0.0))
	var beat := int(pose.get("beat", 0))
	var flash := float(pose.get("flash", 0.0))
	var skin: Color = look["skin"]
	var cloth: Color = look["cloth"]
	var trim: Color = look["trim"]
	if flash > 0.0:
		var wash := clampf(flash * 4.0, 0.0, 0.72)
		skin = skin.lerp(Color.WHITE, wash)
		cloth = cloth.lerp(Color.WHITE, wash)
		trim = trim.lerp(Color.WHITE, wash)
	var step := _step_of(phase, clock, along)
	var chop := _chop_of(phase, beat, along)
	var hip := Vector2(2.0, 4.0)
	if phase == "fall":
		hip = Vector2(10.0, 12.0)
	elif phase == "hurt":
		hip = Vector2(-1.0, 7.0)
	elif phase == "debut":
		hip.y = lerpf(16.0, 4.0, along)
	var steel := _steel_color(look, trim)
	var paint := str(look.get("paint", ""))
	if paint == "sword":
		_paint_sword(ci, hip, step, chop, skin, cloth, trim, steel, phase, flash)
		return
	var belt := _belt_color(look, trim)
	var weapon := str(pose.get("tool", look.get("weapon", "katana")))
	_shadow(ci, hip)
	if bool(look.get("mount", false)):
		_mount(ci, cloth, trim, step)
		hip = Vector2(hip.x - 4.0, 2.0)
	else:
		_legs(ci, hip, step, cloth)
	_torso(ci, hip, cloth, belt)
	var hand := _arms(ci, hip, chop, step, cloth)
	_hood(ci, hip, look, skin, cloth, trim, phase)
	_weapon(ci, paint, weapon, hand, chop, trim, cloth, steel)


static func paint_ailment(ci: CanvasItem, bone: float, still: float, clock: float) -> void:
	if still > 0.0:
		var ring := 0.28 + 0.22 * sin(clock * 6.0)
		ci.draw_arc(Vector2(0, -28), 22.0, 0.4, TAU - 0.2, 8, Color(0.62, 0.9, 0.7, ring), 2.0)
	if bone <= 0.0:
		return
	var chalk := Color(0.96, 0.94, 0.88, clampf(bone / 0.9, 0.0, 1.0))
	ci.draw_line(Vector2(-10, -42), Vector2(-2, -24), chalk, 2.0)
	ci.draw_line(Vector2(8, -42), Vector2(2, -24), chalk, 2.0)
	ci.draw_line(Vector2(-6, -10), Vector2(8, -4), chalk, 2.0)


static func _step_of(phase: String, clock: float, along: float) -> float:
	if phase == "march" or phase == "tale":
		return sin(clock * 8.0)
	if phase == "act":
		return sin(clock * 8.0) * 0.2
	if phase == "hurt":
		return -0.35
	if phase == "fall":
		return along * 0.8
	return 0.12


static func _chop_of(phase: String, beat: int, along: float) -> float:
	if phase == "act":
		if beat >= 2:
			return lerpf(0.55, 1.0, along)
		if beat == 1:
			return 0.45
		return 0.15
	if phase == "hurt" or phase == "fall":
		return -0.15
	return 0.35


static func _belt_color(look: Dictionary, trim: Color) -> Color:
	if not look.has("scarf"):
		return trim
	var scarf_v: Variant = look["scarf"]
	if scarf_v is Color:
		var scarf: Color = scarf_v
		if scarf.a > 0.2:
			return scarf
	return trim


static func _steel_color(look: Dictionary, trim: Color) -> Color:
	var steel := trim.lightened(0.35)
	if not look.has("blade"):
		return steel
	var blade_v: Variant = look["blade"]
	if blade_v is Color:
		var blade: Color = blade_v
		if blade.a > 0.05:
			return blade
	return steel


static func _shadow(ci: CanvasItem, hip: Vector2) -> void:
	ci.draw_rect(Rect2(hip.x - 16.0, GROUND_Y - 1.0, 34.0, 4.0), Color(0, 0, 0, 0.28), true)


static func _bone(ci: CanvasItem, origin: Vector2, angle: float, length: float, thick: float, color: Color) -> Vector2:
	var dir := Vector2(cos(angle), sin(angle))
	var side := Vector2(-dir.y, dir.x) * (thick * 0.5)
	var end := origin + dir * length
	var pts := PackedVector2Array()
	pts.append(origin - side)
	pts.append(origin + side)
	pts.append(end + side)
	pts.append(end - side)
	ci.draw_colored_polygon(pts, color)
	return end


static func _legs(ci: CanvasItem, hip: Vector2, step: float, cloth: Color) -> void:
	var boot := cloth.darkened(0.12)
	_bone(ci, hip + Vector2(-6.0, 0.0), PI * 0.5 + 0.28 + step * 0.32, LEG_L, LIMB_T, boot)
	_bone(ci, hip + Vector2(5.0, 0.0), PI * 0.5 - 0.22 - step * 0.32, LEG_L, LIMB_T, boot)


static func _torso(ci: CanvasItem, hip: Vector2, cloth: Color, belt: Color) -> void:
	var left := hip.x - BODY_W * 0.5
	var top := hip.y - BODY_H
	ci.draw_rect(Rect2(left, top, BODY_W, BODY_H), cloth, true)
	ci.draw_rect(Rect2(left, hip.y - 6.0, BODY_W, 4.2), belt, true)


static func _arms(ci: CanvasItem, hip: Vector2, chop: float, step: float, cloth: Color) -> Vector2:
	var sleeve := cloth.darkened(0.06)
	var glove := cloth.darkened(0.16)
	var back_shoulder := hip + Vector2(-8.0, -BODY_H + 3.0)
	var front_shoulder := hip + Vector2(7.0, -BODY_H + 3.0)
	var back_angle := -2.15 + step * 0.12
	var back_elbow := _bone(ci, back_shoulder, back_angle, UPPER_L, LIMB_T, sleeve)
	_bone(ci, back_elbow, back_angle + 0.55, LOWER_L, LIMB_T - 1.0, glove)
	var front_angle := -0.28 - chop * 0.85
	var front_elbow := _bone(ci, front_shoulder, front_angle, UPPER_L, LIMB_T, sleeve)
	return _bone(ci, front_elbow, front_angle + 0.22, LOWER_L, LIMB_T - 1.0, glove)


static func _hood(ci: CanvasItem, hip: Vector2, look: Dictionary, skin: Color, cloth: Color, trim: Color, phase: String) -> void:
	var faction := str(look.get("faction", "ninja"))
	var center := hip + Vector2(1.0, -BODY_H - HEAD_R + 4.0)
	ci.draw_circle(center, HEAD_R, cloth)
	ci.draw_rect(Rect2(center.x - HEAD_R + 2.0, center.y - 9.0, HEAD_R * 2.0 - 4.0, 4.0), trim, true)
	var mask := skin
	var slit := Color(0.12, 0.08, 0.08)
	var eye := Color(0.96, 0.95, 0.9)
	var ninja := faction == "ninja"
	if faction == "cursed" or faction == "beast":
		mask = Color("121614")
		slit = Color("3d5a32")
		eye = Color("d6f5a8")
		ninja = false
	elif not ninja:
		mask = Color("161214")
		slit = Color("8e2430")
		eye = Color("e23b3b")
	else:
		ci.draw_rect(Rect2(center.x - HEAD_R - 12.0, center.y - 9.0, 18.0, 4.0), trim, true)
		if look.has("eye"):
			var stored: Variant = look["eye"]
			if stored is Color:
				var picked: Color = stored
				eye = picked
	if phase == "hurt" or phase == "fall":
		eye = Color(0.9, 0.9, 0.85)
		slit = eye
	ci.draw_rect(Rect2(center.x - 1.5, center.y - 2.0, 15.0, 13.0), mask, true)
	ci.draw_rect(Rect2(center.x + 2.0, center.y + 4.2, 8.0, 2.2), slit, true)
	ci.draw_rect(Rect2(center.x + 6.2, center.y + 0.2, 5.2, 3.6), eye, true)
	if ninja and phase != "hurt" and phase != "fall":
		ci.draw_rect(Rect2(center.x + 8.6, center.y + 1.2, 1.8, 1.8), Color(0.1, 0.08, 0.08), true)
	_bone(ci, center + Vector2(2.4, -1.2), -0.42, 8.0, 1.8, cloth.darkened(0.5))
	if bool(look.get("horns", false)):
		_bone(ci, center + Vector2(-3.0, -HEAD_R + 3.0), -2.3, 8.0, 2.2, trim)
		_bone(ci, center + Vector2(2.0, -HEAD_R + 3.0), -0.75, 8.0, 2.2, trim)


static func _mount(ci: CanvasItem, cloth: Color, trim: Color, step: float) -> void:
	var hide := cloth.darkened(0.22)
	var body := Vector2(-4.0, 10.0)
	ci.draw_rect(Rect2(body.x - 20.0, body.y - 8.0, 48.0, 16.0), hide, true)
	ci.draw_circle(body + Vector2(26.0, -7.0), 9.0, hide.lightened(0.08))
	ci.draw_rect(Rect2(body.x + 20.0, body.y - 13.0, 12.0, 3.2), trim, true)
	var hoof := hide.darkened(0.12)
	_bone(ci, body + Vector2(-12.0, 8.0), PI * 0.5 + step * 0.35, 12.0, 4.2, hoof)
	_bone(ci, body + Vector2(-2.0, 8.0), PI * 0.5 - step * 0.35, 12.0, 4.2, hoof)
	_bone(ci, body + Vector2(10.0, 8.0), PI * 0.5 + step * 0.3, 12.0, 4.2, hoof)
	_bone(ci, body + Vector2(18.0, 8.0), PI * 0.5 - step * 0.3, 12.0, 4.2, hoof)


static func _weapon(ci: CanvasItem, paint: String, weapon: String, hand: Vector2, chop: float, trim: Color, cloth: Color, steel: Color) -> void:
	match weapon:
		"bow":
			_bow(ci, hand, trim)
		"crossbow":
			_crossbow(ci, hand, trim, cloth)
		"shield":
			_shield(ci, hand, trim, cloth)
		"spear", "polearm":
			_spear(ci, hand, trim)
		"axe":
			_axe(ci, hand, trim)
		"hammer", "club":
			_blunt(ci, hand, trim)
		"bomb":
			_bomb(ci, hand, trim)
		"staff", "scroll":
			_staff(ci, paint, hand, trim, cloth)
		_:
			_blade(ci, hand, chop, steel, trim)


static func _blade(ci: CanvasItem, hand: Vector2, chop: float, steel: Color, trim: Color) -> void:
	_bone(ci, hand, -0.06 - chop * 0.85, 20.0, 2.2, steel)
	ci.draw_rect(Rect2(hand.x - 2.0, hand.y - 1.5, 6.0, 3.2), trim, true)


static func _bow(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	var upper := _bone(ci, hand, -1.45, 15.0, 2.2, trim)
	var lower := _bone(ci, hand, -0.15, 15.0, 2.2, trim)
	ci.draw_line(upper, lower, trim.lightened(0.35), 1.2)


static func _crossbow(ci: CanvasItem, hand: Vector2, trim: Color, cloth: Color) -> void:
	ci.draw_rect(Rect2(hand.x - 2.0, hand.y - 4.0, 16.0, 6.0), cloth.darkened(0.2), true)
	_bone(ci, hand + Vector2(4.0, -1.0), -1.15, 10.0, 2.0, trim)
	_bone(ci, hand + Vector2(4.0, -1.0), -0.15, 10.0, 2.0, trim)


static func _shield(ci: CanvasItem, hand: Vector2, trim: Color, cloth: Color) -> void:
	ci.draw_rect(Rect2(hand.x - 1.0, hand.y - 16.0, 16.0, 26.0), trim, true)
	ci.draw_rect(Rect2(hand.x + 2.0, hand.y - 12.0, 10.0, 18.0), cloth.lightened(0.12), true)


static func _spear(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	var tip := _bone(ci, hand, -0.5, 26.0, 2.3, Color("c8b48a"))
	_bone(ci, tip, -0.5, 6.0, 4.2, trim)


static func _axe(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	var head := _bone(ci, hand, -0.9, 14.0, 3.0, Color("c8b48a"))
	ci.draw_rect(Rect2(head.x - 2.0, head.y - 7.0, 12.0, 10.0), trim, true)


static func _blunt(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	var head := _bone(ci, hand, -0.95, 14.0, 3.2, Color("6b4a32"))
	ci.draw_rect(Rect2(head.x - 6.0, head.y - 5.0, 14.0, 10.0), trim, true)


static func _bomb(ci: CanvasItem, hand: Vector2, trim: Color) -> void:
	ci.draw_circle(hand, 6.0, Color(0.12, 0.1, 0.1))
	ci.draw_rect(Rect2(hand.x + 1.0, hand.y - 11.0, 2.2, 5.0), trim, true)


static func _staff(ci: CanvasItem, paint: String, hand: Vector2, trim: Color, cloth: Color) -> void:
	if paint == "fan":
		var leaf := Color("7dcea0")
		_bone(ci, hand, -0.55, 7.0, 2.2, Color("6b4a32"))
		_bone(ci, hand + Vector2(2.0, -2.0), -0.25, 16.0, 3.6, leaf.darkened(0.08))
		_bone(ci, hand + Vector2(1.0, -3.0), -0.72, 18.0, 3.6, leaf)
		_bone(ci, hand + Vector2(0.0, -3.0), -1.2, 16.0, 3.6, leaf.lightened(0.08))
		return
	if paint == "drum":
		ci.draw_rect(Rect2(hand.x - 7.0, hand.y - 10.0, 16.0, 14.0), trim, true)
		ci.draw_rect(Rect2(hand.x - 4.0, hand.y - 7.0, 10.0, 8.0), cloth.lightened(0.15), true)
		return
	_bone(ci, hand, -1.15, 22.0, 2.8, trim)


# Shop Sword only. Cube head with a front face, gold-trimmed helmet, feather crest,
# short body, one boot, two arm segments, and a small sword.
static func _paint_sword(ci: CanvasItem, hip: Vector2, step: float, chop: float, skin: Color, cloth: Color, trim: Color, steel: Color, phase: String, flash: float) -> void:
	var wash := clampf(flash * 4.0, 0.0, 0.72)
	var kept := skin.a * cloth.a * trim.a * steel.a
	var ink := Color("1a120e").lerp(Color.WHITE, wash * kept)
	var face := Color("f7d2ae").lerp(Color.WHITE, wash)
	var side := Color("e2b08a").lerp(Color.WHITE, wash)
	var metal := Color("5a6570").lerp(Color.WHITE, wash)
	var metal_shade := Color("414a54").lerp(Color.WHITE, wash)
	var metal_deep := Color("353d46").lerp(Color.WHITE, wash)
	var gold := Color("f2b428").lerp(Color.WHITE, wash)
	var gold_deep := Color("d49216").lerp(Color.WHITE, wash)
	var plume := Color("f0e7b8").lerp(Color.WHITE, wash)
	var plume_side := Color("ddd4a4").lerp(Color.WHITE, wash)
	var blade := Color("e7eef6").lerp(steel, 0.16).lerp(Color.WHITE, wash)
	var blade_lit := Color("f8fbfc").lerp(Color.WHITE, wash)
	var hurt := phase == "hurt" or phase == "fall"
	var head := Rect2(hip.x - 20.0, hip.y - 46.0, 40.0, 32.0)
	var helm := Rect2(hip.x - 17.0, hip.y - 58.0, 34.0, 17.0)
	var body := Rect2(hip.x - 12.0, hip.y - 17.0, 24.0, 11.0)
	var plate := Rect2(hip.x - 4.0, hip.y - 14.8, 8.4, 6.6)
	var boot := Rect2(hip.x - 8.5, hip.y - 7.6, 17.0, 5.2)
	var crown := Vector2(helm.position.x + helm.size.x * 0.5, helm.position.y + 1.5)
	_chunk(ci, Rect2(hip.x - 13.0, hip.y - 2.6, 26.0, 4.4), 2.1, Color(0, 0, 0, 0.24), Color(0, 0, 0, 0), 0.0)
	var boot_pivot := Vector2(boot.position.x + boot.size.x * 0.5, boot.position.y + 0.4)
	var boot_pts := _turn(_squircle(boot, 3.0), boot_pivot, step * 0.3)
	_paint_poly(ci, boot_pts, metal_deep, ink, 2.4)
	_chunk(ci, body, 4.4, metal, ink, 2.5)
	_chunk(ci, Rect2(body.position.x + 11.5, body.position.y + 2.6, 9.6, 6.2), 2.4, metal_shade, metal_shade, 0.0)
	_chunk(ci, plate, 2.2, gold, ink, 2.0)
	_chunk(ci, head, 8.8, face, ink, 2.6)
	_chunk(ci, Rect2(head.position.x + 2.6, head.position.y + 12.5, 9.2, 16.2), 2.4, side, side, 0.0)
	_framed(ci, helm, 7.4, metal, gold, ink, 2.3, 2.5)
	_chunk(ci, Rect2(helm.position.x + 15.0, helm.position.y + 4.0, 14.0, 8.0), 3.0, metal_shade, metal_shade, 0.0)
	_sword_blade(ci, crown + Vector2(-1.2, 2.2), -2.22, 14.5, 3.3, 0.45, plume_side, plume_side, ink, 2.1)
	_sword_blade(ci, crown + Vector2(1.6, 2.2), -0.94, 14.0, 3.1, 0.4, plume_side, plume_side, ink, 2.1)
	_sword_blade(ci, crown + Vector2(0.0, 1.2), -1.57, 16.5, 3.5, 0.5, plume, plume, ink, 2.1)
	var eye_far := Rect2(hip.x - 3.2, hip.y - 33.2, 6.4, 7.2)
	var eye_near := Rect2(hip.x + 5.4, hip.y - 32.8, 6.8, 7.6)
	var brow := ink
	var upper_angle := 0.48 - chop * 1.35 + step * 0.14
	var fore_angle := 0.39 - chop * 1.54 + step * 0.1
	var shoulder := hip + Vector2(11.0, -14.0)
	if hurt:
		_segment(ci, eye_far.position + Vector2(0.2, 2.8), 0.06, eye_far.size.x, 2.0, brow, brow, 0.0)
		_segment(ci, eye_near.position + Vector2(0.2, 3.0), -0.05, eye_near.size.x, 2.1, brow, brow, 0.0)
	else:
		_segment(ci, eye_far.position + Vector2(-0.2, -3.0), 0.36, 6.6, 2.1, brow, brow, 0.0)
		_segment(ci, eye_near.position + Vector2(0.2, -3.2), -0.32, 6.8, 2.2, brow, brow, 0.0)
		_chunk(ci, eye_far, 2.2, Color("fff8ef"), ink, 1.7)
		_chunk(ci, eye_near, 2.3, Color("fff8ef"), ink, 1.7)
		_chunk(ci, Rect2(eye_far.position.x + 2.2, eye_far.position.y + 2.4, 2.5, 3.1), 1.0, ink, ink, 0.0)
		_chunk(ci, Rect2(eye_near.position.x + 2.4, eye_near.position.y + 2.5, 2.6, 3.2), 1.0, ink, ink, 0.0)
		ci.draw_rect(Rect2(eye_far.position.x + 2.4, eye_far.position.y + 2.6, 1.15, 1.15), Color("fffdf8"), true)
		ci.draw_rect(Rect2(eye_near.position.x + 2.6, eye_near.position.y + 2.7, 1.2, 1.2), Color("fffdf8"), true)
	var mouth := Rect2(hip.x + 2.4, hip.y - 23.6, 6.0, 2.3)
	_chunk(ci, mouth, 1.1, Color("c45c58").lerp(Color.WHITE, wash), ink, 1.3)
	var elbow := _segment(ci, shoulder, upper_angle, 8.4, 6.4, metal, ink, 2.4)
	var grip := _segment(ci, elbow, fore_angle, 7.4, 5.2, metal_deep, ink, 2.3)
	_sword_weapon(ci, grip, fore_angle, ink, gold, gold_deep, blade, blade_lit)


static func _framed(ci: CanvasItem, rect: Rect2, cut: float, fill: Color, trim: Color, ink: Color, ring: float, edge: float) -> void:
	var outer := ring + edge
	var big := Rect2(rect.position - Vector2(outer, outer), rect.size + Vector2(outer, outer) * 2.0)
	var mid := Rect2(rect.position - Vector2(ring, ring), rect.size + Vector2(ring, ring) * 2.0)
	ci.draw_colored_polygon(_squircle(big, cut + outer), ink)
	ci.draw_colored_polygon(_squircle(mid, cut + ring), trim)
	ci.draw_colored_polygon(_squircle(rect, cut), fill)


static func _sword_weapon(ci: CanvasItem, hand: Vector2, angle: float, ink: Color, gold: Color, gold_deep: Color, blade: Color, blade_lit: Color) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var side := Vector2(-dir.y, dir.x)
	_segment(ci, hand - dir * 4.2, angle, 4.4, 3.1, gold_deep, ink, 1.7)
	_sword_blade(ci, hand + dir * 1.6, angle, 15.5, 1.45, 0.38, blade, blade_lit, ink, 1.7)
	_segment(ci, hand - side * 3.2, angle + PI * 0.5, 6.4, 2.5, gold, ink, 1.7)


static func _sword_blade(ci: CanvasItem, origin: Vector2, angle: float, length: float, base_w: float, tip_w: float, fill: Color, shade: Color, ink: Color, outline: float) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var side := Vector2(-dir.y, dir.x)
	var tip := origin + dir * length
	if outline > 0.15:
		var ring := PackedVector2Array()
		ring.append(origin - dir * outline + side * (base_w + outline))
		ring.append(tip + dir * outline * 0.7 + side * (tip_w + outline))
		ring.append(tip + dir * outline * 0.7 - side * (tip_w + outline))
		ring.append(origin - dir * outline - side * (base_w + outline))
		ci.draw_colored_polygon(ring, ink)
	var steel := PackedVector2Array()
	steel.append(origin + side * base_w)
	steel.append(tip + side * tip_w)
	steel.append(tip - side * tip_w)
	steel.append(origin - side * base_w)
	ci.draw_colored_polygon(steel, fill)
	var shine := PackedVector2Array()
	shine.append(origin + dir * 1.8 + side * 0.35)
	shine.append(tip - dir * 2.4 + side * 0.15)
	shine.append(tip - dir * 2.4 - side * 0.35)
	shine.append(origin + dir * 1.8 - side * 0.45)
	ci.draw_colored_polygon(shine, shade)


static func _chunk(ci: CanvasItem, rect: Rect2, cut: float, fill: Color, ink: Color, outline: float) -> void:
	if outline > 0.2:
		var grown := Rect2(rect.position - Vector2(outline, outline), rect.size + Vector2(outline, outline) * 2.0)
		ci.draw_colored_polygon(_squircle(grown, cut + outline), ink)
	ci.draw_colored_polygon(_squircle(rect, cut), fill)


static func _paint_poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, ink: Color, outline: float) -> void:
	if pts.size() < 3:
		return
	if outline > 0.15:
		ci.draw_colored_polygon(_inflate(pts, outline), ink)
	ci.draw_colored_polygon(pts, fill)


static func _segment(ci: CanvasItem, origin: Vector2, angle: float, length: float, thick: float, fill: Color, ink: Color, outline: float) -> Vector2:
	var cut := minf(thick * 0.46, length * 0.34)
	var limb := Rect2(0.0, -thick * 0.5, length, thick)
	if outline > 0.2:
		var grown := Rect2(-outline, -thick * 0.5 - outline, length + outline * 2.0, thick + outline * 2.0)
		ci.draw_colored_polygon(_place(_squircle(grown, cut + outline), origin, angle), ink)
	ci.draw_colored_polygon(_place(_squircle(limb, cut), origin, angle), fill)
	return origin + Vector2(cos(angle), sin(angle)) * length


static func _squircle(rect: Rect2, cut: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var radius := cut
	var limit := minf(rect.size.x, rect.size.y) * 0.48
	if radius > limit:
		radius = limit
	if radius < 0.4:
		pts.append(rect.position)
		pts.append(Vector2(rect.end.x, rect.position.y))
		pts.append(rect.end)
		pts.append(Vector2(rect.position.x, rect.end.y))
		return pts
	var corners := PackedVector2Array()
	corners.append(rect.position + Vector2(radius, radius))
	corners.append(Vector2(rect.end.x - radius, rect.position.y + radius))
	corners.append(rect.end - Vector2(radius, radius))
	corners.append(Vector2(rect.position.x + radius, rect.end.y - radius))
	var arcs := PackedFloat32Array()
	arcs.append(PI)
	arcs.append(PI * 1.5)
	arcs.append(0.0)
	arcs.append(PI * 0.5)
	var steps := 8
	for corner_i in 4:
		var center: Vector2 = corners[corner_i]
		var a0 := arcs[corner_i]
		for step_i in steps:
			var u := float(step_i) / float(steps)
			var a := a0 + u * PI * 0.5
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


static func _place(pts: PackedVector2Array, origin: Vector2, angle: float) -> PackedVector2Array:
	var spun := PackedVector2Array()
	spun.resize(pts.size())
	var c := cos(angle)
	var s := sin(angle)
	for i in pts.size():
		var point: Vector2 = pts[i]
		spun[i] = origin + Vector2(point.x * c - point.y * s, point.x * s + point.y * c)
	return spun


static func _turn(pts: PackedVector2Array, pivot: Vector2, angle: float) -> PackedVector2Array:
	if absf(angle) < 0.001:
		return pts
	var spun := PackedVector2Array()
	spun.resize(pts.size())
	var c := cos(angle)
	var s := sin(angle)
	for i in pts.size():
		var point: Vector2 = pts[i]
		var delta := point - pivot
		spun[i] = pivot + Vector2(delta.x * c - delta.y * s, delta.x * s + delta.y * c)
	return spun


static func _inflate(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	var count := pts.size()
	for point in pts:
		center += point
	center /= float(maxi(count, 1))
	var grown := PackedVector2Array()
	grown.resize(count)
	for i in count:
		var point: Vector2 = pts[i]
		var delta := point - center
		var span := delta.length()
		if span < 0.001:
			grown[i] = point
		else:
			grown[i] = point + delta * (amount / span)
	return grown

