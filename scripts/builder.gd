extends Node3D

@export var structures: Array[Structure] = []
@export var selector: Node3D
@export var selector_container: Node3D
@export var view_camera: Camera3D
@export var gridmap: GridMap

signal town_changed
signal palette_changed
signal notice(text: String)
signal charter_ready

var map: DataMap
var index: int = 0
var demolish_mode: bool = false
var last_stats: Dictionary = {}

var _plane: Plane
var _target_cell := Vector3i.ZERO
var _income_wait := 0.0
var _autosave := 0.0
var _unlock_sig := ""
var _placements := 0


func _ready() -> void:
	add_to_group("builder")
	map = DataMap.new()
	map.cash = TownRules.STARTING_CASH
	_plane = Plane(Vector3.UP, Vector3.ZERO)
	_build_library()
	if GameState.start_mode == "continue" or (GameState.start_mode != "new" and GameState.has_save()):
		if not load_map():
			start_fresh()
	else:
		start_fresh()
	update_structure()
	_recalc(false)


func _process(delta: float) -> void:
	if selector:
		var goal := Vector3(_target_cell.x, 0, _target_cell.z)
		selector.position = selector.position.lerp(goal, minf(delta * 40.0, 1.0))
	_income_wait += delta
	if _income_wait >= TownRules.TICK_SECONDS:
		_income_wait -= TownRules.TICK_SECONDS
		_pay_income()
	_autosave += delta
	if _autosave >= 20.0:
		_autosave = 0.0
		save_map()
	_keyboard()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_map()


func _build_library() -> void:
	var mesh_library := MeshLibrary.new()
	for structure in structures:
		var id := mesh_library.get_last_unused_item_id()
		mesh_library.create_item(id)
		mesh_library.set_item_mesh(id, get_mesh(structure.model))
		mesh_library.set_item_mesh_transform(id, Transform3D())
	gridmap.mesh_library = mesh_library


func get_mesh(packed_scene: PackedScene) -> Mesh:
	var scene_state := packed_scene.get_state()
	for i in range(scene_state.get_node_count()):
		if scene_state.get_node_type(i) == "MeshInstance3D":
			for j in scene_state.get_node_property_count(i):
				if scene_state.get_node_property_name(i, j) == "mesh":
					return scene_state.get_node_property_value(i, j).duplicate()
	return null


func preview_at_screen(screen_pos: Vector2) -> void:
	_target_cell = _grid_from_screen(screen_pos)


func preview_grid(cell: Vector3i) -> void:
	_target_cell = cell
	if selector:
		selector.position = Vector3(cell.x, 0, cell.z)


func place_or_remove_at_screen(screen_pos: Vector2) -> void:
	var cell := _grid_from_screen(screen_pos)
	preview_grid(cell)
	if demolish_mode:
		remove_at(cell)
	else:
		place_at(cell, index, true)


func place_at(cell: Vector3i, structure_index: int, enforce: bool = true) -> bool:
	if structure_index < 0 or structure_index >= structures.size():
		return false
	var structure := structures[structure_index]
	if enforce and not TownRules.is_unlocked(structure, map.peak_residents):
		notice.emit("Unlocks at %d residents." % structure.unlock_at)
		return false
	var previous := gridmap.get_cell_item(cell)
	if previous == structure_index:
		_rotate_cell(cell)
		return true
	var cost := TownRules.replacement_cost(previous, structure_index, structures)
	if enforce and cost > map.cash:
		notice.emit("Need %s more." % TownRules.money(cost - map.cash))
		return false
	if previous >= 0 and previous < structures.size():
		map.cash += structures[previous].price
	map.cash -= structure.price
	var orientation := gridmap.get_orthogonal_index_from_basis(selector.basis)
	gridmap.set_cell_item(cell, structure_index, orientation)
	Audio.play("sounds/placement-a.ogg, sounds/placement-b.ogg, sounds/placement-c.ogg, sounds/placement-d.ogg", -20)
	_placements += 1
	if _placements >= 3:
		GameState.mark_hint_seen()
	_recalc(true)
	return true


func remove_at(cell: Vector3i) -> bool:
	var previous := gridmap.get_cell_item(cell)
	if previous < 0 or previous >= structures.size():
		notice.emit("Nothing there to remove.")
		return false
	var refund := structures[previous].price
	map.cash += refund
	gridmap.set_cell_item(cell, -1)
	Audio.play("sounds/removal-a.ogg, sounds/removal-b.ogg, sounds/removal-c.ogg, sounds/removal-d.ogg", -20)
	notice.emit("Sold for %s." % TownRules.money(refund))
	_recalc(true)
	return true


func select_index(next_index: int) -> void:
	if next_index < 0 or next_index >= structures.size():
		return
	var structure := structures[next_index]
	if not TownRules.is_unlocked(structure, map.peak_residents):
		notice.emit("%s unlocks at %d residents." % [structure.display_name, structure.unlock_at])
		return
	index = next_index
	demolish_mode = false
	update_structure()
	Audio.play("sounds/toggle.ogg", -30)
	palette_changed.emit()
	town_changed.emit()


func toggle_demolish() -> void:
	demolish_mode = not demolish_mode
	update_structure()
	Audio.play("sounds/toggle.ogg", -30)
	palette_changed.emit()
	town_changed.emit()


func rotate_piece() -> void:
	if selector:
		selector.rotate_y(deg_to_rad(90))
	Audio.play("sounds/rotate.ogg", -30)


func update_structure() -> void:
	if selector_container == null:
		return
	for child in selector_container.get_children():
		selector_container.remove_child(child)
		child.queue_free()
	selector_container.visible = not demolish_mode
	if demolish_mode:
		_tint_cursor(Color(1, 0.35, 0.32))
		return
	if index < 0 or index >= structures.size():
		return
	var model := structures[index].model.instantiate()
	selector_container.add_child(model)
	model.position.y += 0.25
	var affordable := structures[index].price <= map.cash
	_tint_cursor(Color.WHITE if affordable else Color(1.0, 0.72, 0.45))


func _tint_cursor(color: Color) -> void:
	if selector == null:
		return
	var sprite := selector.get_node_or_null("Sprite") as Sprite3D
	if sprite:
		sprite.modulate = color


func start_fresh() -> void:
	gridmap.clear()
	map = DataMap.new()
	map.cash = TownRules.STARTING_CASH
	index = 0
	demolish_mode = false
	save_map()


func save_map() -> void:
	if map == null or gridmap == null:
		return
	map.structures.clear()
	for cell in gridmap.get_used_cells():
		var data := DataStructure.new()
		data.position = Vector2i(cell.x, cell.z)
		data.orientation = gridmap.get_cell_item_orientation(cell)
		data.structure = gridmap.get_cell_item(cell)
		map.structures.append(data)
	ResourceSaver.save(map, GameState.SAVE_PATH)
	GameState.save_profile()


func load_map() -> bool:
	if not FileAccess.file_exists(GameState.SAVE_PATH):
		return false
	var loaded = ResourceLoader.load(GameState.SAVE_PATH)
	if loaded == null or not (loaded is DataMap):
		return false
	gridmap.clear()
	map = loaded
	for cell in map.structures:
		gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
	_recalc(false)
	return true


func _recalc(pay: bool) -> void:
	var cells: Array = []
	for cell in gridmap.get_used_cells():
		cells.append({"pos": Vector2i(cell.x, cell.z), "id": gridmap.get_cell_item(cell)})
	last_stats = TownRules.evaluate(cells, structures)
	var residents := int(last_stats["residents"])
	var before_peak := map.peak_residents
	if residents > map.peak_residents:
		map.peak_residents = residents
		var names := TownRules.unlocks_between(structures, before_peak, map.peak_residents)
		if pay and names.size() > 0:
			notice.emit("Unlocked: " + ", ".join(names))
	var milestones := TownRules.collect_milestones(residents, map.claimed_goals, pay)
	map.claimed_goals = milestones["claimed"]
	if pay and int(milestones["reward"]) > 0:
		map.cash += int(milestones["reward"])
		for event in milestones["events"]:
			notice.emit("%s! +%s" % [event["name"], TownRules.money(int(event["reward"]))])
	if bool(milestones["just_chartered"]) and not map.charter_celebrated:
		map.charter_celebrated = true
		charter_ready.emit()
	var sig := _signature()
	var unlocks_changed := sig != _unlock_sig
	_unlock_sig = sig
	update_structure()
	town_changed.emit()
	if unlocks_changed:
		palette_changed.emit()


func _pay_income() -> void:
	var amount := int(last_stats.get("income", 0))
	if amount <= 0:
		return
	map.cash += amount
	if not demolish_mode and index >= 0 and index < structures.size():
		var affordable := structures[index].price <= map.cash
		_tint_cursor(Color.WHITE if affordable else Color(1.0, 0.72, 0.45))
	town_changed.emit()


func _signature() -> String:
	var bits := ""
	for structure in structures:
		bits += "1" if TownRules.is_unlocked(structure, map.peak_residents) else "0"
	return bits


func _grid_from_screen(screen_pos: Vector2) -> Vector3i:
	if view_camera == null:
		return _target_cell
	var origin := view_camera.project_ray_origin(screen_pos)
	var normal := view_camera.project_ray_normal(screen_pos)
	var hit: Variant = _plane.intersects_ray(origin, normal)
	if hit == null:
		return _target_cell
	var point := hit as Vector3
	return Vector3i(roundi(point.x), 0, roundi(point.z))


func _rotate_cell(cell: Vector3i) -> void:
	var item := gridmap.get_cell_item(cell)
	if item < 0:
		return
	var orientation := gridmap.get_cell_item_orientation(cell)
	var basis := gridmap.get_basis_with_orthogonal_index(orientation)
	basis = basis.rotated(Vector3.UP, PI / 2.0)
	gridmap.set_cell_item(cell, item, gridmap.get_orthogonal_index_from_basis(basis))
	if selector:
		selector.basis = basis
	Audio.play("sounds/rotate.ogg", -30)


func _keyboard() -> void:
	if Input.is_action_just_pressed("structure_next"):
		_cycle(1)
	if Input.is_action_just_pressed("structure_previous"):
		_cycle(-1)
	if Input.is_action_just_pressed("rotate"):
		rotate_piece()
	if Input.is_action_just_pressed("demolish"):
		remove_at(_target_cell)
	if Input.is_action_just_pressed("save"):
		save_map()
		notice.emit("Town saved.")
	if Input.is_action_just_pressed("load"):
		if load_map():
			notice.emit("Town loaded.")
	if Input.is_action_just_pressed("load_resources"):
		_load_sample()


func _cycle(direction: int) -> void:
	if structures.is_empty():
		return
	for _step in structures.size():
		index = wrapi(index + direction, 0, structures.size())
		if TownRules.is_unlocked(structures[index], map.peak_residents):
			demolish_mode = false
			update_structure()
			Audio.play("sounds/toggle.ogg", -30)
			palette_changed.emit()
			town_changed.emit()
			return


func _load_sample() -> void:
	var loaded = ResourceLoader.load("res://sample map/map.res")
	if loaded == null:
		return
	gridmap.clear()
	map = loaded
	for cell in map.structures:
		gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
	_recalc(false)
	notice.emit("Sample town loaded.")
