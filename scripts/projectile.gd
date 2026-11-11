extends Node2D

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


func setup(from: Vector2, aim: Vector2, amount: float, side: int, color: Color, reach: float, road: int, field, heavy: bool = false, may_hit_gate: bool = true, seek_cross: bool = false) -> void:
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
	var delta := aim - from
	if not seek_cross:
		delta.y = 0.0
	if delta.length() < 1.0:
		delta = Vector2(1.0 if aim.x >= from.x else -1.0, 0.0)
	velocity = delta.normalized() * (760.0 if heavy else 640.0)
	z_index = 560 if heavy else 520


func _process(delta: float) -> void:
	if not flying or battle == null or battle.finished or battle.paused:
		return
	var step := velocity * delta
	position += step
	traveled += step.length()
	queue_redraw()
	if traveled >= max_dist:
		queue_free()
		return
	for foe in battle.hostile_targets(shooter_side):
		if _hits(foe):
			foe.take_damage(damage)
			_end()
			return
	if not hits_gate:
		return
	var gate = battle.gate_for_attacker(shooter_side)
	if gate != null and gate.hp > 0.0:
		var gx: float = gate.front_x - position.x
		if abs(gx) <= 22.0 and gx * velocity.x >= -10.0:
			gate.take_damage(damage)
			_end()


func _hits(foe) -> bool:
	var dx: float = foe.position.x - position.x
	if dx * velocity.x < -10.0:
		return false
	if homing and battle.is_berserker(foe):
		return Vector2(dx, foe.position.y - position.y).length() <= 26.0
	if int(foe.lane) != lane:
		return false
	if abs(position.y - road_y) > 30.0:
		return false
	return abs(dx) <= 20.0


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
