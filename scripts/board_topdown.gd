@tool
extends "res://scripts/board.gd"

@export var show_editor_preview: bool = true
@export_range(60.0, 120.0, 1.0) var token_size_px: float = 85.0
@export var iso_tile_size: Vector2 = Vector2(116.0, 58.0)
@export_range(0.35, 0.75, 0.01) var rock_fill: float = 0.54

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

const BASE_ISO_TILE: Vector2 = Vector2(116.0, 58.0)
const PLATFORM_DEPTH: float = 20.0

var cell_step: Vector2 = BASE_ISO_TILE
var inner_origin: Vector2 = Vector2.ZERO
var inner_size: Vector2 = Vector2.ZERO
var grid_nodes: Array[Node2D] = []
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
			var token: AirshipToken = tokens.get(i + 1, null) as AirshipToken
			if token != null:
				token.facing = PREVIEW_FACINGS[i]
	call_deferred("fit_board")

func _draw() -> void:
	# Bilerek boş: izometrik görünür board elemanları .tscn node'larıdır.
	pass

func _cache_scene_nodes() -> void:
	grid_nodes.clear()
	rock_nodes.clear()
	contract_nodes.clear()
	delivery_nodes.clear()
	pad_nodes.clear()
	for child in $GridLayer.get_children():
		if child is Node2D:
			grid_nodes.append(child as Node2D)
	for child in $RocksLayer.get_children():
		if child is Panel:
			rock_nodes.append(child)
	for child in $ContractsLayer.get_children():
		if child is Panel:
			contract_nodes.append(child)
	for child in $DeliveriesLayer.get_children():
		if child is Panel:
			delivery_nodes.append(child)
	for child in $StartPadsLayer.get_children():
		if child is Panel:
			pad_nodes.append(child)

func _cache_ship_tokens() -> void:
	tokens.clear()
	for child in $ShipsLayer.get_children():
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
	if size.x <= 1.0 or size.y <= 1.0 or grid_size.x <= 0 or grid_size.y <= 0:
		return

	# İzometrik board, mantıksal 11x9 grid'i değiştirmez.
	var base_width: float = (float(grid_size.x + grid_size.y) * BASE_ISO_TILE.x) * 0.5
	var base_height: float = (float(grid_size.x + grid_size.y) * BASE_ISO_TILE.y) * 0.5
	var scale_factor: float = minf(
		maxf(0.1, (size.x - 110.0) / base_width),
		maxf(0.1, (size.y - 180.0) / base_height)
	)
	scale_factor = minf(scale_factor, 1.0)
	cell_step = iso_tile_size * scale_factor
	cell_size = minf(cell_step.x, cell_step.y)

	# (0,0) hücresinin merkezi. Board yatayda ortalanır, üstte kanyon payı bırakılır.
	var projected_min_x: float = -float(grid_size.y - 1) * cell_step.x * 0.5 - cell_step.x * 0.5
	var projected_max_x: float = float(grid_size.x - 1) * cell_step.x * 0.5 + cell_step.x * 0.5
	var projected_width: float = projected_max_x - projected_min_x
	inner_origin = Vector2(
		floorf((size.x - projected_width) * 0.5 - projected_min_x),
		ceilf(maxf(70.0, (size.y - base_height * scale_factor) * 0.45))
	)
	inner_size = Vector2(projected_width, base_height * scale_factor)
	grid_origin = inner_origin

	_layout_iso_backdrop()
	_layout_grid_cells()
	_layout_start_pads()
	_layout_rocks()
	_layout_contracts()
	_layout_deliveries()
	_layout_ships()

func _layout_iso_backdrop() -> void:
	var top: Vector2 = cell_center(Vector2i(0, 0)) + Vector2(0.0, -cell_step.y * 0.5)
	var right: Vector2 = cell_center(Vector2i(grid_size.x - 1, 0)) + Vector2(cell_step.x * 0.5, 0.0)
	var bottom: Vector2 = cell_center(Vector2i(grid_size.x - 1, grid_size.y - 1)) + Vector2(0.0, cell_step.y * 0.5)
	var left: Vector2 = cell_center(Vector2i(0, grid_size.y - 1)) + Vector2(-cell_step.x * 0.5, 0.0)
	var depth: Vector2 = Vector2(0.0, PLATFORM_DEPTH)

	var base: Polygon2D = get_node_or_null("IsoBase") as Polygon2D
	var shadow: Polygon2D = get_node_or_null("IsoShadow") as Polygon2D
	var front_left: Polygon2D = get_node_or_null("IsoFrontLeft") as Polygon2D
	var front_right: Polygon2D = get_node_or_null("IsoFrontRight") as Polygon2D
	if base != null:
		base.polygon = PackedVector2Array([top, right, bottom, left])
	if shadow != null:
		shadow.polygon = PackedVector2Array([top + depth, right + depth, bottom + depth, left + depth])
	if front_left != null:
		front_left.polygon = PackedVector2Array([left, bottom, bottom + depth, left + depth])
	if front_right != null:
		front_right.polygon = PackedVector2Array([bottom, right, right + depth, bottom + depth])

func _layout_grid_cells() -> void:
	if grid_size.x <= 0 or grid_size.y <= 0:
		return
	var tile_scale: Vector2 = Vector2(cell_step.x / BASE_ISO_TILE.x, cell_step.y / BASE_ISO_TILE.y)
	for i in range(grid_nodes.size()):
		var cell_node: Node2D = grid_nodes[i]
		var x: int = i % grid_size.x
		var y: int = floori(float(i) / float(grid_size.x))
		if y >= grid_size.y:
			cell_node.visible = false
			continue
		cell_node.visible = true
		cell_node.position = cell_center(Vector2i(x, y))
		cell_node.scale = tile_scale
		cell_node.z_index = 0

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
	return cell_center(cell)

func cell_center(cell: Vector2i) -> Vector2:
	return inner_origin + Vector2(
		float(cell.x - cell.y) * cell_step.x * 0.5,
		float(cell.x + cell.y) * cell_step.y * 0.5
	)

func _entity_z(cell: Vector2i, local_order: int) -> int:
	return 100 + (cell.x + cell.y) * 10 + local_order

func _ship_extent() -> float:
	return roundf(token_size_px)

func _position_token(token: AirshipToken, cell: Vector2i) -> void:
	var extent: float = _ship_extent()
	token.size = Vector2(extent, extent)
	var centered_position: Vector2 = cell_center(cell) - token.size * 0.5 + Vector2(0.0, -8.0)
	token.position = Vector2(roundf(centered_position.x), roundf(centered_position.y))
	token.z_index = _entity_z(cell, 5)

func _token_position(cell: Vector2i, token: AirshipToken) -> Vector2:
	var extent: float = _ship_extent()
	token.size = Vector2(extent, extent)
	token.z_index = _entity_z(cell, 5)
	var centered_position: Vector2 = cell_center(cell) - token.size * 0.5 + Vector2(0.0, -8.0)
	return Vector2(roundf(centered_position.x), roundf(centered_position.y))

func _layout_ships() -> void:
	for id in tokens:
		var token: AirshipToken = tokens[id]
		var fallback_index: int = clampi(int(id) - 1, 0, PREVIEW_STARTS.size() - 1)
		var cell: Vector2i = Vector2i(token.get_meta("grid_cell", PREVIEW_STARTS[fallback_index]))
		_position_token(token, cell)

func _layout_start_pads() -> void:
	var pad_size: Vector2 = Vector2(roundf(cell_step.x * 0.47), roundf(cell_step.y * 0.48))
	for i in range(pad_nodes.size()):
		var pad: Panel = pad_nodes[i]
		if i >= PREVIEW_STARTS.size():
			pad.visible = false
			continue
		var cell: Vector2i = PREVIEW_STARTS[i]
		pad.visible = true
		pad.size = pad_size
		var pos: Vector2 = cell_center(cell) - pad.size * 0.5 + Vector2(0.0, 9.0)
		pad.position = Vector2(roundf(pos.x), roundf(pos.y))
		pad.z_index = 10 + (cell.x + cell.y) * 10

func _layout_rocks() -> void:
	var rock_size: Vector2 = Vector2(
		roundf(minf(70.0, cell_step.x * rock_fill)),
		roundf(minf(52.0, cell_step.y * 0.86))
	)
	for i in range(rock_nodes.size()):
		var rock_node: Panel = rock_nodes[i]
		if i >= rocks.size():
			rock_node.visible = false
			continue
		var cell: Vector2i = rocks[i]
		rock_node.visible = true
		rock_node.size = rock_size
		var pos: Vector2 = cell_center(cell) - rock_node.size * 0.5 + Vector2(0.0, -13.0)
		rock_node.position = Vector2(roundf(pos.x), roundf(pos.y))
		rock_node.z_index = _entity_z(cell, 2)

func _layout_contracts() -> void:
	var cells: Array[Vector2i] = _sorted_cells(pickup_cells)
	var width: float = roundf(minf(cell_step.x * 0.80, 94.0))
	var height: float = 54.0
	for i in range(contract_nodes.size()):
		var node: Panel = contract_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		var contract: Dictionary = pickup_cells[cell]
		node.visible = true
		node.size = Vector2(width, height)
		var pos: Vector2 = cell_center(cell) - node.size * 0.5 + Vector2(0.0, -3.0)
		node.position = Vector2(roundf(pos.x), roundf(pos.y))
		node.z_index = _entity_z(cell, 3)
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
	name_label.offset_bottom = 18.0
	var reward: Label = node.get_node("Reward") as Label
	reward.offset_top = 17.0
	reward.offset_bottom = 34.0
	var target: Label = node.get_node("Target") as Label
	target.offset_top = 33.0
	target.offset_bottom = node.size.y - 2.0

func _layout_deliveries() -> void:
	var cells: Array[Vector2i] = _sorted_cells(delivery_cells)
	var node_size: Vector2 = Vector2(
		roundf(minf(74.0, cell_step.x * 0.64)),
		roundf(minf(44.0, cell_step.y * 0.72))
	)
	for i in range(delivery_nodes.size()):
		var node: Panel = delivery_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		node.visible = true
		node.size = node_size
		var pos: Vector2 = cell_center(cell) - node.size * 0.5
		node.position = Vector2(roundf(pos.x), roundf(pos.y))
		node.z_index = _entity_z(cell, 1)
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
