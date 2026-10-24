extends Node

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--shots"):
		set_process(false)
		return
	_run()


func _run() -> void:
	await get_tree().process_frame
	_phone_window()
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture("01-menu.png")
	GameState.start_mode = "new"
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	var town: Node = null
	for _attempt in 40:
		await get_tree().process_frame
		town = get_tree().get_first_node_in_group("builder")
		if town:
			break
	if town == null:
		push_error("screenshot run could not find the town")
		get_tree().quit(1)
		return
	_build_demo(town)
	var view := town.get_parent().get_node("View")
	view.zoom = 15.0
	await get_tree().create_timer(1.6).timeout
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("show_category"):
		push_error("screenshot run could not find the town HUD")
		get_tree().quit(1)
		return
	hud.show_category("home")
	await get_tree().process_frame
	await _capture("02-gameplay.png")
	hud.open_goals()
	await get_tree().create_timer(0.4).timeout
	await _capture("03-goals.png")
	print("screenshots written")
	get_tree().quit(0)


func _phone_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1560, 720))
	get_window().size = Vector2i(1560, 720)
	print("window ", DisplayServer.window_get_size(), " viewport ", get_viewport().get_visible_rect().size)


func _build_demo(town: Node) -> void:
	for x in range(-3, 4):
		town.place_at(Vector3i(x, 0, 0), 0, true)
	for x in [-2, -1, 1, 2]:
		town.place_at(Vector3i(x, 0, 1), 7, true)
	for x in [-1, 1]:
		town.place_at(Vector3i(x, 0, -1), 7, true)
	town.place_at(Vector3i(-3, 0, 1), 13, true)
	town.place_at(Vector3i(3, 0, 1), 13, true)
	town.select_index(7)
	town.preview_grid(Vector3i(4, 0, 1))


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var directory := ProjectSettings.globalize_path("res://") + "build/screenshots"
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory + "/" + file_name
	var err := image.save_png(path)
	print("SHOT ", path, " ", image.get_width(), "x", image.get_height(), " err=", err)
