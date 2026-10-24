extends RefCounted
class_name UiKit

const INK := Color(0.16, 0.18, 0.22)
const CREAM := Color(0.98, 0.96, 0.92)
const SKY := Color(0.655, 0.871, 0.992)
const SKY_DEEP := Color(0.40, 0.62, 0.82)
const GOLD := Color(0.93, 0.74, 0.28)
const GOOD := Color(0.24, 0.50, 0.34)
const DANGER := Color(0.66, 0.24, 0.20)
const ROAD := Color(0.32, 0.45, 0.60)
const HOME := Color(0.70, 0.38, 0.26)
const PARK := Color(0.30, 0.52, 0.32)
const CIVIC := Color(0.18, 0.46, 0.52)

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://fonts/lilita_one_regular.ttf")
	return _font


static func category_color(category: String) -> Color:
	match category:
		"home":
			return HOME
		"park":
			return PARK
		"civic":
			return CIVIC
		_:
			return ROAD


static func style(bg: Color, border: Color, border_w: int, radius: int = 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


static func style_button(button: Button, bg: Color, border: Color, border_w: int, font_size: int, font_color: Color = Color.WHITE) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.72))
	button.add_theme_stylebox_override("normal", style(bg, border, border_w))
	button.add_theme_stylebox_override("hover", style(bg.lightened(0.08), border, border_w))
	button.add_theme_stylebox_override("pressed", style(bg.darkened(0.08), border, border_w + 1))
	button.add_theme_stylebox_override("disabled", style(bg.darkened(0.18), border.darkened(0.2), border_w))
	button.add_theme_stylebox_override("focus", style(bg, GOLD, maxi(border_w, 3)))


static func label(text: String, size: int, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func safe_insets(viewport: Viewport) -> Vector4i:
	var window := DisplayServer.window_get_size()
	var minimum := 14
	if window.x <= 0 or window.y <= 0:
		return Vector4i(minimum, minimum, minimum, minimum)
	var safe := DisplayServer.get_display_safe_area()
	var visible := viewport.get_visible_rect().size
	var sx := visible.x / float(window.x)
	var sy := visible.y / float(window.y)
	var left := int(safe.position.x * sx)
	var top := int(safe.position.y * sy)
	var right := int((window.x - safe.end.x) * sx)
	var bottom := int((window.y - safe.end.y) * sy)
	return Vector4i(maxi(left, minimum), maxi(top, minimum), maxi(right, minimum), maxi(bottom, minimum))


static func apply_insets(container: MarginContainer, insets: Vector4i) -> void:
	container.add_theme_constant_override("margin_left", insets.x)
	container.add_theme_constant_override("margin_top", insets.y)
	container.add_theme_constant_override("margin_right", insets.z)
	container.add_theme_constant_override("margin_bottom", insets.w)


static func passthrough(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
