extends Node2D

const Buff = preload("res://scripts/level_buff.gd")
const Painter = preload("res://scripts/painter.gd")
const FrameBake = preload("res://scripts/frame_bake.gd")
const Stamp = preload("res://scripts/stamp_bake.gd")

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
var swing_wait: float = 0.0
var swing_leg: int = 0
var swing_u: float = 0.0
var swing_a: Vector2 = Vector2.ZERO
var swing_b: Vector2 = Vector2.ZERO
var swing_c: Vector2 = Vector2.ZERO
var storm_chain: Array = []
var storm_pending = null
var storm_from: Vector2 = Vector2.ZERO
var storm_to: Vector2 = Vector2.ZERO
var storm_hop: float = 1.0
var storm_amount: float = 0.0
var storm_reach: float = 330.0
var cast_t: float = 0.0
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
var root_left: float = 0.0
var frost_time: float = 0.0
var _phase_name: String = "idle"
var _phase_t: float = 0.0
var _phase_beat: int = 0
var _body_sprite: Sprite2D = null
var _flash_mat: ShaderMaterial = null
var _sheet_tex: Texture2D = null
var _bound_key: String = ""
var _shown_slot: int = -1
var _shown_wash: float = -1.0
var _bake_key: String = ""
var _key_skin: int = -1
var _key_cloth: int = -1
var _key_trim: int = -1
var _key_eye: int = -1
var _key_mask: int = -1
var _key_scarf: int = -1
var _key_blade: int = -1
var _key_dress: String = ""
var _key_bits: int = -99999
var _key_flags: int = -1
var _key_weapon: String = ""
var _key_paint: String = ""
var _key_faction: String = ""
var _key_helm: String = ""
var _bar_shell: Node2D = null
var _bar_hp: int = -99999
var _bar_max: int = -99999
var _bar_stacks: int = -99999
var _bar_bits: int = -1


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
		swing_wait = 0.48
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
	var body := Sprite2D.new()
	body.centered = false
	body.offset = FrameBake.offset()
	body.region_enabled = true
	body.region_filter_clip_enabled = true
	body.region_rect = FrameBake.region(0)
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body.z_index = 0
	_flash_mat = FrameBake.flash_material()
	body.material = _flash_mat
	add_child(body)
	_body_sprite = body
	var bars := BarShell.new()
	bars.host = self
	bars.z_index = 1
	add_child(bars)
	_bar_shell = bars


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
	if str(data.get("id", "")) == "viper" and randf() < 0.4:
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
	heal_flash = maxf(0.0, heal_flash - delta)
	cast_t = maxf(0.0, cast_t - delta)
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
	elif winding and not strike_sent and numb <= 0.0:
		var weapon := str(look.get("weapon", "katana"))
		var clock := _act_clock()
		if Painter.strike_due(weapon, int(clock.x), clock.y):
			strike_sent = true
			_resolve_strike()
	if act <= 0.0:
		winding = false
	if lunge <= 0.0:
		show_strike = false
	if battle != null and not battle.puppet and not battle.finished and not battle.paused:
		if role == "storm" or storm_pending != null or not storm_chain.is_empty():
			_tick_storm(delta)
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
	if diving:
		z_index = 480
	elif _spans_roads() and battle.lane_ys.size() > 0:
		z_index = int(battle.lane_ys[battle.lane_ys.size() - 1]) + 24
	else:
		z_index = int(position.y)
	_keep_picture()


func _pace() -> float:
	if root_left > 0.0:
		return 0.0
	if battle != null and battle.has_method("chill_pace"):
		return float(battle.chill_pace(self))
	return 1.0


func _walk(delta: float, rush: float = 1.0) -> void:
	var pace := _pace()
	if pace <= 0.0:
		moving = false
		return
	position.x += facing * float(data["speed"]) * rush * pace * delta


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
	if str(data.get("id", "")) == "bomber":
		var marked = _marked_berserker()
		if marked != null:
			foe = marked
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
		_walk(delta, rush)
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
			cast_t = 0.55
			winding = true
			strike_sent = false
			support_pulse = false
	else:
		target = _support_target()
		if role == "heal" and target != null and attack_timer <= 0.0 and not winding:
			attack_timer = float(data["interval"])
			act = 1.0
			cast_t = 0.55
			winding = true
			strike_sent = false
			support_pulse = true
			pending_foe = target
		elif role == "buff":
			battle.set_buff_link(self, target)
			if target != null and attack_timer <= 0.0 and not winding:
				attack_timer = float(data["interval"])
				act = 1.0
				cast_t = 0.55
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
	_walk(delta)
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
				_walk(delta)
				_clamp_x()
			return
		if _along(prey) <= reach:
			_try_strike(prey, gate)
			return
		moving = true
		_walk(delta)
		_clamp_x()
		return
	if gate != null and abs(position.x - gate.front_x) <= siege + 6.0:
		_try_strike(null, gate)
		return
	moving = true
	_walk(delta)
	_clamp_x()


func _step_toward_lane(index: int, delta: float) -> void:
	var pace := _pace()
	if pace <= 0.0:
		return
	var goal_y: float = battle.lane_y(index)
	var gap: float = goal_y - position.y
	var step := float(data["speed"]) * pace * delta
	if absf(gap) <= step:
		position.y = goal_y
		lane = index
	else:
		position.y += signf(gap) * step


func _try_blink() -> void:
	if blink_wait > 0.0 or _pace() <= 0.0:
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
	moving = false
	var pace := _pace()
	if diving:
		if pace > 0.0:
			_swing_step(delta * pace)
		return
	if pace <= 0.0:
		return
	if swing_wait > 0.0:
		swing_wait -= delta
		hang = 1.0
		act = 0.0
		return
	_start_swing()


func _start_swing() -> void:
	var prey = _closest_prey()
	diving = true
	swing_leg = 0
	swing_u = 0.0
	dive_t = 0.0
	dive_from = position
	dive_prey = prey
	var land_x: float = float(battle.enemy_front) - 48.0
	var land_lane := lane
	if prey != null and is_instance_valid(prey) and prey.alive:
		land_lane = int(prey.lane)
		land_x = float(prey.position.x) - facing * 28.0
		land_x = clampf(land_x, battle.player_front + 10.0, battle.enemy_front - 10.0)
	dive_lane = land_lane
	dive_aim = Vector2(land_x, battle.lane_y(land_lane))
	swing_a = dive_from
	swing_c = dive_aim
	swing_b = Vector2((swing_a.x + swing_c.x) * 0.5, minf(swing_a.y, swing_c.y) - 150.0)
	act = 0.7
	hang = 1.0


func _swing_step(delta: float) -> void:
	swing_u += delta / 0.42
	if swing_u >= 1.0 and swing_leg == 0:
		swing_leg = 1
		swing_u = 0.0
		swing_a = swing_c
		var land := dive_aim
		if dive_prey != null and is_instance_valid(dive_prey) and dive_prey.alive and _is_prey(dive_prey):
			var fresh_x: float = float(dive_prey.position.x) - facing * 28.0
			fresh_x = clampf(fresh_x, battle.player_front + 10.0, battle.enemy_front - 10.0)
			land = Vector2(fresh_x, battle.lane_y(int(dive_prey.lane)))
			dive_aim = land
			dive_lane = int(dive_prey.lane)
		swing_c = land
		swing_b = Vector2((swing_a.x + swing_c.x) * 0.5, minf(swing_a.y, swing_c.y) - 86.0)
	var glide := clampf(swing_u, 0.0, 1.0)
	var remain := 1.0 - glide
	position = swing_a * remain * remain + swing_b * 2.0 * remain * glide + swing_c * glide * glide
	if swing_leg == 0:
		hang = 1.0
	else:
		hang = 1.0 - glide
	lane = dive_lane
	act = 0.55
	moving = false
	if swing_leg == 0 or glide < 1.0:
		return
	diving = false
	perched = false
	hang = 0.0
	act = 0.0
	var landed = dive_prey
	dive_prey = null
	if landed != null and is_instance_valid(landed) and landed.alive and _is_prey(landed):
		var swing := float(data.get("swing", data["damage"])) * damage_multiplier
		landed.take_damage(swing, true, "howler", 70.0)
		lunge = 1.0
		Sfx.play("hit_blunt", randf_range(0.9, 1.02), -5.0)
	attack_timer = float(data["interval"])


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
			cast_t = 0.55
			if "heal_flash" in ally:
				ally.heal_flash = 0.55
			battle.float_text(ally.position + Vector2(0, -46), "+%d" % int(round(healed)), Color("8ee0a2"))
			Sfx.play("heal", randf_range(0.96, 1.05), -8.0)
		return
	if role == "buff" or role == "drum" or role == "aria":
		cast_t = 0.55
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
	_walk(delta)
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
		if not flyer.alive or not flyer.has_method("is_airborne") or not flyer.is_airborne():
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
	if battle == null or not battle.side_has_air(side):
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
	_walk(delta)
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
	_walk(delta)
	_clamp_x()


func _elder(delta: float) -> void:
	var mark = _nearest_anybody()
	if mark == null:
		moving = true
		_walk(delta, 0.45)
		_clamp_x()
		return
	var dx := float(mark.position.x) - position.x
	facing = 1.0 if dx >= 0.0 else -1.0
	if absf(dx) <= float(data["reach"]) + 6.0:
		moving = false
		_try_strike(mark, null)
		return
	moving = true
	_walk(delta)
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
		_walk(delta)
		_clamp_x()
		return
	var gate = battle.gate_for_attacker(side)
	moving = false
	if gate != null and abs(position.x - gate.front_x) <= 86.0:
		_try_strike(null, gate)
		return
	moving = true
	_walk(delta)
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


func _marked_berserker():
	var best = null
	var best_along := 100000.0
	for body in battle.hostile_targets(side):
		if not battle.is_berserker(body):
			continue
		var span := _along(body)
		if span < -8.0:
			continue
		if span < best_along:
			best_along = span
			best = body
	return best


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
	var pool: Array = battle.hostile_targets(side)
	if same_road:
		pool = battle.foes_on_lane(side, lane)
	for foe in pool:
		if not foe.alive:
			continue
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
	for foe in battle.wides_for(side):
		if not foe.alive:
			continue
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
	storm_chain = []
	if front != null:
		storm_chain.append(front)
	var extra := 4
	if front == null:
		extra = 5
	var room := mini(extra, pool.size())
	for pick_i in room:
		storm_chain.append(pool[pick_i])
	storm_amount = amount
	storm_reach = reach
	storm_pending = null
	storm_hop = 1.0
	storm_from = global_position
	storm_to = storm_from
	bolt_marks.clear()
	bolt_t = 0.0
	if front == null and gate != null and abs(position.x - gate.front_x) <= minf(reach, 150.0) + 6.0:
		gate.take_damage(amount)


func _tick_storm(delta: float) -> void:
	if storm_pending != null:
		storm_hop = minf(1.0, storm_hop + delta / 0.16)
		if storm_hop < 1.0:
			return
		var landed = storm_pending
		storm_pending = null
		_land_storm(landed)
	if storm_chain.is_empty():
		return
	_open_storm_hop()


func _open_storm_hop() -> void:
	while not storm_chain.is_empty():
		var raw: Variant = storm_chain[0]
		storm_chain.remove_at(0)
		if not (raw is Node2D):
			continue
		var body = raw
		if not is_instance_valid(body) or not body.alive:
			continue
		storm_pending = body
		storm_to = body.global_position
		storm_hop = 0.0
		bolt_t = 0.55
		return
	storm_pending = null


func _land_storm(target) -> void:
	if target == null or not is_instance_valid(target):
		return
	var struck = target
	if struck.alive:
		var zapped = struck.take_damage(storm_amount, true, "storm", storm_reach)
		if zapped == true and is_instance_valid(struck) and struck.alive:
			if struck.has_method("apply_numb"):
				struck.apply_numb(1.0)
			if struck.has_method("show_bones"):
				struck.show_bones()
	bolt_marks.append(struck.global_position)
	storm_from = struck.global_position
	bolt_t = 0.48
	Sfx.play("hit_magic", randf_range(1.02, 1.12), -12.0)


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


func _read_phase() -> void:
	_phase_name = "idle"
	_phase_t = 0.0
	_phase_beat = 0
	if not alive:
		_phase_name = "fall"
		_phase_t = clampf(fall_t / 0.6, 0.0, 1.0)
	elif numb > 0.0:
		_phase_name = "hurt"
		_phase_t = 0.0
	elif debut > 0.0 and act <= 0.0:
		_phase_name = "debut"
		_phase_t = 1.0 - clampf(debut / 0.46, 0.0, 1.0)
	elif act > 0.0:
		_phase_name = "act"
		var wind := 1.0 - clampf(act, 0.0, 1.0)
		_phase_beat = mini(3, int(wind * 4.0))
		_phase_t = clampf(wind * 4.0 - float(_phase_beat), 0.0, 1.0)
	elif hurt > 0.0:
		_phase_name = "hurt"
		_phase_t = 1.0 - clampf(hurt, 0.0, 1.0)
	elif moving:
		_phase_name = "march"


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


# The body is a shared baked frame. Blood, support lines, and bolts redraw without it.
func _keep_picture() -> void:
	_sync_body()
	_sync_bars()


func _sync_body() -> void:
	if _body_sprite == null:
		return
	FrameBake.warm_ring(self)
	var slot := _baked_slot()
	var key := _current_key()
	if key != _bound_key:
		_sheet_tex = null
		_body_sprite.texture = null
		_bound_key = ""
		_shown_slot = -1
	if _sheet_tex == null:
		var bits := _extra_bits()
		var tex := FrameBake.request(self, key, look, bits)
		if tex != null:
			_sheet_tex = tex
			_bound_key = key
			_body_sprite.texture = tex
			_shown_slot = -1
	if _sheet_tex != null and slot != _shown_slot:
		_shown_slot = slot
		_body_sprite.region_rect = FrameBake.region(slot)
	_place_sprite()
	_tint_sprite()


func _place_sprite() -> void:
	var sc := _body_scale()
	var bob := 0.0
	if moving and alive and debut <= 0.0:
		bob = sin(bob_time * 8.0) * 1.5
	var lift := -58.0 * hang
	if role == "moth":
		lift -= 46.0
	var shift := _body_shift(sc)
	var pos := Vector2(0.0, bob + shift + lift)
	if _body_sprite.position != pos:
		_body_sprite.position = pos
	var face := sc
	if facing < 0.0:
		face = -sc
	var scl := Vector2(face, sc)
	if _body_sprite.scale != scl:
		_body_sprite.scale = scl


func _tint_sprite() -> void:
	var tint := Color(1.0, 1.0, 1.0, 1.0)
	if hurt > 0.0 or numb > 0.0:
		tint = Color(1.0, 0.58, 0.54, 1.0)
	if _body_sprite.modulate != tint:
		_body_sprite.modulate = tint
	var wash := 0.0
	if flash > 0.04:
		wash = clampf(flash * 4.0, 0.0, 0.72)
	if _flash_mat != null and absf(wash - _shown_wash) > 0.03:
		_shown_wash = wash
		_flash_mat.set_shader_parameter("wash", wash)


func _baked_slot() -> int:
	_read_phase()
	if _phase_name == "act":
		return 4 + clampi(_phase_beat, 0, 3)
	if _phase_name == "march":
		var rate := 8.0
		var paint := str(data.get("paint", ""))
		if paint == "runner" or paint == "scout":
			rate = 11.0
		var stride := fposmod(bob_time * rate, TAU) / TAU
		return clampi(int(stride * 4.0), 0, 3)
	return 0


func _extra_bits() -> int:
	var bits := 0
	if hang > 0.45:
		bits |= 1
	if roost > 0.05:
		bits |= 2
	bits |= mini(maxi(throws_left, 0), 3) << 3
	if sit_left > 0.05:
		bits |= 32
	if loading > 0.05:
		bits |= 64
	if call_flash > 0.05:
		bits |= 128
	return bits


func _look_flags() -> int:
	var flags := 0
	if bool(look.get("mount", false)):
		flags |= 1
	if bool(look.get("sheet", false)):
		flags |= 2
	if bool(look.get("horns", false)):
		flags |= 4
	if bool(look.get("sash", false)):
		flags |= 8
	if bool(look.get("pack", true)):
		flags |= 16
	if bool(look.get("bare", false)):
		flags |= 32
	return flags


func _current_key() -> String:
	var skin: Color = look.get("skin", Color.BLACK)
	var cloth: Color = look.get("cloth", Color.BLACK)
	var trim: Color = look.get("trim", Color.BLACK)
	var eye: Color = look.get("eye", Color.BLACK)
	var mask: Color = look.get("mask", Color.BLACK)
	var scarf: Color = look.get("scarf", Color.BLACK)
	var blade: Color = look.get("blade", Color.BLACK)
	var skin_i := skin.to_rgba32()
	var cloth_i := cloth.to_rgba32()
	var trim_i := trim.to_rgba32()
	var eye_i := eye.to_rgba32()
	var mask_i := mask.to_rgba32()
	var scarf_i := scarf.to_rgba32()
	var blade_i := blade.to_rgba32()
	var weapon := str(look.get("weapon", ""))
	var paint := str(look.get("paint", ""))
	var faction := str(look.get("faction", ""))
	var helm := str(look.get("helm", ""))
	var dress := str(look.get("dress", ""))
	var bits := _extra_bits()
	var flags := _look_flags()
	if _bake_key != "" and skin_i == _key_skin and cloth_i == _key_cloth and trim_i == _key_trim and eye_i == _key_eye and mask_i == _key_mask and scarf_i == _key_scarf and blade_i == _key_blade and bits == _key_bits and flags == _key_flags and weapon == _key_weapon and paint == _key_paint and faction == _key_faction and helm == _key_helm and dress == _key_dress:
		return _bake_key
	_key_skin = skin_i
	_key_cloth = cloth_i
	_key_trim = trim_i
	_key_eye = eye_i
	_key_mask = mask_i
	_key_scarf = scarf_i
	_key_blade = blade_i
	_key_bits = bits
	_key_flags = flags
	_key_weapon = weapon
	_key_paint = paint
	_key_faction = faction
	_key_helm = helm
	_key_dress = dress
	_bake_key = FrameBake.make_key(look, bits)
	return _bake_key


func _sync_bars() -> void:
	if _bar_shell == null:
		return
	var hp_i := int(round(hp))
	var max_i := int(round(max_hp))
	var bits := 0
	if debut > 0.0 and alive:
		bits |= 1
	if show_strike and lunge > 0.05:
		bits |= 2
	if bolt_t > 0.02:
		bits |= 4
	if bone_t > 0.02 or numb > 0.02:
		bits |= 8
	if level_stacks > 0:
		bits |= 16
	if role == "assassin" and blink_wait <= 0.0 and alive:
		bits |= 32
	if (role == "drum" or role == "aria") and alive:
		bits |= 64
	if role == "fan" and lunge > 0.08 and alive:
		bits |= 128
	if _is_boss() and lunge > 0.12 and alive:
		bits |= 256
	if _is_berserker() and lunge > 0.12 and alive:
		bits |= 512
	var linked := false
	if alive and support_target != null and is_instance_valid(support_target) and support_target.alive:
		linked = true
	if alive and not drum_targets.is_empty():
		linked = true
	if linked:
		bits |= 1024
	if not alive:
		bits |= 2048
	if heal_flash > 0.02 or cast_t > 0.02:
		bits |= 4096
	var motion := bits & (1 | 2 | 4 | 8 | 64 | 128 | 256 | 512 | 1024 | 4096)
	if hp_i == _bar_hp and max_i == _bar_max and level_stacks == _bar_stacks and bits == _bar_bits and motion == 0:
		return
	_bar_hp = hp_i
	_bar_max = max_i
	_bar_stacks = level_stacks
	_bar_bits = bits
	_bar_shell.queue_redraw()


func draw_bars(ci: Node2D) -> void:
	if debut > 0.0 and alive:
		var ring := clampf(debut / 0.46, 0.0, 1.0)
		var radius := 16.0 + (1.0 - ring) * 14.0
		var at := Vector2(0, 10)
		if _spans_roads():
			radius = _road_span() * 0.48
			at = Vector2.ZERO
		ci.draw_arc(at, radius, 0, TAU, 24, Color(1, 0.9, 0.62, ring), 2.2)
	if not alive:
		return
	var sc := _body_scale()
	var shift := _body_shift(sc)
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var bar_y := -58.0 * sc
	if _spans_roads():
		bar_y = shift + BERSERK_TOP * sc - 14.0
	var bar_w := 36.0 * sc
	var bar_h := 8.0 if _spans_roads() else 5.0
	ci.draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.65))
	var fill := Color("7dce6a") if ratio > 0.35 else Color("e24b3b")
	ci.draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * ratio, bar_h), fill)
	if role == "assassin" and blink_wait <= 0.0:
		ci.draw_circle(Vector2(-bar_w * 0.5 - 6.0, bar_y + 2.0), 3.2, Color("c084fc"))
	if level_stacks > 0:
		ci.draw_circle(Vector2(bar_w * 0.5 + 6.0, bar_y + 2.0), 3.4, Color("e6c36a"))
	if _is_boss() and lunge > 0.12:
		var boss_alpha := clampf(lunge, 0.0, 1.0)
		for mark in boss_marks:
			ci.draw_line(Vector2(0, -20), ci.to_local(mark), Color(0.86, 0.16, 0.12, boss_alpha), 7.0)
	if _is_berserker() and lunge > 0.12:
		var reach := float(data["reach"])
		var alpha := clampf(lunge, 0.0, 1.0)
		for road_y in battle.lane_ys:
			var local_y := float(road_y) - position.y
			ci.draw_line(Vector2(0, -12), Vector2(facing * reach, local_y), Color(1, 0.72, 0.28, alpha * 0.9), 5.0)
	if show_strike and lunge > 0.05:
		ci.draw_line(Vector2(0, -16), ci.to_local(strike_to), Color(1, 0.86, 0.45, clampf(lunge, 0.0, 1.0)), 4.0)
	_draw_bolt(ci)
	_draw_heal_glow(ci)
	_draw_cast_fx(ci)
	if bone_t > 0.0 or numb > 0.0:
		Stamp.paint_ailment(ci, bone_t, numb, bob_time)
	if role == "drum" or role == "aria":
		var note_ink := Color("f4efe4")
		if role == "aria":
			note_ink = Color("d7c4ff")
		for note_i in 3:
			var nx := sin(bob_time * 3.0 + float(note_i)) * 8.0 + float(note_i) * 9.0
			var ny := -52.0 - float(note_i) * 7.0 + sin(bob_time * 5.0 + float(note_i)) * 3.0
			ci.draw_circle(Vector2(nx, ny), 3.0, note_ink)
			ci.draw_line(Vector2(nx + 2.6, ny), Vector2(nx + 2.6, ny - 11.0), note_ink, 1.3)
	if role == "drum" or role == "aria":
		var link_ink := Color("e6c36a")
		if role == "aria":
			link_ink = Color("d7c4ff")
		for marked in drum_targets:
			if marked != null and is_instance_valid(marked) and marked.alive:
				_draw_link(ci, ci.to_local(marked.global_position), link_ink)
	elif support_target != null and is_instance_valid(support_target) and support_target.alive:
		var to: Vector2 = ci.to_local(support_target.global_position)
		var line := Color("8ee0a2") if role == "heal" else Color("e6c36a")
		_draw_link(ci, to, line)
	if role == "fan" and lunge > 0.08:
		var gust := clampf(lunge, 0.0, 1.0)
		var gust_len := 180.0
		if battle != null:
			gust_len = absf(float(battle.enemy_front) - float(battle.player_front)) * 0.25
		for gust_i in 4:
			var gy := -30.0 + float(gust_i) * 12.0
			ci.draw_line(Vector2(0, gy), Vector2(facing * gust_len, gy - 4.0), Color(0.75, 0.9, 0.86, gust * 0.75), 2.0)


func _draw_bolt(ci: Node2D) -> void:
	if bolt_t <= 0.0 and storm_pending == null:
		return
	var glow := clampf(bolt_t / 0.48, 0.2, 1.0)
	var trail := Vector2.ZERO
	var started := false
	for mark in bolt_marks:
		var at: Vector2 = ci.to_local(mark)
		if started:
			ci.draw_line(trail, at, Color(0.55, 0.78, 1.0, glow * 0.4), 2.0)
		trail = at
		started = true
		ci.draw_circle(at, 3.6, Color(0.9, 0.97, 1.0, glow * 0.65))
	if storm_pending == null:
		return
	var tip_g := storm_from.lerp(storm_to, clampf(storm_hop, 0.0, 1.0))
	var origin: Vector2 = ci.to_local(storm_from)
	var tip: Vector2 = ci.to_local(tip_g)
	var mid1 := origin.lerp(tip, 0.34) + Vector2(sin(tip.y * 0.08 + bob_time * 18.0) * 14.0, -16.0)
	var mid2 := origin.lerp(tip, 0.67) + Vector2(cos(tip.x * 0.05 + bob_time * 14.0) * 12.0, 10.0)
	ci.draw_line(origin, mid1, Color(0.62, 0.86, 1.0, glow), 4.0)
	ci.draw_line(mid1, mid2, Color(0.86, 0.95, 1.0, glow), 3.2)
	ci.draw_line(mid2, tip, Color(1.0, 0.96, 0.72, glow), 2.4)
	ci.draw_circle(tip, 5.5, Color(1.0, 0.98, 0.86, glow))


func _draw_heal_glow(ci: Node2D) -> void:
	if heal_flash <= 0.02:
		return
	var glow := clampf(heal_flash / 0.55, 0.0, 1.0)
	var lift := (1.0 - glow) * 16.0
	var at := Vector2(0.0, -42.0 - lift)
	ci.draw_arc(at, 12.0, 0.0, TAU, 16, Color(0.56, 0.92, 0.68, glow), 2.2)
	ci.draw_line(at + Vector2(-7, 0), at + Vector2(7, 0), Color(0.85, 1.0, 0.9, glow), 2.4)
	ci.draw_line(at + Vector2(0, -7), at + Vector2(0, 7), Color(0.85, 1.0, 0.9, glow), 2.4)


func _draw_cast_fx(ci: Node2D) -> void:
	if cast_t <= 0.02 or role == "storm":
		return
	var fade := clampf(cast_t / 0.55, 0.0, 1.0)
	var tint := Color("e6c36a")
	if role == "heal":
		tint = Color("8ee0a2")
	elif role == "aria":
		tint = Color("d7c4ff")
	elif role == "drum":
		tint = Color("f0d78a")
	var spin := bob_time * 4.0
	var ring: Texture2D = FrameBake.ring_tex
	if ring == null:
		ci.draw_arc(Vector2(0, -28), 16.0 + (1.0 - fade) * 10.0, spin, spin + 4.2, 12, Color(tint.r, tint.g, tint.b, fade), 2.4)
		return
	var radius := 16.0 + (1.0 - fade) * 10.0
	var sc := radius / 16.0
	ci.draw_set_transform(Vector2(0.0, -28.0), spin, Vector2(sc, sc))
	ci.draw_texture(ring, Vector2(-32.0, -32.0), Color(tint.r, tint.g, tint.b, fade))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_link(ci: Node2D, to: Vector2, ink: Color) -> void:
	var from := Vector2(0, -20)
	ci.draw_line(from, to, Color(ink.r, ink.g, ink.b, 0.72), 2.0)
	for mote_i in 3:
		var u := fposmod(bob_time * 0.55 + float(mote_i) * 0.33, 1.0)
		ci.draw_circle(from.lerp(to, u), 2.6, Color(ink.r, ink.g, ink.b, 0.9))


class BarShell extends Node2D:
	var host = null

	func _draw() -> void:
		if host == null:
			return
		host.draw_bars(self)
