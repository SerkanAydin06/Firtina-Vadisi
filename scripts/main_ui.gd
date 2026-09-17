extends "res://scripts/main.gd"

const START_CELLS: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(9, 1), Vector2i(1, 7), Vector2i(9, 7)
]
const START_FACINGS: Array[int] = [2, 2, 0, 0]
const CONTRACT_SOURCES: Array[Vector2i] = [
	Vector2i(4, 3), Vector2i(6, 3), Vector2i(4, 5), Vector2i(6, 5)
]
const CONTRACT_DESTINATIONS: Array[Vector2i] = [
	Vector2i(9, 6), Vector2i(1, 6), Vector2i(9, 2), Vector2i(1, 2)
]
const DELIVERY_NAMES: Array[String] = [
	"Bakır İskele", "Sis İskelesi", "Fırtına İskelesi", "Kızıl İskele"
]
const DELIVERY_SHORT_NAMES: Array[String] = [
	"BAKIR", "SİS", "FIRTINA", "KIZIL"
]
const CONTRACT_NAMES: Array[String] = [
	"Kaçak Baharat", "Fırtına Kristali", "Silah Sandığı", "Kaçak İlaç",
	"Bakır Parçalar", "Sis Özü", "Motor Çekirdeği", "Yasak Haritalar"
]
const CONTRACT_SHORT_NAMES: Array[String] = [
	"Baharat", "Kristal", "Silah", "İlaç", "Bakır", "Sis Özü", "Çekirdek", "Harita"
]
const CONTRACT_VALUE: int = 5

var queue_textures: Array[TextureRect] = []
var queue_numbers: Array[Label] = []
var pilot_labels: Array[Label] = []
var contract_serial: int = 0

func build_shell() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background_rect = $Background as TextureRect

func build_menu() -> void:
	menu_layer = $MenuLayer as Control
	settings_popup = $MenuLayer/SettingsPopup as PanelContainer
	$MenuLayer/StartButton.pressed.connect(_on_start_pressed)
	$MenuLayer/SettingsButton.pressed.connect(_on_settings_pressed)
	$MenuLayer/ExitButton.pressed.connect(_on_exit_pressed)

func build_game_ui() -> void:
	game_layer = $GameLayer as Control
	board = $GameLayer/BoardFrame/Board as StormBoard
	round_label = $GameLayer/RightPanel/TopHUD/RoundLabel as Label
	wind_label = $GameLayer/RightPanel/WindPanel/WindLabel as Label
	queue_label = $GameLayer/RightPanel/ProgramPanel/QueueSummary as Label
	command_box = $GameLayer/RightPanel/ProgramPanel/CommandBox as HBoxContainer
	score_box = $GameLayer/PilotsPanel/PilotRows as VBoxContainer
	info_label = $GameLayer/LogPanel/InfoLabel as RichTextLabel
	clear_button = $GameLayer/RightPanel/ClearButton as Button
	execute_button = $GameLayer/RightPanel/ExecuteButton as Button
	info_label.scroll_following = true

	queue_textures = [
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot1/Texture as TextureRect,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot2/Texture as TextureRect,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot3/Texture as TextureRect
	]
	queue_numbers = [
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot1/Number as Label,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot2/Number as Label,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot3/Number as Label
	]
	pilot_labels = [
		$GameLayer/PilotsPanel/PilotRows/Pilot1 as Label,
		$GameLayer/PilotsPanel/PilotRows/Pilot2 as Label,
		$GameLayer/PilotsPanel/PilotRows/Pilot3 as Label,
		$GameLayer/PilotsPanel/PilotRows/Pilot4 as Label
	]

	var pilot_header: Label = $GameLayer/PilotsPanel/Title as Label
	pilot_header.text = "İSİM                 CAN   ALTIN   KARGO / HEDEF"
	pilot_header.offset_right = 536.0
	pilot_header.add_theme_font_size_override("font_size", 15)

	$GameLayer/RightPanel/CardsPanel/Forward1.pressed.connect(_on_command_pressed.bind(CMD_FORWARD_1))
	$GameLayer/RightPanel/CardsPanel/Forward2.pressed.connect(_on_command_pressed.bind(CMD_FORWARD_2))
	$GameLayer/RightPanel/CardsPanel/Left.pressed.connect(_on_command_pressed.bind(CMD_LEFT))
	$GameLayer/RightPanel/CardsPanel/Right.pressed.connect(_on_command_pressed.bind(CMD_RIGHT))
	$GameLayer/RightPanel/CardsPanel/Hook.pressed.connect(_on_command_pressed.bind(CMD_HOOK))
	$GameLayer/RightPanel/CardsPanel/Anchor.pressed.connect(_on_command_pressed.bind(CMD_ANCHOR))
	clear_button.pressed.connect(_on_clear_pressed)
	execute_button.pressed.connect(_on_execute_pressed)
	$GameLayer/RightPanel/RestartButton.pressed.connect(_on_restart_pressed)
	$GameLayer/RightPanel/MenuButton.pressed.connect(show_menu)
	game_built = true

func setup_game() -> void:
	resolving = false
	game_over = false
	round_no = 1
	contract_serial = 0
	player_queue.clear()
	ships.clear()

	rocks = [
		Vector2i(3,1), Vector2i(7,1), Vector2i(3,7), Vector2i(7,7),
		Vector2i(2,3), Vector2i(8,3), Vector2i(2,5), Vector2i(8,5),
		Vector2i(5,2), Vector2i(5,6), Vector2i(3,4), Vector2i(7,4)
	]
	deliveries = {
		CONTRACT_DESTINATIONS[0]: DELIVERY_SHORT_NAMES[0],
		CONTRACT_DESTINATIONS[1]: DELIVERY_SHORT_NAMES[1],
		CONTRACT_DESTINATIONS[2]: DELIVERY_SHORT_NAMES[2],
		CONTRACT_DESTINATIONS[3]: DELIVERY_SHORT_NAMES[3]
	}
	_reset_contracts()

	for child in board.get_children():
		child.queue_free()
	board.tokens.clear()
	board.configure(GRID_SIZE, rocks, pickups, deliveries)

	ships.append(make_ship(1, "Sen", START_CELLS[0], START_FACINGS[0], true, Color(0.32,0.72,1.0)))
	ships.append(make_ship(2, "Kızıl Korsan", START_CELLS[1], START_FACINGS[1], false, Color(0.95,0.30,0.30)))
	ships.append(make_ship(3, "Bakır Martı", START_CELLS[2], START_FACINGS[2], false, Color(0.42,0.90,0.55)))
	if start_with_four_ships:
		ships.append(make_ship(4, "Gece Rüzgârı", START_CELLS[3], START_FACINGS[3], false, Color(0.98,0.82,0.30)))

	for ship in ships:
		board.add_ship(ship.id, ship.color, ship.pos)
		board.update_ship(ship.id, ship.pos, ship.facing, ship.hp, false, false)

	new_wind()
	refresh_ui()
	log_clear()
	log_line("[b]Oyun başladı.[/b] Dört pilot simetrik ve eşit koşullarda başlıyor.")
	log_line("Ortadaki kontratlar ortaktır. Bir kontratı ilk alan pilot o kargoyu kapar.")
	log_line("Her kontratta kargo adı, 5 altın ödül ve isimli teslimat noktası gösterilir.")

func _reset_contracts() -> void:
	pickups = {}
	for source in CONTRACT_SOURCES:
		_spawn_contract_at(source)

func _spawn_contract_at(source: Vector2i) -> void:
	var source_index: int = CONTRACT_SOURCES.find(source)
	if source_index < 0:
		return
	var name_index: int = contract_serial % CONTRACT_NAMES.size()
	var contract: Dictionary = {
		"name": CONTRACT_NAMES[name_index],
		"short": CONTRACT_SHORT_NAMES[name_index],
		"dest": CONTRACT_DESTINATIONS[source_index],
		"source": source,
		"target_name": DELIVERY_NAMES[source_index],
		"target_short": DELIVERY_SHORT_NAMES[source_index],
		"value": CONTRACT_VALUE
	}
	pickups[source] = contract
	contract_serial += 1

func check_all_cargo() -> void:
	var changed_contracts: bool = false
	var respawn_sources: Array[Vector2i] = []
	for ship in ships:
		if ship.hp <= 0:
			continue
		if ship.cargo.is_empty() and pickups.has(ship.pos):
			var claimed: Dictionary = pickups[ship.pos].duplicate(true)
			ship.cargo = claimed
			pickups.erase(ship.pos)
			changed_contracts = true
			log_line("[color=yellow]%s kontratı kaptı: %s → %s (+%d altın).[/color]" % [
				ship.name, claimed.name, str(claimed.target_name), int(claimed.value)
			])
		elif not ship.cargo.is_empty() and ship.pos == ship.cargo.dest:
			var value: int = int(ship.cargo.value)
			var completed_name: String = str(ship.cargo.name)
			var source: Vector2i = Vector2i(ship.cargo.source)
			ship.coins += value
			ship.cargo = {}
			respawn_sources.append(source)
			changed_contracts = true
			log_line("[color=aqua]%s, %s teslimatını tamamladı: +%d altın![/color]" % [ship.name, completed_name, value])

	for source in respawn_sources:
		_spawn_contract_at(source)

	if changed_contracts:
		board.configure(GRID_SIZE, rocks, pickups, deliveries)

func respawn_ship(ship: Dictionary) -> void:
	if not ship.cargo.is_empty():
		var dropped_source: Vector2i = Vector2i(ship.cargo.source)
		if not pickups.has(dropped_source):
			_spawn_contract_at(dropped_source)
			board.configure(GRID_SIZE, rocks, pickups, deliveries)
	ship.hp = MAX_HP
	ship.cargo = {}
	var candidate: Vector2i = START_CELLS[(int(ship.id) - 1) % START_CELLS.size()]
	if ship_at(candidate) == null and not rocks.has(candidate):
		ship.pos = candidate
		return
	for radius in range(1, 5):
		for y in range(maxi(0, candidate.y - radius), mini(GRID_SIZE.y, candidate.y + radius + 1)):
			for x in range(maxi(0, candidate.x - radius), mini(GRID_SIZE.x, candidate.x + radius + 1)):
				var cell: Vector2i = Vector2i(x, y)
				if not rocks.has(cell) and ship_at(cell) == null:
					ship.pos = cell
					return

func refresh_ui() -> void:
	round_label.text = "Tur %d" % round_no
	wind_label.text = DIR_NAMES[wind_dir]
	queue_label.text = ""
	execute_button.disabled = resolving or game_over or player_queue.size() != 3
	clear_button.disabled = resolving or game_over or player_queue.is_empty()

	for i in range(3):
		var slot_texture: TextureRect = queue_textures[i]
		var slot_number: Label = queue_numbers[i]
		if i < player_queue.size():
			slot_texture.texture = COMMAND_TEXTURES[player_queue[i]]
			slot_texture.visible = true
			slot_number.visible = false
		else:
			slot_texture.texture = null
			slot_texture.visible = false
			slot_number.visible = true

	for i in range(pilot_labels.size()):
		var pilot_label: Label = pilot_labels[i]
		if i >= ships.size():
			pilot_label.visible = false
			continue
		pilot_label.visible = true
		var ship: Dictionary = ships[i]
		var cargo_name: String = "—"
		var cargo_target: String = "—"
		if not ship.cargo.is_empty():
			cargo_name = str(ship.cargo.get("short", ship.cargo.name))
			cargo_target = str(ship.cargo.get("target_name", "Teslimat"))
		var name_column: String = str(ship.name).rpad(16, " ")
		var hp_column: String = str(ship.hp).lpad(3, " ")
		var gold_column: String = str(ship.coins).lpad(5, " ")
		var cargo_column: String = (cargo_name + " → " + cargo_target).rpad(24, " ")
		pilot_label.text = "%s | %s | %s | %s" % [name_column, hp_column, gold_column, cargo_column]
		pilot_label.add_theme_font_size_override("font_size", 14)
		pilot_label.add_theme_color_override("font_color", ship.color.lightened(0.15))

func log_clear() -> void:
	info_label.clear()
	info_label.scroll_to_line(0)

func log_line(text: String) -> void:
	info_label.append_text(text + "\n")
	call_deferred("_scroll_log_to_bottom")

func _scroll_log_to_bottom() -> void:
	if not is_instance_valid(info_label):
		return
	var last_line: int = maxi(0, info_label.get_line_count() - 1)
	info_label.scroll_to_line(last_line)
