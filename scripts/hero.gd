extends Node2D

const Buff = preload("res://scripts/level_buff.gd")
const Painter = preload("res://scripts/painter.gd")
const SkillFx = preload("res://scripts/skill_fx.gd")

var battle = null
var side: int = 0
var facing: float = 1.0
var hp: float = 360.0
var max_hp: float = 360.0
var base_max_hp: float = 360.0
var damage_multiplier: float = 1.0
var level_stacks: int = 0
var level_power: float = 0.0
var alive: bool = true
var attack_reach: float = 78.0
var sword_damage: float = 44.0
var sword_interval: float = 0.55
var shoot_damage: float = 36.0
var shoot_interval: float = 0.7
var shoot_reach: float = 380.0
var speed: float = 250.0
var sword_cd: float = 0.0
var shoot_cd: float = 0.0
var pointer_sword: bool = false
var pointer_shoot: bool = false
var dragging: bool = false
var target: Vector2 = Vector2.ZERO
var flash: float = 0.0
var lunge: float = 0.0
var act: float = 0.0
var hurt: float = 0.0
var slash: float = 0.0
var muzzle: float = 0.0
var lane: int = 1
var bob_time: float = 0.0
var stepping: bool = false
var down_timer: float = 0.0
var home_lock: float = 0.0
var gust_lock: float = 0.0
var invuln: float = 0.0
var look: Dictionary = {}
var min_x: float = 80.0
var max_x: float = 1100.0
var min_y: float = 300.0
var max_y: float = 460.0
var bot: bool = false
var bot_axis: Vector2 = Vector2.ZERO
var bot_sword: bool = false
var bot_shoot: bool = false
var driven: bool = false
var net_pos: Vector2 = Vector2.ZERO
var net_step: bool = false
var winding: bool = false
var strike_sent: bool = false
var act_tool: String = "katana"
var pending_kind: String = ""
var numb: float = 0.0
var bone_t: float = 0.0
var root_left: float = 0.0
var frost_time: float = 0.0
var blaze: float = 0.0
var blaze_clock: float = 0.0
var blaze_factor: float = 1.0
var _aura: Sprite2D = null
const RESPAWN: float = 6.0


func setup(field) -> void:
	battle = field
	look = Painter.look("hero")
	facing = 1.0 if side == 0 else -1.0
	var start_y: float = field.ground_y
	if field.lane_ys.size() > 1:
		start_y = float(field.lane_ys[1])
		lane = 1
	if side == 0:
		position = Vector2(field.player_rear, start_y)
	else:
		position = Vector2(field.enemy_rear, start_y)
	net_pos = position
	z_index = 80
	var factor := 1.0
	if battle != null and battle.has_method("rank_factor"):
		factor = float(battle.rank_factor("hero", side))
	base_max_hp = 360.0 * factor
	max_hp = base_max_hp
	hp = max_hp
	sword_damage = 44.0 * factor
	shoot_damage = 36.0 * factor


func set_bounds(a: float, b: float, top: float, bottom: float) -> void:
	min_x = a
	max_x = b
	min_y = top
	max_y = bottom


func set_target(where: Vector2) -> void:
	target = where
	dragging = true


func damage_rating() -> float:
	return sword_damage


func apply_level_buff(power: float = 0.2) -> void:
	Buff.apply(self, power)


func remove_level_buff(power: float = 0.2) -> void:
	Buff.remove(self, power)


func on_buff_death() -> void:
	_go_down()


func apply_numb(seconds: float) -> void:
	numb = maxf(numb, seconds)
	dragging = false
	winding = false
	act = 0.0
	strike_sent = true
	stepping = false


func clear_numb() -> void:
	if numb <= 0.0:
		return
	numb = 0.0
	if battle != null:
		battle.float_text(position + Vector2(0, -40), "clear", Color("8ee0a2"))


func numb_left() -> float:
	return numb


func show_bones() -> void:
	bone_t = 0.9


func take_damage(amount: float, quiet: bool = false, _from_id: String = "", _from_reach: float = -1.0) -> bool:
	if not alive or invuln > 0.0:
		return false
	hp -= amount
	flash = 0.16
	hurt = 1.0
	battle.register_damage()
	battle.float_text(position + Vector2(0, -58), str(int(round(amount))), Color("ffd27a"))
	if not quiet:
		Sfx.play("hit", 1.08, -6.0)
	if hp <= 0.0:
		hp = 0.0
		_go_down()
	return true


func _go_down() -> void:
	if not alive and down_timer > 0.0:
		return
	alive = false
	hp = 0.0
	blaze = 0.0
	blaze_clock = 0.0
	down_timer = RESPAWN
	dragging = false
	home_lock = 0.0
	visible = false
	battle.float_text(position + Vector2(-10, -20), "DOWN", Color("ff8d7a"))


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	lunge = maxf(0.0, lunge - delta * 3.4)
	act = maxf(0.0, act - delta / 0.92)
	hurt = maxf(0.0, hurt - delta / 0.34)
	slash = maxf(0.0, slash - delta)
	muzzle = maxf(0.0, muzzle - delta)
	invuln = maxf(0.0, invuln - delta)
	home_lock = maxf(0.0, home_lock - delta)
	gust_lock = maxf(0.0, gust_lock - delta)
	numb = maxf(0.0, numb - delta)
	bone_t = maxf(0.0, bone_t - delta)
	if battle != null and battle.puppet:
		if not alive:
			visible = false
		elif self == battle.controlled and not battle.finished and not battle.paused:
			_move(delta)
		if act <= 0.0:
			winding = false
		_sync_aura()
		queue_redraw()
		return
	if not alive:
		visible = false
		winding = false
		act = 0.0
		down_timer -= delta
		if down_timer <= 0.0:
			_revive()
		_sync_aura()
		return
	if battle.finished or battle.paused:
		_sync_aura()
		queue_redraw()
		return
	_tick_blaze(delta)
	_sync_aura()
	if numb > 0.0 or gust_lock > 0.0:
		dragging = false
		winding = false
		act = 0.0
		stepping = false
		strike_sent = true
		queue_redraw()
		return
	_move(delta)
	_combat(delta)
	if act <= 0.0:
		winding = false
	if invuln > 0.0:
		modulate.a = 0.45 if int(invuln * 14.0) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0
	queue_redraw()


func _move(delta: float) -> void:
	if driven:
		if home_lock <= 0.0:
			position.x = clampf(net_pos.x, min_x, max_x)
			position.y = clampf(net_pos.y, min_y, max_y)
		lane = battle.lane_index(position.y)
		stepping = false if home_lock > 0.0 else net_step
		return
	var stick := Vector2.ZERO
	if battle != null and not bot:
		stick = battle.stick_axis
	var keys := Vector2.ZERO
	if bot:
		keys = bot_axis
	elif stick.length() <= 0.12:
		keys = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	var step := Vector2.ZERO
	if stick.length() > 0.12:
		step = stick.limit_length(1.0)
	elif keys.length() > 0.15:
		step = keys.normalized()
	var pace := _pace()
	if pace <= 0.0:
		dragging = false
		stepping = false
		lane = battle.lane_index(position.y)
		return
	if step.length() > 0.12:
		dragging = false
		position += step * speed * pace * delta
		bob_time += delta
	elif dragging:
		var delta_to: Vector2 = target - position
		if delta_to.length() <= 6.0:
			dragging = false
		else:
			position += delta_to.normalized() * minf(speed * pace * delta, delta_to.length())
			bob_time += delta
	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, min_y, max_y)
	lane = battle.lane_index(position.y)
	stepping = dragging or step.length() > 0.12


func _combat(delta: float) -> void:
	sword_cd -= delta
	shoot_cd -= delta
	_land_hero()
	var foe = _nearest(maxf(sword_reach(), shoot_reach))
	if foe != null:
		facing = -1.0 if foe.position.x < position.x else 1.0
	else:
		facing = 1.0 if side == 0 else -1.0
	var want_sword := pointer_sword or bot_sword or (not bot and Input.is_action_pressed("sword"))
	var want_shoot := pointer_shoot or bot_shoot or (not bot and Input.is_action_pressed("shoot"))
	if winding:
		return
	if want_sword and sword_cd <= 0.0:
		sword_cd = sword_interval
		act = 1.0
		winding = true
		strike_sent = false
		act_tool = "katana"
		pending_kind = "sword"
	elif want_shoot and shoot_cd <= 0.0:
		shoot_cd = shoot_interval
		act = 1.0
		winding = true
		strike_sent = false
		act_tool = "bow"
		pending_kind = "shoot"


func _land_hero() -> void:
	if not winding or strike_sent:
		return
	var clock := _act_clock()
	if not Painter.strike_due(act_tool, int(clock.x), clock.y):
		return
	strike_sent = true
	lunge = 1.0
	var boosted := blaze > 0.0
	if pending_kind == "sword":
		slash = 0.28
		Sfx.play(Painter.hit_id("katana"), randf_range(0.97, 1.05), -4.0)
		var power := sword_damage * damage_multiplier
		if boosted:
			power *= 3.0 * blaze_factor
		var melee = _nearest(sword_reach())
		if boosted:
			_blaze_melee(melee, power)
		elif melee != null:
			melee.take_damage(power, true, "hero", sword_reach())
		elif _gate_in(sword_reach()):
			battle.damage_gate(1 - side, power)
	else:
		muzzle = 0.2
		Sfx.play(Painter.hit_id("bow"), 1.04, -4.0)
		var road := lane
		var road_y: float = battle.lane_y(road) - 10.0
		var ranged = _nearest(shoot_reach)
		var gate_x: float = float(battle.enemy_front) if side == 0 else float(battle.player_front)
		var aim_x := position.x + facing * shoot_reach
		if ranged != null:
			aim_x = float(ranged.position.x)
		elif _gate_in(shoot_reach):
			aim_x = gate_x
		var shot := shoot_damage * damage_multiplier
		var splash := 0.0
		var burn_kind := ""
		var burn := 0.0
		if boosted:
			shot *= 3.0 * blaze_factor
			splash = 70.0
			burn_kind = "fire"
			burn = 9.0
			if battle.has_method("ember_damage"):
				burn = float(battle.ember_damage())
		battle.fire_arrow(Vector2(position.x, road_y), Vector2(aim_x, road_y), shot, side, Color("fff6c8"), shoot_reach, road, true, _gate_in(shoot_reach), false, "hero", burn_kind, burn, splash)


func _pace() -> float:
	if root_left > 0.0:
		return 0.0
	if battle != null and battle.has_method("chill_pace"):
		return float(battle.chill_pace(self))
	return 1.0


func _tick_blaze(delta: float) -> void:
	if blaze <= 0.0 or not alive:
		return
	var before := blaze
	blaze = maxf(0.0, blaze - delta)
	blaze_clock += before - blaze
	while blaze_clock >= 1.0 and alive:
		blaze_clock -= 1.0
		_bleed(max_hp * 0.125)
	if blaze <= 0.0:
		blaze = 0.0
		blaze_clock = 0.0


func _bleed(amount: float) -> void:
	if not alive:
		return
	hp -= amount
	if battle != null:
		battle.register_damage()
		battle.float_text(position + Vector2(0, -58), str(int(round(amount))), Color("ff7a2a"))
	if hp <= 0.0:
		hp = 0.0
		blaze = 0.0
		blaze_clock = 0.0
		_go_down()


func _blaze_melee(melee, power: float) -> void:
	var at := position + Vector2(facing * 48.0, 0.0)
	var struck := false
	if melee != null:
		at = melee.position
		struck = true
	elif _gate_in(sword_reach()):
		var gate_x: float = float(battle.enemy_front) if side == 0 else float(battle.player_front)
		at = Vector2(gate_x, position.y)
		battle.damage_gate(1 - side, power)
		struck = true
	if not struck:
		return
	if battle.has_method("splash_foes"):
		battle.splash_foes(at, lane, power, side, 70.0)
	elif melee != null:
		melee.take_damage(power, true, "hero", 400.0)
	var burn := 9.0
	if battle.has_method("ember_damage"):
		burn = float(battle.ember_damage())
	battle.lay_hazard("fire", lane, at, 3.0, burn)


func _act_clock() -> Vector2:
	var u := 1.0 - clampf(act, 0.0, 1.0)
	var beat := mini(3, int(u * 4.0))
	var along := clampf(u * 4.0 - float(beat), 0.0, 1.0)
	return Vector2(float(beat), along)


func catch_blow(at_x: float) -> void:
	position.x = clampf(at_x, min_x, max_x)
	hurt = 0.8
	gust_lock = 0.45
	dragging = false
	act = 0.0
	winding = false
	strike_sent = true


func shove_back(at_x: float) -> void:
	position.x = at_x
	hurt = 1.0
	act = 0.0
	winding = false
	strike_sent = true
	var left: float = maxf(1.0, hp * 0.5)
	var lost: float = hp - left
	hp = left
	if lost >= 1.0:
		battle.float_text(position + Vector2(0, -58), str(int(round(lost))), Color("9fd4ff"))


func sword_reach() -> float:
	return attack_reach


func _nearest(reach: float):
	var best = null
	var best_d := reach
	var mine := lane
	for foe in battle.hostile_targets(side):
		if foe.has_method("is_perched") and foe.is_perched():
			continue
		if reach <= 120.0 and foe.has_method("is_airborne") and foe.is_airborne():
			continue
		if int(foe.lane) != mine and not battle.is_boss(foe):
			continue
		var dist: float = absf(float(foe.position.x) - position.x)
		if dist <= best_d:
			best_d = dist
			best = foe
	return best


func _gate_in(reach: float) -> bool:
	var front: float = float(battle.enemy_front) if side == 0 else float(battle.player_front)
	return abs(front - position.x) <= minf(reach, 150.0)


func _revive() -> void:
	alive = true
	hp = max_hp
	invuln = 1.1
	visible = true
	down_timer = 0.0
	dragging = false
	winding = false
	act = 0.0
	var revive_y: float = battle.lane_y(1)
	lane = 1
	var home_x: float = float(battle.player_rear) if side == 0 else float(battle.enemy_rear)
	position = Vector2(home_x, revive_y)
	net_pos = position
	home_lock = 0.55 if battle.duel else 0.0
	battle.float_text(position + Vector2(-16, -40), "RETURN", Color("f3e6c8"))


func _pose() -> Dictionary:
	var phase := "idle"
	var t := 0.0
	var beat := 0
	if not alive:
		phase = "fall"
		t = clampf(1.0 - down_timer / RESPAWN, 0.0, 1.0)
	elif numb > 0.0:
		phase = "hurt"
		t = 0.0
	elif act > 0.0:
		phase = "act"
		var u := 1.0 - clampf(act, 0.0, 1.0)
		beat = mini(3, int(u * 4.0))
		t = clampf(u * 4.0 - float(beat), 0.0, 1.0)
	elif hurt > 0.0:
		phase = "hurt"
		t = 1.0 - clampf(hurt, 0.0, 1.0)
	elif stepping:
		phase = "march"
	var pose := {"phase": phase, "t": t, "clock": bob_time, "flash": flash, "beat": beat}
	if act_tool == "bow" and winding:
		pose["tool"] = "bow"
	return pose


func _draw() -> void:
	var bob := 0.0
	if stepping:
		bob = sin(bob_time * 8.0) * 1.5
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing * 1.42, 1.42))
	Painter.paint_local(self, look, _pose())
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if slash > 0.0:
		_draw_slash()
	if muzzle > 0.0:
		_draw_muzzle()
	draw_line(Vector2(-8, -78), Vector2(8, -78), Color("c44536"), 3.0)
	if not alive:
		return
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	draw_rect(Rect2(-26, -88, 52, 6), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-26, -88, 52.0 * ratio, 6), Color("f2d38a") if ratio > 0.35 else Color("e24b3b"))
	if level_stacks > 0:
		draw_circle(Vector2(32, -85), 3.5, Color("e6c36a"))
	if bone_t > 0.0 or numb > 0.0:
		Painter.paint_ailment(self, bone_t, numb, bob_time)


func _sync_aura() -> void:
	if blaze <= 0.0:
		if _aura != null:
			_aura.visible = false
		return
	var tex: Texture2D = SkillFx.texture("en")
	if tex == null:
		return
	if _aura == null:
		_aura = Sprite2D.new()
		_aura.centered = true
		_aura.z_index = -1
		_aura.show_behind_parent = true
		_aura.region_enabled = true
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_aura.material = mat
		add_child(_aura)
	_aura.visible = true
	if _aura.texture != tex:
		_aura.texture = tex
	var frame: int = posmod(int(Time.get_ticks_msec() / 70), SkillFx.FRAMES)
	_aura.region_rect = SkillFx.region("en", frame)
	_aura.position = Vector2(0.0, -24.0)
	_aura.scale = Vector2(1.25, 1.25)


func _draw_slash() -> void:
	var alpha := clampf(slash / 0.28, 0.0, 1.0)
	var center := Vector2(facing * 22.0, -22.0)
	var start := -1.2
	var finish := 1.15
	if facing < 0.0:
		start = PI - 1.15
		finish = PI + 1.2
	draw_arc(center, 58.0, start, finish, 18, Color(1, 0.94, 0.72, alpha), 10.0)
	draw_arc(center, 42.0, start, finish, 14, Color(0.86, 0.22, 0.16, alpha), 5.0)
	if blaze <= 0.0:
		return
	var along: float = 1.0 - clampf(slash / 0.28, 0.0, 1.0)
	var puff: int = 0
	while puff < 6:
		var t: float = float(puff) / 5.0
		if t > along + 0.02:
			puff += 1
			continue
		var px: float = facing * (18.0 + t * 84.0)
		var py: float = -10.0 - sin(t * PI) * 36.0
		var frame: int = 4 + (puff % 4)
		var fade: float = 0.55 + 0.4 * t
		SkillFx.blit(self, "ex", frame, Rect2(px - 18.0, py - 26.0, 36.0, 42.0), false, Color(1, 1, 1, fade))
		puff += 1


func _draw_muzzle() -> void:
	var alpha := clampf(muzzle / 0.2, 0.0, 1.0)
	var at := Vector2(facing * 34.0, -16.0)
	draw_circle(at, 8.0 + alpha * 14.0, Color(1, 0.95, 0.7, alpha * 0.9))
	draw_circle(at, 4.0, Color("fff6c8"))
