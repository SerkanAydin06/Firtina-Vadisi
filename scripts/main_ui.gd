extends "res://scripts/main.gd"

var queue_textures: Array[TextureRect] = []
var queue_numbers: Array[Label] = []
var pilot_labels: Array[Label] = []

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
		var cargo_text: String = "Boş" if ship.cargo.is_empty() else str(ship.cargo.name)
		pilot_label.text = "%s   |   ❤ %d   |   Altın %d   |   Kargo: %s" % [ship.name, ship.hp, ship.coins, cargo_text]
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
