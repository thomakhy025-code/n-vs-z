extends Node2D

const Buff = preload("res://scripts/level_buff.gd")
const Painter = preload("res://scripts/painter.gd")

var battle = null
var side: int = 0
var facing: float = 1.0
var hp: float = 180.0
var max_hp: float = 180.0
var base_max_hp: float = 180.0
var damage_multiplier: float = 1.0
var level_stacks: int = 0
var alive: bool = true
var attack_reach: float = 78.0
var sword_damage: float = 22.0
var sword_interval: float = 0.55
var shoot_damage: float = 18.0
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
var winding: bool = false
var strike_sent: bool = false
var act_tool: String = "katana"
var pending_kind: String = ""
const RESPAWN: float = 6.0


func setup(field) -> void:
	battle = field
	look = Painter.look("hero")
	var start_y: float = field.ground_y
	if field.lane_ys.size() > 1:
		start_y = float(field.lane_ys[1])
		lane = 1
	position = Vector2(field.player_front + 10.0, start_y)
	z_index = 80


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


func apply_level_buff() -> void:
	Buff.apply(self)


func remove_level_buff() -> void:
	Buff.remove(self)


func on_buff_death() -> void:
	_go_down()


func take_damage(amount: float, quiet: bool = false) -> void:
	if not alive or invuln > 0.0:
		return
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


func _go_down() -> void:
	if not alive and down_timer > 0.0:
		return
	alive = false
	hp = 0.0
	down_timer = RESPAWN
	dragging = false
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
	if not alive:
		winding = false
		act = 0.0
		down_timer -= delta
		if down_timer <= 0.0:
			_revive()
		return
	if battle.finished or battle.paused:
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
	var axis := Vector2.ZERO
	if bot:
		axis = bot_axis
	else:
		axis = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if axis.length() > 0.15:
		dragging = false
		position += axis.normalized() * speed * delta
		bob_time += delta
	elif dragging:
		var delta_to: Vector2 = target - position
		if delta_to.length() <= 6.0:
			dragging = false
		else:
			position += delta_to.normalized() * minf(speed * delta, delta_to.length())
			bob_time += delta
	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, min_y, max_y)
	lane = battle.lane_index(position.y)
	stepping = dragging or axis.length() > 0.15


func _combat(delta: float) -> void:
	sword_cd -= delta
	shoot_cd -= delta
	_land_hero()
	var foe = _nearest(maxf(sword_reach(), shoot_reach))
	if foe != null:
		facing = -1.0 if foe.position.x < position.x else 1.0
	else:
		facing = 1.0
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
	if pending_kind == "sword":
		slash = 0.28
		Sfx.play(Painter.hit_id("katana"), randf_range(0.97, 1.05), -4.0)
		var melee = _nearest(sword_reach())
		if melee != null:
			melee.take_damage(sword_damage * damage_multiplier, true)
		elif _gate_in(sword_reach()):
			battle.damage_gate(1, sword_damage * damage_multiplier)
	else:
		muzzle = 0.2
		Sfx.play(Painter.hit_id("bow"), 1.04, -4.0)
		var road := lane
		var road_y: float = battle.lane_y(road) - 10.0
		var ranged = _nearest(shoot_reach)
		var aim_x := position.x + facing * shoot_reach
		if ranged != null:
			aim_x = float(ranged.position.x)
		elif _gate_in(shoot_reach):
			aim_x = battle.enemy_front
		battle.fire_arrow(Vector2(position.x, road_y), Vector2(aim_x, road_y), shoot_damage * damage_multiplier, 0, Color("fff6c8"), shoot_reach, road, true, _gate_in(shoot_reach), false)


func _act_clock() -> Vector2:
	var u := 1.0 - clampf(act, 0.0, 1.0)
	var beat := mini(3, int(u * 4.0))
	var along := clampf(u * 4.0 - float(beat), 0.0, 1.0)
	return Vector2(float(beat), along)


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
	for foe in battle.hostile_targets(0):
		if int(foe.lane) != mine and not battle.is_boss(foe):
			continue
		var dist: float = absf(float(foe.position.x) - position.x)
		if dist <= best_d:
			best_d = dist
			best = foe
	return best


func _gate_in(reach: float) -> bool:
	return abs(battle.enemy_front - position.x) <= minf(reach, 150.0)


func _revive() -> void:
	alive = true
	hp = max_hp
	invuln = 1.1
	visible = true
	var revive_y: float = battle.lane_y(1)
	lane = 1
	position = Vector2(battle.player_front + 8.0, revive_y)
	battle.float_text(position + Vector2(-16, -40), "RETURN", Color("f3e6c8"))


func _pose() -> Dictionary:
	var phase := "idle"
	var t := 0.0
	var beat := 0
	if not alive:
		phase = "fall"
		t = clampf(1.0 - down_timer / RESPAWN, 0.0, 1.0)
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


func _draw_muzzle() -> void:
	var alpha := clampf(muzzle / 0.2, 0.0, 1.0)
	var at := Vector2(facing * 34.0, -16.0)
	draw_circle(at, 8.0 + alpha * 14.0, Color(1, 0.95, 0.7, alpha * 0.9))
	draw_circle(at, 4.0, Color("fff6c8"))
