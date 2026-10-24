extends CanvasLayer

var builder: Node
var view: Node3D
var _top_bar: Control
var _bottom_bar: Control
var _modal: Control
var _cash: Label
var _income: Label
var _goal: Button
var _hint: Label
var _toast: Label
var _toast_time := 0.0
var _remove_button: Button
var _category := "road"
var _buttons: Array[Button] = []
var _safe: MarginContainer


func _ready() -> void:
	add_to_group("hud")
	layer = 10
	builder = get_parent().get_node("Builder")
	view = get_parent().get_node("View")
	_build()
	view.ui_block = blocks_world
	view.tapped.connect(builder.place_or_remove_at_screen)
	view.pointer_moved.connect(builder.preview_at_screen)
	view.rotate_piece_requested.connect(builder.rotate_piece)
	builder.town_changed.connect(_refresh_stats)
	builder.palette_changed.connect(_rebuild_palette)
	builder.notice.connect(toast)
	builder.charter_ready.connect(_show_charter)
	get_viewport().size_changed.connect(_apply_safe)
	_apply_safe()
	_rebuild_palette()
	_refresh_stats()


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
		if _toast_time <= 0.0:
			_toast.text = ""


func blocks_world(screen_pos: Vector2) -> bool:
	if _modal and is_instance_valid(_modal):
		return true
	if _top_bar and _top_bar.get_global_rect().has_point(screen_pos):
		return true
	if _bottom_bar and _bottom_bar.get_global_rect().has_point(screen_pos):
		return true
	return false


func toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_time = 2.4


func open_goals() -> void:
	_show_modal(_goals_body)


func open_menu() -> void:
	_show_modal(_menu_body)


func _build() -> void:
	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.passthrough(_safe)
	add_child(_safe)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.passthrough(root)
	_safe.add_child(root)

	_top_bar = Control.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 132
	UiKit.passthrough(_top_bar)
	root.add_child(_top_bar)

	var top_row := HBoxContainer.new()
	top_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_row.offset_bottom = 78
	top_row.add_theme_constant_override("separation", 10)
	UiKit.passthrough(top_row)
	_top_bar.add_child(top_row)

	var cash_box := HBoxContainer.new()
	cash_box.add_theme_constant_override("separation", 6)
	cash_box.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.passthrough(cash_box)
	var coin := TextureRect.new()
	coin.texture = load("res://sprites/coin.png")
	coin.custom_minimum_size = Vector2(42, 42)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UiKit.passthrough(coin)
	cash_box.add_child(coin)
	var cash_text := VBoxContainer.new()
	UiKit.passthrough(cash_text)
	_cash = UiKit.label("$0", 30, Color.WHITE)
	_income = UiKit.label("+0", 18, Color(1, 0.95, 0.75))
	_outline(_cash)
	_outline(_income)
	cash_text.add_child(_cash)
	cash_text.add_child(_income)
	cash_box.add_child(cash_text)
	top_row.add_child(cash_box)

	_goal = Button.new()
	_goal.custom_minimum_size = Vector2(168, 70)
	_goal.pressed.connect(open_goals)
	UiKit.style_button(_goal, Color(0.16, 0.22, 0.32, 0.9), UiKit.GOLD, 3, 22)
	top_row.add_child(_goal)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.passthrough(spacer)
	top_row.add_child(spacer)

	var menu := Button.new()
	menu.text = "Menu"
	menu.custom_minimum_size = Vector2(112, 70)
	menu.pressed.connect(open_menu)
	UiKit.style_button(menu, Color(0.16, 0.22, 0.32, 0.92), Color.WHITE, 0, 24)
	top_row.add_child(menu)

	_hint = UiKit.label("", 20, Color.WHITE)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_top = 80
	_hint.offset_bottom = 108
	_outline(_hint)
	_top_bar.add_child(_hint)
	_toast = UiKit.label("", 22, UiKit.GOLD)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 106
	_toast.offset_bottom = 132
	_outline(_toast)
	_top_bar.add_child(_toast)

	_bottom_bar = VBoxContainer.new()
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_top = -236
	_bottom_bar.add_theme_constant_override("separation", 8)
	UiKit.passthrough(_bottom_bar)
	root.add_child(_bottom_bar)

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	UiKit.passthrough(tools)
	_bottom_bar.add_child(tools)
	for category in ["road", "home", "park", "civic"]:
		var chip := Button.new()
		chip.text = _category_title(category)
		chip.custom_minimum_size = Vector2(112, 58)
		chip.set_meta("category", category)
		chip.pressed.connect(_select_category.bind(category))
		tools.add_child(chip)
	var tool_spacer := Control.new()
	tool_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.passthrough(tool_spacer)
	tools.add_child(tool_spacer)
	var rotate := Button.new()
	rotate.text = "Rotate"
	rotate.custom_minimum_size = Vector2(112, 58)
	rotate.pressed.connect(builder.rotate_piece)
	UiKit.style_button(rotate, Color(0.20, 0.28, 0.40), Color.WHITE, 0, 22)
	tools.add_child(rotate)
	_remove_button = Button.new()
	_remove_button.text = "Remove"
	_remove_button.custom_minimum_size = Vector2(124, 58)
	_remove_button.pressed.connect(builder.toggle_demolish)
	tools.add_child(_remove_button)
	var center := Button.new()
	center.text = "Center"
	center.custom_minimum_size = Vector2(112, 58)
	center.pressed.connect(view.recenter)
	UiKit.style_button(center, Color(0.20, 0.28, 0.40), Color.WHITE, 0, 22)
	tools.add_child(center)
	_style_category_chips(tools)

	var scroll := ScrollContainer.new()
	scroll.name = "PaletteScroll"
	scroll.custom_minimum_size = Vector2(0, 128)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_bar.add_child(scroll)
	var row := HBoxContainer.new()
	row.name = "Palette"
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)


func _apply_safe() -> void:
	if _safe:
		UiKit.apply_insets(_safe, UiKit.safe_insets(get_viewport()))


func _select_category(category: String) -> void:
	_category = category
	_style_category_chips(_bottom_bar.get_child(0))
	_rebuild_palette()


func _style_category_chips(tools: Node) -> void:
	for child in tools.get_children():
		if not child.has_meta("category"):
			continue
		var category: String = child.get_meta("category")
		var selected := category == _category
		var bg := UiKit.category_color(category)
		UiKit.style_button(child, bg if selected else bg.darkened(0.35), Color.WHITE if selected else Color(1, 1, 1, 0.45), 4 if selected else 0, 20)


func show_category(category: String) -> void:
	_select_category(category)


func _rebuild_palette() -> void:
	var row := _find_palette()
	if row == null:
		return
	for child in row.get_children():
		child.queue_free()
	_buttons.clear()
	for structure_index in structures_range():
		var structure: Structure = builder.structures[structure_index]
		if structure.category != _category:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(124, 116)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.set_meta("structure_index", structure_index)
		button.pressed.connect(_on_structure_pressed.bind(structure_index))
		row.add_child(button)
		_buttons.append(button)
	_refresh_structure_buttons()
	_style_remove()


func _find_palette() -> Node:
	var scroll := _bottom_bar.get_node_or_null("PaletteScroll")
	if scroll == null:
		return null
	return scroll.get_node_or_null("Palette")


func _outline(node: Label) -> void:
	node.add_theme_constant_override("outline_size", 8)
	node.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.9))


func structures_range() -> Array:
	var indexes: Array = []
	for structure_index in builder.structures.size():
		indexes.append(structure_index)
	return indexes


func _on_structure_pressed(structure_index: int) -> void:
	builder.select_index(structure_index)


func _refresh_stats() -> void:
	var stats: Dictionary = builder.last_stats
	var residents := int(stats.get("residents", 0))
	_cash.text = TownRules.money(builder.map.cash)
	var per_tick := int(stats.get("income", 0))
	_income.text = "+%d / 5s" % per_tick if per_tick > 0 else "No income yet"
	_goal.text = "%d / %d\nResidents" % [residents, TownRules.CHARTER]
	_hint.text = _hint_text(stats, residents)
	_refresh_structure_buttons()
	_style_remove()
	var bar_tint := UiKit.GOLD if residents < TownRules.CHARTER else UiKit.GOOD
	UiKit.style_button(_goal, Color(0.16, 0.22, 0.32, 0.92), bar_tint, 3, 22)


func _hint_text(stats: Dictionary, residents: int) -> String:
	if not GameState.seen_hint:
		return "Drag to move   ·   Pinch to zoom   ·   Two fingers turn   ·   Tap to build"
	if int(stats.get("disconnected", 0)) > 0:
		return "%d homes need a road beside them" % int(stats["disconnected"])
	if int(stats.get("unserved", 0)) > 0:
		return "A workshop earns coins when a road touches it"
	if builder.map.charter_celebrated or residents >= TownRules.CHARTER:
		return "Cobblewick is chartered. Keep building."
	for milestone in TownRules.MILESTONES:
		if residents < int(milestone["at"]):
			return "Next: %s at %d residents" % [milestone["name"], int(milestone["at"])]
	return "Keep building."


func _refresh_structure_buttons() -> void:
	for button in _buttons:
		if not is_instance_valid(button):
			continue
		var structure_index: int = button.get_meta("structure_index")
		var structure: Structure = builder.structures[structure_index]
		var unlocked := TownRules.is_unlocked(structure, builder.map.peak_residents)
		var selected: bool = (not builder.demolish_mode) and structure_index == builder.index
		var bg := UiKit.category_color(structure.category)
		if not unlocked:
			button.text = "%s\nAt %d" % [structure.display_name, structure.unlock_at]
			UiKit.style_button(button, bg.darkened(0.45), Color(1, 1, 1, 0.35), 0, 18)
		else:
			button.text = "%s\n%s" % [structure.display_name, TownRules.money(structure.price)]
			var border := UiKit.GOLD if selected else Color(1, 1, 1, 0.25)
			UiKit.style_button(button, bg if builder.map.cash >= structure.price or selected else bg.darkened(0.25), border, 5 if selected else 0, 18)
		button.modulate = Color.WHITE


func _style_remove() -> void:
	if builder.demolish_mode:
		_remove_button.text = "Removing"
		UiKit.style_button(_remove_button, UiKit.DANGER, Color.WHITE, 4, 20)
	else:
		_remove_button.text = "Remove"
		UiKit.style_button(_remove_button, Color(0.42, 0.22, 0.2), Color.WHITE, 0, 20)


func _show_charter() -> void:
	_show_modal(_charter_body)


func _show_modal(fill: Callable) -> void:
	_close_modal()
	_modal = Control.new()
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.12, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(dim)
	add_child(_modal)
	fill.call(_modal)
	view.accept_world_input = false
	view.cancel_gesture()


func _close_modal() -> void:
	if _modal and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
	if view:
		view.accept_world_input = true


func _menu_body(host: Control) -> void:
	var card := _card(host, "Paused")
	_menu_button(card, "Resume", _close_modal)
	_menu_button(card, "Town goals", open_goals)
	_menu_button(card, "How to play", func() -> void: _show_text_page("How to play", GamePages.how_to_bbcode(), ""))
	_menu_button(card, "Credits", func() -> void: _show_text_page("Credits", GamePages.credits_bbcode(), GamePages.license_file()))
	var sound := "Sound off" if not GameState.muted else "Sound on"
	_menu_button(card, sound, func() -> void:
		GameState.toggle_mute()
		_close_modal()
		open_menu()
	)
	_menu_button(card, "Save and main menu", _leave)


func _goals_body(host: Control) -> void:
	var residents := int(builder.last_stats.get("residents", 0))
	var lines := "[b]Residents %d / %d[/b]\nBest so far: %d. Unlocks stay even if you sell buildings.\n\n" % [residents, TownRules.CHARTER, builder.map.peak_residents]
	for milestone in TownRules.MILESTONES:
		var at := int(milestone["at"])
		var done: bool = builder.map.claimed_goals.has(at) or residents >= at
		var mark := "Done" if done else "Locked"
		lines += "%s — %d residents — %s — %s\n" % [milestone["name"], at, TownRules.money(int(milestone["reward"])), mark]
	lines += "\nHomes count only with a road beside them. Income arrives every 5 seconds."
	var page := GamePages.make_page("Town goals", lines, "", UiKit.safe_insets(get_viewport()))
	host.add_child(page)
	(page.get_meta("back") as Button).pressed.connect(_close_modal)


func _charter_body(host: Control) -> void:
	var page := GamePages.make_page(
		"Cobblewick is chartered",
		"One hundred residents call this lane home. The town is yours — keep building, or start another from the menu.",
		"",
		UiKit.safe_insets(get_viewport())
	)
	host.add_child(page)
	var back := page.get_meta("back") as Button
	back.text = "Keep building"
	back.pressed.connect(_close_modal)


func _show_text_page(title: String, body: String, plain: String) -> void:
	_show_modal(func(host: Control) -> void:
		var page := GamePages.make_page(title, body, plain, UiKit.safe_insets(get_viewport()))
		host.add_child(page)
		(page.get_meta("back") as Button).pressed.connect(open_menu)
	)


func _card(host: Control, title: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.apply_insets(margin, UiKit.safe_insets(get_viewport()))
	UiKit.passthrough(margin)
	host.add_child(margin)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.passthrough(center)
	margin.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", UiKit.style(UiKit.CREAM, Color.WHITE, 0, 22))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UiKit.label(title, 36, UiKit.INK))
	return box


func _menu_button(box: VBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 68)
	UiKit.style_button(button, UiKit.SKY_DEEP, Color.WHITE, 0, 24)
	button.pressed.connect(action)
	box.add_child(button)


func _leave() -> void:
	builder.save_map()
	_close_modal()
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _category_title(category: String) -> String:
	match category:
		"home":
			return "Homes"
		"park":
			return "Parks"
		"civic":
			return "Civic"
		_:
			return "Roads"
