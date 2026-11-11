extends Control

const UiSkin = preload("res://scripts/ui_skin.gd")
const Catalog = preload("res://scripts/unit_catalog.gd")
const Painter = preload("res://scripts/painter.gd")
const BattleScript = preload("res://scripts/battle.gd")
const SceneryScript = preload("res://scripts/scenery.gd")
const Levels = preload("res://scripts/levels.gd")

const SAVE_PATH := "user://progress.cfg"

const HOW_TO := "This is a side-view gate battle. Your clan gate is on the left. The cursed gate is on the right. Both have 1000 blood.

Choose 6 of the 11 soldiers. Value builds by itself. The buttons at the bottom left spend it. Each soldier has a cost and a call time before that soldier can be called again.

There are three roads. Soldiers only march forward on the road where you called them, and they fight only that road. The Berserker hits every road at once, and enemies on every road can hit the Berserker. You move the hero onto any road. Drag, or use WASD. Sword and Shoot are the two large buttons at the bottom right. J and K do the same. Number keys 1 through 6 call the six you brought onto the hero's road.

If a runner slips past the line, you are the one who runs back. If your gate breaks, you lose. Break the cursed gate to win.

The cursed gate calls its own dead: walkers, runners, brutes, spitters, bombers, and later an oni.

Play lists ten roads. The first is open. Winning a road opens the next one. Your purse stays the same on every road. Theirs gets heavier.

Escape or Back returns to the title."

var loadout: Array = []
var roster: Array = []
var card_panels: Dictionary = {}
var detail_label: Label
var count_label: Label
var start_button: Button
var last_id: String = ""
var unlocked: int = 1
var chosen_level: int = 1
var screen: String = "menu"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Engine.time_scale = 1.0
	roster = Catalog.player_roster()
	_bind_inputs()
	_load_progress()
	if _has_arg("--layout"):
		_layout_check()
	elif _has_arg("--unlock-check"):
		_unlock_check()
	elif _has_arg("--shot"):
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


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if screen == "how" or screen == "levels":
		_show_menu()
		get_viewport().set_input_as_handled()
	elif screen == "select":
		_show_levels()
		get_viewport().set_input_as_handled()


func _show_menu() -> void:
	screen = "menu"
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
	var title := UiSkin.label("N-vs-Z", 40, Color("1c140e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UiSkin.label("Two gates. Three roads. Choose six.", 18, Color("6b3a32"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(_menu_button("Play", Color("c44536"), _show_levels))
	box.add_child(_menu_button("How to play", Color("e6c36a"), _show_how))
	box.add_child(_menu_button("Quit", Color("f3e6c8"), func() -> void: get_tree().quit()))


func _show_how() -> void:
	screen = "how"
	var box := _open_page("How to play")
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var body := UiSkin.label(HOW_TO, 16, Color("2c2118"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(body)
	scroll.resized.connect(_fit_scroll_label.bind(scroll, body))
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _show_levels() -> void:
	screen = "levels"
	var box := _open_page("Choose a road")
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for n in Levels.count():
		var rules: Dictionary = Levels.level(n + 1)
		var index := int(rules["index"])
		var open := index <= unlocked
		var text := "%d   %s" % [index, str(rules["name"])]
		if open:
			text += "\n" + str(rules["blurb"])
		else:
			text += "\nLocked"
		var button := _menu_button(text, Color("c44536") if open else Color("d9d0c3"), _pick_level.bind(index))
		button.disabled = not open
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(button)
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _pick_level(index: int) -> void:
	if index > unlocked or index < 1:
		return
	chosen_level = index
	_show_select()


func _open_page(heading: String) -> VBoxContainer:
	_clear_screens()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.add_child(SceneryScript.new())
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.09, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
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
	var title := UiSkin.label(heading, 32, Color("1c140e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	return box


func _fit_scroll_label(scroll: ScrollContainer, body: Label) -> void:
	var width := scroll.size.x - 16.0
	if width < 40.0:
		return
	if body.custom_minimum_size.x > 0.0 and absf(body.custom_minimum_size.x - width) < 24.0:
		return
	body.custom_minimum_size.x = width


func _show_select() -> void:
	screen = "select"
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
	var rules: Dictionary = Levels.level(chosen_level)
	var title := UiSkin.label("Level %d · %s" % [int(rules["index"]), str(rules["name"])], 32, Color("f3e6c8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var choose := UiSkin.label("Choose 6 of 11", 18, Color("f3e6c8"))
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(choose)
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
	row.add_child(_menu_button("Back", Color("f3e6c8"), _show_levels))
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
			if str(entry["id"]) == "berserker":
				return "Hits every road · every road hits back"
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


func _start_battle(chosen: Array, mode: String = "", level_index: int = 0) -> void:
	if level_index >= 1:
		chosen_level = level_index
	screen = "battle"
	loadout = chosen.duplicate()
	_clear_screens()
	for child in get_children():
		if child.get_script() == BattleScript:
			child.queue_free()
	var battle = BattleScript.new()
	add_child(battle)
	battle.start(loadout, mode, chosen_level)


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


func note_clear(level_index: int) -> void:
	var opened := mini(Levels.count(), level_index + 1)
	if opened <= unlocked:
		return
	unlocked = opened
	_save_progress()


func _load_progress() -> void:
	unlocked = 1
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, Levels.count())


func _save_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)


func _layout_check() -> void:
	get_window().size = Vector2i(1280, 720)
	for _i in 2:
		await get_tree().process_frame
	_show_menu()
	for _i in 3:
		await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var play := _button_named(self, "Play")
	var play_ok := false
	if play != null:
		var play_rect := play.get_global_rect()
		play_ok = play_rect.position.y >= 0.0 and play_rect.end.y <= vp.y + 1.0
		print("TITLE play=", play_rect, " vp=", vp, " ok=", play_ok)
	_show_how()
	for _i in 5:
		await get_tree().process_frame
	vp = get_viewport().get_visible_rect().size
	var how_back := _button_named(self, "Back")
	var how_ok := false
	if how_back != null:
		var how_rect := how_back.get_global_rect()
		how_ok = how_rect.position.y >= 0.0 and how_rect.end.y <= vp.y + 1.0 and how_rect.size.y > 20.0
		print("HOW back=", how_rect, " vp=", vp, " ok=", how_ok)
	var body_h := 0.0
	var scroll_h := 0.0
	var scroller := _find_scroll(self)
	if scroller != null and scroller.get_child_count() > 0:
		scroll_h = scroller.size.y
		var content := scroller.get_child(0)
		if content is Control:
			body_h = (content as Control).get_combined_minimum_size().y
	print("SCROLL content=", body_h, " view=", scroll_h)
	_show_levels()
	for _i in 5:
		await get_tree().process_frame
	vp = get_viewport().get_visible_rect().size
	var level_back := _button_named(self, "Back")
	var back_ok := false
	if level_back != null:
		var level_rect := level_back.get_global_rect()
		back_ok = level_rect.position.y >= 0.0 and level_rect.end.y <= vp.y + 1.0
		print("LEVELS back=", level_rect, " vp=", vp, " ok=", back_ok)
	var roads := 0
	var first_open := false
	var saw_night := false
	for node in _collect_buttons(self):
		var b: Button = node
		if b.text == "Back":
			continue
		roads += 1
		if b.text.find("First road") >= 0 and not b.disabled:
			first_open = true
		if b.text.find("Night march") >= 0:
			saw_night = true
		print("LEVEL ", b.disabled, " ", b.text.replace("\n", " / "))
	var win := play_ok and how_ok and back_ok and roads == 10 and first_open and saw_night and body_h > scroll_h and scroll_h > 40.0
	print("LAYOUT ", "OK" if win else "FAIL")
	get_tree().quit(0 if win else 1)


func _unlock_check() -> void:
	var first: Dictionary = Levels.level(1)
	var last: Dictionary = Levels.level(10)
	print("RULES ", float(first["income"]), " ", float(first["start"]), " ", float(last["income"]), " ", float(last["start"]), " ", float(last["oni_at"]), " ", bool(last["paired"]), " ", float(last["hp_mult"]))
	var before := unlocked
	note_clear(1)
	var after1 := unlocked
	note_clear(10)
	var after10 := unlocked
	note_clear(2)
	print("UNLOCK before=", before, " after1=", after1, " after10=", after10, " kept=", unlocked)
	var ok := after1 >= before and after1 >= mini(Levels.count(), maxi(before, 2)) and after10 == Levels.count() and unlocked == Levels.count()
	print("UNLOCK ", "OK" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)


func _find_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child in node.get_children():
		var found := _find_scroll(child)
		if found != null:
			return found
	return null


func _button_named(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found := _button_named(child, text)
		if found != null:
			return found
	return null


func _collect_buttons(node: Node) -> Array:
	var found: Array = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(_collect_buttons(child))
	return found


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
