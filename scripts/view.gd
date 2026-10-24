extends Node3D

const MIN_ZOOM := 16.0
const MAX_ZOOM := 56.0
const TAP_SLOP := 22.0

var camera_position: Vector3
var camera_rotation: Vector3
var zoom: float = 28.0

var accept_world_input := true
var ui_block: Callable = Callable()

var _initial_yaw := 0.0
var _plane := Plane(Vector3.UP, 0)
var _fingers := {}
var _prev_fingers := {}
var _gesture := "none"
var _tap_index := -1
var _tap_pos := Vector2.ZERO
var _tap_moved := false
var _saw_touch := false
var _mouse_down := false
var _mouse_pos := Vector2.ZERO
var _mouse_moved := false
var _rotating := false

@onready var camera: Camera3D = $Camera

signal tapped(screen_pos: Vector2)
signal pointer_moved(screen_pos: Vector2)
signal rotate_piece_requested


func _ready() -> void:
	camera_rotation = rotation_degrees
	_initial_yaw = camera_rotation.y


func _process(delta: float) -> void:
	position = position.lerp(camera_position, minf(delta * 8.0, 1.0))
	rotation_degrees = rotation_degrees.lerp(camera_rotation, minf(delta * 6.0, 1.0))
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), minf(delta * 8.0, 1.0))
	_keyboard(delta)


func _input(event: InputEvent) -> void:
	if not accept_world_input:
		_clear_pointers()
		return
	if event is InputEventScreenTouch:
		_saw_touch = true
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_saw_touch = true
		_on_screen_drag(event)
	elif not _saw_touch and event is InputEventMouseButton:
		_on_mouse_button(event)
	elif not _saw_touch and event is InputEventMouseMotion:
		_on_mouse_motion(event)


func recenter() -> void:
	camera_position = Vector3.ZERO
	camera_rotation.y = _initial_yaw
	zoom = 28.0


func cancel_gesture() -> void:
	_clear_pointers()


func _keyboard(delta: float) -> void:
	if not accept_world_input:
		return
	var input := Vector3.ZERO
	input.x = Input.get_axis("camera_left", "camera_right")
	input.z = Input.get_axis("camera_forward", "camera_back")
	if input.length_squared() > 0.0:
		input = input.rotated(Vector3.UP, rotation.y).normalized()
		camera_position += input * delta * 14.0
		_clamp_camera()
	if Input.is_action_just_pressed("camera_center"):
		recenter()


func _on_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _over_ui(event.position):
			return
		_fingers[event.index] = event.position
		_prev_fingers[event.index] = event.position
		if _fingers.size() == 1:
			_gesture = "tap"
			_tap_index = event.index
			_tap_pos = event.position
			_tap_moved = false
			pointer_moved.emit(event.position)
		else:
			_tap_moved = true
			_gesture = "multi"
	else:
		var was_tap := _gesture == "tap" and event.index == _tap_index and not _tap_moved
		var tap_pos := _tap_pos
		_fingers.erase(event.index)
		_prev_fingers.erase(event.index)
		if was_tap and _fingers.is_empty():
			tapped.emit(tap_pos)
		if _fingers.is_empty():
			_gesture = "none"
		elif _fingers.size() == 1:
			_gesture = "pan"
			_tap_moved = true


func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if not _fingers.has(event.index):
		return
	_fingers[event.index] = event.position
	if _fingers.size() >= 2:
		_gesture = "multi"
		_tap_moved = true
		_apply_pinch()
		_prev_fingers = _fingers.duplicate()
		return
	if _gesture == "tap" and event.position.distance_to(_tap_pos) > TAP_SLOP:
		_tap_moved = true
		_gesture = "pan"
	if _gesture == "pan":
		_pan_screen(event.position - event.relative, event.position)
	elif _gesture == "tap":
		pointer_moved.emit(event.position)
	_prev_fingers[event.index] = event.position


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _over_ui(event.position):
				return
			_mouse_down = true
			_mouse_moved = false
			_mouse_pos = event.position
			pointer_moved.emit(event.position)
		elif _mouse_down:
			if not _mouse_moved:
				tapped.emit(event.position)
			_mouse_down = false
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not _over_ui(event.position):
		rotate_piece_requested.emit()
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_rotating = event.pressed
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom = maxf(MIN_ZOOM, zoom - 3.0)
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom = minf(MAX_ZOOM, zoom + 3.0)


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if _mouse_down:
		if event.position.distance_to(_mouse_pos) > TAP_SLOP:
			_mouse_moved = true
		if _mouse_moved:
			_pan_screen(event.position - event.relative, event.position)
		else:
			pointer_moved.emit(event.position)
	elif _rotating:
		camera_rotation.y -= event.relative.x * 0.35
	elif not _over_ui(event.position):
		pointer_moved.emit(event.position)


func _apply_pinch() -> void:
	var ids: Array = _fingers.keys()
	if ids.size() < 2:
		return
	var a: int = ids[0]
	var b: int = ids[1]
	if not _prev_fingers.has(a) or not _prev_fingers.has(b):
		return
	var previous_a: Vector2 = _prev_fingers[a]
	var previous_b: Vector2 = _prev_fingers[b]
	var next_a: Vector2 = _fingers[a]
	var next_b: Vector2 = _fingers[b]
	var old_distance := previous_a.distance_to(previous_b)
	var new_distance := next_a.distance_to(next_b)
	if old_distance > 8.0 and new_distance > 8.0:
		zoom = clampf(zoom * (old_distance / new_distance), MIN_ZOOM, MAX_ZOOM)
	if old_distance > 48.0 and new_distance > 48.0:
		var delta := wrapf((next_b - next_a).angle() - (previous_b - previous_a).angle(), -PI, PI)
		camera_rotation.y -= rad_to_deg(delta)
	var old_mid := (previous_a + previous_b) * 0.5
	var new_mid := (next_a + next_b) * 0.5
	_pan_screen(old_mid, new_mid)


func _pan_screen(from_pos: Vector2, to_pos: Vector2) -> void:
	var from_hit: Variant = _ground_point(from_pos)
	var to_hit: Variant = _ground_point(to_pos)
	if from_hit == null or to_hit == null:
		return
	camera_position += (from_hit as Vector3) - (to_hit as Vector3)
	_clamp_camera()


func _ground_point(screen_pos: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_pos)
	var normal := camera.project_ray_normal(screen_pos)
	return _plane.intersects_ray(origin, normal)


func _clamp_camera() -> void:
	camera_position.x = clampf(camera_position.x, -42.0, 42.0)
	camera_position.y = 0.0
	camera_position.z = clampf(camera_position.z, -42.0, 42.0)


func _over_ui(screen_pos: Vector2) -> bool:
	return ui_block.is_valid() and bool(ui_block.call(screen_pos))


func _clear_pointers() -> void:
	_fingers.clear()
	_prev_fingers.clear()
	_gesture = "none"
	_mouse_down = false
	_rotating = false
	_tap_moved = true
