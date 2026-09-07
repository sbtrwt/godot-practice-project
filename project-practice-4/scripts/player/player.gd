extends CharacterBody2D

enum PlayerState { IDEAL, WALKING, JUMP, CROUCHING, PUNCH, KICK }

@export var speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity : float  = 1400.0
@export var acceleration: float = 8
@export var punch_duration: float = 0.25
@export var kick_duration: float = 0.35

@onready var player_animation = $Sprite2D/AnimationPlayer
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var player_sprite:Sprite2D = $Sprite2D

var current_state: PlayerState = PlayerState.IDEAL
var state_time_left: float = 0.0
var punch_was_pressed: bool = false
var kick_was_pressed: bool = false

func _ready() -> void:
	change_state(PlayerState.IDEAL)
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var punch_pressed: bool = Input.is_physical_key_pressed(KEY_J)
	var kick_pressed: bool = Input.is_physical_key_pressed(KEY_K)
	var punch_started: bool = punch_pressed and not punch_was_pressed
	var kick_started: bool = kick_pressed and not kick_was_pressed
	punch_was_pressed = punch_pressed
	kick_was_pressed = kick_pressed

	if current_state == PlayerState.PUNCH or current_state == PlayerState.KICK:
		state_time_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * acceleration)
		if state_time_left <= 0.0:
			if is_on_floor():
				change_state(get_ground_state())
			else:
				change_state(PlayerState.JUMP)
	else:
		var down_pressed: bool = Input.is_action_pressed("ui_down")
		if is_on_floor() and down_pressed and punch_started:
			change_state(PlayerState.PUNCH)
		elif is_on_floor() and down_pressed and kick_started:
			change_state(PlayerState.KICK)
		elif not is_on_floor() and kick_started:
			change_state(PlayerState.KICK)
		elif is_on_floor() and punch_started:
			change_state(PlayerState.PUNCH)
		elif is_on_floor() and kick_started:
			change_state(PlayerState.KICK)
		elif is_on_floor() and Input.is_action_just_pressed("ui_accept"):
			player_jump()
		elif is_on_floor() and Input.is_action_pressed("ui_down"):
			velocity.x = move_toward(velocity.x, 0.0, speed * delta * acceleration)
			change_state(PlayerState.CROUCHING)
		else:
			move_horizontally(delta)
			if not is_on_floor():
				change_state(PlayerState.JUMP)
			else:
				change_state(get_ground_state())

	move_and_slide()
	update_facing()

func move_horizontally(delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, speed * delta * acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * acceleration)

func player_jump() -> void:
	velocity.y = jump_velocity
	change_state(PlayerState.JUMP)

func get_ground_state() -> PlayerState:
	if absf(velocity.x) > 1.0:
		return PlayerState.WALKING
	return PlayerState.IDEAL

func change_state(next_state: PlayerState) -> void:
	if current_state == next_state:
		return
	current_state = next_state
	match current_state:
		PlayerState.IDEAL:
			play_animation("player_normal")
		PlayerState.WALKING:
			play_animation("player_walk")
		PlayerState.JUMP:
			play_animation("player_down")
		PlayerState.CROUCHING:
			play_animation("player_down")
		PlayerState.PUNCH:
			state_time_left = punch_duration
			if Input.is_action_pressed("ui_down"):
				play_animation("player_sit_punch")
			else:
				play_animation("player_stand_punch")
		PlayerState.KICK:
			state_time_left = kick_duration
			if not is_on_floor():
				play_animation("player_flying_kick")
			elif Input.is_action_pressed("ui_down"):
				play_animation("player_sit_kick")
			else:
				play_animation("player_stand_kick")

func play_animation(animation_name: String) -> void:
	if player_animation.current_animation != animation_name:
		player_animation.play(animation_name)

func update_facing() -> void:
	if velocity.x > 0.0:
		player_sprite.flip_h = false
	elif velocity.x < 0.0:
		player_sprite.flip_h = true
		
