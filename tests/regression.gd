extends SceneTree

var game
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func fixture(cells: Array) -> void:
	game.board.cancel_animations()
	game.ships.clear()
	game.rocks.clear()
	game.pickups = {}
	game.round_no = 1
	for i in range(cells.size()):
		game.ships.append(game.make_ship(i + 1, "Test", cells[i], 1, i == 0, Color.WHITE))

func run() -> void:
	Engine.time_scale = 20.0
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_start_pressed()
	verify(game.ships.size() == 4 and game.pickups.size() == 4, "Initial ships and contracts")

	var cards = game.get_node("GameLayer/RightPanel/CardsPanel")
	cards.get_node("Forward1Tile").pressed.emit()
	cards.get_node("LeftTile").pressed.emit()
	verify(game.player_queue.size() == 2, "New command tiles connect to game input")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game.command_box.get_child(0).gui_input.emit(click)
	verify(game.player_queue.size() == 1 and game.player_queue[0] == game.CMD_LEFT, "Selected slot removes its own command")
	verify(game.board.get_node("GridLayer").position == Vector2.ZERO, "Grid shares the tokens' coordinate origin")
	verify(not game.route_overlay.steps.is_empty(), "Preview updates after selecting/removing commands")
	game._on_clear_pressed()
	verify(game.route_overlay.steps.is_empty(), "Clear removes preview")
	_test_route_prediction()
	_test_contract_tracking()
	await _test_effects()
	_test_hover()
	_test_board_focus()
	await _test_turn_presentation()
	await _test_victory_screen()
	_test_audio()

	game.ships[0].coins = 15
	verify(game.check_victory(), "Victory threshold")
	verify(game.turn_phase == "finished" and game.active_slot == -1, "Victory clears active turn phase")
	game._on_restart_pressed()
	for button in get_nodes_in_group("command_buttons"):
		verify(not button.disabled, "Cards unlocked after victory restart")
	verify(not game.game_over and game.ships[0].coins == 0, "Restart resets result")

	fixture([Vector2i(3, 3)])
	game.wind_dir = 1
	game.ships[0].anchored = true
	await game.resolve_wind()
	verify(game.ships[0].pos == Vector2i(3, 3), "Anchor stops first wind")
	await game.resolve_wind()
	verify(game.ships[0].pos == Vector2i(4, 3), "Anchor expires before next wind")

	fixture([Vector2i(2, 3), Vector2i(3, 3)])
	game.wind_dir = 1
	game.ships[1].anchored = true
	await game.resolve_wind()
	verify(game.ships[1].pos == Vector2i(3, 3) and game.ships[0].pos == Vector2i(2, 3), "Anchor resists a wind-driven chain")

	fixture([Vector2i(3, 3)])
	game._spawn_contract_at(Vector2i(4, 3))
	game.ships[0].queue = [game.CMD_FORWARD_2]
	await game.resolve_slot(0)
	verify(not game.ships[0].cargo.is_empty(), "Forward 2 collects cargo on intermediate cell")
	verify(game.ships[0].pos == Vector2i(5, 3), "Forward 2 completes movement")

	fixture([Vector2i(8, 6)])
	game._spawn_contract_at(Vector2i(4, 3))
	game.ships[0].cargo = game.pickups[Vector2i(4, 3)].duplicate(true)
	game.pickups.clear()
	game.ships[0].queue = [game.CMD_FORWARD_1]
	await game.resolve_slot(0)
	verify(game.ships[0].coins == 5, "Delivery occurs before wind")
	verify(game.ships[0].deliveries == 1, "Successful delivery counted exactly once")
	verify(game.pickups.has(Vector2i(4, 3)), "Delivered contract respawns")

	fixture([Vector2i(0, 0)])
	game.ships[0].hp = 1
	game.damage_ship(game.ships[0], 1, "test")
	verify(game.ships[0].pos == Vector2i(0, 0), "Respawn does not treat itself as occupied")

	fixture([Vector2i(2, 2), Vector2i(4, 2)])
	game.resolve_simultaneous_step({1: Vector2i.RIGHT, 2: Vector2i.LEFT}, "motor")
	verify(game.ships[0].pos == Vector2i(2, 2) and game.ships[1].pos == Vector2i(4, 2), "Shared destination blocks both")
	fixture([Vector2i(2, 2), Vector2i(3, 2)])
	game.resolve_simultaneous_step({1: Vector2i.RIGHT, 2: Vector2i.LEFT}, "motor")
	verify(game.ships[0].pos == Vector2i(2, 2) and game.ships[1].pos == Vector2i(3, 2), "Head-on movement blocked")
	fixture([Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)])
	game.resolve_simultaneous_step({1: Vector2i.RIGHT}, "motor")
	verify(game.ships[0].pos == Vector2i(3, 2) and game.ships[2].pos == Vector2i(5, 2), "Domino push moves whole chain")
	fixture([Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)])
	game.rocks.assign([Vector2i(5, 2)])
	game.resolve_simultaneous_step({1: Vector2i.RIGHT}, "motor")
	verify(game.ships[0].pos == Vector2i(2, 2) and game.ships[1].pos == Vector2i(3, 2), "Failed chain rolls back all movement")
	verify(game.ships[2].hp == 2, "Blocked end of chain takes damage")
	fixture([Vector2i(2, 2), Vector2i(3, 2)])
	game.resolve_simultaneous_step({1: Vector2i.RIGHT, 2: Vector2i.DOWN}, "motor")
	verify(game.ships[0].pos == Vector2i(3, 2) and game.ships[1].pos == Vector2i(3, 3), "Moving occupant follows its own intent")
	fixture([Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 3), Vector2i(2, 3)])
	game.resolve_simultaneous_step({1: Vector2i.RIGHT, 2: Vector2i.DOWN, 3: Vector2i.LEFT, 4: Vector2i.UP}, "motor")
	verify(game.ships[0].pos == Vector2i(3, 2) and game.ships[3].pos == Vector2i(2, 2), "Four-way cycle resolves simultaneously")

	# Reproducible stress cases: no overlap, invalid cells, or multiple moves per step.
	var random := RandomNumberGenerator.new()
	random.seed = 42
	for trial in range(250):
		var cells: Array = []
		while cells.size() < 4:
			var cell := Vector2i(random.randi_range(1, 7), random.randi_range(1, 7))
			if not cells.has(cell):
				cells.append(cell)
		fixture(cells)
		var intents := {}
		for id in range(1, 5):
			if random.randf() < 0.8:
				intents[id] = game.DIRS[random.randi_range(0, 3)]
		game.resolve_simultaneous_step(intents, "motor")
		var occupied := {}
		for ship in game.ships:
			verify(not occupied.has(ship.pos) and game.is_inside(ship.pos), "Stress: unique valid cell")
			occupied[ship.pos] = true
			var delta: Vector2i = ship.pos - cells[ship.id - 1]
			verify(absi(delta.x) + absi(delta.y) <= 1, "Stress: at most one movement")

	game.setup_game()
	for wind in range(4):
		game.wind_dir = wind
		for ship in game.ships:
			var commands: Array[String] = game.plan_ai(ship)
			verify(commands.size() == 3, "AI produces three commands")
			var pos: Vector2i = ship.pos
			var facing: int = ship.facing
			for command in commands:
				var next: Dictionary = game._ai_transition(pos, facing, command, [])
				verify(not next.is_empty(), "AI avoids static obstacles and wind damage")
				if not next.is_empty():
					pos = next.pos
					facing = next.facing

	game.setup_game()
	game.player_queue.assign([game.CMD_FORWARD_1, game.CMD_LEFT, game.CMD_FORWARD_2])
	game._on_execute_pressed()
	verify(game.route_overlay.steps.is_empty(), "Preview hides while resolving")
	await create_timer(0.1).timeout
	game.show_menu()
	verify(game.turn_phase == "planning" and game.active_slot == -1, "Menu clears turn highlight")
	game._on_start_pressed()
	var start_positions: Array = game.ships.map(func(ship: Dictionary): return ship.pos)
	await create_timer(2.0).timeout
	verify(game.round_no == 1 and not game.resolving, "Old round cancelled after menu/start")
	verify(game.turn_phase == "planning" and game.active_slot == -1, "Old round cannot restore stale highlight")
	verify(game.ships.map(func(ship: Dictionary): return ship.pos) == start_positions, "Old round cannot change new positions")
	for ship in game.ships:
		verify(game.board.tokens[ship.id].get_meta("grid_cell") == ship.pos, "Visual position matches new state")

	game.player_queue.assign([game.CMD_ANCHOR, game.CMD_ANCHOR, game.CMD_ANCHOR])
	await game._on_execute_pressed()
	verify(game.round_no == 2 and not game.resolving, "Complete round advances and unlocks input")
	var original_motion: bool = game.reduced_motion
	var original_pause: float = game.resolution_pause
	var options = game.get_node("MenuLayer/SettingsPopup/Options")
	var original_fullscreen: bool = options.get_node("Fullscreen").button_pressed
	options.get_node("Fullscreen").button_pressed = not original_fullscreen
	options.get_node("Pause").value = 0.65
	options.get_node("ReduceMotion").button_pressed = not original_motion
	game._load_settings()
	verify(game.reduced_motion == not original_motion and game.board.reduced_motion == not original_motion, "Reduced motion setting persists and applies")
	verify(is_equal_approx(game.resolution_pause, 0.65), "Pace setting persists")
	verify(options.get_node("Fullscreen").button_pressed == not original_fullscreen, "Fullscreen setting persists")
	options.get_node("Fullscreen").button_pressed = original_fullscreen
	options.get_node("Pause").value = original_pause
	options.get_node("ReduceMotion").button_pressed = original_motion
	game.board.cancel_animations()
	game.game_audio.stop_all()
	# Let the audio thread release stopped playback before tearing down resources.
	await create_timer(0.15, true, false, true).timeout
	game.queue_free()
	await process_frame
	print("REGRESSION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_route_prediction() -> void:
	var preview = preload("res://scripts/route_preview.gd")
	var ship: Dictionary = game.make_ship(1, "Test", Vector2i(4, 4), 1, true, Color.WHITE)
	var ships: Array = [ship]
	var original: Array = ships.duplicate(true)
	var result: Dictionary = preview.build(ship, [game.CMD_FORWARD_2], 2, [], ships, game.GRID_SIZE)
	verify(result.steps.size() == 3, "Forward 2 previews two motor steps and one wind")
	verify(result.steps[2].to == Vector2i(6, 5) and result.steps[2].kind == "wind", "Wind is projected after motor")
	verify(ships == original, "Prediction leaves the live ship state untouched")
	result = preview.build(ship, [game.CMD_LEFT, game.CMD_FORWARD_1], 1, [], ships, game.GRID_SIZE)
	verify(result.steps[-1].to == Vector2i(6, 3), "Turn changes predicted motor heading")
	result = preview.build(ship, [game.CMD_ANCHOR, game.CMD_RIGHT], 1, [], ships, game.GRID_SIZE)
	verify(result.steps.size() == 3 and result.steps[-1].to == Vector2i(5, 4), "Anchor blocks only its own wind")
	result = preview.build(ship, [game.CMD_FORWARD_2], 2, [Vector2i(5, 4)], ships, game.GRID_SIZE)
	verify(result.steps[0].risk and result.steps[1].from == Vector2i(4, 4), "Rock collision keeps predicted position")
	verify(result.steps[-1].to == Vector2i(4, 5), "Wind still applies after nonfatal collision")
	ship.hp = 1
	result = preview.build(ship, [game.CMD_FORWARD_2], 2, [Vector2i(5, 4)], ships, game.GRID_SIZE)
	verify(result.steps.size() == 1 and not result.reason.is_empty(), "Fatal obstacle ends prediction before respawn")
	ship.hp = 3
	ships.append(game.make_ship(2, "Other", Vector2i(5, 4), 0, false, Color.WHITE))
	result = preview.build(ship, [game.CMD_FORWARD_1, game.CMD_RIGHT], 2, [], ships, game.GRID_SIZE)
	verify(result.steps.size() == 1 and result.steps[0].risk, "Occupied cell marks risk and stops uncertain route")
	var unchanged: Dictionary = result.duplicate(true)
	ships[1].queue = [game.CMD_LEFT, game.CMD_FORWARD_2, game.CMD_HOOK]
	result = preview.build(ship, [game.CMD_FORWARD_1, game.CMD_RIGHT], 2, [], ships, game.GRID_SIZE)
	verify(result == unchanged, "Opponent hidden queues never influence preview")
	result = preview.build(ship, [game.CMD_HOOK], 2, [], ships, game.GRID_SIZE)
	verify(result.steps[0].kind == "hook" and not result.reason.is_empty(), "Hook target is marked as uncertain")
	ship.pos = Vector2i(10, 4)
	result = preview.build(ship, [game.CMD_FORWARD_1], 2, [], [ship], game.GRID_SIZE)
	verify(result.steps[0].risk and result.steps[-1].to == Vector2i(10, 5), "Boundary blocks motor, then wind proceeds")

func _test_contract_tracking() -> void:
	var tracker = game.contract_tracker
	var source := Vector2i(4, 3)
	verify(tracker.target_cell == null, "No cargo means no highlighted destination")
	for node in game.board.contract_nodes:
		if node.visible:
			var info: Dictionary = game.pickups[node.get_meta("grid_cell")]
			verify(node.tooltip_text.contains(info.name) and node.tooltip_text.contains(info.dest_name), "Available contract tooltip matches its current data")
			verify(node.mouse_filter == Control.MOUSE_FILTER_STOP, "Contract accepts hover information")
	game.ships[0].pos = source
	game.check_all_cargo()
	var cargo: Dictionary = game.ships[0].cargo.duplicate(true)
	verify(tracker.target_cell == cargo.dest, "Claim immediately highlights carried cargo destination")
	verify(tracker.cargo_label.text.contains(cargo.name) and tracker.destination_label.text.contains(cargo.dest_name) and tracker.destination_label.text.contains("5"), "Cargo panel shows load, target and reward")
	var highlighted: int = 0
	for dock in game.board.delivery_nodes:
		if dock.get_theme_stylebox("panel") == tracker.target_style:
			highlighted += 1
			verify(dock.get_meta("grid_cell") == cargo.dest and dock.tooltip_text.contains("HEDEFİN"), "Only the actual destination gets player-target information")
	verify(highlighted == 1, "Exactly one dock highlighted")
	game.board.fit_board()
	for dock in game.board.delivery_nodes:
		if dock.get_meta("grid_cell") == cargo.dest:
			verify(dock.tooltip_text.contains("HEDEFİN"), "Target tooltip survives deferred board relayout")
	var before: Array = game.ships.duplicate(true)
	tracker.refresh()
	verify(before == game.ships, "Tracker never mutates gameplay")
	game.ships[0].pos = cargo.dest
	game.check_all_cargo()
	verify(tracker.target_cell == null and game.ships[0].coins == 5, "Delivery clears target immediately")
	for dock in game.board.delivery_nodes:
		verify(dock.get_theme_stylebox("panel") != tracker.target_style and not dock.tooltip_text.contains("HEDEFİN"), "Delivery removes old highlight and tooltip")
	game.ships[0].pos = source
	game.check_all_cargo()
	game.ships[0].hp = 1
	game.damage_ship(game.ships[0], 1, "test")
	verify(tracker.target_cell == null and game.pickups.has(source), "Respawn clears target and restores lost contract")
	game.ships[1].pos = source
	game.check_all_cargo()
	verify(tracker.target_cell == null, "Opponent cargo does not highlight a player destination")
	game.ships[0].pos = Vector2i(6, 3)
	game.check_all_cargo()
	verify(tracker.target_cell != null, "New contract replaces previous target")
	game.show_menu()
	verify(tracker.target_cell == null and not tracker.panel.visible, "Menu clears tracking")
	game._on_start_pressed()
	verify(tracker.target_cell == null and tracker.panel.visible, "New match starts with empty visible tracker")

func _test_effects() -> void:
	var board = game.board
	var original_motion: bool = board.reduced_motion
	board.set_reduced_motion(false)
	var token = board.tokens[1]
	var holder: Control = token.get_node("SpriteHolder")
	token.set_state(3, 3, false)
	var start: float = holder.rotation
	token.set_state(0, 3, false, true)
	verify(is_equal_approx(holder.rotation, start), "Rotation starts at current heading without snapping")
	await token.rotation_tween.finished
	verify(is_equal_approx(holder.rotation, TAU), "North wrap turns through shortest quarter circle")
	board.show_hook(1, 2)
	board.flash_ship(1)
	verify(board.effects.events.size() == 2, "Hook and collision produce effects")
	await create_timer(0.5).timeout
	verify(board.effects.events.is_empty() and not board.effects.is_processing(), "Expired effects stop processing")
	for i in range(60):
		board.show_effect("motor", Vector2.ZERO, Vector2.ONE)
	verify(board.effects.events.size() <= 48, "Effect history stays bounded")
	token.set_state(1, 3, false, true)
	game.show_menu()
	verify(board.effects.events.is_empty() and not board.effects.is_processing(), "Menu cancels all effects")
	verify(token.rotation_tween == null, "Menu cancels rotation")
	game._on_start_pressed()
	game.ships[0].pos = Vector2i(4, 3)
	game.check_all_cargo()
	game.ships[0].pos = game.ships[0].cargo.dest
	game.check_all_cargo()
	verify(board.effects.events.size() == 1 and board.effects.events[0].kind == "delivery", "Actual delivery emits reward effect")
	board.set_reduced_motion(true)
	board.show_hook(1, 2)
	board.flash_ship(1)
	board.show_effect("delivery", Vector2.ZERO)
	verify(board.effects.events.is_empty(), "Reduced motion cancels and suppresses effects")
	board.update_ship(1, Vector2i(1, 1), 2, 3, false, true)
	verify(token.rotation_tween == null and is_equal_approx(holder.rotation, PI), "Reduced motion applies heading instantly")
	game._on_start_pressed()
	verify(board.effects.events.is_empty(), "Restart does not restore old effects")
	board.set_reduced_motion(original_motion)

func _test_turn_presentation() -> void:
	game.setup_game()
	game.player_queue.assign([game.CMD_ANCHOR, game.CMD_ANCHOR, game.CMD_ANCHOR])
	game.refresh_ui()
	var phases: Array[String] = []
	game._on_execute_pressed()
	for frame in range(300):
		if not game.resolving:
			break
		var phase: String = "%s:%d" % [game.turn_phase, game.active_slot]
		if phases.is_empty() or phases.back() != phase:
			phases.append(phase)
			var card = game.command_box.get_child(game.active_slot)
			verify(card.get_theme_stylebox("panel") != game.slot_styles[game.active_slot], "Active command gets distinct border")
			verify(game.execute_button.disabled, "Phase presentation does not unlock input")
			if game.turn_phase == "wind":
				verify(game.get_node("GameLayer/RightPanel/WindPanel").get_theme_stylebox("panel") != game.wind_style, "Wind phase highlights compass")
		await process_frame
	verify(phases == ["command:0", "wind:0", "command:1", "wind:1", "command:2", "wind:2"], "Real round presents all six phases in order")
	verify(not game.resolving and game.turn_phase == "planning" and game.active_slot == -1, "Round returns to planning")
	for i in range(3):
		verify(game.command_box.get_child(i).get_theme_stylebox("panel") == game.slot_styles[i], "Planning restores slot style")
	verify(game.get_node("GameLayer/RightPanel/WindPanel").get_theme_stylebox("panel") == game.wind_style, "Planning restores compass style")

func _test_victory_screen() -> void:
	game.setup_game()
	game.ships[0].coins = 5
	game.ships[1].coins = 15
	game.ships[1].deliveries = 3
	game.ships[2].coins = 10
	game.ships[3].coins = 5
	var order: Array = game.ships.map(func(ship: Dictionary): return ship.id)
	verify(game.check_victory(), "Bot victory opens results")
	var screen = game.victory_screen
	verify(screen.visible and screen.winner_id == 2, "Results identify actual winner")
	verify(screen.ranking.map(func(ship: Dictionary): return ship.id) == [2, 3, 1, 4], "Results sort by gold with stable ties")
	verify(game.ships.map(func(ship: Dictionary): return ship.id) == order, "Ranking preserves game pilot order")
	verify(screen.rows[2].text == "3", "Results display delivery count")
	verify(screen.replay.has_focus(), "Modal takes keyboard focus")
	verify(game.get_node("GameLayer/RightPanel/MenuButton").focus_mode == Control.FOCUS_NONE, "Background controls cannot receive keyboard focus")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.get_node("GameLayer/RightPanel/MenuButton").get_global_rect().get_center()
	root.push_input(click)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
	await process_frame
	verify(screen.visible and game.game_layer.visible, "Modal intercepts mouse clicks on background menu")
	game._on_command_pressed(game.CMD_LEFT)
	verify(game.player_queue.is_empty(), "Game over rejects background commands")
	var log_before: String = game.info_label.text
	game.check_victory()
	verify(game.info_label.text == log_before, "Repeated victory check is idempotent")
	screen.replay.pressed.emit()
	verify(not screen.visible and not game.game_over, "Replay button starts fresh game")
	verify(game.ships.all(func(ship: Dictionary): return ship.deliveries == 0 and ship.coins == 0), "Replay resets all statistics")
	game.ships[0].coins = 15
	game.check_victory()
	verify(screen.heading.text == "ZAFER SENİN", "Human victory gets victory title")
	screen.menu.pressed.emit()
	verify(not screen.visible and game.menu_layer.visible, "Result menu button dismisses modal")
	game._on_start_pressed()
	verify(screen.ranking.is_empty() and screen.winner_id == -1, "New match clears old results")

func _test_audio() -> void:
	game.setup_game()
	var sound = game.game_audio
	var original_music: float = game.music_volume
	var original_effects: float = game.effects_volume
	game._set_music_volume(0.23)
	game._set_effects_volume(0.71)
	game._load_settings()
	verify(is_equal_approx(sound.music_level, 0.23) and is_equal_approx(sound.effects_level, 0.71), "Independent audio levels persist")
	verify(sound.music.playing and sound.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Gameplay starts looping music")
	for kind in ["motor", "hook", "spark", "delivery", "wind"]:
		var clip: AudioStreamWAV = sound.clips[kind]
		verify(not clip.data.is_empty() and clip.get_length() > 0.1, "Audio clip generated: " + kind)
		var peak: int = 0
		for i in range(0, clip.data.size(), 2):
			peak = maxi(peak, absi(clip.data.decode_s16(i)))
		verify(peak > 100 and peak < 32767, "Clip audible and unclipped: " + kind)
		game.play_sound(kind)
	verify(sound.last_played.size() == 5, "All five event types reach audio controller")
	var voice: int = sound.next_voice
	for i in range(20):
		game.play_sound("wind")
	verify(sound.next_voice == voice and sound.players.size() == 6, "Burst effects deduplicated with bounded voice pool")
	sound.stop_effects()
	var motion: bool = game.board.reduced_motion
	game.board.set_reduced_motion(true)
	game.board.flash_ship(1)
	verify(sound.last_played.has("spark"), "Reduced motion preserves collision sound")
	game.board.set_reduced_motion(motion)
	game._set_effects_volume(0.0)
	game.play_sound("delivery")
	verify(sound.last_played.is_empty() and sound.players.all(func(player): return not player.playing), "Zero effects level stops and suppresses sound")
	verify(is_equal_approx(sound.music.volume_linear, 0.23), "Effects mute leaves music unchanged")
	game._set_music_volume(0.0)
	verify(is_zero_approx(sound.music.volume_linear), "Zero music level is silent")
	game.show_menu()
	verify(not sound.music.playing and sound.last_played.is_empty(), "Menu stops music and effects")
	game._on_start_pressed()
	verify(sound.music.playing and sound.last_played.is_empty(), "New match starts clean audio session")
	game._set_music_volume(original_music)
	game._set_effects_volume(original_effects)

func _test_hover() -> void:
	game.setup_game()
	var board = game.board
	var original_motion: bool = board.reduced_motion
	board.set_reduced_motion(false)
	var token = board.tokens[1]
	var cell: Vector2i = game.ships[0].pos
	var ground: Vector2 = token.position
	var start: float = token.hover_lift
	token._process(1.5)
	verify(not is_equal_approx(start, token.hover_lift), "Hover changes visual altitude slowly")
	verify(token.position == ground and game.ships[0].pos == cell, "Hover never changes board position")
	verify(token.get_node("SpriteHolder").position.y < 0, "Hull stays above ground")
	verify(token.get_node("HumanHalo").scale.y < 1.0, "Ground marker follows board perspective")
	token._sync_geometry()
	var ring_position: Vector2 = token.get_node("HumanHalo").position
	token._sync_geometry()
	verify(token.get_node("HumanHalo").position == ring_position, "Geometry refresh does not accumulate ring offset")
	board.set_reduced_motion(true)
	verify(not token.is_processing() and token.hover_lift > 0.0, "Reduced motion keeps altitude without bobbing")
	game.show_menu()
	verify(not token.is_processing(), "Hidden game stops hover processing")
	game._on_start_pressed()
	board.set_reduced_motion(false)
	verify(token.is_processing(), "Fresh match resumes hover")
	board.set_reduced_motion(original_motion)

func _test_board_focus() -> void:
	game.setup_game()
	var focus = game.board_focus
	var snapshot: Array = game.ships.duplicate(true)
	for cell in [Vector2i(0, 0), Vector2i(5, 4), Vector2i(10, 8)]:
		focus.show_at(game.board.cell_center(cell))
		verify(focus.cell == cell, "Locator matches perspective cell center")
	focus.show_at(Vector2(-100, -100))
	verify(focus.cell == Vector2i(-1, -1), "Locator clears outside board")
	focus.show_at(game.board.cell_center(Vector2i(4, 4)))
	game.resolving = true
	game._refresh_route_preview()
	verify(not focus.enabled and focus.cell.x == -1, "Resolving hides locator")
	game.resolving = false
	game.show_menu()
	verify(not focus.enabled and focus.cell.x == -1, "Menu clears locator")
	verify(game.ships == snapshot, "Locator never changes game state")
	game._on_start_pressed()
	verify(focus.enabled, "Planning restores locator")
