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
		_sync_visuals()
@export_range(0, 3, 1) var facing: int = 0:
	set(value):
		facing = value
		_sync_visuals()
@export var body_color: Color = Color.WHITE:
	set(value):
		body_color = value
		_sync_visuals()
@export_range(0, 3, 1) var hp: int = 3:
	set(value):
		hp = value
		_sync_visuals()
@export var has_cargo: bool = false:
	set(value):
		has_cargo = value
		_sync_visuals()
@export var highlight_human_player: bool = true:
	set(value):
		highlight_human_player = value
		_sync_visuals()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_sync_visuals()
	_sync_geometry()

func setup(id: int, color: Color) -> void:
	player_id = id
	body_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_visuals()

func set_state(new_facing: int, new_hp: int, cargo: bool) -> void:
	facing = new_facing
	hp = new_hp
	has_cargo = cargo
	_sync_visuals()

func _sync_visuals() -> void:
	if not is_inside_tree():
		return
	var sprite: TextureRect = get_node_or_null("SpriteHolder/ShipSprite") as TextureRect
	var holder: Control = get_node_or_null("SpriteHolder") as Control
	var human_halo: Panel = get_node_or_null("HumanHalo") as Panel
	var human_inner: Panel = get_node_or_null("HumanInner") as Panel
	var opponent_ring: Panel = get_node_or_null("OpponentRing") as Panel
	var badge: Panel = get_node_or_null("HumanBadge") as Panel
	var cargo_marker: Panel = get_node_or_null("CargoMarker") as Panel
	var hp_fill: Panel = get_node_or_null("HPBar/Fill") as Panel
	var is_human_ship: bool = highlight_human_player and player_id == 1

	if sprite != null:
		sprite.texture = SHIP_TEXTURES.get(player_id, null)
	if holder != null:
		holder.rotation = deg_to_rad(float(facing) * 90.0)
	if human_halo != null:
		human_halo.visible = is_human_ship
	if human_inner != null:
		human_inner.visible = is_human_ship
	if badge != null:
		badge.visible = is_human_ship
	if opponent_ring != null:
		opponent_ring.visible = not is_human_ship
		opponent_ring.modulate = body_color.lightened(0.12)
	if cargo_marker != null:
		cargo_marker.visible = has_cargo
	if hp_fill != null:
		var hp_ratio: float = clampf(float(hp) / 3.0, 0.0, 1.0)
		hp_fill.anchor_right = hp_ratio
		hp_fill.offset_right = 0.0

func _sync_geometry() -> void:
	if not is_inside_tree():
		return
	var holder: Control = get_node_or_null("SpriteHolder") as Control
	if holder != null:
		holder.pivot_offset = size * 0.5

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		call_deferred("_sync_geometry")
