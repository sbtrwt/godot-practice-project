extends Control
## Twin-stick touch controls: left stick moves/jetpacks, right stick aims, Fire taps/shoots.

const LEFT_CENTER: Vector2 = Vector2(150.0, 610.0)
const RIGHT_CENTER: Vector2 = Vector2(1120.0, 610.0)
const STICK_RADIUS: float = 100.0

var _left_pointer: int = -1
var _right_pointer: int = -1
var _left_vector: Vector2 = Vector2.ZERO
var _right_vector: Vector2 = Vector2.ZERO
var _fire_pointer: int = -1


func _ready() -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(touch: InputEventScreenTouch) -> void:
	var point: Vector2 = touch.position
	if touch.pressed:
		if point.distance_to(LEFT_CENTER) <= STICK_RADIUS and _left_pointer == -1:
			_left_pointer = touch.index
			_update_left(point)
		elif point.distance_to(RIGHT_CENTER) <= STICK_RADIUS and _right_pointer == -1:
			_right_pointer = touch.index
			_update_right(point)
		elif point.x > 980.0 and point.y > 500.0:
			_fire_pointer = touch.index
			Input.action_press(&"fire")
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
		queue_redraw()


func _handle_drag(drag: InputEventScreenDrag) -> void:
	if drag.index == _left_pointer:
		_update_left(drag.position)
	elif drag.index == _right_pointer:
		_update_right(drag.position)


func _update_left(point: Vector2) -> void:
	_left_vector = LEFT_CENTER.direction_to(point)
	_left_vector *= minf(point.distance_to(LEFT_CENTER) / STICK_RADIUS, 1.0)
	_update_input_state()
	queue_redraw()


func _update_right(point: Vector2) -> void:
	_right_vector = RIGHT_CENTER.direction_to(point)
	_right_vector *= minf(point.distance_to(RIGHT_CENTER) / STICK_RADIUS, 1.0)
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
	_draw_stick(LEFT_CENTER, _left_vector, Color(0.35, 0.45, 0.65, 0.48))
	_draw_stick(RIGHT_CENTER, _right_vector, Color(0.75, 0.38, 0.34, 0.5))


func _draw_stick(center: Vector2, value: Vector2, color: Color) -> void:
	draw_circle(center, STICK_RADIUS, Color(0.85, 0.9, 0.95, 0.12))
	draw_arc(center, STICK_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.8), 5.0)
	draw_circle(center + value * 55.0, 48.0, color)
	draw_arc(center + value * 55.0, 48.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.75), 4.0)
