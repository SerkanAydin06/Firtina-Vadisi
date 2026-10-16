@tool
extends Control
class_name StormBoard

signal sound_requested(kind: String)


var grid_size := Vector2i(11, 9)
var cell_size := 62.0
var rocks: Array[Vector2i] = []
var pickup_cells: Dictionary = {}
var delivery_cells: Dictionary = {}
var tokens: Dictionary = {}
var reduced_motion: bool = false
var effects: Node2D

var active_tweens: Array[Tween] = []

func cancel_animations() -> void:
	for tween in active_tweens:
		if tween.is_valid():
			tween.kill()
	active_tweens.clear()
	if is_instance_valid(effects):
		effects.clear()
	for token in tokens.values():
		token.modulate = Color.WHITE
		token.cancel_motion()
		token.set_hover_motion(false)

func track_tween(tween: Tween) -> void:
	active_tweens = active_tweens.filter(func(item: Tween) -> bool: return item.is_valid())
	active_tweens.append(tween)

var grid_origin := Vector2.ZERO

func configure(new_grid_size: Vector2i, new_rocks: Array[Vector2i], pickups: Dictionary, deliveries: Dictionary) -> void:
	grid_size = new_grid_size
	rocks = new_rocks
	pickup_cells = pickups
	delivery_cells = deliveries
	queue_redraw()

func fit_board() -> void:
	var usable: Vector2 = size - Vector2(24, 24)
	cell_size = floor(minf(usable.x / float(grid_size.x), usable.y / float(grid_size.y)))
	grid_origin = (size - Vector2(grid_size) * cell_size) * 0.5
	for id in tokens:
		var token: AirshipToken = tokens[id]
		token.size = Vector2(cell_size, cell_size)
	queue_redraw()

func add_ship(id: int, color: Color, cell: Vector2i) -> void:
	var token: AirshipToken = AirshipToken.new()
	token.setup(id, color)
	token.size = Vector2(cell_size, cell_size)
	add_child(token)
	tokens[id] = token
	token.position = cell_to_pixel(cell)

func update_ship(id: int, cell: Vector2i, facing: int, hp: int, has_cargo: bool, animate: bool = true) -> Tween:
	if not tokens.has(id):
		return null
	var token: AirshipToken = tokens[id]
	token.set_hover_motion(not reduced_motion)
	token.set_state(facing, hp, has_cargo, animate and not reduced_motion)
	var target: Vector2 = cell_to_pixel(cell)
	if not animate or reduced_motion:
		token.position = target
		return null
	var tween: Tween = create_tween()
	track_tween(tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(token, "position", target, 0.22)
	return tween

func flash_ship(id: int) -> void:
	if not tokens.has(id):
		return
	var token: AirshipToken = tokens[id]
	show_effect("spark", token.visual_center())
	if reduced_motion:
		return
	var tween: Tween = create_tween()
	track_tween(tween)
	tween.tween_property(token, "modulate", Color(1,0.35,0.35), 0.08)
	tween.tween_property(token, "modulate", Color.WHITE, 0.14)

func cell_to_pixel(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell) * cell_size

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		fit_board()

func _draw() -> void:
	var board_rect: Rect2 = Rect2(grid_origin, Vector2(grid_size) * cell_size)
	draw_rect(board_rect.grow(14.0), Color(0.12, 0.10, 0.08), true)
	draw_rect(board_rect, Color(0.03,0.04,0.05,0.18), true)
	draw_rect(board_rect.grow(4.0), Color(0.90,0.72,0.34,0.40), false, 3.0)

	for y in range(grid_size.y + 1):
		var p1: Vector2 = grid_origin + Vector2(0, float(y) * cell_size)
		var p2: Vector2 = grid_origin + Vector2(float(grid_size.x) * cell_size, float(y) * cell_size)
		draw_line(p1, p2, Color(1.0,1.0,1.0,0.25), 1.0)
	for x in range(grid_size.x + 1):
		var q1: Vector2 = grid_origin + Vector2(float(x) * cell_size, 0)
		var q2: Vector2 = grid_origin + Vector2(float(x) * cell_size, float(grid_size.y) * cell_size)
		draw_line(q1, q2, Color(1.0,1.0,1.0,0.25), 1.0)

	for rock in rocks:
		var rect: Rect2 = Rect2(cell_to_pixel(rock) + Vector2(6, 6), Vector2(cell_size - 12, cell_size - 12))
		draw_rect(rect, Color(0.40,0.12,0.08,0.20), true)
		draw_rect(rect.grow(1.0), Color(1.0,0.45,0.20,0.28), false, 2.0)

	for cell in pickup_cells:
		var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
		draw_circle(center, cell_size * 0.18, Color(1.0,0.74,0.20,0.95))
		draw_circle(center, cell_size * 0.11, Color(0.24,0.15,0.04,1.0))
		draw_arc(center, cell_size * 0.26, 0.0, TAU, 20, Color(1.0,0.86,0.35,0.55), 2.0, true)

	for cell in delivery_cells:
		var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
		var rr: Rect2 = Rect2(center - Vector2.ONE * cell_size * 0.17, Vector2.ONE * cell_size * 0.34)
		draw_rect(rr, Color(0.18,0.78,0.75,0.80), true)
		draw_rect(rr.grow(4), Color(0.67,1.0,0.96,0.75), false, 2)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	cancel_animations()
	for token in tokens.values():
		token.set_hover_motion(not enabled)

func show_effect(kind: String, start: Vector2, finish: Vector2 = Vector2.ZERO, value: int = 0) -> void:
	if not Engine.is_editor_hint():
		sound_requested.emit(kind)
	if reduced_motion or Engine.is_editor_hint():
		return
	if not is_instance_valid(effects):
		effects = preload("res://scripts/board_effects.gd").new()
		effects.z_index = 350
		add_child(effects)
	effects.emit_effect(kind, start, finish, value)

func show_hook(attacker: int, target: int) -> void:
	if tokens.has(attacker) and tokens.has(target):
		var a: AirshipToken = tokens[attacker]
		var b: AirshipToken = tokens[target]
		show_effect("hook", a.visual_center(), b.visual_center())

func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
