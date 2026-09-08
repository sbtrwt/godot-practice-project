extends CharacterBody2D

const StateMachine = preload("res://scripts/player/state_machine.gd")
const IdleState = preload("res://scripts/player/idle_state.gd")
const WalkingState = preload("res://scripts/player/walking_state.gd")
const JumpState = preload("res://scripts/player/jump_state.gd")
const CrouchingState = preload("res://scripts/player/crouching_state.gd")
const PunchState = preload("res://scripts/player/punch_state.gd")
const KickState = preload("res://scripts/player/kick_state.gd")

@export var speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity : float  = 1400.0
@export var acceleration: float = 8
@onready var player_animation = $Sprite2D/AnimationPlayer
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var player_sprite:Sprite2D = $Sprite2D

var state_machine: StateMachine
var punch_was_pressed: bool = false
var kick_was_pressed: bool = false
var punch_started: bool = false
var kick_started: bool = false
var down_pressed: bool = false
var facing_direction:int =1 # 1 for Right, -1 for Left
var is_walking:bool =false

func _ready() -> void:
	state_machine = StateMachine.new()
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

	var punch_pressed: bool = Input.is_physical_key_pressed(KEY_X)
	var kick_pressed: bool = Input.is_physical_key_pressed(KEY_Z)
	punch_started = punch_pressed and not punch_was_pressed
	kick_started = kick_pressed and not kick_was_pressed
	down_pressed = Input.is_action_pressed("ui_down")
	punch_was_pressed = punch_pressed
	kick_was_pressed = kick_pressed
	is_walking = not punch_pressed and not kick_pressed and Input.get_axis("ui_left", "ui_right") != 0.0
	
	
	update_facing()
	state_machine.physics_update(delta)
	move_and_slide()

func _process(delta: float) -> void:
	state_machine.update(delta)

func move_horizontally(delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
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

func execute_punch() -> void:
	set_action_offset("player_stand_punch")
	play_animation("player_stand_punch")
	
func play_animation(animation_name: String) -> void:
	if player_animation.current_animation != animation_name:
		player_animation.play(animation_name)

func update_facing() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction > 0.0 or (direction == 0.0 and velocity.x > 0.0):
		player_sprite.flip_h = false
		facing_direction = 1
	elif direction < 0.0 or (direction == 0.0 and velocity.x < 0.0):
		player_sprite.flip_h = true
		facing_direction = -1
		
		
