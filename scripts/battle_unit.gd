extends Node2D

const Buff = preload("res://scripts/level_buff.gd")
const Painter = preload("res://scripts/painter.gd")

const BERSERK_TOP := -22.0
const BERSERK_BOTTOM := 20.0

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
var act: float = 0.0
var debut: float = 0.46
var hurt: float = 0.0
var fall_t: float = 0.0
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
var gust_lock: float = 0.0
var winding: bool = false
var strike_sent: bool = false
var support_pulse: bool = false
var pending_foe = null
var pending_gate = null
var boss_marks: Array[Vector2] = []
var net_id: int = 0


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
	if role == "boss":
		attack_timer = 0.9
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
	flash = 0.16
	hurt = 1.0
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
	var cycle := Painter.cycle_time(str(data.get("paint", "")))
	act = maxf(0.0, act - delta / cycle)
	debut = maxf(0.0, debut - delta)
	hurt = maxf(0.0, hurt - delta / 0.34)
	if battle != null and battle.puppet:
		if not alive:
			fall_t += delta
			modulate.a = maxf(0.0, 1.0 - fall_t * 1.65)
			queue_redraw()
			if modulate.a <= 0.0:
				queue_free()
			return
		queue_redraw()
		return
	gust_lock = maxf(0.0, gust_lock - delta)
	if gust_lock > 0.0:
		winding = false
		act = 0.0
		hurt = maxf(hurt, 0.45)
	elif winding and not strike_sent:
		var weapon := str(look.get("weapon", "katana"))
		var clock := _act_clock()
		if Painter.strike_due(weapon, int(clock.x), clock.y):
			strike_sent = true
			_resolve_strike()
	if act <= 0.0:
		winding = false
	if lunge <= 0.0:
		show_strike = false
	if not alive:
		fall_t += delta
		modulate.a = maxf(0.0, 1.0 - fall_t * 1.65)
		queue_redraw()
		if modulate.a <= 0.0:
			queue_free()
		return
	if battle.finished or battle.paused:
		queue_redraw()
		return
	attack_timer -= delta
	bob_time += delta
	if gust_lock > 0.0:
		moving = false
	elif role == "heal" or role == "buff":
		_support(delta)
	else:
		_fight(delta)
	if _spans_roads() and battle.lane_ys.size() > 0:
		z_index = int(battle.lane_ys[battle.lane_ys.size() - 1]) + 24
	else:
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
	if role == "heal" and target != null and attack_timer <= 0.0 and not winding:
		attack_timer = float(data["interval"])
		act = 1.0
		winding = true
		strike_sent = false
		support_pulse = true
		pending_foe = target
	elif role == "buff":
		battle.set_buff_link(self, target)
		if target != null and attack_timer <= 0.0 and not winding:
			attack_timer = float(data["interval"])
			act = 1.0
			winding = true
			strike_sent = false
			support_pulse = false
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
	if attack_timer > 0.0 or winding or gust_lock > 0.0:
		return
	attack_timer = float(data["interval"])
	act = 1.0
	winding = true
	strike_sent = false
	support_pulse = false
	pending_foe = foe
	pending_gate = gate


func _act_clock() -> Vector2:
	var u := 1.0 - clampf(act, 0.0, 1.0)
	var beat := mini(3, int(u * 4.0))
	var along := clampf(u * 4.0 - float(beat), 0.0, 1.0)
	return Vector2(float(beat), along)


func _resolve_strike() -> void:
	if support_pulse:
		support_pulse = false
		var ally = pending_foe
		if ally != null and is_instance_valid(ally) and ally.alive:
			ally.hp = minf(ally.max_hp, ally.hp + 40.0)
			heal_flash = 0.55
			battle.float_text(ally.position + Vector2(0, -46), "+40", Color("8ee0a2"))
			Sfx.play("heal", randf_range(0.96, 1.05), -8.0)
		return
	if role == "buff":
		return
	lunge = 1.0
	var amount := float(data["damage"]) * damage_multiplier
	var foe = pending_foe
	var gate = pending_gate
	if foe != null and (not is_instance_valid(foe) or not foe.alive):
		foe = null
	if role != "suicide":
		var swing := Painter.hit_id(str(look.get("weapon", "katana")))
		Sfx.play(swing, randf_range(0.94, 1.06), -7.0)
	var reach := float(data["reach"])
	var siege := minf(reach, 150.0)
	if role == "ranged":
		if foe != null and _along(foe) <= reach + 8.0:
			var cross := int(foe.lane) != lane
			var aim_y := position.y
			if cross:
				aim_y = float(foe.position.y)
			var tint: Color = Color("b6e36a") if side == 1 else Color("f2d38a")
			battle.fire_arrow(position + Vector2(0, -16), Vector2(float(foe.position.x), aim_y - 16.0), amount, side, tint, reach + 40.0, lane, false, true, cross)
		elif foe == null and gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
			var tint_gate: Color = Color("b6e36a") if side == 1 else Color("f2d38a")
			battle.fire_arrow(position + Vector2(0, -16), Vector2(gate.front_x, position.y - 16.0), amount, side, tint_gate, reach + 40.0, lane, false, true, false)
		return
	if _is_boss():
		_strike_boss(amount, reach)
		return
	if _is_berserker():
		for other in battle.hostile_targets(side):
			if abs(other.position.x - position.x) <= reach:
				other.take_damage(amount, true)
		if gate != null and abs(position.x - gate.front_x) <= reach + 8.0:
			gate.take_damage(amount)
		return
	if role == "aoe" or role == "suicide":
		for other in battle.hostile_targets(side):
			if int(other.lane) != lane and not battle.is_boss(other):
				continue
			if abs(other.position.x - position.x) <= reach:
				other.take_damage(amount, true)
		if gate != null and abs(position.x - gate.front_x) <= reach + 8.0:
			gate.take_damage(amount)
		if role == "suicide":
			Sfx.play("explode", randf_range(0.92, 1.05), -3.0)
			take_damage(float(data.get("self_damage", 40)), true)
		return
	if foe != null and _along(foe) <= reach + 8.0:
		if int(foe.lane) != lane:
			strike_to = foe.position
			show_strike = true
		foe.take_damage(amount, true)
	elif gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		gate.take_damage(amount)


func catch_gust(at_x: float) -> void:
	position.x = at_x
	hurt = 1.0
	gust_lock = 0.6
	act = 0.0
	winding = false
	strike_sent = true
	var left: float = maxf(1.0, hp * 0.5)
	var lost := hp - left
	hp = left
	if lost >= 1.0:
		battle.float_text(position + Vector2(0, -48), str(int(round(lost))), Color("9fd4ff"))


func _nearest_foe():
	if _is_berserker() or _is_boss():
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
		if int(foe.lane) == lane or not (battle.is_berserker(foe) or battle.is_boss(foe)):
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


func _is_boss() -> bool:
	return str(data.get("id", "")) == "boss"


func _spans_roads() -> bool:
	return _is_berserker() or _is_boss()


func _strike_boss(amount: float, reach: float) -> void:
	var first = null
	var second = null
	var first_d := reach
	var second_d := reach
	for other in battle.hostile_targets(side):
		var along := _along(other)
		if along < -8.0 or along > reach:
			continue
		if first == null or along < first_d:
			second = first
			second_d = first_d
			first = other
			first_d = along
		elif second == null or along < second_d:
			second = other
			second_d = along
	boss_marks.clear()
	if first != null:
		first.take_damage(amount, true)
		boss_marks.append(first.global_position)
	if second != null:
		second.take_damage(amount, true)
		boss_marks.append(second.global_position)


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


func _pose() -> Dictionary:
	var phase := "idle"
	var t := 0.0
	var beat := 0
	if not alive:
		phase = "fall"
		t = clampf(fall_t / 0.6, 0.0, 1.0)
	elif debut > 0.0 and act <= 0.0:
		phase = "debut"
		t = 1.0 - clampf(debut / 0.46, 0.0, 1.0)
	elif act > 0.0:
		phase = "act"
		var u := 1.0 - clampf(act, 0.0, 1.0)
		beat = mini(3, int(u * 4.0))
		t = clampf(u * 4.0 - float(beat), 0.0, 1.0)
	elif hurt > 0.0:
		phase = "hurt"
		t = 1.0 - clampf(hurt, 0.0, 1.0)
	elif moving:
		phase = "march"
	return {"phase": phase, "t": t, "clock": bob_time, "flash": flash, "beat": beat}


func _road_span() -> float:
	if battle == null or battle.lane_ys.size() < 2:
		return 0.0
	return float(battle.lane_ys[battle.lane_ys.size() - 1]) - float(battle.lane_ys[0])


func _body_scale() -> float:
	var sc := float(data.get("scale", 1.2))
	if not _spans_roads():
		return sc
	var span := _road_span()
	if span <= 1.0:
		return sc
	return span / (BERSERK_BOTTOM - BERSERK_TOP)


func _body_shift(sc: float) -> float:
	if not _spans_roads():
		return 0.0
	return -0.5 * (BERSERK_TOP + BERSERK_BOTTOM) * sc


func _draw() -> void:
	var sc := _body_scale()
	var shift := _body_shift(sc)
	var bob := 0.0
	if moving and alive and debut <= 0.0:
		bob = sin(bob_time * 8.0) * 1.5
	draw_set_transform(Vector2(0, bob + shift), 0, Vector2(facing * sc, sc))
	Painter.paint_local(self, look, _pose())
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if debut > 0.0 and alive:
		var ring := clampf(debut / 0.46, 0.0, 1.0)
		var radius := 16.0 + (1.0 - ring) * 14.0
		var at := Vector2(0, 10)
		if _spans_roads():
			radius = _road_span() * 0.48
			at = Vector2.ZERO
		draw_arc(at, radius, 0, TAU, 24, Color(1, 0.9, 0.62, ring), 2.2)
	if not alive:
		return
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var bar_y := -58.0 * sc
	if _spans_roads():
		bar_y = shift + BERSERK_TOP * sc - 14.0
	var bar_w := 36.0 * sc
	var bar_h := 8.0 if _spans_roads() else 5.0
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.65))
	var fill := Color("7dce6a") if ratio > 0.35 else Color("e24b3b")
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * ratio, bar_h), fill)
	if role == "assassin" and not data.get("blink_used", false):
		draw_circle(Vector2(-bar_w * 0.5 - 6.0, bar_y + 2.0), 3.2, Color("c084fc"))
	if level_stacks > 0:
		draw_circle(Vector2(bar_w * 0.5 + 6.0, bar_y + 2.0), 3.4, Color("e6c36a"))
	if _is_boss() and lunge > 0.12:
		var boss_alpha := clampf(lunge, 0.0, 1.0)
		for mark in boss_marks:
			draw_line(Vector2(0, -20), to_local(mark), Color(0.86, 0.16, 0.12, boss_alpha), 7.0)
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
