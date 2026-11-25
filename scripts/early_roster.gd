extends RefCounted

const Catalog = preload("res://scripts/unit_catalog.gd")

# Skill danger, judged beside blood and damage. Walker is pinned at level 1.
# Scores (blood * 0.08 + damage * 2.2 + danger):
# runner 48, herald 54, viper 97, shell 99, howler 110, reaver 126, storm 147, oni 228.
const SKILL := {
	"runner": 6.0,
	"herald": 28.0,
	"viper": 36.0,
	"shell": 12.0,
	"howler": 48.0,
	"reaver": 18.0,
	"storm": 78.0,
	"oni": 40.0,
}

static var unlocks: Dictionary = {}
static var demos: Dictionary = {}
static var _order: Array = []


static func order() -> Array:
	if not _order.is_empty():
		return _order
	_order = _build_order()
	return _order


static func ensure() -> void:
	if unlocks.has("walker"):
		return
	roll()


static func roll() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_roll_with(rng)


static func roll_seed(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_roll_with(rng)


static func unlock_of(id: String) -> int:
	ensure()
	return int(unlocks.get(id, 99))


static func pool(level_no: int) -> Array:
	ensure()
	var ids: Array = []
	for id in order():
		if int(unlocks.get(str(id), 99)) <= level_no:
			ids.append(str(id))
	if ids.is_empty():
		ids.append("walker")
	return ids


static func debut_on(level_no: int) -> String:
	ensure()
	for id in order():
		var ident := str(id)
		if int(unlocks.get(ident, 0)) == level_no and not bool(demos.get(ident, false)):
			return ident
	return ""


static func mark_demo(id: String) -> void:
	if id == "":
		return
	demos[id] = true


static func token() -> String:
	ensure()
	var names := order()
	var levels := PackedStringArray()
	for i in range(1, names.size()):
		levels.append(str(int(unlocks.get(str(names[i]), 0))))
	var bits := 0
	for i in names.size():
		if bool(demos.get(str(names[i]), false)):
			bits |= 1 << i
	return "nv:" + ".".join(levels) + ":" + str(bits)


static func apply_token(text: String) -> bool:
	if not text.begins_with("nv:"):
		return false
	var parts := text.split(":")
	if parts.size() != 3:
		return false
	var level_bits := str(parts[1]).split(".")
	var names := order()
	if level_bits.size() != names.size() - 1:
		return false
	var seen: Dictionary = {}
	var prev := 1
	var next_map: Dictionary = {"walker": 1}
	for i in level_bits.size():
		var raw := str(level_bits[i])
		if not raw.is_valid_int():
			return false
		var lv := int(raw)
		if lv < 2 or lv > 19 or lv <= prev or seen.has(lv):
			return false
		seen[lv] = true
		prev = lv
		next_map[str(names[i + 1])] = lv
	var bit_text := str(parts[2])
	if not bit_text.is_valid_int():
		return false
	var bits := int(bit_text)
	if bits < 0 or bits > 511:
		return false
	unlocks = next_map
	demos = {}
	for i in names.size():
		if (bits & (1 << i)) != 0:
			demos[str(names[i])] = true
	return true


static func name_of(id: String) -> String:
	if id == "boss":
		return "General"
	var entry := Catalog.find_in(Catalog.enemy_roster(), id)
	var label := str(entry.get("name", ""))
	if label == "":
		return id
	return label


static func line(id: String) -> String:
	match id:
		"walker":
			return "Walker. It strikes one fighter at short range."
		"runner":
			return "Runner. It is faster than a walker, and it strikes sooner."
		"herald":
			return "Herald. It calls two other monsters every few seconds."
		"viper":
			return "Viper. Its bite holds a fighter. For a short time they cannot move or attack, and they hold the hurt pose until it ends."
		"shell":
			return "Shell. It is slow, hits softly, and carries a great deal of blood."
		"howler":
			return "Howler. A short blade cannot reach it. It swings onto an archer or a caster, and an archer can shoot it."
		"reaver":
			return "Reaver. It hits harder, and it strikes one fighter."
		"storm":
			return "Storm. Lightning hits one fighter, then jumps to four others, one by one."
		"oni":
			return "Oni. A heavy blow hits everyone in range on its road."
		"moth":
			return "Moth. It flies on one road. A short blade cannot reach it."
		"elder":
			return "Elder. It appears on the road, strikes whoever is nearest, and then it fades."
		"glut":
			return "Glut. It eats the fighter in front, then sits and heals."
		"brood":
			return "Brood. It bites one fighter. When it dies, three Lings crawl out."
		"ling":
			return "Ling. A small fast biter that crawls out of Brood."
		"knives":
			return "Knives. It matches the sword soldier, and it strikes one fighter at short range."
		"firebow":
			return "Firebow. A hard shot, then fire stays on that spot."
		"fan":
			return "Fan. It blows its road and pushes the fighters in front back."
		"ward":
			return "Ward. A great shield, and a great deal of blood."
		"javelin":
			return "Javelin. It throws long shots, then fights up close."
		"drum":
			return "Drum. It deals no damage. It lifts three allies at once."
		"crow":
			return "Crow. It waits, then the first strike is heavy. After that it fights up close."
		"cow":
			return "Cow. It waits, then it charges. After that it fights up close, slower than the crow."
		"smog":
			return "Smog. It deals no damage. Smoke hides the road where it walks."
		"buck":
			return "Buck. It fires a shotgun, then it reloads."
		"scope":
			return "Scope. One long heavy shot, and it has little blood."
		"aria":
			return "Aria. The song lifts every ally on every road."
		"bomber":
			return "Bomber. It is fragile, and the hit is heavy."
		"boss":
			return "General. It walks out when the gate breaks. The level ends when the general dies."
		_:
			return name_of(id) + ". It strikes one fighter."


static func _roll_with(rng: RandomNumberGenerator) -> void:
	var bag: Array = []
	for lv in range(2, 20):
		bag.append(lv)
	for i in bag.size():
		var j := rng.randi_range(i, bag.size() - 1)
		var swap = bag[i]
		bag[i] = bag[j]
		bag[j] = swap
	var picks: Array = []
	for i in 8:
		picks.append(int(bag[i]))
	for i in range(1, picks.size()):
		var current := int(picks[i])
		var spot := i
		while spot > 0 and int(picks[spot - 1]) > current:
			picks[spot] = picks[spot - 1]
			spot -= 1
		picks[spot] = current
	var names := order()
	unlocks = {"walker": 1}
	for i in picks.size():
		unlocks[str(names[i + 1])] = int(picks[i])
	demos = {}


static func _build_order() -> Array:
	var rows: Array = []
	for entry in Catalog.enemy_roster():
		var ident := str(entry.get("id", ""))
		if SKILL.has(ident):
			rows.append(entry)
	for i in range(1, rows.size()):
		var current: Dictionary = rows[i]
		var spot := i
		while spot > 0:
			var earlier: Dictionary = rows[spot - 1]
			if not _weaker(current, earlier):
				break
			rows[spot] = earlier
			spot -= 1
		rows[spot] = current
	var ids: Array = ["walker"]
	for row in rows:
		ids.append(str(row.get("id", "")))
	return ids


static func _weaker(a: Dictionary, b: Dictionary) -> bool:
	var left := _score(a)
	var right := _score(b)
	if left < right:
		return true
	if left > right:
		return false
	return str(a.get("id", "")) < str(b.get("id", ""))


static func _score(entry: Dictionary) -> float:
	var ident := str(entry.get("id", ""))
	var hp := float(entry.get("hp", 0))
	var damage := float(entry.get("damage", 0))
	return hp * 0.08 + damage * 2.2 + float(SKILL.get(ident, 0.0))
