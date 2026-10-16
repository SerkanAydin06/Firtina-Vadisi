@tool
extends Node2D
## Open navigation brackets leave the landscape visible between cells.
var footprint := PackedVector2Array([Vector2(-48, -28), Vector2(48, -28), Vector2(56, 28), Vector2(-56, 28)])

func set_footprint(quad: PackedVector2Array) -> void:
	footprint = quad
	queue_redraw()

func _draw() -> void:
	if footprint.size() != 4:
		return
	var ink := Color(0.64, 0.78, 0.76, 0.14)
	var accent := Color(0.83, 0.70, 0.46, 0.18)
	for i in range(4):
		var corner: Vector2 = footprint[i] * 0.96
		var before: Vector2 = footprint[(i + 3) % 4] * 0.96
		var after: Vector2 = footprint[(i + 1) % 4] * 0.96
		var length: float = minf(corner.distance_to(before), corner.distance_to(after)) * 0.08
		draw_polyline(PackedVector2Array([
			corner + corner.direction_to(before) * length,
			corner,
			corner + corner.direction_to(after) * length
		]), ink, 0.8, true)
	# A restrained center mark helps count cells without outlining every square.
	draw_circle(Vector2.ZERO, 0.85, accent, true, -1.0, true)
