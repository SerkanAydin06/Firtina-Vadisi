@tool
extends "res://scripts/board.gd"

@export var show_editor_preview: bool = true
@export_range(0.65, 0.95, 0.01) var token_fill: float = 0.80
@export_range(0.45, 0.80, 0.01) var rock_fill: float = 0.58

const PREVIEW_STARTS: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(10,0), Vector2i(0,8), Vector2i(10,8)
]
const PREVIEW_FACINGS: Array[int] = [2, 3, 1, 0]
const PREVIEW_ROCKS: Array[Vector2i] = [
	Vector2i(3,1), Vector2i(7,1), Vector2i(3,7), Vector2i(7,7),
	Vector2i(2,3), Vector2i(8,3), Vector2i(2,5), Vector2i(8,5),
	Vector2i(5,2), Vector2i(5,6), Vector2i(3,4), Vector2i(7,4)
]
const PREVIEW_PICKUPS := {
	Vector2i(4,3): {"name":"Kaçak Baharat", "short":"Baharat", "dest":Vector2i(9,6), "dest_name":"Bakır İskele", "value":5},
	Vector2i(6,3): {"name":"Fırtına Kristali", "short":"Kristal", "dest":Vector2i(1,6), "dest_name":"Sis İskelesi", "value":5},
	Vector2i(4,5): {"name":"Silah Sandığı", "short":"Silah", "dest":Vector2i(9,2), "dest_name":"Fırtına İskelesi", "value":5},
	Vector2i(6,5): {"name":"Kaçak İlaç", "short":"İlaç", "dest":Vector2i(1,2), "dest_name":"Kızıl İskele", "value":5}
}
const PREVIEW_DELIVERIES := {
	Vector2i(9,6): "Bakır İskele",
	Vector2i(1,6): "Sis İskelesi",
	Vector2i(9,2): "Fırtına İskelesi",
	Vector2i(1,2): "Kızıl İskele"
}

var cell_step: Vector2 = Vector2(100.0, 80.0)
var inner_origin: Vector2 = Vector2.ZERO
var inner_size: Vector2 = Vector2.ZERO
var grid_nodes: Array[Panel] = []
var rock_nodes: Array[Panel] = []
var contract_nodes: Array[Panel] = []
var delivery_nodes: Array[Panel] = []
var pad_nodes: Array[Panel] = []

func _ready() -> void:
	_cache_scene_nodes()
	_cache_ship_tokens()
	if Engine.is_editor_hint() and show_editor_preview:
		grid_size = Vector2i(11, 9)
		rocks = PREVIEW_ROCKS.duplicate()
		pickup_cells = PREVIEW_PICKUPS.duplicate(true)
		delivery_cells = PREVIEW_DELIVERIES.duplicate(true)
		for i in range(PREVIEW_FACINGS.size()):
			var token: AirshipToken = tokens.get(i + 1, null)
			if token != null:
				token.facing = PREVIEW_FACINGS[i]
	call_deferred("fit_board")

func _draw() -> void:
	# Bilerek boş: görünür bütün board elemanları .tscn node'larıdır.
	pass

func _cache_scene_nodes() -> void:
	grid_nodes.clear()
	rock_nodes.clear()
	contract_nodes.clear()
	delivery_nodes.clear()
	pad_nodes.clear()
	for child in $GridCells.get_children():
		if child is Panel:
			grid_nodes.append(child)
	for child in $Rocks.get_children():
		if child is Panel:
			rock_nodes.append(child)
	for child in $Contracts.get_children():
		if child is Panel:
			contract_nodes.append(child)
	for child in $Deliveries.get_children():
		if child is Panel:
			delivery_nodes.append(child)
	for child in $StartPads.get_children():
		if child is Panel:
			pad_nodes.append(child)

func _cache_ship_tokens() -> void:
	tokens.clear()
	for child in $Ships.get_children():
		if child is AirshipToken:
			var token: AirshipToken = child
			tokens[token.player_id] = token

func configure(new_grid_size: Vector2i, new_rocks: Array[Vector2i], pickups: Dictionary, deliveries: Dictionary) -> void:
	grid_size = new_grid_size
	rocks = new_rocks
	pickup_cells = pickups
	delivery_cells = deliveries
	fit_board()

func fit_board() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	inner_origin = Vector2(12.0, 12.0)
	inner_size = Vector2(maxf(1.0, size.x - 24.0), maxf(1.0, size.y - 24.0))
	cell_step = Vector2(inner_size.x / float(grid_size.x), inner_size.y / float(grid_size.y))
	cell_size = minf(cell_step.x, cell_step.y)
	grid_origin = inner_origin
	_layout_grid_cells()
	_layout_start_pads()
	_layout_rocks()
	_layout_contracts()
	_layout_deliveries()
	_layout_ships()

func _layout_grid_cells() -> void:
	for i in range(grid_nodes.size()):
		var cell_node: Panel = grid_nodes[i]
		var x: int = i % grid_size.x
		var y: int = i / grid_size.x
		if y >= grid_size.y:
			cell_node.visible = false
			continue
		cell_node.visible = true
		cell_node.position = cell_to_pixel(Vector2i(x, y))
		cell_node.size = cell_step

func add_ship(id: int, color: Color, cell: Vector2i) -> void:
	if not tokens.has(id):
		_cache_ship_tokens()
	if not tokens.has(id):
		return
	var token: AirshipToken = tokens[id]
	token.setup(id, color)
	token.visible = true
	token.set_meta("grid_cell", cell)
	_position_token(token, cell)

func update_ship(id: int, cell: Vector2i, new_facing: int, new_hp: int, has_cargo: bool, animate: bool = true) -> Tween:
	if not tokens.has(id):
		return null
	var token: AirshipToken = tokens[id]
	token.visible = true
	token.set_state(new_facing, new_hp, has_cargo)
	token.set_meta("grid_cell", cell)
	var target: Vector2 = _token_position(cell, token)
	if not animate:
		token.position = target
		return null
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(token, "position", target, 0.22)
	return tween

func cell_to_pixel(cell: Vector2i) -> Vector2:
	return inner_origin + Vector2(float(cell.x) * cell_step.x, float(cell.y) * cell_step.y)

func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_pixel(cell) + cell_step * 0.5

func _position_token(token: AirshipToken, cell: Vector2i) -> void:
	var extent: float = minf(cell_step.x, cell_step.y) * token_fill
	token.size = Vector2(extent, extent)
	token.position = cell_center(cell) - token.size * 0.5

func _token_position(cell: Vector2i, token: AirshipToken) -> Vector2:
	var extent: float = minf(cell_step.x, cell_step.y) * token_fill
	token.size = Vector2(extent, extent)
	return cell_center(cell) - token.size * 0.5

func _layout_ships() -> void:
	for id in tokens:
		var token: AirshipToken = tokens[id]
		var fallback_index: int = clampi(int(id) - 1, 0, PREVIEW_STARTS.size() - 1)
		var cell: Vector2i = Vector2i(token.get_meta("grid_cell", PREVIEW_STARTS[fallback_index]))
		_position_token(token, cell)

func _layout_start_pads() -> void:
	var extent: float = minf(cell_step.x, cell_step.y) * 0.72
	for i in range(pad_nodes.size()):
		var pad: Panel = pad_nodes[i]
		if i >= PREVIEW_STARTS.size():
			pad.visible = false
			continue
		pad.visible = true
		pad.size = Vector2(extent, extent)
		pad.position = cell_center(PREVIEW_STARTS[i]) - pad.size * 0.5

func _layout_rocks() -> void:
	var extent: float = minf(cell_step.x, cell_step.y) * rock_fill
	for i in range(rock_nodes.size()):
		var rock_node: Panel = rock_nodes[i]
		if i >= rocks.size():
			rock_node.visible = false
			continue
		rock_node.visible = true
		rock_node.size = Vector2(extent * 1.12, extent)
		rock_node.position = cell_center(rocks[i]) - rock_node.size * 0.5

func _layout_contracts() -> void:
	var cells: Array[Vector2i] = _sorted_cells(pickup_cells)
	var width: float = minf(cell_step.x * 0.90, 112.0)
	var height: float = minf(cell_step.y * 0.72, 58.0)
	for i in range(contract_nodes.size()):
		var node: Panel = contract_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		var contract: Dictionary = pickup_cells[cell]
		node.visible = true
		node.size = Vector2(width, height)
		node.position = cell_center(cell) - node.size * 0.5
		var name_label: Label = node.get_node("Name") as Label
		var reward_label: Label = node.get_node("Reward") as Label
		var target_label: Label = node.get_node("Target") as Label
		name_label.text = str(contract.get("short", contract.get("name", "Kargo"))).to_upper()
		reward_label.text = "+%d ALTIN" % int(contract.get("value", 0))
		target_label.text = "→ %s" % str(contract.get("dest_name", "Teslimat"))
		_fit_contract_text(node)

func _fit_contract_text(node: Panel) -> void:
	var width: float = node.size.x
	for label_name in ["Name", "Reward", "Target"]:
		var label: Label = node.get_node(label_name) as Label
		label.offset_left = 3.0
		label.offset_right = width - 3.0
	var name_label: Label = node.get_node("Name") as Label
	name_label.offset_top = 2.0
	name_label.offset_bottom = 19.0
	var reward: Label = node.get_node("Reward") as Label
	reward.offset_top = 18.0
	reward.offset_bottom = 36.0
	var target: Label = node.get_node("Target") as Label
	target.offset_top = 35.0
	target.offset_bottom = node.size.y - 2.0

func _layout_deliveries() -> void:
	var cells: Array[Vector2i] = _sorted_cells(delivery_cells)
	var extent: float = minf(cell_step.x, cell_step.y) * 0.66
	for i in range(delivery_nodes.size()):
		var node: Panel = delivery_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		node.visible = true
		node.size = Vector2(extent * 1.28, extent)
		node.position = cell_center(cell) - node.size * 0.5
		var label: Label = node.get_node("Label") as Label
		label.text = str(delivery_cells[cell]).to_upper().replace(" ", "\n")

func _sorted_cells(source: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key in source.keys():
		result.append(Vector2i(key))
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return result

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		call_deferred("fit_board")
