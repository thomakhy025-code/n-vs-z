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
var level_power: float = 0.0
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
var blink_wait: float = 0.0
var winding: bool = false
var strike_sent: bool = false
var support_pulse: bool = false
var pending_foe = null
var pending_gate = null
var boss_marks: Array[Vector2] = []
var net_id: int = 0
var numb: float = 0.0
var bone_t: float = 0.0
var perched: bool = false
var diving: bool = false
var dive_t: float = 0.0
var dive_from: Vector2 = Vector2.ZERO
var dive_aim: Vector2 = Vector2.ZERO
var dive_lane: int = 1
var dive_prey = null
var hang: float = 0.0
var call_left: float = 3.0
var call_flash: float = 0.0
var bolt_t: float = 0.0
var bolt_marks: Array[Vector2] = []
var roost: float = 0.0
var crow_fresh: bool = false
var throws_left: int = 0
var drum_targets: Array = []
var life_left: float = -1.0
var sit_left: float = 0.0
var rounds: int = 4
var loading: float = 0.0
var smoke_tick: float = 0.15
var _picture_stamp: String = ""
var _pose_nudge: float = 0.0


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
	if battle != null and not battle.duel and side != 0:
		var faction := ""
		if battle.rules is Dictionary:
			faction = str(battle.rules.get("faction", ""))
		if bool(entry.get("trial", false)) or faction == "monster":
			look = Painter.as_monster(look)
		elif faction == "human":
			look = Painter.as_human(look)
	attack_timer = 0.55 if role == "berserker" or role == "aoe" else 0.22
	if role == "suicide":
		attack_timer = 0.08
	if role == "boss":
		attack_timer = 0.9
	if role == "howler":
		perched = true
		hang = 1.0
		attack_timer = 0.35
	if role == "storm" or role == "fan":
		attack_timer = float(entry["interval"])
	if role == "herald":
		call_left = 3.0
	if role == "crow" or role == "cow":
		roost = 3.0
		if entry.has("roost_time"):
			roost = float(entry["roost_time"])
		crow_fresh = true
		attack_timer = 0.05
	if role == "javelin":
		throws_left = 5
	if role == "elder":
		life_left = 15.0
	if role == "buck":
		rounds = 4
	bob_time = randf() * TAU
	_pose_nudge = fposmod(bob_time, 0.1)


func damage_rating() -> float:
	return float(data["damage"])


func apply_level_buff(power: float = 0.2) -> void:
	Buff.apply(self, power)


func remove_level_buff(power: float = 0.2) -> void:
	Buff.remove(self, power)


func on_buff_death() -> void:
	_report_down()


func is_perched() -> bool:
	return perched


func apply_numb(seconds: float) -> void:
	numb = maxf(numb, seconds)
	winding = false
	act = 0.0
	strike_sent = true
	moving = false


func clear_numb() -> void:
	if numb <= 0.0:
		return
	numb = 0.0
	if battle != null:
		battle.float_text(position + Vector2(0, -36), "clear", Color("8ee0a2"))


func numb_left() -> float:
	return numb


func show_bones() -> void:
	bone_t = 0.9


func is_airborne() -> bool:
	return role == "moth"


func take_damage(amount: float, quiet: bool = false, from_id: String = "", from_reach: float = -1.0) -> bool:
	if not alive:
		return false
	if perched and from_id != "archer":
		return false
	if role == "moth" and not _moth_allows(from_id, from_reach):
		return false
	if str(data.get("id", "")) == "elder" and randf() < 0.4:
		battle.float_text(position + Vector2(0, -48), "miss", Color("c9d6c4"))
		return false
	if str(data.get("id", "")) == "viper" and randf() < 0.75:
		battle.float_text(position + Vector2(0, -48), "miss", Color("c9d6c4"))
		return false
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
	return true


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
			_keep_picture()
			if modulate.a <= 0.0:
				queue_free()
			return
		_keep_picture()
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
		_keep_picture()
		if modulate.a <= 0.0:
			queue_free()
		return
	if battle.finished or battle.paused:
		_keep_picture()
		return
	attack_timer -= delta
	loading = maxf(0.0, loading - delta)
	if life_left > 0.0:
		life_left -= delta
		if life_left <= 0.0 and alive:
			hp = 0.0
			alive = false
			_report_down()
			_keep_picture()
			return
	blink_wait = maxf(0.0, blink_wait - delta)
	bob_time += delta
	numb = maxf(0.0, numb - delta)
	bone_t = maxf(0.0, bone_t - delta)
	bolt_t = maxf(0.0, bolt_t - delta)
	call_flash = maxf(0.0, call_flash - delta)
	if not perched:
		hang = move_toward(hang, 0.0, delta * 4.0)
	if numb > 0.0:
		winding = false
		act = 0.0
		strike_sent = true
		moving = false
	if gust_lock > 0.0 or numb > 0.0:
		moving = false
	elif (role == "crow" or role == "cow") and roost > 0.0:
		roost -= delta
		moving = false
	elif role == "smog":
		_smog(delta)
	elif role == "elder":
		_elder(delta)
	elif role == "glut":
		_glut(delta)
	elif role == "heal" or role == "buff" or role == "drum" or role == "aria":
		_support(delta)
	else:
		_fight(delta)
	if role == "herald" and numb <= 0.0 and gust_lock <= 0.0:
		_herald(delta)
	if _spans_roads() and battle.lane_ys.size() > 0:
		z_index = int(battle.lane_ys[battle.lane_ys.size() - 1]) + 24
	else:
		z_index = int(position.y)
	_keep_picture()


func _fight(delta: float) -> void:
	if role == "fan":
		_fan(delta)
		return
	if role == "howler" and perched:
		_howler(delta)
		return
	if _halted_by_air(delta):
		return
	if role == "assassin":
		_hunt(delta)
		return
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
	var target = null
	if role == "drum" or role == "aria":
		drum_targets = _drum_targets() if role == "drum" else _aria_targets()
		if not drum_targets.is_empty():
			target = drum_targets[0]
		if role == "aria":
			battle.set_buff_group(self, drum_targets, 0.1)
		else:
			battle.set_buff_group(self, drum_targets)
		if not drum_targets.is_empty() and attack_timer <= 0.0 and not winding:
			attack_timer = float(data["interval"])
			act = 1.0
			winding = true
			strike_sent = false
			support_pulse = false
	else:
		target = _support_target()
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
	support_target = target
	var foe = _nearest_foe()
	var blocked := foe != null and _along(foe) <= float(data["engage"])
	var holding := target != null
	if role == "drum" or role == "aria":
		holding = not drum_targets.is_empty()
	if holding or blocked or not _any_ally_ahead():
		moving = false
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _hunt(delta: float) -> void:
	_try_blink()
	var prey = _closest_prey()
	var gate = battle.gate_for_attacker(side)
	var reach := float(data["reach"])
	var siege := minf(reach, 150.0)
	moving = false
	if prey != null:
		if int(prey.lane) != lane:
			moving = true
			_step_toward_lane(int(prey.lane), delta)
			if _along(prey) > reach:
				position.x += facing * float(data["speed"]) * delta
				_clamp_x()
			return
		if _along(prey) <= reach:
			_try_strike(prey, gate)
			return
		moving = true
		position.x += facing * float(data["speed"]) * delta
		_clamp_x()
		return
	if gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		_try_strike(null, gate)
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _step_toward_lane(index: int, delta: float) -> void:
	var goal_y: float = battle.lane_y(index)
	var gap: float = goal_y - position.y
	var step := float(data["speed"]) * delta
	if absf(gap) <= step:
		position.y = goal_y
		lane = index
	else:
		position.y += signf(gap) * step


func _try_blink() -> void:
	if blink_wait > 0.0:
		return
	var blocker = null
	var blocker_along := 100000.0
	for foe in battle.hostile_targets(side):
		if not foe.alive or int(foe.lane) != lane or _is_prey(foe):
			continue
		var foe_facing: float = foe.facing
		var forward_gap: float = (position.x - foe.position.x) * foe_facing
		var foe_reach: float = float(foe.attack_reach)
		if forward_gap < -6.0 or forward_gap > foe_reach:
			continue
		var along := _along(foe)
		if along < blocker_along:
			blocker_along = along
			blocker = foe
	if blocker == null:
		return
	var dest: float = blocker.position.x - float(blocker.facing) * 38.0
	dest = clampf(dest, battle.player_front + 8.0, battle.enemy_front - 8.0)
	if (dest - blocker.position.x) * facing < 10.0:
		return
	var prey = _closest_prey()
	if prey != null and (dest - position.x) * facing > _along(prey) - 16.0:
		return
	var old: Vector2 = position
	position.x = dest
	blink_wait = 0.18
	battle.poof(old, Color("d7c4ff"))
	battle.poof(position, Color("f3e6c8"))
	Sfx.play("blink", 1.0, -4.0)


func _herald(delta: float) -> void:
	call_left -= delta
	if call_left > 0.0:
		return
	call_left = 3.0
	call_flash = 0.85
	if not winding:
		act = 1.0
	if battle != null and battle.has_method("summon_for_herald"):
		battle.summon_for_herald()


func _howler(delta: float) -> void:
	if diving:
		act = 0.55
		dive_t += delta / 0.38
		var glide := clampf(dive_t, 0.0, 1.0)
		position = dive_from.lerp(dive_aim, glide)
		hang = 1.0 - glide
		lane = dive_lane
		moving = false
		if glide < 1.0:
			return
		diving = false
		perched = false
		hang = 0.0
		act = 0.0
		var landed = dive_prey
		dive_prey = null
		if landed != null and is_instance_valid(landed) and landed.alive:
			var swing := float(data.get("swing", data["damage"])) * damage_multiplier
			landed.take_damage(swing, true, "howler", 70.0)
			lunge = 1.0
			Sfx.play("hit_blunt", randf_range(0.9, 1.02), -5.0)
		attack_timer = float(data["interval"])
		return
	var prey = _closest_prey()
	if prey != null:
		var gap := _along(prey)
		if gap > -8.0 and gap <= 900.0:
			diving = true
			dive_t = 0.0
			dive_from = position
			dive_lane = int(prey.lane)
			dive_prey = prey
			var land_x: float = float(prey.position.x) - facing * 28.0
			land_x = clampf(land_x, battle.player_front + 10.0, battle.enemy_front - 10.0)
			dive_aim = Vector2(land_x, battle.lane_y(dive_lane))
			act = 1.0
			return
	var foe = _closest_ahead(true)
	var gate = battle.gate_for_attacker(side)
	var siege := minf(float(data["reach"]), 150.0)
	var at_line: bool = foe != null and _along(foe) <= 90.0
	var at_gate: bool = gate != null and abs(position.x - float(gate.front_x)) <= siege + 6.0
	if at_line or at_gate:
		perched = false
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _try_strike(foe, gate) -> void:
	if attack_timer > 0.0 or winding or gust_lock > 0.0 or numb > 0.0 or loading > 0.0:
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
			var healed := 40.0 * float(data.get("rank_factor", 1.0))
			ally.hp = minf(ally.max_hp, ally.hp + healed)
			if ally.has_method("clear_numb"):
				ally.clear_numb()
			heal_flash = 0.55
			battle.float_text(ally.position + Vector2(0, -46), "+%d" % int(round(healed)), Color("8ee0a2"))
			Sfx.play("heal", randf_range(0.96, 1.05), -8.0)
		return
	if role == "buff" or role == "drum" or role == "aria":
		return
	var amount := float(data["damage"]) * damage_multiplier
	if role == "fan":
		_strike_fan(amount)
		return
	lunge = 1.0
	var foe = pending_foe
	var gate = pending_gate
	if foe != null and (not is_instance_valid(foe) or not foe.alive):
		foe = null
	if role == "viper":
		_strike_viper(amount, float(data["reach"]), gate)
		return
	if role == "storm":
		_strike_storm(amount, float(data["reach"]), foe, gate)
		return
	if role != "suicide":
		var swing := Painter.hit_id(str(look.get("weapon", "katana")))
		Sfx.play(swing, randf_range(0.94, 1.06), -7.0)
	var reach := float(data["reach"])
	var siege := minf(reach, 150.0)
	var from_id := str(data.get("id", ""))
	if role == "firebow" or role == "javelin":
		_loose_shot(amount, foe, gate)
		return
	if role == "buck" or role == "scope":
		_gunshot(amount, foe, gate, reach)
		return
	if role == "ranged":
		if foe != null and _along(foe) <= reach + 8.0:
			var cross := int(foe.lane) != lane
			var aim_y := position.y
			if cross:
				aim_y = float(foe.position.y)
			var tint: Color = Color("b6e36a") if side == 1 else Color("f2d38a")
			battle.fire_arrow(position + Vector2(0, -16), Vector2(float(foe.position.x), aim_y - 16.0), amount, side, tint, reach + 40.0, lane, false, true, cross, from_id)
		elif foe == null and gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
			var tint_gate: Color = Color("b6e36a") if side == 1 else Color("f2d38a")
			battle.fire_arrow(position + Vector2(0, -16), Vector2(gate.front_x, position.y - 16.0), amount, side, tint_gate, reach + 40.0, lane, false, true, false, from_id)
		return
	if _is_boss():
		_strike_boss(amount, reach)
		return
	if _is_berserker():
		for other in battle.hostile_targets(side):
			if abs(other.position.x - position.x) <= reach:
				other.take_damage(amount, true, from_id, reach)
		if gate != null and abs(position.x - gate.front_x) <= reach + 8.0:
			gate.take_damage(amount)
		return
	if role == "aoe" or role == "suicide":
		for marked_body in battle.hostile_targets(side):
			if int(marked_body.lane) != lane and not battle.is_boss(marked_body):
				continue
			if abs(marked_body.position.x - position.x) <= reach:
				marked_body.take_damage(amount, true, from_id, reach)
		if gate != null and abs(position.x - gate.front_x) <= reach + 8.0:
			gate.take_damage(amount)
		if role == "suicide":
			Sfx.play("explode", randf_range(0.92, 1.05), -3.0)
			take_damage(float(data.get("self_damage", 40)), true, from_id)
		return
	if role == "glut":
		amount = float(data.get("chew", 16.0)) * damage_multiplier
	if (role == "crow" or role == "cow") and crow_fresh and foe != null and _along(foe) <= reach + 8.0:
		amount = float(data.get("opening", amount)) * damage_multiplier
		crow_fresh = false
	if foe != null and _along(foe) <= reach + 8.0:
		if int(foe.lane) != lane:
			strike_to = foe.position
			show_strike = true
		foe.take_damage(amount, true, from_id, reach)
	elif gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		gate.take_damage(amount)


func _fan(delta: float) -> void:
	var someone := false
	for body in battle.hostile_targets(side):
		if int(body.lane) == lane or battle.is_berserker(body) or battle.is_boss(body):
			someone = true
			break
	var gate = battle.gate_for_attacker(side)
	moving = false
	if someone or (gate != null and abs(position.x - gate.front_x) <= 156.0):
		_try_strike(null, gate)
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _strike_fan(amount: float) -> void:
	lunge = 1.0
	battle.blow_road(lane, side, amount, str(data.get("id", "")), position.x)


func _loose_shot(amount: float, foe, gate) -> void:
	var reach := float(data["reach"])
	var siege := minf(reach, 150.0)
	var from_id := str(data.get("id", ""))
	var tint := Color("ff7a2a") if role == "firebow" else Color("e6d3a1")
	var hazard := ""
	var burn := 0.0
	if role == "firebow":
		hazard = "fire"
		burn = float(data.get("burn", 8.0))
	var aim := Vector2.ZERO
	var shoot := false
	var cross := false
	if foe != null and _along(foe) <= reach + 8.0:
		var aim_y := position.y
		if int(foe.lane) != lane:
			aim_y = float(foe.position.y)
			cross = true
		aim = Vector2(float(foe.position.x), aim_y - 16.0)
		shoot = true
	elif gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		aim = Vector2(gate.front_x, position.y - 16.0)
		shoot = true
	if shoot:
		battle.fire_arrow(position + Vector2(0, -16), aim, amount, side, tint, reach + 40.0, lane, false, true, cross, from_id, hazard, burn)
	if role == "javelin":
		_spend_throw()


func _spend_throw() -> void:
	throws_left = maxi(0, throws_left - 1)
	if throws_left > 0:
		return
	data["damage"] = int(data.get("sword", 12))
	data["reach"] = 70.0
	data["engage"] = 70.0
	data["interval"] = 1.0
	role = "melee"
	attack_reach = 70.0
	look["weapon"] = "shortsword"


func _drum_targets() -> Array:
	var picked: Array = []
	for _slot in 3:
		var best = null
		var best_score := -1.0
		for ally in battle.support_candidates(side):
			if ally == self or not ally.alive or int(ally.lane) != lane:
				continue
			if picked.has(ally):
				continue
			var along: float = float(ally.position.x - position.x) * facing
			if along < -4.0 or along > float(data["reach"]):
				continue
			var score: float = ally.damage_rating()
			if score > best_score:
				best_score = score
				best = ally
		if best == null:
			break
		picked.append(best)
	return picked


func _moth_allows(from_id: String, from_reach: float) -> bool:
	if from_id == "fire":
		return false
	if from_reach > 120.0:
		return true
	if from_reach >= 0.0:
		return false
	return from_id == "archer" or from_id == "firebow" or from_id == "lancer" or from_id == "scope" or from_id == "fan" or from_id == "storm"


func _arm_is_short() -> bool:
	if role == "fan" or role == "moth" or role == "storm" or role == "scope" or role == "firebow" or role == "javelin":
		return float(data.get("reach", 70.0)) <= 120.0
	return float(data.get("reach", 70.0)) <= 120.0


func _air_ahead():
	var best = null
	var best_d := 100000.0
	for flyer in battle.hostile_targets(side):
		if not flyer.has_method("is_airborne") or not flyer.is_airborne():
			continue
		if not _spans_roads() and int(flyer.lane) != lane and not battle.is_boss(flyer):
			continue
		var along := _along(flyer)
		if along < -8.0:
			continue
		if along < best_d:
			best_d = along
			best = flyer
	return best


func _halted_by_air(delta: float) -> bool:
	if not _arm_is_short():
		return false
	var wall = _air_ahead()
	if wall == null:
		return false
	var ground = _closest_ahead(not _spans_roads())
	if ground != null and _along(ground) + 6.0 < _along(wall):
		return false
	if _along(wall) <= float(data["reach"]) + 22.0:
		moving = false
		return true
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()
	return true


func _smog(delta: float) -> void:
	smoke_tick -= delta
	if smoke_tick <= 0.0:
		smoke_tick = 0.42
		battle.drop_smoke(position, lane)
	var gate = battle.gate_for_attacker(side)
	if gate != null and abs(position.x - gate.front_x) <= 28.0:
		moving = false
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _elder(delta: float) -> void:
	var mark = _nearest_anybody()
	if mark == null:
		moving = true
		position.x += facing * float(data["speed"]) * 0.45 * delta
		_clamp_x()
		return
	var dx := float(mark.position.x) - position.x
	facing = 1.0 if dx >= 0.0 else -1.0
	if absf(dx) <= float(data["reach"]) + 6.0:
		moving = false
		_try_strike(mark, null)
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _nearest_anybody():
	var best = null
	var best_d := 100000.0
	for body in battle.units:
		if body == self or not is_instance_valid(body) or not body.alive:
			continue
		if int(body.lane) != lane and not battle.is_berserker(body) and not battle.is_boss(body):
			continue
		var dist := absf(float(body.position.x) - position.x)
		if dist < best_d:
			best_d = dist
			best = body
	if battle.hero != null and is_instance_valid(battle.hero) and battle.hero.alive and int(battle.hero.lane) == lane:
		var hero_d := absf(float(battle.hero.position.x) - position.x)
		if hero_d < best_d:
			best_d = hero_d
			best = battle.hero
	if battle.foe != null and is_instance_valid(battle.foe) and battle.foe.alive and int(battle.foe.lane) == lane:
		var foe_d := absf(float(battle.foe.position.x) - position.x)
		if foe_d < best_d:
			best = battle.foe
	return best


func _glut(delta: float) -> void:
	if sit_left > 0.0:
		sit_left -= delta
		moving = false
		winding = false
		act = maxf(act, 0.2)
		return
	var meal = _nearest_meal()
	var reach := float(data["reach"])
	if meal != null and _along(meal) <= reach + 6.0:
		_devour(meal)
		return
	if _wall_in_reach(reach) and (meal == null or _along(meal) > reach):
		moving = false
		return
	if meal != null:
		moving = true
		position.x += facing * float(data["speed"]) * delta
		_clamp_x()
		return
	var gate = battle.gate_for_attacker(side)
	moving = false
	if gate != null and abs(position.x - gate.front_x) <= 86.0:
		_try_strike(null, gate)
		return
	moving = true
	position.x += facing * float(data["speed"]) * delta
	_clamp_x()


func _nearest_meal():
	var best = null
	var best_d := 100000.0
	for meal_body in battle.hostile_targets(side):
		if battle.is_berserker(meal_body):
			continue
		if meal_body.has_method("is_airborne") and meal_body.is_airborne():
			continue
		if meal_body.has_method("is_perched") and meal_body.is_perched():
			continue
		if int(meal_body.lane) != lane and not battle.is_boss(meal_body):
			continue
		var along := _along(meal_body)
		if along < -8.0:
			continue
		if along < best_d:
			best_d = along
			best = meal_body
	return best


func _wall_in_reach(reach: float) -> bool:
	for wall_body in battle.hostile_targets(side):
		var flying := false
		if wall_body.has_method("is_airborne") and bool(wall_body.is_airborne()):
			flying = true
		if not battle.is_berserker(wall_body) and not flying:
			continue
		if not _spans_roads() and int(wall_body.lane) != lane and not battle.is_berserker(wall_body):
			continue
		var along := _along(wall_body)
		if along >= -8.0 and along <= reach + 8.0:
			return true
	return false


func _devour(meal) -> void:
	if meal.has_method("_report_down"):
		meal.hp = 0.0
		meal.alive = false
		meal._report_down()
	elif meal.has_method("_go_down"):
		meal.hp = 0.0
		meal._go_down()
	hp = minf(max_hp, hp + max_hp * 0.2)
	sit_left = 5.0
	act = 1.0
	lunge = 1.0
	battle.float_text(position + Vector2(0, -42), "eat", Color("e24b3b"))
	Sfx.play("hit", 0.72, -6.0)


func _gunshot(amount: float, foe, gate, reach: float) -> void:
	var siege := minf(reach, 150.0)
	if foe != null and _along(foe) <= reach + 8.0:
		strike_to = foe.position
		show_strike = true
		foe.take_damage(amount, true, str(data.get("id", "")), reach)
	elif gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		gate.take_damage(amount)
	if role != "buck":
		return
	rounds = maxi(0, rounds - 1)
	if rounds > 0:
		return
	rounds = 4
	loading = 2.0
	attack_timer = 2.0


func _aria_targets() -> Array:
	var picked: Array = []
	for singer_ally in battle.support_candidates(side):
		if singer_ally == self or not singer_ally.alive:
			continue
		picked.append(singer_ally)
	return picked


func catch_blow(at_x: float) -> void:
	position.x = at_x
	hurt = 0.8
	gust_lock = 0.45
	act = 0.0
	winding = false
	strike_sent = true


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


func _is_prey(foe) -> bool:
	if foe == null or not is_instance_valid(foe) or not ("data" in foe):
		return false
	var id := str(foe.data.get("id", ""))
	return id == "archer" or id == "heal" or id == "level"


func _closest_prey():
	var best = null
	var best_along := 100000.0
	for foe in battle.hostile_targets(side):
		if not _is_prey(foe):
			continue
		var along := _along(foe)
		if along < -8.0:
			continue
		if along < best_along:
			best_along = along
			best = foe
	return best


func _closest_ahead(same_road: bool):
	var best = null
	var best_d := 100000.0
	for foe in battle.hostile_targets(side):
		if same_road and int(foe.lane) != lane:
			continue
		var along := _along(foe)
		if along < -8.0:
			continue
		if _ignores_perch(foe):
			continue
		if _arm_is_short() and foe.has_method("is_airborne") and foe.is_airborne():
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
	return str(data.get("id", "")) == "berserker" and not bool(data.get("trial", false))


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
		first.take_damage(amount, true, "boss", reach)
		boss_marks.append(first.global_position)
	if second != null:
		second.take_damage(amount, true, "boss", reach)
		boss_marks.append(second.global_position)


func _along(other) -> float:
	return (other.position.x - position.x) * facing


func _ignores_perch(foe) -> bool:
	if foe == null or not is_instance_valid(foe) or not foe.has_method("is_perched"):
		return false
	if not foe.is_perched():
		return false
	return str(data.get("id", "")) != "archer"


func _collect_ahead(limit: float) -> Array:
	var found: Array = []
	for body in battle.hostile_targets(side):
		if int(body.lane) != lane and not battle.is_boss(body):
			continue
		var span := _along(body)
		if span < -8.0 or span > limit:
			continue
		found.append(body)
	return found


func _hardest(group: Array):
	var pick = null
	var best := -1.0
	for body in group:
		var rating := 0.0
		if body.has_method("damage_rating"):
			rating = float(body.damage_rating())
		if pick == null or rating > best:
			best = rating
			pick = body
	return pick


func _strike_viper(amount: float, reach: float, gate) -> void:
	Sfx.play("hit_pierce", randf_range(0.92, 1.06), -6.0)
	var ahead := _collect_ahead(100000.0)
	var within := _collect_ahead(reach + 8.0)
	var hold := ahead.size() < 2
	var victim = _hardest(within)
	if victim != null:
		var bit = victim.take_damage(amount, true, "viper", reach)
		if hold and bit == true and is_instance_valid(victim) and victim.alive and victim.has_method("apply_numb"):
			victim.apply_numb(2.0)
		return
	if gate != null and abs(position.x - gate.front_x) <= minf(reach, 150.0) + 6.0:
		gate.take_damage(amount)


func _strike_storm(amount: float, reach: float, foe, gate) -> void:
	Sfx.play("hit_magic", randf_range(0.94, 1.05), -4.0)
	var front = null
	if foe != null and is_instance_valid(foe) and foe.alive and int(foe.lane) == lane and _along(foe) <= reach + 8.0:
		front = foe
	var pool: Array = []
	for body in battle.hostile_targets(side):
		if body == front:
			continue
		pool.append(body)
	pool.shuffle()
	var hits: Array = []
	if front != null:
		hits.append(front)
	var extra := 4
	if front == null:
		extra = 5
	var room := mini(extra, pool.size())
	for pick_i in room:
		hits.append(pool[pick_i])
	bolt_marks.clear()
	for struck in hits:
		var zapped = struck.take_damage(amount, true, "storm", reach)
		if zapped == true and is_instance_valid(struck) and struck.alive:
			if struck.has_method("apply_numb"):
				struck.apply_numb(1.0)
			if struck.has_method("show_bones"):
				struck.show_bones()
		bolt_marks.append(struck.global_position)
	bolt_t = 0.55
	if front == null and gate != null and abs(position.x - gate.front_x) <= minf(reach, 150.0) + 6.0:
		gate.take_damage(amount)


func _support_target():
	var best = null
	var best_score := -1.0
	for ally in battle.support_candidates(side):
		if ally == self or not ally.alive or int(ally.lane) != lane:
			continue
		var along: float = float(ally.position.x - position.x) * facing
		if along < -4.0 or along > float(data["reach"]):
			continue
		var held := 0.0
		if ally.has_method("numb_left"):
			held = float(ally.numb_left())
		var score: float
		if role == "heal" and held > 0.0:
			score = 300000.0 + held
		elif role == "heal":
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
		position.x = clampf(position.x, battle.player_rear, battle.enemy_front)
	else:
		position.x = clampf(position.x, battle.player_front, battle.enemy_rear)


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
	return {
		"phase": phase,
		"t": t,
		"clock": bob_time,
		"flash": flash,
		"beat": beat,
		"hang": hang,
		"calling": call_flash > 0.0,
		"roost": roost,
		"spears": throws_left,
		"loading": loading,
		"sit": sit_left,
	}


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


# A crowded fight used to rebuild every body from polygons on every frame.
# Hold that picture until the walk or attack frame, facing, skin, or hurt flash changes.
func _keep_picture() -> void:
	var stamp := _picture_key()
	if stamp == _picture_stamp:
		return
	_picture_stamp = stamp
	queue_redraw()


func _picture_key() -> String:
	var pose := _pose()
	var phase := str(pose["phase"])
	var along := float(pose["t"])
	var beat := int(pose["beat"])
	var clock := float(pose["clock"])
	var frame := _held_frame(phase, along, beat, clock)
	var skin: Color = look["skin"]
	var cloth: Color = look["cloth"]
	var trim: Color = look["trim"]
	var flash_on := 0
	if float(pose["flash"]) > 0.04:
		flash_on = 1
	var face := 1
	if facing < 0.0:
		face = -1
	var weapon := str(look.get("weapon", ""))
	var paint := str(look.get("paint", ""))
	var faction := str(look.get("faction", ""))
	var horns := 0
	if bool(look.get("horns", false)):
		horns = 1
	var sash := 0
	if bool(look.get("sash", false)):
		sash = 1
	var sheet := 0
	if bool(look.get("sheet", false)):
		sheet = 1
	var helm := str(look.get("helm", ""))
	var mount := 0
	if bool(look.get("mount", false)):
		mount = 1
	var sc := int(round(_body_scale() * 20.0))
	var hang_i := int(clampf(hang, 0.0, 1.0) * 4.0)
	var roost_on := 0
	if float(pose["roost"]) > 0.05:
		roost_on = 1
	var calling := 0
	if bool(pose["calling"]):
		calling = 1
	var spears := int(pose["spears"])
	var loading_on := 0
	if float(pose["loading"]) > 0.05:
		loading_on = 1
	var sit_on := 0
	if float(pose["sit"]) > 0.05:
		sit_on = 1
	var hp_i := int(round(hp))
	var max_i := int(round(max_hp))
	var stacks := level_stacks
	var blink_on := 0
	if role == "assassin" and blink_wait <= 0.0:
		blink_on = 1
	var bolt_on := 0
	if bolt_t > 0.02:
		bolt_on = 1
	var bone_on := 0
	if bone_t > 0.02:
		bone_on = 1
	var numb_on := 0
	if numb > 0.02:
		numb_on = 1
	var strike_on := 0
	if show_strike and lunge > 0.05:
		strike_on = 1
	var link := _link_stamp()
	return "%s.%d.%d.%s.%s.%s.%s.%s.%s.%s.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%d.%s" % [
		phase, frame, face,
		skin.to_html(false), cloth.to_html(false), trim.to_html(false),
		paint, weapon, faction, helm,
		flash_on, horns, sash, sheet, mount, sc, hang_i, roost_on, calling,
		spears, loading_on, sit_on, hp_i, max_i, stacks,
		blink_on, bolt_on, bone_on, numb_on, strike_on,
		link,
	]


func _held_frame(phase: String, along: float, beat: int, clock: float) -> int:
	var paint := str(data.get("paint", ""))
	var rate := 8.0
	if paint == "runner" or paint == "scout":
		rate = 11.0
	if phase == "march":
		return mini(7, int(fposmod(clock * rate, TAU) / TAU * 8.0))
	if phase == "act":
		var u := (float(beat) + clampf(along, 0.0, 0.999)) * 0.25
		var wobble := _pose_nudge
		var shown := clampf(u - wobble, 0.0, 0.999)
		var shown_beat := mini(3, int(shown * 4.0))
		var shown_t := shown * 4.0 - float(shown_beat)
		var swing := shown_beat * 2 + mini(1, int(shown_t * 2.0))
		if paint == "runner" or paint == "scout" or paint == "horse":
			swing += mini(3, int(fposmod(clock * rate, TAU) / TAU * 4.0)) * 8
		return swing
	if phase == "idle":
		var breath := mini(3, int(fposmod(clock * 2.1, TAU) / TAU * 4.0))
		return breath + _prop_frame(paint) * 4
	return mini(3, int(clampf(along, 0.0, 0.999) * 4.0)) + _prop_frame(paint) * 4


func _prop_frame(paint: String) -> int:
	if paint == "crow" or paint == "cow" or paint == "storm" or paint == "viper":
		return mini(5, int(fposmod(bob_time * 6.0, TAU) / TAU * 6.0))
	return 0


func _link_stamp() -> String:
	var text := ""
	var spot := Vector2.ZERO
	if role == "drum":
		for marked in drum_targets:
			if marked != null and is_instance_valid(marked) and marked.alive:
				spot = marked.position
				text += _cell(spot)
	elif support_target != null and is_instance_valid(support_target) and support_target.alive:
		spot = support_target.position
		text = _cell(spot)
	if bolt_t > 0.02:
		for bolt_at in bolt_marks:
			spot = bolt_at
			text += _cell(spot)
	if _is_boss():
		for mark in boss_marks:
			spot = mark
			text += _cell(spot)
	return text


func _cell(at: Vector2) -> String:
	return "%d,%d;" % [int(at.x) >> 3, int(at.y) >> 3]


func _draw() -> void:
	var sc := _body_scale()
	var shift := _body_shift(sc)
	var bob := 0.0
	if moving and alive and debut <= 0.0:
		bob = sin(bob_time * 8.0) * 1.5
	var lift := -58.0 * hang
	if role == "moth":
		lift -= 46.0
	draw_set_transform(Vector2(0, bob + shift + lift), 0, Vector2(facing * sc, sc))
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
	if role == "assassin" and blink_wait <= 0.0:
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
	if bolt_t > 0.0:
		var glow := clampf(bolt_t / 0.55, 0.0, 1.0)
		var bolt_i := 0
		for bolt_at in bolt_marks:
			var tip := to_local(bolt_at)
			var mid := tip * 0.5 + Vector2(sin(tip.y * 0.07 + float(bolt_i)) * 18.0, -22.0)
			draw_line(Vector2(0, -30), mid, Color(0.75, 0.92, 1.0, glow), 4.0)
			draw_line(mid, tip, Color(1.0, 0.98, 0.86, glow), 2.2)
			bolt_i += 1
	if bone_t > 0.0 or numb > 0.0:
		Painter.paint_ailment(self, bone_t, numb, bob_time)
	if role == "drum" or role == "aria":
		for note_i in 3:
			var nx := sin(bob_time * 3.0 + float(note_i)) * 8.0 + float(note_i) * 9.0
			var ny := -52.0 - float(note_i) * 7.0 + sin(bob_time * 5.0 + float(note_i)) * 3.0
			draw_circle(Vector2(nx, ny), 3.0, Color("f4efe4"))
			draw_line(Vector2(nx + 2.6, ny), Vector2(nx + 2.6, ny - 11.0), Color("f4efe4"), 1.3)
	if role == "drum":
		for marked in drum_targets:
			if marked != null and is_instance_valid(marked) and marked.alive:
				draw_line(Vector2(0, -20), to_local(marked.global_position), Color(0.9, 0.76, 0.42, 0.85), 2.0)
	elif support_target != null and is_instance_valid(support_target) and support_target.alive:
		var to: Vector2 = to_local(support_target.global_position)
		var line := Color("8ee0a2") if role == "heal" else Color("e6c36a")
		draw_line(Vector2(0, -20), to, Color(line.r, line.g, line.b, 0.85), 2.0)
	if role == "fan" and lunge > 0.08:
		var gust := clampf(lunge, 0.0, 1.0)
		var gust_len := 180.0
		if battle != null:
			gust_len = absf(float(battle.enemy_front) - float(battle.player_front)) * 0.25
		for gust_i in 4:
			var gy := -30.0 + float(gust_i) * 12.0
			draw_line(Vector2(0, gy), Vector2(facing * gust_len, gy - 4.0), Color(0.75, 0.9, 0.86, gust * 0.75), 2.0)
