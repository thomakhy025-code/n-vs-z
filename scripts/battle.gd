extends Node2D

const Catalog = preload("res://scripts/unit_catalog.gd")
const Painter = preload("res://scripts/painter.gd")
const SceneryScript = preload("res://scripts/scenery.gd")
const GateScript = preload("res://scripts/gate.gd")
const UnitScript = preload("res://scripts/battle_unit.gd")
const HeroScript = preload("res://scripts/hero.gd")
const ArrowScript = preload("res://scripts/projectile.gd")
const FloatScript = preload("res://scripts/float_text.gd")
const PoofScript = preload("res://scripts/poof.gd")
const FieldScript = preload("res://scripts/field_input.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const Levels = preload("res://scripts/levels.gd")

const PLAYER_START := 16.0
const PLAYER_INCOME := 3.6
const ENEMY_START := 22.0
const ENEMY_INCOME_BASE := 7.2
const ENEMY_GROWTH := 0.065
const MAX_SIDE := 24

var mode: String = ""
var rules: Dictionary = {}
var level_no: int = 1
var loadout: Array = []
var finished: bool = false
var paused: bool = false
var player_value: float = PLAYER_START
var enemy_value: float = ENEMY_START
var enemy_income: float = ENEMY_INCOME_BASE
var battle_time: float = 0.0
var damage_events: int = 0
var spawned_player: int = 0
var vp: Vector2 = Vector2(1280, 720)
var ground_y: float = 400.0
var lane_ys: Array[float] = []
var player_front: float = 176.0
var enemy_front: float = 1100.0
var units: Array = []
var buff_links: Dictionary = {}
var player_cd: Dictionary = {}
var enemy_cd: Dictionary = {}
var player_roster: Array = []
var enemy_roster: Array = []
var slot_buttons: Array = []
var slot_hold: Array = []
var player_gate = null
var enemy_gate = null
var hero = null
var world: Node2D
var fx: Node2D
var layer: CanvasLayer
var hud: Control
var value_label: Label
var income_label: Label
var level_label: Label
var player_hp_label: Label
var enemy_hp_label: Label
var player_bar_fill: ColorRect
var enemy_bar_fill: ColorRect
var sword_btn: Button
var shoot_btn: Button
var pause_btn: Button
var home_btn: Button
var player_track: ColorRect
var enemy_track: ColorRect
var hint: Label
var down_label: Label
var pause_layer: Control
var end_layer: Control
var hurt_flash: ColorRect
var lane_tick: int = 0
var enemy_lock: float = 0.2
var wave_left: int = 0
var lull: float = 1.0
var auto_lock: float = 0.15
var texts_this_frame: int = 0
var harness_done: bool = false
var sword_hold: bool = false
var shoot_hold: bool = false
var purse_paid: Dictionary = {}
var boss_up: bool = false
var duel: bool = false
var puppet: bool = false
var local_side: int = 0
var foe_loadout: Array = []
var foe = null
var controlled = null
var duel_probe: bool = false
var next_net: int = 1
var net_acc: float = 0.0
var skin_left: Dictionary = {}
var skin_right: Dictionary = {}
var sent_keys: Array = []
var hand_seen: float = -1.0
var fallen_side: int = -1


func start(chosen: Array, run_mode: String, level_index: int = 1) -> void:
	loadout = chosen.duplicate()
	mode = run_mode
	rules = Levels.level(level_index)
	level_no = int(rules["index"])
	enemy_value = float(rules["start"])
	enemy_income = float(rules["income"])
	player_roster = Catalog.player_roster()
	enemy_roster = Catalog.enemy_roster()
	for entry in player_roster:
		player_cd[str(entry["id"])] = 0.0
	for entry in enemy_roster:
		enemy_cd[str(entry["id"])] = 0.0
	_build_world()
	_build_hud()
	if mode != "":
		Engine.max_fps = 60
	if mode == "":
		Engine.time_scale = 1.0
	elif mode == "smoke":
		Engine.time_scale = 12.0
		hero.bot = true
	elif mode == "sim":
		Engine.time_scale = 15.0
		hero.bot = true
	elif mode == "shot":
		Engine.time_scale = 8.0
		hero.bot = true


func begin_duel(local_ids: Array, other_ids: Array, side: int, runs_world: bool, skins: Dictionary) -> void:
	duel = true
	puppet = not runs_world
	local_side = side
	foe_loadout = other_ids.duplicate()
	var left_raw: Variant = skins.get("left", {})
	var right_raw: Variant = skins.get("right", {})
	skin_left = left_raw if left_raw is Dictionary else {}
	skin_right = right_raw if right_raw is Dictionary else {}
	start(local_ids, "duel", 1)
	enemy_value = PLAYER_START
	enemy_income = PLAYER_INCOME
	enemy_cd.clear()
	for entry in player_roster:
		enemy_cd[str(entry["id"])] = 0.0
	if enemy_gate != null:
		enemy_gate.clan_gate = true
		enemy_gate.queue_redraw()
	foe = HeroScript.new()
	foe.side = 1
	foe.setup(self)
	add_child(foe)
	foe.set_bounds(player_front - 40.0, enemy_front - 12.0, lane_y(0), lane_y(lane_ys.size() - 1))
	foe.net_pos = foe.position
	hero.look = _worn_look(0, "hero")
	foe.look = _worn_look(1, "hero")
	hero.driven = local_side != 0
	foe.driven = local_side == 0 and not duel_probe
	controlled = foe if local_side == 1 else hero
	if level_label != null:
		level_label.text = "1 vs 1"
	if hint != null:
		hint.text = "Both sides are the clan. Drag your hero, or use WASD. Sword, Shoot, and keys 1-6 call the six you chose. The other ninja has the same value and the same calls."
	_bind_duel_signals()
	if duel_probe:
		Engine.time_scale = 8.0
		summon_player("sword")
		summon_foe("sword")
		foe.bot = true
		foe.bot_sword = true
		foe.bot_axis = Vector2(-1, 0)


func _build_world() -> void:
	var scenery = SceneryScript.new()
	add_child(scenery)
	var metrics: Dictionary = scenery.metrics()
	vp = metrics["size"]
	ground_y = float(metrics["ground_y"])
	lane_ys.clear()
	var lanes: Array = metrics["lane_ys"]
	for raw_y in lanes:
		lane_ys.append(float(raw_y))
	player_front = 176.0
	enemy_front = vp.x - 176.0
	player_gate = GateScript.new()
	player_gate.setup(self, 0, Vector2(118, ground_y), player_front)
	add_child(player_gate)
	enemy_gate = GateScript.new()
	enemy_gate.setup(self, 1, Vector2(vp.x - 118, ground_y), enemy_front)
	add_child(enemy_gate)
	world = Node2D.new()
	add_child(world)
	fx = Node2D.new()
	fx.z_index = 120
	add_child(fx)
	hero = HeroScript.new()
	hero.setup(self)
	add_child(hero)
	hero.set_bounds(player_front - 40.0, enemy_front - 12.0, lane_y(0), lane_y(lane_ys.size() - 1))
	controlled = hero


func _build_hud() -> void:
	layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var field = FieldScript.new()
	field.battle = self
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(field)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hurt_flash.color = Color(0, 0, 0, 0)
	hud.add_child(hurt_flash)
	player_hp_label = _plain("1000", 22, Color("f3e6c8"))
	enemy_hp_label = _plain("1000", 22, Color("f3e6c8"))
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label = _plain("Value  16", 32, Color("e6c36a"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income_label = _plain("+3.6 each second", 16, Color("f3e6c8"))
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label = _plain("Level %d  ·  %s" % [level_no, str(rules["name"])], 18, Color("f3e6c8"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = _plain("Drag between the three roads to move. WASD works too. Soldiers you call join the hero's road. Sword and Shoot are on the right. J and K match those buttons. Keys 1-6 call the six you chose.", 16, Color("f3e6c8"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	down_label = _plain("", 20, Color("ffb4a8"))
	down_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_track = _bar_track()
	enemy_track = _bar_track()
	player_bar_fill = _bar_fill(Color("7dce6a"))
	enemy_bar_fill = _bar_fill(Color("e24b3b"))
	player_track.add_child(player_bar_fill)
	enemy_track.add_child(enemy_bar_fill)
	hud.add_child(player_hp_label)
	hud.add_child(enemy_hp_label)
	hud.add_child(value_label)
	hud.add_child(income_label)
	hud.add_child(level_label)
	hud.add_child(hint)
	hud.add_child(down_label)
	hud.add_child(player_track)
	hud.add_child(enemy_track)
	player_track.set_meta("bar", true)
	pause_btn = Button.new()
	pause_btn.text = "Pause"
	pause_btn.focus_mode = Control.FOCUS_NONE
	UiSkin.apply(pause_btn, Color("f3e6c8"), 16)
	pause_btn.pressed.connect(_toggle_pause)
	hud.add_child(pause_btn)
	home_btn = Button.new()
	home_btn.text = "Home"
	home_btn.focus_mode = Control.FOCUS_NONE
	UiSkin.apply(home_btn, Color("e6c36a"), 16)
	home_btn.pressed.connect(_go_home)
	hud.add_child(home_btn)
	sword_btn = Button.new()
	sword_btn.text = "SWORD"
	shoot_btn = Button.new()
	shoot_btn.text = "SHOOT"
	UiSkin.apply(sword_btn, Color("c44536"), 28, Color("f3e6c8"))
	UiSkin.apply(shoot_btn, Color("343e78"), 28, Color("f3e6c8"))
	sword_btn.button_down.connect(func() -> void: sword_hold = true)
	sword_btn.button_up.connect(func() -> void: sword_hold = false)
	shoot_btn.button_down.connect(func() -> void: shoot_hold = true)
	shoot_btn.button_up.connect(func() -> void: shoot_hold = false)
	hud.add_child(shoot_btn)
	hud.add_child(sword_btn)
	for entry_id in loadout:
		var entry: Dictionary = Catalog.find_in(player_roster, str(entry_id))
		var btn := Button.new()
		btn.text = "%s\n%d" % [entry["short"], int(entry["cost"])]
		var cloth: Color = Painter.look(str(entry["paint"]))["cloth"]
		UiSkin.apply(btn, cloth, 16, _ink(cloth))
		var slot_index := slot_buttons.size()
		slot_hold.append(false)
		btn.button_down.connect(_set_hold.bind(slot_index, true))
		btn.button_up.connect(_set_hold.bind(slot_index, false))
		hud.add_child(btn)
		slot_buttons.append(btn)
	_layout_hud()
	if not get_viewport().size_changed.is_connected(_layout_hud):
		get_viewport().size_changed.connect(_layout_hud)


func _set_hold(index: int, held: bool) -> void:
	if index >= 0 and index < slot_hold.size():
		slot_hold[index] = held


func _plain(text: String, size: int, color: Color) -> Label:
	var node := UiSkin.label(text, size, color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _bar_track() -> ColorRect:
	var track := ColorRect.new()
	track.color = Color(0, 0, 0, 0.55)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.custom_minimum_size = Vector2(220, 10)
	track.size = Vector2(220, 10)
	return track


func _bar_fill(color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(220, 10)
	return fill


func _layout_hud() -> void:
	var size := get_viewport_rect().size
	if size.x < 200.0:
		size = vp
	var side_len := sqrt(size.x * size.y / 20.0)
	var margin := 14.0
	if sword_btn != null:
		sword_btn.size = Vector2(side_len, side_len)
		shoot_btn.size = Vector2(side_len, side_len)
		sword_btn.custom_minimum_size = sword_btn.size
		shoot_btn.custom_minimum_size = shoot_btn.size
		sword_btn.position = Vector2(size.x - margin - side_len, size.y - margin - side_len)
		shoot_btn.position = Vector2(size.x - margin - side_len * 2.0 - 10.0, size.y - margin - side_len)
	var count := maxi(slot_buttons.size(), 1)
	var cards_w := size.x - (side_len * 2.0 + 48.0) - 20.0
	var card_w := maxf(78.0, (cards_w - 8.0 * float(count - 1)) / float(count))
	var card_h := minf(side_len * 0.56, 118.0)
	for i in slot_buttons.size():
		var btn: Button = slot_buttons[i]
		btn.size = Vector2(card_w, card_h)
		btn.custom_minimum_size = btn.size
		btn.position = Vector2(16.0 + float(i) * (card_w + 8.0), size.y - margin - card_h)
	player_hp_label.position = Vector2(24, 14)
	player_hp_label.size = Vector2(240, 30)
	enemy_hp_label.position = Vector2(size.x - 264, 14)
	enemy_hp_label.size = Vector2(240, 30)
	value_label.position = Vector2(size.x * 0.5 - 140, 8)
	value_label.size = Vector2(280, 36)
	income_label.position = Vector2(size.x * 0.5 - 140, 42)
	income_label.size = Vector2(280, 22)
	if level_label != null:
		level_label.position = Vector2(size.x * 0.5 - 260, 104)
		level_label.size = Vector2(520, 26)
	hint.position = Vector2(size.x * 0.5 - 340, 132)
	hint.size = Vector2(680, 72)
	down_label.position = Vector2(size.x * 0.5 - 180, size.y - side_len - 42)
	down_label.size = Vector2(360, 28)
	if player_track != null:
		player_track.position = Vector2(24, 48)
		enemy_track.position = Vector2(size.x - 244, 48)
	if pause_btn != null:
		pause_btn.position = Vector2(size.x * 0.5 + 6.0, 66)
		pause_btn.size = Vector2(92, 36)
	if home_btn != null:
		home_btn.position = Vector2(size.x * 0.5 - 98.0, 66)
		home_btn.size = Vector2(92, 36)


func _process(delta: float) -> void:
	texts_this_frame = 0
	battle_time += delta
	if puppet:
		_send_hand()
		_update_hud(delta)
		_run_harness()
		return
	if not finished and not paused:
		for id in player_cd.keys():
			player_cd[id] = maxf(0.0, float(player_cd[id]) - delta)
		for id in enemy_cd.keys():
			enemy_cd[id] = maxf(0.0, float(enemy_cd[id]) - delta)
		player_value += PLAYER_INCOME * delta
		if duel:
			enemy_value += PLAYER_INCOME * delta
			if hand_seen >= 0.0 and battle_time - hand_seen > 0.45 and foe != null:
				foe.pointer_sword = false
				foe.pointer_shoot = false
			if duel_probe and foe != null and foe.alive:
				foe.bot_axis = Vector2(-1, 0)
				foe.bot_sword = true
		elif battle_time < _rule_f("warmup", 0.0):
			lull = 0.0
			wave_left = 0
		else:
			enemy_income += _rule_f("growth", ENEMY_GROWTH) * delta
			enemy_value += enemy_income * delta
			_enemy_ai(delta)
		if mode != "" and mode != "duel":
			_autoplay(delta)
			_drive_hero()
		if hero != null and (not duel or local_side == 0):
			hero.pointer_sword = sword_hold
			hero.pointer_shoot = shoot_hold
		if not duel or local_side == 0:
			for i in slot_hold.size():
				if slot_hold[i]:
					summon_player(str(loadout[i]))
			for i in loadout.size():
				if Input.is_action_pressed("slot%d" % (i + 1)):
					summon_player(str(loadout[i]))
	_send_state(delta)
	_update_hud(delta)
	_run_harness()


func _enemy_ai(delta: float) -> void:
	if lull > 0.0:
		lull -= delta
		return
	if wave_left <= 0:
		var every := _rule_f("wave_every", 22.0)
		if every < 1.0:
			every = 22.0
		wave_left = mini(_rule_i("wave_cap", 8), _rule_i("wave_base", 3) + int(battle_time / every))
	enemy_lock -= delta
	if enemy_lock > 0.0:
		return
	enemy_lock = _rule_f("spawn_gap", 0.42)
	var options: Array = ["walker", "walker", "runner"]
	if battle_time >= _rule_f("oni_at", 50.0):
		options = ["oni", "brute", "bomber", "spitter", "walker", "runner"]
	elif battle_time >= _rule_f("brute_at", 24.0):
		options = ["brute", "bomber", "spitter", "walker", "runner"]
	elif battle_time >= _rule_f("spitter_at", 12.0):
		options = ["walker", "runner", "spitter", "bomber", "walker"]
	options.shuffle()
	var spawned := false
	for id in options:
		if _try_enemy(str(id)):
			spawned = true
			break
	if spawned and _rule_b("paired"):
		for id in options:
			if _try_enemy(str(id), true):
				break
	if not spawned:
		lull = 1.3
		wave_left = 0
		return
	wave_left -= 1
	if wave_left <= 0:
		lull = maxf(_rule_f("lull_floor", 1.5), _rule_f("lull_base", 3.3) - battle_time * _rule_f("lull_shrink", 0.012))


func _try_enemy(id: String, ignore_cd: bool = false) -> bool:
	var entry := Catalog.find_in(enemy_roster, id)
	if entry.is_empty():
		return false
	var cooling := float(enemy_cd[id]) > 0.0 and not ignore_cd
	if cooling or enemy_value < float(entry["cost"]) or _count(1) >= MAX_SIDE:
		return false
	enemy_value -= float(entry["cost"])
	enemy_cd[id] = float(entry["cooldown"])
	_spawn(_scaled_enemy(entry), 1)
	return true


func _scaled_enemy(entry: Dictionary) -> Dictionary:
	var copy: Dictionary = entry.duplicate()
	copy["hp"] = maxi(1, int(round(float(copy["hp"]) * _rule_f("hp_mult", 1.0))))
	copy["damage"] = maxi(1, int(round(float(copy["damage"]) * _rule_f("dmg_mult", 1.0))))
	return copy


func _rule_f(key: String, fallback: float) -> float:
	if rules.is_empty() or not rules.has(key):
		return fallback
	return float(rules[key])


func _rule_i(key: String, fallback: int) -> int:
	if rules.is_empty() or not rules.has(key):
		return fallback
	return int(rules[key])


func _rule_b(key: String) -> bool:
	if rules.is_empty() or not rules.has(key):
		return false
	return bool(rules[key])


func _autoplay(delta: float) -> void:
	auto_lock -= delta
	if auto_lock > 0.0:
		return
	auto_lock = 0.35
	var threat := false
	for unit in units:
		if is_instance_valid(unit) and unit.alive and unit.side == 1 and unit.position.x < vp.x * 0.38:
			threat = true
			break
	var order: Array = ["berserker", "saber", "archer", "lancer", "shield", "heal", "level", "horse", "assassin", "suicide", "sword"]
	if threat:
		order = ["shield", "sword", "archer", "lancer", "berserker", "heal", "saber"]
	var banking := false
	if not threat:
		for id in order:
			if not loadout.has(str(id)):
				continue
			var costly: Dictionary = Catalog.find_in(player_roster, str(id))
			var cost := float(costly["cost"])
			if cost < 25.0:
				continue
			if float(player_cd[str(id)]) <= 0.0 and player_value < cost and player_value >= cost - 16.0:
				banking = true
			break
	var before := player_value
	for id in order:
		if not loadout.has(str(id)):
			continue
		if banking and float(Catalog.find_in(player_roster, str(id))["cost"]) > 10.0:
			continue
		summon_player(str(id))
		if player_value < before:
			return


func _drive_hero() -> void:
	if hero == null or not hero.bot or not hero.alive:
		if hero != null:
			hero.bot_axis = Vector2.ZERO
			hero.bot_sword = false
			hero.bot_shoot = false
		return
	var foe = null
	var best := 100000.0
	for unit in units:
		if is_instance_valid(unit) and unit.alive and unit.side == 1:
			var dist := absf(unit.position.x - hero.position.x)
			if dist < best:
				best = dist
				foe = unit
	if foe != null:
		var desired: float = foe.position.x - 64.0
		var dir := 0.0
		if absf(desired - hero.position.x) >= 12.0:
			dir = signf(desired - hero.position.x)
		var ydir := 0.0
		if absf(foe.position.y - hero.position.y) >= 18.0:
			ydir = signf(foe.position.y - hero.position.y)
		hero.bot_axis = Vector2(dir, ydir)
		hero.bot_sword = best < 96.0 and int(foe.lane) == hero.lane
		hero.bot_shoot = best < 420.0 and int(foe.lane) == hero.lane
	else:
		var goal: float = enemy_front - 80.0
		var dir2 := 0.0
		if absf(goal - hero.position.x) >= 14.0:
			dir2 = signf(goal - hero.position.x)
		hero.bot_axis = Vector2(dir2, 0)
		hero.bot_sword = absf(enemy_front - hero.position.x) <= 90.0
		hero.bot_shoot = true


func summon_player(id: String) -> void:
	if finished or paused:
		return
	if not loadout.has(id):
		return
	var entry := Catalog.find_in(player_roster, id)
	if entry.is_empty():
		return
	if float(player_cd[id]) > 0.0 or player_value < float(entry["cost"]) or _count(0) >= MAX_SIDE:
		return
	player_value -= float(entry["cost"])
	player_cd[id] = float(entry["cooldown"])
	_spawn(entry, 0)


func summon_foe(id: String) -> void:
	if finished or paused or not duel:
		return
	if not foe_loadout.has(id):
		return
	var entry := Catalog.find_in(player_roster, id)
	if entry.is_empty():
		return
	if float(enemy_cd.get(id, 0.0)) > 0.0 or enemy_value < float(entry["cost"]) or _count(1) >= MAX_SIDE:
		return
	enemy_value -= float(entry["cost"])
	enemy_cd[id] = float(entry["cooldown"])
	_spawn(entry, 1)


func _spawn(entry: Dictionary, side: int) -> void:
	var unit = UnitScript.new()
	unit.setup(self, entry, side)
	var road := 1
	if side == 0:
		if hero != null and is_instance_valid(hero) and hero.alive:
			road = hero.lane
	else:
		if duel and foe != null and is_instance_valid(foe) and foe.alive:
			road = foe.lane
		else:
			road = lane_tick % maxi(lane_ys.size(), 1)
			lane_tick += 1
	road = clampi(road, 0, maxi(lane_ys.size() - 1, 0))
	var kind: String = str(entry.get("id", ""))
	if kind == "berserker" or kind == "boss":
		road = lane_ys.size() / 2
	unit.lane = road
	var y := lane_y(road)
	unit.position = Vector2(player_front + 20.0, y) if side == 0 else Vector2(enemy_front - 20.0, y)
	unit.net_id = next_net
	next_net += 1
	if duel:
		unit.look = _worn_look(side, str(entry.get("paint", "sword")))
	world.add_child(unit)
	units.append(unit)
	if side == 0:
		spawned_player += 1
	var paint := str(entry.get("paint", "sword"))
	Sfx.play(Painter.call_id(paint), Painter.call_pitch(paint) * randf_range(0.97, 1.04), -5.0 if side == 0 else -9.0)
	poof(unit.position, Color("f3e6c8") if side == 0 else Color("c6e38a"))


func _count(side: int) -> int:
	var total := 0
	for unit in units:
		if is_instance_valid(unit) and unit.alive and unit.side == side:
			total += 1
	return total


func hostile_targets(attacker_side: int) -> Array:
	var defend := 1 - attacker_side
	var out: Array = []
	for unit in units:
		if is_instance_valid(unit) and unit.alive and unit.side == defend:
			out.append(unit)
	var defender = _hero_for(defend)
	if defender != null:
		out.append(defender)
	return out


func support_candidates(side: int) -> Array:
	var out: Array = []
	for unit in units:
		if is_instance_valid(unit) and unit.alive and unit.side == side:
			out.append(unit)
	var ally = _hero_for(side)
	if ally != null:
		out.append(ally)
	return out


func gate_for_attacker(attacker_side: int):
	return enemy_gate if attacker_side == 0 else player_gate


func damage_gate(defender_side: int, amount: float) -> void:
	var gate = player_gate if defender_side == 0 else enemy_gate
	if gate != null:
		gate.take_damage(amount)


func fire_arrow(from: Vector2, aim: Vector2, amount: float, side: int, color: Color, reach: float, road: int, bold: bool = false, hits_gate: bool = true, homing: bool = false) -> void:
	var arrow = ArrowScript.new()
	arrow.setup(from, aim, amount, side, color, reach, road, self, bold, hits_gate, homing)
	world.add_child(arrow)


func lane_y(index: int) -> float:
	if lane_ys.is_empty():
		return ground_y
	return lane_ys[clampi(index, 0, lane_ys.size() - 1)]


func lane_index(y: float) -> int:
	var best := 0
	var best_d := 100000.0
	for i in lane_ys.size():
		var dist := absf(lane_ys[i] - y)
		if dist < best_d:
			best_d = dist
			best = i
	return best


func is_berserker(unit) -> bool:
	return _unit_id(unit) == "berserker"


func is_boss(unit) -> bool:
	return _unit_id(unit) == "boss"


func _unit_id(unit) -> String:
	if unit == null or not is_instance_valid(unit):
		return ""
	if not ("data" in unit):
		return ""
	var info = unit.data
	if not info is Dictionary:
		return ""
	return str(info.get("id", ""))


func float_text(at: Vector2, text: String, color: Color) -> void:
	texts_this_frame += 1
	if texts_this_frame > 16 or fx == null:
		return
	var node = FloatScript.new()
	node.position = at
	node.z_index = 200
	node.setup(text, color)
	fx.add_child(node)


func poof(at: Vector2, tint: Color) -> void:
	if fx == null:
		return
	var node = PoofScript.new()
	node.position = at
	node.tint = tint
	node.z_index = 90
	fx.add_child(node)


func register_damage() -> void:
	damage_events += 1


func note_gate_hit(side: int) -> void:
	if hurt_flash == null:
		return
	hurt_flash.color = Color(0.75, 0.12, 0.1, 0.32) if side == 0 else Color(0.95, 0.78, 0.35, 0.18)


func gate_gust(defender_side: int) -> void:
	var mid := (player_front + enemy_front) * 0.5
	var attacker_side := 1 - defender_side
	for unit in units:
		if not is_instance_valid(unit) or not unit.alive or int(unit.side) != attacker_side:
			continue
		var unit_x: float = unit.position.x
		var past: bool = unit_x < mid if defender_side == 0 else unit_x > mid
		if not past:
			continue
		if unit.has_method("catch_gust"):
			unit.catch_gust(mid)
	var breaker = null
	if defender_side == 1:
		breaker = hero
	elif duel:
		breaker = foe
	if breaker != null and is_instance_valid(breaker) and breaker.alive:
		var past_mid: bool = breaker.position.x > mid if defender_side == 1 else breaker.position.x < mid
		if past_mid and breaker.has_method("shove_back"):
			breaker.shove_back(mid)
	for road_y in lane_ys:
		poof(Vector2(mid, float(road_y)), Color("d5e6f2"))
	Sfx.play("wind", 0.9, -5.0)
	float_text(Vector2(mid, lane_y(0) - 28.0), "WIND", Color("d5e6f2"))


func on_unit_down(unit) -> void:
	if unit == null or not is_instance_valid(unit) or unit.down_handled:
		return
	unit.down_handled = true
	units.erase(unit)
	var bounty := int(unit.data.get("bounty", 0))
	if unit.side == 1 and bounty > 0:
		player_value += float(bounty)
		float_text(unit.position + Vector2(0, -20), "+%d" % bounty, Color("e6c36a"))
	var snapshot: Array = buff_links.keys()
	for source in snapshot:
		if not buff_links.has(source):
			continue
		if source == unit:
			var target = buff_links[source]
			buff_links.erase(source)
			if _can_buff(target) and target != unit:
				target.remove_level_buff()
		elif buff_links[source] == unit:
			buff_links[source] = null
	if boss_up and _unit_id(unit) == "boss":
		_finish_battle(1)


func set_buff_link(buffer, target) -> void:
	var prev = buff_links.get(buffer, null)
	if prev == target:
		return
	if _can_buff(prev):
		prev.remove_level_buff()
	if target == null:
		buff_links.erase(buffer)
		return
	buff_links[buffer] = target
	if _can_buff(target):
		target.apply_level_buff()
		Sfx.play("buff", 1.0, -6.0)


func _can_buff(node) -> bool:
	return node != null and is_instance_valid(node) and node.alive and node.has_method("remove_level_buff")


func note_enemy_purse() -> void:
	if duel or enemy_gate == null:
		return
	var ratio: float = float(enemy_gate.hp) / maxf(1.0, float(enemy_gate.max_hp))
	var start: float = float(rules.get("start", ENEMY_START))
	if level_no >= 10:
		_pay_purse("70", 0.70, ratio, start)
	if level_no >= 5:
		_pay_purse("50", 0.50, ratio, start)
	_pay_purse("25", 0.25, ratio, start)


func _pay_purse(key: String, line: float, ratio: float, start: float) -> void:
	if ratio > line or purse_paid.has(key):
		return
	purse_paid[key] = true
	enemy_value += start
	var stack := purse_paid.size() - 1
	float_text(Vector2(enemy_front, lane_y(0) - 20.0 - float(stack) * 22.0), "+%d" % int(round(start)), Color("c6e38a"))


func on_gate_fallen(defender_side: int) -> void:
	if finished:
		return
	if duel:
		_finish_battle(defender_side)
		return
	if defender_side == 1 and level_no >= 10 and not boss_up:
		_summon_boss()
		return
	_finish_battle(defender_side)


func _summon_boss() -> void:
	boss_up = true
	enemy_income = 1.0
	var entry: Dictionary = Catalog.find_in(enemy_roster, "boss")
	if entry.is_empty():
		_finish_battle(1)
		return
	_spawn(entry, 1)
	float_text(Vector2(enemy_front - 30.0, lane_y(1) - 78.0), "BOSS", Color("e6c36a"))


func _finish_battle(defender_side: int) -> void:
	if finished:
		return
	finished = true
	paused = false
	fallen_side = defender_side
	var won := defender_side == 1
	if duel:
		won = defender_side != local_side
	Sfx.play("win" if won else "lose", 1.0, -2.0)
	if mode != "" and mode != "duel":
		return
	_close_pause()
	var title := "The cursed gate breaks" if won else "Your gate has fallen"
	var body := "The dead reached the clan gate. Call them again, or choose a different six."
	if duel:
		title = "Their gate falls" if won else "Your gate has fallen"
		body = "The other clan is broken." if won else "Your gate broke. Fight the same six, or choose again."
	elif won:
		var host := get_parent()
		if host != null and host.has_method("note_clear"):
			host.note_clear(level_no)
		if boss_up:
			title = "The war boss falls"
			body = "The last road is clear."
		elif level_no >= Levels.count():
			body = "The last road is clear."
		else:
			var nxt: Dictionary = Levels.level(level_no + 1)
			body = "Level %d, %s, is open." % [int(nxt["index"]), str(nxt["name"])]
	var actions: Array = []
	if won and not duel and level_no < Levels.count():
		actions.append({"text": "Next level", "color": Color("c44536"), "call": Callable(get_parent(), "next_level")})
	actions.append({"text": "Rematch", "color": Color("e6c36a"), "call": Callable(get_parent(), "rematch")})
	actions.append({"text": "Change the six", "color": Color("d7c4a3"), "call": Callable(get_parent(), "change_squad")})
	actions.append({"text": "Home", "color": Color("f7f1df"), "call": Callable(get_parent(), "show_title")})
	end_layer = _overlay(title, body, actions)
	layer.add_child(end_layer)


func _toggle_pause() -> void:
	if finished:
		return
	if duel and puppet:
		Net.ask_pause.rpc_id(1)
		return
	if paused:
		_close_pause()
		return
	paused = true
	pause_layer = _overlay("Paused", "The road waits. Your soldiers hold still until you return.", [
		{"text": "Resume", "color": Color("7dce6a"), "call": Callable(self, "_close_pause")},
		{"text": "Home", "color": Color("e6c36a"), "call": Callable(self, "_go_home")},
		{"text": "Rematch", "color": Color("c44536"), "call": Callable(get_parent(), "rematch")},
		{"text": "Change the six", "color": Color("d7c4a3"), "call": Callable(get_parent(), "change_squad")},
	])
	layer.add_child(pause_layer)


func _go_home() -> void:
	var host := get_parent()
	if host != null and host.has_method("show_title"):
		host.show_title()


func _close_pause() -> void:
	paused = false
	sword_hold = false
	shoot_hold = false
	for i in slot_hold.size():
		slot_hold[i] = false
	if pause_layer != null and is_instance_valid(pause_layer):
		pause_layer.queue_free()
	pause_layer = null


func _overlay(title: String, body: String, buttons: Array) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.07, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 340)
	margin.add_theme_constant_override("margin_right", 340)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_bottom", 40)
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", UiSkin.panel(Color("f3e6c8"), Color("e6c36a"), 18, 4))
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	var heading := UiSkin.label(title, 32, Color("1c140e"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var copy := UiSkin.label(body, 18, Color("3a2a22"))
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(copy)
	for spec in buttons:
		var btn := Button.new()
		btn.text = str(spec["text"])
		btn.custom_minimum_size = Vector2(280, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		UiSkin.apply(btn, spec["color"], 20, _ink(spec["color"]))
		var action: Callable = spec["call"]
		btn.pressed.connect(action)
		box.add_child(btn)
	return root


func _update_hud(delta: float) -> void:
	if player_hp_label == null:
		return
	var player_ratio: float = float(player_gate.hp) / float(player_gate.max_hp)
	var enemy_ratio: float = float(enemy_gate.hp) / float(enemy_gate.max_hp)
	if duel:
		player_hp_label.text = "Left clan  %d" % int(round(player_gate.hp))
		enemy_hp_label.text = "Right clan  %d" % int(round(enemy_gate.hp))
		if level_label != null:
			level_label.text = "1 vs 1"
	else:
		player_hp_label.text = "Clan gate  %d" % int(round(player_gate.hp))
		enemy_hp_label.text = "Cursed gate  %d" % int(round(enemy_gate.hp))
	player_hp_label.add_theme_color_override("font_color", Color("ffb4a8") if player_ratio < 0.3 else Color("f3e6c8"))
	value_label.text = "Value  %d" % int(floor(player_value))
	income_label.text = "+%.1f each second" % PLAYER_INCOME
	player_bar_fill.size.x = 220.0 * clampf(player_ratio, 0.0, 1.0)
	enemy_bar_fill.size.x = 220.0 * clampf(enemy_ratio, 0.0, 1.0)
	player_bar_fill.color = Color("7dce6a") if player_ratio > 0.3 else Color("e24b3b")
	var watched = controlled if controlled != null else hero
	if duel and paused and not finished:
		down_label.text = "Paused"
	elif watched != null and not watched.alive:
		down_label.text = "Hero returns in %.1f" % maxf(watched.down_timer, 0.0)
	else:
		down_label.text = ""
	if hint != null and battle_time > 11.0:
		hint.modulate.a = maxf(0.0, hint.modulate.a - delta * 0.45)
	for i in slot_buttons.size():
		var id := str(loadout[i])
		var entry := Catalog.find_in(player_roster, id)
		var cd := float(player_cd[id])
		var btn: Button = slot_buttons[i]
		if cd > 0.0:
			btn.text = "%s\n%.1fs" % [entry["short"], cd]
			btn.modulate = Color(0.62, 0.62, 0.68)
		else:
			btn.text = "%s\n%d" % [entry["short"], int(entry["cost"])]
			btn.modulate = Color(0.75, 0.62, 0.58) if player_value < float(entry["cost"]) else Color.WHITE
	if hurt_flash != null:
		var fade: Color = hurt_flash.color
		fade.a = move_toward(fade.a, 0.0, delta * 0.9)
		hurt_flash.color = fade


func _run_harness() -> void:
	if harness_done or mode == "":
		return
	var smoke_ready := mode == "smoke" and (battle_time >= 22.0 or (finished and battle_time >= 8.0))
	var sim_ready := mode == "sim" and (battle_time >= 100.0 or finished)
	var shot_ready := mode == "shot" and battle_time >= 18.0
	if duel_probe and battle_time >= 2.0:
		harness_done = true
		var ninja := false
		var walker := false
		for unit in units:
			if not is_instance_valid(unit) or not unit.alive:
				continue
			var kind := str(unit.data.get("id", ""))
			if kind == "walker":
				walker = true
			if kind == "sword" and int(unit.side) == 1 and int(unit.data.get("hp", 0)) == 100:
				ninja = true
		var clan_ok: bool = enemy_gate != null and bool(enemy_gate.clan_gate)
		var duel_ok: bool = ninja and not walker and foe != null and int(foe.side) == 1 and clan_ok and _count(0) >= 1 and _count(1) >= 1
		print("DUEL_%s left=%d right=%d" % ["OK" if duel_ok else "FAIL", _count(0), _count(1)])
		get_tree().quit(0 if duel_ok else 1)
		return
	if smoke_ready:
		harness_done = true
		var ok := damage_events > 0 and spawned_player > 0 and player_gate != null
		print("SMOKE_%s damage=%d spawned=%d pcastle=%.1f ecastle=%.1f" % ["OK" if ok else "FAIL", damage_events, spawned_player, player_gate.hp, enemy_gate.hp])
		get_tree().quit(0 if ok else 1)
	elif sim_ready:
		harness_done = true
		var front_player := 0.0
		var front_enemy := 9999.0
		for unit in units:
			if not is_instance_valid(unit) or not unit.alive:
				continue
			if unit.side == 0:
				front_player = maxf(front_player, unit.position.x)
			else:
				front_enemy = minf(front_enemy, unit.position.x)
		print("SIM time=%.1f pcastle=%.1f ecastle=%.1f value=%.1f punits=%d eunits=%d damage=%d finished=%s pfront=%.0f efront=%.0f hero=%.0f" % [battle_time, player_gate.hp, enemy_gate.hp, player_value, _count(0), _count(1), damage_events, str(finished), front_player, front_enemy, hero.position.x])
		get_tree().quit(0)
	elif shot_ready:
		harness_done = true
		_capture_and_quit()


func _capture_and_quit() -> void:
	Engine.time_scale = 1.0
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://battle_shot.png")
	var err := image.save_png(path)
	print("SAVED ", path, " ", image.get_width(), "x", image.get_height(), " err=", err)
	get_tree().quit(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _hero_for(which: int):
	if hero != null and is_instance_valid(hero) and int(hero.side) == which and hero.alive:
		return hero
	if foe != null and is_instance_valid(foe) and int(foe.side) == which and foe.alive:
		return foe
	return null


func _worn_look(which: int, kind: String) -> Dictionary:
	if not duel:
		return Painter.look(kind)
	var pack: Dictionary = skin_left if which == 0 else skin_right
	var sheet_raw: Variant = pack.get("sheets", [])
	var sheets: Array = sheet_raw if sheet_raw is Array else []
	var sheet := false
	for item in sheets:
		if str(item) == kind:
			sheet = true
			break
	var navy := bool(pack.get("navy", false)) and kind == "saber"
	return Painter.look_as(kind, sheet, navy)


func _bind_duel_signals() -> void:
	if Net.role == "":
		return
	if not Net.input_got.is_connected(_on_hand):
		Net.input_got.connect(_on_hand)
	if not Net.buy_got.is_connected(_on_net_buy):
		Net.buy_got.connect(_on_net_buy)
	if not Net.state_got.is_connected(_on_state):
		Net.state_got.connect(_on_state)
	if not Net.pause_got.is_connected(_on_pause_ask):
		Net.pause_got.connect(_on_pause_ask)


func _exit_tree() -> void:
	if Net.input_got.is_connected(_on_hand):
		Net.input_got.disconnect(_on_hand)
	if Net.buy_got.is_connected(_on_net_buy):
		Net.buy_got.disconnect(_on_net_buy)
	if Net.state_got.is_connected(_on_state):
		Net.state_got.disconnect(_on_state)
	if Net.pause_got.is_connected(_on_pause_ask):
		Net.pause_got.disconnect(_on_pause_ask)


func _on_hand(x: float, y: float, dragging: bool, sword: bool, shoot: bool) -> void:
	if puppet or foe == null:
		return
	foe.net_pos = Vector2(x, y)
	foe.net_step = dragging
	foe.pointer_sword = sword
	foe.pointer_shoot = shoot
	hand_seen = battle_time


func _on_net_buy(unit_id: String) -> void:
	if puppet:
		return
	summon_foe(unit_id)


func _on_pause_ask() -> void:
	if puppet or finished:
		return
	if paused:
		_close_pause()
	else:
		_toggle_pause()


func _send_hand() -> void:
	if Net.role != "guest" or controlled == null:
		return
	var sword := sword_hold or Input.is_action_pressed("sword")
	var shoot := shoot_hold or Input.is_action_pressed("shoot")
	Net.push_hand.rpc_id(1, controlled.position.x, controlled.position.y, controlled.dragging, sword, shoot)
	for i in loadout.size():
		var down := Input.is_action_pressed("slot%d" % (i + 1)) or (i < slot_hold.size() and bool(slot_hold[i]))
		var was := i < sent_keys.size() and bool(sent_keys[i])
		if down and not was:
			Net.ask_buy.rpc_id(1, str(loadout[i]))
		if i >= sent_keys.size():
			sent_keys.append(down)
		else:
			sent_keys[i] = down


func _send_state(delta: float) -> void:
	if not duel or Net.role != "host" or Net.guest_id < 2:
		return
	net_acc += delta
	if net_acc < 0.05:
		return
	net_acc = 0.0
	Net.push_state.rpc_id(Net.guest_id, _pack_state())


func _pack_state() -> Array:
	return [
		player_value,
		enemy_value,
		0.0 if player_gate == null else float(player_gate.hp),
		0.0 if enemy_gate == null else float(enemy_gate.hp),
		1 if paused else 0,
		1 if finished else 0,
		fallen_side,
		_pack_hero(hero),
		_pack_hero(foe),
		_pack_cds(player_cd),
		_pack_cds(enemy_cd),
		_pack_units(),
	]


func _pack_hero(who) -> Array:
	if who == null or not is_instance_valid(who):
		return [0.0, 0.0, 0.0, 0, 1.0, 0.0, "katana", 0.0, 0.0, 0]
	return [
		who.position.x,
		who.position.y,
		who.hp,
		1 if who.alive else 0,
		who.facing,
		who.act,
		who.act_tool,
		who.down_timer,
		who.hurt,
		1 if who.winding else 0,
	]


func _pack_cds(table: Dictionary) -> Array:
	var out: Array = []
	for entry in player_roster:
		out.append(float(table.get(str(entry["id"]), 0.0)))
	return out


func _pack_units() -> Array:
	var out: Array = []
	for unit in units:
		if not is_instance_valid(unit) or not unit.alive:
			continue
		out.append([
			int(unit.net_id),
			int(unit.side),
			str(unit.data.get("id", "sword")),
			unit.position.x,
			unit.position.y,
			unit.hp,
			unit.facing,
			unit.act,
			unit.hurt,
		])
	return out


func _on_state(packet: Array) -> void:
	if not puppet or packet.size() < 12:
		return
	var gold0 := float(packet[0])
	var gold1 := float(packet[1])
	player_value = gold0 if local_side == 0 else gold1
	if player_gate != null:
		player_gate.hp = float(packet[2])
		player_gate.queue_redraw()
	if enemy_gate != null:
		enemy_gate.hp = float(packet[3])
		enemy_gate.queue_redraw()
	var want_pause := int(packet[4]) == 1
	if want_pause != paused and not finished:
		paused = want_pause
		if not want_pause:
			_close_pause()
	_apply_hero(hero, packet[7], local_side == 0)
	_apply_hero(foe, packet[8], local_side == 1)
	var cd_row: Array = packet[9] if local_side == 0 else packet[10]
	_apply_cd_row(player_cd, cd_row)
	_apply_units(packet[11])
	if int(packet[5]) == 1 and not finished:
		_finish_battle(int(packet[6]))


func _apply_cd_row(table: Dictionary, row: Array) -> void:
	var i := 0
	for entry in player_roster:
		if i < row.size():
			table[str(entry["id"])] = float(row[i])
		i += 1


func _apply_hero(who, blob: Variant, local_control: bool) -> void:
	if who == null or not is_instance_valid(who) or not (blob is Array):
		return
	var row: Array = blob
	if row.size() < 10:
		return
	var hx := float(row[0])
	var hy := float(row[1])
	who.hp = float(row[2])
	who.alive = int(row[3]) == 1
	who.visible = who.alive or float(row[7]) > 0.0
	who.facing = float(row[4])
	who.act = float(row[5])
	who.act_tool = str(row[6])
	who.down_timer = float(row[7])
	who.hurt = float(row[8])
	who.winding = int(row[9]) == 1
	if not local_control or not who.alive or absf(who.position.x - hx) > 140.0:
		who.position = Vector2(hx, hy)
		who.net_pos = who.position
	who.lane = lane_index(who.position.y)


func _apply_units(blob: Variant) -> void:
	if not (blob is Array):
		return
	var rows: Array = blob
	var seen: Dictionary = {}
	for raw in rows:
		if not (raw is Array):
			continue
		var row: Array = raw
		if row.size() < 9:
			continue
		var nid := int(row[0])
		seen[nid] = true
		var unit = _unit_by_net(nid)
		if unit == null:
			unit = _make_puppet(int(row[1]), str(row[2]), nid)
		if unit == null:
			continue
		unit.position = Vector2(float(row[3]), float(row[4]))
		unit.hp = float(row[5])
		unit.alive = true
		unit.facing = float(row[6])
		unit.act = float(row[7])
		unit.hurt = float(row[8])
		unit.lane = lane_index(unit.position.y)
	var stale: Array = []
	for unit in units:
		if is_instance_valid(unit) and not seen.has(int(unit.net_id)):
			stale.append(unit)
	for unit in stale:
		units.erase(unit)
		unit.queue_free()


func _unit_by_net(nid: int):
	for unit in units:
		if is_instance_valid(unit) and int(unit.net_id) == nid:
			return unit
	return null


func _make_puppet(which: int, kind: String, nid: int):
	var entry := Catalog.find_in(player_roster, kind)
	if entry.is_empty():
		return null
	var unit = UnitScript.new()
	unit.setup(self, entry, which)
	unit.net_id = nid
	unit.look = _worn_look(which, str(entry.get("paint", kind)))
	unit.position = Vector2(player_front if which == 0 else enemy_front, lane_y(1))
	world.add_child(unit)
	units.append(unit)
	Sfx.play(Painter.call_id(str(entry.get("paint", kind))), Painter.call_pitch(str(entry.get("paint", kind))), -8.0)
	return unit


func _ink(color: Color) -> Color:
	var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
	return Color("1c140e") if lum > 0.62 else Color("f3e6c8")
