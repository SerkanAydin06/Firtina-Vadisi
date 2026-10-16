extends Node2D
## Input-transparent contextual locator; never selects or moves a pilot.
var board: Control
var enabled: bool = true
var cell := Vector2i(-1, -1)
var last_pointer := Vector2.INF

func _process(_delta: float) -> void:
	if not enabled or not board.is_visible_in_tree():
		clear()
		return
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null or (hovered != board and not board.is_ancestor_of(hovered)):
		clear()
		return
	var pointer: Vector2 = board.get_local_mouse_position()
	if pointer == last_pointer:
		return
	last_pointer = pointer
	show_at(pointer)

func show_at(pointer: Vector2) -> void:
	var next := Vector2i(-1, -1)
	for y in range(board.grid_size.y):
		for x in range(board.grid_size.x):
			var candidate := Vector2i(x, y)
			if Geometry2D.is_point_in_polygon(pointer, board._cell_quad(candidate)):
				next = candidate
				break
		if next.x >= 0:
			break
	if cell != next:
		cell = next
		queue_redraw()

func clear() -> void:
	last_pointer = Vector2.INF
	if cell.x >= 0:
		cell = Vector2i(-1, -1)
		queue_redraw()

func _draw() -> void:
	if cell.x < 0:
		return
	var center: Vector2 = board.cell_center(cell)
	var radius: float = board.cell_size * 0.37
	draw_set_transform(center, 0.0, Vector2(1.0, 0.58))
	for i in range(5):
		draw_circle(Vector2.ZERO, radius + float(i) * 3.0, Color(0.28, 0.72, 0.73, 0.025))
	var color := Color(0.72, 0.85, 0.81, 0.65)
	for i in range(4):
		var angle: float = float(i) * PI * 0.5 + 0.12
		draw_arc(Vector2.ZERO, radius, angle, angle + 1.1, 20, color, 1.2, true)
	draw_set_transform(Vector2.ZERO)
	var tag := center + Vector2(-16, radius * 0.58 + 15)
	draw_string(ThemeDB.fallback_font, tag, "%s · %d" % [String.chr(65 + cell.x), cell.y + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c6aa79"))
