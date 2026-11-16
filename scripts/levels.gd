extends RefCounted

# Seventy levels. The clan purse never changes. Theirs gets heavier, eases when the
# soldiers first arrive, then climbs again. Lesson ids live in story.gd.

const Story = preload("res://scripts/story.gd")
const COUNT := 70

const NAMES := [
	"First road", "The spears", "Still they come", "The shield wall", "Thick mist",
	"The ridge", "The riders", "Two at once", "The blink", "Night watch",
	"A fast one", "The long cut", "Cold stone", "The blast", "Shut gate",
	"The staff", "White cloud", "The scroll", "Last lull", "The axe",
	"Banners", "The lower road", "Red sashes", "Shield line", "The drum",
	"Uphill", "Crossbows", "The gate they want", "Heavy boots", "Halfway",
	"Night banners", "Paired ranks", "Iron", "The push", "Broken steps",
	"Their purse", "Close ranks", "The horn", "Last banner", "The general",
	"They return", "Same horns", "The same hour", "No scatter", "Who sent them",
	"A maker", "Ash on the road", "Counted out", "The guess", "Halfway back",
	"No chain", "Still the soldiers", "Three roads", "A workshop", "A person could",
	"Buried horns", "Send and break", "No new soldier", "Tired of guessing", "Long enough",
	"The old road", "Soldiers on the path", "Horns again", "Red on the road", "The descent",
	"A human gate", "Monsters below", "The last sash", "Above the village", "The two armies",
]

static var _rows: Array = []


static func count() -> int:
	return COUNT


static func level(index: int) -> Dictionary:
	var all := _all()
	var picked: int = clampi(index, 1, all.size()) - 1
	return all[picked]


static func faction_of(index: int) -> String:
	if index >= 21 and index <= 40:
		return "human"
	if index >= 62 and index <= 70 and index % 2 == 0:
		return "human"
	return "monster"


static func _all() -> Array:
	if _rows.is_empty():
		for n in COUNT:
			_rows.append(_make(n + 1))
	return _rows


static func _pressure(index: int) -> float:
	if index <= 20:
		return float(index - 1) / 19.0 * 0.72
	if index <= 40:
		return 0.48 + float(index - 21) / 19.0 * 0.42
	if index <= 60:
		return 0.78 + float(index - 41) / 19.0 * 0.18
	return 0.90 + float(index - 61) / 9.0 * 0.10


static func _make(index: int) -> Dictionary:
	var pressure := _pressure(index)
	var lesson := Story.lesson_id(index)
	var faction := faction_of(index)
	var boss := index == 40
	var ease := 1.0 - pressure
	var name := "Road %d" % index
	if index - 1 < NAMES.size():
		name = NAMES[index - 1]
	return _row(
		index,
		name,
		_blurb(index, lesson, faction, boss),
		1.6 + pressure * 6.2,
		16.0 + pressure * 70.0,
		0.0,
		36.0 + ease * 40.0,
		55.0 + ease * 50.0,
		80.0 + ease * 70.0,
		2 + int(pressure * 3.0),
		4 + int(pressure * 8.0),
		26.0 - pressure * 10.0,
		2.2 - pressure * 1.0,
		5.0 - pressure * 2.4,
		0.008 + pressure * 0.008,
		0.75 - pressure * 0.34,
		0.85 + pressure * 0.55,
		0.85 + pressure * 0.45,
		pressure > 0.82,
		faction,
		lesson,
		boss,
	)


static func _blurb(index: int, lesson: String, faction: String, boss: bool) -> String:
	if lesson != "":
		return "Break their gate. Nine come out, three on each road. Kill them all."
	if boss:
		return "Break their gate. A general walks out. The level ends when the general dies."
	if index >= 61:
		return "On the road to the village where they were born."
	if index >= 41:
		return "Monsters again. The clan still thinks the soldiers made them."
	if faction == "human":
		return "Human soldiers on the mountain road."
	return "Monsters on the three roads. Hold the clan gate."


static func _row(index: int, title: String, blurb: String, income: float, start_value: float, growth: float, spitter_at: float, brute_at: float, oni_at: float, wave_base: int, wave_cap: int, wave_every: float, lull_floor: float, lull_base: float, lull_shrink: float, spawn_gap: float, hp_mult: float, dmg_mult: float, paired: bool, faction: String, lesson: String, boss: bool) -> Dictionary:
	return {
		"index": index,
		"name": title,
		"blurb": blurb,
		"income": income,
		"start": start_value,
		"growth": growth,
		"spitter_at": spitter_at,
		"brute_at": brute_at,
		"oni_at": oni_at,
		"wave_base": wave_base,
		"wave_cap": wave_cap,
		"wave_every": wave_every,
		"lull_floor": lull_floor,
		"lull_base": lull_base,
		"lull_shrink": lull_shrink,
		"spawn_gap": spawn_gap,
		"hp_mult": hp_mult,
		"dmg_mult": dmg_mult,
		"paired": paired,
		"warmup": 0.0,
		"faction": faction,
		"lesson": lesson,
		"boss": boss,
	}
