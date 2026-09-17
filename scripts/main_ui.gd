extends "res://scripts/main.gd"

const TopDownBoardScript = preload("res://scripts/board_topdown.gd")

func build_game_ui() -> void:
	game_layer = Control.new()
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.visible = false
	add_child(game_layer)

	var game_bg: ColorRect = ColorRect.new()
	game_bg.color = Color(0.022, 0.024, 0.028, 1.0)
	game_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(game_bg)

	var outer: MarginContainer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 10)
	outer.add_theme_constant_override("margin_right", 10)
	outer.add_theme_constant_override("margin_top", 10)
	outer.add_theme_constant_override("margin_bottom", 10)
	game_layer.add_child(outer)

	var root_row: HBoxContainer = HBoxContainer.new()
	root_row.add_theme_constant_override("separation", 10)
	outer.add_child(root_row)

	var left_col: VBoxContainer = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(1310, 0)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 8)
	root_row.add_child(left_col)

	var board_frame: PanelContainer = PanelContainer.new()
	board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_theme_stylebox_override("panel", _panel(Color(0.070, 0.060, 0.050), Color(0.68, 0.47, 0.20), 3))
	left_col.add_child(board_frame)

	var board_margin: MarginContainer = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 8)
	board_margin.add_theme_constant_override("margin_right", 8)
	board_margin.add_theme_constant_override("margin_top", 8)
	board_margin.add_theme_constant_override("margin_bottom", 8)
	board_frame.add_child(board_margin)

	board = TopDownBoardScript.new()
	board.custom_minimum_size = Vector2(1260, 760)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.add_child(board)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.custom_minimum_size.y = 235
	bottom_row.add_theme_constant_override("separation", 8)
	left_col.add_child(bottom_row)

	var pilots_panel: PanelContainer = PanelContainer.new()
	pilots_panel.custom_minimum_size = Vector2(500, 0)
	pilots_panel.add_theme_stylebox_override("panel", _panel(Color(0.050, 0.052, 0.055), Color(0.62, 0.42, 0.18), 3))
	bottom_row.add_child(pilots_panel)
	var pilots_margin: MarginContainer = _margin(10, 10, 8, 8)
	pilots_panel.add_child(pilots_margin)
	var pilots_v: VBoxContainer = VBoxContainer.new()
	pilots_v.add_theme_constant_override("separation", 5)
	pilots_margin.add_child(pilots_v)
	pilots_v.add_child(_title("PİLOTLAR"))
	score_box = VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 4)
	pilots_v.add_child(score_box)

	var log_panel: PanelContainer = PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_stylebox_override("panel", _panel(Color(0.050, 0.052, 0.055), Color(0.62, 0.42, 0.18), 3))
	bottom_row.add_child(log_panel)
	var log_margin: MarginContainer = _margin(12, 12, 8, 8)
	log_panel.add_child(log_margin)
	var log_v: VBoxContainer = VBoxContainer.new()
	log_v.add_theme_constant_override("separation", 5)
	log_margin.add_child(log_v)
	log_v.add_child(_title("UÇUŞ GÜNLÜĞÜ"))
	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.scroll_active = true
	info_label.fit_content = false
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_size_override("normal_font_size", 16)
	info_label.add_theme_color_override("default_color", Color(0.92, 0.87, 0.77))
	log_v.add_child(info_label)

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(560, 0)
	right_panel.add_theme_stylebox_override("panel", _panel(Color(0.050, 0.046, 0.042), Color(0.70, 0.48, 0.20), 4))
	root_row.add_child(right_panel)
	var right_margin: MarginContainer = _margin(13, 13, 11, 11)
	right_panel.add_child(right_margin)
	var side: VBoxContainer = VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	right_margin.add_child(side)

	var top_hud: HBoxContainer = HBoxContainer.new()
	top_hud.add_theme_constant_override("separation", 8)
	side.add_child(top_hud)
	round_label = _hud("Tur 1")
	round_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hud.add_child(round_label)
	var goal: Label = _hud("Hedef 12 Altın")
	goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hud.add_child(goal)

	var wind_panel: PanelContainer = PanelContainer.new()
	wind_panel.custom_minimum_size.y = 145
	wind_panel.add_theme_stylebox_override("panel", _panel(Color(0.070, 0.070, 0.065), Color(0.55, 0.38, 0.17), 2))
	side.add_child(wind_panel)
	var wind_margin: MarginContainer = _margin(12, 12, 9, 9)
	wind_panel.add_child(wind_margin)
	var wind_v: VBoxContainer = VBoxContainer.new()
	wind_v.add_theme_constant_override("separation", 4)
	wind_margin.add_child(wind_v)
	wind_v.add_child(_title("RÜZGÂR"))
	wind_label = Label.new()
	wind_label.text = "DOĞU →"
	wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wind_label.add_theme_font_size_override("font_size", 30)
	wind_label.add_theme_color_override("font_color", Color(0.52, 0.84, 1.0))
	wind_v.add_child(wind_label)
	var wind_hint: Label = Label.new()
	wind_hint.text = "Her komuttan sonra zeplinler 1 hücre sürüklenir."
	wind_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wind_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wind_hint.add_theme_font_size_override("font_size", 14)
	wind_v.add_child(wind_hint)

	var program_panel: PanelContainer = PanelContainer.new()
	program_panel.add_theme_stylebox_override("panel", _panel(Color(0.056, 0.056, 0.056), Color(0.55, 0.38, 0.17), 2))
	side.add_child(program_panel)
	var program_margin: MarginContainer = _margin(10, 10, 8, 8)
	program_panel.add_child(program_margin)
	var program_v: VBoxContainer = VBoxContainer.new()
	program_v.add_theme_constant_override("separation", 6)
	program_margin.add_child(program_v)
	program_v.add_child(_title("3 KOMUT PROGRAMLA"))
	queue_label = Label.new()
	queue_label.visible = false
	program_v.add_child(queue_label)
	command_box = HBoxContainer.new()
	command_box.alignment = BoxContainer.ALIGNMENT_CENTER
	command_box.add_theme_constant_override("separation", 10)
	program_v.add_child(command_box)

	var cards_panel: PanelContainer = PanelContainer.new()
	cards_panel.add_theme_stylebox_override("panel", _panel(Color(0.056, 0.056, 0.056), Color(0.55, 0.38, 0.17), 2))
	side.add_child(cards_panel)
	var cards_margin: MarginContainer = _margin(10, 10, 8, 8)
	cards_panel.add_child(cards_margin)
	var cards_v: VBoxContainer = VBoxContainer.new()
	cards_v.add_theme_constant_override("separation", 6)
	cards_margin.add_child(cards_v)
	cards_v.add_child(_title("KOMUT KARTLARI"))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	cards_v.add_child(grid)
	for command in COMMANDS:
		var btn: TextureButton = TextureButton.new()
		btn.texture_normal = COMMAND_TEXTURES[command]
		btn.texture_hover = COMMAND_TEXTURES[command]
		btn.texture_pressed = COMMAND_TEXTURES[command]
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(158, 158)
		btn.tooltip_text = command
		btn.pressed.connect(_on_command_pressed.bind(command))
		btn.add_to_group("command_buttons")
		grid.add_child(btn)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	side.add_child(action_row)
	clear_button = Button.new()
	clear_button.text = "TEMİZLE"
	clear_button.custom_minimum_size.y = 55
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.add_theme_font_size_override("font_size", 20)
	clear_button.add_theme_stylebox_override("normal", _button(Color(0.32, 0.075, 0.065), Color(0.68, 0.22, 0.16)))
	clear_button.add_theme_stylebox_override("hover", _button(Color(0.44, 0.10, 0.08), Color(0.84, 0.36, 0.20)))
	clear_button.pressed.connect(_on_clear_pressed)
	action_row.add_child(clear_button)
	execute_button = Button.new()
	execute_button.text = "PROGRAMI AÇ ▶"
	execute_button.custom_minimum_size.y = 55
	execute_button.disabled = true
	execute_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	execute_button.add_theme_font_size_override("font_size", 20)
	execute_button.add_theme_stylebox_override("normal", _button(Color(0.07, 0.26, 0.09), Color(0.28, 0.68, 0.26)))
	execute_button.add_theme_stylebox_override("hover", _button(Color(0.10, 0.37, 0.12), Color(0.40, 0.85, 0.35)))
	execute_button.pressed.connect(_on_execute_pressed)
	action_row.add_child(execute_button)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	side.add_child(footer)
	var restart: Button = Button.new()
	restart.text = "Yeni Oyun"
	restart.custom_minimum_size.y = 40
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.pressed.connect(_on_restart_pressed)
	footer.add_child(restart)
	var to_menu: Button = Button.new()
	to_menu.text = "Ana Menü"
	to_menu.custom_minimum_size.y = 40
	to_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	to_menu.pressed.connect(show_menu)
	footer.add_child(to_menu)

	game_built = true

func refresh_ui() -> void:
	round_label.text = "Tur %d" % round_no
	wind_label.text = "%s" % DIR_NAMES[wind_dir]
	queue_label.text = ""
	execute_button.disabled = resolving or game_over or player_queue.size() != 3
	clear_button.disabled = resolving or game_over or player_queue.is_empty()

	for child in command_box.get_children():
		child.queue_free()
	for i in range(3):
		var holder: PanelContainer = PanelContainer.new()
		holder.custom_minimum_size = Vector2(155, 155)
		holder.add_theme_stylebox_override("panel", _panel(Color(0.052, 0.058, 0.064), Color(0.36, 0.30, 0.22), 2))
		command_box.add_child(holder)
		if i < player_queue.size():
			var tex: TextureRect = TextureRect.new()
			tex.texture = COMMAND_TEXTURES[player_queue[i]]
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = Vector2(149, 149)
			holder.add_child(tex)
		else:
			var empty_label: Label = Label.new()
			empty_label.text = str(i + 1)
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.add_theme_font_size_override("font_size", 34)
			empty_label.add_theme_color_override("font_color", Color(0.44, 0.44, 0.42))
			holder.add_child(empty_label)

	for child in score_box.get_children():
		child.queue_free()
	for ship in ships:
		var row: PanelContainer = PanelContainer.new()
		row.custom_minimum_size.y = 36
		row.add_theme_stylebox_override("panel", _panel(Color(0.055, 0.060, 0.065), ship.color.darkened(0.30), 1))
		score_box.add_child(row)
		var line: HBoxContainer = HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)
		var name_label: Label = Label.new()
		name_label.text = ship.name
		name_label.custom_minimum_size.x = 145
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_color_override("font_color", ship.color.lightened(0.18))
		line.add_child(name_label)
		var hp_label: Label = Label.new()
		hp_label.text = "❤ %d" % ship.hp
		line.add_child(hp_label)
		var coin_label: Label = Label.new()
		coin_label.text = "Altın %d" % ship.coins
		coin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(coin_label)
		var cargo_text: String = "Boş" if ship.cargo.is_empty() else str(ship.cargo.name)
		var cargo_label: Label = Label.new()
		cargo_label.text = cargo_text
		cargo_label.custom_minimum_size.x = 110
		cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cargo_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(cargo_label)

func _panel(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	return style

func _button(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel(fill, border, 2)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _title(value: String) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.61))
	return label

func _hud(value: String) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 48
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.80))
	return label

func _margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin
