extends Control

const BoardScript = preload("res://scripts/board.gd")

const MENU_BG: Texture2D = preload("res://assets/generated/menu_background.png")
const LOGO_TEX: Texture2D = preload("res://assets/generated/logo.png")
const START_NORMAL: Texture2D = preload("res://assets/generated/start_normal.png")
const START_HOVER: Texture2D = preload("res://assets/generated/start_hover.png")
const SETTINGS_NORMAL: Texture2D = preload("res://assets/generated/settings_normal.png")
const SETTINGS_HOVER: Texture2D = preload("res://assets/generated/settings_hover.png")
const EXIT_NORMAL: Texture2D = preload("res://assets/generated/exit_normal.png")
const EXIT_HOVER: Texture2D = preload("res://assets/generated/exit_hover.png")
const CONFIRM_BUTTON_TEX: Texture2D = preload("res://assets/generated/confirm_button.png")

const GRID_SIZE := Vector2i(11, 9)
const MAX_HP := 3
const TARGET_COINS := 12

const CMD_FORWARD_1 := "İleri 1"
const CMD_FORWARD_2 := "İleri 2"
const CMD_LEFT := "Sola Dön"
const CMD_RIGHT := "Sağa Dön"
const CMD_HOOK := "Kanca"
const CMD_ANCHOR := "Çapa"
const COMMANDS := [CMD_FORWARD_1, CMD_FORWARD_2, CMD_LEFT, CMD_RIGHT, CMD_HOOK, CMD_ANCHOR]
const COMMAND_TEXTURES := {
	CMD_FORWARD_1: preload("res://assets/generated/cmd_forward1.png"),
	CMD_FORWARD_2: preload("res://assets/generated/cmd_forward2.png"),
	CMD_LEFT: preload("res://assets/generated/cmd_left.png"),
	CMD_RIGHT: preload("res://assets/generated/cmd_right.png"),
	CMD_HOOK: preload("res://assets/generated/cmd_hook.png"),
	CMD_ANCHOR: preload("res://assets/generated/cmd_anchor.png")
}

const DIRS := [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
const DIR_NAMES := ["KUZEY ↑", "DOĞU →", "GÜNEY ↓", "BATI ←"]

@export var start_with_four_ships := true
@export_range(0.1, 1.0, 0.05) var resolution_pause := 0.28

var background_rect: TextureRect
var menu_layer: Control
var game_layer: Control
var settings_popup: PanelContainer
var game_built: bool = false

var board: StormBoard
var round_label: Label
var wind_label: Label
var queue_label: Label
var info_label: RichTextLabel
var execute_button: Button
var clear_button: Button
var command_box: HBoxContainer
var score_box: VBoxContainer

var rng := RandomNumberGenerator.new()
var ships: Array[Dictionary] = []
var rocks: Array[Vector2i] = [
	Vector2i(4,1), Vector2i(5,1), Vector2i(7,1),
	Vector2i(2,2), Vector2i(7,2), Vector2i(8,2),
	Vector2i(2,3), Vector2i(5,3), Vector2i(8,3),
	Vector2i(4,4), Vector2i(8,4),
	Vector2i(1,5), Vector2i(4,5), Vector2i(6,5),
	Vector2i(1,6), Vector2i(6,6), Vector2i(9,6),
	Vector2i(3,7), Vector2i(4,7), Vector2i(9,7)
]
var pickups := {
	Vector2i(0,4): {"name":"Kaçak Baharat", "dest":Vector2i(10,4), "value":4},
	Vector2i(5,8): {"name":"Fırtına Kristali", "dest":Vector2i(5,0), "value":5}
}
var deliveries := {
	Vector2i(10,4): "Doğu İskele",
	Vector2i(5,0): "Kuzey Kulesi"
}

var player_queue: Array[String] = []
var round_no := 1
var wind_dir := 1
var resolving := false
var game_over := false

func _ready() -> void:
	rng.randomize()
	build_shell()
	build_menu()
	build_game_ui()
	show_menu()

func build_shell() -> void:
	background_rect = TextureRect.new()
	background_rect.texture = MENU_BG
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	var tint := ColorRect.new()
	tint.color = Color(0.05, 0.045, 0.05, 0.28)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tint)

func build_menu() -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)

	var logo := TextureRect.new()
	logo.texture = LOGO_TEX
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(700, 260)
	column.add_child(logo)

	var subtitle := Label.new()
	subtitle.text = "Rüzgâra karşı. Sınırın ötesine."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.modulate = Color(1.0, 0.92, 0.80)
	column.add_child(subtitle)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)

	buttons.add_child(make_menu_button(START_NORMAL, START_HOVER, _on_start_pressed))
	buttons.add_child(make_menu_button(SETTINGS_NORMAL, SETTINGS_HOVER, _on_settings_pressed))
	buttons.add_child(make_menu_button(EXIT_NORMAL, EXIT_HOVER, _on_exit_pressed))

	settings_popup = PanelContainer.new()
	settings_popup.visible = false
	settings_popup.custom_minimum_size = Vector2(500, 190)
	settings_popup.position = Vector2(40, 40)
	settings_popup.anchor_left = 0.5
	settings_popup.anchor_top = 0.5
	settings_popup.anchor_right = 0.5
	settings_popup.anchor_bottom = 0.5
	settings_popup.offset_left = -250
	settings_popup.offset_top = -95
	settings_popup.offset_right = 250
	settings_popup.offset_bottom = 95
	menu_layer.add_child(settings_popup)

	var popup_margin := MarginContainer.new()
	popup_margin.add_theme_constant_override("margin_left", 18)
	popup_margin.add_theme_constant_override("margin_right", 18)
	popup_margin.add_theme_constant_override("margin_top", 18)
	popup_margin.add_theme_constant_override("margin_bottom", 18)
	settings_popup.add_child(popup_margin)

	var popup_box := VBoxContainer.new()
	popup_box.add_theme_constant_override("separation", 10)
	popup_margin.add_child(popup_box)

	var popup_title := Label.new()
	popup_title.text = "Ayarlar / Bilgi"
	popup_title.add_theme_font_size_override("font_size", 24)
	popup_box.add_child(popup_title)

	var popup_text := Label.new()
	popup_text.text = "• Çözünürlük: 1920 x 1080\n• Üretilen görseller artık menüde, komut kartlarında, oyun alanında ve zeplinlerde uygulanmıştır.\n• Kapatmak için tekrar Ayarlar düğmesine bas."
	popup_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_box.add_child(popup_text)

func build_game_ui() -> void:
	game_layer = Control.new()
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.visible = false
	add_child(game_layer)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.04, 0.42)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	game_layer.add_child(margin)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 18)
	margin.add_child(main_row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	main_row.add_child(left)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	left.add_child(header)

	var logo := TextureRect.new()
	logo.texture = LOGO_TEX
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(360, 105)
	header.add_child(logo)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var hud_box := VBoxContainer.new()
	hud_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_box.add_theme_constant_override("separation", 6)
	header.add_child(hud_box)

	round_label = Label.new()
	round_label.add_theme_font_size_override("font_size", 24)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_box.add_child(round_label)

	wind_label = Label.new()
	wind_label.add_theme_font_size_override("font_size", 22)
	wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_box.add_child(wind_label)

	board = BoardScript.new()
	board.custom_minimum_size = Vector2(1120, 760)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(board)

	var legend := Label.new()
	legend.text = "Sarı = Kargo alımı     Turkuaz = Teslimat     Kızıl işaret = Kayalık / çarpışma alanı"
	legend.modulate = Color(0.95, 0.90, 0.82)
	legend.add_theme_font_size_override("font_size", 18)
	left.add_child(legend)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(520, 0)
	main_row.add_child(side_panel)
	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 16)
	side_margin.add_theme_constant_override("margin_right", 16)
	side_margin.add_theme_constant_override("margin_top", 14)
	side_margin.add_theme_constant_override("margin_bottom", 14)
	side_panel.add_child(side_margin)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	side_margin.add_child(side)

	var program_title := Label.new()
	program_title.text = "3 KOMUT PROGRAMLA"
	program_title.add_theme_font_size_override("font_size", 21)
	side.add_child(program_title)

	queue_label = Label.new()
	queue_label.text = "[ ? ]   [ ? ]   [ ? ]"
	queue_label.add_theme_font_size_override("font_size", 18)
	queue_label.custom_minimum_size.y = 34
	side.add_child(queue_label)

	command_box = HBoxContainer.new()
	command_box.add_theme_constant_override("separation", 8)
	side.add_child(command_box)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	side.add_child(grid)
	for command in COMMANDS:
		var btn := TextureButton.new()
		btn.texture_normal = COMMAND_TEXTURES[command]
		btn.texture_hover = COMMAND_TEXTURES[command]
		btn.texture_pressed = COMMAND_TEXTURES[command]
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(152, 202)
		btn.tooltip_text = command
		btn.pressed.connect(_on_command_pressed.bind(command))
		btn.add_to_group("command_buttons")
		grid.add_child(btn)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	side.add_child(action_row)
	clear_button = Button.new()
	clear_button.text = "Temizle"
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.pressed.connect(_on_clear_pressed)
	action_row.add_child(clear_button)
	execute_button = Button.new()
	execute_button.text = "PROGRAMI AÇ"
	execute_button.disabled = true
	execute_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	execute_button.pressed.connect(_on_execute_pressed)
	action_row.add_child(execute_button)

	var sep := HSeparator.new()
	side.add_child(sep)
	var score_title := Label.new()
	score_title.text = "PİLOTLAR"
	score_title.add_theme_font_size_override("font_size", 18)
	side.add_child(score_title)
	score_box = VBoxContainer.new()
	side.add_child(score_box)

	var sep2 := HSeparator.new()
	side.add_child(sep2)
	var log_title := Label.new()
	log_title.text = "UÇUŞ KAYDI"
	log_title.add_theme_font_size_override("font_size", 18)
	side.add_child(log_title)
	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.fit_content = false
	info_label.scroll_active = true
	info_label.custom_minimum_size = Vector2(0, 280)
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(info_label)

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	side.add_child(footer_row)

	var restart := Button.new()
	restart.text = "Yeni Oyun"
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.pressed.connect(_on_restart_pressed)
	footer_row.add_child(restart)

	var to_menu := Button.new()
	to_menu.text = "Ana Menü"
	to_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	to_menu.pressed.connect(show_menu)
	footer_row.add_child(to_menu)

	game_built = true

func make_menu_button(normal_tex: Texture2D, hover_tex: Texture2D, callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = normal_tex
	button.texture_hover = hover_tex
	button.texture_pressed = hover_tex
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(520, 90)
	button.pressed.connect(callback)
	return button

func show_menu() -> void:
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

func _on_restart_pressed() -> void:
	if resolving:
		return
	setup_game()

func setup_game() -> void:
	resolving = false
	game_over = false
	round_no = 1
	player_queue.clear()
	ships.clear()
	for child in board.get_children():
		child.queue_free()
	board.tokens.clear()
	board.configure(GRID_SIZE, rocks, pickups, deliveries)

	ships.append(make_ship(1, "Sen", Vector2i(1,4), 1, true, Color(0.32,0.72,1.0)))
	ships.append(make_ship(2, "Kızıl Korsan", Vector2i(9,4), 3, false, Color(0.95,0.30,0.30)))
	ships.append(make_ship(3, "Bakır Martı", Vector2i(5,7), 0, false, Color(0.42,0.90,0.55)))
	if start_with_four_ships:
		ships.append(make_ship(4, "Gece Rüzgârı", Vector2i(5,2), 2, false, Color(0.98,0.82,0.30)))

	for ship in ships:
		board.add_ship(ship.id, ship.color, ship.pos)
		board.update_ship(ship.id, ship.pos, ship.facing, ship.hp, false, false)

	new_wind()
	refresh_ui()
	log_clear()
	log_line("[b]Oyun başladı.[/b] Üç komut seç. Her komuttan sonra rüzgâr tüm zeplinleri iter.")
	log_line("Kargo almak için sarı hücreye, teslim etmek için ilgili turkuaz hücreye git.")

func make_ship(id: int, ship_name: String, pos: Vector2i, facing: int, human: bool, color: Color) -> Dictionary:
	return {
		"id":id, "name":ship_name, "pos":pos, "facing":facing,
		"hp":MAX_HP, "coins":0, "cargo":{}, "queue":[],
		"human":human, "color":color, "anchored":false
	}

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

func _on_execute_pressed() -> void:
	if resolving or game_over or player_queue.size() != 3:
		return
	resolving = true
	set_input_enabled(false)
	await execute_round()

func execute_round() -> void:
	for ship in ships:
		ship.queue.clear()
		ship.anchored = false
		if ship.human:
			ship.queue = player_queue.duplicate()
		else:
			ship.queue = plan_ai(ship)

	log_line("\n[b]--- TUR %d ---[/b]" % round_no)
	for ship in ships:
		log_line("%s: %s | %s | %s" % [ship.name, ship.queue[0], ship.queue[1], ship.queue[2]])

	for slot in range(3):
		log_line("\n[i]Komut %d çözülüyor...[/i]" % (slot + 1))
		await resolve_slot(slot)
		await get_tree().create_timer(resolution_pause).timeout
		log_line("Rüzgâr itişi: %s" % DIR_NAMES[wind_dir])
		await resolve_wind()
		await get_tree().create_timer(resolution_pause).timeout
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

func resolve_slot(slot: int) -> void:
	for ship in ships:
		if ship.hp <= 0:
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

	var hooks: Array = []
	for ship in ships:
		if ship.hp > 0 and ship.queue[slot] == CMD_HOOK:
			var target: Variant = find_hook_target(ship)
			if target != null:
				hooks.append([ship, target])
			else:
				log_line("%s kancayı boşa attı." % ship.name)
	for pair in hooks:
		var attacker: Dictionary = pair[0]
		var target: Dictionary = pair[1]
		var pull_dir := sign_vec(attacker.pos - target.pos)
		log_line("%s, %s zeplinine kanca taktı!" % [attacker.name, target.name])
		if abs(attacker.pos.x - target.pos.x) + abs(attacker.pos.y - target.pos.y) > 1:
			attempt_single_push(target, pull_dir, attacker.id)
		else:
			log_line("Kanca gerildi ama zeplinler zaten bitişik; konum değişmedi.")
	await animate_all()

	for substep in range(2):
		var intents := {}
		for ship in ships:
			if ship.hp <= 0:
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
		resolve_simultaneous_step(intents, "motor")
		await animate_all()
		await get_tree().create_timer(0.07).timeout

func resolve_wind() -> void:
	var intents := {}
	for ship in ships:
		if ship.hp > 0 and not ship.anchored:
			intents[ship.id] = DIRS[wind_dir]
	resolve_simultaneous_step(intents, "rüzgâr")
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
	for id in ordered_ids:
		if blocked_ids.has(id) or moved_this_step.has(id):
			continue
		var ship: Variant = get_ship(id)
		if ship == null or ship.hp <= 0:
			continue
		attempt_single_push_tracked(ship, intents[id], moved_this_step)

func attempt_single_push_tracked(ship: Dictionary, dir: Vector2i, moved: Dictionary) -> bool:
	if dir == Vector2i.ZERO or moved.has(ship.id):
		return false
	var target: Vector2i = ship.pos + dir
	if not is_inside(target):
		damage_ship(ship, 1, "kanyon duvarına çarptı")
		return false
	if rocks.has(target):
		damage_ship(ship, 1, "kayalığa çarptı")
		return false
	var occupant: Variant = ship_at(target)
	if occupant != null:
		if not push_chain_tracked(occupant, dir, [ship.id], moved):
			damage_ship(occupant, 1, "sıkıştı")
			board.flash_ship(occupant.id)
			return false
	ship.pos = target
	moved[ship.id] = true
	return true

func push_chain_tracked(ship: Dictionary, dir: Vector2i, visited: Array, moved: Dictionary) -> bool:
	if visited.has(ship.id):
		return false
	visited.append(ship.id)
	var target: Vector2i = ship.pos + dir
	if not is_inside(target) or rocks.has(target):
		return false
	var occupant: Variant = ship_at(target)
	if occupant != null:
		if not push_chain_tracked(occupant, dir, visited, moved):
			return false
	ship.pos = target
	moved[ship.id] = true
	return true

func attempt_single_push(ship: Dictionary, dir: Vector2i, source_id: int = -1) -> bool:
	if dir == Vector2i.ZERO:
		return false
	var target: Vector2i = ship.pos + dir
	if not is_inside(target):
		damage_ship(ship, 1, "kanyon duvarına çarptı")
		return false
	if rocks.has(target):
		damage_ship(ship, 1, "kayalığa çarptı")
		return false
	var occupant: Variant = ship_at(target)
	if occupant != null and occupant.id != source_id:
		if not push_chain(occupant, dir, [ship.id]):
			damage_ship(occupant, 1, "sıkıştı")
			board.flash_ship(occupant.id)
			return false
	ship.pos = target
	return true

func push_chain(ship: Dictionary, dir: Vector2i, visited: Array) -> bool:
	if visited.has(ship.id):
		return false
	visited.append(ship.id)
	var target: Vector2i = ship.pos + dir
	if not is_inside(target) or rocks.has(target):
		return false
	var occupant: Variant = ship_at(target)
	if occupant != null:
		if not push_chain(occupant, dir, visited):
			return false
	ship.pos = target
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
	return Vector2i(sign(v.x), sign(v.y))

func check_all_cargo() -> void:
	for ship in ships:
		if ship.hp <= 0:
			continue
		if ship.cargo.is_empty() and pickups.has(ship.pos):
			ship.cargo = pickups[ship.pos].duplicate(true)
			log_line("[color=yellow]%s, %s aldı.[/color]" % [ship.name, ship.cargo.name])
		elif not ship.cargo.is_empty() and ship.pos == ship.cargo.dest:
			var value: int = ship.cargo.value
			log_line("[color=aqua]%s kargoyu teslim etti: +%d altın![/color]" % [ship.name, value])
			ship.coins += value
			ship.cargo = {}

func damage_ship(ship: Dictionary, amount: int, reason: String) -> void:
	ship.hp = max(0, ship.hp - amount)
	board.flash_ship(ship.id)
	log_line("[color=salmon]%s %s: -%d gövde.[/color]" % [ship.name, reason, amount])
	if ship.hp <= 0:
		log_line("[b][color=red]%s düştü! Başlangıç noktasında onarıldı.[/color][/b]" % ship.name)
		respawn_ship(ship)

func respawn_ship(ship: Dictionary) -> void:
	var starts := [Vector2i(1,4), Vector2i(9,4), Vector2i(5,7), Vector2i(5,2)]
	ship.hp = MAX_HP
	ship.cargo = {}
	var candidate: Vector2i = starts[(ship.id-1) % starts.size()]
	if ship_at(candidate) == null and not rocks.has(candidate):
		ship.pos = candidate
	else:
		for y in range(GRID_SIZE.y):
			for x in range(GRID_SIZE.x):
				var c := Vector2i(x,y)
				if not rocks.has(c) and ship_at(c) == null:
					ship.pos = c
					return

func plan_ai(_ship: Dictionary) -> Array[String]:
	var q: Array[String] = []
	for i in range(3):
		var roll := rng.randf()
		if roll < 0.34:
			q.append(CMD_FORWARD_1)
		elif roll < 0.50:
			q.append(CMD_FORWARD_2)
		elif roll < 0.66:
			q.append(CMD_LEFT)
		elif roll < 0.82:
			q.append(CMD_RIGHT)
		elif roll < 0.92:
			q.append(CMD_HOOK)
		else:
			q.append(CMD_ANCHOR)
	return q

func check_victory() -> bool:
	for ship in ships:
		if ship.coins >= TARGET_COINS:
			game_over = true
			resolving = false
			set_input_enabled(false)
			log_line("\n[b][color=yellow]%s %d altına ulaştı ve Fırtına Vadisi'ni kazandı![/color][/b]" % [ship.name, ship.coins])
			refresh_ui()
			return true
	return false

func new_wind() -> void:
	var old := wind_dir
	wind_dir = rng.randi_range(0,3)
	if round_no > 1 and wind_dir == old and rng.randf() < 0.55:
		wind_dir = (wind_dir + rng.randi_range(1,3)) % 4

func animate_all() -> void:
	refresh_tokens(true)
	await get_tree().create_timer(0.24).timeout

func refresh_tokens(animate := false) -> void:
	for ship in ships:
		board.update_ship(ship.id, ship.pos, ship.facing, ship.hp, not ship.cargo.is_empty(), animate)

func refresh_ui() -> void:
	round_label.text = "Tur %d" % round_no
	wind_label.text = "Rüzgâr: %s" % DIR_NAMES[wind_dir]
	var slots := []
	for i in range(3):
		slots.append("[ %s ]" % (player_queue[i] if i < player_queue.size() else "?"))
	queue_label.text = "   ".join(slots)
	execute_button.disabled = resolving or game_over or player_queue.size() != 3
	clear_button.disabled = resolving or game_over or player_queue.is_empty()

	for child in command_box.get_children():
		child.queue_free()
	for i in range(3):
		var holder := PanelContainer.new()
		holder.custom_minimum_size = Vector2(96, 132)
		command_box.add_child(holder)
		if i < player_queue.size():
			var tex := TextureRect.new()
			tex.texture = COMMAND_TEXTURES[player_queue[i]]
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = Vector2(90, 126)
			holder.add_child(tex)

	for child in score_box.get_children():
		child.queue_free()
	for ship in ships:
		var l := Label.new()
		var cargo_text: String = "—" if ship.cargo.is_empty() else str(ship.cargo.name)
		l.text = "%s  |  ❤ %d  |  Altın %d  |  Kargo: %s" % [ship.name, ship.hp, ship.coins, cargo_text]
		l.modulate = ship.color.lightened(0.12)
		score_box.add_child(l)

func set_input_enabled(enabled: bool) -> void:
	for child in get_tree().get_nodes_in_group("command_buttons"):
		if child is BaseButton:
			child.disabled = not enabled
	clear_button.disabled = not enabled
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

func log_clear() -> void:
	info_label.clear()

func log_line(text: String) -> void:
	info_label.append_text(text + "\n")
