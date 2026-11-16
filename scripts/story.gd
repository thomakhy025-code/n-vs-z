extends RefCounted

# The campaign story. Lesson levels, the pages between fights, and who the clan can call.
# A fresh roll each game would make these pages disagree with the fight, so the order is fixed.

const VERSION := 2

const LESSONS := {
	1: "archer",
	2: "lancer",
	4: "shield",
	7: "horse",
	9: "assassin",
	12: "saber",
	14: "suicide",
	16: "heal",
	18: "level",
	20: "berserker",
}

const _CARDS := {
	3: "The monsters do not leave. The sword is still the only call.",
	5: "Mist on the ridge. There are more of them than yesterday.",
	6: "They hold the gate. No new weapon today.",
	8: "Two roads fill at once. The clan does not break.",
	10: "Night on the mountain. The horns keep coming.",
	11: "A fast one slips through. The hero runs it down.",
	13: "Cold stone, and another wave.",
	15: "The gate holds. They learn nothing new.",
	17: "White cloud hides the road. The shapes still find it.",
	19: "A last quiet between the blows. Then they come again.",
	42: "The new monsters keep rank. The clan says a human hand sent them.",
	43: "They arrive at the same hour the soldiers once did.",
	44: "Wild things do not wait for a drum. These do.",
	45: "The clan looks at the horns and still sees a maker.",
	46: "No scatter, no hunger. They come to the gate and stop.",
	47: "Ash on the road, and the same number as yesterday.",
	48: "Someone is counting them out.",
	49: "The mountain asks who. The clan answers: the soldiers.",
	50: "Half of these attacks are done. The guess has not changed.",
	51: "They hold a broken horn up to the light and see no chain.",
	52: "Still they say the soldiers built these bodies.",
	53: "A quiet hour, then the same three roads.",
	54: "The gate shakes. They talk of a workshop in the low country.",
	55: "If a person can call a sword, a person could call a monster.",
	56: "They bury the dead horns away from the huts.",
	57: "The pattern holds. Send, break, send.",
	58: "No new soldier walks out of these gates. Only the same beasts.",
	59: "One more night of horns. The clan is tired of guessing.",
	60: "They have lived with the guess long enough.",
}

const _TAUGHT := {
	"archer": [
		"The gate breaks. Nine archers step out, three on each road.",
		"The clan lives through the arrows.",
		"They pick up the bows and learn the shot.",
	],
	"lancer": [
		"Nine lancers come off the broken gate, three on each road.",
		"The spears stop short of the clan.",
		"They take the spear and learn its reach.",
	],
	"shield": [
		"Nine shield-bearers plant themselves, three on each road.",
		"The wall holds, and then it breaks.",
		"They lift the shields and learn to stand.",
	],
	"horse": [
		"Nine riders pour out, three on each road.",
		"The clan meets the charge and stays.",
		"They take the horses and learn the speed.",
	],
	"assassin": [
		"Nine assassins slip out, three on each road.",
		"One blinks behind the line. The clan turns in time.",
		"They learn the blink, and the cut that follows.",
	],
	"saber": [
		"Nine sabers walk out, three on each road.",
		"The long cuts are slow, and the clan answers them.",
		"They take up the long blade.",
	],
	"suicide": [
		"Nine bombers rush out, three on each road.",
		"The blasts take blood from both sides. The clan remains.",
		"They learn the bomb, and what it costs.",
	],
	"heal": [
		"Nine healing casters step out, three on each road.",
		"They mend the monsters. The clan cuts them down anyway.",
		"They learn the staff, and how to give blood back.",
	],
	"level": [
		"Nine leveling casters come out, three on each road.",
		"The monsters grow stronger beside them. The clan ends it.",
		"They learn the scroll, and how to raise one of their own.",
	],
	"berserker": [
		"Nine axe fighters come out, three on each road.",
		"They are heavy, and they fall one road at a time.",
		"The clan learns the axe. One berserker will stand across all three roads.",
	],
}


static func lesson_id(level_index: int) -> String:
	return str(LESSONS.get(level_index, ""))


static func known_ids(cleared: int) -> Array:
	var ids: Array = ["sword"]
	for key in LESSONS.keys():
		var level_index := int(key)
		if cleared >= level_index:
			ids.append(str(LESSONS[key]))
	return ids


static func duel_open(cleared: int) -> bool:
	return cleared >= 20


static func intro_id(level_index: int) -> String:
	if level_index == 1:
		return "prologue"
	if level_index == 41:
		return "return"
	if level_index == 61:
		return "leave"
	if _CARDS.has(level_index):
		return "card%d" % level_index
	return ""


static func outro_id(level_index: int) -> String:
	if LESSONS.has(level_index):
		return "learn%d" % level_index
	if level_index == 70:
		return "cliff"
	return ""


static func intro_panels(level_index: int) -> Array:
	var id := intro_id(level_index)
	if id == "":
		return []
	if id == "prologue":
		return _prologue()
	if id == "return":
		return _return()
	if id == "leave":
		return _leave()
	return [_panel("mountain", str(_CARDS[level_index]), [
		_fig("hero", 0.34, "walk", false, false),
		_fig("sword", 0.62, "idle", false, false),
	])]


static func outro_panels(level_index: int) -> Array:
	var lesson := lesson_id(level_index)
	if lesson != "":
		var pages := _lesson(lesson)
		if level_index == 20:
			pages.append_array(_quiet())
		return pages
	if level_index == 70:
		return _cliff()
	return []


static func _prologue() -> Array:
	return [
		_panel("village", "They were small, and the village was not kind.", [
			_fig("hero", 0.28, "hurt", false, false),
			_fig("walker", 0.62, "idle", true, false, true),
			_fig("runner", 0.8, "walk", true, false, true),
		], "Get out."),
		_panel("village", "There was no place for them there.", [
			_fig("hero", 0.24, "walk", false, false),
			_fig("sword", 0.4, "walk", false, false),
		], "Leave."),
		_panel("climb", "They took the thin road into the cloud.", [
			_fig("hero", 0.3, "walk", false, false),
			_fig("sword", 0.48, "walk", false, false),
		]),
		_panel("mountain", "The mountain did not know their names. That was enough.", [
			_fig("hero", 0.36, "idle", false, false),
			_fig("sword", 0.58, "idle", false, false),
		]),
		_panel("camp", "For a while, the wind was the only visitor.", [
			_fig("hero", 0.42, "idle", false, false),
		]),
		_panel("night", "Then shapes came up the lower road.", [
			_fig("walker", 0.58, "walk", true, true),
			_fig("brute", 0.76, "walk", true, true),
		], "", true),
		_panel("night", "We only know this.", [
			_fig("hero", 0.34, "act", false, false),
			_fig("sword", 0.52, "act", false, false),
		], "The sword."),
		_panel("night", "The mountain learned their names too.", [
			_fig("hero", 0.3, "idle", false, false),
			_fig("oni", 0.72, "idle", true, true),
		]),
	]


static func _lesson(id: String) -> Array:
	var lines: Array = _TAUGHT[id]
	return [
		_panel("road", str(lines[0]), [
			_fig(id, 0.55, "walk", true, true),
			_fig(id, 0.7, "walk", true, true),
			_fig(id, 0.86, "idle", true, true),
		], "", true),
		_panel("road", str(lines[1]), [
			_fig("hero", 0.28, "act", false, false),
			_fig("sword", 0.44, "act", false, false),
			_fig(id, 0.74, "hurt", true, true),
		]),
		_panel("camp", str(lines[2]), [
			_fig("hero", 0.3, "idle", false, false),
			_fig(id, 0.55, "idle", false, false),
		]),
	]


static func _quiet() -> Array:
	return [
		_panel("mountain", "Months pass. The monsters stop coming.", [
			_fig("hero", 0.4, "idle", false, false),
			_fig("berserker", 0.62, "idle", false, false),
		]),
		_panel("camp", "Other clans have heard of the mountain. One ninja can meet one ninja.", [
			_fig("hero", 0.32, "idle", false, false),
			_fig("sword", 0.68, "idle", true, false),
		]),
		_panel("banners", "Then banners show on the lower road.", [
			_fig("hero", 0.26, "walk", false, false),
			_fig("walker", 0.62, "walk", true, false, true),
			_fig("brute", 0.8, "walk", true, false, true),
		]),
	]


static func _return() -> Array:
	return [
		_panel("night", "The monsters come back up the mountain.", [
			_fig("hero", 0.28, "idle", false, false),
			_fig("brute", 0.62, "walk", true, true),
			_fig("oni", 0.8, "walk", true, true),
		], "", true),
		_panel("camp", "The clan asks why monsters and human soldiers have both come for them.", [
			_fig("hero", 0.34, "idle", false, false),
			_fig("shield", 0.52, "idle", false, false),
			_fig("heal", 0.7, "idle", false, false),
		]),
		_panel("camp", "They cannot prove it. They say the soldiers made the monsters and sent them.", [
			_fig("hero", 0.4, "act", false, false),
		], "A human hand."),
	]


static func _leave() -> Array:
	return [
		_panel("camp", "They will not wait for the next wave to explain itself.", [
			_fig("hero", 0.36, "idle", false, false),
			_fig("saber", 0.56, "idle", false, false),
		]),
		_panel("climb", "They leave their gate, to see the world, and walk toward the village where they were born.", [
			_fig("hero", 0.28, "walk", false, false),
			_fig("sword", 0.44, "walk", false, false),
			_fig("horse", 0.64, "walk", false, false),
		]),
		_panel("road", "On that road, both armies find them.", [
			_fig("brute", 0.22, "walk", false, true),
			_fig("hero", 0.48, "act", false, false),
			_fig("walker", 0.74, "walk", true, false, true),
		], "", true),
	]


static func _cliff() -> Array:
	return [
		_panel("cliff", "They stand on a cliff above the old country.", [
			_fig("hero", 0.32, "idle", false, false),
			_fig("berserker", 0.5, "idle", false, false),
		]),
		_panel("war", "Below them, monsters and human soldiers fight each other.", [
			_fig("oni", 0.22, "act", false, true),
			_fig("brute", 0.38, "act", false, true),
			_fig("walker", 0.62, "act", true, false, true),
			_fig("spitter", 0.8, "act", true, false, true),
		], "", true),
		_panel("cliff", "It is a war between the two sides. The clan still does not know who started it.", [
			_fig("hero", 0.42, "idle", false, false),
		]),
	]


static func _panel(place: String, caption: String, cast: Array, speech: String = "", impact: bool = false) -> Dictionary:
	return {
		"place": place,
		"caption": caption,
		"speech": speech,
		"cast": cast,
		"impact": impact,
	}


static func _fig(id: String, x: float, phase: String, flip: bool, monster: bool, human: bool = false) -> Dictionary:
	return {
		"id": id,
		"x": x,
		"phase": phase,
		"flip": flip,
		"monster": monster,
		"human": human,
	}
