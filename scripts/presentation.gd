extends RefCounted
## Shared visual language. Gameplay and node paths stay in main_ui.gd.

const GOLD := Color("d5b47c")
const INK := Color("101e27")
const LINE := Color("30434b")
const TEXT := Color("e9e6dc")
const MUTED := Color("91a8af")

static func panel(bg: Color, stroke: Color = LINE, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = stroke
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

static func rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)

static func label(parent: Node, value: String, x: float, y: float, w: float, h: float, font_size: int, color: Color = TEXT) -> Label:
	var item := Label.new()
	item.text = value
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	rect(item, x, y, w, h)
	return item

static func command_texture(command: String) -> Texture2D:
	var icons := {"İleri 1": "forward1", "İleri 2": "forward2", "Sola Dön": "left", "Sağa Dön": "right", "Kanca": "hook", "Çapa": "anchor"}
	return load("res://assets/ui/%s.svg" % icons.get(command, "anchor")) as Texture2D
