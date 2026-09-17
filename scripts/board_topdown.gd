@tool
extends "res://scripts/board.gd"

@export var show_editor_preview: bool = true

const PREVIEW_STARTS: Array[Vector2i] = [
	Vector2i(1,1), Vector2i(9,1), Vector2i(1,7), Vector2i(9,7)
]
const PREVIEW_FACINGS: Array[int] = [2, 2, 0, 0]

func _ready() -> void:
	if Engine.is_editor_hint() and show_editor_preview:
		grid_size = Vector2i(11, 9)
		rocks = [
			Vector2i(3,1), Vector2i(7,1), Vector2i(3,7), Vector2i(7,7),
			Vector2i(2,3), Vector2i(8,3), Vector2i(2,5), Vector2i(8,5),
			Vector2i(5,2), Vector2i(5,6), Vector2i(3,4), Vector2i(7,4)
		]
		pickup_cells = {
			Vector2i(4,3): {"name":"Kaçak Baharat", "short":"Baharat", "dest":Vector2i(9,6), "value":5},
			Vector2i(6,3): {"name":"Fırtına Kristali", "short":"Kristal", "dest":Vector2i(1,6), "value":5},
			Vector2i(4,5): {"name":"Silah Sandığı", "short":"Silah", "dest":Vector2i(9,2), "value":5},
			Vector2i(6,5): {"name":"Kaçak İlaç", "short":"İlaç", "dest":Vector2i(1,2), "value":5}
		}
		delivery_cells = {
			Vector2i(9,6): "D1", Vector2i(1,6): "D2",
			Vector2i(9,2): "D3", Vector2i(1,2): "D4"
		}
		call_deferred("fit_board")
		queue_redraw()

func fit_board() -> void:
	var usable: Vector2 = size - Vector2(110.0, 92.0)
	cell_size = floor(minf(usable.x / float(grid_size.x), usable.y / float(grid_size.y)))
	var grid_pixels: Vector2 = Vector2(grid_size) * cell_size
	grid_origin = Vector2(64.0, 50.0) + (size - Vector2(110.0, 92.0) - grid_pixels) * 0.5
	for id in tokens:
		var token: AirshipToken = tokens[id]
		var token_cell: Vector2i = Vector2i(token.get_meta("grid_cell", Vector2i.ZERO))
		token.size = Vector2(cell_size, cell_size)
		token.position = cell_to_pixel(token_cell)
	queue_redraw()

func add_ship(id: int, color: Color, cell: Vector2i) -> void:
	var token: AirshipToken = AirshipToken.new()
	token.setup(id, color)
	token.size = Vector2(cell_size, cell_size)
	token.set_meta("grid_cell", cell)
	add_child(token)
	tokens[id] = token
	token.position = cell_to_pixel(cell)

func update_ship(id: int, cell: Vector2i, facing: int, hp: int, has_cargo: bool, animate: bool = true) -> Tween:
	if not tokens.has(id):
		return null
	var token: AirshipToken = tokens[id]
	token.set_state(facing, hp, has_cargo)
	token.set_meta("grid_cell", cell)
	var target: Vector2 = cell_to_pixel(cell)
	if not animate:
		token.position = target
		return null
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(token, "position", target, 0.22)
	return tween

func _draw() -> void:
	var grid_pixels: Vector2 = Vector2(grid_size) * cell_size
	var board_rect: Rect2 = Rect2(grid_origin, grid_pixels)
	var surround: Rect2 = board_rect.grow(34.0)

	# Kanyon çerçevesi: satranç tahtası yerine tek parça doğal arena hissi.
	draw_rect(surround.grow(12.0), Color(0.035, 0.026, 0.020, 1.0), true)
	draw_rect(surround, Color(0.18, 0.095, 0.055, 1.0), true)
	draw_rect(board_rect.grow(7.0), Color(0.37, 0.28, 0.19, 1.0), true)
	draw_rect(board_rect.grow(7.0), Color(0.73, 0.49, 0.20, 0.92), false, 3.0)

	# Hücreler aynı zemin ailesinde; yalnızca çok hafif doğal ton farkları var.
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell: Vector2i = Vector2i(x, y)
			var rect: Rect2 = Rect2(cell_to_pixel(cell), Vector2(cell_size, cell_size))
			var variation_seed: int = (x * 17 + y * 31 + x * y * 3) % 9
			var variation: float = (float(variation_seed) - 4.0) * 0.006
			var floor_color: Color = Color(0.33 + variation, 0.285 + variation, 0.215 + variation * 0.7, 1.0)
			draw_rect(rect, floor_color, true)
			_draw_floor_detail(rect, x, y)

	# Grid artık rehber; baskın görsel değil.
	for y in range(grid_size.y + 1):
		var y_pos: float = grid_origin.y + float(y) * cell_size
		draw_line(Vector2(grid_origin.x, y_pos), Vector2(grid_origin.x + grid_pixels.x, y_pos), Color(0.09, 0.075, 0.055, 0.42), 1.0)
	for x in range(grid_size.x + 1):
		var x_pos: float = grid_origin.x + float(x) * cell_size
		draw_line(Vector2(x_pos, grid_origin.y), Vector2(x_pos, grid_origin.y + grid_pixels.y), Color(0.09, 0.075, 0.055, 0.42), 1.0)

	_draw_coordinate_plates()
	_draw_start_pads()

	for rock in rocks:
		_draw_rock(rock)

	for cell in pickup_cells:
		_draw_contract(cell, pickup_cells[cell])

	for cell in delivery_cells:
		_draw_delivery(cell, str(delivery_cells[cell]))

	if Engine.is_editor_hint() and show_editor_preview:
		_draw_preview_ship(PREVIEW_STARTS[0], 1, PREVIEW_FACINGS[0], Color(0.32,0.72,1.0))
		_draw_preview_ship(PREVIEW_STARTS[1], 2, PREVIEW_FACINGS[1], Color(0.95,0.30,0.30))
		_draw_preview_ship(PREVIEW_STARTS[2], 3, PREVIEW_FACINGS[2], Color(0.42,0.90,0.55))
		_draw_preview_ship(PREVIEW_STARTS[3], 4, PREVIEW_FACINGS[3], Color(0.98,0.82,0.30))

func _draw_floor_detail(rect: Rect2, x: int, y: int) -> void:
	var seed_value: int = (x * 43 + y * 67 + x * y * 11) % 100
	var center: Vector2 = rect.position + rect.size * 0.5
	if seed_value % 3 == 0:
		var p1: Vector2 = center + Vector2(-cell_size * 0.22, -cell_size * 0.08)
		var p2: Vector2 = center + Vector2(cell_size * 0.03, cell_size * 0.04)
		var p3: Vector2 = center + Vector2(cell_size * 0.20, -cell_size * 0.02)
		draw_polyline(PackedVector2Array([p1, p2, p3]), Color(0.16, 0.12, 0.085, 0.28), 1.2)
	if seed_value % 4 == 0:
		draw_circle(center + Vector2(cell_size * 0.20, cell_size * 0.18), cell_size * 0.025, Color(0.55, 0.39, 0.19, 0.32))
	if seed_value % 5 == 0:
		draw_line(rect.position + Vector2(8.0, rect.size.y - 10.0), rect.position + Vector2(22.0, rect.size.y - 16.0), Color(0.65,0.49,0.27,0.20), 1.0)

func _draw_coordinate_plates() -> void:
	for x in range(grid_size.x):
		var cx: float = grid_origin.x + (float(x) + 0.5) * cell_size
		var plate: Rect2 = Rect2(cx - cell_size * 0.30, grid_origin.y - 34.0, cell_size * 0.60, 27.0)
		draw_rect(plate, Color(0.075, 0.065, 0.052, 1.0), true)
		draw_rect(plate, Color(0.62, 0.42, 0.19, 0.85), false, 1.5)
		draw_string(ThemeDB.fallback_font, plate.position + Vector2(plate.size.x * 0.37, 20.0), String.chr(65 + x), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.96, 0.88, 0.72))
	for y in range(grid_size.y):
		var cy: float = grid_origin.y + (float(y) + 0.5) * cell_size
		var side_plate: Rect2 = Rect2(grid_origin.x - 37.0, cy - cell_size * 0.25, 28.0, cell_size * 0.50)
		draw_rect(side_plate, Color(0.075, 0.065, 0.052, 1.0), true)
		draw_rect(side_plate, Color(0.62, 0.42, 0.19, 0.85), false, 1.5)
		draw_string(ThemeDB.fallback_font, side_plate.position + Vector2(9.0, side_plate.size.y * 0.67), str(y + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.96, 0.88, 0.72))

func _draw_start_pads() -> void:
	for i in range(PREVIEW_STARTS.size()):
		var cell: Vector2i = PREVIEW_STARTS[i]
		var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
		draw_arc(center, cell_size * 0.34, 0.0, TAU, 28, Color(0.76, 0.58, 0.27, 0.26), 2.0, true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-9.0, cell_size * 0.32), "P%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.90,0.76,0.48,0.55))

func _draw_rock(cell: Vector2i) -> void:
	var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
	var radius: float = cell_size * 0.28
	draw_circle(center + Vector2(3.0, 5.0), radius * 1.10, Color(0.04, 0.03, 0.025, 0.48))
	draw_circle(center, radius, Color(0.30, 0.22, 0.16, 1.0))
	draw_circle(center - Vector2(radius * 0.20, radius * 0.20), radius * 0.62, Color(0.46, 0.35, 0.24, 1.0))
	draw_circle(center + Vector2(radius * 0.30, radius * 0.10), radius * 0.42, Color(0.21, 0.16, 0.12, 1.0))
	draw_arc(center, radius * 0.80, 0.25, 4.9, 18, Color(0.68, 0.50, 0.31, 0.50), 2.0, true)

func _draw_contract(cell: Vector2i, contract_value: Variant) -> void:
	if not (contract_value is Dictionary):
		return
	var contract: Dictionary = contract_value
	var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
	var half: float = cell_size * 0.17
	var crate: Rect2 = Rect2(center - Vector2.ONE * half, Vector2.ONE * half * 2.0)
	draw_circle(center, cell_size * 0.37, Color(0.95, 0.58, 0.08, 0.13))
	draw_arc(center, cell_size * 0.35, 0.0, TAU, 24, Color(1.0, 0.70, 0.18, 0.55), 2.0, true)
	draw_rect(crate, Color(0.52, 0.28, 0.08, 1.0), true)
	draw_rect(crate, Color(1.0, 0.70, 0.17, 0.96), false, 2.5)
	draw_line(crate.position, crate.end, Color(0.94, 0.72, 0.31, 0.75), 1.8)
	draw_line(Vector2(crate.end.x, crate.position.y), Vector2(crate.position.x, crate.end.y), Color(0.94, 0.72, 0.31, 0.75), 1.8)

	var short_name: String = str(contract.get("short", contract.get("name", "Kargo")))
	var value: int = int(contract.get("value", 0))
	var dest: Vector2i = Vector2i(contract.get("dest", cell))
	var info: String = "%s  %dA" % [short_name, value]
	var route: String = "→ %s" % _cell_name(dest)
	draw_string(ThemeDB.fallback_font, center + Vector2(-cell_size * 0.42, -cell_size * 0.31), info, HORIZONTAL_ALIGNMENT_CENTER, cell_size * 0.84, 10, Color(1.0, 0.90, 0.64))
	draw_string(ThemeDB.fallback_font, center + Vector2(-cell_size * 0.30, cell_size * 0.38), route, HORIZONTAL_ALIGNMENT_CENTER, cell_size * 0.60, 11, Color(1.0, 0.77, 0.28))

func _draw_delivery(cell: Vector2i, label_text: String) -> void:
	var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
	draw_circle(center, cell_size * 0.30, Color(0.045, 0.16, 0.17, 0.76))
	draw_arc(center, cell_size * 0.30, 0.0, TAU, 24, Color(0.34, 0.94, 0.88, 0.95), 3.0, true)
	draw_circle(center, cell_size * 0.20, Color(0.08, 0.25, 0.25, 0.72))
	draw_string(ThemeDB.fallback_font, center + Vector2(-cell_size * 0.11, cell_size * 0.11), "H", HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(cell_size * 0.30), Color(0.78, 1.0, 0.96))
	draw_string(ThemeDB.fallback_font, center + Vector2(-cell_size * 0.20, cell_size * 0.39), label_text, HORIZONTAL_ALIGNMENT_CENTER, cell_size * 0.40, 10, Color(0.57, 0.95, 0.90, 0.80))

func _draw_preview_ship(cell: Vector2i, ship_id: int, ship_facing: int, ring_color: Color) -> void:
	var texture: Texture2D = AirshipToken.SHIP_TEXTURES.get(ship_id, null)
	if texture == null:
		return
	var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
	var tex_size: Vector2 = texture.get_size()
	var target_h: float = cell_size * 0.88
	var preview_scale: float = target_h / tex_size.y
	var target_size: Vector2 = tex_size * preview_scale
	draw_arc(center, cell_size * 0.38, 0.0, TAU, 28, ring_color, 3.0, true)
	draw_set_transform(center, deg_to_rad(float(ship_facing) * 90.0), Vector2.ONE)
	draw_texture_rect(texture, Rect2(-target_size * 0.5, target_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _cell_name(cell: Vector2i) -> String:
	return "%s%d" % [String.chr(65 + cell.x), cell.y + 1]
