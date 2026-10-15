extends RefCounted
## Read-only forecast: never inspect opponents' queues or consume gameplay RNG.
const DIRS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func build(ship: Dictionary, commands: Array, wind: int, rocks: Array,
		ships: Array, grid: Vector2i) -> Dictionary:
	var result := {"steps": [], "reason": ""}
	var pos: Vector2i = ship.pos
	var facing: int = ship.facing
	var hp: int = ship.hp
	var occupied := {}
	for other in ships:
		if other.id != ship.id and other.hp > 0:
			occupied[other.pos] = true
	for slot in range(commands.size()):
		var command: String = commands[slot]
		if command == "Sola Dön":
			facing = (facing + 3) % 4
		elif command == "Sağa Dön":
			facing = (facing + 1) % 4
		elif command == "Kanca":
			for distance in range(1, 4):
				var cell: Vector2i = pos + DIRS[facing] * distance
				if not _inside(cell, grid) or rocks.has(cell):
					break
				if occupied.has(cell):
					result.steps.append(_step(pos, cell, "hook", slot, true))
					result.reason = "Kanca hedefi hareket edebilir; devamı belirsiz."
					return result
		var count: int = 2 if command == "İleri 2" else (1 if command == "İleri 1" else 0)
		if count == 0:
			result.steps.append(_step(pos, pos, "anchor" if command == "Çapa" else "turn", slot, false))
		# Every command gets its own wind, except the single wind blocked by anchor.
		for phase in ["motor", "wind"]:
			var steps: int = count if phase == "motor" else (0 if command == "Çapa" else 1)
			var direction: Vector2i = DIRS[facing] if phase == "motor" else DIRS[wind]
			for substep in range(steps):
				var target: Vector2i = pos + direction
				var blocked: bool = not _inside(target, grid) or rocks.has(target)
				var risk: bool = occupied.has(target)
				result.steps.append(_step(pos, target, phase, slot, blocked or risk))
				if risk:
					result.reason = "Rakip konumunda çarpışma riski; devamı belirsiz."
					return result
				if blocked:
					hp -= 1
					if hp <= 0:
						result.reason = "Gövde tükenebilir; yeniden doğma sonrası rota gösterilmez."
						return result
				else:
					pos = target
	return result

static func _step(from: Vector2i, to: Vector2i, kind: String, slot: int, risk: bool) -> Dictionary:
	return {"from": from, "to": to, "kind": kind, "slot": slot + 1, "risk": risk}

static func _inside(cell: Vector2i, grid: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid.x and cell.y < grid.y
