extends Node2D

const Stamp = preload("res://scripts/stamp_bake.gd")

var age: float = 0.0
var tint: Color = Color("d7c4ff")
var _ring: Sprite2D


func _ready() -> void:
	Stamp.ensure()
	_ring = Sprite2D.new()
	_ring.texture = Stamp.ring_tex
	_ring.centered = true
	_ring.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_ring)


func _process(delta: float) -> void:
	age += delta
	if _ring != null:
		var radius := 6.0 + age * 90.0
		var alpha := 1.0 - age / 0.32
		_ring.scale = Vector2.ONE * (radius / Stamp.ring_r)
		_ring.modulate = Color(tint.r, tint.g, tint.b, alpha)
	if age >= 0.32:
		queue_free()
