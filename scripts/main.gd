extends Control

const UiSkin = preload("res://scripts/ui_skin.gd")
const Catalog = preload("res://scripts/unit_catalog.gd")
const Painter = preload("res://scripts/painter.gd")
const BattleScript = preload("res://scripts/battle.gd")
const SceneryScript = preload("res://scripts/scenery.gd")
const Levels = preload("res://scripts/levels.gd")
const Story = preload("res://scripts/story.gd")
const MangaScript = preload("res://scripts/manga.gd")

const SAVE_PATH := "user://progress.cfg"

const HOW_TO := "This is a side-view gate battle. Your clan gate is on the left. The cursed gate is on the right. Both have 2000 blood.

Fighters and the hero are born on the ground behind their own gate, so a new call is not standing in the fight. The other side cannot walk past a gate into the ground behind it. Someone standing there can still hit a fighter in front of that gate when the attack reaches. A blow that would have hit someone behind the gate hits the gate instead.

You start with one call, the sword ninja. A lesson ends when their gate breaks and nine of that monster come out, three on each road. Kill all nine and that soldier is yours. Until you know six, bring who you have. After that, choose 6. Value builds by itself. Hold the phone or iPad sideways. A stick at the bottom left moves the hero. The call buttons sit to the right of that stick, and Sword and Shoot sit at the bottom right, so the left thumb can stay on the stick.

There are three roads. Soldiers only march forward on the road where you called them, and they fight only that road. The Berserker stands across all three roads, hits every road at once, and enemies on every road can hit the Berserker. The assassin blinks past every other fighter and crosses roads to kill an archer, a leveling caster, or a healing caster. She cuts no one else. The first time a house falls to half blood, a wind helps that side: fighters of the other team who have crossed the middle are blown back to the center and lose half of the blood they still have. You move the hero onto any road with the stick, by dragging on the field, or with WASD. J and K match Sword and Shoot. Number keys call the soldiers you brought, in order, onto the hero's road.

If a runner slips past the line, you are the one who runs back. If your gate breaks, you lose. On a lesson, breaking their gate is not the end: nine of that monster walk out, and you win when those nine are dead. On level 40, a general walks out after their gate falls, and you win when the general dies. Every other level ends when their gate breaks.

When their gate is down to a quarter of its blood, they immediately gain their starting gold again. At half blood, on every level, they gain 100 value at once. From level 20 on they also gain 100 value when the gate is still at 70% blood.

The other gate calls its own fighters. On monster levels they are walkers, runners, a howler, a viper, a storm, a herald, a shell, a reaver, and later an oni. From level 41 those monsters are faster and harder, and Moth, Elder, Glut, and Brood join them. The howler hangs from the curse. Only an archer can hit it there. It swings once onto an archer, a leveling caster, or a healing caster, then stays on the road. The viper's bite holds one fighter still for 2 seconds, so they cannot move or strike, until a healing caster clears it. If two fighters are in front, it bites the one who hits harder and does not hold them. Most blows miss the viper. The storm waits 4 seconds, then lightning hits the fighter in front and four others on any road, and holds each for 1 second. The herald calls two other monsters every 3 seconds. The shell is slow, hits softly, and carries a great deal of blood. The reaver is a harder hitter for a moderate call. Moth flies on one road. A short weapon cannot hit it, and those fighters stop beneath it, though they still fight a closer fighter on the ground. Elder appears somewhere on the road, strikes whoever is nearest, friend or foe, and fades after 15 seconds. Many blows miss Elder. Glut is very slow. It eats the fighter in front, except a berserker or a flyer, then sits for 5 seconds and heals. Brood bites, and when it dies three quick Lings crawl out. On soldier levels they wear modern kit, and they hit harder than before. Knives match the sword soldier. The firebow is thin-blooded and hits hard, then leaves fire on that spot for 3 seconds. The fan is thin-blooded, barely hurts, and once every 4 seconds blows its whole road: fighters past the middle go back to the middle, and fighters who have not reached the middle go back to their castle. That gust also stretches any fire or ice on the road from where it started out to the castle and keeps it burning 2 seconds longer. The ward carries a great shield, a great deal of blood, and hits for 5. The javelin throws five long heavy shots, then fights up close with a short sword. The drum lifts three allies at once, the way a leveling caster lifts one. The crow waits 3 seconds, strikes the first enemy hard, then fights like the horse rider. From level 61, Smog, Buck, Scope, and Aria join them. Smog deals no damage and lays smoke where it walks. The smoke hides that stretch for 10 seconds. Buck fires a shotgun once a second, four times, then reloads for 2 seconds. Scope fires a long heavy shot every 3 seconds and has little blood. Aria sings, and the lift is half of a leveling caster, on every ally on every road at once. Level 40's general is an officer.

Play lists seventy levels. The first is open. Winning a level opens the next. Levels 1 to 20 are monsters, and that is where each soldier is learned. Levels 21 to 40 are human soldiers. Levels 41 to 60 are monsters again, and the new monsters begin. Levels 61 to 70 alternate, monster then soldier, starting with monsters. The new soldiers begin on the soldier turns. Your purse stays the same. Theirs gets heavier as the levels climb, and it eases a little when the soldiers first arrive.

Each level you open pays 100 diamonds. Clearing a level also pays coins. The base is 200 coins times the level. Three minutes or less doubles that, five minutes or less adds half, six minutes or less pays the base, and a longer clear pays half. Coins are not diamonds. Home has Upgrade. The hero and each soldier you have learned can be ranked 20 times. Each rank adds 5% of that character's blood and damage. Reach, cost, and speed stay the same.

Home is the night gate: Shop, Skin, Upgrade, the levels, and How to play are there, and the diamond count hangs by the lantern. During a fight, Home at the top returns you there.

The shop sells one new skin for the hero and one for each soldier. A skin costs 200 diamonds. Buying it does not put it on. Wear it from Skin, and Nothing puts the old clothes back.

On the website you can keep playing as a guest. That progress stays on the device. Sign in with Google and the levels you have opened, your diamonds, your coins, your ranks, and your skins stay with that account, so a phone, a tablet, and a computer can share them. The first sign-in asks for a name. Ranking lists signed-in players: a higher level cleared ranks above a lower one, and the same level ranks the shorter clear time first. A profile shows that name, the best tag, the hero, and a favourite character.

1 vs 1 is on the home screen. It opens after level 20, and until then the button wears a lock. It is two clans. Each side chooses 6 of the 11. Both have the same value, the same calls, the same roads, the same wind, and a hero. Before the search, choose Your ranks or Maximum. Your ranks uses the ranks saved on each account. Maximum locks both sides at rank 20. The host's choice is what the match uses, and the other ninja can leave. On this page, press Find opponent. The game looks for one other ninja and connects. The match runs until a gate falls. A 1 vs 1 pays no coins. You do not type an address or a code. On a computer build, Host opens port 3001 and the other ninja joins the address.

Escape or Back returns to the title."

var loadout: Array = []
var roster: Array = []
var card_panels: Dictionary = {}
var detail_label: Label
var count_label: Label
var start_button: Button
var last_id: String = ""
var unlocked: int = 1
var cleared: int = 0
var story_version: int = Story.VERSION
var story_seen: Dictionary = {}
var story_layer: CanvasLayer = null
var diamonds: int = 0
var coins: int = 0
var upgrades: Dictionary = {}
var last_clear_time: float = 0.0
var last_clear_coins: int = 0
var last_clear_band: String = ""
var saber_skin: bool = false
var saber_worn: String = "none"
var navy_settled: bool = false
var _navy_dirty: bool = false
var _navy_checked: bool = false
var _navy_was_settled: bool = false
var _navy_local_paid: bool = false
var _navy_grant_amount: int = 0
var sheet_owned: Dictionary = {}
var sheet_worn: Dictionary = {}
var diamond_paid: int = 1
var code_paid: bool = false
var code_lock: bool = false
var code_note: Label = null
var name_note: Label = null
var rank_cleared: int = 0
var rank_time: float = 0.0
var game_name: String = ""
var favorite: String = ""
var favorite_skin: String = ""
var best_rank: int = 0
var rank_rows: Array = []
var viewing: Dictionary = {}
var rank_wait: bool = false
var profile_from_rank: bool = false
var profile_own: bool = false
var was_cloud_signed: bool = false
const ROAD_DIAMONDS := 100
const SKIN_COST := 200
const VIP_CODE := "tomissogood0205"
const VIP_DIAMONDS := 100000000
const WEB_CODE_OPEN := """
(function(){
  document.body.style.touchAction = 'manipulation';
  var old = document.getElementById('nvsz-code');
  if (old) { old.focus(); return; }
  var canvas = document.querySelector('canvas');
  var rect = canvas ? canvas.getBoundingClientRect() : {left:0, top:0, width:window.innerWidth, height:window.innerHeight};
  var input = document.createElement('input');
  input.id = 'nvsz-code';
  input.type = 'text';
  input.maxLength = 32;
  input.autocomplete = 'off';
  input.autocapitalize = 'none';
  input.autocorrect = 'off';
  input.spellcheck = false;
  input.enterKeyHint = 'done';
  input.placeholder = 'Code';
  input.setAttribute('aria-label', 'Code');
  var css = input.style;
  css.position = 'fixed';
  css.zIndex = '40';
  css.boxSizing = 'border-box';
  css.left = (rect.left + rect.width * 0.12) + 'px';
  css.top = (rect.top + Math.max(88, Math.min(rect.height * 0.2, 150))) + 'px';
  css.width = (rect.width * 0.76) + 'px';
  css.height = '52px';
  css.fontSize = '16px';
  css.textAlign = 'center';
  css.color = '#1c140e';
  css.background = '#fff8ea';
  css.border = '3px solid #e6c36a';
  css.borderRadius = '12px';
  css.outline = 'none';
  css.padding = '8px 12px';
  css.touchAction = 'manipulation';
  window.__nvCode = '';
  window.__nvCodeDone = 0;
  input.addEventListener('input', function(){
    var clean = input.value.replace(/[^0-9A-Za-z]/g, '').slice(0, 32);
    if (clean !== input.value) input.value = clean;
    window.__nvCode = clean;
  });
  input.addEventListener('keydown', function(ev){
    if (ev.key === 'Enter') {
      window.__nvCode = input.value.replace(/[^0-9A-Za-z]/g, '');
      window.__nvCodeDone = 1;
      input.blur();
    }
  });
  document.body.appendChild(input);
  input.focus();
})();
"""
const WEB_CODE_CLOSE := """
(function(){
  var old = document.getElementById('nvsz-code');
  if (old) old.remove();
  document.body.style.touchAction = 'none';
  window.__nvCode = '';
  window.__nvCodeDone = 0;
})();
"""
const WEB_NAME_OPEN := """
(function(){
  document.body.style.touchAction = 'manipulation';
  function keep(raw) {
    var out = '';
    var text = String(raw || '');
    for (var i = 0; i < text.length; i++) {
      var c = text.charAt(i);
      var ok = (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
      if (ok && out.length < 16) out += c;
    }
    return out;
  }
  var old = document.getElementById('nvsz-name');
  if (old) { old.focus(); return; }
  var canvas = document.querySelector('canvas');
  var rect = canvas ? canvas.getBoundingClientRect() : {left:0, top:0, width:window.innerWidth, height:window.innerHeight};
  var input = document.createElement('input');
  input.id = 'nvsz-name';
  input.type = 'text';
  input.maxLength = 16;
  input.autocomplete = 'off';
  input.autocapitalize = 'none';
  input.autocorrect = 'off';
  input.spellcheck = false;
  input.enterKeyHint = 'done';
  input.placeholder = 'Name';
  input.setAttribute('aria-label', 'Name');
  var css = input.style;
  css.position = 'fixed';
  css.zIndex = '40';
  css.boxSizing = 'border-box';
  css.left = (rect.left + rect.width * 0.12) + 'px';
  css.top = (rect.top + Math.max(88, Math.min(rect.height * 0.2, 150))) + 'px';
  css.width = (rect.width * 0.76) + 'px';
  css.height = '52px';
  css.fontSize = '16px';
  css.textAlign = 'center';
  css.color = '#1c140e';
  css.background = '#fff8ea';
  css.border = '3px solid #e6c36a';
  css.borderRadius = '12px';
  css.outline = 'none';
  css.padding = '8px 12px';
  css.touchAction = 'manipulation';
  window.__nvName = '';
  window.__nvNameDone = 0;
  input.addEventListener('input', function(){
    var clean = keep(input.value);
    if (clean !== input.value) input.value = clean;
    window.__nvName = clean;
  });
  input.addEventListener('keydown', function(ev){
    if (ev.key === 'Enter') {
      window.__nvName = keep(input.value);
      window.__nvNameDone = 1;
      input.blur();
    }
  });
  document.body.appendChild(input);
  input.focus();
})();
"""
const WEB_NAME_CLOSE := """
(function(){
  var old = document.getElementById('nvsz-name');
  if (old) old.remove();
  document.body.style.touchAction = 'none';
  window.__nvName = '';
  window.__nvNameDone = 0;
})();
"""
var chosen_level: int = 1
var screen: String = "menu"
var layout_account: bool = false
var picking_duel: bool = false
var duel_choice: String = "own"
var duel_mode: String = "own"
var terms_known: bool = false
var duel_sent: bool = false
var duel_started: bool = false
var left_ids: Array = []
var right_ids: Array = []
var left_skin: Dictionary = {}
var right_skin: Dictionary = {}
var left_rank_pack: String = ""
var right_rank_pack: String = ""
var duel_left: Array = []
var duel_right: Array = []
var duel_skins: Dictionary = {}
var duel_status: Label
var duel_code: TextEdit
var duel_address: LineEdit


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Engine.time_scale = 1.0
	roster = Catalog.player_roster()
	_bind_inputs()
	_load_progress()
	_bind_net()
	_bind_cloud()
	if _has_arg("--layout"):
		_layout_check()
	elif _has_arg("--unlock-check"):
		_unlock_check()
	elif _has_arg("--win-check"):
		_win_check()
	elif _has_arg("--shot"):
		_shot_flow()
	elif _has_arg("--sim-cheap"):
		_start_battle(["sword", "archer", "shield", "lancer", "horse", "heal"], "sim")
	elif _has_arg("--sim"):
		_start_battle(["sword", "archer", "shield", "lancer", "berserker", "heal"], "sim")
	elif _has_arg("--duel-smoke"):
		_duel_probe()
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
	_drop_story()
	_close_web_code()
	_close_web_name()
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
	if screen == "how" or screen == "levels" or screen == "shop" or screen == "skin" or screen == "code":
		_show_menu()
		get_viewport().set_input_as_handled()
	elif screen == "duel":
		show_title()
		get_viewport().set_input_as_handled()
	elif screen == "select":
		if picking_duel:
			_show_duel()
		else:
			_show_levels()
		get_viewport().set_input_as_handled()


func _show_menu() -> void:
	if OS.has_feature("web") and Cloud.signed_in and not Cloud.profile_ready:
		_show_opening()
		return
	if _needs_name():
		_show_name()
		return
	screen = "menu"
	_clear_screens()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(SceneryScript.new())
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.22)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var yard := HomeYard.new()
	yard.diamonds = diamonds
	root.add_child(yard)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = 70
	panel.offset_right = 560
	panel.offset_top = -348
	panel.offset_bottom = 360
	panel.add_theme_stylebox_override("panel", UiSkin.panel(Color("1a1614"), Color("e6c36a"), 22, 4))
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := UiSkin.label("Home", 40, Color("f3e6c8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var night := UiSkin.label("The clan gate, after dark.", 16, Color("e7c07a"))
	night.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(night)
	var purse := UiSkin.label("◆  %d" % diamonds, 34, Color("f4e2b0"))
	purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(purse)
	var diamonds_name := UiSkin.label("diamonds", 14, Color("c4a574"))
	diamonds_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diamonds_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(diamonds_name)
	var coin_purse := UiSkin.label("Coins  %d" % coins, 16, Color("e7c07a"))
	coin_purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(coin_purse)
	if _wants_account_row():
		var account := UiSkin.label(_account_line(), 15, Color("c4a574"))
		account.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		account.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		account.mouse_filter = Control.MOUSE_FILTER_IGNORE
		account.custom_minimum_size = Vector2(420, 0)
		box.add_child(account)
		if Cloud.signed_in and game_name.length() >= 2:
			box.add_child(_home_pair(
				"Profile", Color("f3e6c8"), _show_own_profile,
				"Sign out", Color("8d6a45"), _on_account_button
			))
		else:
			var account_text := "Sign out" if Cloud.signed_in else "Sign in with Google"
			var account_color := Color("8d6a45") if Cloud.signed_in else Color("fff8ea")
			box.add_child(_menu_button(account_text, account_color, _on_account_button, 420, 18))
	var nxt := _next_index()
	if nxt >= 1:
		var road: Dictionary = Levels.level(nxt)
		box.add_child(_menu_button("Next level · %s" % str(road["name"]), Color("c44536"), next_level, 420))
	else:
		box.add_child(_menu_button("Play", Color("c44536"), _show_levels, 420))
	box.add_child(_duel_button())
	box.add_child(_home_pair(
		"Choose a level", Color("e6c36a"), _show_levels,
		"How to play", Color("f3e6c8"), _show_how
	))
	box.add_child(_home_pair(
		"Shop", Color("7ec8b3"), _show_shop,
		"Skin", Color("1e3f8f"), _show_skin
	))
	box.add_child(_menu_button("Upgrade", Color("e6c36a"), _show_upgrade, 420))
	if _wants_account_row():
		box.add_child(_home_pair(
			"Code", Color("c4a574"), _show_code,
			"Ranking", Color("e7c07a"), _show_rank
		))
	else:
		box.add_child(_menu_button("Code", Color("c4a574"), _show_code, 420, 18))
	var quit := _menu_button("Quit", Color("6b3a32"), func() -> void: get_tree().quit(), 180, 18)
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(quit)


func _home_pair(left_text: String, left_color: Color, left_call: Callable, right_text: String, right_color: Color, right_call: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var left := _menu_button(left_text, left_color, left_call, 204, 18)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := _menu_button(right_text, right_color, right_call, 204, 18)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(right)
	return row


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


func _skin_ids() -> Array:
	return ["hero", "sword", "archer", "shield", "saber", "lancer", "berserker", "horse", "suicide", "assassin", "heal", "level"]


func _known_skin(id: String) -> bool:
	return id in _skin_ids()


func _skin_title(id: String) -> String:
	match id:
		"sword":
			return "Sword"
		"archer":
			return "Archer"
		"shield":
			return "Shield"
		"saber":
			return "Saber"
		"lancer":
			return "Lancer"
		"berserker":
			return "Berserker"
		"horse":
			return "Horse"
		"suicide":
			return "Bomb"
		"assassin":
			return "Assassin"
		"heal":
			return "Heal"
		"level":
			return "Level"
		"hero":
			return "Hero"
		_:
			return id


func _skin_line(id: String) -> String:
	match id:
		"sword":
			return "Black hood, silver bands, and a silver sword."
		"archer":
			return "Green scarf, green eyes, bow, and a quiver."
		"shield":
			return "Brown coat and a round gold shield."
		"saber":
			return "Black hood, red scarf, and a dark curved sword."
		"lancer":
			return "Blue hood and a blue spear."
		"berserker":
			return "Red armor, bare arms, and a gold axe."
		"horse":
			return "Black rider, red saddle, and a gold sword."
		"suicide":
			return "Black hood, red sash, and a lit bomb."
		"assassin":
			return "Purple hood and a purple dagger."
		"heal":
			return "White robe and a teal crystal staff."
		"level":
			return "Gold hood and an open scroll."
		"hero":
			return "White hood, red scarf, and a silver sword."
		_:
			return ""


func _page_list(box: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 16)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return list


func _show_code() -> void:
	screen = "code"
	var box := _open_page("Code")
	var hint := UiSkin.label("Enter letters and numbers.", 16, Color("6b3a32"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	var note := UiSkin.label("", 18, Color("1c140e"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _web_touch():
		hint.text = "Tap the white box, type letters and numbers, then press Redeem."
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 64)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(gap)
		box.add_child(note)
		code_note = note
		var redeem_touch := _menu_button("Redeem", Color("c44536"), func() -> void: _apply_typed_code(_web_code_text(), note), 220, 18)
		redeem_touch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(redeem_touch)
		var again := _menu_button("Type", Color("e6c36a"), _open_web_code, 220, 18)
		again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(again)
		var back_touch := _menu_button("Back", Color("c4a574"), _show_menu)
		back_touch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(back_touch)
		_open_web_code()
		return
	var field := LineEdit.new()
	field.placeholder_text = "Code"
	field.max_length = 32
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.custom_minimum_size = Vector2(0, 52)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_font_size_override("font_size", 22)
	field.add_theme_color_override("font_color", Color("1c140e"))
	field.add_theme_color_override("font_placeholder_color", Color("8a6a4a"))
	field.add_theme_stylebox_override("normal", UiSkin.panel(Color("fff8ea"), Color("e6c36a"), 12, 3))
	field.add_theme_stylebox_override("focus", UiSkin.panel(Color("fff8ea"), Color("c44536"), 12, 3))
	field.text_changed.connect(_keep_code_text.bind(field))
	box.add_child(field)
	box.add_child(note)
	var redeem := _menu_button("Redeem", Color("c44536"), func() -> void: _redeem_code(field, note), 220, 18)
	redeem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(redeem)
	field.text_submitted.connect(func(_text: String) -> void: _redeem_code(field, note))
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	field.grab_focus()


func _process(_delta: float) -> void:
	if not OS.has_feature("web"):
		return
	if screen == "code" and code_note != null:
		var flag: Variant = JavaScriptBridge.eval("window.__nvCodeDone||0", true)
		if int(flag) == 1:
			JavaScriptBridge.eval("window.__nvCodeDone=0", true)
			_apply_typed_code(_web_code_text(), code_note)
	if screen == "name" and name_note != null:
		var named: Variant = JavaScriptBridge.eval("window.__nvNameDone||0", true)
		if int(named) == 1:
			JavaScriptBridge.eval("window.__nvNameDone=0", true)
			_commit_name(_web_name_text(), name_note)


func _web_touch() -> bool:
	if not OS.has_feature("web"):
		return false
	var touch: Variant = JavaScriptBridge.eval("((navigator.maxTouchPoints||0)>0||('ontouchstart' in window))?1:0", true)
	return int(touch) == 1


func _open_web_code() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(WEB_CODE_OPEN, true)


func _close_web_code() -> void:
	code_note = null
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(WEB_CODE_CLOSE, true)


func _open_web_name() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(WEB_NAME_OPEN, true)


func _close_web_name() -> void:
	name_note = null
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(WEB_NAME_CLOSE, true)


func _web_name_text() -> String:
	if not OS.has_feature("web"):
		return ""
	var raw: Variant = JavaScriptBridge.eval("(document.getElementById('nvsz-name')&&document.getElementById('nvsz-name').value)||window.__nvName||''", true)
	return str(raw)


func _web_code_text() -> String:
	if not OS.has_feature("web"):
		return ""
	var raw: Variant = JavaScriptBridge.eval("(document.getElementById('nvsz-code')&&document.getElementById('nvsz-code').value)||window.__nvCode||''", true)
	return str(raw)


func _keep_code_text(text: String, field: LineEdit) -> void:
	if code_lock:
		return
	var clean := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		var code := ch.unicode_at(0)
		var letter := (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		var digit := code >= 48 and code <= 57
		if letter or digit:
			clean += ch
	if clean == text:
		return
	code_lock = true
	field.text = clean
	field.caret_column = clean.length()
	code_lock = false


func _redeem_code(field: LineEdit, note: Label) -> void:
	if _apply_typed_code(field.text, note):
		field.text = ""


func _apply_typed_code(raw: String, note: Label) -> bool:
	var typed := raw.strip_edges().to_lower()
	if typed != VIP_CODE:
		note.text = "That code does not pay."
		note.add_theme_color_override("font_color", Color("8a2e28"))
		return false
	if code_paid:
		note.text = "That code is already used."
		note.add_theme_color_override("font_color", Color("8a2e28"))
		return false
	code_paid = true
	diamonds += VIP_DIAMONDS
	_save_progress()
	note.text = "◆  %d diamonds added." % VIP_DIAMONDS
	note.add_theme_color_override("font_color", Color("1c140e"))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("var el=document.getElementById('nvsz-code');if(el){el.value='';}window.__nvCode='';", true)
	return true


func _show_shop() -> void:
	screen = "shop"
	var box := _open_page("Shop")
	var purse := UiSkin.label("◆  %d diamonds" % diamonds, 22, Color("1c140e"))
	purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(purse)
	var pay := UiSkin.label("A new level pays %d diamonds. Each skin is %d. Wear it from the home porch." % [ROAD_DIAMONDS, SKIN_COST], 16, Color("6b3a32"))
	pay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pay)
	var list := _page_list(box)
	for id in _skin_ids():
		list.add_child(_shop_sheet(str(id)))
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _shop_sheet(id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var stage := SkinPreview.new()
	stage.kind = id
	stage.sheet = true
	stage.custom_minimum_size = Vector2(180, 150)
	row.add_child(stage)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 6)
	row.add_child(text)
	var name := UiSkin.label("%s skin" % _skin_title(id), 22, Color("1c140e"))
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(name)
	var blurb := UiSkin.label(_skin_line(id), 15, Color("2c2118"))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(blurb)
	var owned := bool(sheet_owned.get(id, false))
	var caption := "Owned"
	var color := Color("e6c36a")
	if not owned:
		caption = "Unlock for %d diamonds" % SKIN_COST
		color = Color("1e3f8f")
	var buy := _menu_button(caption, color, _buy_sheet.bind(id), 220, 16)
	buy.disabled = owned or diamonds < SKIN_COST
	text.add_child(buy)
	return row


func _buy_sheet(id: String) -> void:
	if not _known_skin(id) or bool(sheet_owned.get(id, false)) or diamonds < SKIN_COST:
		return
	diamonds -= SKIN_COST
	sheet_owned[id] = true
	_save_progress()
	_show_shop()


func _show_skin() -> void:
	screen = "skin"
	var box := _open_page("Skin")
	var purse := UiSkin.label("◆  %d diamonds" % diamonds, 22, Color("1c140e"))
	purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(purse)
	var pay := UiSkin.label("Wear a skin you own. Nothing puts the old clothes back.", 16, Color("6b3a32"))
	pay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pay)
	var list := _page_list(box)
	for id in _skin_ids():
		list.add_child(_skin_block(str(id)))
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _skin_block(id: String) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 8)
	var title := UiSkin.label(_skin_title(id), 22, Color("1c140e"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_child(row)
	row.add_child(_wear_column(id, false, false))
	row.add_child(_wear_column(id, true, false))
	return block


func _wear_column(id: String, sheet: bool, navy: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.custom_minimum_size = Vector2(210, 0)
	var stage := SkinPreview.new()
	stage.kind = id
	stage.sheet = sheet
	stage.navy = navy
	stage.custom_minimum_size = Vector2(210, 150)
	column.add_child(stage)
	var heading := "New skin" if sheet else "Nothing"
	var label := UiSkin.label(heading, 16, Color("1c140e"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	var owned := true
	var wearing := false
	if sheet:
		owned = bool(sheet_owned.get(id, false))
		wearing = bool(sheet_worn.get(id, false))
	else:
		wearing = not bool(sheet_worn.get(id, false))
	var caption := "Wearing this"
	var color := Color("e6c36a")
	if not owned:
		caption = "In the shop"
		color = Color("1e3f8f")
		wearing = false
	elif not wearing:
		caption = "Wear this"
		color = Color("1e3f8f") if sheet else Color("1a1216")
	var button := _menu_button(caption, color, _wear_choice.bind(id, sheet, navy), 200, 16)
	button.disabled = wearing or not owned
	column.add_child(button)
	return column


func _wear_choice(id: String, sheet: bool, navy: bool) -> void:
	if navy:
		return
	if sheet:
		if not bool(sheet_owned.get(id, false)):
			return
		sheet_worn[id] = true
		if id == "saber":
			saber_worn = "none"
	else:
		sheet_worn.erase(id)
		if id == "saber":
			saber_worn = "none"
	_apply_skins()
	_save_progress()
	_show_skin()


func _apply_skins() -> void:
	Painter.saber_navy = false
	Painter.sheet_on.clear()
	for key in sheet_worn.keys():
		Painter.sheet_on[str(key)] = true


func _show_levels() -> void:
	screen = "levels"
	var box := _open_page("Choose a level")
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
		button.custom_minimum_size = Vector2(0, 124)
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
	duel_sent = false
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
	var heading := "1 vs 1" if picking_duel else "Level %d · %s" % [int(rules["index"]), str(rules["name"])]
	var title := UiSkin.label(heading, 32, Color("f3e6c8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var choose := UiSkin.label("Choose 6" if _squad_need() == 6 else "Call who you have learned", 18, Color("f3e6c8"))
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(choose)
	var tip_line := _duel_terms_line() if picking_duel else "The sword holds the road. A lesson adds the soldier you just survived."
	var tip := UiSkin.label(tip_line, 15, Color("f3e6c8"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(tip)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	_prepare_loadout()
	for entry in _shown_roster():
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
	row.add_child(_menu_button("Back", Color("f3e6c8"), _leave_select))
	if picking_duel:
		row.add_child(_menu_button("Leave", Color("6b3a32"), show_title, 180, 18))
	var start_text := "Ready" if picking_duel else "Start battle"
	start_button = _menu_button(start_text, Color("c44536"), _begin_from_select)
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
				return "Stands across every road"
			return "Short blast · hits everyone there"
		"suicide":
			return "Rushes, then blasts short range"
		"assassin":
			return "Blinks past the line. Kills archers, healers, and level casters"
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
	if duel_sent:
		return
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
		if _squad_need() == 6:
			count_label.text = "Chosen %d / 6" % loadout.size()
		else:
			count_label.text = "Chosen %d" % loadout.size()
		if _squad_ok() and not loadout.is_empty():
			count_label.text += "  ·  " + _loadout_names()
	if detail_label != null:
		if last_id == "":
			detail_label.text = "Tap a soldier to read what they do. Tap a chosen soldier again to remove them."
		else:
			var entry := Catalog.find_in(roster, last_id)
			detail_label.text = str(entry["detail"])
	if start_button != null:
		start_button.disabled = not _squad_ok()
	if picking_duel and duel_sent and count_label != null:
		count_label.text = "Waiting for the other ninja."


func _loadout_names() -> String:
	var names: PackedStringArray = PackedStringArray()
	for id in loadout:
		var entry := Catalog.find_in(roster, str(id))
		names.append(str(entry["short"]))
	return "  ".join(names)


func _squad_need() -> int:
	if picking_duel:
		return 6
	return mini(6, Story.known_ids(cleared).size())


func _squad_ok() -> bool:
	if duel_sent:
		return false
	if _squad_need() >= 6:
		return loadout.size() == 6
	return loadout.size() >= 1


func _shown_roster() -> Array:
	var allowed: Array = Story.known_ids(cleared)
	var out: Array = []
	for entry in roster:
		if allowed.has(str(entry.get("id", ""))):
			out.append(entry)
	return out


func _prepare_loadout() -> void:
	var allowed: Array = Story.known_ids(cleared)
	var kept: Array = []
	for id in loadout:
		var key := str(id)
		if allowed.has(key) and not kept.has(key):
			kept.append(key)
	if not picking_duel and allowed.size() <= 6:
		loadout = allowed.duplicate()
		return
	loadout = kept
	if loadout.is_empty() and allowed.has("sword"):
		loadout.append("sword")


func _begin_from_select() -> void:
	if not _squad_ok():
		return
	Sfx.play("click", 1.1, -4.0)
	if picking_duel:
		_ready_duel()
		return
	_start_battle(loadout, "")


func _leave_select() -> void:
	if picking_duel:
		_show_duel()
		return
	_show_levels()


func _start_battle(chosen: Array, mode: String = "", level_index: int = 0) -> void:
	if level_index >= 1:
		chosen_level = level_index
	loadout = chosen.duplicate()
	if mode == "" and _begin_intro():
		return
	_launch_battle(mode)


func _launch_battle(mode: String) -> void:
	screen = "battle"
	_clear_screens()
	_drop_battle()
	var battle = BattleScript.new()
	add_child(battle)
	battle.rank_mode = "own"
	battle.rank_left = _rank_dictionary()
	battle.rank_right = {}
	battle.start(loadout, mode, chosen_level)


func _begin_intro() -> bool:
	var pages: Array = Story.intro_panels(chosen_level)
	var id := Story.intro_id(chosen_level)
	if pages.is_empty() or _story_seen(id):
		return false
	_clear_screens()
	_drop_battle()
	screen = "story"
	_play_manga(pages, func() -> void:
		_mark_story(id)
		_launch_battle("")
	)
	return true


func play_clear_story(level_index: int, after: Callable) -> bool:
	var pages: Array = Story.outro_panels(level_index)
	var id := Story.outro_id(level_index)
	if pages.is_empty() or _story_seen(id):
		return false
	screen = "story"
	_play_manga(pages, func() -> void:
		_mark_story(id)
		screen = "battle"
		after.call()
	)
	return true


func _play_manga(pages: Array, after: Callable) -> void:
	_drop_story()
	story_layer = CanvasLayer.new()
	story_layer.layer = 40
	add_child(story_layer)
	var manga = MangaScript.new()
	manga.set_anchors_preset(Control.PRESET_FULL_RECT)
	story_layer.add_child(manga)
	manga.done.connect(func() -> void:
		_drop_story()
		after.call()
	)
	manga.open(pages)


func _drop_story() -> void:
	Sfx.stop_mood()
	if story_layer != null and is_instance_valid(story_layer):
		story_layer.queue_free()
	story_layer = null


func _story_seen(id: String) -> bool:
	return id != "" and bool(story_seen.get(id, false))


func _mark_story(id: String) -> void:
	if id == "":
		return
	story_seen[id] = true
	_save_progress()


func rematch() -> void:
	Engine.time_scale = 1.0
	if Net.role != "":
		Net.announce_rematch()
		return
	_start_battle(loadout, "")


func change_squad() -> void:
	Engine.time_scale = 1.0
	if Net.role != "":
		Net.announce_reselect()
		return
	_drop_battle()
	_show_select()


func show_title() -> void:
	Engine.time_scale = 1.0
	_drop_battle()
	picking_duel = false
	duel_sent = false
	duel_started = false
	terms_known = false
	duel_mode = duel_choice
	if Net.role != "" or Net.live:
		Net.close_match()
	_show_menu()


func next_level() -> void:
	Engine.time_scale = 1.0
	var nxt := _next_index()
	if nxt < 1:
		show_title()
		return
	chosen_level = nxt
	if _squad_ok():
		_start_battle(loadout, "", nxt)
	else:
		_drop_battle()
		_show_select()


func _drop_battle() -> void:
	var doomed: Array = []
	for child in get_children():
		if child.get_script() == BattleScript:
			doomed.append(child)
	for child in doomed:
		remove_child(child)
		child.queue_free()


func _next_index() -> int:
	if cleared < 1 or cleared >= Levels.count():
		return 0
	return cleared + 1


func note_clear(level_index: int, elapsed: float = 0.0) -> void:
	var opened := mini(Levels.count(), level_index + 1)
	var changed := false
	if level_index > cleared:
		cleared = level_index
		changed = true
		if not picking_duel and Story.known_ids(cleared).size() <= 6:
			loadout = Story.known_ids(cleared).duplicate()
	if opened > unlocked:
		unlocked = opened
		changed = true
	if _take_road_pay():
		changed = true
	if _note_rank(level_index, elapsed):
		changed = true
	_grant_coins(level_index, elapsed)
	changed = true
	if changed:
		_save_progress()


func _take_road_pay() -> bool:
	if unlocked <= diamond_paid:
		return false
	diamonds += ROAD_DIAMONDS * (unlocked - diamond_paid)
	diamond_paid = unlocked
	return true


func _grant_coins(level_index: int, elapsed: float) -> void:
	var base := 200 * maxi(1, level_index)
	var paid := base
	var band := "Within 6 minutes: the base amount"
	if elapsed <= 180.0:
		paid = base * 2
		band = "Within 3 minutes: double"
	elif elapsed <= 300.0:
		paid = int(round(float(base) * 1.5))
		band = "Within 5 minutes: half again"
	elif elapsed > 360.0:
		paid = int(base / 2)
		band = "Over 6 minutes: half"
	last_clear_time = elapsed
	last_clear_band = band
	last_clear_coins = paid
	coins = mini(20000000, coins + paid)


func coin_line() -> String:
	if last_clear_coins <= 0:
		return ""
	return "Time %s. %s. +%d coins." % [_format_time(last_clear_time), last_clear_band, last_clear_coins]


func _rank_ids() -> Array:
	var ids: Array = ["hero"]
	for id in Story.known_ids(cleared):
		ids.append(str(id))
	return ids


func _rank_of(id: String) -> int:
	return clampi(int(upgrades.get(id, 1)), 1, 20)


func _rank_cost(rank: int) -> int:
	return 50 * rank * rank


func _pack_ranks() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for id in _rank_ids():
		var rank := _rank_of(str(id))
		if rank > 1:
			parts.append("%s:%d" % [str(id), rank])
	return ",".join(parts)


func _unpack_ranks(raw: String) -> Dictionary:
	var out: Dictionary = {}
	var known: Array = ["hero", "sword", "archer", "shield", "saber", "lancer", "berserker", "horse", "suicide", "assassin", "heal", "level"]
	for piece in raw.split(",", false):
		var bits: PackedStringArray = piece.split(":")
		if bits.size() != 2:
			continue
		var id := str(bits[0])
		if not known.has(id):
			continue
		out[id] = clampi(int(bits[1]), 1, 20)
	return out


func _trim_ranks() -> void:
	var allowed: Array = _rank_ids()
	var keep: Dictionary = {}
	for key in upgrades.keys():
		var id := str(key)
		if allowed.has(id):
			keep[id] = clampi(int(upgrades[key]), 1, 20)
	upgrades = keep


func _rank_dictionary() -> Dictionary:
	var out: Dictionary = {}
	for id in _rank_ids():
		var rank := _rank_of(str(id))
		if rank > 1:
			out[str(id)] = rank
	return out


func _show_upgrade() -> void:
	screen = "upgrade"
	var box := _open_page("Upgrade")
	var purse := UiSkin.label("Coins  %d" % coins, 22, Color("1c140e"))
	purse.name = "UpgradeCoins"
	purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(purse)
	var lead := UiSkin.label("Each rank adds 5% blood and damage. Rank 20 is the last. Every fighter pays the coins below.", 15, Color("6b3a32"))
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lead)
	var prices := GridContainer.new()
	prices.columns = 2
	prices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prices.add_theme_constant_override("h_separation", 24)
	prices.add_theme_constant_override("v_separation", 2)
	for rank in range(1, 20):
		var price := UiSkin.label("Rank %d · %d coins" % [rank + 1, _rank_cost(rank)], 15, Color("6b3a32"))
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prices.add_child(price)
	box.add_child(prices)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "UpgradeList"
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id in _rank_ids():
		list.add_child(_upgrade_row(str(id)))
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _upgrade_row(id: String) -> HBoxContainer:
	var who := "Hero"
	if id != "hero":
		var entry: Dictionary = Catalog.find_in(roster, id)
		who = str(entry.get("name", id))
	var row := HBoxContainer.new()
	row.set_meta("rank_id", id)
	row.set_meta("rank_who", who)
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var title := UiSkin.label("", 16, Color("1c140e"))
	title.name = "RankTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(title)
	var price := UiSkin.label("", 15, Color("8d2f28"))
	price.name = "RankPrice"
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(price)
	row.add_child(words)
	var button := _menu_button("Rank up", Color("c44536"), _buy_rank.bind(id), 168, 16)
	button.name = "RankPay"
	button.custom_minimum_size = Vector2(168, 48)
	row.add_child(button)
	_paint_upgrade_row(row)
	return row


func _paint_upgrade_row(row: HBoxContainer) -> void:
	var id := str(row.get_meta("rank_id", ""))
	var who := str(row.get_meta("rank_who", id))
	var rank := _rank_of(id)
	var title := row.find_child("RankTitle", true, false) as Label
	var price := row.find_child("RankPrice", true, false) as Label
	var button := row.find_child("RankPay", true, false) as Button
	if title != null:
		title.text = "%s    rank %d of 20" % [who, rank]
	var cost := 0
	var pay := "Rank 20. Nothing left to pay."
	if rank < 20:
		cost = _rank_cost(rank)
		pay = "Rank %d costs %d coins" % [rank + 1, cost]
	if price != null:
		price.text = pay
	if button == null:
		return
	button.disabled = rank >= 20 or coins < cost
	button.text = "Full" if rank >= 20 else "%d coins" % cost


func _paint_upgrade_page() -> bool:
	var purse := find_child("UpgradeCoins", true, false) as Label
	var list := find_child("UpgradeList", true, false) as VBoxContainer
	if purse == null or list == null:
		return false
	purse.text = "Coins  %d" % coins
	for child in list.get_children():
		if child is HBoxContainer:
			_paint_upgrade_row(child)
	return true


func _keep_upgrade_place() -> void:
	var scroller := _find_scroll(self)
	var kept := 0
	if scroller != null:
		kept = scroller.scroll_vertical
	var list := find_child("UpgradeList", true, false) as VBoxContainer
	if list != null and list.get_child_count() == _rank_ids().size() and _paint_upgrade_page():
		return
	_show_upgrade()
	var fresh := _find_scroll(self)
	if fresh == null or kept <= 0:
		return
	fresh.scroll_vertical = kept
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(fresh):
			fresh.scroll_vertical = kept
	, CONNECT_ONE_SHOT)


func _buy_rank(id: String) -> void:
	if not _rank_ids().has(id):
		return
	var rank := _rank_of(id)
	if rank >= 20:
		return
	var cost := _rank_cost(rank)
	if coins < cost:
		return
	coins -= cost
	upgrades[id] = rank + 1
	_save_progress()
	_keep_upgrade_place()


func _duel_terms_line() -> String:
	if not terms_known and Net.role == "guest":
		return "The host chooses your ranks or maximum. You can leave."
	if duel_mode == "max":
		return "Maximum. Both sides fight at rank 20. You can leave."
	return "Your ranks. Each side uses the ranks saved on that account. You can leave."


func _set_duel_choice(mode: String) -> void:
	duel_choice = "max" if mode == "max" else "own"
	_show_duel()


func _load_progress() -> void:
	unlocked = 1
	cleared = 0
	diamonds = 0
	coins = 0
	upgrades = {}
	saber_skin = false
	saber_worn = "none"
	sheet_owned = {}
	sheet_worn = {}
	diamond_paid = 1
	code_paid = false
	var migrated := false
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, Levels.count())
		var stored := int(cfg.get_value("progress", "cleared", -1))
		if stored < 0:
			cleared = maxi(0, unlocked - 1)
		else:
			cleared = clampi(stored, 0, Levels.count())
		diamonds = maxi(0, int(cfg.get_value("progress", "diamonds", 0)))
		coins = maxi(0, int(cfg.get_value("progress", "coins", 0)))
		upgrades = _unpack_ranks(str(cfg.get_value("progress", "upgrades", "")))
		saber_skin = bool(cfg.get_value("progress", "saber_skin", false))
		if cfg.has_section_key("progress", "saber_worn"):
			saber_worn = str(cfg.get_value("progress", "saber_worn", "none"))
		else:
			saber_worn = "navy" if saber_skin else "none"
		if cfg.has_section_key("progress", "diamond_paid"):
			diamond_paid = clampi(int(cfg.get_value("progress", "diamond_paid", 1)), 1, Levels.count())
		else:
			diamond_paid = 1
		code_paid = bool(cfg.get_value("progress", "code_paid", false))
		navy_settled = bool(cfg.get_value("progress", "navy_settled", false))
		sheet_owned = _unpack_keys(str(cfg.get_value("progress", "sheet_owned", "")))
		sheet_worn = _unpack_keys(str(cfg.get_value("progress", "sheet_worn", "")))
		rank_cleared = clampi(int(cfg.get_value("progress", "rank_cleared", 0)), 0, Levels.count())
		rank_time = float(cfg.get_value("progress", "rank_time", 0.0))
		game_name = _clean_name(str(cfg.get_value("progress", "game_name", "")))
		favorite = str(cfg.get_value("progress", "favorite", ""))
		favorite_skin = str(cfg.get_value("progress", "favorite_skin", ""))
		best_rank = clampi(int(cfg.get_value("progress", "best_rank", 0)), 0, 100000)
		var stored_story: int = int(cfg.get_value("progress", "story_version", 0))
		story_version = stored_story
		story_seen = _unpack_seen(str(cfg.get_value("progress", "story_seen", "")))
		if stored_story < Story.CAMPAIGN:
			unlocked = 1
			cleared = 0
			rank_cleared = 0
			rank_time = 0.0
		if stored_story < Story.VERSION:
			story_seen = {}
			story_version = Story.VERSION
			migrated = true
	_normalize_progress()
	var paid := _take_road_pay()
	_apply_skins()
	if paid or _navy_dirty or migrated:
		_save_progress()


func _normalize_progress() -> void:
	unlocked = clampi(unlocked, 1, Levels.count())
	cleared = clampi(cleared, 0, Levels.count())
	diamonds = clampi(diamonds, 0, 200000000)
	diamond_paid = clampi(diamond_paid, 1, Levels.count())
	if not _navy_checked:
		_navy_was_settled = navy_settled
		_navy_checked = true
	var own_saber_sheet := bool(sheet_owned.get("saber", false))
	var paid_navy := saber_skin
	if paid_navy or saber_worn == "navy":
		if paid_navy and not own_saber_sheet and not _navy_was_settled and _navy_grant_amount == 0:
			var before := diamonds
			diamonds = mini(200000000, diamonds + SKIN_COST)
			_navy_grant_amount = diamonds - before
		if paid_navy:
			_navy_local_paid = true
		saber_skin = false
		saber_worn = "none"
		navy_settled = true
		_navy_dirty = true
	elif saber_worn != "none":
		saber_worn = "none"
	var keep: Dictionary = {}
	for key in sheet_worn.keys():
		var id := str(key)
		if bool(sheet_owned.get(id, false)):
			keep[id] = true
	sheet_worn = keep
	saber_worn = "none"
	if favorite != "" and not Story.known_ids(cleared).has(favorite):
		favorite = ""
		favorite_skin = ""
	coins = clampi(coins, 0, 20000000)
	_trim_ranks()


func _save_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "cleared", cleared)
	cfg.set_value("progress", "diamonds", diamonds)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "upgrades", _pack_ranks())
	cfg.set_value("progress", "saber_skin", saber_skin)
	cfg.set_value("progress", "saber_worn", saber_worn)
	cfg.set_value("progress", "sheet_owned", _pack_keys(sheet_owned))
	cfg.set_value("progress", "sheet_worn", _pack_keys(sheet_worn))
	cfg.set_value("progress", "diamond_paid", diamond_paid)
	cfg.set_value("progress", "code_paid", code_paid)
	cfg.set_value("progress", "navy_settled", navy_settled)
	cfg.set_value("progress", "rank_cleared", rank_cleared)
	cfg.set_value("progress", "rank_time", rank_time)
	cfg.set_value("progress", "game_name", game_name)
	cfg.set_value("progress", "favorite", favorite)
	cfg.set_value("progress", "favorite_skin", favorite_skin)
	cfg.set_value("progress", "best_rank", best_rank)
	cfg.set_value("progress", "story_version", story_version)
	cfg.set_value("progress", "story_seen", _pack_seen(story_seen))
	cfg.save(SAVE_PATH)
	Cloud.push(_snapshot())
	_push_profile()


func _snapshot() -> Dictionary:
	return {
		"unlocked": unlocked,
		"cleared": cleared,
		"diamonds": diamonds,
		"coins": coins,
		"upgrades": _pack_ranks(),
		"saber_skin": saber_skin,
		"saber_worn": saber_worn,
		"sheet_owned": _pack_keys(sheet_owned),
		"sheet_worn": _pack_keys(sheet_worn),
		"diamond_paid": diamond_paid,
		"code_paid": code_paid,
		"story_version": story_version,
		"story_seen": _pack_seen(story_seen),
	}


func _wants_account_row() -> bool:
	if layout_account:
		return true
	return OS.has_feature("web") and Cloud.configured()


func _account_line() -> String:
	if Cloud.last_error != "":
		return Cloud.last_error
	if Cloud.signed_in:
		var who := game_name
		if who == "":
			who = Cloud.display_name
		if who == "":
			who = Cloud.email
		if who == "":
			who = "Google"
		return "Saved to Google · " + who
	return "Playing as guest. Progress stays on this device."


func _on_account_button() -> void:
	if Cloud.signed_in:
		Cloud.sign_out()
	else:
		Cloud.sign_in()


func _bind_cloud() -> void:
	if Cloud.account_changed.is_connected(_on_account):
		return
	Cloud.account_changed.connect(_on_account)
	Cloud.save_arrived.connect(_on_cloud_save)
	Cloud.profile_arrived.connect(_on_profile)
	Cloud.board_arrived.connect(_on_board)


func _on_account() -> void:
	var signed_out := was_cloud_signed and not Cloud.signed_in
	was_cloud_signed = Cloud.signed_in
	if signed_out:
		game_name = ""
		favorite = ""
		favorite_skin = ""
		best_rank = 0
		_save_progress()
		if profile_own and screen == "profile":
			profile_own = false
			_show_menu()
			return
	if screen == "rank":
		rank_wait = false
		_paint_rank(false)
		return
	if screen == "menu" or screen == "name" or screen == "opening":
		_show_menu()


func _on_cloud_save(data: Dictionary) -> void:
	_merge_from_cloud(data)


func _flag(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return int(value) != 0
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1"


func _whole(value: Variant, fallback: int) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if str(value).is_valid_int():
		return int(str(value))
	return fallback


func _merge_from_cloud(data: Dictionary) -> void:
	if data.is_empty() or not data.has("diamonds"):
		_save_progress()
		return
	var cloud_version := _whole(data.get("story_version", 0), 0)
	if cloud_version >= Story.CAMPAIGN:
		unlocked = maxi(unlocked, clampi(_whole(data.get("unlocked", 1), 1), 1, Levels.count()))
		cleared = maxi(cleared, clampi(_whole(data.get("cleared", 0), 0), 0, Levels.count()))
	if cloud_version >= Story.VERSION:
		for key in _unpack_seen(str(data.get("story_seen", ""))).keys():
			story_seen[str(key)] = true
	diamond_paid = maxi(diamond_paid, clampi(_whole(data.get("diamond_paid", 1), 1), 1, Levels.count()))
	story_version = Story.VERSION
	var cloud_diamonds := clampi(_whole(data.get("diamonds", 0), 0), 0, 200000000)
	var base_diamonds := diamonds - _navy_grant_amount
	if base_diamonds < 0:
		base_diamonds = 0
	diamonds = maxi(base_diamonds, cloud_diamonds)
	coins = maxi(coins, clampi(_whole(data.get("coins", 0), 0), 0, 20000000))
	var cloud_ranks := _unpack_ranks(str(data.get("upgrades", "")))
	for key in cloud_ranks.keys():
		var rank_id := str(key)
		upgrades[rank_id] = maxi(_rank_of(rank_id), int(cloud_ranks[rank_id]))
	code_paid = code_paid or _flag(data.get("code_paid", false))
	var cloud_owned := _unpack_keys(str(data.get("sheet_owned", "")))
	for key in cloud_owned.keys():
		sheet_owned[str(key)] = true
	var cloud_paid := _flag(data.get("saber_skin", false))
	var own_sheet := bool(sheet_owned.get("saber", false))
	if not _navy_was_settled and not own_sheet:
		if cloud_paid or (_navy_local_paid and cloud_diamonds <= base_diamonds):
			diamonds = mini(200000000, diamonds + SKIN_COST)
	if cloud_paid or _navy_local_paid or str(data.get("saber_worn", "none")) == "navy":
		navy_settled = true
		_navy_dirty = true
	saber_skin = false
	saber_worn = "none"
	_navy_was_settled = true
	_navy_grant_amount = 0
	var cloud_worn := _unpack_keys(str(data.get("sheet_worn", "")))
	if not cloud_worn.is_empty():
		sheet_worn = cloud_worn
	_normalize_progress()
	_take_road_pay()
	_apply_skins()
	_save_progress()
	if screen == "menu":
		_show_menu()
	elif screen == "shop":
		_show_shop()
	elif screen == "skin":
		_show_skin()
	elif screen == "upgrade":
		_keep_upgrade_place()


func _needs_name() -> bool:
	return OS.has_feature("web") and Cloud.signed_in and Cloud.profile_ready and game_name.length() < 2


func _show_opening() -> void:
	screen = "opening"
	var box := _open_page("Your account")
	var waiting := "Opening your account."
	if Cloud.last_error != "":
		waiting = Cloud.last_error
	var hint := UiSkin.label(waiting, 18, Color("1c140e"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	var guest := _menu_button("Play as guest", Color("f3e6c8"), _play_guest, 420, 18)
	guest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(guest)


func _play_guest() -> void:
	Cloud.sign_out()


func _show_name() -> void:
	screen = "name"
	var box := _open_page("Your name")
	var hint := UiSkin.label("Choose a name of 2 to 16 letters and numbers.", 16, Color("6b3a32"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	var note := UiSkin.label("", 18, Color("1c140e"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(note)
	name_note = note
	if _web_touch():
		hint.text = "Tap the white box, type 2 to 16 letters and numbers, then press Set name."
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 64)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(gap)
		var web_set := _menu_button("Set name", Color("e6c36a"), func() -> void:
			_commit_name(_web_name_text(), note)
		, 420, 18)
		web_set.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(web_set)
		var again := _menu_button("Type", Color("f3e6c8"), _open_web_name, 420, 18)
		again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(again)
	else:
		var field := LineEdit.new()
		field.placeholder_text = "Name"
		field.max_length = 16
		field.custom_minimum_size = Vector2(420, 52)
		field.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		field.text_changed.connect(func(text: String) -> void:
			_keep_name_text(text, field)
		)
		field.text_submitted.connect(func(text: String) -> void:
			_commit_name(text, note)
		)
		box.add_child(field)
		var desk_set := _menu_button("Set name", Color("e6c36a"), func() -> void:
			_commit_name(field.text, note)
		, 420, 18)
		desk_set.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(desk_set)
	var guest := _menu_button("Play as guest", Color("8d6a45"), _play_guest, 420, 18)
	guest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(guest)
	if _web_touch():
		_open_web_name()


func _keep_name_text(text: String, field: LineEdit) -> void:
	var clean := _clean_name(text)
	if clean == text:
		return
	field.text = clean
	field.caret_column = clean.length()


func _commit_name(raw: String, note: Label) -> void:
	var clean := _clean_name(raw)
	if clean.length() < 2:
		note.text = "Use 2 to 16 letters and numbers."
		return
	game_name = clean
	if cleared > rank_cleared:
		rank_cleared = cleared
		rank_time = 0.0
	_save_progress()
	_close_web_name()
	_show_menu()


func _clean_name(raw: String) -> String:
	var clean := ""
	var text := raw.strip_edges()
	for i in text.length():
		var ch := text.substr(i, 1)
		var code := ch.unicode_at(0)
		var letter := (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		var digit := code >= 48 and code <= 57
		if (letter or digit) and clean.length() < 16:
			clean += ch
	return clean


func _show_rank() -> void:
	rank_wait = true
	profile_own = false
	_paint_rank(true)


func _paint_rank(fetch: bool) -> void:
	screen = "rank"
	var box := _open_page("Ranking")
	var hint := UiSkin.label("A higher level ranks first. The same level ranks the shorter time first.", 16, Color("6b3a32"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	var list := _page_list(box)
	if rank_rows.is_empty():
		var message := "No names yet."
		if rank_wait or fetch:
			message = "Loading the ranking."
		elif Cloud.last_error != "":
			message = Cloud.last_error
		var empty := UiSkin.label(message, 18, Color("1c140e"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		list.add_child(empty)
	else:
		for item in rank_rows:
			if not (item is Dictionary):
				continue
			var row: Dictionary = item
			var place := _whole(row.get("place", 0), 0)
			var tag := _rank_tag(_whole(row.get("best_rank", 0), 0))
			var line := "%d   %s" % [place, str(row.get("name", ""))]
			if tag != "":
				line += "   " + tag
			line += "\n%s   %s" % [_road_name(_whole(row.get("cleared", 0), 0)), _format_time(_seconds(row.get("clear_time", 0.0)))]
			var entry := _menu_button(line, Color("f3e6c8"), _open_ranked.bind(row.duplicate(true)), 420, 16)
			entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			entry.clip_text = false
			entry.custom_minimum_size = Vector2(0, 78)
			entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_child(entry)
	var back := _menu_button("Back", Color("e6c36a"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	if fetch:
		Cloud.load_board()


func _open_ranked(row: Dictionary) -> void:
	profile_from_rank = true
	var own := Cloud.signed_in and str(row.get("uid", "")) == Cloud.uid()
	if own and favorite == "":
		_show_picker()
		return
	_show_profile(row, true)


func _show_own_profile() -> void:
	profile_from_rank = false
	if favorite == "":
		_show_picker()
		return
	_show_profile(_self_view(), false)


func _show_profile(row: Dictionary, from_rank: bool) -> void:
	profile_from_rank = from_rank
	var own := Cloud.signed_in and str(row.get("uid", "")) == Cloud.uid()
	if own:
		if favorite == "":
			_show_picker()
			return
		row = _self_view()
	profile_own = own
	viewing = row.duplicate(true)
	screen = "profile"
	var title := _clean_name(str(viewing.get("name", "")))
	if title == "":
		title = "Profile"
	if own:
		title += "   ·   Hero rank %d" % _rank_of("hero")
	var box := _open_page(title)
	var tag := _rank_tag(_whole(viewing.get("best_rank", 0), 0))
	var place := _whole(viewing.get("place", 0), 0)
	var line := tag
	if place > 0:
		var place_text: String = "Place %d" % place
		line = place_text if line == "" else line + "   " + place_text
	elif line == "":
		line = "Not ranked yet"
	var rank_label := UiSkin.label(line, 22, Color("6b3a32"))
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rank_label)
	var road := UiSkin.label(_road_name(_whole(viewing.get("cleared", 0), 0)) + "   " + _format_time(_seconds(viewing.get("clear_time", 0.0))), 16, Color("1c140e"))
	road.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	road.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(road)
	var portraits := HBoxContainer.new()
	portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	portraits.add_theme_constant_override("separation", 18)
	portraits.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(portraits)
	_add_portrait(portraits, "hero", bool(viewing.get("hero_sheet", false)), false, "Hero")
	var fav := str(viewing.get("favorite", ""))
	if _roster_known(fav):
		var skin := _draw_skin(fav, str(viewing.get("favorite_skin", "")), own)
		_add_portrait(portraits, fav, skin == "sheet", skin == "navy", "Favourite")
	else:
		var missing := UiSkin.label("No favourite yet.", 16, Color("6b3a32"))
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portraits.add_child(missing)
	if own:
		var change := _menu_button("Change favourite", Color("e6c36a"), _show_picker, 420, 18)
		change.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(change)
	var back := _menu_button("Back", Color("f3e6c8"), _back_profile)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _back_profile() -> void:
	profile_own = false
	if profile_from_rank:
		_show_rank()
	else:
		_show_menu()


func _show_picker() -> void:
	screen = "profile"
	profile_own = true
	var box := _open_page("Favourite")
	var hint := UiSkin.label("Choose a favourite. If you own its skin, the profile wears it.", 16, Color("6b3a32"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	var list := _page_list(box)
	for entry in roster:
		if not (entry is Dictionary):
			continue
		var unit: Dictionary = entry
		var id := str(unit.get("id", ""))
		if not _roster_known(id):
			continue
		list.add_child(_menu_button(str(unit.get("short", id)), Color("e6c36a"), _pick_favorite.bind(id), 420, 18))
	var back := _menu_button("Back", Color("f3e6c8"), _back_from_picker)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)


func _back_from_picker() -> void:
	if favorite != "":
		_show_profile(_self_view(), profile_from_rank)
		return
	profile_own = false
	if profile_from_rank:
		_show_rank()
	else:
		_show_menu()


func _pick_favorite(id: String) -> void:
	if not _roster_known(id):
		return
	favorite = id
	favorite_skin = _favorite_skin_for(id)
	_save_progress()
	_show_profile(_self_view(), profile_from_rank)


func _add_portrait(parent: Node, kind: String, sheet: bool, navy: bool, caption: String) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	var title := UiSkin.label(caption, 18, Color("6b3a32"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)
	var pic := Portrait.new()
	pic.kind = kind
	pic.sheet = sheet
	pic.navy = navy
	pic.custom_minimum_size = Vector2(180, 280)
	pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(pic)
	parent.add_child(column)


func _self_view() -> Dictionary:
	var place := 0
	for item in rank_rows:
		if item is Dictionary and str(item.get("uid", "")) == Cloud.uid():
			place = _whole(item.get("place", 0), 0)
			break
	return {
		"uid": Cloud.uid(),
		"name": game_name,
		"cleared": rank_cleared,
		"clear_time": rank_time,
		"favorite": favorite,
		"favorite_skin": favorite_skin,
		"hero_sheet": bool(sheet_worn.get("hero", false)),
		"saber_worn": "none",
		"best_rank": best_rank,
		"place": place,
	}


func _on_board(rows: Array) -> void:
	rank_wait = false
	var kept: Array = []
	for item in rows:
		if not (item is Dictionary):
			continue
		var source: Dictionary = item
		var named := _clean_name(str(source.get("name", "")))
		if named.length() < 2:
			continue
		source["name"] = named
		kept.append(source)
	kept.sort_custom(_rank_before)
	var raised := false
	for i in kept.size():
		var placed: Dictionary = kept[i]
		var place := i + 1
		placed["place"] = place
		if Cloud.signed_in and str(placed.get("uid", "")) == Cloud.uid():
			var stored := clampi(_whole(placed.get("best_rank", 0), 0), 0, 100000)
			var history := stored
			if best_rank > 0 and (history == 0 or best_rank < history):
				history = best_rank
			if history == 0 or place < history:
				best_rank = place
				raised = true
			else:
				best_rank = history
			placed["best_rank"] = best_rank
		kept[i] = placed
	rank_rows = kept
	if raised:
		_save_progress()
	if screen == "rank":
		_paint_rank(false)
	elif screen == "profile" and profile_own:
		_show_profile(_self_view(), profile_from_rank)


func _rank_before(a: Variant, b: Variant) -> bool:
	var left: Dictionary = {}
	var right: Dictionary = {}
	if a is Dictionary:
		left = a
	if b is Dictionary:
		right = b
	var left_level := _whole(left.get("cleared", 0), 0)
	var right_level := _whole(right.get("cleared", 0), 0)
	if left_level != right_level:
		return left_level > right_level
	var left_time := _seconds(left.get("clear_time", 0.0))
	var right_time := _seconds(right.get("clear_time", 0.0))
	var left_real := left_time > 0.0
	var right_real := right_time > 0.0
	if left_real != right_real:
		return left_real
	if left_real and right_real and not is_equal_approx(left_time, right_time):
		return left_time < right_time
	return str(left.get("name", "")) < str(right.get("name", ""))


func _on_profile(data: Dictionary) -> void:
	_apply_profile(data)
	if screen == "opening" or screen == "name" or screen == "menu":
		_show_menu()


func _apply_profile(data: Dictionary) -> void:
	var cloud_name := _clean_name(str(data.get("name", "")))
	var cloud_level := clampi(_whole(data.get("cleared", 0), 0), 0, Levels.count())
	var cloud_time := _seconds(data.get("clear_time", 0.0))
	var profile_version := _whole(data.get("story_version", 0), 0)
	if cloud_name.length() >= 2:
		game_name = cloud_name
		if profile_version >= Story.CAMPAIGN and _better_record(cloud_level, cloud_time, rank_cleared, rank_time):
			rank_cleared = cloud_level
			rank_time = cloud_time
		var fav := str(data.get("favorite", ""))
		favorite = fav if Story.known_ids(cleared).has(fav) else ""
		favorite_skin = _draw_skin(favorite, str(data.get("favorite_skin", "")), false)
		var cloud_best := clampi(_whole(data.get("best_rank", 0), 0), 0, 100000)
		if cloud_best > 0 and (best_rank == 0 or cloud_best < best_rank):
			best_rank = cloud_best
	else:
		game_name = ""
		favorite = ""
		favorite_skin = ""
		best_rank = 0
	if cleared > rank_cleared:
		rank_cleared = cleared
		rank_time = 0.0
	_save_progress()


func _push_profile() -> void:
	if game_name.length() < 2:
		return
	Cloud.push_profile(_profile_body())


func _profile_body() -> Dictionary:
	var skin := _draw_skin(favorite, favorite_skin, false)
	return {
		"name": game_name,
		"cleared": rank_cleared,
		"clear_time": rank_time,
		"favorite": favorite if _roster_known(favorite) else "",
		"favorite_skin": skin,
		"hero_sheet": bool(sheet_worn.get("hero", false)),
		"saber_worn": "none",
		"best_rank": best_rank,
		"story_version": Story.VERSION,
	}


func _note_rank(level_index: int, elapsed: float) -> bool:
	var used := clampf(elapsed, 0.0, 86400.0)
	if level_index > rank_cleared:
		rank_cleared = level_index
		rank_time = used
		return true
	if level_index == rank_cleared and used > 0.0 and (rank_time <= 0.0 or used < rank_time):
		rank_time = used
		return true
	return false


func _better_record(level_a: int, time_a: float, level_b: int, time_b: float) -> bool:
	if level_a != level_b:
		return level_a > level_b
	if time_a > 0.0 and time_b <= 0.0:
		return true
	if time_a > 0.0 and time_b > 0.0 and time_a < time_b:
		return true
	return false


func _roster_known(id: String) -> bool:
	if id == "":
		return false
	for entry in roster:
		if entry is Dictionary and str(entry.get("id", "")) == id:
			return true
	return false


func _favorite_skin_for(id: String) -> String:
	if bool(sheet_owned.get(id, false)):
		return "sheet"
	return ""


func _draw_skin(id: String, stored: String, own: bool) -> String:
	var skin := stored
	if skin != "sheet":
		skin = ""
	if id == "":
		return ""
	if own and skin == "sheet" and not bool(sheet_owned.get(id, false)):
		skin = ""
	return skin


func _rank_tag(rank: int) -> String:
	if rank == 1:
		return "No.1"
	if rank == 2:
		return "No.2"
	if rank == 3:
		return "No.3"
	if rank >= 4 and rank <= 5:
		return "Top 5"
	if rank >= 6 and rank <= 10:
		return "Top 10"
	return ""


func _road_name(level_index: int) -> String:
	if level_index < 1:
		return "No level yet"
	var row: Dictionary = Levels.level(level_index)
	return str(row.get("name", "Road %d" % level_index))


func _format_time(seconds: float) -> String:
	if seconds <= 0.0:
		return "no time"
	var whole := int(seconds)
	var mins := int(whole / 60.0)
	var secs := whole % 60
	if mins > 0:
		return "%d:%02d" % [mins, secs]
	return "%d s" % secs


func _seconds(value: Variant) -> float:
	if value is int or value is float:
		return clampf(float(value), 0.0, 86400.0)
	if str(value).is_valid_float():
		return clampf(float(str(value)), 0.0, 86400.0)
	return 0.0


func _pack_seen(bag: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key in bag.keys():
		var id := str(key).strip_edges()
		if id != "":
			parts.append(id)
	return ",".join(parts)


func _unpack_seen(text: String) -> Dictionary:
	var bag: Dictionary = {}
	if text == "":
		return bag
	for part in text.split(",", false):
		var id := str(part).strip_edges()
		if id != "":
			bag[id] = true
	return bag


func _pack_keys(bag: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key in bag.keys():
		var id := str(key)
		if _known_skin(id):
			parts.append(id)
	return ",".join(parts)


func _unpack_keys(text: String) -> Dictionary:
	var bag: Dictionary = {}
	if text == "":
		return bag
	var parts: PackedStringArray = text.split(",", false)
	for part in parts:
		var id := str(part).strip_edges()
		if _known_skin(id):
			bag[id] = true
	return bag


func _bind_net() -> void:
	if Net.lobby_changed.is_connected(_on_lobby):
		return
	Net.lobby_changed.connect(_on_lobby)
	Net.linked.connect(_on_duel_linked)
	Net.dropped.connect(_on_duel_dropped)
	Net.loadout_got.connect(_on_loadout_got)
	Net.terms_got.connect(_on_terms)
	Net.begin_match.connect(_on_begin_match)
	Net.reselect_got.connect(_on_reselect)
	Net.rematch_got.connect(_on_rematch)


func _duel_probe() -> void:
	var six: Array = ["sword", "archer", "shield", "lancer", "berserker", "heal"]
	var other: Array = ["saber", "horse", "assassin", "suicide", "level", "sword"]
	screen = "battle"
	_clear_screens()
	var battle = BattleScript.new()
	battle.duel_probe = true
	add_child(battle)
	battle.begin_duel(six, other, 0, true, {})


func _show_duel() -> void:
	if not Story.duel_open(cleared):
		_show_menu()
		return
	screen = "duel"
	_clear_screens()
	duel_status = null
	duel_code = null
	duel_address = null
	var box := _open_page("1 vs 1")
	var lead_text := "Both sides are the clan. Each ninja chooses 6. Value, calls, roads, wind, and the hero are the same on both sides."
	if OS.has_feature("web"):
		lead_text = "Press Find opponent. The game looks for one other ninja and connects. Each ninja then chooses 6."
	var lead := UiSkin.label(lead_text, 16, Color("3a2a22"))
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lead)
	duel_status = UiSkin.label(Net.status, 16, Color("1c140e"))
	duel_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	duel_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(duel_status)
	if Net.live:
		var live_terms := UiSkin.label(_duel_terms_line(), 16, Color("6b3a32"))
		live_terms.autowrap_mode = TextServer.AUTOWRAP_WORD
		live_terms.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(live_terms)
		box.add_child(_menu_button("Choose 6", Color("c44536"), _show_select, 420))
		box.add_child(_menu_button("Leave", Color("6b3a32"), show_title, 220, 18))
		return
	var own_text := "Your ranks  ·  on" if duel_choice != "max" else "Your ranks"
	var max_text := "Maximum  ·  on" if duel_choice == "max" else "Maximum"
	box.add_child(_menu_button(own_text, Color("e6c36a"), _set_duel_choice.bind("own"), 420))
	box.add_child(_menu_button(max_text, Color("c44536"), _set_duel_choice.bind("max"), 420))
	if OS.has_feature("web"):
		box.add_child(_menu_button("Find opponent", Color("7d9a6a"), Net.find_opponent, 420))
	else:
		box.add_child(_menu_button("Host", Color("7d9a6a"), Net.host_match, 420))
		duel_address = LineEdit.new()
		duel_address.placeholder_text = "127.0.0.1"
		duel_address.text = "127.0.0.1"
		duel_address.custom_minimum_size = Vector2(0, 48)
		duel_address.alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(duel_address)
		box.add_child(_menu_button("Join", Color("c44536"), _join_duel, 420))
	box.add_child(_menu_button("Back", Color("f3e6c8"), show_title, 220, 18))


func _join_duel() -> void:
	var ip := "127.0.0.1"
	if duel_address != null:
		ip = duel_address.text
	Net.join_address(ip)


func _on_lobby() -> void:
	if screen != "duel" or duel_status == null or not is_instance_valid(duel_status):
		return
	duel_status.text = Net.status
	if duel_code != null and is_instance_valid(duel_code) and Net.code != "" and duel_code.text != Net.code:
		duel_code.text = Net.code
		duel_code.release_focus()


func _on_duel_linked() -> void:
	picking_duel = true
	duel_started = false
	duel_sent = false
	left_ids = []
	right_ids = []
	left_rank_pack = ""
	right_rank_pack = ""
	if Net.role == "host":
		duel_mode = duel_choice
		terms_known = true
		Net.announce_terms(duel_mode)
	else:
		duel_mode = "own"
		terms_known = false
	_show_select()


func _on_duel_dropped() -> void:
	_drop_battle()
	picking_duel = false
	duel_started = false
	duel_sent = false
	_show_duel()


func _ready_duel() -> void:
	duel_sent = true
	if start_button != null:
		start_button.disabled = true
	if count_label != null:
		count_label.text = "Waiting for the other ninja."
	Net.announce_loadout(loadout.duplicate(), _worn_ids(), saber_worn == "navy", _pack_ranks(), duel_mode)


func _worn_ids() -> Array:
	var out: Array = []
	for key in sheet_worn.keys():
		if bool(sheet_worn[key]):
			out.append(str(key))
	return out


func _on_terms(mode: String) -> void:
	duel_mode = "max" if mode == "max" else "own"
	terms_known = true
	if screen == "select" and picking_duel:
		_show_select()


func _on_loadout_got(side: int, ids: Array, sheets: Array, navy: bool, ranks: String, mode: String) -> void:
	if Net.role != "host" or duel_started:
		return
	var skin := {"sheets": sheets.duplicate(), "navy": navy}
	if side == 0:
		left_ids = ids.duplicate()
		left_skin = skin
		left_rank_pack = ranks
		if mode == "max" or mode == "own":
			duel_mode = mode
	else:
		right_ids = ids.duplicate()
		right_skin = skin
		right_rank_pack = ranks
	if left_ids.size() == 6 and right_ids.size() == 6:
		duel_started = true
		Net.announce_start(left_ids, right_ids, {
			"left": left_skin,
			"right": right_skin,
			"mode": duel_mode,
			"left_ranks": left_rank_pack,
			"right_ranks": right_rank_pack,
		})


func _on_begin_match(left: Array, right: Array, skins: Dictionary) -> void:
	duel_left = left.duplicate()
	duel_right = right.duplicate()
	duel_skins = skins.duplicate(true)
	_launch_duel()


func _launch_duel() -> void:
	var side := 0 if Net.role != "guest" else 1
	var local_ids: Array = duel_left if side == 0 else duel_right
	var other: Array = duel_right if side == 0 else duel_left
	screen = "battle"
	loadout = local_ids.duplicate()
	_clear_screens()
	_drop_battle()
	var battle = BattleScript.new()
	add_child(battle)
	battle.begin_duel(local_ids, other, side, side == 0, duel_skins)


func _on_reselect() -> void:
	Engine.time_scale = 1.0
	duel_started = false
	duel_sent = false
	left_ids = []
	right_ids = []
	left_rank_pack = ""
	right_rank_pack = ""
	_drop_battle()
	picking_duel = true
	_show_select()


func _on_rematch() -> void:
	Engine.time_scale = 1.0
	if duel_left.size() != 6 or duel_right.size() != 6:
		return
	_launch_duel()


func _layout_check() -> void:
	layout_account = true
	get_window().size = Vector2i(1280, 720)
	for _i in 2:
		await get_tree().process_frame
	_show_menu()
	for _i in 3:
		await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var play := _button_named(self, "Play")
	var play_ok := false
	var quit_b := _button_named(self, "Quit")
	var duel_b := _button_named(self, "1 vs 1")
	var quit_ok := false
	var duel_ok := false
	if quit_b != null:
		var quit_rect := quit_b.get_global_rect()
		quit_ok = quit_rect.position.y >= 0.0 and quit_rect.end.y <= vp.y + 1.0
		print("TITLE quit=", quit_rect, " ok=", quit_ok)
	if duel_b != null:
		var duel_rect := duel_b.get_global_rect()
		var duel_locked := not Story.duel_open(cleared)
		duel_ok = duel_rect.position.y >= 0.0 and duel_rect.end.y <= vp.y + 1.0
		if duel_locked:
			duel_ok = duel_ok and bool(duel_b.get_meta("duel_locked", false))
		print("TITLE duel=", duel_rect, " locked=", duel_locked, " ok=", duel_ok)
	else:
		print("TITLE duel missing ok=false")
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
	var saw_end := false
	var last_name := str(Levels.level(Levels.count()).get("name", ""))
	for node in _collect_buttons(self):
		var b: Button = node
		if b.text == "Back":
			continue
		roads += 1
		if b.text.find("First road") >= 0 and not b.disabled:
			first_open = true
		if last_name != "" and b.text.find(last_name) >= 0:
			saw_end = true
		if roads <= Levels.count():
			var road_rules: Dictionary = Levels.level(roads)
			print("LEVEL ", b.disabled, " ", b.text.replace("\n", " / "), " +", float(road_rules["income"]))
	var win := play_ok and quit_ok and duel_ok and how_ok and back_ok and roads == Levels.count() and first_open and saw_end and body_h > scroll_h and scroll_h > 40.0
	print("LAYOUT ", "OK" if win else "FAIL")
	get_tree().quit(0 if win else 1)


func _unlock_check() -> void:
	var first: Dictionary = Levels.level(1)
	var last: Dictionary = Levels.level(Levels.count())
	print("RULES ", float(first["income"]), " ", float(first["start"]), " ", float(last["income"]), " ", float(last["start"]), " ", float(last["oni_at"]), " ", bool(last["paired"]), " ", float(last["hp_mult"]))
	var before := unlocked
	note_clear(1)
	var after1 := unlocked
	note_clear(Levels.count())
	var after_last := unlocked
	note_clear(2)
	print("UNLOCK before=", before, " after1=", after1, " after_last=", after_last, " kept=", unlocked)
	var ok := after1 >= before and after1 >= mini(Levels.count(), maxi(before, 2)) and after_last == Levels.count() and unlocked == Levels.count()
	print("UNLOCK ", "OK" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)


func _win_check() -> void:
	get_window().size = Vector2i(1280, 720)
	for _i in 2:
		await get_tree().process_frame
	unlocked = 5
	cleared = 4
	chosen_level = 5
	_mark_story(Story.intro_id(5))
	_mark_story(Story.intro_id(6))
	_start_battle(["sword", "archer", "shield", "lancer", "berserker", "heal"], "", 5)
	await get_tree().process_frame
	var battle := _battle_node()
	if battle == null:
		print("WIN FAIL no battle")
		get_tree().quit(1)
		return
	battle.call("on_gate_fallen", 1)
	for _i in 4:
		await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var nxt := _button_named(self, "Next level")
	var onscreen := false
	if nxt != null:
		var rect := nxt.get_global_rect()
		onscreen = rect.position.y >= 0.0 and rect.end.y <= vp.y + 1.0 and rect.size.y > 20.0
		print("WIN next=", rect, " vp=", vp, " cleared=", cleared, " unlocked=", unlocked)
	var saved := cleared == 5 and unlocked == 6 and onscreen
	next_level()
	for _i in 3:
		await get_tree().process_frame
	var again := _battle_node()
	var moved_level := -1
	if again != null:
		moved_level = int(again.get("level_no"))
	var moved := moved_level == 6
	print("WIN moved=", moved, " level=", moved_level)
	show_title()
	for _i in 4:
		await get_tree().process_frame
	vp = get_viewport().get_visible_rect().size
	var title_btn := _button_named(self, "Next level · The ridge")
	var title_on := false
	if title_btn != null:
		var title_rect := title_btn.get_global_rect()
		title_on = title_rect.position.y >= 0.0 and title_rect.end.y <= vp.y + 1.0 and title_rect.size.y > 20.0
		print("TITLE next=", title_rect, " vp=", vp)
	var ok := saved and moved and title_on
	print("WIN ", "OK" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)


func _battle_node() -> Node:
	for child in get_children():
		if child.get_script() == BattleScript:
			return child
	return null


func _find_scroll(node: Node) -> ScrollContainer:
	if node.is_queued_for_deletion():
		return null
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


func _duel_button() -> Button:
	var open := Story.duel_open(cleared)
	var button := LockButton.new()
	button.text = "1 vs 1"
	button.locked = not open
	button.custom_minimum_size = Vector2(420, 52)
	var color := Color("7d9a6a") if open else Color("d9d0c3")
	var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
	UiSkin.apply(button, color, 22, Color("1c140e") if lum > 0.62 else Color("f3e6c8"))
	if not open:
		button.set_meta("duel_locked", true)
	button.pressed.connect(func() -> void:
		Sfx.play("click", 1.0, -6.0)
		if open:
			_show_duel()
	)
	return button


func _menu_button(text: String, color: Color, action: Callable, wide: float = 280.0, font_px: int = 22) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(wide, 52)
	var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
	UiSkin.apply(button, color, font_px, Color("1c140e") if lum > 0.62 else Color("f3e6c8"))
	button.pressed.connect(func() -> void:
		Sfx.play("click", 1.0, -6.0)
		action.call()
	)
	return button


class LockButton:
	extends Button

	var locked: bool = false

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if not locked:
			return
		var ink := Color("1c140e")
		var cx := size.x - 36.0
		var cy := size.y * 0.5 + 3.0
		draw_arc(Vector2(cx, cy - 6.0), 7.0, PI, TAU, 14, ink, 3.0, true)
		draw_rect(Rect2(cx - 9.0, cy - 2.0, 18.0, 14.0), ink, true)
		draw_circle(Vector2(cx, cy + 4.0), 2.0, Color("d9d0c3"))


class Portrait:
	extends Control

	const Painter = preload("res://scripts/painter.gd")

	var kind: String = "sword"
	var sheet: bool = false
	var navy: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var head_y := -34.0
		var foot_y := 24.0
		var span_x := 78.0
		if kind == "horse":
			head_y = -42.0
			foot_y = 26.0
			span_x = 104.0
		var span_y := foot_y - head_y
		var zoom := minf((size.x - 12.0) / span_x, (size.y - 8.0) / span_y)
		zoom = clampf(zoom, 3.2, 8.2)
		var origin_y := 4.0 - head_y * zoom
		if origin_y + foot_y * zoom > size.y - 4.0:
			origin_y = size.y - 4.0 - foot_y * zoom
		var origin := Vector2(size.x * 0.46, origin_y)
		var look: Dictionary = Painter.look_as(kind, sheet, false)
		draw_set_transform(origin, 0.0, Vector2(zoom, zoom))
		Painter.paint_local(self, look, {
			"phase": "model",
			"t": 0.0,
			"clock": 0.0,
			"flash": 0.0,
			"beat": 0,
		})
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class HomeYard:
	extends Node2D

	var diamonds: int = 0

	func _draw() -> void:
		var size := get_viewport_rect().size
		var foot := Vector2(250.0, size.y * 0.64)
		draw_circle(foot + Vector2(8.0, -70.0), 120.0, Color(1.0, 0.62, 0.28, 0.16))
		draw_ellipse(foot + Vector2(10.0, 18.0), 130.0, 18.0, Color(0, 0, 0, 0.35))
		var wall := Rect2(foot.x - 92.0, foot.y - 150.0, 184.0, 150.0)
		draw_rect(wall, Color("3a2c24"))
		draw_rect(Rect2(wall.position.x, wall.position.y, 16.0, wall.size.y), Color("2a1e18"))
		draw_rect(Rect2(wall.end.x - 16.0, wall.position.y, 16.0, wall.size.y), Color("2a1e18"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(foot.x - 118.0, foot.y - 142.0),
			Vector2(foot.x, foot.y - 214.0),
			Vector2(foot.x + 118.0, foot.y - 142.0),
		]), Color("1a1218"))
		draw_line(Vector2(foot.x - 118.0, foot.y - 142.0), Vector2(foot.x, foot.y - 214.0), Color("c44536"), 6.0)
		draw_line(Vector2(foot.x, foot.y - 214.0), Vector2(foot.x + 118.0, foot.y - 142.0), Color("c44536"), 6.0)
		_window(foot + Vector2(-48.0, -96.0))
		_window(foot + Vector2(48.0, -96.0))
		draw_rect(Rect2(foot.x - 22.0, foot.y - 78.0, 44.0, 78.0), Color("4a3024"))
		draw_circle(foot + Vector2(12.0, -40.0), 3.0, Color("e6c36a"))
		var lamp := foot + Vector2(108.0, -118.0)
		draw_line(Vector2(foot.x + 70.0, foot.y - 150.0), lamp, Color("2a1e18"), 3.0)
		draw_circle(lamp, 16.0, Color("f0b429"))
		draw_circle(lamp, 7.0, Color("fff1c9"))
		draw_circle(lamp, 28.0, Color(1.0, 0.75, 0.35, 0.18))
		var plaque := Rect2(foot.x - 54.0, foot.y - 28.0, 108.0, 36.0)
		draw_rect(plaque, Color("1a1614"))
		draw_rect(Rect2(plaque.position.x, plaque.position.y, plaque.size.x, 3.0), Color("e6c36a"))
		var font := ThemeDB.fallback_font
		draw_string(font, plaque.position + Vector2(10.0, 25.0), "◆  %d" % diamonds, HORIZONTAL_ALIGNMENT_LEFT, 90.0, 18, Color("f4e2b0"))

	func _window(at: Vector2) -> void:
		draw_rect(Rect2(at.x - 16.0, at.y - 18.0, 32.0, 36.0), Color("2a1e18"))
		draw_rect(Rect2(at.x - 12.0, at.y - 14.0, 24.0, 28.0), Color("f0b429"))
		draw_rect(Rect2(at.x - 8.0, at.y - 10.0, 16.0, 12.0), Color("fff1c9"))
		draw_line(at + Vector2(0.0, -14.0), at + Vector2(0.0, 14.0), Color("2a1e18"), 2.0)


class SkinPreview:
	extends Control

	const Painter = preload("res://scripts/painter.gd")
	var kind: String = "sword"
	var sheet: bool = false
	var navy: bool = false
	var clock: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		clock += delta
		queue_redraw()

	func _draw() -> void:
		var origin := Vector2(size.x * 0.5, size.y * 0.74)
		var zoom := 2.05
		if kind == "horse" and not navy:
			zoom = 1.65
			origin.y = size.y * 0.8
		draw_set_transform(origin, 0.0, Vector2(zoom, zoom))
		var look: Dictionary = Painter.look_as(kind, sheet, false)
		var span := fmod(clock, 2.2)
		var phase := "march"
		var beat := 0
		var along := 0.0
		if span < 0.7:
			along = span / 0.7
		else:
			phase = "act"
			var act := (span - 0.7) / 1.5
			beat = mini(3, int(act * 4.0))
			along = clampf(act * 4.0 - float(beat), 0.0, 1.0)
		var pose := {"phase": phase, "t": along, "clock": clock, "beat": beat}
		Painter.paint_local(self, look, pose)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


