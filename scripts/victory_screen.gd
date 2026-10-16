extends Control
## Modal results; rankings are copied so presentation never reorders pilots.
const Visuals = preload("res://scripts/presentation.gd")
var ranking: Array = []
var winner_id: int = -1
var winner_ids: Array = []
var blocked_focus: Dictionary = {}
var game: Control
var heading: Label
var summary: Label
var rows: Array[Label] = []
var replay: Button
var menu: Button

func setup(owner_game: Control) -> void:
	game = owner_game
	name = "VictoryScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 4090
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.045, 0.9)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := Panel.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position -= Vector2(450, 325)
	panel.size = Vector2(900, 650)
	panel.add_theme_stylebox_override("panel", Visuals.panel(Color("10252e"), Color("c29c5d"), 18))
	Visuals.label(panel, "FIRTINA VADİSİ   /   SEFER SONUCU", 44, 30, 812, 28, 16, Color("e8bc70"))
	heading = Visuals.label(panel, "", 44, 76, 812, 64, 44, Color("e8bc70"))
	summary = Visuals.label(panel, "", 44, 150, 812, 34, 21)
	Visuals.label(panel, "SIRA     PİLOT", 44, 220, 480, 28, 16, Color("91a8af"))
	Visuals.label(panel, "ALTIN          TESLİMAT", 600, 220, 260, 28, 16, Color("91a8af"))
	for i in range(4):
		var row := Panel.new()
		panel.add_child(row)
		Visuals.rect(row, 36, 260 + i * 58, 828, 52)
		row.add_theme_stylebox_override("panel", Visuals.panel(Color("18333d") if i == 0 else Color("122a34"), Color.TRANSPARENT, 8))
		rows.append(Visuals.label(row, "", 12, 8, 530, 36, 21))
		rows.append(Visuals.label(row, "", 564, 8, 110, 36, 21, Color("e8bc70")))
		rows.append(Visuals.label(row, "", 720, 8, 80, 36, 21))
	replay = Button.new()
	replay.name = "Replay"
	replay.text = "YENİDEN OYNA"
	panel.add_child(replay)
	Visuals.rect(replay, 44, 548, 394, 60)
	replay.pressed.connect(game._on_restart_pressed)
	menu = Button.new()
	menu.name = "Menu"
	menu.text = "ANA MENÜ"
	panel.add_child(menu)
	Visuals.rect(menu, 462, 548, 394, 60)
	menu.pressed.connect(game.show_menu)
	for button in [replay, menu]:
		var other: Button = menu if button == replay else replay
		button.focus_next = button.get_path_to(other)
		button.focus_previous = button.get_path_to(other)
	hide()

## `winners` tek kazanan ya da eşitlikte ortak kazananlardır (önce altın, sonra kalan gövde).
func show_result(winners: Array) -> void:
	if visible or winners.is_empty():
		return
	var winner: Dictionary = winners[0]
	winner_id = winner.id
	winner_ids = winners.map(func(ship: Dictionary) -> int: return int(ship.id))
	ranking = game.ships.duplicate(true)
	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.coins != b.coins:
			return a.coins > b.coins
		if a.hp != b.hp:
			return a.hp > b.hp
		return a.id < b.id)
	var human_won: bool = winners.any(func(ship: Dictionary) -> bool: return ship.human)
	if winners.size() > 1:
		heading.text = "ORTAK ZAFER" if human_won else "BERABERE BİTTİ"
		var names: Array = winners.map(func(ship: Dictionary) -> String: return str(ship.name))
		summary.text = "Kazananlar: %s  •  %d altın  •  %d tur" % [", ".join(names), winner.coins, game.round_no]
	else:
		heading.text = "ZAFER SENİN" if human_won else "SEFER TAMAMLANDI"
		summary.text = "Kazanan: %s  •  %d altın  •  %d tur" % [winner.name, winner.coins, game.round_no]
	for i in range(4):
		rows[i * 3].get_parent().visible = i < ranking.size()
		if i >= ranking.size():
			continue
		var ship: Dictionary = ranking[i]
		rows[i * 3].text = "%02d   %s%s" % [i + 1, ship.name, "   •   KAZANAN" if winner_ids.has(int(ship.id)) else ""]
		rows[i * 3].add_theme_color_override("font_color", ship.color.lightened(0.2))
		rows[i * 3 + 1].text = str(ship.coins)
		rows[i * 3 + 2].text = str(ship.deliveries)
	_block_focus(game.game_layer)
	show()
	replay.grab_focus()

func _block_focus(node: Node) -> void:
	if node is Control:
		blocked_focus[node] = node.focus_mode
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_block_focus(child)

func dismiss() -> void:
	hide()
	replay.release_focus()
	menu.release_focus()
	for node in blocked_focus:
		if is_instance_valid(node):
			node.focus_mode = blocked_focus[node]
	blocked_focus.clear()
	ranking.clear()
	winner_id = -1
	winner_ids.clear()
