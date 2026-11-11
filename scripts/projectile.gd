extends Node2D

var velocity: Vector2 = Vector2.RIGHT
var damage: float = 0.0
var shooter_side: int = 0
var tint: Color = Color("f2d38a")
var traveled: float = 0.0
var max_dist: float = 360.0
var battle = null
var flying: bool = true


func setup(from: Vector2, aim_x: float, amount: float, side: int, color: Color, reach: float, field) -> void:
	battle = field
	position = from
	damage = amount
	shooter_side = side
	tint = color
	max_dist = reach
	var dir := 1.0 if aim_x >= from.x else -1.0
	velocity = Vector2(dir * 640.0, 0.0)
	z_index = 40


func _process(delta: float) -> void:
	if not flying or battle == null or battle.finished or battle.paused:
		return
	position += velocity * delta
	traveled += abs(velocity.x) * delta
	queue_redraw()
	if traveled >= max_dist:
		queue_free()
		return
	for foe in battle.hostile_targets(shooter_side):
		var dx: float = foe.position.x - position.x
		if abs(dx) <= 18.0 and dx * velocity.x >= -10.0:
			foe.take_damage(damage)
			_end()
			return
	var gate = battle.gate_for_attacker(shooter_side)
	if gate != null and gate.hp > 0.0:
		var gx: float = gate.front_x - position.x
		if abs(gx) <= 22.0 and gx * velocity.x >= -10.0:
			gate.take_damage(damage)
			_end()


func _end() -> void:
	flying = false
	Sfx.play("hit", randf_range(1.02, 1.18), -8.0)
	queue_free()


func _draw() -> void:
	var dir := 1.0 if velocity.x >= 0.0 else -1.0
	draw_line(Vector2(-12.0 * dir, 0), Vector2(8.0 * dir, 0), tint, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8.0 * dir, -4.0),
		Vector2(16.0 * dir, 0.0),
		Vector2(8.0 * dir, 4.0),
	]), tint)
