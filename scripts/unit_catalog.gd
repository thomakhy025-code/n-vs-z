extends RefCounted

# Attacking distance in the draft is when a soldier reacts.
# Attacking range is how far the hit actually lands.
# Archers and lancers stop at their hit reach, so a long weapon stays long.
# Berserkers and the suicide squad rush once an enemy is at mid distance,
# then land the hit at short range.

const SHORT := 70.0
const MID := 145.0
const LONG := 330.0


static func player_roster() -> Array:
	return [
		_u("sword", "Sword Soldier", "Sword", 5, 3.0, 100, 20, 1.0, SHORT, SHORT, "melee", 78, 1.2, "Hits one enemy at short range for 20 every second."),
		_u("archer", "Archer", "Archer", 10, 5.0, 80, 40, 1.0, SHORT, LONG, "ranged", 68, 1.15, "Shoots one enemy from long range for 40 every second."),
		_u("shield", "Shield-Bearer", "Shield", 10, 5.0, 200, 15, 1.0, SHORT, SHORT, "melee", 56, 1.25, "A thick gate of armor. 200 blood, 15 damage, short reach, one target."),
		_u("saber", "Saber", "Saber", 25, 10.0, 150, 50, 1.0, SHORT, SHORT, "melee", 72, 1.22, "Slow to call. Cuts one enemy for 50 every second."),
		_u("lancer", "Lancer", "Lancer", 20, 5.0, 100, 20, 1.0, SHORT, MID, "melee", 74, 1.2, "The spear reaches mid range and hits one enemy for 20 every second."),
		_u("berserker", "Berserker", "Berserk", 50, 20.0, 600, 80, 3.0, MID, SHORT, "aoe", 62, 1.48, "Rushes in from mid distance and stands across all three roads. Every 3 seconds, every enemy in short range on every road takes 80. Enemies on every road can strike back."),
		_u("horse", "Horse Rider", "Rider", 20, 10.0, 100, 30, 1.0, SHORT, SHORT, "melee", 128, 1.35, "Fast. Hits one enemy for 30 every second."),
		_u("suicide", "Suicide Squad", "Bomb", 20, 10.0, 40, 100, 1.0, MID, SHORT, "suicide", 108, 1.15, "Rushes from mid distance. The blast hits everyone in short range for 100, and 40 of that blood is their own."),
		_u("assassin", "Assassin", "Assassin", 15, 8.0, 100, 50, 1.0, SHORT, SHORT, "assassin", 116, 1.12, "She blinks past every other enemy, as many times as she needs, and crosses roads to reach her mark. She only kills an archer, a leveling caster, or a healing caster. The cut is 50."),
		_u("heal", "Healing Caster", "Heal", 20, 10.0, 50, 0, 1.0, SHORT, LONG, "heal", 64, 1.12, "Heals the ally in front of her with the least blood, 40 blood each second, at long range."),
		_u("level", "Leveling Caster", "Level", 20, 10.0, 50, 0, 1.0, SHORT, LONG, "buff", 64, 1.12, "The ally in front with the highest damage gains 20% damage and 20% blood. A second caster can add another 20%. The same caster does not stack twice."),
	]


static func enemy_roster() -> Array:
	return [
		_e("walker", "Walker", 4, 1.5, 168, 18, 1.0, 70.0, 70.0, "melee", 65, 1.18, 3),
		_e("runner", "Runner", 5, 3.0, 90, 16, 0.7, 62.0, 62.0, "melee", 142, 1.05, 3),
		_swing(_e("howler", "Howler", 12, 8.0, 192, 21, 1.1, 70.0, 72.0, "howler", 74, 1.28, 6), 83),
		_e("viper", "Viper", 7, 4.0, 70, 25, 1.2, 68.0, 64.0, "viper", 94, 1.08, 4),
		_e("storm", "Storm", 14, 9.0, 91, 28, 4.0, 330.0, 330.0, "storm", 48, 1.22, 6),
		_e("herald", "Herald", 10, 6.0, 82, 9, 1.3, 64.0, 60.0, "herald", 55, 1.16, 5),
		_e("shell", "Shell", 12, 7.0, 816, 10, 1.45, 74.0, 70.0, "melee", 31, 1.62, 8),
		_e("reaver", "Reaver", 10, 5.5, 276, 39, 0.95, 78.0, 76.0, "melee", 62, 1.36, 7),
		_e("oni", "Oni", 22, 16.0, 1032, 48, 1.5, 150.0, 100.0, "aoe", 36, 1.8, 14),
		_e("moth", "Moth", 8, 5.0, 74, 20, 1.0, 68.0, 68.0, "moth", 76, 1.05, 4),
		_e("elder", "Elder", 10, 6.0, 200, 46, 0.85, 66.0, 66.0, "elder", 116, 1.08, 6),
		_mark(_e("glut", "Glut", 16, 10.0, 780, 0, 1.2, 72.0, 72.0, "glut", 16, 1.85, 10), "chew", 16),
		_e("brood", "Brood", 11, 6.0, 220, 24, 1.15, 66.0, 66.0, "brood", 56, 1.22, 6),
		_e("ling", "Ling", 99, 99.0, 44, 32, 0.7, 56.0, 56.0, "melee", 138, 0.72, 1),
		_e("knives", "Knives", 5, 3.0, 120, 23, 1.0, 70.0, 70.0, "melee", 78, 1.2, 3),
		_mark(_e("firebow", "Firebow", 8, 5.0, 77, 51, 1.15, 70.0, 330.0, "firebow", 46, 1.14, 5), "burn", 9),
		_e("fan", "Fan", 10, 6.0, 70, 3, 7.0, 1200.0, 1200.0, "fan", 42, 1.14, 5),
		_e("ward", "Ward", 11, 7.0, 624, 5, 1.35, 72.0, 70.0, "melee", 26, 1.42, 7),
		_mark(_e("javelin", "Javelin", 9, 4.5, 192, 44, 1.5, 80.0, 330.0, "javelin", 58, 1.2, 5), "sword", 14),
		_e("drum", "Drum", 12, 8.0, 67, 0, 1.0, 70.0, 330.0, "drum", 50, 1.12, 6),
		_charge(_e("crow", "Crow", 14, 8.0, 120, 35, 1.0, 70.0, 70.0, "crow", 128, 1.12, 6), 83, 3.0),
		_charge(_e("cow", "Cow", 12, 8.0, 72, 18, 1.25, 62.0, 62.0, "cow", 78, 1.28, 4), 40, 4.0),
		_e("smog", "Smog", 6, 4.0, 52, 0, 1.0, 70.0, 70.0, "smog", 50, 1.12, 4),
		_e("buck", "Buck", 8, 4.5, 155, 42, 1.0, 80.0, 100.0, "buck", 52, 1.16, 5),
		_e("scope", "Scope", 12, 7.0, 70, 64, 3.0, 70.0, 330.0, "scope", 40, 1.12, 6),
		_e("aria", "Aria", 11, 7.0, 58, 0, 1.2, 70.0, 2000.0, "aria", 46, 1.1, 6),
		_e("boss", "War Boss", 999, 99.0, 1000, 200, 2.0, 120.0, 120.0, "boss", 18, 1.8, 0),
	]


static func lesson_foe(id: String, level_index: int) -> Dictionary:
	var entry := find_in(player_roster(), id)
	if entry.is_empty():
		return {}
	var copy := entry.duplicate()
	var hp := 48 + level_index * 5
	var damage := 8 + int(float(level_index) * 0.45)
	match id:
		"shield":
			hp += 50
			damage = maxi(6, damage - 4)
		"berserker":
			hp = 140
			damage = 22
			copy["scale"] = 1.15
		"suicide":
			hp = 36
			damage = 36
		"heal", "level":
			hp = 64
			damage = 0
		"horse":
			hp = 56 + level_index * 3
	copy["hp"] = hp
	copy["damage"] = damage
	copy["trial"] = true
	copy["bounty"] = 4
	return copy


static func find_in(roster: Array, id: String) -> Dictionary:
	for entry in roster:
		if str(entry["id"]) == id:
			return entry
	return {}


static func _u(id: String, name: String, short: String, cost: int, cooldown: float, hp: int, damage: int, interval: float, engage: float, reach: float, role: String, speed: float, scale: float, detail: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"short": short,
		"cost": cost,
		"cooldown": cooldown,
		"hp": hp,
		"damage": damage,
		"interval": interval,
		"engage": engage,
		"reach": reach,
		"role": role,
		"speed": speed,
		"scale": scale,
		"paint": id,
		"detail": detail,
		"self_damage": 40 if role == "suicide" else 0,
		"bounty": 0,
	}


static func _e(id: String, name: String, cost: int, cooldown: float, hp: int, damage: int, interval: float, engage: float, reach: float, role: String, speed: float, scale: float, bounty: int) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"short": name,
		"cost": cost,
		"cooldown": cooldown,
		"hp": hp,
		"damage": damage,
		"interval": interval,
		"engage": engage,
		"reach": reach,
		"role": role,
		"speed": speed,
		"scale": scale,
		"paint": id,
		"detail": "",
		"self_damage": 40 if role == "suicide" else 0,
		"bounty": bounty,
	}


static func _swing(row: Dictionary, swing: int) -> Dictionary:
	row["swing"] = swing
	return row


static func _mark(row: Dictionary, key: String, value: int) -> Dictionary:
	row[key] = value
	return row


static func _charge(row: Dictionary, opening: int, wait: float) -> Dictionary:
	row["opening"] = opening
	row["roost_time"] = wait
	return row
