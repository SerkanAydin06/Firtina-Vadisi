extends Node2D
## Board-local decoration: Node2D receives no GUI input.
var steps: Array = []
var board: Control

func set_forecast(value: Array) -> void:
	steps = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	if board == null or steps.is_empty():
		return
	var font := ThemeDB.fallback_font
	for step in steps:
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
				draw_line(a, b, color, 3.0, true)
			var wing := direction.orthogonal() * 5.0
			draw_colored_polygon(PackedVector2Array([b, b - direction * 12.0 + wing, b - direction * 12.0 - wing]), color)
		if step.risk:
			draw_circle(finish, 15.0, Color("391d23"))
			draw_line(finish - Vector2(6, 6), finish + Vector2(6, 6), color, 3.0, true)
			draw_line(finish + Vector2(-6, 6), finish + Vector2(6, -6), color, 3.0, true)
		elif step.kind == "wind" or step.kind == "anchor":
			# Per-slot offset keeps consecutive stationary endpoints readable.
			var tag: Vector2 = finish + Vector2(-22 + (step.slot - 1) * 22, -23)
			draw_circle(tag, 11.0, Color("0b1922"))
			draw_arc(tag, 11.0, 0.0, TAU, 24, color, 1.5, true)
			draw_string(font, tag + Vector2(-4.5, 5), str(step.slot), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
