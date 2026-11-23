extends Node2D

const Catalog = preload("res://scripts/unit_catalog.gd")
const SmokeVeil = preload("res://scripts/smoke_veil.gd")
const Painter = preload("res://scripts/painter.gd")
const FrameBake = preload("res://scripts/frame_bake.gd")
const SkillFx = preload("res://scripts/skill_fx.gd")
const SceneryScript = preload("res://scripts/scenery.gd")
const GateScript = preload("res://scripts/gate.gd")
const UnitScript = preload("res://scripts/battle_unit.gd")
const HeroScript = preload("res://scripts/hero.gd")
const ArrowScript = preload("res://scripts/projectile.gd")
const FloatScript = preload("res://scripts/float_text.gd")
const PoofScript = preload("res://scripts/poof.gd")
const FieldScript = preload("res://scripts/field_input.gd")
const TouchLayout = preload("res://scripts/touch_layout.gd")
const JoyScript = preload("res://scripts/joystick.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const Levels = preload("res://scripts/levels.gd")
const Early = preload("res://scripts/early_roster.gd")

const PLAYER_START := 16.0
const PLAYER_INCOME := 3.6
const CASTLE_BLOOD := 2000
const CASTLE_STEP := 200
const RANK_CAP := 20
const ENEMY_START := 22.0
const ENEMY_INCOME_BASE := 7.2
const ENEMY_GROWTH := 0.065
const MAX_SIDE := 24
const BREAK_TIME := 2.55
const SKILL_COST := 60.0
const SPLASH_REACH := 70.0


static func castle_blood(rank: int) -> int:
	return CASTLE_BLOOD + CASTLE_STEP * (clampi(rank, 1, RANK_CAP) - 1)


static func income_tenths(rank: int) -> int:
	return 36 + (clampi(rank, 1, RANK_CAP) - 1)


static func income_rate(rank: int) -> float:
	return float(income_tenths(rank)) / 10.0


static func income_line(rate: float) -> String:
	var tenths := int(round(rate * 10.0))
	var whole := int(float(tenths) / 10.0)
	var frac := tenths - whole * 10
	return "+%d.%d each second" % [whole, frac]


static func is_skill(id: String) -> bool:
	return id == "ex" or id == "ls" or id == "fz" or id == "en"


static func skill_name(id: String) -> String:
	match id:
		"ex":
			return "Explosion"
		"ls":
			return "Light smashing"
		"fz":
			return "Freezing"
		"en":
			return "Enhancement"
		_:
			return id


var mode: String = ""
var rules: Dictionary = {}
var level_no: int = 1
var loadout: Array = []
var finished: bool = false
var paused: bool = false
var player_value: float = PLAYER_START
var player_income: float = PLAYER_INCOME
var enemy_value: float = ENEMY_START
var enemy_income: float = ENEMY_INCOME_BASE
var battle_time: float = 0.0
var damage_events: int = 0
var spawned_player: int = 0
var vp: Vector2 = Vector2(1280, 720)
var ground_y: float = 400.0
var lane_ys: Array[float] = []
const CASTLE_EDGE := 48.0
const CASTLE_YARD := 100.0
const CASTLE_HALF := 58.0
const YARD_STAY := 10.0

var player_front: float = 264.0
var enemy_front: float = 1016.0
var player_rear: float = 48.0
var enemy_rear: float = 1232.0
var units: Array = []
var buff_links: Dictionary = {}
var hazards: Array = []
var smokes: Array = []
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
var coin_label: Label
var level_label: Label
var note_board: Panel
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
var front: CanvasLayer
var hurt_flash: ColorRect
var lane_tick: int = 0
var enemy_lock: float = 0.2
var wave_left: int = 0
var lull: float = 1.0
var auto_lock: float = 0.15
var texts_this_frame: int = 0
var harness_done: bool = false
var sword_hold: bool = false
var stick_axis: Vector2 = Vector2.ZERO
var stick: Control = null
var stick_finger: int = -1
var stick_mouse: bool = false
var shoot_hold: bool = false
var purse_paid: Dictionary = {}
var boss_up: bool = false
var trial_on: bool = false
var trial_left: int = 0
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
var rank_mode: String = "own"
var rank_left: Dictionary = {}
var rank_right: Dictionary = {}
var buff_power: Dictionary = {}
var sent_keys: Array = []
var hand_seen: float = -1.0
var fallen_side: int = -1
var yard_stay: Dictionary = {}
var full_note: float = 0.0
var leaving: bool = false
var win_banked: bool = false
var ending_sent: bool = false
var castle_break: float = -1.0
var break_side: int = -1
var break_cam: Camera2D = null
var break_from: Vector2 = Vector2.ZERO
var break_aim: Vector2 = Vector2.ZERO
var _yard_seen: Dictionary = {}
var _yard_drop: Array = []
var _list_frame: int = -1
var _ally_lists: Array = [[], []]
var _foe_lists: Array = [[], []]
var _lane_foes: Array = [[], []]
var _wide_foes: Array = [[], []]
var _air_on: Array = [false, false]
var _no_foes: Array = []
var _hud_level_size: int = 0
var _hud_hp_hot: bool = false
var _hud_pfill: float = -1.0
var _hud_efill: float = -1.0
var _hud_p_hot: bool = false
var skill_buttons: Array = []
var cold_roads: Array = []
var slash_fx: Array = []
var bursts: Array = []
var fx_glow = null
var fx_body = null
var fx_marks = null
var fx_rooted: bool = false


func start(chosen: Array, run_mode: String, level_index: int = 1) -> void:
	loadout = chosen.duplicate()
	mode = run_mode
	rules = Levels.level(level_index)
	level_no = int(rules["index"])
	if mode == "" and not duel:
		var host := get_parent()
		if host != null and host.has_method("begin_hold"):
			host.begin_hold()
	enemy_value = float(rules["start"])
	enemy_income = float(rules["income"])
	player_income = _income_for(0)
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
	rank_mode = "max" if str(skins.get("mode", "own")) == "max" else "own"
	rank_left = _parse_ranks(str(skins.get("left_ranks", "")))
	rank_right = _parse_ranks(str(skins.get("right_ranks", "")))
	puppet = not runs_world
	local_side = side
	foe_loadout = other_ids.duplicate()
	var left_raw: Variant = skins.get("left", {})
	var right_raw: Variant = skins.get("right", {})
	skin_left = left_raw if left_raw is Dictionary else {}
	skin_right = right_raw if right_raw is Dictionary else {}
	start(local_ids, "duel", 1)
	enemy_value = PLAYER_START
	enemy_income = _income_for(1)
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
	_bound_hero(foe)
	foe.net_pos = foe.position
	hero.look = _worn_look(0, "hero")
	foe.look = _worn_look(1, "hero")
	hero.driven = local_side != 0
	foe.driven = local_side == 0 and not duel_probe
	controlled = foe if local_side == 1 else hero
	if level_label != null:
		level_label.text = "1 vs 1"
	if hint != null:
		hint.text = "The stick moves your hero. The match runs until a gate falls."
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
	player_rear = CASTLE_EDGE
	player_front = CASTLE_EDGE + CASTLE_YARD + CASTLE_HALF * 2.0
	enemy_front = vp.x - player_front
	enemy_rear = vp.x - CASTLE_EDGE
	player_gate = GateScript.new()
	player_gate.setup(self, 0, Vector2(player_front - CASTLE_HALF, ground_y), player_front)
	add_child(player_gate)
	enemy_gate = GateScript.new()
	enemy_gate.setup(self, 1, Vector2(enemy_front + CASTLE_HALF, ground_y), enemy_front)
	add_child(enemy_gate)
	_apply_castles()
	world = Node2D.new()
	add_child(world)
	var veil = SmokeVeil.new()
	veil.battle = self
	veil.z_index = 900
	add_child(veil)
	fx = Node2D.new()
	fx.z_index = 120
	add_child(fx)
	SkillFx.warm(self)
	var glow = SkillFx.GlowLayer.new()
	glow.field = self
	glow.z_index = 500
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = glow_mat
	add_child(glow)
	fx_glow = glow
	var body = SkillFx.BodyLayer.new()
	body.field = self
	body.z_index = 470
	add_child(body)
	fx_body = body
	var marks = SkillFx.MarkLayer.new()
	marks.field = self
	marks.z_index = 640
	add_child(marks)
	fx_marks = marks
	hero = HeroScript.new()
	hero.setup(self)
	add_child(hero)
	_bound_hero(hero)
	controlled = hero


func _build_hud() -> void:
	layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var field = FieldScript.new()
	field.battle = self
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.mouse_filter = Control.MOUSE_FILTER_STOP
	field.z_index = 0
	layer.add_child(field)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.z_index = 2
	layer.add_child(hud)
	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hurt_flash.color = Color(0, 0, 0, 0)
	hud.add_child(hurt_flash)
	note_board = Panel.new()
	note_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_board.clip_contents = true
	note_board.z_index = 3
	note_board.set_meta("note_board", true)
	note_board.add_theme_stylebox_override("panel", UiSkin.panel(Color(0.06, 0.045, 0.06, 0.88), Color("e6c36a"), 12, 2))
	player_hp_label = _plain("Clan gate  %d" % int(round(player_gate.hp)), 16, Color("f3e6c8"))
	enemy_hp_label = _plain("Cursed gate  %d" % int(round(enemy_gate.hp)), 16, Color("f3e6c8"))
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label = _plain("Value  16    ·    %s" % income_line(_shown_income()), 22, Color("e6c36a"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_label = _plain(_coin_board_text(), 16, Color("f3e6c8"))
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label = _plain("Level %d  ·  %s" % [level_no, str(rules["name"])], 18, Color("f3e6c8"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = _plain("Press the field. The stick appears under that hand. Calls sit along the bottom. Sword and Shoot are on the right.", 16, Color("f3e6c8"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	down_label = _plain("", 18, Color("ffb4a8"))
	down_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_track = _bar_track()
	enemy_track = _bar_track()
	player_bar_fill = _bar_fill(Color("7dce6a"))
	enemy_bar_fill = _bar_fill(Color("e24b3b"))
	player_track.add_child(player_bar_fill)
	enemy_track.add_child(enemy_bar_fill)
	note_board.add_child(player_hp_label)
	note_board.add_child(enemy_hp_label)
	note_board.add_child(value_label)
	note_board.add_child(coin_label)
	note_board.add_child(level_label)
	note_board.add_child(down_label)
	note_board.add_child(player_track)
	note_board.add_child(enemy_track)
	hud.add_child(note_board)
	hud.add_child(hint)
	player_track.set_meta("bar", true)
	if not duel:
		pause_btn = Button.new()
		pause_btn.text = "Pause"
		pause_btn.focus_mode = Control.FOCUS_NONE
		UiSkin.apply(pause_btn, Color("f3e6c8"), 16)
		pause_btn.pressed.connect(_toggle_pause)
		note_board.add_child(pause_btn)
		home_btn = Button.new()
		home_btn.text = "Home"
		home_btn.focus_mode = Control.FOCUS_NONE
		UiSkin.apply(home_btn, Color("e6c36a"), 16)
		home_btn.pressed.connect(_go_home)
		note_board.add_child(home_btn)
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
		btn.set_meta("slot_short", str(entry["short"]))
		btn.set_meta("slot_cost", int(entry["cost"]))
		btn.set_meta("call_slot", true)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.z_index = 6
		var slot_index := slot_buttons.size()
		slot_hold.append(false)
		btn.button_down.connect(_press_slot.bind(slot_index))
		btn.button_up.connect(_set_hold.bind(slot_index, false))
		btn.clip_text = true
		hud.add_child(btn)
		slot_buttons.append(btn)
	_build_skill_buttons()
	stick = JoyScript.new()
	stick.moved.connect(_on_stick)
	hud.add_child(stick)
	_layout_hud()
	if not get_viewport().size_changed.is_connected(_layout_hud):
		get_viewport().size_changed.connect(_layout_hud)


func _on_stick(axis: Vector2) -> void:
	stick_axis = axis


func _release_stick() -> void:
	stick_axis = Vector2.ZERO
	stick_finger = -1
	stick_mouse = false
	if stick != null and is_instance_valid(stick) and stick.has_method("release_stick"):
		stick.release_stick()


func _input(event: InputEvent) -> void:
	if finished or paused or puppet:
		return
	if event is InputEventScreenTouch:
		_stick_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_stick_screen_drag(event as InputEventScreenDrag)
	elif stick_finger >= 0 and (event is InputEventMouseButton or event is InputEventMouseMotion):
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_stick_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and stick_mouse:
		_stick_mouse_move(event as InputEventMouseMotion)


func _stick_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		if stick_finger >= 0:
			get_viewport().set_input_as_handled()
			return
		if _stick_blocked(touch.position):
			return
		stick_finger = touch.index
		stick_mouse = false
		_move_stick(touch.position, true)
		get_viewport().set_input_as_handled()
		return
	if touch.index != stick_finger:
		return
	_release_stick()
	get_viewport().set_input_as_handled()


func _stick_screen_drag(drag: InputEventScreenDrag) -> void:
	if drag.index != stick_finger:
		return
	_move_stick(drag.position, false)
	get_viewport().set_input_as_handled()


func _stick_mouse_button(press: InputEventMouseButton) -> void:
	if press.pressed:
		if _stick_blocked(press.position):
			return
		stick_mouse = true
		stick_finger = -1
		_move_stick(press.position, true)
		get_viewport().set_input_as_handled()
		return
	if not stick_mouse:
		return
	_release_stick()
	get_viewport().set_input_as_handled()


func _stick_mouse_move(motion: InputEventMouseMotion) -> void:
	_move_stick(motion.position, false)
	get_viewport().set_input_as_handled()


func _move_stick(point: Vector2, fresh: bool) -> void:
	if stick == null or not is_instance_valid(stick) or hud == null:
		return
	var local: Vector2 = hud.get_global_transform().affine_inverse() * point
	if fresh and stick.has_method("show_under"):
		stick.show_under(local)
	elif stick.has_method("follow_finger"):
		stick.follow_finger(local)


func _stick_blocked(point: Vector2) -> bool:
	if note_board != null and is_instance_valid(note_board) and note_board.get_global_rect().has_point(point):
		return true
	if sword_btn != null and is_instance_valid(sword_btn) and sword_btn.get_global_rect().has_point(point):
		return true
	if shoot_btn != null and is_instance_valid(shoot_btn) and shoot_btn.get_global_rect().has_point(point):
		return true
	for raw_slot in slot_buttons:
		var slot_btn: Button = raw_slot
		if slot_btn.get_global_rect().has_point(point):
			return true
	for raw_skill in skill_buttons:
		var skill_btn: Button = raw_skill
		if is_instance_valid(skill_btn) and skill_btn.get_global_rect().has_point(point):
			return true
	return false


func _set_hold(index: int, held: bool) -> void:
	if index >= 0 and index < slot_hold.size():
		slot_hold[index] = held


# The click itself calls the fighter. A crowded frame can deliver the press and
# the release together, before _process, and the hold flag would already be down.
func _press_slot(index: int) -> void:
	_set_hold(index, true)
	if finished or paused:
		return
	if index < 0 or index >= loadout.size():
		return
	if duel and local_side != 0:
		if _count(local_side) >= MAX_SIDE:
			_note_side_full()
		return
	summon_player(str(loadout[index]))


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
	var size := TouchLayout.view_of(self)
	var box := TouchLayout.measure(size, TouchLayout.insets_of(self))
	var pad: Vector4 = box["pad"]
	var action := Vector2(float(box["action"]), float(box["action"]))
	var top := pad.y
	if sword_btn != null:
		sword_btn.size = action
		shoot_btn.size = action
		sword_btn.custom_minimum_size = action
		shoot_btn.custom_minimum_size = action
		sword_btn.position = box["sword_pos"]
		shoot_btn.position = box["shoot_pos"]
		sword_btn.add_theme_font_size_override("font_size", 24)
		shoot_btn.add_theme_font_size_override("font_size", 24)
	var slot_w := float(box["slot_w"])
	var slot_h := float(box["slot_h"])
	var slot_gap := float(box["slot_gap"])
	var slots_left := float(box["slots_left"])
	var slot_y := float(box["slot_y"])
	var slot_font := 18 if slot_w >= 112.0 else 15
	for i in slot_buttons.size():
		var btn: Button = slot_buttons[i]
		btn.size = Vector2(slot_w, slot_h)
		btn.custom_minimum_size = btn.size
		btn.position = Vector2(slots_left + float(i) * (slot_w + slot_gap), slot_y)
		btn.add_theme_font_size_override("font_size", slot_font)
	if not skill_buttons.is_empty():
		var skill_count := skill_buttons.size()
		var skill_gap := 8.0
		var skill_h := 46.0
		var skill_span := maxf(96.0, size.x - 40.0 - skill_gap * float(skill_count - 1))
		var skill_w := minf(176.0, skill_span / float(skill_count))
		var row_w := skill_w * float(skill_count) + skill_gap * float(skill_count - 1)
		var skill_x := (size.x - row_w) * 0.5
		var skill_y := slot_y - skill_h - 8.0
		for skill_i in skill_count:
			var skill_btn: Button = skill_buttons[skill_i]
			skill_btn.size = Vector2(skill_w, skill_h)
			skill_btn.custom_minimum_size = skill_btn.size
			skill_btn.position = Vector2(skill_x + float(skill_i) * (skill_w + skill_gap), skill_y)
			skill_btn.add_theme_font_size_override("font_size", 15)
	if stick != null:
		var stick_size := float(box["stick"])
		var hold_center := stick.position + stick.size * 0.5
		var was_shown := stick.visible
		stick.size = Vector2(stick_size, stick_size)
		stick.custom_minimum_size = stick.size
		if was_shown:
			stick.position = hold_center - stick.size * 0.5
		stick.queue_redraw()
	var sky_bottom := size.y * 0.34 - 22.0
	var board_top := top + 6.0
	var board_h := minf(132.0, maxf(0.0, sky_bottom - board_top - 4.0))
	var board_x := pad.x + 10.0
	var board_w := maxf(320.0, size.x - pad.x - pad.z - 20.0)
	if note_board != null:
		note_board.position = Vector2(board_x, board_top)
		note_board.size = Vector2(board_w, board_h)
	var side_w := 210.0
	player_hp_label.position = Vector2(14.0, 74.0)
	player_hp_label.size = Vector2(side_w, 24)
	enemy_hp_label.position = Vector2(board_w - side_w - 14.0, 74.0)
	enemy_hp_label.size = Vector2(side_w, 24)
	if player_track != null:
		player_track.position = Vector2(14.0, 102.0)
		enemy_track.position = Vector2(board_w - 234.0, 102.0)
	var mid_w := maxf(280.0, board_w - 460.0)
	var mid_x := (board_w - mid_w) * 0.5
	level_label.position = Vector2(mid_x, 8.0)
	level_label.size = Vector2(mid_w, 26)
	if coin_label != null:
		coin_label.position = Vector2(mid_x, 36.0)
		coin_label.size = Vector2(mid_w, 22)
	value_label.position = Vector2(mid_x, 58.0)
	value_label.size = Vector2(mid_w, 28)
	value_label.add_theme_font_size_override("font_size", 22)
	down_label.position = Vector2(mid_x, 96.0)
	down_label.size = Vector2(mid_w, 24)
	var hint_y := board_top + board_h + 4.0
	hint.position = Vector2(size.x * 0.5 - 300.0, hint_y)
	hint.size = Vector2(600, 36)
	hint.visible = hint_y + 32.0 < sky_bottom
	var chrome := Vector2(136, 58)
	if pause_btn != null:
		pause_btn.size = chrome
		pause_btn.custom_minimum_size = chrome
		pause_btn.position = Vector2(board_w - chrome.x - 12.0, 8.0)
		pause_btn.add_theme_font_size_override("font_size", 20)
	if home_btn != null:
		home_btn.size = chrome
		home_btn.custom_minimum_size = chrome
		home_btn.position = Vector2(12.0, 8.0)
		home_btn.add_theme_font_size_override("font_size", 20)


func _process(delta: float) -> void:
	texts_this_frame = 0
	battle_time += delta
	if puppet:
		_send_hand()
		_update_hud(delta)
		_tick_castle_break(delta)
		_run_harness()
		return
	if not finished and not paused:
		if not duel and mode == "":
			var host := get_parent()
			if host != null and host.has_method("note_hold"):
				host.note_hold(level_no, delta)
		for id in player_cd.keys():
			player_cd[id] = maxf(0.0, float(player_cd[id]) - delta)
		for id in enemy_cd.keys():
			enemy_cd[id] = maxf(0.0, float(enemy_cd[id]) - delta)
		player_value += player_income * delta
		_tick_hazards(delta)
		_tick_chill(delta)
		_tick_slashes(delta)
		_tick_bursts(delta)
		_tick_smokes(delta)
		_redraw_fx()
		if duel:
			enemy_value += enemy_income * delta
			if hand_seen >= 0.0 and battle_time - hand_seen > 0.45 and foe != null:
				foe.pointer_sword = false
				foe.pointer_shoot = false
			if duel_probe and foe != null and foe.alive:
				foe.bot_axis = Vector2(-1, 0)
				foe.bot_sword = true
		elif trial_on or battle_time < _rule_f("warmup", 0.0):
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
		_tick_castle_yard(delta)
	_send_state(delta)
	_update_hud(delta)
	_tick_castle_break(delta)
	_run_harness()


func _enemy_ai(delta: float) -> void:
	if trial_on:
		return
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
	var options := _enemy_options()
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
	var road := -1
	if id == "fan":
		road = _fan_road()
		if road < 0:
			return false
	enemy_value -= float(entry["cost"])
	enemy_cd[id] = float(entry["cooldown"])
	_spawn(_scaled_enemy(entry), 1, road)
	return true


func _fans_on(road: int) -> int:
	var total := 0
	for unit in units:
		if not is_instance_valid(unit) or not unit.alive or unit.side != 1:
			continue
		if str(unit.data.get("id", "")) != "fan" or int(unit.lane) != road:
			continue
		total += 1
	return total


func _fan_road() -> int:
	var roads := maxi(lane_ys.size(), 1)
	for step in roads:
		var road := (lane_tick + step) % roads
		if _fans_on(road) < 2:
			lane_tick = road + 1
			return road
	return -1


func _enemy_options() -> Array:
	return enemy_ids(level_no, rules, battle_time)


static func enemy_ids(level_no: int, rules: Dictionary, _battle_time: float) -> Array:
	# The whole roster this level already had. Time does not add or remove anyone.
	var human := str(rules.get("faction", "")) == "human"
	var modern := human and level_no >= 61
	var dire := (not human) and level_no >= 41
	if modern:
		return ["knives", "buck", "firebow", "javelin", "ward", "smog", "aria", "fan", "scope", "crow", "bomber"]
	if human:
		return ["knives", "firebow", "javelin", "ward", "fan", "drum", "cow", "bomber"]
	if dire:
		return ["walker", "runner", "moth", "viper", "shell", "brood", "elder", "howler", "reaver", "glut", "oni", "storm", "crow"]
	if level_no <= 19:
		return Early.pool(level_no)
	return ["walker", "runner", "viper", "shell", "howler", "herald", "reaver", "oni", "storm"]


static func faced_enemy(entry: Dictionary, rules: Dictionary) -> Dictionary:
	var copy: Dictionary = entry.duplicate()
	var mult := 1.0
	var hp_mult := 1.0
	if rules.has("dmg_mult"):
		mult = float(rules["dmg_mult"])
	if rules.has("hp_mult"):
		hp_mult = float(rules["hp_mult"])
	var kind := str(copy.get("id", ""))
	var catalog_hp: int = int(copy["hp"])
	var catalog_damage: int = int(copy["damage"])
	copy["hp"] = maxi(1, int(round(float(catalog_hp) * hp_mult)))
	if kind == "ward":
		copy["damage"] = 5
	elif kind == "fan":
		copy["damage"] = 3
	elif kind == "drum" or kind == "smog" or kind == "aria" or kind == "glut":
		copy["damage"] = 0
	elif kind == "bomber":
		var scaled_hp: int = int(copy["hp"])
		var scaled_damage: int = maxi(1, int(round(float(catalog_damage) * mult)))
		if scaled_damage < catalog_damage or scaled_hp > catalog_hp:
			copy["hp"] = catalog_hp
			copy["damage"] = catalog_damage
		else:
			copy["damage"] = scaled_damage
	else:
		copy["damage"] = maxi(1, int(round(float(copy["damage"]) * mult)))
	if copy.has("swing"):
		copy["swing"] = maxi(1, int(round(float(copy["swing"]) * mult)))
	if copy.has("opening"):
		copy["opening"] = maxi(1, int(round(float(copy["opening"]) * mult)))
	if copy.has("sword"):
		copy["sword"] = maxi(1, int(round(float(copy["sword"]) * mult)))
	if copy.has("burn"):
		copy["burn"] = maxi(1, int(round(float(copy["burn"]) * mult)))
	if copy.has("chew"):
		copy["chew"] = maxi(1, int(round(float(copy["chew"]) * mult)))
	return copy


func _scaled_enemy(entry: Dictionary) -> Dictionary:
	return faced_enemy(entry, rules)


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
	if float(player_cd[id]) > 0.0:
		return
	if player_value < float(entry["cost"]):
		return
	if _count(0) >= MAX_SIDE:
		_note_side_full()
		return
	player_value -= float(entry["cost"])
	player_cd[id] = float(entry["cooldown"])
	_spawn(entry, 0)


func _note_side_full() -> void:
	full_note = 1.6
	if down_label != null:
		var watched = controlled if controlled != null else hero
		if watched == null or watched.alive:
			if down_label.text != "Field is full":
				down_label.text = "Field is full"
	_paint_slots()


func _paint_slots() -> void:
	if slot_buttons.is_empty():
		return
	var cap_side := 0
	if duel and local_side == 1:
		cap_side = 1
	var at_cap := _count(cap_side) >= MAX_SIDE
	for i in slot_buttons.size():
		var id := str(loadout[i])
		var btn: Button = slot_buttons[i]
		var short_name := str(btn.get_meta("slot_short", id))
		var cost := int(btn.get_meta("slot_cost", 0))
		var cd := 0.0
		if player_cd.has(id):
			cd = float(player_cd[id])
		var shown := ""
		var tint := Color.WHITE
		if cd > 0.0:
			shown = "%s\n%.1fs" % [short_name, cd]
			tint = Color(0.62, 0.62, 0.68)
		elif at_cap:
			shown = "%s\nFULL" % short_name
			tint = Color(0.85, 0.55, 0.45)
		else:
			shown = "%s\n%d" % [short_name, cost]
			if player_value < float(cost):
				tint = Color(0.75, 0.62, 0.58)
		if btn.text != shown:
			btn.text = shown
		if btn.modulate != tint:
			btn.modulate = tint


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


func rank_factor(unit_id: String, side: int) -> float:
	if unit_id != "hero" and Catalog.find_in(player_roster, unit_id).is_empty():
		return 1.0
	if rank_mode == "max":
		return 1.95
	var table := rank_left
	if duel and side == 1:
		table = rank_right
	var rank := 1
	if table.has(unit_id):
		rank = clampi(int(table[unit_id]), 1, 20)
	return 1.0 + 0.05 * float(rank - 1)


func _parse_ranks(raw: String) -> Dictionary:
	var known: Array = ["hero", "sword", "archer", "shield", "saber", "lancer", "berserker", "horse", "suicide", "assassin", "heal", "level", "gate", "income", "ex", "ls", "fz", "en"]
	var out: Dictionary = {}
	for piece in raw.split(",", false):
		var bits: PackedStringArray = piece.split(":")
		if bits.size() != 2:
			continue
		var unit_id := str(bits[0])
		if not known.has(unit_id):
			continue
		out[unit_id] = clampi(int(bits[1]), 1, 20)
	return out


func _side_rank(side: int, id: String) -> int:
	if rank_mode == "max":
		return RANK_CAP
	var table := rank_left
	if duel and side == 1:
		table = rank_right
	if table.has(id):
		return clampi(int(table[id]), 1, RANK_CAP)
	return 1


func _castle_for(side: int) -> int:
	return castle_blood(_side_rank(side, "gate"))


func _income_for(side: int) -> float:
	return income_rate(_side_rank(side, "income"))


func _coin_board_text() -> String:
	var purse := 0
	var host := get_parent()
	if host != null:
		var raw = host.get("coins")
		if raw != null:
			purse = int(raw)
	var text := "Coins  %d" % purse
	if duel or host == null or not host.has_method("hold_hud"):
		return text
	var rate := str(host.hold_hud(level_no))
	if rate != "":
		text += "   ·   " + rate
	return text


func _shown_income() -> float:
	if duel and local_side == 1:
		return _income_for(1)
	return player_income


func _apply_castles() -> void:
	_set_castle(player_gate, _castle_for(0))
	if duel:
		_set_castle(enemy_gate, _castle_for(1))


func _set_castle(gate, blood: int) -> void:
	if gate == null:
		return
	gate.max_hp = float(blood)
	gate.hp = float(blood)


func _ranked(entry: Dictionary, side: int) -> Dictionary:
	var copy := entry.duplicate()
	var factor := rank_factor(str(copy.get("id", "")), side)
	copy["rank_factor"] = factor
	if factor == 1.0:
		return copy
	copy["hp"] = maxi(1, int(round(float(copy["hp"]) * factor)))
	if int(copy.get("damage", 0)) > 0:
		copy["damage"] = maxi(1, int(round(float(copy["damage"]) * factor)))
	return copy


func _spawn(entry: Dictionary, side: int, forced_road: int = -1, back: float = 0.0) -> void:
	entry = _ranked(entry, side)
	var unit = UnitScript.new()
	unit.setup(self, entry, side)
	var trial := bool(entry.get("trial", false))
	var kind: String = str(entry.get("id", ""))
	var road := 1
	if forced_road >= 0:
		road = forced_road
	elif side == 0:
		if hero != null and is_instance_valid(hero) and hero.alive:
			road = hero.lane
	elif duel and foe != null and is_instance_valid(foe) and foe.alive:
		road = foe.lane
	elif not trial and (kind == "berserker" or kind == "boss"):
		road = lane_ys.size() / 2
	else:
		road = lane_tick % maxi(lane_ys.size(), 1)
		lane_tick += 1
	road = clampi(road, 0, maxi(lane_ys.size() - 1, 0))
	unit.lane = road
	var y := lane_y(road)
	var born := player_rear if side == 0 else enemy_rear
	if trial and side == 1:
		born = enemy_front - 28.0 - back
	elif kind == "boss":
		born = enemy_front - 24.0
	elif side == 1:
		born += back
	else:
		born -= back
	unit.position = Vector2(born, y)
	if kind == "elder":
		unit.position.x = randf_range(player_front + 36.0, enemy_front - 36.0)
	unit.net_id = next_net
	next_net += 1
	if duel:
		unit.look = _worn_look(side, str(entry.get("paint", "sword")))
	world.add_child(unit)
	units.append(unit)
	if side == 0:
		spawned_player += 1
	var paint := str(entry.get("paint", "sword"))
	Sfx.play(Painter.call_id(paint), Painter.call_pitch(paint) * randf_range(0.99, 1.01), -2.0 if side == 0 else -9.0)
	poof(unit.position, Color("f3e6c8") if side == 0 else Color("c6e38a"))


func summon_for_herald() -> void:
	var allowed: Array = enemy_ids(level_no, rules, battle_time)
	var base: Array = ["walker", "runner", "howler", "viper", "shell", "reaver"]
	var pool: Array = []
	for ident in base:
		if allowed.has(ident):
			pool.append(ident)
	if pool.is_empty():
		pool.append("walker")
	for call_n in 2:
		if _count(1) >= MAX_SIDE:
			return
		var picked: String = str(pool[randi() % pool.size()])
		var entry := Catalog.find_in(enemy_roster, picked)
		if entry.is_empty():
			continue
		var copy := _scaled_enemy(entry)
		copy["bounty"] = 0
		_spawn(copy, 1)


func _count(side: int) -> int:
	var total := 0
	for unit in units:
		if is_instance_valid(unit) and unit.alive and unit.side == side:
			total += 1
	return total


func sheltered(body) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	var x := float(body.position.x)
	if int(body.side) == 0:
		return x < player_front
	return x > enemy_front


func _tick_castle_yard(delta: float) -> void:
	_yard_seen.clear()
	for unit in units:
		if is_instance_valid(unit) and unit.alive:
			_note_yard(unit, delta)
	if hero != null and is_instance_valid(hero) and hero.alive:
		_note_yard(hero, delta)
	if foe != null and is_instance_valid(foe) and foe.alive:
		_note_yard(foe, delta)
	_yard_drop.clear()
	for old_id in yard_stay.keys():
		if not _yard_seen.has(old_id):
			_yard_drop.append(old_id)
	for drop_id in _yard_drop:
		yard_stay.erase(drop_id)


func _note_yard(body, delta: float) -> void:
	var stay_id: int = body.get_instance_id()
	_yard_seen[stay_id] = true
	if _howler_leaving(body):
		yard_stay.erase(stay_id)
		return
	if sheltered(body):
		var spent: float = float(yard_stay.get(stay_id, 0.0)) + delta
		if spent >= YARD_STAY:
			_set_before_own_castle(body)
			yard_stay.erase(stay_id)
		else:
			yard_stay[stay_id] = spent
	elif yard_stay.has(stay_id):
		yard_stay.erase(stay_id)


func _howler_leaving(body) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if body.get_script() != UnitScript:
		return false
	if str(body.role) != "howler":
		return false
	return bool(body.perched) or bool(body.diving)


func _set_before_own_castle(body) -> void:
	if int(body.side) == 0:
		body.position.x = player_front
	else:
		body.position.x = enemy_front


func hostile_targets(attacker_side: int) -> Array:
	_ensure_lists()
	if attacker_side != 0 and attacker_side != 1:
		return _no_foes
	var foes: Array = _foe_lists[attacker_side]
	return foes


func support_candidates(side: int) -> Array:
	_ensure_lists()
	if side != 0 and side != 1:
		return _no_foes
	var allies: Array = _ally_lists[side]
	return allies


func foes_on_lane(attacker_side: int, road: int) -> Array:
	_ensure_lists()
	if attacker_side != 0 and attacker_side != 1:
		return _no_foes
	var lanes: Array = _lane_foes[attacker_side]
	if road < 0 or road >= lanes.size():
		return _no_foes
	var found: Array = lanes[road]
	return found


func wides_for(attacker_side: int) -> Array:
	_ensure_lists()
	if attacker_side != 0 and attacker_side != 1:
		return _no_foes
	var wides: Array = _wide_foes[attacker_side]
	return wides


func side_has_air(attacker_side: int) -> bool:
	_ensure_lists()
	if attacker_side != 0 and attacker_side != 1:
		return false
	return bool(_air_on[attacker_side])


func _ensure_lists() -> void:
	var frame := Engine.get_process_frames()
	if frame == _list_frame:
		return
	_list_frame = frame
	var roads := maxi(lane_ys.size(), 1)
	for which in 2:
		var allies: Array = _ally_lists[which]
		allies.clear()
		var foes: Array = _foe_lists[which]
		foes.clear()
		var wides: Array = _wide_foes[which]
		wides.clear()
		_air_on[which] = false
		var lanes: Array = _lane_foes[which]
		while lanes.size() < roads:
			var fresh: Array = []
			lanes.append(fresh)
		while lanes.size() > roads:
			lanes.remove_at(lanes.size() - 1)
		for lane_list in lanes:
			lane_list.clear()
	for unit in units:
		if is_instance_valid(unit) and unit.alive:
			var which_side := int(unit.side)
			if which_side == 0 or which_side == 1:
				_push_combatant(unit, which_side)
	for defend_side in 2:
		var defender = _hero_for(defend_side)
		if defender != null:
			_push_combatant(defender, defend_side)


func _push_combatant(body, which_side: int) -> void:
	var allies: Array = _ally_lists[which_side]
	allies.append(body)
	if sheltered(body):
		return
	var attacker := 1 - which_side
	var foes: Array = _foe_lists[attacker]
	foes.append(body)
	if body.has_method("is_airborne") and body.is_airborne():
		_air_on[attacker] = true
	var road := 0
	if "lane" in body:
		road = int(body.lane)
	var lanes: Array = _lane_foes[attacker]
	if lanes.is_empty():
		return
	if road < 0 or road >= lanes.size():
		road = clampi(road, 0, lanes.size() - 1)
	var lane_list: Array = lanes[road]
	lane_list.append(body)
	if is_berserker(body) or is_boss(body):
		var wides: Array = _wide_foes[attacker]
		wides.append(body)


func gate_for_attacker(attacker_side: int):
	return enemy_gate if attacker_side == 0 else player_gate


func damage_gate(defender_side: int, amount: float) -> void:
	var gate = player_gate if defender_side == 0 else enemy_gate
	if gate != null:
		gate.take_damage(amount)


func fire_arrow(from: Vector2, aim: Vector2, amount: float, side: int, color: Color, reach: float, road: int, bold: bool = false, hits_gate: bool = true, homing: bool = false, from_id: String = "", hazard_kind: String = "", hazard_amount: float = 0.0, splash: float = 0.0) -> void:
	var arrow = ArrowScript.new()
	arrow.setup(from, aim, amount, side, color, reach, road, self, bold, hits_gate, homing, from_id, hazard_kind, hazard_amount, splash)
	world.add_child(arrow)
	if duel and Net.role == "host":
		var start := _to_norm(from)
		var end := _to_norm(aim)
		Net.announce_arrow([
			start.x, start.y, end.x, end.y, side, reach, road,
			1 if bold else 0, 1 if homing else 0, color.to_html(false),
		])


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
	if _unit_id(unit) != "berserker":
		return false
	if "data" in unit and unit.data is Dictionary and bool(unit.data.get("trial", false)):
		return false
	return true


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
		var stored = buff_links[source]
		if source == unit:
			var spent := float(buff_power.get(source, 0.2))
			buff_links.erase(source)
			buff_power.erase(source)
			var marked: Array = []
			if stored is Array:
				marked = stored
			elif stored != null:
				marked.append(stored)
			for marked_one in marked:
				if _can_buff(marked_one) and marked_one != unit:
					marked_one.remove_level_buff(spent)
		elif stored is Array:
			if stored.has(unit):
				stored.erase(unit)
		elif stored == unit:
			buff_links[source] = []
	if str(unit.data.get("id", "")) == "brood" and not bool(unit.data.get("child", false)):
		_hatch_lings(unit)
	if boss_up and _unit_id(unit) == "boss":
		_finish_battle(1)
		return
	if trial_on and bool(unit.data.get("trial", false)):
		trial_left = maxi(0, trial_left - 1)
		if trial_left == 0:
			_finish_battle(1)


func set_buff_link(buffer, target) -> void:
	var one: Array = []
	if target != null:
		one.append(target)
	set_buff_group(buffer, one)


func set_buff_group(buffer, targets: Array, power_override: float = -1.0) -> void:
	var power := 0.2
	if power_override >= 0.0:
		power = power_override
	elif buffer != null and "data" in buffer and buffer.data is Dictionary:
		power = 0.2 * float(buffer.data.get("rank_factor", 1.0))
	var prev = buff_links.get(buffer, [])
	var old: Array = []
	if prev is Array:
		old = prev
	elif prev != null:
		old.append(prev)
	var next: Array = []
	for pick in targets:
		if not _can_buff(pick) or next.has(pick):
			continue
		next.append(pick)
	var spent := float(buff_power.get(buffer, power))
	for old_one in old:
		if next.has(old_one):
			continue
		if _can_buff(old_one):
			old_one.remove_level_buff(spent)
	var added := false
	for chosen in next:
		if old.has(chosen):
			continue
		chosen.apply_level_buff(power)
		added = true
	if next.is_empty():
		buff_links.erase(buffer)
		buff_power.erase(buffer)
		return
	buff_links[buffer] = next
	buff_power[buffer] = power
	if added:
		Sfx.play("buff", 1.0, -6.0)


func _can_buff(node) -> bool:
	return node != null and is_instance_valid(node) and node.alive and node.has_method("remove_level_buff")


func note_enemy_purse() -> void:
	if duel or enemy_gate == null:
		return
	var ratio: float = float(enemy_gate.hp) / maxf(1.0, float(enemy_gate.max_hp))
	var start: float = float(rules.get("start", ENEMY_START))
	if level_no >= 20:
		_pay_purse("70", 0.70, ratio, 100.0)
	_pay_purse("50", 0.50, ratio, 100.0)
	_pay_purse("25", 0.25, ratio, start)


func _pay_purse(key: String, line: float, ratio: float, amount: float) -> void:
	if ratio > line or purse_paid.has(key):
		return
	purse_paid[key] = true
	enemy_value += amount
	var stack := purse_paid.size() - 1
	float_text(Vector2(enemy_front, lane_y(0) - 20.0 - float(stack) * 22.0), "+%d" % int(round(amount)), Color("c6e38a"))


func on_gate_fallen(defender_side: int) -> void:
	if finished:
		return
	if duel:
		_finish_battle(defender_side, true)
		return
	if defender_side == 1 and str(rules.get("lesson", "")) != "" and not trial_on:
		_begin_trial()
		return
	if defender_side == 1 and bool(rules.get("boss", false)) and not boss_up:
		_summon_boss()
		return
	_finish_battle(defender_side, true)


func _begin_trial() -> void:
	trial_on = true
	enemy_income = 0.0
	var lesson := str(rules.get("lesson", ""))
	var entry := Catalog.lesson_foe(lesson, level_no)
	if entry.is_empty():
		_finish_battle(1)
		return
	trial_left = 0
	var roads := maxi(lane_ys.size(), 1)
	for road in roads:
		for step in 3:
			_spawn(entry, 1, road, float(step) * 36.0)
			trial_left += 1
	float_text(Vector2(enemy_front - 40.0, lane_y(1) - 78.0), "NINE", Color("7dce6a"))
	if hint != null:
		hint.text = "Their gate is open. Kill the nine."


func _summon_boss() -> void:
	boss_up = true
	enemy_income = 1.0
	var entry: Dictionary = Catalog.find_in(enemy_roster, "boss")
	if entry.is_empty():
		_finish_battle(1)
		return
	entry = entry.duplicate()
	if str(rules.get("faction", "")) == "human":
		entry["paint"] = "general"
		entry["name"] = "General"
	_spawn(entry, 1)
	float_text(Vector2(enemy_front - 30.0, lane_y(1) - 78.0), "GENERAL", Color("e6c36a"))
	if hint != null:
		hint.text = "The general walks. The level ends when the general dies."


func _finish_battle(defender_side: int, from_gate: bool = false) -> void:
	if finished:
		return
	finished = true
	paused = false
	_release_stick()
	fallen_side = defender_side
	var won := defender_side == 1
	if duel:
		won = defender_side != local_side
	Sfx.play("win" if won else "lose", 1.0, -2.0)
	if not duel:
		var purse := get_parent()
		if purse != null and purse.has_method("flush_hold"):
			purse.flush_hold()
	if mode != "" and mode != "duel":
		return
	_close_pause()
	_bank_win(defender_side)
	if _battle_is_quitting():
		return
	if from_gate:
		_start_castle_break(defender_side)
		return
	_show_result(defender_side)


func _bank_win(defender_side: int) -> void:
	if win_banked:
		return
	win_banked = true
	var won := defender_side == 1
	if duel:
		won = defender_side != local_side
	if not won or duel:
		return
	var host := get_parent()
	if host != null and host.has_method("note_clear"):
		host.note_clear(level_no, battle_time)


func _show_result(defender_side: int) -> void:
	if ending_sent or _battle_is_quitting():
		return
	ending_sent = true
	var won := defender_side == 1
	if duel:
		won = defender_side != local_side
	if won and not duel:
		var host := get_parent()
		if host != null and host.has_method("play_clear_story") and host.play_clear_story(level_no, _present_end.bind(defender_side)):
			return
	_present_end(defender_side)


func _battle_is_quitting() -> bool:
	if leaving or not is_inside_tree():
		return true
	return get_tree() == null


func _start_castle_break(defender_side: int) -> void:
	break_side = defender_side
	castle_break = 0.0
	var gate = player_gate if defender_side == 0 else enemy_gate
	if gate != null and is_instance_valid(gate) and gate.has_method("begin_break"):
		gate.begin_break()
	var view := get_viewport_rect().size
	break_from = view * 0.5
	break_aim = break_from
	if gate != null and is_instance_valid(gate):
		break_aim = gate.position
	if break_cam == null or not is_instance_valid(break_cam):
		break_cam = Camera2D.new()
		add_child(break_cam)
	break_cam.position = break_from
	break_cam.zoom = Vector2.ONE
	break_cam.enabled = true
	break_cam.make_current()


func _tick_castle_break(delta: float) -> void:
	if castle_break < 0.0:
		return
	if _battle_is_quitting():
		castle_break = -2.0
		return
	castle_break += delta
	if break_cam != null and is_instance_valid(break_cam):
		var blend := clampf(castle_break / 0.78, 0.0, 1.0)
		var ease := blend * blend * (3.0 - 2.0 * blend)
		break_cam.position = break_from.lerp(break_aim, ease)
		var zoom := lerpf(1.0, 2.45, ease)
		break_cam.zoom = Vector2(zoom, zoom)
	if castle_break >= BREAK_TIME:
		castle_break = -2.0
		_show_result(break_side)


func _present_end(defender_side: int) -> void:
	if end_layer != null and is_instance_valid(end_layer):
		return
	var won := defender_side == 1
	if duel:
		won = defender_side != local_side
	var title := "Their gate breaks" if won else "Your gate has fallen"
	var body := "Your gate broke. Call them again, or choose who you bring."
	if str(rules.get("faction", "")) == "monster" and won and not duel:
		title = "The cursed gate breaks"
	if duel:
		title = "Their gate falls" if won else "Your gate has fallen"
		body = "The other clan is broken." if won else "Your gate broke. Fight the same six, or choose again."
	elif won:
		var lesson := str(rules.get("lesson", ""))
		if lesson != "":
			var learned := Catalog.find_in(player_roster, lesson)
			title = "The clan learns"
			body = "%s can be called now." % str(learned.get("name", "A new soldier"))
		elif boss_up:
			title = "The general falls"
			body = "The soldiers fall back."
		elif level_no >= Levels.count():
			title = "The war"
			body = "Monsters and soldiers fight each other. The road stops on the cliff."
		else:
			body = "The road is clear."
		var host := get_parent()
		if host != null and host.has_method("coin_line"):
			var paid := str(host.coin_line())
			if paid != "":
				body += " " + paid
		if level_no < Levels.count():
			var nxt: Dictionary = Levels.level(level_no + 1)
			body += " Level %d, %s, is open." % [int(nxt["index"]), str(nxt["name"])]
	elif not duel:
		var payer := get_parent()
		if payer != null and payer.has_method("held_line"):
			var held := str(payer.held_line())
			if held != "":
				body += " " + held
	var actions: Array = []
	if won and not duel and level_no < Levels.count():
		actions.append({"text": "Next level", "color": Color("c44536"), "call": Callable(get_parent(), "next_level")})
	actions.append({"text": "Rematch", "color": Color("e6c36a"), "call": Callable(get_parent(), "rematch")})
	actions.append({"text": "Change the call", "color": Color("d7c4a3"), "call": Callable(get_parent(), "change_squad")})
	actions.append({"text": "Home", "color": Color("f7f1df"), "call": Callable(get_parent(), "show_title")})
	var lines := PackedStringArray()
	var purse_line := _coin_board_text()
	if purse_line != "":
		lines.append(purse_line)
	lines.append("Value  %d    ·    %s" % [int(floor(player_value)), income_line(_shown_income())])
	_release_stick()
	end_layer = _overlay(title, body, actions, lines)
	end_layer.set_meta("result_front", true)
	_front_layer().add_child(end_layer)


func _toggle_pause() -> void:
	if finished or duel:
		return
	_release_stick()
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
	_front_layer().add_child(pause_layer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		leaving = true


func _go_home() -> void:
	leaving = true
	castle_break = -2.0
	var host := get_parent()
	if host != null and host.has_method("flush_hold"):
		host.flush_hold()
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


func _front_layer() -> CanvasLayer:
	if front != null and is_instance_valid(front):
		return front
	front = CanvasLayer.new()
	front.layer = 30
	front.set_meta("result_front", true)
	add_child(front)
	return front


func _overlay(title: String, body: String, buttons: Array, lines: PackedStringArray = PackedStringArray()) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.07, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiSkin.panel(Color("f3e6c8"), Color("e6c36a"), 18, 4))
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	var heading := UiSkin.label(title, 36, Color("1c140e"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.custom_minimum_size = Vector2(0, 48)
	box.add_child(heading)
	for line in lines:
		var row := UiSkin.label(str(line), 20, Color("6b3a32"))
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(row)
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
	var player_hp_text := "Clan gate  %d" % int(round(player_gate.hp))
	var enemy_hp_text := "Cursed gate  %d" % int(round(enemy_gate.hp))
	if duel:
		player_hp_text = "Left clan  %d" % int(round(player_gate.hp))
		enemy_hp_text = "Right clan  %d" % int(round(enemy_gate.hp))
		if level_label != null and level_label.text != "1 vs 1":
			level_label.text = "1 vs 1"
	if player_hp_label.text != player_hp_text:
		player_hp_label.text = player_hp_text
	if enemy_hp_label.text != enemy_hp_text:
		enemy_hp_label.text = enemy_hp_text
	var hp_hot := player_ratio < 0.3
	if hp_hot != _hud_hp_hot:
		_hud_hp_hot = hp_hot
		player_hp_label.add_theme_color_override("font_color", Color("ffb4a8") if hp_hot else Color("f3e6c8"))
	var value_text := "Value  %d    ·    %s" % [int(floor(player_value)), income_line(_shown_income())]
	if value_label.text != value_text:
		value_label.text = value_text
	if coin_label != null:
		var coin_text := _coin_board_text()
		if coin_label.text != coin_text:
			coin_label.text = coin_text
	if level_label != null and not duel:
		var level_text := "Level %d  ·  %s" % [level_no, str(rules["name"])]
		if level_label.text != level_text:
			level_label.text = level_text
		if _hud_level_size != 18:
			_hud_level_size = 18
			level_label.add_theme_font_size_override("font_size", 18)
	var pfill := 220.0 * clampf(player_ratio, 0.0, 1.0)
	if absf(pfill - _hud_pfill) >= 0.5:
		_hud_pfill = pfill
		player_bar_fill.size.x = pfill
	var efill := 220.0 * clampf(enemy_ratio, 0.0, 1.0)
	if absf(efill - _hud_efill) >= 0.5:
		_hud_efill = efill
		enemy_bar_fill.size.x = efill
	var p_hot := player_ratio <= 0.3
	if p_hot != _hud_p_hot:
		_hud_p_hot = p_hot
		player_bar_fill.color = Color("e24b3b") if p_hot else Color("7dce6a")
	var watched = controlled if controlled != null else hero
	var down_text := ""
	if duel and paused and not finished:
		down_text = "Paused"
	elif watched != null and not watched.alive:
		down_text = "Hero returns in %.1f" % maxf(watched.down_timer, 0.0)
	elif full_note > 0.0:
		down_text = "Field is full"
	if down_label.text != down_text:
		down_label.text = down_text
	if full_note > 0.0:
		full_note = maxf(0.0, full_note - delta)
	if hint != null and battle_time > 11.0 and hint.modulate.a > 0.0:
		hint.modulate.a = maxf(0.0, hint.modulate.a - delta * 0.45)
	_paint_slots()
	if hurt_flash != null and hurt_flash.color.a > 0.0:
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
		if duel and not finished:
			get_viewport().set_input_as_handled()
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if finished or paused or event.is_echo():
		return
	if duel and local_side != 0:
		return
	for i in loadout.size():
		if event.is_action_pressed("slot%d" % (i + 1)):
			summon_player(str(loadout[i]))
			get_viewport().set_input_as_handled()
			return


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
	return Painter.look_as(kind, sheet, false)


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
	if not Net.arrow_got.is_connected(_on_arrow):
		Net.arrow_got.connect(_on_arrow)
	if not Net.skill_got.is_connected(_on_net_skill):
		Net.skill_got.connect(_on_net_skill)


func _exit_tree() -> void:
	FrameBake.clear()
	if Net.input_got.is_connected(_on_hand):
		Net.input_got.disconnect(_on_hand)
	if Net.buy_got.is_connected(_on_net_buy):
		Net.buy_got.disconnect(_on_net_buy)
	if Net.state_got.is_connected(_on_state):
		Net.state_got.disconnect(_on_state)
	if Net.pause_got.is_connected(_on_pause_ask):
		Net.pause_got.disconnect(_on_pause_ask)
	if Net.arrow_got.is_connected(_on_arrow):
		Net.arrow_got.disconnect(_on_arrow)
	if Net.skill_got.is_connected(_on_net_skill):
		Net.skill_got.disconnect(_on_net_skill)


func _on_hand(x: float, y: float, dragging: bool, sword: bool, shoot: bool) -> void:
	if puppet or foe == null or not foe.alive:
		return
	foe.pointer_sword = sword
	foe.pointer_shoot = shoot
	hand_seen = battle_time
	if foe.home_lock > 0.0:
		return
	foe.net_pos = _from_norm(x, y)
	foe.net_step = dragging


func _on_net_buy(unit_id: String) -> void:
	if puppet:
		return
	summon_foe(unit_id)


func _on_net_skill(id: String) -> void:
	if puppet:
		return
	cast_skill(id, 1)


func _on_pause_ask() -> void:
	if puppet or finished:
		return
	if paused:
		_close_pause()
	else:
		_toggle_pause()


func _send_hand() -> void:
	if Net.role != "guest" or controlled == null or not controlled.alive:
		return
	var sword := sword_hold or Input.is_action_pressed("sword")
	var shoot := shoot_hold or Input.is_action_pressed("shoot")
	var spot := _to_norm(controlled.position)
	Net.announce_hand(spot.x, spot.y, controlled.stepping, sword, shoot)
	for i in loadout.size():
		var down := Input.is_action_pressed("slot%d" % (i + 1)) or (i < slot_hold.size() and bool(slot_hold[i]))
		var was := i < sent_keys.size() and bool(sent_keys[i])
		if down and not was:
			Net.announce_buy(str(loadout[i]))
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
	Net.announce_state(_pack_state())


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
	var spot := _to_norm(who.position)
	return [
		spot.x,
		spot.y,
		who.hp,
		1 if who.alive else 0,
		who.facing,
		who.act,
		who.act_tool,
		who.down_timer,
		who.hurt,
		1 if who.winding else 0,
		who.blaze,
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
		var spot := _to_norm(unit.position)
		out.append([
			int(unit.net_id),
			int(unit.side),
			str(unit.data.get("id", "sword")),
			spot.x,
			spot.y,
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
		_finish_battle(int(packet[6]), true)


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
	var at := _from_norm(float(row[0]), float(row[1]))
	var hx := at.x
	var hy := at.y
	var was_alive := bool(who.alive)
	who.hp = float(row[2])
	who.alive = int(row[3]) == 1
	who.visible = who.alive
	who.facing = float(row[4])
	who.act = float(row[5])
	who.act_tool = str(row[6])
	who.down_timer = float(row[7])
	who.hurt = float(row[8])
	who.winding = int(row[9]) == 1
	if row.size() > 10:
		who.blaze = float(row[10])
	var returned: bool = bool(who.alive) and not was_alive
	if returned or not local_control or not who.alive or absf(who.position.x - hx) > 140.0:
		who.position = Vector2(hx, hy)
		who.net_pos = who.position
		who.dragging = false
	if returned:
		who.home_lock = 0.55
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
		unit.position = _from_norm(float(row[3]), float(row[4]))
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


func _on_arrow(payload: Array) -> void:
	if not puppet or world == null or payload.size() < 10:
		return
	var start := _from_norm(float(payload[0]), float(payload[1]))
	var aim := _from_norm(float(payload[2]), float(payload[3]))
	var arrow = ArrowScript.new()
	arrow.cosmetic = true
	arrow.setup(start, aim, 0.0, int(payload[4]), Color(str(payload[9])), float(payload[5]), int(payload[6]), self, int(payload[7]) == 1, false, int(payload[8]) == 1)
	world.add_child(arrow)


func _unit_by_net(nid: int):
	for unit in units:
		if is_instance_valid(unit) and int(unit.net_id) == nid:
			return unit
	return null


func _make_puppet(which: int, kind: String, nid: int):
	var entry := Catalog.find_in(player_roster, kind)
	if entry.is_empty():
		return null
	entry = _ranked(entry, which)
	var unit = UnitScript.new()
	unit.setup(self, entry, which)
	unit.net_id = nid
	unit.look = _worn_look(which, str(entry.get("paint", kind)))
	unit.position = Vector2(player_front if which == 0 else enemy_front, lane_y(1))
	world.add_child(unit)
	units.append(unit)
	Sfx.play(Painter.call_id(str(entry.get("paint", kind))), Painter.call_pitch(str(entry.get("paint", kind))), -4.0)
	return unit


func _bound_hero(who) -> void:
	var top := lane_y(0)
	var bottom := lane_y(maxi(lane_ys.size() - 1, 0))
	if int(who.side) == 0:
		who.set_bounds(player_rear, enemy_front, top, bottom)
	else:
		who.set_bounds(player_front, enemy_rear, top, bottom)


func _to_norm(p: Vector2) -> Vector2:
	var depth := player_front - player_rear
	var span := enemy_front - player_front
	var far := enemy_rear - enemy_front
	var nx := 0.0
	if p.x < player_front and depth > 1.0:
		nx = -(player_front - p.x) / depth
	elif p.x > enemy_front and far > 1.0:
		nx = 1.0 + (p.x - enemy_front) / far
	elif span > 1.0:
		nx = (p.x - player_front) / span
	var top := lane_y(0)
	var bottom := lane_y(maxi(lane_ys.size() - 1, 0))
	var ny := 0.5
	if bottom > top + 1.0:
		ny = (p.y - top) / (bottom - top)
	return Vector2(nx, ny)


func _from_norm(nx: float, ny: float) -> Vector2:
	var depth := player_front - player_rear
	var span := enemy_front - player_front
	var far := enemy_rear - enemy_front
	var x := player_front
	if nx < 0.0:
		x = player_front + nx * depth
	elif nx > 1.0:
		x = enemy_front + (nx - 1.0) * far
	else:
		x = player_front + nx * span
	var top := lane_y(0)
	var bottom := lane_y(maxi(lane_ys.size() - 1, 0))
	return Vector2(x, top + ny * (bottom - top))


func _ink(color: Color) -> Color:
	var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
	return Color("1c140e") if lum > 0.62 else Color("f3e6c8")


func _local_side() -> int:
	if duel:
		return local_side
	return 0


func _rank_table(side: int) -> Dictionary:
	if duel and side == 1:
		return rank_right
	return rank_left


func owns_skill(id: String, side: int) -> bool:
	return _rank_table(side).has(id)


func skill_rank(id: String, side: int) -> int:
	var table := _rank_table(side)
	if not table.has(id):
		return 0
	if rank_mode == "max":
		return RANK_CAP
	return clampi(int(table[id]), 1, RANK_CAP)


func skill_factor(id: String, side: int) -> float:
	var rank := skill_rank(id, side)
	if rank < 1:
		rank = 1
	return 1.0 + 0.05 * float(rank - 1)


func ember_damage() -> float:
	var entry: Dictionary = Catalog.find_in(player_roster, "firebow")
	if entry.is_empty():
		return 9.0
	return float(entry.get("burn", 9.0))


func _build_skill_buttons() -> void:
	var side := _local_side()
	for skill_id in ["ex", "ls", "fz", "en"]:
		var id := str(skill_id)
		if not owns_skill(id, side):
			continue
		var btn := Button.new()
		btn.text = skill_name(id)
		btn.focus_mode = Control.FOCUS_NONE
		btn.clip_text = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.z_index = 8
		var cloth := Color("c44536")
		if id == "ls":
			cloth = Color("e6c36a")
		elif id == "fz":
			cloth = Color("7eb6e0")
		elif id == "en":
			cloth = Color("ff7a2a")
		UiSkin.apply(btn, cloth, 15, _ink(cloth))
		btn.set_meta("skill_id", id)
		btn.pressed.connect(_press_skill.bind(id))
		hud.add_child(btn)
		skill_buttons.append(btn)


func _press_skill(id: String) -> void:
	if finished or paused:
		return
	if duel and puppet:
		if player_value < SKILL_COST:
			return
		Net.announce_skill(id)
		return
	cast_skill(id, _local_side())


func cast_skill(id: String, side: int) -> bool:
	if finished or paused or not is_skill(id):
		return false
	if not owns_skill(id, side):
		return false
	var who = _hero_for(side)
	if who == null:
		return false
	if not _spend_skill(side, SKILL_COST):
		return false
	var factor := skill_factor(id, side)
	if id == "ex":
		_cast_explosion(who, 400.0 * factor)
	elif id == "ls":
		_cast_smash(who, 320.0 * factor)
	elif id == "fz":
		_cast_freeze(who, 40.0 * factor)
	else:
		who.blaze = 8.0
		who.blaze_factor = factor
		_shout_skill("en")
	return true


func _shout_skill(id: String) -> void:
	Sfx.speak("say_" + id)
	Sfx.play("fx_" + id, 1.0, -2.0)


func _spend_skill(side: int, cost: float) -> bool:
	if side == 0:
		if player_value < cost:
			return false
		player_value -= cost
		return true
	if enemy_value < cost:
		return false
	enemy_value -= cost
	return true


func _toward_enemy(side: int) -> float:
	return 1.0 if side == 0 else -1.0


func _field_length() -> float:
	return maxf(1.0, vp.x)


func _ahead_box(who, portion: float) -> Vector2:
	var reach := _field_length() * portion
	var origin := float(who.position.x)
	var dest := origin + _toward_enemy(int(who.side)) * reach
	var x0 := clampf(minf(origin, dest), 0.0, vp.x)
	var x1 := clampf(maxf(origin, dest), 0.0, vp.x)
	return Vector2(x0, x1)


func _bodies() -> Array:
	var found: Array = []
	for unit in units:
		if is_instance_valid(unit):
			found.append(unit)
	if hero != null and is_instance_valid(hero):
		found.append(hero)
	if foe != null and is_instance_valid(foe):
		found.append(foe)
	return found


func _on_road(body, road: int) -> bool:
	if body == null or not is_instance_valid(body) or not body.alive:
		return false
	if is_berserker(body) or is_boss(body):
		return true
	if not ("lane" in body):
		return false
	return int(body.lane) == road


func _band_has(body, road: int, x0: float, x1: float) -> bool:
	if road >= 0:
		return _stands_in(body, road, x0, x1)
	if body == null or not is_instance_valid(body) or not body.alive:
		return false
	var x := float(body.position.x)
	return x >= x0 - 0.5 and x <= x1 + 0.5


func _hurt_band(caster, x0: float, x1: float, road: int, amount: float, foes: bool, allies: bool) -> void:
	var side := int(caster.side)
	for body in _bodies():
		if body == caster or not body.alive or not body.has_method("take_damage"):
			continue
		if not _band_has(body, road, x0, x1):
			continue
		var enemy := int(body.side) != side
		if enemy and not foes:
			continue
		if not enemy and not allies:
			continue
		body.take_damage(amount, true, "hero", 400.0)


func _root_allies(caster, road: int, seconds: float) -> void:
	var side := int(caster.side)
	for body in _bodies():
		if not body.alive or int(body.side) != side:
			continue
		if not _stands_in(body, road, -4.0, vp.x + 4.0):
			continue
		if not ("root_left" in body):
			continue
		body.root_left = maxf(float(body.root_left), seconds)
		fx_rooted = true


func _cast_explosion(who, amount: float) -> void:
	var span := _ahead_box(who, 0.25)
	_hurt_band(who, span.x, span.y, -1, amount, true, true)
	var burn := ember_damage()
	for road in lane_ys.size():
		var y := lane_y(road)
		lay_zone("fire", road, span.x, span.y, y, 3.0, burn, who)
		poof(Vector2((span.x + span.y) * 0.5, y), Color("ff7a2a"))
	_note_burst(span.x, span.y)
	_shout_skill("ex")


func _cast_smash(who, amount: float) -> void:
	var span := _ahead_box(who, 2.0 / 3.0)
	var road := int(who.lane)
	_hurt_band(who, span.x, span.y, road, amount, true, true)
	var near_x := span.x
	var far_x := span.y
	if _toward_enemy(int(who.side)) < 0.0:
		near_x = span.y
		far_x = span.x
	_note_slash(span.x, span.y, lane_y(road), near_x, far_x)
	_shout_skill("ls")


func _cast_freeze(who, amount: float) -> void:
	var road := int(who.lane)
	_hurt_band(who, 0.0, vp.x, road, amount, true, false)
	_root_allies(who, road, 3.0)
	_hold_cold(road)
	lay_zone("ice", road, 0.0, vp.x, lane_y(road), 6.0, 0.0, null, float(who.position.x))
	_shout_skill("fz")


func _hold_cold(road: int) -> void:
	for patch in cold_roads:
		if int(patch.get("lane", -1)) == road:
			patch["left"] = 6.0
			return
	cold_roads.append({"lane": road, "left": 6.0})


func splash_foes(at: Vector2, road: int, amount: float, side: int, radius: float = SPLASH_REACH) -> void:
	for body in _bodies():
		if not body.alive or not body.has_method("take_damage"):
			continue
		if int(body.side) == side:
			continue
		var wide := is_berserker(body) or is_boss(body)
		if not wide and int(body.lane) != road:
			continue
		if absf(float(body.position.x) - at.x) > radius:
			continue
		body.take_damage(amount, true, "hero", 400.0)


func chill_pace(body) -> float:
	if _standing_on_cold(body):
		return 0.5
	return 1.0


func _standing_on_cold(body) -> bool:
	if body == null or not is_instance_valid(body) or not body.alive:
		return false
	for patch in cold_roads:
		if _on_road(body, int(patch.get("lane", -1))):
			return true
	return false


func _tick_chill(delta: float) -> void:
	var write := 0
	for patch in cold_roads:
		var left := float(patch.get("left", 0.0)) - delta
		if left <= 0.0:
			continue
		patch["left"] = left
		cold_roads[write] = patch
		write += 1
	if write < cold_roads.size():
		cold_roads.resize(write)
	var any_root := false
	for body in _bodies():
		if not ("root_left" in body):
			continue
		var rooted := float(body.root_left) - delta
		if rooted < 0.0:
			rooted = 0.0
		body.root_left = rooted
		if rooted > 0.0 and body.alive:
			any_root = true
		if not body.alive:
			body.frost_time = 0.0
			continue
		if _standing_on_cold(body):
			var stood := float(body.frost_time) + delta
			if stood >= 3.0:
				body.root_left = maxf(float(body.root_left), 1.0)
				stood = 0.0
				any_root = true
			body.frost_time = stood
		else:
			body.frost_time = 0.0
	fx_rooted = any_root


func _note_burst(x0: float, x1: float) -> void:
	var top := lane_y(0) - 86.0
	var bottom := lane_y(maxi(lane_ys.size() - 1, 0)) + 36.0
	bursts.append({
		"x0": x0,
		"x1": x1,
		"y0": top,
		"y1": bottom,
		"left": 3.7,
		"life": 3.7,
		"age": 0.0,
	})
	queue_redraw()
	_redraw_fx()


func _note_slash(x0: float, x1: float, y: float, near_x: float, far_x: float) -> void:
	slash_fx.append({
		"x0": x0,
		"x1": x1,
		"y": y,
		"near": near_x,
		"far": far_x,
		"left": 1.05,
		"life": 1.05,
		"age": 0.0,
	})
	queue_redraw()
	_redraw_fx()


func _tick_slashes(delta: float) -> void:
	if slash_fx.is_empty():
		return
	var write := 0
	for mark in slash_fx:
		var left := float(mark.get("left", 0.0)) - delta
		if left <= 0.0:
			continue
		mark["left"] = left
		mark["age"] = float(mark.get("age", 0.0)) + delta
		slash_fx[write] = mark
		write += 1
	if write < slash_fx.size():
		slash_fx.resize(write)
	queue_redraw()


func _tick_bursts(delta: float) -> void:
	if bursts.is_empty():
		return
	var write := 0
	for mark in bursts:
		var left := float(mark.get("left", 0.0)) - delta
		if left <= 0.0:
			continue
		mark["left"] = left
		mark["age"] = float(mark.get("age", 0.0)) + delta
		bursts[write] = mark
		write += 1
	if write < bursts.size():
		bursts.resize(write)
	queue_redraw()


func lay_hazard(kind: String, road: int, at: Vector2, seconds: float, amount: float) -> void:
	var origin := at.x
	hazards.append({
		"kind": kind,
		"lane": road,
		"origin": origin,
		"x0": origin - 48.0,
		"x1": origin + 48.0,
		"y": at.y,
		"left": seconds,
		"age": 0.0,
		"tick": 0.25,
		"dmg": amount,
	})
	queue_redraw()


func lay_zone(kind: String, road: int, x0: float, x1: float, y: float, seconds: float, amount: float, spare, from_x: float = -1.0) -> void:
	var left_x := minf(x0, x1)
	var right_x := maxf(x0, x1)
	var source := (left_x + right_x) * 0.5
	if from_x >= 0.0:
		source = from_x
	hazards.append({
		"kind": kind,
		"lane": road,
		"origin": (left_x + right_x) * 0.5,
		"from_x": source,
		"x0": left_x,
		"x1": right_x,
		"y": y,
		"left": seconds,
		"age": 0.0,
		"tick": 0.25,
		"dmg": amount,
		"spare": spare,
	})
	queue_redraw()
	_redraw_fx()


func spread_road(road: int, toward_x: float, walls: Array) -> void:
	var stop_x := _gust_stop(toward_x, walls)
	for patch in hazards:
		if int(patch.get("lane", -1)) != road:
			continue
		var kind := str(patch.get("kind", ""))
		if kind != "fire" and kind != "ice":
			continue
		var origin := float(patch.get("origin", toward_x))
		var end_x := toward_x
		if toward_x < origin:
			if _lee_of_wall(origin, walls):
				continue
			end_x = stop_x
		patch["x0"] = minf(origin, end_x)
		patch["x1"] = maxf(origin, end_x)
		patch["left"] = float(patch.get("left", 0.0)) + 2.0
	queue_redraw()


func blow_road(road: int, attacker_side: int, amount: float, from_id: String, fan_x: float) -> void:
	var road_len := absf(enemy_front - player_front)
	var push := road_len * 0.25
	var moved_any := false
	var cover_side := 1 - attacker_side
	var walls := _gust_walls(road, cover_side)
	var bodies: Array = []
	for unit in units:
		if is_instance_valid(unit) and unit.alive:
			bodies.append(unit)
	if hero != null and is_instance_valid(hero) and hero.alive:
		bodies.append(hero)
	if foe != null and is_instance_valid(foe) and foe.alive:
		bodies.append(foe)
	for body in bodies:
		if not _on_fan_road(body, road) or sheltered(body):
			continue
		var bx := float(body.position.x)
		if bx >= fan_x - 0.01:
			continue
		# The gust only hits the other side. Allies are not pushed, hurt, or used to stretch fire.
		if int(body.side) == attacker_side:
			continue
		# A living berserker of that side stops the shove, the hit, and the fire stretch.
		if _gust_spares(body, walls):
			continue
		if body.has_method("take_damage"):
			body.take_damage(amount, true, from_id, 1200.0)
		if _shove_home(body, push):
			moved_any = true
	if moved_any:
		var home_x := player_front + 18.0
		if attacker_side == 0:
			home_x = enemy_front - 18.0
		spread_road(road, home_x, walls)
	var puff_y := lane_y(road)
	var reach := minf(push, maxf(1.0, fan_x - player_front))
	for puff_i in 4:
		var px := fan_x - reach * (float(puff_i) + 0.5) / 4.0
		poof(Vector2(px, puff_y), Color("d5e6f2"))
	Sfx.play("wind", 0.92, -6.0)
	float_text(Vector2(fan_x - reach * 0.5, puff_y - 28.0), "WIND", Color("d5e6f2"))


func _living_berserker(unit) -> bool:
	if unit == null or not is_instance_valid(unit) or not unit.alive:
		return false
	return _unit_id(unit) == "berserker"


func _berserker_blocks(unit, road: int) -> bool:
	if not _living_berserker(unit):
		return false
	# A real berserker is drawn from the top road to the bottom road, so he blocks every road.
	# A trial berserker keeps a normal body and stands on one road.
	if is_berserker(unit):
		return true
	if not ("lane" in unit):
		return false
	return int(unit.lane) == road


func _gust_walls(road: int, cover_side: int) -> Array:
	var found: Array = []
	for unit in units:
		if int(unit.side) != cover_side or not _berserker_blocks(unit, road):
			continue
		found.append(float(unit.position.x))
	return found


func _gust_spares(body, walls: Array) -> bool:
	if _living_berserker(body):
		return true
	var bx := float(body.position.x)
	for raw_wall in walls:
		var wall_x := float(raw_wall)
		if wall_x > bx + 0.01:
			return true
	return false


func _gust_stop(toward_x: float, walls: Array) -> float:
	var stop := toward_x
	for raw_wall in walls:
		var wall_x := float(raw_wall)
		if wall_x > toward_x:
			stop = maxf(stop, wall_x)
	return stop


func _lee_of_wall(origin: float, walls: Array) -> bool:
	for raw_wall in walls:
		var wall_x := float(raw_wall)
		if wall_x >= origin - 0.01:
			return true
	return false


func _on_fan_road(body, road: int) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if is_berserker(body) or is_boss(body):
		return true
	if not ("lane" in body):
		return false
	return int(body.lane) == road


func _shove_home(body, push: float) -> bool:
	var bx := float(body.position.x)
	var dest := bx
	if int(body.side) == 0:
		if bx <= player_front + 0.5:
			return false
		dest = maxf(player_front, bx - push)
		if dest >= bx - 0.5:
			return false
	else:
		if bx >= enemy_front - 0.5:
			return false
		dest = minf(enemy_front, bx + push)
		if dest <= bx + 0.5:
			return false
	if body.has_method("catch_blow"):
		body.catch_blow(dest)
	else:
		body.position.x = dest
	return true


func drop_smoke(at: Vector2, _lane: int) -> void:
	smokes.append({"x": at.x, "y": at.y, "left": 10.0})


func _tick_smokes(delta: float) -> void:
	if smokes.is_empty():
		return
	var write := 0
	for puff in smokes:
		var left := float(puff.get("left", 0.0)) - delta
		if left <= 0.0:
			continue
		puff["left"] = left
		smokes[write] = puff
		write += 1
	if write < smokes.size():
		smokes.resize(write)


func _hatch_lings(parent) -> void:
	var entry := Catalog.find_in(enemy_roster, "ling")
	if entry.is_empty():
		return
	var road := int(parent.lane)
	var at: Vector2 = parent.position
	for hatch_i in 3:
		if _count(1) >= MAX_SIDE:
			return
		var copy := _scaled_enemy(entry)
		copy["child"] = true
		copy["bounty"] = 1
		_spawn(copy, 1)
		var born = units[units.size() - 1]
		born.lane = road
		born.position = Vector2(at.x + float(hatch_i - 1) * 16.0, lane_y(road))


func _tick_hazards(delta: float) -> void:
	if hazards.is_empty():
		return
	var write := 0
	for patch in hazards:
		var left := float(patch.get("left", 0.0)) - delta
		if left <= 0.0:
			continue
		patch["left"] = left
		patch["age"] = float(patch.get("age", 0.0)) + delta
		var tick := float(patch.get("tick", 0.0)) - delta
		if tick <= 0.0:
			_scorch(patch)
			tick = 1.0
		patch["tick"] = tick
		hazards[write] = patch
		write += 1
	if write < hazards.size():
		hazards.resize(write)
	queue_redraw()


func _scorch(patch: Dictionary) -> void:
	var road := int(patch.get("lane", 0))
	var x0 := float(patch.get("x0", 0.0))
	var x1 := float(patch.get("x1", 0.0))
	var amount := float(patch.get("dmg", 0.0))
	var kind := str(patch.get("kind", "fire"))
	if amount <= 0.0:
		return
	var spare: Variant = patch.get("spare", null)
	var bodies: Array = units.duplicate()
	for body in bodies:
		if spare != null and body == spare:
			continue
		if _stands_in(body, road, x0, x1):
			body.take_damage(amount, true, kind, 0.0)
	if (spare == null or hero != spare) and _stands_in(hero, road, x0, x1):
		hero.take_damage(amount, true, kind)
	if (spare == null or foe != spare) and _stands_in(foe, road, x0, x1):
		foe.take_damage(amount, true, kind)


func _stands_in(body, road: int, x0: float, x1: float) -> bool:
	if body == null or not is_instance_valid(body) or not body.alive:
		return false
	var wide := is_berserker(body) or is_boss(body)
	if not wide and int(body.lane) != road:
		return false
	var x := float(body.position.x)
	return x >= x0 - 0.5 and x <= x1 + 0.5


func _redraw_fx() -> void:
	var hot := not bursts.is_empty() or not slash_fx.is_empty() or not hazards.is_empty() or fx_rooted
	if not hot:
		return
	if fx_glow != null:
		fx_glow.queue_redraw()
	if fx_body != null:
		fx_body.queue_redraw()
	if fx_marks != null:
		fx_marks.queue_redraw()


func _draw() -> void:
	if hazards.is_empty():
		return
	SkillFx.draw_ground(self, hazards)

