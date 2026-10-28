extends Control
## Twin-stick touch controls: left stick moves/jetpacks, right stick aims, Fire taps/shoots.

const STICK_RADIUS: float = 100.0
const FIRE_RADIUS: float = 82.0

var _viewport_size: Vector2 = Vector2(1280.0, 720.0)
var _left_center: Vector2 = Vector2(150.0, 610.0)
var _right_center: Vector2 = Vector2(1120.0, 610.0)
var _fire_center: Vector2 = Vector2(1010.0, 610.0)
var _grenade_center: Vector2 = Vector2(460.0, 610.0)
var _left_pointer: int = -1
var _right_pointer: int = -1
var _left_vector: Vector2 = Vector2.ZERO
var _right_vector: Vector2 = Vector2.ZERO
var _fire_pointer: int = -1
var _grenade_pointer: int = -1


func _ready() -> void:
	_refresh_layout()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_layout()


func _refresh_layout() -> void:
	_viewport_size = get_viewport_rect().size
	_left_center = Vector2(150.0, _viewport_size.y - 110.0)
	_right_center = Vector2(_viewport_size.x - 300.0, _viewport_size.y - 110.0)
	_fire_center = Vector2(_viewport_size.x - 110.0, _viewport_size.y - 110.0)
	_grenade_center = _left_center + Vector2(310.0, 0.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(touch: InputEventScreenTouch) -> void:
	var point: Vector2 = touch.position
	if touch.pressed:
		if point.distance_to(_left_center) <= STICK_RADIUS and _left_pointer == -1:
			_left_pointer = touch.index
			_update_left(point)
		elif point.distance_to(_fire_center) <= FIRE_RADIUS and _fire_pointer == -1:
			_fire_pointer = touch.index
			Input.action_press(&"fire")
		elif point.distance_to(_right_center) <= STICK_RADIUS and _right_pointer == -1:
			_right_pointer = touch.index
			_update_right(point)
		elif point.distance_to(_grenade_center) <= 55.0:
			_grenade_pointer = touch.index
			Input.action_press(&"grenade")
	else:
		if touch.index == _left_pointer:
			_left_pointer = -1
			_left_vector = Vector2.ZERO
			_update_input_state()
		elif touch.index == _right_pointer:
			_right_pointer = -1
			_right_vector = Vector2.ZERO
			_update_input_state()
		elif touch.index == _fire_pointer:
			_fire_pointer = -1
			Input.action_release(&"fire")
		elif touch.index == _grenade_pointer:
			_grenade_pointer = -1
			Input.action_release(&"grenade")
		queue_redraw()


func _handle_drag(drag: InputEventScreenDrag) -> void:
	if drag.index == _left_pointer:
		_update_left(drag.position)
	elif drag.index == _right_pointer:
		_update_right(drag.position)


func _update_left(point: Vector2) -> void:
	_left_vector = _left_center.direction_to(point)
	_left_vector *= minf(point.distance_to(_left_center) / STICK_RADIUS, 1.0)
	_update_input_state()
	queue_redraw()


func _update_right(point: Vector2) -> void:
	_right_vector = _right_center.direction_to(point)
	_right_vector *= minf(point.distance_to(_right_center) / STICK_RADIUS, 1.0)
	_update_input_state()
	queue_redraw()


func _update_input_state() -> void:
	InputService.movement_axis = _left_vector
	InputService.jetpack_active = _left_vector.y < -0.35
	InputService.aim_active = _right_vector.length_squared() > 0.05
	if InputService.aim_active:
		InputService.aim_direction = _right_vector.normalized()


func _draw() -> void:
	if not visible:
		return
	_draw_stick(_left_center, _left_vector, Color(0.35, 0.45, 0.65, 0.48))
	_draw_stick(_right_center, _right_vector, Color(0.75, 0.38, 0.34, 0.5))
	draw_string(ThemeDB.fallback_font, _left_center + Vector2(-78.0, -116.0), "MOVE / UP = JETPACK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 1.0, 1.0, 0.78))
	draw_string(ThemeDB.fallback_font, _right_center + Vector2(-55.0, -116.0), "AIM", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 1.0, 1.0, 0.78))
	draw_circle(_fire_center, FIRE_RADIUS, Color(0.75, 0.38, 0.34, 0.38))
	draw_arc(_fire_center, FIRE_RADIUS, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.8), 5.0)
	draw_string(ThemeDB.fallback_font, _fire_center + Vector2(-40.0, 5.0), "FIRE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1.0, 0.9, 0.85, 0.9))
	draw_string(ThemeDB.fallback_font, _grenade_center + Vector2(-55.0, 70.0), "GRENADE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 1.0, 1.0, 0.78))


func _draw_stick(center: Vector2, value: Vector2, color: Color) -> void:
	draw_circle(center, STICK_RADIUS, Color(0.85, 0.9, 0.95, 0.12))
	draw_arc(center, STICK_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.8), 5.0)
	draw_circle(center + value * 55.0, 48.0, color)
	draw_arc(center + value * 55.0, 48.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.75), 4.0)
	if center == _left_center:
		draw_circle(_grenade_center, 44.0, Color(0.25, 0.25, 0.25, 0.48))
		draw_arc(_grenade_center, 44.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.8), 4.0)
