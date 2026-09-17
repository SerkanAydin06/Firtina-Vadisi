extends "res://scripts/board.gd"

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

	draw_rect(surround.grow(10.0), Color(0.075, 0.040, 0.025, 1.0), true)
	draw_rect(surround, Color(0.22, 0.115, 0.068, 1.0), true)
	draw_rect(board_rect.grow(6.0), Color(0.055, 0.052, 0.048, 1.0), true)
	draw_rect(board_rect.grow(6.0), Color(0.68, 0.47, 0.20, 0.95), false, 3.0)

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell: Vector2i = Vector2i(x, y)
			var rect: Rect2 = Rect2(cell_to_pixel(cell), Vector2(cell_size, cell_size))
			var base: float = 0.27 if (x + y) % 2 == 0 else 0.245
			draw_rect(rect, Color(base + 0.055, base + 0.035, base, 1.0), true)
			draw_rect(rect, Color(0.78, 0.71, 0.59, 0.26), false, 1.2)
			draw_rect(rect.grow(-5.0), Color(0.09, 0.08, 0.07, 0.10), false, 1.0)

	for x in range(grid_size.x):
		var cx: float = grid_origin.x + (float(x) + 0.5) * cell_size
		var plate: Rect2 = Rect2(cx - cell_size * 0.34, grid_origin.y - 36.0, cell_size * 0.68, 29.0)
		draw_rect(plate, Color(0.065, 0.066, 0.066, 1.0), true)
		draw_rect(plate, Color(0.62, 0.44, 0.22, 0.9), false, 1.5)
		draw_string(ThemeDB.fallback_font, plate.position + Vector2(plate.size.x * 0.37, 21.0), String.chr(65 + x), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.96, 0.88, 0.72))
	for y in range(grid_size.y):
		var cy: float = grid_origin.y + (float(y) + 0.5) * cell_size
		var side_plate: Rect2 = Rect2(grid_origin.x - 39.0, cy - cell_size * 0.28, 30.0, cell_size * 0.56)
		draw_rect(side_plate, Color(0.065, 0.066, 0.066, 1.0), true)
		draw_rect(side_plate, Color(0.62, 0.44, 0.22, 0.9), false, 1.5)
		draw_string(ThemeDB.fallback_font, side_plate.position + Vector2(10.0, side_plate.size.y * 0.66), str(y + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.96, 0.88, 0.72))

	for rock in rocks:
		var center: Vector2 = cell_to_pixel(rock) + Vector2.ONE * cell_size * 0.5
		var radius: float = cell_size * 0.28
		draw_circle(center + Vector2(2.0, 4.0), radius * 1.05, Color(0.04, 0.03, 0.025, 0.50))
		draw_circle(center, radius, Color(0.31, 0.24, 0.18, 1.0))
		draw_circle(center - Vector2(radius * 0.18, radius * 0.18), radius * 0.60, Color(0.44, 0.35, 0.26, 1.0))
		draw_circle(center + Vector2(radius * 0.28, radius * 0.10), radius * 0.43, Color(0.23, 0.18, 0.14, 1.0))
		draw_arc(center, radius * 0.78, 0.2, 4.8, 18, Color(0.65, 0.50, 0.34, 0.55), 2.0, true)

	for cell in pickup_cells:
		var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
		var half: float = cell_size * 0.20
		var crate: Rect2 = Rect2(center - Vector2.ONE * half, Vector2.ONE * half * 2.0)
		draw_rect(crate, Color(0.52, 0.28, 0.08, 1.0), true)
		draw_rect(crate, Color(1.0, 0.69, 0.16, 0.95), false, 3.0)
		draw_line(crate.position, crate.end, Color(0.95, 0.72, 0.30, 0.8), 2.0)
		draw_line(Vector2(crate.end.x, crate.position.y), Vector2(crate.position.x, crate.end.y), Color(0.95, 0.72, 0.30, 0.8), 2.0)
		draw_arc(center, cell_size * 0.31, 0.0, TAU, 24, Color(1.0, 0.72, 0.18, 0.36), 2.0, true)

	for cell in delivery_cells:
		var center: Vector2 = cell_to_pixel(cell) + Vector2.ONE * cell_size * 0.5
		draw_circle(center, cell_size * 0.29, Color(0.07, 0.18, 0.19, 0.76))
		draw_arc(center, cell_size * 0.29, 0.0, TAU, 24, Color(0.36, 0.92, 0.87, 0.95), 3.0, true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-cell_size * 0.11, cell_size * 0.12), "H", HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(cell_size * 0.34), Color(0.75, 1.0, 0.96))
