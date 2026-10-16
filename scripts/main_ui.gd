extends "res://scripts/main.gd"

const START_CELLS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(10, 0), Vector2i(0, 8), Vector2i(10, 8)
]
const START_FACINGS: Array[int] = [2, 3, 1, 0]
const CONTRACT_SOURCES: Array[Vector2i] = [
	Vector2i(4, 3), Vector2i(6, 3), Vector2i(4, 5), Vector2i(6, 5)
]
const CONTRACT_DESTINATIONS: Array[Vector2i] = [
	Vector2i(9, 6), Vector2i(1, 6), Vector2i(9, 2), Vector2i(1, 2)
]
const DESTINATION_NAMES: Array[String] = [
	"Bakır İskele", "Sis İskelesi", "Fırtına İskelesi", "Kızıl İskele"
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
var pilot_rows: Array[Panel] = []
var pilot_name_labels: Array[Label] = []
var pilot_hp_labels: Array[Label] = []
var pilot_gold_labels: Array[Label] = []
var pilot_cargo_labels: Array[Label] = []
var reduced_motion: bool = false
var contract_serial: int = 0
var board_focus: Node2D
var route_overlay: Node2D
var route_hint: Label
var game_audio: Node
var music_volume: float = 0.35
var effects_volume: float = 0.65
var victory_screen: Control
var contract_tracker: Node
var turn_phase: String = "planning"
var active_slot: int = -1
var slot_styles: Array[StyleBox] = []
var wind_style: StyleBox

func build_shell() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background_rect = $Background as TextureRect

func build_menu() -> void:
	menu_layer = $MenuLayer as Control
	settings_popup = $MenuLayer/SettingsPopup as PanelContainer
	$MenuLayer/StartButton.pressed.connect(_on_start_pressed)
	$MenuLayer/SettingsButton.pressed.connect(_on_settings_pressed)
	$MenuLayer/ExitButton.pressed.connect(_on_exit_pressed)
	_load_settings()
	$MenuLayer/SettingsPopup/Options/Music.value_changed.connect(_set_music_volume)
	$MenuLayer/SettingsPopup/Options/Effects.value_changed.connect(_set_effects_volume)
	$MenuLayer/SettingsPopup/Options/ReduceMotion.toggled.connect(_set_reduced_motion)
	$MenuLayer/SettingsPopup/Options/Fullscreen.toggled.connect(_set_fullscreen)
	$MenuLayer/SettingsPopup/Options/Pause.value_changed.connect(_set_resolution_pause)
	$MenuLayer/SettingsPopup/Options/Close.pressed.connect(func() -> void: settings_popup.hide())

func build_game_ui() -> void:
	game_layer = $GameLayer as Control
	board = $GameLayer/BoardFrame/Board as StormBoard
	board.set_reduced_motion(reduced_motion)
	game_audio = preload("res://scripts/game_audio.gd").new()
	add_child(game_audio)
	game_audio.set_levels(music_volume, effects_volume)
	board.sound_requested.connect(play_sound)
	round_label = $GameLayer/RightPanel/TopHUD/RoundLabel as Label
	wind_label = $GameLayer/RightPanel/WindPanel/WindLabel as Label
	queue_label = $GameLayer/RightPanel/ProgramPanel/QueueSummary as Label
	command_box = $GameLayer/RightPanel/ProgramPanel/CommandBox as HBoxContainer
	info_label = $GameLayer/LogPanel/InfoLabel as RichTextLabel
	clear_button = $GameLayer/RightPanel/ClearButton as Button
	execute_button = $GameLayer/RightPanel/ExecuteButton as Button
	info_label.scroll_following = true

	queue_textures = [
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot1/Selected/Texture as TextureRect,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot2/Selected/Texture as TextureRect,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot3/Selected/Texture as TextureRect
	]
	queue_numbers = [
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot1/Number as Label,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot2/Number as Label,
		$GameLayer/RightPanel/ProgramPanel/CommandBox/Slot3/Number as Label
	]

	pilot_rows = [
		$GameLayer/PilotsPanel/Pilot1 as Panel,
		$GameLayer/PilotsPanel/Pilot2 as Panel,
		$GameLayer/PilotsPanel/Pilot3 as Panel,
		$GameLayer/PilotsPanel/Pilot4 as Panel
	]
	pilot_name_labels = [
		$GameLayer/PilotsPanel/Pilot1/Columns/Name as Label,
		$GameLayer/PilotsPanel/Pilot2/Columns/Name as Label,
		$GameLayer/PilotsPanel/Pilot3/Columns/Name as Label,
		$GameLayer/PilotsPanel/Pilot4/Columns/Name as Label
	]
	pilot_hp_labels = [
		$GameLayer/PilotsPanel/Pilot1/Columns/HP as Label,
		$GameLayer/PilotsPanel/Pilot2/Columns/HP as Label,
		$GameLayer/PilotsPanel/Pilot3/Columns/HP as Label,
		$GameLayer/PilotsPanel/Pilot4/Columns/HP as Label
	]
	pilot_gold_labels = [
		$GameLayer/PilotsPanel/Pilot1/Columns/Gold as Label,
		$GameLayer/PilotsPanel/Pilot2/Columns/Gold as Label,
		$GameLayer/PilotsPanel/Pilot3/Columns/Gold as Label,
		$GameLayer/PilotsPanel/Pilot4/Columns/Gold as Label
	]
	pilot_cargo_labels = [
		$GameLayer/PilotsPanel/Pilot1/Columns/Cargo as Label,
		$GameLayer/PilotsPanel/Pilot2/Columns/Cargo as Label,
		$GameLayer/PilotsPanel/Pilot3/Columns/Cargo as Label,
		$GameLayer/PilotsPanel/Pilot4/Columns/Cargo as Label
	]

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
	_bind_scene_controls()
	for slot in command_box.get_children():
		slot_styles.append(slot.get_theme_stylebox("panel"))
	wind_style = $GameLayer/RightPanel/WindPanel.get_theme_stylebox("panel")
	victory_screen = preload("res://scripts/victory_screen.gd").new()
	add_child(victory_screen)
	victory_screen.setup(self)
	route_overlay = preload("res://scripts/route_overlay.gd").new()
	route_overlay.board = board
	route_overlay.z_index = 400
	board.add_child(route_overlay)
	board_focus = preload("res://scripts/board_focus.gd").new()
	board_focus.board = board
	board_focus.z_index = 90
	board.add_child(board_focus)
	board.resized.connect(board_focus.clear)
	board.resized.connect(route_overlay.queue_redraw)
	route_hint = board.get_node("RouteHint") as Label
	contract_tracker = preload("res://scripts/contract_tracker.gd").new()
	add_child(contract_tracker)
	contract_tracker.setup(self)
	board.resized.connect(func() -> void: contract_tracker.call_deferred("refresh"))

func setup_game() -> void:
	game_audio.stop_all()
	game_audio.start_music()
	if is_instance_valid(victory_screen):
		victory_screen.dismiss()
	session_id += 1
	board.cancel_animations()
	set_input_enabled(true)
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
		CONTRACT_DESTINATIONS[0]: DESTINATION_NAMES[0],
		CONTRACT_DESTINATIONS[1]: DESTINATION_NAMES[1],
		CONTRACT_DESTINATIONS[2]: DESTINATION_NAMES[2],
		CONTRACT_DESTINATIONS[3]: DESTINATION_NAMES[3]
	}
	_reset_contracts()
	board.configure(GRID_SIZE, rocks, pickups, deliveries)

	for id in board.tokens:
		var token: AirshipToken = board.tokens[id]
		token.visible = false

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
	log_line("[color=#d5b47c][b]Sefer başladı.[/b][/color] Rüzgârı oku, rotanı belirle.")
	log_line("Bir kontrat al ve işaretli iskeleye teslim et: [color=#d5b47c]+5 altın.[/color]")
	log_line("Ortadaki kontratlar ortaktır. İlk ulaşan pilot kontratı kapar.")

func _reset_contracts() -> void:
	pickups = {}
	for source in CONTRACT_SOURCES:
		_spawn_contract_at(source)

func _spawn_contract_at(source: Vector2i) -> void:
	var source_index: int = CONTRACT_SOURCES.find(source)
	if source_index < 0:
		return
	var name_index: int = contract_serial % CONTRACT_NAMES.size()
	pickups[source] = {
		"name": CONTRACT_NAMES[name_index],
		"short": CONTRACT_SHORT_NAMES[name_index],
		"dest": CONTRACT_DESTINATIONS[source_index],
		"dest_name": DESTINATION_NAMES[source_index],
		"source": source,
		"value": CONTRACT_VALUE
	}
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
				ship.name, claimed.name, claimed.dest_name, int(claimed.value)
			])
		elif not ship.cargo.is_empty() and ship.pos == ship.cargo.dest:
			var value: int = int(ship.cargo.value)
			var completed_name: String = str(ship.cargo.name)
			var source: Vector2i = Vector2i(ship.cargo.source)
			board.show_effect("delivery", board.cell_center(ship.pos), Vector2.ZERO, value)
			ship.coins += value
			ship.deliveries += 1
			ship.cargo = {}
			respawn_sources.append(source)
			changed_contracts = true
			log_line("[color=aqua]%s, %s teslimatını tamamladı: +%d altın![/color]" % [ship.name, completed_name, value])

	for source in respawn_sources:
		_spawn_contract_at(source)
	if changed_contracts:
		board.configure(GRID_SIZE, rocks, pickups, deliveries)
		_refresh_contract_tracking()

func respawn_ship(ship: Dictionary) -> void:
	if not ship.cargo.is_empty():
		var dropped_source: Vector2i = Vector2i(ship.cargo.source)
		if not pickups.has(dropped_source):
			pickups[dropped_source] = ship.cargo.duplicate(true)
			board.configure(GRID_SIZE, rocks, pickups, deliveries)
	ship.hp = MAX_HP
	ship.anchored = false
	ship.cargo = {}
	_refresh_contract_tracking()
	var candidate: Vector2i = START_CELLS[(int(ship.id) - 1) % START_CELLS.size()]
	if (ship_at(candidate) == null or ship_at(candidate) == ship) and not rocks.has(candidate):
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
	if not resolving:
		present_turn("finished" if game_over else "planning")
	_refresh_contract_tracking()
	_refresh_route_preview()
	round_label.text = "Tur %d" % round_no
	wind_label.text = DIR_NAMES[wind_dir]
	queue_label.text = ""
	execute_button.disabled = resolving or game_over or player_queue.size() != 3
	clear_button.disabled = resolving or game_over or player_queue.is_empty()

	for i in range(3):
		var slot_texture: TextureRect = queue_textures[i]
		var slot_number: Label = queue_numbers[i]
		if i < player_queue.size():
			slot_texture.texture = preload("res://scripts/presentation.gd").command_texture(player_queue[i])
			slot_texture.visible = true
			slot_texture.get_parent().get_node("Caption").text = player_queue[i].to_upper()
			slot_texture.get_parent().get_node("Caption").show()
			slot_number.visible = false
		else:
			slot_texture.texture = null
			slot_texture.visible = false
			slot_texture.get_parent().get_node("Caption").hide()
			slot_number.visible = true

	for i in range(pilot_rows.size()):
		if i >= ships.size():
			pilot_rows[i].visible = false
			continue
		pilot_rows[i].visible = true
		var ship: Dictionary = ships[i]
		pilot_name_labels[i].text = str(ship.name)
		pilot_hp_labels[i].text = "%d / %d" % [int(ship.hp), MAX_HP]
		pilot_gold_labels[i].text = str(ship.coins)
		if ship.cargo.is_empty():
			pilot_cargo_labels[i].text = "—"
		else:
			pilot_cargo_labels[i].text = "%s  →  %s" % [
				str(ship.cargo.get("short", ship.cargo.name)),
				str(ship.cargo.get("dest_name", "Teslimat"))
			]
		var row_color: Color = ship.color.lightened(0.14)
		pilot_name_labels[i].add_theme_color_override("font_color", row_color)
		pilot_hp_labels[i].add_theme_color_override("font_color", row_color)
		pilot_gold_labels[i].add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
		pilot_cargo_labels[i].add_theme_color_override("font_color", Color(0.86, 0.88, 0.83))

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

func _load_settings() -> void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	music_volume = clampf(float(config.get_value("audio", "music", 0.35)), 0.0, 1.0)
	effects_volume = clampf(float(config.get_value("audio", "effects", 0.65)), 0.0, 1.0)
	_refresh_audio_settings()
	reduced_motion = bool(config.get_value("game", "reduced_motion", false))
	$MenuLayer/SettingsPopup/Options/ReduceMotion.set_pressed_no_signal(reduced_motion)
	var fullscreen: bool = bool(config.get_value("display", "fullscreen", true))
	resolution_pause = clampf(float(config.get_value("game", "resolution_pause", 0.28)), 0.1, 1.0)
	$MenuLayer/SettingsPopup/Options/Fullscreen.set_pressed_no_signal(fullscreen)
	$MenuLayer/SettingsPopup/Options/Pause.set_value_no_signal(resolution_pause)
	$MenuLayer/SettingsPopup/Options/SpeedLabel.text = "Komutlar arası bekleme: %.2f sn" % resolution_pause
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", $MenuLayer/SettingsPopup/Options/Fullscreen.button_pressed)
	config.set_value("game", "resolution_pause", resolution_pause)
	config.set_value("game", "reduced_motion", reduced_motion)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "effects", effects_volume)
	config.save("user://settings.cfg")

func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()

func _set_resolution_pause(value: float) -> void:
	resolution_pause = clampf(value, 0.1, 1.0)
	$MenuLayer/SettingsPopup/Options/SpeedLabel.text = "Komutlar arası bekleme: %.2f sn" % resolution_pause
	_save_settings()

func _refresh_route_preview() -> void:
	if is_instance_valid(board_focus):
		board_focus.enabled = not resolving and not game_over and game_layer.visible
		if not board_focus.enabled:
			board_focus.clear()
	if not is_instance_valid(route_overlay):
		return
	if resolving and not game_over and game_layer.visible:
		route_overlay.set_forecast([])
		return
	if game_over or player_queue.is_empty() or ships.is_empty() or not game_layer.visible:
		route_overlay.set_forecast([])
		route_hint.text = ""
		return
	var forecast: Dictionary = preload("res://scripts/route_preview.gd").build(ships[0], player_queue, wind_dir, rocks, ships, GRID_SIZE)
	route_overlay.set_forecast(forecast.steps)
	route_hint.text = "TAHMİNİ ROTA   •   %d motor adımı   •   Kesik mavi: rüzgâr   •   ×: risk" % route_overlay.motor_count
	if not forecast.reason.is_empty():
		route_hint.text = forecast.reason + "  Altın: motor / Mavi: rüzgâr / ×: risk."

func set_input_enabled(enabled: bool) -> void:
	super.set_input_enabled(enabled)
	_refresh_route_preview()

func show_menu() -> void:
	if is_instance_valid(game_audio):
		game_audio.stop_all()
	if is_instance_valid(victory_screen):
		victory_screen.dismiss()
	super.show_menu()
	present_turn("planning")
	_refresh_contract_tracking()
	_refresh_route_preview()

func _refresh_contract_tracking() -> void:
	if is_instance_valid(contract_tracker):
		contract_tracker.refresh()

func _set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if is_instance_valid(board):
		board.set_reduced_motion(enabled)
	_save_settings()

func present_turn(phase: String, slot: int = -1) -> void:
	if is_instance_valid(route_hint):
		if phase == "command":
			present_motor_progress(slot, 0)
		elif phase == "wind":
			route_hint.text = "RÜZGÂR   •   Çapa etkin" if ships[0].anchored else "RÜZGÂR   •   1 hücre sürüklenme"
		else:
			route_hint.text = ""
	turn_phase = phase
	active_slot = slot if phase in ["command", "wind"] else -1
	if slot_styles.is_empty():
		return
	var title: Label = $GameLayer/RightPanel/ProgramPanel/Title
	var wind: Panel = $GameLayer/RightPanel/WindPanel
	wind.add_theme_stylebox_override("panel", wind_style)
	wind.get_node("Title").text = "RÜZGÂR PUSULASI"
	for i in range(command_box.get_child_count()):
		var card: PanelContainer = command_box.get_child(i)
		card.add_theme_stylebox_override("panel", slot_styles[i])
		card.tooltip_text = "Bu komutu kaldırmak için tıkla" if phase == "planning" else "Komut %d" % (i + 1)
	var accent := Color("e8bc70") if phase == "command" else Color("8ed5d3")
	if active_slot >= 0 and active_slot < command_box.get_child_count():
		var highlight := preload("res://scripts/presentation.gd").panel(Color("203b43"), accent, 8)
		highlight.set_border_width_all(3)
		command_box.get_child(active_slot).add_theme_stylebox_override("panel", highlight)
	match phase:
		"command":
			title.text = "KOMUT %d / 3   •   UYGULANIYOR" % (slot + 1)
		"wind":
			title.text = "KOMUT %d / 3   •   RÜZGÂR AŞAMASI" % (slot + 1)
			wind.get_node("Title").text = "RÜZGÂR İTİŞİ   •   UYGULANIYOR"
			var highlight := preload("res://scripts/presentation.gd").panel(Color("19404a"), accent, 10)
			highlight.set_border_width_all(2)
			wind.add_theme_stylebox_override("panel", highlight)
		"finished":
			title.text = "SEFER TAMAMLANDI"
		_:
			title.text = "01   UÇUŞ PLANINI HAZIRLA"
	title.add_theme_color_override("font_color", accent if phase == "wind" else Color("e8bc70"))

func check_victory() -> bool:
	if game_over:
		return true
	if not super.check_victory():
		return false
	for ship in ships:
		if ship.coins >= TARGET_COINS:
			victory_screen.show_result(ship)
			break
	return true

func play_sound(kind: String) -> void:
	if is_instance_valid(game_audio) and game_layer.visible and not game_over:
		game_audio.play_event(kind)

func _refresh_audio_settings() -> void:
	var options := $MenuLayer/SettingsPopup/Options
	options.get_node("Music").set_value_no_signal(music_volume)
	options.get_node("Effects").set_value_no_signal(effects_volume)
	options.get_node("MusicLabel").text = "Müzik: %d%%" % roundi(music_volume * 100.0)
	options.get_node("EffectsLabel").text = "Efektler: %d%%" % roundi(effects_volume * 100.0)
	if is_instance_valid(game_audio):
		game_audio.set_levels(music_volume, effects_volume)

func _set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_refresh_audio_settings()
	_save_settings()

func _set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_refresh_audio_settings()
	_save_settings()

func _bind_scene_controls() -> void:
	$GameLayer/PilotCount.text = ("4" if start_with_four_ships else "3") + " PİLOT     /     12 ALTIN"
	var keys := ["Forward1", "Forward2", "Left", "Right", "Hook", "Anchor"]
	for i in range(keys.size()):
		var tile: Button = get_node("GameLayer/RightPanel/CardsPanel/" + keys[i] + "Tile")
		tile.pressed.connect(_on_command_pressed.bind(COMMANDS[i]))
		tile.draw.connect(func() -> void: tile.modulate = Color(0.5, 0.6, 0.65) if tile.disabled else Color.WHITE)
	for i in range(command_box.get_child_count()):
		command_box.get_child(i).gui_input.connect(_on_slot_input.bind(i))

func _on_slot_input(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not resolving and not game_over and slot < player_queue.size():
			player_queue.remove_at(slot)
			refresh_ui()

func present_motor_progress(slot: int, completed: int) -> void:
	if not is_instance_valid(route_hint) or slot < 0 or slot >= player_queue.size():
		return
	var command: String = player_queue[slot]
	var total: int = 2 if command == CMD_FORWARD_2 else (1 if command == CMD_FORWARD_1 else 0)
	route_hint.text = "KOMUT %d   •   Kalan: %d motor adımı" % [slot + 1, maxi(0, total - completed)] if total > 0 else "KOMUT %d   •   %s" % [slot + 1, command]
