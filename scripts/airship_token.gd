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

var hover_time: float = 0.0
var hover_enabled: bool = true
var hover_lift: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_sync_visuals()
	_sync_geometry()
	_update_hover_processing()

func setup(id: int, color: Color) -> void:
	player_id = id
	body_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_visuals()

var rotation_tween: Tween

func cancel_motion() -> void:
	if rotation_tween != null and rotation_tween.is_valid():
		rotation_tween.kill()
	rotation_tween = null
	_sync_visuals()

func set_state(new_facing: int, new_hp: int, cargo: bool, animate: bool = false) -> void:
	var holder := get_node_or_null("SpriteHolder") as Control
	var start: float = holder.rotation if holder != null else 0.0
	cancel_motion()
	facing = new_facing
	hp = new_hp
	has_cargo = cargo
	_sync_visuals()
	if animate and holder != null:
		var target := start + wrapf(holder.rotation - start, -PI, PI)
		holder.rotation = start
		rotation_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		rotation_tween.tween_property(holder, "rotation", target, 0.22)

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
	# Selection rings mark the ground cell; only the ship floats above it.
	for key in ["HumanHalo", "HumanInner", "OpponentRing"]:
		var ring := get_node_or_null(key) as Control
		if ring != null:
			ring.pivot_offset = ring.size * 0.5
			ring.scale = Vector2(1.0, 0.42)
			ring.offset_top = size.y * 0.13
			ring.offset_bottom = size.y * 0.13
	var badge := get_node_or_null("HumanBadge") as Control
	if badge != null:
		badge.offset_top = size.y * 0.68
		badge.offset_bottom = badge.offset_top + 17.0
	_apply_hover()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		_update_hover_processing()
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		call_deferred("_sync_geometry")

func set_hover_motion(enabled: bool) -> void:
	hover_enabled = enabled
	if not enabled:
		hover_time = 0.0
	_apply_hover()
	_update_hover_processing()

func _update_hover_processing() -> void:
	set_process(hover_enabled and not Engine.is_editor_hint() and is_visible_in_tree())

func _process(delta: float) -> void:
	hover_time = fmod(hover_time + delta, 30.0)
	_apply_hover()

func _apply_hover() -> void:
	var holder := get_node_or_null("SpriteHolder") as Control
	if holder == null:
		return
	var bob: float = sin(hover_time * TAU / 6.0 + float(player_id) * 1.7) if hover_enabled and not Engine.is_editor_hint() else 0.0
	hover_lift = size.y * (0.18 + 0.045 * bob)
	holder.position = Vector2(0.0, -hover_lift)
	queue_redraw()

func visual_center() -> Vector2:
	return position + size * 0.5 - Vector2(0.0, hover_lift)

func _draw() -> void:
	# Feathered contact shadow stays on the board, softer when the hull rises.
	var altitude: float = hover_lift / maxf(size.y, 1.0)
	var spread: float = 1.0 + altitude * 0.8
	var center := size * Vector2(0.56, 0.65)
	for i in range(10):
		var radius: float = size.x * (0.36 - float(i) * 0.022) * spread
		draw_set_transform(center, 0.0, Vector2(1.0, 0.36))
		draw_circle(Vector2.ZERO, radius, Color(0.005, 0.015, 0.02, 0.045 - altitude * 0.035))
	draw_set_transform(Vector2.ZERO)
