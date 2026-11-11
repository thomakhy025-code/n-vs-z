extends RefCounted


static func panel(bg: Color, border: Color, radius: int = 14, width: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	box.border_width_left = width
	box.border_width_top = width
	box.border_width_right = width
	box.border_width_bottom = width
	box.content_margin_left = 12
	box.content_margin_top = 8
	box.content_margin_right = 12
	box.content_margin_bottom = 8
	return box


static func apply(btn: Button, bg: Color, font_px: int, ink: Color = Color("1c140e")) -> void:
	btn.add_theme_stylebox_override("normal", panel(bg, Color("e6c36a")))
	btn.add_theme_stylebox_override("hover", panel(bg.lightened(0.12), Color("f3e6c8")))
	btn.add_theme_stylebox_override("pressed", panel(bg.darkened(0.12), Color("e6c36a")))
	btn.add_theme_stylebox_override("disabled", panel(Color(bg.r, bg.g, bg.b, 0.45), Color("5c5144")))
	btn.add_theme_font_size_override("font_size", font_px)
	btn.add_theme_color_override("font_color", ink)
	btn.add_theme_color_override("font_hover_color", ink)
	btn.add_theme_color_override("font_pressed_color", ink)
	btn.add_theme_color_override("font_disabled_color", Color("3a3228"))
	btn.focus_mode = Control.FOCUS_NONE


static func label(text: String, size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node
