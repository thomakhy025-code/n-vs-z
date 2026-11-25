extends RefCounted

const Painter = preload("res://scripts/painter.gd")

# One sheet per look (paint, colors, faction, weapon, and the few props that
# change the picture). Facing is a sprite flip of that sheet, so both
# directions share it. Walk is four stride samples; attack is four strike
# samples. Hurt and the hit flash are tints, not extra sheets.
const CELL_W := 192
const CELL_H := 240
const PAD := 4
const STRIDE := CELL_W + PAD
const ORIGIN := Vector2(96, 168)
const SLOTS := 8

static var bakes: int = 0
static var paints: int = 0
static var binds: int = 0
static var pending: int = 0
static var blank: int = 0
static var opaque: int = 0
static var ring_draws: int = 0
static var ring_tex: Texture2D = null
static var ring_armed: bool = false
static var _sheets: Dictionary = {}
static var _shader: Shader = null


static func clear() -> void:
	_sheets.clear()
	ring_tex = null
	_shader = null


static func offset() -> Vector2:
	return Vector2(-ORIGIN.x, -ORIGIN.y)


static func region(slot: int) -> Rect2:
	return Rect2(float(slot * STRIDE), 0.0, float(CELL_W), float(CELL_H))


static func make_key(look: Dictionary, bits: int) -> String:
	var skin: Color = look.get("skin", Color.BLACK)
	var cloth: Color = look.get("cloth", Color.BLACK)
	var trim: Color = look.get("trim", Color.BLACK)
	var eye: Color = look.get("eye", Color.BLACK)
	var mask: Color = look.get("mask", Color.BLACK)
	var scarf: Color = look.get("scarf", Color.BLACK)
	var blade: Color = look.get("blade", Color.BLACK)
	var parts := PackedStringArray()
	parts.append(str(look.get("paint", "")))
	parts.append(str(look.get("faction", "")))
	parts.append(str(look.get("weapon", "")))
	parts.append(str(look.get("helm", "")))
	parts.append(skin.to_html(false))
	parts.append(cloth.to_html(false))
	parts.append(trim.to_html(false))
	parts.append(eye.to_html(false))
	parts.append(mask.to_html(false))
	parts.append(scarf.to_html(false))
	parts.append(blade.to_html(false))
	parts.append("1" if bool(look.get("mount", false)) else "0")
	parts.append("1" if bool(look.get("sheet", false)) else "0")
	parts.append("1" if bool(look.get("horns", false)) else "0")
	parts.append("1" if bool(look.get("sash", false)) else "0")
	parts.append("1" if bool(look.get("pack", true)) else "0")
	parts.append("1" if bool(look.get("bare", false)) else "0")
	parts.append(str(look.get("dress", "")))
	parts.append(str(bits))
	return "|".join(parts)


static func request(host: Node, key: String, look: Dictionary, bits: int) -> Texture2D:
	if _sheets.has(key):
		var row: Dictionary = _sheets[key]
		if bool(row.get("ready", false)):
			binds += 1
			var ready_tex: Texture2D = row["tex"]
			return ready_tex
		return null
	var tree := host.get_tree()
	if tree == null:
		return null
	_sheets[key] = {"ready": false}
	bakes += 1
	pending += 1
	var host_node := BakeHost.new()
	host_node.kind = "sheet"
	host_node.key = key
	host_node.look = look.duplicate(true)
	host_node.bits = bits
	tree.root.add_child(host_node)
	return null


static func warm_ring(host: Node) -> void:
	if ring_armed:
		return
	var tree := host.get_tree()
	if tree == null:
		return
	ring_armed = true
	var host_node := BakeHost.new()
	host_node.kind = "ring"
	tree.root.add_child(host_node)


static func flash_material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = "shader_type canvas_item;\nuniform float wash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tvec3 rgb = mix(tex.rgb, vec3(1.0), wash);\n\tCOLOR = vec4(rgb, tex.a) * COLOR;\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("wash", 0.0)
	return mat


static func paint_frame(ci: CanvasItem, look: Dictionary, extra: Dictionary, slot: int) -> void:
	ci.draw_set_transform(Vector2(float(slot * STRIDE), 0.0) + ORIGIN, 0.0, Vector2.ONE)
	Painter.paint_local(ci, look, _pose(slot, look, extra))
	paints += 1
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func paint_ring(ci: CanvasItem) -> void:
	ci.draw_arc(Vector2(32.0, 32.0), 16.0, 0.0, 4.2, 12, Color.WHITE, 2.4)
	ring_draws += 1


static func _walk_theta(slot: int) -> float:
	match slot:
		0:
			return 0.45
		1:
			return 1.20
		2:
			return 3.59
		_:
			return 4.34


static func _pose(slot: int, look: Dictionary, extra: Dictionary) -> Dictionary:
	var paint := str(look.get("paint", ""))
	var rate := 8.0
	if paint == "runner" or paint == "scout":
		rate = 11.0
	var phase := "march"
	var beat := 0
	var along := 0.0
	var clock := 0.0
	if slot < 4:
		clock = _walk_theta(slot) / rate
	else:
		var act_i := slot - 4
		beat = act_i
		phase = "act"
		if act_i == 0:
			along = 0.25
		elif act_i == 1:
			along = 0.55
		elif act_i == 2:
			along = 0.72
		else:
			along = 0.40
		clock = _walk_theta(act_i) / rate
	var hang := float(extra.get("hang", 0.0))
	var roost := float(extra.get("roost", 0.0))
	var sit := float(extra.get("sit", 0.0))
	var loading := float(extra.get("loading", 0.0))
	var spears := int(extra.get("spears", 0))
	var calling := bool(extra.get("calling", false))
	return {
		"phase": phase,
		"t": along,
		"clock": clock,
		"flash": 0.0,
		"beat": beat,
		"hang": hang,
		"calling": calling,
		"roost": roost,
		"spears": spears,
		"loading": loading,
		"sit": sit,
		"tale": "",
	}


static func _extra(bits: int) -> Dictionary:
	var hang := 0.0
	if (bits & 1) != 0:
		hang = 1.0
	var roost := 0.0
	if (bits & 2) != 0:
		roost = 1.0
	var sit := 0.0
	if (bits & 32) != 0:
		sit = 1.0
	var loading := 0.0
	if (bits & 64) != 0:
		loading = 1.0
	return {
		"hang": hang,
		"roost": roost,
		"spears": (bits >> 3) & 3,
		"sit": sit,
		"loading": loading,
		"calling": (bits & 128) != 0,
	}


static func _opaque(img: Image) -> int:
	var count := 0
	var w := img.get_width()
	var h := img.get_height()
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			if img.get_pixel(x, y).a > 0.15:
				count += 1
			x += 4
		y += 4
	return count


class BakeHost extends Node:
	var kind: String = ""
	var key: String = ""
	var look: Dictionary = {}
	var bits: int = 0
	var vp: SubViewport = null
	var step: int = 0
	var tries: int = 0

	func _ready() -> void:
		var baker = load("res://scripts/frame_bake.gd")
		if kind == "ring":
			vp = _viewport(Vector2i(64, 64))
			var ring_draw := RingDrawer.new()
			ring_draw.bake_script = baker
			add_child(vp)
			vp.add_child(ring_draw)
		else:
			vp = _viewport(Vector2i(int(baker.STRIDE) * int(baker.SLOTS), int(baker.CELL_H)))
			var drawer := SheetDrawer.new()
			drawer.look = look
			drawer.extra = baker.call("_extra", bits)
			drawer.bake_script = baker
			add_child(vp)
			vp.add_child(drawer)

	func _process(_delta: float) -> void:
		if vp == null:
			return
		step += 1
		if step == 1:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return
		var baker = load("res://scripts/frame_bake.gd")
		# Headless has no raster target. The polygons still ran; keep a blank
		# sheet so fighters share one texture instead of retrying the read.
		if DisplayServer.get_name() == "headless":
			_store(baker, Image.create(maxi(vp.size.x, 1), maxi(vp.size.y, 1), false, Image.FORMAT_RGBA8), 0)
			queue_free()
			return
		var view_tex := vp.get_texture()
		var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		if view_tex != null:
			var grabbed := view_tex.get_image()
			if grabbed != null:
				img = grabbed
		var seen := int(baker.call("_opaque", img))
		if seen == 0 and tries < 3:
			tries += 1
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return
		_store(baker, img, seen)
		img = null
		queue_free()

	func _store(baker, img: Image, seen: int) -> void:
		if kind == "ring":
			if seen > 0:
				img.fix_alpha_edges()
				baker.ring_tex = ImageTexture.create_from_image(img)
			return
		if seen == 0:
			baker.blank += 1
		else:
			img.fix_alpha_edges()
			if seen > int(baker.opaque):
				baker.opaque = seen
		var tex := ImageTexture.create_from_image(img)
		baker._sheets[key] = {"ready": true, "tex": tex}
		baker.pending -= 1

	func _viewport(view_size: Vector2i) -> SubViewport:
		var made := SubViewport.new()
		made.disable_3d = true
		made.transparent_bg = true
		made.use_hdr_2d = false
		made.handle_input_locally = false
		made.gui_disable_input = true
		made.msaa_2d = Viewport.MSAA_DISABLED
		made.render_target_update_mode = SubViewport.UPDATE_DISABLED
		made.size = view_size
		return made


class SheetDrawer extends Node2D:
	var look: Dictionary = {}
	var extra: Dictionary = {}
	var bake_script: GDScript = null

	func _draw() -> void:
		if bake_script == null:
			return
		for slot in 8:
			bake_script.call("paint_frame", self, look, extra, slot)


class RingDrawer extends Node2D:
	var bake_script: GDScript = null

	func _draw() -> void:
		if bake_script == null:
			return
		bake_script.call("paint_ring", self)
