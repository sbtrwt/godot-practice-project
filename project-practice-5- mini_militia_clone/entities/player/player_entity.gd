class_name PlayerEntity
extends CharacterBody2D
## Composed player entity. Authority owns gameplay; this node exposes local movement for the prototype.

signal movement_intent_changed(direction: Vector2)

const SNAPSHOT_INTERVAL: float = 0.05
const CHARACTER_CELL_SIZE: Vector2 = Vector2(416.0, 512.0)

@export var definition: Resource

@onready var _health: Node = $HealthComponent
@onready var _weapon: Node = $WeaponComponent
@onready var _character_sprite: Sprite2D = $CharacterSprite
@onready var _health_bar: ProgressBar = $HealthBar

var _server_input: Vector2 = Vector2.ZERO
var _target_position: Vector2
var _snapshot_elapsed: float = 0.0
var _input_tick: int = 0
var _jetpack_active: bool = false
var _visual_aim: Vector2 = Vector2.RIGHT
var _flash_remaining: float = 0.0
var _grenade_cooldown: float = 0.0


func _ready() -> void:
	if definition == null:
		push_error("PlayerEntity requires a PlayerDefinition resource.")
		return
	_health.set("max_health", int(definition.get("max_health")))
	_health_bar.max_value = int(definition.get("max_health"))
	_health_bar.value = int(definition.get("max_health"))
	Signal(_health, &"health_changed").connect(_on_health_changed)
	Signal(_health, &"died").connect(_on_health_died)
	_target_position = global_position
	add_to_group("players")


func _physics_process(delta: float) -> void:
	if definition == null:
		return

	if multiplayer.is_server():
		_simulate_authority(delta)
		return

	if is_multiplayer_authority():
		var direction := _read_movement_input()
		_submit_input(direction)
		_simulate_direction(direction)
		if Input.is_action_pressed(&"fire"):
			_submit_fire()
		if Input.is_action_just_pressed(&"grenade"):
			_submit_grenade()
	else:
		global_position = global_position.lerp(_target_position, 0.25)


func _process(delta: float) -> void:
	_flash_remaining = maxf(_flash_remaining - delta, 0.0)
	_grenade_cooldown = maxf(_grenade_cooldown - delta, 0.0)
	if is_multiplayer_authority():
		_visual_aim = InputService.aim_direction if InputService.aim_active else global_position.direction_to(get_global_mouse_position())
	queue_redraw()


func _simulate_authority(delta: float) -> void:
	var direction := _server_input
	if get_multiplayer_authority() == 1:
		direction = _read_movement_input()
		_jetpack_active = InputService.jetpack_active or Input.is_action_pressed(&"jetpack")
	_simulate_direction(direction)
	_snapshot_elapsed += delta
	if _snapshot_elapsed >= SNAPSHOT_INTERVAL:
		_snapshot_elapsed = 0.0
		_send_snapshot()


func _simulate_direction(direction: Vector2) -> void:
	movement_intent_changed.emit(direction)
	velocity.x = direction.x * float(definition.get("move_speed"))
	if _jetpack_active:
		velocity.y = move_toward(velocity.y, -float(definition.get("jetpack_thrust")), 120.0)
	else:
		velocity.y = move_toward(velocity.y, float(definition.get("gravity")), 80.0)
	_update_character_sprite()
	move_and_slide()


func _update_character_sprite() -> void:
	var row: float = CHARACTER_CELL_SIZE.y if _jetpack_active else 0.0
	_character_sprite.region_rect = Rect2(
		0.0,
		row,
		CHARACTER_CELL_SIZE.x,
		CHARACTER_CELL_SIZE.y,
	)
	_character_sprite.flip_h = get_global_mouse_position().x < global_position.x


func _submit_input(direction: Vector2) -> void:
	_input_tick += 1
	_jetpack_active = InputService.jetpack_active or Input.is_action_pressed(&"jetpack")
	submit_input.rpc_id(1, Vector2(direction.x, 0.0), _input_tick, _jetpack_active)


@rpc("any_peer", "call_remote", "unreliable")
func submit_input(direction: Vector2, tick: int, jetpack_active: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority() or tick <= _input_tick:
		return
	_server_input = direction.limit_length(1.0)
	_jetpack_active = jetpack_active
	_input_tick = tick


func _send_snapshot() -> void:
	_receive_snapshot.rpc(global_position, velocity, _input_tick)


@rpc("authority", "call_remote", "unreliable")
func _receive_snapshot(snapshot_position: Vector2, new_velocity: Vector2, tick: int) -> void:
	if tick < _input_tick:
		return
	_input_tick = tick
	_target_position = snapshot_position
	velocity = new_velocity
	if is_multiplayer_authority():
		global_position = global_position.lerp(snapshot_position, 0.5)


func _submit_fire() -> void:
	if not bool(_weapon.call("try_fire")):
		return
	var aim_direction := InputService.aim_direction if InputService.aim_active else global_position.direction_to(get_global_mouse_position())
	_visual_aim = aim_direction.normalized()
	request_fire.rpc_id(1, aim_direction)


func _submit_grenade() -> void:
	if _grenade_cooldown > 0.0:
		return
	_grenade_cooldown = 1.0
	request_grenade.rpc_id(1, global_position)


@rpc("any_peer", "call_remote", "reliable")
func request_grenade(origin: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = get_multiplayer_authority()
	if sender_id != get_multiplayer_authority() or _grenade_cooldown > 0.0:
		return
	_grenade_cooldown = 1.0
	_resolve_grenade(origin, sender_id)


func _resolve_grenade(origin: Vector2, attacker_id: int) -> void:
	for candidate_node: Node in get_tree().get_nodes_in_group("players"):
		if candidate_node == self or not candidate_node is Node2D:
			continue
		var candidate: Node2D = candidate_node as Node2D
		if candidate.get_multiplayer_authority() == attacker_id:
			continue
		if candidate.global_position.distance_to(origin) <= 180.0:
			candidate.call("apply_authoritative_damage", 50, attacker_id)


func _read_movement_input() -> Vector2:
	if InputService.movement_axis.length_squared() > 0.01:
		return Vector2(InputService.movement_axis.x, 0.0)
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


@rpc("any_peer", "call_remote", "reliable")
func request_fire(aim_direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = get_multiplayer_authority()
	if sender_id != get_multiplayer_authority() or aim_direction.length_squared() < 0.01:
		return
	if not bool(_weapon.call("try_fire")):
		return
	show_shot.rpc(aim_direction.normalized())
	_resolve_hitscan(sender_id, aim_direction.normalized())


@rpc("authority", "call_local", "unreliable")
func show_shot(aim_direction: Vector2) -> void:
	_visual_aim = aim_direction.normalized()
	_flash_remaining = 0.08
	queue_redraw()


func _draw() -> void:
	var aim: Vector2 = _visual_aim.normalized()
	draw_line(Vector2.ZERO, aim * 52.0, Color(1.0, 0.88, 0.5, 0.55), 3.0)
	if _flash_remaining > 0.0:
		var flash_position: Vector2 = aim * 47.0
		draw_circle(flash_position, 13.0, Color(1.0, 0.75, 0.25, 0.9))
		draw_circle(flash_position, 6.0, Color(1.0, 1.0, 0.85, 1.0))


func _resolve_hitscan(shooter_id: int, aim_direction: Vector2) -> void:
	var best_target: Node2D = null
	var best_distance: float = INF
	for candidate_node: Node in get_tree().get_nodes_in_group("players"):
		if candidate_node == self or not candidate_node is Node2D:
			continue
		var candidate: Node2D = candidate_node as Node2D
		if candidate.get_multiplayer_authority() == shooter_id:
			continue
		var offset := candidate.global_position - global_position
		var distance := offset.length()
		if distance > float(_weapon.get("max_range")) or distance >= best_distance:
			continue
		if aim_direction.dot(offset.normalized()) < 0.86:
			continue
		best_target = candidate
		best_distance = distance
	if best_target != null:
		best_target.call("apply_authoritative_damage", int(_weapon.get("damage")), shooter_id)


## Applies damage only when called by the authority.
func apply_authoritative_damage(amount: int, attacker_id: int) -> void:
	if not multiplayer.is_server():
		return
	_health.call("take_damage", amount)
	if int(_health.get("current_health")) <= 0:
		MatchService.report_kill(attacker_id)
		_respawn_after_delay()


func _respawn_after_delay() -> void:
	global_position = Vector2(320 + (get_multiplayer_authority() - 1) * 100, 360)
	_health.call("heal", int(_health.get("max_health")))


func _on_health_changed(_current: int, _maximum: int) -> void:
	_health_bar.value = _current
	EventBus.score_changed.emit(get_multiplayer_authority(), 0)


func _on_health_died() -> void:
	EventBus.player_removed.emit(get_multiplayer_authority())
