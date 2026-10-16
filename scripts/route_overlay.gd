extends Node2D
## Board-local decoration: Node2D receives no GUI input.
var steps: Array = []
var board: Control
var motor_count: int = 0

func set_forecast(value: Array) -> void:
	steps = value.duplicate(true)
	motor_count = 0
	for step in steps:
		if step.kind == "motor":
			motor_count += 1
	queue_redraw()

func _draw() -> void:
	if board == null or steps.is_empty():
		return
	var font := ThemeDB.fallback_font
	var number := 0
	for step in steps:
		if step.kind == "motor":
			number += 1
		var start: Vector2 = board.cell_center(step.from)
		var finish: Vector2 = board.cell_center(step.to)
		# Boundary markers stay inside the board's clipped canvas.
		finish = finish.clamp(Vector2(14, 14), board.size - Vector2(14, 14))
		var color := Color("e4bd7a")
		if step.kind == "wind":
			color = Color("71cfda")
		if step.risk:
			color = Color("ff8276")
		var delta: Vector2 = finish - start
		if delta.length() > 2.0:
			var direction: Vector2 = delta.normalized()
			var a: Vector2 = start + direction * 12.0
			var b: Vector2 = finish - direction * 12.0
			draw_line(a, b, Color(0.02, 0.05, 0.07, 0.9), 7.0, true)
			if step.kind == "wind" or step.kind == "hook":
				draw_dashed_line(a, b, color, 2.5, 8.0, true)
			else:
				draw_line(a, b, Color(color, 0.12), 11.0, true)
				draw_line(a, b, color, 2.0, true)
			var wing := direction.orthogonal() * 5.0
			draw_colored_polygon(PackedVector2Array([b, b - direction * 12.0 + wing, b - direction * 12.0 - wing]), color)
		if step.risk:
			draw_circle(finish, 15.0, Color("391d23"))
			draw_line(finish - Vector2(6, 6), finish + Vector2(6, 6), color, 3.0, true)
			draw_line(finish + Vector2(-6, 6), finish + Vector2(6, -6), color, 3.0, true)
		elif step.kind == "motor":
			draw_circle(finish, 10.0, Color("0b1922"))
			draw_arc(finish, 10.0, 0.0, TAU, 32, color, 1.2, true)
			draw_string(font, finish + Vector2(-4, 4), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		elif step.kind == "wind":
			# Small wind streaks distinguish drift from numbered motor steps.
			for i in range(3):
				var offset := Vector2(-7 + i * 2, -4 + i * 4)
				draw_line(finish + offset, finish + offset + Vector2(11 - i * 2, 0), color, 1.4, true)
	var last: Dictionary = steps[-1]
	if not steps.any(func(step): return step.risk):
		var destination: Vector2 = board.cell_center(last.to)
		draw_arc(destination, 19.0, 0.0, TAU, 48, Color("e4bd7a"), 1.5, true)
		var label := "%d adım + rüzgâr" % motor_count if steps.any(func(step): return step.kind == "wind") else "%d adım" % motor_count
		var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20.0
		var tag := Vector2(clampf(destination.x - width * 0.5, 4, board.size.x - width - 4), clampf(destination.y + 25, 4, board.size.y - 29))
		draw_style_box(_tag_style(), Rect2(tag, Vector2(width, 24)))
		draw_string(font, tag + Vector2(10, 17), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e4bd7a"))

func _tag_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1922")
	style.border_color = Color("655b43")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
