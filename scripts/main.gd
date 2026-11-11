extends Control

const UiSkin = preload("res://scripts/ui_skin.gd")
const Catalog = preload("res://scripts/unit_catalog.gd")
const Painter = preload("res://scripts/painter.gd")
const BattleScript = preload("res://scripts/battle.gd")
const SceneryScript = preload("res://scripts/scenery.gd")

const HOW_TO := "This is a side-view gate battle. Your clan gate is on the left. The cursed gate is on the right. Both have 1000 blood.

Choose 6 of the 11 soldiers. Value builds by itself. The buttons at the bottom left spend it. Each soldier has a cost and a call time before that soldier can be called again.

Soldiers only march forward. They stop to fight whatever is in front of them, and they do not turn around. You move the hero. Drag the road, or use WASD. Sword and Shoot are the two large buttons at the bottom right. J and K do the same. Number keys 1 through 6 call the six you brought, in the order you chose them.

If a runner slips past the line, you are the one who runs back. If your gate breaks, you lose. Break the cursed gate to win.

The cursed gate calls its own dead: walkers, runners, brutes, spitters, bombers, and later an oni."

var loadout: Array = []
var roster: Array = []
var card_panels: Dictionary = {}
var detail_label: Label
var count_label: Label
var start_button: Button
var last_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Engine.time_scale = 1.0
	roster = Catalog.player_roster()
	_bind_inputs()
	if _has_arg("--shot"):
		_shot_flow()
	elif _has_arg("--sim-cheap"):
		_start_battle(["sword", "archer", "shield", "lancer", "horse", "heal"], "sim")
	elif _has_arg("--sim"):
		_start_battle(["sword", "archer", "shield", "lancer", "berserker", "heal"], "sim")
	elif _has_arg("--smoke"):
		_start_battle(["sword", "archer", "shield", "lancer", "berserker", "heal"], "smoke")
	else:
		_show_menu()


func _has_arg(flag: String) -> bool:
	return flag in OS.get_cmdline_user_args() or flag in OS.get_cmdline_args()


func _shot_flow() -> void:
	_show_menu()
	for _i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://menu_shot.png")
	print("SAVED ", path, " err=", image.save_png(path))
	_start_battle(["sword", "archer", "shield", "saber", "berserker", "heal"], "shot")


func _bind_inputs() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("sword", [KEY_J])
	_bind("shoot", [KEY_K])
	_bind("pause", [KEY_ESCAPE])
	_bind("slot1", [KEY_1])
	_bind("slot2", [KEY_2])
	_bind("slot3", [KEY_3])
	_bind("slot4", [KEY_4])
	_bind("slot5", [KEY_5])
	_bind("slot6", [KEY_6])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	else:
		InputMap.action_erase_events(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func _clear_screens() -> void:
	var doomed: Array = []
	for child in get_children():
		if child is Control:
			doomed.append(child)
	for child in doomed:
		child.visible = false
		child.queue_free()


func _show_menu() -> void:
	_clear_screens()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(SceneryScript.new())
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.09, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -230
	panel.offset_bottom = 230
	panel.add_theme_stylebox_override("panel", UiSkin.panel(Color("f3e6c8"), Color("e6c36a"), 20, 4))
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := UiSkin.label("SAMURAI VS ZOMBIES", 40, Color("1c140e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UiSkin.label("Two gates. One road. Choose six.", 18, Color("6b3a32"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(_menu_button("Choose your six", Color("c44536"), _show_select))
	box.add_child(_menu_button("How to play", Color("e6c36a"), _show_how))
	box.add_child(_menu_button("Quit", Color("f3e6c8"), func() -> void: get_tree().quit()))


func _show_how() -> void:
	_clear_screens()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(SceneryScript.new())
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.09, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -280
	panel.offset_bottom = 280
	panel.add_theme_stylebox_override("panel", UiSkin.panel(Color("f3e6c8"), Color("e6c36a"), 18, 4))
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := UiSkin.label("How to play", 32, Color("1c140e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var body := UiSkin.label(HOW_TO, 16, Color("2c2118"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size = Vector2(760, 360)
	box.add_child(body)
	box.add_child(_menu_button("Back", Color("e6c36a"), _show_menu))


func _show_select() -> void:
	_clear_screens()
	card_panels.clear()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(SceneryScript.new())
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.09, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)
	var title := UiSkin.label("Choose 6 of 11", 32, Color("f3e6c8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tip := UiSkin.label("Sword and Shield hold the road. Archers and Lancers strike from behind. Bring one heavy hitter and one support.", 15, Color("f3e6c8"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(tip)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	for entry in roster:
		grid.add_child(_make_card(entry))
	count_label = UiSkin.label("", 16, Color("f3e6c8"))
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(count_label)
	detail_label = UiSkin.label("Tap a soldier to read what they do.", 15, Color("f7f1df"))
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(detail_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(_menu_button("Back", Color("f3e6c8"), _show_menu))
	start_button = _menu_button("Start battle", Color("c44536"), _begin_from_select)
	row.add_child(start_button)
	_refresh_cards()


func _make_card(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(286, 108)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := UiSkin.label(_card_text(entry), 14, Color("1c140e"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	var id := str(entry["id"])
	panel.gui_input.connect(_on_card_input.bind(id))
	card_panels[id] = panel
	return panel


func _card_text(entry: Dictionary) -> String:
	return "%s\n%d value · every %ss\n%d blood · %d damage\n%s" % [
		entry["name"],
		int(entry["cost"]),
		_num(float(entry["cooldown"])),
		int(entry["hp"]),
		int(entry["damage"]),
		_reach_line(entry),
	]


func _reach_line(entry: Dictionary) -> String:
	match str(entry["role"]):
		"ranged":
			return "Long reach · one target"
		"aoe":
			return "Short blast · hits everyone there"
		"suicide":
			return "Rushes, then blasts short range"
		"assassin":
			return "Blinks behind the first threat"
		"heal":
			return "Heals the weakest ally in front"
		"buff":
			return "Raises the strongest ally by 20%"
		_:
			if float(entry["reach"]) >= 140.0:
				return "Mid reach · one target"
			return "Short reach · one target"


func _num(value: float) -> String:
	if is_equal_approx(value, int(value)):
		return str(int(value))
	return "%.1f" % value


func _on_card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle(id)


func _toggle(id: String) -> void:
	Sfx.play("click", 1.0, -4.0)
	last_id = id
	if loadout.has(id):
		loadout.erase(id)
	elif loadout.size() < 6:
		loadout.append(id)
	_refresh_cards()


func _refresh_cards() -> void:
	for id in card_panels.keys():
		var selected: bool = loadout.has(id)
		var cloth: Color = Painter.look(str(id))["cloth"]
		var bg := Color("fff8ea") if selected else Color("f3e6c8")
		var border := Color("e6c36a") if selected else cloth.darkened(0.15)
		card_panels[id].add_theme_stylebox_override("panel", UiSkin.panel(bg, border, 12, 5 if selected else 3))
	if count_label != null:
		count_label.text = "Chosen %d / 6" % loadout.size()
		if loadout.size() == 6:
			count_label.text += "  ·  " + _loadout_names()
	if detail_label != null:
		if last_id == "":
			detail_label.text = "Tap a soldier to read what they do. Tap a chosen soldier again to remove them."
		else:
			var entry := Catalog.find_in(roster, last_id)
			detail_label.text = str(entry["detail"])
	if start_button != null:
		start_button.disabled = loadout.size() != 6


func _loadout_names() -> String:
	var names: PackedStringArray = PackedStringArray()
	for id in loadout:
		var entry := Catalog.find_in(roster, str(id))
		names.append(str(entry["short"]))
	return "  ".join(names)


func _begin_from_select() -> void:
	if loadout.size() != 6:
		return
	Sfx.play("click", 1.1, -4.0)
	_start_battle(loadout, "")


func _start_battle(chosen: Array, mode: String = "") -> void:
	loadout = chosen.duplicate()
	_clear_screens()
	for child in get_children():
		if child.get_script() == BattleScript:
			child.queue_free()
	var battle = BattleScript.new()
	add_child(battle)
	battle.start(loadout, mode)


func rematch() -> void:
	Engine.time_scale = 1.0
	_start_battle(loadout, "")


func change_squad() -> void:
	Engine.time_scale = 1.0
	for child in get_children():
		if child.get_script() == BattleScript:
			child.queue_free()
	_show_select()


func show_title() -> void:
	Engine.time_scale = 1.0
	for child in get_children():
		if child.get_script() == BattleScript:
			child.queue_free()
	_show_menu()


func _menu_button(text: String, color: Color, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 52)
	var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
	UiSkin.apply(button, color, 22, Color("1c140e") if lum > 0.62 else Color("f3e6c8"))
	button.pressed.connect(func() -> void:
		Sfx.play("click", 1.0, -6.0)
		action.call()
	)
	return button
