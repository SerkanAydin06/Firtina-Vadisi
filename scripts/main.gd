extends Control
## Oyun mantığı: tur, hareket/itiş, kanca, rüzgâr, botlar, hasar ve zafer.
## Sahne bağlantıları ve sunum `main_ui.gd` içindedir; bu dosya düğüm oluşturmaz.

const GRID_SIZE := Vector2i(11, 9)
const MAX_HP := 3
const TARGET_COINS := 12
const WIND_CALM := -1

const CMD_FORWARD_1 := "İleri 1"
const CMD_FORWARD_2 := "İleri 2"
const CMD_LEFT := "Sola Dön"
const CMD_RIGHT := "Sağa Dön"
const CMD_HOOK := "Kanca"
const CMD_ANCHOR := "Çapa"
const COMMANDS := [CMD_FORWARD_1, CMD_FORWARD_2, CMD_LEFT, CMD_RIGHT, CMD_HOOK, CMD_ANCHOR]

const DIRS := [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
const DIR_NAMES := ["KUZEY ↑", "DOĞU →", "GÜNEY ↓", "BATI ←"]
const CALM_NAME := "SAKİN HAVA"

# Bot arama maliyetleri: bir komut 2, bir gövde kaybı 7, rakip hücresine girmek 3.
const AI_STEP_COST := 2
const AI_DAMAGE_COST := 7
const AI_CROWD_COST := 3
const AI_MAX_COST := 80
const AI_MOVES := [CMD_FORWARD_1, CMD_FORWARD_2, CMD_LEFT, CMD_RIGHT, CMD_ANCHOR]

@export var start_with_four_ships := true
@export_range(0.1, 1.0, 0.05) var resolution_pause := 0.28

var background_rect: TextureRect
var menu_layer: Control
var game_layer: Control
var settings_popup: Control
var game_built: bool = false

var board: StormBoard
var round_label: Label
var wind_label: Label
var queue_label: Label
var info_label: RichTextLabel
var execute_button: Button
var clear_button: Button
var command_box: HBoxContainer

var rng := RandomNumberGenerator.new()
var ships: Array[Dictionary] = []
var rocks: Array[Vector2i] = []
var pickups := {}
var deliveries := {}

var player_queue: Array[String] = []
var round_no := 1
var wind_dir := WIND_CALM
var resolving := false
var game_over := false
var session_id: int = 0
var last_winners: Array = []

func _ready() -> void:
	rng.randomize()
	build_shell()
	build_menu()
	build_game_ui()
	show_menu()

# --- Alt sınıfın doldurduğu sahne ve sunum kancaları -------------------------

func build_shell() -> void:
	pass

func build_menu() -> void:
	pass

func build_game_ui() -> void:
	pass

func setup_game() -> void:
	pass

func refresh_ui() -> void:
	pass

func check_all_cargo() -> void:
	pass

func log_clear() -> void:
	pass

func log_line(_text: String) -> void:
	pass

func present_turn(_phase: String, _slot: int = -1) -> void:
	pass

func play_sound(_kind: String) -> void:
	pass

func present_motor_progress(_slot: int, _completed: int) -> void:
	pass

## Botun taşıyacak kargosu ve alınabilir kontrat yoksa bekleyeceği hücreler.
func _ai_idle_goals(_ship: Dictionary) -> Array:
	return []

func respawn_ship(ship: Dictionary) -> void:
	ship.hp = MAX_HP
	ship.anchored = false
	ship.cargo = {}

# --- Menü ve girdi -----------------------------------------------------------

func show_menu() -> void:
	session_id += 1
	resolving = false
	board.cancel_animations()
	menu_layer.visible = true
	game_layer.visible = false
	settings_popup.visible = false

func _on_start_pressed() -> void:
	menu_layer.visible = false
	game_layer.visible = true
	if game_built:
		setup_game()

func _on_settings_pressed() -> void:
	settings_popup.visible = not settings_popup.visible

func _on_exit_pressed() -> void:
	get_tree().quit()

## Çözülen tur da güvenle iptal edilir: yeni oturum eski eşzamansız işleri durdurur.
func _on_restart_pressed() -> void:
	setup_game()

func make_ship(id: int, ship_name: String, pos: Vector2i, facing: int, human: bool, color: Color) -> Dictionary:
	return {
		"id":id, "name":ship_name, "pos":pos, "facing":facing,
		"hp":MAX_HP, "coins":0, "deliveries":0, "cargo":{}, "queue":[],
		"human":human, "color":color, "anchored":false, "downed":false
	}

func can_edit_program() -> bool:
	return not resolving and not game_over and game_built and game_layer.visible

func _on_command_pressed(command: String) -> void:
	if resolving or game_over or player_queue.size() >= 3:
		return
	player_queue.append(command)
	refresh_ui()

func _on_clear_pressed() -> void:
	if resolving or game_over:
		return
	player_queue.clear()
	refresh_ui()

func _on_undo_pressed() -> void:
	if resolving or game_over or player_queue.is_empty():
		return
	player_queue.pop_back()
	refresh_ui()

func _on_execute_pressed() -> void:
	if resolving or game_over or player_queue.size() != 3:
		return
	resolving = true
	set_input_enabled(false)
	await execute_round()

# --- Tur çözümü --------------------------------------------------------------

func execute_round() -> void:
	var active_session: int = session_id
	for ship in ships:
		ship.queue.clear()
		ship.anchored = false
		ship.downed = false
	for ship in ships:
		ship.queue = player_queue.duplicate() if ship.human else plan_ai(ship)

	log_line("\n[b]--- TUR %d ---[/b]" % round_no)
	for ship in ships:
		log_line("%s: %s | %s | %s" % [ship.name, ship.queue[0], ship.queue[1], ship.queue[2]])

	for slot in range(3):
		present_turn("command", slot)
		log_line("\n[i]Komut %d çözülüyor...[/i]" % (slot + 1))
		await resolve_slot(slot, active_session)
		if active_session != session_id or game_over:
			return
		if check_victory():
			return
		await get_tree().create_timer(resolution_pause).timeout
		if active_session != session_id:
			return
		present_turn("wind", slot)
		if wind_dir == WIND_CALM:
			log_line("Sakin hava: rüzgâr esmedi.")
		else:
			log_line("Rüzgâr itişi: %s" % DIR_NAMES[wind_dir])
		await resolve_wind()
		if active_session != session_id:
			return
		await get_tree().create_timer(resolution_pause).timeout
		if active_session != session_id:
			return
		check_all_cargo()
		refresh_ui()
		if check_victory():
			return

	round_no += 1
	player_queue.clear()
	new_wind()
	resolving = false
	set_input_enabled(true)
	refresh_ui()

## Düşüp onarılan pilot turun kalan komutlarını uygulamaz.
func can_act(ship: Dictionary) -> bool:
	return ship.hp > 0 and not ship.get("downed", false)

func resolve_slot(slot: int, active_session: int = -1) -> void:
	if active_session == -1:
		active_session = session_id
	for ship in ships:
		if not can_act(ship):
			continue
		var cmd: String = ship.queue[slot]
		if cmd == CMD_LEFT:
			ship.facing = (ship.facing + 3) % 4
			log_line("%s sola döndü." % ship.name)
		elif cmd == CMD_RIGHT:
			ship.facing = (ship.facing + 1) % 4
			log_line("%s sağa döndü." % ship.name)
		elif cmd == CMD_ANCHOR:
			ship.anchored = true
			log_line("%s çapayı bıraktı; sıradaki rüzgâra karşı sabitlendi." % ship.name)
	await animate_all()
	if active_session != session_id:
		return

	resolve_hooks(slot)
	await animate_all()
	if active_session != session_id:
		return

	present_motor_progress(slot, 0)
	for substep in range(2):
		var intents := {}
		for ship in ships:
			if not can_act(ship):
				continue
			var cmd: String = ship.queue[slot]
			var steps := 0
			if cmd == CMD_FORWARD_1:
				steps = 1
			elif cmd == CMD_FORWARD_2:
				steps = 2
			if substep < steps:
				intents[ship.id] = DIRS[ship.facing]
		if intents.is_empty():
			break
		var origins: Dictionary = {}
		for ship in ships:
			origins[ship.id] = ship.pos
		resolve_simultaneous_step(intents, "motor")
		for ship in ships:
			var origin: Vector2i = origins[ship.id]
			var delta: Vector2i = ship.pos - origin
			if intents.has(ship.id) and absi(delta.x) + absi(delta.y) == 1:
				board.show_effect("motor", board.cell_center(origin), board.cell_center(ship.pos))
		check_all_cargo()
		await animate_all()
		if active_session != session_id:
			return
		present_motor_progress(slot, substep + 1)
		await get_tree().create_timer(0.07).timeout
		if active_session != session_id:
			return

## Tüm kancalar aynı konumlardan hedef seçer ve çekişler tek eşzamanlı adımda uygulanır.
## Karşı yönlerden veya dik açıyla çekilen hedef yerinde kalır.
func resolve_hooks(slot: int) -> void:
	var pulls := {}
	for ship in ships:
		if not can_act(ship) or ship.queue[slot] != CMD_HOOK:
			continue
		var target: Variant = find_hook_target(ship)
		if target == null:
			log_line("%s kancayı boşa attı." % ship.name)
			continue
		board.show_hook(ship.id, target.id)
		log_line("%s, %s zeplinine kanca taktı!" % [ship.name, target.name])
		if target.get("downed", false):
			log_line("%s onarımda; kanca onu yerinden oynatamadı." % target.name)
		elif absi(ship.pos.x - target.pos.x) + absi(ship.pos.y - target.pos.y) > 1:
			pulls[target.id] = pulls.get(target.id, Vector2i.ZERO) + sign_vec(ship.pos - target.pos)
		else:
			log_line("Kanca gerildi ama zeplinler zaten bitişik; konum değişmedi.")
	var intents := {}
	for id in pulls:
		var pull: Vector2i = pulls[id]
		if absi(pull.x) + absi(pull.y) == 1:
			intents[id] = pull
		else:
			log_line("%s iki yönden çekildi; kancalar birbirini dengeledi." % get_ship(id).name)
	if not intents.is_empty():
		resolve_simultaneous_step(intents, "kanca")
		check_all_cargo()

func resolve_wind() -> void:
	if wind_dir == WIND_CALM:
		for ship in ships:
			ship.anchored = false
		await animate_all()
		return
	play_sound("wind")
	var intents := {}
	for ship in ships:
		if can_act(ship) and not ship.anchored:
			intents[ship.id] = DIRS[wind_dir]
	resolve_simultaneous_step(intents, "rüzgâr")
	for ship in ships:
		ship.anchored = false
	check_all_cargo()
	await animate_all()

func resolve_simultaneous_step(intents: Dictionary, cause: String) -> void:
	var destinations := {}
	for id in intents:
		var ship: Variant = get_ship(id)
		destinations[id] = ship.pos + intents[id]

	var target_to_ids := {}
	for id in destinations:
		var target: Vector2i = destinations[id]
		if not target_to_ids.has(target):
			target_to_ids[target] = []
		target_to_ids[target].append(id)
	var blocked_ids := {}
	if cause == "rüzgâr":
		for ship in ships:
			if ship.anchored or ship.get("downed", false):
				blocked_ids[ship.id] = true
	for target in target_to_ids:
		var colliding_ids: Array = target_to_ids[target]
		if colliding_ids.size() > 1:
			for id in colliding_ids:
				blocked_ids[id] = true
				board.flash_ship(id)
			log_line("%s çarpışması: aynı hücreye %d zeplin girmeye çalıştı." % [cause.capitalize(), colliding_ids.size()])

	for id in destinations:
		if blocked_ids.has(id):
			continue
		var ship: Variant = get_ship(id)
		var other: Variant = ship_at(destinations[id])
		if other != null and destinations.has(other.id) and destinations[other.id] == ship.pos:
			blocked_ids[id] = true
			blocked_ids[other.id] = true
			board.flash_ship(id)
			board.flash_ship(other.id)
			log_line("%s ile %s kafa kafaya geldi." % [ship.name, other.name])

	var ordered_ids: Array = intents.keys()
	ordered_ids.sort()
	if ordered_ids.size() > 1:
		var shift := round_no % ordered_ids.size()
		for i in range(shift):
			ordered_ids.append(ordered_ids.pop_front())
	var moved_this_step := {}
	var damage_ids := {}
	for id in ordered_ids:
		if blocked_ids.has(id) or moved_this_step.has(id):
			continue
		var proposed := {}
		var failure := {}
		if _plan_step(id, intents[id], intents, blocked_ids, moved_this_step, proposed, failure):
			for moving_id in proposed:
				get_ship(moving_id).pos = proposed[moving_id]
				moved_this_step[moving_id] = true
		elif failure.has("id"):
			damage_ids[failure.id] = failure.reason
	# Hasar hareket işleminden sonra uygulanır; yeniden doğma girdileri değiştirmez.
	for id in damage_ids:
		damage_ship(get_ship(id), 1, damage_ids[id])

func _plan_step(id: int, dir: Vector2i, intents: Dictionary, blocked: Dictionary,
		moved: Dictionary, proposed: Dictionary, failure: Dictionary) -> bool:
	if proposed.has(id):
		return true # Üç veya daha fazla zeplinden oluşan döngü aynı anda boşalabilir.
	if blocked.has(id) or moved.has(id):
		return false
	var ship: Dictionary = get_ship(id)
	var target: Vector2i = ship.pos + dir
	if not is_inside(target) or rocks.has(target):
		failure.id = id
		failure.reason = "kayalığa çarptı" if rocks.has(target) else "kanyon duvarına çarptı"
		return false
	if proposed.values().has(target):
		return false
	proposed[id] = target
	var occupant: Variant = ship_at(target)
	if occupant != null:
		var next_dir: Vector2i = intents.get(occupant.id, dir)
		if not _plan_step(occupant.id, next_dir, intents, blocked, moved, proposed, failure):
			return false
	return true

func find_hook_target(attacker: Dictionary) -> Variant:
	var dir: Vector2i = DIRS[attacker.facing]
	for distance in range(1,4):
		var cell: Vector2i = attacker.pos + dir * distance
		if not is_inside(cell) or rocks.has(cell):
			break
		var target: Variant = ship_at(cell)
		if target != null:
			return target
	return null

func sign_vec(v: Vector2i) -> Vector2i:
	return Vector2i(signi(v.x), signi(v.y))

func damage_ship(ship: Dictionary, amount: int, reason: String) -> void:
	ship.hp = max(0, ship.hp - amount)
	board.flash_ship(ship.id)
	log_line("[color=salmon]%s %s: -%d gövde.[/color]" % [ship.name, reason, amount])
	if ship.hp <= 0:
		respawn_ship(ship)
		ship.downed = resolving
		if resolving:
			log_line("[b][color=red]%s düştü! Başlangıcında onarıldı; bu turun kalanını bekleyecek.[/color][/b]" % ship.name)
		else:
			log_line("[b][color=red]%s düştü! Başlangıcında onarıldı.[/color][/b]" % ship.name)

# --- Botlar ------------------------------------------------------------------

func plan_ai(ship: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var pos: Vector2i = ship.pos
	var facing: int = ship.facing
	var hp: int = ship.hp
	var cargo: Dictionary = ship.cargo
	var available: Dictionary = pickups.duplicate(true)
	var crowd := {}
	for other in ships:
		if other.id != ship.id and other.hp > 0:
			crowd[other.pos] = true
	for slot in range(3):
		var goals: Array = [cargo.dest] if not cargo.is_empty() else available.keys()
		if goals.is_empty():
			goals = _ai_idle_goals(ship)
		var command: String = _ai_next_command(pos, facing, hp, goals, crowd)
		result.append(command)
		var next: Dictionary = ai_simulate(pos, facing, hp, command)
		if next.hp <= 0:
			break
		pos = next.pos
		facing = next.facing
		hp = next.hp
		for cell in next.cells:
			if cargo.is_empty() and available.has(cell):
				cargo = available[cell]
				available.erase(cell)
			elif not cargo.is_empty() and cell == cargo.dest:
				cargo = {}
	while result.size() < 3:
		result.append(CMD_ANCHOR)
	return result

## Tek başına bir zeplinin bir komut + rüzgâr sonucunu çözücüyle aynı kurallarla hesaplar.
## `cells`, kargo/teslimat kontrolü yapılan hücreleri sırayla içerir.
func ai_simulate(pos: Vector2i, facing: int, hp: int, command: String) -> Dictionary:
	var state := {"pos": pos, "facing": facing, "hp": hp, "damage": 0, "cells": []}
	if command == CMD_LEFT:
		state.facing = (facing + 3) % 4
	elif command == CMD_RIGHT:
		state.facing = (facing + 1) % 4
	var steps: int = 2 if command == CMD_FORWARD_2 else (1 if command == CMD_FORWARD_1 else 0)
	for step in range(steps):
		var target: Vector2i = state.pos + DIRS[state.facing]
		if not is_inside(target) or rocks.has(target):
			state.damage += 1
		else:
			state.pos = target
			state.cells.append(target)
	if command != CMD_ANCHOR and wind_dir != WIND_CALM:
		var drift: Vector2i = state.pos + DIRS[wind_dir]
		if not is_inside(drift) or rocks.has(drift):
			state.damage += 1
		else:
			state.pos = drift
			state.cells.append(drift)
	state.hp = hp - state.damage
	return state

## En ucuz rotanın ilk komutu. Güvenli rota yoksa sınırlı hasarı kabul eder,
## hedefe hiç ulaşılamıyorsa hedefe en çok yaklaştıran komutu seçer.
func _ai_next_command(pos: Vector2i, facing: int, hp: int, goals: Array, crowd: Dictionary = {}) -> String:
	if goals.is_empty():
		return CMD_ANCHOR
	var goal_set := {}
	for goal in goals:
		goal_set[goal] = true
	var buckets: Array = []
	buckets.resize(AI_MAX_COST + 1)
	for i in range(buckets.size()):
		buckets[i] = []
	var best := {Vector4i(pos.x, pos.y, facing, hp): 0}
	buckets[0].append({"pos": pos, "facing": facing, "hp": hp, "first": "", "goal": false})
	var fallback: String = CMD_ANCHOR
	var fallback_score: int = _ai_distance(pos, goals) * 10
	for cost in range(buckets.size()):
		for state in buckets[cost]:
			if state.goal:
				return state.first
			if best.get(Vector4i(state.pos.x, state.pos.y, state.facing, state.hp), -1) < cost:
				continue
			for command in AI_MOVES:
				var next: Dictionary = ai_simulate(state.pos, state.facing, state.hp, command)
				if next.hp <= 0:
					continue
				var first: String = command if state.first == "" else state.first
				var step_cost: int = AI_STEP_COST + next.damage * AI_DAMAGE_COST
				var reached: bool = false
				for cell in next.cells:
					if crowd.has(cell):
						step_cost += AI_CROWD_COST
					if goal_set.has(cell):
						reached = true
				var next_cost: int = cost + step_cost
				if next_cost > AI_MAX_COST:
					continue
				if reached:
					buckets[next_cost].append({"first": first, "goal": true})
					continue
				var key := Vector4i(next.pos.x, next.pos.y, next.facing, next.hp)
				if best.has(key) and best[key] <= next_cost:
					continue
				best[key] = next_cost
				buckets[next_cost].append({"pos": next.pos, "facing": next.facing, "hp": next.hp, "first": first, "goal": false})
				var score: int = _ai_distance(next.pos, goals) * 10 + next_cost
				if score < fallback_score:
					fallback_score = score
					fallback = first
	return fallback

func _ai_distance(pos: Vector2i, goals: Array) -> int:
	var nearest: int = 999
	for goal in goals:
		nearest = mini(nearest, absi(goal.x - pos.x) + absi(goal.y - pos.y))
	return nearest

# --- Zafer, rüzgâr ve yardımcılar -------------------------------------------

## Eşik geçilirse önce altın, sonra kalan gövde kazananı belirler; ikisi de eşitse ortak zafer.
func victory_winners() -> Array:
	var contenders: Array = ships.filter(func(ship: Dictionary) -> bool: return ship.coins >= TARGET_COINS)
	if contenders.is_empty():
		return []
	contenders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.coins != b.coins:
			return a.coins > b.coins
		if a.hp != b.hp:
			return a.hp > b.hp
		return a.id < b.id)
	var top: Dictionary = contenders[0]
	return contenders.filter(func(ship: Dictionary) -> bool: return ship.coins == top.coins and ship.hp == top.hp)

func check_victory() -> bool:
	var winners: Array = victory_winners()
	if winners.is_empty():
		return false
	last_winners = winners
	game_over = true
	resolving = false
	set_input_enabled(false)
	if winners.size() == 1:
		log_line("\n[b][color=yellow]%s %d altına ulaştı ve Fırtına Vadisi'ni kazandı![/color][/b]" % [winners[0].name, winners[0].coins])
	else:
		var names: Array = winners.map(func(ship: Dictionary) -> String: return str(ship.name))
		log_line("\n[b][color=yellow]Ortak zafer: %s %d altınla eşit bitirdi![/color][/b]" % [", ".join(names), winners[0].coins])
	refresh_ui()
	return true

## İlk tur sakin geçer: köşelerdeki pilotlar daha komut seçmeden duvara itilmez.
func new_wind() -> void:
	if round_no <= 1:
		wind_dir = WIND_CALM
		return
	var old := wind_dir
	wind_dir = rng.randi_range(0,3)
	if old != WIND_CALM and wind_dir == old and rng.randf() < 0.55:
		wind_dir = (wind_dir + rng.randi_range(1,3)) % 4

func wind_name() -> String:
	return CALM_NAME if wind_dir == WIND_CALM else DIR_NAMES[wind_dir]

func animate_all() -> void:
	refresh_tokens(true)
	await get_tree().create_timer(0.24).timeout

func refresh_tokens(animate := false) -> void:
	for ship in ships:
		board.update_ship(ship.id, ship.pos, ship.facing, ship.hp, not ship.cargo.is_empty(), animate)

func set_input_enabled(enabled: bool) -> void:
	for child in get_tree().get_nodes_in_group("command_buttons"):
		if child is BaseButton:
			child.disabled = not enabled
	clear_button.disabled = not enabled or player_queue.is_empty()
	execute_button.disabled = not enabled or player_queue.size() != 3

func get_ship(id: int) -> Variant:
	for ship in ships:
		if ship.id == id:
			return ship
	return null

func ship_at(cell: Vector2i) -> Variant:
	for ship in ships:
		if ship.hp > 0 and ship.pos == cell:
			return ship
	return null

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y
