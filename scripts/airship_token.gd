@tool
extends Control
class_name AirshipToken

const SHIP_TEXTURES := {
	1: preload("res://assets/generated/ship_blue.png"),
	2: preload("res://assets/generated/ship_red.png"),
	3: preload("res://assets/generated/ship_green.png"),
	4: preload("res://assets/generated/ship_yellow.png")
}

@export_range(1, 4, 1) var player_id: int = 1:
	set(value):
		player_id = value
		queue_redraw()
@export_range(0, 3, 1) var facing: int = 0:
	set(value):
		facing = value
		queue_redraw()
@export var body_color: Color = Color.WHITE:
	set(value):
		body_color = value
		queue_redraw()
@export_range(0, 3, 1) var hp: int = 3:
	set(value):
		hp = value
		queue_redraw()
@export var has_cargo: bool = false:
	set(value):
		has_cargo = value
		queue_redraw()
@export var highlight_human_player: bool = true:
	set(value):
		highlight_human_player = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	queue_redraw()

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
	var ring_radius: float = s * 0.39
	var texture: Texture2D = SHIP_TEXTURES.get(player_id, null)
	var is_human_ship: bool = highlight_human_player and player_id == 1

	if is_human_ship:
		draw_circle(center, s * 0.455, Color(0.15, 0.76, 1.0, 0.13))
		draw_arc(center, s * 0.435, 0.0, TAU, 48, Color(0.92, 0.99, 1.0, 1.0), 5.0, true)
		draw_arc(center, s * 0.365, 0.0, TAU, 48, Color(0.12, 0.72, 1.0, 1.0), 3.0, true)
	else:
		draw_circle(center, ring_radius * 1.04, Color(0.03, 0.025, 0.02, 0.32))
		draw_arc(center, ring_radius, 0.0, TAU, 36, body_color.lightened(0.12), 3.0, true)

	if texture != null:
		var tex_size: Vector2 = texture.get_size()
		var max_extent: float = s * 0.70
		var draw_scale: float = minf(max_extent / maxf(tex_size.x, 1.0), max_extent / maxf(tex_size.y, 1.0))
		var target_size: Vector2 = tex_size * draw_scale
		var angle: float = deg_to_rad(float(facing) * 90.0)
		draw_set_transform(center, angle, Vector2.ONE)
		draw_texture_rect(texture, Rect2(-target_size * 0.5, target_size), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(center, ring_radius * 0.72, body_color)

	if is_human_ship:
		var badge_width: float = s * 0.54
		var badge_height: float = maxf(18.0, s * 0.19)
		var badge_rect := Rect2(center.x - badge_width * 0.5, 2.0, badge_width, badge_height)
		draw_rect(badge_rect, Color(0.015, 0.075, 0.11, 0.96), true)
		draw_rect(badge_rect, Color(0.72, 0.96, 1.0, 1.0), false, 2.0)
		var badge_font_size: int = maxi(11, int(s * 0.13))
		draw_string(ThemeDB.fallback_font, badge_rect.position + Vector2(0.0, badge_rect.size.y * 0.73), "SEN", HORIZONTAL_ALIGNMENT_CENTER, badge_rect.size.x, badge_font_size, Color(0.95, 1.0, 1.0, 1.0))

	if has_cargo:
		var cargo_rect := Rect2(center.x + s * 0.13, center.y + s * 0.12, s * 0.17, s * 0.17)
		draw_rect(cargo_rect, Color(1.0, 0.78, 0.16), true)
		draw_rect(cargo_rect.grow(2.0), Color(0.15, 0.10, 0.05), false, 2.0)

	var hp_ratio: float = clampf(float(hp) / 3.0, 0.0, 1.0)
	draw_rect(Rect2(s * 0.14, s * 0.86, s * 0.72, 6.0), Color(0.08, 0.08, 0.08, 0.92), true)
	draw_rect(Rect2(s * 0.14, s * 0.86, s * 0.72 * hp_ratio, 6.0), Color(0.25, 0.95, 0.40, 0.95), true)
