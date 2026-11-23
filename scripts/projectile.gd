extends Node2D

const SkillFx = preload("res://scripts/skill_fx.gd")

var velocity: Vector2 = Vector2.RIGHT
var damage: float = 0.0
var shooter_side: int = 0
var tint: Color = Color("f2d38a")
var traveled: float = 0.0
var max_dist: float = 360.0
var battle = null
var flying: bool = true
var lane: int = 0
var road_y: float = 0.0
var bold: bool = false
var hits_gate: bool = true
var homing: bool = false
var cosmetic: bool = false
var from_id: String = ""
var hazard: String = ""
var hazard_dmg: float = 0.0
var splash: float = 0.0
var trail: Array[Vector2] = []


func setup(from: Vector2, aim: Vector2, amount: float, side: int, color: Color, reach: float, road: int, field, heavy: bool = false, may_hit_gate: bool = true, seek_cross: bool = false, shot_from: String = "", hazard_kind: String = "", hazard_amount: float = 0.0, splash_reach: float = 0.0) -> void:
	battle = field
	position = from
	damage = amount
	shooter_side = side
	tint = color
	max_dist = reach
	lane = road
	road_y = from.y
	bold = heavy
	hits_gate = may_hit_gate
	homing = seek_cross
	from_id = shot_from
	hazard = hazard_kind
	hazard_dmg = hazard_amount
	splash = splash_reach
	var delta := aim - from
	if not seek_cross:
		delta.y = 0.0
	if delta.length() < 1.0:
		delta = Vector2(1.0 if aim.x >= from.x else -1.0, 0.0)
	velocity = delta.normalized() * (760.0 if heavy else 640.0)
	z_index = 560 if heavy else 520
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if not flying or battle == null or battle.finished or battle.paused:
		return
	var step := velocity * delta
	position += step
	traveled += step.length()
	if hazard == "fire":
		trail.append(position)
		while trail.size() > 8:
			trail.pop_front()
		queue_redraw()
	if traveled >= max_dist:
		queue_free()
		return
	if cosmetic:
		return
	for foe in battle.hostile_targets(shooter_side):
		if _perch_miss(foe):
			continue
		if _hits(foe):
			var road := lane
			if "lane" in foe:
				road = int(foe.lane)
			var at := Vector2(float(foe.position.x), battle.lane_y(road))
			_drop_hazard(at, road)
			if splash > 0.0 and battle.has_method("splash_foes"):
				battle.splash_foes(at, road, damage, shooter_side, splash)
			else:
				foe.take_damage(damage, false, from_id, max_dist)
			_end()
			return
	if not hits_gate:
		return
	var gate = battle.gate_for_attacker(shooter_side)
	if gate != null and gate.hp > 0.0:
		var gx: float = gate.front_x - position.x
		if abs(gx) <= 22.0 and gx * velocity.x >= -10.0:
			var gate_at := Vector2(gate.front_x, road_y)
			_drop_hazard(gate_at, lane)
			gate.take_damage(damage)
			if splash > 0.0 and battle.has_method("splash_foes"):
				battle.splash_foes(gate_at, lane, damage, shooter_side, splash)
			_end()


func _perch_miss(foe) -> bool:
	if from_id == "archer":
		return false
	if foe != null and foe.has_method("is_perched") and foe.is_perched():
		return true
	return false


func _hits(foe) -> bool:
	var dx: float = foe.position.x - position.x
	if dx * velocity.x < -10.0:
		return false
	if battle.is_boss(foe):
		return absf(dx) <= 56.0
	if homing and battle.is_berserker(foe):
		return Vector2(dx, foe.position.y - position.y).length() <= 26.0
	if int(foe.lane) != lane:
		return false
	if abs(position.y - road_y) > 30.0:
		return false
	return abs(dx) <= 20.0


func _drop_hazard(at: Vector2, road: int) -> void:
	if hazard == "" or battle == null or not battle.has_method("lay_hazard"):
		return
	battle.lay_hazard(hazard, road, at, 3.0, hazard_dmg)


func _end() -> void:
	flying = false
	Sfx.play("hit", randf_range(1.02, 1.18), -8.0)
	queue_free()


func _draw() -> void:
	var dir := velocity.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var tail := 34.0 if bold else 14.0
	var tip := 18.0 if bold else 8.0
	var width := 8.0 if bold else 3.0
	if bold:
		draw_line(-dir * tail, dir * tip, Color(tint.r, tint.g, tint.b, 0.35), width + 10.0)
	draw_line(-dir * tail, dir * tip, tint, width)
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([
		dir * tip + side * (6.0 if bold else 4.0),
		dir * (tip + (12.0 if bold else 8.0)),
		dir * tip - side * (6.0 if bold else 4.0),
	]), tint)
	if hazard == "fire":
		_draw_fire_trail()


func _draw_fire_trail() -> void:
	var count: int = trail.size()
	var i: int = 0
	while i < count:
		var spot: Vector2 = trail[i] - position
		var fade: float = float(i + 1) / float(count)
		var frame: int = 4 + (i % 4)
		var wide: float = 20.0 + fade * 22.0
		SkillFx.blit(self, "ex", frame, Rect2(spot.x - wide * 0.5, spot.y - wide * 0.85, wide, wide * 0.9), false, Color(1, 1, 1, 0.4 + fade * 0.6))
		i += 1
