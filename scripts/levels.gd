extends RefCounted

# Enemy purse and the extra pressure for each road. The clan purse never changes.


static func count() -> int:
	return _all().size()


static func level(index: int) -> Dictionary:
	var all: Array = _all()
	var picked: int = clampi(index, 1, all.size()) - 1
	var row: Dictionary = all[picked]
	return row


static func _all() -> Array:
	return [
		_row(1, "First road", "+0.8 each second, starts at 1.5.", 0.8, 1.5, 0.004, 18.0, 32.0, 60.0, 2, 5, 26.0, 2.4, 4.6, 0.008, 1.05, 1.0, 0.19, false),
		_row(2, "Open purse", "+0.9 each second, starts at 2.", 0.9, 2.0, 0.004, 18.0, 32.0, 60.0, 2, 5, 26.0, 2.4, 4.6, 0.008, 1.0, 1.0, 0.19, false),
		_row(3, "Early spit", "Spitters and bombers from the first wave. +1.0 each second, starts at 2.", 1.0, 2.0, 0.004, 0.0, 32.0, 60.0, 2, 5, 26.0, 2.4, 4.6, 0.008, 1.0, 1.0, 0.19, false),
		_row(4, "Short breath", "Shorter lulls between waves. +1.05 each second, starts at 2.5.", 1.05, 2.5, 0.004, 18.0, 32.0, 60.0, 2, 5, 26.0, 1.8, 3.4, 0.01, 0.95, 1.0, 0.19, false),
		_row(5, "Thick hide", "5% more blood. Brutes from 28s. +1.1 each second, starts at 2.5.", 1.1, 2.5, 0.004, 18.0, 28.0, 60.0, 2, 5, 26.0, 2.2, 4.2, 0.008, 1.0, 1.05, 0.19, false),
		_row(6, "Rising curse", "Their purse grows twice as fast. +1.15 each second, starts at 3.", 1.15, 3.0, 0.008, 18.0, 32.0, 60.0, 2, 5, 26.0, 2.2, 4.2, 0.008, 1.0, 1.0, 0.19, false),
		_row(7, "Oni early", "The oni can be called from 55s. +1.2 each second, starts at 3.", 1.2, 3.0, 0.004, 18.0, 32.0, 55.0, 2, 5, 26.0, 2.2, 4.2, 0.008, 1.0, 1.0, 0.2, false),
		_row(8, "Paired muster", "Two dead in one beat, on two roads. +1.25 each second, starts at 3.", 1.25, 3.0, 0.004, 18.0, 32.0, 60.0, 2, 5, 26.0, 2.4, 4.4, 0.008, 1.1, 1.0, 0.2, true),
		_row(9, "Fast muster", "Slightly faster calls and tougher dead. +1.3 each second, starts at 3.5.", 1.3, 3.5, 0.005, 16.0, 28.0, 55.0, 2, 6, 24.0, 2.0, 3.8, 0.008, 0.9, 1.05, 0.2, false),
		_row(10, "Night march", "Quiet for 10 seconds, then paired calls. The oni from 55s. +1.4 each second, starts at 2.", 1.4, 2.0, 0.005, 16.0, 30.0, 55.0, 2, 6, 24.0, 2.2, 4.2, 0.008, 1.05, 1.05, 0.2, true, 10.0),
	]


static func _row(index: int, title: String, blurb: String, income: float, start_value: float, growth: float, spitter_at: float, brute_at: float, oni_at: float, wave_base: int, wave_cap: int, wave_every: float, lull_floor: float, lull_base: float, lull_shrink: float, spawn_gap: float, hp_mult: float, dmg_mult: float, paired: bool, warmup: float = 0.0) -> Dictionary:
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
		"warmup": warmup,
	}
