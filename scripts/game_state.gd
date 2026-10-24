extends Node

const PROFILE_PATH := "user://profile.cfg"
const SAVE_PATH := "user://map.res"

var start_mode := ""
var muted := false
var seen_hint := false


func _ready() -> void:
	load_profile()
	apply_mute()


func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))
		seen_hint = bool(cfg.get_value("game", "seen_hint", false))


func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PROFILE_PATH)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("game", "seen_hint", seen_hint)
	cfg.save(PROFILE_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func toggle_mute() -> void:
	muted = not muted
	apply_mute()
	save_profile()


func apply_mute() -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)


func mark_hint_seen() -> void:
	if seen_hint:
		return
	seen_hint = true
	save_profile()
