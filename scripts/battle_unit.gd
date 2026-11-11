extends Node2D

const Buff = preload("res://scripts/level_buff.gd")
const Painter = preload("res://scripts/painter.gd")

var data: Dictionary = {}
var look: Dictionary = {}
var side: int = 0
var facing: float = 1.0
var hp: float = 1.0
var max_hp: float = 1.0
var base_max_hp: float = 1.0
var damage_multiplier: float = 1.0
var level_stacks: int = 0
var alive: bool = true
var reported: bool = false
var down_handled: bool = false
var attack_timer: float = 0.25
var flash: float = 0.0
var lunge: float = 0.0
var bob_time: float = 0.0
var moving: bool = false
var support_target = null
var heal_flash: float = 0.0
var battle = null
var role: String = "melee"
var attack_reach: float = 70.0
var lane: int = 1
var strike_to: Vector2 = Vector2.ZERO
var show_strike: bool = false


func setup(field, entry: Dictionary, which_side: int) -> void:
	battle = field
	data = entry.duplicate()
	side = which_side
	facing = 1.0 if side == 0 else -1.0
	role = str(entry["role"])
	base_max_hp = float(entry["hp"])
	max_hp = base_max_hp
	hp = max_hp
	attack_reach = float(entry["reach"])
	look = Painter.look(str(entry["paint"]))
	attack_timer = 0.55 if role == "berserker" or role == "aoe" else 0.22
	if role == "suicide":
		attack_timer = 0.08
	bob_time = randf() * TAU


func damage_rating() -> float:
	return float(data["damage"])


func apply_level_buff() -> void:
	Buff.apply(self)


func remove_level_buff() -> void:
	Buff.remove(self)


func on_buff_death() -> void:
	_report_down()


func take_damage(amount: float, quiet: bool = false) -> void:
	if not alive:
		return
	hp -= amount
	flash = 0.12
	lunge = maxf(lunge, 0.2)
	battle.register_damage()
	battle.float_text(position + Vector2(0, -48), str(int(round(amount))), Color("ffd27a"))
	if not quiet:
		Sfx.play("hit", randf_range(0.92, 1.08), -10.0)
	if hp <= 0.0:
		hp = 0.0
		alive = false
		_report_down()


func _report_down() -> void:
	if reported:
		return
	reported = true
	alive = false
	battle.on_unit_down(self)


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	lunge = maxf(0.0, lunge - delta * 3.2)
	if lunge <= 0.0:
		show_strike = false
	if not alive:
		modulate.a = maxf(0.0, modulate.a - delta * 2.4)
		position.y -= delta * 16.0
		queue_redraw()
		if modulate.a <= 0.0:
			queue_free()
		return
	if battle.finished or battle.paused:
		queue_redraw()
		return
	attack_timer -= delta
	bob_time += delta
	if role == "heal" or role == "buff":
		_support(delta)
	else:
		_fight(delta)
	z_index = int(position.y)
	queue_redraw()


func _fight(delta: float) -> void:
	if role == "assassin":
		_try_blink()
	var foe = _nearest_foe()
	var gate = battle.gate_for_attacker(side)
	var reach := float(data["reach"])
	var engage := float(data["engage"])
	var siege := minf(reach, 150.0)
	var rush := 1.0
	if foe != null and _along(foe) <= engage and (role == "suicide" or role == "aoe"):
		rush = 1.45
	moving = false
	if foe != null and _along(foe) <= reach:
		_try_strike(foe, gate)
	elif foe == null and gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		_try_strike(null, gate)
	else:
		moving = true
		position.x += facing * float(data["speed"]) * rush * delta
		_clamp_x()


func _support(delta: float) -> void:
	var target = _support_target()
	support_target = target
	if role == "heal" and target != null:
		var gain := 40.0 * delta
		var before: float = target.hp
		target.hp = minf(target.max_hp, target.hp + gain)
		heal_flash -= delta
		if target.hp > before and heal_flash <= 0.0:
			heal_flash = 0.55
			battle.float_text(target.position + Vector2(0, -46), "+%d" % int(round(40.0 * 0.55)), Color("8ee0a2"))
			Sfx.play("heal", randf_range(0.96, 1.05), -8.0)
	elif role == "buff":
		battle.set_buff_link(self, target)
	var foe = _nearest_foe()
	var blocked := foe != null and _along(foe) <= float(data["engage"])
	if target != null or blocked or not _any_ally_ahead():
		moving = false
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _try_blink() -> void:
	if data.get("blink_used", false):
		return
	for foe in battle.hostile_targets(side):
		if not foe.alive or int(foe.lane) != lane:
			continue
		var foe_facing: float = foe.facing
		var forward_gap: float = (position.x - foe.position.x) * foe_facing
		var foe_reach: float = float(foe.attack_reach)
		if forward_gap < -6.0 or forward_gap > foe_reach:
			continue
		var dest: float = foe.position.x - foe_facing * 38.0
		dest = minf(dest, battle.enemy_front - 8.0)
		if dest <= foe.position.x + 10.0:
			continue
		var old: Vector2 = position
		position.x = dest
		data["blink_used"] = true
		battle.poof(old, Color("d7c4ff"))
		battle.poof(position, Color("f3e6c8"))
		Sfx.play("blink", 1.0, -4.0)
		return


func _try_strike(foe, gate) -> void:
	if attack_timer > 0.0:
		return
	attack_timer = float(data["interval"])
	lunge = 1.0
	var amount := float(data["damage"]) * damage_multiplier
	if role == "ranged":
		var cross := foe != null and int(foe.lane) != lane
		var aim_x: float = gate.front_x if foe == null else float(foe.position.x)
		var aim_y := position.y
		if cross:
			aim_y = float(foe.position.y)
		var tint: Color = Color("b6e36a") if side == 1 else Color("f2d38a")
		battle.fire_arrow(position + Vector2(0, -16), Vector2(aim_x, aim_y - 16.0), amount, side, tint, float(data["reach"]) + 40.0, lane, false, true, cross)
		Sfx.play("arrow", randf_range(0.94, 1.06), -6.0)
		return
	Sfx.play("hit", randf_range(0.9, 1.05), -8.0)
	if _is_berserker():
		for other in battle.hostile_targets(side):
			if abs(other.position.x - position.x) <= float(data["reach"]):
				other.take_damage(amount, true)
		if gate != null and abs(position.x - gate.front_x) <= float(data["reach"]) + 8.0:
			gate.take_damage(amount)
		return
	if role == "aoe" or role == "suicide":
		for other in battle.hostile_targets(side):
			if int(other.lane) != lane:
				continue
			if abs(other.position.x - position.x) <= float(data["reach"]):
				other.take_damage(amount, true)
		if gate != null and abs(position.x - gate.front_x) <= float(data["reach"]) + 8.0:
			gate.take_damage(amount)
		if role == "suicide":
			Sfx.play("explode", randf_range(0.92, 1.05), -3.0)
			take_damage(float(data.get("self_damage", 40)), true)
		return
	if foe != null:
		if int(foe.lane) != lane:
			strike_to = foe.position
			show_strike = true
		foe.take_damage(amount, true)
	elif gate != null:
		gate.take_damage(amount)


func _nearest_foe():
	if _is_berserker():
		return _closest_ahead(false)
	var same = _closest_ahead(true)
	if same != null:
		return same
	return _berserker_in_reach()


func _closest_ahead(same_road: bool):
	var best = null
	var best_d := 100000.0
	for foe in battle.hostile_targets(side):
		if same_road and int(foe.lane) != lane:
			continue
		var along := _along(foe)
		if along < -8.0:
			continue
		if along < best_d:
			best_d = along
			best = foe
	return best


func _berserker_in_reach():
	var reach := float(data["reach"])
	var best = null
	var best_d := reach
	for foe in battle.hostile_targets(side):
		if not battle.is_berserker(foe) or int(foe.lane) == lane:
			continue
		var along := _along(foe)
		if along < -8.0 or along > reach:
			continue
		if along <= best_d:
			best_d = along
			best = foe
	return best


func _is_berserker() -> bool:
	return str(data.get("id", "")) == "berserker"


func _along(other) -> float:
	return (other.position.x - position.x) * facing


func _support_target():
	var best = null
	var best_score := -1.0
	for ally in battle.support_candidates(side):
		if ally == self or not ally.alive or int(ally.lane) != lane:
			continue
		var along: float = float(ally.position.x - position.x) * facing
		if along < -4.0 or along > float(data["reach"]):
			continue
		var score: float
		if role == "heal":
			if ally.hp >= ally.max_hp - 0.5:
				continue
			score = 100000.0 - ally.hp
		else:
			score = ally.damage_rating()
		if score > best_score:
			best_score = score
			best = ally
	return best


func _any_ally_ahead() -> bool:
	for ally in battle.support_candidates(side):
		if ally == self or not ally.alive or int(ally.lane) != lane:
			continue
		if (ally.position.x - position.x) * facing > 8.0:
			return true
	return false


func _clamp_x() -> void:
	if side == 0:
		position.x = clampf(position.x, battle.player_front - 8.0, battle.enemy_front)
	else:
		position.x = clampf(position.x, battle.player_front, battle.enemy_front + 8.0)


func _draw() -> void:
	var sc: float = float(data.get("scale", 1.2))
	var bob := 0.0
	if moving and alive:
		bob = sin(bob_time * 10.0) * 2.0
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing * sc, sc))
	Painter.paint_local(self, look, lunge > 0.35, flash)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if not alive:
		return
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var bar_y := -58.0 * sc
	var bar_w := 36.0 * sc
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, 5), Color(0, 0, 0, 0.65))
	var fill := Color("7dce6a") if ratio > 0.35 else Color("e24b3b")
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * ratio, 5), fill)
	if role == "assassin" and not data.get("blink_used", false):
		draw_circle(Vector2(-bar_w * 0.5 - 6.0, bar_y + 2.0), 3.2, Color("c084fc"))
	if level_stacks > 0:
		draw_circle(Vector2(bar_w * 0.5 + 6.0, bar_y + 2.0), 3.4, Color("e6c36a"))
	if _is_berserker() and lunge > 0.12:
		var reach := float(data["reach"])
		var alpha := clampf(lunge, 0.0, 1.0)
		for road_y in battle.lane_ys:
			var local_y := float(road_y) - position.y
			draw_line(Vector2(0, -12), Vector2(facing * reach, local_y), Color(1, 0.72, 0.28, alpha * 0.9), 5.0)
	if show_strike and lunge > 0.05:
		draw_line(Vector2(0, -16), to_local(strike_to), Color(1, 0.86, 0.45, clampf(lunge, 0.0, 1.0)), 4.0)
	if support_target != null and is_instance_valid(support_target) and support_target.alive:
		var to: Vector2 = to_local(support_target.global_position)
		var line := Color("8ee0a2") if role == "heal" else Color("e6c36a")
		draw_line(Vector2(0, -20), to, Color(line.r, line.g, line.b, 0.85), 2.0)
