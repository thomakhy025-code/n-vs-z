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
var bob_time: float = 0.0
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
const RESPAWN: float = 6.0


func setup(field) -> void:
	battle = field
	look = Painter.look("hero")
	position = Vector2(field.player_front + 10.0, field.ground_y - 8.0)
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
	flash = 0.12
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
	invuln = maxf(0.0, invuln - delta)
	if not alive:
		down_timer -= delta
		if down_timer <= 0.0:
			_revive()
		return
	if battle.finished or battle.paused:
		queue_redraw()
		return
	_move(delta)
	_combat(delta)
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


func _combat(delta: float) -> void:
	sword_cd -= delta
	shoot_cd -= delta
	var foe = _nearest(maxf(sword_reach(), shoot_reach))
	if foe != null:
		facing = -1.0 if foe.position.x < position.x else 1.0
	else:
		facing = 1.0
	var want_sword := pointer_sword or bot_sword or (not bot and Input.is_action_pressed("sword"))
	var want_shoot := pointer_shoot or bot_shoot or (not bot and Input.is_action_pressed("shoot"))
	if want_sword and sword_cd <= 0.0:
		var melee = _nearest(sword_reach())
		if melee != null:
			melee.take_damage(sword_damage * damage_multiplier, true)
			sword_cd = sword_interval
			lunge = 1.0
			Sfx.play("sword", randf_range(0.96, 1.06), -4.0)
		elif _gate_in(sword_reach()):
			battle.damage_gate(1, sword_damage * damage_multiplier)
			sword_cd = sword_interval
			lunge = 1.0
			Sfx.play("sword", 0.94, -4.0)
	if want_shoot and shoot_cd <= 0.0:
		var ranged = _nearest(shoot_reach)
		var aim_x: float = battle.enemy_front
		if ranged != null:
			aim_x = ranged.position.x
		if ranged != null or _gate_in(shoot_reach):
			battle.fire_arrow(position + Vector2(0, -18), aim_x, shoot_damage * damage_multiplier, 0, Color("fff4d2"), shoot_reach)
			shoot_cd = shoot_interval
			Sfx.play("arrow", 1.08, -4.0)


func sword_reach() -> float:
	return attack_reach


func _nearest(reach: float):
	var best = null
	var best_d := reach
	for foe in battle.hostile_targets(0):
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
	position = Vector2(battle.player_front + 8.0, battle.ground_y - 8.0)
	battle.float_text(position + Vector2(-16, -40), "RETURN", Color("f3e6c8"))


func _draw() -> void:
	var bob := sin(bob_time * 10.0) * 2.0
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing * 1.42, 1.42))
	Painter.paint_local(self, look, lunge > 0.35, flash)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_line(Vector2(-8, -78), Vector2(8, -78), Color("c44536"), 3.0)
	if not alive:
		return
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	draw_rect(Rect2(-26, -88, 52, 6), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-26, -88, 52.0 * ratio, 6), Color("f2d38a") if ratio > 0.35 else Color("e24b3b"))
	if level_stacks > 0:
		draw_circle(Vector2(32, -85), 3.5, Color("e6c36a"))
