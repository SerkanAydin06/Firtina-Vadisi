extends Node2D
## Decorative, bounded effects; never touches simulation state or input.
const MAX_EVENTS := 48
var events: Array[Dictionary] = []

func _ready() -> void:
	set_process(false)

func emit_effect(kind: String, start: Vector2, finish: Vector2, value: int) -> void:
	if events.size() >= MAX_EVENTS:
		events.pop_front()
	events.append({"kind": kind, "start": start, "finish": finish, "value": value,
		"age": 0.0, "duration": 0.75 if kind == "delivery" else 0.4})
	set_process(true)
	queue_redraw()

func clear() -> void:
	events.clear()
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	for event in events:
		event.age += delta
	events = events.filter(func(event: Dictionary) -> bool: return event.age < event.duration)
	set_process(not events.is_empty())
	queue_redraw()

func _draw() -> void:
	for event in events:
		var progress: float = event.age / event.duration
		var origin: Vector2 = event.start
		var gold := Color(1.0, 0.77, 0.35, 1.0 - progress)
		match event.kind:
			"motor":
				var end: Vector2 = origin.lerp(event.finish, minf(progress * 2.0, 1.0))
				draw_line(origin, end, Color(0.3, 0.83, 1.0, (1.0 - progress) * 0.22), 12.0, true)
				draw_line(origin, end, Color(0.65, 0.94, 1.0, 1.0 - progress), 2.0, true)
			"hook":
				var end: Vector2 = event.finish
				var middle := (origin + end) * 0.5 + Vector2(0, sin(progress * PI) * 12.0)
				draw_polyline(PackedVector2Array([origin, middle, end]), Color(0.02, 0.06, 0.08, 1.0 - progress), 6.0, true)
				draw_polyline(PackedVector2Array([origin, middle, end]), gold, 2.0, true)
				draw_arc(end, 8.0, 0.0, PI * 1.5, 16, gold, 2.0, true)
			"spark":
				for i in range(10):
					var direction := Vector2.from_angle(float(i) * TAU / 10.0)
					draw_line(origin + direction * (16.0 + progress * 18.0), origin + direction * (25.0 + progress * 35.0), gold, 2.5, true)
			"delivery":
				draw_arc(origin, 25.0 + progress * 55.0, 0, TAU, 48, gold, 3.0, true)
				draw_arc(origin, 18.0 + progress * 40.0, 0, TAU, 48, Color(0.5, 1.0, 0.9, (1.0 - progress) * 0.6), 1.5, true)
				draw_string(ThemeDB.fallback_font, origin + Vector2(-40, -35 - progress * 25), "+%d ALTIN" % event.value, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, gold)
