extends RefCounted

# Shared fight stamps. A shape is drawn once into a texture, then moved,
# scaled, and tinted. Nothing here allocates a texture per unit per frame.

static var ready: bool = false
static var shapes: int = 0
static var pixel: Texture2D
static var disc_tex: Texture2D
static var ring_tex: Texture2D
static var flame_red: Texture2D
static var flame_orange: Texture2D
static var arrow_tex: Texture2D
static var arrow_bold: Texture2D
static var aim_tex: Texture2D
static var arc_outer: Texture2D
static var arc_inner: Texture2D
static var arc_ls: Texture2D
static var arc_fz: Texture2D
static var bone_tex: Texture2D
static var numb_tex: Texture2D
static var crystal: Texture2D
static var chip: Texture2D
static var shock: Texture2D
static var disc_r: float = 30.0
static var ring_r: float = 28.0
static var aim_r: float = 112.0
static var flame_anchor := Vector2(0.5, 1.0)
static var flame_unit: float = 48.0
static var bone_offset := Vector2.ZERO
static var numb_offset := Vector2.ZERO
static var crystal_px: float = 170.0
static var crystal_offset := Vector2.ZERO
static var chip_px: float = 140.0
static var chip_offset := Vector2.ZERO
static var shock_ref: float = 180.0
static var shock_offset := Vector2.ZERO
static var glow_mat: ShaderMaterial


static func ensure() -> void:
	if ready:
		return
	ready = true
	pixel = _tex(_solid(1, 1, Color.WHITE), false)
	disc_tex = _tex(_disc_image(64, 30.0), true)
	ring_tex = _tex(_ring_image(64, 28.0, 3.2), true)
	var red_flame: Dictionary = _flame_image(Color("c44536"))
	var orange_flame: Dictionary = _flame_image(Color("e07a28"))
	flame_red = red_flame["tex"]
	flame_orange = orange_flame["tex"]
	flame_anchor = red_flame["anchor"]
	flame_unit = float(red_flame["unit"])
	arrow_tex = _arrow_tex(false)
	arrow_bold = _arrow_tex(true)
	aim_tex = _tex(_aim_image(), true)
	arc_outer = _tex(_arc_image(148, 58.0, 10.0, -1.2, 1.15), true)
	arc_inner = _tex(_arc_image(104, 42.0, 5.0, -1.2, 1.15), true)
	arc_ls = _tex(_arc_image(96, 40.0, 2.4, 0.5, TAU - 0.4), true)
	arc_fz = _tex(_arc_image(96, 40.0, 2.2, 0.8, TAU - 0.6), true)
	_bake_marks()
	_bake_shock()


static func glow_material() -> ShaderMaterial:
	if glow_mat == null:
		var shader := Shader.new()
		shader.code = "shader_type canvas_item;\nrender_mode blend_add;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tif (dot(tex.rgb, vec3(1.0)) < 0.004) {\n\t\tdiscard;\n\t}\n\tCOLOR = vec4(tex.rgb * COLOR.a, 1.0);\n}\n"
		glow_mat = ShaderMaterial.new()
		glow_mat.shader = shader
	return glow_mat


static func apply_mesh(sprite: Sprite2D, xf: Transform2D, unit_px: float) -> void:
	var inv: float = 1.0 / maxf(unit_px, 0.001)
	var fit := Transform2D(Vector2(inv, 0.0), Vector2(0.0, inv), Vector2.ZERO)
	sprite.transform = xf * fit


static func disc(ci: CanvasItem, at: Vector2, radius: float, tint: Color) -> void:
	if disc_tex == null or radius < 0.15 or tint.a <= 0.004:
		return
	var side: float = radius / disc_r * float(disc_tex.get_width())
	ci.draw_texture_rect(disc_tex, Rect2(at.x - side * 0.5, at.y - side * 0.5, side, side), false, tint)


static func ring(ci: CanvasItem, at: Vector2, radius: float, tint: Color) -> void:
	if ring_tex == null or radius < 1.0 or tint.a <= 0.004:
		return
	var side: float = radius / ring_r * float(ring_tex.get_width())
	ci.draw_texture_rect(ring_tex, Rect2(at.x - side * 0.5, at.y - side * 0.5, side, side), false, tint)


static func aim(ci: CanvasItem, at: Vector2, radius: float) -> void:
	if aim_tex == null or radius < 4.0:
		return
	var side: float = radius / aim_r * float(aim_tex.get_width())
	ci.draw_texture_rect(aim_tex, Rect2(at.x - side * 0.5, at.y - side * 0.5, side, side), false, Color.WHITE)


static func paint_flame(ci: CanvasItem, base: Vector2, tall: float, orange: bool) -> void:
	var tex: Texture2D = flame_orange if orange else flame_red
	if tex == null or tall < 1.0:
		return
	var sc: float = tall / maxf(flame_unit, 1.0)
	var dw: float = float(tex.get_width()) * sc
	var dh: float = float(tex.get_height()) * sc
	var origin := Vector2(base.x - flame_anchor.x * dw, base.y - flame_anchor.y * dh)
	ci.draw_texture_rect(tex, Rect2(origin, Vector2(dw, dh)), false, Color.WHITE)


static func stroke(ci: CanvasItem, pts: PackedVector2Array, width: float, tint: Color) -> void:
	if pixel == null or pts.size() < 2 or width < 0.2 or tint.a <= 0.004:
		return
	var last: int = pts.size() - 1
	var i: int = 0
	while i < last:
		_seg(ci, pts[i], pts[i + 1], width, tint)
		i += 1


static func paint_ailment(ci: CanvasItem, bone: float, still: float, clock: float) -> void:
	ensure()
	if still > 0.0 and numb_tex != null:
		var ring_a: float = 0.28 + 0.22 * sin(clock * 6.0)
		_mark(ci, numb_tex, numb_offset, Color(0.62, 0.9, 0.7, ring_a))
	if bone <= 0.0 or bone_tex == null:
		return
	var blink: float = 0.2 + 0.8 * absf(sin(clock * 16.0))
	var chalk_a: float = clampf(bone / 0.9, 0.0, 1.0) * blink
	_mark(ci, bone_tex, bone_offset, Color(0.96, 0.94, 0.88, chalk_a))


static func bake_ice(spike: PackedVector2Array, spike_out: PackedVector2Array, chip_pts: PackedVector2Array, chip_out: PackedVector2Array) -> void:
	if crystal != null:
		return
	var built: Dictionary = _ice_tex(spike, spike_out, crystal_px, 0.42)
	crystal = built["tex"]
	crystal_offset = built["offset"]
	var chipped: Dictionary = _ice_tex(chip_pts, chip_out, chip_px, 0.58)
	chip = chipped["tex"]
	chip_offset = chipped["offset"]


static func bake_poly(pts: PackedVector2Array, fill: Color) -> Dictionary:
	ensure()
	if pts.size() < 3:
		return {"tex": pixel, "origin": Vector2.ZERO}
	var bounds: Rect2 = _bounds(pts, 1.0)
	var w: int = maxi(int(ceil(bounds.size.x)) + 2, 2)
	var h: int = maxi(int(ceil(bounds.size.y)) + 2, 2)
	var data: PackedByteArray = _bytes(w, h)
	var shifted: PackedVector2Array = PackedVector2Array()
	var n: int = pts.size()
	var i: int = 0
	while i < n:
		shifted.append(pts[i] - bounds.position + Vector2(1.0, 1.0))
		i += 1
	_fill_poly(data, w, h, shifted, fill)
	return {"tex": _tex(_image(w, h, data), true), "origin": bounds.position - Vector2(1.0, 1.0)}


static func _mark(ci: CanvasItem, tex: Texture2D, offset: Vector2, tint: Color) -> void:
	var pos := Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) * 0.5) + offset
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_texture(tex, pos, tint)


static func _seg(ci: CanvasItem, a: Vector2, b: Vector2, width: float, tint: Color) -> void:
	var delta: Vector2 = b - a
	var leng: float = delta.length()
	if leng < 0.35:
		return
	ci.draw_set_transform(a, delta.angle(), Vector2(leng, width))
	ci.draw_texture(pixel, Vector2(0.0, -0.5), tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _tex(img: Image, bleed: bool) -> Texture2D:
	if bleed:
		img.fix_alpha_edges()
	shapes += 1
	return ImageTexture.create_from_image(img)


static func _image(w: int, h: int, data: PackedByteArray) -> Image:
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


static func _bytes(w: int, h: int) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(w * h * 4)
	return data


static func _solid(w: int, h: int, fill: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	return img


static func _put(data: PackedByteArray, w: int, x: int, y: int, tint: Color) -> void:
	if x < 0 or y < 0:
		return
	var i: int = (y * w + x) * 4
	if i < 0 or i + 3 >= data.size():
		return
	data[i] = int(clampf(tint.r, 0.0, 1.0) * 255.0)
	data[i + 1] = int(clampf(tint.g, 0.0, 1.0) * 255.0)
	data[i + 2] = int(clampf(tint.b, 0.0, 1.0) * 255.0)
	data[i + 3] = int(clampf(tint.a, 0.0, 1.0) * 255.0)


static func _add(data: PackedByteArray, w: int, x: int, y: int, tint: Color, cover: float) -> void:
	if cover <= 0.0 or x < 0 or y < 0:
		return
	var i: int = (y * w + x) * 4
	if i < 0 or i + 3 >= data.size():
		return
	var nr: float = float(data[i]) / 255.0 + tint.r * cover
	var ng: float = float(data[i + 1]) / 255.0 + tint.g * cover
	var nb: float = float(data[i + 2]) / 255.0 + tint.b * cover
	var na: float = maxf(float(data[i + 3]) / 255.0, tint.a * cover)
	data[i] = int(clampf(nr, 0.0, 1.0) * 255.0)
	data[i + 1] = int(clampf(ng, 0.0, 1.0) * 255.0)
	data[i + 2] = int(clampf(nb, 0.0, 1.0) * 255.0)
	data[i + 3] = int(clampf(na, 0.0, 1.0) * 255.0)


static func _disc_image(side: int, radius: float) -> Image:
	var data: PackedByteArray = _bytes(side, side)
	var c := Vector2(float(side) * 0.5, float(side) * 0.5)
	var y: int = 0
	while y < side:
		var x: int = 0
		while x < side:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var a: float = clampf(radius + 0.6 - d, 0.0, 1.0)
			if a > 0.0:
				_put(data, side, x, y, Color(1, 1, 1, a))
			x += 1
		y += 1
	return _image(side, side, data)


static func _ring_image(side: int, radius: float, width: float) -> Image:
	var data: PackedByteArray = _bytes(side, side)
	var c := Vector2(float(side) * 0.5, float(side) * 0.5)
	var y: int = 0
	while y < side:
		var x: int = 0
		while x < side:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var a: float = clampf(width * 0.5 + 0.6 - absf(d - radius), 0.0, 1.0)
			if a > 0.0:
				_put(data, side, x, y, Color(1, 1, 1, a))
			x += 1
		y += 1
	return _image(side, side, data)


static func _arc_image(side: int, radius: float, width: float, a0: float, a1: float) -> Image:
	var data: PackedByteArray = _bytes(side, side)
	var c := Vector2(float(side) * 0.5, float(side) * 0.5)
	var y: int = 0
	while y < side:
		var x: int = 0
		while x < side:
			var rel := Vector2(float(x) + 0.5, float(y) + 0.5) - c
			var d: float = rel.length()
			var ang: float = atan2(rel.y, rel.x)
			if _in_sweep(ang, a0, a1):
				var a: float = clampf(width * 0.5 + 0.65 - absf(d - radius), 0.0, 1.0)
				if a > 0.0:
					_put(data, side, x, y, Color(1, 1, 1, a))
			x += 1
		y += 1
	return _image(side, side, data)


static func _in_sweep(ang: float, a0: float, a1: float) -> bool:
	var span: float = a1 - a0
	if span < 0.0:
		span += TAU
	var rel: float = ang - a0
	while rel < 0.0:
		rel += TAU
	while rel >= TAU:
		rel -= TAU
	return rel <= span


static func _flame_image(hot: Color) -> Dictionary:
	var tall := 48.0
	var half := 17.0
	var tip := Vector2(half * 0.15, -tall)
	var body := PackedVector2Array([Vector2(-half, 0.0), Vector2(half, 0.0), tip])
	var grown: PackedVector2Array = _grow(body, 4.0)
	var core := PackedVector2Array([
		Vector2(-half * 0.34, -tall * 0.22),
		Vector2(half * 0.28, -tall * 0.22),
		tip + Vector2(0.0, tall * 0.4),
	])
	var bounds: Rect2 = _bounds(grown, 2.0)
	var w: int = maxi(int(ceil(bounds.size.x)), 2)
	var h: int = maxi(int(ceil(bounds.size.y)), 2)
	var data: PackedByteArray = _bytes(w, h)
	_fill_poly(data, w, h, _shift(grown, bounds.position), Color("1c140e"))
	_fill_poly(data, w, h, _shift(body, bounds.position), hot)
	_fill_poly(data, w, h, _shift(core, bounds.position), Color("e6c36a"))
	var anchor := Vector2((0.0 - bounds.position.x) / float(w), (0.0 - bounds.position.y) / float(h))
	return {"tex": _tex(_image(w, h, data), true), "anchor": anchor, "unit": tall}


static func _arrow_tex(bold: bool) -> Texture2D:
	var tail: float = 34.0 if bold else 14.0
	var tip: float = 18.0 if bold else 8.0
	var head: float = 12.0 if bold else 8.0
	var width: float = 8.0 if bold else 3.0
	var reach: float = tail + tip + head + 8.0
	var span: float = (width + 14.0) if bold else (width + 10.0)
	var w: int = int(ceil(reach))
	var h: int = int(ceil(span))
	var data: PackedByteArray = _bytes(w, h)
	var origin := Vector2(tail + 4.0, float(h) * 0.5)
	if bold:
		_capsule(data, w, h, origin + Vector2(-tail, 0.0), origin + Vector2(tip, 0.0), (width + 10.0) * 0.5, Color(1, 1, 1, 0.35))
	_capsule(data, w, h, origin + Vector2(-tail, 0.0), origin + Vector2(tip, 0.0), width * 0.5, Color.WHITE)
	var side: float = 6.0 if bold else 4.0
	var tri := PackedVector2Array([
		origin + Vector2(tip, side),
		origin + Vector2(tip + head, 0.0),
		origin + Vector2(tip, -side),
	])
	_fill_poly(data, w, h, tri, Color.WHITE)
	var tex: Texture2D = _tex(_image(w, h, data), true)
	return tex


static func arrow_offset(bold: bool) -> Vector2:
	ensure()
	var tex: Texture2D = arrow_bold if bold else arrow_tex
	var tail: float = 34.0 if bold else 14.0
	var w: float = float(tex.get_width())
	var h: float = float(tex.get_height())
	var zero := Vector2(tail + 4.0, h * 0.5)
	return Vector2(w * 0.5 - zero.x, h * 0.5 - zero.y)


static func _aim_image() -> Image:
	var side := 256
	var data: PackedByteArray = _bytes(side, side)
	var c := Vector2(128.0, 128.0)
	var radius := 112.0
	var y: int = 0
	while y < side:
		var x: int = 0
		while x < side:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d <= radius:
				col = Color("c44536")
				col.a = 0.34
			var ink: float = clampf(6.2 - absf(d - radius), 0.0, 1.0)
			if ink > 0.0:
				col = _over(col, Color("1c140e", ink))
			var gold: float = clampf(3.1 - absf(d - (radius - 9.0)), 0.0, 1.0)
			if gold > 0.0:
				col = _over(col, Color("e6c36a", gold))
			if d <= 7.0:
				col = _over(col, Color("1c140e"))
			if d <= 3.2:
				col = Color("fff6c8")
			if col.a > 0.0:
				_put(data, side, x, y, col)
			x += 1
		y += 1
	return _image(side, side, data)


static func _over(under: Color, over: Color) -> Color:
	var a: float = over.a + under.a * (1.0 - over.a)
	if a <= 0.001:
		return Color(0, 0, 0, 0)
	var rgb: Color = (over * over.a + under * under.a * (1.0 - over.a)) / a
	rgb.a = a
	return rgb


static func _bake_marks() -> void:
	var bone_lines: Array = [
		[Vector2(-12, -36), Vector2(-3, -18), 2.4],
		[Vector2(10, -38), Vector2(2, -16), 2.4],
		[Vector2(-8, -6), Vector2(11, 0), 2.4],
		[Vector2(-5, -48), Vector2(5, -43), 1.8],
	]
	var bone_pack: Dictionary = _mark_image(bone_lines, Vector2(0, -46), 3.4)
	bone_tex = bone_pack["tex"]
	bone_offset = bone_pack["offset"]
	var numb_pack: Dictionary = _numb_image()
	numb_tex = numb_pack["tex"]
	numb_offset = numb_pack["offset"]


static func _mark_image(lines: Array, dot: Vector2, dot_r: float) -> Dictionary:
	var min_v := Vector2(-20, -56)
	var max_v := Vector2(20, 8)
	var w: int = int(max_v.x - min_v.x)
	var h: int = int(max_v.y - min_v.y)
	var data: PackedByteArray = _bytes(w, h)
	for raw in lines:
		var row: Array = raw
		var a: Vector2 = row[0]
		var b: Vector2 = row[1]
		var width: float = float(row[2])
		_capsule(data, w, h, a - min_v, b - min_v, width * 0.5, Color.WHITE)
	_fill_circle(data, w, h, dot - min_v, dot_r, Color.WHITE)
	var zero := Vector2(-min_v.x, -min_v.y)
	var offset := Vector2(float(w) * 0.5 - zero.x, float(h) * 0.5 - zero.y)
	return {"tex": _tex(_image(w, h, data), true), "offset": offset}


static func _numb_image() -> Dictionary:
	var min_v := Vector2(-30.0, -48.0)
	var side_w := 60
	var side_h := 60
	var data: PackedByteArray = _bytes(side_w, side_h)
	var center := Vector2(0.0, -18.0) - min_v
	var y: int = 0
	while y < side_h:
		var x: int = 0
		while x < side_w:
			var rel := Vector2(float(x) + 0.5, float(y) + 0.5) - center
			var ang: float = atan2(rel.y, rel.x)
			if ang < 0.0:
				ang += TAU
			if _in_sweep(ang, 0.4, TAU - 0.2):
				var a: float = clampf(1.7 - absf(rel.length() - 24.0), 0.0, 1.0)
				if a > 0.0:
					_put(data, side_w, x, y, Color(1, 1, 1, a))
			x += 1
		y += 1
	var zero := Vector2(0.0, 0.0) - min_v
	var offset := Vector2(float(side_w) * 0.5 - zero.x, float(side_h) * 0.5 - zero.y)
	return {"tex": _tex(_image(side_w, side_h, data), true), "offset": offset}


static func _bake_shock() -> void:
	var ref := shock_ref
	var tris: Array = []
	var wedges: Array[Vector3] = [
		Vector3(0.02, 0.61, 1.02),
		Vector3(0.78, 0.36, 1.06),
		Vector3(1.32, 0.69, 0.97),
		Vector3(2.17, 0.28, 1.04),
		Vector3(2.62, 0.65, 1.0),
		Vector3(3.45, 0.34, 1.03),
		Vector3(4.05, 0.52, 0.95),
		Vector3(4.83, 0.77, 1.01),
		Vector3(5.84, 0.29, 0.97),
	]
	var blue := Color(0.015, 0.22, 0.42, 1.0)
	var ice := Color(0.30, 0.80, 1.0, 1.0)
	var edge := Color(0.79, 0.98, 1.0, 1.0)
	var w: int = 0
	while w < wedges.size():
		var wedge: Vector3 = wedges[w]
		_shock_wedge(tris, ref, wedge.x, wedge.y, wedge.z, blue, ice, edge)
		w += 1
	var min_v := Vector2.ZERO
	var max_v := Vector2.ZERO
	var started := false
	for raw in tris:
		var tri: Dictionary = raw
		var corner: int = 0
		while corner < 3:
			var key := "a"
			if corner == 1:
				key = "b"
			elif corner == 2:
				key = "c"
			var p: Vector2 = tri[key]
			if not started:
				min_v = p
				max_v = p
				started = true
			else:
				min_v.x = minf(min_v.x, p.x)
				min_v.y = minf(min_v.y, p.y)
				max_v.x = maxf(max_v.x, p.x)
				max_v.y = maxf(max_v.y, p.y)
			corner += 1
	min_v -= Vector2(2, 2)
	max_v += Vector2(2, 2)
	var iw: int = maxi(int(ceil(max_v.x - min_v.x)), 2)
	var ih: int = maxi(int(ceil(max_v.y - min_v.y)), 2)
	var data: PackedByteArray = _bytes(iw, ih)
	for raw_tri in tris:
		var row: Dictionary = raw_tri
		var pa: Vector2 = row["a"] - min_v
		var pb: Vector2 = row["b"] - min_v
		var pc: Vector2 = row["c"] - min_v
		_fill_tri(data, iw, ih, pa, pb, pc, row["ca"], row["cb"], row["cc"])
	shock = _tex(_image(iw, ih, data), true)
	var mid := Vector2.ZERO - min_v
	shock_offset = Vector2(float(iw) * 0.5 - mid.x, float(ih) * 0.5 - mid.y)
	shock_ref = ref


static func _shock_pt(radius_px: float, angle: float, geom_r: float, lift: float) -> Vector2:
	var reach: float = geom_r * radius_px
	var at := Vector2(cos(angle) * reach, sin(angle) * reach * 0.28)
	at.y -= lift * radius_px
	return at


static func _shock_wedge(tris: Array, radius_px: float, angle: float, span_a: float, rad: float, blue: Color, ice: Color, edge: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: Array = []
	var j: int = 0
	while j <= 6:
		var t: float = float(j) / 6.0
		var taper: float = sin(PI * t)
		var a: float = angle + span_a * t
		var rr: float = rad + 0.1 * t * t - 0.035 * taper
		pts.append(_shock_pt(radius_px, a, rr - 0.075 * taper, 0.0))
		cols.append(blue)
		pts.append(_shock_pt(radius_px, a, rr - 0.02 * taper, 0.037 * taper))
		cols.append(ice)
		pts.append(_shock_pt(radius_px, a, rr, 0.012 * taper))
		cols.append(edge)
		if j > 0:
			var k: int = j * 3
			_push_tri(tris, pts, cols, k - 3, k - 2, k)
			_push_tri(tris, pts, cols, k, k - 2, k + 1)
			_push_tri(tris, pts, cols, k - 2, k - 1, k + 1)
			_push_tri(tris, pts, cols, k + 1, k - 1, k + 2)
		j += 1
	if span_a > 0.45:
		var tooth: float = angle + span_a * 0.67
		var extra: PackedVector2Array = PackedVector2Array()
		var tooth_cols: Array = []
		extra.append(_shock_pt(radius_px, tooth, rad + 0.05, 0.0))
		tooth_cols.append(blue)
		extra.append(_shock_pt(radius_px, tooth + 0.075, rad + 0.11, 0.016))
		tooth_cols.append(ice)
		extra.append(_shock_pt(radius_px, tooth + 0.16, rad + 0.23, 0.038))
		tooth_cols.append(edge)
		_push_tri(tris, extra, tooth_cols, 0, 1, 2)


static func _push_tri(tris: Array, pts: PackedVector2Array, cols: Array, a: int, b: int, c: int) -> void:
	if a < 0 or b < 0 or c < 0:
		return
	if a >= pts.size() or b >= pts.size() or c >= pts.size():
		return
	var pa: Vector2 = pts[a]
	var pb: Vector2 = pts[b]
	var pc: Vector2 = pts[c]
	if absf((pb - pa).cross(pc - pa)) < 0.08:
		return
	tris.append({
		"a": pa, "b": pb, "c": pc,
		"ca": cols[a], "cb": cols[b], "cc": cols[c],
	})


static func _fill_tri(data: PackedByteArray, w: int, h: int, a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
	var min_x: int = int(floor(minf(a.x, minf(b.x, c.x))))
	var max_x: int = int(ceil(maxf(a.x, maxf(b.x, c.x))))
	var min_y: int = int(floor(minf(a.y, minf(b.y, c.y))))
	var max_y: int = int(ceil(maxf(a.y, maxf(b.y, c.y))))
	min_x = maxi(min_x, 0)
	min_y = maxi(min_y, 0)
	max_x = mini(max_x, w - 1)
	max_y = mini(max_y, h - 1)
	var area: float = (b - a).cross(c - a)
	if absf(area) < 0.001:
		return
	var y: int = min_y
	while y <= max_y:
		var x: int = min_x
		while x <= max_x:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var w0: float = (b - p).cross(c - p) / area
			var w1: float = (c - p).cross(a - p) / area
			var w2: float = (a - p).cross(b - p) / area
			if w0 >= -0.001 and w1 >= -0.001 and w2 >= -0.001:
				var col: Color = ca * w0 + cb * w1 + cc * w2
				_add(data, w, x, y, Color(col.r, col.g, col.b, 1.0), clampf(col.a, 0.0, 1.0))
			x += 1
		y += 1


static func _ice_tex(fill_pts: PackedVector2Array, out_pts: PackedVector2Array, unit_px: float, seed: float) -> Dictionary:
	var bounds: Rect2 = _bounds(out_pts, 0.04)
	var w: int = maxi(int(ceil(bounds.size.x * unit_px)), 2)
	var h: int = maxi(int(ceil(bounds.size.y * unit_px)), 2)
	var data: PackedByteArray = _bytes(w, h)
	var y: int = 0
	while y < h:
		var x: int = 0
		while x < w:
			var local := Vector2(bounds.position.x + (float(x) + 0.5) / unit_px, bounds.position.y + (float(y) + 0.5) / unit_px)
			var ink: bool = _inside(out_pts, local)
			var body: bool = _inside(fill_pts, local)
			if body:
				var uv := _ice_uv(fill_pts, local)
				_put(data, w, x, y, _ice_shade(uv, seed))
			elif ink:
				_put(data, w, x, y, Color(0.02353, 0.07059, 0.14902, 1.0))
			x += 1
		y += 1
	var zero := Vector2((0.0 - bounds.position.x) * unit_px, (0.0 - bounds.position.y) * unit_px)
	var offset := Vector2(float(w) * 0.5 - zero.x, float(h) * 0.5 - zero.y)
	return {"tex": _tex(_image(w, h, data), true), "offset": offset}


static func _ice_uv(pts: PackedVector2Array, p: Vector2) -> Vector2:
	if pts.is_empty():
		return Vector2.ZERO
	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var i: int = 0
	while i < pts.size():
		min_x = minf(min_x, pts[i].x)
		max_x = maxf(max_x, pts[i].x)
		i += 1
	var span_x: float = maxf(max_x - min_x, 0.001)
	return Vector2((p.x - min_x) / span_x, clampf(-p.y, 0.0, 1.0))


static func _ice_shade(uv: Vector2, seed: float) -> Color:
	var across: float = clampf(uv.x, 0.0, 1.0)
	var up: float = clampf(uv.y, 0.0, 1.0)
	var cel: float = clampf(0.20 + across * 0.58 + up * 0.24, 0.0, 1.0)
	var shadow := Vector3(0.04706, 0.23137, 0.45882)
	var mid := Vector3(0.13333, 0.72157, 0.94118)
	var lit := Vector3(0.90980, 0.98039, 1.0)
	var rim := Vector3(0.64706, 0.95294, 0.98824)
	var base := shadow
	base = base.lerp(mid, smoothstep(0.42, 0.45, cel))
	base = base.lerp(lit, smoothstep(0.72, 0.75, cel))
	var diag: float = across * 2.4 + up * 3.8 + seed * TAU
	var streak1: float = smoothstep(0.91, 0.94, sin(diag))
	var streak2: float = smoothstep(0.95, 0.98, sin(diag * 2.1 + 1.3))
	var spec: float = clampf(streak1 * 0.65 + streak2 * 0.45, 0.0, 1.0)
	if cel <= 0.48:
		spec = 0.0
	base = base.lerp(Vector3.ONE, spec * 0.72)
	var edge: float = minf(across, 1.0 - across)
	var fres: float = smoothstep(0.16, 0.0, edge)
	var col: Vector3 = base + rim * fres * 1.15
	var foot: float = smoothstep(0.18, 0.0, up)
	col = col.lerp(shadow, 0.36 * foot)
	var peak: float = maxf(col.x, maxf(col.y, col.z))
	if peak > 1.0:
		col /= peak
		col = col.lerp(Vector3.ONE, 0.82)
	col = Vector3(clampf(col.x, 0.0, 1.0), clampf(col.y, 0.0, 1.0), clampf(col.z, 0.0, 1.0))
	return Color(col.x, col.y, col.z, 0.96)


static func _capsule(data: PackedByteArray, w: int, h: int, a: Vector2, b: Vector2, radius: float, tint: Color) -> void:
	var min_x: int = int(floor(minf(a.x, b.x) - radius))
	var max_x: int = int(ceil(maxf(a.x, b.x) + radius))
	var min_y: int = int(floor(minf(a.y, b.y) - radius))
	var max_y: int = int(ceil(maxf(a.y, b.y) + radius))
	var ab: Vector2 = b - a
	var ab_len: float = ab.length_squared()
	var y: int = maxi(min_y, 0)
	var y_end: int = mini(max_y, h - 1)
	var x_end: int = mini(max_x, w - 1)
	while y <= y_end:
		var x: int = maxi(min_x, 0)
		while x <= x_end:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var t: float = 0.0
			if ab_len > 0.0001:
				t = clampf((p - a).dot(ab) / ab_len, 0.0, 1.0)
			var d: float = p.distance_to(a + ab * t)
			var cover: float = clampf(radius + 0.65 - d, 0.0, 1.0)
			if cover > 0.0:
				_add(data, w, x, y, tint, cover)
			x += 1
		y += 1


static func _fill_circle(data: PackedByteArray, w: int, h: int, center: Vector2, radius: float, tint: Color) -> void:
	var min_x: int = maxi(int(floor(center.x - radius - 1.0)), 0)
	var max_x: int = mini(int(ceil(center.x + radius + 1.0)), w - 1)
	var min_y: int = maxi(int(floor(center.y - radius - 1.0)), 0)
	var max_y: int = mini(int(ceil(center.y + radius + 1.0)), h - 1)
	var y: int = min_y
	while y <= max_y:
		var x: int = min_x
		while x <= max_x:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			var cover: float = clampf(radius + 0.6 - d, 0.0, 1.0)
			if cover > 0.0:
				_put(data, w, x, y, Color(tint.r, tint.g, tint.b, tint.a * cover))
			x += 1
		y += 1


static func _fill_poly(data: PackedByteArray, w: int, h: int, pts: PackedVector2Array, tint: Color) -> void:
	if pts.size() < 3:
		return
	var bounds: Rect2 = _bounds(pts, 0.0)
	var min_x: int = maxi(int(floor(bounds.position.x)), 0)
	var min_y: int = maxi(int(floor(bounds.position.y)), 0)
	var max_x: int = mini(int(ceil(bounds.position.x + bounds.size.x)), w - 1)
	var max_y: int = mini(int(ceil(bounds.position.y + bounds.size.y)), h - 1)
	var y: int = min_y
	while y <= max_y:
		var x: int = min_x
		while x <= max_x:
			if _inside(pts, Vector2(float(x) + 0.5, float(y) + 0.5)):
				_put(data, w, x, y, tint)
			x += 1
		y += 1


static func _inside(pts: PackedVector2Array, p: Vector2) -> bool:
	var n: int = pts.size()
	var hit := false
	var j: int = n - 1
	var i: int = 0
	while i < n:
		var a: Vector2 = pts[j]
		var b: Vector2 = pts[i]
		if (a.y > p.y) != (b.y > p.y):
			var x_at: float = (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x
			if p.x < x_at:
				hit = not hit
		j = i
		i += 1
	return hit


static func _bounds(pts: PackedVector2Array, pad: float) -> Rect2:
	var min_v: Vector2 = pts[0]
	var max_v: Vector2 = pts[0]
	var i: int = 1
	while i < pts.size():
		min_v.x = minf(min_v.x, pts[i].x)
		min_v.y = minf(min_v.y, pts[i].y)
		max_v.x = maxf(max_v.x, pts[i].x)
		max_v.y = maxf(max_v.y, pts[i].y)
		i += 1
	min_v -= Vector2(pad, pad)
	max_v += Vector2(pad, pad)
	return Rect2(min_v, max_v - min_v)


static func _shift(pts: PackedVector2Array, origin: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var i: int = 0
	while i < pts.size():
		out.append(pts[i] - origin)
		i += 1
	return out


static func _grow(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var mid := Vector2.ZERO
	var i: int = 0
	while i < pts.size():
		mid += pts[i]
		i += 1
	mid /= float(maxi(pts.size(), 1))
	var out := PackedVector2Array()
	i = 0
	while i < pts.size():
		var spoke: Vector2 = pts[i] - mid
		var reach: float = spoke.length()
		if reach < 0.2:
			out.append(pts[i])
		else:
			out.append(mid + spoke * ((reach + amount) / reach))
		i += 1
	return out
