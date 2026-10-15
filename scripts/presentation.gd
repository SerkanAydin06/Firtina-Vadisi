extends RefCounted
## Shared visual language. Gameplay and node paths stay in main_ui.gd.

const GOLD := Color("d5b47c")
const INK := Color("101e27")
const LINE := Color("30434b")
const TEXT := Color("e9e6dc")
const MUTED := Color("91a8af")

static func panel(bg: Color, stroke: Color = LINE, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = stroke
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

static func rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)

static func label(parent: Node, value: String, x: float, y: float, w: float, h: float, font_size: int, color: Color = TEXT) -> Label:
	var item := Label.new()
	item.text = value
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	rect(item, x, y, w, h)
	return item

static func apply(game: Control) -> void:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var bg: Color = Color("182d37") if state == "hover" else INK
		theme.set_stylebox(state, "Button", panel(bg, GOLD if state == "focus" else LINE, 8))
	theme.set_color("font_disabled_color", "Button", Color("5e747c"))
	game.theme = theme
	var layer: Control = game.get_node("GameLayer")
	layer.get_node("GameBG").color = Color("080f16")
	label(layer, "FIRTINA VADİSİ", 28, 20, 700, 49, 38, TEXT)
	label(layer, "HAVA KORSANLARI  /  TAKTİK SEFER HARİTASI", 31, 73, 900, 24, 15, GOLD)
	var status := label(layer, "4 PİLOT     /     12 ALTIN", 1020, 38, 294, 32, 17, MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.text = ("4" if game.start_with_four_ships else "3") + " PİLOT     /     12 ALTIN"
	var board_frame: Panel = layer.get_node("BoardFrame")
	rect(board_frame, 24, 112, 1296, 732)
	board_frame.add_theme_stylebox_override("panel", panel(INK, Color("5b6255"), 16))
	var board: Control = board_frame.get_node("Board")
	board.custom_minimum_size = Vector2.ZERO
	board.get_node("GridLayer").custom_minimum_size = Vector2.ZERO
	board.get_node("GridLayer").set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.top_margin = 44.0
	board.bottom_margin = 46.0
	board.side_margin = 46.0
	board.token_size_px = 96.0
	board.get_node("ArenaBackground").add_theme_stylebox_override("panel", panel(Color("0c1d26"), Color.TRANSPARENT))
	var chart := TextureRect.new()
	chart.texture = load("res://assets/ui/valley_chart.svg")
	chart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chart.stretch_mode = TextureRect.STRETCH_SCALE
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(chart)
	board.move_child(chart, 1)
	chart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label(board, "SEKTÖR 07   /   FIRTINA GEÇİDİ", 22, 8, 600, 25, 13, MUTED)
	label(board, "◆  KONTRAT       ◇  TESLİMAT       ▲  KAYALIK", 24, 680, 900, 26, 13, GOLD)
	for rock in board.rock_nodes:
		rock.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var art := TextureRect.new()
		art.texture = load("res://assets/ui/rock.svg")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rock.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for dock in board.delivery_nodes:
		dock.add_theme_stylebox_override("panel", panel(Color("14383d"), Color("589d99"), 6))
		dock.get_node("Label").add_theme_color_override("font_color", Color("9fdfd3"))
		dock.get_node("Label").add_theme_font_size_override("font_size", 12)
	for contract in board.contract_nodes:
		contract.add_theme_stylebox_override("panel", panel(Color("3a3023"), GOLD, 6))
		for key in ["Name", "Reward"]:
			contract.get_node(key).add_theme_font_size_override("font_size", 13)
		contract.get_node("Name").add_theme_color_override("font_color", Color("fff0d5"))
		contract.get_node("Reward").add_theme_color_override("font_color", GOLD)
		contract.get_node("Target").add_theme_font_size_override("font_size", 10)
	var pilots: Panel = layer.get_node("PilotsPanel")
	rect(pilots, 24, 864, 808, 192)
	pilots.add_theme_stylebox_override("panel", panel(INK))
	pilots.get_node("Title").text = "PİLOTLAR  /  SEFER DURUMU"
	pilots.get_node("Title").add_theme_font_size_override("font_size", 15)
	pilots.get_node("Header").add_theme_stylebox_override("panel", panel(Color("162a34"), Color.TRANSPARENT, 4))
	rect(pilots.get_node("Header"), 14, 36, 780, 26)
	for i in range(4):
		var row: Panel = pilots.get_node("Pilot%d" % (i + 1))
		rect(row, 14, 66 + i * 29, 780, 28)
		row.add_theme_stylebox_override("panel", panel(Color("132630") if i % 2 == 0 else INK, Color.TRANSPARENT, 4))
		for child in row.get_node("Columns").get_children():
			child.add_theme_font_size_override("font_size", 16)
	var log_panel: Panel = layer.get_node("LogPanel")
	rect(log_panel, 852, 864, 468, 192)
	log_panel.add_theme_stylebox_override("panel", panel(INK))
	log_panel.get_node("Title").text = "SEFER GÜNLÜĞÜ"
	log_panel.get_node("Title").add_theme_font_size_override("font_size", 15)
	rect(game.info_label, 16, 44, 436, 132)
	game.info_label.add_theme_font_size_override("normal_font_size", 16)
	game.info_label.add_theme_color_override("default_color", MUTED)
	_style_console(game)
	board.fit_board()

static func _style_console(game: Control) -> void:
	var side: Panel = game.get_node("GameLayer/RightPanel")
	rect(side, 1344, 24, 552, 1032)
	side.add_theme_stylebox_override("panel", panel(Color("0e1b24"), LINE, 16))
	var top: Panel = side.get_node("TopHUD")
	rect(top, 16, 16, 520, 64)
	top.add_theme_stylebox_override("panel", panel(Color("182b34"), Color.TRANSPARENT, 8))
	top.get_node("RoundLabel").add_theme_font_size_override("font_size", 25)
	rect(top.get_node("GoalLabel"), 260, 9, 244, 46)
	top.get_node("GoalLabel").text = "HEDEF  /  12 ALTIN"
	top.get_node("GoalLabel").add_theme_font_size_override("font_size", 17)
	var wind: Panel = side.get_node("WindPanel")
	rect(wind, 16, 94, 520, 116)
	wind.add_theme_stylebox_override("panel", panel(Color("112e38"), Color("31515a"), 10))
	wind.get_node("Title").text = "RÜZGÂR PUSULASI"
	wind.get_node("Title").add_theme_font_size_override("font_size", 14)
	wind.get_node("Title").add_theme_color_override("font_color", MUTED)
	rect(wind.get_node("WindLabel"), 18, 30, 484, 46)
	wind.get_node("WindLabel").add_theme_color_override("font_color", Color("8ed5d3"))
	wind.get_node("WindLabel").add_theme_font_size_override("font_size", 31)
	rect(wind.get_node("Hint"), 12, 80, 496, 25)
	wind.get_node("Hint").text = "Her komuttan sonra 1 hücre sürüklenirsin."
	wind.get_node("Hint").add_theme_font_size_override("font_size", 14)
	var program: Panel = side.get_node("ProgramPanel")
	rect(program, 16, 230, 520, 184)
	program.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	program.get_node("Title").text = "01   UÇUŞ PLANINI HAZIRLA"
	program.get_node("Title").horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	program.get_node("Title").add_theme_font_size_override("font_size", 16)
	program.get_node("Title").add_theme_color_override("font_color", GOLD)
	rect(game.command_box, 12, 44, 496, 128)
	game.command_box.add_theme_constant_override("separation", 12)
	for i in range(3):
		var slot: PanelContainer = game.command_box.get_child(i)
		slot.custom_minimum_size = Vector2(156, 128)
		slot.add_theme_stylebox_override("panel", panel(Color("14252e"), Color("3d5157"), 8))
		slot.get_node("Number").text = "0%d" % (i + 1)
		slot.get_node("Number").add_theme_color_override("font_color", Color("5d767e"))
		var selected := VBoxContainer.new()
		selected.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(selected)
		var selected_icon: TextureRect = slot.get_node("Texture")
		selected_icon.reparent(selected)
		selected_icon.custom_minimum_size = Vector2(0, 76)
		selected_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var caption := Label.new()
		caption.name = "Caption"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 14)
		caption.add_theme_color_override("font_color", GOLD)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.hide()
		selected.add_child(caption)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.get_node("Number").mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.tooltip_text = "Bu komutu kaldırmak için tıkla"
		slot.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if not game.resolving and not game.game_over and i < game.player_queue.size():
					game.player_queue.remove_at(i)
					game.refresh_ui()
		)
	var cards: Panel = side.get_node("CardsPanel")
	rect(cards, 16, 432, 520, 376)
	cards.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cards.get_node("Title").text = "02   KOMUTLARINI SEÇ"
	cards.get_node("Title").horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cards.get_node("Title").add_theme_font_size_override("font_size", 16)
	cards.get_node("Title").add_theme_color_override("font_color", GOLD)
	var keys := ["Forward1", "Forward2", "Left", "Right", "Hook", "Anchor"]
	var names := ["İLERİ 1", "İLERİ 2", "SOLA DÖN", "SAĞA DÖN", "KANCA", "ÇAPA"]
	var icons := ["forward1", "forward2", "left", "right", "hook", "anchor"]
	var details := ["1 hücre ilerle", "2 hücre ilerle", "90° sola dön", "90° sağa dön", "Rakibini çek", "Rüzgâra diren"]
	for i in range(6):
		var button: TextureButton = cards.get_node(keys[i])
		button.hide()
		button.remove_from_group("command_buttons")
		cards.get_node(keys[i] + "Desc").hide()
		var tile := Button.new()
		tile.name = keys[i] + "Tile"
		tile.tooltip_text = details[i]
		tile.add_to_group("command_buttons")
		cards.add_child(tile)
		rect(tile, 8 + (i % 3) * 172, 48 + floori(float(i) / 3.0) * 160, 160, 148)
		tile.add_theme_stylebox_override("normal", panel(Color("192c36"), Color("38505a"), 10))
		tile.add_theme_stylebox_override("hover", panel(Color("29454c"), GOLD, 10))
		tile.add_theme_stylebox_override("pressed", panel(Color("344346"), GOLD, 10))
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/%s.svg" % icons[i])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
		rect(icon, 52, 12, 56, 56)
		var title := label(tile, names[i], 0, 77, 160, 25, 17)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var hint := label(tile, details[i], 0, 107, 160, 22, 13, MUTED)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.pressed.connect(game._on_command_pressed.bind(game.COMMANDS[i]))
		# Parent modulation dims both icon and text when the round locks input.
		tile.draw.connect(func() -> void: tile.modulate = Color(0.5, 0.6, 0.65) if tile.disabled else Color.WHITE)
	rect(game.clear_button, 16, 824, 150, 62)
	game.clear_button.text = "TEMİZLE"
	game.clear_button.add_theme_stylebox_override("normal", panel(Color("192932"), LINE, 8))
	game.clear_button.add_theme_font_size_override("font_size", 17)
	rect(game.execute_button, 178, 824, 358, 62)
	game.execute_button.text = "UÇUŞ PLANINI BAŞLAT  →"
	game.execute_button.add_theme_font_size_override("font_size", 18)
	game.execute_button.add_theme_stylebox_override("normal", panel(Color("c4a16a"), GOLD, 8))
	game.execute_button.add_theme_stylebox_override("hover", panel(Color("e1bd85"), GOLD, 8))
	game.execute_button.add_theme_color_override("font_color", Color("14222a"))
	label(side, "Üç komut seç. Rüzgârı hesaba kat.", 16, 898, 520, 28, 14, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rect(side.get_node("RestartButton"), 16, 958, 252, 48)
	rect(side.get_node("MenuButton"), 284, 958, 252, 48)

static func command_texture(command: String) -> Texture2D:
	var icons := {"İleri 1": "forward1", "İleri 2": "forward2", "Sola Dön": "left", "Sağa Dön": "right", "Kanca": "hook", "Çapa": "anchor"}
	return load("res://assets/ui/%s.svg" % icons.get(command, "anchor")) as Texture2D
