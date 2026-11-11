extends RefCounted


static func apply(node) -> void:
	node.level_stacks += 1
	_recompute(node)


static func remove(node) -> void:
	node.level_stacks = maxi(0, node.level_stacks - 1)
	_recompute(node)


static func _recompute(node) -> void:
	var new_mult := 1.0 + 0.2 * float(node.level_stacks)
	var new_max := float(node.base_max_hp) * new_mult
	var delta := new_max - float(node.max_hp)
	node.max_hp = new_max
	node.damage_multiplier = new_mult
	if not node.alive:
		return
	node.hp += delta
	if node.hp > node.max_hp:
		node.hp = node.max_hp
	if node.hp <= 0.0:
		node.hp = 0.0
		node.alive = false
		if node.has_method("on_buff_death"):
			node.on_buff_death()
