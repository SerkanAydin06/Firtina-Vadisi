@tool
extends "res://scripts/board.gd"

@export var show_editor_preview: bool = true
@export_range(60.0, 105.0, 1.0) var token_size_px: float = 85.0
@export_range(0.72, 0.95, 0.01) var far_row_scale: float = 0.82
@export_range(0.0, 0.40, 0.01) var perspective_strength: float = 0.20
@export_range(30.0, 90.0, 1.0) var side_margin: float = 42.0
@export_range(50.0, 120.0, 1.0) var top_margin: float = 76.0
@export_range(55.0, 130.0, 1.0) var bottom_margin: float = 82.0

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

const PLATFORM_DEPTH: float = 18.0

var cell_step: Vector2 = Vector2(100.0, 62.0)
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
	# Görünür board elemanları gerçek sahne node'larıdır.
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

	var near_width: float = maxf(200.0, size.x - side_margin * 2.0)
	var board_height: float = maxf(160.0, size.y - top_margin - bottom_margin)
	inner_origin = Vector2(size.x * 0.5, top_margin)
	inner_size = Vector2(near_width, board_height)
	cell_step = Vector2(near_width / float(grid_size.x), board_height / float(grid_size.y))
	cell_size = minf(cell_step.x, cell_step.y)
	grid_origin = _grid_point(0.0, 0.0)

	_layout_perspective_backdrop()
	_layout_grid_cells()
	_layout_start_pads()
	_layout_rocks()
	_layout_contracts()
	_layout_deliveries()
	_layout_ships()

func _depth_t(grid_y: float) -> float:
	return clampf(grid_y / float(grid_size.y), 0.0, 1.0)

func _projected_y(t: float) -> float:
	var curved_t: float = t * (1.0 - perspective_strength) + t * t * perspective_strength
	return top_margin + inner_size.y * curved_t

func _row_width(t: float) -> float:
	return inner_size.x * lerpf(far_row_scale, 1.0, t)

func _grid_point(grid_x: float, grid_y: float) -> Vector2:
	var t: float = _depth_t(grid_y)
	var width: float = _row_width(t)
	var x_ratio: float = grid_x / float(grid_size.x)
	return Vector2(
		size.x * 0.5 + (x_ratio - 0.5) * width,
		_projected_y(t)
	)

func _cell_quad(cell: Vector2i) -> PackedVector2Array:
	return PackedVector2Array([
		_grid_point(float(cell.x), float(cell.y)),
		_grid_point(float(cell.x + 1), float(cell.y)),
		_grid_point(float(cell.x + 1), float(cell.y + 1)),
		_grid_point(float(cell.x), float(cell.y + 1))
	])

func cell_to_pixel(cell: Vector2i) -> Vector2:
	return cell_center(cell)

func cell_center(cell: Vector2i) -> Vector2:
	return _grid_point(float(cell.x) + 0.5, float(cell.y) + 0.5)

func _depth_scale(cell: Vector2i) -> float:
	return lerpf(far_row_scale, 1.0, _depth_t(float(cell.y) + 0.5))

func _entity_z(cell: Vector2i, local_order: int) -> int:
	return 100 + cell.y * 20 + local_order

func _layout_perspective_backdrop() -> void:
	var top_left: Vector2 = _grid_point(0.0, 0.0)
	var top_right: Vector2 = _grid_point(float(grid_size.x), 0.0)
	var bottom_right: Vector2 = _grid_point(float(grid_size.x), float(grid_size.y))
	var bottom_left: Vector2 = _grid_point(0.0, float(grid_size.y))
	var depth: Vector2 = Vector2(0.0, PLATFORM_DEPTH)

	var base: Polygon2D = get_node_or_null("PerspectiveBase") as Polygon2D
	var shadow: Polygon2D = get_node_or_null("PerspectiveShadow") as Polygon2D
	var front: Polygon2D = get_node_or_null("PerspectiveFrontLip") as Polygon2D
	var right_lip: Polygon2D = get_node_or_null("PerspectiveRightLip") as Polygon2D
	if base != null:
		base.polygon = PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	if shadow != null:
		shadow.polygon = PackedVector2Array([top_left + depth, top_right + depth, bottom_right + depth, bottom_left + depth])
	if front != null:
		front.polygon = PackedVector2Array([bottom_left, bottom_right, bottom_right + depth, bottom_left + depth])
	if right_lip != null:
		right_lip.polygon = PackedVector2Array([top_right, bottom_right, bottom_right + depth, top_right + depth])

func _layout_grid_cells() -> void:
	if grid_size.x <= 0 or grid_size.y <= 0:
		return
	for i in range(grid_nodes.size()):
		var cell_node: Node2D = grid_nodes[i]
		var x: int = i % grid_size.x
		var y: int = floori(float(i) / float(grid_size.x))
		if y >= grid_size.y:
			cell_node.visible = false
			continue
		var quad: PackedVector2Array = _cell_quad(Vector2i(x, y))
		var center: Vector2 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
		var local_quad := PackedVector2Array([
			quad[0] - center,
			quad[1] - center,
			quad[2] - center,
			quad[3] - center
		])
		var inner_quad := PackedVector2Array([
			local_quad[0] * 0.94,
			local_quad[1] * 0.94,
			local_quad[2] * 0.94,
			local_quad[3] * 0.94
		])
		var outline_points := PackedVector2Array([
			local_quad[0], local_quad[1], local_quad[2], local_quad[3], local_quad[0]
		])
		cell_node.visible = true
		cell_node.position = center
		cell_node.scale = Vector2.ONE
		cell_node.z_index = 0
		var fill: Polygon2D = cell_node.get_node_or_null("Fill") as Polygon2D
		var inner: Polygon2D = cell_node.get_node_or_null("InnerGlow") as Polygon2D
		var outline: Line2D = cell_node.get_node_or_null("Outline") as Line2D
		if fill != null:
			fill.polygon = local_quad
			fill.color = Color(0.255, 0.205, 0.145, 0.18 if (x + y) % 2 == 0 else 0.11)
		if inner != null:
			inner.polygon = inner_quad
			inner.color = Color(0.24, 0.34, 0.36, 0.07)
		if outline != null:
			outline.points = outline_points
			outline.width = 2.0
			outline.default_color = Color(0.66, 0.49, 0.28, 0.90)

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

func _ship_extent(cell: Vector2i) -> float:
	return roundf(token_size_px * _depth_scale(cell))

func _position_token(token: AirshipToken, cell: Vector2i) -> void:
	var extent: float = _ship_extent(cell)
	token.size = Vector2(extent, extent)
	var centered_position: Vector2 = cell_center(cell) - token.size * 0.5 + Vector2(0.0, -7.0 * _depth_scale(cell))
	token.position = Vector2(roundf(centered_position.x), roundf(centered_position.y))
	token.z_index = _entity_z(cell, 8)

func _token_position(cell: Vector2i, token: AirshipToken) -> Vector2:
	var extent: float = _ship_extent(cell)
	token.size = Vector2(extent, extent)
	token.z_index = _entity_z(cell, 8)
	var centered_position: Vector2 = cell_center(cell) - token.size * 0.5 + Vector2(0.0, -7.0 * _depth_scale(cell))
	return Vector2(roundf(centered_position.x), roundf(centered_position.y))

func _layout_ships() -> void:
	for id in tokens:
		var token: AirshipToken = tokens[id]
		var fallback_index: int = clampi(int(id) - 1, 0, PREVIEW_STARTS.size() - 1)
		var cell: Vector2i = Vector2i(token.get_meta("grid_cell", PREVIEW_STARTS[fallback_index]))
		_position_token(token, cell)

func _layout_start_pads() -> void:
	for i in range(pad_nodes.size()):
		var pad: Panel = pad_nodes[i]
		if i >= PREVIEW_STARTS.size():
			pad.visible = false
			continue
		var cell: Vector2i = PREVIEW_STARTS[i]
		var s: float = _depth_scale(cell)
		pad.visible = true
		pad.size = Vector2(roundf(64.0 * s), roundf(38.0 * s))
		var pos: Vector2 = cell_center(cell) - pad.size * 0.5 + Vector2(0.0, 5.0 * s)
		pad.position = Vector2(roundf(pos.x), roundf(pos.y))
		pad.z_index = _entity_z(cell, 1)

func _layout_rocks() -> void:
	for i in range(rock_nodes.size()):
		var rock_node: Panel = rock_nodes[i]
		if i >= rocks.size():
			rock_node.visible = false
			continue
		var cell: Vector2i = rocks[i]
		var s: float = _depth_scale(cell)
		rock_node.visible = true
		rock_node.size = Vector2(roundf(62.0 * s), roundf(52.0 * s))
		var pos: Vector2 = cell_center(cell) - rock_node.size * 0.5 + Vector2(0.0, -8.0 * s)
		rock_node.position = Vector2(roundf(pos.x), roundf(pos.y))
		rock_node.z_index = _entity_z(cell, 4)

func _layout_contracts() -> void:
	var cells: Array[Vector2i] = _sorted_cells(pickup_cells)
	for i in range(contract_nodes.size()):
		var node: Panel = contract_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		var contract: Dictionary = pickup_cells[cell]
		var s: float = _depth_scale(cell)
		node.visible = true
		node.size = Vector2(roundf(106.0 * s), roundf(56.0 * s))
		var pos: Vector2 = cell_center(cell) - node.size * 0.5 + Vector2(0.0, -2.0 * s)
		node.position = Vector2(roundf(pos.x), roundf(pos.y))
		node.z_index = _entity_z(cell, 6)
		var name_label: Label = node.get_node("Name") as Label
		var reward_label: Label = node.get_node("Reward") as Label
		var target_label: Label = node.get_node("Target") as Label
		name_label.text = str(contract.get("short", contract.get("name", "Kargo"))).to_upper()
		reward_label.text = "+%d ALTIN" % int(contract.get("value", 0))
		target_label.text = "→ %s" % str(contract.get("dest_name", "Teslimat"))
		_fit_contract_text(node)

func _fit_contract_text(node: Panel) -> void:
	var width: float = node.size.x
	var height: float = node.size.y
	for label_name in ["Name", "Reward", "Target"]:
		var label: Label = node.get_node(label_name) as Label
		label.offset_left = 3.0
		label.offset_right = width - 3.0
	var name_label: Label = node.get_node("Name") as Label
	name_label.offset_top = 1.0
	name_label.offset_bottom = height * 0.33
	var reward: Label = node.get_node("Reward") as Label
	reward.offset_top = height * 0.31
	reward.offset_bottom = height * 0.65
	var target: Label = node.get_node("Target") as Label
	target.offset_top = height * 0.63
	target.offset_bottom = height - 1.0

func _layout_deliveries() -> void:
	var cells: Array[Vector2i] = _sorted_cells(delivery_cells)
	for i in range(delivery_nodes.size()):
		var node: Panel = delivery_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		var s: float = _depth_scale(cell)
		node.visible = true
		node.size = Vector2(roundf(78.0 * s), roundf(44.0 * s))
		var pos: Vector2 = cell_center(cell) - node.size * 0.5
		node.position = Vector2(roundf(pos.x), roundf(pos.y))
		node.z_index = _entity_z(cell, 3)
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
