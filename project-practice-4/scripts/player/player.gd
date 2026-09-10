extends CharacterBody2D

signal replay_finished

const StateMachine = preload("res://scripts/player/state_machine.gd")
const IdleState = preload("res://scripts/player/idle_state.gd")
const WalkingState = preload("res://scripts/player/walking_state.gd")
const JumpState = preload("res://scripts/player/jump_state.gd")
const CrouchingState = preload("res://scripts/player/crouching_state.gd")
const PunchState = preload("res://scripts/player/punch_state.gd")
const KickState = preload("res://scripts/player/kick_state.gd")
const PunchCommand = preload("res://scripts/player/punch_command.gd")
const KickCommand = preload("res://scripts/player/kick_command.gd")
const JumpCommand = preload("res://scripts/player/jump_command.gd")
const MovementCommand = preload("res://scripts/player/movement_command.gd")
const RecordedCommand = preload("res://scripts/player/recorded_command.gd")

@export var speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity : float  = 1400.0
@export var acceleration: float = 1
@onready var player_animation = $Sprite2D/AnimationPlayer
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var player_sprite:Sprite2D = $Sprite2D

var state_machine: StateMachine
var punch_command: PlayerCommand
var kick_command: PlayerCommand
var jump_command: PlayerCommand
var last_recorded_direction: float = 0.0
var last_recorded_down: bool = false
var replay_direction: float = 0.0
var replay_down_pressed: bool = false
var command_history: Array[RecordedCommand] = []
var is_recording_commands: bool = false
var is_replaying_commands: bool = false
var recording_started_at: int = 0
var replay_elapsed: float = 0.0
var replay_index: int = 0
var punch_was_pressed: bool = false
var kick_was_pressed: bool = false
var punch_started: bool = false
var kick_started: bool = false
var jump_started: bool = false
var down_pressed: bool = false
var facing_direction:int =1 # 1 for Right, -1 for Left
var is_walking:bool =false

func _ready() -> void:
	state_machine = StateMachine.new()
	punch_command = PunchCommand.new()
	kick_command = KickCommand.new()
	jump_command = JumpCommand.new()
	state_machine.add_state("idle", IdleState.new(self))
	state_machine.add_state("walking", WalkingState.new(self))
	state_machine.add_state("jump", JumpState.new(self))
	state_machine.add_state("crouching", CrouchingState.new(self))
	state_machine.add_state("punch", PunchState.new(self))
	state_machine.add_state("kick", KickState.new(self))
	state_machine.change_state("idle")
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var punch_pressed: bool = not is_replaying_commands and Input.is_physical_key_pressed(KEY_X)
	var kick_pressed: bool = not is_replaying_commands and Input.is_physical_key_pressed(KEY_Z)
	var input_direction := replay_direction if is_replaying_commands else Input.get_axis("ui_left", "ui_right")
	var input_down := replay_down_pressed if is_replaying_commands else Input.is_action_pressed("ui_down")
	jump_started = not is_replaying_commands and Input.is_action_just_pressed("ui_up")
	punch_started = punch_pressed and not punch_was_pressed
	kick_started = kick_pressed and not kick_was_pressed
	down_pressed = input_down
	punch_was_pressed = punch_pressed
	kick_was_pressed = kick_pressed
	is_walking = not punch_pressed and not kick_pressed and input_direction != 0.0
	if not is_replaying_commands and (input_direction != last_recorded_direction or input_down != last_recorded_down):
		execute_command(MovementCommand.new(input_direction, input_down))
		last_recorded_direction = input_direction
		last_recorded_down = input_down
	
	
	update_facing()
	_update_replay(delta)
	state_machine.physics_update(delta)
	move_and_slide()

func _process(delta: float) -> void:
	state_machine.update(delta)

func move_horizontally(delta: float) -> void:
	var direction: float = replay_direction if is_replaying_commands else Input.get_axis("ui_left", "ui_right")
	if direction != 0.0 and is_walking:
		velocity.x = move_toward(velocity.x, direction * speed, speed * delta * acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * acceleration)

func player_jump() -> void:
	velocity.y = jump_velocity
	change_state("jump")

func get_ground_state() -> String:
	if  is_walking:
		return "walking"
	return "idle"

func get_animation_duration(animation_name: String) -> float:
	return player_animation.get_animation(animation_name).length

func set_action_offset(animation_name: String) -> void:
	var action_animation: Animation = player_animation.get_animation(animation_name)
	var track_index: int = action_animation.find_track(NodePath(".:offset"), Animation.TYPE_VALUE)
	if track_index == -1:
		return

	var key_index: int = action_animation.track_find_key(track_index, 0.0)
	if key_index == -1:
		return

	var editor_offset: Vector2 = action_animation.track_get_key_value(track_index, key_index)
	action_animation.track_set_key_value(
		track_index,
		key_index,
		Vector2(absf(editor_offset.x) * facing_direction, editor_offset.y)
	)

func change_state(state_name: String) -> void:
	state_machine.change_state(state_name)

func set_replay_input(direction: float, is_down_pressed: bool) -> void:
	replay_direction = direction
	replay_down_pressed = is_down_pressed

func get_input_direction() -> float:
	return replay_direction if is_replaying_commands else Input.get_axis("ui_left", "ui_right")

func execute_command(command: PlayerCommand) -> void:
	if is_recording_commands and not is_replaying_commands:
		var timestamp := (Time.get_ticks_msec() - recording_started_at) / 1000.0
		command_history.append(RecordedCommand.new(command, timestamp))
	command.execute(self)

func start_recording() -> void:
	command_history.clear()
	recording_started_at = Time.get_ticks_msec()
	last_recorded_direction = INF
	last_recorded_down = not replay_down_pressed
	is_recording_commands = true

func stop_recording() -> void:
	is_recording_commands = false

func replay_commands() -> void:
	if command_history.is_empty():
		return
	replay_elapsed = 0.0
	replay_index = 0
	replay_direction = 0.0
	replay_down_pressed = false
	is_replaying_commands = true

func _update_replay(delta: float) -> void:
	if not is_replaying_commands:
		return

	replay_elapsed += delta
	while replay_index < command_history.size():
		var recorded_command: RecordedCommand = command_history[replay_index]
		if recorded_command.timestamp > replay_elapsed:
			break
		recorded_command.command.execute(self)
		replay_index += 1

	if replay_index == command_history.size():
		is_replaying_commands = false
		replay_finished.emit()

func clear_command_history() -> void:
	command_history.clear()

func execute_punch() -> void:
	set_action_offset("player_stand_punch")
	play_animation("player_stand_punch")

func reset_sprite_offset() -> void:
	player_sprite.offset = Vector2.ZERO
	
func play_animation(animation_name: String, restart: bool = false) -> void:
	if restart or player_animation.current_animation != animation_name:
		player_animation.play(animation_name)

func update_facing() -> void:
	var direction := get_input_direction()
	if direction > 0.0 or (direction == 0.0 and velocity.x > 0.0):
		player_sprite.flip_h = false
		facing_direction = 1
	elif direction < 0.0 or (direction == 0.0 and velocity.x < 0.0):
		player_sprite.flip_h = true
		facing_direction = -1
		
		
