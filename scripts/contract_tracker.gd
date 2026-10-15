extends Node
## Player cargo presentation only; never claims or awards a contract.
const Visuals = preload("res://scripts/presentation.gd")
var game: Control
var panel: Panel
var cargo_label: Label
var destination_label: Label
var target_cell: Variant = null
var normal_styles: Dictionary = {}
var target_style: StyleBoxFlat

func setup(owner_game: Control) -> void:
	game = owner_game
	var side: Control = game.get_node("GameLayer/RightPanel")
	panel = Panel.new()
	panel.name = "CargoTracker"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	side.add_child(panel)
	Visuals.rect(panel, 16, 898, 520, 50)
	panel.add_theme_stylebox_override("panel", Visuals.panel(Color("152c32"), Color("38565b"), 6))
	cargo_label = Visuals.label(panel, "", 12, 3, 496, 22, 16, Visuals.TEXT)
	destination_label = Visuals.label(panel, "", 12, 25, 496, 21, 14, Visuals.GOLD)
	for label in [cargo_label, destination_label]:
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for dock in game.board.delivery_nodes:
		normal_styles[dock] = dock.get_theme_stylebox("panel")
	target_style = Visuals.panel(Color("304c42"), Visuals.GOLD, 6)
	target_style.set_border_width_all(3)
	target_style.shadow_color = Color(0.84, 0.70, 0.40, 0.32)
	target_style.shadow_size = 10

func refresh() -> void:
	clear_target()
	if game.ships.is_empty() or not game.game_layer.visible or game.game_over:
		panel.hide()
		return
	panel.show()
	var cargo: Dictionary = {}
	for ship in game.ships:
		if ship.human:
			cargo = ship.cargo
			break
	if cargo.is_empty():
		cargo_label.text = "AKTİF KONTRAT YOK"
		destination_label.text = "Altın kontratların üzerine gelerek hedeflerini incele."
		panel.tooltip_text = "Bir kontrat hücresine ulaşarak yükü al. İşaretli iskeleye teslim ederek altın kazan."
		return
	target_cell = cargo.dest
	cargo_label.text = "YÜK  /  %s" % str(cargo.name)
	destination_label.text = "HEDEF  /  %s    •    +%d ALTIN" % [str(cargo.dest_name), int(cargo.value)]
	panel.tooltip_text = "Yük: %s\nHedef: %s\nÖdül: %d altın" % [str(cargo.name), str(cargo.dest_name), int(cargo.value)]
	for dock in game.board.delivery_nodes:
		if dock.visible and dock.get_meta("grid_cell", Vector2i(-1, -1)) == target_cell:
			dock.add_theme_stylebox_override("panel", target_style)
			dock.get_node("Label").add_theme_color_override("font_color", Visuals.GOLD)
			dock.tooltip_text = "TESLİMAT HEDEFİN\n" + panel.tooltip_text
			dock.set_meta("tracked_cell", target_cell)
			dock.set_meta("tracking_tooltip", dock.tooltip_text)

func clear_target() -> void:
	target_cell = null
	for dock in normal_styles:
		if dock.has_meta("tracked_cell"):
			dock.remove_meta("tracked_cell")
			dock.remove_meta("tracking_tooltip")
		dock.add_theme_stylebox_override("panel", normal_styles[dock])
		dock.get_node("Label").add_theme_color_override("font_color", Color("9fdfd3"))
		dock.tooltip_text = str(dock.get_meta("base_tooltip", ""))
