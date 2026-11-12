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
		_row(1, "First road", "+0.8 each second, starts at 22.", 0.8, 22.0, 0.0, 12.0, 24.0, 50.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.0, 1.0, false),
		_row(2, "Open purse", "+0.9 each second, starts at 28.", 0.9, 28.0, 0.0, 12.0, 24.0, 50.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.0, 1.0, false),
		_row(3, "Early spit", "Spitters and bombers from the first wave. +1.0 each second, starts at 34.", 1.0, 34.0, 0.0, 0.0, 24.0, 50.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.0, 1.0, false),
		_row(4, "Short breath", "Shorter lulls, and each wave is one body larger. +1.05 each second, starts at 40.", 1.05, 40.0, 0.0, 12.0, 24.0, 50.0, 4, 9, 22.0, 0.95, 2.1, 0.016, 0.42, 1.0, 1.0, false),
		_row(5, "Thick hide", "15% more blood. Brutes from 16s. +1.1 each second, starts at 46.", 1.1, 46.0, 0.0, 12.0, 16.0, 50.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.15, 1.0, false),
		_row(6, "Rising curse", "+1.15 each second, starts at 52.", 1.15, 52.0, 0.0, 12.0, 24.0, 50.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.0, 1.0, false),
		_row(7, "Oni early", "The oni can be called from 28s. +1.2 each second, starts at 58.", 1.2, 58.0, 0.0, 12.0, 24.0, 28.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.0, 1.0, false),
		_row(8, "Paired muster", "Two dead in one beat, on two roads. +1.25 each second, starts at 64.", 1.25, 64.0, 0.0, 12.0, 24.0, 50.0, 3, 8, 22.0, 1.5, 3.3, 0.012, 0.42, 1.0, 1.0, true),
		_row(9, "Fast muster", "Faster calls, waves up to 11, tougher dead. +1.3 each second, starts at 70.", 1.3, 70.0, 0.0, 12.0, 24.0, 50.0, 4, 11, 16.0, 1.1, 2.4, 0.015, 0.30, 1.25, 1.1, false),
		_row(10, "Night march", "Early oni, paired calls, fast waves, tougher dead. +1.4 each second, starts at 76. A war boss walks when the gate falls.", 1.4, 76.0, 0.0, 12.0, 24.0, 28.0, 4, 11, 16.0, 1.1, 2.4, 0.015, 0.30, 1.25, 1.1, true),
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
