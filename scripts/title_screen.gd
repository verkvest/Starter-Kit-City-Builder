extends Control

var _page: Control
var _safe: MarginContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	get_viewport().size_changed.connect(_apply_safe)
	_apply_safe()
	_play_ambience()


func _build() -> void:
	var sky := ColorRect.new()
	sky.color = UiKit.SKY
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(sky)

	var wash := TextureRect.new()
	wash.texture = load("res://icon.png")
	wash.modulate = Color(1, 1, 1, 0.16)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	UiKit.passthrough(wash)
	add_child(wash)

	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.passthrough(_safe)
	add_child(_safe)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiKit.passthrough(center)
	_safe.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 0)
	card.add_theme_stylebox_override("panel", UiKit.style(Color(0.98, 0.96, 0.92, 0.96), Color.WHITE, 0, 28))
	center.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)

	var badge := TextureRect.new()
	badge.texture = load("res://icon.png")
	badge.custom_minimum_size = Vector2(72, 72)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiKit.passthrough(badge)
	box.add_child(badge)

	var title := UiKit.label("Cobblewick", 54, UiKit.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title)

	var subtitle := UiKit.label("Build roads. House neighbors.\nCharter the town at 100 residents.", 22, Color(0.28, 0.32, 0.36))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(440, 0)
	box.add_child(subtitle)

	if GameState.has_save():
		_big_button(box, "Continue", UiKit.GOOD, _continue)
		_big_button(box, "New town", UiKit.SKY_DEEP, _confirm_new)
	else:
		_big_button(box, "New town", UiKit.GOOD, _start_new)
	_big_button(box, "How to play", UiKit.HOME, func() -> void: _open_page("How to play", GamePages.how_to_bbcode(), ""))
	_big_button(box, "Credits", UiKit.CIVIC, func() -> void: _open_page("Credits", GamePages.credits_bbcode(), GamePages.license_file()))
	var sound_label := "Sound off" if not GameState.muted else "Sound on"
	_big_button(box, sound_label, Color(0.35, 0.38, 0.44), _toggle_sound)

	var version := UiKit.label("Version %s" % ProjectSettings.get_setting("application/config/version", "0.1.0"), 16, Color(0.35, 0.38, 0.42))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(version)


func _big_button(box: VBoxContainer, text: String, color: Color, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(440, 64)
	UiKit.style_button(button, color, Color.WHITE, 0, 26)
	button.pressed.connect(action)
	box.add_child(button)


func _apply_safe() -> void:
	if _safe:
		UiKit.apply_insets(_safe, UiKit.safe_insets(get_viewport()))


func _play_ambience() -> void:
	var player := AudioStreamPlayer.new()
	var stream := load("res://sounds/ambience.ogg").duplicate() as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	player.volume_db = -24.0
	add_child(player)
	player.play()


func _continue() -> void:
	GameState.start_mode = "continue"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _start_new() -> void:
	GameState.start_mode = "new"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _confirm_new() -> void:
	_close_page()
	_page = GamePages.make_page(
		"New town?",
		"Starting over replaces the Cobblewick you have saved.",
		"",
		UiKit.safe_insets(get_viewport())
	)
	add_child(_page)
	var back := _page.get_meta("back") as Button
	back.text = "Cancel"
	back.pressed.connect(_close_page)
	var confirm := Button.new()
	confirm.text = "Replace the saved town"
	confirm.custom_minimum_size = Vector2(0, 72)
	UiKit.style_button(confirm, UiKit.DANGER, Color.WHITE, 0, 24)
	confirm.pressed.connect(_start_new)
	back.get_parent().add_child(confirm)
	back.get_parent().move_child(confirm, back.get_index())


func _toggle_sound() -> void:
	GameState.toggle_mute()
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_page = null
	_build()
	_apply_safe()
	_play_ambience()


func _open_page(title: String, body: String, plain: String) -> void:
	_close_page()
	_page = GamePages.make_page(title, body, plain, UiKit.safe_insets(get_viewport()))
	add_child(_page)
	(_page.get_meta("back") as Button).pressed.connect(_close_page)


func _close_page() -> void:
	if _page and is_instance_valid(_page):
		_page.queue_free()
	_page = null
