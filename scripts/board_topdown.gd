@tool
extends "res://scripts/board.gd"

@export var show_editor_preview: bool = true
@export_range(60.0, 120.0, 1.0) var token_size_px: float = 85.0
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
var vertical_grid_lines: Array[ColorRect] = []
var horizontal_grid_lines: Array[ColorRect] = []
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
	# Bilerek boş: görünür bütün board elemanları .tscn node'larıdır.
	pass

func _cache_scene_nodes() -> void:
	grid_nodes.clear()
	vertical_grid_lines.clear()
	horizontal_grid_lines.clear()
	rock_nodes.clear()
	contract_nodes.clear()
	delivery_nodes.clear()
	pad_nodes.clear()
	for child in $GridLayer.get_children():
		if child is Panel:
			grid_nodes.append(child)
		elif child is ColorRect:
			var line: ColorRect = child
			var line_name: String = str(line.name)
			if line_name.begins_with("V"):
				vertical_grid_lines.append(line)
			elif line_name.begins_with("H"):
				horizontal_grid_lines.append(line)
	vertical_grid_lines.sort_custom(func(a: ColorRect, b: ColorRect) -> bool: return str(a.name) < str(b.name))
	horizontal_grid_lines.sort_custom(func(a: ColorRect, b: ColorRect) -> bool: return str(a.name) < str(b.name))
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

	# Hücrelerin tamamı aynı tam piksel ölçüsünde olsun.
	# Tasarım boyutu 1305x801 olduğunda sonuç tam olarak 117x87'dir.
	var available_width: float = maxf(1.0, size.x - 18.0)
	var available_height: float = maxf(1.0, size.y - 18.0)
	var step_x: float = maxf(1.0, floorf(available_width / float(grid_size.x)))
	var step_y: float = maxf(1.0, floorf(available_height / float(grid_size.y)))
	cell_step = Vector2(step_x, step_y)
	inner_size = Vector2(step_x * float(grid_size.x), step_y * float(grid_size.y))
	inner_origin = Vector2(
		roundf((size.x - inner_size.x) * 0.5),
		roundf((size.y - inner_size.y) * 0.5)
	)
	cell_size = minf(cell_step.x, cell_step.y)
	grid_origin = inner_origin

	_layout_grid_cells()
	_layout_start_pads()
	_layout_rocks()
	_layout_contracts()
	_layout_deliveries()
	_layout_ships()

func _layout_grid_cells() -> void:
	if grid_size.x <= 0 or grid_size.y <= 0:
		return

	for i in range(grid_nodes.size()):
		var cell_node: Panel = grid_nodes[i]
		var x: int = i % grid_size.x
		var y: int = floori(float(i) / float(grid_size.x))
		if y >= grid_size.y:
			cell_node.visible = false
			continue
		cell_node.visible = true
		cell_node.position = cell_to_pixel(Vector2i(x, y))
		cell_node.size = cell_step

	const LINE_WIDTH: float = 2.0
	for i in range(vertical_grid_lines.size()):
		var line: ColorRect = vertical_grid_lines[i]
		if i > grid_size.x:
			line.visible = false
			continue
		var px: float = inner_origin.x + float(i) * cell_step.x
		line.visible = true
		line.position = Vector2(px - LINE_WIDTH * 0.5, inner_origin.y)
		line.size = Vector2(LINE_WIDTH, inner_size.y)

	for i in range(horizontal_grid_lines.size()):
		var line: ColorRect = horizontal_grid_lines[i]
		if i > grid_size.y:
			line.visible = false
			continue
		var py: float = inner_origin.y + float(i) * cell_step.y
		line.visible = true
		line.position = Vector2(inner_origin.x, py - LINE_WIDTH * 0.5)
		line.size = Vector2(inner_size.x, LINE_WIDTH)

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

func _ship_extent() -> float:
	# Gemi hücrenin dışına taşmasın. 2 px toplam güvenlik payı bırak.
	return roundf(minf(token_size_px, minf(cell_step.x - 2.0, cell_step.y - 2.0)))

func _position_token(token: AirshipToken, cell: Vector2i) -> void:
	var extent: float = _ship_extent()
	token.size = Vector2(extent, extent)
	var centered_position: Vector2 = cell_center(cell) - token.size * 0.5
	token.position = Vector2(roundf(centered_position.x), roundf(centered_position.y))

func _token_position(cell: Vector2i, token: AirshipToken) -> Vector2:
	var extent: float = _ship_extent()
	token.size = Vector2(extent, extent)
	var centered_position: Vector2 = cell_center(cell) - token.size * 0.5
	return Vector2(roundf(centered_position.x), roundf(centered_position.y))

func _layout_ships() -> void:
	for id in tokens:
		var token: AirshipToken = tokens[id]
		var fallback_index: int = clampi(int(id) - 1, 0, PREVIEW_STARTS.size() - 1)
		var cell: Vector2i = Vector2i(token.get_meta("grid_cell", PREVIEW_STARTS[fallback_index]))
		_position_token(token, cell)

func _layout_start_pads() -> void:
	var extent: float = roundf(minf(cell_step.x, cell_step.y) * 0.72)
	for i in range(pad_nodes.size()):
		var pad: Panel = pad_nodes[i]
		if i >= PREVIEW_STARTS.size():
			pad.visible = false
			continue
		pad.visible = true
		pad.size = Vector2(extent, extent)
		var raw_position: Vector2 = cell_center(PREVIEW_STARTS[i]) - pad.size * 0.5
		pad.position = Vector2(roundf(raw_position.x), roundf(raw_position.y))

func _layout_rocks() -> void:
	var extent: float = roundf(minf(cell_step.x, cell_step.y) * rock_fill)
	for i in range(rock_nodes.size()):
		var rock_node: Panel = rock_nodes[i]
		if i >= rocks.size():
			rock_node.visible = false
			continue
		rock_node.visible = true
		rock_node.size = Vector2(roundf(extent * 1.12), extent)
		var raw_position: Vector2 = cell_center(rocks[i]) - rock_node.size * 0.5
		rock_node.position = Vector2(roundf(raw_position.x), roundf(raw_position.y))

func _layout_contracts() -> void:
	var cells: Array[Vector2i] = _sorted_cells(pickup_cells)
	var width: float = roundf(minf(cell_step.x * 0.90, 112.0))
	var height: float = roundf(minf(cell_step.y * 0.72, 58.0))
	for i in range(contract_nodes.size()):
		var node: Panel = contract_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		var contract: Dictionary = pickup_cells[cell]
		node.visible = true
		node.size = Vector2(width, height)
		var raw_position: Vector2 = cell_center(cell) - node.size * 0.5
		node.position = Vector2(roundf(raw_position.x), roundf(raw_position.y))
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
	var extent: float = roundf(minf(cell_step.x, cell_step.y) * 0.66)
	for i in range(delivery_nodes.size()):
		var node: Panel = delivery_nodes[i]
		if i >= cells.size():
			node.visible = false
			continue
		var cell: Vector2i = cells[i]
		node.visible = true
		node.size = Vector2(roundf(extent * 1.28), extent)
		var raw_position: Vector2 = cell_center(cell) - node.size * 0.5
		node.position = Vector2(roundf(raw_position.x), roundf(raw_position.y))
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
