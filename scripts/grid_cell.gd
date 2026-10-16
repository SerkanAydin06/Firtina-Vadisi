@tool
extends Node2D
## Invisible cell geometry. The locator and route preview provide context.
var footprint := PackedVector2Array([Vector2(-48, -28), Vector2(48, -28), Vector2(56, 28), Vector2(-56, 28)])

func set_footprint(quad: PackedVector2Array) -> void:
	footprint = quad
	queue_redraw()
