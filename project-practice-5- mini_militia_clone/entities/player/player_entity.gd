class_name PlayerEntity
extends CharacterBody2D
## Composed player entity. Authority owns gameplay; this node exposes local movement for the prototype.

signal movement_intent_changed(direction: Vector2)

const SNAPSHOT_INTERVAL: float = 0.05
const CHARACTER_CELL_SIZE: Vector2 = Vector2(416.0, 512.0)
const GRENADE_FUSE_SECONDS: float = 0.35

@export var definition: Resource
@export var spawn_position: Vector2 = Vector2(320.0, 360.0)

@onready var _health: Node = $HealthComponent
@onready var _hurtbox: Node = $HurtboxComponent
@onready var _weapon: Node = $WeaponComponent
@onready var _character_sprite: Sprite2D = $CharacterSprite
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _server_input: Vector2 = Vector2.ZERO
var _target_position: Vector2
var _snapshot_elapsed: float = 0.0
var _input_tick: int = 0
var _jetpack_active: bool = false
var _visual_aim: Vector2 = Vector2.RIGHT
var _flash_remaining: float = 0.0
var _grenade_cooldown: float = 0.0
var _grenade_effect_remaining: float = 0.0
var _grenade_effect_origin: Vector2 = Vector2.ZERO
var _grenade_fuse_remaining: float = 0.0
var _grenade_fuse_origin: Vector2 = Vector2.ZERO
var _snapshot_queue: Array[Dictionary] = []
var _respawning: bool = false
var _hit_effect_remaining: float = 0.0
var _hit_effect_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	if definition == null:
		push_error("PlayerEntity requires a PlayerDefinition resource.")
		return
	_health.set("max_health", int(definition.get("max_health")))
	_health_bar.max_value = int(definition.get("max_health"))
	_health_bar.value = int(definition.get("max_health"))
	Signal(_health, &"health_changed").connect(_on_health_changed)
	Signal(_health, &"died").connect(_on_health_died)
	Signal(_hurtbox, &"hit_received").connect(_on_hurtbox_hit)
	_target_position = global_position
	add_to_group("players")


func _physics_process(delta: float) -> void:
	if definition == null:
		return
	if _respawning:
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
	_grenade_effect_remaining = maxf(_grenade_effect_remaining - delta, 0.0)
	_grenade_fuse_remaining = maxf(_grenade_fuse_remaining - delta, 0.0)
	_hit_effect_remaining = maxf(_hit_effect_remaining - delta, 0.0)
	_deliver_queued_snapshots()
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
	if NetworkService.should_drop_packet():
		return
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


@rpc("any_peer", "call_remote", "unreliable")
func _receive_snapshot(snapshot_position: Vector2, new_velocity: Vector2, tick: int) -> void:
	if multiplayer.is_server():
		return
	if tick < _input_tick:
		return
	var latency := NetworkService.simulated_latency_seconds()
	if latency > 0.0:
		_snapshot_queue.append({"position": snapshot_position, "velocity": new_velocity, "tick": tick, "deliver_at": Time.get_ticks_msec() + latency * 1000.0})
		return
	_apply_snapshot(snapshot_position, new_velocity, tick)


func _deliver_queued_snapshots() -> void:
	if _snapshot_queue.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	while not _snapshot_queue.is_empty() and float(_snapshot_queue[0]["deliver_at"]) <= now:
		var snapshot: Dictionary = _snapshot_queue.pop_front()
		_apply_snapshot(snapshot["position"], snapshot["velocity"], int(snapshot["tick"]))


func _apply_snapshot(snapshot_position: Vector2, new_velocity: Vector2, tick: int) -> void:
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
	_grenade_cooldown = float(_weapon.get("grenade_cooldown"))
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
	show_grenade_fuse.rpc(origin)
	await get_tree().create_timer(GRENADE_FUSE_SECONDS).timeout
	if not is_inside_tree() or not multiplayer.is_server():
		return
	show_grenade.rpc(origin)
	for candidate_node: Node in get_tree().get_nodes_in_group("players"):
		if candidate_node == self or not candidate_node is Node2D:
			continue
		var candidate: Node2D = candidate_node as Node2D
		if candidate.get_multiplayer_authority() == attacker_id:
			continue
		if candidate.global_position.distance_to(origin) <= float(_weapon.get("grenade_radius")):
			var hurtbox: Node = candidate.get_node_or_null("HurtboxComponent")
			if hurtbox != null and hurtbox.has_method(&"receive_hit"):
				hurtbox.call("receive_hit", int(_weapon.get("grenade_damage")), attacker_id)


@rpc("any_peer", "call_local", "unreliable")
func show_grenade_fuse(origin: Vector2) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		return
	_grenade_fuse_origin = to_local(origin)
	_grenade_fuse_remaining = GRENADE_FUSE_SECONDS
	queue_redraw()


@rpc("any_peer", "call_local", "unreliable")
func show_grenade(origin: Vector2) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		return
	_grenade_effect_origin = to_local(origin)
	_grenade_effect_remaining = 0.28
	queue_redraw()


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


@rpc("any_peer", "call_local", "unreliable")
func show_shot(aim_direction: Vector2) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		return
	_visual_aim = aim_direction.normalized()
	_flash_remaining = 0.08
	queue_redraw()


func _draw() -> void:
	var player_label := "P%d" % get_multiplayer_authority()
	draw_string(ThemeDB.fallback_font, Vector2(-18.0, -48.0), player_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.92, 0.96, 1.0, 0.9))
	var aim: Vector2 = _visual_aim.normalized()
	draw_line(Vector2.ZERO, aim * 52.0, Color(1.0, 0.88, 0.5, 0.55), 3.0)
	if _flash_remaining > 0.0:
		var flash_position: Vector2 = aim * 47.0
		draw_circle(flash_position, 13.0, Color(1.0, 0.75, 0.25, 0.9))
		draw_circle(flash_position, 6.0, Color(1.0, 1.0, 0.85, 1.0))
	if _grenade_effect_remaining > 0.0:
		var progress := 1.0 - (_grenade_effect_remaining / 0.28)
		var radius := lerpf(18.0, 180.0, progress)
		var alpha := 1.0 - progress
		draw_circle(_grenade_effect_origin, radius, Color(1.0, 0.42, 0.12, alpha * 0.18))
		draw_arc(_grenade_effect_origin, radius, 0.0, TAU, 32, Color(1.0, 0.72, 0.25, alpha * 0.9), 5.0)
		draw_circle(_grenade_effect_origin, 10.0 + progress * 8.0, Color(1.0, 0.92, 0.5, alpha))
	if _grenade_fuse_remaining > 0.0:
		var fuse_progress := 1.0 - (_grenade_fuse_remaining / GRENADE_FUSE_SECONDS)
		draw_circle(_grenade_fuse_origin, 12.0, Color(0.15, 0.08, 0.04, 0.9))
		draw_arc(_grenade_fuse_origin, 18.0, -PI * 0.5, -PI * 0.5 + TAU * fuse_progress, 20, Color(1.0, 0.8, 0.25, 0.95), 3.0)
	if _hit_effect_remaining > 0.0:
		var hit_alpha := _hit_effect_remaining / 0.16
		draw_line(_hit_effect_position + Vector2(-10.0, -10.0), _hit_effect_position + Vector2(10.0, 10.0), Color(1.0, 0.95, 0.55, hit_alpha), 3.0)
		draw_line(_hit_effect_position + Vector2(10.0, -10.0), _hit_effect_position + Vector2(-10.0, 10.0), Color(1.0, 0.95, 0.55, hit_alpha), 3.0)


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
		show_hit.rpc(best_target.global_position)
		var hurtbox: Node = best_target.get_node_or_null("HurtboxComponent")
		if hurtbox != null and hurtbox.has_method(&"receive_hit"):
			hurtbox.call("receive_hit", int(_weapon.get("damage")), shooter_id)


@rpc("any_peer", "call_local", "unreliable")
func show_hit(world_position: Vector2) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		return
	_hit_effect_position = to_local(world_position)
	_hit_effect_remaining = 0.16
	queue_redraw()


## Applies a received hit only when called by the authority.
func _on_hurtbox_hit(amount: int, attacker_id: int) -> void:
	if not multiplayer.is_server():
		return
	_health.call("take_damage", amount)
	if int(_health.get("current_health")) <= 0:
		MatchService.report_kill(attacker_id, get_multiplayer_authority())
		_respawn_after_delay()


func _respawn_after_delay() -> void:
	if _respawning:
		return
	_respawning = true
	_set_respawning_visual.rpc(true)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	global_position = spawn_position
	_health.call("heal", int(_health.get("max_health")))
	_respawning = false
	_set_respawning_visual.rpc(false)


@rpc("any_peer", "call_local", "reliable")
func _set_respawning_visual(is_respawning: bool) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != 0:
		return
	visible = not is_respawning
	_collision_shape.disabled = is_respawning


func _on_health_changed(_current: int, _maximum: int) -> void:
	_health_bar.value = _current
	EventBus.score_changed.emit(get_multiplayer_authority(), 0)
	if multiplayer.is_server():
		_publish_health.rpc(_current, _maximum)


@rpc("any_peer", "call_remote", "reliable")
func _publish_health(current: int, maximum: int) -> void:
	if multiplayer.is_server():
		return
	_health.call("apply_replicated_health", current, maximum)


func _on_health_died() -> void:
	EventBus.player_removed.emit(get_multiplayer_authority())
