extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity : float  = 1400.0
@export var acceleration: float = 8

@onready var player_animation = $Sprite2D/AnimationPlayer
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var player_sprite:Sprite2D = $Sprite2D

func _ready() -> void:
	player_animation.play("player_normal")
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() == true:
		player_jump()
			
	var direction: float = Input.get_axis("ui_left","ui_right")
	if direction:
		velocity.x= direction*speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	update_animations()

func player_jump():
	
	velocity.y = jump_velocity
	
func update_animations():
	var landing_soon: bool = ray_cast_2d.is_colliding() and velocity.y > 0
	
	if landing_soon or is_on_floor():
		if velocity.x != 0:
			player_animation.play("player_walk")
		else:
			player_animation.play("player_normal")
	elif velocity.y < 0:
		player_animation.play("player_down")
	elif  velocity.y > 0:
		player_animation.play("player_down")
	
	if velocity.x > 0:
		player_sprite.flip_h = false
		
	if velocity.x < 0:
		player_sprite.flip_h = true
		
