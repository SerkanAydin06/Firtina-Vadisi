@tool
extends EditorPlugin
## Enabled only in the temporary project created by run_editor_preview.py.
var failures := 0
func _enter_tree() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += count_nodes(child)
	return count
func run() -> void:
	await get_tree().create_timer(1.0).timeout
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	check(Engine.is_editor_hint(), "Test requires editor mode")
	var settings_path := "user://settings.cfg"
	var before := FileAccess.get_file_as_bytes(settings_path) if FileAccess.file_exists(settings_path) else PackedByteArray()
	var packed = load("res://scenes/main.tscn")
	for cycle in range(2):
		var game = packed.instantiate()
		get_tree().root.add_child(game)
		await get_tree().process_frame
		await get_tree().process_frame
		check(game.get_node("GameLayer").visible, "Game layout visible in editor")
		check(not game.get_node("MenuLayer").visible, "Menu does not cover editor preview")
		check(game.get_node("GameLayer/RightPanel/CardsPanel/Forward1Tile").pressed.get_connections().is_empty(), "Editor does not connect gameplay signals")
		check(game.get_node("GameLayer/RightPanel/CargoTracker/CargoLabel") != null, "Cargo label is editable scene content")
		check(game.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "Editor does not create audio")
		check(not game.has_node("VictoryScreen"), "Editor does not initialize game results")
		var board = game.get_node("GameLayer/BoardFrame/Board")
		var count := count_nodes(game)
		board.fit_board()
		board.fit_board()
		check(count_nodes(game) == count, "Preview refresh does not duplicate nodes")
		check(board.get_node("GridLayer").position == Vector2.ZERO, "Preview grid origin matches tokens")
		game.queue_free()
		await get_tree().process_frame
	var after := FileAccess.get_file_as_bytes(settings_path) if FileAccess.file_exists(settings_path) else PackedByteArray()
	check(before == after, "Editor does not alter user settings")
	print("EDITOR PREVIEW: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
