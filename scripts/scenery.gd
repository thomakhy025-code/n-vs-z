extends Node2D

var stars: PackedVector2Array = PackedVector2Array()
var ash: Array = []


func _ready() -> void:
	z_index = -10
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for _i in 48:
		stars.append(Vector2(rng.randf(), rng.randf() * 0.48))
	for _j in 28:
		ash.append(Vector2(rng.randf(), rng.randf()))


func metrics() -> Dictionary:
	var size := get_viewport_rect().size
	if size.x < 200.0:
		size = Vector2(1280, 720)
	var side := sqrt(size.x * size.y / 20.0)
	var button_top := size.y - 14.0 - side
	var top := size.y * 0.34
	var bottom := button_top - 36.0
	if bottom < top + 90.0:
		bottom = top + 90.0
	var mid := (top + bottom) * 0.5
	return {
		"size": size,
		"ground_y": mid,
		"lane_ys": [top, mid, bottom],
	}


func _process(delta: float) -> void:
	for i in ash.size():
		var flake: Vector2 = ash[i]
		flake.y += delta * (0.018 + float(i % 5) * 0.006)
		flake.x += sin(Time.get_ticks_msec() * 0.001 + float(i)) * delta * 0.01
		if flake.y > 1.05:
			flake = Vector2(randf(), -0.04)
		ash[i] = flake
	queue_redraw()


func _draw() -> void:
	var info := metrics()
	var size: Vector2 = info["size"]
	var lanes: Array = info["lane_ys"]
	var horizon: float = float(lanes[0]) - 28.0
	var bands := 10
	for band in bands:
		var t := float(band) / float(bands)
		var color := Color("0c1020").lerp(Color("5a3040"), t)
		draw_rect(Rect2(0, horizon * t, size.x, horizon / float(bands) + 1.0), color)
	for star in stars:
		draw_circle(Vector2(star.x * size.x, star.y * horizon), 1.4, Color("f3e6c8"))
	var moon := Vector2(size.x * 0.78, horizon * 0.28)
	draw_circle(moon, 42, Color("f4e2b0"))
	draw_circle(moon + Vector2(-14, -2), 34, Color("12162a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon * 0.92),
		Vector2(size.x * 0.22, horizon * 0.58),
		Vector2(size.x * 0.4, horizon * 0.86),
		Vector2(size.x * 0.58, horizon * 0.52),
		Vector2(size.x * 0.78, horizon * 0.82),
		Vector2(size.x, horizon * 0.48),
		Vector2(size.x, horizon),
		Vector2(0, horizon),
	]), Color("1b2438"))
	_tree(Vector2(size.x * 0.9, horizon), 1.0)
	_tree(Vector2(size.x * 0.84, horizon + 4), 0.7)
	draw_rect(Rect2(0, horizon - 6, size.x, size.y - horizon + 6), Color("241c16"))
	for road_y in lanes:
		var y := float(road_y)
		draw_rect(Rect2(0, y - 16.0, size.x, 32.0), Color("3d3126"))
		draw_line(Vector2(0, y - 16.0), Vector2(size.x, y - 16.0), Color("2a2118"), 3.0)
		draw_line(Vector2(0, y + 16.0), Vector2(size.x, y + 16.0), Color("2a2118"), 3.0)
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("6b5340"), 1.0)
	for i in 18:
		var x := 40.0 + float(i) * (size.x / 18.0)
		draw_line(Vector2(x, horizon + 8.0), Vector2(x + 8.0, horizon + 22.0), Color("3e4a32"), 2.0)
	for flake in ash:
		draw_circle(Vector2(flake.x * size.x, flake.y * size.y), 1.6, Color(1, 1, 1, 0.28))


func _tree(at: Vector2, scale: float) -> void:
	draw_rect(Rect2(at.x - 3 * scale, at.y - 46 * scale, 6 * scale, 46 * scale), Color("1a1714"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(at.x, at.y - 78 * scale),
		Vector2(at.x - 16 * scale, at.y - 40 * scale),
		Vector2(at.x + 14 * scale, at.y - 42 * scale),
	]), Color("152033"))
