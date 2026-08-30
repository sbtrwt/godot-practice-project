extends CharacterBody2D

@export var start_position: Vector2
@export var end_position: Vector2
@export var speed : float =100.0

var direction: int = 1

func _ready():
	start_position = self.global_position
	end_position = $endPoint.global_position
	$AnimatedSprite2D.play("default")
	
func _physics_process(delta):
	var target_position = end_position if direction == 1 else start_position
	var movement_vector = (target_position - global_position).normalized() * speed
	velocity = movement_vector
	move_and_slide()
	
	if global_position.distance_squared_to(target_position) < 5:
		direction *= -1
