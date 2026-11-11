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
		_u("berserker", "Berserker", "Berserk", 50, 20.0, 300, 80, 3.0, MID, SHORT, "aoe", 62, 1.48, "Rushes in from mid distance. Every 3 seconds, every enemy in short range on every road takes 80. Enemies on every road can strike back."),
		_u("horse", "Horse Rider", "Rider", 20, 10.0, 100, 30, 1.0, SHORT, SHORT, "melee", 128, 1.35, "Fast. Hits one enemy for 30 every second."),
		_u("suicide", "Suicide Squad", "Bomb", 20, 10.0, 40, 100, 1.0, MID, SHORT, "suicide", 108, 1.15, "Rushes from mid distance. The blast hits everyone in short range for 100, and 40 of that blood is their own."),
		_u("assassin", "Assassin", "Assassin", 15, 8.0, 100, 50, 1.0, SHORT, SHORT, "assassin", 116, 1.12, "The first time an enemy could hit her, she blinks behind that enemy. The trick happens once. Then she cuts for 50."),
		_u("heal", "Healing Caster", "Heal", 20, 10.0, 50, 0, 1.0, SHORT, LONG, "heal", 64, 1.12, "Heals the ally in front of her with the least blood, 40 blood each second, at long range."),
		_u("level", "Leveling Caster", "Level", 20, 10.0, 50, 0, 1.0, SHORT, LONG, "buff", 64, 1.12, "The ally in front with the highest damage gains 20% damage and 20% blood. A second caster can add another 20%. The same caster does not stack twice."),
	]


static func enemy_roster() -> Array:
	return [
		_e("walker", "Walker", 6, 1.5, 140, 16, 1.0, 70.0, 70.0, "melee", 54, 1.18, 3),
		_e("runner", "Runner", 8, 3.0, 75, 14, 0.7, 62.0, 62.0, "melee", 118, 1.05, 3),
		_e("brute", "Brute", 16, 6.5, 380, 26, 1.2, 76.0, 76.0, "melee", 34, 1.55, 7),
		_e("spitter", "Spitter", 12, 5.0, 100, 18, 1.25, 330.0, 330.0, "ranged", 44, 1.12, 5),
		_e("bomber", "Bomber", 12, 6.0, 55, 120, 0.7, 145.0, 70.0, "suicide", 102, 1.2, 5),
		_e("oni", "Oni", 34, 16.0, 860, 42, 1.5, 150.0, 100.0, "aoe", 30, 1.8, 14),
	]


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
