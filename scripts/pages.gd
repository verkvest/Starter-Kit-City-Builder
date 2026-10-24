extends RefCounted
class_name GamePages

static func how_to_bbcode() -> String:
	return """[b]Build Cobblewick[/b]
Tap an empty plot to place the selected piece. Tap the same piece again to spin it. Turn on Remove, then tap a building to sell it.

[b]Look around[/b]
Drag with one finger to slide the town. Pinch to zoom. Twist two fingers to turn the view. Rotate turns the piece before you set it down.

[b]Grow the town[/b]
Homes count residents only when a road touches them, on a side and not a corner. Every few seconds the town earns coins from residents, plus fountains, workshops on a road, and one coin for every two trees beside a home.

[b]Charter[/b]
New buildings unlock as your best population grows, and they stay unlocked. Reach 10, 25, 50, and 100 residents for bonuses. At 100 residents the town is chartered, and you can keep building."""


static func credits_bbcode() -> String:
	return """[b]Cobblewick[/b]
A small town builder made for phones. The game code is adapted from Kenney's Starter Kit City Builder.

[b]Code[/b]
Copyright (c) 2025-2026 Kenney. MIT License.
Sound playback pool in this project is adapted from KidsCanCode Godot Recipes. Copyright (c) 2019 KidsCanCode. MIT License.

[b]Art and audio[/b]
3D models, sprites, sound effects, and the vector source file are CC0 by Kenney (kenney.nl).

[b]Font[/b]
Lilita One. Copyright (c) 2011 Juan Montoreano (juan@remolacha.biz), with Reserved Font Name Lilita. SIL Open Font License 1.1.

[b]Engine[/b]
Made with Godot Engine. Copyright (c) 2014-present Godot Engine contributors. Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur. MIT License.

The full license texts follow."""


static func make_page(title: String, body_bbcode: String, plain: String, insets: Vector4i) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = UiKit.SKY_DEEP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiKit.apply_insets(margin, insets)
	UiKit.passthrough(margin)
	root.add_child(margin)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiKit.style(UiKit.CREAM, Color(1, 1, 1, 0.4), 0, 22))
	margin.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var heading := UiKit.label(title, 36, UiKit.INK)
	box.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich.add_theme_font_override("normal_font", UiKit.font())
	rich.add_theme_font_override("bold_font", UiKit.font())
	rich.add_theme_font_size_override("normal_font_size", 22)
	rich.add_theme_font_size_override("bold_font_size", 24)
	rich.add_theme_color_override("default_color", UiKit.INK)
	rich.text = body_bbcode
	column.add_child(rich)
	if not plain.is_empty():
		var dump := UiKit.label(plain, 18, Color(0.22, 0.24, 0.28))
		dump.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(dump)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 72)
	UiKit.style_button(back, UiKit.GOOD, Color(0.15, 0.32, 0.2), 0, 26)
	box.add_child(back)
	root.set_meta("back", back)
	return root


static func license_file() -> String:
	var path := "res://THIRD_PARTY_LICENSES.md"
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)
	return "License file missing from the build. See THIRD_PARTY_LICENSES.md in the project."
