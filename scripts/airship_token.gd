@tool
extends Control
class_name AirshipToken

const SHIP_TEXTURES := {
	1: preload("res://assets/generated/ship_blue.png"),
	2: preload("res://assets/generated/ship_red.png"),
	3: preload("res://assets/generated/ship_green.png"),
	4: preload("res://assets/generated/ship_yellow.png")
}

var player_id: int = 0
var facing: int = 0
var body_color: Color = Color.WHITE
var hp: int = 3
var has_cargo: bool = false

func setup(id: int, color: Color) -> void:
	player_id = id
	body_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_state(new_facing: int, new_hp: int, cargo: bool) -> void:
	facing = new_facing
	hp = new_hp
	has_cargo = cargo
	queue_redraw()

func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var center: Vector2 = size * 0.5
	var ring_radius: float = s * 0.40
	var texture: Texture2D = SHIP_TEXTURES.get(player_id, null)

	draw_arc(center, ring_radius, 0.0, TAU, 36, body_color.lightened(0.12), 3.0, true)
	if texture != null:
		var tex_size: Vector2 = texture.get_size()
		var target_h: float = s * 0.92
		var draw_scale: float = target_h / tex_size.y
		var target_size: Vector2 = tex_size * draw_scale
		var angle: float = deg_to_rad(float(facing) * 90.0)
		draw_set_transform(center, angle, Vector2.ONE)
		draw_texture_rect(texture, Rect2(-target_size * 0.5, target_size), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(center, ring_radius, body_color)

	if has_cargo:
		var cargo_rect := Rect2(center.x + s * 0.15, center.y + s * 0.14, s * 0.18, s * 0.18)
		draw_rect(cargo_rect, Color(1.0, 0.78, 0.16), true)
		draw_rect(cargo_rect.grow(2.0), Color(0.15, 0.10, 0.05), false, 2.0)

	var hp_ratio: float = clampf(float(hp) / 3.0, 0.0, 1.0)
	draw_rect(Rect2(s * 0.12, s * 0.88, s * 0.76, 6.0), Color(0.08, 0.08, 0.08, 0.92), true)
	draw_rect(Rect2(s * 0.12, s * 0.88, s * 0.76 * hp_ratio, 6.0), Color(0.25, 0.95, 0.40, 0.95), true)
