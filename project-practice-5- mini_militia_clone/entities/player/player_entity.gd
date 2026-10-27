class_name PlayerEntity
extends CharacterBody2D
## Composed player entity. Authority owns gameplay; this node exposes local movement for the prototype.

signal movement_intent_changed(direction: Vector2)

const SNAPSHOT_INTERVAL: float = 0.05

@export var definition: Resource

@onready var _health: Node = $HealthComponent
@onready var _weapon: Node = $WeaponComponent

var _server_input: Vector2 = Vector2.ZERO
var _target_position: Vector2
var _snapshot_elapsed: float = 0.0
var _input_tick: int = 0


func _ready() -> void:
	if definition == null:
		push_error("PlayerEntity requires a PlayerDefinition resource.")
		return
	_health.set("max_health", int(definition.get("max_health")))
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
		var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		_submit_input(direction)
		_simulate_direction(direction)
		if Input.is_action_pressed(&"fire"):
			_submit_fire()
	else:
		global_position = global_position.lerp(_target_position, 0.25)


func _simulate_authority(delta: float) -> void:
	var direction := _server_input
	if get_multiplayer_authority() == 1:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_simulate_direction(direction)
	_snapshot_elapsed += delta
	if _snapshot_elapsed >= SNAPSHOT_INTERVAL:
		_snapshot_elapsed = 0.0
		_send_snapshot()


func _simulate_direction(direction: Vector2) -> void:
	movement_intent_changed.emit(direction)
	velocity = direction * float(definition.get("move_speed"))
	move_and_slide()


func _submit_input(direction: Vector2) -> void:
	_input_tick += 1
	submit_input.rpc_id(1, direction, _input_tick)


@rpc("any_peer", "call_remote", "unreliable")
func submit_input(direction: Vector2, tick: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority() or tick <= _input_tick:
		return
	_server_input = direction.limit_length(1.0)
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
	var aim_direction := global_position.direction_to(get_global_mouse_position())
	request_fire.rpc_id(1, aim_direction)


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
	_resolve_hitscan(sender_id, aim_direction.normalized())


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
	EventBus.score_changed.emit(get_multiplayer_authority(), 0)


func _on_health_died() -> void:
	EventBus.player_removed.emit(get_multiplayer_authority())
